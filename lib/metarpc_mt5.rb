require_relative "metarpc_mt5/version"
require_relative "metarpc_mt5/errors"
require_relative "metarpc_mt5/subscription"
require_relative "metarpc_mt5/mt5_account"
require_relative "metarpc_mt5/mt5_service"
require_relative "metarpc_mt5/mt5_sugar"

module MetaRPC
  # Three-layer Ruby SDK for the MetaRPC MetaTrader 5 gateway (mt5.mrpc.pro):
  #
  #   MT5Account  - low-level, 1:1 gRPC (raw protobuf in/out)
  #   MT5Service  - mid-level, typed Ruby objects and plain arguments
  #   MT5Sugar    - high-level, one-line helpers with smart defaults
  #
  # `Client` aliases MT5Sugar (the friendly entry point); `Account` aliases MT5Account.
  module MT5
  end
end
