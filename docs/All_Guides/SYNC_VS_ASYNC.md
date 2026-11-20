# Synchronous Calls & Threaded Streaming

> How RubyMT5 actually executes: every request/response call is **synchronous and blocking**; the only concurrency is **streaming on background threads**. There is no async/await or Fiber API.

---

## 🎯 The model in one line

- **Request/response calls** (account info, quotes, trading, history) **block** the calling thread and **return a value** (or raise). Linear, simple, predictable.
- **Streaming calls** (`subscribe_ticks`, `on_trade`, …) run on a **background thread** and invoke your block per message, returning a `Subscription` immediately — your main thread keeps going.
- **Want parallelism for blocking calls?** Spawn your own Ruby `Thread`s. The gRPC layer releases the GVL while waiting on the network, so independent calls can be in flight at once.

| | Blocking call | Background-thread stream |
|---|---|---|
| Returns | the result value | a `Subscription` (immediately) |
| Blocks your thread? | yes, until the reply | no — the block runs on the reader thread |
| Use for | everything request/response | live ticks, trade & P/L events |
| Stop it | n/a (it already returned) | `sub.cancel` |

---

## ✅ Synchronous calls (the default — everything)

Just call and use the result. No `await`, no runtime to set up:

```ruby
require "metarpc_mt5"

mt5 = MetaRPC::MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
mt5.connect(5057947437, "password", server: "MetaQuotes-Demo")

a = mt5.account_info          # blocks, returns an Account Struct
q = mt5.price("EURUSD")       # blocks, returns a Quote
r = mt5.buy_market("EURUSD", 0.01)   # blocks, returns OrderSendData
puts "balance #{a.balance}  bid #{q.bid}  trade #{r.returned_code}"
```

This is the right model for **CLI scripts, one-off tasks, notebooks, and the demos** — read top to bottom.

---

## 🧵 Concurrency with your own threads

Because each call blocks only its own thread, you parallelise by spawning threads. Independent reads then wait concurrently instead of one-after-another:

```ruby
# Quote several symbols at once
symbols = %w[EURUSD GBPUSD USDJPY XAUUSD]
quotes  = symbols.map { |s| Thread.new { [s, mt5.price(s)] } }.map(&:value).to_h
quotes.each { |s, q| puts "#{s}  #{q.bid} / #{q.ask}" }
```

> **Share carefully.** One connected `mt5` multiplexes fine for reads over gRPC. For heavy concurrent trading, prefer a separate connection per worker (pass a stable `id:` per strategy) so sessions don't interleave. Guard any shared mutable state you build yourself with a `Mutex`.

---

## 📡 Streaming is the built-in concurrency

A streaming method hands the work to a background thread and returns a `Subscription`. Your main thread is free while the block runs per message:

```ruby
sub = mt5.subscribe_ticks("EURUSD") { |t| puts "#{t.bid} / #{t.ask}" }
# ... main thread keeps working ...
sleep 5
sub.cancel          # stop cleanly (joins the reader thread)
```

Need a blocking sample instead? `each_tick` runs the stream inline for a fixed time and returns the count:

```ruby
n = mt5.each_tick("EURUSD", seconds: 5) { |t| puts t.bid }
```

Full lifecycle, patterns and pitfalls (including *don't `cancel` from inside the block*): [gRPC Stream Management](./GRPC_STREAM_MANAGEMENT.md).

---

## 💡 Rules of thumb

1. **Default to straight synchronous code.** It's the whole request/response API and it's the simplest thing that works.
2. **Use streaming for live data** — it's already concurrent (a background thread), so you don't manage threads yourself.
3. **Add threads only when you have independent blocking work** (e.g. many symbols) and the wall-clock saving matters.
4. **Background jobs** (a cron task, a Sidekiq/Resque worker) run this synchronous code as-is — nothing special required.
5. **There is no async/await here.** If you see `await` or `connect_by_server_name` in an example, it's from another language's SDK — the Ruby API is `MT5Sugar.create(...)` + `connect`.

---

## See Also

- [gRPC Stream Management](./GRPC_STREAM_MANAGEMENT.md) — streams, `Subscription`, cleanup
- [Glossary](./GLOSSARY.md) · [Getting Started](./GETTING_STARTED.md) · [MT5Sugar API](../MT5Sugar/MT5Sugar.API_Overview.md)
