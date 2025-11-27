#!/usr/bin/env bash
# test_orchestration_commands.sh
# Unified test suite for orchestration commands (/coordinate, /research)

set -uo pipefail

# Test framework setup
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
CLAUDE_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib"

TEST_RESULTS=()
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Pre-flight check - coordinate.md was archived
COORDINATE_CMD="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"
if [ ! -f "$COORDINATE_CMD" ]; then
  echo "SKIP: coordinate.md not found (was archived)"
  echo "This test validates orchestration commands including coordinate."
  exit 0  # Exit successfully to indicate skip
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions

# test_helper: Record test result
record_test() {
  local test_name="$1"
  local result="$2"  # "PASS" or "FAIL"
  local message="${3:-}"

  ((TESTS_RUN++))

  if [[ "$result" == "PASS" ]]; then
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $test_name"
    TEST_RESULTS+=("PASS: $test_name")
  else
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $test_name"
    if [[ -n "$message" ]]; then
      echo -e "  ${RED}Error: $message${NC}"
    fi
    TEST_RESULTS+=("FAIL: $test_name - $message")
  fi
}

# test_helper: Test agent invocation pattern in command file
test_agent_invocation_pattern() {
  local command_file="$1"
  local test_name="Agent invocation pattern: $(basename "$command_file")"

  if [[ ! -f "$command_file" ]]; then
    record_test "$test_name" "FAIL" "File not found: $command_file"
    return 1
  fi

  # Run validation script
  if "$SCRIPT_DIR/../lib/util/validate-agent-invocation-pattern.sh" "$command_file" >/dev/null 2>&1; then
    record_test "$test_name" "PASS"
    return 0
  else
    record_test "$test_name" "FAIL" "Anti-patterns detected (run validation script for details)"
    return 1
  fi
}

# test_helper: Test bootstrap sequence
test_bootstrap_sequence() {
  local command_name="$1"
  local test_name="Bootstrap sequence: $command_name"

  # This is a placeholder - actual implementation would test command startup
  # For now, just check if command file exists
  local command_file="$SCRIPT_DIR/../commands/${command_name}.md"

  if [[ ! -f "$command_file" ]]; then
    record_test "$test_name" "FAIL" "Command file not found"
    return 1
  fi

  # Check for ANY library sourcing patterns (different commands use different libraries)
  # Look for "source .claude/lib/" or "source.*lib/" patterns
  if grep -q "source.*\.claude/lib/" "$command_file" || \
     grep -q "source.*lib/" "$command_file"; then
    record_test "$test_name" "PASS"
    return 0
  else
    record_test "$test_name" "FAIL" "No library sourcing found"
    return 1
  fi
}

# test_helper: Test delegation rate (counts imperative agent invocations)
test_delegation_rate() {
  local command_file="$1"
  local test_name="Delegation rate check: $(basename "$command_file")"

  # Count imperative Task invocations (actual agent invocations)
  # The "**EXECUTE NOW**: USE the Task tool" pattern is the definitive marker
  # of fixed agent invocations (post-spec 497 fixes)
  local imperative_count
  imperative_count=$(grep -c "\*\*EXECUTE NOW\*\*.*USE the Task tool" "$command_file" 2>/dev/null || echo "0")

  # Ensure numeric value
  imperative_count=$(echo "$imperative_count" | tr -d '[:space:]')
  imperative_count=${imperative_count:-0}

  # Expected minimum invocations per command (based on plan documentation)
  local expected_min
  case "$(basename "$command_file")" in
    coordinate.md)
      expected_min=5  # State machine: Research, plan, implement, debug, document
      ;;
    *)
      expected_min=1  # At least one agent invocation expected
      ;;
  esac

  if [[ $imperative_count -ge $expected_min ]]; then
    record_test "$test_name" "PASS" "Found $imperative_count imperative invocations (≥$expected_min expected)"
    return 0
  elif [[ $imperative_count -eq 0 ]]; then
    record_test "$test_name" "FAIL" "No imperative invocations found (expected ≥$expected_min)"
    return 1
  else
    record_test "$test_name" "FAIL" "Only $imperative_count imperative invocations found (expected ≥$expected_min)"
    return 1
  fi
}

# Main test execution

echo "============================================"
echo "Orchestration Commands Test Suite"
echo "============================================"
echo ""

# Test Suite 1: Agent Invocation Patterns
echo "Test Suite 1: Agent Invocation Patterns"
echo "----------------------------------------"
test_agent_invocation_pattern "$SCRIPT_DIR/../commands/coordinate.md"
echo ""

# Test Suite 2: Bootstrap Sequences
echo "Test Suite 2: Bootstrap Sequences"
echo "----------------------------------------"
test_bootstrap_sequence "coordinate"
echo ""

# Test Suite 3: Delegation Rate Analysis
echo "Test Suite 3: Delegation Rate Analysis"
echo "----------------------------------------"
test_delegation_rate "$SCRIPT_DIR/../commands/coordinate.md"
echo ""

