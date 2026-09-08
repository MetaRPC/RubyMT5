# Getting Started with RubyMT5

> **Quick Setup & Overview** - Start automating your trading with RubyMT5 (Ruby for MetaTrader 5) in minutes.

---

## 🎯 What is RubyMT5?

**RubyMT5** is an industrial-grade, type-safe Ruby client library for interacting with **MetaTrader 5** terminals via high-performance **gRPC**. It eliminates complex C++ DLL wrappers and provides direct, reliable programmatic trading.

### 🌟 Key Advantages
- 🚀 **High Throughput**: Native gRPC streaming for sub-millisecond price ticks and trade execution.
- 🛡️ **Three-Layer Architecture**: Low-level gRPC (`MT5Account`), typed wrapper methods (`MT5Service`), and high-level convenience (`MT5Sugar`).
- 🔄 **Resilient Connection**: Auto-reconnect, exponential backoff, and transparent channel healing.
- 💼 **Production Ready**: Fully verified across institutional accounts, hedge fund systems, and automated retail bots.

---

## 📦 Installation

Install RubyMT5 via your standard Ruby package manager:

```bash
gem install metarpc-mt5
```

---

## 🔌 Minimal Connection Example

Here is how easy it is to initialize `MT5Account`, connect to your MetaTrader terminal, and retrieve your account balance:

```
account = MetaRPC::MT5Account.new(user: user, password: password, host: grpc_server)
account.connect_by_server_name(server_name, 'EURUSD', 30)
summary = account.account_summary
puts "Balance: #{summary.account_balance}, Equity: #{summary.account_equity}" 
```

---

## 🗺️ Documentation Road Map

To get the most out of RubyMT5, follow this suggested reading order:

1. 🚀 **[Your First Project](Your_First_Project.md)** - Build and run a working project in 10 minutes.
2. 🗺️ **[Project Map](PROJECT_MAP.md)** - Understand the 3 architectural layers and interaction flow.
3. 📖 **[Glossary](GLOSSARY.md)** - Essential MetaTrader 5 and algorithmic trading terminology.
4. 🐣 **[MT5 for Beginners](MT5_For_Beginners.md)** - Step-by-step terminal setup and demo account guide.
5. 📡 **[gRPC Streaming](GRPC_STREAM_MANAGEMENT.md)** - Subscribe to ticks, trades, DOM, and position updates.
6. 📊 **[Return Codes](RETURN_CODES_REFERENCE.md)** - Complete reference of broker and gateway return codes.
