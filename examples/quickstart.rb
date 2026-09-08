require "metarpc_mt5"

client = MetaRPC::MT5::Client.new("mt5.broker.com", 443)

puts "Connecting to MT5..."
if client.connect(2005432, "password")
  puts "Connected!"

  acc = client.account_info
  puts "Account Balance: #{acc[:balance]} #{acc[:currency]}"

  order = client.order_send(
    symbol: "EURUSD",
    action: :buy,
    volume: 0.1,
    comment: "Ruby MT5 Bot"
  )
  puts "Order executed! Deal: ##{order[:deal]} Ticket: ##{order[:ticket]}"
end
