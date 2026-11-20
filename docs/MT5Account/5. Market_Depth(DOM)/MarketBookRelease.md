# ➖ Unsubscribe from the Order Book

> **Request:** stop receiving a symbol's Depth of Market (`MarketBookReleaseData`). The clean-up step of the DOM lifecycle.

**API Information:**

* **Low-level API:** `MT5Account#market_book_release(symbol)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `MarketBookRelease` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `MarketBookRelease(MarketBookReleaseRequest) → MarketBookReleaseReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#market_book_release(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** Closes the Depth-of-Market subscription for one symbol.
* **Why you need it.** Free gateway resources when you're done reading the book — always release what you added.
* **Sanity check.** Returns `true` when the subscription closed.

---

## 🎯 Purpose

`market_book_release` is step 3 of **add → get → release**. Leaving DOM subscriptions open keeps the gateway maintaining books you no longer read — release them as soon as you're finished.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def market_book_release(symbol) -> Boolean   # true if the book was closed
end
```

**Request message:** `MarketBookReleaseRequest { string symbol = 1; }`
**Reply:** the SDK returns `data.closed_successfully` (a `Boolean`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol to unsubscribe. |

## ⬆️ Output

`true` when the subscription closed.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Pair every add with a release** — ideally in an `ensure` block so it runs even on error.
* **Idempotent-ish:** releasing a symbol you didn't add is harmless (returns a falsey/`true` result depending on the gateway).

---

## 🔗 Usage Examples

### 1) Release one

```ruby
acct.market_book_release("EURUSD")
```

### 2) Full add → read → release

```ruby
if acct.market_book_add("EURUSD")
  puts acct.market_book_get("EURUSD").mql_book_infos.size
  acct.market_book_release("EURUSD")
end
```

### 3) Release everything you added

```ruby
%w[EURUSD GBPUSD].each { |s| acct.market_book_release(s) }
```

---

## 🔧 Common Patterns

### Guaranteed release with `ensure`

```ruby
acct.market_book_add("EURUSD")
begin
  book = acct.market_book_get("EURUSD").mql_book_infos
  # ... use book ...
ensure
  acct.market_book_release("EURUSD")
end
```

---

## 📚 See Also

* [MarketBookAdd](./MarketBookAdd.md) · [MarketBookGet](./MarketBookGet.md)
* **Friendly layer:** [`MT5Service#book_release`](../../MT5Service/5.%20MarketDepth_Methods.md).

---

**Back to:** [Market Depth — Overview](./Market_Depth.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
