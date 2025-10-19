#!/bin/bash

# Test suite for /orchestrate artifact creation and delegation
# Part of orchestrate artifact management fixes (Plan 066)

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/artifact-creation.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../lib/metadata-extraction.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../lib/detect-project-dir.sh" 2>/dev/null || true

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function: Run a test
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo ""
  echo "Running test: $test_name"

  if $test_func; then
    echo "  ✓ PASS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ FAIL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Verify EXECUTE NOW block count
test_execute_now_coverage() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  if [ ! -f "$COMMAND_FILE" ]; then
    echo "    ERROR: orchestrate.md not found"
    return 1
  fi

  # Count EXECUTE NOW blocks
  local COUNT=$(grep -c "^\*\*EXECUTE NOW" "$COMMAND_FILE" || echo "0")

  echo "    Found $COUNT EXECUTE NOW blocks (target: ≥15)"

  if [ "$COUNT" -ge 15 ]; then
    return 0
  else
    echo "    ERROR: Only $COUNT blocks, need ≥15"
    return 1
  fi
}

# Test 2: Verify research phase has Task tool patterns
test_research_uses_task_tool() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Search for Task tool patterns in research phase section
  local RESEARCH_SECTION=$(sed -n '/^### Research Phase/,/^### Planning Phase/p' "$COMMAND_FILE")

  # Check for Task invocation mentions
  if echo "$RESEARCH_SECTION" | grep -q "Task tool\|Task {"; then
    echo "    Research phase references Task tool"
    return 0
  else
    echo "    ERROR: Research phase missing Task tool references"
    return 1
  fi
}

# Test 3: Verify planning phase has plan-architect delegation
test_planning_delegates_to_agent() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Search for plan-architect references in planning phase
  local PLANNING_SECTION=$(sed -n '/^### Planning Phase/,/^### Implementation Phase/p' "$COMMAND_FILE")

  # Check for plan-architect agent invocation
  if echo "$PLANNING_SECTION" | grep -q "plan-architect"; then
    echo "    Planning phase references plan-architect agent"
  else
    echo "    ERROR: Planning phase missing plan-architect references"
    return 1
  fi

  # Check for EXECUTE NOW block
  if echo "$PLANNING_SECTION" | grep -q "EXECUTE NOW.*Delegate Planning"; then
    echo "    Planning phase has delegation EXECUTE NOW block"
    return 0
  else
    echo "    ERROR: Planning phase missing delegation EXECUTE NOW block"
    return 1
  fi
}

# Test 4: Verify verification checklists present
test_verification_checklists() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Count verification checklists
  local COUNT=$(grep -c "Verification Checklist" "$COMMAND_FILE" || echo "0")

  echo "    Found $COUNT verification checklists (target: ≥5)"

  if [ "$COUNT" -ge 5 ]; then
    return 0
  else
    echo "    ERROR: Only $COUNT checklists, need ≥5"
    return 1
  fi
}

# Test 5: Verify report path calculation block exists
test_report_path_calculation() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Check for report path calculation EXECUTE NOW block
  if grep -q "EXECUTE NOW.*Calculate Report Paths" "$COMMAND_FILE"; then
    echo "    Report path calculation block found"
  else
    echo "    ERROR: Report path calculation block missing"
    return 1
  fi

  # Check for REPORT_PATHS array usage
  if grep -q 'REPORT_PATHS\[' "$COMMAND_FILE"; then
    echo "    REPORT_PATHS array usage found"
    return 0
  else
    echo "    ERROR: REPORT_PATHS array not used"
    return 1
  fi
}

# Test 6: Verify REPORT_PATH parsing block exists
test_report_path_parsing() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Check for REPORT_PATH parsing EXECUTE NOW block
  if grep -q "EXECUTE NOW.*Parse REPORT_PATH from Agent Outputs" "$COMMAND_FILE"; then
    echo "    REPORT_PATH parsing block found"
  else
    echo "    ERROR: REPORT_PATH parsing block missing"
    return 1
  fi

  # Check for fallback logic
  if grep -q "Using pre-calculated path" "$COMMAND_FILE"; then
    echo "    Fallback logic present"
    return 0
  else
    echo "    ERROR: Fallback logic missing"
    return 1
  fi
}

