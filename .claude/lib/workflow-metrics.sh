#!/usr/bin/env bash
#
# Workflow Metrics Aggregation Utility
# Aggregates data from adaptive-planning.log and agent-registry.json
#
# Usage:
#   source .claude/lib/workflow-metrics.sh
#   aggregate_workflow_times | jq .
#   aggregate_agent_metrics | jq .
#   aggregate_complexity_metrics | jq .
#   generate_performance_report

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"

# ==============================================================================
# Workflow Time Aggregation
# ==============================================================================

# aggregate_workflow_times: Extract timing data from adaptive-planning.log
# Usage: aggregate_workflow_times
# Returns: JSON with workflow timing metrics
aggregate_workflow_times() {
  local log_file="${CLAUDE_PROJECT_DIR}/.claude/logs/adaptive-planning.log"

  if [ ! -f "$log_file" ]; then
    echo '{"error":"Log file not found"}'
    return 1
  fi

  # Extract workflow start/end timestamps (simplified - real implementation needs parsing)
  local workflow_start=$(grep "WORKFLOW_START" "$log_file" | tail -1 | awk '{print $1" "$2}')
  local workflow_end=$(grep "WORKFLOW_END" "$log_file" | tail -1 | awk '{print $1" "$2}')

  # Calculate duration (requires date manipulation - simplified here)
  local duration_seconds=0
  if [ -n "$workflow_start" ] && [ -n "$workflow_end" ]; then
    local start_epoch=$(date -d "$workflow_start" +%s 2>/dev/null || echo "0")
    local end_epoch=$(date -d "$workflow_end" +%s 2>/dev/null || echo "0")
    duration_seconds=$((end_epoch - start_epoch))
  fi

  # Count phases
  local total_phases=$(grep -c "PHASE_START" "$log_file" || echo "0")
  local completed_phases=$(grep -c "PHASE_COMPLETE" "$log_file" || echo "0")

  # Average time per phase
  local avg_phase_time=0
  if [ "$completed_phases" -gt 0 ]; then
    avg_phase_time=$((duration_seconds / completed_phases))
  fi

  # Build JSON
  jq -n \
    --argjson duration "$duration_seconds" \
    --argjson total "$total_phases" \
    --argjson completed "$completed_phases" \
    --argjson avg "$avg_phase_time" \
    '{
      workflow_duration_seconds: $duration,
      total_phases: $total,
      completed_phases: $completed,
      avg_phase_time_seconds: $avg
    }'
}

# ==============================================================================
# Agent Metrics Aggregation
# ==============================================================================

# aggregate_agent_metrics: Extract agent performance from agent-registry.json
# Usage: aggregate_agent_metrics
# Returns: JSON with agent invocation statistics
aggregate_agent_metrics() {
  local registry_file="${CLAUDE_PROJECT_DIR}/.claude/agents/agent-registry.json"

  if [ ! -f "$registry_file" ]; then
    echo '{"error":"Agent registry not found"}'
    return 1
  fi

  # Extract agent metrics using jq
  jq '{
    total_agents: (.agents | length),
    agent_summary: [
      .agents | to_entries[] | {
        agent_type: .key,
        invocations: .value.invocations,
        successes: .value.successes,
        failures: .value.failures,
        success_rate: (if .value.invocations > 0 then (.value.successes / .value.invocations * 100) else 0 end),
        avg_duration: .value.avg_duration
      }
    ]
  }' "$registry_file"
}

# ==============================================================================
# Complexity Metrics Aggregation
# ==============================================================================

