# ENUMs Usage Reference — MT5Account

> Which low-level `MT5Account` methods take or return protobuf enums, and how you pass them in Ruby.

---

## 💎 How enums work in Ruby

In the Ruby protobuf runtime, **an enum value is a Ruby symbol** — both when you pass it in and when you read it back. There are no module constants to import (unlike Python/Node): you write the value's name as a `:SYMBOL`.

```ruby
# IN — a property selector enum, passed as a symbol:
balance  = mt5.account.account_info_double(:ACCOUNT_BALANCE)      # AccountInfoDoublePropertyType
leverage = mt5.account.account_info_integer(:ACCOUNT_LEVERAGE)    # AccountInfoIntegerPropertyType
digits   = mt5.account.symbol_info_integer("EURUSD", :SYMBOL_DIGITS)

# OUT — an enum-typed field reads back as a symbol:
acc = mt5.account.account_summary
acc.account_trade_mode        # => :MRPC_ACCOUNT_TRADE_MODE_DEMO   (MrpcEnumAccountTradeMode)
```

**Don't know a value's exact spelling?** List any enum with the [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md):

```bash
ruby examples/demos/helpers/17_protobuf_inspector.rb enum AccountInfoDoublePropertyType
ruby examples/demos/helpers/17_protobuf_inspector.rb whereenum TMT5_ENUM_ORDER_TYPE
```

> **Mind the context.** Order-type lives in **separate enums** per call: `TMT5_ENUM_ORDER_TYPE` (order_send), `ENUM_ORDER_TYPE_TF` (calculators / order_check), `ENUM_ORDER_TYPE` (margin rate), `SUB_ENUM_ORDER_TYPE` (streaming). See the table in [Return Codes](./RETURN_CODES_REFERENCE.md) and [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md).

---

## ✅ Summary

| Method Group | With enums | Total | % |
|--------------|-----------|-------|---|
| Account Information | 4 | 4 | 100% |
| Symbol Information | 7 | 13 | 54% |
| Positions & Orders | 3 | 6 | 50% |
| Market Depth / DOM | 1 | 3 | 33% |
| Trading Operations | 6 | 6 | 100% |
| Streaming Methods | 3 | 5 | 60% |
| **Total** | **24** | **37** | **65%** |

---

## 👤 1. Account Information — 4/4 use enums

| Method | In / Out | Input enum | Output enum |
|--------|----------|------------|-------------|
| `account_summary` | 0 / 1 | — | `MrpcEnumAccountTradeMode` (3): DEMO, CONTEST, REAL |
| `account_info_double` | 1 / 0 | `AccountInfoDoublePropertyType` (14): `:ACCOUNT_BALANCE`, `:ACCOUNT_EQUITY`, `:ACCOUNT_MARGIN`, `:ACCOUNT_MARGIN_FREE`, `:ACCOUNT_MARGIN_LEVEL`, … | — |
| `account_info_integer` | 1 / 0 | `AccountInfoIntegerPropertyType` (11): `:ACCOUNT_LOGIN`, `:ACCOUNT_TRADE_MODE`, `:ACCOUNT_LEVERAGE`, `:ACCOUNT_MARGIN_MODE`, … | — |
| `account_info_string` | 1 / 0 | `AccountInfoStringPropertyType` (4): `:ACCOUNT_NAME`, `:ACCOUNT_SERVER`, `:ACCOUNT_CURRENCY`, `:ACCOUNT_COMPANY` | — |

---

## 📊 2. Symbol Information — 7/13 use enums

