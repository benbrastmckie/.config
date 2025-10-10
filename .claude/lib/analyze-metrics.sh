#!/usr/bin/env bash
# analyze-metrics.sh - Metrics aggregation and analysis utilities
#
# Purpose: Provide automated analysis of command and agent metrics
# Usage: Source this file and call functions directly, or use via /analyze command

set -euo pipefail

# Get the script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METRICS_DIR="${METRICS_DIR:-$SCRIPT_DIR/../data/metrics}"

# Function: analyze_command_metrics
# Description: Parse command execution times and success rates
# Arguments:
#   $1 - Timeframe in days (default: 30)
# Returns: JSON object with command metrics
analyze_command_metrics() {
  local timeframe_days="${1:-30}"
  local cutoff_date
  cutoff_date=$(date -d "$timeframe_days days ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
                date -v-"${timeframe_days}d" +%Y-%m-%dT%H:%M:%S 2>/dev/null)

  local metrics_file="$METRICS_DIR/2025-10.jsonl"

  if [[ ! -f "$metrics_file" ]]; then
    echo "ERROR: Metrics file not found: $metrics_file" >&2
    return 1
  fi

  # Parse JSONL and filter by timeframe
  jq -r --arg cutoff "$cutoff_date" '
    select(.timestamp >= $cutoff) |
    select(.operation != "unknown") |
    {
      operation: .operation,
      duration_ms: .duration_ms,
      status: .status,
      timestamp: .timestamp
    }
  ' "$metrics_file" 2>/dev/null || true
}

