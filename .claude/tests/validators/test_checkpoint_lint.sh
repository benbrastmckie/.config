#!/usr/bin/env bash
# test_checkpoint_lint.sh - Unit tests for lint-checkpoint-format.sh
# Version: 1.0.0

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_RUN=0

# Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: search upward
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "${PROJECT_DIR:-}" ]; then
  echo "ERROR: Cannot find project directory" >&2
  exit 1
fi

LINTER="$PROJECT_DIR/.claude/scripts/lint-checkpoint-format.sh"
TEST_DATA_DIR="$PROJECT_DIR/.claude/tests/validators/test_data"

# Setup test data directory
setup_test_data() {
  mkdir -p "$TEST_DATA_DIR"
}

# Cleanup test data directory
cleanup_test_data() {
  rm -rf "$TEST_DATA_DIR"
}

# Assert test result
assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [ "$expected" -eq "$actual" ]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name (expected exit $expected, got $actual)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 1: Validator requires file arguments
test_no_files_error() {
  local exit_code=0
  bash "$LINTER" >/dev/null 2>&1 || exit_code=$?

  assert_exit_code 1 "$exit_code" "No files provided returns error"
}

# Test 2: Validator handles missing file
test_missing_file() {
  local exit_code=0
  bash "$LINTER" "$TEST_DATA_DIR/nonexistent.md" >/dev/null 2>&1 || exit_code=$?

  assert_exit_code 1 "$exit_code" "Missing file returns error"
}

# Test 3: Valid checkpoint format passes
test_valid_checkpoint_format() {
  local test_file="$TEST_DATA_DIR/valid_checkpoint.md"

  cat > "$test_file" <<'EOF'
# Valid Command

```bash
echo "[CHECKPOINT] Phase 1 complete"
echo "Context: TOPIC_PATH=/path/to/topic, PLAN_FILE=/path/to/plan"
echo "Ready for: Phase 2 execution"
```
EOF

  local exit_code=0
  bash "$LINTER" "$test_file" >/dev/null 2>&1 || exit_code=$?

  assert_exit_code 0 "$exit_code" "Valid checkpoint format passes"
}

# Test 4: Missing Context line warns
test_missing_context() {
  local test_file="$TEST_DATA_DIR/missing_context.md"

  cat > "$test_file" <<'EOF'
# Command Missing Context

```bash
echo "[CHECKPOINT] Phase 1 complete"
echo "Ready for: Phase 2 execution"
```
EOF

  local exit_code=0
  local output
  output=$(bash "$LINTER" "$test_file" 2>&1) || exit_code=$?

  # Should warn but not error
  assert_exit_code 0 "$exit_code" "Missing Context generates warning but passes"

  if echo "$output" | grep -q "missing 'Context:' line"; then
    echo -e "  ${GREEN}✓${NC} Warning message detected"
  else
    echo -e "  ${YELLOW}⚠${NC} Warning message not found"
  fi
}

# Test 5: Missing Ready line warns
test_missing_ready() {
  local test_file="$TEST_DATA_DIR/missing_ready.md"

  cat > "$test_file" <<'EOF'
# Command Missing Ready

```bash
echo "[CHECKPOINT] Phase 1 complete"
echo "Context: PHASE=1, STATUS=complete"
```
EOF

  local exit_code=0
  local output
  output=$(bash "$LINTER" "$test_file" 2>&1) || exit_code=$?

  # Should warn but not error
  assert_exit_code 0 "$exit_code" "Missing Ready line generates warning"

  if echo "$output" | grep -q "missing 'Ready for:' line"; then
    echo -e "  ${GREEN}✓${NC} Warning message detected"
  fi
}

# Test 6: Missing status word warns
test_missing_status_word() {
  local test_file="$TEST_DATA_DIR/missing_status.md"

  cat > "$test_file" <<'EOF'
# Command Missing Status

```bash
echo "[CHECKPOINT] Phase 1"
echo "Context: PHASE=1"
echo "Ready for: Phase 2"
```
EOF

  local exit_code=0
  local output
  output=$(bash "$LINTER" "$test_file" 2>&1) || exit_code=$?

  # Should warn about missing status word
  assert_exit_code 0 "$exit_code" "Missing status word generates warning"

  if echo "$output" | grep -q "missing status word"; then
    echo -e "  ${GREEN}✓${NC} Warning message detected"
  fi
}

# Test 7: Invalid Context format warns
test_invalid_context_format() {
  local test_file="$TEST_DATA_DIR/invalid_context.md"

  cat > "$test_file" <<'EOF'
# Command Invalid Context

```bash
echo "[CHECKPOINT] Phase 1 complete"
echo "Context: some text without key=value pairs"
echo "Ready for: Phase 2"
```
EOF

  local exit_code=0
  local output
  output=$(bash "$LINTER" "$test_file" 2>&1) || exit_code=$?

  # Should warn about format
  assert_exit_code 0 "$exit_code" "Invalid Context format generates warning"

  if echo "$output" | grep -q "missing KEY=value format"; then
    echo -e "  ${GREEN}✓${NC} Warning message detected"
  fi
}

# Test 8: Help flag works
test_help_flag() {
  local exit_code=0
  local output
  output=$(bash "$LINTER" --help 2>&1) || exit_code=$?

  assert_exit_code 0 "$exit_code" "Help flag returns success"

  if echo "$output" | grep -q "Usage:"; then
    echo -e "  ${GREEN}✓${NC} Help output contains usage"
  fi
}

# Test 9: Version flag works
test_version_flag() {
  local exit_code=0
  local output
  output=$(bash "$LINTER" --version 2>&1) || exit_code=$?

  assert_exit_code 0 "$exit_code" "Version flag returns success"

  if echo "$output" | grep -q "version"; then
    echo -e "  ${GREEN}✓${NC} Version output contains version info"
  fi
}

# Main test suite
main() {
  echo "=========================================="
  echo "Checkpoint Format Linter Unit Tests"
  echo "=========================================="
  echo ""

  # Setup
  setup_test_data

  # Run tests
  test_no_files_error
  test_missing_file
  test_valid_checkpoint_format
  test_missing_context
  test_missing_ready
  test_missing_status_word
  test_invalid_context_format
  test_help_flag
  test_version_flag

  # Cleanup
  cleanup_test_data

  # Summary
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}FAILED${NC}: Some tests failed"
    exit 1
  else
    echo -e "${GREEN}PASSED${NC}: All tests passed"
    exit 0
  fi
}

main "$@"
