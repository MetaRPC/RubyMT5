# Glossary

> The MT5, trading and SDK terms you'll meet in these docs, grouped by kind.

---

## 🏗️ Architectural terms

**Three-layer architecture** — the SDK is three decoupled layers, each owning the one below (`sugar.service` → `MT5Service`, `service.account` → `MT5Account`). See the [Project Map](./PROJECT_MAP.md).

**MT5Account** — the low-level layer. Raw gRPC: you pass protobuf `*Request` messages and read `*Reply` / `*Data` replies via their snake_case accessors. Owns the channel, the gRPC stubs, auth metadata, reconnect and streaming. → [overview](../MT5Account/MT5Account.Master.Overview.md)

**MT5Service** — the mid layer. Same calls, but it builds the protobuf from plain arguments and returns typed Ruby `Struct`s (`Account`, `Quote`…). → [overview](../MT5Service/MT5Service.Overview.md)

**MT5Sugar** — the high layer. One-line helpers (`buy_market`, `close_all_positions`) with smart defaults; trade helpers return the result data (check `returned_code`). → [overview](../MT5Sugar/MT5Sugar.API_Overview.md)

**Struct (DTO)** — the plain Ruby `Struct` objects `MT5Service` returns instead of protobuf (`Account`, `Quote`…), with read-only attribute methods.

**ApiError** — the error raised when the gateway or terminal reports a problem (`MetaRPC::MT5::ApiError`). `InvalidLoginError` flags never-retry auth failures; `TradeOutcomeUnknown` marks a trade whose result is uncertain after a transport failure. See [Return Codes → the error model](./RETURN_CODES_REFERENCE.md).

**Subscription** — what a streaming method returns (`MetaRPC::MT5::Subscription`): call `cancel` to stop the stream; `count` / `error` report its state.

**Client / Account aliases** — `MetaRPC::MT5::Client` aliases `MT5Sugar`; `MetaRPC::MT5::Account` aliases `MT5Account`.

---

## 💎 Ruby-specific concepts

**Blocks for streams** — a streaming method yields each payload to the block you pass, and returns a `Subscription` to stop it.

```ruby
sub = mt5.on_symbol_tick("EURUSD") { |t| puts "#{t.bid} / #{t.ask}" }
# later:
sub.cancel
```

**Keyword arguments** — optional parameters are passed by name, not position.

```ruby
mt5.connect(5057947437, "password", server: "MetaQuotes-Demo")
mt5.buy_market_with_sl_tp("EURUSD", 0.01, sl: 1.0820, tp: 1.0920, comment: "demo")
```

**Enums as symbols** — protobuf enums are Ruby symbols, both in and out (`:MRPC_ACCOUNT_TRADE_MODE_DEMO`, `:ACCOUNT_BALANCE`). See the [ENUMs Reference](./ENUMS_USAGE_REFERENCE.md).

```ruby
mode = mt5.account.account_info_double(:ACCOUNT_BALANCE)
```

**Typed Structs vs protobuf stubs** — the low layer returns generated protobuf objects (snake_case accessors like `reply.account_balance`); the mid layer unwraps them into typed `Struct`s. Discover real field names with the [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md).

```ruby
d = mt5.account.opened_orders          # low: protobuf, d.position_infos
ps = mt5.service.opened_orders         # mid: typed objects
```

**Error handling — `begin / rescue`** — wrap calls that can fail; rescue `MetaRPC::MT5::ApiError` (or its subclasses).

```ruby
begin
  mt5.buy_market("EURUSD", 0.01)
rescue MetaRPC::MT5::ApiError => e
  warn "trade failed: #{e.message}"
end
```

**Connection & cleanup** — `connect` / `quick_connect` opens the terminal session; `disconnect` closes it and **frees the terminal** (a trial allows one per IP). Use `ensure`.

```ruby
begin
  # …
ensure
  mt5.disconnect
end
```

---

## 🎓 Trading terms

### Account

**Balance** — closed-trade money; excludes floating P/L. **Equity** — balance + floating P/L; moves with open positions. **Margin** — funds locked to hold positions. **Free margin** — equity − margin; available to open more. **Margin level** — equity / margin × 100 (%); low levels risk a **stop-out**. **Leverage** — the multiplier (1:100) setting margin need. **Trade mode** — `DEMO`, `CONTEST` or `REAL`.

### Instruments & prices

