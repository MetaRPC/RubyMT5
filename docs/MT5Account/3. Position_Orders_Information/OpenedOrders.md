# 📂 Open Positions & Pending Orders

> **Request:** everything open right now (`OpenedOrdersData`) — filled **positions** and working **orders** — in one call.

**API Information:**

* **Low-level API:** `MT5Account#opened_orders(sort:)` · **gRPC:** `mt5_term_api.AccountHelper` · **Proto:** `OpenedOrders`

### RPC
`OpenedOrders(OpenedOrdersRequest) → OpenedOrdersReply` — the SDK returns `data` (`OpenedOrdersData`).

---

## 💬 Just the essentials

* **What it is.** One RPC returning open **positions** (`position_infos`) and pending **orders** (`opened_orders`).
* **Why you need it.** Build a live book, compute exposure, find a ticket to modify/close.
* **Sanity check.** `position_infos.size` matches [`positions_total`](./PositionsTotal.md).

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Open positions + pending orders. sort: a BMT5_OPENED_ORDER_SORT_* symbol.
  def opened_orders(sort: :BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC) -> Mt5TermApi::OpenedOrdersData
end
```

**Request message:** `OpenedOrdersRequest { EnumOpenedOrderSortType inputSortMode = 1; }`

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `sort` | `Symbol` *(keyword)* | Ordering, e.g. `:BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC`. |

---

## 🧱 Sort enum — `BMT5_ENUM_OPENED_ORDER_SORT_TYPE` (all 4)

```protobuf
BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC        = 0
BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_DESC       = 1
BMT5_OPENED_ORDER_SORT_BY_ORDER_TICKET_ID_ASC  = 2
BMT5_OPENED_ORDER_SORT_BY_ORDER_TICKET_ID_DESC = 3
```

## ⬆️ Output — `OpenedOrdersData`

* **`position_infos`** → `[PositionInfo]` — filled positions.
* **`opened_orders`** → `[]` — pending / working orders.

### `PositionInfo` (key fields)

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `ticket` | `ticket` | `Integer` | Position ticket (unique id). |
| `symbol` | `symbol` | `String` | Symbol. |
| `type` | `type` | `Symbol` | Position direction (buy / sell) enum. |
| `volume` | `volume` | `Float` | Volume in lots. |
| `price_open` | `price_open` | `Float` | Entry price. |
| `price_current` | `price_current` | `Float` | Current market price. |
| `stop_loss` / `take_profit` | `stop_loss` / `take_profit` | `Float` | SL / TP (`0` = none). |
| `profit` | `profit` | `Float` | Current floating P/L. |
| `swap` | `swap` | `Float` | Accrued swap. |
| `position_commission` | `position_commission` | `Float` | Commission. |
| `magic_number` | `magic_number` | `Integer` | EA magic number. |
| `comment` | `comment` | `String` | Order comment. |
| `open_time` / `open_time_utc` | `open_time` / `open_time_utc` | `Timestamp` | Open time (broker / UTC). |
| `identifier` | `identifier` | `Integer` | Position identifier (stable across partial closes). |

---

## 🧱 Enum values (outputs)

The enum-typed fields on each returned row come back as Ruby symbols:

??? info "`PositionInfo.type` → `BMT5_ENUM_POSITION_TYPE`"
    ```protobuf
    BMT5_POSITION_TYPE_BUY  = 0
    BMT5_POSITION_TYPE_SELL = 1
    ```

??? info "`PositionInfo.reason` → `BMT5_ENUM_POSITION_REASON`"
    ```protobuf
    BMT5_POSITION_REASON_CLIENT = 0
    BMT5_POSITION_REASON_MOBILE = 1
    BMT5_POSITION_REASON_WEB    = 2
    BMT5_POSITION_REASON_EXPERT = 3
    ORDER_REASON_SL             = 4
    ORDER_REASON_TP             = 5
    ORDER_REASON_SO             = 6
    ```

??? info "`OpenedOrderInfo.type` → `BMT5_ENUM_ORDER_TYPE`"
    ```protobuf
    BMT5_ORDER_TYPE_BUY = 0   BMT5_ORDER_TYPE_SELL = 1
    BMT5_ORDER_TYPE_BUY_LIMIT = 2   BMT5_ORDER_TYPE_SELL_LIMIT = 3
    BMT5_ORDER_TYPE_BUY_STOP = 4   BMT5_ORDER_TYPE_SELL_STOP = 5
    BMT5_ORDER_TYPE_BUY_STOP_LIMIT = 6   BMT5_ORDER_TYPE_SELL_STOP_LIMIT = 7   BMT5_ORDER_TYPE_CLOSE_BY = 8
    ```

??? info "`OpenedOrderInfo.state` → `BMT5_ENUM_ORDER_STATE`"
    ```protobuf
    BMT5_ORDER_STATE_STARTED = 0   BMT5_ORDER_STATE_PLACED = 1   BMT5_ORDER_STATE_CANCELED = 2
    BMT5_ORDER_STATE_PARTIAL = 3   BMT5_ORDER_STATE_FILLED = 4   BMT5_ORDER_STATE_REJECTED = 5
    BMT5_ORDER_STATE_EXPIRED = 6   BMT5_ORDER_STATE_REQUEST_ADD = 7
    BMT5_ORDER_STATE_REQUEST_MODIFY = 8   BMT5_ORDER_STATE_REQUEST_CANCEL = 9
    ```

??? info "`OpenedOrderInfo.type_filling` → `BMT5_ENUM_ORDER_TYPE_FILLING`"
    ```protobuf
    BMT5_ORDER_FILLING_FOK = 0   BMT5_ORDER_FILLING_IOC = 1   BMT5_ORDER_FILLING_RETURN = 2   BMT5_ORDER_FILLING_BOC = 3
    ```

??? info "`OpenedOrderInfo.type_time` → `BMT5_ENUM_ORDER_TYPE_TIME`"
    ```protobuf
    BMT5_ORDER_TIME_GTC = 0   BMT5_ORDER_TIME_DAY = 1   BMT5_ORDER_TIME_SPECIFIED = 2   BMT5_ORDER_TIME_SPECIFIED_DAY = 3
    ```

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`.
* **Filter in Ruby** by `magic_number` / `symbol`, or use [`MT5Service#positions(magic:, symbol:)`](../../MT5Service/MT5Service.Overview.md).
* **Lightweight alternative:** [`opened_orders_tickets`](./OpenedOrdersTickets.md) when you only need ids.

---

## 🔗 Usage Examples

### 1) List open positions

```ruby
acct.opened_orders.position_infos.each do |p|
  puts format("#%d %-8s %s %.2f @ %s  P/L %.2f", p.ticket, p.symbol, p.type, p.volume, p.price_open, p.profit)
end
```

### 2) Total exposure by symbol

```ruby
by_sym = Hash.new(0.0)
acct.opened_orders.position_infos.each { |p| by_sym[p.symbol] += p.volume }
p by_sym
```

### 3) Find a ticket to close

```ruby
pos = acct.opened_orders.position_infos.find { |p| p.symbol == "EURUSD" }
acct.order_close(ticket: pos.ticket) if pos
```

---

## 📚 See Also

* [PositionsTotal](./PositionsTotal.md) · [OpenedOrdersTickets](./OpenedOrdersTickets.md)
* [OrderClose](../4.%20Trading_Operations/OrderClose.md) · [OrderModify](../4.%20Trading_Operations/OrderModify.md)
* **Friendly layer:** [`MT5Service#positions`](../../MT5Service/MT5Service.Overview.md).

---

**Back to:** [Positions & Orders — Overview](./Position_Orders_Information.Overview.md) · [Master Overview](../MT5Account.Master.Overview.md)
