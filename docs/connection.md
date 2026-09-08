
## 🆔 Generate Account ID (`GetId`)

> ⚠️ **Important**: You must generate your deterministic account ID with `GetId` **firstly** before connecting or streaming.

Before establishing a connection, call `GetId` with your trading account number and password to obtain your deterministic terminal GUID:

```bash
curl -X GET "https://mt5.mrpc.pro/GetId?user=YOUR_LOGIN&password=YOUR_PASSWORD" \
     -H "APIKey: YOUR_API_KEY"
```

The resulting `id` must be provided as the `id` header alongside `APIKey` for all subsequent operations.


# Connection & Authentication

Managing MT5 sessions with `MetaRPC::MT5::Client`.

```ruby
require 'metarpc_mt5'

client = MetaRPC::MT5::Client.new('mt5.mrpc.pro', 443)
client.connect(2005432, 'password')

if client.connected?
  puts "Online and ready!"
end

client.disconnect
```


> **Authentication Note**: Connecting to `mt5.mrpc.pro:443` requires a valid MetaRPC API key. Register for free at [https://mrpc.pro/signup](https://mrpc.pro/signup) and generate your token in [https://mrpc.pro/my](https://mrpc.pro/my).

