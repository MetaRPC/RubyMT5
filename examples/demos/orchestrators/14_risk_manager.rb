# ══════════════════════════════════════════════════════════════════════════════
# FILE: 14_risk_manager.rb — ORCHESTRATOR: RISK MANAGER / KILL-SWITCH
# ──────────────────────────────────────────────────────────────────────────────
# PURPOSE:
#   Monitor the account and enforce a simple risk policy: if floating drawdown
#   breaches a threshold, flatten everything (kill-switch). SAFE by default — a wide
#   threshold + dry_run mean nothing is closed, it only REPORTS.
#
# STRATEGY LOGIC:
#   Floating drawdown = how much unrealized loss you're carrying, as a fraction of
#   balance:  drawdown = max(0, -(equity − balance)) / balance.
#   On every check we recompute it; once it crosses `max_drawdown` the kill-switch
#   "fires" — in a real run (dry_run = false) that calls close_all_positions to cap
#   the loss. This is the safety net you run ALONGSIDE a trading strategy.
#
#   ORCHESTRATOR: composes balance + equity + count_positions → close_all_positions.
#
# WHAT THIS DEMO COVERS:
#   1. POLICY   - define the drawdown limit and mode
#   2. MONITOR  - balance / equity / count_positions on a loop
#   3. ENFORCE  - close_all_positions when the limit is breached
#
# TUNABLES:  dry_run (false = actually flatten) · max_drawdown (fraction) · checks
#
# RUN:  ruby examples/demos/main.rb 14     (SAFE by default: dry_run reporting)
# ══════════════════════════════════════════════════════════════════════════════

Demos.register("14", "Risk manager          - monitor account / kill-switch") do |sugar, _cfg|
  dry_run = true          # true = report only, never close
  max_drawdown = 0.50     # kill-switch at 50% of balance lost (floating)
  checks = 3

  Demos.sub("1. policy")
  puts format("  max floating drawdown: %.0f%% of balance   mode: %s",
              max_drawdown * 100, dry_run ? "DRY-RUN (report only)" : "ARMED (will flatten)")

  checks.times do |i|
    sleep 1

    # ──────────────────────────────────────────────────────────────────────────────
    #  2.1  balance           — realized funds (excludes floating P/L).
    #  2.2  equity            — balance + floating P/L; the live account value.
    #  2.3  count_positions   — how many positions are at risk right now.
    #       Drawdown = max(0, -(equity − balance)) / balance.
    # ──────────────────────────────────────────────────────────────────────────────
    balance = sugar.balance
    equity  = sugar.equity
    floating = equity - balance
    dd = balance.zero? ? 0.0 : (floating.negative? ? -floating / balance : 0.0)
    open = sugar.count_positions

    Demos.sub("check #{i + 1}/#{checks}")
    puts format("  balance %.2f  equity %.2f  floating %.2f  drawdown %.1f%%  positions %d",
                balance, equity, floating, dd * 100, open)

    # ──────────────────────────────────────────────────────────────────────────────
    #  3.1  close_all_positions — the kill-switch. Fires once drawdown ≥ the limit;
    #       in dry_run we only report what WOULD happen.
    # ──────────────────────────────────────────────────────────────────────────────
    if dd >= max_drawdown
      if dry_run
        puts "  #{Demos::C[:yellow]}KILL-SWITCH would fire (dry-run): close all #{open} positions#{Demos::C[:reset]}"
      else
        puts "  #{Demos::C[:yellow]}KILL-SWITCH firing: closing all positions#{Demos::C[:reset]}"
        sugar.close_all_positions
      end
      break
    end
  end
  puts "  done — within risk limits."
end
