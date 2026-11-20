require "metarpc_mt5"

# MetaRPC MT5 Ruby SDK quickstart (real gRPC calls against mt5.mrpc.pro:443).
#
#   MRPC_API_KEY=... MT5_LOGIN=... MT5_PASSWORD=... MT5_SERVER=MetaQuotes-Demo \
#     bundle exec ruby examples/quickstart.rb
#
# Three layers, one object: MT5Sugar.create builds MT5Sugar -> MT5Service ->
# MT5Account. Reach down with `mt5.service` / `mt5.account` when you need to.
#
# Use a STABLE terminal id per account/strategy (uuid5 below): the gateway keeps
# one terminal per id, and a fresh id on every run orphans terminals.

MT5 = MetaRPC::MT5

api_key  = ARGV[0] || ENV["MRPC_API_KEY"] || abort("set MRPC_API_KEY")
login    = (ENV["MT5_LOGIN"] || abort("set MT5_LOGIN")).to_i
password = ENV["MT5_PASSWORD"] || abort("set MT5_PASSWORD")
server   = ENV["MT5_SERVER"] || "MetaQuotes-Demo"

terminal_id = MT5::MT5Account.uuid5(MT5::MT5Account::NAMESPACE_DNS, "quickstart-#{login}")
mt5 = MT5::MT5Sugar.create("mt5.mrpc.pro", 443, api_key: api_key, id: terminal_id)

puts "Connecting #{login}@#{server} ..."
begin
  mt5.connect(login, password, server: server, name: "ruby-quickstart")
rescue MT5::InvalidLoginError => e
  abort "Invalid login, not retrying: #{e.message}"
end

a = mt5.account_info
puts "Account #{a.login} (#{a.company}) balance=#{a.balance} #{a.currency} " \
     "equity=#{a.equity} leverage=1:#{a.leverage} mode=#{a.trade_mode}"

symbol = "EURUSD"
mt5.account.symbol_select(symbol, true)     # low-level reach when a one-liner is too narrow
q = mt5.price(symbol)
puts "#{symbol} bid=#{q.bid} ask=#{q.ask} spread=#{q.spread.round(5)}"

bars = mt5.bars(symbol, timeframe: :M5, max_bars: 10)
puts "last M5 close: #{bars.last&.close}"

puts "streaming ticks for 5 s ..."
n = mt5.each_tick([symbol], seconds: 5) { |t| puts "  #{t.symbol} #{t.bid}/#{t.ask}" }
puts "#{n} ticks"

if mt5.demo? && ENV["QUICKSTART_TRADE"] == "1"
  r = mt5.buy_market(symbol, 0.01, magic: 123_456, comment: "ruby-quickstart")
  puts "buy_market retcode=#{r.returned_code} #{r.returned_string_code} order=#{r.order} deal=#{r.deal} price=#{r.price}"
  if r.returned_code == 10_009
    c = mt5.close_position(r.order)
    puts "close retcode=#{c.returned_code} #{c.returned_string_code}"
  end
end

puts "open positions: #{mt5.open_positions.map { |p| "#{p.symbol} #{p.type} #{p.volume} @#{p.price_open} magic=#{p.magic_number}" }.inspect}"
# Do not disconnect: the terminal stays bound to terminal_id and the next run reuses it.
