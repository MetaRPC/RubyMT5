# ✅ Getting an Account Summary

> **Request:** full account summary (`AccountSummaryData`) from **MT5**. Fetch all core account metrics in a single call.

**API Information:**

* **Low-level API:** `MT5Account#account_summary` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.AccountHelper`
* **Proto definition:** `AccountSummary` (defined in `mt5-term-api-account-helper.proto`)

### RPC

* **Service:** `mt5_term_api.AccountHelper`
* **Method:** `AccountSummary(AccountSummaryRequest) → AccountSummaryReply`
* **Low-level client (generated):** `Mt5TermApi::AccountHelper::Stub#account_summary(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** A single RPC returning full account state: balance, equity, credit, currency, leverage, trade mode, margin / free margin / margin level / margin mode, and server time.
* **Why you need it.** Fast dashboard / CLI status; double-check login / currency / leverage; connection heartbeat via `server_time`.
* **Sanity check.** If `account_login`, `account_currency`, `account_leverage`, `account_equity` are set → the connection is alive.

---

## 🎯 Purpose

Use it to display real-time account state and sanity-check connectivity:

* Dashboard / CLI status in one call.
* Verify balance & equity before trading.
* Terminal heartbeat via `server_time` / `server_time_utc` and `server_utc_offset_seconds`.

> **Prefer plain values?** [`MT5Service#account_info`](../../MT5Service/MT5Service.Overview.md) returns a friendly `Account` Struct (named fields, times as numbers) instead of protobuf.

---

## 🧱 Signature

```ruby
require "metarpc_mt5"

class MetaRPC::MT5::MT5Account
  # Retrieves full account information in a single call.
  # Returns the raw AccountSummaryData (read fields with snake_case accessors);
  # raises ApiError on failure.
  def account_summary -> Mt5TermApi::AccountSummaryData
end
```

**Request message:**

`AccountSummaryRequest {}` *(empty message — the SDK builds it for you; `account_summary` takes no arguments)*

**Reply message:**

```protobuf
AccountSummaryReply {
  oneof response {
    AccountSummaryData data = 1;
    Error error = 2;
  }
}
```

`MT5Account` unwraps the `oneof`: it returns `data` on success and **raises** `ApiError` (carrying the server-side `Error`) otherwise.

---

## 🔽 Input

**No parameters.** `account_summary` takes no arguments — the SDK sends an empty `AccountSummaryRequest`.

**There is no per-call timeout argument.** Each call runs on the account's deadline (`timeout`, default `60` s). Tune it on the account:

```ruby
acct.timeout = 15   # seconds — deadline for ordinary read RPCs
```

---

## ⬆️ Output — `AccountSummaryData`

| Field (proto) | Ruby accessor | Type | Description |
| ------------- | ------------- | ---- | ----------- |
| `account_login` | `account_login` | `Integer` | Trading account login (ID). |
| `account_balance` | `account_balance` | `Float` | Balance excluding floating P/L. |
| `account_equity` | `account_equity` | `Float` | Equity = balance + floating P/L. |
| `account_user_name` | `account_user_name` | `String` | Account holder name. |
| `account_leverage` | `account_leverage` | `Integer` | Leverage (e.g. `100` for 1:100). |
| `account_trade_mode` | `account_trade_mode` | `Symbol` | Demo / Contest / Real — see enum below. |
| `account_company_name` | `account_company_name` | `String` | Broker / company display name. |
| `account_currency` | `account_currency` | `String` | Deposit currency (e.g. `"USD"`). |
| `server_time` | `server_time` | `Timestamp` | Server time at response (broker time zone). `.seconds` → unix seconds. |
| `server_time_utc` | `server_time_utc` | `Timestamp` | The same moment in UTC. |
| `utc_timezone_server_time_shift_minutes` | `utc_timezone_server_time_shift_minutes` | `Integer` | Server offset from UTC (minutes). |
| `account_credit` | `account_credit` | `Float` | Credit amount. |
| `server_utc_offset_seconds` | `server_utc_offset_seconds` | `Integer` | Broker offset from UTC in seconds (positive = ahead). |
| `account_margin` | `account_margin` | `Float` | Margin currently used by open positions. |
| `account_margin_free` | `account_margin_free` | `Float` | Free margin available for new positions. |
| `account_margin_level` | `account_margin_level` | `Float` | Margin level in percent (`equity / margin × 100`); `0` when no margin is used. |
| `account_margin_mode` | `account_margin_mode` | `Symbol` | Margin mode (MT5 demo = `RETAIL_HEDGING`) — see enum below. |
| `account_trade_allowed` | `account_trade_allowed` | `Boolean` | Trading allowed for this account. |
| `account_trade_expert` | `account_trade_expert` | `Boolean` | Automated (EA) trading allowed. |
| `terminal_connected` | `terminal_connected` | `Boolean` | Terminal is connected to the broker. |
| `terminal_trade_allowed` | `terminal_trade_allowed` | `Boolean` | Trading is allowed in the terminal. |

> **🧮 Floating profit:** the summary has no dedicated profit field — compute `account_equity - account_balance`, or read `account_info_double(:ACCOUNT_PROFIT)`.

---

## 🧱 Related enums (from proto)

> **💡 Enum usage note:** generated protobuf enums come back as Ruby **symbols**. Compare against the full constant, e.g. `s.account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO`.

### `MrpcEnumAccountTradeMode`

```protobuf
enum MrpcEnumAccountTradeMode {
  MRPC_ACCOUNT_TRADE_MODE_DEMO    = 0;  // demo / practice
  MRPC_ACCOUNT_TRADE_MODE_CONTEST = 1;  // contest
  MRPC_ACCOUNT_TRADE_MODE_REAL    = 2;  // real trading
}
```

