#!/usr/bin/env bash
# Test suite for /build iteration loop functionality
# Tests: iteration checkpoint validation, context estimation, stuck detection, resumption

# Test directory setup
TEST_DIR="${HOME}/.claude/tmp/test_build_iteration_$$"
mkdir -p "$TEST_DIR"

# Cleanup on exit
cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# === Setup ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [ "$expected" = "$actual" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() {
  local file_path="$1"
  local test_name="$2"

  if [ -f "$file_path" ]; then
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: $test_name (file not found: $file_path)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "=========================================="
echo "Build Iteration Integration Tests"
echo "=========================================="
echo ""

# === Test 1: validate_iteration_checkpoint with missing plan_path ===
echo "--- Test 1: Missing plan_path detection ---"

VALID_CHECKPOINT="$TEST_DIR/valid_checkpoint.json"
cat > "$VALID_CHECKPOINT" << 'EOF'
{
  "version": "2.1",
  "timestamp": "2025-11-21T10:00:00Z",
  "plan_path": "/tmp/nonexistent_plan.md",
  "topic_path": "/tmp/topic",
  "iteration": 2,
  "max_iterations": 5,
  "continuation_context": "",
  "work_remaining": "phase_3,phase_4,phase_5",
  "last_work_remaining": "phase_2,phase_3,phase_4,phase_5",
  "context_estimate": 150000,
  "halt_reason": "",
  "workflow_id": "build_test_123"
}
EOF

# Run validation in subshell
RESULT=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  validate_iteration_checkpoint '$VALID_CHECKPOINT' 2>&1
" 2>&1)
EXIT_CODE=$?

if [ "$EXIT_CODE" -ne 0 ] && echo "$RESULT" | grep -q "plan_path file not found"; then
  echo "✓ PASS: validate_iteration_checkpoint detects missing plan_path"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: validate_iteration_checkpoint should detect missing plan_path (exit=$EXIT_CODE)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# === Test 2: validate_iteration_checkpoint with valid checkpoint ===
echo ""
echo "--- Test 2: Valid checkpoint acceptance ---"

# Create a temp plan file to make validation pass
TEMP_PLAN="$TEST_DIR/test_plan.md"
cat > "$TEMP_PLAN" << 'EOF'
# Test Plan

### Phase 1: Setup
- [ ] Task 1

### Phase 2: Implementation
- [ ] Task 2

### Phase 3: Testing
- [ ] Task 3
EOF

# Update checkpoint with valid plan path
cat > "$VALID_CHECKPOINT" << EOF
{
  "version": "2.1",
  "timestamp": "2025-11-21T10:00:00Z",
  "plan_path": "$TEMP_PLAN",
  "topic_path": "$TEST_DIR",
  "iteration": 2,
  "max_iterations": 5,
  "continuation_context": "",
  "work_remaining": "phase_3",
  "last_work_remaining": "phase_2,phase_3",
  "context_estimate": 150000,
  "halt_reason": "",
  "workflow_id": "build_test_123"
}
EOF

EXIT_CODE=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  validate_iteration_checkpoint '$VALID_CHECKPOINT' 2>/dev/null
  echo \$?
" 2>&1 | tail -1)

assert_equals "0" "$EXIT_CODE" "validate_iteration_checkpoint accepts valid checkpoint"

# === Test 3: validate_iteration_checkpoint with invalid iteration ===
echo ""
echo "--- Test 3: Invalid iteration count ---"

INVALID_CHECKPOINT="$TEST_DIR/invalid_iteration.json"
cat > "$INVALID_CHECKPOINT" << EOF
{
  "version": "2.1",
  "plan_path": "$TEMP_PLAN",
  "iteration": 10,
  "max_iterations": 5,
  "work_remaining": "phase_3"
}
EOF

RESULT=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  validate_iteration_checkpoint '$INVALID_CHECKPOINT' 2>&1
" 2>&1)
EXIT_CODE=$?

if echo "$RESULT" | grep -q "iteration.*exceeds max_iterations"; then
  echo "✓ PASS: validate_iteration_checkpoint detects iteration > max_iterations"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "✗ FAIL: validate_iteration_checkpoint should detect iteration > max_iterations"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# === Test 4: load_iteration_checkpoint extracts fields ===
echo ""
echo "--- Test 4: load_iteration_checkpoint field extraction ---"

LOADED_JSON=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  load_iteration_checkpoint '$VALID_CHECKPOINT' 2>/dev/null
" 2>&1)

