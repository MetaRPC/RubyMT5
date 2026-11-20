# 🔔 Streaming Trade Transactions

> **Stream:** low-level MT5 trade-transaction events (`OnTradeTransactionData`) — the raw transaction feed behind every order lifecycle.

**API Information:**

* **Low-level API:** `MT5Account#on_trade_transaction { |data| ... }` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.SubscriptionService`
* **Proto definition:** `OnTradeTransaction` (defined in `mt5-term-api-subscriptions.proto`)

### RPC

* **Service:** `mt5_term_api.SubscriptionService`
* **Method:** `OnTradeTransaction(OnTradeTransactionRequest) → stream OnTradeTransactionReply`
* **Low-level client (generated):** `Mt5TermApi::SubscriptionService::Stub#on_trade_transaction(request, metadata:, return_op:)`

---

## 💬 Just the essentials

* **What it is.** The finest-grained trade feed — mirrors the MQL5 `OnTradeTransaction` event (request → order → deal).
* **Why you need it.** Audit every step of an order's life, reconcile fills, or build precise execution analytics.
* **Sanity check.** One `order_send` typically emits **several** transactions (more than [`on_trade`](./OnTrade.md)).

---

## 🎯 Purpose

`on_trade_transaction` is the **audit-grade** stream. Where [`on_trade`](./OnTrade.md) tells you "something changed", this tells you *each* underlying step — use it when you need the full execution trail rather than a summary.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def on_trade_transaction(&block) -> MetaRPC::MT5::Subscription
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `&block` | `proc(data)` | Called per transaction. |

## ⬆️ Yielded — `OnTradeTransactionData`

The MT5 trade-transaction payload — the transaction (request/result codes, order & deal ids, type, price, volume), mirroring the MQL5 `OnTradeTransaction` event. Finer than [`on_trade`](./OnTrade.md): one order emits several transactions (request accepted → order placed → deal done).

---

## 🧩 Notes & Tips

* **More events than `on_trade`** — expect bursts per trade; keep the block short.
* **`sub.cancel`** to stop; inspect `sub.error` after cancel for any stored error.
* **Overkill for simple bots** — use [`on_trade`](./OnTrade.md) unless you specifically need the transaction trail.

---

## 🔗 Usage Examples

### 1) Raw transaction feed

```ruby
sub = acct.on_trade_transaction { |txn| puts txn.inspect[0, 80] }
sleep 10
sub.cancel
```

### 2) Count transactions

```ruby
n = 0
sub = acct.on_trade_transaction { n += 1 }
sleep 5; sub.cancel
puts "#{n} transactions"
```

### 3) Error-safe reader

```ruby
sub = acct.on_trade_transaction { |_t| }
sleep 5
sub.cancel
warn sub.error if sub.error
```

---

## 🔧 Common Patterns

### Collect an execution trail for one order

```ruby
trail = []
sub = acct.on_trade_transaction { |txn| trail << txn }
# ... place the order, wait a moment ...
sleep 2; sub.cancel
puts "#{trail.size} transactions captured"
```

---

## 📚 See Also

* [OnTrade](./OnTrade.md) — higher-level change events.
* **Friendly layer:** [`MT5Service#on_trade_transaction`](../../MT5Service/6.%20Streaming_Methods.md).

---

**Back to:** [Streaming Methods — Overview](./Streaming_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
