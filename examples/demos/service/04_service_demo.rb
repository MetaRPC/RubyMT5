# ══════════════════════════════════════════════════════════════════════════════
# FILE: 04_service_demo.rb — MID-LEVEL (MT5Service) DEMO
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   The typed facade: plain Ruby Structs and arguments instead of protobuf.
#   Reached via sugar.service. READ-ONLY: account snapshot, a quote, positions.
#
# WHAT THIS DEMO COVERS:
#   1. ACCOUNT  - account_info (Account struct) / demo?
#   2. QUOTES   - quote(symbol) (Quote struct) / symbol_params
#   3. POSITIONS - positions(magic:, symbol:)
#
# RUN:  ruby examples/demos/main.rb 4      (SAFE: read-only)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("4", "Service demo          - typed account / quote / positions") do |sugar, cfg|
  svc = sugar.service   # the MT5Service
  sym = cfg.test_symbol

  Demos.sub("1. account")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  account_info — typed snapshot Account(login, balance, equity, currency,
  #       leverage, trade_mode, company, server_time_utc).
  #  1.2  demo?        — true on a demo account.
  # ──────────────────────────────────────────────────────────────────────────────
  a = svc.account_info
  puts format("  #%s  %.2f %s  leverage 1:%d  demo? %s", a.login, a.balance, a.currency, a.leverage, svc.demo?)

  Demos.sub("2. quotes & specs")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  quote(symbol)        — Quote(symbol, bid, ask, last, spread, time_utc).
  #  2.2  symbol_params(symbol)— full SymbolParameters spec, or nil if unknown.
  # ──────────────────────────────────────────────────────────────────────────────
  q = svc.quote(sym)
  puts format("  %s  bid %s  ask %s  spread %.5f", q.symbol, q.bid, q.ask, q.spread)
  sp = svc.symbol_params(sym)
  puts format("  spec: digits %d  vol_min %s  vol_step %s", sp.digits, sp.volume_min, sp.volume_step) if sp

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.3  select_symbol / symbol_exist? / symbol_synchronized? — typed predicates.
  #  2.4  symbol_params_all(sort:) — full spec of every symbol (array).
  # ──────────────────────────────────────────────────────────────────────────────
  svc.select_symbol(sym)
  puts "  exists? #{svc.symbol_exist?(sym)}   synced? #{svc.symbol_synchronized?(sym)}   total specs #{svc.symbol_params_all.size}"

  Demos.sub("3. positions")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  positions(magic:, symbol:) — open positions filtered in Ruby.
  #       Returns [PositionInfo] (ticket, symbol, volume, price_open, profit, ...).
  # ──────────────────────────────────────────────────────────────────────────────
  positions = svc.positions
  puts "  open positions: #{positions.size}"
  positions.first(5).each { |p| puts format("    #%d %-8s vol %.2f P/L %.2f", p.ticket, p.symbol, p.volume, p.profit) }
end
