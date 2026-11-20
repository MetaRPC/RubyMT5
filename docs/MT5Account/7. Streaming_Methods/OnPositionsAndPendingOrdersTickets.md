# 🔔 Streaming Ticket Snapshots

> **Stream:** snapshots of open position & pending-order tickets on a timer (`OnPositionsAndPendingOrdersTicketsData`) — the lightweight way to watch what's open over time.

**API Information:**

* **Low-level API:** `MT5Account#on_positions_and_pending_orders_tickets(interval_ms:) { |data| ... }` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.SubscriptionService`
* **Proto definition:** `OnPositionsAndPendingOrdersTickets` (defined in `mt5-term-api-subscriptions.proto`)

### RPC

* **Service:** `mt5_term_api.SubscriptionService`
* **Method:** `OnPositionsAndPendingOrdersTickets(...) → stream`
* **Low-level client (generated):** `Mt5TermApi::SubscriptionService::Stub#on_positions_and_pending_orders_tickets(request, metadata:, return_op:)`

---

## 💬 Just the essentials

* **What it is.** A timer-driven stream of just the **ticket ids** of open positions and pending orders.
* **Why you need it.** Detect opens/closes by diffing successive snapshots — no full order payloads.
* **Sanity check.** Snapshots arrive ~once per `interval_ms`; the ticket sets match [`opened_orders_tickets`](../3.%20Position_Orders_Information/OpenedOrdersTickets.md).

---

## 🎯 Purpose

This is the **push** version of [`opened_orders_tickets`](../3.%20Position_Orders_Information/OpenedOrdersTickets.md): instead of polling, you get periodic ticket snapshots and compute the set difference to see exactly what opened or closed — cheap change-detection for a position monitor.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def on_positions_and_pending_orders_tickets(interval_ms: 1000, &block) -> MetaRPC::MT5::Subscription
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `interval_ms` | `Integer` *(keyword, default `1000`)* | Snapshot interval. |
| `&block` | `proc(data)` | Called per snapshot. |

## ⬆️ Yielded

Snapshot data carrying the current **position tickets** and **pending-order tickets** — diff successive snapshots to detect opens/closes cheaply.

---

## 🧩 Notes & Tips

* **Lightweight alternative to [`on_trade`](./OnTrade.md)** when you only track *which tickets exist*, not full detail.
* **Keep the previous snapshot** to compute `added = current - previous` and `removed = previous - current`.
* **`sub.cancel`** to stop.

---

## 🔗 Usage Examples

### 1) Just wire it up

```ruby
sub = acct.on_positions_and_pending_orders_tickets(interval_ms: 1000) { |_d| }
sleep 5; sub.cancel
```

### 2) Detect opens / closes by diff

```ruby
last = []
sub = acct.on_positions_and_pending_orders_tickets do |d|
  cur = d.opened_position_tickets.to_a
  puts "opened: #{(cur - last).inspect}  closed: #{(last - cur).inspect}"
  last = cur
end
```

### 3) Faster polling

```ruby
acct.on_positions_and_pending_orders_tickets(interval_ms: 500) { |_d| }
```

---

## 🔧 Common Patterns

### Fire a callback when a ticket closes

```ruby
def on_close(acct, ticket, &cb)
  seen = false
  acct.on_positions_and_pending_orders_tickets do |d|
    open = d.opened_position_tickets.to_a.include?(ticket)
    seen ||= open
    cb.call(ticket) if seen && !open
  end
end
```

---

## 📚 See Also

* [OpenedOrdersTickets](../3.%20Position_Orders_Information/OpenedOrdersTickets.md) — one-shot · [OnTrade](./OnTrade.md).
* **Friendly layer:** [`MT5Service#on_tickets`](../../MT5Service/6.%20Streaming_Methods.md).

---

**Back to:** [Streaming Methods — Overview](./Streaming_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
