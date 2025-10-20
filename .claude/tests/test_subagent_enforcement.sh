#!/bin/bash
# Test Suite: Subagent Prompt Execution Enforcement
#
# Tests that subagent files follow Standard 0.5 (Subagent Prompt Enforcement)
# for reliable file creation, sequential dependencies, and imperative language.
#
# Usage: ./test_subagent_enforcement.sh [agent-name]
#   - If agent-name provided: Test that specific agent
#   - If no args: Test all priority agents
#
# Exit codes:
#   0 = All tests passed
#   1 = One or more tests failed
#   2 = Usage error

set -euo pipefail

# Test configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
AGENTS_DIR="$CLAUDE_DIR/agents"

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
# Subagent Enforcement Tests
#=============================================================================

# Test SA-1: Imperative Language (Pattern A)
test_sa1_imperative_language() {
  local agent_file="$1"
  local test_name="SA-1: Imperative Language"

  test_start "$test_name"

  # Check for "YOU MUST" directives (minimum 3)
  local must_count
  must_count=$(grep -c "YOU MUST\|YOU WILL\|YOU SHALL" "$agent_file" || echo "0")

  if [ "$must_count" -ge 3 ]; then
    # Check that "I am" declarations are minimal or absent
    local i_am_count
    i_am_count=$(grep -c "I am\|My role is" "$agent_file" || echo "0")

    if [ "$i_am_count" -le 1 ]; then
      test_pass "$test_name ($must_count imperatives, $i_am_count descriptive)"
      return 0
    else
      test_fail "$test_name" "Too many 'I am' declarations ($i_am_count) - should use 'YOU MUST' instead"
      return 1
    fi
  else
    test_fail "$test_name" "Insufficient imperative language ($must_count instances, need ≥3)"
    return 1
  fi
}

# Test SA-2: Sequential Step Dependencies (Pattern B)
test_sa2_sequential_dependencies() {
  local agent_file="$1"
  local test_name="SA-2: Sequential Step Dependencies"

  test_start "$test_name"

  # Check for "STEP N (REQUIRED BEFORE STEP N+1)" pattern
  if assert_pattern_exists "$agent_file" "STEP [0-9].*REQUIRED BEFORE" "Sequential step marker"; then
    # Count how many steps have dependencies
    local step_count
    step_count=$(grep -c "STEP [0-9].*REQUIRED BEFORE" "$agent_file" || echo "0")

    if [ "$step_count" -ge 2 ]; then
      test_pass "$test_name ($step_count sequential dependencies)"
      return 0
    else
      test_fail "$test_name" "Only $step_count sequential dependency found, need ≥2"
      return 1
    fi
  else
    test_fail "$test_name" "No sequential step dependencies found (STEP N REQUIRED BEFORE STEP N+1)"
    return 1
  fi
}

# Test SA-3: File Creation Priority (Pattern C)
test_sa3_file_creation_priority() {
  local agent_file="$1"
  local test_name="SA-3: File Creation Priority"

  test_start "$test_name"

  # Check if agent creates files
  if grep -q "Write\|create.*file\|report\|plan" "$agent_file"; then
    # Check for PRIMARY OBLIGATION or ABSOLUTE REQUIREMENT
    if assert_pattern_exists "$agent_file" "PRIMARY OBLIGATION\|ABSOLUTE REQUIREMENT" "File creation priority marker"; then
      # Check for explicit ordering (file creation FIRST)
      if assert_pattern_exists "$agent_file" "FIRST:\|PRIMARY.*file\|CREATE FILE.*first" "Priority ordering"; then
        test_pass "$test_name"
        return 0
      else
        test_fail "$test_name" "File creation marked as requirement but not prioritized as FIRST task"
        return 1
      fi
    else
      test_fail "$test_name" "Agent creates files but lacks PRIMARY OBLIGATION marker"
      return 1
    fi
  else
    echo -e "       ${YELLOW}[SKIP]${NC} Agent doesn't create files, priority not required"
    return 0
  fi
}

# Test SA-4: Verification Checkpoints (Pattern B)
test_sa4_verification_checkpoints() {
  local agent_file="$1"
  local test_name="SA-4: Verification Checkpoints"

  test_start "$test_name"

  # Check for "MANDATORY VERIFICATION" blocks
  if assert_pattern_exists "$agent_file" "MANDATORY VERIFICATION" "Verification checkpoint marker"; then
    # Check for actual verification code (test -f or similar)
    if assert_pattern_exists "$agent_file" "test -f\|\\[ ! -f\|verify\|check" "Verification code"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "MANDATORY VERIFICATION marker present but no verification code"
      return 1
    fi
  else
    # Agents that create files should have verification
    if grep -q "Write\|create.*file" "$agent_file"; then
      test_fail "$test_name" "Agent creates files but lacks MANDATORY VERIFICATION"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Agent doesn't create files, verification optional"
      return 0
    fi
  fi
}

