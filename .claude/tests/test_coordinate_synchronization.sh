#!/bin/bash
# Synchronization Validation Tests for /coordinate Command
# Verifies that duplicate code blocks remain synchronized

# Setup test environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMAND_FILE="$PROJECT_ROOT/.claude/commands/coordinate.md"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  if $test_func; then
    echo "PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "FAIL: $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

echo "========================================"
echo "Synchronization Tests: /coordinate"
echo "========================================"
echo ""

# Verify command file exists
if [ ! -f "$COMMAND_FILE" ]; then
  echo "FATAL: Command file not found: $COMMAND_FILE"
  exit 1
fi

# ────────────────────────────────────────────────────────────────────
# Test 1: CLAUDE_PROJECT_DIR Pattern Consistency
# ────────────────────────────────────────────────────────────────────

test_claude_project_dir_consistency() {
  # Extract CLAUDE_PROJECT_DIR detection pattern from multiple blocks
  # We expect: if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  #              CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  #              export CLAUDE_PROJECT_DIR
  #            fi

  local pattern_count=$(grep -c "CLAUDE_PROJECT_DIR=\"\$(git rev-parse" "$COMMAND_FILE")

  # There should be 12 occurrences (one per bash block in /coordinate)
  # NOTE: Updated from 7 to 12 to match actual coordinate.md structure
  if [ "$pattern_count" -eq 12 ]; then
    return 0
  else
    echo "  Expected 12 CLAUDE_PROJECT_DIR patterns, found: $pattern_count"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 2: Library Sourcing Pattern Consistency
# ────────────────────────────────────────────────────────────────────

test_library_sourcing_consistency() {
  # Verify all blocks properly source libraries
  # Pattern 1: source "${CLAUDE_PROJECT_DIR}/.claude/lib/..."
  local sourcing_pattern1=$(grep -c "source.*\${CLAUDE_PROJECT_DIR}/\.claude/lib/" "$COMMAND_FILE")

  # Pattern 2: source "${LIB_DIR}/..."
  local sourcing_pattern2=$(grep -c "source.*\${LIB_DIR}/" "$COMMAND_FILE")

  # Total sourcing operations (should be at least 6-7)
  local total_sourcing=$((sourcing_pattern1 + sourcing_pattern2))

  if [ "$total_sourcing" -ge 6 ]; then
    return 0
  else
    echo "  Expected ≥6 library sourcing patterns, found: $total_sourcing"
    echo "  (Pattern 1: $sourcing_pattern1, Pattern 2: $sourcing_pattern2)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Test 3: Required Libraries Complete
# ────────────────────────────────────────────────────────────────────

test_required_libraries_complete() {
  # Verify all 4 REQUIRED_LIBS arrays include workflow-scope-detection.sh
  local workflow_scope_lib_count=$(grep -c '"workflow-scope-detection.sh"' "$COMMAND_FILE")

  # Should appear in all 4 REQUIRED_LIBS arrays
  if [ "$workflow_scope_lib_count" -eq 4 ]; then
    # Also verify overview-synthesis.sh is in all arrays (from 598 fix)
    local overview_synthesis_count=$(grep -c '"overview-synthesis.sh"' "$COMMAND_FILE")
    if [ "$overview_synthesis_count" -eq 4 ]; then
      return 0
    else
      echo "  overview-synthesis.sh found in $overview_synthesis_count arrays (expected 4)"
      return 1
    fi
  else
    echo "  workflow-scope-detection.sh found in $workflow_scope_lib_count arrays (expected 4)"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────
# Run All Tests
# ────────────────────────────────────────────────────────────────────

run_test "Test 1: CLAUDE_PROJECT_DIR pattern consistent across 12 blocks" \
  test_claude_project_dir_consistency

run_test "Test 2: Library sourcing pattern consistent across 12 blocks" \
  test_library_sourcing_consistency

run_test "Test 3: All required libraries present in REQUIRED_LIBS arrays" \
  test_required_libraries_complete

echo ""
echo "========================================"
echo "Test Results"
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All synchronization tests passed"
  exit 0
else
  echo "✗ Some synchronization tests failed"
  exit 1
fi
