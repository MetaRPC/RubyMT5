# MT5Account — Master Overview

> One page to **orient fast**: what lives where, how to choose the right API, and jump links to every **overview** and **method spec** in this docs set.

`MetaRPC::MT5::MT5Account` (from the `metarpc_mt5` gem) is the **low-level** layer — a thin, 1:1-with-the-wire client. Each method maps to a single gRPC RPC: you pass the plain arguments, it builds the generated protobuf `*Request`, sends it with the APIKey + terminal-id metadata, and returns the reply's `*Data` payload — or raises `MetaRPC::MT5::ApiError`. It owns the gRPC channel, the service stubs, the auth metadata and the connection lifecycle.

```ruby
require "metarpc_mt5"
acct = MetaRPC::MT5::MT5Account.new("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
```

!!! note "When to use this layer"
    Use `MT5Account` when you need a field the friendly layers do not expose, or full control over the exact request. For everyday work prefer [`MT5Service`](../MT5Service/MT5Service.Overview.md) (plain args + typed Structs) or [`MT5Sugar`](../MT5Sugar/MT5Sugar.API_Overview.md) (one-liners).

---

## 🚦 Start here — Section Overviews

* **[Account Information — Overview](./1.%20Account_Information/Account_Information.Overview.md)**
  Account balance / equity / margin / leverage — the complete snapshot in one call, or single properties.

* **[Symbol Information — Overview](./2.%20Symbol_Information/Symbol_Information.Overview.md)**
  Quotes, symbol properties, trading rules, Market Watch management.

* **[Positions & Orders — Overview](./3.%20Position_Orders_Information/Position_Orders_Information.Overview.md)**
  Open positions, pending orders, historical deals and order history.

* **[Trading Operations — Overview](./4.%20Trading_Operations/Trading_Operations.Overview.md)**
  Order execution, position management, margin/profit calculations, trade validation.

* **[Market Depth (DOM) — Overview](./5.%20Market_Depth(DOM)/Market_Depth.Overview.md)**
  Level-II quotes / order book — subscribe, read, release.

* **[Additional Methods — Overview](./6.%20Additional_Methods/Additional_Methods.Overview.md)**
  Margin rates, trading sessions, batch symbol params, tick value.

* **[Streaming Methods — Overview](./7.%20Streaming_Methods/Streaming_Methods.Overview.md)**
  Real-time streams: ticks, trades, position-profit, ticket snapshots, transactions.

---

## 🧭 How to pick an API

| If you need…                        | Go to…                | Typical calls                                                          |
| ----------------------------------- | --------------------- | --------------------------------------------------------------------- |
| Account snapshot                    | Account Information   | `account_summary`                                                     |
| A single account property           | Account Information   | `account_info_double` / `_integer` / `_string`                       |
| Live quotes / symbol props          | Symbol Information    | `symbol_info_tick`, `symbol_info_double`, `symbol_select`            |
| Open positions / pending orders     | Positions & Orders    | `opened_orders`, `positions_total`, `opened_orders_tickets`          |
| Closed deals / order history        | Positions & Orders    | `order_history`, `positions_history`                                 |
| Place / modify / close an order     | Trading Operations    | `order_send`, `order_modify`, `order_close`                         |
| Validate / size before trading      | Trading Operations    | `order_check`, `order_calc_margin`, `order_calc_profit`             |
| Level-II order book                 | Market Depth (DOM)    | `market_book_add`, `market_book_get`, `market_book_release`         |
| Margin rates / sessions / batch     | Additional Methods    | `symbol_info_margin_rate`, `symbol_params_many`, `tick_value_with_size` |
| Real-time updates                   | Streaming Methods     | `on_symbol_tick`, `on_trade`, `on_position_profit`                  |

---

## 🔌 Usage pattern (raw gRPC)

Every method is called on an `MT5Account`. It owns the gRPC channel, sends the terminal id and API key as metadata, and unwraps the reply — returning the protobuf `*Data` payload or **raising** an error.

