# 🗺️ Project Map

> The whole project as one annotated tree, with links. **Links point to section *overviews*, never individual method pages** — open an overview to drill down into its methods. The API layers live here and on the [home page](../index.md) cards (they're intentionally kept out of the left sidebar).

---

## 🧱 The three layers

RubyMT5 is built in three decoupled layers. Your code can enter at any level, and each layer **owns** the one beneath it (`sugar.service` → the `MT5Service`, `service.account` → the `MT5Account`). `MetaRPC::MT5::Client` aliases `MT5Sugar`; `Account` aliases `MT5Account`.

| Layer | Source | What it does | Overview |
| ----- | ------ | ------------ | -------- |
| **3 · MT5Sugar** | `lib/metarpc_mt5/mt5_sugar.rb` | One-line helpers: `buy_market`, `close_all_positions`, risk sizing, SL/TP. 13 groups. | [MT5Sugar overview](../MT5Sugar/MT5Sugar.API_Overview.md) |
| **2 · MT5Service** | `lib/metarpc_mt5/mt5_service.rb` | Typed facade: plain args in, typed Ruby Structs out (`Account`, `Quote`). No protobuf. 6 groups. | [MT5Service overview](../MT5Service/MT5Service.Overview.md) |
| **1 · MT5Account** | `lib/metarpc_mt5/mt5_account.rb` | Low-level gRPC: protobuf request/reply, connect/session, reconnect, streaming. Everything builds on it. 7 groups. | [MT5Account overview](../MT5Account/MT5Account.Master.Overview.md) |

```
Your code  →  MT5Sugar  →  MT5Service  →  MT5Account  →  gRPC  →  mt5.mrpc.pro:443  →  MT5 terminal
```

---

## 🌳 Repository tree

- **`RubyMT5/`** — repo root (the `metarpc_mt5` gem + runnable demos + docs)
  - **`lib/`** — the gem's Ruby source
    - `metarpc_mt5.rb` — entry point: requires all layers; defines `MetaRPC::MT5`
    - `metarpc_mt5/mt5_account.rb` — **Layer 1** → [MT5Account overview](../MT5Account/MT5Account.Master.Overview.md)
    - `metarpc_mt5/mt5_service.rb` — **Layer 2** (+ `Account` / `Quote` Structs) → [MT5Service overview](../MT5Service/MT5Service.Overview.md)
    - `metarpc_mt5/mt5_sugar.rb` — **Layer 3** (+ `Client` / `Account` aliases) → [MT5Sugar overview](../MT5Sugar/MT5Sugar.API_Overview.md)
    - `metarpc_mt5/errors.rb` — `ApiError` / `InvalidLoginError` / `TradeOutcomeUnknown` → [Return Codes & errors](./RETURN_CODES_REFERENCE.md)
    - `metarpc_mt5/subscription.rb` — the stream handle (`cancel` / `count` / `error`)
    - `metarpc_mt5/version.rb` — the gem version
  - **`package/`** — generated protobuf stubs (`mt5-term-api-*_pb.rb`, `*_services_pb.rb`) — the raw contract → [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md)
  - **`examples/`** — runnable code → [Getting Started](./GETTING_STARTED.md)
    - `quickstart.rb` — smallest connect-and-trade example
    - **`demos/`** — the demo suite (interactive menu via `main.rb`)
      - `main.rb` — the menu / launcher (`ruby examples/demos/main.rb [N]`)
      - **`config/`** — `config.json` (login/password/server/symbol/volume) · `config.rb` (loads it + env vars)
      - **`helpers/`** — `connection.rb` (loads the SDK, connects, the demo registry)
      - **`lowlevel/`** — raw `MT5Account` → [overview](../MT5Account/MT5Account.Master.Overview.md)
        - `01_general_operations.rb` · `02_trading_operations.rb` · `03_streaming_methods.rb`
      - **`service/`** — typed `MT5Service` → [overview](../MT5Service/MT5Service.Overview.md)
        - `04_service_demo.rb` · `05_service_streaming.rb`
      - **`sugar/`** — one-liner `MT5Sugar` → [overview](../MT5Sugar/MT5Sugar.API_Overview.md)
        - `06_sugar_basics.rb` · `07_sugar_trading.rb` · `08_sugar_positions.rb` · `09_sugar_history.rb` · `10_sugar_advanced.rb`
      - **`orchestrators/`** — strategy loops → [Strategies](../Strategies/Strategies.Master.Overview.md)
        - `11_trailing_stop.rb` · `13_grid_trader.rb` · `14_risk_manager.rb`
      - **`presets/`** — `16_adaptive_preset.rb` (adaptive market mode)
      - **`usercode/`** — `18_usercode.rb` (sandbox for your own snippets)
  - **`test/`** — the `test_client.rb` suite
  - **`docs/`** — this documentation site (mkdocs-material) — see the map below
  - `metarpc_mt5.gemspec` · `Gemfile` · `mkdocs.yml` — gem / docs config

---

## 📚 Documentation tree

- **`docs/`**
  - [Home](../index.md) — landing page (cards into the three layers + Trade Copier)
  - **`All_Guides/`** — the guides in the left nav (Getting Started, MT5 for Beginners, Your First Project, SDK Ecosystem, Glossary, Sync vs Async, gRPC Stream Management, Enums, Return Codes, Protobuf Inspector, UserCode Sandbox)
  - **`MT5Account/`** — low-level gRPC docs → [overview](../MT5Account/MT5Account.Master.Overview.md) *(per-method pages inside)*
  - **`MT5Service/`** — typed facade docs → [overview](../MT5Service/MT5Service.Overview.md) *(per-group pages inside)*
  - **`MT5Sugar/`** — one-liner docs → [overview](../MT5Sugar/MT5Sugar.API_Overview.md) *(per-group pages inside)*
  - **`Strategies/`** — orchestrators & the adaptive preset → [overview](../Strategies/Strategies.Master.Overview.md)
  - `Guide_Images/` · `styles/` · `javascripts/` · `includes/` — assets & theme

> The `MT5Account/`, `MT5Service/` and `MT5Sugar/` folders hold the detail pages but are **not in the left sidebar** — reach them from the home cards or the overview links above. Each overview is the index into its own pages.

---

## 🎮 Running the demos

The demos (laid out in the tree above) run from one menu — pass a number to run one directly:

```bash
ruby examples/demos/main.rb          # interactive menu
ruby examples/demos/main.rb 6        # sugar basics
ruby examples/demos/main.rb 11       # trailing-stop orchestrator
```

Config comes from `examples/demos/config/config.json` or the env vars `MT5_LOGIN` / `MT5_PASSWORD` / `MT5_SERVER` / `MT5_SYMBOL` / `MT5_VOLUME` / `MRPC_API_KEY`.

---

## 🎯 Which layer should you use?

- **Most trading apps → [MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md).** One-liners, risk-based sizing and SL/TP keep your code short and safe.
- **Custom execution → [MT5Service](../MT5Service/MT5Service.Overview.md).** Typed calls when you manage your own flow.
- **Protocol-level control → [MT5Account](../MT5Account/MT5Account.Master.Overview.md).** Raw protobuf requests and streams.
- **New to MT5?** → [MT5 for Beginners](./MT5_For_Beginners.md), then [Getting Started](./GETTING_STARTED.md).
- **Mirror trades to other accounts?** → [SDK Ecosystem → Trade Copier](./SDK_Ecosystem.md).