| Method | In / Out | Input enum | Output enum |
|--------|----------|------------|-------------|
| `symbols_total` · `symbol_exist` · `symbol_name` · `symbol_select` · `symbol_is_synchronized` · `symbol_info_tick` | 0 / 0 | — | — |
| `symbol_info_double` | 1 / 0 | `SymbolInfoDoubleProperty` (60) — e.g. `:SYMBOL_BID`, `:SYMBOL_ASK`, `:SYMBOL_POINT` | — |
| `symbol_info_integer` | 1 / 0 | `SymbolInfoIntegerProperty` (37) — e.g. `:SYMBOL_DIGITS`, `:SYMBOL_SPREAD` | — |
| `symbol_info_string` | 1 / 0 | `SymbolInfoStringProperty` (15) | — |
| `symbol_info_margin_rate` | 1 / 0 | `ENUM_ORDER_TYPE` (9) — MQL order type | — |
| `symbol_info_session_quote` | 1 / 0 | `DayOfWeek` (7): `:SUNDAY` … `:SATURDAY` | — |
| `symbol_info_session_trade` | 1 / 0 | `DayOfWeek` (7): `:SUNDAY` … `:SATURDAY` | — |
| `symbol_params_many` | 1 / 13 | `AH_SYMBOL_PARAMS_MANY_SORT_TYPE` (4) | 13 enums in `SymbolParameters`: `BMT5_ENUM_SYMBOL_SECTOR`, `BMT5_ENUM_SYMBOL_INDUSTRY`, `BMT5_ENUM_SYMBOL_CHART_MODE`, `BMT5_ENUM_SYMBOL_CALC_MODE`, `BMT5_ENUM_SYMBOL_TRADE_MODE`, `BMT5_ENUM_SYMBOL_TRADE_EXECUTION`, `BMT5_ENUM_SYMBOL_SWAP_MODE`, `BMT5_ENUM_DAY_OF_WEEK`, `BMT5_ENUM_ORDER_TYPE_FILLING`, `BMT5_ENUM_ORDER_TYPE`, `BMT5_ENUM_SYMBOL_ORDER_GTC_MODE`, `BMT5_ENUM_SYMBOL_OPTION_MODE`, `BMT5_ENUM_SYMBOL_OPTION_RIGHT` |

---

## 📋 3. Positions & Orders — 3/6 use enums

| Method | In / Out | Input enum | Output enum |
|--------|----------|------------|-------------|
| `positions_total` · `opened_orders_tickets` · `tick_value_with_size` | 0 / 0 | — | — |
| `opened_orders` | 1 / 6 | `BMT5_ENUM_OPENED_ORDER_SORT_TYPE` (4) | in `PositionInfo`: `BMT5_ENUM_POSITION_TYPE`, `BMT5_ENUM_POSITION_REASON`; in `OpenedOrderInfo`: `BMT5_ENUM_ORDER_TYPE`, `BMT5_ENUM_ORDER_STATE`, `BMT5_ENUM_ORDER_TYPE_FILLING`, `BMT5_ENUM_ORDER_TYPE_TIME` |
| `order_history` | 1 / 4 | `BMT5_ENUM_ORDER_HISTORY_SORT_TYPE` (6) | in `OrderHistoryData` (orders only — no deal rows): `BMT5_ENUM_ORDER_STATE`, `BMT5_ENUM_ORDER_TYPE`, `BMT5_ENUM_ORDER_TYPE_FILLING`, `BMT5_ENUM_ORDER_TYPE_TIME` |
| `positions_history` | 1 / 1 | `AH_ENUM_POSITIONS_HISTORY_SORT_TYPE` (4) | `AH_ENUM_POSITIONS_HISTORY_ORDER_TYPE` (9) |

---

## 📚 4. Market Depth / DOM — 1/3 use enums

| Method | In / Out | Input enum | Output enum |
|--------|----------|------------|-------------|
| `market_book_add` · `market_book_release` | 0 / 0 | — | — |
| `market_book_get` | 0 / 1 | — | `BookType` (4): `BOOK_TYPE_SELL`, `BOOK_TYPE_BUY`, `BOOK_TYPE_SELL_MARKET`, `BOOK_TYPE_BUY_MARKET` |

---

## 💰 5. Trading Operations — 6/6 use enums

| Method | In / Out | Input enum | Output enum |
|--------|----------|------------|-------------|
| `order_send` | 2 / 0 | `TMT5_ENUM_ORDER_TYPE` (9) + `TMT5_ENUM_ORDER_TYPE_TIME` (4) | — |
| `order_modify` | 1 / 0 | `TMT5_ENUM_ORDER_TYPE_TIME` (4) | — |
| `order_close` | 0 / 1 | — | `MRPC_ORDER_CLOSE_MODE` (3): `MRPC_MARKET_ORDER_CLOSE`, `MRPC_MARKET_ORDER_PARTIAL_CLOSE`, `MRPC_PENDING_ORDER_REMOVE` |
| `order_check` | 4 / 0 | in `MrpcMqlTradeRequest`: `MRPC_ENUM_TRADE_REQUEST_ACTIONS` (6), `ENUM_ORDER_TYPE_TF` (9), `MRPC_ENUM_ORDER_TYPE_FILLING` (4), `MRPC_ENUM_ORDER_TYPE_TIME` (4) | — |
| `order_calc_margin` | 1 / 0 | `ENUM_ORDER_TYPE_TF` (9) | — |
| `order_calc_profit` | 1 / 0 | `ENUM_ORDER_TYPE_TF` (9) | — |

