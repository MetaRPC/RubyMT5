# MT5Account · Account Information — Overview

> Account balance, equity, margin, leverage, currency, trade mode and server time — the complete snapshot in one call, or a single property at a time. Use this page to choose the right API for reading account state.

These methods are **read-only**. `account_summary` lives on `mt5_term_api.AccountHelper`; the `account_info_*` single-property methods on `mt5_term_api.AccountInformation`. Each returns the raw `*Data` (read fields with snake_case accessors), or raises `ApiError`.

## 📁 What lives here

* **[AccountSummary](./AccountSummary.md)** — **all account info** at once (login, balance, equity, credit, leverage, currency, margin / free margin / margin level / margin mode, server time). Returns the `MrpcEnumAccountTradeMode` and `MrpcEnumAccountMarginMode` enums.
* **[AccountInfoDouble](./AccountInfoDouble.md)** — a **single double** property (balance, equity, margin, profit, credit…). Takes an `AccountInfoDoublePropertyType`.
* **[AccountInfoInteger](./AccountInfoInteger.md)** — a **single integer** property (login, leverage, limit orders…). Takes an `AccountInfoIntegerPropertyType`.
* **[AccountInfoString](./AccountInfoString.md)** — a **single string** property (name, server, currency, company). Takes an `AccountInfoStringPropertyType`.

---

## 🧭 Plain English

* **account_summary** → the **one-stop shop** for a complete snapshot. One RPC, everything you need for a dashboard, a pre-trade affordability check, or a connection heartbeat.
* **account_info_double / integer / string** → grab **one property** when that's all you need — lighter than the full summary. Each takes a property enum selecting which value to read.

> Rule of thumb: need the **full snapshot** → `account_summary`; need **one specific value** → `account_info_*`.

---

## Quick choose

| If you need…                                      | Use                     | Returns             | Enums used |
| ------------------------------------------------- | ----------------------- | ------------------- | ---------- |
| Complete account snapshot (all values)            | `account_summary`       | `AccountSummaryData`| **Output:** `MrpcEnumAccountTradeMode`, `MrpcEnumAccountMarginMode` |
| One numeric value (balance, equity, margin, …)    | `account_info_double`   | `Float`             | **Input:** `AccountInfoDoublePropertyType` |
| One integer value (login, leverage, …)            | `account_info_integer`  | `Integer`           | **Input:** `AccountInfoIntegerPropertyType` |
| One text value (currency, company, server, …)     | `account_info_string`   | `String`            | **Input:** `AccountInfoStringPropertyType` |

---

## ❌ Cross-refs & gotchas

* **Margin** — `account_summary` already returns `account_margin`, `account_margin_free`, `account_margin_level` and `account_margin_mode`; `account_info_double(:ACCOUNT_MARGIN_FREE / :ACCOUNT_MARGIN_LEVEL)` is just the single-value alternative.
* **Floating profit** — the summary carries no dedicated profit field; compute `account_equity − account_balance`, or read `account_info_double(:ACCOUNT_PROFIT)`.
* **Currency** affects how profit is calculated — always check the account currency.
* **Leverage** determines margin requirements — higher leverage, less margin needed.
* **Timeouts** — read RPCs use the account's `timeout` (default `60` s); tune via `acct.timeout = 30`.

---

## 🟢 Minimal snippets

```ruby
# Complete account snapshot
s = acct.account_summary
puts "Balance: #{s.account_balance.round(2)}, Equity: #{s.account_equity.round(2)}, Leverage: 1:#{s.account_leverage}"
```

```ruby
# Single property — account balance (pass the enum as a Ruby symbol)
balance = acct.account_info_double(:ACCOUNT_BALANCE)   # => Float
puts "Balance: #{balance.round(2)}"
```

```ruby
# Single integer property — leverage
leverage = acct.account_info_integer(:ACCOUNT_LEVERAGE)
puts "Leverage: 1:#{leverage}"
```

