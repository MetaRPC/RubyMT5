# ══════════════════════════════════════════════════════════════════════════════
# FILE: 07_sugar_trading.rb — HIGH-LEVEL (MT5Sugar) TRADING DEMO
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Open and immediately close ONE tiny market position with MT5Sugar one-liners.
#   ⚠ PLACES A REAL (demo) ORDER — run on a demo account only. Volume is cfg.test_volume.
#
# WHAT THIS DEMO COVERS:
#   1. QUOTE    - price(symbol) before trading
#   2. OPEN     - buy_market(symbol, volume)
#   3. CLOSE    - close_position(ticket)
#
# RUN:  ruby examples/demos/main.rb 7      (⚠ opens & closes a tiny demo order)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("7", "Sugar trading         - open & close a tiny demo order", warn: true) do |sugar, cfg|
  sym = cfg.test_symbol
  vol = cfg.test_volume

  Demos.sub("1. quote")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  price(symbol) — snapshot the market before sending an order.
  # ──────────────────────────────────────────────────────────────────────────────
  q = sugar.price(sym)
  puts format("  %s  bid %s  ask %s", sym, q.bid, q.ask)

  Demos.sub("2. open market position")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  buy_market(symbol, volume, **opts) — market buy at the current ask.
  #       Returns: OrderSendData (returned_code 10009 = DONE, order, deal, price, volume).
  #       Trading one-liners RAISE on a broker rejection — wrap in begin/rescue.
  # ──────────────────────────────────────────────────────────────────────────────
  res = sugar.buy_market(sym, vol, comment: "RubyMT5-demo07", magic: 700_007)
  puts format("  opened: retcode %s  order #%s  deal #%s  @ %s", res.returned_code, res.order, res.deal, res.price)

  sleep 1   # let the position settle before closing

  Demos.sub("3. close the position")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  open_positions(symbol:)  — find the freshly opened position's ticket.
  #  3.2  close_position(ticket)   — full close (volume: nil). Returns OrderCloseData.
  # ──────────────────────────────────────────────────────────────────────────────
  pos = sugar.open_positions(symbol: sym).max_by(&:ticket)
  if pos
    out = sugar.close_position(pos.ticket)
    puts format("  closed #%d: retcode %s", pos.ticket, out.returned_code)
  else
    puts "  no open position found to close (already filled & closed?)"
  end

  Demos.sub("4. SL/TP helpers + close-all")

  # ──────────────────────────────────────────────────────────────────────────────
  #  4.1  buy_market_with_sl_tp(symbol, volume, sl:, tp:) — open with protective
  #       stop-loss / take-profit in one call. (sell_market_with_sl_tp is the mirror.)
  #  4.2  modify_tp(ticket, tp) / modify_sl_tp(ticket, stop_loss:, take_profit:)
  #       — adjust stops of an open position.
  #  4.3  close_all_by_symbol(symbol) — flatten every position on a symbol.
  # ──────────────────────────────────────────────────────────────────────────────
  pt = sugar.price(sym)
  pip = sugar.symbol_point(sym) * 100
  sl = (pt.bid - 20 * pip).round(sugar.symbol_digits(sym))
  tp = (pt.ask + 20 * pip).round(sugar.symbol_digits(sym))
  r2 = sugar.buy_market_with_sl_tp(sym, vol, sl: sl, tp: tp, magic: 700_008, comment: "RubyMT5-sltp")
  puts format("  opened w/ SL %s TP %s: retcode %s order #%s", sl, tp, r2.returned_code, r2.order)
  if (p2 = sugar.open_positions(symbol: sym).max_by(&:ticket))
    sugar.modify_sl_tp(p2.ticket, stop_loss: sl, take_profit: (pt.ask + 30 * pip).round(sugar.symbol_digits(sym)))
    puts "  modified #{p2.ticket} (SL/TP)"
  end
  closed = sugar.close_all_by_symbol(sym)
  puts "  close_all_by_symbol(#{sym}): closed #{closed.size}"
end
