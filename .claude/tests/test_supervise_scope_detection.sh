#!/usr/bin/env bash
# Test script for /supervise workflow scope detection
# Tests the detect_workflow_scope() function with various input patterns

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Source the detect_workflow_scope function from workflow-detection.sh library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/workflow-detection.sh"

# Test helper function
test_scope_detection() {
  local workflow_desc="$1"
  local expected_scope="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  local actual_scope=$(detect_workflow_scope "$workflow_desc")

  if [ "$actual_scope" == "$expected_scope" ]; then
    echo -e "${GREEN}✓${NC} Test $TESTS_RUN: $test_name"
    echo "    Input: \"$workflow_desc\""
    echo "    Expected: $expected_scope"
    echo "    Got: $actual_scope"
    echo ""
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} Test $TESTS_RUN: $test_name"
    echo "    Input: \"$workflow_desc\""
    echo "    Expected: $expected_scope"
    echo "    Got: $actual_scope"
    echo ""
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

echo "════════════════════════════════════════════════════════"
echo "  Testing /supervise Workflow Scope Detection"
echo "════════════════════════════════════════════════════════"
echo ""

# Pattern 1: Research-only tests
echo "Pattern 1: Research-only"
echo "─────────────────────────"
test_scope_detection "research API authentication patterns" "research-only" "Simple research query"
test_scope_detection "research the codebase architecture" "research-only" "Research with 'the' article"
test_scope_detection "Research error handling mechanisms" "research-only" "Capitalized research"
echo ""

# Pattern 2: Research-and-plan tests
echo "Pattern 2: Research-and-plan"
echo "─────────────────────────────"
test_scope_detection "research authentication to create refactor plan" "research-and-plan" "Research to create plan"
test_scope_detection "analyze the auth module for planning a refactor" "research-and-plan" "Analyze for planning"
test_scope_detection "investigate error handling and create implementation plan" "research-and-plan" "Investigate and create plan"
test_scope_detection "research API patterns to plan feature" "research-and-plan" "Research to plan"
echo ""

# Pattern 3: Full-implementation tests
echo "Pattern 3: Full-implementation"
echo "───────────────────────────────"
test_scope_detection "implement OAuth2 authentication" "full-implementation" "Implement feature"
test_scope_detection "build a new user registration system" "full-implementation" "Build system"
test_scope_detection "add feature for token refresh" "full-implementation" "Add feature"
test_scope_detection "create code component for logging" "full-implementation" "Create component"
test_scope_detection "add functionality for rate limiting" "full-implementation" "Add functionality"
echo ""

# Pattern 4: Debug-only tests
echo "Pattern 4: Debug-only"
echo "─────────────────────"
test_scope_detection "fix token refresh bug in auth.js" "debug-only" "Fix bug"
test_scope_detection "debug authentication failure" "debug-only" "Debug failure"
test_scope_detection "troubleshoot connection error in database" "debug-only" "Troubleshoot error"
test_scope_detection "fix the memory leak issue" "debug-only" "Fix issue"
echo ""

# Edge cases and ambiguous queries (should default to research-and-plan)
echo "Edge Cases (Default to research-and-plan)"
echo "──────────────────────────────────────────"
test_scope_detection "analyze the codebase" "research-and-plan" "Ambiguous analyze"
test_scope_detection "look at the authentication module" "research-and-plan" "Informal request"
test_scope_detection "check the error handling" "research-and-plan" "Vague check request"
test_scope_detection "" "research-and-plan" "Empty string"
echo ""

# Complex queries that might be ambiguous
echo "Complex Queries"
echo "───────────────"
test_scope_detection "research auth then implement it" "full-implementation" "Mixed: research + implement"
test_scope_detection "fix bug and add feature" "full-implementation" "Mixed: fix + add (add wins)"
test_scope_detection "implement fix for auth bug" "full-implementation" "Implement fix (implement wins)"
echo ""

# Summary
echo "════════════════════════════════════════════════════════"
echo "  Test Results Summary"
echo "════════════════════════════════════════════════════════"
echo ""
echo "Tests Run:    $TESTS_RUN"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed!${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  echo ""
  exit 1
fi

# Cleanup
rm -f "$TEMP_SCRIPT"