if [ -n "$LOADED_JSON" ]; then
  LOADED_ITER=$(echo "$LOADED_JSON" | jq -r '.iteration')
  assert_equals "2" "$LOADED_ITER" "load_iteration_checkpoint extracts iteration field"

  LOADED_WORK=$(echo "$LOADED_JSON" | jq -r '.work_remaining')
  assert_equals "phase_3" "$LOADED_WORK" "load_iteration_checkpoint extracts work_remaining"
else
  echo "✗ FAIL: load_iteration_checkpoint returned empty"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# === Test 5: save_iteration_checkpoint creates file ===
echo ""
echo "--- Test 5: save_iteration_checkpoint file creation ---"

SAVE_JSON=$(cat << EOF
{
  "plan_path": "$TEMP_PLAN",
  "topic_path": "$TEST_DIR",
  "iteration": 3,
  "max_iterations": 5,
  "work_remaining": "phase_4,phase_5",
  "workflow_id": "save_test_456"
}
EOF
)

SAVED_PATH=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  save_iteration_checkpoint '$SAVE_JSON' 2>/dev/null
" 2>&1)

if [ -n "$SAVED_PATH" ] && [ -f "$SAVED_PATH" ]; then
  echo "✓ PASS: save_iteration_checkpoint creates checkpoint file"
  TESTS_PASSED=$((TESTS_PASSED + 1))

  # Verify version added
  SAVED_VERSION=$(jq -r '.version' "$SAVED_PATH")
  assert_equals "2.1" "$SAVED_VERSION" "save_iteration_checkpoint sets version 2.1"

  # Clean up saved checkpoint
  rm -f "$SAVED_PATH"
else
  echo "✗ FAIL: save_iteration_checkpoint did not create file ($SAVED_PATH)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# === Test 6: Valid halt_reason values ===
echo ""
echo "--- Test 6: Valid halt_reason values ---"

for halt_reason in "context_threshold" "max_iterations" "stuck" "completion"; do
  HALT_CHECKPOINT="$TEST_DIR/halt_${halt_reason}.json"
  cat > "$HALT_CHECKPOINT" << EOF
{
  "version": "2.1",
  "plan_path": "$TEMP_PLAN",
  "iteration": 1,
  "max_iterations": 5,
  "work_remaining": "",
  "halt_reason": "$halt_reason"
}
EOF

  EXIT_CODE=$(bash -c "
    cd '$PROJECT_DIR'
    source lib/workflow/checkpoint-utils.sh 2>/dev/null
    validate_iteration_checkpoint '$HALT_CHECKPOINT' 2>/dev/null
    echo \$?
  " 2>&1 | tail -1)

  if [ "$EXIT_CODE" = "0" ]; then
    echo "✓ PASS: halt_reason '$halt_reason' accepted"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "✗ FAIL: halt_reason '$halt_reason' should be accepted"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
done

# === Test 7: work_remaining type validation ===
echo ""
echo "--- Test 7: work_remaining type validation ---"

# String type (valid)
STRING_WR="$TEST_DIR/string_wr.json"
cat > "$STRING_WR" << EOF
{
  "version": "2.1",
  "plan_path": "$TEMP_PLAN",
  "iteration": 1,
  "max_iterations": 5,
  "work_remaining": "phase_1,phase_2"
}
EOF

EXIT_CODE=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  validate_iteration_checkpoint '$STRING_WR' 2>/dev/null
  echo \$?
" 2>&1 | tail -1)
assert_equals "0" "$EXIT_CODE" "work_remaining string type accepted"

# Array type (valid)
ARRAY_WR="$TEST_DIR/array_wr.json"
cat > "$ARRAY_WR" << EOF
{
  "version": "2.1",
  "plan_path": "$TEMP_PLAN",
  "iteration": 1,
  "max_iterations": 5,
  "work_remaining": ["phase_1", "phase_2"]
}
EOF

EXIT_CODE=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  validate_iteration_checkpoint '$ARRAY_WR' 2>/dev/null
  echo \$?
" 2>&1 | tail -1)
assert_equals "0" "$EXIT_CODE" "work_remaining array type accepted"

# Null type (valid)
NULL_WR="$TEST_DIR/null_wr.json"
cat > "$NULL_WR" << EOF
{
  "version": "2.1",
  "plan_path": "$TEMP_PLAN",
  "iteration": 1,
  "max_iterations": 5,
  "work_remaining": null
}
EOF

EXIT_CODE=$(bash -c "
  cd '$PROJECT_DIR'
  source lib/workflow/checkpoint-utils.sh 2>/dev/null
  validate_iteration_checkpoint '$NULL_WR' 2>/dev/null
  echo \$?
" 2>&1 | tail -1)
assert_equals "0" "$EXIT_CODE" "work_remaining null type accepted"

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -gt 0 ]; then
  exit 1
else
  echo "All tests passed!"
  exit 0
fi
