#!/bin/bash
# Phase 7: Comprehensive Compliance Verification Test
# Tests all 6 remediation areas across 5 workflow commands

set -euo pipefail

CLAUDE_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CLAUDE_PROJECT_DIR

COMMANDS=(
  "build"
  "debug"
  "research"
  "plan"
  "revise"
)

COMMAND_PATHS=(
  "${CLAUDE_PROJECT_DIR}/.claude/commands/build.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/debug.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/research.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/plan.md"
  "${CLAUDE_PROJECT_DIR}/.claude/commands/revise.md"
)

echo "=== Phase 7: Comprehensive Compliance Verification ==="
echo ""

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS

test_pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "✓ $1"
}

test_fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILED_TESTS+=("$1")
  echo "✗ $1"
}

# ============================================================================
# Area 1: Agent Invocation Patterns (13 instances)
# ============================================================================
echo "=== Area 1: Agent Invocation Patterns ==="
echo "Testing: Task tool invocations with behavioral injection"
echo ""

# Expected agent invocations per command
# build: 1 (implementer-coordinator)
# fix: 3 (research-specialist, plan-architect, debug-analyst)
# research-report: 1 (research-specialist)
# research-plan: 2 (research-specialist, plan-architect)
# research-revise: 2 (research-specialist, plan-architect)

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  path="${COMMAND_PATHS[$i]}"

  # Check for Task tool invocations
  if grep -q "^Task {" "$path"; then
    test_pass "$cmd: Task tool invocation found"
  else
    test_fail "$cmd: Task tool invocation missing"
  fi

  # Check for behavioral injection pattern
  if grep -q "Read and follow ALL behavioral guidelines from:" "$path"; then
    test_pass "$cmd: Behavioral injection pattern found"
  else
    test_fail "$cmd: Behavioral injection pattern missing"
  fi

  # Check for agent file references
  if grep -q ".claude/agents/.*\.md" "$path"; then
    test_pass "$cmd: Agent file reference found"
  else
    test_fail "$cmd: Agent file reference missing"
  fi
done

echo ""

# ============================================================================
# Area 2: Bash Block Variable Scope (5 commands)
# ============================================================================
echo "=== Area 2: Bash Block Variable Scope ==="
echo "Testing: State persistence with append_workflow_state/load_workflow_state"
echo ""

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  path="${COMMAND_PATHS[$i]}"

  # Check for append_workflow_state usage
  if grep -q "append_workflow_state" "$path"; then
    test_pass "$cmd: append_workflow_state found"
  else
    test_fail "$cmd: append_workflow_state missing"
  fi

  # Check for load_workflow_state usage
  if grep -q "load_workflow_state" "$path"; then
    test_pass "$cmd: load_workflow_state found"
  else
    test_fail "$cmd: load_workflow_state missing"
  fi
done

echo ""

# ============================================================================
# Area 3: Execution Enforcement Markers (26 instances)
# ============================================================================
echo "=== Area 3: Execution Enforcement Markers ==="
echo "Testing: MANDATORY VERIFICATION blocks after agent invocations"
echo ""

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  path="${COMMAND_PATHS[$i]}"

  # Count MANDATORY VERIFICATION blocks
  count=$(grep -c "# MANDATORY VERIFICATION" "$path" || echo "0")

  if [ "$count" -gt 0 ]; then
    test_pass "$cmd: MANDATORY VERIFICATION blocks found ($count instances)"
  else
    test_fail "$cmd: MANDATORY VERIFICATION blocks missing"
  fi

  # Check for verification logic after agent invocations
  if grep -q "Verifying.*artifacts" "$path"; then
    test_pass "$cmd: Verification logic found"
  else
    test_fail "$cmd: Verification logic missing"
  fi
done

echo ""

