# 🧪 Validating a Trade Request

> **Request:** check whether a trade request would succeed — margin, free margin, retcode — **without sending it** (`OrderCheckData`).

**API Information:**

* **Low-level API:** `MT5Account#order_check(request)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.TradeFunctions`
* **Proto definition:** `OrderCheck` (defined in `mt5-term-api-trade-functions.proto`)

### RPC

* **Service:** `mt5_term_api.TradeFunctions`
* **Method:** `OrderCheck(OrderCheckRequest) → OrderCheckReply`
* **Low-level client (generated):** `Mt5TermApi::TradeFunctions::Stub#order_check(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** A dry-run: the server validates a trade request and returns the would-be margin / free margin / retcode — but **places nothing**.
* **Why you need it.** Confirm affordability and a clean retcode before committing with [`order_send`](./OrderSend.md).
* **Sanity check.** A valid 0.1-lot request on a funded demo returns a result with a success retcode.

---

## 🎯 Purpose

`order_check` is the **"would this go through?"** gate. It's the safe way to test sizing and stops against the account's margin without touching the market — ideal before an automated entry.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # `request` is a Mt5TermApi::MrpcMqlTradeRequest.
  def order_check(request) -> Mt5TermApi::OrderCheckData
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `request` | `MrpcMqlTradeRequest` | The trade to validate. Key fields: `symbol`, `volume`, `order_type` (an **`ORDER_TYPE_TF_*`** enum), `price`. |

```ruby
req = Mt5TermApi::MrpcMqlTradeRequest.new(
  symbol: "EURUSD", volume: 0.1, order_type: :ORDER_TYPE_TF_BUY,
  price: acct.symbol_info_tick("EURUSD").ask
)
```

> ⚠️ **Enum gotcha:** `order_type` here uses the **trade-functions** enum `ORDER_TYPE_TF_BUY` (not the trading-helper `TMT5_ORDER_TYPE_BUY`). See [SymbolInfoMarginRate](../6.%20Additional_Methods/SymbolInfoMarginRate.md) for the third order-type enum.

## ⬆️ Output — `OrderCheckData`

* **`mql_trade_check_result`** — the check result message: retcode, balance/equity/margin **after** the hypothetical trade, free margin, margin level, comment.

---

## 🧱 Enum values (raw — you build the `MrpcMqlTradeRequest`)

`order_check` takes a pre-built request, so set these fields with the **raw** enum symbols:

### `action` → `MRPC_ENUM_TRADE_REQUEST_ACTIONS`

```protobuf
TRADE_ACTION_DEAL     = 0   // market deal
TRADE_ACTION_PENDING  = 1   // place a pending order
TRADE_ACTION_SLTP     = 2   // modify SL/TP of a position
TRADE_ACTION_MODIFY   = 3   // modify a pending order
TRADE_ACTION_REMOVE   = 4   // delete a pending order
TRADE_ACTION_CLOSE_BY = 5   // close by an opposite position
```

### `order_type` → `ENUM_ORDER_TYPE_TF`

```protobuf
ORDER_TYPE_TF_BUY = 0   ORDER_TYPE_TF_SELL = 1
ORDER_TYPE_TF_BUY_LIMIT = 2   ORDER_TYPE_TF_SELL_LIMIT = 3
ORDER_TYPE_TF_BUY_STOP = 4   ORDER_TYPE_TF_SELL_STOP = 5
ORDER_TYPE_TF_BUY_STOP_LIMIT = 6   ORDER_TYPE_TF_SELL_STOP_LIMIT = 7   ORDER_TYPE_TF_CLOSE_BY = 8
```

### `type_filling` → `MRPC_ENUM_ORDER_TYPE_FILLING`

```protobuf
ORDER_FILLING_FOK = 0   ORDER_FILLING_IOC = 1   ORDER_FILLING_RETURN = 2   ORDER_FILLING_BOC = 3
```

### `type_time` → `MRPC_ENUM_ORDER_TYPE_TIME`

```protobuf
ORDER_TIME_GTC = 0   ORDER_TIME_DAY = 1   ORDER_TIME_SPECIFIED = 2   ORDER_TIME_SPECIFIED_DAY = 3
```

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure. (It never places a trade.)
* **Build the request once, reuse it** for several sizes by changing `volume`.
* **Pre-flight, not a guarantee** — the market can move between `order_check` and `order_send`; keep stops sane.

---

## 🔗 Usage Examples

### 1) Validate before sending

```ruby
req = Mt5TermApi::MrpcMqlTradeRequest.new(symbol: "EURUSD", volume: 0.1,
        order_type: :ORDER_TYPE_TF_BUY, price: acct.symbol_info_tick("EURUSD").ask)
res = acct.order_check(req)
puts res.mql_trade_check_result ? "ok to send" : "check failed"
```

### 2) Affordability gate before `order_send`

```ruby
if acct.order_check(req).mql_trade_check_result
  acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.1)
else
  warn "not affordable / rejected"
end
```

### 3) Find the biggest volume that passes

```ruby
ask = acct.symbol_info_tick("EURUSD").ask
vol = [5.0, 1.0, 0.1].find do |v|
  r = Mt5TermApi::MrpcMqlTradeRequest.new(symbol: "EURUSD", volume: v, order_type: :ORDER_TYPE_TF_BUY, price: ask)
  acct.order_check(r).mql_trade_check_result
end
puts "largest ok: #{vol}"
```

---

## 🔧 Common Patterns

### Reusable checker

```ruby
def affordable?(acct, symbol, volume)
  ask = acct.symbol_info_tick(symbol).ask
  req = Mt5TermApi::MrpcMqlTradeRequest.new(symbol: symbol, volume: volume, order_type: :ORDER_TYPE_TF_BUY, price: ask)
  !acct.order_check(req).mql_trade_check_result.nil?
rescue MetaRPC::MT5::ApiError
  false
end
```

---

## 📚 See Also

* [OrderCalcMargin](./OrderCalcMargin.md) · [OrderCalcProfit](./OrderCalcProfit.md) · [OrderSend](./OrderSend.md)
* **Friendly layer:** [`MT5Service#order_check`](../../MT5Service/4.%20Trading_Methods.md).

---

**Back to:** [Trading Operations — Overview](./Trading_Operations.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
