#!/usr/bin/env bash
# Test suite for progressive collapse commands
# Tests collapse and merge functionality

set -e

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../../lib"

# Source required libraries
source "$LIB_DIR/plan/plan-core-bundle.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
TEST_DIR="/tmp/progressive_collapse_tests_$$"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR/specs/plans/001_test/"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Create test plan with expanded phase
create_expanded_plan() {
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  # Ensure directory exists
  mkdir -p "$plan_dir"

  # Main plan with summary
  cat > "$plan_dir/001_test.md" <<'EOF'
# Test Plan

## Metadata
- **Plan Number**: 001
- **Structure Level**: 1
- **Expanded Phases**: [2, 3]

## Implementation Phases

### Phase 1: Setup [COMPLETED]
**Objective**: Initial setup

Tasks:
- [x] Task 1

### Phase 2: Implementation
**Objective**: Build core features
**Status**: [PENDING]

For detailed tasks and implementation, see [Phase 2 Details](phase_2_implementation.md)

### Phase 3: Deployment
**Objective**: Deploy to production
**Status**: [PENDING]

For detailed tasks and implementation, see [Phase 3 Details](phase_3_deployment.md)
EOF

  # Expanded phase 2
  cat > "$plan_dir/phase_2_implementation.md" <<'EOF'
### Phase 2: Implementation

## Metadata
- **Phase Number**: 2
- **Parent Plan**: 001_test.md

**Objective**: Build core features
**Complexity**: High

Tasks:
- [ ] Task 1: Backend setup
- [ ] Task 2: Frontend setup
- [x] Task 3: Integration
- [ ] Task 4: Testing

Testing:
```bash
npm test
```

Expected Outcomes:
- Core features implemented
- Tests passing

## Update Reminder
When phase complete, mark Phase 2 as [COMPLETED] in main plan: `001_test.md`
EOF

  # Expanded phase 3
  cat > "$plan_dir/phase_3_deployment.md" <<'EOF'
### Phase 3: Deployment

## Metadata
- **Phase Number**: 3
- **Parent Plan**: 001_test.md

**Objective**: Deploy to production
**Complexity**: Medium

Tasks:
- [ ] Deployment task 1
- [ ] Deployment task 2

## Update Reminder
When phase complete, mark Phase 3 as [COMPLETED] in main plan: `001_test.md`
EOF
}

# Test 1: Merge phase content into plan
test_merge_phase() {
  create_expanded_plan
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  # Merge phase 2
  merge_phase_into_plan \
    "$plan_dir/001_test.md" \
    "$plan_dir/phase_2_implementation.md" \
    2

  # Check if content was merged
  if grep -q "Task 1: Backend setup" "$plan_dir/001_test.md"; then
    pass "Phase content merged into plan"
  else
    fail "Phase content merged into plan" "Tasks not found in plan"
    return
  fi

  # Check that link was removed
  if ! grep -q "For detailed tasks and implementation, see \[Phase 2 Details\]" "$plan_dir/001_test.md"; then
    pass "Phase summary link removed"
  else
    fail "Phase summary link removed" "Link still present"
  fi

  # Check task status preserved
  if grep -q "\[x\] Task 3: Integration" "$plan_dir/001_test.md"; then
    pass "Task completion status preserved"
  else
    fail "Task completion status preserved" "Completed task not found"
  fi
}

# Test 2: Remove phase from expanded list
test_remove_expanded_phase() {
  create_expanded_plan
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  # Remove phase 2 from expanded list
  remove_expanded_phase \
    "$plan_dir/001_test.md" \
    2

  # Check metadata
  if grep -q "Expanded Phases.*: \[3\]" "$plan_dir/001_test.md"; then
    pass "Phase removed from Expanded Phases"
  else
    fail "Phase removed from Expanded Phases" "Metadata not updated correctly"
  fi
}

# Test 3: Check remaining phases
test_has_remaining_phases() {
  create_expanded_plan
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  # Should have remaining phases
  local has_remaining=$(has_remaining_phases "$plan_dir")

  if [[ "$has_remaining" == "true" ]]; then
    pass "Detect remaining phases"
  else
    fail "Detect remaining phases" "Expected true, got $has_remaining"
  fi

  # Remove all phase files
  rm "$plan_dir/phase_2_implementation.md"
  rm "$plan_dir/phase_3_deployment.md"

  # Should have no remaining phases
  has_remaining=$(has_remaining_phases "$plan_dir")

  if [[ "$has_remaining" == "false" ]]; then
    pass "Detect no remaining phases"
  else
    fail "Detect no remaining phases" "Expected false, got $has_remaining"
  fi
}

