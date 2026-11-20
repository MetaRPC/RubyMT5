# Protobuf Inspector — Interactive Type Explorer

> A small offline tool that reads the generated MT5 protobuf stubs and tells you the **real** field names, types and enum values — so you never guess an accessor again.

The generated stubs under `package/*_pb.rb` are the raw contract. When you need to know *"what's the exact accessor on this reply?"* or *"what are the valid values of this enum?"*, the inspector answers from the descriptors themselves — no connection, no API key, no trades.

**Source:** `examples/demos/helpers/17_protobuf_inspector.rb`

---

## 🏁 Running it

It's a standalone helper (it does **not** go through the demo menu, which connects first):

```bash
# interactive REPL
ruby examples/demos/helpers/17_protobuf_inspector.rb

# one-shot — pass a command as arguments, get the answer, exit
ruby examples/demos/helpers/17_protobuf_inspector.rb OnSymbolTickRequest
ruby examples/demos/helpers/17_protobuf_inspector.rb enum TMT5_ENUM_ORDER_TYPE
ruby examples/demos/helpers/17_protobuf_inspector.rb field position_ticket
ruby examples/demos/helpers/17_protobuf_inspector.rb search Tick
```

The REPL opens on a summary of what it discovered:

```
================================================================
MT5 PROTOBUF INSPECTOR (Ruby)
================================================================
  321 message types · 74 enums discovered
  Type 'help' for commands, 'list' to browse, 'exit' to quit.

>
```

> **Offline & safe.** It only `require`s the `package/*_pb.rb` message stubs and reads their descriptors. It never opens a channel. You can run it with no credentials at all.

---

## 🧰 Commands

| Command | What it shows | Example |
|---------|---------------|---------|
| `list [--msg\|--enum]` | all message types and/or enums | `list --enum` |
| `<TypeName>` | a message's fields (name · type · label · #) | `PositionHistoryInfo` |
| `search <text>` | message **and** enum names containing `<text>` | `search Order` |
| `field <name>` | which messages carry a field named `<name>` | `field position_ticket` |
| `findtype <type>` | every field of a proto type, grouped by message | `findtype double` |
| `enum <Name>` | an enum's values (sorted by number) | `enum TMT5_ENUM_ORDER_TYPE` |
| `whereenum <Name>` | which message fields use an enum | `whereenum BMT5_ENUM_ORDER_TYPE` |
| `stats` | type / field / enum counts | `stats` |
| `help` or `?` | the command list | `help` |
| `exit` / `quit` / `q` | leave the REPL | `exit` |

Name lookups are **fuzzy**: exact → case-insensitive exact → a single partial match → otherwise it lists the candidates.

---

## 🔎 Worked examples (real output)

### A message's fields — `<TypeName>`

Fields print as **name · proto-type · label · field-number**. Message/enum fields show their subtype inline (`enum<…>` / `message<…>`):

```
> OnTradeData

TYPE: OnTradeData   (4 fields)
================================================================
  type                       enum<MT5_SUB_ENUM_EVENT_GROUP_TYPE>           (#1)
  event_data                 message<OnTadeEventData>           (#2)
  account_info               message<OnEventAccountInfo>           (#3)
  terminal_instance_guid_id  string                           (#4)
```

The field **name is the accessor** you call in Ruby (`data.event_data`, `data.account_info`). This is how you catch the naming gotchas the stubs hide — for example `TickSizeSymbol` uses PascalCase accessors:

```
> TickSizeSymbol

TYPE: TickSizeSymbol   (7 fields)
================================================================
  Index                 int32                            (#1)
  Name                  string                           (#2)
  TradeTickValue        double                           (#3)   ← t.TradeTickValue, not t.trade_tick_value
  TradeTickValueProfit  double                           (#4)
  TradeTickValueLoss    double                           (#5)
  TradeTickSize         double                           (#6)
  TradeContractSize     double                           (#7)
```

### Which message has a field? — `field <name>`

```
> field position_ticket

FIELD 'position_ticket'
────────────────────────────────────────────────────────────────
exact match in (3): MqlTradeRequest, MqlTradeTransaction, PositionHistoryInfo

partial (2): OnPositionsAndPendingOrdersTicketsData (position_tickets), OpenedOrdersTicketsData (opened_position_tickets)
```

So on a position-history row the accessor is **`position_ticket`**, not `ticket` — the kind of mistake this command ends in seconds.

### An enum's values — `enum <Name>`

