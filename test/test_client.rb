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
