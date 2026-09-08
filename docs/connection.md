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

