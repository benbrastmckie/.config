#!/usr/bin/env bash
# test-checkbox-utils.sh
#
# Unit tests for checkbox-utils.sh success criteria functions

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_LIB="$SCRIPT_DIR/../../lib"

# Source the library under test
source "$CLAUDE_LIB/plan/checkbox-utils.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
test_name=""
setup_test() {
  test_name="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
  echo ""
  echo "=== Test $TESTS_RUN: $test_name ==="
}

assert_success() {
  local command="$1"
  local description="$2"

  if eval "$command" >/dev/null 2>&1; then
    echo "✓ $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ $description (expected success, got failure)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_failure() {
  local command="$1"
  local description="$2"

  # Run in subshell to catch exit from error()
  if ( eval "$command" ) >/dev/null 2>&1; then
    echo "✗ $description (expected failure, got success)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  else
    echo "✓ $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
}

assert_count() {
  local actual="$1"
  local expected="$2"
  local description="$3"

  if [[ "$actual" -eq "$expected" ]]; then
    echo "✓ $description (count: $actual)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "✗ $description (expected: $expected, got: $actual)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Create test plan files
create_test_plan() {
  local plan_file="$1"
  cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Metadata

- **Date**: 2025-12-08
- **Feature**: Test plan for success criteria functions
- **Status**: [NOT STARTED]

## Success Criteria

- [ ] Criterion 1: Function works correctly
- [ ] Criterion 2: Error handling is robust
- [ ] Criterion 3: Edge cases are handled

## Phase 1: Setup [NOT STARTED]

- [ ] Task 1: Install dependencies
- [ ] Task 2: Configure environment

## Phase 2: Implementation [NOT STARTED]

- [ ] Task 1: Implement feature
- [ ] Task 2: Write tests
EOF
}

create_test_plan_no_success_criteria() {
  local plan_file="$1"
  cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Metadata

- **Date**: 2025-12-08
- **Feature**: Test plan without success criteria
- **Status**: [NOT STARTED]

## Phase 1: Setup [NOT STARTED]

- [ ] Task 1: Install dependencies
- [ ] Task 2: Configure environment
EOF
}

create_test_plan_partial_complete() {
  local plan_file="$1"
  cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Metadata

- **Date**: 2025-12-08
- **Feature**: Test plan with partial success criteria
- **Status**: [IN PROGRESS]

## Success Criteria

- [x] Criterion 1: Function works correctly
- [ ] Criterion 2: Error handling is robust
- [ ] Criterion 3: Edge cases are handled

## Phase 1: Setup [COMPLETE]

- [x] Task 1: Install dependencies
- [x] Task 2: Configure environment
EOF
}

# Test 1: mark_success_criteria_complete with valid plan
setup_test "mark_success_criteria_complete with valid plan"
TEST_PLAN=$(mktemp)
create_test_plan "$TEST_PLAN"

assert_success "mark_success_criteria_complete '$TEST_PLAN'" \
  "Function should succeed with valid plan"

CHECKED_COUNT=$(grep -c "^- \[x\].*Criterion" "$TEST_PLAN" || echo 0)
assert_count "$CHECKED_COUNT" "3" \
  "All 3 criteria should be marked complete"

rm -f "$TEST_PLAN"

# Test 2: mark_success_criteria_complete with missing section
setup_test "mark_success_criteria_complete with missing Success Criteria section"
TEST_PLAN=$(mktemp)
create_test_plan_no_success_criteria "$TEST_PLAN"

assert_failure "mark_success_criteria_complete '$TEST_PLAN'" \
  "Function should fail when Success Criteria section missing"

rm -f "$TEST_PLAN"

# Test 3: mark_success_criteria_complete with non-existent file
setup_test "mark_success_criteria_complete with non-existent file"

assert_failure "mark_success_criteria_complete '/tmp/nonexistent_plan_12345.md'" \
  "Function should fail with non-existent file"

# Test 4: verify_success_criteria_complete with all complete
setup_test "verify_success_criteria_complete with all criteria complete"
TEST_PLAN=$(mktemp)
create_test_plan "$TEST_PLAN"
mark_success_criteria_complete "$TEST_PLAN" 2>/dev/null

assert_success "verify_success_criteria_complete '$TEST_PLAN'" \
  "Function should return success when all criteria complete"

rm -f "$TEST_PLAN"

# Test 5: verify_success_criteria_complete with some incomplete
setup_test "verify_success_criteria_complete with some criteria incomplete"
TEST_PLAN=$(mktemp)
create_test_plan_partial_complete "$TEST_PLAN"

assert_failure "verify_success_criteria_complete '$TEST_PLAN'" \
  "Function should return failure when some criteria incomplete"

UNCHECKED_COUNT=$(grep -c "^- \[ \].*Criterion" "$TEST_PLAN" || echo 0)
assert_count "$UNCHECKED_COUNT" "2" \
  "2 criteria should remain unchecked"

rm -f "$TEST_PLAN"

# Test 6: verify_success_criteria_complete with missing section
setup_test "verify_success_criteria_complete with missing Success Criteria section"
TEST_PLAN=$(mktemp)
create_test_plan_no_success_criteria "$TEST_PLAN"

assert_failure "verify_success_criteria_complete '$TEST_PLAN'" \
  "Function should return failure when Success Criteria section missing"

rm -f "$TEST_PLAN"

# Test 7: mark_success_criteria_complete doesn't affect phases
setup_test "mark_success_criteria_complete doesn't affect phase checkboxes"
TEST_PLAN=$(mktemp)
create_test_plan "$TEST_PLAN"

PHASE_UNCHECKED_BEFORE=$(grep -c "^- \[ \].*Task" "$TEST_PLAN" || echo 0)
mark_success_criteria_complete "$TEST_PLAN" 2>/dev/null
PHASE_UNCHECKED_AFTER=$(grep -c "^- \[ \].*Task" "$TEST_PLAN" || echo 0)

assert_count "$PHASE_UNCHECKED_AFTER" "$PHASE_UNCHECKED_BEFORE" \
  "Phase checkboxes should remain unchanged"

rm -f "$TEST_PLAN"

# Test 8: Integration test - mark criteria then verify
setup_test "Integration: mark_success_criteria_complete then verify"
TEST_PLAN=$(mktemp)
create_test_plan "$TEST_PLAN"

# Mark all criteria complete
mark_success_criteria_complete "$TEST_PLAN" 2>/dev/null

# Verify they are complete
assert_success "verify_success_criteria_complete '$TEST_PLAN'" \
  "Verification should pass after marking complete"

# Check count
CHECKED_COUNT=$(grep -c "^- \[x\].*Criterion" "$TEST_PLAN" || echo 0)
assert_count "$CHECKED_COUNT" "3" \
  "All 3 criteria should be marked complete"

rm -f "$TEST_PLAN"

# Print test summary
echo ""
echo "═══════════════════════════════════════"
echo "TEST SUMMARY"
echo "═══════════════════════════════════════"
echo "Tests Run:    $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo "═══════════════════════════════════════"

if [[ "$TESTS_FAILED" -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
