# ══════════════════════════════════════════════════════════════════════════════
# FILE: 03_streaming_methods.rb — LOW-LEVEL (MT5Account) STREAMING
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Raw server-stream RPCs. Each returns a Subscription (background thread). This
#   demo runs the tick and trade streams for a few seconds, then cancels them.
#   READ-ONLY (it only subscribes).
#
# WHAT THIS DEMO COVERS:
#   1. TICKS         - on_symbol_tick(symbols) { |tick| ... }
#   2. TRADE EVENTS  - on_trade { |event| ... }
#
# RUN:  ruby examples/demos/main.rb 3      (SAFE: read-only, ~6s)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("3", "Streaming             - raw tick + trade streams (~6s)") do |sugar, cfg|
  acct = sugar.account
  sym = cfg.test_symbol

  Demos.sub("1. on_symbol_tick (~5s)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  on_symbol_tick(symbols) { |tick| ... } — streams MrpcSubscriptionMqlTick
  #       (symbol, bid, ask, last, time) on a background thread.
  #       Returns a Subscription; call .cancel to unsubscribe cleanly.
  # ──────────────────────────────────────────────────────────────────────────────
  ticks = 0
  tick_sub = acct.on_symbol_tick(sym) do |t|
    ticks += 1
    puts format("    tick %-8s bid %s ask %s", t.symbol, t.bid, t.ask) if ticks <= 5
  end
  sleep 5
  tick_sub.cancel
  puts "  received #{ticks} ticks"

  Demos.sub("2. on_trade (~1s snapshot)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  on_trade { |event| ... } — streams OnTradeData whenever orders/positions
  #       change. Here we just open the stream briefly to show the wiring.
  # ──────────────────────────────────────────────────────────────────────────────
  events = 0
  trade_sub = acct.on_trade { |_evt| events += 1 }
  sleep 1
  trade_sub.cancel
  puts "  trade events in 1s: #{events} (none expected unless you trade elsewhere)"

  Demos.sub("3. other streams (~1s each)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  on_position_profit(interval_ms:) — periodic position P/L snapshots.
  #  3.2  on_positions_and_pending_orders_tickets(interval_ms:) — ticket snapshots.
  #  3.3  on_trade_transaction — low-level MT5 trade-transaction events.
  #       All return a Subscription; open briefly, then cancel.
  # ──────────────────────────────────────────────────────────────────────────────
  %i[profit tickets txn].each_with_object({}) do |k, counts|
    counts[k] = 0
    sub =
      case k
      when :profit  then acct.on_position_profit(interval_ms: 500) { counts[k] += 1 }
      when :tickets then acct.on_positions_and_pending_orders_tickets(interval_ms: 500) { counts[k] += 1 }
      when :txn     then acct.on_trade_transaction { counts[k] += 1 }
      end
    sleep 1
    sub.cancel
    puts "  #{k}: #{counts[k]} message(s)"
  end
end