# Test 4: Cleanup plan directory
test_cleanup_plan_directory() {
  create_expanded_plan
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  # Remove all phase files except main plan
  rm "$plan_dir/phase_2_implementation.md"
  rm "$plan_dir/phase_3_deployment.md"

  # Cleanup directory
  local new_path=$(cleanup_plan_directory "$plan_dir")

  # Check that plan was moved to parent
  if [[ -f "$new_path" ]]; then
    pass "Plan file moved to parent"
  else
    fail "Plan file moved to parent" "File not found at $new_path"
    return
  fi

  # Check that directory was deleted
  if [[ ! -d "$plan_dir" ]]; then
    pass "Plan directory deleted"
  else
    fail "Plan directory deleted" "Directory still exists"
  fi

  # Check that file is at expected location
  if [[ "$new_path" == "$TEST_DIR/specs/plans/001_test.md" ]]; then
    pass "Plan moved to correct location"
  else
    fail "Plan moved to correct location" "Expected $TEST_DIR/specs/plans/001_test.md, got $new_path"
  fi
}

# Test 5: Full collapse workflow (non-last phase)
test_full_collapse_non_last() {
  create_expanded_plan
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  info "Testing full collapse workflow (non-last phase)"

  # Merge phase 2
  merge_phase_into_plan \
    "$plan_dir/001_test.md" \
    "$plan_dir/phase_2_implementation.md" \
    2

  # Remove from metadata
  remove_expanded_phase \
    "$plan_dir/001_test.md" \
    2

  # Delete phase file
  rm "$plan_dir/phase_2_implementation.md"

  # Verify content in plan
  if grep -q "Task 2: Frontend setup" "$plan_dir/001_test.md"; then
    pass "Full collapse: content preserved"
  else
    fail "Full collapse: content preserved" "Content not found"
    return
  fi

  # Verify metadata
  if grep -q "Expanded Phases.*: \[3\]" "$plan_dir/001_test.md"; then
    pass "Full collapse: metadata updated"
  else
    fail "Full collapse: metadata updated" "Metadata incorrect"
  fi

  # Verify directory still exists (phase 3 remains)
  if [[ -d "$plan_dir" ]] && [[ -f "$plan_dir/phase_3_deployment.md" ]]; then
    pass "Full collapse: directory retained"
  else
    fail "Full collapse: directory retained" "Directory or phase 3 missing"
  fi
}

# Test 6: Full collapse workflow (last phase)
test_full_collapse_last() {
  create_expanded_plan
  local plan_dir="$TEST_DIR/specs/plans/001_test"

  info "Testing full collapse workflow (last phase after removing others)"

  # Remove phase 2 file
  rm "$plan_dir/phase_2_implementation.md"

  # Merge phase 3
  merge_phase_into_plan \
    "$plan_dir/001_test.md" \
    "$plan_dir/phase_3_deployment.md" \
    3

  # Remove from metadata
  remove_expanded_phase \
    "$plan_dir/001_test.md" \
    3

  # Delete phase file
  rm "$plan_dir/phase_3_deployment.md"

  # Update structure level
  update_structure_level \
    "$plan_dir/001_test.md" \
    0

  # Cleanup directory
  local new_path=$(cleanup_plan_directory "$plan_dir")

  # Verify file moved
  if [[ -f "$new_path" ]]; then
    pass "Last collapse: plan moved"
  else
    fail "Last collapse: plan moved" "Plan not found"
    return
  fi

  # Verify directory deleted
  if [[ ! -d "$plan_dir" ]]; then
    pass "Last collapse: directory deleted"
  else
    fail "Last collapse: directory deleted" "Directory still exists"
  fi

  # Verify structure level
  if grep -q "Structure Level.*: 0" "$new_path"; then
    pass "Last collapse: structure level updated"
  else
    fail "Last collapse: structure level updated" "Structure level incorrect"
  fi
}

# Run all tests
run_tests() {
  info "Starting progressive collapse tests"
  setup

  test_merge_phase
  test_remove_expanded_phase
  test_has_remaining_phases
  test_cleanup_plan_directory
  test_full_collapse_non_last
  test_full_collapse_last

  cleanup

  echo ""
  echo "========================================="
  echo "Test Results:"
  echo "  Total:  $TESTS_RUN"
  echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
  echo "========================================="

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

# Run tests
run_tests
