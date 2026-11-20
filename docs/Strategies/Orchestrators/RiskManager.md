# 🛡️ Risk Manager Orchestrator

> Monitor the account and flatten everything if floating drawdown breaches a limit — a kill-switch you run **alongside** a trading strategy. Safe by default (dry-run).

**Demo:** `examples/demos/orchestrators/14_risk_manager.rb` · **Run:** `ruby examples/demos/main.rb 14`

---

## 💡 What it is

The other orchestrators open trades; this one **protects** them. It polls the account and, once unrealized losses get too big, closes every position to cap the damage. In practice it runs in parallel with whatever strategy is trading.

---

## 🧠 Strategy logic

Floating drawdown is unrealized loss as a fraction of balance:

```
floating = equity − balance
drawdown = max(0, −floating) / balance
```

On each check it recomputes `drawdown`; once it crosses `max_drawdown`, the **kill-switch fires** → `close_all_positions`. With `dry_run = true` (the default) it only reports what *would* happen, so the demo never closes anything.

---

## 🧱 Composed from (MT5Sugar)

| Step | Methods |
|------|---------|
| **Monitor** | [`balance`](../../MT5Sugar/2.%20Balance_Margin.md) · [`equity`](../../MT5Sugar/2.%20Balance_Margin.md) · [`count_positions`](../../MT5Sugar/8.%20Position_Information.md) |
| **Enforce** | [`close_all_positions`](../../MT5Sugar/7.%20Position_Management.md) |

---

## 🔧 Code walkthrough

```ruby
dry_run = true          # true = report only
max_drawdown = 0.50     # fire at 50% of balance lost (floating)

checks.times do
  sleep 1
  balance  = sugar.balance
  equity   = sugar.equity
  floating = equity - balance
  dd = balance.zero? ? 0.0 : (floating.negative? ? -floating / balance : 0.0)

  if dd >= max_drawdown
    sugar.close_all_positions unless dry_run   # kill-switch
    break
  end
end
```

---

## ⚙️ Tunables

| Name | Meaning |
|------|---------|
| `dry_run` | `true` = report only · `false` = actually flatten |
| `max_drawdown` | drawdown fraction that fires the switch (e.g. `0.10` = 10%) |
| `checks` | how many times the demo polls |

**Make it real:** replace the fixed `checks` loop with an [`on_position_profit`](../../MT5Sugar/13.%20Streaming.md) stream so the switch reacts live, and run it as a separate supervisor thread next to your strategy.

---

## ⚠️ Safety

Read-only by default (`dry_run = true`) — it never closes anything until you arm it. When armed, `close_all_positions` is irreversible. Demo accounts only.

---

## 📚 See also

* [Trailing Stop](./TrailingStop.md) · [Grid Trader](./GridTrader.md) · [Adaptive Preset](../Presets/AdaptiveMarketMode.md)
* [MT5Sugar · Position Management](../../MT5Sugar/7.%20Position_Management.md) · [Balance & Margin](../../MT5Sugar/2.%20Balance_Margin.md)

**Back to:** [Strategies — Master Overview](../Strategies.Master.Overview.md)
