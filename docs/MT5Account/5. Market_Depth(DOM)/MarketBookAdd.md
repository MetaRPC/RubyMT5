# ➕ Subscribe to the Order Book

> **Request:** subscribe the terminal to a symbol's Depth of Market (`MarketBookAddData`). Required before [`market_book_get`](./MarketBookGet.md).

**API Information:**

* **Low-level API:** `MT5Account#market_book_add(symbol)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `MarketBookAdd` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `MarketBookAdd(MarketBookAddRequest) → MarketBookAddReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#market_book_add(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** Opens a Depth-of-Market (Level-II) subscription for one symbol.
* **Why you need it.** The terminal only keeps the order book for symbols you've subscribed — do this before [`market_book_get`](./MarketBookGet.md).
* **Sanity check.** Returns `true` when the book opened. Many FX feeds return `true` but an **empty** ladder.

---

## 🎯 Purpose

`market_book_add` is step 1 of the DOM lifecycle **add → get → release**. It tells the gateway to start maintaining the order book for a symbol so later `market_book_get` snapshots have data.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def market_book_add(symbol) -> Boolean   # true if the book was opened
end
```

**Request message:** `MarketBookAddRequest { string symbol = 1; }`
**Reply:** the SDK returns `data.opened_successfully` (a `Boolean`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol to subscribe. |

## ⬆️ Output

`true` when the subscription opened (the symbol has a book).

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Always pair with [`market_book_release`](./MarketBookRelease.md)** — leaving subscriptions open wastes gateway resources.
* **Empty books are normal** on retail FX — check `market_book_get(...).mql_book_infos` for content.
* **Select first** if needed: some symbols require [`symbol_select`](../2.%20Symbol_Information/SymbolSelect.md) before a book is available.

---

## 🔗 Usage Examples

### 1) Guard the lifecycle

```ruby
if acct.market_book_add("EURUSD")
  # ... read with market_book_get ...
  acct.market_book_release("EURUSD")
else
  puts "no DOM for EURUSD"
end
```

### 2) Subscribe a basket

```ruby
%w[EURUSD GBPUSD].each { |s| acct.market_book_add(s) }
```

### 3) Add, confirm it has depth, else release

```ruby
if acct.market_book_add("XAUUSD")
  depth = acct.market_book_get("XAUUSD").mql_book_infos.size
  acct.market_book_release("XAUUSD") if depth.zero?
  puts "levels: #{depth}"
end
```

---

## 🔧 Common Patterns

### With-book block (auto-release)

```ruby
def with_book(acct, sym)
  return yield(nil) unless acct.market_book_add(sym)
  yield acct.market_book_get(sym)
ensure
  acct.market_book_release(sym)
end
```

---

## 📚 See Also

* [MarketBookGet](./MarketBookGet.md) · [MarketBookRelease](./MarketBookRelease.md)
* **Friendly layer:** [`MT5Service#book_add`](../../MT5Service/5.%20MarketDepth_Methods.md).

---

**Back to:** [Market Depth — Overview](./Market_Depth.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
