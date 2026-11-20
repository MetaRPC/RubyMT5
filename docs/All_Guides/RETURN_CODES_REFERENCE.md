# Return Codes & the Error Model

> How RubyMT5 tells you a trade's result: `returned_code` on the data it returns, `ApiError` when the call itself fails, and `TradeOutcomeUnknown` when a trade's fate is uncertain.

---

## 🛡️ What `returned_code` is

**RetCode** (`returned_code`) is the trade-server status returned after a trading operation. **`10009` = done.** Anything else is the reason the broker rejected or deferred the trade (not enough money, market closed, bad stops…).

RetCodes appear **only on trading operations**, because only those go through the broker and can be rejected. Read-only calls (prices, symbols, balance) have no RetCode — they either return data or raise.

```ruby
r = mt5.buy_market("EURUSD", 0.01)       # returns OrderSendData — it does NOT raise on a rejection
if r.returned_code == 10_009             # TRADE_RETCODE_DONE
  puts "opened ##{r.order}"
else
  puts "rejected: #{r.returned_code} #{r.returned_code_description}"
end
```

> **Golden rule:** *no exception ≠ trade succeeded.* The call returning without raising only means the request reached the terminal. **Always check `returned_code`.**

---

## 🧭 The three outcomes of a trade call

| Outcome | How it surfaces | What it means |
|---------|-----------------|---------------|
| **Done** | returned data, `returned_code == 10009` | the broker executed it |
| **Rejected / deferred** | returned data, `returned_code != 10009` | broker said no (or requote) — reason in `returned_code_description` |
| **Call failed** | raises `MetaRPC::MT5::ApiError` | gateway/terminal error branch (validation, timeout, bad API key…) |
| **Uncertain** | raises `…::ApiError` *or* a `TradeOutcomeUnknown`-marked error | request may or may not have executed — **do not blindly retry** |

So a complete trade looks like:

```ruby
begin
  r = mt5.buy_market_with_sl_tp("EURUSD", 0.01, sl: 1.0820, tp: 1.0920)
  if r.returned_code == 10_009
    puts "opened ##{r.order} @ #{r.price}"
  else
    puts "rejected: #{r.returned_string_code} — #{r.returned_code_description}"
  end
rescue MetaRPC::MT5::ApiError => e
  raise if e.trade_outcome_unknown?           # uncertain — check positions before retrying
  warn "trade error: #{e.error.mql_error_trade_description}"
end
```

---

## 📥 What the trade data carries

Trade one-liners return the operation's `*Data` (`OrderSendData`, `OrderModifyData`, `OrderCloseData`). The send result's fields:

```
> OrderSendData              # ruby examples/demos/helpers/17_protobuf_inspector.rb OrderSendData
  returned_code              uint32    ← 10009 = DONE
  deal                       uint64
  order                      uint64    ← the position/order ticket on success
  volume                     double
  price                      double
  returned_string_code       string    ← e.g. "TRADE_RETCODE_NO_MONEY"
  returned_code_description  string    ← human text, straight from the server
  …
```

**You rarely need a lookup table:** every result already carries `returned_string_code` (the symbolic name) and `returned_code_description` (human text). The symbolic names are the protobuf enum **`MqlErrorTradeCode`** — list them all with the inspector:

```bash
ruby examples/demos/helpers/17_protobuf_inspector.rb enum MqlErrorTradeCode
```

---

## ❗ The error object (`MetaRPC::MT5::ApiError`)

When the gateway answers with the error branch, the SDK raises `MetaRPC::MT5::ApiError`, wrapping the protobuf `Error`. Useful accessors:

| On the error | Gives |
|--------------|-------|
| `e.message` | the full formatted string (code, type, MQL + trade codes, descriptions) |
| `e.code` | the gateway `error_code` **string** (e.g. `"MRPC_TIMEOUT"`, `"API_KEY_INVALID"`) |
| `e.error.mql_error_trade_int_code` | the numeric trade retcode (e.g. `10019`) |
| `e.error.mql_error_trade_code` | the retcode as an enum symbol (e.g. `:TRADE_RETCODE_NO_MONEY`) |
| `e.error.mql_error_trade_description` | human trade-error text |
| `e.api_key_error?` | `true` for `API_KEY_INVALID` / `API_KEY_REQUIRED` — never retry |
| `e.trade_outcome_unknown?` | `true` when the trade's result is uncertain (see below) |

