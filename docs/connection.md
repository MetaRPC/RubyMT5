# Connection & Authentication

Managing MT5 sessions with `MetaRPC::MT5::Client`.

```ruby
require 'metarpc_mt5'

client = MetaRPC::MT5::Client.new('mt5.broker.com', 443)
client.connect(2005432, 'password')

if client.connected?
  puts "Online and ready!"
end

client.disconnect
```
