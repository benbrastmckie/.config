#!/usr/bin/env bash
# Test: Agent Delegation in /coordinate Command
# Category: CRITICAL - Verifies 100% agent delegation rate

set -e

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_FILE="$SCRIPT_DIR/../commands/coordinate.md"
TEST_NAME="test_coordinate_delegation"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test_header() {
  echo -e "\n${YELLOW}=== $1 ===${NC}"
}

assert_true() {
  local description="$1"
  local command="$2"
  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command"; then
    echo -e "${GREEN}✓${NC} $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_false() {
  local description="$1"
  local command="$2"
  TESTS_RUN=$((TESTS_RUN + 1))

  if eval "$command"; then
    echo -e "${RED}✗${NC} $description"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  else
    echo -e "${GREEN}✓${NC} $description"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  fi
}

assert_count() {
  local description="$1"
  local expected="$2"
  local command="$3"
  TESTS_RUN=$((TESTS_RUN + 1))

  local actual
  actual=$(eval "$command")

  if [ "$actual" -ge "$expected" ]; then
    echo -e "${GREEN}✓${NC} $description (expected ≥$expected, got $actual)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo -e "${RED}✗${NC} $description (expected ≥$expected, got $actual)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Command file exists
print_test_header "Test 1: Command File Existence"
assert_true "Command file exists" "[ -f '$COMMAND_FILE' ]"

# Test 2: Phase 1 - Research Agent Invocations
print_test_header "Test 2: Phase 1 - Research Agent Delegation"
assert_true "Research-specialist agent referenced" "grep -q 'research-specialist.md' '$COMMAND_FILE'"
assert_true "Phase 1 has Task invocation" "grep -A 100 'Phase 1.*Research' '$COMMAND_FILE' | grep -qE 'USE.*Task tool|invoke.*Task|Task tool.*research'"
assert_true "Phase 1 Task has imperative marker" "grep -A 100 'Phase 1.*Research' '$COMMAND_FILE' | grep -qE 'EXECUTE NOW|YOU MUST|REQUIRED ACTION'"

# Test 3: Phase 2 - Plan Architect Invocation
print_test_header "Test 3: Phase 2 - Plan Architect Delegation"
assert_true "Plan-architect agent referenced" "grep -q 'plan-architect.md' '$COMMAND_FILE'"
assert_true "Phase 2 has Task invocation" "grep -A 100 'Phase 2.*Plan' '$COMMAND_FILE' | grep -qE 'USE.*Task tool|invoke.*Task|Task tool.*plan'"
assert_true "Phase 2 Task has imperative marker" "grep -A 100 'Phase 2.*Plan' '$COMMAND_FILE' | grep -qE 'EXECUTE NOW|YOU MUST|REQUIRED ACTION'"

# Test 4: Phase 3 - Implementer-Coordinator Invocation
print_test_header "Test 4: Phase 3 - Implementer-Coordinator Delegation"
assert_true "Implementer-coordinator agent referenced" "grep -q 'implementer-coordinator.md' '$COMMAND_FILE'"
assert_false "Code-writer agent NOT used for Phase 3" "grep -A 100 'Phase 3' '$COMMAND_FILE' | grep -q 'code-writer.md'"
assert_true "Phase 3 has Task invocation" "grep -A 100 'Phase 3' '$COMMAND_FILE' | grep -qE 'USE.*Task tool|invoke.*Task|Task tool.*implement'"
assert_true "Phase 3 Task has imperative marker" "grep -A 100 'Phase 3' '$COMMAND_FILE' | grep -qE 'EXECUTE NOW|YOU MUST|REQUIRED ACTION'"

# Test 5: Phase 4 - Test Specialist Invocation
print_test_header "Test 5: Phase 4 - Test Specialist Delegation"
assert_true "Test-specialist agent referenced" "grep -q 'test-specialist.md' '$COMMAND_FILE'"
assert_true "Phase 4 has Task invocation" "grep -A 100 'Phase 4.*Test' '$COMMAND_FILE' | grep -qE 'USE.*Task tool|invoke.*Task|Task tool.*test'"
assert_true "Phase 4 Task has imperative marker" "grep -A 100 'Phase 4.*Test' '$COMMAND_FILE' | grep -qE 'EXECUTE NOW|YOU MUST|REQUIRED ACTION'"

# Test 6: Phase 5 - Debug Analyst Invocation
print_test_header "Test 6: Phase 5 - Debug Analyst Delegation"
assert_true "Debug-analyst agent referenced" "grep -q 'debug-analyst.md' '$COMMAND_FILE'"
assert_true "Phase 5 has Task invocation" "grep -A 100 'Phase 5' '$COMMAND_FILE' | grep -qE 'USE.*Task tool|invoke.*Task|Task tool.*debug'"
assert_true "Phase 5 Task has imperative marker" "grep -A 100 'Phase 5' '$COMMAND_FILE' | grep -qE 'EXECUTE NOW|YOU MUST|REQUIRED ACTION'"

# Test 7: Phase 6 - Doc Writer Invocation
print_test_header "Test 7: Phase 6 - Doc Writer Delegation"
assert_true "Doc-writer agent referenced" "grep -q 'doc-writer.md' '$COMMAND_FILE'"
assert_true "Phase 6 has Task invocation" "grep -A 100 'Phase 6.*Doc' '$COMMAND_FILE' | grep -qE 'USE.*Task tool|invoke.*Task|Task tool.*doc'"
assert_true "Phase 6 Task has imperative marker" "grep -A 100 'Phase 6.*Doc' '$COMMAND_FILE' | grep -qE 'EXECUTE NOW|YOU MUST|REQUIRED ACTION'"

# Test 8: All Task Invocations Have Imperative Markers
print_test_header "Test 8: Global Imperative Marker Compliance"
assert_count "All imperative markers for Task invocations" 6 "grep -c 'EXECUTE NOW.*Task tool' '$COMMAND_FILE'"

# Test 9: No Code-Fenced Task Examples
print_test_header "Test 9: No Code-Fenced Task Examples (Prevents 0% Delegation)"
assert_false "No code-fenced YAML Task blocks" "grep -Pzo '\`\`\`yaml\s*Task\s*\{' '$COMMAND_FILE'"
assert_false "No code-fenced Task blocks (any language)" "grep -Pzo '\`\`\`[a-z]*\s*Task\s*\{' '$COMMAND_FILE'"

# Test 10: Behavioral Content Extraction
print_test_header "Test 10: Behavioral Content Extraction (Standard 12)"
assert_count "Agent behavioral files referenced" 7 "grep -c '.claude/agents/.*\.md' '$COMMAND_FILE'"
assert_count "Behavioral injection pattern used" 5 "grep -c 'Read and follow ALL behavioral guidelines from:' '$COMMAND_FILE'"

# Test 11: Completion Signals Present
print_test_header "Test 11: Agent Completion Signals"
assert_true "REPORT_CREATED signal documented" "grep -q 'REPORT_CREATED:' '$COMMAND_FILE'"
assert_true "PLAN_CREATED signal documented" "grep -q 'PLAN_CREATED:' '$COMMAND_FILE'"
assert_true "Phase completion signals documented" "grep -qE 'DEBUG_ANALYSIS_COMPLETE:|SUMMARY_CREATED:' '$COMMAND_FILE'"

# Test 12: Agent Invocations Count
print_test_header "Test 12: Total Agent Invocation Count"
assert_count "Task invocations present" 7 "grep -c 'USE.*Task tool' '$COMMAND_FILE'"

# Summary
print_test_header "Test Summary"
echo "Tests run:    $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All agent delegation tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some agent delegation tests failed.${NC}"
  exit 1
fi
