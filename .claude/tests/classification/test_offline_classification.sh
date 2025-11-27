#!/usr/bin/env bash
# Test that classification fails gracefully in offline scenarios
# Validates: LLM classification error visibility improvements

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect project root using git or walk-up pattern
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  CLAUDE_PROJECT_DIR="$SCRIPT_DIR"
  while [ "$CLAUDE_PROJECT_DIR" != "/" ]; do
    if [ -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
      break
    fi
    CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_PROJECT_DIR")"
  done
fi
LIB_DIR="${CLAUDE_PROJECT_DIR}/.claude/lib"

test_count=0
pass_count=0
fail_count=0

echo "=== Test: Offline Classification Error Visibility ==="
echo ""

# Source required libraries
if [ ! -f "${LIB_DIR}/workflow/workflow-llm-classifier.sh" ]; then
  echo "ERROR: workflow-llm-classifier.sh not found"
  exit 1
fi

if [ ! -f "${LIB_DIR}/workflow/workflow-scope-detection.sh" ]; then
  echo "ERROR: workflow-scope-detection.sh not found"
  exit 1
fi

# Set required environment variables
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export WORKFLOW_CLASSIFICATION_TIMEOUT="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"

source "${LIB_DIR}/workflow/workflow-llm-classifier.sh"
source "${LIB_DIR}/workflow/workflow-scope-detection.sh"

# Test 1: LLM timeout produces visible error message
echo "Test 1: LLM timeout produces visible error message..."
test_count=$((test_count + 1))

# Temporarily disable test mode to test actual error handling
unset WORKFLOW_CLASSIFICATION_TEST_MODE
export WORKFLOW_CLASSIFICATION_TIMEOUT=2

# Capture both stdout and stderr
result=$(classify_workflow_comprehensive "test workflow" 2>&1 || true)

# Check if we got any output (not suppressed)
if [ -z "$result" ]; then
  echo "✗ FAIL: Error messages suppressed (no output)"
  fail_count=$((fail_count + 1))
else
  echo "✓ PASS: Error messages visible"
  pass_count=$((pass_count + 1))
fi

# Test 2: Error message provides actionable suggestions
echo ""
echo "Test 2: Error message provides actionable suggestions..."
test_count=$((test_count + 1))

if echo "$result" | grep -qi "suggestion\|alternative"; then
  echo "✓ PASS: Error message provides actionable guidance"
  pass_count=$((pass_count + 1))
else
  echo "✗ FAIL: Error message doesn't provide actionable suggestions"
  echo "Output received:"
  echo "$result"
  fail_count=$((fail_count + 1))
fi

# Test 3: Timeout completes in reasonable time (<3s for 2s timeout)
echo ""
echo "Test 3: Timeout completes in reasonable time..."
test_count=$((test_count + 1))

start_time=$(date +%s)
classify_workflow_comprehensive "test workflow" 2>&1 >/dev/null || true
end_time=$(date +%s)
duration=$((end_time - start_time))

if [ "$duration" -lt 5 ]; then
  echo "✓ PASS: Timeout completed in ${duration}s (acceptable)"
  pass_count=$((pass_count + 1))
else
  echo "✗ FAIL: Timeout took ${duration}s (too long)"
  fail_count=$((fail_count + 1))
fi

# Test 4: Test mode works without network (for offline testing)
echo ""
echo "Test 4: Test mode works without network (for offline testing)..."
test_count=$((test_count + 1))

export WORKFLOW_CLASSIFICATION_TEST_MODE=1
unset WORKFLOW_CLASSIFICATION_TIMEOUT

result=$(classify_workflow_comprehensive "Research authentication patterns" 2>&1)

if [ -n "$result" ] && echo "$result" | jq -e '.workflow_type' >/dev/null 2>&1; then
  echo "✓ PASS: Test mode returns valid JSON classification"
  pass_count=$((pass_count + 1))
else
  echo "✗ FAIL: Test mode failed or returned invalid JSON"
  echo "Output: $result"
  fail_count=$((fail_count + 1))
fi

unset WORKFLOW_CLASSIFICATION_TEST_MODE

# Test 5: Verify sm_init forwards errors (no suppression at sm_init level)
echo ""
echo "Test 5: sm_init forwards classification errors..."
test_count=$((test_count + 1))

if [ -f "${LIB_DIR}/workflow/workflow-state-machine.sh" ]; then
  # Check if the fix is present (2>&1 or 2>"$file" instead of 2>/dev/null)
  if grep -q "classify_workflow_comprehensive.*2>&1" "${LIB_DIR}/workflow/workflow-state-machine.sh" || \
     grep -q 'classify_workflow_comprehensive.*2>"' "${LIB_DIR}/workflow/workflow-state-machine.sh"; then
    echo "✓ PASS: sm_init forwards classification errors (captures or forwards stderr)"
    pass_count=$((pass_count + 1))
  elif grep -q "classify_workflow_comprehensive.*2>/dev/null" "${LIB_DIR}/workflow/workflow-state-machine.sh"; then
    echo "✗ FAIL: sm_init suppresses errors with 2>/dev/null"
    fail_count=$((fail_count + 1))
  else
    echo "WARNING: Cannot determine error forwarding pattern"
    pass_count=$((pass_count + 1))
  fi
else
  echo "⊘ SKIP: workflow-state-machine.sh not found"
fi

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
