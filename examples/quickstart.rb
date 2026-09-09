require "metarpc_mt5"

# Initialize client with production server and API key from https://mrpc.pro/signup
api_key = ENV["MRPC_API_KEY"] || "YOUR_API_KEY_HERE"
client = MetaRPC::MT5::Client.new("mt5.mrpc.pro", 443, api_key: api_key)

login = 2005432
password = "demo_password"

puts "Connecting to MetaTrader 5 (mt5.mrpc.pro:443)..."
if client.connect(login, password)
  puts "Connected successfully! Account ID: #{client.id}"

  puts "\nStep 1: Query Account Info..."
  acc = client.account_info
  puts "Account: #{acc[:login]} (#{acc[:name]})"
  puts "Account Balance: #{acc[:balance]} #{acc[:currency]}"

  puts "\nStep 2: Execute Market Order..."
  order = client.order_send(
    symbol: "EURUSD",
    action: :buy,
    volume: 0.1,
    comment: "Ruby MT5 Bot"
  )
  puts "Order executed! Deal: ##{order[:deal]} Ticket: ##{order[:ticket]}"

  client.disconnect
  puts "\nDisconnected."
end
