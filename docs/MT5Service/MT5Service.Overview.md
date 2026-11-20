# MT5Service — Mid-Level API Overview

> A convenient wrapper over **[MT5Account](../MT5Account/MT5Account.Master.Overview.md)** that returns **plain Ruby objects (Structs) and plain arguments** instead of protobuf messages.

**🧩 API Layer:** **MID-LEVEL** — the balance between low-level ([MT5Account](../MT5Account/MT5Account.Master.Overview.md)) and high-level ([MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md)).

---

## ⚠️ Same calls, cleaner results

MT5Service and MT5Account make the **same gRPC calls** — the difference is the **return shape**, not the logic.

```ruby
# Low-level (MT5Account) — you read the protobuf tick:
t = account.symbol_info_tick("EURUSD")
spread = t.ask - t.bid

# Mid-level (MT5Service) — you get a tidy Quote struct:
q = service.quote("EURUSD")       # Quote(symbol, bid, ask, last, spread, time_utc)
spread = q.spread
```

**What the mid layer does for you**

* ✅ Builds the protobuf `*Request` from plain arguments.
* ✅ Returns typed Ruby **Structs** where they add value — `Account`, `Quote`.
* ✅ Auto-pages history reads and hands back ready arrays.
* ✅ Filters positions in Ruby (`positions(magic:, symbol:)`).
* ✅ Keeps the raw protobuf `*Data` where the full shape matters (orders, specs, order book) — one hop from the low layer.

Both layers are equally valid — pick the altitude you prefer. For one-liners, go up again to [MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md).

---

## 🏗️ Architecture layers

```
┌─────────────────────────────────────────────┐
│  MT5Sugar      one-liners, risk-based sizing│  ← highest
├─────────────────────────────────────────────┤
│  MT5Service    plain args → typed structs   │  ← YOU ARE HERE
├─────────────────────────────────────────────┤
│  MT5Account    raw protobuf / gRPC          │  ← lowest
└─────────────────────────────────────────────┘
```

Each layer **owns** the one below it: `MT5Sugar` owns an `MT5Service`, which owns an `MT5Account`. From here you can always drop down with `service.account`.

---

## 🧱 Construction & lifecycle

```ruby
require "metarpc_mt5"

# Build a fresh MT5Account underneath, or wrap one you already have:
service = MetaRPC::MT5::MT5Service.new(api_key: ENV["MRPC_API_KEY"])
# service = MetaRPC::MT5::MT5Service.new(existing_account)

service.connect(5057947437, "password", server: "MetaQuotes-Demo")

a = service.account_info            # Account struct
puts "#{a.login}  #{a.balance} #{a.currency}  1:#{a.leverage}"

service.disconnect
```

* `MT5Service.new(account = nil, **opts)` → wraps `account`, or builds a fresh `MT5Account` from `**opts` (`api_key:`, `id:`, `host`, `port`, `timeout:`).
* `service.account` → the underlying `MT5Account` (drop down a layer any time).
* `service.connect(login, password, server:)` — also `connect_by_host` / `connect_proxy`.
* `service.disconnect(delete:)` — pass `delete: true` to free the terminal (otherwise it stays warm).

> **Tuning timeouts.** Unary reads use the underlying `account.timeout` (seconds, default `60`); set `service.account.timeout = 30` to change it.

---

## 📁 Method groups (40+ methods)

| # | Group | Methods |
| - | ----- | ------- |
| 1 | **[Account Methods](./1.%20Account_Methods.md)** (6) | `account_info` · `account_summary` · `demo?` · `account_info_double` · `account_info_integer` · `account_info_string` |
| 2 | **[Symbol Methods](./2.%20Symbol_Methods.md)** (15) | `quote` · `tick` · `symbols` · `symbols_total` · `symbol_name` · `symbol_exist?` · `symbol_synchronized?` · `select_symbol` · `symbol_params` · `symbol_params_all` · `margin_rate` · `tick_value_with_size` · `session_quote` · `session_trade` · `bars` |
| 3 | **[Position & Order Methods](./3.%20Position_Orders_Methods.md)** (6) | `positions_total` · `opened_orders` · `opened_tickets` · `positions` · `order_history` · `positions_history` |
| 4 | **[Trading Methods](./4.%20Trading_Methods.md)** (6) | `order_send` · `order_modify` · `order_close` · `order_check` · `order_calc_margin` · `order_calc_profit` |
| 5 | **[Market Depth Methods](./5.%20MarketDepth_Methods.md)** (3) | `book_add` · `book` · `book_release` |
| 6 | **[Streaming Methods](./6.%20Streaming_Methods.md)** (6) | `subscribe_ticks` · `on_trade` · `on_position_profit` · `on_tickets` · `on_trade_transaction` · `each_tick` |