```ruby
# Single string property — currency
currency = acct.account_info_string(:ACCOUNT_CURRENCY)
puts "Currency: #{currency}"
```

```ruby
# Account-health check — the summary already carries the margin level
s = acct.account_summary
level = s.account_margin_level   # also account_margin, account_margin_free

if level.positive? && level < 100      then puts "⚠️ Margin level critical!"
elsif level.positive? && level < 200   then puts "⚠️ Low margin level"
else                                        puts "✅ Healthy margin level"
end
```

---

## 🧱 Enums used in Account Information

All four methods use enums — either as an **input** property selector, or as an **output** field describing the account. In Ruby, pass an enum as a **symbol** (`:ACCOUNT_BALANCE`); outputs come back as symbols too (`:MRPC_ACCOUNT_TRADE_MODE_DEMO`).

### Input enums (property selectors)

Passed to the `account_info_*` methods to choose **which** property to read:

| Method | Input enum | Purpose | Example values |
|--------|------------|---------|----------------|
| **account_info_double** | `AccountInfoDoublePropertyType` | which double property | `:ACCOUNT_BALANCE`, `:ACCOUNT_EQUITY`, `:ACCOUNT_MARGIN`, `:ACCOUNT_MARGIN_FREE`, `:ACCOUNT_MARGIN_LEVEL`, `:ACCOUNT_PROFIT`, `:ACCOUNT_CREDIT`, … (14 total) |
| **account_info_integer** | `AccountInfoIntegerPropertyType` | which integer property | `:ACCOUNT_LOGIN`, `:ACCOUNT_LEVERAGE`, `:ACCOUNT_TRADE_MODE`, `:ACCOUNT_LIMIT_ORDERS`, `:ACCOUNT_TRADE_ALLOWED`, `:ACCOUNT_MARGIN_MODE`, … (11 total) |
| **account_info_string** | `AccountInfoStringPropertyType` | which string property | `:ACCOUNT_NAME`, `:ACCOUNT_SERVER`, `:ACCOUNT_CURRENCY`, `:ACCOUNT_COMPANY` (4 total) |

```ruby
balance  = acct.account_info_double(:ACCOUNT_BALANCE)
leverage = acct.account_info_integer(:ACCOUNT_LEVERAGE)
currency = acct.account_info_string(:ACCOUNT_CURRENCY)
```

### Output enums (returned values)

Returned in `account_summary` to describe account state:

| Method | Output enum | Accessor | Values |
|--------|-------------|----------|--------|
| **account_summary** | `MrpcEnumAccountTradeMode` | `account_trade_mode` | `:..._DEMO` (0) · `:..._CONTEST` (1) · `:..._REAL` (2) |
| **account_summary** | `MrpcEnumAccountMarginMode` | `account_margin_mode` | `:..._RETAIL_NETTING` (0) · `:..._EXCHANGE` (1) · `:..._RETAIL_HEDGING` (2, typical MT5) |

```ruby
s = acct.account_summary
case s.account_trade_mode
when :MRPC_ACCOUNT_TRADE_MODE_DEMO then puts "Demo account"
when :MRPC_ACCOUNT_TRADE_MODE_REAL then puts "Real account"
end
```

### 📝 Notes about enums

* **Input enums are required** — `account_info_*` always needs a property symbol.
* **Output enums are typed fields** — `account_summary` returns `account_trade_mode` / `account_margin_mode` directly as symbols.
* **`account_info_integer` special case** — some integer properties (e.g. `:ACCOUNT_TRADE_MODE`) encode an enum, but come back as a plain `Integer` (0/1/2).
* **No enums on Double/String outputs** — those always return a plain `Float` / `String`.

---

## See also

* **Symbols & Quotes:** [Symbol Information — Overview](../2.%20Symbol_Information/Symbol_Information.Overview.md) — prices and symbol properties.
* **Friendly layer:** [`MT5Service#account_info`](../../MT5Service/MT5Service.Overview.md) returns a named `Account` Struct (plain fields, UTC times).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
