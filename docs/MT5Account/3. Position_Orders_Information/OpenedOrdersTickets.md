# 🎫 Open Tickets (Lightweight)

> **Request:** just the tickets of open positions and pending orders (`OpenedOrdersTicketsData`) — no per-order detail, ideal for cheap diffs.

**API Information:**

* **Low-level API:** `MT5Account#opened_orders_tickets` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountHelper`
* **Proto definition:** `OpenedOrdersTickets` (defined in `mt5-term-api-account-helper.proto`)

### RPC

* **Service:** `mt5_term_api.AccountHelper`
* **Method:** `OpenedOrdersTickets(OpenedOrdersTicketsRequest) → OpenedOrdersTicketsReply`
* **Low-level client (generated):** `Mt5TermApi::AccountHelper::Stub#opened_orders_tickets(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning two id lists: open **position** tickets and pending **order** tickets.
* **Why you need it.** Detect opens/closes by **diffing** successive snapshots, without transferring full order payloads.
* **Sanity check.** `opened_position_tickets.size` matches [`positions_total`](./PositionsTotal.md).

---

## 🎯 Purpose

`opened_orders_tickets` is the **change-detection** primitive. Poll it on a timer (or use the [`on_positions_and_pending_orders_tickets`](../7.%20Streaming_Methods/OnPositionsAndPendingOrdersTickets.md) stream), keep the previous set, and the set difference tells you exactly what opened or closed — far cheaper than re-pulling [`opened_orders`](./OpenedOrders.md) each time.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def opened_orders_tickets -> Mt5TermApi::OpenedOrdersTicketsData
end
```

**Request message:** `OpenedOrdersTicketsRequest {}` *(empty)*.
**Reply:** the SDK returns `data` (`OpenedOrdersTicketsData`).

---

## 🔽 Input

**None.**

## ⬆️ Output — `OpenedOrdersTicketsData`

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `opened_position_tickets` | `opened_position_tickets` | `Integer[]` | Tickets of open positions. |
| `opened_orders_tickets` | `opened_orders_tickets` | `Integer[]` | Tickets of pending/working orders. |

> Both are repeated fields — call `.to_a` to get a plain Ruby array.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Much lighter** than [`opened_orders`](./OpenedOrders.md) — use it when you only need ids.
* **Diff with Set operations:** `(current - previous)` = newly opened; `(previous - current)` = just closed.

---

## 🔗 Usage Examples

### 1) Count cheaply

```ruby
tk = acct.opened_orders_tickets
puts "positions #{tk.opened_position_tickets.to_a.size}  pending #{tk.opened_orders_tickets.to_a.size}"
```

### 2) Detect new opens (diff two snapshots)

```ruby
before = acct.opened_orders_tickets.opened_position_tickets.to_a
# ... place a trade elsewhere ...
after  = acct.opened_orders_tickets.opened_position_tickets.to_a
puts "newly opened: #{(after - before).inspect}"
```

### 3) Pending-order ids

```ruby
p acct.opened_orders_tickets.opened_orders_tickets.to_a
```

### 4) Is a specific ticket still open?

```ruby
open = acct.opened_orders_tickets.opened_position_tickets.to_a
puts open.include?(123_456) ? "still open" : "closed"
```

---

## 🔧 Common Patterns

### Poll for closes

```ruby
def wait_closed(acct, ticket, timeout: 30)
  deadline = Time.now + timeout
  loop do
    return true unless acct.opened_orders_tickets.opened_position_tickets.to_a.include?(ticket)
    return false if Time.now > deadline
    sleep 0.5
  end
end
```

---

## 📚 See Also

* [OpenedOrders](./OpenedOrders.md) — full detail · [PositionsTotal](./PositionsTotal.md) — count.
* [OnPositionsAndPendingOrdersTickets](../7.%20Streaming_Methods/OnPositionsAndPendingOrdersTickets.md) — push version.
* **Friendly layer:** [`MT5Sugar#open_tickets`](../../MT5Sugar/MT5Sugar.API_Overview.md).

---

**Back to:** [Positions & Orders — Overview](./Position_Orders_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
