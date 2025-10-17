#!/bin/bash

# Validation script for /orchestrate command structure
# Part of orchestrate artifact management fixes (Plan 066)
#
# Usage: ./validate-orchestrate.sh
# Exit codes: 0 = all validations passed, 1 = validation failures

set -euo pipefail

# Detect project directory
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # SCRIPT_DIR is .claude/lib, so go up two levels to project root
  export CLAUDE_PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
fi

COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  NC='\033[0m' # No Color
else
  GREEN=''
  RED=''
  YELLOW=''
  NC=''
fi

# Validation counters
VALIDATIONS_RUN=0
VALIDATIONS_PASSED=0
VALIDATIONS_FAILED=0
WARNINGS=0

# Helper: Run validation check
validate() {
  local check_name="$1"
  local check_func="$2"

  VALIDATIONS_RUN=$((VALIDATIONS_RUN + 1))
  echo ""
  echo "Validation: $check_name"

  if $check_func; then
    echo -e "  ${GREEN}✓${NC} PASS"
    VALIDATIONS_PASSED=$((VALIDATIONS_PASSED + 1))
    return 0
  else
    echo -e "  ${RED}✗${NC} FAIL"
    VALIDATIONS_FAILED=$((VALIDATIONS_FAILED + 1))
    return 1
  fi
}

# Helper: Issue warning
warn() {
  local message="$1"
  echo -e "  ${YELLOW}⚠${NC}  WARNING: $message"
  WARNINGS=$((WARNINGS + 1))
}

# Validation 1: Check EXECUTE NOW block count
check_execute_now_count() {
  local execute_count=$(grep -c "^\*\*EXECUTE NOW" "$COMMAND_FILE" || echo "0")

  echo "  Found $execute_count EXECUTE NOW blocks"

  if [ "$execute_count" -ge 15 ]; then
    echo "  Target met: ≥15 blocks"
    return 0
  else
    echo "  ERROR: Only $execute_count EXECUTE NOW blocks (need ≥15)"
    return 1
  fi
}

# Validation 2: Check research phase Task tool usage
check_research_task_tool() {
  # Extract research phase section and count Task tool references
  local task_research=$(sed -n '/^### Research Phase/,/^### Planning Phase/p' "$COMMAND_FILE" | grep -E "Task tool|Task \{" | wc -l || echo "0")

  echo "  Found $task_research Task tool references in research phase"

  if [ "$task_research" -gt 0 ]; then
    echo "  Research phase uses Task tool"
    return 0
  else
    echo "  ERROR: Research phase missing Task tool usage"
    return 1
  fi
}

# Validation 3: Check planning phase plan-architect delegation
check_planning_delegation() {
  # Extract planning phase section and count plan-architect references
  local task_planning=$(sed -n '/^### Planning Phase/,/^### Implementation Phase/p' "$COMMAND_FILE" | grep "plan-architect" | wc -l || echo "0")

  echo "  Found $task_planning plan-architect references in planning phase"

  if [ "$task_planning" -gt 0 ]; then
    echo "  Planning phase uses plan-architect delegation"
  else
    echo "  ERROR: Planning phase missing plan-architect delegation"
    return 1
  fi

  # Check for EXECUTE NOW delegation block
  if grep -q "EXECUTE NOW.*Delegate Planning to plan-architect" "$COMMAND_FILE"; then
    echo "  Planning delegation EXECUTE NOW block present"
    return 0
  else
    echo "  ERROR: Planning delegation EXECUTE NOW block missing"
    return 1
  fi
}

# Validation 4: Check verification checklists
check_verification_checklists() {
  local verify_count=$(grep -c "Verification Checklist" "$COMMAND_FILE" || echo "0")

  echo "  Found $verify_count verification checklists"

  if [ "$verify_count" -ge 5 ]; then
    echo "  Target met: ≥5 checklists"
    return 0
  else
    echo "  ERROR: Only $verify_count verification checklists (need ≥5)"
    return 1
  fi
}

# Validation 5: Check critical artifact management blocks
check_artifact_management_blocks() {
  local required_blocks=(
    "Calculate Report Paths"
    "Parse REPORT_PATH from Agent Outputs"
    "Verify Report File Creation"
    "Extract Metadata from Report Files"
    "Verify Plan File Created"
  )

  local found_count=0

  for block in "${required_blocks[@]}"; do
    if grep -q "EXECUTE NOW.*$block" "$COMMAND_FILE"; then
      echo "  ✓ Found: $block"
      found_count=$((found_count + 1))
    else
      warn "Missing EXECUTE NOW block: $block"
    fi
  done

  if [ "$found_count" -eq "${#required_blocks[@]}" ]; then
    echo "  All critical artifact management blocks present"
    return 0
  else
    echo "  ERROR: Only $found_count/${#required_blocks[@]} critical blocks found"
    return 1
  fi
}

