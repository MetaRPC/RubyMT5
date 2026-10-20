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

module MetaRPC
  module MT5
    # Raised when the gateway answers with the `error` branch of a reply oneof
    # (MQL error, validation error, terminal timeout, ...).
    class ApiError < StandardError
      attr_reader :error

      def initialize(error, rpc_name = nil)
        @error = error
        super("#{rpc_name}: #{error.error_code} #{error.error_message} " \
              "(type=#{error.type} mql=#{error.mql_error_code}/#{error.mql_error_int_code} " \
              "#{error.mql_error_description} trade=#{error.mql_error_trade_code}/#{error.mql_error_trade_int_code} " \
              "#{error.mql_error_trade_description})".strip)
      end

      def code = error.error_code
    end

    # Raised by connect when the broker rejects the login. Never retry this.
    class InvalidLoginError < ApiError; end

    # Thin, honest wrapper over the MetaRPC MT5 gRPC gateway.
    #
    #   acct = MetaRPC::MT5::Client.new(api_key: ENV["MRPC_API_KEY"], id: stable_uuid)
    #   acct.connect(498489, "pwd", server: "ICMCapitalLtd-Demo", name: "my-bot")
    #   s = acct.account_summary          # Mt5TermApi::AccountSummaryData
    #   t = acct.symbol_info_tick("EURUSD")
    #   r = acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.01, magic: 600001, comment: "S001")
    #
    # Every RPC returns the `data` message of the reply (never the reply wrapper)
    # and raises ApiError when the reply carries an error, GRPC::BadStatus on
    # transport / gateway failures.
    class Client
      DEFAULT_HOST = "mt5.mrpc.pro"
      DEFAULT_PORT = 443

      # MQL5 ENUM_TIMEFRAMES values accepted by price_history.
      TIMEFRAMES = {
        M1: 1, M2: 2, M3: 3, M4: 4, M5: 5, M6: 6, M10: 10, M12: 12, M15: 15, M20: 20, M30: 30,
        H1: 16385, H2: 16386, H3: 16387, H4: 16388, H6: 16390, H8: 16392, H12: 16396,
        D1: 16408, W1: 32769, MN1: 49153
      }.freeze

      ORDER_TYPES = {
        buy: :TMT5_ORDER_TYPE_BUY, sell: :TMT5_ORDER_TYPE_SELL,
        buy_limit: :TMT5_ORDER_TYPE_BUY_LIMIT, sell_limit: :TMT5_ORDER_TYPE_SELL_LIMIT,
        buy_stop: :TMT5_ORDER_TYPE_BUY_STOP, sell_stop: :TMT5_ORDER_TYPE_SELL_STOP,
        buy_stop_limit: :TMT5_ORDER_TYPE_BUY_STOP_LIMIT, sell_stop_limit: :TMT5_ORDER_TYPE_SELL_STOP_LIMIT
      }.freeze

      TF_ORDER_TYPES = {
        buy: :ORDER_TYPE_TF_BUY, sell: :ORDER_TYPE_TF_SELL, buy_limit: :ORDER_TYPE_TF_BUY_LIMIT, sell_limit: :ORDER_TYPE_TF_SELL_LIMIT,
        buy_stop: :ORDER_TYPE_TF_BUY_STOP, sell_stop: :ORDER_TYPE_TF_SELL_STOP
      }.freeze

      attr_reader :host, :port, :api_key, :id, :login, :server, :name, :last_disconnect_deleted, :server_guid
      attr_accessor :timeout

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
      #   Client.uuid5(Client::NAMESPACE_DNS, "fleet-audit-RubyMT5")
      NAMESPACE_DNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8".freeze
      def self.uuid5(namespace, name)
        ns = [namespace.delete("-")].pack("H*")
        h = Digest::SHA1.digest(ns + name).bytes[0, 16]
        h[6] = (h[6] & 0x0f) | 0x50
        h[8] = (h[8] & 0x3f) | 0x80
        hex = h.pack("C*").unpack1("H*")
        "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
      end

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

      def target = "#{@host}:#{@port}"

      def connected? = @connected

      # gRPC metadata attached to every call: APIKey + terminal id.
      def metadata
        md = { "apikey" => @api_key }
        md["id"] = @id if @id
        md
      end

      # ---------------------------------------------------------------- connection

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

      def check_connect = call(:connection, :check_connect, Mt5TermApi::CheckConnectRequest.new)
      def connection_status = call(:connection, :connection_status, Mt5TermApi::ConnectionStatusRequest.new)
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

      # ------------------------------------------------------------------- account

      # Mt5TermApi::AccountSummaryData: account_login, account_balance,
      # account_equity, account_currency, account_leverage, account_trade_mode
      # (:MRPC_ACCOUNT_TRADE_MODE_DEMO / _CONTEST / _REAL), account_company_name,
      # server_time (Timestamp, broker tz), server_time_utc.
      def account_summary = call(:account_helper, :account_summary, Mt5TermApi::AccountSummaryRequest.new)

      def demo? = account_summary.account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO

      def account_info_double(property) = call(:account_information, :account_info_double, Mt5TermApi::AccountInfoDoubleRequest.new(property_id: property)).requested_value
      def account_info_integer(property) = call(:account_information, :account_info_integer, Mt5TermApi::AccountInfoIntegerRequest.new(property_id: property)).requested_value
      def account_info_string(property) = call(:account_information, :account_info_string, Mt5TermApi::AccountInfoStringRequest.new(property_id: property)).requested_value

      # ------------------------------------------------------------------- symbols

      def symbol_select(symbol, select = true) = call(:market_info, :symbol_select, Mt5TermApi::SymbolSelectRequest.new(symbol: symbol, select: select)).success
      def symbol_exist(symbol) = call(:market_info, :symbol_exist, Mt5TermApi::SymbolExistRequest.new(name: symbol)).exists
      def symbol_is_synchronized(symbol) = call(:market_info, :symbol_is_synchronized, Mt5TermApi::SymbolIsSynchronizedRequest.new(symbol: symbol)).synchronized

      # Mt5TermApi::MrpcMqlTick: bid, ask, last, volume, time (unix s, broker tz),
      # time_utc, time_msc, flags. Prices come from here, not from SymbolParamsMany.
      def symbol_info_tick(symbol) = call(:market_info, :symbol_info_tick, Mt5TermApi::SymbolInfoTickRequest.new(symbol: symbol))

      def symbol_info_double(symbol, property) = call(:market_info, :symbol_info_double, Mt5TermApi::SymbolInfoDoubleRequest.new(symbol: symbol, type: property)).value
      def symbol_info_integer(symbol, property) = call(:market_info, :symbol_info_integer, Mt5TermApi::SymbolInfoIntegerRequest.new(symbol: symbol, type: property)).value
      def symbol_info_string(symbol, property) = call(:market_info, :symbol_info_string, Mt5TermApi::SymbolInfoStringRequest.new(symbol: symbol, type: property)).value

      # Names of all symbols known to the terminal.
      def symbol_list = call(:market_info, :symbol_list, Mt5TermApi::SymbolListRequest.new, timeout: 120).Symbols.to_a

      # Full spec of one symbol (Mt5TermApi::SymbolParameters: digits, point,
      # volume_min/max/step, trade_contract_size, trade_tick_size/value,
      # trade_stops_level, filling_mode, trade_mode, currency_base/profit/margin...).
      # nil when the symbol does not exist.
      def symbol_params(symbol)
        data = call(:account_helper, :symbol_params_many, Mt5TermApi::SymbolParamsManyRequest.new(symbol_name: symbol))
        data.symbol_infos.find { |s| s.name == symbol }
      end

      # All symbols' specs in ONE call (do not page: page_number does not advance).
      def symbol_params_many(sort: nil)
        req = Mt5TermApi::SymbolParamsManyRequest.new
        req.sort_type = sort if sort
        call(:account_helper, :symbol_params_many, req, timeout: 120).symbol_infos.to_a
      end

      # -------------------------------------------------------------------- bars

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

      # ------------------------------------------------------------------ streams

      # Handle for a running server-stream. #cancel stops it; #join waits.
      class Subscription
        attr_reader :count
        attr_accessor :error, :thread

        def initialize(op)
          @op = op
          @count = 0
        end

        # Cancel the stream and wait for the reader thread to finish.
        def cancel
          @op.cancel
          @thread&.join(5)
        end

        def join(limit = nil) = @thread.join(limit)
        def alive? = @thread&.alive? || false
        def bump! = @count += 1
      end

      # Subscribe to ticks. Yields Mt5TermApi::MrpcSubscriptionMqlTick (symbol,
      # bid, ask, last, volume, time (Timestamp), time_msc, flags) on a background
      # thread. Returns a Subscription; call .cancel to unsubscribe cleanly.
      def on_symbol_tick(symbols, &block)
        req = Mt5TermApi::OnSymbolTickRequest.new(symbol_names: Array(symbols))
        stream(:subscriptions, :on_symbol_tick, req) { |reply| block.call(reply.data.symbol_tick) }
      end
      alias subscribe_ticks on_symbol_tick

      # Trade events (orders/positions changed). Yields Mt5TermApi::OnTradeData.
      def on_trade(&block) = stream(:subscriptions, :on_trade, Mt5TermApi::OnTradeRequest.new) { |r| block.call(r.data) }

      # Position P/L updates every `interval_ms`. Yields OnPositionProfitData.
      def on_position_profit(interval_ms: 1000, ignore_empty: true, &block)
        req = Mt5TermApi::OnPositionProfitRequest.new(timer_period_milliseconds: interval_ms, ignore_empty_data: ignore_empty)
        stream(:subscriptions, :on_position_profit, req) { |r| block.call(r.data) }
      end

      # Blocking variant: iterate ticks for `seconds`, then return the count.
      def each_tick(symbols, seconds:, &block)
        n = 0
        sub = on_symbol_tick(symbols) { |t| n += 1; block&.call(t) }
        sleep seconds
        sub.cancel
        raise sub.error if sub.error && !sub.error.is_a?(GRPC::Cancelled)
        n
      end

      # ------------------------------------------------------------------- trading

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
        call(:trading_helper, without_checks ? :order_send_without_checks : :order_send, req, timeout: 120)
      end

      def buy(symbol, volume, **kw) = order_send(symbol: symbol, type: :buy, volume: volume, **kw)
      def sell(symbol, volume, **kw) = order_send(symbol: symbol, type: :sell, volume: volume, **kw)

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
        call(:trading_helper, :order_modify, req, timeout: 120)
      end

      # Close a position (volume 0/nil = full close) or delete a pending order.
      # Returns Mt5TermApi::OrderCloseData (returned_code 10009, close_mode).
      def order_close(ticket:, volume: nil, slippage: 10)
        req = Mt5TermApi::OrderCloseRequest.new(ticket: ticket, volume: volume.to_f, slippage: slippage)
        call(:trading_helper, :order_close, req, timeout: 120)
      end

      def order_check(request) = call(:trade_functions, :order_check, Mt5TermApi::OrderCheckRequest.new(mql_trade_request: request))
      def order_calc_margin(symbol:, type:, volume:, price:) = call(:trade_functions, :order_calc_margin, Mt5TermApi::OrderCalcMarginRequest.new(order_type: TF_ORDER_TYPES.fetch(type.to_sym, type), symbol: symbol, volume: volume, open_price: price)).margin
      def positions_total = call(:trade_functions, :positions_total, Google::Protobuf::Empty.new).total_positions

      # Open positions and pending orders (Mt5TermApi::OpenedOrdersData:
      # position_infos[] (PositionInfo: ticket, symbol, type, volume, price_open,
      # stop_loss, take_profit, profit, magic_number, comment) and opened_orders[]).
      def opened_orders(sort: :BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC) = call(:account_helper, :opened_orders, Mt5TermApi::OpenedOrdersRequest.new(inputSortMode: sort))

      # Open positions, optionally filtered by magic and/or symbol.
      def positions(magic: nil, symbol: nil)
        opened_orders.position_infos.select { |p| (magic.nil? || p.magic_number == magic) && (symbol.nil? || p.symbol == symbol) }
      end

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

      # ----------------------------------------------------------------- internals

      def ts(t)
        return t if t.is_a?(Google::Protobuf::Timestamp)
        Google::Protobuf::Timestamp.new(seconds: t.to_i, nanos: 0)
      end

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

      def unwrap(reply, rpc)
        return reply unless reply.respond_to?(:response)
        case reply.response
        when :error then raise ApiError.new(reply.error, rpc)
        when :data then reply.data
        else reply
        end
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
    end

    Account = Client
  end
end
