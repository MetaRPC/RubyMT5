# 📈 Calculating Profit of a Move

> **Request:** the profit of a hypothetical round-trip (`OrderCalcProfitData`) — open at one price, close at another — without trading.

**API Information:**

* **Low-level API:** `MT5Account#order_calc_profit(symbol:, type:, volume:, open_price:, close_price:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.TradeFunctions`
* **Proto definition:** `OrderCalcProfit` (defined in `mt5-term-api-trade-functions.proto`)

### RPC

* **Service:** `mt5_term_api.TradeFunctions`
* **Method:** `OrderCalcProfit(OrderCalcProfitRequest) → OrderCalcProfitReply`
* **Low-level client (generated):** `Mt5TermApi::TradeFunctions::Stub#order_calc_profit(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the profit (account currency) if `volume` lots of `symbol` move from `open_price` to `close_price`.
* **Why you need it.** Price a stop-loss or take-profit in money terms, size to a fixed risk, or compute a trade's risk/reward.
* **Sanity check.** A `:buy` with `close_price > open_price` returns a positive number.

---

## 🎯 Purpose

`order_calc_profit` turns a **price move into money** — the complement of [`order_calc_margin`](./OrderCalcMargin.md). Use it to translate a stop distance into risk, a target into reward, and to size a position so a stop costs a fixed amount.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # type: :buy / :sell / ... (mapped to ORDER_TYPE_TF_*).
  def order_calc_profit(symbol:, type:, volume:, open_price:, close_price:) -> Float
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` *(keyword)* | Symbol. |
| `type` | `Symbol` *(keyword)* | `:buy` / `:sell` / … |
| `volume` | `Float` *(keyword)* | Lots. |
| `open_price` | `Float` *(keyword)* | Hypothetical entry price. |
| `close_price` | `Float` *(keyword)* | Hypothetical exit price. |

## ⬆️ Output

A `Float` — the profit in the account currency (negative = loss).

---

## 🧱 Enum values

### `type` → `ENUM_ORDER_TYPE_TF`

The method maps a **friendly** symbol — or pass the raw `ORDER_TYPE_TF_*` symbol directly:

| Friendly `type:` | Raw enum | # |
|---|---|---|
| `:buy` | `ORDER_TYPE_TF_BUY` | 0 |
| `:sell` | `ORDER_TYPE_TF_SELL` | 1 |
| `:buy_limit` | `ORDER_TYPE_TF_BUY_LIMIT` | 2 |
| `:sell_limit` | `ORDER_TYPE_TF_SELL_LIMIT` | 3 |
| `:buy_stop` | `ORDER_TYPE_TF_BUY_STOP` | 4 |
| `:sell_stop` | `ORDER_TYPE_TF_SELL_STOP` | 5 |
| — *(raw only)* | `ORDER_TYPE_TF_BUY_STOP_LIMIT` | 6 |
| — *(raw only)* | `ORDER_TYPE_TF_SELL_STOP_LIMIT` | 7 |
| — *(raw only)* | `ORDER_TYPE_TF_CLOSE_BY` | 8 |

> Direction matters here: `:buy` vs `:sell` flips the sign of the move between `open_price` and `close_price`.

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Direction matters:** for a `:sell`, profit is positive when `close_price < open_price`.
* **Currency conversion** is included — if the profit currency isn't the account currency, the result is already converted.

---

## 🔗 Usage Examples

### 1) +100 points on 0.1 lot

```ruby
ask = acct.symbol_info_tick("EURUSD").ask
pt  = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
puts acct.order_calc_profit(symbol: "EURUSD", type: :buy, volume: 0.1,
                            open_price: ask, close_price: ask + 100 * pt).round(2)
```

### 2) Value of a stop-loss (risk)

```ruby
risk = acct.order_calc_profit(symbol: "EURUSD", type: :buy, volume: 0.1,
                              open_price: 1.1000, close_price: 1.0950)
puts "risk: #{risk.round(2)}"   # negative
```

### 3) Risk/reward of an SL/TP pair

```ruby
r = acct.order_calc_profit(symbol: "EURUSD", type: :buy, volume: 0.1, open_price: 1.10, close_price: 1.095)
w = acct.order_calc_profit(symbol: "EURUSD", type: :buy, volume: 0.1, open_price: 1.10, close_price: 1.115)
puts "R:R = 1:#{(w / -r).round(2)}"
```

### 4) Size to a fixed dollar risk

```ruby
per_01 = -acct.order_calc_profit(symbol: "EURUSD", type: :buy, volume: 0.1, open_price: 1.10, close_price: 1.095)
target_risk = 50.0
vol = (0.1 * target_risk / per_01).round(2)
puts "volume for $#{target_risk} risk: #{vol}"
```

---

## 🔧 Common Patterns

### Fixed-risk position sizing

```ruby
def size_for_risk(acct, sym, entry, stop, risk_money, type: :buy)
  loss_01 = -acct.order_calc_profit(symbol: sym, type: type, volume: 0.1, open_price: entry, close_price: stop)
  step    = acct.symbol_info_double(sym, :SYMBOL_VOLUME_STEP)
  raw     = 0.1 * risk_money / loss_01
  (raw / step).floor * step
end
```

---

## 📚 See Also

* [OrderCalcMargin](./OrderCalcMargin.md) · [OrderCheck](./OrderCheck.md)
* **Friendly layer:** [`MT5Sugar#calc_profit`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#order_calc_profit`](../../MT5Service/4.%20Trading_Methods.md).

---

**Back to:** [Trading Operations — Overview](./Trading_Operations.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
