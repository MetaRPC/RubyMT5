# UserCode Sandbox

> Your blank canvas inside the demo suite — `sugar` arrives already connected, so you write only the trading logic.

---

## 🏁 Quick start

1. Open `examples/demos/usercode/18_usercode.rb`.
2. Write your code inside the registered block (below the `write your code below` marker).
3. Run it:

```bash
ruby examples/demos/main.rb 18
```

That's it — the menu connects once, then hands your block a live, connected `sugar`.

The sandbox as it ships:

```ruby
Demos.register("18", "Sandbox - your own code (edit 18_usercode.rb)") do |sugar, cfg|
  sym = cfg.test_symbol

  # ─── write your code below ───
  puts "  balance #{format('%.2f', sugar.balance)}   #{sym} bid #{sugar.bid(sym)}"

  #   q    = sugar.service.quote(sym)
  #   tick = sugar.account.symbol_info_tick(sym)
  #   sugar.buy_market(sym, cfg.test_volume)   # ⚠ trades on a demo account
end
```

> Keep it **read-only** while experimenting, or use tiny volumes on a **demo** account.

---

## 🎁 What's already set up

The block receives two arguments:

| Argument | What it is |
|----------|------------|
| `sugar` | a connected `MT5Sugar` — the high-level one-liners |
| `cfg` | the loaded config: `cfg.test_symbol`, `cfg.test_volume`, `cfg.user`, `cfg.server`, … |

And from `sugar` you can reach every layer:

```ruby
sugar            # MT5Sugar  — one-liners
sugar.service    # MT5Service — typed Structs (Quote, Account)
sugar.account    # MT5Account — raw gRPC / protobuf
```

No `connect` call, no API key handling — the launcher did it. Config comes from `examples/demos/config/config.json` or the `MT5_LOGIN` / `MT5_PASSWORD` / `MT5_SERVER` / `MT5_SYMBOL` / `MT5_VOLUME` env vars.

---

## 🧩 Mixing the three layers

All three are live at once — drop down whenever the sugar layer doesn't expose what you need:

```ruby
# High — MT5Sugar
bal = sugar.balance                       # => Float

# Mid — MT5Service (typed Struct)
q = sugar.service.quote("EURUSD")         # Quote(bid, ask, spread, …)

# Low — MT5Account (raw protobuf)
tick = sugar.account.symbol_info_tick("EURUSD")   # raw MrpcMqlTick
```

---

## 📘 Quick reference (MT5Sugar)

```ruby
# ── Account ──────────────────────────────────────────────
sugar.balance            # Float
sugar.equity             # balance + floating P/L
sugar.free_margin        # available to open more
sugar.margin_level       # %
sugar.account_info       # Struct(login, balance, currency, leverage, …)
sugar.demo?              # true on a demo account

# ── Prices ───────────────────────────────────────────────
sugar.bid("EURUSD")      # Float
sugar.ask("EURUSD")
sugar.spread("EURUSD")
sugar.price("EURUSD")    # Quote(bid, ask, spread, …)

# ── Market orders (return OrderSendData — check returned_code) ──
r = sugar.buy_market("EURUSD", 0.01)
r = sugar.sell_market("EURUSD", 0.01)
r = sugar.buy_market_with_sl_tp("EURUSD", 0.01, sl: 1.0820, tp: 1.0920)

# ── Pending orders ───────────────────────────────────────
sugar.buy_limit("EURUSD", 0.01, 1.0850)
sugar.sell_stop("EURUSD", 0.01, 1.0750)

# ── Positions ────────────────────────────────────────────
sugar.open_positions(symbol: "EURUSD")   # Array
sugar.count_positions
sugar.total_profit
sugar.has_position?("EURUSD")
sugar.close_position(ticket)
sugar.close_all_positions
sugar.close_all_by_symbol("EURUSD")
sugar.modify_sl_tp(ticket, stop_loss: 1.0830, take_profit: 1.0930)

# ── History (needs from_utc:) ────────────────────────────
sugar.order_history(from_utc: Time.now.utc - 24 * 3600)
sugar.positions_history(from_utc: Time.now.utc - 7 * 86_400)

# ── Symbols & risk sizing ────────────────────────────────
sugar.symbol_digits("EURUSD")
sugar.symbol_point("EURUSD")
sugar.min_stop_level("EURUSD")
sugar.required_margin("EURUSD", 0.10, sugar.ask("EURUSD"))
sugar.calc_profit("EURUSD", 0.10, 1.0900, 1.0950)        # type: :buy by default
sugar.max_lot("EURUSD", sugar.ask("EURUSD"))

# ── Streaming (block + Subscription) ─────────────────────
sub = sugar.subscribe_ticks("EURUSD") { |t| puts t.bid }   # sub.cancel to stop
n   = sugar.each_tick("EURUSD", seconds: 5) { |t| puts t.bid }  # blocking
```

