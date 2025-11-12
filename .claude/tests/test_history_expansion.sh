#!/usr/bin/env bash
#
# Test: History Expansion Prevention with set +H
# Validates that set +H prevents history expansion from corrupting bash syntax
#
# Related: Spec 641 Phase 5
# Tests fix for: Bad substitution errors from history expansion

set -euo pipefail

# Test configuration
TEST_NAME="History Expansion Prevention"
PASSED=0
FAILED=0

echo "=== $TEST_NAME ==="
echo ""

# Test 1: Indirect variable expansion with set +H
echo "Test 1: Indirect variable expansion with set +H"
(
  set +H  # Disable history expansion

  VAR_NAME="TEST_VALUE"
  TEST_VALUE="success"

  # This syntax would fail with history expansion enabled
  RESULT="${!VAR_NAME}"

  if [ "$RESULT" = "success" ]; then
    echo "  ✓ Indirect expansion works with set +H"
    exit 0
  else
    echo "  ❌ Indirect expansion failed"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 2: Array variable expansion with set +H
echo "Test 2: Array index variable expansion with set +H"
(
  set +H

  ARRAY_0="value0"
  ARRAY_1="value1"
  ARRAY_2="value2"

  # Loop with indirect expansion
  SUCCESS=0
  for i in 0 1 2; do
    var_name="ARRAY_$i"
    value="${!var_name}"
    if [ "$value" = "value$i" ]; then
      SUCCESS=$((SUCCESS + 1))
    fi
  done

  if [ $SUCCESS -eq 3 ]; then
    echo "  ✓ All array expansions successful"
    exit 0
  else
    echo "  ❌ Some array expansions failed ($SUCCESS/3)"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 3: Verify set +H is effective across function calls
echo "Test 3: set +H effectiveness across function calls"
(
  set +H

  test_function() {
    local var_name="FUNC_VAR"
    local FUNC_VAR="from_function"
    # Indirect expansion should work in function
    echo "${!var_name}"
  }

  RESULT=$(test_function)

  if [ "$RESULT" = "from_function" ]; then
    echo "  ✓ set +H works in function scope"
    exit 0
  else
    echo "  ❌ set +H ineffective in function scope"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Test 4: Multiple subprocess test (bash blocks simulation)
echo "Test 4: set +H persistence in subprocess chain"
(
  # Block 1
  set +H
  VAR_1="block1"
  echo "VAR_1=$VAR_1" > /tmp/test_hist_$$.txt

  # Block 2 (separate subprocess)
  (
    set +H  # Must repeat in each subprocess
    source /tmp/test_hist_$$.txt

    var_name="VAR_1"
    value="${!var_name}"

    if [ "$value" = "block1" ]; then
      echo "subprocess_success" > /tmp/test_hist_result_$$.txt
    else
      echo "subprocess_fail" > /tmp/test_hist_result_$$.txt
    fi
  )

  # Check result
  RESULT=$(cat /tmp/test_hist_result_$$.txt)
  rm -f /tmp/test_hist_$$.txt /tmp/test_hist_result_$$.txt

  if [ "$RESULT" = "subprocess_success" ]; then
    echo "  ✓ set +H effective across subprocesses"
    exit 0
  else
    echo "  ❌ set +H failed in subprocess chain"
    exit 1
  fi
) && PASSED=$((PASSED + 1)) || FAILED=$((FAILED + 1))

# Results
echo ""
echo "Results: $PASSED passed, $FAILED failed"

if [ $FAILED -eq 0 ]; then
  echo "✓ All history expansion tests passed"
  exit 0
else
  echo "❌ Some history expansion tests failed"
  exit 1
fi
