# MT5Account · Positions & Orders — Overview

> Open positions, pending orders, their tickets, and the closed history. In MT5 a **position** is net market exposure, an **order** is a pending/working instruction, and a **deal** is an executed transaction recorded in history.

Reads live on `mt5_term_api.AccountHelper` / `TradeFunctions`. Each returns the raw `*Data` or a plain value, or raises `ApiError`.

## 📁 What lives here

| Method | What it does |
|--------|--------------|
| **[PositionsTotal](./PositionsTotal.md)** | count of open positions |
| **[OpenedOrders](./OpenedOrders.md)** | open positions **and** pending orders, full detail |
| **[OpenedOrdersTickets](./OpenedOrdersTickets.md)** | just the tickets (lightweight) |
| **[OrderHistory](./OrderHistory.md)** | closed orders + deals in a time window (auto-paged) |
| **[PositionsHistory](./PositionsHistory.md)** | closed positions / round-trips (auto-paged) |

---

## 🧭 Plain English

* **Now:** `opened_orders` gives you both open **positions** (`position_infos`) and pending **orders** (`opened_orders`) in one reply; `positions_total` is just the count; `opened_orders_tickets` is the cheap tickets-only variant.
* **History:** `order_history` returns closed orders & deals; `positions_history` returns one row per closed round-trip (open→close, with profit).

> Rule of thumb: **what's open now** → `opened_orders`; **what happened before** → `order_history` / `positions_history`.

---

## Quick choose

| If you need…                         | Use                      | Returns |
| ------------------------------------ | ------------------------ | ------- |
| How many positions are open          | `positions_total`        | `Integer` |
| Open positions + pending orders      | `opened_orders`          | `OpenedOrdersData` |
| Only the tickets                     | `opened_orders_tickets`  | `OpenedOrdersTicketsData` |
| Closed orders & deals (window)       | `order_history`          | `[HistoryData]` |
| Closed round-trips (window)          | `positions_history`      | `[PositionHistoryInfo]` |

---

## ❌ Cross-refs & gotchas

* **History takes UTC times** — pass `Time` objects (the SDK converts to protobuf Timestamps). History reads are **auto-paged** by the SDK.
* **Position ≠ order.** `opened_orders.position_infos` are filled positions; `opened_orders.opened_orders` are pending/working orders.
* **Filter in Ruby** — `opened_orders.position_infos.select { |p| p.magic_number == 600001 }`, or use [`MT5Service#positions(magic:, symbol:)`](../../MT5Service/MT5Service.Overview.md).

---

## 🟢 Minimal snippets

```ruby
data = acct.opened_orders
puts "positions #{data.position_infos.size}  pending #{data.opened_orders.size}"
data.position_infos.each { |p| puts "##{p.ticket} #{p.symbol} #{p.volume} P/L #{p.profit}" }

from = Time.now.utc - 7*24*3600
acct.order_history(from_utc: from).last(5).each { |h| puts h.history_deal&.ticket }
```

---

## See also

* **Trading:** [Trading Operations — Overview](../4.%20Trading_Operations/Trading_Operations.Overview.md) — place / modify / close.
* **Friendly layer:** [`MT5Service#positions` / `#order_history`](../../MT5Service/MT5Service.Overview.md).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
