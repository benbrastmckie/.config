#!/usr/bin/env bash
#
# Adaptive Planning Logger
# Provides structured logging for adaptive planning trigger evaluations and replanning events
#
# Usage:
#   source .claude/lib/adaptive-planning-logger.sh
#   log_trigger_evaluation "complexity" "triggered" '{"score": 9.2, "threshold": 8}'
#   log_replan_invocation "expand_phase" "success" "/path/to/updated_plan.md"

set -euo pipefail

# Configuration
readonly AP_LOG_FILE="${CLAUDE_LOGS_DIR:-.claude/logs}/adaptive-planning.log"
readonly AP_LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
readonly AP_LOG_MAX_FILES=5

# Ensure log directory exists
mkdir -p "$(dirname "$AP_LOG_FILE")"

#
# Rotate log file if it exceeds max size
#
rotate_log_if_needed() {
  if [[ ! -f "$AP_LOG_FILE" ]]; then
    return 0
  fi

  local file_size
  file_size=$(stat -f%z "$AP_LOG_FILE" 2>/dev/null || stat -c%s "$AP_LOG_FILE" 2>/dev/null || echo 0)

  if (( file_size >= AP_LOG_MAX_SIZE )); then
    # Rotate logs: .log -> .log.1, .log.1 -> .log.2, etc.
    for ((i = AP_LOG_MAX_FILES - 1; i >= 1; i--)); do
      if [[ -f "${AP_LOG_FILE}.$i" ]]; then
        mv "${AP_LOG_FILE}.$i" "${AP_LOG_FILE}.$((i + 1))"
      fi
    done

    # Move current log to .1
    mv "$AP_LOG_FILE" "${AP_LOG_FILE}.1"

    # Remove oldest if we exceed max files
    if [[ -f "${AP_LOG_FILE}.$((AP_LOG_MAX_FILES + 1))" ]]; then
      rm "${AP_LOG_FILE}.$((AP_LOG_MAX_FILES + 1))"
    fi
  fi
}

#
# Write a structured log entry
# Args:
#   $1: log_level (INFO, WARN, ERROR)
#   $2: event_type
#   $3: message
#   $4: data (optional JSON string)
#
write_log_entry() {
  local log_level="$1"
  local event_type="$2"
  local message="$3"
  local data="${4:-}"

  rotate_log_if_needed

  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  local entry
  if [[ -n "$data" ]]; then
    entry=$(printf '[%s] %s %s: %s | data=%s\n' \
      "$timestamp" "$log_level" "$event_type" "$message" "$data")
  else
    entry=$(printf '[%s] %s %s: %s\n' \
      "$timestamp" "$log_level" "$event_type" "$message")
  fi

  echo "$entry" >> "$AP_LOG_FILE"
}

#
# Log a trigger evaluation
# Args:
#   $1: trigger_type (complexity|test_failure|scope_drift)
#   $2: result (triggered|not_triggered)
#   $3: metrics (JSON string with trigger-specific data)
#
log_trigger_evaluation() {
  local trigger_type="$1"
  local result="$2"
  local metrics="$3"

  local message="Trigger evaluation: ${trigger_type} -> ${result}"
  write_log_entry "INFO" "trigger_eval" "$message" "$metrics"
}

#
# Log complexity scores and threshold comparison
# Args:
#   $1: phase_number
#   $2: complexity_score
#   $3: threshold
#   $4: task_count
#
log_complexity_check() {
  local phase_number="$1"
  local complexity_score="$2"
  local threshold="$3"
  local task_count="$4"

  local data
  data=$(printf '{"phase": %d, "score": %.1f, "threshold": %d, "tasks": %d}' \
    "$phase_number" "$complexity_score" "$threshold" "$task_count")

  local triggered="not_triggered"
  # Use awk for floating point comparison instead of bc
  if awk -v score="$complexity_score" -v thresh="$threshold" 'BEGIN {exit !(score > thresh)}' || (( task_count > 10 )); then
    triggered="triggered"
  fi

  log_trigger_evaluation "complexity" "$triggered" "$data"
}

#
# Log test failure pattern detection
# Args:
#   $1: phase_number
#   $2: consecutive_failures
#   $3: failure_log (path or excerpt)
#
log_test_failure_pattern() {
  local phase_number="$1"
  local consecutive_failures="$2"
  local failure_log="$3"

  local data
  data=$(printf '{"phase": %d, "consecutive_failures": %d, "log": "%s"}' \
    "$phase_number" "$consecutive_failures" "${failure_log//\"/\\\"}")

  local triggered="not_triggered"
  if (( consecutive_failures >= 2 )); then
    triggered="triggered"
  fi

  log_trigger_evaluation "test_failure" "$triggered" "$data"
}

#
# Log scope drift detection
# Args:
#   $1: phase_number
#   $2: drift_description
#
log_scope_drift() {
  local phase_number="$1"
  local drift_description="$2"

  local data
  data=$(printf '{"phase": %d, "description": "%s"}' \
    "$phase_number" "${drift_description//\"/\\\"}")

  log_trigger_evaluation "scope_drift" "triggered" "$data"
}

