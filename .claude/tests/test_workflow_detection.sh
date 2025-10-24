#!/usr/bin/env bash
# Unit tests for workflow-detection.sh

source "$(dirname "$0")/../lib/workflow-detection.sh"

# Test detect_workflow_scope function
test_research_only() {
  local result=$(detect_workflow_scope "research API patterns")
  if [ "$result" == "research-only" ]; then
    echo "✓ PASS: research-only detection"
    return 0
  else
    echo "✗ FAIL: Expected 'research-only', got '$result'"
    return 1
  fi
}

test_research_and_plan() {
  local result=$(detect_workflow_scope "research authentication to create plan")
  if [ "$result" == "research-and-plan" ]; then
    echo "✓ PASS: research-and-plan detection"
    return 0
  else
    echo "✗ FAIL: Expected 'research-and-plan', got '$result'"
    return 1
  fi
}

test_full_implementation() {
  local result=$(detect_workflow_scope "implement OAuth2 authentication")
  if [ "$result" == "full-implementation" ]; then
    echo "✓ PASS: full-implementation detection"
    return 0
  else
    echo "✗ FAIL: Expected 'full-implementation', got '$result'"
    return 1
  fi
}

test_debug_only() {
  local result=$(detect_workflow_scope "fix token refresh bug")
  if [ "$result" == "debug-only" ]; then
    echo "✓ PASS: debug-only detection"
    return 0
  else
    echo "✗ FAIL: Expected 'debug-only', got '$result'"
    return 1
  fi
}

test_should_run_phase() {
  export PHASES_TO_EXECUTE="0,1,2"

  if should_run_phase 1; then
    echo "✓ PASS: should_run_phase detects phase in list"
  else
    echo "✗ FAIL: should_run_phase failed to detect phase 1"
    return 1
  fi

  if ! should_run_phase 3; then
    echo "✓ PASS: should_run_phase correctly skips phase 3"
  else
    echo "✗ FAIL: should_run_phase incorrectly included phase 3"
    return 1
  fi
}

# Run all tests
echo "Running workflow-detection.sh unit tests..."
echo ""

FAILURES=0
test_research_only || FAILURES=$((FAILURES + 1))
test_research_and_plan || FAILURES=$((FAILURES + 1))
test_full_implementation || FAILURES=$((FAILURES + 1))
test_debug_only || FAILURES=$((FAILURES + 1))
test_should_run_phase || FAILURES=$((FAILURES + 1))

echo ""
if [ $FAILURES -eq 0 ]; then
  echo "All tests passed ✓"
  exit 0
else
  echo "Tests failed: $FAILURES"
  exit 1
fi
