# ══════════════════════════════════════════════════════════════════════════════
# FILE: 01_general_operations.rb — LOW-LEVEL (MT5Account) GENERAL OPERATIONS
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   The raw gRPC client. Each call maps 1:1 to an RPC and returns the protobuf
#   `*Data` message. READ-ONLY: account, symbols, a tick and some bars.
#
# WHAT THIS DEMO COVERS:
#   1. ACCOUNT   - account_summary / account_info_double / integer / string
#   2. SYMBOLS   - symbols_total / symbol_exist / symbol_name / symbol_list /
#                  symbol_is_synchronized / symbol_info_tick / symbol_info_string
#   3. MARKET    - symbol_params_many / price_history
#   4. DETAILS   - tick_value_with_size / symbol_info_margin_rate /
#                  symbol_info_session_quote / session_trade / market_book_add/get/release
#
# RUN:  ruby examples/demos/main.rb 1      (SAFE: read-only)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("1", "General operations    - account & symbols (raw MT5Account)") do |sugar, cfg|
  acct = sugar.account   # the raw MT5Account
  sym = cfg.test_symbol

  Demos.sub("1. account")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  account_summary — all account data in one call (AccountSummaryData):
  #       account_login, account_balance, account_equity, account_currency,
  #       account_leverage, account_trade_mode, account_company_name.
  # ──────────────────────────────────────────────────────────────────────────────
  s = acct.account_summary
  puts format("  #%s  balance %.2f %s  leverage 1:%d  %s",
              s.account_login, s.account_balance, s.account_currency, s.account_leverage, s.account_company_name)

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.2  account_info_double/integer/string(property) — one typed property each.
  #       property is an ACCOUNT_* enum symbol (see ENUMS reference).
  # ──────────────────────────────────────────────────────────────────────────────
  puts format("  equity %.2f  margin %.2f  free %.2f",
              acct.account_info_double(:ACCOUNT_EQUITY),
              acct.account_info_double(:ACCOUNT_MARGIN),
              acct.account_info_double(:ACCOUNT_MARGIN_FREE))
  puts format("  leverage 1:%d  currency %s",
              acct.account_info_integer(:ACCOUNT_LEVERAGE),
              acct.account_info_string(:ACCOUNT_CURRENCY))

  Demos.sub("2. symbols")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  symbols_total(mode:)       — count of symbols (mode: true = Market Watch).
  #  2.2  symbol_exist(symbol)       — does the symbol exist?            → true/false
  #  2.3  symbol_list                — names of all symbols             → [String]
  #  2.4  symbol_name(index)         — symbol name by index             → String
  #  2.5  symbol_is_synchronized(s)  — is its data synced?              → true/false
  #  2.6  symbol_info_tick(symbol)   — last tick (MrpcMqlTick: bid, ask, last, time).
  #  2.7  symbol_info_string(s, prop)— one SYMBOL_* string property.
  # ──────────────────────────────────────────────────────────────────────────────
  all = acct.symbol_list
  puts "  symbols total #{acct.symbols_total}   list #{all.size}   first #{acct.symbol_name(0)}"
  puts "  #{sym} exists? #{acct.symbol_exist(sym)}   synced? #{acct.symbol_is_synchronized(sym)}"
  t = acct.symbol_info_tick(sym)
  puts format("  %s tick: bid %s  ask %s  last %s   desc %s",
              sym, t.bid, t.ask, t.last, acct.symbol_info_string(sym, :SYMBOL_DESCRIPTION))

  Demos.sub("3. market data")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  symbol_params_many(sort:) — full spec of EVERY symbol in one call.
  #       Each entry: SymbolParameters (digits, point, volume_min/max/step, ...).
  # ──────────────────────────────────────────────────────────────────────────────
  specs = acct.symbol_params_many
  one = specs.find { |x| x.name == sym }
  puts format("  %s spec: digits %d  point %s  vol_min %s  vol_step %s",
              sym, one.digits, one.point, one.volume_min, one.volume_step) if one

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.2  price_history(symbol, timeframe:, max_bars:) — OHLC bars, oldest first.
  #       timeframe: :M1 .. :MN1 (or a raw ENUM_TIMEFRAMES int). Returns [PriceBar].
  # ──────────────────────────────────────────────────────────────────────────────
  bars = acct.price_history(sym, timeframe: :H1, max_bars: 5)
  puts "  last #{bars.size} H1 bars:"
  bars.each { |b| puts format("    o %s  h %s  l %s  c %s", b.open, b.high, b.low, b.close) }

  Demos.sub("4. details: sizing, margin, sessions, DOM")

  # ──────────────────────────────────────────────────────────────────────────────
  #  4.1  tick_value_with_size(symbols)   — tick value / size / contract size (sizing).
  #  4.2  symbol_info_margin_rate(s, type)— initial / maintenance margin rates.
  # ──────────────────────────────────────────────────────────────────────────────
  tv = acct.tick_value_with_size(sym).symbol_tick_size_infos.first
  puts format("  tick value %s  tick size %s  contract %s", tv.TradeTickValue, tv.TradeTickSize, tv.TradeContractSize) if tv
  mr = acct.symbol_info_margin_rate(sym, :buy)
  puts format("  margin rate: initial %s  maintenance %s", mr.initial_margin_rate, mr.maintenance_margin_rate)

  # ──────────────────────────────────────────────────────────────────────────────
  #  4.3  symbol_info_session_quote / session_trade(s, day_of_week:) — session [from,to).
  # ──────────────────────────────────────────────────────────────────────────────
  sq = acct.symbol_info_session_quote(sym, day_of_week: :MONDAY)
  st = acct.symbol_info_session_trade(sym, day_of_week: :MONDAY)
  puts "  Monday quote session from #{sq.from&.seconds}s  trade session from #{st.from&.seconds}s"

  # ──────────────────────────────────────────────────────────────────────────────
  #  4.4  market_book_add / market_book_get / market_book_release — Depth of Market.
  #       add → read snapshot → release. Not all symbols expose a book.
  # ──────────────────────────────────────────────────────────────────────────────
  if acct.market_book_add(sym)
    depth = acct.market_book_get(sym).mql_book_infos
    puts "  DOM levels for #{sym}: #{depth.size}"
    acct.market_book_release(sym)
  else
    puts "  DOM not available for #{sym}"
  end
end
