# MT5Account · Symbol Information — Overview

> Live quotes, symbol properties and Market-Watch management. Read a tick, a single symbol property, or check existence / sync state — all on `mt5_term_api.MarketInfo`.

These methods are **read-only** except `symbol_select` (which toggles a symbol in Market Watch). Each returns the raw `*Data` (snake_case accessors) or a plain value, or raises `ApiError`.

## 📁 What lives here

| Method | What it does |
|--------|--------------|
| **[SymbolsTotal](./SymbolsTotal.md)** | count of symbols (all, or Market-Watch only) |
| **[SymbolExist](./SymbolExist.md)** | does a symbol exist on the server? |
| **[SymbolName](./SymbolName.md)** | symbol name by index |
| **[SymbolSelect](./SymbolSelect.md)** | add / remove a symbol from Market Watch |
| **[SymbolIsSynchronized](./SymbolIsSynchronized.md)** | is the symbol's data synced with the server? |
| **[SymbolInfoDouble](./SymbolInfoDouble.md)** | one SYMBOL_* double property (point, volume_min…) |
| **[SymbolInfoInteger](./SymbolInfoInteger.md)** | one SYMBOL_* integer property (digits, spread…) |
| **[SymbolInfoString](./SymbolInfoString.md)** | one SYMBOL_* string property (description, base currency…) |
| **[SymbolInfoTick](./SymbolInfoTick.md)** | the latest tick (bid / ask / last / time) |

---

## 🧭 Plain English

* Prices come from **`symbol_info_tick`** — not from the symbol spec. For the full contract spec in one call use [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md).
* **`symbol_info_double / integer / string`** read one property at a time (point, digits, stops level, currencies…).
* **`symbol_select(sym, true)`** makes a symbol visible in Market Watch — required before some reads on symbols the terminal hasn't loaded yet.

> Rule of thumb: need **a price** → `symbol_info_tick`; need **one property** → `symbol_info_*`; need **the whole spec** → `symbol_params_many`.

---

## Quick choose

| If you need…                         | Use                     | Returns |
| ------------------------------------ | ----------------------- | ------- |
| Bid / ask / last right now           | `symbol_info_tick`      | `MrpcMqlTick` |
| How many symbols exist               | `symbols_total`         | `Integer` |
| Whether a symbol exists              | `symbol_exist`          | `Boolean` |
| A symbol name by index               | `symbol_name`           | `String` |
| Show/hide in Market Watch            | `symbol_select`         | `Boolean` |
| Sync state                           | `symbol_is_synchronized`| `Boolean` |
| One numeric property                 | `symbol_info_double`    | `Float` |
| One integer property                 | `symbol_info_integer`   | `Integer` |
| One text property                    | `symbol_info_string`    | `String` |

---

## ❌ Cross-refs & gotchas

* **`symbol_info_tick.last` is often `0`** on FX — use `bid` / `ask`.
* **Select before reading** uncommon symbols: `symbol_select(sym)` then read.
* **Pip vs point:** on 5/3-digit symbols a pip = `10 × point`. `point` comes from `symbol_info_double(:SYMBOL_POINT)`.
* **Full spec** (lot limits, stops level, currencies) → [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md) is one call for everything.

---

## 🟢 Minimal snippets

```ruby
t = acct.symbol_info_tick("EURUSD")
puts "bid #{t.bid}  ask #{t.ask}  spread #{(t.ask - t.bid).round(5)}"

digits = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
point  = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
puts "digits #{digits}  point #{point}"

acct.symbol_select("GBPUSD", true)          # ensure it's in Market Watch
puts "exists? #{acct.symbol_exist('GBPUSD')}  synced? #{acct.symbol_is_synchronized('GBPUSD')}"
```

---

## See also

* **Account:** [Account Information — Overview](../1.%20Account_Information/Account_Information.Overview.md)
* **Full spec / sizing:** [Additional Methods — Overview](../6.%20Additional_Methods/Additional_Methods.Overview.md)
* **Friendly layer:** [`MT5Service#quote` / `#symbol_params`](../../MT5Service/MT5Service.Overview.md).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
