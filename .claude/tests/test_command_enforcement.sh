#!/bin/bash
# Test Suite: Command Execution Enforcement
#
# Tests that commands follow Standard 0 (Execution Enforcement) patterns
# for reliable file creation, verification checkpoints, and fallback mechanisms.
#
# Usage: ./test_command_enforcement.sh [command-name]
#   - If command-name provided: Test that specific command
#   - If no args: Test all priority commands
#
# Exit codes:
#   0 = All tests passed
#   1 = One or more tests failed
#   2 = Usage error

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
COMMANDS_DIR="$CLAUDE_DIR/commands"

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#=============================================================================
# Test Utilities
#=============================================================================

test_start() {
  local test_name="$1"
  echo -e "${YELLOW}[TEST]${NC} $test_name"
  ((TESTS_RUN++))
}

test_pass() {
  local test_name="$1"
  echo -e "${GREEN}[PASS]${NC} $test_name"
  ((TESTS_PASSED++))
}

test_fail() {
  local test_name="$1"
  local reason="$2"
  echo -e "${RED}[FAIL]${NC} $test_name"
  echo -e "       Reason: $reason"
  ((TESTS_FAILED++))
  FAILED_TESTS+=("$test_name: $reason")
}

assert_pattern_exists() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if grep -q "$pattern" "$file"; then
    return 0
  else
    return 1
  fi
}

assert_pattern_count() {
  local file="$1"
  local pattern="$2"
  local min_count="$3"
  local description="$4"

  local actual_count
  actual_count=$(grep -c "$pattern" "$file" || echo "0")

  if [ "$actual_count" -ge "$min_count" ]; then
    return 0
  else
    echo "Expected ≥$min_count, found $actual_count"
    return 1
  fi
}

#=============================================================================
# Command Enforcement Tests
#=============================================================================

# Test CE-1: Path Pre-Calculation Pattern
test_ce1_path_precalculation() {
  local command_file="$1"
  local test_name="CE-1: Path Pre-Calculation"

  test_start "$test_name"

  # Check for "EXECUTE NOW" with path calculation
  if assert_pattern_exists "$command_file" "EXECUTE NOW.*[Pp]ath" "Path pre-calculation marker"; then
    # Check for actual path calculation code
    if assert_pattern_exists "$command_file" "PATH=\|_PATH=\|calculate.*path" "Path calculation code"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "EXECUTE NOW marker present but no path calculation code found"
      return 1
    fi
  else
    # Not all commands need this pattern (e.g., read-only commands)
    # Check if command invokes agents
    if grep -q "Task {" "$command_file"; then
      test_fail "$test_name" "Command invokes agents but lacks path pre-calculation"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Command doesn't invoke agents, path pre-calculation not required"
      return 0
    fi
  fi
}

# Test CE-2: Mandatory Verification Checkpoints
test_ce2_verification_checkpoints() {
  local command_file="$1"
  local test_name="CE-2: Mandatory Verification Checkpoints"

  test_start "$test_name"

  # Check for "MANDATORY VERIFICATION" markers
  if assert_pattern_exists "$command_file" "MANDATORY VERIFICATION" "Verification checkpoint marker"; then
    # Check for file existence verification
    if assert_pattern_exists "$command_file" "\[ ! -f \|test -f" "File existence check"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "MANDATORY VERIFICATION marker present but no file existence check"
      return 1
    fi
  else
    # Check if command creates or depends on files
    if grep -q "Task {\|Write\|create.*file" "$command_file"; then
      test_fail "$test_name" "Command creates/uses files but lacks mandatory verification"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Command doesn't create/depend on files, verification not required"
      return 0
    fi
  fi
}

# Test CE-3: Fallback Mechanisms
test_ce3_fallback_mechanisms() {
  local command_file="$1"
  local test_name="CE-3: Fallback Mechanisms"

  test_start "$test_name"

  # Check for fallback creation patterns
  if grep -q "Task {" "$command_file"; then
    # Command invokes agents, should have fallback
    if assert_pattern_exists "$command_file" "fallback\|Fallback" "Fallback marker"; then
      # Check for actual fallback code (cat > or similar)
      if assert_pattern_exists "$command_file" "cat >.*<<EOF\|echo.*>" "Fallback creation code"; then
        test_pass "$test_name"
        return 0
      else
        test_fail "$test_name" "Fallback marker present but no fallback creation code"
        return 1
      fi
    else
      test_fail "$test_name" "Command invokes agents but lacks fallback mechanism"
      return 1
    fi
  else
    echo -e "       ${YELLOW}[SKIP]${NC} Command doesn't invoke agents, fallback not required"
    return 0
  fi
}

