# 🔔 Streaming Position P/L

> **Stream:** position profit/loss updates on a timer (`OnPositionProfitData`) — new, updated and deleted positions since the last tick.

**API Information:**

* **Low-level API:** `MT5Account#on_position_profit(interval_ms:, ignore_empty:) { |data| ... }` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.SubscriptionService`
* **Proto definition:** `OnPositionProfit` (defined in `mt5-term-api-subscriptions.proto`)

### RPC

* **Service:** `mt5_term_api.SubscriptionService`
* **Method:** `OnPositionProfit(OnPositionProfitRequest) → stream OnPositionProfitReply`
* **Low-level client (generated):** `Mt5TermApi::SubscriptionService::Stub#on_position_profit(request, metadata:, return_op:)`

---

## 💬 Just the essentials

* **What it is.** A timer-driven stream emitting your open positions' P/L every `interval_ms`.
* **Why you need it.** A live floating-P/L readout for a dashboard, trailing logic, or a drawdown kill-switch.
* **Sanity check.** With an open position, snapshots arrive ~once per `interval_ms` and carry `updated_positions`.

---

## 🎯 Purpose

`on_position_profit` is the **live P/L feed**. Unlike [`on_trade`](./OnTrade.md) (which fires on *changes*), this fires on a *timer* so you always have a current profit figure — ideal for monitoring and risk guards.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def on_position_profit(interval_ms: 1000, ignore_empty: true, &block) -> MetaRPC::MT5::Subscription
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `interval_ms` | `Integer` *(keyword, default `1000`)* | How often to emit a snapshot. |
| `ignore_empty` | `Boolean` *(keyword, default `true`)* | Skip empty snapshots (no positions). |
| `&block` | `proc(data)` | Called per snapshot. |

## ⬆️ Yielded — `OnPositionProfitData`

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `new_positions` | message[] | Positions opened since last snapshot. |
| `updated_positions` | message[] | Positions whose P/L changed. |
| `deleted_positions` | message[] | Positions closed since last snapshot. |
| `account_info` | message | Account snapshot. |

---

## 🧩 Notes & Tips

* **Pick a sane `interval_ms`** — `1000` is a good default; too small floods your block.
* **`ignore_empty: true`** suppresses snapshots when you're flat — flip to `false` to get heartbeats anyway.
* **`sub.cancel`** to stop; keep the block short.

---

## 🔗 Usage Examples

### 1) Live floating P/L

```ruby
sub = acct.on_position_profit(interval_ms: 1000) do |d|
  puts "floating: #{d.updated_positions.sum(&:profit).round(2)}"
end
sleep 5; sub.cancel
```

### 2) Drawdown alert

```ruby
sub = acct.on_position_profit do |d|
  total = d.updated_positions.sum(&:profit)
  puts "⚠️ drawdown #{total.round(2)}" if total < -50
end
```

### 3) React to opens/closes within the feed

```ruby
acct.on_position_profit do |d|
  d.new_positions.each     { |p| puts "opened ##{p.ticket}" }
  d.deleted_positions.each { |p| puts "closed ##{p.ticket}" }
end
```

---

## 🔧 Common Patterns

### Kill-switch on floating drawdown

```ruby
def arm_kill_switch(acct, limit:)
  acct.on_position_profit(interval_ms: 1000) do |d|
    if d.updated_positions.sum(&:profit) <= -limit
      acct.opened_orders.position_infos.each { |p| acct.order_close(ticket: p.ticket) }
    end
  end
end
```

---

## 📚 See Also

* [OnPositionsAndPendingOrdersTickets](./OnPositionsAndPendingOrdersTickets.md) · [OnTrade](./OnTrade.md).
* **Friendly layer:** [`MT5Service#on_position_profit`](../../MT5Service/6.%20Streaming_Methods.md).

---

**Back to:** [Streaming Methods — Overview](./Streaming_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
