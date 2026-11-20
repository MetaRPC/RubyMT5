# 📘 Positions History (Round-Trips)

> **Request:** closed positions — one row per round-trip (`[PositionHistoryInfo]`), with open/close prices and realized profit. The SDK **auto-pages** and returns the full list.

**API Information:**

* **Low-level API:** `MT5Account#positions_history(from_utc:, to_utc:, sort:, page_size:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountHelper`
* **Proto definition:** `PositionsHistory` (defined in `mt5-term-api-account-helper.proto`)

### RPC

* **Service:** `mt5_term_api.AccountHelper`
* **Method:** `PositionsHistory(PositionsHistoryRequest) → PositionsHistoryReply`
* **Low-level client (generated):** the SDK loops pages via `next_page_token` and concatenates `data.history_positions`.

---

## 💬 Just the essentials

* **What it is.** Closed positions, one row per round-trip (open → close), with realized profit.
* **Why you need it.** Win-rate, equity curve, best/worst trades — the simplest view of trading results.
* **Sanity check.** Rows have a `position_ticket`, `symbol`, `profit`, and open/close prices.

---

## 🎯 Purpose

`positions_history` is the **results** read. Where [`order_history`](./OrderHistory.md) is order/deal grained (one order → several deals), this gives you **one tidy row per completed position** — ideal for performance stats.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def positions_history(from_utc:, to_utc: Time.now.utc,
                        sort: :AH_POSITION_OPEN_TIME_ASC, page_size: 500) -> Array
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `from_utc` | `Time` / `Integer` *(keyword, required)* | Window start (UTC) — filters by position **open** time. |
| `to_utc` | `Time` / `Integer` *(keyword)* | Window end (UTC). Default: now. |
| `sort` | `Symbol` *(keyword)* | Ordering, e.g. `:AH_POSITION_OPEN_TIME_ASC`. |
| `page_size` | `Integer` *(keyword)* | Page size for the internal paging loop. |

## 🧱 Sort enum — `AH_ENUM_POSITIONS_HISTORY_SORT_TYPE` (all 4)

```protobuf
AH_POSITION_OPEN_TIME_ASC  = 0
AH_POSITION_OPEN_TIME_DESC = 1
AH_POSITION_TICKET_ASC     = 2
AH_POSITION_TICKET_DESC    = 3
```

## ⬆️ Output — `[PositionHistoryInfo]`

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `position_ticket` | `position_ticket` | `Integer` | Position ticket (**note:** not `ticket`). |
| `symbol` | `symbol` | `String` | Symbol. |
| `order_type` | `order_type` | `Symbol` | Direction (buy / sell) enum. |
| `volume` | `volume` | `Float` | Volume in lots. |
| `open_price` / `close_price` | `open_price` / `close_price` | `Float` | Entry / exit price. |
| `open_time` / `close_time` | `open_time` / `close_time` | `Timestamp` | Open / close time. |
| `profit` | `profit` | `Float` | Realized profit. |
| `swap` / `commission` / `fee` | `swap` / `commission` / `fee` | `Float` | Costs. |
| `magic` | `magic` | `Integer` | EA magic number. |
| `comment` | `comment` | `String` | Comment. |

---

## 🧱 Enum values (outputs)

### `order_type` → `AH_ENUM_POSITIONS_HISTORY_ORDER_TYPE`

The direction that opened each closed position, as a symbol:

```protobuf
AH_ORDER_TYPE_BUY = 0   AH_ORDER_TYPE_SELL = 1
AH_ORDER_TYPE_BUY_LIMIT = 2   AH_ORDER_TYPE_SELL_LIMIT = 3
AH_ORDER_TYPE_BUY_STOP = 4   AH_ORDER_TYPE_SELL_STOP = 5
AH_ORDER_TYPE_BUY_STOP_LIMIT = 6   AH_ORDER_TYPE_SELL_STOP_LIMIT = 7   AH_ORDER_TYPE_CLOSE_BY = 8
```

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`. Longer internal deadline (history can be large).
* **The ticket accessor is `position_ticket`**, not `ticket`.
* **Filters by open time** — a position opened before `from_utc` but closed inside the window is **not** included.
* **One row per round-trip** — simpler than [`order_history`](./OrderHistory.md) for performance stats.

---

## 🔗 Usage Examples

### 1) Last 7 days of closed positions

```ruby
from = Time.now.utc - 7 * 24 * 3600
acct.positions_history(from_utc: from).each do |p|
  puts format("#%d  %-8s  vol %.2f  %s → %s  profit %.2f",
              p.position_ticket, p.symbol, p.volume, p.open_price, p.close_price, p.profit)
end
```

### 2) Win rate

```ruby
rows = acct.positions_history(from_utc: Time.now.utc - 30 * 24 * 3600)
wins = rows.count { |p| p.profit.positive? }
puts "win rate: #{(100.0 * wins / rows.size).round(1)}% of #{rows.size}"
```

### 3) Best & worst trade

```ruby
rows = acct.positions_history(from_utc: Time.now.utc - 30 * 24 * 3600)
puts "best #{rows.max_by(&:profit)&.profit}  worst #{rows.min_by(&:profit)&.profit}"
```

### 4) Net result including costs

```ruby
rows = acct.positions_history(from_utc: Time.now.utc - 7 * 24 * 3600)
net = rows.sum { |p| p.profit + p.swap + p.commission + p.fee }
puts "net (incl. costs): #{net.round(2)}"
```

---

## 🔧 Common Patterns

### Equity-curve points

```ruby
def equity_curve(acct, days: 30)
  running = 0.0
  acct.positions_history(from_utc: Time.now.utc - days * 24 * 3600)
      .sort_by { |p| p.close_time.seconds }
      .map { |p| running += p.profit; [p.close_time.seconds, running.round(2)] }
end
```

---

## 📚 See Also

* [OrderHistory](./OrderHistory.md) — orders + deals (finer grain).
* **Friendly layer:** [`MT5Sugar#positions_history`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#positions_history`](../../MT5Service/3.%20Position_Orders_Methods.md).

---

**Back to:** [Positions & Orders — Overview](./Position_Orders_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
