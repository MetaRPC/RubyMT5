# ══════════════════════════════════════════════════════════════════════════════
# FILE: 08_sugar_positions.rb — HIGH-LEVEL (MT5Sugar) POSITIONS DEMO
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Inspect the open book with MT5Sugar one-liners. Fully READ-ONLY: it lists and
#   summarizes positions but never opens or closes anything.
#
# WHAT THIS DEMO COVERS:
#   1. LISTING   - open_positions / count_positions / has_position?
#   2. SUMMARIES - total_profit / profit_by_symbol / position(ticket)
#
# RUN:  ruby examples/demos/main.rb 8      (SAFE: read-only)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("8", "Sugar positions       - list / inspect positions (read-only)") do |sugar, cfg|
  sym = cfg.test_symbol

  Demos.sub("1. listing")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  count_positions       — number of open positions           → Integer
  #  1.2  open_positions        — every open position (PositionInfo[])
  #       Filter with open_positions(magic:, symbol:).
  #  1.3  has_position?(symbol) — is there an open position on it?    → true/false
  # ──────────────────────────────────────────────────────────────────────────────
  positions = sugar.open_positions
  puts "  open positions: #{sugar.count_positions}   has #{sym}? #{sugar.has_position?(sym)}"
  positions.first(10).each do |p|
    puts format("    #%d  %-8s  vol %.2f  open %s  P/L %.2f", p.ticket, p.symbol, p.volume, p.price_open, p.profit)
  end
  puts "  (no open positions — open one with demo 7 first)" if positions.empty?

  Demos.sub("2. summaries")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  total_profit            — summed floating P/L over all positions → Float
  #  2.2  profit_by_symbol(symbol)— floating P/L for one symbol            → Float
  #  2.3  position(ticket)        — one position by ticket                 → PositionInfo | nil
  # ──────────────────────────────────────────────────────────────────────────────
  puts format("  total P/L %.2f    %s P/L %.2f", sugar.total_profit, sym, sugar.profit_by_symbol(sym))
  if (first = positions.first)
    one = sugar.position(first.ticket)
    puts "  position(#{first.ticket}) -> #{one&.symbol} vol #{one&.volume}"
  end

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.4  positions_by_symbol(symbol) — only positions on one symbol → [PositionInfo]
  #  2.5  open_tickets                — position & pending-order tickets (cheap).
  # ──────────────────────────────────────────────────────────────────────────────
  tk = sugar.open_tickets
  puts "  #{sym} positions: #{sugar.positions_by_symbol(sym).size}   open position tickets: #{tk.opened_position_tickets.to_a.size}"
end
