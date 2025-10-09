#!/usr/bin/env bash
# Test agent behavior file validation
# Tests expansion_specialist and collapse_specialist agent files

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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  [ -f "$agent_file" ]
}

validate_agent_has_role() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "^## Role" "$agent_file"
}

validate_agent_has_guidelines() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "^## Behavioral Guidelines" "$agent_file"
}

validate_agent_has_workflow() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Workflow" "$agent_file"
}

validate_agent_has_tools() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Tools Available" "$agent_file"
}

validate_agent_has_constraints() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Constraints" "$agent_file"
}

validate_agent_has_artifact_format() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Artifact Format" "$agent_file"
}

validate_agent_has_error_handling() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Error Handling" "$agent_file"
}

validate_agent_has_success_criteria() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Success Criteria" "$agent_file"
}

validate_agent_has_examples() {
  local agent_name="$1"
  local agent_file="$PROJECT_ROOT/.claude/agents/${agent_name}.md"
  grep -q "Example" "$agent_file"
}

# Main test execution
main() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Agent Behavior File Validation Tests"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Test expansion_specialist
  echo "Testing expansion_specialist agent:"
  test_case "Agent file exists" validate_agent_file_exists "expansion_specialist"
  test_case "Has role section" validate_agent_has_role "expansion_specialist"
  test_case "Has behavioral guidelines" validate_agent_has_guidelines "expansion_specialist"
  test_case "Has workflow documentation" validate_agent_has_workflow "expansion_specialist"
  test_case "Has tools specification" validate_agent_has_tools "expansion_specialist"
  test_case "Has constraints" validate_agent_has_constraints "expansion_specialist"
  test_case "Has artifact format" validate_agent_has_artifact_format "expansion_specialist"
  test_case "Has error handling" validate_agent_has_error_handling "expansion_specialist"
  test_case "Has success criteria" validate_agent_has_success_criteria "expansion_specialist"
  test_case "Has examples" validate_agent_has_examples "expansion_specialist"
  echo ""

  # Test collapse_specialist
  echo "Testing collapse_specialist agent:"
  test_case "Agent file exists" validate_agent_file_exists "collapse_specialist"
  test_case "Has role section" validate_agent_has_role "collapse_specialist"
  test_case "Has behavioral guidelines" validate_agent_has_guidelines "collapse_specialist"
  test_case "Has workflow documentation" validate_agent_has_workflow "collapse_specialist"
  test_case "Has tools specification" validate_agent_has_tools "collapse_specialist"
  test_case "Has constraints" validate_agent_has_constraints "collapse_specialist"
  test_case "Has artifact format" validate_agent_has_artifact_format "collapse_specialist"
  test_case "Has error handling" validate_agent_has_error_handling "collapse_specialist"
  test_case "Has success criteria" validate_agent_has_success_criteria "collapse_specialist"
  test_case "Has examples" validate_agent_has_examples "collapse_specialist"
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
