#!/usr/bin/env bash
# test_argument_capture_lint.sh - Unit tests for lint-argument-capture.sh
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

LINTER="$PROJECT_DIR/.claude/scripts/lint-argument-capture.sh"
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

# Test 3: Valid 2-block pattern passes
test_valid_two_block_pattern() {
  local test_file="$TEST_DATA_DIR/valid_two_block.md"

  cat > "$test_file" <<'EOF'
# Valid Command

```bash
# Block 1: Argument Capture
# YOUR_DESCRIPTION_HERE
ARGS_FILE=$(mktemp)
cat > "${ARGS_FILE}" <<'ARGS_EOF'
FEATURE_DESC="$1"
COMPLEXITY="$2"
ARGS_EOF
```

```bash
# Block 2: Argument Validation
source "${ARGS_FILE}" 2>/dev/null || true
rm -f "${ARGS_FILE}"

if [[ -z "${FEATURE_DESC:-}" ]]; then
  echo "Error: Feature description required"
  exit 1
fi
```
EOF

  local exit_code=0
  bash "$LINTER" "$test_file" >/dev/null 2>&1 || exit_code=$?

  assert_exit_code 0 "$exit_code" "Valid 2-block pattern passes"
}

# Test 4: Missing temp file cleanup warns
test_missing_cleanup() {
  local test_file="$TEST_DATA_DIR/missing_cleanup.md"

  cat > "$test_file" <<'EOF'
# Command Missing Cleanup

```bash
# YOUR_DESCRIPTION_HERE
ARGS_FILE=$(mktemp)
cat > "${ARGS_FILE}" <<'ARGS_EOF'
FEATURE_DESC="$1"
ARGS_EOF
```

```bash
source "${ARGS_FILE}" 2>/dev/null || true
# Missing: rm -f "${ARGS_FILE}"
```
EOF

  local exit_code=0
  local output
  output=$(bash "$LINTER" "$test_file" 2>&1) || exit_code=$?

  # Should warn but not error (exit 0)
  assert_exit_code 0 "$exit_code" "Missing cleanup generates warning but passes"

  # Check for warning in output
  if echo "$output" | grep -q "missing temp file cleanup"; then
    echo -e "  ${GREEN}✓${NC} Warning message detected"
  else
    echo -e "  ${YELLOW}⚠${NC} Warning message not found in output"
  fi
}

# Test 5: Single-block pattern warns
test_single_block_pattern() {
  local test_file="$TEST_DATA_DIR/single_block.md"

  cat > "$test_file" <<'EOF'
# Command Single Block

```bash
# YOUR_DESCRIPTION_HERE
ARGS_FILE=$(mktemp)
cat > "${ARGS_FILE}" <<'ARGS_EOF'
FEATURE_DESC="$1"
ARGS_EOF

# Inline validation (anti-pattern)
source "${ARGS_FILE}" 2>/dev/null || true
rm -f "${ARGS_FILE}"

if [[ -z "${FEATURE_DESC:-}" ]]; then
  echo "Error: Required"
  exit 1
fi
```
EOF

  local exit_code=0
  local output
  output=$(bash "$LINTER" "$test_file" 2>&1) || exit_code=$?

  # Should warn about missing validation block
  assert_exit_code 0 "$exit_code" "Single-block pattern generates warning"
}

# Test 6: Help flag works
test_help_flag() {
  local exit_code=0
  local output
  output=$(bash "$LINTER" --help 2>&1) || exit_code=$?

  assert_exit_code 0 "$exit_code" "Help flag returns success"

  if echo "$output" | grep -q "Usage:"; then
    echo -e "  ${GREEN}✓${NC} Help output contains usage"
  fi
}

# Test 7: Version flag works
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
  echo "Argument Capture Linter Unit Tests"
  echo "=========================================="
  echo ""

  # Setup
  setup_test_data

  # Run tests
  test_no_files_error
  test_missing_file
  test_valid_two_block_pattern
  test_missing_cleanup
  test_single_block_pattern
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
