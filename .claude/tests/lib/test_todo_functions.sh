#!/usr/bin/env bash
# test_todo_functions.sh - Unit tests for todo-functions.sh library
#
# Tests the query functions:
# - plan_exists_in_todo()
# - get_plan_current_section()

set -e

# === TEST CONFIGURATION ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_TMP="/tmp/test_todo_functions_$$"
PASS_COUNT=0
FAIL_COUNT=0

# === TEST ISOLATION ===
# Override CLAUDE_PROJECT_DIR to prevent production directory pollution
export CLAUDE_PROJECT_DIR="$TEST_TMP"
export CLAUDE_SPECS_ROOT="$TEST_TMP/specs"

# === SETUP ===
setup() {
  mkdir -p "$TEST_TMP/.claude"
  mkdir -p "$TEST_TMP/specs/001_test_topic/plans"
  mkdir -p "$TEST_TMP/specs/002_other_topic/plans"

  # Create test TODO.md with sample sections
  cat > "$TEST_TMP/.claude/TODO.md" << 'EOF'
# TODO

## In Progress

- [x] **Test Plan 1** - Description for test plan 1
  - **Plan**: [001-test-plan.md](specs/001_test_topic/plans/001-test-plan.md)

## Not Started

- [ ] **Test Plan 2** - Description for another test plan
  - **Plan**: [002-other-plan.md](specs/002_other_topic/plans/002-other-plan.md)

## Backlog

- [ ] Manually curated item

## Completed

- [x] **Done Plan** - Already completed
  - **Plan**: [003-done-plan.md](specs/003_done/plans/003-done-plan.md)
EOF

  # Create test plan files
  cat > "$TEST_TMP/specs/001_test_topic/plans/001-test-plan.md" << 'EOF'
# Test Plan 1
## Metadata
- **Status**: [IN PROGRESS]
EOF

  cat > "$TEST_TMP/specs/002_other_topic/plans/002-other-plan.md" << 'EOF'
# Test Plan 2
## Metadata
- **Status**: [NOT STARTED]
EOF

  # Source the library under test (suppress optional dependency warnings)
  source "$PROJECT_ROOT/lib/todo/todo-functions.sh" 2>/dev/null || {
    echo "ERROR: Could not source todo-functions.sh" >&2
    exit 1
  }
}

# === CLEANUP ===
cleanup() {
  rm -rf "$TEST_TMP"
}

trap cleanup EXIT

# === TEST HELPERS ===
assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"

  if [ "$expected" = "$actual" ]; then
    echo "  ✓ PASS: $msg"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: $msg"
    echo "    Expected: '$expected'"
    echo "    Actual:   '$actual'"
    ((FAIL_COUNT++))
  fi
}

assert_success() {
  local exit_code="$1"
  local msg="${2:-}"

  if [ "$exit_code" -eq 0 ]; then
    echo "  ✓ PASS: $msg"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: $msg (exit code: $exit_code)"
    ((FAIL_COUNT++))
  fi
}

assert_failure() {
  local exit_code="$1"
  local msg="${2:-}"

  if [ "$exit_code" -ne 0 ]; then
    echo "  ✓ PASS: $msg"
    ((PASS_COUNT++))
  else
    echo "  ✗ FAIL: $msg (expected failure, got success)"
    ((FAIL_COUNT++))
  fi
}

# === TEST CASES ===

test_plan_exists_in_todo_found_relative() {
  echo "Test: plan_exists_in_todo - plan exists (relative path)"
  if plan_exists_in_todo "specs/001_test_topic/plans/001-test-plan.md"; then
    assert_success 0 "Plan found with relative path"
  else
    assert_failure 0 "Plan found with relative path"
  fi
}

test_plan_exists_in_todo_not_found() {
  echo "Test: plan_exists_in_todo - plan not in TODO.md"
  if plan_exists_in_todo "specs/999_nonexistent/plans/missing.md"; then
    assert_success 1 "Plan correctly not found"
  else
    assert_success 0 "Plan correctly not found"
  fi
}

test_plan_exists_in_todo_no_todomd() {
  echo "Test: plan_exists_in_todo - TODO.md doesn't exist"
  rm -f "$TEST_TMP/.claude/TODO.md"
  if plan_exists_in_todo "specs/001_test_topic/plans/001-test-plan.md"; then
    assert_failure 0 "Correctly returns failure when TODO.md missing"
  else
    assert_success 0 "Correctly returns failure when TODO.md missing"
  fi
  # Restore TODO.md for subsequent tests
  setup
}

test_get_plan_current_section_in_progress() {
  echo "Test: get_plan_current_section - plan in 'In Progress' section"
  local section
  section=$(get_plan_current_section "specs/001_test_topic/plans/001-test-plan.md")
  assert_eq "In Progress" "$section" "Correct section for in-progress plan"
}

test_get_plan_current_section_not_started() {
  echo "Test: get_plan_current_section - plan in 'Not Started' section"
  local section
  section=$(get_plan_current_section "specs/002_other_topic/plans/002-other-plan.md")
  assert_eq "Not Started" "$section" "Correct section for not-started plan"
}

test_get_plan_current_section_completed() {
  echo "Test: get_plan_current_section - plan in 'Completed' section"
  local section
  section=$(get_plan_current_section "specs/003_done/plans/003-done-plan.md")
  assert_eq "Completed" "$section" "Correct section for completed plan"
}

test_get_plan_current_section_not_found() {
  echo "Test: get_plan_current_section - plan not in TODO.md"
  local section
  section=$(get_plan_current_section "specs/999_nonexistent/plans/missing.md")
  assert_eq "" "$section" "Empty string for missing plan"
}

test_get_plan_current_section_no_todomd() {
  echo "Test: get_plan_current_section - TODO.md doesn't exist"
  rm -f "$TEST_TMP/.claude/TODO.md"
  local section
  section=$(get_plan_current_section "specs/001_test_topic/plans/001-test-plan.md" 2>/dev/null)
  assert_eq "" "$section" "Empty string when TODO.md missing"
  # Restore TODO.md for subsequent tests
  setup
}

# === RUN TESTS ===
main() {
  echo "=== TODO Functions Unit Tests ==="
  echo ""

  setup

  echo "--- plan_exists_in_todo tests ---"
  test_plan_exists_in_todo_found_relative
  test_plan_exists_in_todo_not_found
  test_plan_exists_in_todo_no_todomd
  echo ""

  echo "--- get_plan_current_section tests ---"
  test_get_plan_current_section_in_progress
  test_get_plan_current_section_not_started
  test_get_plan_current_section_completed
  test_get_plan_current_section_not_found
  test_get_plan_current_section_no_todomd
  echo ""

  # Summary
  echo "=== Test Summary ==="
  echo "Passed: $PASS_COUNT"
  echo "Failed: $FAIL_COUNT"

  if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
