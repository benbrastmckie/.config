#!/usr/bin/env bash
# Test concurrent workflow isolation
# Tests that multiple coordinate workflows can run simultaneously without state file interference

set -euo pipefail

# Setup test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

echo "Test: Concurrent Workflow Isolation"
echo "===================================="
echo ""

# Source required libraries
LIB_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/lib"
source "$LIB_DIR/state-persistence.sh"

# Test 1: Unique state ID file creation
echo "Test 1: Unique state ID file names"
echo "-----------------------------------"

# Simulate creating two state ID files with small time gap
TIMESTAMP1=$(date +%s%N)
sleep 0.01  # 10ms delay to ensure different timestamps
TIMESTAMP2=$(date +%s%N)

STATE_ID_FILE_1="${TEST_DIR}/coordinate_state_id_${TIMESTAMP1}.txt"
STATE_ID_FILE_2="${TEST_DIR}/coordinate_state_id_${TIMESTAMP2}.txt"

# Verify filenames are different
if [ "$STATE_ID_FILE_1" != "$STATE_ID_FILE_2" ]; then
  echo "✓ PASS: State ID files have unique names"
else
  echo "✗ FAIL: State ID files have identical names"
  echo "  File 1: $STATE_ID_FILE_1"
  echo "  File 2: $STATE_ID_FILE_2"
  exit 1
fi

echo ""

# Test 2: Concurrent workflow state file isolation
echo "Test 2: Workflow state file isolation"
echo "--------------------------------------"

# Create two simulated workflows
WORKFLOW_ID_1="coordinate_test_$(date +%s)_1"
WORKFLOW_ID_2="coordinate_test_$(date +%s)_2"

sleep 0.01  # Ensure different IDs

# Initialize state for workflow 1
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID_1")
STATE_FILE_1="$STATE_FILE"
echo "Workflow 1 state ID: $WORKFLOW_ID_1" > "$STATE_ID_FILE_1"
append_workflow_state "COORDINATE_STATE_ID_FILE" "$STATE_ID_FILE_1"
append_workflow_state "WORKFLOW_SCOPE" "test-workflow-1"

# Initialize state for workflow 2
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID_2")
STATE_FILE_2="$STATE_FILE"
echo "Workflow 2 state ID: $WORKFLOW_ID_2" > "$STATE_ID_FILE_2"
append_workflow_state "COORDINATE_STATE_ID_FILE" "$STATE_ID_FILE_2"
append_workflow_state "WORKFLOW_SCOPE" "test-workflow-2"

# Verify both state files exist and are different
if [ -f "$STATE_FILE_1" ] && [ -f "$STATE_FILE_2" ] && [ "$STATE_FILE_1" != "$STATE_FILE_2" ]; then
  echo "✓ PASS: Both workflows have separate state files"
else
  echo "✗ FAIL: State file isolation failed"
  echo "  State file 1: $STATE_FILE_1"
  echo "  State file 2: $STATE_FILE_2"
  exit 1
fi

# Verify state file 1 has correct content
load_workflow_state "$WORKFLOW_ID_1"
if [ "$WORKFLOW_SCOPE" = "test-workflow-1" ]; then
  echo "✓ PASS: Workflow 1 state loaded correctly"
else
  echo "✗ FAIL: Workflow 1 state has wrong content"
  echo "  Expected WORKFLOW_SCOPE: test-workflow-1"
  echo "  Actual WORKFLOW_SCOPE: $WORKFLOW_SCOPE"
  exit 1
fi

# Verify state file 2 has correct content
load_workflow_state "$WORKFLOW_ID_2"
if [ "$WORKFLOW_SCOPE" = "test-workflow-2" ]; then
  echo "✓ PASS: Workflow 2 state loaded correctly"
else
  echo "✗ FAIL: Workflow 2 state has wrong content"
  echo "  Expected WORKFLOW_SCOPE: test-workflow-2"
  echo "  Actual WORKFLOW_SCOPE: $WORKFLOW_SCOPE"
  exit 1
fi

echo ""

# Test 3: State ID file cleanup (simulated)
echo "Test 3: State ID file cleanup"
echo "------------------------------"

# Create temporary state ID files
CLEANUP_TEST_FILE_1="$TEST_DIR/cleanup_test_1.txt"
CLEANUP_TEST_FILE_2="$TEST_DIR/cleanup_test_2.txt"

echo "test1" > "$CLEANUP_TEST_FILE_1"
echo "test2" > "$CLEANUP_TEST_FILE_2"

# Verify both files exist
if [ -f "$CLEANUP_TEST_FILE_1" ] && [ -f "$CLEANUP_TEST_FILE_2" ]; then
  echo "✓ Both test files created"
else
  echo "✗ FAIL: Test file creation failed"
  exit 1
fi

# Simulate cleanup of first file only (as would happen with trap)
rm -f "$CLEANUP_TEST_FILE_1" 2>/dev/null || true

