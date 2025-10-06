#!/usr/bin/env bash
# Shared complexity analysis utilities
# Provides functions for analyzing phase/plan complexity and triggering adaptive planning

set -euo pipefail

# ==============================================================================
# Constants
# ==============================================================================

# Complexity thresholds
readonly COMPLEXITY_THRESHOLD_LOW=2
readonly COMPLEXITY_THRESHOLD_MEDIUM=5
readonly COMPLEXITY_THRESHOLD_HIGH=8
readonly COMPLEXITY_THRESHOLD_CRITICAL=10

# Task count thresholds
readonly TASK_COUNT_THRESHOLD_EXPAND=10

# ==============================================================================
# Core Complexity Analysis
# ==============================================================================

# calculate_phase_complexity: Calculate complexity score for a phase
# Usage: calculate_phase_complexity <phase-name> <task-list>
# Returns: Complexity score (0-10+)
# Example: calculate_phase_complexity "Refactor Architecture" "$TASK_LIST"
calculate_phase_complexity() {
  local phase_name="${1:-}"
  local task_list="${2:-}"

  if [ -z "$phase_name" ]; then
    echo "0"
    return
  fi

  # Use existing analyzer script
  if [ -f "${CLAUDE_PROJECT_DIR}/.claude/utils/analyze-phase-complexity.sh" ]; then
    local result=$("${CLAUDE_PROJECT_DIR}/.claude/utils/analyze-phase-complexity.sh" "$phase_name" "$task_list")
    local score=$(echo "$result" | grep "^COMPLEXITY_SCORE=" | cut -d'=' -f2)
    echo "${score:-0}"
  else
    # Fallback: simple calculation
    local score=0

    # High complexity keywords (weight: 3)
    if echo "$phase_name" | grep -qiE "refactor|architecture|redesign|migrate|security"; then
      score=$((score + 3))
    fi

    # Medium complexity keywords (weight: 2)
    if echo "$phase_name" | grep -qiE "implement|create|build|integrate|add"; then
      score=$((score + 2))
    fi

    # Task count
    if [ -n "$task_list" ]; then
      local task_count=$(echo "$task_list" | grep -c "^- \[ \]" || echo "0")
      # Ensure task_count is numeric
      task_count=${task_count:-0}
      if [[ "$task_count" =~ ^[0-9]+$ ]]; then
        local task_score=$(((task_count + 4) / 5))
        score=$((score + task_score))
      fi
    fi

    # Ensure score is numeric before outputting
    score=${score:-0}
    echo "$score"
  fi
}

# analyze_task_structure: Analyze task list structure and depth
# Usage: analyze_task_structure <task-list>
# Returns: JSON with task metrics
# Example: analyze_task_structure "$TASK_LIST"
analyze_task_structure() {
  local task_list="${1:-}"

  if [ -z "$task_list" ]; then
    echo '{"total_tasks":0,"nested_tasks":0,"max_depth":0,"file_count":0}'
    return
  fi

  # Count tasks
  local total_tasks=$(echo "$task_list" | grep -c "^- \[ \]" | tr -d ' \n' || echo "0")

  # Count nested tasks (indented)
  local nested_tasks=$(echo "$task_list" | grep -c "^  - \[ \]" | tr -d ' \n' || echo "0")

  # Estimate max depth (simple heuristic)
  local max_depth=1
  if [ "${nested_tasks:-0}" -gt 0 ]; then
    max_depth=2
  fi

  # Count file mentions
  local file_count=$(echo "$task_list" | grep -oE '\.(lua|js|py|sh|md|json|yaml|toml)' 2>/dev/null | wc -l | tr -d ' \n' || echo "0")

  # Build JSON response
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson total "$total_tasks" \
      --argjson nested "$nested_tasks" \
      --argjson depth "$max_depth" \
      --argjson files "$file_count" \
      '{total_tasks:$total,nested_tasks:$nested,max_depth:$depth,file_count:$files}'
  else
    echo "{\"total_tasks\":$total_tasks,\"nested_tasks\":$nested_tasks,\"max_depth\":$max_depth,\"file_count\":$file_count}"
  fi
}

# ==============================================================================
# Trigger Detection
# ==============================================================================

# detect_complexity_triggers: Check if complexity exceeds thresholds
# Usage: detect_complexity_triggers <complexity-score> <task-count>
# Returns: "true" if triggered, "false" otherwise
# Example: detect_complexity_triggers 9 12
detect_complexity_triggers() {
  local complexity_score="${1:-0}"
  local task_count="${2:-0}"

  if [ "$complexity_score" -gt "$COMPLEXITY_THRESHOLD_HIGH" ]; then
    echo "true"
    return 0
  fi

  if [ "$task_count" -gt "$TASK_COUNT_THRESHOLD_EXPAND" ]; then
    echo "true"
    return 0
  fi

  echo "false"
  return 1
}

