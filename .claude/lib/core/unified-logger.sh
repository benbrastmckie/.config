#!/usr/bin/env bash
#
# Unified Logger
# Provides structured logging for all Claude Code operations
# Consolidates: adaptive-planning-logger.sh, conversion-logger.sh
#
# Log files:
#   - .claude/logs/adaptive-planning.log
#   - .claude/logs/conversion.log
#
# Features:
#   - Structured logging (timestamp, level, category, message)
#   - Log rotation (10MB max, 5 files retained)
#   - Multiple log streams
#   - Query functions
#
# Usage:
#   source .claude/lib/core/unified-logger.sh
#   log_complexity_check 3 9.2 8 12  # Adaptive planning
#   init_conversion_log "$OUTPUT_DIR/conversion.log"  # Conversion

# Source guard: prevent duplicate sourcing (Phase 2 optimization)
if [ -n "${UNIFIED_LOGGER_SOURCED:-}" ]; then
  return 0
fi
UNIFIED_LOGGER_SOURCED=1

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"
source "$SCRIPT_DIR/timestamp-utils.sh"

# Configuration (only set if not already defined to avoid readonly conflicts)
if [[ -z "${LOG_MAX_SIZE:-}" ]]; then
  readonly LOG_MAX_SIZE=$((10 * 1024 * 1024))  # 10MB
fi
if [[ -z "${LOG_MAX_FILES:-}" ]]; then
  readonly LOG_MAX_FILES=5
fi

# Adaptive planning log
if [[ -z "${AP_LOG_FILE:-}" ]]; then
  readonly AP_LOG_FILE="${CLAUDE_LOGS_DIR:-.claude/data/logs}/adaptive-planning.log"
fi
mkdir -p "$(dirname "$AP_LOG_FILE")"

# Conversion log (configurable)
if [[ -z "${CONVERSION_LOG_FILE:-}" ]]; then
  CONVERSION_LOG_FILE=""
fi
if [[ -z "${CONVERSION_LOG_MAX_SIZE:-}" ]]; then
  readonly CONVERSION_LOG_MAX_SIZE=${LOG_MAX_SIZE}
fi
if [[ -z "${CONVERSION_LOG_MAX_FILES:-}" ]]; then
  readonly CONVERSION_LOG_MAX_FILES=${LOG_MAX_FILES}
fi

# ============================================================================
# CORE LOGGING FUNCTIONS
# ============================================================================

#
# rotate_log_file - Generic log rotation function
#
# Arguments:
#   $1 - Log file path
#   $2 - Max size (optional, defaults to LOG_MAX_SIZE)
#   $3 - Max files (optional, defaults to LOG_MAX_FILES)
#
rotate_log_file() {
  local log_file="$1"
  local max_size="${2:-$LOG_MAX_SIZE}"
  local max_files="${3:-$LOG_MAX_FILES}"

  if [[ ! -f "$log_file" ]]; then
    return 0
  fi

  local file_size
  file_size=$(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo 0)

  if (( file_size >= max_size )); then
    # Rotate logs: .log -> .log.1, .log.1 -> .log.2, etc.
    for ((i = max_files - 1; i >= 1; i--)); do
      if [[ -f "${log_file}.$i" ]]; then
        mv "${log_file}.$i" "${log_file}.$((i + 1))"
      fi
    done

    # Move current log to .1
    mv "$log_file" "${log_file}.1"

    # Remove oldest if we exceed max files
    if [[ -f "${log_file}.$((max_files + 1))" ]]; then
      rm "${log_file}.$((max_files + 1))"
    fi
  fi
}

# ============================================================================
# ADAPTIVE PLANNING LOGGING
# ============================================================================

#
# write_log_entry - Write a structured log entry to adaptive planning log
#
# Arguments:
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

  rotate_log_file "$AP_LOG_FILE"

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
# log_trigger_evaluation - Log a trigger evaluation
#
# Arguments:
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
# log_complexity_check - Log complexity scores and threshold comparison
#
# Arguments:
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
  # Use awk for floating point comparison
  if awk -v score="$complexity_score" -v thresh="$threshold" 'BEGIN {exit !(score > thresh)}' || (( task_count > 10 )); then
    triggered="triggered"
  fi

  log_trigger_evaluation "complexity" "$triggered" "$data"
}

