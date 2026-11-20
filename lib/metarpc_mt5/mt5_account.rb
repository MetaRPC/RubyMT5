# ══════════════════════════════════════════════════════════════════════════════
# MT5Account — Low-Level MetaTrader 5 gRPC Client
# ══════════════════════════════════════════════════════════════════════════════
#
# The low-level layer of the three-layer stack:
#     MT5Account (this file)  →  MT5Service  →  MT5Sugar
#
# Each method maps 1:1 to a MetaRPC MT5 RPC. You pass plain arguments, it builds
# the generated protobuf *Request, sends it with the APIKey + id metadata, and
# returns the reply's `data` message. Raises ApiError on an error reply and
# GRPC::BadStatus on transport failures.
#
# TOTAL METHODS: 48 (43 unary RPCs + 5 streaming RPCs)
#
# METHOD GROUPS:
# ──────────────────────────────────────────────────────────────────────────────
#
# 1. SESSION & CONNECTION (9 methods)
#    • connect / connect_ex   - Connect by broker server (cluster) name (ConnectEx)
#    • connect_by_host        - Connect by raw broker host:port (Connect)
#    • connect_proxy          - Connect through a SOCKS/HTTP proxy
#    • get_id                 - Resolve the terminal session id (GetId RPC)
#    • check_connect          - Verify the terminal is still attached
#    • connection_status      - Current connection status
#    • reconnect              - Re-establish the broker connection
#    • disconnect             - Stop the terminal (delete: removes it too)
#    • close                  - Drop cached stubs / release channels
#
# 2. ACCOUNT INFORMATION (4 methods)
#    • account_summary        - All account data in one call (RECOMMENDED)
#    • account_info_double    - One ACCOUNT_* double  (Balance, Equity, Margin...)
#    • account_info_integer   - One ACCOUNT_* integer (Login, Leverage...)
#    • account_info_string    - One ACCOUNT_* string  (Currency, Company...)
#
# 3. SYMBOLS & MARKET INFO (15 methods)
#    • symbols_total          - Count total / Market-Watch symbols
#    • symbol_exist           - Does a symbol exist?
#    • symbol_name            - Symbol name by index
#    • symbol_select          - Add / remove a symbol from Market Watch
#    • symbol_is_synchronized - Is the symbol synced with the server?
#    • symbol_info_double     - One SYMBOL_* double  (Point, Volume...)
#    • symbol_info_integer    - One SYMBOL_* integer (Digits, Stops Level...)
#    • symbol_info_string     - One SYMBOL_* string  (Description, Base Currency...)
#    • symbol_info_margin_rate- Initial / maintenance margin rates
#    • symbol_info_tick       - Last tick (bid / ask / last / time)
#    • symbol_info_session_quote - Quote session [from, to) for a weekday
#    • symbol_info_session_trade - Trade session [from, to) for a weekday
#    • symbol_list            - Names of all symbols
#    • symbol_params_many     - Full specs of all symbols in one call
#    • tick_value_with_size   - Tick value / size / contract size for sizing
#
# 4. MARKET DEPTH / DOM (3 methods)
#    • market_book_add        - Subscribe to a symbol's order book
#    • market_book_release    - Unsubscribe from the order book
#    • market_book_get        - Current order-book snapshot
#
# 5. PRICE HISTORY (1 method)
#    • price_history / bars   - OHLC bars for a symbol and timeframe
#
# 6. STREAMS (5 methods)
#    • on_symbol_tick         - Stream ticks
#    • on_trade               - Stream trade events
#    • on_position_profit     - Stream position P/L updates
#    • on_positions_and_pending_orders_tickets - Stream ticket snapshots
#    • on_trade_transaction   - Stream low-level trade transactions
#
# 7. TRADING (7 methods)
#    • order_send             - Send a market or pending order
#    • order_modify           - Modify SL/TP/price/expiration
#    • order_close            - Close a position / delete a pending order
#    • order_check            - Validate a trade request without sending
#    • order_calc_margin      - Margin required for an order
#    • order_calc_profit      - Profit for a hypothetical round-trip
#    • positions_total        - Count open positions
#
# 8. OPENED ORDERS & HISTORY (4 methods)
#    • opened_orders          - Open positions & pending orders (full detail)
#    • opened_orders_tickets  - Only the tickets (lightweight)
#    • order_history          - Historical orders+deals (auto-paged)
#    • positions_history      - Historical positions / round-trips (auto-paged)
#
# UTILITIES:
#    • compute_deterministic_id - Derive a stable terminal id from login+password
#    • uuid5                    - RFC-4122 v5 id from a namespace + name
#    • target / connected? / metadata (headers) - session accessors
#
# ══════════════════════════════════════════════════════════════════════════════

