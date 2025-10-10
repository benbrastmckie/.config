#!/usr/bin/env bash
# Analyze feature description to estimate complexity metrics
# Usage: analyze-plan-requirements.sh "<feature_description>"

set -e

if [ $# -lt 1 ]; then
  echo "Usage: $0 \"<feature_description>\"" >&2
  exit 1
fi

FEATURE_DESC="$1"

# Heuristics for estimating complexity from feature description

# Task count estimation based on keywords and complexity indicators
estimate_task_count() {
  local desc="$1"
  local base_tasks=5  # Minimum baseline
  local task_count=$base_tasks

  # Count action verbs (implement, create, add, build, refactor, etc.)
  local action_words=$(echo "$desc" | grep -oiE '\b(implement|create|add|build|refactor|update|modify|enhance|design|develop|integrate|test|document|migrate|setup|configure|fix)\b' | wc -l)
  task_count=$((task_count + action_words * 2))

  # Count "and" conjunctions (indicates multiple components)
  local conjunctions=$(echo "$desc" | grep -oiE '\band\b' | wc -l)
  task_count=$((task_count + conjunctions * 3))

  # Count comma-separated items
  local comma_count=$(echo "$desc" | grep -o ',' | wc -l)
  task_count=$((task_count + comma_count * 2))

  # Adjust for complexity keywords
  if echo "$desc" | grep -qiE '\b(complete|comprehensive|full|entire|across|system-wide|end-to-end)\b'; then
    task_count=$((task_count + 10))
  fi

  if echo "$desc" | grep -qiE '\b(simple|small|quick|minor|fix|single)\b'; then
    task_count=$((task_count - 3))
    [ $task_count -lt 3 ] && task_count=3
  fi

  echo "$task_count"
}

# Phase count estimation
estimate_phase_count() {
  local desc="$1"
  local task_count=$2
  local base_phases=3

  # More tasks = more phases
  if [ $task_count -lt 10 ]; then
    base_phases=3
  elif [ $task_count -lt 30 ]; then
    base_phases=5
  elif [ $task_count -lt 60 ]; then
    base_phases=8
  else
    base_phases=12
  fi

  # Adjust for architectural keywords
  if echo "$desc" | grep -qiE '\b(architecture|redesign|refactor|migration)\b'; then
    base_phases=$((base_phases + 2))
  fi

  # Adjust for multi-layer keywords
  if echo "$desc" | grep -qiE '\b(backend|frontend|database|api|ui)\b'; then
    local layers=$(echo "$desc" | grep -oiE '\b(backend|frontend|database|api|ui)\b' | sort -u | wc -l)
    base_phases=$((base_phases + layers - 1))
  fi

  echo "$base_phases"
}

# Hours estimation
estimate_hours() {
  local task_count=$1
  local phase_count=$2

  # Base estimate: 2 hours per task on average
  local hours=$((task_count * 2))

  # Adjust for phase count (more phases = more overhead)
  hours=$((hours + phase_count * 3))

  echo "$hours"
}

# Dependency estimation
estimate_dependencies() {
  local phase_count=$1

  # Typical dependency ratio: 30-40% of phases have dependencies
  local deps=$((phase_count * 4 / 10))

  # Minimum 1 dependency for multi-phase projects
  [ $deps -lt 1 ] && [ $phase_count -gt 2 ] && deps=1

  echo "$deps"
}

# Run estimations
TASK_COUNT=$(estimate_task_count "$FEATURE_DESC")
PHASE_COUNT=$(estimate_phase_count "$FEATURE_DESC" "$TASK_COUNT")
HOURS=$(estimate_hours "$TASK_COUNT" "$PHASE_COUNT")
DEPENDENCIES=$(estimate_dependencies "$PHASE_COUNT")

# Output estimated metrics
cat <<EOF
Feature Description Analysis
=============================

Feature: "$FEATURE_DESC"

Estimated Metrics:
  Tasks:        $TASK_COUNT
  Phases:       $PHASE_COUNT
  Hours:        $HOURS
  Dependencies: $DEPENDENCIES

These metrics can be used with calculate-plan-complexity.sh:
  ./calculate-plan-complexity.sh $TASK_COUNT $PHASE_COUNT $HOURS $DEPENDENCIES

EOF

# Automatically calculate complexity and recommend tier
if command -v calculate-plan-complexity.sh >/dev/null 2>&1; then
  echo "Automatic Complexity Calculation:"
  echo "=================================="
  calculate-plan-complexity.sh "$TASK_COUNT" "$PHASE_COUNT" "$HOURS" "$DEPENDENCIES"
elif [ -x "$(dirname "$0")/calculate-plan-complexity.sh" ]; then
  echo "Automatic Complexity Calculation:"
  echo "=================================="
  "$(dirname "$0")/calculate-plan-complexity.sh" "$TASK_COUNT" "$PHASE_COUNT" "$HOURS" "$DEPENDENCIES"
else
  echo "Note: Run calculate-plan-complexity.sh with above metrics for tier recommendation"
fi
