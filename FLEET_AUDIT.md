# RubyMT5 — fleet audit (MT5, prod gateway `mt5.mrpc.pro:443`)

Audited 2026-10-20 against `ICMCapitalLtd-Demo` login 498489 (demo). Every step of
`fleet/runners/ruby/smoke/smoke.rb` passes on Windows (Ruby 3.3.12) and on the Debian 12 VPS
(Ruby 3.1.2). Read this before implementing a strategy on the `ruby` runner.

**Verdict: usable — after the fixes below.** The upstream gem as vendored was NOT a working SDK:
its `Client` was a mock (hard-coded account info, `rand` tickets) and its generated protobuf files
could not even be loaded on any current `google-protobuf`. Both are fixed in `lib/RubyMT5`.

---

## 1. Install / reference

Not on rubygems. Reference the vendored gem by path (relative to your Gemfile):

```ruby
# Gemfile
source "https://rubygems.org"
gem "metarpc_mt5", path: "../../../../lib/RubyMT5"   # from fleet/runners/ruby/<thing>/
gem "bigdecimal", ">= 3.1", "< 4"                     # keep Ruby's bundled bigdecimal (no native build)
```

Runtime dependencies (declared in the gemspec): `grpc >= 1.60`, `google-protobuf >= 4.26`,
`googleapis-common-protos-types >= 1.4`. Ruby >= 3.1.

```ruby
require "bundler/setup"
require "metarpc_mt5"      # defines MetaRPC::MT5::Client (alias MetaRPC::MT5::Account) and Mt5TermApi::* messages
```

The gem adds its own `package/` directory to `$LOAD_PATH` (the generated `*_pb.rb` files require each
other by bare name), so nothing else is needed.

### Build / run — Windows

```powershell
# one-off: gems are prebuilt for x64-mingw-ucrt, no MSYS2 needed
gem install grpc google-protobuf googleapis-common-protos-types
cd C:\git\trading-bots\fleet\runners\ruby\smoke
$env:MRPC_API_KEY="mrpc_live_..."; $env:MT5_LOGIN="498489"; $env:MT5_PASSWORD="..."; $env:MT5_SERVER="ICMCapitalLtd-Demo"
bundle exec ruby smoke.rb
```
(`bundle install` tries to fetch a newer `bigdecimal` and fails without MSYS2; `bundle exec` resolves
against the installed gems and works. If you must `bundle install`, use `bundle install --prefer-local`.)

### Build / run — VPS (Debian 12, Ruby 3.1.2, rubygems 3.3.15)

```bash
# one-off (done 2026-10-20; ≈25 min of compile: rubygems 3.3.15 is too old for the prebuilt x86_64-linux
# grpc gem, so `gem install grpc` falls back to grpc 1.80.0 from source — do NOT run it twice in parallel)
nice gem install --no-document grpc google-protobuf googleapis-common-protos-types
gem install --no-document bundler -v "~> 2.5"     # Debian ships bundler only as a library, no `bundle` executable
cd /opt/fleet-audit/RubyMT5/fleet/runners/ruby/smoke      # or /opt/fleet/fleet/runners/ruby/smoke
bundle install                                            # resolves against the installed gems (bigdecimal 3.x pin)
MRPC_API_KEY=... MT5_LOGIN=498489 MT5_PASSWORD=... MT5_SERVER=ICMCapitalLtd-Demo bundle exec ruby smoke.rb
```
Installed on the VPS now: grpc 1.80.0, google-protobuf 4.35.1, googleapis-common-protos-types 1.22.0,
bundler 2.5.x (`/usr/local/bin/bundle`). No CRLF / path-separator / case issues were found: the same
files run unchanged on both platforms.
Offline unit tests: `cd lib/RubyMT5 && ruby -Ilib test/test_client.rb`.

---

## 2. Copy-pasteable call signatures (all verified live)

### Connect (ConnectEx by server name, stable terminal id)

