# ➕ Show / Hide a Symbol in Market Watch

> **Request:** add or remove a symbol from Market Watch (`SymbolSelectData`). Some reads require a symbol to be selected before its data is available.

**API Information:**

* **Low-level API:** `MT5Account#symbol_select(symbol, select = true)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolSelect` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolSelect(SymbolSelectRequest) → SymbolSelectReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_select(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC that toggles a symbol in Market Watch — `select = true` shows it, `false` hides it.
* **Why you need it.** The terminal only keeps live data for selected symbols; select an uncommon one before quoting, reading its spec, or trading it.
* **Sanity check.** `symbol_select("EURUSD", true)` returns `true`; right after, [`symbol_is_synchronized`](./SymbolIsSynchronized.md) flips to `true`.

---

## 🎯 Purpose

`symbol_select` **warms up** a symbol. Majors are usually selected already, but a symbol the terminal hasn't loaded needs this first — otherwise [`symbol_info_tick`](./SymbolInfoTick.md) / [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md) may return stale or empty data.

> **Lifecycle:** `symbol_exist?` → `symbol_select(true)` → wait for `symbol_is_synchronized` → read. Hide it again with `symbol_select(false)` when you're done, to keep Market Watch tidy.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Add (select=true) or remove (select=false) `symbol` from Market Watch.
  def symbol_select(symbol, select = true) -> Boolean
end
```

**Request message:** `SymbolSelectRequest { string symbol = 1; bool select = 2; }`
**Reply:** the SDK returns `data.success` (a `Boolean`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol name. |
| `select` | `Boolean` *(default `true`)* | `true` = show in Market Watch, `false` = hide. |

---

## ⬆️ Output

`true` on success.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure; wrap in `begin/rescue`.
* **Call it before** reading ticks/params for a symbol the terminal hasn't loaded.
* **You can't remove** a symbol that has open positions or pending orders — hide will fail.
* **Not instant.** After selecting, poll [`symbol_is_synchronized`](./SymbolIsSynchronized.md) before relying on history/specs.

---

## 🔗 Usage Examples

### 1) Select, then quote

```ruby
acct.symbol_select("GBPUSD", true)
t = acct.symbol_info_tick("GBPUSD")
puts "#{t.bid}/#{t.ask}"
```

### 2) Select and wait until synced

```ruby
acct.symbol_select("XAUUSD", true)
sleep 0.2 until acct.symbol_is_synchronized("XAUUSD")
puts "ready"
```

### 3) Hide when done

```ruby
acct.symbol_select("GBPUSD", false)
```

### 4) Bulk-select a basket

```ruby
%w[EURUSD GBPUSD USDJPY].each { |s| acct.symbol_select(s, true) }
```

---

## 🔧 Common Patterns

### Ensure-ready helper

```ruby
def ensure_ready(acct, sym, timeout: 5)
  acct.symbol_select(sym, true)
  deadline = Time.now + timeout
  sleep 0.2 until acct.symbol_is_synchronized(sym) || Time.now > deadline
  sym
end
```

---

## 📚 See Also

* [SymbolIsSynchronized](./SymbolIsSynchronized.md) · [SymbolExist](./SymbolExist.md) · [SymbolInfoTick](./SymbolInfoTick.md)
* **Friendly layer:** [`MT5Service#select_symbol`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
