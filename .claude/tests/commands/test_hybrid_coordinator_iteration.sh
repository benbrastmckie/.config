#!/usr/bin/env bash
# Test: Hybrid Coordinator Iteration and Compatibility
# Tests iteration continuation, brief summary parsing, and backward compatibility

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/.." && pwd)"

# Source test utilities
source "${CLAUDE_DIR}/lib/core/error-handling.sh" 2>/dev/null || exit 1

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  ✓ $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Expected: $expected"
    echo "    Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local test_name="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -n "$value" ]; then
    echo "  ✓ $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Value is empty"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  local substring="$1"
  local text="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$text" | grep -q "$substring"; then
    echo "  ✓ $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Expected substring: $substring"
    echo "    Not found in: $text"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Brief Summary Parsing (New Format)
test_brief_summary_parsing() {
  echo ""
  echo "Test 1: Brief Summary Parsing (New Format)"

  # Create a test summary with new format
  local test_summary="/tmp/test_summary_new.md"
  cat > "$test_summary" <<'EOF'
coordinator_type: software
summary_brief: "Completed Phase 1-2 with 15 tasks. Context: 65%. Next: Continue Phase 3."
phases_completed: [1, 2]
phase_count: 2
work_remaining: Phase_3 Phase_4
context_exhausted: false
context_usage_percent: 65
requires_continuation: true

# Implementation Summary

## Work Status
Phases 1-2 complete.
EOF

  # Parse fields
  local coord_type=$(head -10 "$test_summary" | grep -E "^coordinator_type:" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d '"')
  local summary_brief=$(head -10 "$test_summary" | grep -E "^summary_brief:" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"')
  local phases_completed=$(head -10 "$test_summary" | grep -E "^phases_completed:" | sed 's/^phases_completed:[[:space:]]*//' | tr -d '[],"')

  assert_equals "software" "$coord_type" "Coordinator type parsed correctly"
  assert_not_empty "$summary_brief" "Summary brief parsed correctly"
  assert_contains "1 2" "$phases_completed" "Phases completed parsed correctly"

  rm -f "$test_summary"
}

# Test 2: Brief Summary Fallback (Legacy Format)
test_brief_summary_fallback() {
  echo ""
  echo "Test 2: Brief Summary Fallback (Legacy Format)"

  # Create a test summary without new fields (legacy format)
  local test_summary="/tmp/test_summary_legacy.md"
  cat > "$test_summary" <<'EOF'
# Implementation Summary

**Brief**: Completed Phase 1-2 with 10 tasks.

## Work Status
Phases 1-2 complete.
EOF

  # Parse coordinator_type (should be empty)
  local coord_type=$(head -10 "$test_summary" | grep -E "^coordinator_type:" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d '"' || echo "")

  # Parse summary_brief (should be empty, trigger fallback)
  local summary_brief=$(head -10 "$test_summary" | grep -E "^summary_brief:" | sed 's/^summary_brief:[[:space:]]*//' | tr -d '"' || echo "")

  # Fallback: Extract from **Brief** line
  if [ -z "$summary_brief" ]; then
    summary_brief=$(head -10 "$test_summary" | grep "^\*\*Brief\*\*:" | sed 's/^\*\*Brief\*\*:[[:space:]]*//')
  fi

  assert_equals "" "$coord_type" "Legacy summary has no coordinator_type field"
  assert_not_empty "$summary_brief" "Fallback parsing extracted brief summary"

  rm -f "$test_summary"
}

# Test 3: Metric Aggregation (Lean Summaries)
test_lean_metric_aggregation() {
  echo ""
  echo "Test 3: Lean Metric Aggregation"

  # Create a test lean summary
  local test_summary="/tmp/test_lean_summary.md"
  cat > "$test_summary" <<'EOF'
coordinator_type: lean
summary_brief: "Completed Phase 1 with 5 theorems. Context: 55%. Next: Continue Phase 2."
phases_completed: [1]
theorem_count: 5
work_remaining: Phase_2
context_exhausted: false
context_usage_percent: 55
requires_continuation: true

# Proof Summary
EOF

  # Parse fields
  local coord_type=$(head -10 "$test_summary" | grep -E "^coordinator_type:" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d '"')
  local theorem_count=$(grep -E "^theorem_count:" "$test_summary" | sed 's/^theorem_count:[[:space:]]*//')

  assert_equals "lean" "$coord_type" "Lean coordinator type parsed"
  assert_equals "5" "$theorem_count" "Theorem count extracted correctly"

  rm -f "$test_summary"
}

# Test 4: Metric Aggregation (Software Summaries)
test_software_metric_aggregation() {
  echo ""
  echo "Test 4: Software Metric Aggregation"

  # Create a test software summary
  local test_summary="/tmp/test_software_summary.md"
  cat > "$test_summary" <<'EOF'
coordinator_type: software
summary_brief: "Completed Phase 1-2 with 3 commits. Context: 70%. Next: Complete."
phases_completed: [1, 2]
phase_count: 2
git_commits: [abc123, def456, ghi789]
work_remaining: 0
context_exhausted: false
context_usage_percent: 70
requires_continuation: false

# Implementation Summary
EOF

  # Parse fields
  local coord_type=$(head -10 "$test_summary" | grep -E "^coordinator_type:" | sed 's/^coordinator_type:[[:space:]]*//' | tr -d '"')
  local git_commits=$(grep -E "^git_commits:" "$test_summary" | sed 's/^git_commits:[[:space:]]*//' | tr -d '[],"' | wc -w)

  assert_equals "software" "$coord_type" "Software coordinator type parsed"
  assert_equals "3" "$git_commits" "Git commits count extracted correctly"

  rm -f "$test_summary"
}

# Run all tests
echo "=========================================="
echo "Hybrid Coordinator Iteration Tests"
echo "=========================================="

test_brief_summary_parsing
test_brief_summary_fallback
test_lean_metric_aggregation
test_software_metric_aggregation

# Print summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo "✓ All hybrid coordinator iteration tests passed!"
  exit 0
else
  echo ""
  echo "✗ Some tests failed"
  exit 1
fi
