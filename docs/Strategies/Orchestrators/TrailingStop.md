# 🎯 Trailing Stop Orchestrator

> Open a position, then **ratchet its stop-loss up** behind the price to lock in profit as the market moves your way. ⚠ Places a real (demo) order.

**Demo:** `examples/demos/orchestrators/11_trailing_stop.rb` · **Run:** `ruby examples/demos/main.rb 11`

---

## 💡 What it is

A trailing stop is the simplest profit-protection strategy: you enter, and every tick you move the stop-loss to a fixed distance behind the current price — but **only upward**. If price keeps rising, the stop follows and your locked-in profit grows; if price pulls back into the stop, you're taken out with the gains you'd already secured.

---

## 🧠 Strategy logic

On each tick the orchestrator computes a candidate stop:

```
candidate_sl = bid − trail_pts × point
```

and applies the **ratchet rule** — move the stop there only if it's **higher** than the best stop so far:

```
if candidate_sl > best_sl    → modify_sl(ticket, candidate_sl)   # tighten
else                          → hold (never loosen)
```

That one-way ratchet is the whole idea: the stop can only improve, never give back ground.

---

## 🧱 Composed from (MT5Sugar)

| Step | Methods |
|------|---------|
| **Open** | [`buy_market`](../../MT5Sugar/5.%20Simple_Trading.md) · [`open_positions`](../../MT5Sugar/8.%20Position_Information.md) |
| **Trail** | [`bid`](../../MT5Sugar/4.%20Prices_Quotes.md) · [`modify_sl`](../../MT5Sugar/6.%20Trading_SLTP.md) · [`symbol_point`](../../MT5Sugar/10.%20Symbol_Information.md) · [`symbol_digits`](../../MT5Sugar/10.%20Symbol_Information.md) |
| **Close** | [`close_position`](../../MT5Sugar/7.%20Position_Management.md) |

---

## 🔧 Code walkthrough

```ruby
point  = sugar.symbol_point(sym)
digits = sugar.symbol_digits(sym)
trail_pts = 150      # stop sits this far below bid
steps = 6            # how many ticks to trail for

# 1. OPEN — buy, then grab the position's ticket
res = sugar.buy_market(sym, vol, magic: 110_011)
pos = sugar.open_positions(symbol: sym).max_by(&:ticket)

# 2. TRAIL — ratchet the stop up, never down
best_sl = nil
steps.times do
  sleep 1
  bid  = sugar.bid(sym)
  want = (bid - trail_pts * point).round(digits)
  if best_sl.nil? || want > best_sl
    best_sl = want
    sugar.modify_sl(pos.ticket, want)          # tighten only
  end
end

# 3. CLOSE — exit (a real run lets the stop do it)
sugar.close_position(pos.ticket)
```

---

## ⚙️ Tunables

| Name | Meaning |
|------|---------|
| `trail_pts` | trail distance in points (smaller = tighter, gets stopped sooner) |
| `steps` | how many ticks the demo trails for |

**Make it real:** replace the fixed `steps` loop with a [`subscribe_ticks`](../../MT5Sugar/13.%20Streaming.md) stream and let the broker's stop close the position (drop the explicit `close_position`).

---

## ⚠️ Safety

Places one tiny market position and closes it. Demo accounts only. Respect the symbol's [`min_stop_level`](../../MT5Sugar/10.%20Symbol_Information.md) — a stop too close to price is rejected.

---

## 📚 See also

* [Grid Trader](./GridTrader.md) · [Risk Manager](./RiskManager.md) · [Adaptive Preset](../Presets/AdaptiveMarketMode.md)
* [MT5Sugar · Trading with SL/TP](../../MT5Sugar/6.%20Trading_SLTP.md)

**Back to:** [Strategies — Master Overview](../Strategies.Master.Overview.md)
