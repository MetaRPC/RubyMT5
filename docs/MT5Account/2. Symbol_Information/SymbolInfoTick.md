# 📈 Getting the Latest Tick

> **Request:** the most recent tick for a symbol (`MrpcMqlTick`) — bid, ask, last, volume and timestamps. This is where **prices** come from.

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_tick(symbol)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoTick` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoTick(SymbolInfoTickRequest) → SymbolInfoTickReply`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the latest quote for a symbol.
* **Why you need it.** Current bid/ask before trading, spread monitoring, a lightweight price feed (poll it, or use the [`on_symbol_tick`](../7.%20Streaming_Methods/OnSymbolTick.md) stream for push).
* **Sanity check.** `bid` and `ask` are non-zero on an active symbol; `ask > bid`.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Latest tick for `symbol`. Returns MrpcMqlTick; raises ApiError on failure.
  def symbol_info_tick(symbol) -> Mt5TermApi::MrpcMqlTick
end
```

**Request message:** `SymbolInfoTickRequest { string symbol = 1; }`
**Reply:** `SymbolInfoTickReply { oneof response { MrpcMqlTick data; Error error; } }` — the SDK returns `data`.

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol, e.g. `"EURUSD"`. Required. |

---

## ⬆️ Output — `MrpcMqlTick`

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `bid` | `bid` | `Float` | Best bid price. |
| `ask` | `ask` | `Float` | Best ask price. |
| `last` | `last` | `Float` | Last deal price (often `0` on FX). |
| `volume` | `volume` | `Integer` | Tick volume. |
| `volume_real` | `volume_real` | `Float` | Real volume (exchange symbols). |
| `time` | `time` | `Integer` | Tick time, unix seconds (broker tz). |
| `time_utc` | `time_utc` | `Integer` | Tick time, unix seconds (UTC). |
| `time_msc` | `time_msc` | `Integer` | Tick time in milliseconds (broker tz). |
| `time_msc_utc` | `time_msc_utc` | `Integer` | Tick time in milliseconds (UTC). |
| `flags` | `flags` | `Integer` | Tick flags bitmask (which fields changed). |

> **Spread** = `ask - bid` (price units). In **points**: `((ask - bid) / point).round`, where `point = symbol_info_double(symbol, :SYMBOL_POINT)`.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`; wrap in `begin/rescue`.
* **`last` is 0 on FX** — use `bid` / `ask` for quotes.
* **Push vs poll:** for a live feed use [`on_symbol_tick`](../7.%20Streaming_Methods/OnSymbolTick.md) instead of polling this in a loop.
* **Select first** if a symbol isn't loaded: `symbol_select(symbol, true)`.

---

## 🔗 Usage Examples

### 1) Current quote & spread

```ruby
t = acct.symbol_info_tick("EURUSD")
spread_pts = ((t.ask - t.bid) / acct.symbol_info_double("EURUSD", :SYMBOL_POINT)).round
puts "bid #{t.bid}  ask #{t.ask}  spread #{spread_pts} pts"
```

### 2) Tick age

```ruby
t = acct.symbol_info_tick("EURUSD")
age = Time.now.utc.to_i - t.time_utc
puts "last tick #{age}s ago"
```

### 3) Poll a few symbols

```ruby
%w[EURUSD GBPUSD USDJPY].each do |sym|
  t = acct.symbol_info_tick(sym)
  puts format("%-8s %s / %s", sym, t.bid, t.ask)
end
```

---

## 📚 See Also

* [SymbolInfoDouble](./SymbolInfoDouble.md) — `:SYMBOL_POINT`, `:SYMBOL_BID`, … one property at a time.
* [OnSymbolTick](../7.%20Streaming_Methods/OnSymbolTick.md) — push stream of ticks.
* **Friendly layer:** [`MT5Service#quote`](../../MT5Service/MT5Service.Overview.md) → `Quote(bid, ask, last, spread, time_utc)`.

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
