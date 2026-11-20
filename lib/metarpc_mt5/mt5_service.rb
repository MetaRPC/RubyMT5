# ══════════════════════════════════════════════════════════════════════════════
# MT5Service — Mid-Level MetaTrader 5 Typed Facade
# ══════════════════════════════════════════════════════════════════════════════
#
# The mid layer of the three-layer stack:
#     MT5Account  →  MT5Service (this file)  →  MT5Sugar
#
# Wraps an MT5Account and hands you plain Ruby objects (Structs) and plain
# arguments instead of generated protobuf messages. Reads that span pages
# (history) come back as ready arrays. The raw client is one hop away via #account.
#
# Returns tidy Structs: Quote(symbol, bid, ask, last, spread, time_utc) and
# Account(login, balance, equity, currency, leverage, trade_mode, company, server_time_utc).
#
# METHOD GROUPS:
# ──────────────────────────────────────────────────────────────────────────────
#
# 1. CONNECTION (6 methods)
#    • connect                - Connect by broker server (cluster) name
#    • connect_by_host        - Connect by raw broker host:port
#    • connect_proxy          - Connect through a proxy
#    • connected?             - Connection status
#    • reconnect              - Re-establish the broker connection
#    • disconnect             - Stop the terminal
#
# 2. ACCOUNT (6 methods)
#    • account_info           - Typed Account snapshot (Struct)
#    • account_summary        - Raw AccountSummaryData (every field)
#    • demo?                  - Is this a demo account?
#    • account_info_double    - One ACCOUNT_* double property
#    • account_info_integer   - One ACCOUNT_* integer property
#    • account_info_string    - One ACCOUNT_* string property
#
# 3. SYMBOLS & MARKET INFO (14 methods)
#    • quote                  - Typed best bid/ask (Quote struct)
#    • tick                   - Raw MrpcMqlTick
#    • symbols                - Names of all symbols
#    • symbols_total          - Count of symbols
#    • symbol_name            - Symbol name by index
#    • symbol_exist?          - Does a symbol exist?
#    • symbol_synchronized?   - Is the symbol synced?
#    • select_symbol          - Add / remove from Market Watch
#    • symbol_params          - Full spec of one symbol
#    • symbol_params_all      - Full spec of every symbol
#    • margin_rate            - Initial / maintenance margin rates
#    • tick_value_with_size   - Tick value / size / contract size
#    • session_quote          - Quote session times for a weekday
#    • session_trade          - Trade session times for a weekday
#
# 4. MARKET DEPTH / DOM (3 methods)
#    • book_add               - Subscribe to the order book
#    • book_release           - Unsubscribe from the order book
#    • book                   - Order-book snapshot
#
# 5. BARS (1 method)
#    • bars                   - OHLC bars (oldest first)
#
# 6. STREAMS (6 methods)
#    • subscribe_ticks        - Stream ticks
#    • on_trade               - Stream trade events
#    • on_position_profit     - Stream position P/L updates
#    • on_tickets             - Stream ticket snapshots
#    • on_trade_transaction   - Stream trade transactions
#    • each_tick              - Blocking: iterate ticks for N seconds
#
# 7. TRADING (6 methods)
#    • order_send             - Market or pending order
#    • order_modify           - Modify SL / TP / price / expiration
#    • order_close            - Close or delete by ticket
#    • order_check            - Validate a trade request
#    • order_calc_margin      - Margin for an order
#    • order_calc_profit      - Profit for a round-trip
#
# 8. POSITIONS & HISTORY (6 methods)
#    • positions_total        - Count of open positions
#    • opened_orders          - Open positions & pending orders (full)
#    • opened_tickets         - Only the tickets (lightweight)
#    • positions              - Open positions (filter by magic / symbol)
#    • order_history          - Historical orders + deals
#    • positions_history      - Historical positions / round-trips
#
# ══════════════════════════════════════════════════════════════════════════════

require_relative "mt5_account"

