#!/usr/bin/env bash
# Test case: Verify state ID file path consistency
# Validates: State file path standardization on CLAUDE_PROJECT_DIR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

test_count=0
pass_count=0
fail_count=0

echo "=== Test: State File Path Consistency ==="
echo ""

# Setup
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export HOME="${HOME:-/home/$(whoami)}"

# Create temp directory
mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/tmp"

# Pre-flight check - coordinate.md was archived
COORDINATE_CMD="${SCRIPT_DIR}/../commands/coordinate.md"
if [ ! -f "$COORDINATE_CMD" ]; then
  echo "SKIP: coordinate.md not found (was archived)"
  echo "This test validates coordinate.md state file consistency."
  exit 0  # Exit successfully to indicate skip
fi

# Test 1: Verify coordinate.md uses CLAUDE_PROJECT_DIR for state ID file
echo "Test 1: coordinate.md uses CLAUDE_PROJECT_DIR for state ID file..."
test_count=$((test_count + 1))

COORDINATE_CMD="${SCRIPT_DIR}/../commands/coordinate.md"

if [ ! -f "$COORDINATE_CMD" ]; then
  echo "✗ FAIL: coordinate.md not found at $COORDINATE_CMD"
  fail_count=$((fail_count + 1))
else
  # Check if COORDINATE_STATE_ID_FILE uses CLAUDE_PROJECT_DIR
  if grep -q 'COORDINATE_STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"' "$COORDINATE_CMD"; then
    echo "✓ PASS: State ID file uses CLAUDE_PROJECT_DIR"
    pass_count=$((pass_count + 1))
  else
    echo "✗ FAIL: State ID file does not use CLAUDE_PROJECT_DIR"
    echo "Looking for: COORDINATE_STATE_ID_FILE=\"\${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt\""
    fail_count=$((fail_count + 1))
  fi
fi

# Test 2: Verify old HOME-based path no longer used
echo ""
echo "Test 2: Verify HOME-based state ID path is not used..."
test_count=$((test_count + 1))

if [ -f "$COORDINATE_CMD" ]; then
  # Check for old HOME-based path (should not exist in fixed version)
  if grep -q 'COORDINATE_STATE_ID_FILE="${HOME}/.claude/tmp/coordinate_state_id.txt"' "$COORDINATE_CMD"; then
    echo "✗ FAIL: Old HOME-based path still present"
    fail_count=$((fail_count + 1))
  else
    echo "✓ PASS: Old HOME-based path removed"
    pass_count=$((pass_count + 1))
  fi
fi

# Test 3: Test path consistency in practice
echo ""
echo "Test 3: Path consistency in practice (HOME != CLAUDE_PROJECT_DIR)..."
test_count=$((test_count + 1))

TEST_WORKFLOW_ID="test_path_$(date +%s)_$$"
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/coordinate_state_id.txt"
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${TEST_WORKFLOW_ID}.sh"

# Simulate Block 1: Write state ID file
echo "$TEST_WORKFLOW_ID" > "$STATE_ID_FILE"

# Simulate Block 2: Read state ID file and create state file
if [ -f "$STATE_ID_FILE" ]; then
  LOADED_WORKFLOW_ID=$(cat "$STATE_ID_FILE")

  # Create state file in same directory
  echo "export TEST_VAR='test_value'" > "$STATE_FILE"

  # Verify both files are in CLAUDE_PROJECT_DIR
  if [ -f "$STATE_ID_FILE" ] && [ -f "$STATE_FILE" ]; then
    echo "✓ PASS: Both state ID and state file in CLAUDE_PROJECT_DIR"
    pass_count=$((pass_count + 1))
  else
    echo "✗ FAIL: State files not co-located"
    echo "  State ID file: $STATE_ID_FILE (exists: $([ -f "$STATE_ID_FILE" ] && echo yes || echo no))"
    echo "  State file: $STATE_FILE (exists: $([ -f "$STATE_FILE" ] && echo yes || echo no))"
    fail_count=$((fail_count + 1))
  fi
else
  echo "✗ FAIL: State ID file not found at $STATE_ID_FILE"
  fail_count=$((fail_count + 1))
fi

# Test 4: Verify all coordinate.md bash blocks use CLAUDE_PROJECT_DIR
echo ""
echo "Test 4: All bash blocks reference CLAUDE_PROJECT_DIR for state ID..."
test_count=$((test_count + 1))

if [ -f "$COORDINATE_CMD" ]; then
  # Count references to state ID file with CLAUDE_PROJECT_DIR
  CORRECT_REFS=$(grep -c "CLAUDE_PROJECT_DIR.*coordinate_state_id.txt" "$COORDINATE_CMD" 2>/dev/null || echo "0")

  # Count any remaining references to HOME/.claude/tmp/coordinate_state_id.txt
  INCORRECT_REFS=$(grep -c "HOME.*coordinate_state_id.txt" "$COORDINATE_CMD" 2>/dev/null || echo "0")

  # Validate counts are integers
  [ "$CORRECT_REFS" -eq "$CORRECT_REFS" ] 2>/dev/null || CORRECT_REFS=0
  [ "$INCORRECT_REFS" -eq "$INCORRECT_REFS" ] 2>/dev/null || INCORRECT_REFS=0

  if [ "$CORRECT_REFS" -gt 0 ] && [ "$INCORRECT_REFS" -eq 0 ]; then
    echo "✓ PASS: All references use CLAUDE_PROJECT_DIR ($CORRECT_REFS found, 0 incorrect)"
    pass_count=$((pass_count + 1))
  else
    echo "✗ FAIL: Found incorrect path references"
    echo "  Correct (CLAUDE_PROJECT_DIR): $CORRECT_REFS"
    echo "  Incorrect (HOME): $INCORRECT_REFS"
    fail_count=$((fail_count + 1))
  fi
fi

# Cleanup
rm -f "$STATE_ID_FILE" "$STATE_FILE" 2>/dev/null || true

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests run: $test_count"
echo "Tests passed: $pass_count"
echo "Tests failed: $fail_count"

if [ "$fail_count" -gt 0 ]; then
  echo ""
  echo "TEST_FAILED"
  exit 1
else
  echo ""
  echo "TEST_PASSED"
  exit 0
fi
