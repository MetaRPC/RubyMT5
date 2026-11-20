# 🔢 Reading One Double Account Property

> **Request:** a single floating-point account property (`AccountInfoDoubleData`) — balance, equity, margin, profit, credit and more — selected by an enum.

**API Information:**

* **Low-level API:** `MT5Account#account_info_double(property)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountInformation`
* **Proto definition:** `AccountInfoDouble` (defined in `mt5-term-api-account-information.proto`)

### RPC

* **Service:** `mt5_term_api.AccountInformation`
* **Method:** `AccountInfoDouble(AccountInfoDoubleRequest) → AccountInfoDoubleReply`
* **Low-level client (generated):** `Mt5TermApi::AccountInformation::Stub#account_info_double(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC that returns a single `Float` account metric, chosen by a property enum.
* **Why you need it.** Lighter than the full [`account_summary`](./AccountSummary.md) when you only need one number — e.g. free margin before sizing a trade.
* **Sanity check.** `account_info_double(:ACCOUNT_BALANCE)` matches `account_summary.account_balance`.

---

## 🎯 Purpose

Read **one** double property on demand. The money-management essentials live here — `:ACCOUNT_MARGIN_FREE` (can I afford this trade?), `:ACCOUNT_PROFIT` (floating P/L), `:ACCOUNT_MARGIN_LEVEL` (margin health). For several values at once, call [`account_summary`](./AccountSummary.md) once instead of many single reads.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Returns one ACCOUNT_* double property. `property` is an
  # AccountInfoDoublePropertyType symbol (e.g. :ACCOUNT_EQUITY).
  def account_info_double(property) -> Float
end
```

**Request message:** `AccountInfoDoubleRequest { AccountInfoDoublePropertyType property_id = 1; }`
**Reply:** the SDK returns `data.requested_value` (a `Float`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `property` | `Symbol` *(AccountInfoDoublePropertyType)* | Which double property to read. Required. |

## ⬆️ Output

A single `Float` — the requested property's value.

---

## 🧱 Property enum — `AccountInfoDoublePropertyType`

```protobuf
enum AccountInfoDoublePropertyType {
  ACCOUNT_BALANCE            = 0;   // account balance (deposit currency)
  ACCOUNT_CREDIT             = 1;   // credit
  ACCOUNT_PROFIT             = 2;   // current floating profit
  ACCOUNT_EQUITY             = 3;   // equity = balance + floating P/L
  ACCOUNT_MARGIN             = 4;   // margin used by open positions
  ACCOUNT_MARGIN_FREE        = 5;   // free margin for new positions
  ACCOUNT_MARGIN_LEVEL       = 6;   // margin level, percent
  ACCOUNT_MARGIN_SO_CALL     = 7;   // margin call level
  ACCOUNT_MARGIN_SO_SO       = 8;   // stop-out level
  ACCOUNT_MARGIN_INITIAL     = 9;   // reserved initial margin
  ACCOUNT_MARGIN_MAINTENANCE = 10;  // reserved maintenance margin
  ACCOUNT_ASSETS             = 11;  // current assets
  ACCOUNT_LIABILITIES        = 12;  // current liabilities
  ACCOUNT_COMMISSION_BLOCKED = 13;  // blocked commission
}
```

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `MetaRPC::MT5::ApiError` on a server rejection; wrap in `begin/rescue`.
* **Pass the symbol, not the number** — `:ACCOUNT_EQUITY`, not `3`.
* **The full snapshot is cheaper for many values** — if you need several, call [`account_summary`](./AccountSummary.md) once.
* **Floating profit** is `:ACCOUNT_PROFIT` here, or `account_equity - account_balance` from the summary.

---

## 🔗 Usage Examples

### 1) Free margin before trading

```ruby
free = acct.account_info_double(:ACCOUNT_MARGIN_FREE)
puts "free margin: #{free.round(2)}"
```

### 2) Floating profit

```ruby
profit = acct.account_info_double(:ACCOUNT_PROFIT)
puts profit.positive? ? "In profit: +#{profit.round(2)}" : "Down: #{profit.round(2)}"
```

### 3) Margin-health gauge

```ruby
level = acct.account_info_double(:ACCOUNT_MARGIN_LEVEL)
puts case
     when level.zero?   then "No open margin"
     when level < 100   then "⚠️ Critical"
     when level < 200   then "⚠️ Low"
     else                    "✅ Healthy"
     end
```

### 4) Equity vs balance (floating)

```ruby
eq  = acct.account_info_double(:ACCOUNT_EQUITY)
bal = acct.account_info_double(:ACCOUNT_BALANCE)
puts "floating: #{(eq - bal).round(2)}"
```

---

## 🔧 Common Patterns

### Affordability check

```ruby
def can_afford?(acct, margin_needed)
  acct.account_info_double(:ACCOUNT_MARGIN_FREE) >= margin_needed
rescue MetaRPC::MT5::ApiError
  false
end
```

---

## 📚 See Also

* [AccountSummary](./AccountSummary.md) — all values at once.
* [AccountInfoInteger](./AccountInfoInteger.md) · [AccountInfoString](./AccountInfoString.md) — integer / string properties.
* **Friendly layer:** [`MT5Sugar#balance` / `#equity` / `#margin` / `#free_margin`](../../MT5Sugar/MT5Sugar.API_Overview.md) · [`MT5Service#account_info_double`](../../MT5Service/1.%20Account_Methods.md).

---

**Back to:** [Account Information — Overview](./Account_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
