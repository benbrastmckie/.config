#!/usr/bin/env bash
# context_metrics_dashboard.sh - Context reduction metrics dashboard
# Part of hierarchical agent context preservation system
#
# Usage:
#   ./context_metrics_dashboard.sh [--format text|json] [--log-file PATH]
#
# Generates:
#   - Average reduction percentage
#   - Max/min reduction
#   - Commands with highest context usage
#   - Improvement recommendations

set -euo pipefail

# ==============================================================================
# Configuration
# ==============================================================================

: "${CLAUDE_PROJECT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

METRICS_LOG="${CLAUDE_PROJECT_DIR}/.claude/data/logs/context-metrics.log"
OUTPUT_FORMAT="text"  # text or json

# ==============================================================================
# Argument Parsing
# ==============================================================================

while [[ $# -gt 0 ]]; do
  case $1 in
    --format)
      OUTPUT_FORMAT="$2"
      shift 2
      ;;
    --log-file)
      METRICS_LOG="$2"
      shift 2
      ;;
    --help)
      cat <<EOF
Usage: context_metrics_dashboard.sh [OPTIONS]

Generate context reduction metrics dashboard from logs.

OPTIONS:
  --format FORMAT     Output format: text or json (default: text)
  --log-file PATH     Path to context metrics log (default: .claude/data/logs/context-metrics.log)
  --help              Show this help message

EXAMPLES:
  ./context_metrics_dashboard.sh
  ./context_metrics_dashboard.sh --format json
  ./context_metrics_dashboard.sh --log-file /path/to/custom.log
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# ==============================================================================
# Utility Functions
# ==============================================================================

# check_log_file: Verify log file exists
check_log_file() {
  if [ ! -f "$METRICS_LOG" ]; then
    echo "Error: Context metrics log not found: $METRICS_LOG" >&2
    echo "No metrics have been logged yet. Run commands with context metrics tracking enabled." >&2
    return 1
  fi
  return 0
}

# parse_metrics: Extract metrics from log file
parse_metrics() {
  # Extract all CONTEXT_BEFORE and CONTEXT_AFTER entries
  local before_entries=$(grep "CONTEXT_BEFORE" "$METRICS_LOG" 2>/dev/null || echo "")
  local after_entries=$(grep "CONTEXT_AFTER" "$METRICS_LOG" 2>/dev/null || echo "")

  # Count total operations
  local operation_count=$(echo "$before_entries" | grep -c "CONTEXT_BEFORE" || echo "0")

  if [ "$operation_count" -eq 0 ]; then
    echo "No context metrics found in log file" >&2
    return 1
  fi

  echo "operation_count=$operation_count"
  echo "before_entries<<EOF"
  echo "$before_entries"
  echo "EOF"
  echo "after_entries<<EOF"
  echo "$after_entries"
  echo "EOF"
}

# calculate_statistics: Calculate reduction statistics
calculate_statistics() {
  local before_entries="$1"
  local after_entries="$2"

  # Arrays to store values
  local -a operations=()
  local -a reductions=()
  local -a before_tokens=()
  local -a after_tokens=()

  # Parse before entries
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      local op=$(echo "$line" | grep -oE 'operation=[^ ]+' | cut -d= -f2)
      local tokens=$(echo "$line" | grep -oE 'tokens=[0-9]+' | cut -d= -f2)

      operations+=("$op")
      before_tokens+=("$tokens")
    fi
  done <<< "$before_entries"

  # Parse after entries
  local idx=0
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      local tokens=$(echo "$line" | grep -oE 'tokens=[0-9]+' | cut -d= -f2)
      after_tokens+=("$tokens")

      # Calculate reduction for this operation
      if [ "$idx" -lt "${#before_tokens[@]}" ]; then
        local before="${before_tokens[$idx]}"
        local after="$tokens"
        if [ "$before" -gt 0 ]; then
          local reduction=$(( (before - after) * 100 / before ))
          reductions+=("$reduction")
        else
          reductions+=("0")
        fi
      fi

      idx=$((idx + 1))
    fi
  done <<< "$after_entries"

  # Calculate summary statistics
  local total_reduction=0
  local max_reduction=0
  local min_reduction=100
  local count="${#reductions[@]}"

  for reduction in "${reductions[@]}"; do
    total_reduction=$((total_reduction + reduction))

    if [ "$reduction" -gt "$max_reduction" ]; then
      max_reduction="$reduction"
    fi

    if [ "$reduction" -lt "$min_reduction" ]; then
      min_reduction="$reduction"
    fi
  done

  local avg_reduction=0
  if [ "$count" -gt 0 ]; then
    avg_reduction=$((total_reduction / count))
  fi

  # Find operations with highest context usage (lowest reduction)
  local -a high_usage_ops=()
  local -a high_usage_reductions=()

  for i in "${!operations[@]}"; do
    local op="${operations[$i]}"
    local red="${reductions[$i]:-0}"

    if [ "$red" -lt 70 ]; then
      high_usage_ops+=("$op")
      high_usage_reductions+=("$red")
    fi
  done

  # Output results
  echo "count=$count"
  echo "avg_reduction=$avg_reduction"
  echo "max_reduction=$max_reduction"
  echo "min_reduction=$min_reduction"
  echo "high_usage_count=${#high_usage_ops[@]}"

  for i in "${!high_usage_ops[@]}"; do
    echo "high_usage_$i=${high_usage_ops[$i]}:${high_usage_reductions[$i]}"
  done
}