```ruby
# STABLE id per strategy: uuid5(DNS namespace, strategy id) -> same terminal reused on every run.
tid  = MetaRPC::MT5::Client.uuid5(MetaRPC::MT5::Client::NAMESPACE_DNS, "fleet-audit-RubyMT5")
acct = MetaRPC::MT5::Client.new("mt5.mrpc.pro", 443, api_key: ENV["MRPC_API_KEY"], id: tid, timeout: 60)

begin
  data = acct.connect(498489, "password", server: "ICMCapitalLtd-Demo", name: "S001", timeout_seconds: 120)
  # data: Mt5TermApi::ConnectData  (terminal_instance_guid = "mt5_live_<hex>", terminal_type = :MT5)
rescue MetaRPC::MT5::InvalidLoginError => e
  # broker rejected the credentials -> terminal for this strategy, NEVER retry
rescue MetaRPC::MT5::ApiError, GRPC::BadStatus => e
  # transient: back off and retry connect
end
acct.metadata   # => {"apikey"=>..., "id"=>tid}  sent with every RPC
```
Connect costs ~4.5 s when the gateway has to start the terminal, ~0.2 s when the terminal bound to `id`
is already alive (re-runs). The gateway returns its own alias `mt5_live_<id-without-dashes>` but the
routing key stays the `id` you sent; the client keeps using yours (`acct.server_guid` holds the alias).

`acct.connect_by_host(login, pwd, host:, port:)` does the same via `Connect` (raw trade-server address).
`acct.check_connect`, `acct.connection_status`, `acct.reconnect(force: false)`, `acct.disconnect(delete: false)` exist;
**do not disconnect at the end of a run** — leave the terminal bound to the stable id.

### Account summary + DEMO guard

```ruby
s = acct.account_summary            # Mt5TermApi::AccountSummaryData
s.account_login        # 498489
s.account_balance      # 100000.0
s.account_equity       # 100000.0
s.account_currency     # "USD"
s.account_leverage     # 100
s.account_trade_mode   # :MRPC_ACCOUNT_TRADE_MODE_DEMO | :MRPC_ACCOUNT_TRADE_MODE_CONTEST | :MRPC_ACCOUNT_TRADE_MODE_REAL
s.account_company_name # "ICM Capital Limited"
s.server_time_utc      # Google::Protobuf::Timestamp (use .to_time); server_time is broker-tz
abort "not demo" unless acct.demo?  # == account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO
```

### Symbols / quote

```ruby
acct.symbol_exist("EURUSD")              # true/false
acct.symbol_select("EURUSD", true)       # add to Market Watch (needed before ticks/orders on fresh terminals)
acct.symbol_is_synchronized("EURUSD")    # wait for true AND a two-sided tick after selecting

t = acct.symbol_info_tick("EURUSD")      # Mt5TermApi::MrpcMqlTick  <- PRICES COME FROM HERE
t.bid; t.ask; t.last; t.volume; t.time (unix s, broker tz); t.time_utc; t.time_msc; t.flags
# reject quotes with bid <= 0, ask <= 0 or bid == ask (demo feeds publish them)

p = acct.symbol_params("EURUSD")         # Mt5TermApi::SymbolParameters (nil if unknown) <- SPECS COME FROM HERE
p.digits (5)  p.point (1e-5)  p.trade_contract_size (100000.0)
p.volume_min (0.01)  p.volume_max  p.volume_step (0.01)
p.trade_tick_size  p.trade_tick_value  p.trade_stops_level (0)  p.trade_freeze_level
p.trade_mode       # :BMT5_SYMBOL_TRADE_MODE_FULL / _DISABLED / _LONGONLY / _SHORTONLY / _CLOSEONLY
p.filling_mode     # repeated: [:BMT5_ORDER_FILLING_FOK, :BMT5_ORDER_FILLING_IOC]
p.currency_base; p.currency_profit; p.currency_margin; p.swap_long; p.swap_short; p.sym_description; p.path
all = acct.symbol_params_many            # [SymbolParameters] for every symbol, ONE call (never page: page_number does not advance)
acct.symbol_list                         # ["EURUSD", ...] names only
acct.symbol_info_double("EURUSD", :SYMBOL_BID)   # raw MQL property getters also exist (int/string too)
```
Known gotcha (HANDOFF §7.4): `bid/ask/currency_base` inside the bulk `symbol_params_many` reply are
unreliable; use `symbol_info_tick` for prices and `symbol_params(symbol)` for a single symbol's spec.

