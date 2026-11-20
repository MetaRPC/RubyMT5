# 🔢 One Double Symbol Property

> **Request:** a single floating-point symbol property (`SymbolInfoDoubleData`) — point, bid/ask, volume limits, tick value, swaps… — selected by an enum.

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_double(symbol, property)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoDouble` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoDouble(SymbolInfoDoubleRequest) → SymbolInfoDoubleReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_info_double(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning a single `Float` symbol metric, chosen by a property enum.
* **Why you need it.** Grab just one number — the point size for pip math, the min lot for sizing, the tick value for risk — without pulling the whole spec.
* **Sanity check.** `symbol_info_double("EURUSD", :SYMBOL_POINT)` is a small positive number (e.g. `1.0e-05`).

---

## 🎯 Purpose

Read **one** double property when that's all you need. For many values at once, [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md) returns the full `SymbolParameters` in a single call — cheaper than many single reads.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # One SYMBOL_* double property. `property` is a SymbolInfoDoubleProperty symbol.
  def symbol_info_double(symbol, property) -> Float
end
```

**Request message:** `SymbolInfoDoubleRequest { string symbol = 1; SymbolInfoDoubleProperty type = 2; }`
**Reply:** the SDK returns `data.value` (a `Float`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol, e.g. `"EURUSD"`. |
| `property` | `Symbol` *(SymbolInfoDoubleProperty)* | Which double property to read. |

## ⬆️ Output

A single `Float`.

---

## 🧱 Property enum — `SymbolInfoDoubleProperty` (all 60 values)

Pass any of these as the `property` symbol (e.g. `:SYMBOL_POINT`):

```protobuf
SYMBOL_BID                        = 0    // best bid
SYMBOL_BIDHIGH                    = 1
SYMBOL_BIDLOW                     = 2
SYMBOL_ASK                        = 3    // best ask
SYMBOL_ASKHIGH                    = 4
SYMBOL_ASKLOW                     = 5
SYMBOL_LAST                       = 6    // last deal price
SYMBOL_LASTHIGH                   = 7
SYMBOL_LASTLOW                    = 8
SYMBOL_VOLUME_REAL                = 9
SYMBOL_VOLUMEHIGH_REAL            = 10
SYMBOL_VOLUMELOW_REAL             = 11
SYMBOL_OPTION_STRIKE              = 12
SYMBOL_POINT                      = 13   // point size (pip = point × 10 on 3/5-digit symbols)
SYMBOL_TRADE_TICK_VALUE           = 14   // value of one tick (account currency)
SYMBOL_TRADE_TICK_VALUE_PROFIT    = 15
SYMBOL_TRADE_TICK_VALUE_LOSS      = 16
SYMBOL_TRADE_TICK_SIZE            = 17   // minimal price change
SYMBOL_TRADE_CONTRACT_SIZE        = 18   // contract size (units per lot)
SYMBOL_TRADE_ACCRUED_INTEREST     = 19
SYMBOL_TRADE_FACE_VALUE           = 20
SYMBOL_TRADE_LIQUIDITY_RATE       = 21
SYMBOL_VOLUME_MIN                 = 22   // minimum lot
SYMBOL_VOLUME_MAX                 = 23   // maximum lot
SYMBOL_VOLUME_STEP                = 24   // lot step
SYMBOL_VOLUME_LIMIT               = 25
SYMBOL_SWAP_LONG                  = 26   // swap for long positions
SYMBOL_SWAP_SHORT                 = 27   // swap for short positions
SYMBOL_SWAP_SUNDAY                = 28
SYMBOL_SWAP_MONDAY                = 29
SYMBOL_SWAP_TUESDAY               = 30
SYMBOL_SWAP_WEDNESDAY             = 31
SYMBOL_SWAP_THURSDAY              = 32
SYMBOL_SWAP_FRIDAY                = 33
SYMBOL_SWAP_SATURDAY              = 34
SYMBOL_MARGIN_INITIAL             = 35   // initial margin
SYMBOL_MARGIN_MAINTENANCE         = 36
SYMBOL_SESSION_VOLUME             = 37
SYMBOL_SESSION_TURNOVER           = 38
SYMBOL_SESSION_INTEREST           = 39
SYMBOL_SESSION_BUY_ORDERS_VOLUME  = 40
SYMBOL_SESSION_SELL_ORDERS_VOLUME = 41
SYMBOL_SESSION_OPEN               = 42
SYMBOL_SESSION_CLOSE              = 43
SYMBOL_SESSION_AW                 = 44
SYMBOL_SESSION_PRICE_SETTLEMENT   = 45
SYMBOL_SESSION_PRICE_LIMIT_MIN    = 46
SYMBOL_SESSION_PRICE_LIMIT_MAX    = 47
SYMBOL_MARGIN_HEDGED              = 48
SYMBOL_PRICE_CHANGE               = 49
SYMBOL_PRICE_VOLATILITY           = 50
SYMBOL_PRICE_THEORETICAL          = 51
SYMBOL_PRICE_DELTA                = 52   // option Greeks (53–58)
SYMBOL_PRICE_THETA                = 53
SYMBOL_PRICE_GAMMA                = 54
SYMBOL_PRICE_VEGA                 = 55
SYMBOL_PRICE_RHO                  = 56
SYMBOL_PRICE_OMEGA                = 57
SYMBOL_PRICE_SENSITIVITY          = 58
SYMBOL_COUNT                      = 59
```

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure; wrap in `begin/rescue`.
* **Select uncommon symbols first** ([`symbol_select`](./SymbolSelect.md)) — an unselected symbol may return stale values.
* **Pip vs point:** on 5/3-digit symbols a pip is `10 × point`.
* **Prefer the full spec** for 3+ values: [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md).

---

## 🔗 Usage Examples

### 1) Point & lot limits

```ruby
point    = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
vol_min  = acct.symbol_info_double("EURUSD", :SYMBOL_VOLUME_MIN)
vol_step = acct.symbol_info_double("EURUSD", :SYMBOL_VOLUME_STEP)
puts "point #{point}  min lot #{vol_min}  step #{vol_step}"
```

### 2) Pip size

```ruby
digits = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
pip = acct.symbol_info_double("EURUSD", :SYMBOL_POINT) * ([3, 5].include?(digits) ? 10 : 1)
puts "1 pip = #{pip}"
```

### 3) Round a stop to the point grid

```ruby
pt = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
raw_sl = 1.094237
sl = (raw_sl / pt).round * pt
puts sl
```

### 4) Current bid/ask via properties

```ruby
bid = acct.symbol_info_double("EURUSD", :SYMBOL_BID)
ask = acct.symbol_info_double("EURUSD", :SYMBOL_ASK)
puts "spread #{(ask - bid).round(5)}"
```

---

## 🔧 Common Patterns

### Cache the sizing constants

```ruby
def sizing(acct, sym)
  {
    point: acct.symbol_info_double(sym, :SYMBOL_POINT),
    tick_value: acct.symbol_info_double(sym, :SYMBOL_TRADE_TICK_VALUE),
    vol_min: acct.symbol_info_double(sym, :SYMBOL_VOLUME_MIN),
    vol_step: acct.symbol_info_double(sym, :SYMBOL_VOLUME_STEP),
  }
end
```

---

## 📚 See Also

* [SymbolInfoInteger](./SymbolInfoInteger.md) · [SymbolInfoString](./SymbolInfoString.md) · [SymbolInfoTick](./SymbolInfoTick.md)
* [SymbolParamsMany](../6.%20Additional_Methods/SymbolParamsMany.md) — the full spec in one call.
* **Friendly layer:** [`MT5Service#symbol_params`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
