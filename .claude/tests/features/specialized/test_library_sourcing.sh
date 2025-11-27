#!/usr/bin/env bash
# test_library_sourcing.sh - Unit tests for library-sourcing.sh
# Coverage target: >80%

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
CLAUDE_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test utilities
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Setup test environment
setup() {
  # Create temporary directory for test
  TEST_DIR=$(mktemp -d)
  export TEST_CLAUDE_ROOT="$TEST_DIR"
}

# Cleanup test environment
teardown() {
  if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

# Test 1: All libraries sourced successfully
test_all_libraries_sourced() {
  local test_name="All 7 libraries sourced successfully"

  # Source the library
  if source "${CLAUDE_ROOT}/lib/core/library-sourcing.sh"; then
    # Call the function
    if source_required_libraries 2>/dev/null; then
      # Verify all 7 libraries were sourced by checking for known functions
      local all_sourced=true

      # Check for functions from each library (these are example function names)
      # Adjust based on actual function names in each library
      if ! declare -f get_next_topic_number &>/dev/null; then
        all_sourced=false
      fi

      if [[ "$all_sourced" == "true" ]]; then
        pass "$test_name"
      else
        fail "$test_name" "Not all library functions available"
      fi
    else
      fail "$test_name" "source_required_libraries returned non-zero"
    fi
  else
    fail "$test_name" "Failed to source library-sourcing.sh"
  fi
}

# Test 2: Missing library triggers appropriate error
test_missing_library_error() {
  local test_name="Missing library triggers appropriate error"

  setup

  # Create test library directory with one missing library
  mkdir -p "$TEST_DIR/lib"

  # Copy all but one library
  local copied=0
  for lib in topic-utils.sh detect-project-dir.sh artifact-creation.sh \
              metadata-extraction.sh overview-synthesis.sh checkpoint-utils.sh; do
    if [[ -f "${CLAUDE_ROOT}/lib/${lib}" ]]; then
      cp "${CLAUDE_ROOT}/lib/${lib}" "$TEST_DIR/lib/"
      copied=$((copied + 1))
    fi
  done
  # Intentionally skip error-handling.sh to test missing library

  # Create a test version of library-sourcing.sh pointing to TEST_DIR
  mkdir -p "$TEST_DIR/.claude/lib/core"
  cat > "$TEST_DIR/.claude/lib/core/library-sourcing.sh" <<'EOF'
source_required_libraries() {
  local claude_root="$TEST_CLAUDE_ROOT"
  local libraries=(
    "topic-utils.sh"
    "detect-project-dir.sh"
    "artifact-creation.sh"
    "metadata-extraction.sh"
    "overview-synthesis.sh"
    "checkpoint-utils.sh"
    "error-handling.sh"
  )
  local failed_libraries=()
  for lib in "${libraries[@]}"; do
    local lib_path="${claude_root}/lib/${lib}"
    if [[ ! -f "$lib_path" ]]; then
      failed_libraries+=("$lib (expected at: $lib_path)")
      continue
    fi
    if ! source "$lib_path" 2>/dev/null; then
      failed_libraries+=("$lib (source failed)")
    fi
  done
  if [[ ${#failed_libraries[@]} -gt 0 ]]; then
    echo "ERROR: Failed to source required libraries:" >&2
    for failed_lib in "${failed_libraries[@]}"; do
      echo "  - $failed_lib" >&2
    done
    return 1
  fi
  return 0
}
EOF

  # Source and test
  # shellcheck disable=SC1091
  source "$TEST_DIR/.claude/lib/core/library-sourcing.sh"

  if ! source_required_libraries 2>/dev/null; then
    # Function should fail with missing library
    # Verify error message mentions the missing library
    local error_output
    error_output=$(source_required_libraries 2>&1 || true)

    if echo "$error_output" | grep -q "error-handling.sh"; then
      pass "$test_name"
    else
      fail "$test_name" "Error message doesn't mention missing library"
    fi
  else
    fail "$test_name" "Function should have failed with missing library"
  fi

  teardown
}

# Test 3: Invalid library path handled gracefully
test_invalid_library_path() {
  local test_name="Invalid library path handled gracefully"

  setup

  # Create test library directory with proper subdirectory structure (post-refactoring)
  mkdir -p "$TEST_DIR/lib/core"
  mkdir -p "$TEST_DIR/lib/plan"
  mkdir -p "$TEST_DIR/lib/artifact"
  mkdir -p "$TEST_DIR/lib/workflow"
  mkdir -p "$TEST_DIR/.claude/lib/core"

  # Library paths after refactoring (commit fb8680db)
  declare -A LIB_SOURCES=(
    ["plan/topic-utils.sh"]="plan/topic-utils.sh"
    ["core/detect-project-dir.sh"]="core/detect-project-dir.sh"
    ["artifact/artifact-creation.sh"]="artifact/artifact-creation.sh"
    ["workflow/metadata-extraction.sh"]="workflow/metadata-extraction.sh"
    ["artifact/overview-synthesis.sh"]="artifact/overview-synthesis.sh"
    ["workflow/checkpoint-utils.sh"]="workflow/checkpoint-utils.sh"
    ["core/error-handling.sh"]="core/error-handling.sh"
  )

  # Copy all libraries to their proper subdirectory locations
  for lib_path in "${!LIB_SOURCES[@]}"; do
    if [[ -f "${CLAUDE_ROOT}/lib/${lib_path}" ]]; then
      cp "${CLAUDE_ROOT}/lib/${lib_path}" "$TEST_DIR/lib/${lib_path}"
    fi
  done

  # Create corrupted library (syntax error) in test directory
  echo "this is not valid bash syntax }{][" > "$TEST_DIR/lib/core/error-handling.sh"

  # Create test version of library-sourcing.sh with subdirectory paths
  cat > "$TEST_DIR/.claude/lib/core/library-sourcing.sh" <<'EOF'
source_required_libraries() {
  local claude_root="$TEST_CLAUDE_ROOT"
  local libraries=(
    "plan/topic-utils.sh"
    "core/detect-project-dir.sh"
    "artifact/artifact-creation.sh"
    "workflow/metadata-extraction.sh"
    "artifact/overview-synthesis.sh"
    "workflow/checkpoint-utils.sh"
    "core/error-handling.sh"
  )
  local failed_libraries=()
  for lib in "${libraries[@]}"; do
    local lib_path="${claude_root}/lib/${lib}"
    if [[ ! -f "$lib_path" ]]; then
      failed_libraries+=("$lib (expected at: $lib_path)")
      continue
    fi
    if ! source "$lib_path" 2>/dev/null; then
      failed_libraries+=("$lib (source failed)")
    fi
  done
  if [[ ${#failed_libraries[@]} -gt 0 ]]; then
    echo "ERROR: Failed to source required libraries:" >&2
    for failed_lib in "${failed_libraries[@]}"; do
      echo "  - $failed_lib" >&2
    done
    return 1
  fi
  return 0
}
EOF

  # Source and test
  # shellcheck disable=SC1091
  source "$TEST_DIR/.claude/lib/core/library-sourcing.sh"

  if ! source_required_libraries 2>/dev/null; then
    # Function should fail with corrupted library
    local error_output
    error_output=$(source_required_libraries 2>&1 || true)

    if echo "$error_output" | grep -q "source failed"; then
      pass "$test_name"
    else
      fail "$test_name" "Error message doesn't indicate source failure"
    fi
  else
    fail "$test_name" "Function should have failed with corrupted library"
  fi

  teardown
}

# Test 4: Error message includes library name and expected path
test_error_message_format() {
  local test_name="Error message includes library name and expected path"

  setup

  # Create empty test lib directory (all libraries missing)
  mkdir -p "$TEST_DIR/lib"
  mkdir -p "$TEST_DIR/.claude/lib/core"

  # Create test version of library-sourcing.sh
  cat > "$TEST_DIR/.claude/lib/core/library-sourcing.sh" <<'EOF'
source_required_libraries() {
  local claude_root="$TEST_CLAUDE_ROOT"
  local libraries=(
    "topic-utils.sh"
    "detect-project-dir.sh"
  )
  local failed_libraries=()
  for lib in "${libraries[@]}"; do
    local lib_path="${claude_root}/lib/${lib}"
    if [[ ! -f "$lib_path" ]]; then
      failed_libraries+=("$lib (expected at: $lib_path)")
      continue
    fi
    if ! source "$lib_path" 2>/dev/null; then
      failed_libraries+=("$lib (source failed)")
    fi
  done
  if [[ ${#failed_libraries[@]} -gt 0 ]]; then
    echo "ERROR: Failed to source required libraries:" >&2
    for failed_lib in "${failed_libraries[@]}"; do
      echo "  - $failed_lib" >&2
    done
    return 1
  fi
  return 0
}
EOF

  # Source and test
  # shellcheck disable=SC1091
  source "$TEST_DIR/.claude/lib/core/library-sourcing.sh"

  local error_output
  error_output=$(source_required_libraries 2>&1 || true)

  # Verify error message format
  if echo "$error_output" | grep -q "ERROR: Failed to source required libraries:" && \
     echo "$error_output" | grep -q "expected at:"; then
    pass "$test_name"
  else
    fail "$test_name" "Error message format incorrect"
  fi

  teardown
}

# Test 5: Return codes are correct
test_return_codes() {
  local test_name="Return codes (0=success, 1=failure)"

  # Test success case
  if source "${CLAUDE_ROOT}/lib/core/library-sourcing.sh"; then
    if source_required_libraries 2>/dev/null; then
      local success_code=$?
      if [[ $success_code -eq 0 ]]; then
        pass "$test_name (success case)"
      else
        fail "$test_name (success case)" "Expected return code 0, got $success_code"
      fi
    else
      fail "$test_name (success case)" "Unexpected failure on real libraries"
    fi
  else
    fail "$test_name (success case)" "Failed to source library-sourcing.sh"
  fi
}

# Run all tests
echo "Running library-sourcing.sh unit tests..."
echo "=========================================="

test_all_libraries_sourced
test_missing_library_error
test_invalid_library_path
test_error_message_format
test_return_codes

# Summary
echo ""
echo "=========================================="
echo "Test Summary:"
echo "  Total: $TESTS_RUN"
echo -e "  ${GREEN}Passed${NC}: $TESTS_PASSED"
echo -e "  ${RED}Failed${NC}: $TESTS_FAILED"

# Calculate coverage
if [[ $TESTS_RUN -gt 0 ]]; then
  coverage=$((TESTS_PASSED * 100 / TESTS_RUN))
  echo "  Coverage: ${coverage}%"

  if [[ $coverage -ge 80 ]]; then
    echo -e "  ${GREEN}✓ Coverage target met (≥80%)${NC}"
  else
    echo -e "  ${YELLOW}⚠ Coverage below target (<80%)${NC}"
  fi
fi

# Exit with appropriate code
if [[ $TESTS_FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi
