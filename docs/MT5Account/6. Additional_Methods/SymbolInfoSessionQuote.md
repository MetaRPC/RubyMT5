# 🕐 Quote Session Times

> **Request:** the quote session `[from, to)` for a symbol on a given weekday (`SymbolInfoSessionQuoteData`) — when the symbol is **quoted**.

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_session_quote(symbol, day_of_week:, session_index:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoSessionQuote` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoSessionQuote(SymbolInfoSessionQuoteRequest) → SymbolInfoSessionQuoteReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_info_session_quote(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning a single quote-session window for a symbol on one weekday.
* **Why you need it.** Know when prices are being published (vs when you can actually trade — see [`symbol_info_session_trade`](./SymbolInfoSessionTrade.md)).
* **Sanity check.** On a 24/5 FX major, weekdays return a long window; Saturday/Sunday are usually empty or closed.

---

## 🎯 Purpose

`symbol_info_session_quote` tells you the broker's **quoting hours**. Combined with the trade session, it lets a bot avoid acting outside market hours or during thin, quote-only windows.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  # day_of_week: an ENUM_DAY_OF_WEEK symbol (:SUNDAY .. :SATURDAY).
  def symbol_info_session_quote(symbol, day_of_week:, session_index: 0) -> Mt5TermApi::SymbolInfoSessionQuoteData
end
```

## 🔽 Input

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `symbol` | `String` | The symbol. |
| `day_of_week` | `Symbol` *(keyword)* | `:SUNDAY` … `:SATURDAY`. |
| `session_index` | `Integer` *(keyword, default `0`)* | Which session on that day (0-based). |

## 🧱 Day enum — `DayOfWeek` (all 7)

```protobuf
SUNDAY    = 0
MONDAY    = 1
TUESDAY   = 2
WEDNESDAY = 3
THURSDAY  = 4
FRIDAY    = 5
SATURDAY  = 6
```

## ⬆️ Output — `SymbolInfoSessionQuoteData`

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `from` | message | Session start (read `.seconds`). |
| `to` | message | Session end (read `.seconds`). |

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **`from` / `to` are seconds-of-day** style messages — read `.seconds`.
* **Multiple sessions:** bump `session_index` (0, 1, 2…) to walk a day with breaks; stop when the call errors / returns empty.
* **Quote ≠ trade:** quoting can be wider than the tradable window — compare with [`symbol_info_session_trade`](./SymbolInfoSessionTrade.md).

---

## 🔗 Usage Examples

### 1) Monday quote session

```ruby
sq = acct.symbol_info_session_quote("EURUSD", day_of_week: :MONDAY)
puts "#{sq.from&.seconds}s → #{sq.to&.seconds}s"
```

### 2) Whole week at a glance

```ruby
%i[MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY].each do |d|
  s = acct.symbol_info_session_quote("EURUSD", day_of_week: d)
  puts "#{d}: #{s.from&.seconds} → #{s.to&.seconds}"
end
```

### 3) Walk multiple sessions of a day

```ruby
i = 0
loop do
  s = acct.symbol_info_session_quote("XAUUSD", day_of_week: :MONDAY, session_index: i)
  break if s.from.nil?
  puts "session #{i}: #{s.from.seconds} → #{s.to.seconds}"
  i += 1
rescue MetaRPC::MT5::ApiError
  break
end
```

---

## 🔧 Common Patterns

### Seconds-of-day → "HH:MM"

```ruby
def hhmm(secs)
  format("%02d:%02d", secs / 3600, (secs % 3600) / 60)
end
sq = acct.symbol_info_session_quote("EURUSD", day_of_week: :MONDAY)
puts "#{hhmm(sq.from.seconds)}–#{hhmm(sq.to.seconds)}"
```

---

## 📚 See Also

* [SymbolInfoSessionTrade](./SymbolInfoSessionTrade.md) — trade (not quote) sessions.
* **Friendly layer:** [`MT5Service#session_quote`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Additional Methods — Overview](./Additional_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
