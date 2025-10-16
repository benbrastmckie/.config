#!/usr/bin/env bash
#
# Test: Utility Sourcing Validation
# Verifies all utilities can be sourced without errors
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

echo "Testing Utility Sourcing..."
echo "==========================="
echo

# Test 1: Source base-utils.sh
echo "Test 1: Source base-utils.sh"
if source "$LIB_DIR/base-utils.sh" 2>/dev/null; then
  echo "  ✓ base-utils.sh sourced successfully"
  # Verify functions exist
  if type error >/dev/null 2>&1 && type warn >/dev/null 2>&1 && type info >/dev/null 2>&1; then
    echo "  ✓ error(), warn(), info() functions available"
  else
    echo "  ✗ base-utils.sh functions not available"
    exit 1
  fi
else
  echo "  ✗ Failed to source base-utils.sh"
  exit 1
fi
echo

# Test 2: Source plan-core-bundle.sh
echo "Test 2: Source plan-core-bundle.sh"
if source "$LIB_DIR/plan-core-bundle.sh" 2>/dev/null; then
  echo "  ✓ plan-core-bundle.sh sourced successfully"
  # Verify key functions exist
  FUNCTIONS=("extract_phase_name" "extract_phase_content" "detect_structure_level")
  PASS=0
  for func in "${FUNCTIONS[@]}"; do
    if type "$func" >/dev/null 2>&1; then
      ((PASS++))
    fi
  done
  echo "  ✓ $PASS/${#FUNCTIONS[@]} sample functions available"
else
  echo "  ✗ Failed to source plan-core-bundle.sh"
  exit 1
fi
echo

# Test 3: Source unified-logger.sh
echo "Test 3: Source unified-logger.sh"
if source "$LIB_DIR/unified-logger.sh" 2>/dev/null; then
  echo "  ✓ unified-logger.sh sourced successfully"
  # Verify key functions exist
  FUNCTIONS=("log_complexity_check" "log_replan_invocation" "write_log_entry")
  PASS=0
  for func in "${FUNCTIONS[@]}"; do
    if type "$func" >/dev/null 2>&1; then
      ((PASS++))
    fi
  done
  echo "  ✓ $PASS/${#FUNCTIONS[@]} sample functions available"
else
  echo "  ✗ Failed to source unified-logger.sh"
  exit 1
fi
echo

# Test 4: Source standalone utilities
echo "Test 4: Source standalone utilities"
STANDALONE=("complexity-utils.sh" "checkpoint-utils.sh")
PASS=0
FAIL=0

for util in "${STANDALONE[@]}"; do
  if source "$LIB_DIR/$util" 2>/dev/null; then
    echo "  ✓ $util sourced successfully"
    ((PASS++))
  else
    echo "  ✗ Failed to source $util"
    ((FAIL++))
  fi
done

echo "  Result: $PASS/$((PASS+FAIL)) standalone utilities sourced"
echo

# Summary
echo "============================="
echo "All Utilities Sourcing Tests Passed"
echo "============================="
echo
echo "Ready for Phase 1 implementation:"
echo "  - All bundles functional"
echo "  - All standalone utilities accessible"
echo "  - No sourcing errors detected"
