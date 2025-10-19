#!/bin/bash
# validate_phase7_success.sh
#
# Validates all Phase 7 success criteria are met.

set -euo pipefail

CLAUDE_DIR="/home/benjamin/.config/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SHARED_DIR="$COMMANDS_DIR/shared"
LIB_DIR="$CLAUDE_DIR/lib"

echo "═══════════════════════════════════════════════════════════"
echo "Phase 7 Success Criteria Validation"
echo "═══════════════════════════════════════════════════════════"
echo ""

TOTAL_CRITERIA=0
PASSING_CRITERIA=0

# Helper function
check_criterion() {
  local description=$1
  local test_command=$2

  TOTAL_CRITERIA=$((TOTAL_CRITERIA + 1))

  echo "[$TOTAL_CRITERIA] $description"
  if eval "$test_command" &>/dev/null; then
    echo "    ✓ PASS"
    PASSING_CRITERIA=$((PASSING_CRITERIA + 1))
  else
    echo "    ✗ FAIL"
  fi
  echo ""
}

# Stage 1 Criteria
echo "Stage 1: Foundation"
echo "───────────────────"
check_criterion "shared/ directory exists" "[ -d '$SHARED_DIR' ]"
check_criterion "shared/README.md exists" "[ -f '$SHARED_DIR/README.md' ]"

# Stage 2 Criteria
echo "Stage 2: Extract Command Documentation"
echo "───────────────────────────────────────"
check_criterion "workflow-phases.md created" "[ -f '$SHARED_DIR/workflow-phases.md' ]"
check_criterion "setup-modes.md created" "[ -f '$SHARED_DIR/setup-modes.md' ]"
check_criterion "bloat-detection.md created" "[ -f '$SHARED_DIR/bloat-detection.md' ]"
check_criterion "extraction-strategies.md created" "[ -f '$SHARED_DIR/extraction-strategies.md' ]"
check_criterion "standards-analysis.md created" "[ -f '$SHARED_DIR/standards-analysis.md' ]"
check_criterion "revise-auto-mode.md created" "[ -f '$SHARED_DIR/revise-auto-mode.md' ]"
check_criterion "revision-types.md created" "[ -f '$SHARED_DIR/revision-types.md' ]"
check_criterion "phase-execution.md created" "[ -f '$SHARED_DIR/phase-execution.md' ]"
check_criterion "implementation-workflow.md created" "[ -f '$SHARED_DIR/implementation-workflow.md' ]"
check_criterion "orchestrate.md reduced (target <1200)" "[ \$(wc -l < '$COMMANDS_DIR/orchestrate.md') -le 1200 ]"
check_criterion "setup.md reduced (target <400)" "[ \$(wc -l < '$COMMANDS_DIR/setup.md') -le 400 ]"
check_criterion "revise.md reduced (target ~400)" "[ \$(wc -l < '$COMMANDS_DIR/revise.md') -le 450 ]"
check_criterion "implement.md reduced (target <500)" "[ \$(wc -l < '$COMMANDS_DIR/implement.md') -le 500 ]"

# Stage 3 Criteria
echo "Stage 3: Consolidate Utility Libraries"
echo "───────────────────────────────────────"
check_criterion "base-utils.sh created" "[ -f '$LIB_DIR/base-utils.sh' ]"
check_criterion "plan-core-bundle.sh created" "[ -f '$LIB_DIR/plan-core-bundle.sh' ]"
check_criterion "unified-logger.sh created" "[ -f '$LIB_DIR/unified-logger.sh' ]"
# Wrappers removed - now using modular utilities directly
# parse-plan-core.sh, plan-metadata-utils.sh, plan-structure-utils.sh → plan-core-bundle.sh
# adaptive-planning-logger.sh, conversion-logger.sh → unified-logger.sh
# artifact-operations.sh → 7 modular utilities

# Stage 4 Criteria
echo "Stage 4: Update Commands and Documentation"
echo "───────────────────────────────────────────"
check_criterion "Commands use plan-core-bundle.sh" "grep -q 'plan-core-bundle' '$COMMANDS_DIR/expand.md' || grep -q 'plan-core-bundle' '$COMMANDS_DIR/collapse.md'"
check_criterion "Commands use unified-logger.sh" "grep -q 'unified-logger' '$SHARED_DIR/implementation-workflow.md'"
check_criterion "lib/README.md documents consolidation" "grep -q 'Recent Consolidation' '$LIB_DIR/README.md'"
check_criterion ".claude/README.md has Directory Roles" "grep -q 'Directory Roles' '$CLAUDE_DIR/README.md'"

# Stage 5 Criteria
echo "Stage 5: Documentation, Testing, and Validation"
echo "────────────────────────────────────────────────"
check_criterion ".claude/README.md has Phase 7 section" "grep -q 'Phase 7' '$CLAUDE_DIR/README.md'"
check_criterion "commands/README.md has Phase 7 section" "grep -q 'Phase 7' '$COMMANDS_DIR/README.md'"
check_criterion "Architecture diagram created" "[ -f '$CLAUDE_DIR/docs/architecture.md' ]"
check_criterion "Reference validation script created" "[ -f '$CLAUDE_DIR/tests/test_command_references.sh' ]"
check_criterion "Test results logged" "[ -f '$CLAUDE_DIR/tests/phase7_test_results.log' ]"

# Overall Criteria
echo "Overall Phase 7 Success Criteria"
echo "─────────────────────────────────"
check_criterion "≥9 shared files created" "[ \$(ls '$SHARED_DIR'/*.md 2>/dev/null | wc -l) -ge 9 ]"
check_criterion "Test suite pass rate ≥95%" "[ \$(grep -c '✓.*PASSED' '$CLAUDE_DIR/tests/phase7_test_results.log') -ge 40 ]"
check_criterion "File size reductions achieved" "[ \$(wc -l < '$COMMANDS_DIR/orchestrate.md') -le 1200 ]"

# Summary
echo "═══════════════════════════════════════════════════════════"
echo "Validation Summary"
echo "═══════════════════════════════════════════════════════════"
echo "Total criteria: $TOTAL_CRITERIA"
echo "Passing criteria: $PASSING_CRITERIA"
if [ $TOTAL_CRITERIA -gt 0 ]; then
  PASS_RATE=$(($PASSING_CRITERIA * 100 / $TOTAL_CRITERIA))
  echo "Pass rate: ${PASS_RATE}%"
else
  echo "Pass rate: N/A"
fi
echo ""

if [ $PASSING_CRITERIA -eq $TOTAL_CRITERIA ]; then
  echo "✓ SUCCESS: All Phase 7 success criteria met"
  exit 0
else
  FAILING=$((TOTAL_CRITERIA - PASSING_CRITERIA))
  echo "⚠ INCOMPLETE: $FAILING criteria not yet met"
  exit 1
fi
