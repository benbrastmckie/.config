#!/usr/bin/env bash
# context-metrics.sh - Context preservation metrics tracking
# Part of .claude/lib/ modular utilities
#
# Primary Functions:
#   track_context_usage - Track context usage before/after operations
#   calculate_context_reduction - Calculate reduction percentage
#   log_context_metrics - Log metrics to file
#   generate_context_report - Generate summary report
#
# Usage:
#   source "${BASH_SOURCE%/*}/context-metrics.sh"
#   track_context_usage "before" "operation_name"
#   track_context_usage "after" "operation_name"

set -euo pipefail

# ==============================================================================
# Environment Setup
# ==============================================================================

# Set CLAUDE_PROJECT_DIR if not already set
: "${CLAUDE_PROJECT_DIR:=$(pwd)}"

# ==============================================================================
# Constants
# ==============================================================================

readonly CONTEXT_METRICS_LOG="${CLAUDE_PROJECT_DIR}/.claude/data/logs/context-metrics.log"
readonly CONTEXT_METRICS_MAX_SIZE=10485760  # 10MB

# ==============================================================================
# Context Tracking Functions
# ==============================================================================

# track_context_usage: Track context usage at a point in workflow
# Usage: track_context_usage <phase> <operation> [content]
# Phase: "before" or "after"
# Returns: Estimated token count
# Example: track_context_usage "before" "research_phase" "$research_content"
track_context_usage() {
  local phase="${1:-}"
  local operation="${2:-}"
  local content="${3:-}"

  if [ -z "$phase" ] || [ -z "$operation" ]; then
    echo "Usage: track_context_usage <before|after> <operation> [content]" >&2
    return 1
  fi

  # Estimate token count (rough: 1 token ≈ 4 characters)
  local char_count=0
  if [ -n "$content" ]; then
    char_count=$(echo "$content" | wc -c | tr -d ' ')
  fi
  local token_estimate=$((char_count / 4))

  # Log metrics
  log_context_metrics "$phase" "$operation" "$token_estimate" "$char_count"

  echo "$token_estimate"
}

# log_context_metrics: Log context metrics to file
# Usage: log_context_metrics <phase> <operation> <tokens> <chars>
# Example: log_context_metrics "before" "research" 1000 4000
log_context_metrics() {
  local phase="${1:-}"
  local operation="${2:-}"
  local tokens="${3:-0}"
  local chars="${4:-0}"

  # Ensure log directory exists
  local log_dir=$(dirname "$CONTEXT_METRICS_LOG")
  mkdir -p "$log_dir"

  # Create log entry
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local log_entry="[$timestamp] CONTEXT_${phase^^}: operation=$operation tokens=$tokens chars=$chars"

  echo "$log_entry" >> "$CONTEXT_METRICS_LOG"

  # Rotate log if needed
  if [ -f "$CONTEXT_METRICS_LOG" ] && [ $(wc -c < "$CONTEXT_METRICS_LOG") -gt "$CONTEXT_METRICS_MAX_SIZE" ]; then
    rotate_context_log
  fi
}

# calculate_context_reduction: Calculate reduction percentage
# Usage: calculate_context_reduction <before_tokens> <after_tokens>
# Returns: Reduction percentage
# Example: calculate_context_reduction 1000 300
calculate_context_reduction() {
  local before="${1:-0}"
  local after="${2:-0}"

  if [ "$before" -eq 0 ]; then
    echo "0"
    return 0
  fi

  local reduction=$(( (before - after) * 100 / before ))
  echo "$reduction"
}

# rotate_context_log: Rotate context metrics log
# Usage: rotate_context_log
rotate_context_log() {
  if [ ! -f "$CONTEXT_METRICS_LOG" ]; then
    return 0
  fi

  # Rotate logs (keep 5 files)
  for i in {4..1}; do
    if [ -f "${CONTEXT_METRICS_LOG}.$i" ]; then
      mv "${CONTEXT_METRICS_LOG}.$i" "${CONTEXT_METRICS_LOG}.$((i+1))"
    fi
  done

  mv "$CONTEXT_METRICS_LOG" "${CONTEXT_METRICS_LOG}.1"
  touch "$CONTEXT_METRICS_LOG"
}

