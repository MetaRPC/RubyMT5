# 🪜 Grid Trader Orchestrator

> Bracket the market with a symmetric grid of pending orders, list them, then remove them. ⚠ Places real (demo) pending orders, then cancels them.

**Demo:** `examples/demos/orchestrators/13_grid_trader.rb` · **Run:** `ruby examples/demos/main.rb 13`

---

## 💡 What it is

A grid surrounds the current price with pending orders so you're positioned **whichever way the market breaks**. This demo shows the mechanics — it **places** the grid and then **removes** it (no position management), so you can see how limits and stops bracket the market.

---

## 🧠 Strategy logic

At each level `i` (spaced `step_pts` apart from the market) it places **four** pending orders:

| Order | Where | Fires when… |
|-------|-------|-------------|
| `buy_limit` | below the market | price **dips** into it (join the pullback) |
| `sell_limit` | above the market | price **rallies** into it (fade the spike) |
| `buy_stop` | above the market | price **breaks out up** |
| `sell_stop` | below the market | price **breaks down** |

Limits **face** the market (mean-reversion); stops **break out** with momentum. Whichever zone price enters, an order triggers.

---

## 🧱 Composed from (MT5Sugar)

| Step | Methods |
|------|---------|
| **Place** | [`price`](../../MT5Sugar/4.%20Prices_Quotes.md) · [`buy_limit`/`sell_limit`/`buy_stop`/`sell_stop`](../../MT5Sugar/5.%20Simple_Trading.md) |
| **List** | `sugar.account.opened_orders.opened_orders` (raw layer) |
| **Remove** | [`order_close(ticket:)`](../../MT5Sugar/7.%20Position_Management.md) (deletes a pending) |

---

## 🔧 Code walkthrough

```ruby
levels = 2         # per side
step_pts = 300     # spacing, points
q = sugar.price(sym)

placed = []
(1..levels).each do |i|
  buy_price  = (q.bid - i * step_pts * point).round(digits)   # below
  sell_price = (q.ask + i * step_pts * point).round(digits)   # above
  b  = sugar.buy_limit(sym,  vol, buy_price)
  s  = sugar.sell_limit(sym, vol, sell_price)
  bs = sugar.buy_stop(sym,   vol, sell_price)   # breakout up
  ss = sugar.sell_stop(sym,  vol, buy_price)    # breakout down
  placed.push(b.order, s.order, bs.order, ss.order)
end

# remove the grid — order_close on a pending ticket deletes it
placed.each { |t| sugar.order_close(ticket: t) rescue nil }
```

---

## ⚙️ Tunables

| Name | Meaning |
|------|---------|
| `levels` | number of price levels per side |
| `step_pts` | spacing between levels, in points (wider = fewer, farther orders) |

**Make it real:** keep the grid live, watch fills via [`on_trade`](../../MT5Sugar/13.%20Streaming.md), and add take-profit / stop-loss and a [`close_all_by_symbol`](../../MT5Sugar/7.%20Position_Management.md) exit.

---

## ⚠️ Safety

Places `4 × levels` pending orders and deletes them. Demo accounts only. A level may trigger before removal — the demo guards each `order_close` with `rescue`.

---

## 📚 See also

* [Trailing Stop](./TrailingStop.md) · [Risk Manager](./RiskManager.md) · [Adaptive Preset](../Presets/AdaptiveMarketMode.md)
* [MT5Sugar · Simple Trading](../../MT5Sugar/5.%20Simple_Trading.md)

**Back to:** [Strategies — Master Overview](../Strategies.Master.Overview.md)
