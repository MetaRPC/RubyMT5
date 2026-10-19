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

client = MetaRPC::MT5::Client.new('mt5.mrpc.pro', 443)

puts 'Connecting...'
client.connect(2005432, 'my_pass')
puts 'Connected!'

acc = client.account_info
puts "Account Balance: #{acc[:balance]} #{acc[:currency]}"

# Open 0.01 Buy
order = client.order_send(
  symbol: 'EURUSD',
  action: :buy,
  volume: 0.01,
  comment: 'Ruby MT5 Quickstart'
)

puts "Order executed! Deal ##{order[:deal]} Ticket ##{order[:ticket]}"
```

---

## Step 3: Run the Program

Run your application:

```bash
bundle install
bundle exec ruby examples/quickstart.rb
```

Run it from the cloned repository: its `examples/quickstart` does the same thing.

---

## 🚀 Next Steps

Congratulations! You have successfully established a direct gRPC connection to MetaTrader 5. Next:
- Explore **[gRPC Streaming](GRPC_STREAM_MANAGEMENT.md)** to listen to live ticks.
- Check the **[API Reference](../API_Reference/MT5Account.md)** for all 40+ available terminal methods.
- Learn about high-level risk management and auto-normalization in **[MT5Sugar](../API_Reference/MT5Sugar.md)**.
