#!/usr/bin/env bash
# test_repair_workflow.sh - Unit tests for /repair command workflow
# Coverage target: >80%

set -euo pipefail

# Get script directory
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
CLAUDE_ROOT="${CLAUDE_PROJECT_DIR}/.claude"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test utilities
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 1: Verify repair-analyst agent file structure
test_repair_analyst_structure() {
  local test_name="repair-analyst agent file structure"

  local agent_file="${CLAUDE_ROOT}/agents/repair-analyst.md"

  if [[ ! -f "$agent_file" ]]; then
    fail "$test_name" "Agent file not found: $agent_file"
    return
  fi

  # Check for required sections
  local has_frontmatter=false
  local has_step1=false
  local has_step2=false
  local has_step3=false
  local has_step4=false
  local has_completion_criteria=false

  if grep -q "^---" "$agent_file" && grep -q "allowed-tools:" "$agent_file"; then
    has_frontmatter=true
  fi

  if grep -q "STEP 1" "$agent_file"; then has_step1=true; fi
  if grep -q "STEP 2" "$agent_file"; then has_step2=true; fi
  if grep -q "STEP 3" "$agent_file"; then has_step3=true; fi
  if grep -q "STEP 4" "$agent_file"; then has_step4=true; fi
  if grep -q "COMPLETION CRITERIA" "$agent_file"; then has_completion_criteria=true; fi

  if [[ "$has_frontmatter" == "true" ]] && \
     [[ "$has_step1" == "true" ]] && \
     [[ "$has_step2" == "true" ]] && \
     [[ "$has_step3" == "true" ]] && \
     [[ "$has_step4" == "true" ]] && \
     [[ "$has_completion_criteria" == "true" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "Missing required sections (frontmatter: $has_frontmatter, steps: $has_step1/$has_step2/$has_step3/$has_step4, criteria: $has_completion_criteria)"
  fi
}

# Test 2: Verify /repair command file structure
test_repair_command_structure() {
  local test_name="/repair command file structure"

  local command_file="${CLAUDE_ROOT}/commands/repair.md"

  if [[ ! -f "$command_file" ]]; then
    fail "$test_name" "Command file not found: $command_file"
    return
  fi

  # Check for required sections
  local has_frontmatter=false
  local has_block1=false
  local has_block2=false
  local has_block3=false
  local has_repair_analyst=false
  local has_plan_architect=false
  local has_set_h=false

  if grep -q "^---" "$command_file" && grep -q "allowed-tools:" "$command_file"; then
    has_frontmatter=true
  fi

  if grep -q "## Block 1: Consolidated Setup" "$command_file"; then has_block1=true; fi
  if grep -q "## Block 2: Research Verification and Planning Setup" "$command_file"; then has_block2=true; fi
  if grep -q "## Block 3: Plan Verification and Completion" "$command_file"; then has_block3=true; fi
  if grep -q "repair-analyst" "$command_file"; then has_repair_analyst=true; fi
  if grep -q "plan-architect" "$command_file"; then has_plan_architect=true; fi
  if grep -q "set +H" "$command_file"; then has_set_h=true; fi

  if [[ "$has_frontmatter" == "true" ]] && \
     [[ "$has_block1" == "true" ]] && \
     [[ "$has_block2" == "true" ]] && \
     [[ "$has_block3" == "true" ]] && \
     [[ "$has_repair_analyst" == "true" ]] && \
     [[ "$has_plan_architect" == "true" ]] && \
     [[ "$has_set_h" == "true" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "Missing required sections"
  fi
}

# Test 3: Verify agent registry entry
test_agent_registry_entry() {
  local test_name="Agent registry contains repair-analyst"

  local registry_file="${CLAUDE_ROOT}/agents/agent-registry.json"

  if [[ ! -f "$registry_file" ]]; then
    fail "$test_name" "Registry file not found: $registry_file"
    return
  fi

  # Check if jq is available
  if ! command -v jq &>/dev/null; then
    fail "$test_name" "jq not available for JSON parsing"
    return
  fi

  # Check for repair-analyst entry
  if jq -e '.agents["repair-analyst"]' "$registry_file" >/dev/null 2>&1; then
    # Verify required fields
    local agent_type=$(jq -r '.agents["repair-analyst"].type' "$registry_file")
    local agent_category=$(jq -r '.agents["repair-analyst"].category' "$registry_file")
    local tools_count=$(jq -r '.agents["repair-analyst"].tools | length' "$registry_file")

    if [[ "$agent_type" == "specialized" ]] && \
       [[ "$agent_category" == "analysis" ]] && \
       [[ "$tools_count" -ge 4 ]]; then
      pass "$test_name"
    else
      fail "$test_name" "Entry exists but fields incorrect (type: $agent_type, category: $agent_category, tools: $tools_count)"
    fi
  else
    fail "$test_name" "repair-analyst entry not found in registry"
  fi
}

# Test 4: Verify agent-reference.md update
test_agent_reference_update() {
  local test_name="Agent reference documentation updated"

  local ref_file="${CLAUDE_ROOT}/docs/reference/standards/agent-reference.md"

  if [[ ! -f "$ref_file" ]]; then
    fail "$test_name" "Reference file not found: $ref_file"
    return
  fi

  if grep -q "### repair-analyst" "$ref_file"; then
    pass "$test_name"
  else
    fail "$test_name" "repair-analyst section not found in agent-reference.md"
  fi
}

# Test 5: Verify command guide documentation
test_command_guide_exists() {
  local test_name="Command guide documentation exists"

  local guide_file="${CLAUDE_ROOT}/docs/guides/commands/repair-command-guide.md"

  if [[ ! -f "$guide_file" ]]; then
    fail "$test_name" "Guide file not found: $guide_file"
    return
  fi

  # Check for key sections
  local has_overview=false
  local has_architecture=false
  local has_examples=false
  local has_filtering=false

  if grep -q "## Overview" "$guide_file"; then has_overview=true; fi
  if grep -q "## Architecture" "$guide_file"; then has_architecture=true; fi
  if grep -q "## Usage Examples" "$guide_file"; then has_examples=true; fi
  if grep -q "## Error Filtering" "$guide_file"; then has_filtering=true; fi

  if [[ "$has_overview" == "true" ]] && \
     [[ "$has_architecture" == "true" ]] && \
     [[ "$has_examples" == "true" ]] && \
     [[ "$has_filtering" == "true" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "Missing required documentation sections"
  fi
}

# Test 6: Behavioral compliance - File Creation Compliance
test_agent_file_creation_compliance() {
  local test_name="Agent has mandatory file creation in STEP 2"

  local agent_file="${CLAUDE_ROOT}/agents/repair-analyst.md"

  if [[ ! -f "$agent_file" ]]; then
    fail "$test_name" "Agent file not found"
    return
  fi

  # Check STEP 2 explicitly requires Write tool usage
  if grep -A 20 "STEP 2" "$agent_file" | grep -q "ABSOLUTE REQUIREMENT"; then
    if grep -A 20 "STEP 2" "$agent_file" | grep -q "Write tool"; then
      pass "$test_name"
    else
      fail "$test_name" "STEP 2 missing Write tool requirement"
    fi
  else
    fail "$test_name" "STEP 2 missing ABSOLUTE REQUIREMENT directive"
  fi
}

# Test 7: Behavioral compliance - Completion Signal Format
test_agent_completion_signal() {
  local test_name="Agent has correct completion signal format"

  local agent_file="${CLAUDE_ROOT}/agents/repair-analyst.md"

  if [[ ! -f "$agent_file" ]]; then
    fail "$test_name" "Agent file not found"
    return
  fi

  # Check for REPORT_CREATED signal
  if grep -q "REPORT_CREATED:" "$agent_file"; then
    pass "$test_name"
  else
    fail "$test_name" "Missing REPORT_CREATED completion signal"
  fi
}

# Test 8: Behavioral compliance - Imperative Language
test_agent_imperative_language() {
  local test_name="Agent uses imperative language throughout"

  local agent_file="${CLAUDE_ROOT}/agents/repair-analyst.md"

  if [[ ! -f "$agent_file" ]]; then
    fail "$test_name" "Agent file not found"
    return
  fi

  # Check for imperative verbs
  local has_execute=false
  local has_verify=false
  local has_must=false

  if grep -qi "execute" "$agent_file"; then has_execute=true; fi
  if grep -qi "verify" "$agent_file"; then has_verify=true; fi
  if grep -qi "MUST" "$agent_file"; then has_must=true; fi

  if [[ "$has_execute" == "true" ]] && \
     [[ "$has_verify" == "true" ]] && \
     [[ "$has_must" == "true" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "Missing imperative language (execute: $has_execute, verify: $has_verify, must: $has_must)"
  fi
}

# Test 9: Command standards - EXECUTE NOW directives
test_command_execute_now_directives() {
  local test_name="Command has EXECUTE NOW directives for all blocks"

  local command_file="${CLAUDE_ROOT}/commands/repair.md"

  if [[ ! -f "$command_file" ]]; then
    fail "$test_name" "Command file not found"
    return
  fi

  # Count EXECUTE NOW directives (should be at least 5: 3 blocks + 2 Task invocations)
  local execute_count=$(grep -c "EXECUTE NOW" "$command_file" || echo "0")

  if [[ "$execute_count" -ge 5 ]]; then
    pass "$test_name"
  else
    fail "$test_name" "Insufficient EXECUTE NOW directives (found $execute_count, expected >=5)"
  fi
}

# Test 10: Command standards - Task invocations without code blocks
test_command_task_invocations() {
  local test_name="Task invocations have no code block wrappers"

  local command_file="${CLAUDE_ROOT}/commands/repair.md"

  if [[ ! -f "$command_file" ]]; then
    fail "$test_name" "Command file not found"
    return
  fi

  # Check Task invocations don't have ```yaml or ``` around them
  # Look for Task { without preceding ```
  local has_proper_task_format=true

  # Extract Task blocks and check for code fence before them
  if grep -B 1 "Task {" "$command_file" | grep -q '```'; then
    has_proper_task_format=false
  fi

  if [[ "$has_proper_task_format" == "true" ]]; then
    pass "$test_name"
  else
    fail "$test_name" "Task invocations wrapped in code blocks"
  fi
}

# Run all tests
echo "Running /repair workflow tests..."
echo "=================================="
echo ""

test_repair_analyst_structure
test_repair_command_structure
test_agent_registry_entry
test_agent_reference_update
test_command_guide_exists
test_agent_file_creation_compliance
test_agent_completion_signal
test_agent_imperative_language
test_command_execute_now_directives
test_command_task_invocations

# Print summary
echo ""
echo "=================================="
echo "Test Summary"
echo "=================================="
echo -e "Tests run:    $TESTS_RUN"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
else
  echo -e "Tests failed: $TESTS_FAILED"
fi
echo ""

# Exit with appropriate code
if [[ $TESTS_FAILED -gt 0 ]]; then
  exit 1
else
  exit 0
fi
