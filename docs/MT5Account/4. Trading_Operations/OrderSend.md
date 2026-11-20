# 🚀 Sending an Order

> **Request:** open a **market** or **pending** order (`OrderSendData`). The core trade call.

**API Information:**

* **Low-level API:** `MT5Account#order_send(symbol:, type:, volume:, ...)` · **gRPC:** `mt5_term_api.TradingHelper` · **Proto:** `OrderSend`

### RPC
`OrderSend(OrderSendRequest) → OrderSendReply` — the SDK returns `data` (`OrderSendData`).

---

## 💬 Just the essentials

* **What it is.** Opens a position (market) or places a pending order.
* **Why you need it.** It's how you enter the market.
* **Sanity check.** Success ⇒ `returned_code == 10009` (TRADE_RETCODE_DONE); `order` / `deal` are non-zero.

> ⚠️ **Exactly-once.** A trade is sent once and **never re-sent** by the SDK. A transport failure may leave the outcome unknown (`TradeOutcomeUnknown`) — check positions/history before retrying.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def order_send(symbol:, type:, volume:,
                 price: nil, stop_loss: nil, take_profit: nil, comment: nil,
                 magic: nil, slippage: nil, stop_limit_price: nil,
                 expiration_type: nil, expiration_utc: nil, quotes_wait_ms: nil,
                 without_checks: false) -> Mt5TermApi::OrderSendData
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` *(required)* | Symbol, e.g. `"EURUSD"`. |
| `type` | `Symbol` *(required)* | `:buy` / `:sell` / `:buy_limit` / `:sell_limit` / `:buy_stop` / `:sell_stop` / `:buy_stop_limit` / `:sell_stop_limit`. |
| `volume` | `Float` *(required)* | Lots. |
| `price` | `Float` | Entry price. Required for pending orders; for market orders the server fills at market. |
| `stop_loss` / `take_profit` | `Float` | Protective prices (optional). |
| `comment` | `String` | Free-text tag (optional). |
| `magic` | `Integer` | EA magic → `expert_id` (optional). |
| `slippage` | `Integer` | Max price deviation (optional). |
| `stop_limit_price` | `Float` | Trigger price for stop-limit orders. |
| `expiration_type` / `expiration_utc` | enum / `Time` | Pending-order expiry (optional). |
| `without_checks` | `Boolean` | Use `OrderSendWithoutChecks` (skip terminal-side checks). |

---

## ⬆️ Output — `OrderSendData`

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `returned_code` | `returned_code` | `Integer` | Trade-server retcode — **`10009` = DONE**. |
| `order` | `order` | `Integer` | New order ticket. |
| `deal` | `deal` | `Integer` | Resulting deal ticket (market orders). |
| `volume` | `volume` | `Float` | Filled volume. |
| `price` | `price` | `Float` | Fill price. |
| `bid` / `ask` | `bid` / `ask` | `Float` | Market at execution. |
| `comment` | `comment` | `String` | Server comment. |
| `returned_string_code` | `returned_string_code` | `String` | Retcode as text. |
| `returned_code_description` | `returned_code_description` | `String` | Human-readable description. |

---

## 🧱 Enum values

### `type` → `TMT5_ENUM_ORDER_TYPE`

The method maps a **friendly** symbol to the wire enum — or pass the raw `TMT5_ORDER_TYPE_*` symbol directly:

| Friendly `type:` | Raw enum | # |
|---|---|---|
| `:buy` | `TMT5_ORDER_TYPE_BUY` | 0 |
| `:sell` | `TMT5_ORDER_TYPE_SELL` | 1 |
| `:buy_limit` | `TMT5_ORDER_TYPE_BUY_LIMIT` | 2 |
| `:sell_limit` | `TMT5_ORDER_TYPE_SELL_LIMIT` | 3 |
| `:buy_stop` | `TMT5_ORDER_TYPE_BUY_STOP` | 4 |
| `:sell_stop` | `TMT5_ORDER_TYPE_SELL_STOP` | 5 |
| `:buy_stop_limit` | `TMT5_ORDER_TYPE_BUY_STOP_LIMIT` | 6 |
| `:sell_stop_limit` | `TMT5_ORDER_TYPE_SELL_STOP_LIMIT` | 7 |
| — *(raw only)* | `TMT5_ORDER_TYPE_CLOSE_BY` | 8 |

### `expiration_type` → `TMT5_ENUM_ORDER_TYPE_TIME` (raw symbol — no friendly alias)

```protobuf
TMT5_ORDER_TIME_GTC           = 0
TMT5_ORDER_TIME_DAY           = 1
TMT5_ORDER_TIME_SPECIFIED     = 2
TMT5_ORDER_TIME_SPECIFIED_DAY = 3
```

## 🧩 Notes & Tips

* **Errors are exceptions:** a rejection raises `ApiError`; a transport failure may raise a `TradeOutcomeUnknown`-marked error — **do not blindly retry**.
* **Round prices** to the symbol's digits (`symbol_info_integer(sym, :SYMBOL_DIGITS)`) and respect the min stop distance (`:SYMBOL_TRADE_STOPS_LEVEL`).
* **Market vs pending:** pending orders require `price:` (and face/break the market per type).

---

## 🔗 Usage Examples

### 1) Market buy

```ruby
r = acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.1, magic: 600001, comment: "entry")
if r.returned_code == 10_009
  puts "opened order ##{r.order} deal ##{r.deal} @ #{r.price}"
else
  puts "rejected: #{r.returned_code} #{r.returned_code_description}"
end
```

### 2) Market buy with SL/TP

```ruby
t = acct.symbol_info_tick("EURUSD"); d = acct.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)
pt = acct.symbol_info_double("EURUSD", :SYMBOL_POINT)
acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.1,
                stop_loss: (t.bid - 500*pt).round(d), take_profit: (t.ask + 500*pt).round(d))
```

### 3) Pending buy-limit below market

```ruby
bid = acct.symbol_info_tick("EURUSD").bid
acct.order_send(symbol: "EURUSD", type: :buy_limit, volume: 0.1, price: (bid - 0.0030).round(5))
```

---

## 📚 See Also

* [OrderModify](./OrderModify.md) · [OrderClose](./OrderClose.md) · [OrderCheck](./OrderCheck.md)
* [OrderCalcMargin](./OrderCalcMargin.md) — size before sending.
* **Friendly layer:** [`MT5Sugar#buy_market` / `#buy_limit` / `#buy_market_with_sl_tp`](../../MT5Sugar/MT5Sugar.API_Overview.md).

---

**Back to:** [Trading Operations — Overview](./Trading_Operations.Overview.md) · [Master Overview](../MT5Account.Master.Overview.md)
