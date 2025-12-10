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
  # TODO: Implement plan structure detection test
  # Expected behavior:
  # - Level 0: Inline plan (single file)
  # - Level 1: Phase files in dedicated directory
  # - Build correct file list for each level

  skip "test_plan_structure_detection - Not implemented yet (Phase 4)"
}

#=============================================================================
# Test 2: Wave Extraction from Plan Metadata
#=============================================================================
test_wave_extraction() {
  # TODO: Implement wave extraction test
  # Expected behavior:
  # - Parse dependencies: [] field from plan
  # - Default to sequential (one phase per wave)
  # - Handle parallel_wave: true + wave_id indicators
  # - Gracefully handle missing metadata

  skip "test_wave_extraction - Not implemented yet (Phase 5)"
}

#=============================================================================
# Test 3: Wave Execution Orchestration
#=============================================================================
test_wave_execution_orchestration() {
  # TODO: Implement wave execution orchestration test
  # Expected behavior:
  # - Sequential wave execution (Wave 1 → Wave 2 → Wave 3)
  # - Parallel implementer invocation within waves
  # - Wave synchronization (hard barrier)
  # - MCP rate limit budget allocation

  skip "test_wave_execution_orchestration - Not implemented yet (Phase 6)"
}

#=============================================================================
# Test 4: Phase Number Extraction
#=============================================================================
test_phase_number_extraction() {
  # TODO: Implement phase number extraction test
  # Expected behavior:
  # - Extract phase_number from theorem metadata
  # - Pass to lean-implementer for progress tracking
  # - Handle phase_number=0 (file-based mode)

  skip "test_phase_number_extraction - Not implemented yet (Phase 8)"
}

#=============================================================================
# Test 5: Progress Tracking Forwarding
#=============================================================================
test_progress_tracking_forwarding() {
  # TODO: Implement progress tracking forwarding test
  # Expected behavior:
  # - Forward progress tracking instructions to lean-implementer
  # - Handle checkbox-utils unavailability gracefully
  # - Skip in file-based mode

  skip "test_progress_tracking_forwarding - Not implemented yet (Phase 8)"
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
  # TODO: Implement dual-mode compatibility test
  # Expected behavior:
  # - No cross-contamination between modes
  # - execution_mode parameter parsed correctly
  # - Output format identical for both modes

  skip "test_dual_mode_compatibility - Not implemented yet (Phase 6)"
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
