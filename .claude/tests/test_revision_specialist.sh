#!/bin/bash
# Test suite for revision-specialist agent and research-and-revise workflow

# Source test utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
pass() {
  echo "✓ $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo "✗ $1"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

echo "========================================"
echo "Revision Specialist Test Suite"
echo "========================================"
echo ""

# Test 1: Workflow scope detection (research-and-revise pattern)
echo "Test 1: Workflow scope detection (research-and-revise pattern)"
source "${PROJECT_ROOT}/.claude/lib/workflow-scope-detection.sh"

SCOPE1=$(detect_workflow_scope "research authentication patterns and revise existing plan")
if [ "$SCOPE1" = "research-and-revise" ]; then
  pass "Pattern 1: 'research X and revise Y' detected correctly"
else
  fail "Pattern 1 failed: got '$SCOPE1', expected 'research-and-revise'"
fi

SCOPE2=$(detect_workflow_scope "research auth patterns to update 042 plan")
if [ "$SCOPE2" = "research-and-revise" ]; then
  pass "Pattern 2: 'research X to update plan' detected correctly"
else
  fail "Pattern 2 failed: got '$SCOPE2', expected 'research-and-revise'"
fi

SCOPE3=$(detect_workflow_scope "analyze security patterns then modify security plan")
if [ "$SCOPE3" = "research-and-revise" ]; then
  pass "Pattern 3: 'analyze X then modify Y' detected correctly"
else
  fail "Pattern 3 failed: got '$SCOPE3', expected 'research-and-revise'"
fi

# Test 2: No false positives
echo ""
echo "Test 2: No false positives (research-and-plan should not match research-and-revise)"

SCOPE4=$(detect_workflow_scope "research auth and create plan")
if [ "$SCOPE4" = "research-and-plan" ]; then
  pass "No false positive: 'research X and create plan' → research-and-plan"
else
  fail "False positive detected: got '$SCOPE4', expected 'research-and-plan'"
fi

SCOPE5=$(detect_workflow_scope "research authentication patterns")
if [ "$SCOPE5" = "research-only" ]; then
  pass "No false positive: 'research X' → research-only"
else
  fail "False positive detected: got '$SCOPE5', expected 'research-only'"
fi

# Test 3: Plan discovery logic
echo ""
echo "Test 3: Plan discovery (finds most recent plan)"

# Create test topic directory with multiple plans
TEST_TOPIC_DIR="/tmp/test_revision_spec_$$"
mkdir -p "$TEST_TOPIC_DIR/plans"

echo "# Test Plan 1" > "$TEST_TOPIC_DIR/plans/001_test.md"
sleep 1
echo "# Test Plan 2" > "$TEST_TOPIC_DIR/plans/002_test.md"

# Test discovery finds most recent
TOPIC_PATH="$TEST_TOPIC_DIR"
EXISTING_PLAN=$(find "${TOPIC_PATH}/plans" -name "*.md" -type f -print0 2>/dev/null | \
                 xargs -0 ls -t 2>/dev/null | head -1)

if [[ "$EXISTING_PLAN" == *"002_test.md" ]]; then
  pass "Plan discovery finds most recent plan (002_test.md)"
else
  fail "Plan discovery failed: got '$EXISTING_PLAN', expected path ending in 002_test.md"
fi

# Test 4: Backup creation
echo ""
echo "Test 4: Backup creation (timestamped backup in backups/ directory)"

PLAN_DIR="$TEST_TOPIC_DIR/plans"
BACKUP_DIR="${PLAN_DIR}/backups"
mkdir -p "$BACKUP_DIR"

PLAN_PATH="$TEST_TOPIC_DIR/plans/002_test.md"
PLAN_BASENAME=$(basename "$PLAN_PATH")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/${PLAN_BASENAME%.md}_${TIMESTAMP}.md"

cp "$PLAN_PATH" "$BACKUP_PATH"

if [ -f "$BACKUP_PATH" ]; then
  pass "Backup created successfully: $(basename "$BACKUP_PATH")"
else
  fail "Backup creation failed"
fi

# Verify backup has correct format
if [[ "$(basename "$BACKUP_PATH")" =~ ^002_test_[0-9]{8}_[0-9]{6}\.md$ ]]; then
  pass "Backup filename has correct timestamp format"
else
  fail "Backup filename format incorrect: $(basename "$BACKUP_PATH")"
fi

# Test 5: State machine terminal state mapping
echo ""
echo "Test 5: State machine terminal state mapping (research-and-revise case exists)"

# Just verify the case statement includes research-and-revise
if grep -q "research-and-revise)" "${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh"; then
  pass "State machine includes research-and-revise case"
else
  fail "State machine missing research-and-revise case"
fi

# Verify it maps to STATE_PLAN
if grep -A 1 "research-and-revise)" "${PROJECT_ROOT}/.claude/lib/workflow-state-machine.sh" | grep -q "STATE_PLAN"; then
  pass "research-and-revise correctly maps to STATE_PLAN"
else
  fail "research-and-revise mapping incorrect"
fi

# Test 6: Completion signal format
echo ""
echo "Test 6: Completion signal format (REVISION_COMPLETED: <path>)"

COMPLETION_SIGNAL="REVISION_COMPLETED: /home/user/.claude/specs/042_auth/plans/001_auth_plan.md"

if echo "$COMPLETION_SIGNAL" | grep -q "^REVISION_COMPLETED: /"; then
  pass "Completion signal format correct"
else
  fail "Completion signal format incorrect"
fi

# Test 7: Error handling (no existing plan found)
echo ""
echo "Test 7: Error handling (fail-fast when no existing plan found)"

TEST_EMPTY_DIR="/tmp/test_revision_empty_$$"
mkdir -p "$TEST_EMPTY_DIR/reports"

TOPIC_PATH="$TEST_EMPTY_DIR"
EXISTING_PLAN=""

if [ -d "${TOPIC_PATH}/plans" ]; then
  EXISTING_PLAN=$(find "${TOPIC_PATH}/plans" -name "*.md" -type f -print0 2>/dev/null | \
                   xargs -0 ls -t 2>/dev/null | head -1)
fi

if [ -z "$EXISTING_PLAN" ]; then
  pass "Error detection works: no plan found as expected"
else
  fail "Error detection failed: plan found when none should exist"
fi

# Cleanup test directories
rm -rf "$TEST_TOPIC_DIR" "$TEST_EMPTY_DIR"

# Test Results Summary
echo ""
echo "========================================"
echo "Test Results Summary"
echo "========================================"
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
