# ══════════════════════════════════════════════════════════════════════════════
# MT5Sugar — High-Level MetaTrader 5 One-Liners
# ══════════════════════════════════════════════════════════════════════════════
#
# The top layer of the three-layer stack:
#     MT5Account  →  MT5Service  →  MT5Sugar (this file)
#
# One-liners with smart defaults: connect, read money and prices, trade, and size
# positions. Wraps an MT5Service (which wraps an MT5Account); reach the layers
# below with #service and #account.
#
#     mt5 = MetaRPC::MT5::MT5Sugar.create(api_key: ENV["MRPC_API_KEY"])
#     mt5.connect(498489, "pwd", server: "ICMarkets-Demo")
#     mt5.bid("EURUSD"); t = mt5.buy_market("EURUSD", 0.01); mt5.close_position(t.order)
#
# METHOD GROUPS:
# ──────────────────────────────────────────────────────────────────────────────
#
# 1. CONSTRUCTION (3 methods)
#    • create                 - Build the whole stack (Sugar → Service → Account)
#    • account                - The raw MT5Account underneath
#    • service                - The MT5Service underneath
#
# 2. CONNECTION (6 methods)
#    • connect                - Connect by broker server name (keyword server:)
#    • connect_by_host        - Connect by raw broker host:port
#    • quick_connect          - Positional-server shorthand
#    • connected?             - Connection status
#    • reconnect              - Re-establish the broker connection
#    • disconnect             - Stop the terminal
#
# 3. MONEY — reads (9 methods)
#    • balance                - Account balance
#    • equity                 - Account equity
#    • margin                 - Used margin
#    • free_margin            - Free margin
#    • margin_level           - Margin level %
#    • profit                 - Floating P/L
#    • account_info           - Typed Account snapshot
#    • account_summary        - Raw AccountSummaryData
#    • demo?                  - Is this a demo account?
#
# 4. PRICES — reads (4 methods)
#    • bid                    - Best bid for a symbol
#    • ask                    - Best ask for a symbol
#    • spread                 - ask − bid
#    • price                  - Quote struct (bid / ask / last / spread / time)
#
# 5. SIMPLE TRADING (6 methods)
#    • buy_market / sell_market - Market order (aliases: buy / sell)
#    • buy_limit / sell_limit   - Pending limit order
#    • buy_stop  / sell_stop    - Pending stop order
#
# 6. TRADING WITH SL/TP (2 methods)
#    • buy_market_with_sl_tp  - Market buy with stop-loss / take-profit
#    • sell_market_with_sl_tp - Market sell with stop-loss / take-profit
#
# 7. RAW TRADING (3 methods)
#    • order_send             - Full-control order (any type / options)
#    • order_modify           - Modify SL / TP / price / expiration
#    • order_close            - Close or delete by ticket
#
# 8. POSITION MANAGEMENT (6 methods)
#    • close_position         - Close one position (full or partial)
#    • close_all_positions    - Close every open position
#    • close_all_by_symbol    - Close all positions on a symbol
#    • modify_sl              - Set a position's stop-loss
#    • modify_tp              - Set a position's take-profit
#    • modify_sl_tp           - Set both at once
#
# 9. POSITION INFORMATION (8 methods)
#    • open_positions         - Open positions (filter by magic / symbol)
#    • position               - One position by ticket
#    • positions_by_symbol    - Positions on a symbol
#    • has_position?          - Any position on a symbol?
#    • count_positions        - Number of open positions
#    • total_profit           - Summed floating P/L
#    • profit_by_symbol       - Floating P/L for a symbol
#    • open_tickets           - Position & pending-order tickets
#
# 10. HISTORY (2 methods)
#    • order_history          - Historical orders + deals
#    • positions_history      - Historical positions / round-trips
#
# 11. SYMBOL INFORMATION (11 methods)
#    • symbol_info            - Full spec of a symbol
#    • all_symbols            - Names of all symbols
#    • symbols_total          - Count of symbols
#    • symbol_name            - Symbol name by index
#    • symbol_available?      - Does a symbol exist?
#    • symbol_digits          - Price decimals
#    • symbol_point           - Point size
#    • min_stop_level         - Min SL/TP distance (points)
#    • bars                   - OHLC bars
#    • session_quote          - Quote session times for a weekday
#    • session_trade          - Trade session times for a weekday
#
# 12. MARKET DEPTH / DOM (3 methods)
#    • book_add               - Subscribe to the order book
#    • book_release           - Unsubscribe from the order book
#    • book                   - Order-book snapshot
#
# 13. RISK MANAGEMENT (3 methods)
#    • required_margin        - Margin for a hypothetical order
#    • calc_profit            - Profit for a hypothetical round-trip
#    • max_lot                - Largest lot that fits free margin
#
# 14. STREAMS (6 methods)
#    • subscribe_ticks        - Stream ticks
#    • on_trade               - Stream trade events
#    • on_position_profit     - Stream position P/L updates
#    • on_tickets             - Stream ticket snapshots
#    • on_trade_transaction   - Stream trade transactions
#    • each_tick              - Blocking: iterate ticks for N seconds
#
# ══════════════════════════════════════════════════════════════════════════════

