#!/usr/bin/env bash
# Unit tests for lib/plan/complexity-utils.sh
#
# Tests complexity calculation functions:
#   - calculate_phase_complexity
#   - calculate_plan_complexity
#   - exceeds_complexity_threshold

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

# Source test helpers
source "${SCRIPT_DIR}/../lib/test-helpers.sh" 2>/dev/null || \
  { echo "Cannot load test helpers"; exit 1; }

# Source library under test
LIB_PATH="${PROJECT_ROOT}/lib/plan/complexity-utils.sh"
source "$LIB_PATH" 2>/dev/null || { echo "Cannot load complexity-utils"; exit 1; }

# Create temp directory for test fixtures
TEST_TMP="${SCRIPT_DIR}/../tmp/test_complexity_$$"
mkdir -p "$TEST_TMP"
trap "rm -rf '$TEST_TMP'" EXIT

setup_test

# Test: calculate_plan_complexity with basic inputs
test_plan_complexity_basic() {
  local score
  score=$(calculate_plan_complexity 10 3 5 2)

  # Expected: (10 * 0.3) + (3 * 1.0) + (5 * 0.1) + 2 = 3 + 3 + 0.5 + 2 = 8.5
  if [[ "$score" == "8.5" ]]; then
    pass "plan_complexity_basic_calculation"
  else
    fail "plan_complexity_basic_calculation" "Expected 8.5, got $score"
  fi
}

# Test: calculate_plan_complexity with zero inputs
test_plan_complexity_zeros() {
  local score
  score=$(calculate_plan_complexity 0 0 0 0)

  assert_equals "0.0" "$score" "plan_complexity_zero_inputs"
}

# Test: calculate_plan_complexity with missing args defaults to 0
test_plan_complexity_missing_args() {
  local score
  score=$(calculate_plan_complexity 10)

  # Expected: (10 * 0.3) + 0 + 0 + 0 = 3.0
  assert_equals "3.0" "$score" "plan_complexity_missing_args"
}

# Test: exceeds_complexity_threshold returns 0 when exceeded
test_threshold_exceeded() {
  if exceeds_complexity_threshold 10.0 8.0; then
    pass "threshold_exceeded_returns_true"
  else
    fail "threshold_exceeded_returns_true" "Score 10.0 should exceed threshold 8.0"
  fi
}

# Test: exceeds_complexity_threshold returns 1 when not exceeded
test_threshold_not_exceeded() {
  if ! exceeds_complexity_threshold 5.0 8.0; then
    pass "threshold_not_exceeded_returns_false"
  else
    fail "threshold_not_exceeded_returns_false" "Score 5.0 should not exceed threshold 8.0"
  fi
}

# Test: exceeds_complexity_threshold handles equal values
test_threshold_equal() {
  if ! exceeds_complexity_threshold 8.0 8.0; then
    pass "threshold_equal_returns_false"
  else
    fail "threshold_equal_returns_false" "Score equal to threshold should return false"
  fi
}

# Test: calculate_phase_complexity with nonexistent file
test_phase_complexity_no_file() {
  local score
  score=$(calculate_phase_complexity "/nonexistent/file.md" 1 2>&1)

  # Should return 0 or error
  if [[ "$score" == "0" || "$score" == *"0"* ]]; then
    pass "phase_complexity_no_file_returns_zero"
  else
    fail "phase_complexity_no_file_returns_zero" "Expected 0 for nonexistent file, got $score"
  fi
}

# Test: calculate_phase_complexity with sample plan
test_phase_complexity_sample() {
  # Create a sample plan file
  local test_plan="${TEST_TMP}/sample_plan.md"
  cat > "$test_plan" <<'EOF'
# Sample Plan

### Phase 1: Setup

Tasks:
- [ ] Create directory structure
- [ ] Initialize configuration
- [ ] Set up dependencies

References:
- ./setup.sh
- ./config.lua

```bash
mkdir -p test
```

Expected Duration: 1 hour

### Phase 2: Implementation
EOF

  local score
  score=$(calculate_phase_complexity "$test_plan" 1)

  # Score should be > 0 based on tasks, files, code blocks, duration
  # Use awk instead of bc for portability
  if awk -v score="$score" 'BEGIN { exit (score > 0) ? 0 : 1 }'; then
    pass "phase_complexity_sample_positive_score"
  else
    fail "phase_complexity_sample_positive_score" "Expected positive score, got $score"
  fi
}

# Test: calculate_phase_complexity task counting
test_phase_complexity_task_count() {
  # Create plan with known task count
  local test_plan="${TEST_TMP}/task_count_plan.md"
  cat > "$test_plan" <<'EOF'
### Phase 1: Tasks

- [ ] Task one
- [ ] Task two
- [ ] Task three
- [ ] Task four
- [ ] Task five

### Phase 2: Next
EOF

  local score
  score=$(calculate_phase_complexity "$test_plan" 1)

  # 5 tasks * 0.5 = 2.5 minimum
  # Use awk instead of bc for portability
  if awk -v score="$score" 'BEGIN { exit (score >= 2.5) ? 0 : 1 }'; then
    pass "phase_complexity_counts_tasks"
  else
    fail "phase_complexity_counts_tasks" "Expected score >= 2.5 for 5 tasks, got $score"
  fi
}

# Test: calculate_phase_complexity empty phase
test_phase_complexity_empty() {
  local test_plan="${TEST_TMP}/empty_plan.md"
  cat > "$test_plan" <<'EOF'
### Phase 1: Empty

### Phase 2: Next
EOF

  local score
  score=$(calculate_phase_complexity "$test_plan" 1)

  assert_equals "0.0" "$score" "phase_complexity_empty_phase"
}

# Test: calculate_plan_complexity with large values
test_plan_complexity_large() {
  local score
  score=$(calculate_plan_complexity 100 20 50 10)

  # Expected: (100 * 0.3) + (20 * 1.0) + (50 * 0.1) + 10 = 30 + 20 + 5 + 10 = 65.0
  assert_equals "65.0" "$score" "plan_complexity_large_values"
}

# Run all tests
test_plan_complexity_basic
test_plan_complexity_zeros
test_plan_complexity_missing_args
test_threshold_exceeded
test_threshold_not_exceeded
test_threshold_equal
test_phase_complexity_no_file
test_phase_complexity_sample
test_phase_complexity_task_count
test_phase_complexity_empty
test_plan_complexity_large

teardown_test