# ==============================================================================
# Reporting Functions
# ==============================================================================

# generate_context_report: Generate summary report from metrics log
# Usage: generate_context_report [operation-pattern]
# Returns: Summary statistics
# Example: generate_context_report "research"
generate_context_report() {
  local operation_pattern="${1:-.*}"

  if [ ! -f "$CONTEXT_METRICS_LOG" ]; then
    echo "No context metrics logged yet"
    return 0
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Context Metrics Report"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Extract metrics for operation
  local before_entries=$(grep "CONTEXT_BEFORE.*operation=$operation_pattern" "$CONTEXT_METRICS_LOG" 2>/dev/null || echo "")
  local after_entries=$(grep "CONTEXT_AFTER.*operation=$operation_pattern" "$CONTEXT_METRICS_LOG" 2>/dev/null || echo "")

  if [ -z "$before_entries" ] && [ -z "$after_entries" ]; then
    echo "No metrics found for pattern: $operation_pattern"
    return 0
  fi

  # Calculate statistics
  local total_before=0
  local total_after=0
  local count=0

  while IFS= read -r entry; do
    if [ -n "$entry" ]; then
      local tokens=$(echo "$entry" | grep -oE 'tokens=[0-9]+' | cut -d= -f2)
      total_before=$((total_before + tokens))
      count=$((count + 1))
    fi
  done <<< "$before_entries"

  while IFS= read -r entry; do
    if [ -n "$entry" ]; then
      local tokens=$(echo "$entry" | grep -oE 'tokens=[0-9]+' | cut -d= -f2)
      total_after=$((total_after + tokens))
    fi
  done <<< "$after_entries"

  if [ "$count" -gt 0 ]; then
    local avg_before=$((total_before / count))
    local avg_after=$((total_after / count))
    local avg_reduction=$(calculate_context_reduction "$avg_before" "$avg_after")

    echo "Operations matched: $count"
    echo "Average context before: $avg_before tokens"
    echo "Average context after: $avg_after tokens"
    echo "Average reduction: $avg_reduction%"
  else
    echo "No complete before/after pairs found"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# get_context_metrics_summary: Get concise metrics summary
# Usage: get_context_metrics_summary <operation>
# Returns: JSON with metrics
# Example: get_context_metrics_summary "research_phase"
get_context_metrics_summary() {
  local operation="${1:-}"

  if [ -z "$operation" ]; then
    echo "Usage: get_context_metrics_summary <operation>" >&2
    return 1
  fi

  if [ ! -f "$CONTEXT_METRICS_LOG" ]; then
    echo '{"error":"No metrics logged"}'
    return 1
  fi

  # Get most recent before/after for this operation
  local before_entry=$(grep "CONTEXT_BEFORE.*operation=$operation" "$CONTEXT_METRICS_LOG" | tail -1)
  local after_entry=$(grep "CONTEXT_AFTER.*operation=$operation" "$CONTEXT_METRICS_LOG" | tail -1)

  if [ -z "$before_entry" ] || [ -z "$after_entry" ]; then
    echo '{"error":"Incomplete metrics for operation"}'
    return 1
  fi

  local before_tokens=$(echo "$before_entry" | grep -oE 'tokens=[0-9]+' | cut -d= -f2)
  local after_tokens=$(echo "$after_entry" | grep -oE 'tokens=[0-9]+' | cut -d= -f2)
  local reduction=$(calculate_context_reduction "$before_tokens" "$after_tokens")

  if command -v jq &> /dev/null; then
    jq -n \
      --arg op "$operation" \
      --arg before "$before_tokens" \
      --arg after "$after_tokens" \
      --arg reduction "$reduction" \
      '{
        operation: $op,
        context_before: ($before | tonumber),
        context_after: ($after | tonumber),
        reduction_percent: ($reduction | tonumber)
      }'
  else
    cat <<EOF
{
  "operation": "$operation",
  "context_before": $before_tokens,
  "context_after": $after_tokens,
  "reduction_percent": $reduction
}
EOF
  fi
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f track_context_usage
  export -f log_context_metrics
  export -f calculate_context_reduction
  export -f rotate_context_log
  export -f generate_context_report
  export -f get_context_metrics_summary
fi