# Test CE-4: Agent Template Enforcement
test_ce4_agent_template_enforcement() {
  local command_file="$1"
  local test_name="CE-4: Agent Template Enforcement"

  test_start "$test_name"

  if grep -q "Task {" "$command_file"; then
    # Check for "THIS EXACT TEMPLATE" marker
    if assert_pattern_exists "$command_file" "THIS EXACT TEMPLATE" "Agent template enforcement marker"; then
      # Check for "ENFORCEMENT" or "No modifications" warning
      if assert_pattern_exists "$command_file" "ENFORCEMENT:\|No modifications\|Do NOT simplify" "Enforcement warning"; then
        test_pass "$test_name"
        return 0
      else
        test_fail "$test_name" "Template marker present but no enforcement warning"
        return 1
      fi
    else
      test_fail "$test_name" "Command invokes agents but lacks template enforcement marker"
      return 1
    fi
  else
    echo -e "       ${YELLOW}[SKIP]${NC} Command doesn't invoke agents, template enforcement not required"
    return 0
  fi
}

# Test CE-5: Checkpoint Reporting
test_ce5_checkpoint_reporting() {
  local command_file="$1"
  local test_name="CE-5: Checkpoint Reporting"

  test_start "$test_name"

  # Check for "CHECKPOINT REQUIREMENT" or "CHECKPOINT:" blocks
  if assert_pattern_exists "$command_file" "CHECKPOINT REQUIREMENT\|CHECKPOINT:" "Checkpoint marker"; then
    # Check for reporting structure (- items or similar)
    if assert_pattern_exists "$command_file" "complete\|verified" "Checkpoint reporting content"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "Checkpoint marker present but no reporting structure"
      return 1
    fi
  else
    # Complex commands should have checkpoints
    local line_count
    line_count=$(wc -l < "$command_file")
    if [ "$line_count" -gt 500 ]; then
      test_fail "$test_name" "Complex command (>500 lines) lacks checkpoint reporting"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Simple command, checkpoint reporting optional"
      return 0
    fi
  fi
}

# Test CE-6: Imperative Language Usage
test_ce6_imperative_language() {
  local command_file="$1"
  local test_name="CE-6: Imperative Language Usage"

  test_start "$test_name"

  # Check for imperative markers
  local imperative_count
  imperative_count=$(grep -c "YOU MUST\|EXECUTE NOW\|ABSOLUTE REQUIREMENT\|MANDATORY" "$command_file" || echo "0")

  if [ "$imperative_count" -ge 3 ]; then
    # Check that passive voice is minimal
    local passive_count
    passive_count=$(grep -c "should.*create\|may.*verify\|can.*emit" "$command_file" || echo "0")

    if [ "$passive_count" -le "$((imperative_count / 3))" ]; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "Too much passive voice ($passive_count instances) vs imperative ($imperative_count)"
      return 1
    fi
  else
    test_fail "$test_name" "Insufficient imperative language markers (found $imperative_count, need ≥3)"
    return 1
  fi
}

# Test CE-7: Agent Prompt Strengthening
test_ce7_agent_prompt_strengthening() {
  local command_file="$1"
  local test_name="CE-7: Agent Prompt Strengthening"

  test_start "$test_name"

  if grep -q "Task {" "$command_file"; then
    # Check for "ABSOLUTE REQUIREMENT" or "CRITICAL" in agent prompts
    if assert_pattern_exists "$command_file" "ABSOLUTE REQUIREMENT\|CRITICAL:" "Strong directive in agent prompt"; then
      # Check for explicit "DO NOT" anti-patterns
      if assert_pattern_exists "$command_file" "DO NOT.*return\|DO NOT.*summary" "Anti-pattern directive"; then
        test_pass "$test_name"
        return 0
      else
        test_fail "$test_name" "Strong directive present but no anti-pattern warning"
        return 1
      fi
    else
      test_fail "$test_name" "Agent invocations lack strong directives (ABSOLUTE REQUIREMENT, CRITICAL)"
      return 1
    fi
  else
    echo -e "       ${YELLOW}[SKIP]${NC} Command doesn't invoke agents"
    return 0
  fi
}

# Test CE-8: WHY THIS MATTERS Context
test_ce8_why_this_matters() {
  local command_file="$1"
  local test_name="CE-8: WHY THIS MATTERS Context"

  test_start "$test_name"

  # Check for "WHY THIS MATTERS" sections
  local why_count
  why_count=$(grep -c "WHY THIS MATTERS\|GUARANTEE\|CONSEQUENCE" "$command_file" || echo "0")

  if [ "$why_count" -ge 1 ]; then
    test_pass "$test_name"
    return 0
  else
    # Complex commands should explain rationale
    local line_count
    line_count=$(wc -l < "$command_file")
    if [ "$line_count" -gt 300 ]; then
      test_fail "$test_name" "Complex command lacks 'WHY THIS MATTERS' context"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Simple command, context optional"
      return 0
    fi
  fi
}

