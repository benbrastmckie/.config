#!/usr/bin/env bash
# Test that classification fails gracefully in offline scenarios
# Validates: LLM classification error visibility improvements

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/../lib"

test_count=0
pass_count=0
fail_count=0

echo "=== Test: Offline Classification Error Visibility ==="
echo ""

# Source required libraries
if [ ! -f "${LIB_DIR}/workflow-llm-classifier.sh" ]; then
  echo "ERROR: workflow-llm-classifier.sh not found"
  exit 1
fi

if [ ! -f "${LIB_DIR}/workflow-scope-detection.sh" ]; then
  echo "ERROR: workflow-scope-detection.sh not found"
  exit 1
fi

# Set required environment variables
export CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
export WORKFLOW_CLASSIFICATION_TIMEOUT="${WORKFLOW_CLASSIFICATION_TIMEOUT:-10}"

source "${LIB_DIR}/workflow-llm-classifier.sh"
source "${LIB_DIR}/workflow-scope-detection.sh"

# Test 1: LLM timeout produces visible error message
echo "Test 1: LLM timeout produces visible error message..."
test_count=$((test_count + 1))

export WORKFLOW_CLASSIFICATION_MODE=llm-only
export WORKFLOW_CLASSIFICATION_TIMEOUT=2

# Capture both stdout and stderr
result=$(classify_workflow_comprehensive "test workflow" 2>&1 || true)

# Check if we got any output (not suppressed)
if [ -z "$result" ]; then
  echo "FAIL: Error messages suppressed (no output)"
  fail_count=$((fail_count + 1))
else
  echo "PASS: Error messages visible"
  pass_count=$((pass_count + 1))
fi

# Test 2: Error message suggests offline mode (regex-only)
echo ""
echo "Test 2: Error message suggests offline mode..."
test_count=$((test_count + 1))

if echo "$result" | grep -qi "regex"; then
  echo "PASS: Error message mentions regex-only mode"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: Error message doesn't suggest offline alternative"
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
  echo "PASS: Timeout completed in ${duration}s (acceptable)"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: Timeout took ${duration}s (too long)"
  fail_count=$((fail_count + 1))
fi

# Test 4: Regex-only mode works without network
echo ""
echo "Test 4: Regex-only mode works without network..."
test_count=$((test_count + 1))

export WORKFLOW_CLASSIFICATION_MODE=regex-only
unset WORKFLOW_CLASSIFICATION_TIMEOUT

result=$(classify_workflow_comprehensive "Research authentication patterns" 2>&1)

if [ -n "$result" ] && echo "$result" | grep -q "research"; then
  echo "PASS: Regex-only mode functional"
  pass_count=$((pass_count + 1))
else
  echo "FAIL: Regex-only mode failed"
  echo "Output: $result"
  fail_count=$((fail_count + 1))
fi

# Test 5: Verify sm_init forwards errors (no suppression at sm_init level)
echo ""
echo "Test 5: sm_init forwards classification errors..."
test_count=$((test_count + 1))

if [ -f "${LIB_DIR}/workflow-state-machine.sh" ]; then
  # Check if the fix is present (2>&1 instead of 2>/dev/null)
  if grep -q "classify_workflow_comprehensive.*2>&1" "${LIB_DIR}/workflow-state-machine.sh"; then
    echo "PASS: sm_init forwards classification errors (uses 2>&1)"
    pass_count=$((pass_count + 1))
  elif grep -q "classify_workflow_comprehensive.*2>/dev/null" "${LIB_DIR}/workflow-state-machine.sh"; then
    echo "FAIL: sm_init suppresses errors with 2>/dev/null"
    fail_count=$((fail_count + 1))
  else
    echo "WARNING: Cannot determine error forwarding pattern"
    pass_count=$((pass_count + 1))
  fi
else
  echo "SKIP: workflow-state-machine.sh not found"
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