### Bars

```ruby
bars = acct.price_history("EURUSD", timeframe: :M1, max_bars: 50)        # newest 50 bars, oldest first
bars = acct.price_history("EURUSD", timeframe: :H1, from_utc: Time.now.utc - 7*86400, to_utc: Time.now.utc, max_bars: 500)
b = bars.last   # Mt5TermApi::PriceBar
b.time (unix s, broker tz)  b.time_utc (unix s)  b.open b.high b.low b.close  b.tick_volume  b.spread  b.real_volume
# timeframe: :M1 :M2 :M3 :M4 :M5 :M6 :M10 :M12 :M15 :M20 :M30 :H1 :H2 :H3 :H4 :H6 :H8 :H12 :D1 :W1 :MN1
#            (MetaRPC::MT5::Client::TIMEFRAMES maps them to MQL5 ENUM_TIMEFRAMES ints; raw ints also accepted)
# max_bars defaults to 500 on the gateway; the last bar is the still-forming one.
```

### Tick stream (subscribe / unsubscribe)

```ruby
sub = acct.on_symbol_tick(%w[EURUSD XAUUSD]) do |t|   # runs on a background thread
  # t: Mt5TermApi::MrpcSubscriptionMqlTick  t.symbol t.bid t.ask t.last t.volume t.time (Timestamp) t.time_msc t.flags
end
sleep 10
sub.cancel          # clean unsubscribe (gRPC cancel + thread join); sub.count = ticks received; sub.error = exception if the stream died
sub.alive?

n = acct.each_tick(["EURUSD"], seconds: 10) { |t| ... }   # blocking convenience: returns tick count
acct.on_trade { |ev| ... }                                # OnTradeData (orders/positions changed)
acct.on_position_profit(interval_ms: 1000) { |d| ... }    # periodic P/L of open positions
```
A stream that ends by itself (server restart, terminal recycled) sets `sub.error` (a `GRPC::BadStatus`)
and the thread exits; resubscribe in your loop. Measured: EURUSD ≈ 0.9–1.5 ticks/s at 00:30 UTC.

### Orders

```ruby
r = acct.order_send(symbol: "EURUSD", type: :buy, volume: 0.01, magic: 600001, comment: "S001", slippage: 20)
# optional: price:, stop_loss:, take_profit:, stop_limit_price:, expiration_type:, expiration_utc:, quotes_wait_ms:, without_checks: true
# type: :buy :sell :buy_limit :sell_limit :buy_stop :sell_stop :buy_stop_limit :sell_stop_limit (or the raw TMT5_ORDER_TYPE_* symbol)
r.returned_code       # 10009 == TRADE_RETCODE_DONE  (check this; the call does NOT raise on a rejected request)
r.returned_string_code # "TRADE_RETCODE_DONE"; r.returned_code_description
r.order               # 131838249 -> for a market order this IS the position ticket (hedging and netting)
r.deal                # 18216561
r.price; r.volume; r.bid; r.ask; r.comment
acct.buy("EURUSD", 0.01, magic: 600001, comment: "S001")   # shorthand; acct.sell likewise

m = acct.order_modify(ticket: r.order, stop_loss: 1.1201, take_profit: 1.1231)   # positions: SL/TP; pendings: + price:, stop_limit:, expiration_*
m.returned_code == 10_009

c = acct.order_close(ticket: r.order, slippage: 20)          # full close; volume: 0.005 for partial; pending ticket -> delete
c.returned_code == 10_009;  c.close_mode  # :MRPC_MARKET_ORDER_CLOSE / :MRPC_MARKET_ORDER_PARTIAL_CLOSE / :MRPC_PENDING_ORDER_REMOVE

acct.order_calc_margin(symbol: "EURUSD", type: :buy, volume: 0.01, price: 1.12)   # Float
acct.positions_total                                                              # Integer
```
Rejections come back two ways: as a non-10009 `returned_code` (broker trade-server retcodes, e.g. 10018
market closed, 10019 no money, 10016 invalid stops) or as `MetaRPC::MT5::ApiError` (gateway/MQL error;
`e.error.mql_error_trade_code`, `e.code`). Handle both. Round volume to `volume_step` yourself.

