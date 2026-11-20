# ══════════════════════════════════════════════════════════════════════════════
# FILE: config.rb — DEMO CONNECTION SETTINGS
# ──────────────────────────────────────────────────────────────────────────────
# Loads demo credentials from config/config.json and overlays environment
# variables (env wins). Never commit real credentials — prefer the MT5_* env vars.
#
# ENV VARS (override the JSON file):
#   MT5_LOGIN · MT5_PASSWORD · MT5_SERVER · MT5_HOST · MT5_PORT ·
#   MT5_SYMBOL · MT5_VOLUME · MRPC_API_KEY
#
# USAGE:
#   require_relative "config/config"
#   cfg = Demos.load_config   # => Demos::Config(user, password, server, host, port, ...)
# ══════════════════════════════════════════════════════════════════════════════

require "json"

module Demos
  Config = Struct.new(:user, :password, :server, :host, :port, :api_key,
                      :test_symbol, :test_volume, keyword_init: true)

  # API key passed on the command line (set by main.rb from ARGV); overrides env + file.
  @api_key_override = nil
  def self.api_key_override=(key)
    @api_key_override = (key.nil? || key.empty? ? nil : key)
  end

  def self.load_config
    file = {}
    path = File.join(__dir__, "config.json")
    file = JSON.parse(File.read(path)) if File.exist?(path)

    env = ENV
    num = ->(v, d) { v.nil? || v.empty? ? d : v.to_f }
    int = ->(v, d) { v.nil? || v.empty? ? d : v.to_i }

    Config.new(
      user:        int.call(env["MT5_LOGIN"], (file["user"] || 0).to_i),
      password:    env["MT5_PASSWORD"] || file["password"] || "",
      server:      env["MT5_SERVER"] || file["mt_cluster"] || "MetaQuotes-Demo",
      host:        env["MT5_HOST"] || file["host"] || "mt5.mrpc.pro",
      port:        int.call(env["MT5_PORT"], (file["port"] || 443).to_i),
      api_key:     @api_key_override || env["MRPC_API_KEY"] || file["api_key"] || "",
      test_symbol: env["MT5_SYMBOL"] || file["test_symbol"] || "EURUSD",
      test_volume: num.call(env["MT5_VOLUME"], (file["test_volume"] || 0.01).to_f)
    )
  end
end
