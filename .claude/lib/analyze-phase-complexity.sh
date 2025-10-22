#!/usr/bin/env bash
#
# analyze-phase-complexity.sh - Standalone 5-factor complexity analyzer
#
# Usage: analyze-phase-complexity.sh <phase_name> <task_list>
# Output: COMPLEXITY_SCORE=N.N
#
# Implements weighted 5-factor complexity formula:
# - Task count (30%)
# - File references (20%)
# - Dependency depth (20%)
# - Test scope (15%)
# - Risk factors (15%)

set -euo pipefail

# Input validation
if [ $# -lt 2 ]; then
  echo "Usage: $0 <phase_name> <task_list>" >&2
  echo "COMPLEXITY_SCORE=0.0"
  exit 1
fi

PHASE_NAME="$1"
TASK_LIST="$2"

# Debug logging configuration
DEBUG_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/data/logs/complexity-debug.log"
mkdir -p "$(dirname "$DEBUG_LOG")" 2>/dev/null || true

debug_log() {
  if [ "${COMPLEXITY_DEBUG:-0}" = "1" ]; then
    echo "[DEBUG] $*" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DEBUG_LOG" 2>/dev/null || true
  fi
}

# Factor 1: Task Count (30% weight)
extract_task_count() {
  local task_list="$1"
  local count=0

  if [ -n "$task_list" ]; then
    local raw_count=$(echo "$task_list" | grep -c "^- \[ \]" 2>/dev/null || echo "0")
    debug_log "Raw task count before trim: '$raw_count'"
    count=$(echo "$raw_count" | tr -d ' \n\r\t')
    debug_log "Task count after trim: '$count'"
  fi

  # Ensure numeric
  count=${count:-0}
  debug_log "Final task count: $count"
  echo "$count"
}

# Factor 2: File References (20% weight)
extract_file_count() {
  local task_list="$1"
  local count=0

  if [ -n "$task_list" ]; then
    # Extract file paths matching various patterns
    local files=$(echo "$task_list" | \
      grep -oE '([a-zA-Z0-9_/-]+/)*[a-zA-Z0-9_-]+\.[a-zA-Z0-9]+' 2>/dev/null | \
      sort -u || echo "")

    if [ -n "$files" ]; then
      count=$(echo "$files" | wc -l | tr -d ' \n')
    fi
  fi

  # Cap at 30 to prevent extreme scores
  count=${count:-0}
  if [ "$count" -gt 30 ]; then
    count=30
    debug_log "File count capped at 30"
  fi

  debug_log "File count: $count"
  echo "$count"
}

# Factor 3: Dependency Depth (20% weight)
calculate_dependency_depth() {
  local task_list="$1"
  local depth=0

  if [ -n "$task_list" ]; then
    # Extract dependency metadata
    local deps=$(echo "$task_list" | grep -oP 'depends_on:\s*\[\K[^\]]+' 2>/dev/null || echo "")

    if [ -n "$deps" ]; then
      # Count comma-separated dependencies as depth indicator
      # Simple heuristic: number of dependencies = chain depth estimate
      depth=$(echo "$deps" | tr ',' '\n' | wc -l | tr -d ' ')

      # Cap at reasonable maximum (5)
      if [ "$depth" -gt 5 ]; then
        depth=5
        debug_log "Dependency depth capped at 5"
      fi
    fi
  fi

  debug_log "Dependency depth: $depth"
  echo "$depth"
}

# Factor 4: Test Scope (15% weight)
extract_test_count() {
  local task_list="$1"
  local count=0

  if [ -n "$task_list" ]; then
    count=$(echo "$task_list" | \
      grep -iEc 'test|spec|coverage|testing|unittest|integration test' 2>/dev/null | tr -d ' \n' || echo "0")
  fi

  # Cap at 20 to prevent over-weighting
  count=${count:-0}
  if [ "$count" -gt 20 ]; then
    count=20
    debug_log "Test count capped at 20"
  fi

  debug_log "Test count: $count"
  echo "$count"
}

# Factor 5: Risk Factors (15% weight)
extract_risk_count() {
  local task_list="$1"
  local count=0

  if [ -n "$task_list" ]; then
    count=$(echo "$task_list" | \
      grep -iEc 'security|migration|breaking|API|schema|authentication|authorization|database' 2>/dev/null | tr -d ' \n' || echo "0")
  fi

  # Cap at 10 to prevent over-weighting
  count=${count:-0}
  if [ "$count" -gt 10 ]; then
    count=10
    debug_log "Risk count capped at 10"
  fi

  debug_log "Risk count: $count"
  echo "$count"
}

# Main calculation
main() {
  debug_log "=== Analyzing phase: $PHASE_NAME ==="

  # Extract all factors
  local task_count=$(extract_task_count "$TASK_LIST")
  local file_count=$(extract_file_count "$TASK_LIST")
  local depth=$(calculate_dependency_depth "$TASK_LIST")
  local test_count=$(extract_test_count "$TASK_LIST")
  local risk_count=$(extract_risk_count "$TASK_LIST")

  # Calculate weighted raw score using integer arithmetic (multiplied by 100 for precision)
  # Formula: (tasks * 30) + (files * 20) + (depth * 20) + (tests * 15) + (risks * 15) / 100
  local task_score=$(( task_count * 30 ))
  local file_score=$(( file_count * 20 ))
  local depth_score=$(( depth * 20 ))
  local test_score=$(( test_count * 15 ))
  local risk_score=$(( risk_count * 15 ))

  local raw_score_int=$(( task_score + file_score + depth_score + test_score + risk_score ))

  debug_log "Raw score calculation (x100):"
  debug_log "  ($task_count * 30) = $task_score"
  debug_log "  ($file_count * 20) = $file_score"
  debug_log "  ($depth * 20) = $depth_score"
  debug_log "  ($test_count * 15) = $test_score"
  debug_log "  ($risk_count * 15) = $risk_score"
  debug_log "  raw_score_int = $raw_score_int (x100)"

  # Apply normalization factor (0.411 = 411/1000)
  # This factor was empirically calibrated using Plan 080 ground truth data
  # Calibration correlation: 0.7515 (target: 0.90)
  # normalized = (raw_score_int * 411) / (100 * 1000) = (raw_score_int * 411) / 100000
  #
  # Note: Original factor was 0.822, but this over-normalized scores.
  # Factor 0.411 (0.822 / 2) was determined through grid search to maximize
  # correlation with human-judged complexity ratings.
  local normalized_int=$(( raw_score_int * 411 / 1000 ))

  # Convert to 0.1 precision (multiply by 10 to keep 1 decimal place)
  local final_int=$(( (normalized_int + 5) / 10 ))  # +5 for rounding

  # Cap at 15.0 (150 in our scale)
  if [ "$final_int" -gt 150 ]; then
    final_int=150
    debug_log "Score capped at 15.0"
  fi

  # Format as decimal (divide by 10)
  local whole=$(( final_int / 10 ))
  local decimal=$(( final_int % 10 ))
  local final_score="${whole}.${decimal}"

  debug_log "Normalized score (x10): $normalized_int (factor: 411/1000, calibrated)"
  debug_log "Final score: $final_score"
  debug_log "=== Analysis complete ==="

  # Output in expected format
  echo "COMPLEXITY_SCORE=$final_score"
}

# Execute main function
main