#
# log_test_failure_pattern - Log test failure pattern detection
#
# Arguments:
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
# log_scope_drift - Log scope drift detection
#
# Arguments:
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
# log_replan_invocation - Log a replanning invocation
#
# Arguments:
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
# log_loop_prevention - Log loop prevention enforcement
#
# Arguments:
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
# log_collapse_check - Log collapse opportunity evaluation
#
# Arguments:
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
# log_collapse_invocation - Log collapse invocation
#
# Arguments:
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
    warn "Invalid trigger_type '$trigger_type', using 'manual'"
    trigger_type="manual"
  fi

  local data
  data=$(printf '{"phase": %d, "trigger": "%s", "reason": "%s"}' \
    "$phase_num" "$trigger_type" "${reason//\"/\\\"}")

  local message="Collapsing phase $phase_num ($trigger_type): $reason"

  write_log_entry "INFO" "collapse_invocation" "$message" "$data"
}

#
# log_complexity_discrepancy - Log threshold vs agent score differences
#
# Arguments:
#   $1: phase
#   $2: threshold_score
#   $3: agent_score
#   $4: score_diff
#   $5: agent_reasoning (optional)
#   $6: reconciliation_method (optional)
#
log_complexity_discrepancy() {
  local phase="$1"
  local threshold_score="$2"
  local agent_score="$3"
  local score_diff="$4"
  local agent_reasoning="${5:-}"
  local reconciliation_method="${6:-}"

  local data
  data=$(printf '{"phase": "%s", "threshold_score": %s, "agent_score": %s, "difference": %s, "reconciliation_method": "%s", "agent_reasoning": "%s"}' \
    "${phase//\"/\\\"}" "$threshold_score" "$agent_score" "$score_diff" \
    "${reconciliation_method//\"/\\\"}" "${agent_reasoning//\"/\\\"}")

  local message="Complexity discrepancy in $phase: threshold=$threshold_score, agent=$agent_score, diff=$score_diff, method=$reconciliation_method"

  write_log_entry "INFO" "complexity_discrepancy" "$message" "$data"
}

#
# query_adaptive_log - Query log for recent events
#
# Arguments:
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
# get_adaptive_stats - Get statistics about adaptive planning activity
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

# ============================================================================
# CONVERSION LOGGING
# ============================================================================

#
# init_conversion_log - Initialize conversion log file
#
# Arguments:
#   $1 - Log file path
#   $2 - Input directory (optional)
#   $3 - Output directory (optional)
#
init_conversion_log() {
  CONVERSION_LOG_FILE="$1"
  local input_dir="${2:-}"
  local output_dir="${3:-}"

  # Ensure log directory exists
  mkdir -p "$(dirname "$CONVERSION_LOG_FILE")"

  # Initialize with header
  cat > "$CONVERSION_LOG_FILE" <<EOF
========================================
Document Conversion Log
Started: $(date)
========================================

EOF

  if [[ -n "$input_dir" ]]; then
    echo "Input Directory: $input_dir" >> "$CONVERSION_LOG_FILE"
  fi

  if [[ -n "$output_dir" ]]; then
    echo "Output Directory: $output_dir" >> "$CONVERSION_LOG_FILE"
  fi

  echo "" >> "$CONVERSION_LOG_FILE"
}

#
# log_conversion_start - Log the start of a conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Target format (markdown, docx, pdf)
#
log_conversion_start() {
  local input_file="$1"
  local target_format="$2"

  rotate_log_file "$CONVERSION_LOG_FILE"

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] START: $(basename "$input_file") -> $target_format" >> "$CONVERSION_LOG_FILE"
}

#
# log_conversion_success - Log a successful conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Output file path
#   $3 - Tool used (markitdown, pandoc, pymupdf4llm)
#   $4 - Duration in milliseconds (optional)
#
log_conversion_success() {
  local input_file="$1"
  local output_file="$2"
  local tool_used="$3"
  local duration_ms="${4:-0}"

  rotate_log_file "$CONVERSION_LOG_FILE"

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  local file_size
  if [[ -f "$output_file" ]]; then
    file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")
  else
    file_size="0"
  fi

  cat >> "$CONVERSION_LOG_FILE" <<EOF
[$timestamp] SUCCESS: $(basename "$input_file")
  Tool: $tool_used
  Output: $(basename "$output_file")
  Size: $file_size bytes
  Duration: ${duration_ms}ms

EOF
}

