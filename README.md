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
```

Runtime dependencies: `grpc`, `google-protobuf` (>= 4.26), `googleapis-common-protos-types` (prebuilt
binaries exist for Windows x64 and x86_64-linux; Ruby >= 3.1). `require "metarpc_mt5"` loads
`MetaRPC::MT5::Client` and the generated `Mt5TermApi::*` gRPC messages. See `FLEET_AUDIT.md` for every
verified call signature.

---

## 🏃 How to Run Examples

Clone the repository and run the quickstart example out-of-the-box:

```bash
git clone https://github.com/MetaRPC/RubyMT5.git
cd RubyMT5
bundle install

# 1. Run with default TRIAL key:
bundle exec ruby examples/quickstart.rb

# 2. Or pass your MetaRPC API key directly as an argument:
bundle exec ruby examples/quickstart.rb your_api_key_here

# 3. Or use the MRPC_API_KEY environment variable:
export MRPC_API_KEY="your_api_key_here"        # Windows CMD: set MRPC_API_KEY=your_api_key_here
bundle exec ruby examples/quickstart.rb        # Windows PowerShell: $env:MRPC_API_KEY="your_api_key_here"
```

---

## 🔑 API Key & Authentication

Connecting to MetaRPC production endpoints (`mt5.mrpc.pro:443`) requires an API key:

1. **Sign Up**: Create an account for free at [https://mrpc.pro/signup](https://mrpc.pro/signup).
2. **Generate API Key**: In your MetaRPC Portal dashboard at [https://mrpc.pro/my](https://mrpc.pro/my), go to **API Keys** to generate and copy your personal API token.
3. **Configure Connection**: Pass your API key / token along with the server address (`mt5.mrpc.pro:443`) in your connection settings.

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
