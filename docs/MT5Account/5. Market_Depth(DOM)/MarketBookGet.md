# 📖 Reading the Order Book

> **Request:** the current Depth-of-Market snapshot for a symbol (`MarketBookGetData`). Call [`market_book_add`](./MarketBookAdd.md) first.

**API Information:**

* **Low-level API:** `MT5Account#market_book_get(symbol)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `MarketBookGet` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `MarketBookGet(MarketBookGetRequest) → MarketBookGetReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#market_book_get(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the current order-book ladder for a subscribed symbol.
* **Why you need it.** Read Level-II liquidity — the price/volume at each bid and ask level — for microstructure, slippage estimates, or a DOM widget.
* **Sanity check.** After [`market_book_add`](./MarketBookAdd.md), `mql_book_infos` has levels on instruments that expose depth (often empty on retail FX).

---

## 🎯 Purpose

`market_book_get` is step 2 of **add → get → release**: the snapshot read. It's a point-in-time picture (not a stream) — poll it, or read once per decision.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def market_book_get(symbol) -> Mt5TermApi::MarketBookGetData
end
```

**Request message:** `MarketBookGetRequest { string symbol = 1; }`
**Reply:** the SDK returns `data` (`MarketBookGetData`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | A symbol you've subscribed with `market_book_add`. |

## ⬆️ Output — `MarketBookGetData`

* **`mql_book_infos`** → `[MrpcMqlBookInfo]` — the ladder. Each level:

| Field | Ruby accessor | Type | Description |
| ----- | ------------- | ---- | ----------- |
| `type` | `type` | `Symbol` | Level type (buy / sell / market buy / sell) enum. |
| `price` | `price` | `Float` | Price at this level. |
| `volume` | `volume` | `Integer` | Volume at this level. |
| `volume_real` | `volume_real` | `Float` | Real volume (where provided). |

---

## 🧱 Enum values

### `type` (output) → `BookType`

Each DOM entry's side, on `MrpcBookInfo.type`:

```protobuf
BOOK_TYPE_SELL        = 0   // ask side (resting sell)
BOOK_TYPE_BUY         = 1   // bid side (resting buy)
BOOK_TYPE_SELL_MARKET = 2   // sell at market
BOOK_TYPE_BUY_MARKET  = 3   // buy at market
```

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Empty is valid** — guard with `.any?` before indexing.
* **Snapshot, not a stream** — re-call it to refresh; there's no DOM callback.
* **Subscribe first** — without [`market_book_add`](./MarketBookAdd.md) the book is empty.

---

## 🔗 Usage Examples

### 1) Count levels

```ruby
acct.market_book_add("EURUSD")
puts acct.market_book_get("EURUSD").mql_book_infos.size
acct.market_book_release("EURUSD")
```

### 2) Top 5 levels

```ruby
acct.market_book_get("EURUSD").mql_book_infos.first(5).each do |l|
  puts "#{l.type}  #{l.price} x #{l.volume}"
end
```

### 3) Best bid / best ask from the ladder

```ruby
levels = acct.market_book_get("EURUSD").mql_book_infos
bids = levels.select { |l| l.type.to_s.include?("BUY") }
asks = levels.select { |l| l.type.to_s.include?("SELL") }
puts "best bid #{bids.map(&:price).max}  best ask #{asks.map(&:price).min}" if levels.any?
```

---

## 🔧 Common Patterns

### Total depth on each side

```ruby
def depth_totals(acct, sym)
  levels = acct.market_book_get(sym).mql_book_infos
  levels.group_by { |l| l.type }.transform_values { |ls| ls.sum(&:volume) }
end
```

---

## 📚 See Also

* [MarketBookAdd](./MarketBookAdd.md) · [MarketBookRelease](./MarketBookRelease.md)
* **Friendly layer:** [`MT5Service#book`](../../MT5Service/5.%20MarketDepth_Methods.md).

---

**Back to:** [Market Depth — Overview](./Market_Depth.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