> The `MT5Service` / `MT5Sugar` trade helpers accept a friendly `type:` (e.g. `:buy`, `:sell_limit`) and map it to `TMT5_ENUM_ORDER_TYPE` for you — you only reach for the raw enum at the `MT5Account` level.

---

## 📡 6. Streaming Methods — 3/5 use enums

| Method | In / Out | Output enums |
|--------|----------|--------------|
| `on_symbol_tick` · `on_positions_and_pending_orders_tickets` | 0 / 0 | — |
| `on_position_profit` | 0 / 1 | `MT5_SUB_ENUM_EVENT_GROUP_TYPE` (2) — `OnPositionProfitData.type` |
| `on_trade` | 0 / 11 | `MT5_SUB_ENUM_EVENT_GROUP_TYPE` (`type`) + nested: `SUB_ENUM_POSITION_TYPE`, `SUB_ENUM_POSITION_REASON`, `SUB_ENUM_ORDER_TYPE`, `SUB_ENUM_ORDER_STATE`, `SUB_ENUM_DEAL_TYPE`, `SUB_ENUM_ORDER_TYPE_TIME`, `SUB_ENUM_ORDER_TYPE_FILLING`, `SUB_ENUM_ORDER_REASON`, `SUB_ENUM_DEAL_ENTRY`, `SUB_ENUM_DEAL_REASON` |
| `on_trade_transaction` | 0 / 9 | `MT5_SUB_ENUM_EVENT_GROUP_TYPE` (`type`); in `MqlTradeTransaction`: `SUB_ENUM_TRADE_TRANSACTION_TYPE`, `SUB_ENUM_ORDER_TYPE`, `SUB_ENUM_ORDER_STATE`, `SUB_ENUM_DEAL_TYPE`, `SUB_ENUM_ORDER_TYPE_TIME`; in `MqlTradeRequest`: `SUB_ENUM_TRADE_REQUEST_ACTIONS`, `SUB_ENUM_ORDER_TYPE`, `SUB_ENUM_ORDER_TYPE_FILLING`, `SUB_ENUM_ORDER_TYPE_TIME`; in `MqlTradeResult`: `MqlErrorTradeCode` |

---

## ⚠️ Special cases

1. **Result enums — `SYMBOL_SECTOR` / `SYMBOL_INDUSTRY`.** Most selectors just *pick* a property, but two `SymbolInfoIntegerProperty` selectors return a value that is **itself** an enum code: `symbol_info_integer(symbol, :SYMBOL_SECTOR)` returns a `BMT5_ENUM_SYMBOL_SECTOR` value (14 of them) and `:SYMBOL_INDUSTRY` returns a `BMT5_ENUM_SYMBOL_INDUSTRY` value (152). The low-level call hands it back as a plain `int64`, so map the number yourself — `ruby examples/demos/helpers/17_protobuf_inspector.rb enum BMT5_ENUM_SYMBOL_INDUSTRY`. The same values arrive **already typed** on `SymbolParameters.sector` / `.industry` from `symbol_params_many`.
2. **`returned_code` is not an enum.** On trade results it's a plain `uint32` (though its *names* live in the `MqlErrorTradeCode` enum). See [Return Codes](./RETURN_CODES_REFERENCE.md).

---

## See Also

- [1 · Account Information](../MT5Account/1.%20Account_Information/Account_Information.Overview.md)
- [2 · Symbol Information](../MT5Account/2.%20Symbol_Information/Symbol_Information.Overview.md)
- [3 · Positions & Orders](../MT5Account/3.%20Position_Orders_Information/Position_Orders_Information.Overview.md)
- [4 · Trading Operations](../MT5Account/4.%20Trading_Operations/Trading_Operations.Overview.md)
- [5 · Market Depth (DOM)](../MT5Account/5.%20Market_Depth(DOM)/Market_Depth.Overview.md)
- [7 · Streaming Methods](../MT5Account/7.%20Streaming_Methods/Streaming_Methods.Overview.md)
- [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md) · [Return Codes](./RETURN_CODES_REFERENCE.md)
