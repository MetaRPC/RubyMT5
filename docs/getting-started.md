# Getting Started with RubyMT5

## Prerequisites
- **Ruby 2.7+**
- Bundler

## Quickstart Example

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


> **Authentication Note**: Connecting to `mt5.mrpc.pro:443` requires a valid MetaRPC API key. Register for free at [https://mrpc.pro/signup](https://mrpc.pro/signup) and generate your token in [https://mrpc.pro/my](https://mrpc.pro/my).

