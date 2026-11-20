# 🧭 Adaptive Market Mode Preset

> Measure the market (spread + recent volatility) and **recommend which orchestrator** to run. Fully read-only — it decides, it doesn't trade.

**Demo:** `examples/demos/presets/16_adaptive_preset.rb` · **Run:** `ruby examples/demos/main.rb 16`

---

## 💡 What it is

An orchestrator runs **one** strategy. A **preset** is the layer above: it reads conditions and **routes** to the orchestrator that fits right now. This one is the "brain" that chooses between [Trailing Stop](../Orchestrators/TrailingStop.md), [Grid Trader](../Orchestrators/GridTrader.md), and [Risk Manager](../Orchestrators/RiskManager.md).

```
measure spread + volatility  ─▶  pick a playbook  ─▶  (a real preset launches it)
```

---

## 🧠 Decision logic

Two signals drive the choice:

* **spread** (in points) — how costly/illiquid the market is right now.
* **ATR proxy** — the average H1 high-low range over the last 24 bars (a volatility estimate).

| Condition | Pick | Why |
|-----------|------|-----|
| spread > 50 pts | **[14] Risk Manager** | costly/illiquid — don't enter actively, just watch risk |
| ATR > 400 pts | **[11] Trailing Stop** | strong directional moves — ride them, protect profit |
| otherwise (calm) | **[13] Grid Trader** | range-bound chop — harvest the range with a grid |

---

## 🧱 Composed from (MT5Sugar)

| Step | Methods |
|------|---------|
| **Signals** | [`spread`](../../MT5Sugar/4.%20Prices_Quotes.md) · [`bars`](../../MT5Sugar/10.%20Symbol_Information.md) · [`symbol_point`](../../MT5Sugar/10.%20Symbol_Information.md) |
| **Decide** | pure Ruby — map signals to a recommendation |

---

## 🔧 Code walkthrough

```ruby
point = sugar.symbol_point(sym)

# 1. SIGNALS
spread_pts = (sugar.spread(sym) / point).round
bars = sugar.bars(sym, timeframe: :H1, max_bars: 24)
ranges  = bars.map { |b| (b.high - b.low) / point }
atr_pts = ranges.empty? ? 0 : (ranges.sum / ranges.size).round

# 2. DECIDE
pick =
  if    spread_pts > 50 then "14 Risk manager"
  elsif atr_pts    > 400 then "11 Trailing stop"
  else                       "13 Grid trader"
  end
puts "→ run demo [#{pick}]"
```

---

## ⚙️ Tunables

| Name | Meaning |
|------|---------|
| spread threshold (`50`) | above this, the market is treated as too costly to enter |
| ATR threshold (`400`) | above this, the market is treated as "trending/volatile" |
| H1 lookback (`24`) | how many bars feed the volatility estimate |

**Make it real:** instead of printing the pick, **launch** the chosen orchestrator (call its block), and re-evaluate on a schedule so the bot adapts as conditions change.

---

## ⚠️ Safety

Fully read-only — it only analyses and prints a recommendation. Nothing is traded.

---

## 📚 See also

* Orchestrators it routes to: [Trailing Stop](../Orchestrators/TrailingStop.md) · [Grid Trader](../Orchestrators/GridTrader.md) · [Risk Manager](../Orchestrators/RiskManager.md)
* [MT5Sugar · Symbol Information](../../MT5Sugar/10.%20Symbol_Information.md) · [Prices & Quotes](../../MT5Sugar/4.%20Prices_Quotes.md)

**Back to:** [Strategies — Master Overview](../Strategies.Master.Overview.md)
