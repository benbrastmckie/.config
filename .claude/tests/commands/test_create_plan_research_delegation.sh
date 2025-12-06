#!/usr/bin/env bash
# Test suite for /create-plan research and planning delegation refactor
# Validates that research-specialist and plan-architect are invoked via Task tool
# Tests hard barrier verification blocks prevent bypass

set -euo pipefail

# === SETUP ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate up to .config directory (project root)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Validate PROJECT_ROOT is correct
if [ ! -d "${PROJECT_ROOT}/.claude" ]; then
  echo "ERROR: Failed to find .claude directory at ${PROJECT_ROOT}" >&2
  exit 1
fi

# Test metadata
TEST_NAME="create-plan-research-delegation"
TEST_DESCRIPTION="Validates /create-plan enforces subagent delegation for research AND planning"

# === TEST UTILITIES ===
cleanup_test_artifacts() {
  local topic_dir="$1"
  if [ -n "$topic_dir" ] && [ -d "$topic_dir" ]; then
    rm -rf "$topic_dir"
  fi
}

# === TEST CASE 1: Simple feature (complexity 1) ===
test_simple_feature_delegation() {
  echo "Test Case 1: Simple feature (complexity 1)"
  echo "Expected: research-specialist invoked via Task tool, plan-architect invoked via Task tool"

  # This test validates the command STRUCTURE, not execution
  # We check that the command file contains proper Task invocation patterns

  local command_file="${PROJECT_ROOT}/commands/create-plan.md"

  # Check for imperative directive pattern in research invocation
  if ! grep -q "^\*\*EXECUTE NOW\*\*: USE the Task tool to invoke the research-specialist agent" "$command_file"; then
    echo "FAIL: Missing imperative directive for research-specialist invocation" >&2
    return 1
  fi

  # Check for imperative directive pattern in planning invocation
  if ! grep -q "^\*\*EXECUTE NOW\*\*: USE the Task tool to invoke the plan-architect agent" "$command_file"; then
    echo "FAIL: Missing imperative directive for plan-architect invocation" >&2
    return 1
  fi

  # Check for DO NOT prohibitions (research)
  if ! grep -q "DO NOT perform research directly" "$command_file"; then
    echo "FAIL: Missing DO NOT prohibition for direct research" >&2
    return 1
  fi

  # Check for DO NOT prohibitions (planning)
  if ! grep -q "DO NOT write the plan file directly" "$command_file"; then
    echo "FAIL: Missing DO NOT prohibition for direct plan writing" >&2
    return 1
  fi

  echo "PASS: Command structure validates proper Task invocation patterns"
  return 0
}

# === TEST CASE 2: Hard barrier validation (research) ===
test_research_hard_barrier() {
  echo "Test Case 2: Research hard barrier validation"
  echo "Expected: Block 1f validates research report exists with proper structure"

  local command_file="${PROJECT_ROOT}/commands/create-plan.md"

  # Check for research setup block (Block 1e)
  if ! grep -q "^## Block 1e: Research Setup and Context Barrier" "$command_file"; then
    echo "FAIL: Missing Block 1e (Research Setup and Context Barrier)" >&2
    return 1
  fi

  # Check for CHECKPOINT in Block 1e
  if ! grep -q "CHECKPOINT: Research setup complete, ready for Task invocation" "$command_file"; then
    echo "FAIL: Missing CHECKPOINT in Block 1e" >&2
    return 1
  fi

  # Check for research verification block (Block 1f)
  if ! grep -q "^## Block 1f: Research Output Verification" "$command_file"; then
    echo "FAIL: Missing Block 1f (Research Output Verification)" >&2
    return 1
  fi

  # Check for hard barrier validation using validate_agent_artifact
  if ! grep -q 'validate_agent_artifact "\$REPORT_PATH"' "$command_file"; then
    echo "FAIL: Missing validate_agent_artifact call in Block 1f" >&2
    return 1
  fi

  # Check for content validation (## Findings section)
  if ! grep -q 'grep -q "\^## Findings" "\$REPORT_PATH"' "$command_file"; then
    echo "FAIL: Missing content validation for ## Findings section" >&2
    return 1
  fi

  echo "PASS: Research hard barrier validation structure correct"
  return 0
}

