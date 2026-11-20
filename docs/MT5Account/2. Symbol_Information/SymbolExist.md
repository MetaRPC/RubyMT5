# ❓ Does a Symbol Exist?

> **Request:** check whether a symbol is known to the server (`SymbolExistData`) — before you quote it, select it, or trade it.

**API Information:**

* **Low-level API:** `MT5Account#symbol_exist(symbol)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolExist` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolExist(SymbolExistRequest) → SymbolExistReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_exist(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC that answers "does the server know this symbol name?"
* **Why you need it.** Validate user input, guard a read/trade against a typo, filter a candidate list down to tradable names.
* **Sanity check.** A known major like `"EURUSD"` returns `true`; a made-up name returns `false` (no error).

---

## 🎯 Purpose

`symbol_exist` is your **input-validation gate**. It distinguishes "the symbol is wrong" (returns `false`) from "the call failed" (raises) — so you can reject bad input cleanly instead of letting a later `symbol_info_tick` / `order_send` blow up.

> **Exists ≠ ready.** A symbol can **exist** yet not be **selected** in Market Watch or **synchronized** yet. For reads that need its data loaded, follow up with [`symbol_select`](./SymbolSelect.md) and [`symbol_is_synchronized`](./SymbolIsSynchronized.md).

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # True if the server knows `symbol`. Raises ApiError on a transport/gateway failure.
  def symbol_exist(symbol) -> Boolean
end
```

**Request message:** `SymbolExistRequest { string name = 1; }`
**Reply:** the SDK returns `data.exists` (a `Boolean`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol name to check, e.g. `"EURUSD"`. |

---

## ⬆️ Output

`true` / `false` — whether the symbol exists on the server.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** a missing symbol is **not** an error (returns `false`); only transport/gateway failures raise `ApiError`.
* **Case & suffix sensitivity.** Broker symbol names can carry suffixes (`EURUSD.m`, `EURUSD-ECN`). If `false` surprises you, list the catalog with `acct.symbol_list` and match the real spelling.
* **Exists vs selected vs synced** — three different states; see [SymbolSelect](./SymbolSelect.md) / [SymbolIsSynchronized](./SymbolIsSynchronized.md).

---

## 🔗 Usage Examples

### 1) Guard a read

```ruby
abort "unknown symbol" unless acct.symbol_exist("EURUSD")
t = acct.symbol_info_tick("EURUSD")
```

### 2) Validate user input

```ruby
def valid_symbol?(acct, name)
  acct.symbol_exist(name)
rescue MetaRPC::MT5::ApiError
  false
end
```

### 3) Filter a candidate list

```ruby
wanted = %w[EURUSD FOOBAR GBPUSD XYZ]
tradable = wanted.select { |s| acct.symbol_exist(s) }
puts tradable.inspect   # => ["EURUSD", "GBPUSD"]
```

### 4) Resolve a suffix when the plain name misses

```ruby
name = "EURUSD"
unless acct.symbol_exist(name)
  name = acct.symbol_list.find { |s| s.start_with?("EURUSD") } || name
end
puts name
```

---

## 🔧 Common Patterns

### Ensure-and-select helper

```ruby
def ensure_symbol(acct, sym)
  raise ArgumentError, "unknown symbol #{sym}" unless acct.symbol_exist(sym)
  acct.symbol_select(sym, true)
  sym
end
```

---

## 📚 See Also

* [SymbolSelect](./SymbolSelect.md) · [SymbolIsSynchronized](./SymbolIsSynchronized.md) · [SymbolName](./SymbolName.md)
* **Friendly layer:** [`MT5Service#symbol_exist?`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