### Open positions / filtering by magic

```ruby
acct.positions(magic: 600001)                    # [Mt5TermApi::PositionInfo] filtered client-side by magic_number
acct.positions(magic: 600001, symbol: "EURUSD")
pos.ticket pos.symbol pos.type (:BMT5_POSITION_TYPE_BUY/_SELL) pos.volume pos.price_open pos.price_current
pos.stop_loss pos.take_profit pos.profit pos.swap pos.magic_number pos.comment pos.identifier pos.open_time_utc
oo = acct.opened_orders                          # Mt5TermApi::OpenedOrdersData: oo.position_infos + oo.opened_orders (pending; .magic_number .type .price_open ...)
```
The gateway has no server-side magic filter; every runner filters `magic_number == own magic`.

### History

```ruby
rows = acct.order_history(from_utc: Time.now.utc - 3600)            # [Mt5TermApi::HistoryData], auto-follows page_token
rows.each do |h|
  o = h.history_order   # OrderHistoryData: ticket state type price_open volume_initial magic_number position_id symbol comment setup_time_utc done_time_utc
  d = h.history_deal    # DealHistoryData:  ticket type (:BMT5_DEAL_TYPE_BUY/_SELL/_BALANCE...) entry_type (:BMT5_DEAL_ENTRY_IN/_OUT) price volume profit commission swap position_id symbol comment time_utc
end
closed = acct.positions_history(from_utc: Time.now.utc - 3600)      # [Mt5TermApi::PositionHistoryInfo]: one row per closed position
x.position_ticket x.symbol x.open_price x.close_price x.volume x.profit x.commission x.swap x.magic x.comment x.open_time_utc x.close_time_utc
```
`positions_history` carries `magic`; `order_history` deals do not (orders do: `history_order.magic_number`).
Filter the audit trade by `magic` on positions_history or by `comment`/`position_id` on deals.

### Errors / reconnect

```ruby
rescue MetaRPC::MT5::InvalidLoginError   # terminal; log and stop the strategy
rescue MetaRPC::MT5::ApiError => e       # e.error (Mt5TermApi::Error): type, error_code, error_message, mql_error_*; e.code
rescue GRPC::DeadlineExceeded, GRPC::Unavailable, GRPC::Internal => e   # transport: back off (1,2,4,...60 s) then acct.connect(...) again with the SAME id
```
There is no automatic reconnect in the client (by design: the host owns the back-off policy). The
per-RPC deadline is `timeout:` (default 60 s; connect uses `timeout_seconds + 30`; history/bars 120 s).
A unary call made while the terminal is gone raises `ApiError` or `GRPC::BadStatus`; calling
`connect` again with the same `id` revives the same terminal in ~4 s.

---

## 3. Bugs found and fixed (all in `lib/RubyMT5`, mirrored to `C:/git/setup_RubyMT5` and committed there)