# === TEST CASE 3: Hard barrier validation (planning) ===
test_planning_hard_barrier() {
  echo "Test Case 3: Planning hard barrier validation"
  echo "Expected: Block 3a validates plan file exists with proper structure"

  local command_file="${PROJECT_ROOT}/commands/create-plan.md"

  # Check for planning setup CHECKPOINT in Block 2
  if ! grep -q "CHECKPOINT: Planning setup complete, ready for Task invocation" "$command_file"; then
    echo "FAIL: Missing CHECKPOINT in Block 2" >&2
    return 1
  fi

  # Check for planning verification block (Block 3a)
  if ! grep -q "^## Block 3a: Planning Output Verification" "$command_file"; then
    echo "FAIL: Missing Block 3a (Planning Output Verification)" >&2
    return 1
  fi

  # Check for hard barrier validation using validate_agent_artifact
  if ! grep -q 'validate_agent_artifact "\$PLAN_PATH"' "$command_file"; then
    echo "FAIL: Missing validate_agent_artifact call in Block 3a" >&2
    return 1
  fi

  # Check for structure validation (## Metadata section)
  if ! grep -q 'grep -q "\^## Metadata" "\$PLAN_PATH"' "$command_file"; then
    echo "FAIL: Missing structure validation for ## Metadata section" >&2
    return 1
  fi

  # Check for structure validation (phase headings)
  if ! grep -q 'grep -q "\^### Phase \[0-9\]" "\$PLAN_PATH"' "$command_file"; then
    echo "FAIL: Missing structure validation for phase headings" >&2
    return 1
  fi

  echo "PASS: Planning hard barrier validation structure correct"
  return 0
}

# === TEST CASE 4: No pseudo-code Task syntax ===
test_no_pseudocode_task_syntax() {
  echo "Test Case 4: Verify no pseudo-code Task { ... } syntax"
  echo "Expected: Command file contains NO pseudo-code Task blocks"

  local command_file="${PROJECT_ROOT}/commands/create-plan.md"

  # Check for prohibited pseudo-code syntax after Block 1e-exec
  # We allow it in documentation/comments, but not as actual invocation pattern
  local pseudocode_count
  pseudocode_count=$(grep -c "^Task {" "$command_file" 2>/dev/null || echo "0")

  if [ "$pseudocode_count" -gt 0 ]; then
    echo "FAIL: Found $pseudocode_count instances of pseudo-code 'Task {' syntax" >&2
    echo "This syntax is interpreted as descriptive text, not actual Task tool invocation" >&2
    return 1
  fi

  echo "PASS: No pseudo-code Task syntax found (uses imperative directives instead)"
  return 0
}

# === TEST CASE 5: Context barrier separation ===
test_context_barrier_separation() {
  echo "Test Case 5: Verify context barriers separate bash blocks from Task invocations"
  echo "Expected: CHECKPOINT messages create barriers before Task invocations"

  local command_file="${PROJECT_ROOT}/commands/create-plan.md"

  # Check Block 1e-exec has CRITICAL BARRIER message
  if ! grep -q "^\*\*CRITICAL BARRIER\*\*: The bash block above MUST complete before proceeding" "$command_file"; then
    echo "FAIL: Missing CRITICAL BARRIER message before research Task invocation" >&2
    return 1
  fi

  # Verify Block 1e-exec comes after Block 1e
  local block_1e_line=$(grep -n "^## Block 1e: Research Setup and Context Barrier" "$command_file" | cut -d':' -f1)
  local block_1e_exec_line=$(grep -n "^## Block 1e-exec: Research Specialist Invocation" "$command_file" | cut -d':' -f1)

  if [ "$block_1e_exec_line" -le "$block_1e_line" ]; then
    echo "FAIL: Block 1e-exec should come after Block 1e" >&2
    return 1
  fi

  # Verify Block 2-exec comes after Block 2
  local block_2_line=$(grep -n "^## Block 2: Research Verification and Planning Setup" "$command_file" | cut -d':' -f1)
  local block_2_exec_line=$(grep -n "^## Block 2-exec: Plan-Architect Invocation" "$command_file" | cut -d':' -f1)

  if [ "$block_2_exec_line" -le "$block_2_line" ]; then
    echo "FAIL: Block 2-exec should come after Block 2" >&2
    return 1
  fi

  echo "PASS: Context barriers properly separate bash blocks from Task invocations"
  return 0
}

