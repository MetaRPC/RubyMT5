# RubyMT5 SDK

> Idiomatic Ruby gem SDK for MetaTrader 5 algorithmic trading automation.

> **Note:** releases before October 2026 were a preview whose `Client` returned simulated values (a fixed balance, made-up order tickets). `MetaRPC::MT5::Client` is now a real TLS gRPC client against `mt5.mrpc.pro:443` (connect, account summary, quotes, bars, tick streams, orders, history), verified live on a demo account; see `FLEET_AUDIT.md` for every call signature. The [REST API](https://mrpc.pro/docs-legacy/mt5-client-api) remains available as well.

[![Docs](https://img.shields.io/badge/docs-RubyMT5-blue.svg)](https://metarpc.github.io/RubyMT5/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

📄 **Full Documentation**: [https://metarpc.github.io/RubyMT5/](https://metarpc.github.io/RubyMT5/)

---

## 📦 Installation

The gem is not published on rubygems. Get it from the repository and reference it by path from your `Gemfile`:

```bash
git clone https://github.com/MetaRPC/RubyMT5.git
```

```ruby
source "https://rubygems.org"
gem "metarpc_mt5", path: "/path/to/RubyMT5"
gem "grpc", "~> 1.84.1" if Gem.win_platform?   # Windows: pin to the last version with a prebuilt binary
```

Runtime dependencies: `grpc` (>= 1.60), `google-protobuf` (>= 4.26), `googleapis-common-protos-types`
(>= 1.4); Ruby >= 3.1. `require "metarpc_mt5"` loads the three layers — `MetaRPC::MT5::MT5Account`
→ `MT5Service` → `MT5Sugar` (alias `Client`) — and the generated `Mt5TermApi::*` gRPC messages.
See `FLEET_AUDIT.md` for every verified call signature.

> 🪟 **Windows:** the `grpc` gem ships a prebuilt binary (`x64-mingw-ucrt`) only **through 1.84.1** —
> 1.85.0+ is source-only and needs a full C/C++ build toolchain. Pin it in **your** Gemfile as shown
> above, or `bundle install` will try (and fail) to compile grpc from source.

---

## 🧱 Architecture & first call

RubyMT5 is three decoupled layers — enter at whichever level you need, and drop down when a one-liner is too narrow:

- **`MT5Sugar`** — high-level one-liners (`buy_market`, `close_all_positions`, risk sizing). Alias `Client`.
- **`MT5Service`** — typed facade: plain args in, Ruby Structs out (`Quote`, `Account`).
- **`MT5Account`** — raw gRPC: protobuf in/out, connect/session, reconnect, streaming. Alias `Account`.

```ruby
require "metarpc_mt5"
MT5 = MetaRPC::MT5

mt5 = MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
mt5.connect(5057947437, "password", server: "MetaQuotes-Demo")

a = mt5.account_info                 # high: Struct(login, balance, currency, …)
q = mt5.price("EURUSD")              # mid (via sugar): Quote(bid, ask, spread)
r = mt5.buy_market("EURUSD", 0.01)   # trade — returns OrderSendData; 10009 = done
puts "#{a.balance} #{a.currency} · #{q.bid}/#{q.ask} · #{r.returned_code}"

mt5.service   # reach the typed facade   (MT5Service)
mt5.account   # reach the raw gRPC layer (MT5Account)
```

See the [full docs](https://metarpc.github.io/RubyMT5/) for every method, and the [Project Map](https://metarpc.github.io/RubyMT5/All_Guides/PROJECT_MAP/) for how the layers fit together.

---

## 🏃 How to Run Examples

Clone the repository, install, and run. The quickstart connects to a **demo account**, so it needs an
API key **and** a login / password / server:

```bash
git clone https://github.com/MetaRPC/RubyMT5.git
cd RubyMT5
bundle install

# quickstart.rb — pass the API key as ARGV[0] or MRPC_API_KEY; login/password/server via env:
MRPC_API_KEY=your_api_key MT5_LOGIN=5057947437 MT5_PASSWORD=your_password MT5_SERVER=MetaQuotes-Demo \
  bundle exec ruby examples/quickstart.rb

# the interactive demo suite (15 demos across all three layers):
ruby examples/demos/main.rb          # menu
ruby examples/demos/main.rb 6        # run demo 6 (sugar basics) directly
```

```powershell
# Windows PowerShell:
$env:MRPC_API_KEY="your_api_key"; $env:MT5_LOGIN="5057947437"
$env:MT5_PASSWORD="your_password"; $env:MT5_SERVER="MetaQuotes-Demo"
bundle exec ruby examples/quickstart.rb
```

> Demo credentials (login / password / server) come from the MetaRPC Portal or the one-click
> **[$1 demo in the MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client)**. The demos can also
> read `examples/demos/config/config.json` instead of env vars.

---

## 🔑 API Key & Authentication

Connecting to MetaRPC production endpoints (`mt5.mrpc.pro:443`) requires an API key:

1. **Sign Up**: Create an account for free at [https://mrpc.pro/signup](https://mrpc.pro/signup).
2. **Copy your key**: It's **provisioned automatically** — nothing to generate. Open the [MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client) (or the [Portal](https://mrpc.pro/my)) and copy the key shown at the top. For a keyless first look you can also pass the literal value `"TRIAL"`.
3. **Use it**: Pass the key to `MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ...)`, or set the `MRPC_API_KEY` environment variable.

---

## 🆔 Automatic Account ID & Authentication

MetaRPC endpoints route calls using a terminal session identifier (`id`):
- When connecting via `Connect` / `ConnectEx`, the server automatically generates and returns a session GUID (`terminalInstanceGuid`).
- The SDK automatically captures this session ID and attaches both the `id` and `APIKey` headers on all subsequent calls (`AccountSummary`, `OrderSend`, streaming, etc.) — no manual `GetId` or `curl` calls required.
- Pass your API key directly to the Account/Client constructor or via the `MRPC_API_KEY` environment variable.

## 🌐 Production Endpoints

| Environment | Host | Port | Protocol |
| :--- | :--- | :--- | :--- |
| **Production** | `mt5.mrpc.pro` | `443` | TLS / gRPC |
| **Direct API UI (Swagger)** | `https://mt5.mrpc.pro/apiui` | `443` | HTTPS |
| **Portal Dashboard** | `https://mrpc.pro/my` | `443` | HTTPS |
| **Registration / API Key** | `https://mrpc.pro/signup` | `443` | HTTPS |

---

## 📄 Documentation & Guides

Explore comprehensive documentation at [https://metarpc.github.io/RubyMT5/](https://metarpc.github.io/RubyMT5/):
- 🚀 **Quick Start & First Project**
- 🔑 **Authentication & API Keys**
- 📡 **Live Market Data & gRPC Streaming**
- 💼 **Account Management & Order Execution**
- 📊 **Return Codes & Error Handling Reference**
