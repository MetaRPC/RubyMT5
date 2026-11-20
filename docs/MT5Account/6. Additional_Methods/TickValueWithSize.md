# 🧮 Tick Value / Size / Contract

> **Request:** tick value, tick size and contract size for one or more symbols (`TickValueWithSizeData`) — the numbers you need to size a position in money terms.

**API Information:**

* **Low-level API:** `MT5Account#tick_value_with_size(symbols)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountHelper`
* **Proto definition:** `TickValueWithSize` (defined in `mt5-term-api-account-helper.proto`)

### RPC

* **Service:** `mt5_term_api.AccountHelper`
* **Method:** `TickValueWithSize(TickValueWithSizeRequest) → TickValueWithSizeReply`
* **Low-level client (generated):** `Mt5TermApi::AccountHelper::Stub#tick_value_with_size(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the sizing triple — tick value, tick size, contract size — for one symbol or a batch.
* **Why you need it.** Convert a stop distance in points into money, and a money risk into a lot size.
* **Sanity check.** For EURUSD on a USD account, `TradeTickValue` ≈ `1.0` and `TradeTickSize` ≈ `1.0e-05`.

---

## 🎯 Purpose

`tick_value_with_size` is the **risk-sizing** read: with tick value and tick size you know the money value of one point, and with contract size you can reason about exposure — the basis for "how many lots for $X of risk?".

> ⚠️ **PascalCase gotcha:** each `TickSizeSymbol` entry exposes **PascalCase** accessors — `tv.TradeTickValue`, not `tv.trade_tick_value`.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # `symbols` is a String or an Array of symbol names.
  def tick_value_with_size(symbols) -> Mt5TermApi::TickValueWithSizeData
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbols` | `String` or `[String]` | One symbol or several. |

## ⬆️ Output — `TickValueWithSizeData`

* **`symbol_tick_size_infos`** → array of `TickSizeSymbol`:

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `Name` | `String` | Symbol. |
| `TradeTickValue` | `Float` | Value of one tick (account currency). |
| `TradeTickValueProfit` | `Float` | Tick value for a profitable position. |
| `TradeTickValueLoss` | `Float` | Tick value for a losing position. |
| `TradeTickSize` | `Float` | Minimal price change. |
| `TradeContractSize` | `Float` | Contract size (units per lot). |

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **PascalCase accessors** — capital `T` (`TradeTickValue`), same style as `SymbolListData.Symbols`.
* **Money per point** ≈ `TradeTickValue × (point / TradeTickSize)`, where `point` is `symbol_info_double(sym, :SYMBOL_POINT)`.

---

## 🔗 Usage Examples

### 1) One symbol

```ruby
tv = acct.tick_value_with_size("EURUSD").symbol_tick_size_infos.first
puts "tick value #{tv.TradeTickValue}  tick size #{tv.TradeTickSize}  contract #{tv.TradeContractSize}"
```

### 2) Several at once

```ruby
acct.tick_value_with_size(%w[EURUSD GBPUSD XAUUSD]).symbol_tick_size_infos.each do |x|
  puts "#{x.Name}: #{x.TradeTickValue}"
end
```

### 3) Money value of one point

```ruby
tv = acct.tick_value_with_size("EURUSD").symbol_tick_size_infos.first
pt = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
puts (tv.TradeTickValue * (pt / tv.TradeTickSize)).round(4)
```

---

## 🔧 Common Patterns

### Lots for a fixed point-risk

```ruby
def lots_for_risk(acct, sym, stop_points, risk_money)
  tv   = acct.tick_value_with_size(sym).symbol_tick_size_infos.first
  pt   = acct.symbol_info_double(sym, :SYMBOL_POINT)
  per_point_per_lot = tv.TradeTickValue * (pt / tv.TradeTickSize)
  step = acct.symbol_info_double(sym, :SYMBOL_VOLUME_STEP)
  raw  = risk_money / (stop_points * per_point_per_lot)
  (raw / step).floor * step
end
```

---

## 📚 See Also

* [SymbolParamsMany](./SymbolParamsMany.md) — the full spec · [OrderCalcProfit](../4.%20Trading_Operations/OrderCalcProfit.md).
* **Friendly layer:** [`MT5Service#tick_value_with_size`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Additional Methods — Overview](./Additional_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
