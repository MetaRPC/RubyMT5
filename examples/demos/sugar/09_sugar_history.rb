# ══════════════════════════════════════════════════════════════════════════════
# FILE: 09_sugar_history.rb — HIGH-LEVEL (MT5Sugar) HISTORY DEMO
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Read closed history with MT5Sugar. Fully READ-ONLY. Shows the last few days
#   of closed orders+deals and closed positions (round-trips).
#
# WHAT THIS DEMO COVERS:
#   1. ORDER HISTORY     - order_history(from_utc:)
#   2. POSITIONS HISTORY - positions_history(from_utc:)
#
# RUN:  ruby examples/demos/main.rb 9      (SAFE: read-only)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("9", "Sugar history         - closed orders & positions (read-only)") do |sugar, _cfg|
  from = Time.now.utc - (7 * 24 * 60 * 60)   # last 7 days

  Demos.sub("1. order history (last 7 days)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  order_history(from_utc:, to_utc:) — closed orders + deals in a window.
  #       Auto-pages the gateway. Returns: [HistoryData] (history_order / history_deal).
  # ──────────────────────────────────────────────────────────────────────────────
  orders = sugar.order_history(from_utc: from)
  puts "  history rows: #{orders.size}"
  orders.last(5).each do |h|
    d = h.history_deal
    next unless d
    puts format("    deal #%d  %-8s  vol %.2f  price %s  profit %.2f",
                d.ticket, d.symbol, d.volume, d.price, d.profit)
  end

  Demos.sub("2. positions history (closed round-trips)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  positions_history(from_utc:, to_utc:) — one row per closed round-trip
  #       (open/close price, profit, magic). Auto-pages. Returns: [PositionHistory].
  # ──────────────────────────────────────────────────────────────────────────────
  closed = sugar.positions_history(from_utc: from)
  puts "  closed positions: #{closed.size}"
  closed.last(5).each do |p|
    puts format("    #%d  %-8s  vol %.2f  profit %.2f", p.position_ticket, p.symbol, p.volume, p.profit)
  end
  puts "  (nothing closed in the window)" if closed.empty?
end