Full lists: [MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md) · [MT5Service](../MT5Service/MT5Service.Overview.md) · [MT5Account](../MT5Account/MT5Account.Master.Overview.md).

---

## ✅ Checking a trade

Trade one-liners **return the result data** — they don't raise on a broker rejection. Check `returned_code` (`10009` = done); a hard failure raises `MetaRPC::MT5::ApiError`:

```ruby
begin
  r = sugar.buy_market(sym, cfg.test_volume)
  if r.returned_code == 10_009
    puts "opened ##{r.order} @ #{r.price}"
  else
    puts "rejected: #{r.returned_string_code} — #{r.returned_code_description}"
  end
rescue MetaRPC::MT5::ApiError => e
  raise if e.trade_outcome_unknown?     # uncertain — check positions before retrying
  warn "trade error: #{e.error.mql_error_trade_description}"
end
```

See [Return Codes & the error model](./RETURN_CODES_REFERENCE.md) for the full picture.

---

## 📝 A complete sandbox example

Risk-size a trade to ~1% of balance, open it, then report:

```ruby
Demos.register("18", "Sandbox - your own code") do |sugar, cfg|
  sym = cfg.test_symbol
  q   = sugar.price(sym)
  pip = sugar.symbol_point(sym) * 10
  dig = sugar.symbol_digits(sym)

  sl  = (q.bid - 20 * pip).round(dig)                      # 20-pip stop
  tp  = (q.ask + 40 * pip).round(dig)

  loss_at_01 = -sugar.calc_profit(sym, 0.1, q.ask, sl)     # loss on 0.1 lot if stopped
  lots = [(0.1 * (sugar.balance * 0.01) / loss_at_01).round(2), 0.01].max

  if sugar.required_margin(sym, lots, q.ask) > sugar.free_margin
    puts "  not enough free margin for #{lots} lots"
  else
    r = sugar.buy_market_with_sl_tp(sym, lots, sl: sl, tp: tp)
    puts r.returned_code == 10_009 ? "  opened ##{r.order} (#{lots} lots)" : "  #{r.returned_code_description}"
  end

  puts "  open: #{sugar.count_positions}  floating P/L: #{sugar.total_profit.round(2)}"
end
```

---

## 💡 Tips & common mistakes

1. **Start read-only.** `sugar.balance`, `sugar.price(sym)`, `sugar.open_positions` can't hurt anything — learn the shapes first.
2. **Trade on demo, tiny volumes.** Use `cfg.test_volume` (0.01) and confirm `sugar.demo?` before trading.
3. **Check `returned_code`.** A returned result is *not* proof of success — `10009` is. Catching exceptions alone is not enough.
4. **Don't re-raise an uncertain trade blindly.** On `trade_outcome_unknown?`, check `open_positions` first — the SDK never auto-resends a trade.
5. **Enum values are symbols** (`:ACCOUNT_BALANCE`), not constants — see [ENUMs Reference](./ENUMS_USAGE_REFERENCE.md).
6. **Unsure of a field or enum name?** Ask the [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md).

---

## See Also

- [MT5Sugar API](../MT5Sugar/MT5Sugar.API_Overview.md) · [MT5Service](../MT5Service/MT5Service.Overview.md) · [MT5Account](../MT5Account/MT5Account.Master.Overview.md)
- [Return Codes & errors](./RETURN_CODES_REFERENCE.md) · [ENUMs Reference](./ENUMS_USAGE_REFERENCE.md) · [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md)
- [Your First Project](./Your_First_Project.md) — a standalone script version of the same idea
