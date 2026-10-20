require "metarpc_mt5"

# MetaRPC MT5 Ruby SDK quickstart (real gRPC calls against mt5.mrpc.pro:443).
#
#   MRPC_API_KEY=... MT5_LOGIN=... MT5_PASSWORD=... MT5_SERVER=MetaQuotes-Demo bundle exec ruby examples/quickstart.rb
#
# Use a STABLE terminal id per account/strategy (uuid5 below): the gateway keeps
# one terminal per id, and a fresh id on every run orphans terminals.

api_key = ARGV[0] || ENV["MRPC_API_KEY"] || abort("set MRPC_API_KEY")
login = (ENV["MT5_LOGIN"] || abort("set MT5_LOGIN")).to_i
password = ENV["MT5_PASSWORD"] || abort("set MT5_PASSWORD")
server = ENV["MT5_SERVER"] || "MetaQuotes-Demo"

terminal_id = MetaRPC::MT5::Client.uuid5(MetaRPC::MT5::Client::NAMESPACE_DNS, "quickstart-#{login}")
client = MetaRPC::MT5::Client.new("mt5.mrpc.pro", 443, api_key: api_key, id: terminal_id)

puts "Connecting #{login}@#{server} ..."
begin
  client.connect(login, password, server: server, name: "ruby-quickstart")
rescue MetaRPC::MT5::InvalidLoginError => e
  abort "Invalid login, not retrying: #{e.message}"
end

acc = client.account_summary
puts "Account #{acc.account_login} (#{acc.account_company_name}) balance=#{acc.account_balance} #{acc.account_currency} " \
     "equity=#{acc.account_equity} leverage=1:#{acc.account_leverage} mode=#{acc.account_trade_mode}"

symbol = "EURUSD"
client.symbol_select(symbol, true)
tick = client.symbol_info_tick(symbol)
puts "#{symbol} bid=#{tick.bid} ask=#{tick.ask}"

bars = client.price_history(symbol, timeframe: :M5, max_bars: 10)
puts "last M5 close: #{bars.last&.close}"

puts "streaming ticks for 5 s ..."
n = client.each_tick([symbol], seconds: 5) { |t| puts "  #{t.symbol} #{t.bid}/#{t.ask}" }
puts "#{n} ticks"

if acc.account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO && ENV["QUICKSTART_TRADE"] == "1"
  r = client.order_send(symbol: symbol, type: :buy, volume: 0.01, magic: 123_456, comment: "ruby-quickstart")
  puts "order_send retcode=#{r.returned_code} #{r.returned_string_code} order=#{r.order} deal=#{r.deal} price=#{r.price}"
  if r.returned_code == 10_009
    c = client.order_close(ticket: r.order)
    puts "order_close retcode=#{c.returned_code} #{c.returned_string_code}"
  end
end

puts "open positions: #{client.positions.map { |p| "#{p.symbol} #{p.type} #{p.volume} @#{p.price_open} magic=#{p.magic_number}" }.inspect}"
# Do not disconnect: the terminal stays bound to terminal_id and the next run reuses it.