#
# log_conversion_failure - Log a failed conversion
#
# Arguments:
#   $1 - Input file path
#   $2 - Error message
#   $3 - Tool attempted (optional)
#
log_conversion_failure() {
  local input_file="$1"
  local error_message="$2"
  local tool_attempted="${3:-unknown}"

  rotate_log_file "$CONVERSION_LOG_FILE"

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  cat >> "$CONVERSION_LOG_FILE" <<EOF
[$timestamp] FAILURE: $(basename "$input_file")
  Tool: $tool_attempted
  Error: $error_message

EOF
}

#
# log_conversion_fallback - Log a fallback attempt
#
# Arguments:
#   $1 - Input file path
#   $2 - Primary tool that failed
#   $3 - Fallback tool being tried
#
log_conversion_fallback() {
  local input_file="$1"
  local primary_tool="$2"
  local fallback_tool="$3"

  rotate_log_file "$CONVERSION_LOG_FILE"

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] FALLBACK: $(basename "$input_file") - $primary_tool failed, trying $fallback_tool" >> "$CONVERSION_LOG_FILE"
}

#
# log_tool_detection - Log tool detection results
#
# Arguments:
#   $1 - Tool name
#   $2 - Available (true/false)
#   $3 - Version (optional)
#
log_tool_detection() {
  local tool_name="$1"
  local available="$2"
  local version="${3:-unknown}"

  rotate_log_file "$CONVERSION_LOG_FILE"

  if [[ "$available" == "true" ]]; then
    echo "TOOL DETECTION: $tool_name - AVAILABLE ($version)" >> "$CONVERSION_LOG_FILE"
  else
    echo "TOOL DETECTION: $tool_name - NOT AVAILABLE" >> "$CONVERSION_LOG_FILE"
  fi
}

#
# log_phase_start - Log the start of a conversion phase
#
# Arguments:
#   $1 - Phase name (TOOL DETECTION, CONVERSION, VALIDATION, etc.)
#
log_phase_start() {
  local phase_name="$1"

  rotate_log_file "$CONVERSION_LOG_FILE"

  cat >> "$CONVERSION_LOG_FILE" <<EOF

========================================
$phase_name PHASE
========================================

EOF
}

#
# log_phase_end - Log the end of a conversion phase
#
# Arguments:
#   $1 - Phase name
#
log_phase_end() {
  local phase_name="$1"

  rotate_log_file "$CONVERSION_LOG_FILE"

  cat >> "$CONVERSION_LOG_FILE" <<EOF
========================================
END: $phase_name PHASE
========================================

EOF
}

#
# log_validation_check - Log a validation check result
#
# Arguments:
#   $1 - File path
#   $2 - Check type (size, structure, magic_number)
#   $3 - Result (pass/fail/warning)
#   $4 - Details
#
log_validation_check() {
  local file_path="$1"
  local check_type="$2"
  local result="$3"
  local details="$4"

  rotate_log_file "$CONVERSION_LOG_FILE"

  local symbol
  case "$result" in
    pass) symbol="✓" ;;
    fail) symbol="✗" ;;
    warning) symbol="⚠" ;;
    *) symbol="·" ;;
  esac

  echo "VALIDATION [$symbol $result]: $(basename "$file_path") - $check_type - $details" >> "$CONVERSION_LOG_FILE"
}

#
# log_summary - Log conversion summary statistics
#
# Arguments:
#   $1 - Total files processed
#   $2 - Successful conversions
#   $3 - Failed conversions
#   $4 - Validation failures
#
log_summary() {
  local total="$1"
  local successes="$2"
  local failures="$3"
  local validation_failures="${4:-0}"

  rotate_log_file "$CONVERSION_LOG_FILE"

  cat >> "$CONVERSION_LOG_FILE" <<EOF

========================================
CONVERSION SUMMARY
========================================
Total Files Processed: $total
  Successful: $successes
  Failed: $failures
  Validation Failures: $validation_failures

Completed: $(date)
========================================
EOF
}

# ==============================================================================
# Progress Markers
# ==============================================================================