require_relative "mt5_service"

module MetaRPC
  module MT5
    # HIGH-LEVEL layer — one-liners with smart defaults over {MT5Service} / {MT5Account}.
    #
    # The fastest way to connect, read money and prices, trade, and size positions.
    # It wraps an MT5Service (which wraps an MT5Account) and exposes short helpers —
    # `balance`, `bid`, `buy_market`, `close_position`, ... — while still delegating
    # the full typed/raw API, so this one object does the whole job.
    #
    #   mt5 = MetaRPC::MT5::MT5Sugar.create(api_key: ENV["MRPC_API_KEY"])
    #   mt5.connect(498489, "pwd", server: "ICMarkets-Demo")
    #   mt5.balance                       # => 10000.0
    #   mt5.bid("EURUSD")                 # => 1.0831
    #   t = mt5.buy_market("EURUSD", 0.01)
    #   mt5.close_position(t.order)
    #
    # Reach the layers below with {#service} and {#account}.
    class MT5Sugar
      attr_reader :service

      # ════════════════════════════════════════════════════════════════════════════
      #region CONSTRUCTION
      # ════════════════════════════════════════════════════════════════════════════

      # Wrap an existing MT5Service, or build the whole stack from the same arguments.
      def initialize(service = nil, **opts)
        @service = service.is_a?(MT5Service) ? service : MT5Service.new(**opts)
      end

      # Build the whole stack: MT5Sugar -> MT5Service -> MT5Account.
      #
      #   MT5Sugar.create(api_key: ENV["MRPC_API_KEY"], id: stable_uuid)
      def self.create(host = MT5Account::DEFAULT_HOST, port = MT5Account::DEFAULT_PORT, **opts)
        new(MT5Service.new(MT5Account.new(host, port, **opts)))
      end

      # The MT5Account underneath (raw gRPC).
      def account = @service.account

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region CONNECTION
      # ════════════════════════════════════════════════════════════════════════════

      # Connect by broker server name (keyword `server:` kept for drop-in use).
      def connect(login, password, server:, **opts) = @service.connect(login, password, server: server, **opts)
      def connect_by_host(login, password, host:, port:, **opts) = @service.connect_by_host(login, password, host: host, port: port, **opts)
      # Positional-server shorthand.
      def quick_connect(login, password, server) = @service.connect(login, password, server: server)
      def connected? = @service.connected?
      def reconnect(force: false) = @service.reconnect(force: force)
      def disconnect(delete: false, reason: nil) = @service.disconnect(delete: delete, reason: reason)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region MONEY (READS)
      # ════════════════════════════════════════════════════════════════════════════

      def balance      = account.account_info_double(:ACCOUNT_BALANCE)
      def equity       = account.account_info_double(:ACCOUNT_EQUITY)
      def margin       = account.account_info_double(:ACCOUNT_MARGIN)
      def free_margin  = account.account_info_double(:ACCOUNT_MARGIN_FREE)
      def margin_level = account.account_info_double(:ACCOUNT_MARGIN_LEVEL)
      def profit       = account.account_info_double(:ACCOUNT_PROFIT)
      def account_info = @service.account_info
      def account_summary = @service.account_summary
      def demo? = @service.demo?

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region PRICES (READS)
      # ════════════════════════════════════════════════════════════════════════════

      def bid(symbol)    = @service.quote(symbol).bid
      def ask(symbol)    = @service.quote(symbol).ask
      def spread(symbol) = (q = @service.quote(symbol); q.ask - q.bid)
      def price(symbol)  = @service.quote(symbol)   # Quote struct (bid/ask/last/spread/time_utc)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region SIMPLE TRADING
      # ════════════════════════════════════════════════════════════════════════════

      def buy_market(symbol, volume, **kw)  = @service.order_send(symbol: symbol, type: :buy,  volume: volume, **kw)
      def sell_market(symbol, volume, **kw) = @service.order_send(symbol: symbol, type: :sell, volume: volume, **kw)
      alias buy buy_market
      alias sell sell_market

      def buy_limit(symbol, volume, price, **kw)  = @service.order_send(symbol: symbol, type: :buy_limit,  volume: volume, price: price, **kw)
      def sell_limit(symbol, volume, price, **kw) = @service.order_send(symbol: symbol, type: :sell_limit, volume: volume, price: price, **kw)
      def buy_stop(symbol, volume, price, **kw)   = @service.order_send(symbol: symbol, type: :buy_stop,   volume: volume, price: price, **kw)
      def sell_stop(symbol, volume, price, **kw)  = @service.order_send(symbol: symbol, type: :sell_stop,  volume: volume, price: price, **kw)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region TRADING WITH SL/TP
      # ════════════════════════════════════════════════════════════════════════════

      def buy_market_with_sl_tp(symbol, volume, sl:, tp:, **kw)  = @service.order_send(symbol: symbol, type: :buy,  volume: volume, stop_loss: sl, take_profit: tp, **kw)
      def sell_market_with_sl_tp(symbol, volume, sl:, tp:, **kw) = @service.order_send(symbol: symbol, type: :sell, volume: volume, stop_loss: sl, take_profit: tp, **kw)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region RAW TRADING PASSTHROUGH
      # ════════════════════════════════════════════════════════════════════════════

      # Drop-in with the old flat client / full control when a helper is too narrow.
      def order_send(symbol:, type:, volume:, **opts) = @service.order_send(symbol: symbol, type: type, volume: volume, **opts)
      def order_modify(ticket:, **opts) = @service.order_modify(ticket: ticket, **opts)
      def order_close(ticket:, **opts)  = @service.order_close(ticket: ticket, **opts)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region POSITION MANAGEMENT
      # ════════════════════════════════════════════════════════════════════════════

      def close_position(ticket, volume: nil, slippage: 10) = @service.order_close(ticket: ticket, volume: volume, slippage: slippage)
      def close_all_positions(slippage: 10) = open_positions.map { |p| close_position(p.ticket, slippage: slippage) }
      def close_all_by_symbol(symbol, slippage: 10) = positions_by_symbol(symbol).map { |p| close_position(p.ticket, slippage: slippage) }
      def modify_sl(ticket, stop_loss)   = @service.order_modify(ticket: ticket, stop_loss: stop_loss)
      def modify_tp(ticket, take_profit) = @service.order_modify(ticket: ticket, take_profit: take_profit)
      def modify_sl_tp(ticket, stop_loss:, take_profit:) = @service.order_modify(ticket: ticket, stop_loss: stop_loss, take_profit: take_profit)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region POSITION INFORMATION
      # ════════════════════════════════════════════════════════════════════════════

      def open_positions(magic: nil, symbol: nil) = @service.positions(magic: magic, symbol: symbol)
      def position(ticket) = open_positions.find { |p| p.ticket == ticket }
      def positions_by_symbol(symbol) = @service.positions(symbol: symbol)
      def has_position?(symbol) = positions_by_symbol(symbol).any?
      def count_positions = @service.positions_total
      def total_profit = open_positions.sum(&:profit)
      def profit_by_symbol(symbol) = positions_by_symbol(symbol).sum(&:profit)
      # Tickets only (open positions + pending orders), cheaply.
      def open_tickets = @service.opened_tickets

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region HISTORY
      # ════════════════════════════════════════════════════════════════════════════

      def order_history(from_utc:, **opts) = @service.order_history(from_utc: from_utc, **opts)
      def positions_history(from_utc:, **opts) = @service.positions_history(from_utc: from_utc, **opts)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region SYMBOL INFORMATION
      # ════════════════════════════════════════════════════════════════════════════

      def symbol_info(symbol) = @service.symbol_params(symbol)
      def all_symbols = @service.symbols
      def symbols_total(market_watch_only: false) = @service.symbols_total(market_watch_only: market_watch_only)
      def symbol_name(index, selected: false) = @service.symbol_name(index, selected: selected)
      def symbol_available?(symbol) = @service.symbol_exist?(symbol)
      def symbol_digits(symbol) = account.symbol_info_integer(symbol, :SYMBOL_DIGITS)
      def symbol_point(symbol)  = account.symbol_info_double(symbol, :SYMBOL_POINT)
      def min_stop_level(symbol) = account.symbol_info_integer(symbol, :SYMBOL_TRADE_STOPS_LEVEL)
      def bars(symbol, **opts) = @service.bars(symbol, **opts)
      # Quote / trade session [from, to) for a weekday (:SUNDAY..:SATURDAY).
      def session_quote(symbol, day_of_week:, session_index: 0) = @service.session_quote(symbol, day_of_week: day_of_week, session_index: session_index)
      def session_trade(symbol, day_of_week:, session_index: 0) = @service.session_trade(symbol, day_of_week: day_of_week, session_index: session_index)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region MARKET DEPTH (DOM)
      # ════════════════════════════════════════════════════════════════════════════

      # Subscribe to a symbol's order book, read it, then release it.
      def book_add(symbol) = @service.book_add(symbol)
      def book_release(symbol) = @service.book_release(symbol)
      def book(symbol) = @service.book(symbol)

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region RISK MANAGEMENT
      # ════════════════════════════════════════════════════════════════════════════

      # Margin required to open `volume` lots of `symbol` at `price` (type :buy/:sell).
      def required_margin(symbol, volume, price, type: :buy) = @service.order_calc_margin(symbol: symbol, type: type, volume: volume, price: price)

      # Profit of `volume` lots of `symbol` moving open_price -> close_price (type :buy/:sell).
      def calc_profit(symbol, volume, open_price, close_price, type: :buy) = @service.order_calc_profit(symbol: symbol, type: type, volume: volume, open_price: open_price, close_price: close_price)

      # Largest volume that fits in free margin for `symbol` at `price`, rounded to the
      # symbol's volume step. Returns 0.0 when one lot already exceeds free margin.
      def max_lot(symbol, price, type: :buy)
        per_lot = required_margin(symbol, 1.0, price, type: type)
        return 0.0 if per_lot <= 0
        step = (symbol_info(symbol)&.volume_step || 0.01)
        raw = free_margin / per_lot
        (raw / step).floor * step
      end

      #endregion

      # ════════════════════════════════════════════════════════════════════════════
      #region STREAMS
      # ════════════════════════════════════════════════════════════════════════════

      def subscribe_ticks(symbols, &block) = @service.subscribe_ticks(symbols, &block)
      def on_trade(&block) = @service.on_trade(&block)
      def on_position_profit(interval_ms: 1000, ignore_empty: true, &block) = @service.on_position_profit(interval_ms: interval_ms, ignore_empty: ignore_empty, &block)
      def on_tickets(interval_ms: 1000, &block) = @service.on_tickets(interval_ms: interval_ms, &block)
      def on_trade_transaction(&block) = @service.on_trade_transaction(&block)
      def each_tick(symbols, seconds:, &block) = @service.each_tick(symbols, seconds: seconds, &block)

      #endregion
    end

    # Backward-compatible aliases.
    #   Client  -> the friendly high-level layer (drop-in for the old flat client)
    #   Account -> the raw low-level layer
    Client = MT5Sugar
    Account = MT5Account
  end
end
