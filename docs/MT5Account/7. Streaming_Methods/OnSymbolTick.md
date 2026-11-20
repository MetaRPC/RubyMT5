# 🔔 Streaming Ticks

> **Stream:** a tick for each price update on one or more symbols (`MrpcSubscriptionMqlTick`). Push, not poll.

**API Information:**

* **Low-level API:** `MT5Account#on_symbol_tick(symbols) { |tick| ... }` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.SubscriptionService`
* **Proto definition:** `OnSymbolTick` (defined in `mt5-term-api-subscriptions.proto`)

### RPC

* **Service:** `mt5_term_api.SubscriptionService`
* **Method:** `OnSymbolTick(OnSymbolTickRequest) → stream OnSymbolTickReply`
* **Low-level client (generated):** `Mt5TermApi::SubscriptionService::Stub#on_symbol_tick(request, metadata:, return_op:)`

---

## 💬 Just the essentials

* **What it is.** A server stream that fires your block on every price change, on a background thread.
* **Why you need it.** A live feed without polling — drive a dashboard, a trailing stop, or a signal.
* **Sanity check.** `sub.count` climbs while an active symbol trades; `sub.cancel` stops it.

---

## 🎯 Purpose

`on_symbol_tick` is the **real-time price source**. Prefer it over polling [`symbol_info_tick`](../2.%20Symbol_Information/SymbolInfoTick.md) in a loop: lower latency, less load, and it pushes only when something changes.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # `symbols` is a String or Array. Returns a Subscription; call .cancel to stop.
  def on_symbol_tick(symbols, &block) -> MetaRPC::MT5::Subscription
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbols` | `String` or `[String]` | Symbol(s) to subscribe. |
| `&block` | `proc(tick)` | Called per tick. |

## ⬆️ Yielded — `MrpcSubscriptionMqlTick`

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `symbol` | `String` | Which symbol. |
| `bid` / `ask` / `last` | `Float` | Prices. |
| `volume` / `volume_real` | `Integer` / `Float` | Tick volume. |
| `time` / `time_utc` | `Timestamp` | Tick time (broker / UTC) — read `.seconds`. |
| `time_msc` / `time_msc_utc` | `Integer` | Milliseconds. |
| `flags` | `Integer` | Change flags bitmask. |

---

## 🧩 Notes & Tips

* **Keep the block short** — it runs on the reader thread; hand heavy work to a `Queue`.
* **Control handle:** `sub.cancel` to stop, `sub.count` for ticks received, `sub.error` for a stored non-`Cancelled` error.
* **Blocking helper:** for "collect for N seconds" use [`MT5Service#each_tick`](../../MT5Service/6.%20Streaming_Methods.md).

---

## 🔗 Usage Examples

### 1) Live bid/ask for a basket

```ruby
sub = acct.on_symbol_tick(%w[EURUSD GBPUSD]) do |t|
  puts format("%-8s %s / %s", t.symbol, t.bid, t.ask)
end
sleep 5
sub.cancel
```

### 2) Count ticks over a window

```ruby
n = 0
sub = acct.on_symbol_tick("EURUSD") { n += 1 }
sleep 3; sub.cancel
puts "#{n} ticks in 3s (sub.count=#{sub.count})"
```

### 3) Track the session high/low

```ruby
hi, lo = -Float::INFINITY, Float::INFINITY
sub = acct.on_symbol_tick("EURUSD") { |t| hi = [hi, t.ask].max; lo = [lo, t.bid].min }
sleep 10; sub.cancel
puts "high #{hi}  low #{lo}"
```

---

## 🔧 Common Patterns

### Hand ticks to a worker via a queue

```ruby
q = Queue.new
sub = acct.on_symbol_tick("EURUSD") { |t| q << t }     # short: just enqueue
Thread.new { loop { tick = q.pop; heavy_process(tick) } }
```

---

## 📚 See Also

* [OnTrade](./OnTrade.md) · [SymbolInfoTick](../2.%20Symbol_Information/SymbolInfoTick.md) — one-shot tick.
* **Friendly layer:** [`MT5Service#subscribe_ticks` / `#each_tick`](../../MT5Service/6.%20Streaming_Methods.md).

---

**Back to:** [Streaming Methods — Overview](./Streaming_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
