# API Reference

### `MetaRPC::MT5::Client`
- `initialize(host, port = 443)`
- `connect(login, password)`
- `disconnect`
- `connected?`
- `account_info`
- `subscribe_quotes(symbols, &block)`
- `order_send(symbol:, action:, volume:, price:, stop_loss:, take_profit:, comment:)`
- `order_modify(ticket:, stop_loss:, take_profit:)`
- `order_close(ticket:, volume:)`
