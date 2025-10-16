#!/usr/bin/env bash
# test_hierarchy_updates.sh
#
# Test suite for checkbox hierarchy update utilities.
# Tests checkbox-utils.sh functions across Level 0/1/2 plan structures.

set -euo pipefail

# Detect project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CLAUDE_PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the checkbox utilities
source "$CLAUDE_PROJECT_DIR/.claude/lib/checkbox-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source checkbox-utils.sh"
  exit 1
}

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
pass_test() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ $1"
}

fail_test() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "✗ $1"
}

print_suite_header() {
  echo ""
  echo "============================================"
  echo "  Test Suite: $1"
  echo "============================================"
  echo ""
}

print_suite_summary() {
  echo ""
  echo "============================================"
  echo "  Test Summary"
  echo "============================================"
  echo "  Tests Run:    $TESTS_RUN"
  echo "  Tests Passed: $TESTS_PASSED"
  echo "  Tests Failed: $TESTS_FAILED"
  echo "============================================"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
  fi
}

# Test 1: Update checkbox in single file
test_update_checkbox_single_file() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local test_file=$(mktemp)

  cat > "$test_file" <<'EOF'
# Test Plan

## Phase 1: Implementation

Tasks:
- [ ] Implement feature A
- [ ] Implement feature B
- [ ] Test implementation
EOF

  # Update checkbox
  update_checkbox "$test_file" "Implement feature A" "x"

  # Verify update
  if grep -qF -- "- [x] Implement feature A" "$test_file"; then
    pass_test "Update checkbox in single file"
  else
    fail_test "Update checkbox in single file - checkbox not updated"
  fi

  rm -f "$test_file"
}

# Test 2: Update checkbox with fuzzy matching
test_update_checkbox_fuzzy_match() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local test_file=$(mktemp)

  cat > "$test_file" <<'EOF'
Tasks:
- [ ] Implement authentication middleware for API endpoints
- [ ] Test authentication flow
EOF

  # Update using partial pattern
  update_checkbox "$test_file" "authentication middleware" "x"

  # Verify fuzzy match worked
  if grep -qF -- "- [x] Implement authentication middleware" "$test_file"; then
    pass_test "Fuzzy matching works correctly"
  else
    fail_test "Fuzzy matching failed"
  fi

  rm -f "$test_file"
}

# Test 3: Propagate checkbox update (Level 0 - single file)
test_propagate_level0() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local test_dir=$(mktemp -d)
  local plan_file="$test_dir/test_plan.md"

  cat > "$plan_file" <<'EOF'
# Test Plan

### Phase 1: Implementation

Tasks:
- [ ] Create module A
- [ ] Create module B
- [ ] Test modules
EOF

  # Propagate update (Level 0, single file)
  propagate_checkbox_update "$plan_file" 1 "Create module A" "x" 2>/dev/null || true

  # Verify update
  if grep -qF -- "- [x] Create module A" "$plan_file"; then
    pass_test "Level 0 propagation works"
  else
    fail_test "Level 0 propagation failed"
  fi

  rm -rf "$test_dir"
}

# Test 4: Mark phase complete (Level 0)
test_mark_phase_complete_level0() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local test_dir=$(mktemp -d)
  local plan_file="$test_dir/test_plan.md"

  cat > "$plan_file" <<'EOF'
# Test Plan

### Phase 1: Setup

Tasks:
- [ ] Task 1
- [ ] Task 2

### Phase 2: Implementation

Tasks:
- [ ] Task 3
- [ ] Task 4
EOF

  # Mark Phase 1 complete
  mark_phase_complete "$plan_file" 1

  # Verify Phase 1 tasks marked complete
  local phase1_complete=$(sed -n '/^### Phase 1:/,/^### Phase 2:/p' "$plan_file" | grep -cF -- "- [x]" || echo "0")

  if [[ "$phase1_complete" -eq 2 ]]; then
    pass_test "Mark phase complete (Level 0)"
  else
    fail_test "Mark phase complete - Phase 1 not fully marked complete (found $phase1_complete/2)"
  fi

  rm -rf "$test_dir"
}

# Test 5: Verify checkbox consistency (Level 0 - always consistent)
test_verify_consistency_level0() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local test_dir=$(mktemp -d)
  local plan_file="$test_dir/test_plan.md"

  cat > "$plan_file" <<'EOF'
# Test Plan

### Phase 1: Setup

Tasks:
- [x] Task 1
- [ ] Task 2
EOF

  # Verify consistency (Level 0 always returns 0)
  if verify_checkbox_consistency "$plan_file" 1 2>/dev/null; then
    pass_test "Level 0 consistency verification"
  else
    fail_test "Level 0 consistency verification failed"
  fi

  rm -rf "$test_dir"
}

# Test 6: Update checkbox handles missing task gracefully
test_update_checkbox_missing_task() {
  TESTS_RUN=$((TESTS_RUN + 1))
  local test_file=$(mktemp)

  cat > "$test_file" <<'EOF'
Tasks:
- [ ] Task A
- [ ] Task B
EOF

  # Try to update non-existent task
  if ! update_checkbox "$test_file" "Task C" "x" 2>/dev/null; then
    pass_test "Missing task handled correctly"
  else
    fail_test "Should have returned error for missing task"
  fi

  rm -f "$test_file"
}

# Run all tests
run_test_suite() {
  print_suite_header "Checkbox Hierarchy Updates"

  test_update_checkbox_single_file
  test_update_checkbox_fuzzy_match
  test_propagate_level0
  test_mark_phase_complete_level0
  test_verify_consistency_level0
  test_update_checkbox_missing_task

  print_suite_summary
}

run_test_suite
