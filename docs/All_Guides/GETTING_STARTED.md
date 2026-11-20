# Getting Started with RubyMT5

> **Quick setup** — connect to MetaTrader 5 from Ruby in a few minutes.

---

## What is RubyMT5?

**RubyMT5** is a Ruby client for MetaTrader 5 accounts over the MetaRPC gRPC API (`mt5.mrpc.pro:443`). It's organised in **three layers** you can mix freely:

* **[MT5Account](../MT5Account/MT5Account.Master.Overview.md)** — raw gRPC, protobuf in/out, full control.
* **[MT5Service](../MT5Service/MT5Service.Overview.md)** — typed Ruby Structs, plain arguments.
* **[MT5Sugar](../MT5Sugar/MT5Sugar.API_Overview.md)** — one-line helpers.

See the [Project Map](./PROJECT_MAP.md) for how they fit together. (`MetaRPC::MT5::Client` aliases `MT5Sugar`.)

---

## Install & downloads

Two ways to use RubyMT5 — take **our ready-made project**, or take **only the protocol** and build your own client.

### 1 · Take our project (recommended)

The complete thing we built: the three layers (`MT5Sugar` / `MT5Service` / `MT5Account`), the error/stream helpers, and the generated stubs — all wired together as the `metarpc_mt5` gem.