# aggregate_complexity_metrics: Extract complexity evaluation stats from log
# Usage: aggregate_complexity_metrics
# Returns: JSON with complexity evaluation statistics
aggregate_complexity_metrics() {
  local log_file="${CLAUDE_PROJECT_DIR}/.claude/logs/adaptive-planning.log"

  if [ ! -f "$log_file" ]; then
    echo '{"error":"Log file not found"}'
    return 1
  fi

  # Count evaluation methods
  local threshold_only=$(grep -c "evaluation_method.*threshold\"" "$log_file" 2>/dev/null || echo "0")
  local agent_used=$(grep -c "evaluation_method.*agent\"" "$log_file" 2>/dev/null || echo "0")
  local hybrid_used=$(grep -c "evaluation_method.*hybrid\"" "$log_file" 2>/dev/null || echo "0")

  # Count discrepancies
  local discrepancies=$(grep -c "complexity_discrepancy" "$log_file" 2>/dev/null || echo "0")

  # Total evaluations
  local total_evaluations=$((threshold_only + agent_used + hybrid_used))

  # Build JSON
  jq -n \
    --argjson total "$total_evaluations" \
    --argjson threshold "$threshold_only" \
    --argjson agent "$agent_used" \
    --argjson hybrid "$hybrid_used" \
    --argjson discrepancies "$discrepancies" \
    '{
      total_evaluations: $total,
      threshold_only: $threshold,
      agent_overrides: $agent,
      hybrid_averages: $hybrid,
      score_discrepancies: $discrepancies,
      agent_invocation_rate: (if $total > 0 then (($agent + $hybrid) / $total * 100) else 0 end)
    }'
}

# ==============================================================================
# Performance Report Generation
# ==============================================================================

# generate_performance_report: Create markdown performance report
# Usage: generate_performance_report
# Returns: Markdown formatted report
generate_performance_report() {
  local workflow_metrics
  workflow_metrics=$(aggregate_workflow_times)

  local agent_metrics
  agent_metrics=$(aggregate_agent_metrics)

  local complexity_metrics
  complexity_metrics=$(aggregate_complexity_metrics)

  # Extract values
  local duration=$(echo "$workflow_metrics" | jq -r '.workflow_duration_seconds // 0')
  local total_phases=$(echo "$workflow_metrics" | jq -r '.total_phases // 0')
  local completed_phases=$(echo "$workflow_metrics" | jq -r '.completed_phases // 0')

  local total_agents=$(echo "$agent_metrics" | jq -r '.total_agents // 0')
  local agent_summary=$(echo "$agent_metrics" | jq -r '.agent_summary // []')

  local total_evals=$(echo "$complexity_metrics" | jq -r '.total_evaluations // 0')
  local agent_rate=$(echo "$complexity_metrics" | jq -r '.agent_invocation_rate // 0')

  # Generate markdown report
  cat <<EOF
# Workflow Performance Report

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

## Workflow Summary

- **Total Duration**: ${duration}s ($(($duration / 60))m $(($duration % 60))s)
- **Phases**: $completed_phases / $total_phases completed
- **Average Phase Time**: $(echo "$workflow_metrics" | jq -r '.avg_phase_time_seconds')s

## Agent Performance

- **Total Agents Used**: $total_agents
- **Agent Invocation Summary**:

$(echo "$agent_summary" | jq -r '.[] | "  - **\(.agent_type)**: \(.invocations) invocations, \(.success_rate | floor)% success rate, \(.avg_duration)s avg"')

## Complexity Evaluation

- **Total Evaluations**: $total_evals
- **Agent Invocation Rate**: ${agent_rate}%
- **Threshold-Only**: $(echo "$complexity_metrics" | jq -r '.threshold_only')
- **Agent Overrides**: $(echo "$complexity_metrics" | jq -r '.agent_overrides')
- **Hybrid Averages**: $(echo "$complexity_metrics" | jq -r '.hybrid_averages')
- **Score Discrepancies**: $(echo "$complexity_metrics" | jq -r '.score_discrepancies')

---

*Report generated by workflow-metrics.sh*
EOF
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f aggregate_workflow_times
  export -f aggregate_agent_metrics
  export -f aggregate_complexity_metrics
  export -f generate_performance_report
fi
