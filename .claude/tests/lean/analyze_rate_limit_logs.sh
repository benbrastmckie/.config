#!/usr/bin/env bash
# Analyze search tool logs for MCP rate limit compliance testing

set -euo pipefail

# Input: Directory containing search tool logs
LOG_DIR="${1:-.claude/specs/028_lean_subagent_orchestration/debug/search_tool_logs}"

if [ ! -d "$LOG_DIR" ]; then
  echo "ERROR: Log directory not found: $LOG_DIR"
  exit 1
fi

echo "═══════════════════════════════════════════════════════════"
echo " MCP RATE LIMIT COORDINATION ANALYSIS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Count total log files (one per agent)
TOTAL_AGENTS=$(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l)
echo "Total Agents: $TOTAL_AGENTS"
echo ""

# Analyze by wave
for wave_num in 1 2 3 4 5; do
  wave_logs=$(ls "$LOG_DIR"/wave_${wave_num}_*.log 2>/dev/null || echo "")

  if [ -z "$wave_logs" ]; then
    continue
  fi

  agent_count=$(echo "$wave_logs" | wc -l)

  echo "───────────────────────────────────────────────────────────"
  echo " WAVE $wave_num: $agent_count agents"
  echo "───────────────────────────────────────────────────────────"

  # Extract budget allocation
  budget_allocated=$(grep "Budget Allocated:" "$LOG_DIR"/wave_${wave_num}_*.log | head -1 | awk '{print $NF}')
  echo "Budget Allocated per Agent: $budget_allocated"

  # Count external requests per agent
  total_external=0
  for log_file in $wave_logs; do
    agent_name=$(basename "$log_file" .log | sed "s/wave_${wave_num}_agent_//")

    # Count external search tool uses (BUDGET CONSUMED markers)
    external_count=$(grep -c "BUDGET CONSUMED" "$log_file" 2>/dev/null || echo "0")

    # Count local search uses (no budget consumed)
    local_count=$(grep -c "lean_local_search (no budget consumed)" "$log_file" 2>/dev/null || echo "0")

    # Extract budget consumed from final summary
    budget_consumed=$(grep "Total Budget Consumed:" "$log_file" | awk '{print $4}' | cut -d'/' -f1)

    echo "  Agent: $agent_name"
    echo "    Local Searches: $local_count"
    echo "    External Searches: $external_count"
    echo "    Budget Consumed: $budget_consumed"

    total_external=$((total_external + external_count))
  done

  echo ""
  echo "Wave $wave_num Summary:"
  echo "  Total External Requests: $total_external"

  if [ "$total_external" -le 3 ]; then
    echo "  Rate Limit Status: ✅ COMPLIANT (≤ 3 requests)"
  else
    echo "  Rate Limit Status: ❌ VIOLATION (> 3 requests)"
  fi
  echo ""
done

echo "═══════════════════════════════════════════════════════════"
echo " COMPLIANCE VERIFICATION"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Overall compliance check
for wave_num in 1 2 3 4 5; do
  wave_logs=$(ls "$LOG_DIR"/wave_${wave_num}_*.log 2>/dev/null || echo "")

  if [ -z "$wave_logs" ]; then
    continue
  fi

  total_external=0
  for log_file in $wave_logs; do
    external_count=$(grep -c "BUDGET CONSUMED" "$log_file" 2>/dev/null || echo "0")
    total_external=$((total_external + external_count))
  done

  if [ "$total_external" -le 3 ]; then
    echo "Wave $wave_num: ✅ PASS"
  else
    echo "Wave $wave_num: ❌ FAIL ($total_external external requests, expected ≤ 3)"
  fi
done

echo ""

# Check for local search prioritization
echo "───────────────────────────────────────────────────────────"
echo " LOCAL SEARCH PRIORITIZATION"
echo "───────────────────────────────────────────────────────────"
echo ""

all_logs=$(ls "$LOG_DIR"/*.log 2>/dev/null || echo "")

if [ -n "$all_logs" ]; then
  for log_file in $all_logs; do
    agent_name=$(basename "$log_file" .log)

    # Check if local search was attempted first
    first_search=$(grep -E "Attempting (lean_local_search|lean_leansearch|lean_loogle)" "$log_file" | head -1)

    if echo "$first_search" | grep -q "lean_local_search"; then
      echo "  $agent_name: ✅ lean_local_search attempted first"
    else
      echo "  $agent_name: ❌ Did not attempt lean_local_search first"
    fi
  done
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo " ANALYSIS COMPLETE"
echo "═══════════════════════════════════════════════════════════"
