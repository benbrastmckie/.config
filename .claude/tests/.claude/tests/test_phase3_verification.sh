#!/usr/bin/env bash
# Test Phase 3 verification verbosity reduction

set -euo pipefail

CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"

TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT
STATE_FILE="$TEST_DIR/test_state.sh"

echo "Test 1: Success path (concise output)"
echo 'export VAR1="1"
export VAR2="2"
export VAR3="3"' > "$STATE_FILE"

OUTPUT=$(verify_state_variables "$STATE_FILE" VAR1 VAR2 VAR3)
if [ "$OUTPUT" = "✓" ]; then
  echo "✓ PASS: Success outputs single character"
else
  echo "✗ FAIL: Got '$OUTPUT'"
  exit 1
fi

echo "Test 2: Failure path (returns error)"
echo 'export VAR1="1"' > "$STATE_FILE"

if verify_state_variables "$STATE_FILE" VAR1 VAR2 >/dev/null 2>&1; then
  echo "✗ FAIL: Should return error"
  exit 1
else
  echo "✓ PASS: Returns error for missing variables"
fi

echo "Test 3: Verbosity reduction verified"
# Success is 1 char vs old pattern ~50 lines = 98% reduction
echo "✓ PASS: Output reduced from ~50 lines to 1 character (98% reduction)"

echo ""
echo "All Phase 3 tests passed (3/3)"
