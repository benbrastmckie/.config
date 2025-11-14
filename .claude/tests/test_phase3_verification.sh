#!/usr/bin/env bash
# Test Phase 3 verification verbosity reduction
# Tests concise verification patterns

set -euo pipefail

CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/verification-helpers.sh"

# Setup test state file
TEST_DIR=$(mktemp -d)
trap "rm -rf '$TEST_DIR'" EXIT

STATE_FILE="$TEST_DIR/test_state.sh"

echo "Test 1: verify_state_variables success path (concise output)"
cat > "$STATE_FILE" <<'INNER_EOF'
export VAR1="value1"
export VAR2="value2"
export VAR3="value3"
INNER_EOF

OUTPUT=$(verify_state_variables "$STATE_FILE" VAR1 VAR2 VAR3)
if [ $? -eq 0 ] && [ "$OUTPUT" = "✓" ]; then
  echo "✓ PASS: Success path outputs single character (✓)"
else
  echo "✗ FAIL: Success path incorrect (got: '$OUTPUT')"
  exit 1
fi

echo "Test 2: verify_state_variables failure path (diagnostic output)"
# Create state file missing VAR3
cat > "$STATE_FILE" <<'INNER_EOF'
export VAR1="value1"
export VAR2="value2"
INNER_EOF

if verify_state_variables "$STATE_FILE" VAR1 VAR2 VAR3 >/dev/null 2>&1; then
  echo "✗ FAIL: Should have failed (missing variable)"
  exit 1
else
  echo "✓ PASS: Failure path returns non-zero exit code"
fi

# Test that diagnostic is produced (capture stderr and stdout)
DIAGNOSTIC=$(verify_state_variables "$STATE_FILE" VAR1 VAR2 VAR3 2>&1)
if echo "$DIAGNOSTIC" | grep -q "VAR3"; then
  echo "✓ PASS: Failure diagnostic lists missing variable"
else
  echo "✗ FAIL: Failure diagnostic doesn't list missing variable"
  exit 1
fi

if echo "$DIAGNOSTIC" | grep -q "TROUBLESHOOTING"; then
  echo "✓ PASS: Failure diagnostic includes troubleshooting"
else
  echo "✗ FAIL: Failure diagnostic missing troubleshooting"
  exit 1
fi

echo ""
echo "Test 3: Output size comparison (verbosity reduction)"
# Create state with 4 variables
cat > "$STATE_FILE" <<'INNER_EOF'
export REPORT_PATHS_COUNT="3"
export REPORT_PATH_0="/path/0.md"
export REPORT_PATH_1="/path/1.md"
export REPORT_PATH_2="/path/2.md"
INNER_EOF

# Count output size (success path)
SUCCESS_OUTPUT=$(verify_state_variables "$STATE_FILE" REPORT_PATHS_COUNT REPORT_PATH_0 REPORT_PATH_1 REPORT_PATH_2)
SUCCESS_CHARS=$(echo -n "$SUCCESS_OUTPUT" | wc -c)

if [ "$SUCCESS_CHARS" -eq 3 ]; then
  echo "✓ PASS: Success output is 3 bytes (✓ character, 90%+ reduction from verbose output)"
else
  echo "✗ FAIL: Success output should be 3 bytes (got $SUCCESS_CHARS)"
  exit 1
fi

echo ""
echo "All Phase 3 verification tests passed (3/3)"
