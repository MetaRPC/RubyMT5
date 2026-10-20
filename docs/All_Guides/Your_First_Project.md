# Your First Project in 10 Minutes (Ruby)

> **Hands-on Quick Start** - Create a working trading project with MetaTrader 5 and RubyMT5 from scratch.

---

## Step 0: Obtain Your API Key

To connect to MetaRPC endpoints (`mt5.mrpc.pro:443`), obtain your API key:
1. Register for free at [https://mrpc.pro/signup](https://mrpc.pro/signup).
2. Generate your API token in your dashboard at [https://mrpc.pro/my](https://mrpc.pro/my).
3. Set your token in your environment or connection config.

---

## Step 1: Create Your Project

Create a new directory for your trading bot:

```bash
mkdir my_rubymt5_bot
cd my_rubymt5_bot
```

Get the SDK (it is not on a package registry):

```bash
git clone https://github.com/MetaRPC/RubyMT5.git
```

---

## Step 2: Write Your Trading Code

Create your main application file and paste the following snippet:

```ruby
require 'metarpc_mt5'

# One stable terminal id per account/strategy: the gateway keeps one terminal per id.
terminal_id = MetaRPC::MT5::Client.uuid5(MetaRPC::MT5::Client::NAMESPACE_DNS, 'my-first-bot')
client = MetaRPC::MT5::Client.new('mt5.mrpc.pro', 443, api_key: ENV['MRPC_API_KEY'], id: terminal_id)

puts 'Connecting...'
client.connect(2005432, 'my_pass', server: 'MetaQuotes-Demo')
puts 'Connected!'

acc = client.account_summary
puts "Account Balance: #{acc.account_balance} #{acc.account_currency}"

# Open 0.01 Buy (only on a demo account)
if acc.account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO
  order = client.order_send(symbol: 'EURUSD', type: :buy, volume: 0.01, comment: 'Ruby MT5 Quickstart')
  if order.returned_code == 10_009
    puts "Order executed! Deal ##{order.deal} Ticket ##{order.order}"
  else
    puts "Rejected: #{order.returned_code} #{order.returned_string_code}"
  end
end
```

---

## Step 3: Run the Program

Run your application:

```bash
bundle install
MRPC_API_KEY=... MT5_LOGIN=... MT5_PASSWORD=... MT5_SERVER=MetaQuotes-Demo bundle exec ruby examples/quickstart.rb
```

Run it from the cloned repository: its `examples/quickstart` does the same thing.

---

## 🚀 Next Steps

Congratulations! You have successfully established a direct gRPC connection to MetaTrader 5. Next:
- Explore **[gRPC Streaming](GRPC_STREAM_MANAGEMENT.md)** to listen to live ticks.
- Check the **[API Reference](../API_Reference/MT5Account.md)** for all 40+ available terminal methods.
- Learn about high-level risk management and auto-normalization in **[MT5Sugar](../API_Reference/MT5Sugar.md)**.
