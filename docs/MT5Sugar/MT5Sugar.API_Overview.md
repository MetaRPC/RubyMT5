# MT5Sugar — High-Level API Overview

> One-line helpers for everyday trading: connect, read balances, quote, buy/sell, manage positions, size risk, stream. The friendliest layer — built on **[MT5Service](../MT5Service/MT5Service.Overview.md)**, which is built on **[MT5Account](../MT5Account/MT5Account.Master.Overview.md)**.

**🧩 API Layer:** **HIGH-LEVEL** — maximum convenience, minimum boilerplate.

---

## 🧱 One call builds the whole stack

```ruby
require "metarpc_mt5"

mt5 = MetaRPC::MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
mt5.connect(5057947437, "password", server: "MetaQuotes-Demo")

r = mt5.buy_market("EURUSD", 0.10)
mt5.modify_sl_tp(r.order, stop_loss: 1.0850, take_profit: 1.1000)
puts "balance #{mt5.balance.round(2)}"
```

* `MT5Sugar.create(host = "mt5.mrpc.pro", port = 443, **opts)` → builds `MT5Sugar → MT5Service → MT5Account` (`opts`: `api_key:`, `id:`, `timeout:`).
* `mt5.service` → the mid layer · `mt5.account` → the low layer. Drop down any time.
* `MetaRPC::MT5::Client` aliases `MT5Sugar` — a drop-in friendly entry point.

---

## 🛑 How errors surface

Trading one-liners (`buy_market`, `close_position`, …) return the result `*Data` — **check `returned_code` (`10009` = DONE)**:

```ruby
r = mt5.buy_market("EURUSD", 0.10)
puts r.returned_code == 10_009 ? "✅ ##{r.order}" : "❌ #{r.returned_code_description}"
```

A **hard** failure still raises: a server-side error raises `MetaRPC::MT5::ApiError`, and a transport failure after the request may have reached the terminal raises a `TradeOutcomeUnknown`-marked error — **don't blindly retry a trade**. Read helpers (`balance`, `bid`, `connected?`) return plain values.

---

## 📁 Method groups

| # | Group | What's inside |
| - | ----- | ------------- |
| 1 | **[Connection](./1.%20Connection.md)** | `connect` · `connect_by_host` · `quick_connect` · `connected?` · `reconnect` · `disconnect` |
| 2 | **[Balance & Margin](./2.%20Balance_Margin.md)** | `balance` · `equity` · `margin` · `free_margin` · `margin_level` · `profit` |
| 3 | **[Account Information](./3.%20Account_Information.md)** | `account_info` · `account_summary` · `demo?` |
| 4 | **[Prices & Quotes](./4.%20Prices_Quotes.md)** | `bid` · `ask` · `spread` · `price` |
| 5 | **[Simple Trading](./5.%20Simple_Trading.md)** | `buy_market`/`sell_market` (`buy`/`sell`) · `buy_limit`/`sell_limit` · `buy_stop`/`sell_stop` |
| 6 | **[Trading with SL/TP](./6.%20Trading_SLTP.md)** | `buy_market_with_sl_tp` · `sell_market_with_sl_tp` · `modify_sl` · `modify_tp` · `modify_sl_tp` |
| 7 | **[Position Management](./7.%20Position_Management.md)** | `close_position` · `close_all_positions` · `close_all_by_symbol` · raw `order_send`/`order_modify`/`order_close` |
| 8 | **[Position Information](./8.%20Position_Information.md)** | `open_positions` · `position` · `positions_by_symbol` · `has_position?` · `count_positions` · `total_profit` · `profit_by_symbol` · `open_tickets` |
| 9 | **[History & Statistics](./9.%20History_Statistics.md)** | `order_history` · `positions_history` |
| 10 | **[Symbol Information](./10.%20Symbol_Information.md)** | `symbol_info` · `all_symbols` · `symbols_total` · `symbol_name` · `symbol_available?` · `symbol_digits` · `symbol_point` · `min_stop_level` · `bars` · `session_quote` · `session_trade` |
| 11 | **[Risk Management](./11.%20Risk_Management.md)** | `required_margin` · `calc_profit` · `max_lot` |
| 12 | **[Market Depth (DOM)](./12.%20Market_Depth.md)** | `book_add` · `book` · `book_release` |
| 13 | **[Streaming](./13.%20Streaming.md)** | `subscribe_ticks` · `on_trade` · `on_position_profit` · `on_tickets` · `on_trade_transaction` · `each_tick` |

---

## 🧮 Pips on MT5

Pip size = `point × (digits == 3 || digits == 5 ? 10 : 1)`. So on 5-digit EURUSD one pip = `0.0001`, on 3-digit JPY pairs one pip = `0.01`. Read `point` / `digits` with [`symbol_point`](./10.%20Symbol_Information.md) / [`symbol_digits`](./10.%20Symbol_Information.md).

---

## 📚 See also

* **Down:** [MT5Service — Overview](../MT5Service/MT5Service.Overview.md) · [MT5Account — Master Overview](../MT5Account/MT5Account.Master.Overview.md).
* **Reference:** [Return Codes](../All_Guides/RETURN_CODES_REFERENCE.md) · [Sync vs Async](../All_Guides/SYNC_VS_ASYNC.md).