* **Just the library**, for your own app — the gem isn't on RubyGems, so point Bundler at the repo:

  ```ruby
  # Gemfile
  gem "metarpc_mt5", git: "https://github.com/MetaRPC/RubyMT5.git"
  ```

  ```bash
  bundle install
  ```

  Then `require "metarpc_mt5"`. Brings the SDK **and** the protobuf stubs (under the gem's `package/`).

* **The full repo** (adds the runnable `examples/demos/` and the tests):

  ```bash
  git clone https://github.com/MetaRPC/RubyMT5.git
  cd RubyMT5
  bundle install
  ruby examples/demos/main.rb 6     # run a demo (6 = sugar basics)
  ```

> 🎓 **New here? Start with the full repo (the `git clone` above).** You get all **three layers** side by side (`MT5Account` → `MT5Service` → `MT5Sugar`) and ready-made **examples written on each of them** that you can run and read. Learn the SDK this way first — only once you're comfortable should you consider building your own from the raw protos (option 2 below).

> 🪟 **Windows note.** The `grpc` gem ships prebuilt binaries for Windows (`x64-mingw-ucrt`) only through **1.84.1** — newer versions are source-only and need a full build toolchain. On Windows, pin it in your Gemfile: `gem "grpc", "~> 1.84.1"`. (The repo's Gemfile already does this.)

### 2 · Take only the protos and build it yourself (raw gRPC)

**For advanced use — after you know the SDK.** Skip our layers and talk to the gateway from the generated stubs directly. The stubs ship in the **`package/`** folder (`mt5-term-api-*_pb.rb`, `*_services_pb.rb`, and `mrpc-mt5-error_pb.rb`).

**Download just the `package/` folder** (not the whole repo) — any of these:

```bash
# A) quickest — grab only the subfolder (no git history)
npx degit MetaRPC/RubyMT5/package package

# B) pure git — sparse-checkout only package/
git clone --depth 1 --filter=blob:none --no-checkout https://github.com/MetaRPC/RubyMT5.git
cd RubyMT5 && git sparse-checkout set --no-cone 'package/**' && git checkout

# C) via Bundler — then copy the folder out of the installed gem
bundle install          # with the Gemfile git source above
cp -r "$(bundle show metarpc_mt5)/package" ./package
```

Then install the gRPC + protobuf runtime next to it:

```bash
gem install grpc -v 1.84.1 google-protobuf googleapis-common-protos-types
```

Put `package/` on the load path and require the service stubs:

```ruby
$LOAD_PATH.unshift(File.expand_path("package", __dir__))
require "mt5-term-api-market-info_services_pb"   # etc.
```

The raw **`.proto`** sources (to regenerate stubs for another language or version) are on the **[MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client)** → *Download MT5 Protos*.

> ⚠️ **The stubs are not standalone — take the whole `package/` folder, not single files.** Each `*_pb.rb` cross-requires its siblings (e.g. `mrpc-mt5-error_pb`) by bare name, so `package/` must be on `$LOAD_PATH`. This path gives you **raw gRPC with no 3-layer SDK** — see the [Protobuf Inspector](./PROTOBUF_INSPECTOR_GUIDE.md).

---

## 🔑 API Key & Authentication

Connecting to the MetaRPC production endpoint (`mt5.mrpc.pro:443`) uses a personal **API key** — you get one just by registering on our site:

1. **Sign up** — create a free account at **[https://mrpc.pro/signup](https://mrpc.pro/signup)**.
2. **Copy your key** — it's **provisioned automatically**; open the **[MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client)** and your key is shown at the top (*Active* · **Copy key**). Nothing to generate.
3. **Use it** — pass the key to `MT5Sugar.create(host, port, api_key:)` (or set the `MRPC_API_KEY` environment variable instead of hard-coding it).

You'll also need an MT5 **demo** account (login / password / server, e.g. `MetaQuotes-Demo`) — see [MT5 for Beginners](./MT5_For_Beginners.md) to create one (one click for $1, or free via the MT5 terminal).

> 💡 **`TRIAL` / keyless.** No account yet? Pass the literal value `"TRIAL"` as the key to connect for a first look. Your own key — free from sign-up — is for normal use.

### 🆔 Session ID is automatic

You never call `get_id` or supply an `id` header. On `connect` / `connect_ex` the server generates a terminal session GUID (`terminal_instance_guid`) and the SDK attaches it — alongside your API key — to every later request and stream automatically. Prefer passing a **stable `id:`** per strategy so the gateway reuses one terminal.

---

## Connect & read the account

```ruby
require "metarpc_mt5"

mt5 = MetaRPC::MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
mt5.connect(5057947437, "password", server: "MetaQuotes-Demo")

a = mt5.account_info
puts "##{a.login} — #{a.balance} #{a.currency} · 1:#{a.leverage}"
```

Prefer environment variables? Set `MT5_LOGIN` / `MT5_PASSWORD` / `MT5_SERVER` and read them into `mt5.quick_connect(login, password, server)`.

---

## A first trade (demo)

```ruby
r = mt5.buy_market("EURUSD", 0.01)          # tiny demo position
puts r.returned_code == 10_009 ? "opened ##{r.order}" : r.returned_code_description

pos = mt5.open_positions(symbol: "EURUSD").max_by(&:ticket)
mt5.close_position(pos.ticket) if pos
```

Trading one-liners return the result `*Data` — check **`returned_code` (`10009` = DONE)**. A hard failure raises `MetaRPC::MT5::ApiError` (and a transport failure after the request may have reached the terminal raises a `TradeOutcomeUnknown`-marked error — don't blindly retry). See [Return Codes & the error model](./RETURN_CODES_REFERENCE.md).

---

## Dropping down a layer

Need something the sugar layer doesn't expose? Go down:

```ruby
service = mt5.service   # MT5Service — typed Structs
account = mt5.account   # MT5Account — raw protobuf

q    = service.quote("EURUSD")             # Quote(bid, ask, spread, …)
tick = account.symbol_info_tick("EURUSD")  # raw MrpcMqlTick
```

---

## Next

* [Your First Project](./Your_First_Project.md) — build a small script end to end.
* [MT5 for Beginners](./MT5_For_Beginners.md) — the trading concepts.
* [MT5Sugar API](../MT5Sugar/MT5Sugar.API_Overview.md) — every helper.
* [Project Map](./PROJECT_MAP.md) — how the three layers fit together.
