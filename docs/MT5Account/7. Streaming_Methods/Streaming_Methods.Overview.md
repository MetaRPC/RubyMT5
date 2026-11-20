# MT5Account · Streaming Methods — Overview

> Real-time server streams: ticks, trade events, position-profit updates, ticket snapshots and raw trade transactions. Every stream runs on a **background thread** and hands you a `Subscription`.

All five live on `mt5_term_api.SubscriptionService`.

## 🔌 The stream contract

Each streaming method takes a **block** and returns a `MetaRPC::MT5::Subscription`:

```ruby
sub = acct.on_symbol_tick("EURUSD") { |tick| puts "#{tick.bid}/#{tick.ask}" }
# ... later ...
sub.cancel          # stop the stream and join the reader thread
```

* The SDK reads the stream on a background thread and calls your block per payload.
* `sub.cancel` unsubscribes cleanly; `sub.alive?` tells you if it's still running; `sub.count` is how many messages arrived; `sub.error` holds a non-`GRPC::Cancelled` error if one occurred.
* An error inside the stream is stored on `sub.error` (the thread doesn't crash your program).

## 📁 What lives here

| Method | Yields |
|--------|--------|
| **[OnSymbolTick](./OnSymbolTick.md)** | a tick (`MrpcSubscriptionMqlTick`) per price update |
| **[OnTrade](./OnTrade.md)** | `OnTradeData` when orders/positions change |
| **[OnPositionProfit](./OnPositionProfit.md)** | `OnPositionProfitData` on a timer |
| **[OnPositionsAndPendingOrdersTickets](./OnPositionsAndPendingOrdersTickets.md)** | ticket snapshots on a timer |
| **[OnTradeTransaction](./OnTradeTransaction.md)** | low-level `OnTradeTransactionData` events |

---

## 🧭 Plain English

* **Prices** → `on_symbol_tick`. **Any order/position change** → `on_trade`. **Live P/L** → `on_position_profit`. **Open tickets over time** → `on_positions_and_pending_orders_tickets`. **Raw MT5 transactions** → `on_trade_transaction`.

> Rule of thumb: keep block handlers **short** (they run on the reader thread); hand heavy work to a queue.

---

## 🟢 Minimal snippet

```ruby
n = 0
sub = acct.on_symbol_tick("EURUSD") { |t| n += 1 }
sleep 5
sub.cancel
puts "#{n} ticks in 5s"
```

---

## See also

* **Blocking helper:** [`MT5Service#each_tick`](../../MT5Service/MT5Service.Overview.md) — iterate ticks for N seconds, then return a count.
* **Concepts:** [gRPC Stream Management](../../All_Guides/GRPC_STREAM_MANAGEMENT.md).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