# ==============================================================================
# Output Functions
# ==============================================================================

# output_text: Generate text dashboard
output_text() {
  local stats="$1"

  # Parse statistics
  local count=$(echo "$stats" | grep "^count=" | cut -d= -f2)
  local avg_reduction=$(echo "$stats" | grep "^avg_reduction=" | cut -d= -f2)
  local max_reduction=$(echo "$stats" | grep "^max_reduction=" | cut -d= -f2)
  local min_reduction=$(echo "$stats" | grep "^min_reduction=" | cut -d= -f2)
  local high_usage_count=$(echo "$stats" | grep "^high_usage_count=" | cut -d= -f2)

  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT REDUCTION METRICS DASHBOARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Operations Tracked: $count

Summary Statistics:
  Average Reduction:  $avg_reduction%
  Maximum Reduction:  $max_reduction%
  Minimum Reduction:  $min_reduction%

Target Metrics:
  Minimum Target:     60% reduction
  Status:             $([ "$avg_reduction" -ge 60 ] && echo "✓ Target Met" || echo "✗ Below Target")

EOF

  if [ "$high_usage_count" -gt 0 ]; then
    echo "Operations with High Context Usage (<70% reduction):"
    echo ""

    local idx=0
    while true; do
      local entry=$(echo "$stats" | grep "^high_usage_$idx=" 2>/dev/null || echo "")
      if [ -z "$entry" ]; then
        break
      fi

      local op=$(echo "$entry" | cut -d= -f2 | cut -d: -f1)
      local reduction=$(echo "$entry" | cut -d: -f2)

      echo "  • $op: $reduction% reduction"

      idx=$((idx + 1))
    done

    echo ""
    echo "Recommendations:"
    echo "  1. Review operations with <70% reduction"
    echo "  2. Ensure metadata-only passing is used"
    echo "  3. Apply aggressive context pruning after phases"
    echo "  4. Verify forward_message pattern usage"
  else
    echo "Performance: All operations achieve ≥70% context reduction"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# output_json: Generate JSON dashboard
output_json() {
  local stats="$1"

  # Parse statistics
  local count=$(echo "$stats" | grep "^count=" | cut -d= -f2)
  local avg_reduction=$(echo "$stats" | grep "^avg_reduction=" | cut -d= -f2)
  local max_reduction=$(echo "$stats" | grep "^max_reduction=" | cut -d= -f2)
  local min_reduction=$(echo "$stats" | grep "^min_reduction=" | cut -d= -f2)
  local high_usage_count=$(echo "$stats" | grep "^high_usage_count=" | cut -d= -f2)

  # Build high usage operations JSON
  local high_usage_json="[]"
  if [ "$high_usage_count" -gt 0 ]; then
    local ops_json="["
    local idx=0

    while true; do
      local entry=$(echo "$stats" | grep "^high_usage_$idx=" 2>/dev/null || echo "")
      if [ -z "$entry" ]; then
        break
      fi

      local op=$(echo "$entry" | cut -d= -f2 | cut -d: -f1)
      local reduction=$(echo "$entry" | cut -d: -f2)

      if [ "$idx" -gt 0 ]; then
        ops_json+=","
      fi

      ops_json+="{\"operation\":\"$op\",\"reduction\":$reduction}"

      idx=$((idx + 1))
    done

    ops_json+="]"
    high_usage_json="$ops_json"
  fi

  # Generate JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg count "$count" \
      --arg avg "$avg_reduction" \
      --arg max "$max_reduction" \
      --arg min "$min_reduction" \
      --argjson high_usage "$high_usage_json" \
      '{
        operations_tracked: ($count | tonumber),
        statistics: {
          average_reduction: ($avg | tonumber),
          maximum_reduction: ($max | tonumber),
          minimum_reduction: ($min | tonumber)
        },
        targets: {
          minimum_target: 60,
          target_met: (($avg | tonumber) >= 60)
        },
        high_usage_operations: $high_usage
      }'
  else
    cat <<EOF
{
  "operations_tracked": $count,
  "statistics": {
    "average_reduction": $avg_reduction,
    "maximum_reduction": $max_reduction,
    "minimum_reduction": $min_reduction
  },
  "targets": {
    "minimum_target": 60,
    "target_met": $([ "$avg_reduction" -ge 60 ] && echo "true" || echo "false")
  },
  "high_usage_operations": $high_usage_json
}
EOF
  fi
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
  # Check log file exists
  if ! check_log_file; then
    return 1
  fi

  # Parse metrics from log
  local metrics=$(parse_metrics)

  if [ $? -ne 0 ]; then
    echo "Error: Failed to parse metrics from log file" >&2
    return 1
  fi

  # Extract before/after entries
  local before_entries=$(echo "$metrics" | sed -n '/before_entries<<EOF/,/^EOF$/p' | sed '1d;$d')
  local after_entries=$(echo "$metrics" | sed -n '/after_entries<<EOF/,/^EOF$/p' | sed '1d;$d')

  # Calculate statistics
  local stats=$(calculate_statistics "$before_entries" "$after_entries")

  # Generate output
  if [ "$OUTPUT_FORMAT" = "json" ]; then
    output_json "$stats"
  else
    output_text "$stats"
  fi

  return 0
}

# Run main function
main "$@"
