Gem::Specification.new do |spec|
  spec.name          = "metarpc_mt5"
  spec.version       = "1.0.0"
  spec.authors       = ["MetaRPC"]
  spec.email         = ["info@metarpc.pro"]

  spec.summary       = "MetaTrader 5 Ruby SDK for algorithmic trading automation"
  spec.description   = "Pure Ruby client for connecting directly to MetaTrader 5 servers without desktop terminal."
  spec.homepage      = "https://metarpc.github.io/RubyMT5/"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*.rb", "README.md"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"
end
