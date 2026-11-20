# Your First Project

> Build a small, complete RubyMT5 script: connect, quote, trade with risk sizing, and report.

---

## 1 · Set up

```bash
mkdir mt5-bot && cd mt5-bot
```

Point Bundler at the repo (the gem isn't on RubyGems), then install:

```ruby
# Gemfile
source "https://rubygems.org"
gem "metarpc_mt5", git: "https://github.com/MetaRPC/RubyMT5.git"
gem "grpc", "~> 1.84.1" if Gem.win_platform?   # Windows: prebuilt binary
```

```bash
bundle install
```

Create `bot.rb`. (Prefer the ready-made examples? `git clone` the repo and read `examples/demos/` — see [Getting Started](./GETTING_STARTED.md).)

---

## 2 · Connect

```ruby
require "metarpc_mt5"

mt5 = MetaRPC::MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"])
mt5.quick_connect(
  ENV["MT5_LOGIN"].to_i,
  ENV["MT5_PASSWORD"],
  ENV["MT5_SERVER"],          # e.g. MetaQuotes-Demo
)
puts "connected? #{mt5.connected?}"
```

> Need the `MRPC_API_KEY`? Register at [https://mrpc.pro/signup](https://mrpc.pro/signup) — your key is provisioned automatically and shown in the [MT5 Client API Explorer](https://mrpc.pro/explorer/mt5-client) (*Copy key*). See [Getting Started → API Key](./GETTING_STARTED.md). (Or pass `"TRIAL"` for keyless access while testing.)

---

## 3 · Look at the market

```ruby
symbol = "EURUSD"
q = mt5.price(symbol)
pips = (q.spread / mt5.symbol_point(symbol) / 10).round(1)
puts "#{symbol}  bid #{q.bid}  ask #{q.ask}  #{pips} pips"
```

---

## 4 · Trade with risk sizing

```ruby
digits = mt5.symbol_digits(symbol)
pip    = mt5.symbol_point(symbol) * 10          # 1 pip on a 5-digit symbol
sl     = (q.bid - 20 * pip).round(digits)       # 20-pip stop
tp     = (q.ask + 40 * pip).round(digits)       # 40-pip target

# Size so the 20-pip stop risks ~1% of balance:
loss_per_01 = -mt5.calc_profit(symbol, 0.1, q.ask, sl)        # loss on 0.1 lot if stopped
lots = [(0.1 * (mt5.balance * 0.01) / loss_per_01).round(2), 0.01].max

# Can we afford the margin?
if mt5.required_margin(symbol, lots, q.ask) > mt5.free_margin
  abort "not enough free margin for #{lots} lots"
end

r = mt5.buy_market_with_sl_tp(symbol, lots, sl: sl, tp: tp, comment: "first-project")
puts r.returned_code == 10_009 ? "opened ##{r.order} with #{lots} lots" : r.returned_code_description
```

---

## 5 · Manage & report

```ruby
puts "open positions: #{mt5.count_positions}"
puts "floating P/L: #{mt5.total_profit.round(2)}"

# tidy up for the demo
mt5.close_all_positions

# today's realized result
from = Time.now.utc - 24 * 3600
deals = mt5.order_history(from_utc: from).filter_map { |h| h.history_deal }
puts "today: #{deals.size} deals, net #{deals.sum(&:profit).round(2)}"
```

---

## 6 · Run it

```bash
MT5_LOGIN=5057947437 MT5_PASSWORD=secret MT5_SERVER=MetaQuotes-Demo \
MRPC_API_KEY=YOUR_KEY bundle exec ruby bot.rb
```

---

## Where to go next

* Stream live prices → [gRPC Streaming](./GRPC_STREAM_MANAGEMENT.md).
* Strategy loops → [Strategies](../Strategies/Strategies.Master.Overview.md).
* Full helper list → [MT5Sugar API](../MT5Sugar/MT5Sugar.API_Overview.md).