# Validation 6: Check inline code examples
check_inline_examples() {
  local examples=(
    "Example: Extracting Research Topics from Workflow"
    "Parallel Agent Invocation Pattern"
    "Complete Task Tool Invocation Example"
  )

  local found_count=0

  for example in "${examples[@]}"; do
    if grep -q "$example" "$COMMAND_FILE"; then
      echo "  ✓ Found: $example"
      found_count=$((found_count + 1))
    else
      warn "Missing example: $example"
    fi
  done

  if [ "$found_count" -ge 2 ]; then
    echo "  Sufficient inline examples present ($found_count/3)"
    return 0
  else
    echo "  ERROR: Only $found_count/3 inline examples found"
    return 1
  fi
}

# Validation 7: Check for file-based metadata extraction
check_file_based_extraction() {
  # Check for extract_report_metadata usage
  if grep -q "extract_report_metadata" "$COMMAND_FILE"; then
    echo "  ✓ extract_report_metadata function used"
  else
    echo "  ERROR: extract_report_metadata function not found"
    return 1
  fi

  # Check for context reduction metrics
  if grep -q "Context Reduction Metrics" "$COMMAND_FILE"; then
    echo "  ✓ Context reduction metrics present"
  else
    warn "Context reduction metrics missing"
  fi

  # Check for 92% reduction target
  if grep -q "92%" "$COMMAND_FILE"; then
    echo "  ✓ 92% reduction target mentioned"
    return 0
  else
    warn "92% reduction target not explicitly mentioned"
    return 0  # Warning only, not a failure
  fi
}

# Validation 8: Check command structure integrity
check_structure_integrity() {
  local required_sections=(
    "### Research Phase"
    "### Planning Phase"
    "### Implementation Phase"
    "### Documentation Phase"
  )

  local found_count=0

  for section in "${required_sections[@]}"; do
    if grep -q "^$section" "$COMMAND_FILE"; then
      echo "  ✓ Section present: $section"
      found_count=$((found_count + 1))
    else
      echo "  ERROR: Missing section: $section"
    fi
  done

  if [ "$found_count" -eq "${#required_sections[@]}" ]; then
    echo "  All required sections present"
    return 0
  else
    echo "  ERROR: Only $found_count/${#required_sections[@]} sections found"
    return 1
  fi
}

# Validation 9: Check for agent behavioral guidelines references
check_agent_guidelines() {
  local agent_files=(
    "research-specialist.md"
    "plan-architect.md"
  )

  local found_count=0

  for agent_file in "${agent_files[@]}"; do
    if grep -q "$agent_file" "$COMMAND_FILE"; then
      echo "  ✓ References: $agent_file"
      found_count=$((found_count + 1))
    else
      warn "Missing reference to: $agent_file"
    fi
  done

  if [ "$found_count" -ge 1 ]; then
    echo "  Agent behavioral guidelines referenced"
    return 0
  else
    echo "  ERROR: No agent behavioral guideline references found"
    return 1
  fi
}

# Validation 10: Check for failure handling patterns
check_failure_handling() {
  # Check for error handling examples
  if grep -q "Failure Handling\|ERROR:" "$COMMAND_FILE"; then
    echo "  ✓ Error handling patterns present"
  else
    warn "Error handling patterns not found"
  fi

  # Check for exit codes
  if grep -q "exit 1" "$COMMAND_FILE"; then
    echo "  ✓ Exit codes used for failures"
    return 0
  else
    warn "No explicit exit codes found"
    return 0  # Warning only
  fi
}

# Main validation runner
main() {
  echo "================================================================"
  echo "Orchestrate Command Validation"
  echo "================================================================"
  echo ""
  echo "Command file: $COMMAND_FILE"

  if [ ! -f "$COMMAND_FILE" ]; then
    echo -e "${RED}ERROR:${NC} orchestrate.md not found at $COMMAND_FILE"
    exit 1
  fi

  # Run all validations
  validate "EXECUTE NOW block count (≥15)" check_execute_now_count
  validate "Research phase Task tool usage" check_research_task_tool
  validate "Planning phase delegation" check_planning_delegation
  validate "Verification checklists (≥5)" check_verification_checklists
  validate "Critical artifact management blocks" check_artifact_management_blocks
  validate "Inline code examples" check_inline_examples
  validate "File-based metadata extraction" check_file_based_extraction
  validate "Command structure integrity" check_structure_integrity
  validate "Agent behavioral guideline references" check_agent_guidelines
  validate "Failure handling patterns" check_failure_handling

  # Summary
  echo ""
  echo "================================================================"
  echo "Validation Summary"
  echo "================================================================"
  echo "Validations run:    $VALIDATIONS_RUN"
  echo -e "Validations passed: ${GREEN}$VALIDATIONS_PASSED${NC}"
  echo -e "Validations failed: ${RED}$VALIDATIONS_FAILED${NC}"
  echo -e "Warnings:          ${YELLOW}$WARNINGS${NC}"
  echo ""

  if [ "$VALIDATIONS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed!${NC}"
    if [ "$WARNINGS" -gt 0 ]; then
      echo -e "${YELLOW}⚠${NC}  $WARNINGS warning(s) issued (non-critical)"
    fi
    return 0
  else
    echo -e "${RED}✗ Validation failed${NC}"
    echo "  Please address the issues above before proceeding"
    return 1
  fi
}

# Run validations
main "$@"