# Test CE-9: Enforcement Score (Automated Audit)
test_ce9_enforcement_score() {
  local command_file="$1"
  local test_name="CE-9: Enforcement Score"

  test_start "$test_name"

  # Use audit script if available
  local audit_script="$CLAUDE_DIR/lib/audit-execution-enforcement.sh"
  if [ -f "$audit_script" ]; then
    local score
    score=$("$audit_script" "$command_file" 2>/dev/null | grep -oP 'Score: \K[0-9]+' || echo "0")

    if [ "$score" -ge 95 ]; then
      test_pass "$test_name (score: $score/100)"
      return 0
    elif [ "$score" -ge 85 ]; then
      echo -e "       ${YELLOW}[WARN]${NC} Score $score/100 is acceptable but below target (95+)"
      test_pass "$test_name (score: $score/100, below target)"
      return 0
    else
      test_fail "$test_name" "Score $score/100 is below minimum threshold (85)"
      return 1
    fi
  else
    echo -e "       ${YELLOW}[SKIP]${NC} Audit script not found, manual scoring needed"
    return 0
  fi
}

# Test CE-10: Regression Check (Command Still Functional)
test_ce10_regression_check() {
  local command_file="$1"
  local test_name="CE-10: Regression Check"

  test_start "$test_name"

  # Check that enforcement hasn't broken basic structure
  local required_sections=("## Workflow" "## Usage")
  local missing_sections=()

  for section in "${required_sections[@]}"; do
    if ! grep -q "$section" "$command_file"; then
      missing_sections+=("$section")
    fi
  done

  if [ "${#missing_sections[@]}" -eq 0 ]; then
    test_pass "$test_name"
    return 0
  else
    test_fail "$test_name" "Missing required sections: ${missing_sections[*]}"
    return 1
  fi
}

#=============================================================================
# Test Runner
#=============================================================================

run_command_tests() {
  local command_file="$1"
  local command_name
  command_name=$(basename "$command_file" .md)

  echo ""
  echo "========================================================================================================="
  echo "Testing Command: $command_name"
  echo "File: $command_file"
  echo "========================================================================================================="
  echo ""

  # Run all tests
  test_ce1_path_precalculation "$command_file"
  test_ce2_verification_checkpoints "$command_file"
  test_ce3_fallback_mechanisms "$command_file"
  test_ce4_agent_template_enforcement "$command_file"
  test_ce5_checkpoint_reporting "$command_file"
  test_ce6_imperative_language "$command_file"
  test_ce7_agent_prompt_strengthening "$command_file"
  test_ce8_why_this_matters "$command_file"
  test_ce9_enforcement_score "$command_file"
  test_ce10_regression_check "$command_file"

  echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
  echo "========================================================================================================="
  echo "Command Execution Enforcement Test Suite"
  echo "Standard 0 (Execution Enforcement) Validation"
  echo "========================================================================================================="
  echo ""

  # Determine which commands to test
  local commands_to_test=()

  if [ "$#" -eq 0 ]; then
    # Test priority commands by default
    commands_to_test=(
      "$COMMANDS_DIR/orchestrate.md"
      "$COMMANDS_DIR/implement.md"
      "$COMMANDS_DIR/plan.md"
      "$COMMANDS_DIR/expand.md"
      "$COMMANDS_DIR/debug.md"
      "$COMMANDS_DIR/document.md"
    )
    echo "Testing priority commands: orchestrate, implement, plan, expand, debug, document"
  else
    # Test specified command
    local command_name="$1"
    if [ -f "$COMMANDS_DIR/$command_name.md" ]; then
      commands_to_test=("$COMMANDS_DIR/$command_name.md")
      echo "Testing command: $command_name"
    elif [ -f "$command_name" ]; then
      commands_to_test=("$command_name")
      echo "Testing file: $command_name"
    else
      echo "Error: Command not found: $command_name"
      echo "Usage: $0 [command-name]"
      exit 2
    fi
  fi

  # Run tests for each command
  for command_file in "${commands_to_test[@]}"; do
    if [ -f "$command_file" ]; then
      run_command_tests "$command_file"
    else
      echo "Warning: Command file not found: $command_file"
    fi
  done

  # Print summary
  echo "========================================================================================================="
  echo "Test Summary"
  echo "========================================================================================================="
  echo "Total tests run: $TESTS_RUN"
  echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
  echo ""

  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo "Failed tests:"
    for failed_test in "${FAILED_TESTS[@]}"; do
      echo -e "  ${RED}✗${NC} $failed_test"
    done
    echo ""
    echo "Coverage: $((TESTS_PASSED * 100 / TESTS_RUN))%"
    exit 1
  else
    echo -e "${GREEN}All tests passed! ✓${NC}"
    echo "Coverage: 100%"
    exit 0
  fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
