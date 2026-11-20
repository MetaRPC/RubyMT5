# 💱 Margin Rates for an Order Type

> **Request:** the initial and maintenance margin rates for a symbol at a given order type (`SymbolInfoMarginRateData`).

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_margin_rate(symbol, order_type)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoMarginRate` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoMarginRate(SymbolInfoMarginRateRequest) → SymbolInfoMarginRateReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_info_margin_rate(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the margin **multipliers** (initial / maintenance) the broker applies to a symbol for a given order type.
* **Why you need it.** Explain why margin differs between order types, or feed a custom margin model.
* **Sanity check.** `initial_margin_rate` is typically `1.0` for a plain market order on FX.

---

## 🎯 Purpose

`symbol_info_margin_rate` exposes the per-order-type margin **rates** behind [`order_calc_margin`](../4.%20Trading_Operations/OrderCalcMargin.md). Pending/limit/stop types can carry different rates than market orders — read them when you need the exact multiplier rather than the final figure.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # order_type: :buy / :sell / :buy_limit / ... (mapped to the MQL ORDER_TYPE_* enum),
  # or a raw :ORDER_TYPE_* symbol.
  def symbol_info_margin_rate(symbol, order_type) -> Mt5TermApi::SymbolInfoMarginRateData
end
```

> ⚠️ **Enum gotcha (third one!):** this RPC uses the **MQL `ENUM_ORDER_TYPE`** (`ORDER_TYPE_BUY`, `ORDER_TYPE_SELL`, …) — *not* `order_send`'s `TMT5_ORDER_TYPE_*` and *not* the calculators' `ORDER_TYPE_TF_*`. The SDK maps friendly `:buy` / `:sell` symbols to `:ORDER_TYPE_BUY` for you.

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol. |
| `order_type` | `Symbol` | `:buy` / `:sell` / `:buy_limit` / … (or a raw `:ORDER_TYPE_*`). |

## ⬆️ Output — `SymbolInfoMarginRateData`

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `initial_margin_rate` | `Float` | Initial margin multiplier. |
| `maintenance_margin_rate` | `Float` | Maintenance margin multiplier. |

---

## 🧱 Enum values

### `order_type` → `ENUM_ORDER_TYPE` (MQL)

The method accepts a **friendly** symbol (it upcases `:buy` → `:ORDER_TYPE_BUY`) — or pass the raw `ORDER_TYPE_*` symbol directly:

| Friendly `order_type` | Raw enum | # |
|---|---|---|
| `:buy` | `ORDER_TYPE_BUY` | 0 |
| `:sell` | `ORDER_TYPE_SELL` | 1 |
| `:buy_limit` | `ORDER_TYPE_BUY_LIMIT` | 2 |
| `:sell_limit` | `ORDER_TYPE_SELL_LIMIT` | 3 |
| `:buy_stop` | `ORDER_TYPE_BUY_STOP` | 4 |
| `:sell_stop` | `ORDER_TYPE_SELL_STOP` | 5 |
| `:buy_stop_limit` | `ORDER_TYPE_BUY_STOP_LIMIT` | 6 |
| `:sell_stop_limit` | `ORDER_TYPE_SELL_STOP_LIMIT` | 7 |
| `:close_by` | `ORDER_TYPE_CLOSE_BY` | 8 |

> This is the **MQL** `ENUM_ORDER_TYPE` (no prefix) — distinct from `order_send`'s `TMT5_ENUM_ORDER_TYPE` and the calculators' `ENUM_ORDER_TYPE_TF`.

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Want the money figure, not the rate?** Use [`order_calc_margin`](../4.%20Trading_Operations/OrderCalcMargin.md) — it applies these rates for you.
* **Rates can be 0** on some instruments/types — don't divide by them blindly.

---

## 🔗 Usage Examples

### 1) Initial / maintenance for a buy

```ruby
mr = acct.symbol_info_margin_rate("EURUSD", :buy)
puts "initial #{mr.initial_margin_rate}  maintenance #{mr.maintenance_margin_rate}"
```

### 2) Compare buy vs sell

```ruby
%i[buy sell].each do |t|
  puts "#{t}: #{acct.symbol_info_margin_rate('EURUSD', t).initial_margin_rate}"
end
```

### 3) Pending vs market

```ruby
%i[buy buy_limit buy_stop].each do |t|
  puts "#{t}: #{acct.symbol_info_margin_rate('EURUSD', t).initial_margin_rate}"
end
```

---

## 🔧 Common Patterns

### Margin-rate table for a symbol

```ruby
def margin_rates(acct, sym)
  %i[buy sell buy_limit sell_limit buy_stop sell_stop].to_h do |t|
    [t, acct.symbol_info_margin_rate(sym, t).initial_margin_rate]
  end
end
```

---

## 📚 See Also

* [OrderCalcMargin](../4.%20Trading_Operations/OrderCalcMargin.md) — margin for a concrete order.
* [TickValueWithSize](./TickValueWithSize.md) · [SymbolParamsMany](./SymbolParamsMany.md)
* **Friendly layer:** [`MT5Service#margin_rate`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Additional Methods — Overview](./Additional_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
