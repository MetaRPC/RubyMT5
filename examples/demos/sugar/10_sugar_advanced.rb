# ══════════════════════════════════════════════════════════════════════════════
# FILE: 10_sugar_advanced.rb — HIGH-LEVEL (MT5Sugar) RISK & SIZING DEMO
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Pre-trade math with MT5Sugar: required margin, max affordable lot, and the
#   projected profit of a hypothetical move. Fully READ-ONLY — no order is sent.
#
# WHAT THIS DEMO COVERS:
#   1. MARGIN & SIZING - required_margin / max_lot
#   2. PROFIT PROJECTION - calc_profit
#
# RUN:  ruby examples/demos/main.rb 10     (SAFE: read-only)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("10", "Sugar advanced        - risk sizing / margin (read-only)") do |sugar, cfg|
  sym = cfg.test_symbol
  vol = cfg.test_volume
  ask = sugar.ask(sym)

  Demos.sub("1. margin & sizing")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  required_margin(symbol, volume, price, type:) — margin to open the order
  #       Returns: Float (account currency). type: defaults to :buy.
  #  1.2  max_lot(symbol, price, type:) — largest volume that fits free margin,
  #       rounded to the symbol's volume step.                        → Float
  # ──────────────────────────────────────────────────────────────────────────────
  puts format("  required margin for %.2f %s @ %s: %.2f", vol, sym, ask, sugar.required_margin(sym, vol, ask))
  puts format("  free margin %.2f  → max lot on %s: %s", sugar.free_margin, sym, sugar.max_lot(sym, ask))

  Demos.sub("2. profit projection")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  calc_profit(symbol, volume, open_price, close_price, type:) — profit of a
  #       hypothetical round-trip without trading. Returns: Float (account currency).
  # ──────────────────────────────────────────────────────────────────────────────
  target = ask + (100 * sugar.symbol_point(sym))   # +100 points
  profit = sugar.calc_profit(sym, vol, ask, target)
  puts format("  %.2f %s from %s → %s (+100 pts): profit %.2f", vol, sym, ask, target, profit)

  Demos.sub("3. symbol utilities")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  all_symbols            — names of all symbols                  → [String]
  #  3.2  symbol_available?(s)   — does the symbol exist?                → true/false
  #  3.3  symbol_name(index)     — symbol name by index                 → String
  #  3.4  min_stop_level(s)      — min SL/TP distance in points          → Integer
  #  3.5  symbol_digits / symbol_point — precision helpers.
  # ──────────────────────────────────────────────────────────────────────────────
  names = sugar.all_symbols
  puts "  symbols: #{names.size}   first #{sugar.symbol_name(0)}   #{sym} available? #{sugar.symbol_available?(sym)}"
  puts "  #{sym}: digits #{sugar.symbol_digits(sym)}  point #{sugar.symbol_point(sym)}  min stop #{sugar.min_stop_level(sym)} pts"

  Demos.sub("4. sessions & order book")

  # ──────────────────────────────────────────────────────────────────────────────
  #  4.1  session_quote / session_trade(s, day_of_week:) — session [from,to) times.
  #  4.2  book_add(s) → book(s) → book_release(s) — Depth of Market snapshot.
  # ──────────────────────────────────────────────────────────────────────────────
  sq = sugar.session_quote(sym, day_of_week: :MONDAY)
  puts "  Monday quote session from #{sq.from&.seconds}s"
  if sugar.book_add(sym)
    puts "  DOM levels: #{sugar.book(sym).mql_book_infos.size}"
    sugar.book_release(sym)
  else
    puts "  DOM not available for #{sym}"
  end
end