Subclass **`InvalidLoginError < ApiError`** is raised by `connect` when the broker rejects the login — never retry it.

```ruby
rescue MetaRPC::MT5::InvalidLoginError
  abort "bad login/password/server"
rescue MetaRPC::MT5::ApiError => e
  case e.error.mql_error_trade_int_code
  when 10_019 then warn "not enough money — reduce volume"
  when 10_018 then warn "market closed — try during trading hours"
  when 10_016 then warn "stops too close — widen SL/TP (StopLevel)"
  else warn "error #{e.code}: #{e.error.mql_error_trade_description}"
  end
end
```

---

## ⚠️ `TradeOutcomeUnknown` — the one you must not retry blindly

A trade call can fail **after** the request may already have reached the terminal (a gateway/terminal timeout, or a transport drop like gRPC `UNAVAILABLE` / `DEADLINE_EXCEEDED`). The trade **may or may not** have executed. The SDK **never re-sends a trade automatically**.

Two ways it reaches you, both answering `trade_outcome_unknown? == true`:

```ruby
begin
  r = mt5.buy_market("EURUSD", 0.01)
rescue MetaRPC::MT5::TradeOutcomeUnknown => e   # transport failure, mixed into the GRPC error
  warn e.to_s
  # check whether it actually opened before doing anything:
  pos = mt5.open_positions(symbol: "EURUSD").max_by(&:ticket)
  # decide to keep it or send again — never retry unconditionally
rescue MetaRPC::MT5::ApiError => e
  retry_safely unless e.trade_outcome_unknown?  # in-band timeout (10012/10028/10031, MRPC_TIMEOUT…)
end
```

In-band uncertainty is flagged for trade RPCs when the code is a timeout (`MRPC_TIMEOUT`, `TERMINAL_API_TIMEOUT`, …) or the trade retcode is `10012` (TIMEOUT), `10028` (LOCKED) or `10031` (CONNECTION).

---

## 📋 Complete RetCode list (`MqlErrorTradeCode`)

These are the standard MQL5 trade return codes, exactly as the enum defines them in `package/`. **Bold = success.**

### Success & partial

| Code | Name | Meaning |
|------|------|---------|
| **10009** | `TRADE_RETCODE_DONE` | request completed — the one you check for |
| 10008 | `TRADE_RETCODE_PLACED` | pending order placed |
| 10010 | `TRADE_RETCODE_DONE_PARTIAL` | only part of the volume filled |

### Requote — retry with a fresh price

| Code | Name |
|------|------|
| 10004 | `TRADE_RETCODE_REQUOTE` |
| 10020 | `TRADE_RETCODE_PRICE_CHANGED` |

### Temporary — retry with a delay

| Code | Name |
|------|------|
| 10012 | `TRADE_RETCODE_TIMEOUT` |
| 10021 | `TRADE_RETCODE_PRICE_OFF` (no quotes) |
| 10024 | `TRADE_RETCODE_TOO_MANY_REQUESTS` |
| 10028 | `TRADE_RETCODE_LOCKED` |
| 10029 | `TRADE_RETCODE_FROZEN` |
| 10031 | `TRADE_RETCODE_CONNECTION` (no connection) |

### Validation — fix the request

| Code | Name | Common cause |
|------|------|--------------|
| 10013 | `TRADE_RETCODE_INVALID` | malformed request |
| 10014 | `TRADE_RETCODE_INVALID_VOLUME` | volume < min or > max / wrong step |
| 10015 | `TRADE_RETCODE_INVALID_PRICE` | price breaks symbol rules |
| 10016 | `TRADE_RETCODE_INVALID_STOPS` | SL/TP too close (StopLevel) |
| 10022 | `TRADE_RETCODE_INVALID_EXPIRATION` | bad expiration time |
| 10030 | `TRADE_RETCODE_INVALID_FILL` | fill type not allowed |
| 10035 | `TRADE_RETCODE_INVALID_ORDER` | order type prohibited for symbol |
| 10038 | `TRADE_RETCODE_INVALID_CLOSE_VOLUME` | close volume exceeds position |

