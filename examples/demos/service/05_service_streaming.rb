# ══════════════════════════════════════════════════════════════════════════════
# FILE: 05_service_streaming.rb — MID-LEVEL (MT5Service) STREAMING
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Streaming through the typed facade. subscribe_ticks / each_tick / on_trade all
#   return the same Subscription handle as the raw layer. READ-ONLY.
#
# WHAT THIS DEMO COVERS:
#   1. TICKS (blocking)  - each_tick(symbols, seconds:)
#   2. TICKS (callback)  - subscribe_ticks(symbols) + .cancel
#
# RUN:  ruby examples/demos/main.rb 5      (SAFE: read-only, ~6s)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("5", "Service streaming     - typed tick streams (~6s)") do |sugar, cfg|
  svc = sugar.service
  sym = cfg.test_symbol

  Demos.sub("1. each_tick (blocking, ~4s)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  1.1  each_tick(symbols, seconds:) { |tick| ... } — subscribe, iterate for N
  #       seconds, auto-cancel, and return the tick count. Simplest for scripts.
  # ──────────────────────────────────────────────────────────────────────────────
  shown = 0
  n = svc.each_tick(sym, seconds: 4) do |t|
    shown += 1
    puts format("    tick bid %s ask %s", t.bid, t.ask) if shown <= 5
  end
  puts "  total ticks in 4s: #{n}"

  Demos.sub("2. subscribe_ticks (manual cancel, ~2s)")

  # ──────────────────────────────────────────────────────────────────────────────
  #  2.1  subscribe_ticks(symbols) { |tick| ... } — returns a Subscription you keep
  #       and later .cancel. Use when the stream must outlive one method call.
  # ──────────────────────────────────────────────────────────────────────────────
  count = 0
  sub = svc.subscribe_ticks(sym) { |_t| count += 1 }
  sleep 2
  sub.cancel
  puts "  received #{count} ticks before cancel"
end
