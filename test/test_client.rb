require "minitest/autorun"
require_relative "../lib/metarpc_mt5"

# Offline tests: construction, metadata, id derivation and request building.
# Live behaviour is covered by fleet/runners/ruby/smoke/smoke.rb.
class TestMetaRPCMT5Client < Minitest::Test
  def setup
    @client = MetaRPC::MT5::Client.new("mt5.mrpc.pro", 443, api_key: "mrpc_test_key", id: "11111111-2222-5333-8444-555555555555")
  end

  def test_initial_state
    refute @client.connected?
    assert_equal "mt5.mrpc.pro", @client.host
    assert_equal 443, @client.port
    assert_equal "mrpc_test_key", @client.api_key
    assert_equal "mt5.mrpc.pro:443", @client.target
  end

  def test_metadata_carries_apikey_and_id
    assert_equal({ "apikey" => "mrpc_test_key", "id" => "11111111-2222-5333-8444-555555555555" }, @client.metadata)
    c = MetaRPC::MT5::Client.new(api_key: "k")
    assert_equal({ "apikey" => "k" }, c.metadata)
  end

  def test_api_key_required
    old = ENV.delete("MRPC_API_KEY")
    assert_raises(ArgumentError) { MetaRPC::MT5::Client.new }
  ensure
    ENV["MRPC_API_KEY"] = old if old
  end

  def test_deterministic_id
    id = MetaRPC::MT5::Client.compute_deterministic_id(12_345_678, "demo_password")
    assert_equal "6ce74465-7aa9-3a79-2bd8-e40241b50c43", id
  end

  def test_uuid5_matches_rfc4122
    # python: uuid.uuid5(uuid.NAMESPACE_DNS, "fleet-audit-RubyMT5")
    assert_equal "1ca894c5-2a7c-5b6b-8396-31d389de4d11",
                 MetaRPC::MT5::Client.uuid5(MetaRPC::MT5::Client::NAMESPACE_DNS, "fleet-audit-RubyMT5")
  end

  def test_generated_messages_load
    req = Mt5TermApi::ConnectExRequest.new(user: 1, password: "p", mt_cluster_name: "X-Demo", name: "n")
    assert_equal "X-Demo", req.mt_cluster_name
    o = Mt5TermApi::OrderSendRequest.new(symbol: "EURUSD", operation: :TMT5_ORDER_TYPE_BUY, volume: 0.01)
    assert_equal :TMT5_ORDER_TYPE_BUY, o.operation
    assert_equal 16_385, MetaRPC::MT5::Client::TIMEFRAMES[:H1]
  end

  def test_unwrap_raises_api_error
    err = Mt5TermApi::Error.new(error_code: "X", error_message: "boom")
    reply = Mt5TermApi::AccountSummaryReply.new(error: err)
    e = assert_raises(MetaRPC::MT5::ApiError) { @client.unwrap(reply, :account_summary) }
    assert_equal "X", e.code
    data = Mt5TermApi::AccountSummaryData.new(account_login: 7)
    assert_equal 7, @client.unwrap(Mt5TermApi::AccountSummaryReply.new(data: data), :account_summary).account_login
  end
end