# Function: analyze_agent_metrics
# Description: Parse agent performance data
# Arguments:
#   $1 - Timeframe in days (default: 30)
# Returns: JSON object with agent metrics
analyze_agent_metrics() {
  local timeframe_days="${1:-30}"
  local agent_metrics_dir="$METRICS_DIR/agents"

  if [[ ! -d "$agent_metrics_dir" ]]; then
    echo "INFO: Agent metrics directory not found" >&2
    return 0
  fi

  local cutoff_date
  cutoff_date=$(date -d "$timeframe_days days ago" +%Y-%m-%dT%H:%M:%S 2>/dev/null || \
                date -v-"${timeframe_days}d" +%Y-%m-%dT%H:%M:%S 2>/dev/null)

  # Aggregate metrics from all agent JSONL files
  for agent_file in "$agent_metrics_dir"/*.jsonl; do
    [[ -f "$agent_file" ]] || continue

    local agent_name
    agent_name=$(basename "$agent_file" .jsonl)

    jq -r --arg cutoff "$cutoff_date" --arg agent "$agent_name" '
      select(.timestamp >= $cutoff) |
      {
        agent: $agent,
        duration_ms: .duration_ms,
        status: .status,
        tools_used: .tools_used,
        error: .error,
        timestamp: .timestamp
      }
    ' "$agent_file" 2>/dev/null || true
  done
}

# Function: identify_bottlenecks
# Description: Find slowest phases and most common failures
# Arguments:
#   $1 - Metrics JSON data (from stdin or argument)
# Returns: Markdown report of bottlenecks
identify_bottlenecks() {
  local metrics_data="${1:-}"

  if [[ -z "$metrics_data" ]]; then
    # Read from stdin if no argument
    metrics_data=$(cat)
  fi

  echo "## Performance Bottlenecks"
  echo ""

  # Find slowest operations (top 5)
  echo "### Slowest Operations"
  echo ""
  echo "$metrics_data" | jq -r '
    select(.duration_ms != null and .duration_ms > 0) |
    "\(.operation)|\(.duration_ms)"
  ' | sort -t'|' -k2 -nr | head -5 | while IFS='|' read -r operation duration; do
    local duration_sec=$((duration / 1000))
    echo "- $operation: ${duration_sec}s (${duration}ms)"
  done
  echo ""

  # Find most common failures
  echo "### Most Common Failures"
  echo ""
  local failures
  failures=$(echo "$metrics_data" | jq -r '
    select(.status == "error" or .status == "failed") |
    .operation
  ' | sort | uniq -c | sort -rn | head -5)

  if [[ -n "$failures" ]]; then
    echo "$failures" | while read -r count operation; do
      echo "- $operation: $count failures"
    done
  else
    echo "No failures found in timeframe"
  fi
  echo ""
}

# Function: calculate_template_effectiveness
# Description: Compare template vs manual plan creation times
# Arguments:
#   $1 - Timeframe in days (default: 30)
# Returns: Markdown comparison report
calculate_template_effectiveness() {
  local timeframe_days="${1:-30}"

  echo "## Template Effectiveness Analysis"
  echo ""

  # Get command metrics
  local command_data
  command_data=$(analyze_command_metrics "$timeframe_days")

  # Calculate average times for template vs manual planning
  local template_avg manual_avg
  template_avg=$(echo "$command_data" | jq -r '
    select(.operation == "plan-from-template") |
    .duration_ms
  ' | awk '{sum+=$1; count++} END {if (count>0) print int(sum/count); else print 0}')

  manual_avg=$(echo "$command_data" | jq -r '
    select(.operation == "plan") |
    .duration_ms
  ' | awk '{sum+=$1; count++} END {if (count>0) print int(sum/count); else print 0}')

  if [[ "$template_avg" -gt 0 ]] && [[ "$manual_avg" -gt 0 ]]; then
    local savings_pct=$(( (manual_avg - template_avg) * 100 / manual_avg ))
    echo "- Template-based planning: $(( template_avg / 1000 ))s average"
    echo "- Manual planning: $(( manual_avg / 1000 ))s average"
    echo "- Time savings: ${savings_pct}% faster with templates"
  else
    echo "Insufficient data for template effectiveness analysis"
  fi
  echo ""
}

# Function: generate_trend_report
# Description: Monthly trend analysis
# Arguments:
#   $1 - Timeframe in days (default: 30)
# Returns: Markdown trend report with ASCII charts
generate_trend_report() {
  local timeframe_days="${1:-30}"

  echo "## Usage Trends (Last $timeframe_days Days)"
  echo ""

  # Get command metrics
  local command_data
  command_data=$(analyze_command_metrics "$timeframe_days")

  # Count operations by type
  echo "### Command Usage"
  echo ""
  local usage_counts
  usage_counts=$(echo "$command_data" | jq -r '.operation' | sort | uniq -c | sort -rn)

  if [[ -n "$usage_counts" ]]; then
    # Find max count for scaling
    local max_count
    max_count=$(echo "$usage_counts" | head -1 | awk '{print $1}')

    echo "$usage_counts" | while read -r count operation; do
      local bar_length=$(( count * 40 / max_count ))
      local bar
      bar=$(printf '%*s' "$bar_length" | tr ' ' '█')
      printf "%-25s %3d %s\n" "$operation" "$count" "$bar"
    done
  else
    echo "No usage data available for timeframe"
  fi
  echo ""

  # Success rate over time
  echo "### Success Rate"
  echo ""
  local total_ops success_ops
  total_ops=$(echo "$command_data" | jq -s 'length')
  success_ops=$(echo "$command_data" | jq -r 'select(.status == "success")' | jq -s 'length')

  if [[ "$total_ops" -gt 0 ]]; then
    local success_rate=$(( success_ops * 100 / total_ops ))
    echo "- Total operations: $total_ops"
    echo "- Successful: $success_ops"
    echo "- Success rate: ${success_rate}%"
  else
    echo "No operations data available"
  fi
  echo ""
}

# Function: generate_recommendations
# Description: Data-driven optimization suggestions
# Arguments:
#   $1 - Metrics JSON data
# Returns: Markdown recommendations
generate_recommendations() {
  local metrics_data="${1:-}"

  if [[ -z "$metrics_data" ]]; then
    metrics_data=$(cat)
  fi

  echo "## Optimization Recommendations"
  echo ""

  # Analyze failure patterns
  local high_failure_ops
  high_failure_ops=$(echo "$metrics_data" | jq -r '
    select(.status == "error" or .status == "failed") |
    .operation
  ' | sort | uniq -c | sort -rn | head -3)

  if [[ -n "$high_failure_ops" ]]; then
    echo "### High-Failure Operations"
    echo ""
    echo "$high_failure_ops" | while read -r count operation; do
      if [[ "$count" -gt 5 ]]; then
        echo "- **$operation**: $count failures detected"
        echo "  - Review error handling and validation"
        echo "  - Add defensive checks for edge cases"
        echo "  - Consider adding pre-flight validation"
      fi
    done
    echo ""
  fi

  # Analyze slow operations
  local slow_ops
  slow_ops=$(echo "$metrics_data" | jq -r '
    select(.duration_ms != null and .duration_ms > 10000) |
    "\(.operation)|\(.duration_ms)"
  ' | sort -t'|' -k2 -nr | head -3)

  if [[ -n "$slow_ops" ]]; then
    echo "### Performance Optimization Opportunities"
    echo ""
    echo "$slow_ops" | while IFS='|' read -r operation duration; do
      local duration_sec=$((duration / 1000))
      echo "- **$operation**: ${duration_sec}s average"
      echo "  - Profile for bottlenecks"
      echo "  - Consider caching frequently accessed data"
      echo "  - Review I/O operations for optimization"
    done
    echo ""
  fi

  # Template usage analysis
  local template_usage
  template_usage=$(echo "$metrics_data" | jq -r '
    select(.operation == "plan-from-template") |
    .operation
  ' | wc -l)

  local manual_planning
  manual_planning=$(echo "$metrics_data" | jq -r '
    select(.operation == "plan") |
    .operation
  ' | wc -l)

  if [[ "$manual_planning" -gt "$template_usage" ]] && [[ "$manual_planning" -gt 5 ]]; then
    echo "### Template Adoption"
    echo ""
    echo "- Manual planning used ${manual_planning} times vs ${template_usage} template-based"
    echo "  - Consider creating templates for common patterns"
    echo "  - Review recent manual plans for template opportunities"
    echo "  - Promote template usage for faster planning"
    echo ""
  fi
}

# Function: generate_metrics_report
# Description: Generate complete metrics analysis report
# Arguments:
#   $1 - Timeframe in days (default: 30)
#   $2 - Output file path (optional, defaults to stdout)
# Returns: Complete markdown metrics report
generate_metrics_report() {
  local timeframe_days="${1:-30}"
  local output_file="${2:-}"

  local report_content

  # Generate report sections
  report_content="# Metrics Analysis Report\n\n"
  report_content+="Generated: $(date '+%Y-%m-%d %H:%M:%S')\n"
  report_content+="Timeframe: Last $timeframe_days days\n\n"
  report_content+="---\n\n"

  # Get metrics data
  local command_data
  command_data=$(analyze_command_metrics "$timeframe_days")

  if [[ -z "$command_data" ]]; then
    report_content+="No metrics data available for the specified timeframe.\n"
  else
    # Add trend report
    report_content+="$(generate_trend_report "$timeframe_days")\n"

    # Add bottleneck analysis
    report_content+="$(echo "$command_data" | identify_bottlenecks)\n"

    # Add template effectiveness
    report_content+="$(calculate_template_effectiveness "$timeframe_days")\n"

    # Add recommendations
    report_content+="$(echo "$command_data" | generate_recommendations)\n"
  fi

  # Output report
  if [[ -n "$output_file" ]]; then
    echo -e "$report_content" > "$output_file"
    echo "Report saved to: $output_file"
  else
    echo -e "$report_content"
  fi
}

# Only run main function if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Default to 30-day analysis
  timeframe="${1:-30}"
  output_file="${2:-}"

  generate_metrics_report "$timeframe" "$output_file"
fi
