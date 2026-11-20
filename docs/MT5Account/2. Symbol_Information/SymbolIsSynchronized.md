# 🔄 Is a Symbol Synchronized?

> **Request:** whether the terminal has finished syncing a symbol's data with the server (`SymbolIsSynchronizedData`) — the "ready to read" signal.

**API Information:**

* **Low-level API:** `MT5Account#symbol_is_synchronized(symbol)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolIsSynchronized` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolIsSynchronized(SymbolIsSynchronizedRequest) → SymbolIsSynchronizedReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_is_synchronized(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC telling you if `symbol`'s specs/quotes/history are in sync with the broker.
* **Why you need it.** Right after [`symbol_select`](./SymbolSelect.md), a symbol may not be ready — gate your reads on this.
* **Sanity check.** A long-selected major reads `true`; a just-selected exotic may read `false` for a moment.

---

## 🎯 Purpose

`symbol_is_synchronized` is the **"is it ready?"** check in the symbol lifecycle (`exist?` → `select` → **`synchronized?`** → read). Polling it before reading history or specs avoids stale/empty data on freshly selected symbols.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def symbol_is_synchronized(symbol) -> Boolean
end
```

**Request message:** `SymbolIsSynchronizedRequest { string symbol = 1; }`
**Reply:** the SDK returns `data.synchronized` (a `Boolean`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol name. |

---

## ⬆️ Output

`true` when the symbol's specs/history are synchronized.

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Poll, don't assume.** After [`symbol_select`](./SymbolSelect.md) a symbol can read `false` briefly — loop with a small `sleep` and a timeout.
* **Pairs with sync-sensitive reads** — [`price_history`](../6.%20Additional_Methods/SymbolParamsMany.md) family and [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md) are the ones most worth gating.

---

## 🔗 Usage Examples

### 1) One-shot check

```ruby
puts acct.symbol_is_synchronized("EURUSD")
```

### 2) Wait until ready (with timeout)

```ruby
deadline = Time.now + 5
sleep 0.2 until acct.symbol_is_synchronized("XAUUSD") || Time.now > deadline
```

### 3) Select then confirm

```ruby
acct.symbol_select("GBPUSD", true)
puts acct.symbol_is_synchronized("GBPUSD") ? "ready" : "still syncing"
```

### 4) Only read when synced

```ruby
if acct.symbol_is_synchronized("EURUSD")
  bars = acct.price_history("EURUSD", timeframe: :H1, max_bars: 100)
end
```

---

## 🔧 Common Patterns

### Block until synchronized

```ruby
def wait_synced(acct, sym, timeout: 5)
  deadline = Time.now + timeout
  until acct.symbol_is_synchronized(sym)
    raise "sync timeout for #{sym}" if Time.now > deadline
    sleep 0.2
  end
end
```

---

## 📚 See Also

* [SymbolSelect](./SymbolSelect.md) · [SymbolExist](./SymbolExist.md)
* **Friendly layer:** [`MT5Service#symbol_synchronized?`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
