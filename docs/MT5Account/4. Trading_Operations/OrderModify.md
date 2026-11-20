# ✏️ Modifying an Order

> **Request:** change SL/TP of a position, or price/SL/TP/expiration of a pending order (`OrderModifyData`).

**API Information:**

* **Low-level API:** `MT5Account#order_modify(ticket:, ...)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.TradingHelper`
* **Proto definition:** `OrderModify` (defined in `mt5-term-api-trading-helper.proto`)

### RPC

* **Service:** `mt5_term_api.TradingHelper`
* **Method:** `OrderModify(OrderModifyRequest) → OrderModifyReply`
* **Low-level client (generated):** `Mt5TermApi::TradingHelper::Stub#order_modify(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One trade RPC that edits an existing ticket — attach/move SL & TP on a position, or retune a pending order's price and expiry.
* **Why you need it.** Trail a stop, lock in profit, re-price a pending order as the market moves.
* **Sanity check.** Success ⇒ `returned_code == 10009`.

> ⚠️ **Exactly-once.** Like every trade call, this is sent once and **never re-sent**. A transport failure after the request may have reached the terminal is marked `TradeOutcomeUnknown` — re-read the position before retrying.

---

## 🎯 Purpose

`order_modify` is **position/order maintenance**. The common job is moving a stop-loss (manual lock-in or an automated trailing stop); the other is re-pricing a working pending order. It never changes volume — for that, close and re-open.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def order_modify(ticket:, stop_loss: nil, take_profit: nil, price: nil,
                   stop_limit: nil, expiration_type: nil, expiration_utc: nil) -> Mt5TermApi::OrderModifyData
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `ticket` | `Integer` *(required)* | Position or order ticket. |
| `stop_loss` / `take_profit` | `Float` | New protective prices. |
| `price` | `Float` | New price (pending orders). |
| `stop_limit` | `Float` | New stop-limit trigger. |
| `expiration_type` / `expiration_utc` | enum / `Time` | New expiry (pending orders). |

## ⬆️ Output — `OrderModifyData`

Same shape as `OrderSendData`: `returned_code` (**10009 = DONE**), `order`, `returned_string_code`, `returned_code_description`, …

---

## 🧱 Enum values

### `expiration_type` → `TMT5_ENUM_ORDER_TYPE_TIME` (raw symbol — passed through, no friendly alias)

```protobuf
TMT5_ORDER_TIME_GTC           = 0
TMT5_ORDER_TIME_DAY           = 1
TMT5_ORDER_TIME_SPECIFIED     = 2
TMT5_ORDER_TIME_SPECIFIED_DAY = 3
```

## 🧩 Notes & Tips

* **Errors are exceptions:** a rejection raises `ApiError`; a transport failure may raise a `TradeOutcomeUnknown`-marked error.
* **Respect the min stop distance** (`:SYMBOL_TRADE_STOPS_LEVEL`) — SL/TP too close to price are rejected.
* **Round** new prices to the symbol's digits (`:SYMBOL_DIGITS`).
* **Only moves what you pass** — omit `take_profit:` and the existing TP is left untouched.

---

## 🔗 Usage Examples

### 1) Attach / move a stop-loss

```ruby
pt  = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
d   = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
bid = acct.symbol_info_tick("EURUSD").bid
acct.order_modify(ticket: 123_456, stop_loss: (bid - 200 * pt).round(d))
```

### 2) Set both SL and TP

```ruby
acct.order_modify(ticket: 123_456, stop_loss: 1.0800, take_profit: 1.1000)
```

### 3) Re-price a pending order

```ruby
acct.order_modify(ticket: 123_456, price: 1.0750)
```

### 4) One trailing-stop step (ratchet up only)

```ruby
pt = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
d  = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
want = (acct.symbol_info_tick("EURUSD").bid - 150 * pt).round(d)
acct.order_modify(ticket: 123_456, stop_loss: want) if want > @best_sl.to_f
@best_sl = want
```

---

## 🔧 Common Patterns

### Safe-modify respecting the stops level

```ruby
def safe_sl(acct, sym, ticket, sl)
  pt    = acct.symbol_info_double(sym, :SYMBOL_POINT)
  d     = acct.symbol_info_integer(sym, :SYMBOL_DIGITS)
  stops = acct.symbol_info_integer(sym, :SYMBOL_TRADE_STOPS_LEVEL)
  bid   = acct.symbol_info_tick(sym).bid
  sl    = [sl, bid - stops * pt].min            # keep it outside the stops level
  acct.order_modify(ticket: ticket, stop_loss: sl.round(d))
end
```

---

## 📚 See Also

* [OrderSend](./OrderSend.md) · [OrderClose](./OrderClose.md)
* **Friendly layer:** [`MT5Sugar#modify_sl` / `#modify_sl_tp`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#order_modify`](../../MT5Service/4.%20Trading_Methods.md).

---

**Back to:** [Trading Operations — Overview](./Trading_Operations.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
