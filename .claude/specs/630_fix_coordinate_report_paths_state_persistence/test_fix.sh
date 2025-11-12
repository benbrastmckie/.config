#!/usr/bin/env bash
# Test script for REPORT_PATHS state persistence fix
# Tests that REPORT_PATHS_COUNT and REPORT_PATH_N are saved to state

set -euo pipefail

echo "=== Testing REPORT_PATHS State Persistence Fix ==="
echo ""

# Setup
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

# Source required libraries
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/state-persistence.sh"

# Test 1: Verify initialize_workflow_paths exports variables
echo "Test 1: Verify initialize_workflow_paths exports REPORT_PATHS_COUNT"
echo "-------------------------------------------------------------------"

# Create temporary state file
WORKFLOW_ID="test_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
echo "State file: $STATE_FILE"

# Initialize workflow paths
TEST_DESCRIPTION="Research bash execution patterns and state management"
TEST_SCOPE="research-only"

if initialize_workflow_paths "$TEST_DESCRIPTION" "$TEST_SCOPE"; then
  echo "✓ initialize_workflow_paths succeeded"

  if [ -n "${REPORT_PATHS_COUNT:-}" ]; then
    echo "✓ REPORT_PATHS_COUNT is set: $REPORT_PATHS_COUNT"
  else
    echo "✗ REPORT_PATHS_COUNT is NOT set"
    exit 1
  fi

  # Check individual report paths
  for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
    var_name="REPORT_PATH_$i"
    if [ -n "${!var_name:-}" ]; then
      echo "✓ $var_name is set: ${!var_name}"
    else
      echo "✗ $var_name is NOT set"
      exit 1
    fi
  done
else
  echo "✗ initialize_workflow_paths failed"
  exit 1
fi

echo ""
echo "Test 2: Verify state persistence (simulating coordinate.md logic)"
echo "-------------------------------------------------------------------"

# Simulate the fix in coordinate.md
append_workflow_state "TOPIC_PATH" "$TOPIC_PATH"
append_workflow_state "REPORT_PATHS_COUNT" "$REPORT_PATHS_COUNT"

for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  append_workflow_state "$var_name" "${!var_name}"
done

echo "✓ Saved REPORT_PATHS_COUNT and REPORT_PATH_N to state"

# Verify state file contents
echo ""
echo "State file contents:"
echo "-------------------------------------------------------------------"
grep "REPORT_PATH" "$STATE_FILE" || echo "No REPORT_PATH variables found"

echo ""
echo "Test 3: Verify state restoration (simulating research handler)"
echo "-------------------------------------------------------------------"

# Clear variables to simulate new bash block
unset REPORT_PATHS_COUNT
unset REPORT_PATH_0
unset REPORT_PATH_1
unset REPORT_PATH_2

# Load state (simulates what happens in research handler)
load_workflow_state "$WORKFLOW_ID"

if [ -n "${REPORT_PATHS_COUNT:-}" ]; then
  echo "✓ REPORT_PATHS_COUNT restored: $REPORT_PATHS_COUNT"
else
  echo "✗ REPORT_PATHS_COUNT NOT restored"
  exit 1
fi

for ((i=0; i<REPORT_PATHS_COUNT; i++)); do
  var_name="REPORT_PATH_$i"
  if [ -n "${!var_name:-}" ]; then
    echo "✓ $var_name restored: ${!var_name}"
  else
    echo "✗ $var_name NOT restored"
    exit 1
  fi
done

echo ""
echo "Test 4: Verify reconstruct_report_paths_array works"
echo "-------------------------------------------------------------------"

# Call the function that was failing before
unset REPORT_PATHS
declare -a REPORT_PATHS

reconstruct_report_paths_array

if [ ${#REPORT_PATHS[@]} -eq "$REPORT_PATHS_COUNT" ]; then
  echo "✓ REPORT_PATHS array reconstructed with ${#REPORT_PATHS[@]} elements"
  for i in "${!REPORT_PATHS[@]}"; do
    echo "  [$i]: ${REPORT_PATHS[$i]}"
  done
else
  echo "✗ REPORT_PATHS array reconstruction failed"
  echo "  Expected: $REPORT_PATHS_COUNT elements"
  echo "  Got: ${#REPORT_PATHS[@]} elements"
  exit 1
fi

echo ""
echo "==================================================================="
echo "✓ All tests passed!"
echo "==================================================================="
echo ""
echo "Fix verified:"
echo "  - REPORT_PATHS_COUNT is saved to state"
echo "  - REPORT_PATH_N variables are saved to state"
echo "  - State is restored correctly in subsequent blocks"
echo "  - reconstruct_report_paths_array() works without errors"
echo ""

# Cleanup
rm -f "$STATE_FILE"
echo "Cleaned up test state file: $STATE_FILE"