**Symbol** — a tradable instrument (`EURUSD`, `XAUUSD`). **Bid / Ask** — sell / buy price; **spread** = ask − bid. **Digits** — decimal places (5 for EURUSD, 3 for JPY). **Tick** — one price update (`symbol_info_tick` / `on_symbol_tick`). **DOM (Depth of Market)** — the order book: pending volume at each price level.

### Orders, positions & deals (MT5 model)

**Order** — an instruction to trade. **Market** fills now; **pending** (LIMIT/STOP/STOP_LIMIT) waits for a price. **Position** — an *open* trade; on MT5 distinct from the order and the deals. **Deal** — a single execution (fill); a position is the net of its deals. **Ticket** — the numeric id (a filled market order's order ticket = its position ticket). **Order type** — three different enums by context: `TMT5_ORDER_TYPE_*` (order_send), `ORDER_TYPE_TF_*` (calculators / order_check), MQL `ORDER_TYPE_*` (margin rate). `BUY=0, SELL=1, …`. **Position type**: `0 = BUY`, `1 = SELL`. **SL / TP** — stop-loss / take-profit auto-close levels. **Magic number** — a client id tagging a strategy's orders. **RetCode** (`returned_code`) — the trade-server return code; **`10009` = DONE**. See [Return Codes](./RETURN_CODES_REFERENCE.md).

---

## 📦 Technical concepts

**Point** — the smallest price increment (`0.00001` on 5-digit EURUSD). **Pip** — the conventional move unit; on a 3- or 5-digit symbol `pip = point × 10`, so one pip on EURUSD = `0.0001`. **Tick value / tick size** — the money value of one tick, and the price change one tick represents — inputs for P&L and sizing.

**Lot / volume** — trade size in lots (`0.01` = micro). Must obey **volume limits** (`volume_min` / `volume_max` / `volume_step`). **Contract size** — units of the base instrument per 1.0 lot.

**Risk-based sizing** — picking the lot so a stop of N pips loses a fixed amount: combine [`calc_profit`](../MT5Sugar/11.%20Risk_Management.md), `required_margin` and `max_lot`. **Risk amount** = `balance × risk_percent / 100`. **Required margin** — margin a prospective order needs. **Drawdown** — the drop from a peak to current equity, %.

**Stops level** (`SYMBOL_TRADE_STOPS_LEVEL`) — minimum distance, in points, SL/TP may sit from the market; closer → retcode `10016`.

**Trailing stop** — a stop that ratchets in your favour, never back ([orchestrator](../Strategies/Orchestrators/TrailingStop.md)). **Breakeven** — moving the stop to entry once in profit. **Hedging** — holding BUY and SELL on one symbol at once (hedging accounts). **Grid trading** — bracketing price with pending orders ([orchestrator](../Strategies/Orchestrators/GridTrader.md)). **Scalping** — many small short-lived trades. **News trading** — trading around releases; expect wide spreads / rejections. **Kill-switch** — close everything on a drawdown/margin breach ([risk manager](../Strategies/Orchestrators/RiskManager.md)).

---

## 🔌 gRPC & protocol terms

**gRPC** — the RPC protocol the SDK speaks to `mt5.mrpc.pro:443` (HTTP/2 + protobuf over TLS).

**Protobuf** — the binary message format. On the low layer you build `*Request` messages and read `*Reply` replies via snake_case accessors; `MT5Service` hides this behind typed Structs. The generated stubs live in `package/`.

**Streaming pattern** — a server stream delivered via a block: a streaming method yields each payload and returns a `Subscription`. See [gRPC Stream Management](./GRPC_STREAM_MANAGEMENT.md).

**Gateway** — the MetaRPC service (`mt5.mrpc.pro`) bridging the SDK to MT5 terminals and managing sessions. **Terminal** — the MT5 instance your account runs on behind the gateway. **Session / terminal instance guid** — the id obtained on `connect` (ConnectEx), attached with your API key to every later call automatically (on `mt5.account.server_guid`). **API key** — your MetaRPC key; pass it to `MT5Sugar.create(...)`, or use `"TRIAL"`.

---

## See also

* [Project Map](./PROJECT_MAP.md) · [MT5 for Beginners](./MT5_For_Beginners.md) · [Getting Started](./GETTING_STARTED.md) · [Return Codes](./RETURN_CODES_REFERENCE.md) · [SDK Ecosystem](./SDK_Ecosystem.md)
