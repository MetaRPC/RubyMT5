# 🔤 Reading One String Account Property

> **Request:** a single text account property (`AccountInfoStringData`) — name, server, currency or company — selected by an enum.

**API Information:**

* **Low-level API:** `MT5Account#account_info_string(property)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountInformation`
* **Proto definition:** `AccountInfoString` (defined in `mt5-term-api-account-information.proto`)

### RPC

* **Service:** `mt5_term_api.AccountInformation`
* **Method:** `AccountInfoString(AccountInfoStringRequest) → AccountInfoStringReply`
* **Low-level client (generated):** `Mt5TermApi::AccountInformation::Stub#account_info_string(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC that returns a single `String` account property, chosen by a property enum.
* **Why you need it.** Read the deposit currency (needed for profit math), the broker/company name, or the server name.
* **Sanity check.** `account_info_string(:ACCOUNT_CURRENCY)` matches `account_summary.account_currency`.

---

## 🎯 Purpose

Read **one** text property on demand. The one you'll reach for most is `:ACCOUNT_CURRENCY` — it decides how profit and margin are expressed and whether a symbol's profit is converted.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Returns one ACCOUNT_* string property. `property` is an
  # AccountInfoStringPropertyType symbol (e.g. :ACCOUNT_CURRENCY).
  def account_info_string(property) -> String
end
```

**Request message:** `AccountInfoStringRequest { AccountInfoStringPropertyType property_id = 1; }`
**Reply:** the SDK returns `data.requested_value` (a `String`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `property` | `Symbol` *(AccountInfoStringPropertyType)* | Which string property to read. Required. |

## ⬆️ Output

A single `String` — the requested property's value.

---

## 🧱 Property enum — `AccountInfoStringPropertyType`

```protobuf
enum AccountInfoStringPropertyType {
  ACCOUNT_NAME     = 0;  // account holder name
  ACCOUNT_SERVER   = 1;  // trade server name (e.g. "MetaQuotes-Demo")
  ACCOUNT_CURRENCY = 2;  // deposit currency (e.g. "USD")
  ACCOUNT_COMPANY  = 3;  // broker / company name
}
```

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`; wrap in `begin/rescue`.
* **Currency drives profit math** — read it once per session and reuse it.
* **Also in the summary:** the same values are on [`account_summary`](./AccountSummary.md) (`account_currency`, `account_company_name`) — use a single read if you need several fields.

---

## 🔗 Usage Examples

### 1) Currency & company

```ruby
puts "#{acct.account_info_string(:ACCOUNT_COMPANY)} — #{acct.account_info_string(:ACCOUNT_CURRENCY)}"
```

### 2) Identify the server

```ruby
puts "Server: #{acct.account_info_string(:ACCOUNT_SERVER)}"
```

### 3) Account holder

```ruby
puts "Holder: #{acct.account_info_string(:ACCOUNT_NAME)}"
```

### 4) Label an account for logs

```ruby
label = "#{acct.account_info_string(:ACCOUNT_NAME)} @ #{acct.account_info_string(:ACCOUNT_SERVER)}"
puts label
```

---

## 🔧 Common Patterns

### One-line account header

```ruby
def account_header(acct)
  "#{acct.account_info_string(:ACCOUNT_COMPANY)} · " \
  "#{acct.account_info_string(:ACCOUNT_SERVER)} · " \
  "#{acct.account_info_string(:ACCOUNT_CURRENCY)}"
end
```

---

## 📚 See Also

* [AccountSummary](./AccountSummary.md) — currency & company in the full snapshot.
* [AccountInfoDouble](./AccountInfoDouble.md) · [AccountInfoInteger](./AccountInfoInteger.md).
* **Friendly layer:** [`MT5Service#account_info_string`](../../MT5Service/1.%20Account_Methods.md).

---

**Back to:** [Account Information — Overview](./Account_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
