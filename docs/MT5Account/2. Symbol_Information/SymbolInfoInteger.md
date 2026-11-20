# 🔢 One Integer Symbol Property

> **Request:** a single integer symbol property (`SymbolInfoIntegerData`) — digits, spread, stops level, trade mode… — selected by an enum.

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_integer(symbol, property)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoInteger` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoInteger(SymbolInfoIntegerRequest) → SymbolInfoIntegerReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_info_integer(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning a single `Integer` symbol property, chosen by a property enum.
* **Why you need it.** The two you'll reach for most: `:SYMBOL_DIGITS` (how many decimals to round prices to) and `:SYMBOL_TRADE_STOPS_LEVEL` (the minimum SL/TP distance).
* **Sanity check.** `symbol_info_integer("EURUSD", :SYMBOL_DIGITS)` is `5` on most 5-digit FX feeds.

---

## 🎯 Purpose

Read **one** integer property on demand. `:SYMBOL_DIGITS` and `:SYMBOL_TRADE_STOPS_LEVEL` are the pre-trade essentials — round prices to the right precision and keep SL/TP outside the freeze/stops distance so orders aren't rejected.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # One SYMBOL_* integer property. `property` is a SymbolInfoIntegerProperty symbol.
  def symbol_info_integer(symbol, property) -> Integer
end
```

**Request message:** `SymbolInfoIntegerRequest { string symbol = 1; SymbolInfoIntegerProperty type = 2; }`
**Reply:** the SDK returns `data.value` (an `Integer`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol, e.g. `"EURUSD"`. |
| `property` | `Symbol` *(SymbolInfoIntegerProperty)* | Which integer property to read. |

## ⬆️ Output

A single `Integer` (some properties encode an enum but return as a number).

---

## 🧱 Property enum — `SymbolInfoIntegerProperty` (all 37 values)

Pass any of these as the `property` symbol (e.g. `:SYMBOL_DIGITS`):

```protobuf
SYMBOL_SUBSCRIPTION_DELAY    = 0
SYMBOL_SECTOR                = 1    // result enum: BMT5_ENUM_SYMBOL_SECTOR (14)
SYMBOL_INDUSTRY              = 2    // result enum: BMT5_ENUM_SYMBOL_INDUSTRY (152)
SYMBOL_CUSTOM                = 3
SYMBOL_BACKGROUND_COLOR      = 4
SYMBOL_CHART_MODE            = 5
SYMBOL_EXIST                 = 6
SYMBOL_SELECT                = 7    // selected in Market Watch (0/1)
SYMBOL_VISIBLE               = 8    // visible in Market Watch (0/1)
SYMBOL_SESSION_DEALS         = 9
SYMBOL_SESSION_BUY_ORDERS    = 10
SYMBOL_SESSION_SELL_ORDERS   = 11
SYMBOL_VOLUME                = 12
SYMBOL_VOLUMEHIGH            = 13
SYMBOL_VOLUMELOW             = 14
SYMBOL_TIME                  = 15
SYMBOL_TIME_MSC              = 16
SYMBOL_DIGITS                = 17   // price decimal places
SYMBOL_SPREAD_FLOAT          = 18   // floating spread (0/1)
SYMBOL_SPREAD                = 19   // current spread in points
SYMBOL_TICKS_BOOKDEPTH       = 20
SYMBOL_TRADE_CALC_MODE       = 21   // margin calc mode
SYMBOL_TRADE_MODE            = 22   // trading mode (disabled / long-only / full …)
SYMBOL_START_TIME            = 23
SYMBOL_EXPIRATION_TIME       = 24
SYMBOL_TRADE_STOPS_LEVEL     = 25   // min SL/TP distance from price (points)
SYMBOL_TRADE_FREEZE_LEVEL    = 26   // freeze distance (points)
SYMBOL_TRADE_EXEMODE         = 27
SYMBOL_SWAP_MODE             = 28
SYMBOL_SWAP_ROLLOVER3DAYS    = 29
SYMBOL_MARGIN_HEDGED_USE_LEG = 30
SYMBOL_EXPIRATION_MODE       = 31
SYMBOL_FILLING_MODE          = 32   // allowed filling modes bitmask
SYMBOL_ORDER_MODE            = 33
SYMBOL_ORDER_GTC_MODE        = 34
SYMBOL_OPTION_MODE           = 35
SYMBOL_OPTION_RIGHT          = 36
```

> **Result enums:** `:SYMBOL_SECTOR` and `:SYMBOL_INDUSTRY` return a *code* (a plain `Integer`) from `BMT5_ENUM_SYMBOL_SECTOR` / `BMT5_ENUM_SYMBOL_INDUSTRY` — map it yourself, or read the already-typed `SymbolParameters.sector` / `.industry` from `symbol_params_many`. See the [ENUMs Reference](../../All_Guides/ENUMS_USAGE_REFERENCE.md).

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **`:SYMBOL_DIGITS`** → how many decimals to round prices to before sending an order.
* **`:SYMBOL_TRADE_STOPS_LEVEL`** → the minimum SL/TP distance in points; orders inside it are rejected.
* **Boolean-ish flags** (`:SYMBOL_VISIBLE`, `:SYMBOL_SELECT`) come back as `0`/`1`.

---

## 🔗 Usage Examples

### 1) Digits & stops level

```ruby
digits = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
stops  = acct.symbol_info_integer("EURUSD", :SYMBOL_TRADE_STOPS_LEVEL)
puts "digits #{digits}  min stop #{stops} pts"
```

### 2) Round a price to the symbol's digits

```ruby
digits = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
price  = 1.0942371
puts price.round(digits)
```

### 3) Validate an SL distance before sending

```ruby
pt    = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
stops = acct.symbol_info_integer("EURUSD", :SYMBOL_TRADE_STOPS_LEVEL)
bid   = acct.symbol_info_tick("EURUSD").bid
sl    = bid - 300 * pt
ok    = (bid - sl) >= stops * pt
puts ok ? "SL ok" : "SL too close (min #{stops} pts)"
```

### 4) Is the symbol visible?

```ruby
puts acct.symbol_info_integer("EURUSD", :SYMBOL_VISIBLE) == 1 ? "visible" : "hidden"
```

---

## 🔧 Common Patterns

### Price-rounding helper

```ruby
def round_price(acct, sym, price)
  price.round(acct.symbol_info_integer(sym, :SYMBOL_DIGITS))
end
```

---

## 📚 See Also

* [SymbolInfoDouble](./SymbolInfoDouble.md) · [SymbolInfoString](./SymbolInfoString.md) · [SymbolInfoTick](./SymbolInfoTick.md)
* [SymbolParamsMany](../6.%20Additional_Methods/SymbolParamsMany.md) — the full spec in one call.
* **Friendly layer:** [`MT5Sugar#symbol_digits` / `#min_stop_level`](../../MT5Sugar/MT5Sugar.API_Overview.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
