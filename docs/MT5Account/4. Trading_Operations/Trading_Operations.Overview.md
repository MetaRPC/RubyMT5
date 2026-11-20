# MT5Account · Trading Operations — Overview

> Place, modify and close orders, plus the pre-trade calculators. All trade calls go through `mt5_term_api.TradingHelper`; the calculators/validation through `TradeFunctions`.

## ⚠️ Exactly-once trade safety

Trade calls (`order_send` / `order_modify` / `order_close`) are **sent exactly once and never re-sent by the SDK**. If a trade call fails at the transport level *after* the request may already have reached the terminal, the error is marked **`TradeOutcomeUnknown`** — the trade may or may not have executed. **Check open positions / history before retrying.** See [Return Codes](../../All_Guides/RETURN_CODES_REFERENCE.md).

## 📁 What lives here

| Method | What it does |
|--------|--------------|
| **[OrderSend](./OrderSend.md)** | open a market or pending order |
| **[OrderModify](./OrderModify.md)** | change SL/TP/price/expiration |
| **[OrderClose](./OrderClose.md)** | close a position or delete a pending order |
| **[OrderCheck](./OrderCheck.md)** | validate a trade request without sending it |
| **[OrderCalcMargin](./OrderCalcMargin.md)** | margin required for an order |
| **[OrderCalcProfit](./OrderCalcProfit.md)** | profit of a hypothetical round-trip |

---

## 🧭 Plain English

* **Trade:** `order_send` opens, `order_modify` adjusts, `order_close` exits. Each returns a `*Data` with a **`returned_code`** — **`10009` = DONE**.
* **Think first:** `order_check` validates (margin / retcode) without touching the market; `order_calc_margin` / `order_calc_profit` do the pre-trade math.

> Rule of thumb: **size/validate** with the calculators → **execute** with `order_send` → **manage** with `order_modify` / `order_close`.

---

## Quick choose

| If you need…                         | Use                 | Returns |
| ------------------------------------ | ------------------- | ------- |
| Open market / pending order          | `order_send`        | `OrderSendData` |
| Change SL / TP / price               | `order_modify`      | `OrderModifyData` |
| Close position / delete pending      | `order_close`       | `OrderCloseData` |
| Validate before sending              | `order_check`       | `OrderCheckData` |
| Margin for an order                  | `order_calc_margin` | `Float` |
| Profit of a move                     | `order_calc_profit` | `Float` |

---

## 🧱 Order-type symbols

`order_send` takes a friendly `type:` symbol mapped to the trading-helper enum:

| `type:` | Meaning |
|---------|---------|
| `:buy` / `:sell` | market order |
| `:buy_limit` / `:sell_limit` | pending limit (faces the market) |
| `:buy_stop` / `:sell_stop` | pending stop (breakout) |
| `:buy_stop_limit` / `:sell_stop_limit` | stop-limit |

> The calculators (`order_calc_margin` / `order_calc_profit`) and `order_check` use the **trade-functions** enum (`ORDER_TYPE_TF_*`); the SDK maps the same friendly symbols for you.

---

## 🟢 Minimal snippets

```ruby
ask = acct.symbol_info_tick("EURUSD").ask
margin = acct.order_calc_margin(symbol: "EURUSD", type: :buy, volume: 0.1, price: ask)
puts "margin #{margin.round(2)}"

r = acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.1, magic: 600001)
puts "retcode #{r.returned_code} order ##{r.order}" if r.returned_code == 10_009

acct.order_close(ticket: r.order)
```

---

## See also

* **State:** [Positions & Orders — Overview](../3.%20Position_Orders_Information/Position_Orders_Information.Overview.md).
* **Friendly layer:** [`MT5Sugar#buy_market` / `#close_position`](../../MT5Sugar/MT5Sugar.API_Overview.md).
* **Return codes:** [Return Codes & the error model](../../All_Guides/RETURN_CODES_REFERENCE.md).

---

**Back to:** [MT5Account — Master Overview](../MT5Account.Master.Overview.md)