# Test 7: Verify forward_message integration uses files
test_forward_message_uses_files() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Check for extract_report_metadata usage
  if grep -q "extract_report_metadata" "$COMMAND_FILE"; then
    echo "    extract_report_metadata function used"
  else
    echo "    ERROR: extract_report_metadata not found"
    return 1
  fi

  # Check for context reduction metrics
  if grep -q "Context Reduction Metrics" "$COMMAND_FILE"; then
    echo "    Context reduction metrics present"
    return 0
  else
    echo "    ERROR: Context reduction metrics missing"
    return 1
  fi
}

# Test 8: Verify plan verification block exists
test_plan_verification_block() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Check for plan verification EXECUTE NOW block
  if grep -q "EXECUTE NOW.*Verify Plan File Created" "$COMMAND_FILE"; then
    echo "    Plan verification block found"
  else
    echo "    ERROR: Plan verification block missing"
    return 1
  fi

  # Check for section validation
  if grep -q 'for section in.*Metadata.*Overview' "$COMMAND_FILE"; then
    echo "    Section validation logic present"
    return 0
  else
    echo "    ERROR: Section validation logic missing"
    return 1
  fi
}

# Test 9: Verify inline code examples present
test_inline_code_examples() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Check for topic extraction example
  if grep -q "Example: Extracting Research Topics from Workflow" "$COMMAND_FILE"; then
    echo "    Topic extraction example found"
  else
    echo "    WARNING: Topic extraction example missing"
  fi

  # Check for parallel invocation example
  if grep -q "Parallel Agent Invocation Pattern" "$COMMAND_FILE"; then
    echo "    Parallel invocation pattern found"
  else
    echo "    WARNING: Parallel invocation pattern missing"
  fi

  # Check for Task tool example
  if grep -q "Complete Task Tool Invocation Example" "$COMMAND_FILE"; then
    echo "    Task tool invocation example found"
    return 0
  else
    echo "    WARNING: Task tool example missing"
    return 1
  fi
}

# Test 10: Verify command structure integrity
test_command_structure_integrity() {
  local COMMAND_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/orchestrate.md"

  # Check for all major phase headers
  local required_phases=("Research Phase" "Planning Phase" "Implementation Phase" "Documentation Phase")
  local found_count=0

  for phase in "${required_phases[@]}"; do
    if grep -q "^### $phase" "$COMMAND_FILE"; then
      echo "    Found section: $phase"
      found_count=$((found_count + 1))
    else
      echo "    WARNING: Missing section: $phase"
    fi
  done

  if [ "$found_count" -eq "${#required_phases[@]}" ]; then
    echo "    All required phase sections present"
    return 0
  else
    echo "    ERROR: Only $found_count/${#required_phases[@]} phase sections found"
    return 1
  fi
}

# Main test runner
main() {
  echo "================================================================"
  echo "Orchestrate Artifact Creation Test Suite"
  echo "================================================================"

  # Detect project directory
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    # SCRIPT_DIR is .claude/tests, so go up two levels to project root
    export CLAUDE_PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
    echo "CLAUDE_PROJECT_DIR set to: $CLAUDE_PROJECT_DIR"
  fi

  # Run all tests
  run_test "EXECUTE NOW coverage (≥15 blocks)" test_execute_now_coverage
  run_test "Research phase uses Task tool" test_research_uses_task_tool
  run_test "Planning phase delegates to agent" test_planning_delegates_to_agent
  run_test "Verification checklists present (≥5)" test_verification_checklists
  run_test "Report path calculation block" test_report_path_calculation
  run_test "REPORT_PATH parsing block" test_report_path_parsing
  run_test "Forward message uses files" test_forward_message_uses_files
  run_test "Plan verification block" test_plan_verification_block
  run_test "Inline code examples" test_inline_code_examples
  run_test "Command structure integrity" test_command_structure_integrity

  # Summary
  echo ""
  echo "================================================================"
  echo "Test Results Summary"
  echo "================================================================"
  echo "Tests run:    $TESTS_RUN"
  echo "Tests passed: $TESTS_PASSED"
  echo "Tests failed: $TESTS_FAILED"
  echo ""

  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo "✓ All tests passed!"
    return 0
  else
    echo "✗ Some tests failed"
    return 1
  fi
}

# Run tests
main "$@"