```ruby
def trade_mode_to_s(mode)
  case mode
  when :MRPC_ACCOUNT_TRADE_MODE_DEMO    then "DEMO"
  when :MRPC_ACCOUNT_TRADE_MODE_CONTEST then "CONTEST"
  when :MRPC_ACCOUNT_TRADE_MODE_REAL    then "REAL"
  else "UNKNOWN(#{mode})"
  end
end
```

### `MrpcEnumAccountMarginMode`

```protobuf
enum MrpcEnumAccountMarginMode {
  MRPC_ACCOUNT_MARGIN_MODE_RETAIL_NETTING = 0;  // netting (one position per symbol)
  MRPC_ACCOUNT_MARGIN_MODE_EXCHANGE       = 1;  // exchange margin
  MRPC_ACCOUNT_MARGIN_MODE_RETAIL_HEDGING = 2;  // hedging (many positions per symbol) — typical MT5
}
```

---

## 🧩 Notes & Tips

* **Errors are exceptions:** a server-side rejection raises `MetaRPC::MT5::ApiError`; a transport failure raises the gRPC error. Wrap in `begin/rescue`.
* **Default timeout:** read RPCs use the account's `timeout` (default `60` s).
* **Timestamps:** `server_time` / `server_time_utc` are `google.protobuf.Timestamp`; read `.seconds` for unix seconds, or use the friendly `MT5Service#account_info` which returns numbers.
* **Session is automatic:** `connect` obtains the terminal id and the SDK attaches it to this call — you never pass it yourself.

---

## 🔗 Usage Examples

### 1) Basic usage

```ruby
require "metarpc_mt5"

acct = MetaRPC::MT5::MT5Account.new("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
acct.connect(5057947437, "password", server: "MetaQuotes-Demo")

s = acct.account_summary
puts "Account Login: #{s.account_login}"
puts "Balance: #{s.account_balance.round(2)} #{s.account_currency}"
puts "Equity: #{s.account_equity.round(2)}"
puts "Leverage: 1:#{s.account_leverage}"
```

### 2) Compact status line for a CLI

```ruby
def print_account_status(acct)
  s = acct.account_summary
  puts "Acc #{s.account_login} | #{s.account_currency} | " \
       "Bal #{s.account_balance.round(2)} | Eq #{s.account_equity.round(2)} | " \
       "Lev 1:#{s.account_leverage} | Mode #{trade_mode_to_s(s.account_trade_mode)}"
rescue MetaRPC::MT5::ApiError => e
  puts "❌ Error: #{e.message}"
end
# Output: Acc 5057947437 | USD | Bal 10000.0 | Eq 10050.25 | Lev 1:100 | Mode DEMO
```

### 3) Floating profit & margin health

```ruby
def print_health(acct)
  s = acct.account_summary
  floating = s.account_equity - s.account_balance   # no dedicated profit field
  level = s.account_margin_level                    # 0 when flat

  puts "Floating P/L: #{floating.round(2)}"
  if level.zero?       then puts "No open margin"
  elsif level < 100    then puts "⚠️ Margin level critical!"
  elsif level < 200    then puts "⚠️ Low margin level"
  else                      puts "✅ Healthy margin level"
  end
end
```

### 4) Server time with timezone shift

```ruby
def print_server_time(acct)
  s = acct.account_summary
  utc    = Time.at(s.server_time_utc.seconds).utc
  broker = Time.at(s.server_time.seconds).utc
  puts "Server time (UTC): #{utc.iso8601}"
  puts "Server time (broker): #{broker.iso8601}"
  puts "Broker offset from UTC: #{s.server_utc_offset_seconds} seconds"
end
```

### 5) Structured data model

```ruby
AccountView = Struct.new(:login, :currency, :balance, :equity, :floating, :leverage, :trade_mode, :company, keyword_init: true)

def from_proto(s)
  AccountView.new(
    login: s.account_login, currency: s.account_currency,
    balance: s.account_balance, equity: s.account_equity,
    floating: s.account_equity - s.account_balance,
    leverage: s.account_leverage, trade_mode: trade_mode_to_s(s.account_trade_mode),
    company: s.account_company_name
  )
end

p from_proto(acct.account_summary)
```

### 6) Error handling

```ruby
def try_get_summary(acct)
  acct.account_summary
rescue MetaRPC::MT5::ApiError, GRPC::BadStatus => e
  puts "Failed to get account summary: #{e.message}"
  nil
end
```

---

## 🔧 Common Patterns

### Health check

```ruby
def account_healthy?(acct)
  s = acct.account_summary
  s.account_login.positive? && !s.account_currency.empty? && s.account_leverage.positive?
rescue StandardError
  false
end
```

### Monitor account changes

```ruby
def monitor_account(acct, interval_s)
  loop do
    s = acct.account_summary
    puts "[#{Time.now.strftime('%H:%M:%S')}] Balance: #{s.account_balance.round(2)} | Equity: #{s.account_equity.round(2)}"
    sleep interval_s
  rescue MetaRPC::MT5::ApiError => e
    puts "❌ Error: #{e.message}"
  end
end
# Usage: monitor_account(acct, 5)
```

---

## 📚 See Also

* [AccountInfoDouble](./AccountInfoDouble.md) — one double account property (balance, equity, margin, profit…).
* [AccountInfoInteger](./AccountInfoInteger.md) — one integer account property (login, leverage…).
* [AccountInfoString](./AccountInfoString.md) — one string account property (currency, company, server).
* **Friendly layer:** [`MT5Service#account_info`](../../MT5Service/MT5Service.Overview.md) → a named `Account` Struct.

---

**Back to:** [Account Information — Overview](./Account_Information.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
