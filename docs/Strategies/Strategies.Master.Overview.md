# Strategies — Master Overview

> Orchestrators and presets built on **[MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md)** — small, readable strategy demos you can run and adapt.

---

## ⚠️ Educational demos only

Every orchestrator and preset here is a **demonstration template**, not a production trading system. They use simple signals, no real risk engine, and fixed parameters. **Run them on a demo account.** Before anything live: understand the algorithm, backtest, forward-test, and add real risk management.

---

## 🧩 What's an orchestrator vs a preset?

* **Orchestrator** — composes several [`MT5Sugar`](../MT5Sugar/MT5Sugar.API_Overview.md) one-liners into **one full strategy lifecycle** (open → manage → close). It runs a single playbook.
* **Preset** — the layer **above** orchestrators: it reads the market and **picks which orchestrator** fits right now. The "brain" / router.

```
Preset  ─ reads conditions ─▶  picks an Orchestrator  ─ composes ─▶  MT5Sugar one-liners
```

---

## 📁 Orchestrators

| # | Strategy | Idea | Trades? |
|---|----------|------|---------|
| 11 | **[Trailing Stop](./Orchestrators/TrailingStop.md)** | open, then ratchet the stop-loss up behind price, lock in profit | ⚠ yes (demo) |
| 13 | **[Grid Trader](./Orchestrators/GridTrader.md)** | bracket the market with pending limits + stops, then remove them | ⚠ yes (demo) |
| 14 | **[Risk Manager](./Orchestrators/RiskManager.md)** | monitor floating drawdown, flatten everything on breach (kill-switch) | dry-run by default |

## 📁 Presets

| # | Preset | Idea |
|---|--------|------|
| 16 | **[Adaptive Market Mode](./Presets/AdaptiveMarketMode.md)** | measure spread + volatility → recommend trailing / grid / risk-manager |

---

## ▶️ Running them

All are registered demos — launch from the interactive menu or directly:

```bash
ruby examples/demos/main.rb         # menu
ruby examples/demos/main.rb 11      # trailing stop
ruby examples/demos/main.rb 16      # adaptive preset (read-only)
```

Credentials come from `examples/demos/config/config.json` or the `MT5_*` env vars (see [Getting Started](../All_Guides/GETTING_STARTED.md)).

---

## 📚 See also

* **High-level API:** [MT5Sugar — API Overview](../MT5Sugar/MT5Sugar.API_Overview.md) — the one-liners these compose.
* **Reference:** [Return Codes](../All_Guides/RETURN_CODES_REFERENCE.md).