### Restrictions — check trading conditions

| Code | Name |
|------|------|
| 10017 | `TRADE_RETCODE_TRADE_DISABLED` |
| 10018 | `TRADE_RETCODE_MARKET_CLOSED` |
| 10026 | `TRADE_RETCODE_SERVER_DISABLES_AT` |
| 10027 | `TRADE_RETCODE_CLIENT_DISABLES_AT` |
| 10032 | `TRADE_RETCODE_ONLY_REAL` |
| 10042 | `TRADE_RETCODE_LONG_ONLY` |
| 10043 | `TRADE_RETCODE_SHORT_ONLY` |
| 10044 | `TRADE_RETCODE_CLOSE_ONLY` |
| 10045 | `TRADE_RETCODE_FIFO_CLOSE` |
| 10046 | `TRADE_RETCODE_HEDGE_PROHIBITED` |

### Limits — reduce volume / positions

| Code | Name |
|------|------|
| 10019 | `TRADE_RETCODE_NO_MONEY` |
| 10033 | `TRADE_RETCODE_LIMIT_ORDERS` |
| 10034 | `TRADE_RETCODE_LIMIT_VOLUME` |
| 10040 | `TRADE_RETCODE_LIMIT_POSITIONS` |

### State

| Code | Name | Meaning |
|------|------|---------|
| 10023 | `TRADE_RETCODE_ORDER_CHANGED` | order changed during the request |
| 10025 | `TRADE_RETCODE_NO_CHANGES` | new params equal current — nothing to do |
| 10036 | `TRADE_RETCODE_POSITION_CLOSED` | position already closed |
| 10039 | `TRADE_RETCODE_CLOSE_ORDER_EXIST` | a close order already exists |

### Rejection / processing

| Code | Name |
|------|------|
| 10006 | `TRADE_RETCODE_REJECT` |
| 10007 | `TRADE_RETCODE_CANCEL` |
| 10011 | `TRADE_RETCODE_ERROR` |
| 10041 | `TRADE_RETCODE_REJECT_CANCEL` |

---

## 🔁 A retry pattern

Categorise by RetCode and let `trade_outcome_unknown?` gate the uncertain ones:

```ruby
REQUOTE   = [10_004, 10_020].freeze
TEMPORARY = [10_012, 10_021, 10_024, 10_028, 10_029, 10_031].freeze

def buy_with_retry(mt5, symbol, volume, tries: 3)
  tries.times do |i|
    r = mt5.buy_market(symbol, volume)
    return r if r.returned_code == 10_009
    code = r.returned_code
    break unless REQUOTE.include?(code) || TEMPORARY.include?(code)   # permanent → stop
    sleep(REQUOTE.include?(code) ? 0.1 : i + 1)                        # requote fast, temp backoff
  end
  nil
rescue MetaRPC::MT5::ApiError => e
  raise if e.trade_outcome_unknown?    # never auto-retry an uncertain trade
  raise
end
```

---

## 📑 Quick category reference

| Category | RetCodes | Action |
|----------|----------|--------|
| Success | 10008, 10009, 10010 | continue |
| Requote | 10004, 10020 | retry immediately with a fresh price |
| Temporary | 10012, 10021, 10024, 10028, 10029, 10031 | retry with a delay |
| Validation | 10013–10016, 10022, 10030, 10035, 10038 | fix the request |
| Restrictions | 10017, 10018, 10026, 10027, 10032, 10042–10046 | check conditions |
| Limits | 10019, 10033, 10034, 10040 | reduce volume / positions |
| State | 10023, 10025, 10036, 10039 | re-read current state |
| Rejection | 10006, 10007, 10011, 10041 | inspect the request |

---

## See Also

* [Glossary → ApiError / Subscription](./GLOSSARY.md) · [ENUMs Reference](./ENUMS_USAGE_REFERENCE.md)
* [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md) — `enum MqlErrorTradeCode` lists every code
* [MT5Sugar → Simple Trading](../MT5Sugar/5.%20Simple_Trading.md) · [Getting Started](./GETTING_STARTED.md)
