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



---

## 🆔 Account ID Generation (`GetId`)

> ⚠️ **Important**: You must generate your deterministic account ID with `GetId` **firstly** before connecting or streaming.

MetaRPC endpoints require two essential credentials for all operations:
1. **`APIKey`**: Your personal authentication token from [https://mrpc.pro/my](https://mrpc.pro/my) (obtained by registering at [https://mrpc.pro/signup](https://mrpc.pro/signup)). Sent in the `APIKey` header.
2. **`id`**: A deterministic account GUID generated from your MetaTrader `user` (login number) and `password`. The same credentials always produce the exact same GUID.

### Calling GetId

#### Via REST API:
```bash
curl -X GET "https://mt5.mrpc.pro/GetId?user=YOUR_LOGIN&password=YOUR_PASSWORD" \
     -H "APIKey: YOUR_API_KEY"
```

Response:
```json
{
  "data": {
    "id": "e8d91060-c3d3-4f4d-8d2a-9e1b2c3d4e5f"
  }
}
```

#### Via gRPC:
Send a `GetIdRequest` with `user` and `password` to the connection service before calling `ConnectEx`.

Use this returned `id` GUID in the `id` header or session parameter for `ConnectEx`, `AccountSummary`, and all other terminal operations.
