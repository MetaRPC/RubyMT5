# MT5Account · Market Depth (DOM) — Overview

> Level-II quotes / the order book. The lifecycle is always **add → get → release**: subscribe the terminal to a symbol's book, read snapshots, then unsubscribe.

All three live on `mt5_term_api.MarketInfo`. Not every symbol exposes a book (many FX feeds return an empty one).

## 📁 What lives here

| Method | What it does |
|--------|--------------|
| **[MarketBookAdd](./MarketBookAdd.md)** | subscribe to a symbol's order book |
| **[MarketBookGet](./MarketBookGet.md)** | read the current book snapshot |
| **[MarketBookRelease](./MarketBookRelease.md)** | unsubscribe |

---

## 🧭 Plain English

1. **`market_book_add(sym)`** → start receiving depth for `sym` (returns `true` on success).
2. **`market_book_get(sym)`** → read the current ladder (`mql_book_infos`).
3. **`market_book_release(sym)`** → stop when done.

> Rule of thumb: always `release` what you `add` — leaving subscriptions open wastes gateway resources.

---

## 🟢 Minimal snippet

```ruby
if acct.market_book_add("EURUSD")
  book = acct.market_book_get("EURUSD").mql_book_infos
  book.first(5).each { |lvl| puts "#{lvl.type} #{lvl.price} x #{lvl.volume}" }
  acct.market_book_release("EURUSD")
else
  puts "no DOM for EURUSD"
end
```

---

## See also

* **Quotes:** [Symbol Information — Overview](../2.%20Symbol_Information/Symbol_Information.Overview.md) — top-of-book bid/ask.
* **Friendly layer:** [`MT5Sugar#book_add` / `#book` / `#book_release`](../../MT5Sugar/MT5Sugar.API_Overview.md).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
