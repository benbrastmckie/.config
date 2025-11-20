#!/bin/bash
# complexity-utils.sh
#
# Utilities for calculating complexity scores for plans and phases
#
# This supports the adaptive planning feature documented in CLAUDE.md where
# phases with complexity >8 or >10 tasks trigger automatic expansion.

# Source dependencies
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# complexity-thresholds.sh was archived - using inline defaults
COMPLEXITY_THRESHOLD_LOW=${COMPLEXITY_THRESHOLD_LOW:-2}
COMPLEXITY_THRESHOLD_MEDIUM=${COMPLEXITY_THRESHOLD_MEDIUM:-5}
COMPLEXITY_THRESHOLD_HIGH=${COMPLEXITY_THRESHOLD_HIGH:-8}

# Calculate complexity score for a phase
#
# Args:
#   $1 - Plan file path
#   $2 - Phase number
#
# Returns:
#   Complexity score (float) on stdout
#
# Complexity factors:
#   - Task count (more tasks = higher complexity)
#   - File references (more files = higher complexity)
#   - Nested structures (more nesting = higher complexity)
#   - Estimated duration (longer = higher complexity)
calculate_phase_complexity() {
  local plan_file="$1"
  local phase_num="$2"

  if [ ! -f "$plan_file" ]; then
    echo "0" >&2
    return 1
  fi

  # Extract phase content
  local phase_content
  phase_content=$(sed -n "/^###* Phase $phase_num:/,/^###* Phase $((phase_num + 1)):/p" "$plan_file" | head -n -1)

  if [ -z "$phase_content" ]; then
    # Try alternative phase format
    phase_content=$(sed -n "/^###* Phase $phase_num[^:]/,/^###* Phase $((phase_num + 1))/p" "$plan_file" | head -n -1)
  fi

  if [ -z "$phase_content" ]; then
    echo "0"
    return 0
  fi

  # Count tasks
  local task_count
  task_count=$(echo "$phase_content" | grep -c "^- \[ \]" 2>/dev/null || echo "0")
  task_count=$(echo "$task_count" | tr -d '\n' | tr -d ' ')
  task_count=${task_count:-0}
  [[ "$task_count" =~ ^[0-9]+$ ]] || task_count=0

  # Count file references (lines with file paths)
  local file_count
  file_count=$(echo "$phase_content" | grep -c -E "\\./(.*\\.(sh|md|lua|py|js|ts))" 2>/dev/null || echo "0")
  file_count=$(echo "$file_count" | tr -d '\n' | tr -d ' ')
  file_count=${file_count:-0}
  [[ "$file_count" =~ ^[0-9]+$ ]] || file_count=0

  # Count code blocks (indicator of complexity)
  local code_blocks
  code_blocks=$(echo "$phase_content" | grep -c "^\`\`\`" 2>/dev/null || echo "0")
  code_blocks=$(echo "$code_blocks" | tr -d '\n' | tr -d ' ')
  code_blocks=${code_blocks:-0}
  [[ "$code_blocks" =~ ^[0-9]+$ ]] || code_blocks=0
  code_blocks=$((code_blocks / 2))  # Each block has opening and closing

  # Estimate duration indicators
  local has_duration=0
  if echo "$phase_content" | grep -qi "hour\|minute\|duration"; then
    has_duration=1
  fi

  # Calculate weighted score
  # Base: task_count * 0.5
  # Files: file_count * 0.2
  # Code blocks: code_blocks * 0.3
  # Duration mentioned: +1.0

  local score
  score=$(awk -v tasks="$task_count" -v files="$file_count" -v blocks="$code_blocks" -v duration="$has_duration" '
    BEGIN {
      score = (tasks * 0.5) + (files * 0.2) + (blocks * 0.3) + duration
      printf "%.1f", score
    }
  ')

  echo "$score"
  return 0
}

# Calculate complexity score for an entire plan
#
# Args:
#   $1 - Task count
#   $2 - Phase count
#   $3 - Estimated hours
#   $4 - Dependency complexity (0-10)
#
# Returns:
#   Complexity score (float) on stdout
calculate_plan_complexity() {
  local task_count="${1:-0}"
  local phase_count="${2:-0}"
  local estimated_hours="${3:-0}"
  local dependency_complexity="${4:-0}"

  # Weighted formula:
  # - Tasks: 0.3 per task
  # - Phases: 1.0 per phase
  # - Hours: 0.1 per hour
  # - Dependencies: raw score (0-10)

  local score
  score=$(awk -v tasks="$task_count" -v phases="$phase_count" -v hours="$estimated_hours" -v deps="$dependency_complexity" '
    BEGIN {
      score = (tasks * 0.3) + (phases * 1.0) + (hours * 0.1) + deps
      printf "%.1f", score
    }
  ')

  echo "$score"
  return 0
}

# Check if phase complexity exceeds threshold
#
# Args:
#   $1 - Complexity score
#   $2 - Threshold (optional, defaults from CLAUDE.md)
#
# Returns:
#   0 if exceeds threshold, 1 otherwise
exceeds_complexity_threshold() {
  local score="$1"
  local threshold="${2:-}"

  # Load threshold from CLAUDE.md if not provided
  if [ -z "$threshold" ]; then
    get_complexity_thresholds >/dev/null 2>&1
    threshold="$EXPANSION_THRESHOLD"
  fi

  # Compare using awk (handles floats)
  if awk -v score="$score" -v thresh="$threshold" 'BEGIN { exit (score > thresh) ? 0 : 1 }'; then
    return 0  # Exceeds
  else
    return 1  # Does not exceed
  fi
}

# Export functions
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f calculate_phase_complexity
  export -f calculate_plan_complexity
  export -f exceeds_complexity_threshold
fi
