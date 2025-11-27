#!/usr/bin/env bash
# Test agent behavior file validation
# Tests plan-structure-manager agent file (consolidated from expansion-specialist and collapse-specialist)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Find project root using git or walk-up pattern
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
PROJECT_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

# Pre-flight check for required agent
AGENT_FILE="$PROJECT_ROOT/agents/plan-structure-manager.md"
if [ ! -f "$AGENT_FILE" ]; then
  echo "SKIP: plan-structure-manager agent not found (may have been archived or renamed)"
  exit 0  # Exit successfully to indicate skip
fi

# Test function
test_case() {
  local description="$1"
  shift
  TESTS_RUN=$((TESTS_RUN + 1))

  echo -n "  Testing: $description... "

  if "$@" >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Validation functions
validate_agent_file_exists() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  [ -f "$agent_file" ]
}

validate_agent_has_role() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "^## Role" "$agent_file"
}

validate_agent_has_guidelines() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "^## Behavioral Guidelines" "$agent_file"
}

validate_agent_has_workflow() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "Workflow" "$agent_file"
}

validate_agent_has_tools() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "Tools Available" "$agent_file"
}

validate_agent_has_constraints() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "Constraints" "$agent_file"
}

validate_agent_has_artifact_format() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "Artifact Format" "$agent_file"
}

validate_agent_has_error_handling() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "Error Handling" "$agent_file"
}

validate_agent_has_success_criteria() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q -E "Success Criteria|COMPLETION CRITERIA" "$agent_file"
}

validate_agent_has_examples() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/agents/${agent_name}.md"
  grep -q "Example" "$agent_file"
}

# Main test execution
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Agent Behavior File Validation Tests"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Test plan-structure-manager (consolidated from expansion-specialist and collapse-specialist)
  echo "Testing plan-structure-manager agent:"
  test_case "Agent file exists" validate_agent_file_exists "plan-structure-manager"
  test_case "Has role section" validate_agent_has_role "plan-structure-manager"
  test_case "Has behavioral guidelines" validate_agent_has_guidelines "plan-structure-manager"
  test_case "Has workflow documentation" validate_agent_has_workflow "plan-structure-manager"
  test_case "Has tools specification" validate_agent_has_tools "plan-structure-manager"
  test_case "Has constraints" validate_agent_has_constraints "plan-structure-manager"
  test_case "Has artifact format" validate_agent_has_artifact_format "plan-structure-manager"
  test_case "Has error handling" validate_agent_has_error_handling "plan-structure-manager"
  test_case "Has success criteria" validate_agent_has_success_criteria "plan-structure-manager"
  test_case "Has examples" validate_agent_has_examples "plan-structure-manager"
  echo ""

  # Summary
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Test Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Total tests:  $TESTS_RUN"
  echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"

  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
    echo ""
    exit 1
  else
    echo "Failed:       0"
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

# Run tests
main "$@"