```ruby
require "metarpc_mt5"

# Create the client (prepares the gRPC channel; api_key from MRPC_API_KEY)
acct = MetaRPC::MT5::MT5Account.new("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])

# Connect the terminal (ConnectEx by broker server name).
# The gateway returns a terminal session GUID; later calls reuse it automatically.
acct.connect(5057947437, "password", server: "MetaQuotes-Demo")

# Call a method: returns the *Data payload, or raises ApiError / a gRPC error.
s = acct.account_summary
puts "Balance: #{s.account_balance} #{s.account_currency}"
```

Every method follows the same shape:

* **Proto Service/Method:** `Service.Method(Request) → Reply`
* **Client call:** `acct.method(args)` returns the `*Data` payload.
* **Reply structure:** the reply carries either a `data` payload or an `error`; `MT5Account` returns the `data` and turns `error` into a raised **`ApiError`**.
* **Errors are exceptions** — there are no error return values; wrap calls in `begin/rescue`.

**Field access:** the generated protobuf messages expose **snake_case** readers — `s.account_balance`, not `getAccountBalance()`. The friendly `MT5Service` layer converts these into plain Ruby Structs for you.

**Timestamps:** proto uses `google.protobuf.Timestamp` (or raw unix seconds on some messages); read `.seconds`. `MT5Service` returns numbers / UTC instead.

**Streaming methods:** return a `Subscription` handle. The SDK reads the stream on a background thread and invokes your block for each payload; call `subscription.cancel` to stop.

---

## 📚 Full index · all method specs

### 1 · Account Information · [Overview](./1.%20Account_Information/Account_Information.Overview.md)
* [AccountSummary](./1.%20Account_Information/AccountSummary.md) — all account data in one call.
* [AccountInfoDouble](./1.%20Account_Information/AccountInfoDouble.md) — one ACCOUNT_* double property.
* [AccountInfoInteger](./1.%20Account_Information/AccountInfoInteger.md) — one ACCOUNT_* integer property.
* [AccountInfoString](./1.%20Account_Information/AccountInfoString.md) — one ACCOUNT_* string property.

### 2 · Symbol Information · [Overview](./2.%20Symbol_Information/Symbol_Information.Overview.md)
* [SymbolsTotal](./2.%20Symbol_Information/SymbolsTotal.md) · [SymbolExist](./2.%20Symbol_Information/SymbolExist.md) · [SymbolName](./2.%20Symbol_Information/SymbolName.md)
* [SymbolSelect](./2.%20Symbol_Information/SymbolSelect.md) · [SymbolIsSynchronized](./2.%20Symbol_Information/SymbolIsSynchronized.md)
* [SymbolInfoDouble](./2.%20Symbol_Information/SymbolInfoDouble.md) · [SymbolInfoInteger](./2.%20Symbol_Information/SymbolInfoInteger.md) · [SymbolInfoString](./2.%20Symbol_Information/SymbolInfoString.md)
* [SymbolInfoTick](./2.%20Symbol_Information/SymbolInfoTick.md)

### 3 · Positions & Orders · [Overview](./3.%20Position_Orders_Information/Position_Orders_Information.Overview.md)
* [PositionsTotal](./3.%20Position_Orders_Information/PositionsTotal.md) · [OpenedOrders](./3.%20Position_Orders_Information/OpenedOrders.md) · [OpenedOrdersTickets](./3.%20Position_Orders_Information/OpenedOrdersTickets.md)
* [OrderHistory](./3.%20Position_Orders_Information/OrderHistory.md) · [PositionsHistory](./3.%20Position_Orders_Information/PositionsHistory.md)

### 4 · Trading Operations · [Overview](./4.%20Trading_Operations/Trading_Operations.Overview.md)
* [OrderSend](./4.%20Trading_Operations/OrderSend.md) · [OrderModify](./4.%20Trading_Operations/OrderModify.md) · [OrderClose](./4.%20Trading_Operations/OrderClose.md)
* [OrderCheck](./4.%20Trading_Operations/OrderCheck.md) · [OrderCalcMargin](./4.%20Trading_Operations/OrderCalcMargin.md) · [OrderCalcProfit](./4.%20Trading_Operations/OrderCalcProfit.md)

