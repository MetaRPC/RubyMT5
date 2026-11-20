# 🔢 Counting Symbols

> **Request:** how many symbols the terminal knows (`SymbolsTotalData`) — all of them, or only those currently in Market Watch.

**API Information:**

* **Low-level API:** `MT5Account#symbols_total(mode: false)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolsTotal` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolsTotal(SymbolsTotalRequest) → SymbolsTotalReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbols_total(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning the number of symbols — the whole broker catalog, or just the ones shown in Market Watch.
* **Why you need it.** Size a loop over [`symbol_name`](./SymbolName.md), show "N instruments available", or check how many symbols are selected vs hidden.
* **Sanity check.** The all-symbols count (`mode: false`) is ≥ the Market-Watch count (`mode: true`), and both are `> 0` once connected.

---

## 🎯 Purpose

Use it whenever you need the **size** of the symbol universe rather than the names themselves:

* Bound an index loop with [`symbol_name(i)`](./SymbolName.md).
* Report catalog size in a dashboard or health check.
* Measure how many symbols are in Market Watch vs the full list (hidden = all − selected).

> **Just want every name?** `acct.symbol_list` returns the full `[String]` in one call — no need to loop `symbol_name` yourself.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Count of symbols. mode: true counts only Market-Watch (selected) symbols.
  # Returns an Integer; raises ApiError on failure.
  def symbols_total(mode: false) -> Integer
end
```

**Request message:** `SymbolsTotalRequest { bool mode = 1; }`
**Reply:** `SymbolsTotalReply { oneof response { SymbolsTotalData data; Error error; } }` — the SDK returns `data.total`.

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `mode` | `Boolean` *(keyword, default `false`)* | `false` = **all** symbols on the server; `true` = only those in **Market Watch**. |

---

## ⬆️ Output

A single `Integer` — the number of symbols.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `MetaRPC::MT5::ApiError` on a server rejection; wrap in `begin/rescue`.
* **Big catalogs.** A broker can expose **10k+** symbols (`mode: false`); don't eagerly fetch a tick/spec for every one — select and read only what you trade.
* **Market Watch is smaller.** `mode: true` reflects what's currently selected; grow it with [`symbol_select`](./SymbolSelect.md).
* **Names, not just the count:** iterate with [`symbol_name`](./SymbolName.md), or get them all at once via `acct.symbol_list`.

---

## 🔗 Usage Examples

### 1) All vs Market Watch

```ruby
all = acct.symbols_total
mw  = acct.symbols_total(mode: true)
puts "catalog #{all}  ·  market watch #{mw}  ·  hidden #{all - mw}"
```

### 2) Iterate the first N symbols

```ruby
n = [acct.symbols_total, 10].min
(0...n).each { |i| puts acct.symbol_name(i) }
```

### 3) Health check — is the catalog loaded?

```ruby
def catalog_ready?(acct)
  acct.symbols_total.positive?
rescue MetaRPC::MT5::ApiError
  false
end
```

### 4) Market-Watch ratio

```ruby
all = acct.symbols_total.to_f
pct = all.zero? ? 0 : (100 * acct.symbols_total(mode: true) / all).round(1)
puts "#{pct}% of symbols are in Market Watch"
```

---

## 🔧 Common Patterns

### Build a symbol index (prefer `symbol_list`)

```ruby
# Cheapest: one call for every name
names = acct.symbol_list                      # => [String]

# Or, if you specifically need the count first:
total = acct.symbols_total
names = (0...total).map { |i| acct.symbol_name(i) }   # heavier: N round-trips
```

---

## 📚 See Also

* [SymbolName](./SymbolName.md) — name by index · [SymbolExist](./SymbolExist.md) — existence check.
* [SymbolSelect](./SymbolSelect.md) — grow Market Watch.
* **Friendly layer:** [`MT5Service#symbols_total` / `#symbols`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
