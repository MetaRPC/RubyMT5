# ══════════════════════════════════════════════════════════════════════════════
# FILE: 06_sugar_basics.rb — HIGH-LEVEL (MT5Sugar) BASICS DEMO
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   The simplest way to talk to MT5: one-liners for connection health, account
#   balances and prices. `sugar` arrives already connected (main.rb connected it).
#   Read-only — nothing is traded here (see 07 for trading).
#
# WHAT THIS DEMO COVERS:
#   1. CONNECTION       - connected?
#   2. BALANCE & MARGIN - balance / equity / free_margin / profit
#   3. PRICES           - bid / ask / spread / price
#
# API LEVELS:
#   HIGH-LEVEL  (MT5Sugar)   - THIS FILE
#   MID-LEVEL   (MT5Service) - sugar.service
#   LOW-LEVEL   (MT5Account) - sugar.account
#
# RUN:  ruby examples/demos/main.rb 6      (SAFE: read-only)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("6", "Sugar basics          - connection, balance, prices") do |sugar, cfg|
  sym = cfg.test_symbol

  Demos.sub("1. connection")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  connected?  — is the session up?
  #       Returns: true/false (true after a successful connect).
  # ──────────────────────────────────────────────────────────────────────────────
  puts "  connected? #{sugar.connected?}"

  Demos.sub("2. balance & margin (one-liners)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  balance      — realized funds, excludes floating P/L     → Float
  #  2.2  equity       — balance + floating P/L                    → Float
  #  2.3  free_margin  — margin available for new positions        → Float
  #  2.4  profit       — current floating profit (equity − balance)→ Float
  # ──────────────────────────────────────────────────────────────────────────────
  puts format("  balance %.2f", sugar.balance)
  puts format("  equity  %.2f", sugar.equity)
  puts format("  free    %.2f", sugar.free_margin)
  puts format("  level   %.1f%%", sugar.margin_level)
  puts format("  profit  %.2f", sugar.profit)

  Demos.sub("3. prices")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  bid(symbol) / ask(symbol) — latest bid / ask             → Float
  #  3.2  spread(symbol)            — ask − bid (price units)       → Float
  # ──────────────────────────────────────────────────────────────────────────────
  puts format("  %s bid %s  ask %s  spread %.5f", sym, sugar.bid(sym), sugar.ask(sym), sugar.spread(sym))

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.3  price(symbol) — bid / ask / last / spread / time in one snapshot
  #       Returns: Quote(symbol, bid, ask, last, spread, time_utc).
  # ──────────────────────────────────────────────────────────────────────────────
  p = sugar.price(sym)
  puts format("  price snapshot: bid %s  ask %s  spread %.5f", p.bid, p.ask, p.spread)
end