# generate_complexity_report: Generate detailed complexity analysis report
# Usage: generate_complexity_report <phase-name> <task-list>
# Returns: JSON report with all metrics
# Example: generate_complexity_report "Phase 3: Refactor" "$TASKS"
generate_complexity_report() {
  local phase_name="${1:-}"
  local task_list="${2:-}"

  local complexity_score=$(calculate_phase_complexity "$phase_name" "$task_list")
  local task_structure=$(analyze_task_structure "$task_list")
  local total_tasks=$(echo "$task_structure" | jq -r '.total_tasks // 0' 2>/dev/null | head -1 || echo "0")
  # Remove any whitespace/newlines
  total_tasks=$(echo "$total_tasks" | tr -d '\n\r' | tr -d ' ')
  local trigger=$(detect_complexity_triggers "$complexity_score" "$total_tasks")

  # Determine recommended action
  local recommended_action="none"
  local trigger_reason=""

  if [ "$trigger" = "true" ]; then
    if [ "$complexity_score" -gt "$COMPLEXITY_THRESHOLD_HIGH" ]; then
      recommended_action="expand_phase"
      trigger_reason="Complexity score $complexity_score exceeds threshold $COMPLEXITY_THRESHOLD_HIGH"
    elif [ "$total_tasks" -gt "$TASK_COUNT_THRESHOLD_EXPAND" ]; then
      recommended_action="expand_phase"
      trigger_reason="Task count $total_tasks exceeds threshold $TASK_COUNT_THRESHOLD_EXPAND"
    fi
  fi

  # Build report
  if command -v jq &> /dev/null; then
    jq -n \
      --arg phase "$phase_name" \
      --argjson score "$complexity_score" \
      --argjson structure "$task_structure" \
      --arg trigger "$trigger" \
      --arg action "$recommended_action" \
      --arg reason "$trigger_reason" \
      '{
        phase_name: $phase,
        complexity_score: $score,
        task_structure: $structure,
        trigger_detected: $trigger,
        recommended_action: $action,
        trigger_reason: $reason,
        thresholds: {
          complexity_high: '$COMPLEXITY_THRESHOLD_HIGH',
          task_count_expand: '$TASK_COUNT_THRESHOLD_EXPAND'
        }
      }'
  else
    cat <<EOF
{
  "phase_name": "$phase_name",
  "complexity_score": $complexity_score,
  "task_structure": $task_structure,
  "trigger_detected": "$trigger",
  "recommended_action": "$recommended_action",
  "trigger_reason": "$trigger_reason",
  "thresholds": {
    "complexity_high": $COMPLEXITY_THRESHOLD_HIGH,
    "task_count_expand": $TASK_COUNT_THRESHOLD_EXPAND
  }
}
EOF
  fi
}

# ==============================================================================
# Plan-Level Analysis
# ==============================================================================

# analyze_plan_complexity: Analyze overall plan complexity
# Usage: analyze_plan_complexity <plan-file>
# Returns: JSON with plan-level metrics
# Example: analyze_plan_complexity "specs/plans/025_plan.md"
analyze_plan_complexity() {
  local plan_file="${1:-}"

  if [ ! -f "$plan_file" ]; then
    echo '{"total_phases":0,"avg_complexity":0,"max_complexity":0,"phases_exceeding_threshold":0}'
    return
  fi

  # Count total phases
  local total_phases=$(grep -c "^### Phase [0-9]" "$plan_file" 2>/dev/null || echo "0")

  # For now, return basic metrics (full implementation would analyze each phase)
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson phases "$total_phases" \
      '{
        total_phases: $phases,
        avg_complexity: 5,
        max_complexity: 8,
        phases_exceeding_threshold: 0,
        note: "Detailed per-phase analysis requires parse-adaptive-plan.sh"
      }'
  else
    echo '{"total_phases":'$total_phases',"avg_complexity":5,"max_complexity":8,"phases_exceeding_threshold":0}'
  fi
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# get_complexity_level: Get human-readable complexity level
# Usage: get_complexity_level <complexity-score>
# Returns: Level name (trivial/low/medium/high/critical)
# Example: get_complexity_level 7
get_complexity_level() {
  local score="${1:-0}"

  if [ "$score" -le "$COMPLEXITY_THRESHOLD_LOW" ]; then
    echo "trivial"
  elif [ "$score" -le "$COMPLEXITY_THRESHOLD_MEDIUM" ]; then
    echo "low"
  elif [ "$score" -le "$COMPLEXITY_THRESHOLD_HIGH" ]; then
    echo "medium"
  elif [ "$score" -le "$COMPLEXITY_THRESHOLD_CRITICAL" ]; then
    echo "high"
  else
    echo "critical"
  fi
}

# format_complexity_summary: Format complexity report for human reading
# Usage: format_complexity_summary <complexity-json>
# Returns: Formatted text summary
# Example: format_complexity_summary "$(generate_complexity_report ...)"
format_complexity_summary() {
  local complexity_json="${1:-}"

  if [ -z "$complexity_json" ]; then
    echo "No complexity data available"
    return
  fi

  local phase_name=$(echo "$complexity_json" | jq -r '.phase_name // "Unknown"' 2>/dev/null || echo "Unknown")
  local score=$(echo "$complexity_json" | jq -r '.complexity_score // 0' 2>/dev/null || echo "0")
  local tasks=$(echo "$complexity_json" | jq -r '.task_structure.total_tasks // 0' 2>/dev/null || echo "0")
  local trigger=$(echo "$complexity_json" | jq -r '.trigger_detected // "false"' 2>/dev/null || echo "false")
  local action=$(echo "$complexity_json" | jq -r '.recommended_action // "none"' 2>/dev/null || echo "none")
  local level=$(get_complexity_level "$score")

  cat <<EOF
Complexity Analysis: $phase_name
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Score:     $score/10 ($level)
Tasks:     $tasks
Trigger:   $trigger
Action:    $action
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f calculate_phase_complexity
  export -f analyze_task_structure
  export -f detect_complexity_triggers
  export -f generate_complexity_report
  export -f analyze_plan_complexity
  export -f get_complexity_level
  export -f format_complexity_summary
fi
