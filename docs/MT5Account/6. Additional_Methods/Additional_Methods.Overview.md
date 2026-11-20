# MT5Account · Additional Methods — Overview

> Batch symbol specs, tick value for sizing, margin rates and trading sessions. These round out the symbol/market reads that don't fit the basic Symbol-Information group.

Mixed services: `symbol_params_many` / `tick_value_with_size` on `AccountHelper`; `symbol_info_margin_rate` / `symbol_info_session_quote` / `symbol_info_session_trade` on `MarketInfo`.

## 📁 What lives here

| Method | What it does |
|--------|--------------|
| **[SymbolParamsMany](./SymbolParamsMany.md)** | full contract spec of **every** symbol in one call |
| **[TickValueWithSize](./TickValueWithSize.md)** | tick value / size / contract size for sizing |
| **[SymbolInfoMarginRate](./SymbolInfoMarginRate.md)** | initial / maintenance margin rates for an order type |
| **[SymbolInfoSessionQuote](./SymbolInfoSessionQuote.md)** | quote session [from, to) for a weekday |
| **[SymbolInfoSessionTrade](./SymbolInfoSessionTrade.md)** | trade session [from, to) for a weekday |

---

## 🧭 Plain English

* **`symbol_params_many`** → the heavy one: one call returns the full `SymbolParameters` for all symbols (digits, point, lot limits, swaps, margins, currencies…). Cache it.
* **`tick_value_with_size`** → the numbers you need to size a position (tick value / tick size / contract size).
* **`symbol_info_margin_rate`** → margin multipliers per order type.
* **session_quote / session_trade** → when a symbol quotes / trades on a given weekday.

---

## Quick choose

| If you need…                         | Use                        | Returns |
| ------------------------------------ | -------------------------- | ------- |
| Full spec of all symbols             | `symbol_params_many`       | `[SymbolParameters]` |
| Tick value / size / contract         | `tick_value_with_size`     | `TickValueWithSizeData` |
| Margin rates for an order type       | `symbol_info_margin_rate`  | `SymbolInfoMarginRateData` |
| Quote session times                  | `symbol_info_session_quote`| `SymbolInfoSessionQuoteData` |
| Trade session times                  | `symbol_info_session_trade`| `SymbolInfoSessionTradeData` |

---

## 🟢 Minimal snippet

```ruby
spec = acct.symbol_params_many.find { |s| s.name == "EURUSD" }
puts "digits #{spec.digits}  min #{spec.volume_min}  step #{spec.volume_step}"

mr = acct.symbol_info_margin_rate("EURUSD", :buy)
puts "initial #{mr.initial_margin_rate}  maintenance #{mr.maintenance_margin_rate}"
```

---

## See also

* **Basics:** [Symbol Information — Overview](../2.%20Symbol_Information/Symbol_Information.Overview.md).
* **Friendly layer:** [`MT5Service#symbol_params_all` / `#margin_rate` / `#session_quote`](../../MT5Service/MT5Service.Overview.md).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
