# 🔢 Reading One Integer Account Property

> **Request:** a single integer account property (`AccountInfoIntegerData`) — login, leverage, trade mode, limit orders and more — selected by an enum.

**API Information:**

* **Low-level API:** `MT5Account#account_info_integer(property)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountInformation`
* **Proto definition:** `AccountInfoInteger` (defined in `mt5-term-api-account-information.proto`)

### RPC

* **Service:** `mt5_term_api.AccountInformation`
* **Method:** `AccountInfoInteger(AccountInfoIntegerRequest) → AccountInfoIntegerReply`
* **Low-level client (generated):** `Mt5TermApi::AccountInformation::Stub#account_info_integer(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC that returns a single `Integer` account property, chosen by a property enum.
* **Why you need it.** Read leverage for margin math, the login id, or flags like trade-allowed — without the full summary.
* **Sanity check.** `account_info_integer(:ACCOUNT_LOGIN)` equals your connected login.

---

## 🎯 Purpose

Read **one** integer property on demand. Most common: `:ACCOUNT_LEVERAGE` (drives margin requirements), `:ACCOUNT_LOGIN` (identity), and the permission flags `:ACCOUNT_TRADE_ALLOWED` / `:ACCOUNT_TRADE_EXPERT`.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # Returns one ACCOUNT_* integer property. `property` is an
  # AccountInfoIntegerPropertyType symbol (e.g. :ACCOUNT_LEVERAGE).
  def account_info_integer(property) -> Integer
end
```

**Request message:** `AccountInfoIntegerRequest { AccountInfoIntegerPropertyType property_id = 1; }`
**Reply:** the SDK returns `data.requested_value` (an `Integer`).

---

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `property` | `Symbol` *(AccountInfoIntegerPropertyType)* | Which integer property to read. Required. |

## ⬆️ Output

A single `Integer`. Some properties encode an enum (e.g. `:ACCOUNT_TRADE_MODE` → `0`/`1`/`2`) but still come back as a plain `Integer`.

---

## 🧱 Property enum — `AccountInfoIntegerPropertyType`

```protobuf
enum AccountInfoIntegerPropertyType {
  ACCOUNT_LOGIN           = 0;   // account login (ID)
  ACCOUNT_TRADE_MODE      = 1;   // 0 demo · 1 contest · 2 real
  ACCOUNT_LEVERAGE        = 2;   // leverage (e.g. 100)
  ACCOUNT_LIMIT_ORDERS    = 3;   // max active pending orders
  ACCOUNT_MARGIN_SO_MODE  = 4;   // stop-out mode (percent / money)
  ACCOUNT_TRADE_ALLOWED   = 5;   // trading allowed (0/1)
  ACCOUNT_TRADE_EXPERT    = 6;   // EA trading allowed (0/1)
  ACCOUNT_MARGIN_MODE     = 7;   // 0 netting · 1 exchange · 2 hedging
  ACCOUNT_CURRENCY_DIGITS = 8;   // currency decimal places
  ACCOUNT_FIFO_CLOSE      = 9;   // FIFO close required (0/1)
  ACCOUNT_HEDGE_ALLOWED   = 10;  // hedging allowed (0/1)
}
```

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError`; wrap in `begin/rescue`.
* **Boolean-ish flags** come back as `0`/`1` — compare `== 1` or use `.positive?`.
* **Leverage** drives margin requirements — read it once and cache it per session.
* **`:ACCOUNT_TRADE_MODE`** returns `0`/`1`/`2` as a plain `Integer` here (the typed symbol is on [`account_summary`](./AccountSummary.md)).

---

## 🔗 Usage Examples

### 1) Leverage & login

```ruby
puts "Login #{acct.account_info_integer(:ACCOUNT_LOGIN)}  leverage 1:#{acct.account_info_integer(:ACCOUNT_LEVERAGE)}"
```

### 2) Is automated trading allowed?

```ruby
ea_ok = acct.account_info_integer(:ACCOUNT_TRADE_EXPERT) == 1
puts ea_ok ? "EAs allowed" : "EA trading disabled"
```

### 3) Margin mode

```ruby
mode = acct.account_info_integer(:ACCOUNT_MARGIN_MODE)
puts ["netting", "exchange", "hedging"][mode] || "unknown"
```

### 4) Trade permission gate

```ruby
unless acct.account_info_integer(:ACCOUNT_TRADE_ALLOWED) == 1
  abort "trading is disabled for this account"
end
```

---

## 🔧 Common Patterns

### Cache identity & leverage once

```ruby
def account_facts(acct)
  {
    login: acct.account_info_integer(:ACCOUNT_LOGIN),
    leverage: acct.account_info_integer(:ACCOUNT_LEVERAGE),
    ea_allowed: acct.account_info_integer(:ACCOUNT_TRADE_EXPERT) == 1,
  }
end
```

---

## 📚 See Also

* [AccountSummary](./AccountSummary.md) — all values at once (trade mode / margin mode as symbols).
* [AccountInfoDouble](./AccountInfoDouble.md) · [AccountInfoString](./AccountInfoString.md).
* **Friendly layer:** [`MT5Service#account_info_integer`](../../MT5Service/1.%20Account_Methods.md).

---

**Back to:** [Account Information — Overview](./Account_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
