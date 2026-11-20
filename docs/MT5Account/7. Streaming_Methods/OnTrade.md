# 🔔 Streaming Trade Events

> **Stream:** a payload whenever orders or positions change (`OnTradeData`) — your single source of truth for "something changed".

**API Information:**

* **Low-level API:** `MT5Account#on_trade { |event| ... }` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.SubscriptionService`
* **Proto definition:** `OnTrade` (defined in `mt5-term-api-subscriptions.proto`)

### RPC

* **Service:** `mt5_term_api.SubscriptionService`
* **Method:** `OnTrade(OnTradeRequest) → stream OnTradeReply`
* **Low-level client (generated):** `Mt5TermApi::SubscriptionService::Stub#on_trade(request, metadata:, return_op:)`

---

## 💬 Just the essentials

* **What it is.** A server stream that fires on every order/position change — fills, modifications, closes.
* **Why you need it.** React to executions the instant they happen instead of polling [`opened_orders`](../3.%20Position_Orders_Information/OpenedOrders.md).
* **Sanity check.** Place or close a trade elsewhere and your block fires.

---

## 🎯 Purpose

`on_trade` is the **change notifier**. Use it as the trigger to refresh your view of the book, log activity, or run follow-up logic — then read the authoritative state with [`opened_orders`](../3.%20Position_Orders_Information/OpenedOrders.md) if you need full detail.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def on_trade(&block) -> MetaRPC::MT5::Subscription
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `&block` | `proc(data)` | Called per `OnTradeData`. |

## ⬆️ Yielded — `OnTradeData`

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `type` | `Symbol` | Event type enum. |
| `event_data` | message | The change payload (affected orders/positions). |
| `account_info` | message | Account snapshot at the event. |
| `terminal_instance_guid_id` | `String` | Terminal session id. |

---

## 🧩 Notes & Tips

* **Fires on fills, modifications and closes** — one stream covers the whole account.
* **Keep the block short**; `sub.cancel` to stop.
* **For finer detail** (request → order → deal) use [`on_trade_transaction`](./OnTradeTransaction.md).

---

## 🔗 Usage Examples

### 1) Log events

```ruby
sub = acct.on_trade { |ev| puts "trade event: #{ev.type}" }
sleep 10
sub.cancel
```

### 2) Refresh the book on any change

```ruby
sub = acct.on_trade do |_ev|
  puts "positions now: #{acct.positions_total}"
end
```

### 3) Count events in a window

```ruby
n = 0
sub = acct.on_trade { n += 1 }
sleep 5; sub.cancel
puts "#{n} events"
```

---

## 🔧 Common Patterns

### Event-driven state refresh (debounced)

```ruby
last = Time.at(0)
sub = acct.on_trade do |_ev|
  next if Time.now - last < 0.5          # debounce bursts
  last = Time.now
  @book = acct.opened_orders.position_infos
end
```

---

## 📚 See Also

* [OnTradeTransaction](./OnTradeTransaction.md) — lower-level transactions · [OnPositionProfit](./OnPositionProfit.md).
* **Friendly layer:** [`MT5Service#on_trade`](../../MT5Service/6.%20Streaming_Methods.md).

---

**Back to:** [Streaming Methods — Overview](./Streaming_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
