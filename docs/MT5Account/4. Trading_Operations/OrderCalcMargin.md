# 💰 Calculating Required Margin

> **Request:** the margin needed to open an order (`OrderCalcMarginData`) — before you send it.

**API Information:**

* **Low-level API:** `MT5Account#order_calc_margin(symbol:, type:, volume:, price:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.TradeFunctions`
* **Proto definition:** `OrderCalcMargin` (defined in `mt5-term-api-trade-functions.proto`)

### RPC

* **Service:** `mt5_term_api.TradeFunctions`
* **Method:** `OrderCalcMargin(OrderCalcMarginRequest) → OrderCalcMarginReply`
* **Low-level client (generated):** `Mt5TermApi::TradeFunctions::Stub#order_calc_margin(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the margin (account currency) to open `volume` lots of `symbol` at `price`.
* **Why you need it.** Size positions to your free margin, and reject trades you can't afford before sending them.
* **Sanity check.** Margin for 0.1 lot EURUSD ≈ `contract × price × 0.1 / leverage`.

---

## 🎯 Purpose

`order_calc_margin` turns a trade idea into a **cash requirement**. Compare it to [`account_info_double(:ACCOUNT_MARGIN_FREE)`](../1.%20Account_Information/AccountInfoDouble.md) to answer "does this fit?", or invert it to find the largest affordable volume.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # type: :buy / :sell / :buy_limit / ... (mapped to ORDER_TYPE_TF_*).
  def order_calc_margin(symbol:, type:, volume:, price:) -> Float
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` *(keyword)* | Symbol. |
| `type` | `Symbol` *(keyword)* | `:buy` / `:sell` / `:buy_limit` / … |
| `volume` | `Float` *(keyword)* | Lots. |
| `price` | `Float` *(keyword)* | Price to calculate at (e.g. current ask). |

## ⬆️ Output

A `Float` — the margin in the account currency.

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

> For margin, `:buy` and `:sell` give the same figure; direction only matters for the pending variants.

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Buy vs sell** can differ on some instruments — pass the real direction.
* **Leverage-sensitive:** the same volume costs less margin at higher leverage.

---

## 🔗 Usage Examples

### 1) Margin for a planned trade

```ruby
ask = acct.symbol_info_tick("EURUSD").ask
puts acct.order_calc_margin(symbol: "EURUSD", type: :buy, volume: 0.1, price: ask).round(2)
```

### 2) Does it fit free margin?

```ruby
need = acct.order_calc_margin(symbol: "EURUSD", type: :buy, volume: 1.0, price: ask)
free = acct.account_info_double(:ACCOUNT_MARGIN_FREE)
puts need <= free ? "affordable" : "too big (#{need.round(2)} > #{free.round(2)})"
```

### 3) Largest affordable volume (rounded to step)

```ruby
per_lot = acct.order_calc_margin(symbol: "EURUSD", type: :buy, volume: 1.0, price: ask)
step    = acct.symbol_info_double("EURUSD", :SYMBOL_VOLUME_STEP)
free    = acct.account_info_double(:ACCOUNT_MARGIN_FREE)
max_lot = ((free / per_lot) / step).floor * step
puts "max lot: #{max_lot}"
```

### 4) Compare buy vs sell

```ruby
%i[buy sell].each { |t| puts "#{t}: #{acct.order_calc_margin(symbol: 'EURUSD', type: t, volume: 0.1, price: ask).round(2)}" }
```

---

## 🔧 Common Patterns

### Affordability guard

```ruby
def affordable?(acct, sym, vol, type: :buy)
  price = acct.symbol_info_tick(sym).ask
  acct.order_calc_margin(symbol: sym, type: type, volume: vol, price: price) <=
    acct.account_info_double(:ACCOUNT_MARGIN_FREE)
end
```

---

## 📚 See Also

* [OrderCalcProfit](./OrderCalcProfit.md) · [OrderCheck](./OrderCheck.md) · [OrderSend](./OrderSend.md)
* **Friendly layer:** [`MT5Sugar#required_margin` / `#max_lot`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#order_calc_margin`](../../MT5Service/4.%20Trading_Methods.md).

---

**Back to:** [Trading Operations — Overview](./Trading_Operations.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