# Test SA-5: Template Enforcement (Pattern E)
test_sa5_template_enforcement() {
  local agent_file="$1"
  local test_name="SA-5: Template Enforcement"

  test_start "$test_name"

  # Check for "THIS EXACT TEMPLATE" markers
  if assert_pattern_exists "$agent_file" "THIS EXACT TEMPLATE\|OUTPUT FORMAT.*EXACT" "Template enforcement marker"; then
    # Check for REQUIRED/MANDATORY section markers
    if assert_pattern_exists "$agent_file" "REQUIRED\|MANDATORY.*section" "Required section markers"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "Template marked as exact but sections not marked REQUIRED/MANDATORY"
      return 1
    fi
  else
    # Agents with structured output should have templates
    if grep -q "report\|plan\|documentation" "$agent_file"; then
      test_fail "$test_name" "Agent produces structured output but lacks template enforcement"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Agent doesn't produce structured output, template optional"
      return 0
    fi
  fi
}

# Test SA-6: Passive Voice Elimination (Pattern D)
test_sa6_passive_voice_elimination() {
  local agent_file="$1"
  local test_name="SA-6: Passive Voice Elimination"

  test_start "$test_name"

  # Count passive voice instances
  local passive_count
  passive_count=$(grep -c "should create\|may verify\|can emit\|consider adding\|try to" "$agent_file" || echo "0")

  # Count imperative instances
  local imperative_count
  imperative_count=$(grep -c "MUST create\|WILL verify\|SHALL emit\|MUST add" "$agent_file" || echo "0")

  # Ratio check: passive should be <25% of imperative
  if [ "$imperative_count" -gt 0 ]; then
    local max_passive=$((imperative_count / 4))
    if [ "$passive_count" -le "$max_passive" ]; then
      test_pass "$test_name ($passive_count passive vs $imperative_count imperative)"
      return 0
    else
      test_fail "$test_name" "Too much passive voice ($passive_count instances vs $imperative_count imperative)"
      return 1
    fi
  else
    test_fail "$test_name" "No imperative language found"
    return 1
  fi
}

# Test SA-7: Completion Criteria
test_sa7_completion_criteria() {
  local agent_file="$1"
  local test_name="SA-7: Completion Criteria"

  test_start "$test_name"

  # Check for "COMPLETION CRITERIA" or "ALL REQUIRED" section
  if assert_pattern_exists "$agent_file" "COMPLETION CRITERIA\|ALL REQUIRED" "Completion criteria marker"; then
    # Check for checklist format
    if assert_pattern_exists "$agent_file" "\\[ \\]\\|\\[x\\]" "Checklist format"; then
      # Check for NON-COMPLIANCE or UNACCEPTABLE consequence
      if assert_pattern_exists "$agent_file" "NON-COMPLIANCE\|UNACCEPTABLE" "Consequence warning"; then
        test_pass "$test_name"
        return 0
      else
        test_fail "$test_name" "Completion criteria present but no consequence warning"
        return 1
      fi
    else
      test_fail "$test_name" "Completion criteria present but not in checklist format"
      return 1
    fi
  else
    test_fail "$test_name" "No explicit completion criteria (COMPLETION CRITERIA - ALL REQUIRED)"
    return 1
  fi
}

# Test SA-8: WHY THIS MATTERS Context
test_sa8_why_this_matters() {
  local agent_file="$1"
  local test_name="SA-8: WHY THIS MATTERS Context"

  test_start "$test_name"

  # Check for "WHY THIS MATTERS" sections
  local why_count
  why_count=$(grep -c "WHY THIS MATTERS\|CONSEQUENCE OF NON-COMPLIANCE" "$agent_file" || echo "0")

  if [ "$why_count" -ge 1 ]; then
    test_pass "$test_name ($why_count context sections)"
    return 0
  else
    test_fail "$test_name" "No 'WHY THIS MATTERS' context found"
    return 1
  fi
}

# Test SA-9: Checkpoint Reporting
test_sa9_checkpoint_reporting() {
  local agent_file="$1"
  local test_name="SA-9: Checkpoint Reporting"

  test_start "$test_name"

  # Check for "CHECKPOINT REQUIREMENT" or "CHECKPOINT:" markers
  if assert_pattern_exists "$agent_file" "CHECKPOINT REQUIREMENT\|CHECKPOINT:" "Checkpoint marker"; then
    # Check for emission/reporting directive
    if assert_pattern_exists "$agent_file" "Emit\|Report\|EMIT\|report this" "Reporting directive"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "Checkpoint marker present but no emission directive"
      return 1
    fi
  else
    # Complex agents should have checkpoints
    local line_count
    line_count=$(wc -l < "$agent_file")
    if [ "$line_count" -gt 200 ]; then
      test_fail "$test_name" "Complex agent (>200 lines) lacks checkpoint reporting"
      return 1
    else
      echo -e "       ${YELLOW}[SKIP]${NC} Simple agent, checkpoint reporting optional"
      return 0
    fi
  fi
}