| # | Bug | Fix |
|---|---|---|
| 1 | **Generated `package/*_pb.rb` used the legacy `DescriptorPool.generated_pool.build do add_file ... add_message` DSL**, removed in google-protobuf 4.x. `require` fails with `undefined method 'build' for DescriptorPool` on every current gem; the package was unloadable. | Regenerated all 16 protos (the gateway's own `Mrpc.TerminalManager/proto/mt5/*.proto` + `google/api/annotations`) with `grpc_tools_ruby_protoc` 1.84 → `add_serialized_file` form. Imports were flattened (`mt5/` prefix dropped) to keep the flat `package/` layout. 33 files, loads on protobuf 4.35/4.36. |
| 2 | **`lib/metarpc_mt5/client.rb` was a mock**: `account_info` returned a hard-coded 50 000 USD account, `order_send` returned `rand` tickets, `subscribe_quotes` did nothing, no gRPC call anywhere; the README/docs promised a working SDK. | Rewrote `MetaRPC::MT5::Client` as a real gRPC client (TLS, `apikey`+`id` metadata, oneof data/error unwrapping, server-streaming on a cancelable background thread). Public surface documented above. Kept `compute_deterministic_id`, `connected?`, `disconnect(delete:)`, `last_disconnect_deleted` for compatibility. |
| 3 | `metarpc_mt5.gemspec` declared no runtime dependencies and did not ship `package/`, so a path/gem install had neither `grpc` nor the stubs. | Added `grpc`, `google-protobuf`, `googleapis-common-protos-types` deps, `package/**` to files, `require_paths = ["lib","package"]`, `required_ruby_version >= 3.1`. |
| 4 | `examples/quickstart.rb` and `test/test_client.rb` exercised the mock (asserting the fake 50 000 balance). | Rewritten: quickstart does connect/summary/tick/bars/stream (+ optional demo trade); tests are offline (metadata, uuid5, message construction, error unwrapping): `7 runs, 16 assertions, 0 failures`. |
| 5 | README said `gem install rubymt5` (no such gem). | README install section now shows the path dependency. |

Found while writing the client (not bugs in the vendored code, but easy to get wrong): `SymbolExistRequest`
field is `name`, not `symbol`; `OnSymbolTickReply.data` is `OnSymbolTickData` whose tick is `.symbol_tick`;
`PositionsTotalData.total_positions`; `AccountInfo*Data.requested_value`; `SymbolListData.Symbols`
(capitalised); opened-orders sort enum is `BMT5_OPENED_ORDER_SORT_BY_OPEN_TIME_ASC` while order-history
sort is `BMT5_SORT_BY_CLOSE_TIME_ASC`.

---

## 4. Performance (prod, ICMCapitalLtd-Demo, EURUSD, 00:26–00:30 UTC)

| Metric | Windows (Ruby 3.3.12, grpc 1.83.1) | VPS (Ruby 3.1.2, grpc 1.80.0) |
|---|---|---|
| connect, cold (terminal created) | 4.5 s | (terminal already alive) |
| connect, warm (same id, terminal alive) | 0.21 s | 0.022 s |
| account_summary | 37–120 ms | 7 ms |
| symbol_info_tick / symbol_params | ~100 ms each | ~10 ms each |
| price_history 50×M1 | 70–220 ms | 5 ms |
| tick stream EURUSD | 9 ticks / 10 s | 7 ticks / 10 s |
| order_send market → filled | 240–390 ms | 76 ms |
| order_modify / order_close | 165–460 ms / 100–180 ms | 62 ms / 45 ms |
| order_history + positions_history (1 h) | 66–111 ms | 15 ms |
| process RSS after the whole run | 38 MB | 37.8 MB |
| total smoke runtime (incl. 10 s stream) | 11.8 s | 10.3 s |

The VPS sits next to the gateway: round-trips are ~10× cheaper than from the Windows box. Budget
~10 ms per unary call and ~80 ms per order on the VPS; with 6 Ruby strategies polling every few seconds
the host will be idle most of the time.

Memory: one `Client` = one gRPC channel per service stub (8 stubs max, lazily created); the Ruby grpc
gem's thread pool is shared. A host process running 6 strategies on 6 terminals should stay well under
150 MB. The grpc gem is a native extension (not thread-free): streams run on Ruby threads and hold the GVL
only while decoding, fine for 6 strategies.

---

## 5. VPS run (2026-10-20 00:37 UTC, `/opt/fleet-audit/RubyMT5`)

```
terminal id: 1ca894c5-2a7c-5b6b-8396-31d389de4d11
PASS connect (22 ms) guid=mt5_live_1ca894c52a7c5b6b839631d389de4d11 type=MT5
PASS account (7 ms) login=498489 balance=99999.64 equity=99999.64 currency=USD leverage=1:100 mode=MRPC_ACCOUNT_TRADE_MODE_DEMO company="ICM Capital Limited"
PASS symbols (39 ms) EURUSD bid=1.12182 ask=1.1219999999999999 digits=5 contract=100000.0 vol_min=0.01 vol_step=0.01 stops_level=0 trade_mode=BMT5_SYMBOL_TRADE_MODE_FULL filling=[:BMT5_ORDER_FILLING_FOK, :BMT5_ORDER_FILLING_IOC]
PASS bars (5 ms) 50 M1 bars, last: time_utc=2026-10-20 00:37:00 UTC o=1.12185 h=1.12185 l=1.1218 c=1.12183 v=23
PASS stream (10008 ms) 7 ticks in 10s (0.7/s), first="EURUSD 1.12182/1.1219999999999999"
PASS order_open (76 ms) EURUSD order=131838642 deal=18216960 price=1.12202 vol=0.01 retcode=10009 TRADE_RETCODE_DONE; position ticket=131838642 magic=599999 comment="fleet-audit"
PASS order_modify (62 ms) ticket=131838642 sl=1.12034 tp=1.12334 retcode=10009; position now sl=1.1203400000000001 tp=1.12334
PASS order_close (45 ms) ticket=131838642 retcode=10009 mode=MRPC_MARKET_ORDER_CLOSE; remaining audit positions=[]
PASS history (15 ms) 6 deals / 3 closed positions in the last hour; audit: ... pos=131838642 EURUSD open=1.12202 close=1.12184 pnl=-0.18 magic=599999
INFO rss=37.8 MB runtime=10.3 s ruby=3.1.2 grpc=1.80.0 protobuf=4.35.1
ALL PASS
```
Audit trades: EURUSD 0.01 lot, tickets 131838240 / 131838249 (Windows) and 131838642 (VPS), all closed,
−0.18 USD each (spread). The terminal `fleet-audit-RubyMT5` is left connected on prod, bound to the id above.

Note the float noise in prices (`1.1219999999999999`): protobuf doubles are exact, Ruby's `Float#to_s`
is not. Round with `symbol_params.digits` before comparing or logging.

---

## 6. Things a strategy implementer must know

- **Stable `id`**: `Client.uuid5(Client::NAMESPACE_DNS, strategy.id)` (identical to Python's
  `uuid.uuid5(uuid.NAMESPACE_DNS, ...)`, verified byte-for-byte). Never `SecureRandom.uuid` per run.
- **DEMO guard**: `account_summary.account_trade_mode == :MRPC_ACCOUNT_TRADE_MODE_DEMO` before any order.
- **Market order ticket == position ticket** (`r.order`); modify/close with it. Confirm with
  `acct.positions(magic:)` before modifying (the position appeared within the first poll in every run).
- **Retcodes**: success is `returned_code == 10009`; the client does not raise on broker rejections.
- **Enums are Ruby symbols** (`:TMT5_ORDER_TYPE_BUY`, `:BMT5_POSITION_TYPE_SELL`, `:MRPC_ACCOUNT_TRADE_MODE_DEMO`);
  compare with symbols, not ints. Unknown enum values come back as integers.
- **Times**: `*_utc` fields are the ones to use (`time_utc` unix seconds on ticks/bars; `Timestamp` on
  history → `.to_time`). The non-suffixed fields are broker-server local time.
- **Requests with UTC**: pass `from_utc:/to_utc:` (`Time` or Integer); the client sets the `*_utc` fields.
- **Volume**: clamp to `[volume_min, volume_max]`, round to `volume_step` (`(v / step).round * step`).
- **Stops**: `trade_stops_level` is 0 on ICM demo but not everywhere; place SL/TP at least
  `stops_level * point` away from the current bid/ask or you get 10016.
- **Fresh terminal + symbol not in Market Watch**: `symbol_select` then wait for
  `symbol_is_synchronized` and a two-sided tick (first tick can be 0/0).
- **Streams** run on background threads; do not call unary RPCs from inside the tick block if you need
  ordering guarantees — push to a `Queue` and consume in the strategy loop.
- **One Client per account**; stubs are cached per client. Create a fresh `Client` after a fatal error.
- **Do not `disconnect`** on shutdown (the fleet keeps terminals alive); `disconnect(delete: true)` only
  when retiring a strategy for good.