#
# Log a replanning invocation
# Args:
#   $1: revision_type (expand_phase|add_phase|split_phase|update_tasks)
#   $2: status (success|failure)
#   $3: result (updated plan path or error message)
#   $4: context (optional JSON string)
#
log_replan_invocation() {
  local revision_type="$1"
  local status="$2"
  local result="$3"
  local context="${4:-}"

  local log_level="INFO"
  if [[ "$status" == "failure" ]]; then
    log_level="ERROR"
  fi

  local message="Replanning invoked: ${revision_type} -> ${status}"
  local data
  if [[ -n "$context" ]]; then
    data=$(printf '{"revision_type": "%s", "result": "%s", "context": %s}' \
      "$revision_type" "${result//\"/\\\"}" "$context")
  else
    data=$(printf '{"revision_type": "%s", "result": "%s"}' \
      "$revision_type" "${result//\"/\\\"}")
  fi

  write_log_entry "$log_level" "replan" "$message" "$data"
}

#
# Log loop prevention enforcement
# Args:
#   $1: phase_number
#   $2: replan_count
#   $3: action (allowed|blocked)
#
log_loop_prevention() {
  local phase_number="$1"
  local replan_count="$2"
  local action="$3"

  local log_level="INFO"
  if [[ "$action" == "blocked" ]]; then
    log_level="WARN"
  fi

  local message="Loop prevention: phase ${phase_number} replan count ${replan_count} -> ${action}"
  local data
  data=$(printf '{"phase": %d, "replan_count": %d, "max_allowed": 2}' \
    "$phase_number" "$replan_count")

  write_log_entry "$log_level" "loop_prevention" "$message" "$data"
}

#
# Query log for recent events
# Args:
#   $1: event_type (optional, defaults to all)
#   $2: limit (optional, defaults to 10)
#
query_adaptive_log() {
  local event_type="${1:-}"
  local limit="${2:-10}"

  if [[ ! -f "$AP_LOG_FILE" ]]; then
    echo "No adaptive planning log found at: $AP_LOG_FILE"
    return 1
  fi

  if [[ -n "$event_type" ]]; then
    tail -n 100 "$AP_LOG_FILE" | grep "$event_type" | tail -n "$limit"
  else
    tail -n "$limit" "$AP_LOG_FILE"
  fi
}

#
# Get statistics about adaptive planning activity
#
get_adaptive_stats() {
  if [[ ! -f "$AP_LOG_FILE" ]]; then
    echo "No adaptive planning log found"
    return 1
  fi

  local total_triggers
  local complexity_triggers
  local test_failure_triggers
  local scope_drift_triggers
  local total_replans
  local successful_replans
  local failed_replans

  total_triggers=$(grep -c "trigger_eval" "$AP_LOG_FILE" || echo 0)
  complexity_triggers=$(grep "trigger_eval.*complexity.*triggered" "$AP_LOG_FILE" | grep -c "triggered" || echo 0)
  test_failure_triggers=$(grep "trigger_eval.*test_failure.*triggered" "$AP_LOG_FILE" | grep -c "triggered" || echo 0)
  scope_drift_triggers=$(grep "trigger_eval.*scope_drift.*triggered" "$AP_LOG_FILE" | grep -c "triggered" || echo 0)
  total_replans=$(grep -c "replan" "$AP_LOG_FILE" || echo 0)
  successful_replans=$(grep "replan.*success" "$AP_LOG_FILE" | grep -c "success" || echo 0)
  failed_replans=$(grep "replan.*failure" "$AP_LOG_FILE" | grep -c "failure" || echo 0)

  cat <<EOF
Adaptive Planning Statistics
============================
Total Trigger Evaluations: $total_triggers
  - Complexity Triggers: $complexity_triggers
  - Test Failure Triggers: $test_failure_triggers
  - Scope Drift Triggers: $scope_drift_triggers

Total Replans: $total_replans
  - Successful: $successful_replans
  - Failed: $failed_replans

Log File: $AP_LOG_FILE
Log Size: $(du -h "$AP_LOG_FILE" | cut -f1)
EOF
}

#
# Log collapse opportunity evaluation
# Args:
#   $1: phase_num
#   $2: complexity_score
#   $3: threshold
#   $4: triggered (true/false)
#
log_collapse_check() {
  local phase_num="$1"
  local complexity_score="$2"
  local threshold="$3"
  local triggered="$4"

  local data
  data=$(printf '{"phase": %d, "complexity": %.1f, "threshold": %.1f, "triggered": %s}' \
    "$phase_num" "$complexity_score" "$threshold" "$triggered")

  local message="Collapse check: Phase $phase_num complexity $complexity_score (threshold $threshold) -> $triggered"

  write_log_entry "INFO" "collapse_check" "$message" "$data"
}

#
# Log collapse invocation
# Args:
#   $1: phase_num
#   $2: trigger_type (manual|auto)
#   $3: reason
#
log_collapse_invocation() {
  local phase_num="$1"
  local trigger_type="$2"
  local reason="$3"

  # Validate trigger_type
  if [[ "$trigger_type" != "manual" && "$trigger_type" != "auto" ]]; then
    echo "Warning: Invalid trigger_type '$trigger_type', using 'manual'" >&2
    trigger_type="manual"
  fi

  local data
  data=$(printf '{"phase": %d, "trigger": "%s", "reason": "%s"}' \
    "$phase_num" "$trigger_type" "${reason//\"/\\\"}")

  local message="Collapsing phase $phase_num ($trigger_type): $reason"

  write_log_entry "INFO" "collapse_invocation" "$message" "$data"
}

# Export functions for use in other scripts
export -f rotate_log_if_needed
export -f write_log_entry
export -f log_trigger_evaluation
export -f log_complexity_check
export -f log_test_failure_pattern
export -f log_scope_drift
export -f log_replan_invocation
export -f log_loop_prevention
export -f log_collapse_check
export -f log_collapse_invocation
export -f query_adaptive_log
export -f get_adaptive_stats
