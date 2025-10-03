#!/usr/bin/env bash
# Analyze implementation phase complexity for agent selection
# Usage: analyze-phase-complexity.sh <phase-name> <task-list>

set -euo pipefail

PHASE_NAME="${1:-}"
TASK_LIST="${2:-}"

if [ -z "$PHASE_NAME" ]; then
  echo "Usage: analyze-phase-complexity.sh <phase-name> <task-list>" >&2
  exit 1
fi

# Initialize complexity score
SCORE=0

# Keyword scoring for phase name
count_keywords() {
  local text="$1"
  shift
  local weight="$1"
  shift
  local count=0

  for keyword in "$@"; do
    if echo "$text" | grep -qi "$keyword"; then
      ((count++)) || true
    fi
  done

  echo $((count * weight))
}

# High complexity keywords (weight: 3)
HIGH_COMPLEXITY=$(count_keywords "$PHASE_NAME" 3 "refactor" "architecture" "redesign" "migrate" "security")
SCORE=$((SCORE + HIGH_COMPLEXITY))

# Medium complexity keywords (weight: 2)
MEDIUM_COMPLEXITY=$(count_keywords "$PHASE_NAME" 2 "implement" "create" "build" "integrate" "add")
SCORE=$((SCORE + MEDIUM_COMPLEXITY))

# Low complexity keywords (weight: 1)
LOW_COMPLEXITY=$(count_keywords "$PHASE_NAME" 1 "fix" "update" "modify" "adjust" "change")
SCORE=$((SCORE + LOW_COMPLEXITY))

# Task-based complexity (if task list provided)
if [ -n "$TASK_LIST" ]; then
  # Count tasks
  TASK_COUNT=$(echo "$TASK_LIST" | grep -c "^- \[ \]" || echo "0")

  # Add task count contribution (0.2 per task, capped at 2)
  TASK_SCORE=$(echo "($TASK_COUNT * 2 + 9) / 10" | bc 2>/dev/null || echo "0")
  if [ "$TASK_SCORE" -gt 2 ]; then
    TASK_SCORE=2
  fi
  SCORE=$((SCORE + TASK_SCORE))

  # Test/verify keywords in tasks (weight: 0.5 each, max 1)
  TEST_COUNT=$(echo "$TASK_LIST" | { grep -ic "test\|verify\|check" || true; } | tr -d ' \n')
  if [ "${TEST_COUNT:-0}" -gt 0 ]; then
    SCORE=$((SCORE + 1))
  fi

  # Estimate file count from task descriptions
  FILE_MENTIONS=$(echo "$TASK_LIST" | { grep -oE '\.(lua|js|py|sh|md|json|yaml|toml)' || true; } | wc -l | tr -d ' \n')
  if [ "${FILE_MENTIONS:-0}" -gt 0 ]; then
    FILE_SCORE=$(echo "($FILE_MENTIONS * 5 + 9) / 10" | bc 2>/dev/null || echo "0")
    if [ "$FILE_SCORE" -gt 2 ]; then
      FILE_SCORE=2
    fi
    SCORE=$((SCORE + FILE_SCORE))
  fi
fi

# Special case detection
SPECIAL_CASE=""

# Documentation task detection
if echo "$PHASE_NAME" | grep -qi "documentation\|readme\|doc\|guide"; then
  SPECIAL_CASE="doc-writer"
fi

# Test task detection
if echo "$PHASE_NAME" | grep -qi "^test\|testing\|test.*suite"; then
  SPECIAL_CASE="test-specialist"
fi

# Debug/investigation detection
if echo "$PHASE_NAME" | grep -qi "debug\|investigate\|diagnose\|troubleshoot"; then
  SPECIAL_CASE="debug-specialist"
fi

# Output results
echo "COMPLEXITY_SCORE=$SCORE"
echo "SPECIAL_CASE=$SPECIAL_CASE"

# Select agent based on score
if [ -n "$SPECIAL_CASE" ]; then
  echo "SELECTED_AGENT=$SPECIAL_CASE"
  echo "THINKING_MODE="
elif [ "$SCORE" -le 2 ]; then
  echo "SELECTED_AGENT=direct"
  echo "THINKING_MODE="
elif [ "$SCORE" -le 5 ]; then
  echo "SELECTED_AGENT=code-writer"
  echo "THINKING_MODE="
elif [ "$SCORE" -le 7 ]; then
  echo "SELECTED_AGENT=code-writer"
  echo "THINKING_MODE=think"
elif [ "$SCORE" -le 9 ]; then
  echo "SELECTED_AGENT=code-writer"
  echo "THINKING_MODE=think hard"
else
  echo "SELECTED_AGENT=code-writer"
  echo "THINKING_MODE=think harder"
fi
