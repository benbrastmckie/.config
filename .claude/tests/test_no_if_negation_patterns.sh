#!/usr/bin/env bash
# Test suite for prohibited negation patterns
# Detects if ! and elif ! patterns that cause bash history expansion errors

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Enable test mode for error log isolation
export CLAUDE_TEST_MODE=1

# Setup test isolation directories
TEST_ROOT="/tmp/test_no_if_negation_$$"
mkdir -p "$TEST_ROOT/.claude/specs"
export CLAUDE_SPECS_ROOT="$TEST_ROOT/.claude/specs"
export CLAUDE_PROJECT_DIR="$TEST_ROOT"

# Cleanup trap (removes test directories on all exit paths)
cleanup() {
  local exit_code=$?
  [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
  unset CLAUDE_SPECS_ROOT
  unset CLAUDE_PROJECT_DIR
  unset CLAUDE_TEST_MODE
  exit $exit_code
}
trap cleanup EXIT

# Source error handling library (test mode routes to test log)
CLAUDE_LIB="${HOME}/.config/.claude/lib"
source "${CLAUDE_LIB}/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Initialize error log (creates .claude/tests/logs/test-errors.jsonl)
ensure_error_log_exists

# Set metadata for error logging
COMMAND_NAME="test_no_if_negation_patterns"
WORKFLOW_ID="test_$(date +%s)"
USER_ARGS="detect if ! patterns"
export COMMAND_NAME WORKFLOW_ID USER_ARGS

# Test helper functions
pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo -e "${GREEN}✓${NC} $1"
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo -e "${RED}✗${NC} $1"
  echo -e "  ${YELLOW}Reason:${NC} $2"
}

info() {
  echo -e "${YELLOW}ℹ${NC} $1"
}

# Detection logic searches REAL command files (not test directory)
COMMANDS_DIR="${HOME}/.config/.claude/commands"

# Test 1: Detect if ! patterns
test_if_negation_detection() {
  info "Testing 'if !' pattern detection"

  violations_found=0

  while IFS=: read -r file line content; do
    violations_found=$((violations_found + 1))

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Prohibited 'if !' pattern found" \
      "pattern_detection" \
      "$(jq -n --arg file "$file" --argjson line "$line" --arg pattern "$content" \
        '{file: $file, line: $line, pattern: $pattern}')"

    echo "  ❌ $file:$line"
  done < <(grep -rn "if !" "${COMMANDS_DIR}/"*.md 2>/dev/null || true)

  if [ $violations_found -eq 0 ]; then
    pass "No 'if !' patterns found in command files"
  else
    fail "Found $violations_found 'if !' patterns" "All if ! patterns should be eliminated"
  fi
}

# Test 2: Detect elif ! patterns
test_elif_negation_detection() {
  info "Testing 'elif !' pattern detection"

  violations_found=0

  while IFS=: read -r file line content; do
    violations_found=$((violations_found + 1))

    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "validation_error" \
      "Prohibited 'elif !' pattern found" \
      "pattern_detection" \
      "$(jq -n --arg file "$file" --argjson line "$line" --arg pattern "$content" \
        '{file: $file, line: $line, pattern: $pattern}')"

    echo "  ❌ $file:$line"
  done < <(grep -rn "elif !" "${COMMANDS_DIR}/"*.md 2>/dev/null || true)

  if [ $violations_found -eq 0 ]; then
    pass "No 'elif !' patterns found in command files"
  else
    fail "Found $violations_found 'elif !' patterns" "All elif ! patterns should be eliminated"
  fi
}

# Test 3: Verify command files exist
test_command_files_exist() {
  info "Testing command files accessibility"

  local files_found=0

  for file in "${COMMANDS_DIR}/"*.md; do
    if [ -f "$file" ]; then
      files_found=$((files_found + 1))
    fi
  done

  if [ $files_found -gt 0 ]; then
    pass "Found $files_found command files to validate"
  else
    fail "No command files found" "Commands directory should contain .md files"
  fi
}

# Run all tests
run_all_tests() {
  echo "==============================="
  echo "Prohibited Negation Patterns Test Suite"
  echo "==============================="
  echo ""

  test_command_files_exist
  test_if_negation_detection
  test_elif_negation_detection

  echo ""
  echo "==============================="
  echo "Test Results"
  echo "==============================="
  echo "Tests Run:    $TESTS_RUN"
  echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "${RED}FAILURE${NC}: Some tests failed"
    echo ""
    echo "Review test errors: /errors --log-file .claude/tests/logs/test-errors.jsonl"
    echo "Or: /errors --command test_no_if_negation_patterns"
    exit 1
  else
    echo -e "${GREEN}SUCCESS${NC}: All tests passed - No prohibited negation patterns found"
    exit 0
  fi
}

# Run tests
run_all_tests