# Test Suite 4: Utility Scripts
echo "Test Suite 4: Utility Scripts"
echo "----------------------------------------"

# Test validation script exists and is executable
if [[ -x "$SCRIPT_DIR/../lib/util/validate-agent-invocation-pattern.sh" ]]; then
  record_test "Validation script executable" "PASS"
else
  record_test "Validation script executable" "FAIL" "Not found or not executable"
fi

# Test backup script exists and is executable
if [[ -x "$SCRIPT_DIR/../lib/util/backup-command-file.sh" ]]; then
  record_test "Backup script executable" "PASS"
else
  record_test "Backup script executable" "FAIL" "Not found or not executable"
fi

# Test rollback script exists and is executable
if [[ -x "$SCRIPT_DIR/../lib/util/rollback-command-file.sh" ]]; then
  record_test "Rollback script executable" "PASS"
else
  record_test "Rollback script executable" "FAIL" "Not found or not executable"
fi

echo ""

# Test Suite 5: Plan Naming Convention
echo "Test Suite 5: Plan Naming Convention"
echo "----------------------------------------"

# Test coordinate plan naming pattern
test_coordinate_plan_naming() {
  local test_name="Coordinate plan naming pattern"

  # Source topic-utils.sh to access sanitize_topic_name()
  if [[ ! -f "$CLAUDE_LIB/plan/topic-utils.sh" ]]; then
    record_test "$test_name" "FAIL" "topic-utils.sh not found"
    return 1
  fi

  source "$CLAUDE_LIB/plan/topic-utils.sh"

  # Test workflow description
  local workflow_desc="fix authentication bug"

  # Expected sanitized name from topic-utils.sh algorithm
  local expected_topic="fix_authentication_bug"
  local expected_pattern="001_${expected_topic}_plan.md"

  # Call sanitize_topic_name() directly
  local actual_topic
  actual_topic=$(sanitize_topic_name "$workflow_desc")

  # Assert topic name matches expected pattern
  if [[ "$actual_topic" != "$expected_topic" ]]; then
    record_test "$test_name" "FAIL" "Topic name mismatch: expected '$expected_topic', got '$actual_topic'"
    return 1
  fi

  # Verify plan path construction
  local topic_path=".claude/specs/999_${actual_topic}"
  local plan_path="${topic_path}/plans/${expected_pattern}"

  # Assert plan path contains topic name
  if [[ ! "$plan_path" =~ $expected_topic ]]; then
    record_test "$test_name" "FAIL" "Plan path missing topic name: $plan_path"
    return 1
  fi

  # Assert plan path is NOT generic
  if [[ "$plan_path" =~ "001_implementation.md" ]]; then
    record_test "$test_name" "FAIL" "Plan path uses generic name (regression detected)"
    return 1
  fi

  record_test "$test_name" "PASS"
  return 0
}

# Test that coordinate.md doesn't have hardcoded generic plan path
test_no_hardcoded_plan_path() {
  local test_name="No hardcoded generic plan path in coordinate.md"
  local command_file="$SCRIPT_DIR/../commands/coordinate.md"

  # Check for hardcoded "001_implementation.md" assignment
  if grep -q 'PLAN_PATH=.*001_implementation\.md' "$command_file"; then
    record_test "$test_name" "FAIL" "Found hardcoded PLAN_PATH='..001_implementation.md' (regression)"
    return 1
  fi

  record_test "$test_name" "PASS"
  return 0
}

# Test PLAN_PATH state persistence
test_plan_path_state_persistence() {
  local test_name="PLAN_PATH state persistence in coordinate.md"
  local command_file="$SCRIPT_DIR/../commands/coordinate.md"

  # Verify PLAN_PATH is saved to state (bash block 1)
  if ! grep -q 'append_workflow_state.*"PLAN_PATH"' "$command_file"; then
    record_test "$test_name" "FAIL" "PLAN_PATH not saved to workflow state"
    return 1
  fi

  # Verify PLAN_PATH validation exists (bash block 2)
  if ! grep -q 'if.*PLAN_PATH.*empty\|missing' "$command_file"; then
    record_test "$test_name" "FAIL" "PLAN_PATH validation not found"
    return 1
  fi

  record_test "$test_name" "PASS"
  return 0
}

# Run plan naming tests
test_coordinate_plan_naming
test_no_hardcoded_plan_path
test_plan_path_state_persistence

echo ""

# Summary
echo "============================================"
echo "Test Summary"
echo "============================================"
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "${RED}Failed: $TESTS_FAILED${NC}"
else
  echo "Failed: $TESTS_FAILED"
fi
echo ""

# Exit with appropriate code
if [[ $TESTS_FAILED -eq 0 ]]; then
  echo -e "${GREEN}✓ All tests passed${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  echo ""
  echo "Failed tests:"
  for result in "${TEST_RESULTS[@]}"; do
    if [[ "$result" == FAIL:* ]]; then
      echo "  - ${result#FAIL: }"
    fi
  done
  exit 1
fi
