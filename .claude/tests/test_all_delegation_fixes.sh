#!/usr/bin/env bash
# Master test orchestrator for all subagent delegation fixes
# Tests Phases 2, 3, and 4 (code-writer, orchestrate, system-wide)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════════"
echo "  Subagent Delegation Fixes - Master Test Suite"
echo "════════════════════════════════════════════════════════════"
echo ""

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=""

run_test() {
  local test_name="$1"
  local test_script="$2"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo -e "${BLUE}[$TESTS_RUN] Running: $test_name${NC}"
  echo "────────────────────────────────────────────────────────────"

  if bash "$test_script" 2>&1; then
    echo -e "${GREEN}✓ PASSED: $test_name${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo ""
    return 0
  else
    echo -e "${RED}✗ FAILED: $test_name${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS="${FAILED_TESTS}  - $test_name\n"
    echo ""
    return 1
  fi
}

echo -e "${BLUE}Phase 2: /implement code-writer Fix${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -f "$SCRIPT_DIR/test_code_writer_no_recursion.sh" ]; then
  run_test "Code-writer No Recursion" \
    "$SCRIPT_DIR/test_code_writer_no_recursion.sh"
else
  echo -e "${YELLOW}⊘ SKIPPED: test_code_writer_no_recursion.sh not found${NC}"
  echo ""
fi

echo -e "${BLUE}Phase 3: /orchestrate Planning Fix${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -f "$SCRIPT_DIR/test_orchestrate_planning_behavioral_injection.sh" ]; then
  run_test "Orchestrate Planning Behavioral Injection" \
    "$SCRIPT_DIR/test_orchestrate_planning_behavioral_injection.sh"
else
  echo -e "${YELLOW}⊘ SKIPPED: test_orchestrate_planning_behavioral_injection.sh not found${NC}"
  echo ""
fi

echo -e "${BLUE}Phase 4: System-Wide Validation${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

run_test "Anti-Pattern Detection (Agent Files)" \
  "$SCRIPT_DIR/validate_no_agent_slash_commands.sh"

run_test "Behavioral Injection Compliance (Commands)" \
  "$SCRIPT_DIR/validate_command_behavioral_injection.sh"

run_test "Topic-Based Artifact Organization" \
  "$SCRIPT_DIR/validate_topic_based_artifacts.sh"

# Summary
echo "════════════════════════════════════════════════════════════"
echo "  Test Results Summary"
echo "════════════════════════════════════════════════════════════"
echo "Tests run: $TESTS_RUN"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  ✅ ALL DELEGATION FIXES VALIDATED SUCCESSFULLY           ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  ❌ SOME TESTS FAILED                                      ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Failed tests:"
  echo -e "$FAILED_TESTS"
  exit 1
fi
