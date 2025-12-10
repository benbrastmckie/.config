#!/usr/bin/env bash
# Test suite for lean-coordinator plan-driven mode
# Tests wave extraction from plan metadata, sequential execution, and dual-mode compatibility

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# tests/integration/ is 2 levels deep in .claude/, need to go up 3 levels to get to project root
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Test isolation: Override CLAUDE_SPECS_ROOT to temporary directory
TEST_ROOT="/tmp/lean_coordinator_test_$$"
export CLAUDE_SPECS_ROOT="$TEST_ROOT"

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

skip() {
  echo -e "${BLUE}⊘ SKIP${NC}: $1"
  TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Cleanup trap
cleanup() {
  if [ -d "$TEST_ROOT" ]; then
    rm -rf "$TEST_ROOT"
  fi
}
trap cleanup EXIT

echo ""
echo "=============================================="
echo "lean-coordinator Plan-Driven Mode Test Suite"
echo "=============================================="
echo ""

#=============================================================================
# Test 1: Plan Structure Detection
#=============================================================================
test_plan_structure_detection() {
  # Test that STEP 1 documents plan structure detection logic
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_plan_structure_detection - lean-coordinator.md not found"
    return
  fi

  # Check for STEP 1 presence
  if ! grep -q "### STEP 1: Plan Structure Detection" "$coordinator_file"; then
    fail "test_plan_structure_detection - STEP 1 not found"
    return
  fi

  # Check for Level 0 and Level 1 detection documentation
  if ! grep -q "Level 0: All theorem phases inline in single file" "$coordinator_file"; then
    fail "test_plan_structure_detection - Level 0 detection not documented"
    return
  fi

  if ! grep -q "Level 1: Phases in separate files" "$coordinator_file"; then
    fail "test_plan_structure_detection - Level 1 detection not documented"
    return
  fi

  # Check for detection method code block
  if ! grep -q 'if \[ -d "$plan_dir" \]' "$coordinator_file"; then
    fail "test_plan_structure_detection - Detection method not documented"
    return
  fi

  # Check for STRUCTURE_LEVEL variable
  if ! grep -q "STRUCTURE_LEVEL=1" "$coordinator_file"; then
    fail "test_plan_structure_detection - STRUCTURE_LEVEL variable not found"
    return
  fi

  if ! grep -q "STRUCTURE_LEVEL=0" "$coordinator_file"; then
    fail "test_plan_structure_detection - STRUCTURE_LEVEL=0 not found"
    return
  fi

  # Check for phase file list building logic
  if ! grep -q 'ls "$plan_dir"/phase_\*.md' "$coordinator_file"; then
    fail "test_plan_structure_detection - Phase file list building not documented"
    return
  fi

  pass "test_plan_structure_detection - Plan structure detection documented correctly"
}

#=============================================================================
# Test 2: Wave Extraction from Plan Metadata
#=============================================================================
test_wave_extraction() {
  # Test that STEP 2 documents wave extraction from plan metadata
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_wave_extraction - lean-coordinator.md not found"
    return
  fi

  # Check for STEP 2 presence
  if ! grep -q "### STEP 2: Wave Extraction from Plan Metadata" "$coordinator_file"; then
    fail "test_wave_extraction - STEP 2 not found"
    return
  fi

  # Check that dependency-analyzer.sh is NOT invoked
  if ! grep -q "Plan-driven mode does NOT invoke dependency-analyzer.sh" "$coordinator_file"; then
    fail "test_wave_extraction - dependency-analyzer.sh removal not documented"
    return
  fi

  # Check for dependencies field parsing
  if ! grep -q 'dependencies:\s*\[\]' "$coordinator_file"; then
    fail "test_wave_extraction - dependencies field parsing not documented"
    return
  fi

  # Check for sequential default behavior
  if ! grep -q "Sequential by Default" "$coordinator_file"; then
    fail "test_wave_extraction - sequential default not documented"
    return
  fi

  if ! grep -q "Each phase is its own wave" "$coordinator_file"; then
    fail "test_wave_extraction - one phase per wave not documented"
    return
  fi

  # Check for parallel wave detection
  if ! grep -q "Parallel Wave Detection" "$coordinator_file"; then
    fail "test_wave_extraction - parallel wave detection not documented"
    return
  fi

  if ! grep -q "parallel_wave: true" "$coordinator_file"; then
    fail "test_wave_extraction - parallel_wave indicator not documented"
    return
  fi

  if ! grep -q "wave_id" "$coordinator_file"; then
    fail "test_wave_extraction - wave_id indicator not documented"
    return
  fi

  # Check for dependency ordering
  if ! grep -q "Dependency Ordering" "$coordinator_file"; then
    fail "test_wave_extraction - dependency ordering not documented"
    return
  fi

  # Check for wave structure validation
  if ! grep -q "Validate Wave Structure" "$coordinator_file"; then
    fail "test_wave_extraction - wave structure validation not documented"
    return
  fi

  pass "test_wave_extraction - Wave extraction from plan metadata documented correctly"
}

#=============================================================================
# Test 3: Wave Execution Orchestration
#=============================================================================
test_wave_execution_orchestration() {
  # Test that STEP 4 documents wave execution orchestration
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_wave_execution_orchestration - lean-coordinator.md not found"
    return
  fi

  # Check for STEP 4 presence
  if ! grep -q "### STEP 4: Wave Execution Loop" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - STEP 4 not found"
    return
  fi

  # Check for wave initialization
  if ! grep -q "Wave Initialization" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - wave initialization not documented"
    return
  fi

  # Check for MCP rate limit budget allocation
  if ! grep -q "MCP Rate Limit Budget Allocation" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - MCP rate limit budget allocation not documented"
    return
  fi

  if ! grep -q "TOTAL_BUDGET=3" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - total budget value not found"
    return
  fi

  if ! grep -q "budget_per_implementer" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - budget_per_implementer not documented"
    return
  fi

  # Check for parallel implementer invocation
  if ! grep -q "Parallel Implementer Invocation" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - parallel implementer invocation not documented"
    return
  fi

  if ! grep -q "multiple invocations in single response" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - multiple invocations pattern not documented"
    return
  fi

  # Check for wave synchronization (hard barrier)
  if ! grep -q "Wave Synchronization" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - wave synchronization not documented"
    return
  fi

  if ! grep -q "Wait for ALL implementers in wave to complete" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - hard barrier not documented"
    return
  fi

  # Check for Task tool invocation pattern
  if ! grep -q "Task {" "$coordinator_file"; then
    fail "test_wave_execution_orchestration - Task tool invocation pattern not documented"
    return
  fi

  pass "test_wave_execution_orchestration - Wave execution orchestration documented correctly"
}

#=============================================================================
# Test 4: Phase Number Extraction
#=============================================================================
test_phase_number_extraction() {
  # Test that phase_number extraction is documented in STEP 4
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_phase_number_extraction - lean-coordinator.md not found"
    return
  fi

  # Check for Phase Number Extraction section
  if ! grep -q "Phase Number Extraction" "$coordinator_file"; then
    fail "test_phase_number_extraction - Phase Number Extraction section not found"
    return
  fi

  # Check for phase_number field in theorem metadata
  if ! grep -q '"phase_number": [0-9]' "$coordinator_file"; then
    fail "test_phase_number_extraction - phase_number field not documented"
    return
  fi

  # Check for phase_num extraction logic
  if ! grep -q 'phase_num=.*jq.*phase_number' "$coordinator_file"; then
    fail "test_phase_number_extraction - phase_num extraction logic not documented"
    return
  fi

  # Check for phase_number=0 handling (file-based mode)
  if ! grep -q "phase_num = 0.*File-based mode" "$coordinator_file"; then
    fail "test_phase_number_extraction - phase_number=0 handling not documented"
    return
  fi

  # Check for phase_num > 0 handling (progress tracking)
  if ! grep -q "phase_num > 0.*Enable progress tracking" "$coordinator_file"; then
    fail "test_phase_number_extraction - phase_num>0 handling not documented"
    return
  fi

  pass "test_phase_number_extraction - Phase number extraction documented correctly"
}

#=============================================================================
# Test 5: Progress Tracking Forwarding
#=============================================================================
test_progress_tracking_forwarding() {
  # Test that progress tracking forwarding is documented in STEP 4
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_progress_tracking_forwarding - lean-coordinator.md not found"
    return
  fi

  # Check for Progress Tracking Instruction Forwarding section
  if ! grep -q "Progress Tracking Instruction Forwarding" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - Progress Tracking Instruction Forwarding section not found"
    return
  fi

  # Check for checkbox-utils sourcing instruction
  if ! grep -q "source.*checkbox-utils.sh" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - checkbox-utils sourcing not documented"
    return
  fi

  # Check for add_in_progress_marker instruction
  if ! grep -q "add_in_progress_marker" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - add_in_progress_marker not documented"
    return
  fi

  # Check for mark_phase_complete instruction
  if ! grep -q "mark_phase_complete" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - mark_phase_complete not documented"
    return
  fi

  # Check for add_complete_marker instruction
  if ! grep -q "add_complete_marker" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - add_complete_marker not documented"
    return
  fi

  # Check for graceful degradation note
  if ! grep -q "gracefully degrades.*unavailable.*non-fatal" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - graceful degradation not documented"
    return
  fi

  # Check for file-based mode skip
  if ! grep -q "File-based mode.*Skip progress tracking" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - file-based mode skip not documented"
    return
  fi

  # Check for forwarding pattern
  if ! grep -q "Forwarding Pattern" "$coordinator_file"; then
    fail "test_progress_tracking_forwarding - forwarding pattern not documented"
    return
  fi

  pass "test_progress_tracking_forwarding - Progress tracking forwarding documented correctly"
}

#=============================================================================
# Test 6: File-Based Mode Preservation (CRITICAL - Regression Check)
#=============================================================================
test_file_based_mode_preservation() {
  # Test that documentation includes STEP 0 for mode detection
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_file_based_mode_preservation - lean-coordinator.md not found"
    return
  fi

  # Check for STEP 0 presence
  if ! grep -q "### STEP 0: Execution Mode Detection" "$coordinator_file"; then
    fail "test_file_based_mode_preservation - STEP 0 not found in lean-coordinator.md"
    return
  fi

  # Check for execution_mode parameter parsing
  if ! grep -q 'EXECUTION_MODE="\${execution_mode:-plan-based}"' "$coordinator_file"; then
    fail "test_file_based_mode_preservation - execution_mode parameter parsing not found"
    return
  fi

  # Check for file-based mode conditional
  if ! grep -q 'if \[ "$EXECUTION_MODE" = "file-based" \]' "$coordinator_file"; then
    fail "test_file_based_mode_preservation - file-based mode conditional not found"
    return
  fi

  # Check for plan-based mode mention
  if ! grep -q 'execution_mode = "plan-based"' "$coordinator_file"; then
    fail "test_file_based_mode_preservation - plan-based mode not documented"
    return
  fi

  # Check that STEP 1 and STEP 2 have backward compatibility notes
  if ! grep -q "This STEP is only executed in plan-based mode" "$coordinator_file"; then
    fail "test_file_based_mode_preservation - backward compatibility notes missing"
    return
  fi

  pass "test_file_based_mode_preservation - Mode detection documented correctly"
}

#=============================================================================
# Test 7: Dual-Mode Compatibility
#=============================================================================
test_dual_mode_compatibility() {
  # Test that documentation ensures dual-mode compatibility
  local coordinator_file="$PROJECT_DIR/.claude/agents/lean-coordinator.md"

  if ! [ -f "$coordinator_file" ]; then
    fail "test_dual_mode_compatibility - lean-coordinator.md not found"
    return
  fi

  # Check for execution_mode parameter in Input Format section
  if ! grep -q "execution_mode.*file-based.*plan-based" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - execution_mode parameter not documented in Input Format"
    return
  fi

  # Check for Execution Mode Behavior section
  if ! grep -q "Execution Mode Behavior" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - Execution Mode Behavior section not found"
    return
  fi

  # Check for file-based mode description
  if ! grep -q "file-based mode.*Legacy mode" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - file-based mode not described"
    return
  fi

  # Check for plan-based mode description
  if ! grep -q "plan-based mode.*Optimized mode" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - plan-based mode not described"
    return
  fi

  # Check for dual-mode output format consistency
  if ! grep -q "Dual-Mode Behavior Note.*Output format is identical" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - output format consistency not documented"
    return
  fi

  # Check for coordinator_type field in output
  if ! grep -q "coordinator_type: lean" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - coordinator_type field not documented"
    return
  fi

  # Check for summary_brief field in output
  if ! grep -q "summary_brief" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - summary_brief field not documented"
    return
  fi

  # Check for clean-break exception documentation
  if ! grep -q "Clean-Break Exception" "$coordinator_file"; then
    fail "test_dual_mode_compatibility - clean-break exception not documented"
    return
  fi

  pass "test_dual_mode_compatibility - Dual-mode compatibility documented correctly"
}

#=============================================================================
# Test 8: Blocking Detection and Revision
#=============================================================================
test_blocking_detection_and_revision() {
  # TODO: Implement blocking detection test (optional, may defer)
  # Expected behavior:
  # - Detect partial theorems with blocking dependencies
  # - Trigger lean-plan-updater when context allows
  # - Respect revision depth limit (max 2)

  skip "test_blocking_detection_and_revision - Not implemented yet (optional)"
}

#=============================================================================
# Run all tests
#=============================================================================
test_plan_structure_detection
test_wave_extraction
test_wave_execution_orchestration
test_phase_number_extraction
test_progress_tracking_forwarding
test_file_based_mode_preservation
test_dual_mode_compatibility
test_blocking_detection_and_revision

# Summary
echo ""
echo "=============================================="
echo "Test Summary"
echo "=============================================="
echo -e "Total:   $TESTS_RUN"
echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Skipped: ${BLUE}$TESTS_SKIPPED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All tests passed or skipped${NC}"
  exit 0
else
  echo -e "${RED}✗ Some tests failed${NC}"
  exit 1
fi
