#!/usr/bin/env bash
#
# Test: Function Availability Across Bash Blocks
# Validates that functions are available via library re-sourcing
#
# Related: Spec 641 Phase 5
# Tests fix for: emit_progress and display_brief_summary missing errors

set -euo pipefail

# Test configuration
TEST_NAME="Cross-Block Function Availability"
PASSED=0
FAILED=0

# Setup
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

echo "=== $TEST_NAME ==="
echo ""

# Test 1: emit_progress available via unified-logger.sh
echo "Test 1: emit_progress function availability"
(
  set +H

  # Source unified-logger.sh
  if [ -f "${LIB_DIR}/unified-logger.sh" ]; then
    source "${LIB_DIR}/unified-logger.sh"
  else
    echo "  ❌ unified-logger.sh not found"
    exit 1
  fi

  # Test emit_progress function
  if command -v emit_progress &>/dev/null; then
    # Function exists, test it
    OUTPUT=$(emit_progress "1" "Test message" 2>&1)
    if echo "$OUTPUT" | grep -q "Test message"; then
      echo "  ✓ emit_progress function works"
      exit 0
    else
      echo "  ❌ emit_progress didn't produce expected output"
      exit 1
    fi
  else
    echo "  ❌ emit_progress function not found"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 2: display_brief_summary available via unified-logger.sh
echo "Test 2: display_brief_summary function availability"
(
  set +H

  # Source unified-logger.sh
  source "${LIB_DIR}/unified-logger.sh"

  # Test display_brief_summary function
  if command -v display_brief_summary &>/dev/null; then
    # Function exists - set required variables
    WORKFLOW_SCOPE="research-only"
    TOPIC_PATH="/tmp/test_topic"
    REPORT_PATHS=("/tmp/report1.md" "/tmp/report2.md")

    # Run function and capture output
    OUTPUT=$(display_brief_summary 2>&1)

    if echo "$OUTPUT" | grep -q "research-only"; then
      echo "  ✓ display_brief_summary function works"
      exit 0
    else
      echo "  ❌ display_brief_summary didn't produce expected output"
      exit 1
    fi
  else
    echo "  ❌ display_brief_summary function not found"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 3: Functions available in subprocess (simulating bash blocks)
echo "Test 3: Functions available across subprocess boundaries"
(
  # Block 1: Source libraries
  set +H
  source "${LIB_DIR}/unified-logger.sh"

  echo "block1_sourced" > /tmp/test_func_$$.txt

  # Block 2: Separate subprocess, re-source libraries
  (
    set +H
    source "${LIB_DIR}/unified-logger.sh"

    # Verify functions still available
    if command -v emit_progress &>/dev/null && command -v display_brief_summary &>/dev/null; then
      echo "subprocess_success" >> /tmp/test_func_$$.txt
    else
      echo "subprocess_fail" >> /tmp/test_func_$$.txt
    fi
  )

  # Check result
  if grep -q "subprocess_success" /tmp/test_func_$$.txt; then
    rm -f /tmp/test_func_$$.txt
    echo "  ✓ Functions available in subprocess after re-sourcing"
    exit 0
  else
    rm -f /tmp/test_func_$$.txt
    echo "  ❌ Functions missing in subprocess"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 4: Source guards prevent duplicate execution
echo "Test 4: Source guards allow safe multiple sourcing"
(
  set +H

  # Source same library multiple times
  source "${LIB_DIR}/unified-logger.sh"
  source "${LIB_DIR}/unified-logger.sh"
  source "${LIB_DIR}/unified-logger.sh"

  # Functions should still work
  if command -v emit_progress &>/dev/null; then
    echo "  ✓ Multiple sourcing handled safely by source guards"
    exit 0
  else
    echo "  ❌ Multiple sourcing broke function availability"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Results
echo ""
echo "Results: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  echo "✓ All function availability tests passed"
  exit 0
else
  echo "❌ Some function availability tests failed"
  exit 1
fi
