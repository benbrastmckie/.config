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
  if [ -f "${LIB_DIR}/core/unified-logger.sh" ]; then
    source "${LIB_DIR}/core/unified-logger.sh"
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
  source "${LIB_DIR}/core/unified-logger.sh"

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
  source "${LIB_DIR}/core/unified-logger.sh"

  echo "block1_sourced" > /tmp/test_func_$$.txt

  # Block 2: Separate subprocess, re-source libraries
  (
    set +H
    source "${LIB_DIR}/core/unified-logger.sh"

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
  source "${LIB_DIR}/core/unified-logger.sh"
  source "${LIB_DIR}/core/unified-logger.sh"
  source "${LIB_DIR}/core/unified-logger.sh"

  # Functions should still work
  if command -v emit_progress &>/dev/null; then
    echo "  ✓ Multiple sourcing handled safely by source guards"
    exit 0
  else
    echo "  ❌ Multiple sourcing broke function availability"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 5: Multi-block coordinate workflow simulation (Spec 661 Phase 4)
echo "Test 5: Functions available across 3-block coordinate workflow"
(
  set +H
  TEST_STATE_FILE="/tmp/test_multiblock_$$.state"

  # Check if verification-helpers.sh exists (was archived with coordinate command)
  if [ ! -f "${LIB_DIR}/util/verification-helpers.sh" ]; then
    echo "  - verification-helpers.sh archived with coordinate (skipped)"
    exit 0
  fi

  # Block 1: Initialize workflow and source libraries
  bash -c "
    set +H
    LIB_DIR='${LIB_DIR}'

    # Source libraries in Standard 15 order
    source \"\${LIB_DIR}/workflow/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/core/state-persistence.sh\"
    source \"\${LIB_DIR}/core/error-handling.sh\"
    source \"\${LIB_DIR}/util/verification-helpers.sh\"

    # Verify critical functions available
    if command -v handle_state_error &>/dev/null && \
       command -v verify_file_created &>/dev/null; then
      echo 'BLOCK1_SUCCESS' > '${TEST_STATE_FILE}'
    else
      echo 'BLOCK1_FAIL' > '${TEST_STATE_FILE}'
      exit 1
    fi
  " || exit 1

  # Verify Block 1 success
  if ! grep -q "BLOCK1_SUCCESS" "$TEST_STATE_FILE"; then
    rm -f "$TEST_STATE_FILE"
    echo "  ❌ Block 1 library sourcing failed"
    exit 1
  fi

  # Block 2: Re-source libraries (simulating subsequent bash block)
  bash -c "
    set +H
    LIB_DIR='${LIB_DIR}'

    # Re-source libraries in same order
    source \"\${LIB_DIR}/workflow/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/core/state-persistence.sh\"
    source \"\${LIB_DIR}/core/error-handling.sh\"
    source \"\${LIB_DIR}/util/verification-helpers.sh\"

    # Verify functions still available
    if command -v handle_state_error &>/dev/null && \
       command -v verify_file_created &>/dev/null; then
      echo 'BLOCK2_SUCCESS' >> '${TEST_STATE_FILE}'
    else
      echo 'BLOCK2_FAIL' >> '${TEST_STATE_FILE}'
      exit 1
    fi
  " || exit 1

  # Verify Block 2 success
  if ! grep -q "BLOCK2_SUCCESS" "$TEST_STATE_FILE"; then
    rm -f "$TEST_STATE_FILE"
    echo "  ❌ Block 2 library re-sourcing failed"
    exit 1
  fi

  # Block 3: Final block with all functions
  bash -c "
    set +H
    LIB_DIR='${LIB_DIR}'

    # Re-source libraries again
    source \"\${LIB_DIR}/workflow/workflow-state-machine.sh\"
    source \"\${LIB_DIR}/core/state-persistence.sh\"
    source \"\${LIB_DIR}/core/error-handling.sh\"
    source \"\${LIB_DIR}/util/verification-helpers.sh\"
    source \"\${LIB_DIR}/core/unified-logger.sh\"

    # Verify all critical functions available
    if command -v handle_state_error &>/dev/null && \
       command -v verify_file_created &>/dev/null && \
       command -v emit_progress &>/dev/null; then
      echo 'BLOCK3_SUCCESS' >> '${TEST_STATE_FILE}'
    else
      echo 'BLOCK3_FAIL' >> '${TEST_STATE_FILE}'
      exit 1
    fi
  " || exit 1

  # Verify Block 3 success
  if grep -q "BLOCK3_SUCCESS" "$TEST_STATE_FILE"; then
    rm -f "$TEST_STATE_FILE"
    echo "  ✓ Functions available across all 3 blocks (coordinate workflow simulation)"
    exit 0
  else
    rm -f "$TEST_STATE_FILE"
    echo "  ❌ Block 3 library sourcing failed"
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
