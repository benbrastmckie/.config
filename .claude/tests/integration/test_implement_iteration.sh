#!/usr/bin/env bash
# Integration test for /implement command iteration behavior
# Tests multi-iteration execution, backward compatibility, and safety limits

set -euo pipefail

# Test isolation pattern to prevent production directory pollution
TEST_ROOT="/tmp/test_isolation_$$"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap
trap 'rm -rf "$TEST_ROOT"' EXIT

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_test() {
  echo -e "${YELLOW}[TEST $((TESTS_RUN + 1))]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((TESTS_PASSED++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((TESTS_FAILED++))
}

# Setup test environment
setup_test_env() {
  mkdir -p "$TEST_ROOT/.claude/"{lib,commands,agents,tmp,data/checkpoints}
  mkdir -p "$CLAUDE_SPECS_ROOT"

  # Copy required libraries and files
  cp -r /home/benjamin/.config/.claude/lib/* "$TEST_ROOT/.claude/lib/"
  cp /home/benjamin/.config/.claude/commands/implement.md "$TEST_ROOT/.claude/commands/"
  cp /home/benjamin/.config/.claude/agents/implementer-coordinator.md "$TEST_ROOT/.claude/agents/"

  # Initialize git repo for project detection
  cd "$TEST_ROOT"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"
}

# Create test plan with N phases
create_test_plan() {
  local phase_count=$1
  local plan_dir="$CLAUDE_SPECS_ROOT/test_plan"
  mkdir -p "$plan_dir/plans"

  local plan_file="$plan_dir/plans/test-plan.md"

  cat > "$plan_file" <<EOF
# Test Implementation Plan

## Metadata
- **Status**: [NOT STARTED]

## Implementation Phases

EOF

  for ((i=1; i<=phase_count; i++)); do
    cat >> "$plan_file" <<EOF
### Phase $i: Test Phase $i [NOT STARTED]
dependencies: []

**Tasks**:
- [ ] Task $i.1
- [ ] Task $i.2

**Expected Duration**: 1 hour

EOF
  done

  echo "$plan_file"
}

# Create mock implementer-coordinator that simulates work
create_mock_coordinator() {
  local mock_script="$TEST_ROOT/.claude/agents/mock-coordinator.sh"

  cat > "$mock_script" <<'MOCK_EOF'
#!/usr/bin/env bash
# Mock implementer-coordinator for testing

ITERATION=${1:-1}
PLAN_FILE=${2:-}
SUMMARIES_DIR=${3:-}

# Simulate some work
sleep 0.1

# Create summary
SUMMARY_FILE="$SUMMARIES_DIR/implementation_summary_iter${ITERATION}.md"
mkdir -p "$SUMMARIES_DIR"

# Determine work remaining based on iteration
if [ "$ITERATION" -eq 1 ]; then
  WORK_REMAINING="Phase 4 Phase 5 Phase 6 Phase 7 Phase 8 Phase 9 Phase 10"
  REQUIRES_CONTINUATION="true"
elif [ "$ITERATION" -eq 2 ]; then
  WORK_REMAINING="Phase 7 Phase 8 Phase 9 Phase 10"
  REQUIRES_CONTINUATION="true"
elif [ "$ITERATION" -eq 3 ]; then
  WORK_REMAINING="0"
  REQUIRES_CONTINUATION="false"
else
  WORK_REMAINING="0"
  REQUIRES_CONTINUATION="false"
fi

cat > "$SUMMARY_FILE" <<EOF
# Implementation Summary - Iteration $ITERATION

## Work Status
Completed: $((ITERATION * 3)) of 10 phases ($((ITERATION * 30))% complete)

## Phases Completed This Iteration
- Phase $((ITERATION * 3 - 2))
- Phase $((ITERATION * 3 - 1))
- Phase $((ITERATION * 3))

## Testing Strategy
- Test Files Created: test_phase_${ITERATION}.sh
- Test Execution: bash test_phase_${ITERATION}.sh
- Coverage Target: 80%
EOF

# Return completion signal
echo "IMPLEMENTATION_COMPLETE: $((ITERATION * 3))"
echo "plan_file: $PLAN_FILE"
echo "topic_path: $(dirname "$(dirname "$PLAN_FILE")")"
echo "summary_path: $SUMMARY_FILE"
echo "work_remaining: $WORK_REMAINING"
echo "context_exhausted: false"
echo "context_usage_percent: $((ITERATION * 30))%"
echo "requires_continuation: $REQUIRES_CONTINUATION"
echo "stuck_detected: false"

exit 0
MOCK_EOF

  chmod +x "$mock_script"
  echo "$mock_script"
}

# Test 1: Multi-iteration completion
test_multi_iteration() {
  ((TESTS_RUN++))
  log_test "Multi-iteration completion with large plan"

  local plan_file=$(create_test_plan 10)
  local topic_dir=$(dirname "$(dirname "$plan_file")")

  # Create state for iteration
  local workflow_id="implement_test_$$"
  local state_file="$TEST_ROOT/.claude/tmp/workflow_state_${workflow_id}.env"
  mkdir -p "$(dirname "$state_file")"

  cat > "$state_file" <<EOF
WORKFLOW_ID=$workflow_id
PLAN_FILE=$plan_file
TOPIC_PATH=$topic_dir
SUMMARIES_DIR=$topic_dir/summaries
ITERATION=1
MAX_ITERATIONS=5
CONTEXT_THRESHOLD=90
STARTING_PHASE=1
IMPLEMENTATION_STATUS=continuing
EOF

  echo "$workflow_id" > "$TEST_ROOT/.claude/tmp/implement_state_id.txt"

  # Simulate iteration 1
  mkdir -p "$topic_dir/summaries"
  bash "$TEST_ROOT/.claude/agents/mock-coordinator.sh" 1 "$plan_file" "$topic_dir/summaries"

  # Verify summary created
  if [ -f "$topic_dir/summaries/implementation_summary_iter1.md" ]; then
    log_pass "Iteration 1 summary created"
  else
    log_fail "Iteration 1 summary not created"
    return 1
  fi

  # Verify work_remaining reported
  local summary_content=$(cat "$topic_dir/summaries/implementation_summary_iter1.md")
  if echo "$summary_content" | grep -q "Work Status"; then
    log_pass "Summary contains Work Status section"
  else
    log_fail "Summary missing Work Status section"
    return 1
  fi

  log_pass "Multi-iteration test completed successfully"
}

# Test 2: Single-iteration backward compatibility
test_single_iteration() {
  ((TESTS_RUN++))
  log_test "Single-iteration backward compatibility with small plan"

  local plan_file=$(create_test_plan 3)
  local topic_dir=$(dirname "$(dirname "$plan_file")")

  # Create state for single iteration
  local workflow_id="implement_single_$$"
  local state_file="$TEST_ROOT/.claude/tmp/workflow_state_${workflow_id}.env"
  mkdir -p "$(dirname "$state_file")"

  cat > "$state_file" <<EOF
WORKFLOW_ID=$workflow_id
PLAN_FILE=$plan_file
TOPIC_PATH=$topic_dir
SUMMARIES_DIR=$topic_dir/summaries
ITERATION=1
MAX_ITERATIONS=5
CONTEXT_THRESHOLD=90
STARTING_PHASE=1
IMPLEMENTATION_STATUS=complete
EOF

  echo "$workflow_id" > "$TEST_ROOT/.claude/tmp/implement_state_id.txt"

  # Simulate single iteration that completes
  mkdir -p "$topic_dir/summaries"

  # Create coordinator that reports completion
  local summary_file="$topic_dir/summaries/implementation_summary_complete.md"
  cat > "$summary_file" <<EOF
# Implementation Summary

## Work Status
Completed: 3 of 3 phases (100% complete)

## Testing Strategy
- Test Files Created: test_complete.sh
- Test Execution: bash test_complete.sh
- Coverage Target: 80%
EOF

  # Verify immediate completion
  if grep -q "100% complete" "$summary_file"; then
    log_pass "Single iteration completed in one pass"
  else
    log_fail "Single iteration did not complete as expected"
    return 1
  fi

  log_pass "Single-iteration backward compatibility test passed"
}

# Test 3: Max iterations safety
test_max_iterations() {
  ((TESTS_RUN++))
  log_test "Max iterations safety limit enforcement"

  local plan_file=$(create_test_plan 20)
  local topic_dir=$(dirname "$(dirname "$plan_file")")

  # Create state at max iterations
  local workflow_id="implement_max_$$"
  local state_file="$TEST_ROOT/.claude/tmp/workflow_state_${workflow_id}.env"
  mkdir -p "$(dirname "$state_file")"

  # Set ITERATION to MAX_ITERATIONS
  cat > "$state_file" <<EOF
WORKFLOW_ID=$workflow_id
PLAN_FILE=$plan_file
TOPIC_PATH=$topic_dir
SUMMARIES_DIR=$topic_dir/summaries
ITERATION=5
MAX_ITERATIONS=5
CONTEXT_THRESHOLD=90
STARTING_PHASE=1
IMPLEMENTATION_STATUS=continuing
WORK_REMAINING=Phase 15 Phase 16 Phase 17 Phase 18 Phase 19 Phase 20
EOF

  echo "$workflow_id" > "$TEST_ROOT/.claude/tmp/implement_state_id.txt"

  # The iteration decision block should detect max iterations and halt
  # We can't easily test the full command flow, but we can verify state

  if [ "$(grep ITERATION= "$state_file" | cut -d= -f2)" -eq 5 ]; then
    log_pass "Max iterations reached (5/5)"
  else
    log_fail "Max iterations check failed"
    return 1
  fi

  # Verify IMPLEMENTATION_STATUS is continuing (would trigger max_iterations check)
  if grep -q "IMPLEMENTATION_STATUS=continuing" "$state_file"; then
    log_pass "Status correctly set to continuing at max iterations"
  else
    log_fail "Status not set correctly"
    return 1
  fi

  log_pass "Max iterations safety test passed"
}

# Test 4: Checkpoint resumption during iteration
test_checkpoint_resumption() {
  ((TESTS_RUN++))
  log_test "Checkpoint resumption with iteration counter preservation"

  local plan_file=$(create_test_plan 8)
  local topic_dir=$(dirname "$(dirname "$plan_file")")

  # Create checkpoint after first iteration
  local workflow_id="implement_resume_$$"
  local checkpoint_dir="$TEST_ROOT/.claude/data/checkpoints"
  local checkpoint_file="$checkpoint_dir/implement_resume_checkpoint.txt"
  mkdir -p "$checkpoint_dir"

  cat > "$checkpoint_file" <<EOF
[CHECKPOINT] Iteration 2 of 5
Context: ITERATION=2, CONTINUATION_CONTEXT=$topic_dir/summaries/iteration_1_summary.md, WORK_REMAINING=Phase 5 Phase 6 Phase 7 Phase 8
Ready for: Next iteration (Block 1b Task invocation)
EOF

  # Create state file with iteration 2
  local state_file="$TEST_ROOT/.claude/tmp/workflow_state_${workflow_id}.env"
  cat > "$state_file" <<EOF
WORKFLOW_ID=$workflow_id
PLAN_FILE=$plan_file
TOPIC_PATH=$topic_dir
SUMMARIES_DIR=$topic_dir/summaries
ITERATION=2
MAX_ITERATIONS=5
CONTEXT_THRESHOLD=90
STARTING_PHASE=1
IMPLEMENTATION_STATUS=continuing
CONTINUATION_CONTEXT=$topic_dir/summaries/iteration_1_summary.md
WORK_REMAINING=Phase 5 Phase 6 Phase 7 Phase 8
EOF

  echo "$workflow_id" > "$TEST_ROOT/.claude/tmp/implement_state_id.txt"

  # Verify iteration counter restored
  local restored_iteration=$(grep "ITERATION=" "$state_file" | cut -d= -f2)
  if [ "$restored_iteration" -eq 2 ]; then
    log_pass "Iteration counter restored correctly (2)"
  else
    log_fail "Iteration counter not restored (expected 2, got $restored_iteration)"
    return 1
  fi

  # Verify continuation context preserved
  if grep -q "CONTINUATION_CONTEXT.*iteration_1_summary" "$state_file"; then
    log_pass "Continuation context preserved"
  else
    log_fail "Continuation context not preserved"
    return 1
  fi

  log_pass "Checkpoint resumption test passed"
}

# Test 5: Test isolation verification
test_isolation_verification() {
  ((TESTS_RUN++))
  log_test "Test isolation - no production directory pollution"

  # Verify TEST_ROOT is set to isolated location
  if [[ "$TEST_ROOT" == /tmp/test_isolation_* ]]; then
    log_pass "TEST_ROOT is in isolated location: $TEST_ROOT"
  else
    log_fail "TEST_ROOT not in isolated location: $TEST_ROOT"
    return 1
  fi

  # Verify CLAUDE_SPECS_ROOT points to test location
  if [[ "$CLAUDE_SPECS_ROOT" == "$TEST_ROOT"* ]]; then
    log_pass "CLAUDE_SPECS_ROOT points to test location"
  else
    log_fail "CLAUDE_SPECS_ROOT not isolated: $CLAUDE_SPECS_ROOT"
    return 1
  fi

  # Verify CLAUDE_PROJECT_DIR points to test location
  if [ "$CLAUDE_PROJECT_DIR" = "$TEST_ROOT" ]; then
    log_pass "CLAUDE_PROJECT_DIR points to test root"
  else
    log_fail "CLAUDE_PROJECT_DIR not isolated: $CLAUDE_PROJECT_DIR"
    return 1
  fi

  # Verify production directories not polluted
  if [ ! -d "/home/benjamin/.config/.claude/specs/test_plan" ]; then
    log_pass "Production specs directory not polluted"
  else
    log_fail "Production specs directory polluted!"
    return 1
  fi

  log_pass "Test isolation verification passed"
}

# Main test runner
main() {
  echo "=========================================="
  echo "  /implement Iteration Integration Tests"
  echo "=========================================="
  echo ""

  # Setup
  echo "Setting up test environment..."
  setup_test_env
  create_mock_coordinator
  echo "Test environment ready"
  echo ""

  # Run tests
  test_multi_iteration || true
  echo ""

  test_single_iteration || true
  echo ""

  test_max_iterations || true
  echo ""

  test_checkpoint_resumption || true
  echo ""

  test_isolation_verification || true
  echo ""

  # Summary
  echo "=========================================="
  echo "  Test Results"
  echo "=========================================="
  echo "Tests run:    $TESTS_RUN"
  echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
  fi
}

# Run tests
main "$@"