module MetaRPC
  module MT5
    # MID-LEVEL layer — a typed facade over {MT5Account}.
    #
    # It wraps an MT5Account and hands you plain Ruby objects (Structs) and plain
    # arguments instead of generated protobuf messages: quotes become a {Quote}
    # struct, the account summary an {Account} struct, and reads that span pages
    # (history) come back as ready arrays. Every low-level method is still one hop
    # away via {#account}.
    #
    #   svc = MetaRPC::MT5::MT5Service.new(api_key: ENV["MRPC_API_KEY"])
    #   svc.connect(498489, "pwd", server: "ICMarkets-Demo")
    #   svc.account_info.balance        # => 10000.0
    #   q = svc.quote("EURUSD")         # Quote(bid:, ask:, last:, spread:, time_utc:)
    #   svc.positions(magic: 600001)    # [Mt5TermApi::PositionInfo]
    class MT5Service
      # Tidy, read-only snapshots returned by the typed reads.
      Quote   = Struct.new(:symbol, :bid, :ask, :last, :spread, :time_utc, keyword_init: true)
      Account = Struct.new(:login, :balance, :equity, :currency, :leverage, :trade_mode,
                           :company, :server_time_utc, keyword_init: true)

      attr_reader :account

      # Wrap an existing MT5Account, or build one from the same arguments.
      #
      #   MT5Service.new(existing_account)
      #   MT5Service.new(api_key: "...", id: "...")
      def initialize(account = nil, **opts)
        @account = account.is_a?(MT5Account) ? account : MT5Account.new(**opts)
      end

      # ════════════════════════════════════════════════════════════════════════════
      #region CONNECTION
      # ════════════════════════════════════════════════════════════════════════════

      # Connect by broker server (cluster) name.
      def connect(login, password, server:, **opts) = @account.connect(login, password, server: server, **opts)
      # Connect by raw broker host:port.
      def connect_by_host(login, password, host:, port:, **opts) = @account.connect_by_host(login, password, host: host, port: port, **opts)
      # Connect through a proxy.
      def connect_proxy(login, password, **opts) = @account.connect_proxy(login, password, **opts)
      # True once connected.
      def connected? = @account.connected?
      # Re-establish the terminal's broker connection.
      def reconnect(force: false) = @account.reconnect(force: force)
      # Stop the terminal (delete: true also removes it from the account list).
      def disconnect(delete: false, reason: nil) = @account.disconnect(delete: delete, reason: reason)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region ACCOUNT
      # ════════════════════════════════════════════════════════════════════════════

      # Typed snapshot of the account.
      def account_info
        s = @account.account_summary
        Account.new(login: s.account_login, balance: s.account_balance, equity: s.account_equity,
                    currency: s.account_currency, leverage: s.account_leverage,
                    trade_mode: s.account_trade_mode, company: s.account_company_name,
                    server_time_utc: s.server_time_utc)
      end

      # Raw AccountSummaryData (every field), when you need more than {#account_info}.
      def account_summary = @account.account_summary

      # True when the account is a demo account.
      def demo? = @account.account_summary.account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO

      # One ACCOUNT_* double / integer / string property.
      def account_info_double(property)  = @account.account_info_double(property)
      def account_info_integer(property) = @account.account_info_integer(property)
      def account_info_string(property)  = @account.account_info_string(property)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region SYMBOLS & MARKET INFO
      # ════════════════════════════════════════════════════════════════════════════

      # Typed best bid/ask snapshot for a symbol.
      def quote(symbol)
        t = @account.symbol_info_tick(symbol)
        Quote.new(symbol: symbol, bid: t.bid, ask: t.ask, last: t.last,
                  spread: (t.ask - t.bid), time_utc: t.time_utc)
      end

      # Raw MrpcMqlTick (bid, ask, last, volume, time, flags).
      def tick(symbol) = @account.symbol_info_tick(symbol)

      # Names of all symbols.
      def symbols = @account.symbol_list
      # Count of symbols (market_watch_only: only Market-Watch symbols).
      def symbols_total(market_watch_only: false) = @account.symbols_total(mode: market_watch_only)
      # Symbol name at an index.
      def symbol_name(index, selected: false) = @account.symbol_name(index, selected: selected)
      # Does the symbol exist?
      def symbol_exist?(symbol) = @account.symbol_exist(symbol)
      # Has the terminal finished syncing the symbol?
      def symbol_synchronized?(symbol) = @account.symbol_is_synchronized(symbol)
      # Show/hide a symbol in Market Watch.
      def select_symbol(symbol, select = true) = @account.symbol_select(symbol, select)

      # Full spec of one symbol (Mt5TermApi::SymbolParameters), or nil if unknown.
      def symbol_params(symbol)
        @account.symbol_params_many.find { |s| s.name == symbol }
      end

      # Every symbol's spec in one call.
      def symbol_params_all(sort: nil) = @account.symbol_params_many(sort: sort)

      # Initial/maintenance margin rates for a symbol at an order type.
      def margin_rate(symbol, type) = @account.symbol_info_margin_rate(symbol, type)
      # Tick value / size / contract size for sizing.
      def tick_value_with_size(symbols) = @account.tick_value_with_size(symbols)
      # Quote / trade session [from, to) for a symbol on a weekday.
      def session_quote(symbol, day_of_week:, session_index: 0) = @account.symbol_info_session_quote(symbol, day_of_week: day_of_week, session_index: session_index)
      def session_trade(symbol, day_of_week:, session_index: 0) = @account.symbol_info_session_trade(symbol, day_of_week: day_of_week, session_index: session_index)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region MARKET DEPTH (DOM)
      # ════════════════════════════════════════════════════════════════════════════

      # Subscribe to a symbol's order book (returns bool).
      def book_add(symbol) = @account.market_book_add(symbol)
      # Unsubscribe from a symbol's order book (returns bool).
      def book_release(symbol) = @account.market_book_release(symbol)
      # Current order book for a symbol (call {#book_add} first).
      def book(symbol) = @account.market_book_get(symbol)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region BARS
      # ════════════════════════════════════════════════════════════════════════════

      # Price bars (Mt5TermApi::PriceBar[]), oldest first.
      def bars(symbol, timeframe: :M1, from_utc: nil, to_utc: nil, max_bars: 500)
        @account.price_history(symbol, timeframe: timeframe, from_utc: from_utc, to_utc: to_utc, max_bars: max_bars)
      end

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region STREAMS
      # ════════════════════════════════════════════════════════════════════════════

      # Tick stream (returns a Subscription).
      def subscribe_ticks(symbols, &block) = @account.on_symbol_tick(symbols, &block)
      # Trade-event stream.
      def on_trade(&block) = @account.on_trade(&block)
      # Position P/L stream.
      def on_position_profit(interval_ms: 1000, ignore_empty: true, &block) = @account.on_position_profit(interval_ms: interval_ms, ignore_empty: ignore_empty, &block)
      # Position/pending-order ticket snapshots stream.
      def on_tickets(interval_ms: 1000, &block) = @account.on_positions_and_pending_orders_tickets(interval_ms: interval_ms, &block)
      # Low-level trade-transaction stream.
      def on_trade_transaction(&block) = @account.on_trade_transaction(&block)

      # Blocking variant: iterate ticks for `seconds`, then return the count.
      def each_tick(symbols, seconds:, &block)
        n = 0
        sub = @account.on_symbol_tick(symbols) { |t| n += 1; block&.call(t) }
        sleep seconds
        sub.cancel
        raise sub.error if sub.error && !sub.error.is_a?(GRPC::Cancelled)
        n
      end

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region TRADING
      # ════════════════════════════════════════════════════════════════════════════

      # Market or pending order (type: :buy/:sell/:buy_limit/...). Returns OrderSendData.
      def order_send(symbol:, type:, volume:, **opts) = @account.order_send(symbol: symbol, type: type, volume: volume, **opts)
      def order_modify(ticket:, **opts) = @account.order_modify(ticket: ticket, **opts)
      def order_close(ticket:, volume: nil, slippage: 10) = @account.order_close(ticket: ticket, volume: volume, slippage: slippage)
      def order_check(request) = @account.order_check(request)
      # Margin / profit calculators.
      def order_calc_margin(symbol:, type:, volume:, price:) = @account.order_calc_margin(symbol: symbol, type: type, volume: volume, price: price)
      def order_calc_profit(symbol:, type:, volume:, open_price:, close_price:) = @account.order_calc_profit(symbol: symbol, type: type, volume: volume, open_price: open_price, close_price: close_price)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region POSITIONS & HISTORY
      # ════════════════════════════════════════════════════════════════════════════

      # Count of open positions.
      def positions_total = @account.positions_total

      # Open positions and pending orders (OpenedOrdersData).
      def opened_orders(sort: :BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC) = @account.opened_orders(sort: sort)

      # Just the tickets of open positions and pending orders.
      def opened_tickets = @account.opened_orders_tickets

      # Open positions, optionally filtered by magic and/or symbol.
      def positions(magic: nil, symbol: nil)
        opened_orders.position_infos.select do |p|
          (magic.nil? || p.magic_number == magic) && (symbol.nil? || p.symbol == symbol)
        end
      end

      # Closed orders+deals between two UTC Times ([Mt5TermApi::HistoryData]).
      def order_history(from_utc:, to_utc: Time.now.utc, sort: :BMT5_SORT_BY_CLOSE_TIME_ASC, page_size: 500)
        @account.order_history(from_utc: from_utc, to_utc: to_utc, sort: sort, page_size: page_size)
      end

      # Closed positions (one row per round-trip).
      def positions_history(from_utc:, to_utc: Time.now.utc, sort: :AH_POSITION_OPEN_TIME_ASC, page_size: 500)
        @account.positions_history(from_utc: from_utc, to_utc: to_utc, sort: sort, page_size: page_size)
      end

      #endregion
    end
  end
end