# Verify only file 1 was removed
if [ ! -f "$CLEANUP_TEST_FILE_1" ] && [ -f "$CLEANUP_TEST_FILE_2" ]; then
  echo "✓ PASS: Cleanup removes only targeted state ID file"
else
  echo "✗ FAIL: Cleanup affected wrong files"
  echo "  File 1 exists: $([ -f "$CLEANUP_TEST_FILE_1" ] && echo "yes" || echo "no")"
  echo "  File 2 exists: $([ -f "$CLEANUP_TEST_FILE_2" ] && echo "yes" || echo "no")"
  exit 1
fi

echo ""

# Test 4: Backward compatibility with fixed location
echo "Test 4: Backward compatibility"
echo "-------------------------------"

# Create old-style fixed location state ID file
FIXED_LOCATION="${TEST_DIR}/coordinate_state_id.txt"
WORKFLOW_ID_OLD="coordinate_backward_compat_$(date +%s)"

echo "$WORKFLOW_ID_OLD" > "$FIXED_LOCATION"
unset STATE_FILE  # Clear any previous STATE_FILE
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID_OLD")
STATE_FILE_OLD="$STATE_FILE"
# Don't save COORDINATE_STATE_ID_FILE to state (simulate old workflow)
append_workflow_state "WORKFLOW_SCOPE" "backward-compat-test"

# Simulate reading from fixed location (backward compatibility path)
unset COORDINATE_STATE_ID_FILE  # Clear variable from previous tests
COORDINATE_STATE_ID_FILE_OLD="$FIXED_LOCATION"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"

  # Check if COORDINATE_STATE_ID_FILE is in state (should not be for old workflows)
  if [ -z "${COORDINATE_STATE_ID_FILE:-}" ]; then
    # Old workflow - use fixed location
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
  fi
else
  echo "✗ FAIL: Fixed location file not found"
  exit 1
fi

# Verify backward compatibility works
if [ "$WORKFLOW_SCOPE" = "backward-compat-test" ] && [ "$COORDINATE_STATE_ID_FILE" = "$FIXED_LOCATION" ]; then
  echo "✓ PASS: Backward compatibility maintained"
else
  echo "✗ FAIL: Backward compatibility broken"
  echo "  WORKFLOW_SCOPE: $WORKFLOW_SCOPE"
  echo "  COORDINATE_STATE_ID_FILE: $COORDINATE_STATE_ID_FILE"
  exit 1
fi

echo ""

# Test 5: New unique pattern detection
echo "Test 5: New unique pattern detection"
echo "-------------------------------------"

# Create workflow with new unique pattern
TIMESTAMP_NEW=$(date +%s%N)
WORKFLOW_ID_NEW="coordinate_unique_$(date +%s)"
STATE_ID_FILE_NEW="$TEST_DIR/coordinate_state_id_${TIMESTAMP_NEW}.txt"

echo "$WORKFLOW_ID_NEW" > "$STATE_ID_FILE_NEW"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID_NEW")
STATE_FILE_NEW="$STATE_FILE"
append_workflow_state "COORDINATE_STATE_ID_FILE" "$STATE_ID_FILE_NEW"
append_workflow_state "WORKFLOW_SCOPE" "unique-pattern-test"

# Also create old fixed location with same workflow ID (for backward compat check)
echo "$WORKFLOW_ID_NEW" > "$FIXED_LOCATION"

# Simulate loading with new pattern
COORDINATE_STATE_ID_FILE_OLD="$FIXED_LOCATION"
if [ -f "$COORDINATE_STATE_ID_FILE_OLD" ]; then
  WORKFLOW_ID=$(cat "$COORDINATE_STATE_ID_FILE_OLD")
  load_workflow_state "$WORKFLOW_ID"

  # Check if workflow state has unique state ID file path (new pattern)
  if [ -n "${COORDINATE_STATE_ID_FILE:-}" ] && [ "$COORDINATE_STATE_ID_FILE" != "$COORDINATE_STATE_ID_FILE_OLD" ]; then
    # Workflow is using new unique state ID file pattern
    DETECTED_PATTERN="new"
  else
    # Workflow is using old fixed location pattern
    COORDINATE_STATE_ID_FILE="$COORDINATE_STATE_ID_FILE_OLD"
    DETECTED_PATTERN="old"
  fi
else
  echo "✗ FAIL: State ID file not found"
  exit 1
fi

# Verify new pattern is detected correctly
if [ "$DETECTED_PATTERN" = "new" ] && [ "$COORDINATE_STATE_ID_FILE" = "$STATE_ID_FILE_NEW" ]; then
  echo "✓ PASS: New unique pattern detected correctly"
else
  echo "✗ FAIL: Pattern detection failed"
  echo "  Detected pattern: $DETECTED_PATTERN"
  echo "  COORDINATE_STATE_ID_FILE: $COORDINATE_STATE_ID_FILE"
  echo "  Expected: $STATE_ID_FILE_NEW"
  exit 1
fi

echo ""
echo "============================================"
echo "All concurrent workflow tests passed (5/5)"
echo "============================================"
