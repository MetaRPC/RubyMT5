# 🔢 Counting Open Positions

> **Request:** the number of open positions (`PositionsTotalData`) — the cheapest "are we in the market?" probe.

**API Information:**

* **Low-level API:** `MT5Account#positions_total` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.TradeFunctions`
* **Proto definition:** `PositionsTotal` (defined in `mt5-term-api-trade-functions.proto`)

### RPC

* **Service:** `mt5_term_api.TradeFunctions`
* **Method:** `PositionsTotal(google.protobuf.Empty) → PositionsTotalReply`
* **Low-level client (generated):** `Mt5TermApi::TradeFunctions::Stub#positions_total(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One tiny RPC returning how many positions are currently open.
* **Why you need it.** Gate new entries ("max N concurrent"), detect a flat account, or drive a "wait until closed" loop — without pulling the full book.
* **Sanity check.** `0` on a flat account; grows by one per [`order_send`](../4.%20Trading_Operations/OrderSend.md) market fill.

---

## 🎯 Purpose

`positions_total` is the **lightest** open-state read. When you only need the *count* (not the details), it beats [`opened_orders`](./OpenedOrders.md): no list to transfer, no fields to parse.

> Need the tickets but still cheap? [`opened_orders_tickets`](./OpenedOrdersTickets.md). Need full detail? [`opened_orders`](./OpenedOrders.md).

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def positions_total -> Integer
end
```

**Request message:** `google.protobuf.Empty` (no fields).
**Reply:** the SDK returns `data.total_positions` (an `Integer`).

---

## 🔽 Input

**None.**

## ⬆️ Output

An `Integer` — the count of open positions.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `MetaRPC::MT5::ApiError` on failure; wrap in `begin/rescue`.
* **Positions, not orders.** This counts filled **positions**, not pending orders — those live in [`opened_orders`](./OpenedOrders.md)`.opened_orders`.
* **Cheap to poll**, but for a push signal on changes use [`on_trade`](../7.%20Streaming_Methods/OnTrade.md).

---

## 🔗 Usage Examples

### 1) Quick count

```ruby
puts "open positions: #{acct.positions_total}"
```

### 2) Gate new entries

```ruby
MAX = 5
return if acct.positions_total >= MAX   # refuse to over-trade
```

### 3) Flat check

```ruby
puts acct.positions_total.zero? ? "flat" : "in market"
```

### 4) Wait until the account is flat

```ruby
sleep 1 until acct.positions_total.zero?
puts "all closed"
```

---

## 🔧 Common Patterns

### Concurrency guard

```ruby
def can_open?(acct, max: 5)
  acct.positions_total < max
rescue MetaRPC::MT5::ApiError
  false
end
```

---

## 📚 See Also

* [OpenedOrders](./OpenedOrders.md) — full detail · [OpenedOrdersTickets](./OpenedOrdersTickets.md) — tickets only.
* **Friendly layer:** [`MT5Sugar#count_positions`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#positions_total`](../../MT5Service/3.%20Position_Orders_Methods.md).

---

**Back to:** [Positions & Orders — Overview](./Position_Orders_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