# Test SA-10: Fallback Integration Compatibility
test_sa10_fallback_compatibility() {
  local agent_file="$1"
  local test_name="SA-10: Fallback Integration"

  test_start "$test_name"

  # If agent creates files, it should document return format for fallback
  if grep -q "Write\|create.*file" "$agent_file"; then
    # Check for explicit return format ("Return ONLY:" or similar)
    if assert_pattern_exists "$agent_file" "Return ONLY:\|RETURN FORMAT:\|output format" "Return format specification"; then
      test_pass "$test_name"
      return 0
    else
      test_fail "$test_name" "Agent creates files but doesn't specify return format for fallback"
      return 1
    fi
  else
    echo -e "       ${YELLOW}[SKIP]${NC} Agent doesn't create files, fallback compatibility not applicable"
    return 0
  fi
}

# Test SA-11: Enforcement Score (Automated Audit)
test_sa11_enforcement_score() {
  local agent_file="$1"
  local test_name="SA-11: Enforcement Score"

  test_start "$test_name"

  # Use audit script if available
  local audit_script="$CLAUDE_DIR/lib/audit-execution-enforcement.sh"
  if [ -f "$audit_script" ]; then
    local score
    score=$("$audit_script" "$agent_file" 2>/dev/null | grep -oP 'Score: \K[0-9]+' || echo "0")

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

# Test SA-12: Behavioral Injection Compatibility
test_sa12_behavioral_injection() {
  local agent_file="$1"
  local test_name="SA-12: Behavioral Injection"

  test_start "$test_name"

  # Agent files should be structured for behavioral injection
  # Check for clear sections that commands can reference
  local required_sections=("## STEP\|## Process\|## Workflow" "## Output\|## Expected Output\|## Deliverables")
  local missing_sections=()

  for section_pattern in "${required_sections[@]}"; do
    if ! grep -qE "$section_pattern" "$agent_file"; then
      missing_sections+=("$section_pattern")
    fi
  done

  if [ "${#missing_sections[@]}" -eq 0 ]; then
    test_pass "$test_name"
    return 0
  else
    test_fail "$test_name" "Missing sections for behavioral injection: ${missing_sections[*]}"
    return 1
  fi
}

#=============================================================================
# Test Runner
#=============================================================================

run_agent_tests() {
  local agent_file="$1"
  local agent_name
  agent_name=$(basename "$agent_file" .md)

  echo ""
  echo "========================================================================================================="
  echo "Testing Agent: $agent_name"
  echo "File: $agent_file"
  echo "========================================================================================================="
  echo ""

  # Run all tests
  test_sa1_imperative_language "$agent_file"
  test_sa2_sequential_dependencies "$agent_file"
  test_sa3_file_creation_priority "$agent_file"
  test_sa4_verification_checkpoints "$agent_file"
  test_sa5_template_enforcement "$agent_file"
  test_sa6_passive_voice_elimination "$agent_file"
  test_sa7_completion_criteria "$agent_file"
  test_sa8_why_this_matters "$agent_file"
  test_sa9_checkpoint_reporting "$agent_file"
  test_sa10_fallback_compatibility "$agent_file"
  test_sa11_enforcement_score "$agent_file"
  test_sa12_behavioral_injection "$agent_file"

  echo ""
}

#=============================================================================
# Main
#=============================================================================

main() {
  echo "========================================================================================================="
  echo "Subagent Prompt Execution Enforcement Test Suite"
  echo "Standard 0.5 (Subagent Prompt Enforcement) Validation"
  echo "========================================================================================================="
  echo ""

  # Determine which agents to test
  local agents_to_test=()

  if [ "$#" -eq 0 ]; then
    # Test priority agents by default
    agents_to_test=(
      "$AGENTS_DIR/research-specialist.md"
      "$AGENTS_DIR/plan-architect.md"
      "$AGENTS_DIR/code-writer.md"
      "$AGENTS_DIR/spec-updater.md"
      "$AGENTS_DIR/implementation-researcher.md"
      "$AGENTS_DIR/debug-analyst.md"
    )
    echo "Testing priority agents: research-specialist, plan-architect, code-writer, spec-updater, implementation-researcher, debug-analyst"
  else
    # Test specified agent
    local agent_name="$1"
    if [ -f "$AGENTS_DIR/$agent_name.md" ]; then
      agents_to_test=("$AGENTS_DIR/$agent_name.md")
      echo "Testing agent: $agent_name"
    elif [ -f "$agent_name" ]; then
      agents_to_test=("$agent_name")
      echo "Testing file: $agent_name"
    else
      echo "Error: Agent not found: $agent_name"
      echo "Usage: $0 [agent-name]"
      exit 2
    fi
  fi

  # Run tests for each agent
  for agent_file in "${agents_to_test[@]}"; do
    if [ -f "$agent_file" ]; then
      run_agent_tests "$agent_file"
    else
      echo "Warning: Agent file not found: $agent_file"
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
