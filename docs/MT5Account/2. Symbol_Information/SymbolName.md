# 🔤 Symbol Name by Index

> **Request:** the name of the symbol at a given index (`SymbolNameData`) — walk the catalog, or the Market-Watch subset, position by position.

**API Information:**

* **Low-level API:** `MT5Account#symbol_name(index, selected: false)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolName` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolName(SymbolNameRequest) → SymbolNameReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_name(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the symbol name at position `index` — over the full catalog, or only the Market-Watch list.
* **Why you need it.** Iterate the catalog with [`symbols_total`](./SymbolsTotal.md), build a picker, or read the *n*-th Market-Watch symbol.
* **Sanity check.** `symbol_name(0)` returns a real name; an out-of-range index raises.

---

## 🎯 Purpose

`symbol_name` is the **index → name** half of catalog iteration (`symbols_total` gives you the count). Together they let you enumerate symbols without hard-coding names.

> **Prefer the whole list?** `acct.symbol_list` returns every name in **one** call — cheaper than looping `symbol_name` across thousands of indices. Use `symbol_name` when you need a single position (e.g. "the first Market-Watch symbol") or are streaming through a huge catalog lazily.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Name of the symbol at `index`. selected: true indexes within Market Watch only.
  def symbol_name(index, selected: false) -> String
end
```

**Request message:** `SymbolNameRequest { int32 index = 1; bool selected = 2; }`
**Reply:** the SDK returns `data.name` (a `String`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `index` | `Integer` | Zero-based index into the symbol list. |
| `selected` | `Boolean` *(keyword, default `false`)* | `false` = index into the full catalog; `true` = index into Market-Watch symbols only. |

---

## ⬆️ Output

A `String` — the symbol name at that index.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** an out-of-range `index` raises `ApiError` — bound your loop with [`symbols_total`](./SymbolsTotal.md).
* **Two index spaces.** `selected: false` and `selected: true` are different orderings and sizes — pick the one that matches your count.
* **N round-trips.** Looping `symbol_name` over the whole catalog is one call per index; `acct.symbol_list` is one call total.

---

## 🔗 Usage Examples

### 1) First symbol (catalog vs Market Watch)

```ruby
puts "catalog[0]      #{acct.symbol_name(0)}"
puts "market_watch[0] #{acct.symbol_name(0, selected: true)}"
```

### 2) First 5 names

```ruby
(0...5).each { |i| puts acct.symbol_name(i) }
```

### 3) Safely read the n-th Market-Watch symbol

```ruby
def mw_symbol(acct, i)
  i < acct.symbols_total(mode: true) ? acct.symbol_name(i, selected: true) : nil
end
```

### 4) Build the list (prefer `symbol_list`)

```ruby
total = acct.symbols_total
names = (0...total).map { |i| acct.symbol_name(i) }   # heavier
# names = acct.symbol_list                             # one call — preferred
```

---

## 🔧 Common Patterns

### Paginated picker

```ruby
def page_symbols(acct, page:, per: 20)
  start = page * per
  stop  = [start + per, acct.symbols_total].min
  (start...stop).map { |i| acct.symbol_name(i) }
end
```

---

## 📚 See Also

* [SymbolsTotal](./SymbolsTotal.md) — the count · [SymbolExist](./SymbolExist.md) — existence.
* **Friendly layer:** [`MT5Service#symbol_name` / `#symbols`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
