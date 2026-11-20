# 🕑 Trade Session Times

> **Request:** the trade session `[from, to)` for a symbol on a given weekday (`SymbolInfoSessionTradeData`) — when the symbol can actually be **traded**.

**API Information:**

* **Low-level API:** `MT5Account#symbol_info_session_trade(symbol, day_of_week:, session_index:)` (from the `metarpc_mt5` gem)
* **gRPC service:** `mt5_term_api.MarketInfo`
* **Proto definition:** `SymbolInfoSessionTrade` (defined in `mt5-term-api-market-info.proto`)

### RPC

* **Service:** `mt5_term_api.MarketInfo`
* **Method:** `SymbolInfoSessionTrade(SymbolInfoSessionTradeRequest) → SymbolInfoSessionTradeReply`
* **Low-level client (generated):** `Mt5TermApi::MarketInfo::Stub#symbol_info_session_trade(request, metadata:, deadline:)`

---

## 💬 Just the essentials

* **What it is.** One RPC returning a single trade-session window for a symbol on one weekday.
* **Why you need it.** Gate order placement to market hours — don't send into a closed session.
* **Sanity check.** Trade windows are usually equal to or narrower than the [quote windows](./SymbolInfoSessionQuote.md).

---

## 🎯 Purpose

`symbol_info_session_trade` is the **"can I trade now?"** calendar. Use it to skip entries when the instrument is quote-only or closed, and to schedule activity around session opens/closes.

---

## 🧱 Signature

```ruby
class MetaRPC::MT5::MT5Account
  def symbol_info_session_trade(symbol, day_of_week:, session_index: 0) -> Mt5TermApi::SymbolInfoSessionTradeData
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

## ⬆️ Output — `SymbolInfoSessionTradeData`

| Ruby accessor | Type | Description |
| ------------- | ---- | ----------- |
| `from` | message | Session start (read `.seconds`). |
| `to` | message | Session end (read `.seconds`). |

---

## 🧩 Notes & Tips

* **Errors are exceptions:** raises `ApiError` on failure.
* **Quote vs trade:** a symbol may **quote** outside the window in which it can be **traded** — compare against [`symbol_info_session_quote`](./SymbolInfoSessionQuote.md).
* **Weekends** are typically empty/closed on FX — handle `nil` `from`.

---

## 🔗 Usage Examples

### 1) Monday trade session

```ruby
st = acct.symbol_info_session_trade("EURUSD", day_of_week: :MONDAY)
puts "#{st.from&.seconds}s → #{st.to&.seconds}s"
```

### 2) Compare quote vs trade window

```ruby
q = acct.symbol_info_session_quote("EURUSD", day_of_week: :MONDAY)
t = acct.symbol_info_session_trade("EURUSD", day_of_week: :MONDAY)
puts "quote #{q.from&.seconds}  ·  trade #{t.from&.seconds}"
```

### 3) Is a symbol tradable today?

```ruby
day = Time.now.utc.strftime("%A").upcase.to_sym   # e.g. :MONDAY
tradable = !acct.symbol_info_session_trade("EURUSD", day_of_week: day).from.nil?
puts tradable ? "market open today" : "closed today"
```

---

## 🔧 Common Patterns

### Trade-hours guard

```ruby
def within_trade_hours?(acct, sym)
  day  = Time.now.utc.strftime("%A").upcase.to_sym
  s    = acct.symbol_info_session_trade(sym, day_of_week: day)
  return false if s.from.nil?
  now  = Time.now.utc
  secs = now.hour * 3600 + now.min * 60 + now.sec
  (s.from.seconds..s.to.seconds).cover?(secs)
end
```

---

## 📚 See Also

* [SymbolInfoSessionQuote](./SymbolInfoSessionQuote.md) — quote sessions.
* **Friendly layer:** [`MT5Service#session_trade`](../../MT5Service/2.%20Symbol_Methods.md).

---

**Back to:** [Additional Methods — Overview](./Additional_Methods.Overview.md) · [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