#
# emit_progress - Emit silent progress marker
#
# Arguments:
#   $1: phase_number
#   $2: action description
#
# Output format: PROGRESS: [Phase N] - action
#
# Example: emit_progress "1" "Research complete (4/4 succeeded)"
#
emit_progress() {
  local phase="$1"
  local action="$2"
  echo "PROGRESS: [Phase $phase] - $action"
}

# Display brief summary for coordinate workflows
# Used at terminal states to show completion message
display_brief_summary() {
  echo ""
  echo "✓ Workflow complete: $WORKFLOW_SCOPE"
  case "$WORKFLOW_SCOPE" in
    research-only)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count research reports in: $TOPIC_PATH/reports/"
      ;;
    research-and-plan)
      local report_count=${#REPORT_PATHS[@]}
      echo "Created $report_count reports + 1 plan in: $TOPIC_PATH/"
      echo "→ Run: /implement $PLAN_PATH"
      ;;
    full-implementation)
      echo "Implementation complete. Summary: $SUMMARY_PATH"
      ;;
    debug-only)
      echo "Debug analysis complete: $DEBUG_REPORT"
      ;;
    *)
      echo "Workflow artifacts available in: $TOPIC_PATH"
      ;;
  esac
  echo ""

  # Cleanup temp files now that workflow is complete
  COORDINATE_DESC_FILE="${HOME}/.claude/tmp/coordinate_workflow_desc.txt"
  COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"
  rm -f "$COORDINATE_DESC_FILE" "$COORDINATE_STATE_ID_FILE" 2>/dev/null || true
}

# ==============================================================================
# Filename Slug Generation Logging (Spec 688)
# ==============================================================================

# log_slug_generation: Log filename slug generation strategy for monitoring
#
# Tracks which tier was used for each research topic:
#   - llm: LLM-generated slug passed validation (preferred)
#   - sanitize: LLM slug invalid, sanitized short_name used (fallback)
#   - truncate: LLM slug exceeded 255 bytes, truncated
#   - generic: Both LLM slug and short_name empty, used topicN (ultimate fallback)
#
# Arguments:
#   $1 - level: Log level (DEBUG, INFO, WARN, ERROR)
#   $2 - topic_index: Topic index (0-3)
#   $3 - strategy: Strategy used (llm, sanitize, truncate, generic)
#   $4 - final_slug: Final validated slug
#
# Log format:
#   [2025-11-12 22:30:45] INFO SLUG_GENERATION topic_index=0 strategy=llm slug=implementation_architecture
#
log_slug_generation() {
  local level="$1"
  local topic_index="$2"
  local strategy="$3"
  local final_slug="$4"

  # Validate inputs
  if [[ -z "$level" || -z "$topic_index" || -z "$strategy" || -z "$final_slug" ]]; then
    return 1
  fi

  # Create log entry
  local timestamp
  timestamp=$(generate_timestamp)
  local message="topic_index=$topic_index strategy=$strategy slug=$final_slug"

  # Write to adaptive planning log (slug generation is part of adaptive planning workflow)
  rotate_log_file "$AP_LOG_FILE"
  write_log_entry "$AP_LOG_FILE" "$level" "SLUG_GENERATION" "$message"

  # Also log to stderr if DEBUG mode enabled
  if [ "${WORKFLOW_CLASSIFICATION_DEBUG:-0}" = "1" ]; then
    echo "[DEBUG] Slug generation: $message" >&2
  fi

  return 0
}

# Export all functions for use in other scripts
export -f rotate_log_file
export -f write_log_entry
export -f log_slug_generation
export -f log_trigger_evaluation
export -f log_complexity_check
export -f log_test_failure_pattern
export -f log_scope_drift
export -f log_replan_invocation
export -f log_loop_prevention
export -f log_collapse_check
export -f log_collapse_invocation
export -f log_complexity_discrepancy
export -f query_adaptive_log
export -f get_adaptive_stats
export -f init_conversion_log
export -f log_conversion_start
export -f log_conversion_success
export -f log_conversion_failure
export -f log_conversion_fallback
export -f log_tool_detection
export -f log_phase_start
export -f log_phase_end
export -f log_validation_check
export -f log_summary
export -f emit_progress
export -f display_brief_summary