# === TEST CASE 6: Pre-calculated paths (Hard Barrier Pattern) ===
test_precalculated_paths() {
  echo "Test Case 6: Verify paths are pre-calculated BEFORE agent invocation"
  echo "Expected: REPORT_PATH and PLAN_PATH calculated in bash blocks, passed to agents"

  local command_file="${PROJECT_ROOT}/commands/create-plan.md"

  # Check REPORT_PATH pre-calculation in Block 1e
  if ! grep -q 'REPORT_PATH="\${RESEARCH_DIR}/\${REPORT_FILENAME}"' "$command_file"; then
    echo "FAIL: Missing REPORT_PATH pre-calculation in Block 1e" >&2
    return 1
  fi

  # Check REPORT_PATH passed to research-specialist
  if ! grep -q "Expected Output Path: \${REPORT_PATH}" "$command_file"; then
    echo "FAIL: REPORT_PATH not passed to research-specialist in Block 1e-exec" >&2
    return 1
  fi

  # Check PLAN_PATH pre-calculation in Block 2
  if ! grep -q 'PLAN_PATH="\${PLANS_DIR}/\${PLAN_FILENAME}"' "$command_file"; then
    echo "FAIL: Missing PLAN_PATH pre-calculation in Block 2" >&2
    return 1
  fi

  # Check PLAN_PATH passed to plan-architect
  if ! grep -q "Output Path: \${PLAN_PATH}" "$command_file"; then
    echo "FAIL: PLAN_PATH not passed to plan-architect in Block 2-exec" >&2
    return 1
  fi

  echo "PASS: Paths pre-calculated and passed to agents (Hard Barrier Pattern)"
  return 0
}

# === RUN ALL TESTS ===
main() {
  # Disable errexit for test execution (we want to run all tests even if some fail)
  set +e

  echo "=========================================="
  echo "Test Suite: $TEST_NAME"
  echo "Description: $TEST_DESCRIPTION"
  echo "=========================================="
  echo ""

  local failed=0
  local passed=0

  # Run tests
  if test_simple_feature_delegation; then
    ((passed++))
  else
    ((failed++))
  fi
  echo ""

  if test_research_hard_barrier; then
    ((passed++))
  else
    ((failed++))
  fi
  echo ""

  if test_planning_hard_barrier; then
    ((passed++))
  else
    ((failed++))
  fi
  echo ""

  if test_no_pseudocode_task_syntax; then
    ((passed++))
  else
    ((failed++))
  fi
  echo ""

  if test_context_barrier_separation; then
    ((passed++))
  else
    ((failed++))
  fi
  echo ""

  if test_precalculated_paths; then
    ((passed++))
  else
    ((failed++))
  fi
  echo ""

  # Summary
  echo "=========================================="
  echo "Test Results: $passed passed, $failed failed"
  echo "=========================================="

  if [ "$failed" -eq 0 ]; then
    echo "SUCCESS: All tests passed"
    return 0
  else
    echo "FAILURE: $failed test(s) failed"
    return 1
  fi
}

# Execute tests
main "$@"