# A trade is sent exactly once: a transport failure of a trade call is marked TradeOutcomeUnknown (the trade may
# have been executed), never re-sent. In-process gRPC server on localhost, no network.
class TestMetaRPCMT5TradeOutcome < Minitest::Test
  Codes = GRPC::Core::StatusCodes

  # Counts calls; the next call fails with `fail_next` (a GRPC::BadStatus) or answers `error_next` (an Error message).
  class FakeServer
    attr_accessor :fail_next, :error_next
    attr_reader :calls

    def initialize = @calls = Hash.new(0)

    def answer(rpc, reply_class, data)
      @calls[rpc] += 1
      if (f = @fail_next)
        @fail_next = nil
        raise f
      end
      if (e = @error_next)
        @error_next = nil
        return reply_class.new(error: e)
      end
      reply_class.new(data: data)
    end
  end

  FAKE = FakeServer.new

  class Trading < Mt5TermApi::TradingHelper::Service
    def order_send(_req, _call) = FAKE.answer(:order_send, Mt5TermApi::OrderSendReply, Mt5TermApi::OrderSendData.new(returned_code: 10_009, order: 88))
    def order_modify(_req, _call) = FAKE.answer(:order_modify, Mt5TermApi::OrderModifyReply, Mt5TermApi::OrderModifyData.new(returned_code: 10_009))
    def order_close(_req, _call) = FAKE.answer(:order_close, Mt5TermApi::OrderCloseReply, Mt5TermApi::OrderCloseData.new(returned_code: 10_009))
  end

  class AccountHelper < Mt5TermApi::AccountHelper::Service
    def account_summary(_req, _call) = FAKE.answer(:account_summary, Mt5TermApi::AccountSummaryReply, Mt5TermApi::AccountSummaryData.new(account_login: 7))
  end

  def self.port
    @port ||= begin
      server = GRPC::RpcServer.new
      port = server.add_http2_port("127.0.0.1:0", :this_port_is_insecure)
      server.handle(Trading)
      server.handle(AccountHelper)
      Thread.new { server.run }
      server.wait_till_running(10)
      Minitest.after_run { server.stop }
      port
    end
  end

  def setup
    @client = MetaRPC::MT5::Client.new("127.0.0.1", self.class.port, api_key: "k", id: "11111111-2222-5333-8444-555555555555", timeout: 10)
    FAKE.calls.clear
  end

  TRADES = {
    "OrderSend" => [:order_send, ->(c) { c.order_send(symbol: "EURUSD", type: :buy, volume: 0.1) }],
    "OrderModify" => [:order_modify, ->(c) { c.order_modify(ticket: 88, stop_loss: 1.0) }],
    "OrderClose" => [:order_close, ->(c) { c.order_close(ticket: 88, volume: 0.05) }]
  }.freeze

  def test_trade_transport_failure_is_sent_once_and_marked_trade_outcome_unknown
    TRADES.each do |operation, (rpc, run)|
      [GRPC::Unavailable, GRPC::DeadlineExceeded, GRPC::Unknown, GRPC::Internal].each do |klass|
        FAKE.calls.clear
        FAKE.fail_next = klass.new("connection reset")
        e = assert_raises(klass) { run.call(@client) }   # still the gRPC error class callers rescue
        assert_equal({ rpc => 1 }, FAKE.calls, "#{operation} #{klass}")
        assert_kind_of MetaRPC::MT5::TradeOutcomeUnknown, e
        assert_kind_of GRPC::BadStatus, e
        assert_equal klass.new.code, e.code
        assert_equal "connection reset", e.details
        assert_equal "TRADE_OUTCOME_UNKNOWN", e.error_code
        assert e.trade_outcome_unknown?
        assert_equal operation, e.operation
        assert_match(/\ATRADE_OUTCOME_UNKNOWN: #{operation} failed with gRPC [A-Z_]+ .*NOT re-sent.*connection reset/, e.message)
      end
    end
  end

  def test_rescue_by_module_catches_it
    FAKE.fail_next = GRPC::Unavailable.new("down")
    caught = begin
      @client.order_send(symbol: "EURUSD", type: :buy, volume: 0.1)
    rescue MetaRPC::MT5::TradeOutcomeUnknown => e
      e
    end
    assert_equal "OrderSend", caught.operation
  end

  def test_trade_refused_before_terminal_is_api_error_with_known_outcome
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "TERMINAL_INSTANCE_NOT_FOUND", error_message: "no terminal")
    e = assert_raises(MetaRPC::MT5::ApiError) { @client.order_send(symbol: "EURUSD", type: :buy, volume: 0.1) }
    assert_equal "TERMINAL_INSTANCE_NOT_FOUND", e.code
    refute e.trade_outcome_unknown?
    refute e.api_key_error?
    assert_equal({ order_send: 1 }, FAKE.calls)
  end

  def test_refused_api_key_is_one_call_with_its_code
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "API_KEY_INVALID", error_message: "Unknown API key")
    e = assert_raises(MetaRPC::MT5::ApiError) { @client.order_send(symbol: "EURUSD", type: :buy, volume: 0.1) }
    assert_equal "API_KEY_INVALID", e.code
    assert e.api_key_error?
    refute e.trade_outcome_unknown?
    assert_equal({ order_send: 1 }, FAKE.calls)
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "API_KEY_REQUIRED", error_message: "no key")
    assert assert_raises(MetaRPC::MT5::ApiError) { @client.account_summary }.api_key_error?
  end

  def test_transport_failure_naming_a_refused_key_is_not_marked
    FAKE.fail_next = GRPC::Unknown.new("API_KEY_INVALID")
    e = assert_raises(GRPC::Unknown) { @client.order_send(symbol: "EURUSD", type: :buy, volume: 0.1) }
    refute_kind_of MetaRPC::MT5::TradeOutcomeUnknown, e
    assert_equal({ order_send: 1 }, FAKE.calls)
  end

  def test_in_band_trade_timeouts_are_unknown_outcomes_reads_are_not
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "X", type: :MRPC_TIMEOUT)
    assert assert_raises(MetaRPC::MT5::ApiError) { @client.order_close(ticket: 88) }.trade_outcome_unknown?
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "MQL5_SIDE_TRADE_ERROR", mql_error_trade_int_code: 10_031)
    assert assert_raises(MetaRPC::MT5::ApiError) { @client.order_send(symbol: "EURUSD", type: :buy, volume: 0.1) }.trade_outcome_unknown?
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "MQL5_SIDE_TRADE_ERROR", mql_error_trade_int_code: 10_019)
    refute assert_raises(MetaRPC::MT5::ApiError) { @client.order_send(symbol: "EURUSD", type: :buy, volume: 0.1) }.trade_outcome_unknown?
    FAKE.error_next = Mt5TermApi::Error.new(error_code: "MRPC_TIMEOUT", type: :MRPC_TIMEOUT)
    refute assert_raises(MetaRPC::MT5::ApiError) { @client.account_summary }.trade_outcome_unknown?
  end

  def test_read_transport_failure_is_the_plain_grpc_error
    FAKE.fail_next = GRPC::Unavailable.new("down")
    e = assert_raises(GRPC::Unavailable) { @client.account_summary }
    refute_kind_of MetaRPC::MT5::TradeOutcomeUnknown, e
    assert_equal({ account_summary: 1 }, FAKE.calls)
    assert_equal 7, @client.account_summary.account_login
  end
end
