#!/usr/bin/env bash
# Calculate plan complexity score and recommend tier
# Usage: calculate-plan-complexity.sh <task_count> <phase_count> <estimated_hours> <dependency_count>

set -e

# Input validation
if [ $# -lt 4 ]; then
  echo "Usage: $0 <task_count> <phase_count> <estimated_hours> <dependency_count>" >&2
  exit 1
fi

TASK_COUNT=$1
PHASE_COUNT=$2
ESTIMATED_HOURS=$3
DEPENDENCY_COUNT=$4

# Validate inputs are numbers
if ! [[ "$TASK_COUNT" =~ ^[0-9]+$ ]] || ! [[ "$PHASE_COUNT" =~ ^[0-9]+$ ]] || \
   ! [[ "$ESTIMATED_HOURS" =~ ^[0-9]+$ ]] || ! [[ "$DEPENDENCY_COUNT" =~ ^[0-9]+$ ]]; then
  echo "Error: All inputs must be non-negative integers" >&2
  exit 1
fi

# Complexity scoring formula:
# complexity_score = (task_count * 1.0) + (phase_count * 5.0) + (total_hours * 0.5) + (dependency_count * 2.0)
#
# Thresholds:
# - Simple (Tier 1): score < 50
# - Medium (Tier 2): 50 ≤ score < 200
# - Complex (Tier 3): score ≥ 200

# Calculate using awk for floating point arithmetic
COMPLEXITY_SCORE=$(awk -v tc="$TASK_COUNT" -v pc="$PHASE_COUNT" -v eh="$ESTIMATED_HOURS" -v dc="$DEPENDENCY_COUNT" \
  'BEGIN { printf "%.1f", (tc * 1.0) + (pc * 5.0) + (eh * 0.5) + (dc * 2.0) }')

# Determine tier based on thresholds (using awk for float comparison)
TIER=$(awk -v score="$COMPLEXITY_SCORE" 'BEGIN {
  if (score < 50) print 1
  else if (score < 200) print 2
  else print 3
}')

case $TIER in
  1) TIER_NAME="Simple (Single-File)" ;;
  2) TIER_NAME="Medium (Phase-Directory)" ;;
  3) TIER_NAME="Complex (Hierarchical Tree)" ;;
esac

# Output results
cat <<EOF
Complexity Score: $COMPLEXITY_SCORE
Recommended Tier: $TIER ($TIER_NAME)

Breakdown:
  Tasks:        $TASK_COUNT × 1.0 = $(awk -v n="$TASK_COUNT" 'BEGIN { printf "%.1f", n * 1.0 }')
  Phases:       $PHASE_COUNT × 5.0 = $(awk -v n="$PHASE_COUNT" 'BEGIN { printf "%.1f", n * 5.0 }')
  Hours:        $ESTIMATED_HOURS × 0.5 = $(awk -v n="$ESTIMATED_HOURS" 'BEGIN { printf "%.1f", n * 0.5 }')
  Dependencies: $DEPENDENCY_COUNT × 2.0 = $(awk -v n="$DEPENDENCY_COUNT" 'BEGIN { printf "%.1f", n * 2.0 }')

Tier Thresholds:
  Tier 1 (Simple):  score < 50
  Tier 2 (Medium):  50 ≤ score < 200
  Tier 3 (Complex): score ≥ 200
EOF
