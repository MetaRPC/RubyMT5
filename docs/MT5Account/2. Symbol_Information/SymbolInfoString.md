# 🔤 One String Symbol Property

> **Request:** a single text symbol property (`SymbolInfoStringData`) — description, base/profit/margin currency, path… — selected by an enum.

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_string(symbol, property)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoString` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoString(SymbolInfoStringRequest) → SymbolInfoStringReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_info_string(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning a single `String` symbol property, chosen by a property enum.
* **Why you need it.** Read the human description for a UI, or the base/profit currencies that drive profit & margin math.
* **Sanity check.** `symbol_info_string("EURUSD", :SYMBOL_CURRENCY_BASE)` is `"EUR"`.

---

## 🎯 Purpose

Read **one** text property on demand — most often the **currencies** (which decide how profit and margin are calculated) or a **description** for display.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # One SYMBOL_* string property. `property` is a SymbolInfoStringProperty symbol.
  def symbol_info_string(symbol, property) -> String
end
```

**Request message:** `SymbolInfoStringRequest { string symbol = 1; SymbolInfoStringProperty type = 2; }`
**Reply:** the SDK returns `data.value` (a `String`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol, e.g. `"EURUSD"`. |
| `property` | `Symbol` *(SymbolInfoStringProperty)* | Which string property to read. |

## ⬆️ Output

A single `String`.

---

## 🧱 Property enum — `SymbolInfoStringProperty` (all 15 values)

Pass any of these as the `property` symbol (e.g. `:SYMBOL_DESCRIPTION`):

```protobuf
SYMBOL_BASIS           = 0
SYMBOL_CATEGORY        = 1
SYMBOL_COUNTRY         = 2
SYMBOL_SECTOR_NAME     = 3    // economic sector name
SYMBOL_INDUSTRY_NAME   = 4    // industry / activity name
SYMBOL_CURRENCY_BASE   = 5    // base currency (EUR for EURUSD)
SYMBOL_CURRENCY_PROFIT = 6    // profit currency (USD for EURUSD)
SYMBOL_CURRENCY_MARGIN = 7    // margin currency
SYMBOL_BANK            = 8
SYMBOL_DESCRIPTION     = 9    // human-readable description ("Euro vs US Dollar")
SYMBOL_EXCHANGE        = 10
SYMBOL_FORMULA         = 11   // formula for a custom/synthetic symbol
SYMBOL_ISIN            = 12   // ISIN (where available)
SYMBOL_PAGE            = 13   // web page URL
SYMBOL_PATH            = 14   // Market Watch tree path
```

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Currencies matter.** If the **profit currency** isn't the account currency, P/L is converted at the current rate — expect small differences vs a naive points×value estimate.
* **One call for everything:** the same fields live on `SymbolParameters` (`currency_base`, `currency_profit`, `sym_description`, `path`) via [`symbol_params_many`](../6.%20Additional_Methods/SymbolParamsMany.md).

---

## 🔗 Usage Examples

### 1) Description for a UI

```ruby
puts acct.symbol_info_string("EURUSD", :SYMBOL_DESCRIPTION)   # "Euro vs US Dollar"
```

### 2) Base / profit currency

```ruby
base   = acct.symbol_info_string("EURUSD", :SYMBOL_CURRENCY_BASE)
profit = acct.symbol_info_string("EURUSD", :SYMBOL_CURRENCY_PROFIT)
puts "#{base} → #{profit}"
```

### 3) Is profit in the account currency?

```ruby
acct_ccy = acct.account_info_string(:ACCOUNT_CURRENCY)
sym_ccy  = acct.symbol_info_string("EURUSD", :SYMBOL_CURRENCY_PROFIT)
puts sym_ccy == acct_ccy ? "no conversion" : "converted #{sym_ccy}→#{acct_ccy}"
```

### 4) Market-Watch folder

```ruby
puts acct.symbol_info_string("EURUSD", :SYMBOL_PATH)   # e.g. "Forex\\Majors\\EURUSD"
```

---

## 🔧 Common Patterns

### Display label

```ruby
def symbol_label(acct, sym)
  "#{sym} — #{acct.symbol_info_string(sym, :SYMBOL_DESCRIPTION)}"
end
```

---

## 📚 See Also

* [SymbolInfoDouble](./SymbolInfoDouble.md) · [SymbolInfoInteger](./SymbolInfoInteger.md) · [SymbolInfoTick](./SymbolInfoTick.md)
* [SymbolParamsMany](../6.%20Additional_Methods/SymbolParamsMany.md) — currencies & description in the full spec.
* **Friendly layer:** [`MT5Service#symbol_params`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Symbol Information — Overview](./Symbol_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