```
> enum TMT5_ENUM_ORDER_TYPE

ENUM: TMT5_ENUM_ORDER_TYPE
================================================================
  TMT5_ORDER_TYPE_BUY             = 0
  TMT5_ORDER_TYPE_SELL            = 1
  TMT5_ORDER_TYPE_BUY_LIMIT       = 2
  TMT5_ORDER_TYPE_SELL_LIMIT      = 3
  TMT5_ORDER_TYPE_BUY_STOP        = 4
  TMT5_ORDER_TYPE_SELL_STOP       = 5
  TMT5_ORDER_TYPE_BUY_STOP_LIMIT  = 6
  TMT5_ORDER_TYPE_SELL_STOP_LIMIT = 7
  TMT5_ORDER_TYPE_CLOSE_BY        = 8
```

### Where is an enum used? — `whereenum <Name>`

```
> whereenum BMT5_ENUM_ORDER_TYPE

ENUM 'BMT5_ENUM_ORDER_TYPE' used in (4 fields)
================================================================
  HistoryOrderInfo.type
  OpenedOrderInfo.type
  OrderHistoryData.type
  SymbolParameters.order_mode
```

### All fields of a type — `findtype <type>`

```
> findtype double

FIELDS OF TYPE 'double' (292 in 56 messages)
================================================================
  AccountInfoDoubleData: requested_value
  AccountSummaryData: account_balance, account_equity, account_credit, account_margin, account_margin_free, account_margin_level
  …
```

Valid type names are the proto scalar/compound types: `double`, `float`, `string`, `bool`, `int32`, `int64`, `uint32`, `uint64`, `message`, `enum`.

### Counts — `stats`

```
> stats
================================================================
  message types : 321
  message fields: 1431
  enums         : 74
  enum values   : 989
```

---

## 🧭 The "three order_type enums" gotcha

`search order_type` reveals why a BUY constant that works in one call fails in another — the API has **separate order-type enums per context**:

```
> search order_type
enums (13): … BMT5_ENUM_ORDER_TYPE, ENUM_ORDER_TYPE, ENUM_ORDER_TYPE_TF,
            SUB_ENUM_ORDER_TYPE, TMT5_ENUM_ORDER_TYPE, …
```

| Enum | Use it for |
|------|------------|
| `TMT5_ENUM_ORDER_TYPE` | `order_send` (opening/placing orders) |
| `ENUM_ORDER_TYPE_TF` | calculators / `order_check` (`order_calc_margin`, `order_calc_profit`) |
| `ENUM_ORDER_TYPE` (MQL) | `symbol_info_margin_rate` |
| `SUB_ENUM_ORDER_TYPE` | streaming events (`on_trade`, `on_trade_transaction`) |

When a call rejects your enum, `whereenum <Name>` confirms whether that enum is even accepted by the message you're building. See [ENUMs Reference](./ENUMS_USAGE_REFERENCE.md) for the full picture.

---

## 📦 Common use cases

1. **"`undefined method` on a reply."** Run `<ReplyType>` and read the real field names — e.g. a history row exposes `position_ticket`, not `ticket`.
2. **"What value do I pass for `order_type`?"** `enum TMT5_ENUM_ORDER_TYPE` (and mind the context table above).
3. **"Which request/reply do I need?"** `search <keyword>` lists both messages and enums matching the name.
4. **"Which messages even have this field?"** `field <name>` — exact and partial hits with the real field spelling.
5. **"Where is this enum accepted?"** `whereenum <Name>` before you build the request.

---

## ℹ️ How it works

Ruby's protobuf runtime exposes a **descriptor** on every generated type. The inspector walks the `Mt5TermApi` namespace, classifies each constant as a message (`Google::Protobuf::Descriptor`) or an enum (`Google::Protobuf::EnumDescriptor`), and reads fields (`name`, `type`, `label`, `number`, `subtype`) and enum pairs straight from those descriptors. That's why it's always in sync with the stubs — there's no hand-maintained list to drift.

Because Ruby descriptors carry field numbers, proto types, labels and subtypes, this inspector reports **more** than the raw getter/setter names you'd see in some other SDKs — you get the full field shape.

---

## See Also

* [MT5Account overview](../MT5Account/MT5Account.Master.Overview.md) — the documented API over these stubs
* [ENUMs Reference](./ENUMS_USAGE_REFERENCE.md) — which enum belongs to which call
* [Return Codes & errors](./RETURN_CODES_REFERENCE.md) — `returned_code` and the error model
* [Getting Started → raw gRPC](./GETTING_STARTED.md) — taking only the `package/` stubs

---

**Tip:** reach for the inspector the moment a field or enum name is in doubt — one `field` or `enum` lookup is faster than reading a stub by hand.
