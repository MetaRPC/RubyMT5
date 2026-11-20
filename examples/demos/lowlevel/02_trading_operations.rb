# ══════════════════════════════════════════════════════════════════════════════
# FILE: 02_trading_operations.rb — LOW-LEVEL (MT5Account) TRADING OPERATIONS
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   The raw trading RPCs: order_send → order_modify → order_close, plus the
#   pre-trade calculators. ⚠ PLACES A REAL (demo) ORDER — demo account only.
#
# WHAT THIS DEMO COVERS:
#   1. CALCULATE - order_calc_margin / order_calc_profit
#   2. OPEN      - order_send(symbol:, type:, volume:)
#   3. MANAGE    - order_modify (SL/TP) → order_close
#
# RUN:  ruby examples/demos/main.rb 2      (⚠ opens & closes a tiny demo order)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("2", "Trading operations    - order_send/modify/close (raw)", warn: true) do |sugar, cfg|
  acct = sugar.account
  sym = cfg.test_symbol
  vol = cfg.test_volume

  Demos.sub("1. pre-trade calculators")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  order_calc_margin(symbol:, type:, volume:, price:) — margin needed → Float
  #  1.2  order_calc_profit(symbol:, type:, volume:, open_price:, close_price:) → Float
  # ──────────────────────────────────────────────────────────────────────────────
  ask = acct.symbol_info_tick(sym).ask
  margin = acct.order_calc_margin(symbol: sym, type: :buy, volume: vol, price: ask)
  profit = acct.order_calc_profit(symbol: sym, type: :buy, volume: vol, open_price: ask, close_price: ask + 0.001)
  puts format("  margin for %.2f %s: %.2f   profit of a +0.001 move: %.2f", vol, sym, margin, profit)

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.3  positions_total       — number of open positions              → Integer
  #  1.4  opened_orders_tickets — only the tickets (OpenedOrdersTicketsData:
  #       opened_position_tickets[], opened_orders_tickets[]).
  # ──────────────────────────────────────────────────────────────────────────────
  tk = acct.opened_orders_tickets
  puts "  positions_total #{acct.positions_total}   position tickets #{tk.opened_position_tickets.to_a.size}"

  Demos.sub("2. order_send (market buy)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  order_send(symbol:, type:, volume:, ...) — market or pending order.
  #       type: :buy/:sell/:buy_limit/... magic -> expert_id.
  #       Returns OrderSendData (returned_code 10009 = DONE, order, deal, price).
  #       RAISES ApiError on rejection; a trade is NEVER re-sent automatically.
  # ──────────────────────────────────────────────────────────────────────────────
  res = acct.order_send(symbol: sym, type: :buy, volume: vol, magic: 200_002, comment: "RubyMT5-demo02")
  puts format("  opened: retcode %s  order #%s  deal #%s  @ %s", res.returned_code, res.order, res.deal, res.price)
  sleep 1

  Demos.sub("3. modify & close")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.0  order_check(request) — validate a MrpcMqlTradeRequest without sending it
  #       (margin / free margin / retcode). Guarded: enum/field details vary by build.
  # ──────────────────────────────────────────────────────────────────────────────
  begin
    req = Mt5TermApi::MrpcMqlTradeRequest.new(symbol: sym, volume: vol, order_type: :ORDER_TYPE_TF_BUY, price: ask)
    chk = acct.order_check(req)
    puts "  order_check: #{chk.mql_trade_check_result ? 'result returned' : 'n/a'}"
  rescue StandardError => e
    puts "  order_check skipped: #{e.message[0, 70]}"
  end

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  opened_orders — find the new position (OpenedOrdersData.position_infos[]).
  #  3.2  order_modify(ticket:, stop_loss:, take_profit:) — attach SL/TP.
  #  3.3  order_close(ticket:) — full close. Returns OrderCloseData.
  # ──────────────────────────────────────────────────────────────────────────────
  pos = acct.opened_orders.position_infos.select { |p| p.symbol == sym }.max_by(&:ticket)
  if pos
    pt = acct.symbol_info_tick(sym)
    sl = (pt.bid - 200 * acct.symbol_info_double(sym, :SYMBOL_POINT)).round(acct.symbol_info_integer(sym, :SYMBOL_DIGITS))
    acct.order_modify(ticket: pos.ticket, stop_loss: sl)
    puts "  modified #{pos.ticket}: SL #{sl}"
    out = acct.order_close(ticket: pos.ticket)
    puts "  closed #{pos.ticket}: retcode #{out.returned_code}"
  else
    puts "  no open position found (filled & auto-closed?)"
  end
end
