# ══════════════════════════════════════════════════════════════════════════════
# FILE: 11_trailing_stop.rb — ORCHESTRATOR: TRAILING STOP
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   A full mini-lifecycle: open a tiny position, then trail its stop-loss behind
#   the price for a few ticks, then close. ⚠ PLACES A REAL (demo) ORDER.
#
# STRATEGY LOGIC:
#   A trailing stop locks in profit as the market moves your way. We buy, then on
#   each tick recompute a stop `trail_pts` points below the current bid and move the
#   SL there — but ONLY upward (a "ratchet"): the stop never loosens. If the price
#   pulls back, the SL stays put and eventually gets hit, protecting gains.
#
#   This is an ORCHESTRATOR: it composes MT5Sugar one-liners
#   (buy_market → bid + modify_sl in a loop → close_position) into a strategy.
#
# WHAT THIS DEMO COVERS:
#   1. OPEN   - buy_market(symbol, volume) + open_positions(symbol:)
#   2. TRAIL  - bid(symbol) + modify_sl(ticket, price)   (ratchet-up loop)
#   3. CLOSE  - close_position(ticket)
#
# TUNABLES:  trail_pts (trail distance, points) · steps (how many ticks to trail)
#
# RUN:  ruby examples/demos/main.rb 11     (⚠ opens, trails, then closes)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("11", "Trailing stop         - open, trail SL, close", warn: true) do |sugar, cfg|
  sym = cfg.test_symbol
  vol = cfg.test_volume
  point = sugar.symbol_point(sym)      # price value of one point, for distance math
  digits = sugar.symbol_digits(sym)    # decimals to round the SL price to
  trail_pts = 150         # trail distance in points (SL sits this far below bid)
  steps = 6               # how many ticks to trail for

  Demos.sub("1. open")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  buy_market(symbol, volume, **opts) — open the market position we'll trail.
  #       Returns: OrderSendData (returned_code 10009 = DONE, order, deal, price).
  #  1.2  open_positions(symbol:) — fetch the freshly opened position to get its ticket
  #       (we trail/close by ticket). Take the newest with max_by(&:ticket).
  # ──────────────────────────────────────────────────────────────────────────────
  res = sugar.buy_market(sym, vol, magic: 110_011, comment: "RubyMT5-trail")
  puts format("  opened order #%s deal #%s @ %s", res.order, res.deal, res.price)
  pos = sugar.open_positions(symbol: sym).max_by(&:ticket)
  unless pos
    puts "  no position to trail"
    next
  end

  Demos.sub("2. trail the stop-loss")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  bid(symbol)              — latest price we trail behind.
  #  2.2  modify_sl(ticket, price) — move the stop-loss of the open position.
  #       THE RATCHET: compute SL = bid − trail_pts·point, but only call modify_sl
  #       when the new SL is HIGHER than the best so far — never loosen a stop.
  # ──────────────────────────────────────────────────────────────────────────────
  best_sl = nil
  steps.times do |i|
    sleep 1
    bid = sugar.bid(sym)
    want = (bid - trail_pts * point).round(digits)   # candidate SL this tick
    if best_sl.nil? || want > best_sl
      best_sl = want
      sugar.modify_sl(pos.ticket, want)              # ratchet up
      puts format("  step %d: bid %s → SL %s", i + 1, bid, want)
    else
      puts format("  step %d: bid %s (SL held at %s)", i + 1, bid, best_sl)
    end
  end

  Demos.sub("3. close")

  # ──────────────────────────────────────────────────────────────────────────────
  #  3.1  close_position(ticket) — exit at the end of the demo (in a real run you'd
  #       let the trailing stop do the closing when price pulls back into it).
  # ──────────────────────────────────────────────────────────────────────────────
  out = sugar.close_position(pos.ticket)
  puts "  closed ##{pos.ticket}: retcode #{out.returned_code}"
end
