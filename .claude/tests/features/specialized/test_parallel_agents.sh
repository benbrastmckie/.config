#!/usr/bin/env bash
# Test parallel agent invocation and result aggregation patterns

set -euo pipefail

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Color codes for test output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to report test results
report_test() {
  local test_name="$1"
  local result="$2"

  if [ "$result" = "PASS" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  elif [ "$result" = "SKIP" ]; then
    echo -e "${YELLOW}⊘${NC} $test_name (skipped)"
  else
    echo -e "${RED}✗${NC} $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 1: Result aggregation from multiple successful phases
test_result_aggregation_success() {
  # Simulate agent outputs
  mkdir -p "$TEST_DIR/wave_outputs"

  cat > "$TEST_DIR/wave_outputs/phase_2_output.txt" << 'EOF'
PROGRESS: Phase 2 starting
PROGRESS: Implementing feature_a.lua
PROGRESS: Phase 2 complete
CHANGED: feature_a.lua
CHANGED: tests/feature_a_spec.lua
TEST_OUTPUT_START
✓ All tests passed (3/3)
TEST_OUTPUT_END
EOF

  cat > "$TEST_DIR/wave_outputs/phase_3_output.txt" << 'EOF'
PROGRESS: Phase 3 starting
PROGRESS: Implementing feature_b.lua
PROGRESS: Phase 3 complete
CHANGED: feature_b.lua
CHANGED: tests/feature_b_spec.lua
TEST_OUTPUT_START
✓ All tests passed (2/2)
TEST_OUTPUT_END
EOF

  # Simulate aggregation logic
  declare -A PHASE_STATUS
  declare -A PHASE_FILES

  for phase_num in 2 3; do
    OUTPUT_FILE="$TEST_DIR/wave_outputs/phase_${phase_num}_output.txt"

    if grep -q "PROGRESS: Phase $phase_num complete" "$OUTPUT_FILE"; then
      PHASE_STATUS[$phase_num]="success"
    else
      PHASE_STATUS[$phase_num]="failure"
    fi

    PHASE_FILES[$phase_num]=$(grep "^CHANGED:" "$OUTPUT_FILE" | cut -d':' -f2- | tr '\n' ' ')
  done

  # Verify aggregation
  if [ "${PHASE_STATUS[2]}" = "success" ] && [ "${PHASE_STATUS[3]}" = "success" ]; then
    if [[ "${PHASE_FILES[2]}" =~ "feature_a.lua" ]] && [[ "${PHASE_FILES[3]}" =~ "feature_b.lua" ]]; then
      report_test "Result aggregation (all success)" "PASS"
      return 0
    fi
  fi

  report_test "Result aggregation (all success)" "FAIL"
  echo "  Phase 2 status: ${PHASE_STATUS[2]}"
  echo "  Phase 3 status: ${PHASE_STATUS[3]}"
  return 1
}

# Test 2: Failure handling in parallel execution
test_failure_handling() {
  mkdir -p "$TEST_DIR/wave_fail"

  cat > "$TEST_DIR/wave_fail/phase_2_output.txt" << 'EOF'
PROGRESS: Phase 2 starting
PROGRESS: Phase 2 complete
CHANGED: feature_a.lua
TEST_OUTPUT_START
✓ All tests passed (3/3)
TEST_OUTPUT_END
EOF

  cat > "$TEST_DIR/wave_fail/phase_3_output.txt" << 'EOF'
PROGRESS: Phase 3 starting
ERROR: Test failure in phase 3
✗ 2 tests failed
EOF

  # Simulate aggregation with failure
  declare -A PHASE_STATUS
  WAVE_STATUS="success"
  FAILED_PHASES=()

  for phase_num in 2 3; do
    OUTPUT_FILE="$TEST_DIR/wave_fail/phase_${phase_num}_output.txt"

    if grep -q "PROGRESS: Phase $phase_num complete" "$OUTPUT_FILE"; then
      PHASE_STATUS[$phase_num]="success"
    else
      PHASE_STATUS[$phase_num]="failure"
      WAVE_STATUS="failure"
      FAILED_PHASES+=("$phase_num")
    fi
  done

  # Verify fail-fast detection
  if [ "${PHASE_STATUS[2]}" = "success" ] && [ "${PHASE_STATUS[3]}" = "failure" ] && [ "$WAVE_STATUS" = "failure" ]; then
    if [ "${#FAILED_PHASES[@]}" -eq 1 ] && [ "${FAILED_PHASES[0]}" = "3" ]; then
      report_test "Failure handling (partial wave failure)" "PASS"
      return 0
    fi
  fi

  report_test "Failure handling (partial wave failure)" "FAIL"
  echo "  Phase 2 status: ${PHASE_STATUS[2]}"
  echo "  Phase 3 status: ${PHASE_STATUS[3]}"
  echo "  Wave status: $WAVE_STATUS"
  echo "  Failed phases: ${FAILED_PHASES[*]}"
  return 1
}

# Test 3: Test output parsing
test_test_output_parsing() {
  mkdir -p "$TEST_DIR/test_outputs"

  cat > "$TEST_DIR/test_outputs/phase_output.txt" << 'EOF'
PROGRESS: Phase 4 starting
PROGRESS: Running tests
TEST_OUTPUT_START
Running test suite...
✓ test_feature_a_basic ... passed
✓ test_feature_a_edge_cases ... passed
✗ test_feature_a_invalid_input ... failed
  Expected: "error"
  Got: "undefined"
✓ test_feature_b ... passed
TEST_OUTPUT_END
PROGRESS: Tests completed with failures
EOF

  # Extract test output
  TEST_OUTPUT=$(sed -n '/^TEST_OUTPUT_START/,/^TEST_OUTPUT_END/p' "$TEST_DIR/test_outputs/phase_output.txt")

  # Verify extraction
  if echo "$TEST_OUTPUT" | grep -q "test_feature_a_basic" && echo "$TEST_OUTPUT" | grep -q "failed"; then
    report_test "Test output parsing" "PASS"
    return 0
  else
    report_test "Test output parsing" "FAIL"
    echo "  Could not extract test output correctly"
    return 1
  fi
}

# Test 4: File changes aggregation across multiple phases
test_file_changes_aggregation() {
  mkdir -p "$TEST_DIR/file_changes"

  cat > "$TEST_DIR/file_changes/phase_2_output.txt" << 'EOF'
CHANGED: src/database.lua
CHANGED: src/models/user.lua
CHANGED: tests/database_spec.lua
EOF

  cat > "$TEST_DIR/file_changes/phase_3_output.txt" << 'EOF'
CHANGED: src/api.lua
CHANGED: src/routes/auth.lua
CHANGED: tests/api_spec.lua
EOF

  cat > "$TEST_DIR/file_changes/phase_4_output.txt" << 'EOF'
CHANGED: src/frontend.lua
CHANGED: src/views/login.lua
CHANGED: tests/frontend_spec.lua
EOF

  # Aggregate file changes
  ALL_FILES=""
  for phase_num in 2 3 4; do
    OUTPUT_FILE="$TEST_DIR/file_changes/phase_${phase_num}_output.txt"
    PHASE_FILES=$(grep "^CHANGED:" "$OUTPUT_FILE" | cut -d':' -f2- | tr '\n' ' ')
    ALL_FILES+="$PHASE_FILES"
  done

  # Verify all files captured
  if [[ "$ALL_FILES" =~ "database.lua" ]] && [[ "$ALL_FILES" =~ "api.lua" ]] && [[ "$ALL_FILES" =~ "frontend.lua" ]]; then
    report_test "File changes aggregation" "PASS"
    return 0
  else
    report_test "File changes aggregation" "FAIL"
    echo "  Missing expected files in aggregation"
    echo "  Got: $ALL_FILES"
    return 1
  fi
}

# Test 5: Empty phase output handling
test_empty_output_handling() {
  mkdir -p "$TEST_DIR/empty_output"

  # Create empty output file (simulating missing agent output)
  touch "$TEST_DIR/empty_output/phase_5_output.txt"

  # Attempt to parse
  OUTPUT_FILE="$TEST_DIR/empty_output/phase_5_output.txt"
  if grep -q "PROGRESS: Phase 5 complete" "$OUTPUT_FILE"; then
    STATUS="success"
  else
    STATUS="failure"
  fi

  # Should mark as failure
  if [ "$STATUS" = "failure" ]; then
    report_test "Empty output handling" "PASS"
    return 0
  else
    report_test "Empty output handling" "FAIL"
    echo "  Expected failure status for empty output"
    return 1
  fi
}

# Test 6: Wave state checkpoint structure
test_wave_checkpoint_structure() {
  # Simulate wave checkpoint data
  WAVE_CHECKPOINT=$(cat <<'EOF'
{
  "current_wave": 2,
  "total_waves": 3,
  "wave_structure": {
    "1": [1],
    "2": [2, 3],
    "3": [4]
  },
  "parallel_execution_enabled": true,
  "max_wave_parallelism": 3,
  "wave_results": {
    "1": {
      "phases": [1],
      "status": "completed",
      "duration_ms": 185000
    },
    "2": {
      "phases": [2, 3],
      "status": "in_progress",
      "parallel": true
    }
  }
}
EOF
)

  # Validate structure
  if command -v jq &> /dev/null; then
    if echo "$WAVE_CHECKPOINT" | jq -e '.current_wave' >/dev/null 2>&1 && \
       echo "$WAVE_CHECKPOINT" | jq -e '.wave_structure["2"]' >/dev/null 2>&1 && \
       echo "$WAVE_CHECKPOINT" | jq -e '.wave_results["1"].status' >/dev/null 2>&1; then
      report_test "Wave checkpoint structure" "PASS"
      return 0
    else
      report_test "Wave checkpoint structure" "FAIL"
      echo "  Checkpoint structure validation failed"
      return 1
    fi
  else
    report_test "Wave checkpoint structure" "SKIP"
    return 0
  fi
}

# Run all tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing Parallel Agent Patterns"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

test_result_aggregation_success || true
test_failure_handling || true
test_test_output_parsing || true
test_file_changes_aggregation || true
test_empty_output_handling || true
test_wave_checkpoint_structure || true

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