# ============================================================================
# Area 4: Checkpoint Reporting (11 instances)
# ============================================================================
echo "=== Area 4: Checkpoint Reporting ==="
echo "Testing: CHECKPOINT structured output with metrics"
echo ""

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  path="${COMMAND_PATHS[$i]}"

  # Count CHECKPOINT blocks
  count=$(grep -c "^echo \"CHECKPOINT:" "$path" || echo "0")

  if [ "$count" -gt 0 ]; then
    test_pass "$cmd: CHECKPOINT reporting found ($count instances)"
  else
    test_fail "$cmd: CHECKPOINT reporting missing"
  fi

  # Check for structured checkpoint format
  if grep -q "echo \"- Workflow type:" "$path"; then
    test_pass "$cmd: Structured checkpoint format found"
  else
    test_fail "$cmd: Structured checkpoint format missing"
  fi
done

echo ""

# ============================================================================
# Area 5: Error Diagnostic Enhancements (17 instances)
# ============================================================================
echo "=== Area 5: Error Diagnostic Enhancements ==="
echo "Testing: Enhanced state transition errors with diagnostic context"
echo ""

# Expected error enhancements per command
# build: 5, fix: 4, research-report: 2, research-plan: 3, research-revise: 3

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  path="${COMMAND_PATHS[$i]}"

  # Check for DIAGNOSTIC Information sections
  diag_count=$(grep -c "echo \"DIAGNOSTIC Information:\"" "$path" || echo "0")

  if [ "$diag_count" -gt 0 ]; then
    test_pass "$cmd: DIAGNOSTIC sections found ($diag_count instances)"
  else
    test_fail "$cmd: DIAGNOSTIC sections missing"
  fi

  # Check for POSSIBLE CAUSES sections
  if grep -q "echo \"POSSIBLE CAUSES:\"" "$path"; then
    test_pass "$cmd: POSSIBLE CAUSES sections found"
  else
    test_fail "$cmd: POSSIBLE CAUSES sections missing"
  fi

  # Check for TROUBLESHOOTING sections
  if grep -q "echo \"TROUBLESHOOTING:\"" "$path"; then
    test_pass "$cmd: TROUBLESHOOTING sections found"
  else
    test_fail "$cmd: TROUBLESHOOTING sections missing"
  fi
done

echo ""

# ============================================================================
# Area 6: Library Version Requirements
# ============================================================================
echo "=== Area 6: Library Version Requirements ==="
echo "Testing: check_library_requirements usage"
echo ""

for i in "${!COMMANDS[@]}"; do
  cmd="${COMMANDS[$i]}"
  path="${COMMAND_PATHS[$i]}"

  # Check for library version checking
  if grep -q "check_library_requirements" "$path"; then
    test_pass "$cmd: Library version checking found"
  else
    test_fail "$cmd: Library version checking missing"
  fi

  # Check for required versions
  if grep -q "workflow-state-machine.sh:.*>=2.0.0" "$path"; then
    test_pass "$cmd: workflow-state-machine.sh version requirement found"
  else
    test_fail "$cmd: workflow-state-machine.sh version requirement missing"
  fi
done

echo ""

# ============================================================================
# Summary and Compliance Score Calculation
# ============================================================================
echo "=== Compliance Verification Summary ==="
echo ""
echo "Tests Run: $TESTS_RUN"
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo "Failed Tests:"
  for test in "${FAILED_TESTS[@]}"; do
    echo "  - $test"
  done
  echo ""
fi

# Calculate compliance score
COMPLIANCE_SCORE=$((TESTS_PASSED * 100 / TESTS_RUN))
echo "Overall Compliance Score: ${COMPLIANCE_SCORE}%"
echo ""

# Determine compliance tier
if [ "$COMPLIANCE_SCORE" -ge 95 ]; then
  echo "✓ EXCELLENT: Target compliance (95%+) achieved!"
  exit 0
elif [ "$COMPLIANCE_SCORE" -ge 90 ]; then
  echo "✓ GOOD: High compliance (90-94%) achieved"
  exit 0
elif [ "$COMPLIANCE_SCORE" -ge 80 ]; then
  echo "⚠ MODERATE: Acceptable compliance (80-89%), improvements recommended"
  exit 1
else
  echo "✗ POOR: Low compliance (<80%), significant work needed"
  exit 1
fi
