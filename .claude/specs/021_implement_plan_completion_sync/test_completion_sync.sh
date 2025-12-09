#!/bin/bash
# Test script for completion marker synchronization
# Tests mark_phase_complete() propagation across Level 0, 1, 2 structures

# Note: Not using set -e to allow all tests to run even if some fail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Source required libraries
source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh 2>/dev/null || {
  echo -e "${RED}ERROR: Cannot load checkbox-utils.sh${NC}"
  exit 1
}

# Helper function for test results
pass_test() {
  echo -e "${GREEN}✓ PASS:${NC} $1"
  ((TESTS_PASSED++)) || true
}

fail_test() {
  echo -e "${RED}✗ FAIL:${NC} $1"
  ((TESTS_FAILED++)) || true
}

info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

# Test 1: Level 0 (Inline Plan)
echo "========================================="
echo "Test 1: Level 0 Inline Plan"
echo "========================================="

TEST_DIR="/tmp/test-completion-sync-$$"
mkdir -p "$TEST_DIR"

plan_file="$TEST_DIR/test-plan-level0.md"
cat > "$plan_file" <<'EOF'
# Test Plan Level 0

## Phase 1: Test Phase [IN PROGRESS]
- [ ] Task 1
- [ ] Task 2
EOF

info "Testing mark_phase_complete() on Level 0 plan..."
mark_phase_complete "$plan_file" 1

if grep -q "\[COMPLETE\]" "$plan_file"; then
  pass_test "Level 0: Main plan heading has [COMPLETE] marker"
else
  fail_test "Level 0: Main plan missing [COMPLETE] marker"
fi

if grep -q '\- \[x\] Task 1' "$plan_file" && grep -q '\- \[x\] Task 2' "$plan_file"; then
  pass_test "Level 0: All tasks marked complete"
else
  fail_test "Level 0: Tasks not marked complete"
fi

# Test 2: Level 1 (Expanded Phases)
echo ""
echo "========================================="
echo "Test 2: Level 1 Expanded Phases"
echo "========================================="

plan_dir="$TEST_DIR/test-plan-level1"
mkdir -p "$plan_dir"

main_plan="$TEST_DIR/test-plan-level1.md"
cat > "$main_plan" <<'EOF'
# Test Plan Level 1

## Phase 2: Test Phase [IN PROGRESS]
- [ ] Task 1
EOF

phase_file="$plan_dir/phase_2_test_phase.md"
cat > "$phase_file" <<'EOF'
# Phase 2: Test Phase - Expanded [IN PROGRESS]
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
EOF

info "Testing mark_phase_complete() on Level 1 plan with expanded phase..."
mark_phase_complete "$main_plan" 2

if grep -q "\[COMPLETE\]" "$main_plan"; then
  pass_test "Level 1: Main plan heading has [COMPLETE] marker"
else
  fail_test "Level 1: Main plan missing [COMPLETE] marker"
fi

if grep -q "\[COMPLETE\]" "$phase_file"; then
  pass_test "Level 1: Phase file heading has [COMPLETE] marker"
else
  fail_test "Level 1: Phase file missing [COMPLETE] marker"
  cat "$phase_file"
fi

if grep -q '\- \[x\] Task 1' "$main_plan"; then
  pass_test "Level 1: Main plan tasks marked complete"
else
  fail_test "Level 1: Main plan tasks not marked complete"
fi

if grep -q '\- \[x\] Task 1' "$phase_file" && grep -q '\- \[x\] Task 2' "$phase_file" && grep -q '\- \[x\] Task 3' "$phase_file"; then
  pass_test "Level 1: Phase file tasks marked complete"
else
  fail_test "Level 1: Phase file tasks not marked complete"
fi

# Test 3: Level 2 (Expanded Stages)
echo ""
echo "========================================="
echo "Test 3: Level 2 Expanded Stages"
echo "========================================="

plan_dir_l2="$TEST_DIR/test-plan-level2"
phase_dir="$plan_dir_l2/phase_3_test_phase"
mkdir -p "$phase_dir"

main_plan_l2="$TEST_DIR/test-plan-level2.md"
cat > "$main_plan_l2" <<'EOF'
# Test Plan Level 2

## Phase 3: Test Phase [IN PROGRESS]
- [ ] Task 1
EOF

phase_file_l2="$plan_dir_l2/phase_3_test_phase.md"
cat > "$phase_file_l2" <<'EOF'
# Phase 3: Test Phase - Expanded [IN PROGRESS]

### Stage 1: Setup [IN PROGRESS]
- [ ] Task 1

### Stage 2: Execute [NOT STARTED]
- [ ] Task 2
EOF

stage_file="$phase_dir/stage_1_setup.md"
cat > "$stage_file" <<'EOF'
# Stage 1: Setup [IN PROGRESS]
- [ ] Task 1
- [ ] Task 2
EOF

info "Testing mark_phase_complete() on Level 2 plan with expanded stages..."
mark_phase_complete "$main_plan_l2" 3

if grep -q "\[COMPLETE\]" "$main_plan_l2"; then
  pass_test "Level 2: Main plan heading has [COMPLETE] marker"
else
  fail_test "Level 2: Main plan missing [COMPLETE] marker"
fi

if grep -q "\[COMPLETE\]" "$phase_file_l2"; then
  pass_test "Level 2: Phase file heading has [COMPLETE] marker"
else
  fail_test "Level 2: Phase file missing [COMPLETE] marker"
fi

if grep -q '\- \[x\] Task 1' "$main_plan_l2"; then
  pass_test "Level 2: Main plan tasks marked complete"
else
  fail_test "Level 2: Main plan tasks not marked complete"
fi

if grep -q '\- \[x\] Task 1' "$phase_file_l2" && grep -q '\- \[x\] Task 2' "$phase_file_l2"; then
  pass_test "Level 2: Phase file tasks marked complete"
else
  fail_test "Level 2: Phase file tasks not marked complete"
fi

# Test 4: Idempotent Behavior
echo ""
echo "========================================="
echo "Test 4: Idempotent Behavior"
echo "========================================="

info "Testing mark_phase_complete() called twice on same phase..."
mark_phase_complete "$main_plan" 2

if grep -q "\[COMPLETE\]" "$main_plan" && [ $(grep -c "\[COMPLETE\]" "$main_plan") -eq 1 ]; then
  pass_test "Idempotent: No duplicate markers in main plan"
else
  fail_test "Idempotent: Duplicate markers found in main plan"
fi

if grep -q "\[COMPLETE\]" "$phase_file" && [ $(grep -c "\[COMPLETE\]" "$phase_file") -eq 1 ]; then
  pass_test "Idempotent: No duplicate markers in phase file"
else
  fail_test "Idempotent: Duplicate markers found in phase file"
fi

# Test 5: Error Handling (Non-existent Phase)
echo ""
echo "========================================="
echo "Test 5: Error Handling"
echo "========================================="

info "Testing mark_phase_complete() on non-existent phase..."
if mark_phase_complete "$main_plan" 999 2>/dev/null; then
  pass_test "Error handling: Function returns gracefully for non-existent phase"
else
  pass_test "Error handling: Function handles non-existent phase without crashing"
fi

# Cleanup
rm -rf "$TEST_DIR"

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
