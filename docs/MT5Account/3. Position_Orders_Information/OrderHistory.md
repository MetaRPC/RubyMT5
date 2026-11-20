# 📜 Order & Deal History

> **Request:** closed orders and deals in a time window (`[HistoryData]`). The SDK **auto-pages** the gateway and returns the full list.

**API Information:**

* **Low-level API:** `MT5Account#order_history(from_utc:, to_utc:, sort:, page_size:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountHelper`
* **Proto definition:** `OrderHistory` (defined in `mt5-term-api-account-helper.proto`)

### RPC

* **Service:** `mt5_term_api.AccountHelper`
* **Method:** `OrderHistory(OrderHistoryRequest) → OrderHistoryReply`
* **Low-level client (generated):** the SDK loops pages via `next_page_token` and concatenates `data.history_data`.

---

## 💬 Just the essentials

* **What it is.** Historical orders + deals between two UTC times, fully paged for you.
* **Why you need it.** P/L reports, trade journals, reconciliation against your own records.
* **Sanity check.** Each `HistoryData` carries a `history_order` and/or `history_deal`.

---

## 🎯 Purpose

`order_history` is the **audit trail** at order/deal grain. One order can produce several deals (partial fills), so iterate `history_deal` for realized money. For a simpler "one row per round-trip" view, use [`positions_history`](./PositionsHistory.md) instead.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def order_history(from_utc:, to_utc: Time.now.utc,
                    sort: :BMT5_SORT_BY_CLOSE_TIME_ASC, page_size: 500) -> Array
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `from_utc` | `Time` / `Integer` *(keyword, required)* | Window start (UTC). |
| `to_utc` | `Time` / `Integer` *(keyword)* | Window end (UTC). Default: now. |
| `sort` | `Symbol` *(keyword)* | Ordering, e.g. `:BMT5_SORT_BY_CLOSE_TIME_ASC`. |
| `page_size` | `Integer` *(keyword)* | Page size for the internal paging loop. |

## 🧱 Sort enum — `BMT5_ENUM_ORDER_HISTORY_SORT_TYPE` (all 6)

```protobuf
BMT5_SORT_BY_OPEN_TIME_ASC        = 0
BMT5_SORT_BY_OPEN_TIME_DESC       = 1
BMT5_SORT_BY_CLOSE_TIME_ASC       = 2
BMT5_SORT_BY_CLOSE_TIME_DESC      = 3
BMT5_SORT_BY_ORDER_TICKET_ID_ASC  = 4
BMT5_SORT_BY_ORDER_TICKET_ID_DESC = 5
```

## ⬆️ Output

An `Array` of `HistoryData`. Each item exposes:

* **`history_order`** — the order record (type, volume, prices, times).
* **`history_deal`** — the executed deal: `ticket`, `symbol`, `volume`, `price`, `profit`, `commission`, `swap`, `time`.

---

## 🧱 Enum values (outputs)

Each history row (`OrderHistoryData`) is an **order** — its enum fields as symbols:

??? info "`type` → `BMT5_ENUM_ORDER_TYPE`"
    ```protobuf
    BMT5_ORDER_TYPE_BUY = 0   BMT5_ORDER_TYPE_SELL = 1
    BMT5_ORDER_TYPE_BUY_LIMIT = 2   BMT5_ORDER_TYPE_SELL_LIMIT = 3
    BMT5_ORDER_TYPE_BUY_STOP = 4   BMT5_ORDER_TYPE_SELL_STOP = 5
    BMT5_ORDER_TYPE_BUY_STOP_LIMIT = 6   BMT5_ORDER_TYPE_SELL_STOP_LIMIT = 7   BMT5_ORDER_TYPE_CLOSE_BY = 8
    ```

??? info "`state` → `BMT5_ENUM_ORDER_STATE`"
    ```protobuf
    BMT5_ORDER_STATE_STARTED = 0   BMT5_ORDER_STATE_PLACED = 1   BMT5_ORDER_STATE_CANCELED = 2
    BMT5_ORDER_STATE_PARTIAL = 3   BMT5_ORDER_STATE_FILLED = 4   BMT5_ORDER_STATE_REJECTED = 5
    BMT5_ORDER_STATE_EXPIRED = 6   BMT5_ORDER_STATE_REQUEST_ADD = 7
    BMT5_ORDER_STATE_REQUEST_MODIFY = 8   BMT5_ORDER_STATE_REQUEST_CANCEL = 9
    ```

??? info "`type_filling` → `BMT5_ENUM_ORDER_TYPE_FILLING`"
    ```protobuf
    BMT5_ORDER_FILLING_FOK = 0   BMT5_ORDER_FILLING_IOC = 1   BMT5_ORDER_FILLING_RETURN = 2   BMT5_ORDER_FILLING_BOC = 3
    ```

??? info "`type_time` → `BMT5_ENUM_ORDER_TYPE_TIME`"
    ```protobuf
    BMT5_ORDER_TIME_GTC = 0   BMT5_ORDER_TIME_DAY = 1   BMT5_ORDER_TIME_SPECIFIED = 2   BMT5_ORDER_TIME_SPECIFIED_DAY = 3
    ```

> `order_history` returns **orders only** (no deal rows), so no deal-type/entry/reason enums appear here.

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`. Uses a longer internal deadline (history can be large).
* **UTC times:** pass `Time` objects; the SDK builds the protobuf Timestamps.
* **Deals vs orders:** one order → several deals (partial fills); sum `history_deal.profit` for realized P/L.
* **Big windows:** keep `page_size` reasonable (default `500`) — the SDK still returns the full concatenated array.

---

## 🔗 Usage Examples

### 1) Last 7 days of deals

```ruby
from = Time.now.utc - 7 * 24 * 3600
acct.order_history(from_utc: from).each do |h|
  d = h.history_deal
  next unless d
  puts format("deal #%d  %-8s  vol %.2f  price %s  profit %.2f", d.ticket, d.symbol, d.volume, d.price, d.profit)
end
```

### 2) Total realized P/L

```ruby
total = acct.order_history(from_utc: Time.now.utc - 30 * 24 * 3600)
            .filter_map { |h| h.history_deal&.profit }.sum
puts "30-day realized P/L: #{total.round(2)}"
```

### 3) A specific calendar window

```ruby
acct.order_history(from_utc: Time.utc(2025, 1, 1), to_utc: Time.utc(2025, 2, 1))
```

### 4) Per-symbol realized P/L

```ruby
by_sym = Hash.new(0.0)
acct.order_history(from_utc: Time.now.utc - 7 * 24 * 3600).each do |h|
  d = h.history_deal or next
  by_sym[d.symbol] += d.profit
end
p by_sym
```

---

## 🔧 Common Patterns

### Daily P/L buckets

```ruby
def daily_pl(acct, days: 7)
  acct.order_history(from_utc: Time.now.utc - days * 24 * 3600)
      .filter_map { |h| h.history_deal }
      .group_by   { |d| Time.at(d.time.seconds).utc.to_date rescue nil }
      .transform_values { |ds| ds.sum(&:profit).round(2) }
end
```

---

## 📚 See Also

* [PositionsHistory](./PositionsHistory.md) — one row per closed round-trip.
* **Friendly layer:** [`MT5Sugar#order_history`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#order_history`](../../MT5Service/3.%20Position_Orders_Methods.md).

---

**Back to:** [Positions & Orders — Overview](./Position_Orders_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
