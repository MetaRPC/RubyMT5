# ❌ Closing an Order

> **Request:** close a position (fully or partially) or delete a pending order (`OrderCloseData`).

**API Information:**

* **Low-level API:** `MT5Account#order_close(ticket:, volume:, slippage:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.TradingHelper`
* **Proto definition:** `OrderClose` (defined in `mt5-term-api-trading-helper.proto`)

### RPC

* **Service:** `mt5_term_api.TradingHelper`
* **Method:** `OrderClose(OrderCloseRequest) → OrderCloseReply`
* **Low-level client (generated):** `Mt5TermApi::TradingHelper::Stub#order_close(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One trade RPC that exits a position — full or partial — or deletes a pending order, by ticket.
* **Why you need it.** Take profit / cut a loss, scale out of a position, or cancel a working order.
* **Sanity check.** Success ⇒ `returned_code == 10009`; `close_mode` says whether it was a close or a delete.

> ⚠️ **Exactly-once.** Sent once, never re-sent. On a transport failure re-read the position before retrying.

---

## 🎯 Purpose

`order_close` is your **exit**. On a **position** ticket it closes (all or part of the volume); on a **pending** ticket it deletes the order. One method covers both — `close_mode` in the reply tells you which happened.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Close a position (volume nil/0 = full) or delete a pending order by ticket.
  def order_close(ticket:, volume: nil, slippage: 10) -> Mt5TermApi::OrderCloseData
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `ticket` | `Integer` *(required)* | Position or pending-order ticket. |
| `volume` | `Float` | Lots to close; `nil`/`0` = full close. |
| `slippage` | `Integer` *(default `10`)* | Max price deviation (points). |

## ⬆️ Output — `OrderCloseData`

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `returned_code` | `returned_code` | `Integer` | **`10009` = DONE**. |
| `returned_string_code` | `returned_string_code` | `String` | Retcode as text. |
| `returned_code_description` | `returned_code_description` | `String` | Human-readable description. |
| `close_mode` | `close_mode` | `Symbol` | How it was closed (close / delete) enum. |

---

## 🧱 Enum values

### `close_mode` (output) → `MRPC_ORDER_CLOSE_MODE`

What the server did, returned on `OrderCloseData.close_mode`:

```protobuf
MRPC_MARKET_ORDER_CLOSE         = 0   // a market position fully closed
MRPC_MARKET_ORDER_PARTIAL_CLOSE = 1   // a market position partially closed
MRPC_PENDING_ORDER_REMOVE       = 2   // a pending order deleted
```

## 🧩 Notes & Tips

* **Errors are exceptions:** a rejection raises `ApiError`; a transport failure may raise a `TradeOutcomeUnknown`-marked error.
* **Partial close:** pass a `volume` smaller than the position; the remainder stays open as a new/continuing position.
* **Pending orders:** `order_close` on a pending ticket **deletes** it (no fill).
* **Slippage** guards against adverse moves on a market close — widen it on fast markets.

---

## 🔗 Usage Examples

### 1) Full close

```ruby
out = acct.order_close(ticket: 123_456)
puts out.returned_code == 10_009 ? "closed" : out.returned_code_description
```

### 2) Partial close (half)

```ruby
acct.order_close(ticket: 123_456, volume: 0.05)
```

### 3) Delete a pending order

```ruby
acct.order_close(ticket: pending_ticket)   # pending → deleted
```

### 4) Close everything on a symbol

```ruby
acct.opened_orders.position_infos
    .select { |p| p.symbol == "EURUSD" }
    .each   { |p| acct.order_close(ticket: p.ticket) }
```

---

## 🔧 Common Patterns

### Close-all with a result summary

```ruby
def close_all(acct)
  acct.opened_orders.position_infos.map do |p|
    r = acct.order_close(ticket: p.ticket)
    [p.ticket, r.returned_code]
  end.to_h
end
```

---

## 📚 See Also

* [OrderSend](./OrderSend.md) · [OrderModify](./OrderModify.md) · [OpenedOrders](../3.%20Position_Orders_Information/OpenedOrders.md)
* **Friendly layer:** [`MT5Sugar#close_position` / `#close_all_positions`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#order_close`](../../MT5Service/4.%20Trading_Methods.md).

---

**Back to:** [Trading Operations — Overview](./Trading_Operations.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
