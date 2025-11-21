#!/usr/bin/env bash
#
# Test: REPORT_PATHS Array Serialization Across Bash Blocks
# Validates that arrays can be serialized and reconstructed across subprocess boundaries
#
# Related: Spec 641 Phase 5
# Tests fix for: Bad substitution errors in array serialization

set -euo pipefail

# Test configuration
TEST_NAME="REPORT_PATHS Array Serialization"
PASSED=0
FAILED=0

# Setup
TEST_DIR="/tmp/test_array_serialization_$$"
mkdir -p "$TEST_DIR"
STATE_FILE="$TEST_DIR/test_state.txt"

echo "=== $TEST_NAME ==="
echo ""

# Test 1: Serialize array with set +H
echo "Test 1: Array serialization with set +H directive"
(
  set +H  # Critical: Prevent history expansion

  # Create test array
  REPORT_PATHS_COUNT=4
  REPORT_PATH_0="/path/to/report0.md"
  REPORT_PATH_1="/path/to/report1.md"
  REPORT_PATH_2="/path/to/report2.md"
  REPORT_PATH_3="/path/to/report3.md"

  # Serialize to state file (this was failing before fix)
  echo "REPORT_PATHS_COUNT=$REPORT_PATHS_COUNT" > "$STATE_FILE"

  for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
    var_name="REPORT_PATH_$i"
    # Indirect variable expansion - requires set +H to work correctly
    echo "${var_name}=${!var_name}" >> "$STATE_FILE"
  done

  # Verify serialization succeeded
  if [ -f "$STATE_FILE" ] && [ $(wc -l < "$STATE_FILE") -eq 5 ]; then
    echo "  ✓ Array serialized successfully (5 lines written)"
    exit 0
  else
    echo "  ❌ Array serialization failed"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 2: Deserialize array in separate subprocess
echo "Test 2: Array deserialization in separate subprocess"
(
  set +H  # Also needed in deserialization block

  # Load state from file (simulate separate bash block)
  source "$STATE_FILE"

  # Verify all variables loaded
  if [ "$REPORT_PATHS_COUNT" -eq 4 ] && \
     [ "$REPORT_PATH_0" = "/path/to/report0.md" ] && \
     [ "$REPORT_PATH_1" = "/path/to/report1.md" ] && \
     [ "$REPORT_PATH_2" = "/path/to/report2.md" ] && \
     [ "$REPORT_PATH_3" = "/path/to/report3.md" ]; then
    echo "  ✓ All 5 variables deserialized correctly"
    exit 0
  else
    echo "  ❌ Deserialization failed - variables missing or incorrect"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 3: Round-trip with array reconstruction
echo "Test 3: Complete round-trip with array reconstruction"
(
  set +H

  # Load state
  source "$STATE_FILE"

  # Reconstruct array (as done in workflow-initialization.sh)
  REPORT_PATHS=()
  for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
    var_name="REPORT_PATH_$i"
    REPORT_PATHS+=("${!var_name}")
  done

  # Verify reconstructed array
  if [ "${#REPORT_PATHS[@]}" -eq 4 ] && \
     [ "${REPORT_PATHS[0]}" = "/path/to/report0.md" ] && \
     [ "${REPORT_PATHS[3]}" = "/path/to/report3.md" ]; then
    echo "  ✓ Array reconstructed successfully (4 elements)"
    exit 0
  else
    echo "  ❌ Array reconstruction failed"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 4: Verify bad substitution prevented
echo "Test 4: Confirm no bad substitution errors in output"
(
  set +H

  # This would fail with "bad substitution" error without set +H
  REPORT_PATHS_COUNT=2
  REPORT_PATH_0="/test/path0.md"
  REPORT_PATH_1="/test/path1.md"

  # Capture stderr to detect bad substitution
  ERROR_OUTPUT=$(
    for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
      var_name="REPORT_PATH_$i"
      echo "${var_name}=${!var_name}"
    done 2>&1 >/dev/null
  )

  # Check for bad substitution error
  if echo "$ERROR_OUTPUT" | grep -q "bad substitution"; then
    echo "  ❌ Bad substitution error detected"
    exit 1
  else
    echo "  ✓ No bad substitution errors"
    exit 0
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Cleanup
rm -rf "$TEST_DIR"

# Results
echo ""
echo "Results: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  echo "✓ All array serialization tests passed"
  exit 0
else
  echo "❌ Some array serialization tests failed"
  exit 1
fi