---

## 🧾 The typed objects (Structs)

`MT5Service` returns two `Struct`s; everything else is the raw protobuf `*Data` (one hop from [MT5Account](../MT5Account/MT5Account.Master.Overview.md)).

| Struct | From | Fields |
| --- | ---- | ------ |
| **`Account`** | `account_info` | `login, balance, equity, currency, leverage, trade_mode, company, server_time_utc` |
| **`Quote`** | `quote` | `symbol, bid, ask, last, spread, time_utc` |

Raw protobuf still comes back from: `positions` / `opened_orders` (`PositionInfo`), `order_send` (`OrderSendData`), `symbol_params` (`SymbolParameters`), `bars` (`PriceBar[]`), `book` (`MarketBookGetData`), history methods (`HistoryData` / `PositionHistoryInfo`).

---

## 💡 Usage examples

### 1) Account snapshot

```ruby
a = service.account_info
puts "##{a.login} · #{a.balance} #{a.currency} · 1:#{a.leverage}"
```

### 2) Current price

```ruby
q = service.quote("EURUSD")
puts "Bid #{q.bid}, Ask #{q.ask}, Spread #{q.spread.round(5)}"
```

### 3) Validate → place an order

```ruby
r = service.order_send(symbol: "EURUSD", type: :buy, volume: 0.1, stop_loss: 1.08, take_profit: 1.09)
puts r.returned_code == 10_009 ? "✅ order ##{r.order}" : "❌ #{r.returned_code_description}"
```

### 4) Live price + floating P&L

```ruby
t = service.subscribe_ticks("EURUSD") { |q| puts "tick #{q.bid} #{q.ask}" }
p = service.on_position_profit { |d| puts "floating: #{d.updated_positions.sum(&:profit).round(2)}" }
# later: t.cancel; p.cancel
```

---

## 📊 Low-level vs mid-level

| Aspect | MT5Account (low) | MT5Service (mid) |
| ------ | ---------------- | ---------------- |
| Arguments | plain args, builds `*Request` | plain args |
| Return | protobuf `*Data` | `Struct` (where it helps) or `*Data` |
| Quotes | `symbol_info_tick` → tick | `quote` → `Quote(bid, ask, spread, …)` |
| Account | `account_summary` → `*Data` | `account_info` → `Account` struct |
| History | manual paging | auto-paged arrays |
| Best for | every field, full control | everyday app code |

---

## 🔧 Best practices

1. **Handle errors with `begin/rescue`.** Every method raises on failure — a server rejection raises `MetaRPC::MT5::ApiError` (carrying the mql / trade codes), a transport failure raises the gRPC error.

   ```ruby
   begin
     a = service.account_info
   rescue MetaRPC::MT5::ApiError => e
     warn "failed: #{e.message}"
   end
   ```

2. **Check the trade retcode.** `order_send` / `order_modify` / `order_close` return a result with a `returned_code` — **`10009` = DONE**. A transport failure after the request may have reached the terminal is raised as a `TradeOutcomeUnknown`-marked error — do not blindly retry.

3. **Tune the timeout** via `service.account.timeout` (seconds) for slow links or heavy history pulls.

4. **Always `cancel`** streaming subscriptions when done — they run on a background thread and don't stop on their own.

5. **Free the terminal** with `service.disconnect(delete: true)` at the end of a one-shot run (a trial allows one terminal per IP).

---

## 📚 Related

- **Down:** [MT5Account — Master Overview](../MT5Account/MT5Account.Master.Overview.md) — raw protobuf, full control.
- **Up:** [MT5Sugar — API Overview](../MT5Sugar/MT5Sugar.API_Overview.md) — one-line helpers.
- **Groups:** [Account](./1.%20Account_Methods.md) · [Symbol](./2.%20Symbol_Methods.md) · [Positions & Orders](./3.%20Position_Orders_Methods.md) · [Trading](./4.%20Trading_Methods.md) · [Market Depth](./5.%20MarketDepth_Methods.md) · [Streaming](./6.%20Streaming_Methods.md).
- **Reference:** [Return Codes](../All_Guides/RETURN_CODES_REFERENCE.md) · [Sync vs Async](../All_Guides/SYNC_VS_ASYNC.md).

---

## 🎯 Summary

MT5Service is the everyday layer: the **same gRPC calls** as MT5Account, but plain arguments in and tidy Ruby objects out — typed `Account` / `Quote` Structs, auto-paged history, filtered positions, no manual request building. Drop to MT5Account for full control, go up to MT5Sugar for one-liners.