### 5 · Market Depth (DOM) · [Overview](./5.%20Market_Depth(DOM)/Market_Depth.Overview.md)
* [MarketBookAdd](./5.%20Market_Depth(DOM)/MarketBookAdd.md) · [MarketBookGet](./5.%20Market_Depth(DOM)/MarketBookGet.md) · [MarketBookRelease](./5.%20Market_Depth(DOM)/MarketBookRelease.md)

### 6 · Additional Methods · [Overview](./6.%20Additional_Methods/Additional_Methods.Overview.md)
* [SymbolParamsMany](./6.%20Additional_Methods/SymbolParamsMany.md) · [TickValueWithSize](./6.%20Additional_Methods/TickValueWithSize.md)
* [SymbolInfoMarginRate](./6.%20Additional_Methods/SymbolInfoMarginRate.md) · [SymbolInfoSessionQuote](./6.%20Additional_Methods/SymbolInfoSessionQuote.md) · [SymbolInfoSessionTrade](./6.%20Additional_Methods/SymbolInfoSessionTrade.md)

### 7 · Streaming Methods · [Overview](./7.%20Streaming_Methods/Streaming_Methods.Overview.md)
* [OnSymbolTick](./7.%20Streaming_Methods/OnSymbolTick.md) · [OnTrade](./7.%20Streaming_Methods/OnTrade.md)
* [OnPositionProfit](./7.%20Streaming_Methods/OnPositionProfit.md) · [OnPositionsAndPendingOrdersTickets](./7.%20Streaming_Methods/OnPositionsAndPendingOrdersTickets.md) · [OnTradeTransaction](./7.%20Streaming_Methods/OnTradeTransaction.md)

> **Connection methods** (`connect` / `connect_by_host` / `connect_proxy` / `get_id` / `check_connect` / `connection_status` / `reconnect` / `disconnect` / `close`) are shown in the **Usage pattern** above and in [Getting Started](../All_Guides/GETTING_STARTED.md).

---

## 🏗️ API Architecture

### Layer 1: MT5Account (Low-Level) — You are here!

**What:** direct protobuf/gRPC communication with the MT5 terminal. Plain arguments in, protobuf `*Data` out; complete access to every MT5 function; highest control. **Location:** `lib/metarpc_mt5/mt5_account.rb`.

### Layer 2: MT5Service

**What:** a friendly facade over `MT5Account` — plain arguments and typed Ruby Structs (`Account`, `Quote`…). No protobuf. **Location:** `lib/metarpc_mt5/mt5_service.rb` → [overview](../MT5Service/MT5Service.Overview.md).

### Layer 3: MT5Sugar

**What:** high-level convenience API — one-liners, risk-based position sizing, smart defaults. **Location:** `lib/metarpc_mt5/mt5_sugar.rb` → [overview](../MT5Sugar/MT5Sugar.API_Overview.md).

Each layer **owns** the one below it: `MT5Sugar` owns an `MT5Service`, which owns an `MT5Account`. From Sugar you can always reach down with `sugar.service` and `sugar.account`. (`MetaRPC::MT5::Client` aliases `MT5Sugar`; `MetaRPC::MT5::Account` aliases `MT5Account`.)

---

## 💡 Key concepts

* **Errors are exceptions.** A server-side rejection raises `MetaRPC::MT5::ApiError` (carrying the `mql` / trade codes); a transport failure raises the gRPC error. There are no error return values.
* **Session id is automatic.** `connect` (ConnectEx) obtains a terminal session GUID; the SDK attaches it (+ your api key) to every later call and stream. Pass a **stable `id:`** per strategy so the gateway reuses one terminal.
* **Trade retcode.** `order_send` / `order_close` carry a trade-server result code — **`10009` = DONE** (success). See [Return Codes](../All_Guides/RETURN_CODES_REFERENCE.md).
* **MT5 has positions.** Unlike MT4, MT5 separates **positions** (net market exposure), **orders** (pending/working) and **deals** (executed transactions in history).

---

"Trade safe, code clean, and may your gRPC streams always flow smoothly."