require "digest"
require "grpc"
require "google/protobuf/well_known_types"

# Generated protobuf / gRPC stubs live in <gem root>/package and require each
# other by bare file name, so that directory has to be on the load path.
PACKAGE_DIR = File.expand_path("../../package", __dir__)
$LOAD_PATH.unshift(PACKAGE_DIR) unless $LOAD_PATH.include?(PACKAGE_DIR)

%w[
  mrpc-mt5-error_pb
  mt5-term-api-connection_services_pb
  mt5-term-api-account-helper_services_pb
  mt5-term-api-account-information_services_pb
  mt5-term-api-market-info_services_pb
  mt5-term-api-subscriptions_services_pb
  mt5-term-api-trade-functions_services_pb
  mt5-term-api-trading-helper_services_pb
  mt5-term-api-trade-stats_services_pb
  mt5-term-api-health-check_services_pb
].each { |f| require f }

require_relative "errors"
require_relative "subscription"

module MetaRPC
  module MT5
    # LOW-LEVEL layer — a thin, honest, 1:1-with-the-wire gRPC client.
    #
    # Each method maps to a single MetaRPC MT5 RPC: you pass the plain arguments,
    # it builds the generated protobuf `*Request`, sends it with the APIKey + id
    # metadata, and returns the reply's `data` message (never the reply wrapper).
    # It raises {ApiError} when the reply carries an error and GRPC::BadStatus on
    # transport / gateway failures. It owns the gRPC channel, the service stubs,
    # the auth metadata and the connection lifecycle.
    #
    #   acct = MetaRPC::MT5::MT5Account.new(api_key: ENV["MRPC_API_KEY"], id: stable_uuid)
    #   acct.connect(498489, "pwd", server: "ICMarkets-Demo", name: "my-bot")
    #   s = acct.account_summary          # Mt5TermApi::AccountSummaryData
    #   t = acct.symbol_info_tick("EURUSD")
    #   r = acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.01, magic: 600001)
    #
    # For typed Ruby objects and plain arguments use {MT5Service}; for one-line
    # helpers use {MT5Sugar}.
    class MT5Account
      # ════════════════════════════════════════════════════════════════════════════
      #region CONSTANTS
      # ════════════════════════════════════════════════════════════════════════════

      DEFAULT_HOST = "mt5.mrpc.pro"
      DEFAULT_PORT = 443

      # MQL5 ENUM_TIMEFRAMES values accepted by price_history.
      TIMEFRAMES = {
        M1: 1, M2: 2, M3: 3, M4: 4, M5: 5, M6: 6, M10: 10, M12: 12, M15: 15, M20: 20, M30: 30,
        H1: 16385, H2: 16386, H3: 16387, H4: 16388, H6: 16390, H8: 16392, H12: 16396,
        D1: 16408, W1: 32769, MN1: 49153
      }.freeze

      # Friendly order type -> trading-helper TMT5_ENUM_ORDER_TYPE symbol.
      ORDER_TYPES = {
        buy: :TMT5_ORDER_TYPE_BUY, sell: :TMT5_ORDER_TYPE_SELL,
        buy_limit: :TMT5_ORDER_TYPE_BUY_LIMIT, sell_limit: :TMT5_ORDER_TYPE_SELL_LIMIT,
        buy_stop: :TMT5_ORDER_TYPE_BUY_STOP, sell_stop: :TMT5_ORDER_TYPE_SELL_STOP,
        buy_stop_limit: :TMT5_ORDER_TYPE_BUY_STOP_LIMIT, sell_stop_limit: :TMT5_ORDER_TYPE_SELL_STOP_LIMIT
      }.freeze

      # Friendly order type -> trade-functions ORDER_TYPE_TF_* symbol (calc/check).
      TF_ORDER_TYPES = {
        buy: :ORDER_TYPE_TF_BUY, sell: :ORDER_TYPE_TF_SELL, buy_limit: :ORDER_TYPE_TF_BUY_LIMIT, sell_limit: :ORDER_TYPE_TF_SELL_LIMIT,
        buy_stop: :ORDER_TYPE_TF_BUY_STOP, sell_stop: :ORDER_TYPE_TF_SELL_STOP
      }.freeze

      #endregion

      attr_reader :host, :port, :api_key, :id, :login, :server, :name, :last_disconnect_deleted, :server_guid
      attr_accessor :timeout

      # ════════════════════════════════════════════════════════════════════════════
      #region IDENTITY HELPERS
      # ════════════════════════════════════════════════════════════════════════════

      # Deterministic RFC-4122-looking id derived from login+password (used when
      # the caller gives no id). Prefer passing a stable `id:` per strategy.
      def self.compute_deterministic_id(user, password)
        raw = Digest::SHA256.digest("#{user}:#{password}")
        le = raw[0..15].bytes
        le[0], le[1], le[2], le[3] = le[3], le[2], le[1], le[0]
        le[4], le[5] = le[5], le[4]
        le[6], le[7] = le[7], le[6]
        format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", *le)
      end

      # UUID v5 (SHA-1, RFC 4122) of `name` under `namespace` (a uuid string).
      # Use it to derive a STABLE terminal id per strategy, e.g.
      #   MT5Account.uuid5(MT5Account::NAMESPACE_DNS, "fleet-audit-RubyMT5")
      NAMESPACE_DNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8".freeze
      def self.uuid5(namespace, name)
        ns = [namespace.delete("-")].pack("H*")
        h = Digest::SHA1.digest(ns + name).bytes[0, 16]
        h[6] = (h[6] & 0x0f) | 0x50
        h[8] = (h[8] & 0x3f) | 0x80
        hex = h.pack("C*").unpack1("H*")
        "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
      end

      #endregion

      # @param id [String, nil] terminal instance id to reuse. Strongly recommended:
      #   the gateway keeps one terminal per id; a fresh id per run orphans terminals.
      # @param timeout [Numeric] per-RPC deadline in seconds (streams are exempt).
      def initialize(host = DEFAULT_HOST, port = DEFAULT_PORT, api_key: nil, id: nil, timeout: 60, channel_args: {})
        @host = host
        @port = port
        @api_key = api_key || ENV["MRPC_API_KEY"]
        raise ArgumentError, "api_key is required (pass api_key: or set MRPC_API_KEY)" if @api_key.nil? || @api_key.empty?

        @id = id
        @timeout = timeout
        @connected = false
        @channel_args = {
          "grpc.keepalive_time_ms" => 30_000,
          "grpc.keepalive_timeout_ms" => 10_000,
          "grpc.keepalive_permit_without_calls" => 1,
          "grpc.max_receive_message_length" => 64 * 1024 * 1024
        }.merge(channel_args)
        @creds = port == 443 ? GRPC::Core::ChannelCredentials.new : :this_channel_is_insecure
        @stubs = {}
      end

      # ════════════════════════════════════════════════════════════════════════════
      #region SESSION
      # ════════════════════════════════════════════════════════════════════════════

      # "host:port" the stubs dial.
      def target = "#{@host}:#{@port}"

      # True once a connect call has succeeded (and not been disconnected).
      def connected? = @connected

      # gRPC metadata attached to every call: APIKey + terminal id.
      def metadata
        md = { "apikey" => @api_key }
        md["id"] = @id if @id
        md
      end
      alias headers metadata

      # Drop the cached service stubs; their channels are closed by GC. Call it
      # when you are done with the account to release the gRPC connections.
      def close
        @stubs = {}
        @connected = false
        nil
      end

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region CONNECTION
      # ════════════════════════════════════════════════════════════════════════════

      # ConnectEx: connect by broker server (cluster) name. Creates the terminal
      # on the gateway (or reuses the one bound to `id`). Returns ConnectData.
      # Raises InvalidLoginError for bad credentials (do NOT retry that one).
      def connect(login, password, server:, name: nil, timeout_seconds: 120, expiration: nil)
        @login = Integer(login)
        @server = server
        @name = name
        @id ||= self.class.compute_deterministic_id(@login, password)
        req = Mt5TermApi::ConnectExRequest.new(user: @login, password: password, mt_cluster_name: server,
                                               timeout_seconds: timeout_seconds)
        req.name = name if name
        req.expiration = expiration if expiration
        data = call(:connection, :connect_ex, req, timeout: timeout_seconds + 30)
        # The gateway answers with its own alias ("mt5_live_<hex>"); keep sending the
        # id we chose: it is the routing key and stays stable across runs.
        @server_guid = data.terminal_instance_guid
        @connected = true
        data
      rescue ApiError => e
        raise InvalidLoginError.new(e.error, "ConnectEx") if e.code.to_s =~ /INVALID_LOGIN|WrongPassword|INVALID_ACCOUNT/i
        raise
      end
      alias connect_ex connect

      # Connect by raw host:port of the broker trade server (no cluster lookup).
      def connect_by_host(login, password, host:, port:, name: nil, timeout_seconds: 120)
        @login = Integer(login)
        @server = "#{host}:#{port}"
        @name = name
        @id ||= self.class.compute_deterministic_id(@login, password)
        req = Mt5TermApi::ConnectRequest.new(user: @login, password: password, host: host, port: port,
                                             timeout_seconds: timeout_seconds)
        req.name = name if name
        data = call(:connection, :connect, req, timeout: timeout_seconds + 30)
        @server_guid = data.terminal_instance_guid
        @connected = true
        data
      end

      # Connect through a proxy (SOCKS/HTTP). Returns ConnectProxyData
      # (unique_identifier, terminal_type). `proxy_type` is a ProxyTypes enum symbol.
      def connect_proxy(login, password, host:, port:, proxy_host:, proxy_port:, proxy_type:,
                        proxy_user: nil, proxy_password: nil, name: nil, timeout_seconds: 120)
        @login = Integer(login)
        req = Mt5TermApi::ConnectProxyRequest.new(user: @login, password: password, host: host, port: port,
                                                  proxyHost: proxy_host, proxyPort: proxy_port, proxyType: proxy_type,
                                                  timeout_seconds: timeout_seconds)
        req.proxyUser = proxy_user if proxy_user
        req.proxyPassword = proxy_password if proxy_password
        req.name = name if name
        call(:connection, :connect_proxy, req, timeout: timeout_seconds + 30)
      end

      # Resolve the terminal session id the gateway assigns to these credentials
      # (GetId). Returns the id string. The SDK normally derives one locally via
      # {.compute_deterministic_id}; use this when you want the server's own id.
      def get_id(user, password) = call(:connection, :get_id, Mt5TermApi::GetIdRequest.new(user: Integer(user), password: password)).id

      # Is the terminal still attached on the gateway? Returns CheckConnectData.
      def check_connect = call(:connection, :check_connect, Mt5TermApi::CheckConnectRequest.new)

      # Current connection status of the terminal (ConnectionStatusData).
      def connection_status = call(:connection, :connection_status, Mt5TermApi::ConnectionStatusRequest.new)

      # Force the gateway to re-establish the terminal's broker connection.
      def reconnect(force: false) = call(:connection, :reconnect, Mt5TermApi::ReconnectRequest.new(force_reconnection: force), timeout: 180)

      # Stops the terminal on the gateway. delete: true also removes it from the
      # account list (the next connect with the same id creates a fresh one).
      def disconnect(delete: false, reason: nil)
        req = Mt5TermApi::DisconnectRequest.new
        req.delete = delete
        req.reason = reason if reason
        data = call(:connection, :disconnect, req)
        @connected = false
        @last_disconnect_deleted = delete
        data
      end

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region ACCOUNT INFORMATION
      # ════════════════════════════════════════════════════════════════════════════

      # Mt5TermApi::AccountSummaryData: account_login, account_balance,
      # account_equity, account_currency, account_leverage, account_trade_mode
      # (:MRPC_ACCOUNT_TRADE_MODE_DEMO / _CONTEST / _REAL), account_company_name,
      # server_time (Timestamp, broker tz), server_time_utc.
      def account_summary = call(:account_helper, :account_summary, Mt5TermApi::AccountSummaryRequest.new)

      # One ACCOUNT_* double property (e.g. :ACCOUNT_EQUITY, :ACCOUNT_MARGIN).
      def account_info_double(property) = call(:account_information, :account_info_double, Mt5TermApi::AccountInfoDoubleRequest.new(property_id: property)).requested_value

      # One ACCOUNT_* integer property (e.g. :ACCOUNT_LEVERAGE, :ACCOUNT_TRADE_MODE).
      def account_info_integer(property) = call(:account_information, :account_info_integer, Mt5TermApi::AccountInfoIntegerRequest.new(property_id: property)).requested_value

      # One ACCOUNT_* string property (e.g. :ACCOUNT_CURRENCY, :ACCOUNT_COMPANY).
      def account_info_string(property) = call(:account_information, :account_info_string, Mt5TermApi::AccountInfoStringRequest.new(property_id: property)).requested_value

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region SYMBOLS & MARKET INFO
      # ════════════════════════════════════════════════════════════════════════════

      # Count of symbols on the terminal. mode: true counts only Market-Watch symbols.
      def symbols_total(mode: false) = call(:market_info, :symbols_total, Mt5TermApi::SymbolsTotalRequest.new(mode: mode)).total

      # Does `symbol` exist on the server? Returns bool.
      def symbol_exist(symbol) = call(:market_info, :symbol_exist, Mt5TermApi::SymbolExistRequest.new(name: symbol)).exists

      # Name of the symbol at `index` (selected: true -> index within Market Watch).
      def symbol_name(index, selected: false) = call(:market_info, :symbol_name, Mt5TermApi::SymbolNameRequest.new(index: index, selected: selected)).name

      # Show/hide a symbol in Market Watch (required before some reads). Returns bool.
      def symbol_select(symbol, select = true) = call(:market_info, :symbol_select, Mt5TermApi::SymbolSelectRequest.new(symbol: symbol, select: select)).success

      # Has the terminal finished syncing `symbol`'s data? Returns bool.
      def symbol_is_synchronized(symbol) = call(:market_info, :symbol_is_synchronized, Mt5TermApi::SymbolIsSynchronizedRequest.new(symbol: symbol)).synchronized

      # One SYMBOL_* double property (e.g. :SYMBOL_POINT, :SYMBOL_VOLUME_MIN).
      def symbol_info_double(symbol, property) = call(:market_info, :symbol_info_double, Mt5TermApi::SymbolInfoDoubleRequest.new(symbol: symbol, type: property)).value

      # One SYMBOL_* integer property (e.g. :SYMBOL_DIGITS, :SYMBOL_TRADE_STOPS_LEVEL).
      def symbol_info_integer(symbol, property) = call(:market_info, :symbol_info_integer, Mt5TermApi::SymbolInfoIntegerRequest.new(symbol: symbol, type: property)).value

      # One SYMBOL_* string property (e.g. :SYMBOL_DESCRIPTION, :SYMBOL_CURRENCY_BASE).
      def symbol_info_string(symbol, property) = call(:market_info, :symbol_info_string, Mt5TermApi::SymbolInfoStringRequest.new(symbol: symbol, type: property)).value

      # Initial / maintenance margin rates for `symbol` at `order_type`
      # (SymbolInfoMarginRateData: initial_margin_rate, maintenance_margin_rate).
      # `order_type` is the MQL ENUM_ORDER_TYPE: pass :buy / :sell / :buy_limit / ...
      # (mapped to :ORDER_TYPE_BUY etc.) or the raw enum symbol.
      def symbol_info_margin_rate(symbol, order_type)
        ot = order_type.to_s.start_with?("ORDER_TYPE_") ? order_type : :"ORDER_TYPE_#{order_type.to_s.upcase}"
        call(:market_info, :symbol_info_margin_rate,
             Mt5TermApi::SymbolInfoMarginRateRequest.new(symbol: symbol, order_type: ot))
      end

      # Mt5TermApi::MrpcMqlTick: bid, ask, last, volume, time (unix s, broker tz),
      # time_utc, time_msc, flags. Prices come from here, not from SymbolParamsMany.
      def symbol_info_tick(symbol) = call(:market_info, :symbol_info_tick, Mt5TermApi::SymbolInfoTickRequest.new(symbol: symbol))

      # Quote session [from, to) for `symbol` on `day_of_week` (an ENUM_DAY_OF_WEEK
      # symbol), session index `session_index`. Returns SymbolInfoSessionQuoteData.
      def symbol_info_session_quote(symbol, day_of_week:, session_index: 0)
        call(:market_info, :symbol_info_session_quote,
             Mt5TermApi::SymbolInfoSessionQuoteRequest.new(symbol: symbol, day_of_week: day_of_week, session_index: session_index))
      end

      # Trade session [from, to) for `symbol` on `day_of_week`, session `session_index`.
      # Returns SymbolInfoSessionTradeData.
      def symbol_info_session_trade(symbol, day_of_week:, session_index: 0)
        call(:market_info, :symbol_info_session_trade,
             Mt5TermApi::SymbolInfoSessionTradeRequest.new(symbol: symbol, day_of_week: day_of_week, session_index: session_index))
      end

      # Names of all symbols known to the terminal.
      def symbol_list = call(:market_info, :symbol_list, Mt5TermApi::SymbolListRequest.new, timeout: 120).Symbols.to_a

      # All symbols' specs in ONE call (do not page: page_number does not advance).
      # Each entry is a Mt5TermApi::SymbolParameters (digits, point, volume_min/max/step,
      # trade_contract_size, trade_tick_size/value, trade_stops_level, filling_mode,
      # trade_mode, currency_base/profit/margin...).
      def symbol_params_many(sort: nil)
        req = Mt5TermApi::SymbolParamsManyRequest.new
        req.sort_type = sort if sort
        call(:account_helper, :symbol_params_many, req, timeout: 120).symbol_infos.to_a
      end

      # Tick value / tick size / contract size for one or more symbols (sizing).
      # Returns TickValueWithSizeData (symbol_tick_size_infos[]).
      def tick_value_with_size(symbols) = call(:account_helper, :tick_value_with_size, Mt5TermApi::TickValueWithSizeRequest.new(symbol_names: Array(symbols)))

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region MARKET DEPTH (DOM)
      # ════════════════════════════════════════════════════════════════════════════

      # Subscribe the terminal to `symbol`'s order book. Returns bool (opened_successfully).
      def market_book_add(symbol) = call(:market_info, :market_book_add, Mt5TermApi::MarketBookAddRequest.new(symbol: symbol)).opened_successfully

      # Unsubscribe from `symbol`'s order book. Returns bool (closed_successfully).
      def market_book_release(symbol) = call(:market_info, :market_book_release, Mt5TermApi::MarketBookReleaseRequest.new(symbol: symbol)).closed_successfully

      # Current order book for `symbol` (MarketBookGetData: mql_book_infos[]).
      # Call {#market_book_add} first.
      def market_book_get(symbol) = call(:market_info, :market_book_get, Mt5TermApi::MarketBookGetRequest.new(symbol: symbol))

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region PRICE HISTORY (BARS)
      # ════════════════════════════════════════════════════════════════════════════

      # Returns [Mt5TermApi::PriceBar] (time unix s broker tz, time_utc, open, high,
      # low, close, tick_volume, spread, real_volume), oldest first.
      # timeframe: :M1 .. :MN1 symbol, or the raw MQL5 ENUM_TIMEFRAMES int.
      # With from/to omitted the newest `max_bars` bars are returned.
      def price_history(symbol, timeframe: :M1, from_utc: nil, to_utc: nil, max_bars: 500)
        tf = timeframe.is_a?(Integer) ? timeframe : TIMEFRAMES.fetch(timeframe.to_sym)
        req = Mt5TermApi::PriceHistoryRequest.new(symbol: symbol, timeframe: tf, max_bars: max_bars)
        req.from_time_utc = from_utc.to_i if from_utc
        req.to_time_utc = to_utc.to_i if to_utc
        call(:market_info, :price_history, req, timeout: 120).bars.to_a
      end
      alias bars price_history

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region STREAMS
      # ════════════════════════════════════════════════════════════════════════════

      # Subscribe to ticks. Yields Mt5TermApi::MrpcSubscriptionMqlTick (symbol,
      # bid, ask, last, volume, time (Timestamp), time_msc, flags) on a background
      # thread. Returns a {Subscription}; call .cancel to unsubscribe cleanly.
      def on_symbol_tick(symbols, &block)
        req = Mt5TermApi::OnSymbolTickRequest.new(symbol_names: Array(symbols))
        stream(:subscriptions, :on_symbol_tick, req) { |reply| block.call(reply.data.symbol_tick) }
      end

      # Trade events (orders/positions changed). Yields Mt5TermApi::OnTradeData.
      def on_trade(&block) = stream(:subscriptions, :on_trade, Mt5TermApi::OnTradeRequest.new) { |r| block.call(r.data) }

      # Position P/L updates every `interval_ms`. Yields OnPositionProfitData.
      def on_position_profit(interval_ms: 1000, ignore_empty: true, &block)
        req = Mt5TermApi::OnPositionProfitRequest.new(timer_period_milliseconds: interval_ms, ignore_empty_data: ignore_empty)
        stream(:subscriptions, :on_position_profit, req) { |r| block.call(r.data) }
      end

      # Snapshots of open position & pending-order tickets every `interval_ms`.
      # Yields OnPositionsAndPendingOrdersTicketsData.
      def on_positions_and_pending_orders_tickets(interval_ms: 1000, &block)
        req = Mt5TermApi::OnPositionsAndPendingOrdersTicketsRequest.new(timer_period_milliseconds: interval_ms)
        stream(:subscriptions, :on_positions_and_pending_orders_tickets, req) { |r| block.call(r.data) }
      end

      # Low-level MT5 trade-transaction events. Yields OnTradeTransactionData.
      def on_trade_transaction(&block) = stream(:subscriptions, :on_trade_transaction, Mt5TermApi::OnTradeTransactionRequest.new) { |r| block.call(r.data) }

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region TRADING
      # ════════════════════════════════════════════════════════════════════════════

      # Market or pending order. type: :buy/:sell/:buy_limit/... or a
      # Mt5TermApi::TMT5_ENUM_ORDER_TYPE symbol. magic -> expert_id.
      # Returns Mt5TermApi::OrderSendData (returned_code 10009 = TRADE_RETCODE_DONE,
      # order, deal, price, volume, returned_string_code, returned_code_description).
      def order_send(symbol:, type:, volume:, price: nil, stop_loss: nil, take_profit: nil, comment: nil,
                     magic: nil, slippage: nil, stop_limit_price: nil, expiration_type: nil, expiration_utc: nil,
                     quotes_wait_ms: nil, without_checks: false)
        req = Mt5TermApi::OrderSendRequest.new(symbol: symbol, operation: ORDER_TYPES.fetch(type.to_sym, type), volume: volume)
        req.price = price if price
        req.stop_loss = stop_loss if stop_loss
        req.take_profit = take_profit if take_profit
        req.comment = comment if comment
        req.expert_id = magic if magic
        req.slippage = slippage if slippage
        req.stop_limit_price = stop_limit_price if stop_limit_price
        req.expiration_time_type = expiration_type if expiration_type
        req.expiration_time_utc = ts(expiration_utc) if expiration_utc
        req.quotes_wait_ms = quotes_wait_ms if quotes_wait_ms
        trade_call(without_checks ? "OrderSendWithoutChecks" : "OrderSend",
                   without_checks ? :order_send_without_checks : :order_send, req, timeout: 120)
      end

      # Modify SL/TP of a position, or price/SL/TP/expiration of a pending order.
      # Returns Mt5TermApi::OrderModifyData (returned_code 10009 on success).
      def order_modify(ticket:, stop_loss: nil, take_profit: nil, price: nil, stop_limit: nil, expiration_type: nil, expiration_utc: nil)
        req = Mt5TermApi::OrderModifyRequest.new(ticket: ticket)
        req.stop_loss = stop_loss if stop_loss
        req.take_profit = take_profit if take_profit
        req.price = price if price
        req.stop_limit = stop_limit if stop_limit
        req.expiration_time_type = expiration_type if expiration_type
        req.expiration_time_utc = ts(expiration_utc) if expiration_utc
        trade_call("OrderModify", :order_modify, req, timeout: 120)
      end

      # Close a position (volume 0/nil = full close) or delete a pending order.
      # Returns Mt5TermApi::OrderCloseData (returned_code 10009, close_mode).
      def order_close(ticket:, volume: nil, slippage: 10)
        req = Mt5TermApi::OrderCloseRequest.new(ticket: ticket, volume: volume.to_f, slippage: slippage)
        trade_call("OrderClose", :order_close, req, timeout: 120)
      end

      # Validate a trade request without sending it (OrderCheckData: margin, free
      # margin, retcode). `request` is a Mt5TermApi::MqlTradeRequest.
      def order_check(request) = call(:trade_functions, :order_check, Mt5TermApi::OrderCheckRequest.new(mql_trade_request: request))

      # Margin required to open `volume` lots of `symbol` at `price` (type :buy/:sell).
      def order_calc_margin(symbol:, type:, volume:, price:) = call(:trade_functions, :order_calc_margin, Mt5TermApi::OrderCalcMarginRequest.new(order_type: TF_ORDER_TYPES.fetch(type.to_sym, type), symbol: symbol, volume: volume, open_price: price)).margin

      # Profit of `volume` lots of `symbol` moving from `open_price` to `close_price`
      # (type :buy/:sell). Returns the profit in the account currency.
      def order_calc_profit(symbol:, type:, volume:, open_price:, close_price:) = call(:trade_functions, :order_calc_profit, Mt5TermApi::OrderCalcProfitRequest.new(order_type: TF_ORDER_TYPES.fetch(type.to_sym, type), symbol: symbol, volume: volume, open_price: open_price, close_price: close_price)).profit

      # Number of open positions on the account.
      def positions_total = call(:trade_functions, :positions_total, Google::Protobuf::Empty.new).total_positions

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region OPENED ORDERS & HISTORY
      # ════════════════════════════════════════════════════════════════════════════

      # Open positions and pending orders (Mt5TermApi::OpenedOrdersData:
      # position_infos[] (PositionInfo: ticket, symbol, type, volume, price_open,
      # stop_loss, take_profit, profit, magic_number, comment) and opened_orders[]).
      def opened_orders(sort: :BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC) = call(:account_helper, :opened_orders, Mt5TermApi::OpenedOrdersRequest.new(inputSortMode: sort))

      # Just the tickets of open positions and pending orders, cheaply
      # (OpenedOrdersTicketsData: opened_position_tickets[], opened_orders_tickets[]).
      def opened_orders_tickets = call(:account_helper, :opened_orders_tickets, Mt5TermApi::OpenedOrdersTicketsRequest.new)

      # Closed orders+deals between two UTC Times. Returns [Mt5TermApi::HistoryData]
      # each with history_order (OrderHistoryData) and history_deal (DealHistoryData).
      def order_history(from_utc:, to_utc: Time.now.utc, sort: :BMT5_SORT_BY_CLOSE_TIME_ASC, page_size: 500)
        req = Mt5TermApi::OrderHistoryRequest.new(inputFromUtc: ts(from_utc), inputToUtc: ts(to_utc), inputSortMode: sort, page_size: page_size)
        out = []
        loop do
          data = call(:account_helper, :order_history, req, timeout: 120)
          out.concat(data.history_data.to_a)
          break if data.next_page_token.to_s.empty?
          req.page_token = data.next_page_token
        end
        out
      end

      # Closed positions (one row per round-trip: open/close price, profit, magic).
      def positions_history(from_utc:, to_utc: Time.now.utc, sort: :AH_POSITION_OPEN_TIME_ASC, page_size: 500)
        req = Mt5TermApi::PositionsHistoryRequest.new(sort_type: sort, position_open_time_from_utc: ts(from_utc), position_open_time_to_utc: ts(to_utc), page_size: page_size)
        out = []
        loop do
          data = call(:account_helper, :positions_history, req, timeout: 120)
          out.concat(data.history_positions.to_a)
          break if data.next_page_token.to_s.empty?
          req.page_token = data.next_page_token
        end
        out
      end

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region INTERNALS
      # ════════════════════════════════════════════════════════════════════════════
      private

      # Coerce a Time / unix int into a protobuf Timestamp (passes one through).
      def ts(t)
        return t if t.is_a?(Google::Protobuf::Timestamp)
        Google::Protobuf::Timestamp.new(seconds: t.to_i, nanos: 0)
      end

      # Memoized service stub for `name`.
      def stub(name)
        @stubs[name] ||= begin
          klass = {
            connection: Mt5TermApi::Connection::Stub,
            account_helper: Mt5TermApi::AccountHelper::Stub,
            account_information: Mt5TermApi::AccountInformation::Stub,
            market_info: Mt5TermApi::MarketInfo::Stub,
            subscriptions: Mt5TermApi::SubscriptionService::Stub,
            trade_functions: Mt5TermApi::TradeFunctions::Stub,
            trading_helper: Mt5TermApi::TradingHelper::Stub,
            trade_stats: Mt5TermApi::TradeStats::Stub
          }.fetch(name)
          klass.new(target, @creds, channel_args: @channel_args)
        end
      end

      # Unary call: sends metadata, unwraps the data/error oneof.
      def call(service, rpc, request, timeout: @timeout)
        reply = stub(service).public_send(rpc, request, metadata: metadata, deadline: Time.now + timeout)
        unwrap(reply, rpc)
      end

      # A trade call: sent exactly once, never re-sent. A transport failure after which the trade may have been
      # executed is raised as the same GRPC::BadStatus, marked TradeOutcomeUnknown.
      def trade_call(operation, rpc, request, timeout:)
        call(:trading_helper, rpc, request, timeout: timeout)
      rescue GRPC::BadStatus => e
        TradeOutcomeUnknown.mark(e, operation) if TradeOutcomeUnknown.applies?(e)
        raise
      end

      # Unwrap a reply's data/error into the data message: raise ApiError on an error.
      # Handles both shapes the gateway uses: a `response` oneof (most replies) and
      # plain `data` / `error` fields with no oneof (e.g. TickValueWithSizeReply).
      def unwrap(reply, rpc)
        if reply.respond_to?(:response)
          case reply.response
          when :error then raise ApiError.new(reply.error, rpc)
          when :data then return reply.data
          end
        elsif reply.respond_to?(:data) || reply.respond_to?(:error)
          raise ApiError.new(reply.error, rpc) if reply.respond_to?(:error) && reply.error
          return reply.data if reply.respond_to?(:data)
        end
        reply
      end

      # Server-streaming call on a background thread; yields each reply.
      def stream(service, rpc, request)
        op = stub(service).public_send(rpc, request, metadata: metadata, return_op: true)
        sub = Subscription.new(op)
        sub.thread = Thread.new do
          begin
            op.execute.each do |reply|
              raise ApiError.new(reply.error, rpc) if reply.respond_to?(:response) && reply.response == :error
              sub.bump!
              yield reply
            end
          rescue GRPC::Cancelled
            # expected on cancel
          rescue StandardError => e
            sub.error = e
          end
        end
        sub.thread.report_on_exception = false
        sub
      end

      #endregion
    end
  end
end
