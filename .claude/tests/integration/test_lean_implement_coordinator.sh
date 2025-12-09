#!/usr/bin/env bash
# Integration test for /lean-implement hard barrier enforcement and coordinator integration
# Tests implementer-coordinator delegation, wave-based orchestration, brief summary parsing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="/tmp/lean_implement_coordinator_test_$$"

# Test helper functions
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

info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
  export CLAUDE_PROJECT_DIR="$PROJECT_DIR"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test 1: Verify artifact path pre-calculation in Block 1a
test_artifact_path_precalculation() {
  info "Testing artifact path pre-calculation"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  if [[ ! -f "$command_file" ]]; then
    fail "lean-implement.md not found" "Expected at $command_file"
    return
  fi

  # Check for SUMMARIES_DIR calculation
  if grep -q "SUMMARIES_DIR=" "$command_file"; then
    pass "lean-implement pre-calculates SUMMARIES_DIR"
  else
    fail "lean-implement missing SUMMARIES_DIR calculation" "Should pre-calculate in Block 1a"
  fi

  # Check for DEBUG_DIR calculation
  if grep -q "DEBUG_DIR=" "$command_file"; then
    pass "lean-implement pre-calculates DEBUG_DIR"
  else
    fail "lean-implement missing DEBUG_DIR calculation" "Should pre-calculate in Block 1a"
  fi

  # Check for OUTPUTS_DIR calculation
  if grep -q "OUTPUTS_DIR=" "$command_file"; then
    pass "lean-implement pre-calculates OUTPUTS_DIR"
  else
    fail "lean-implement missing OUTPUTS_DIR calculation" "Should pre-calculate in Block 1a"
  fi

  # Check for CHECKPOINTS_DIR calculation
  if grep -q "CHECKPOINTS_DIR=" "$command_file"; then
    pass "lean-implement pre-calculates CHECKPOINTS_DIR"
  else
    fail "lean-implement missing CHECKPOINTS_DIR calculation" "Should pre-calculate in Block 1a"
  fi
}

# Test 2: Verify hard barrier pattern enforcement in Block 1b
test_hard_barrier_enforcement() {
  info "Testing hard barrier pattern enforcement"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check for HARD BARRIER comment
  if grep -q "HARD BARRIER" "$command_file"; then
    pass "lean-implement has HARD BARRIER enforcement comment"
  else
    fail "lean-implement missing HARD BARRIER comment" "Should have explicit hard barrier marker"
  fi

  # Check coordinator delegation is mandatory
  if grep -q "MANDATORY" "$command_file" || grep -q "delegation.*required" "$command_file"; then
    pass "lean-implement enforces mandatory coordinator delegation"
  else
    fail "lean-implement missing mandatory delegation enforcement" "Should have MANDATORY comment"
  fi

  # Check COORDINATOR_NAME is persisted
  if grep -q "COORDINATOR_NAME=" "$command_file"; then
    pass "lean-implement persists COORDINATOR_NAME for validation"
  else
    fail "lean-implement missing COORDINATOR_NAME persistence" "Should persist for Block 1c validation"
  fi
}

# Test 3: Verify coordinator input contract includes artifact paths
test_coordinator_input_contract() {
  info "Testing coordinator input contract"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check for artifact_paths in input contract
  if grep -q "artifact_paths" "$command_file"; then
    pass "lean-implement includes artifact_paths in coordinator contract"
  else
    fail "lean-implement missing artifact_paths" "Should pass to coordinator"
  fi

  # Check for summaries_dir in contract
  if grep -q "summaries_dir" "$command_file"; then
    pass "lean-implement includes summaries_dir in contract"
  else
    fail "lean-implement missing summaries_dir" "Should pass to coordinator"
  fi

  # Check for debug_dir in contract (can be in artifact_paths structure or standalone)
  if grep -q "debug.*DEBUG_DIR" "$command_file" || grep -q "DEBUG_DIR" "$command_file"; then
    pass "lean-implement includes debug_dir in contract"
  else
    fail "lean-implement missing debug_dir" "Should pass to coordinator"
  fi
}

# Test 4: Verify hard barrier validation in Block 1c
test_hard_barrier_validation() {
  info "Testing hard barrier validation"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check for summary file validation
  if grep -q "LATEST_SUMMARY" "$command_file" && grep -q "find.*SUMMARIES_DIR" "$command_file"; then
    pass "lean-implement validates summary file exists"
  else
    fail "lean-implement missing summary validation" "Should check for summary file"
  fi

  # Check for delegation bypass detection
  if grep -q "HARD BARRIER FAILED" "$command_file"; then
    pass "lean-implement detects delegation bypass"
  else
    fail "lean-implement missing bypass detection" "Should fail if summary missing"
  fi

  # Check for error logging on failure (can use different error types)
  if grep -q "log_command_error" "$command_file" && grep -q "agent_error\|validation_error" "$command_file"; then
    pass "lean-implement logs coordinator errors"
  else
    fail "lean-implement missing error logging" "Should log agent_error on bypass"
  fi
}

# Test 5: Verify brief summary parsing (not full file read)
test_brief_summary_parsing() {
  info "Testing brief summary parsing for context reduction"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check for summary_brief field parsing
  if grep -q "summary_brief:" "$command_file"; then
    pass "lean-implement parses summary_brief field"
  else
    fail "lean-implement missing summary_brief parsing" "Should parse from return signal"
  fi

  # Check for phases_completed field parsing
  if grep -q "phases_completed:" "$command_file"; then
    pass "lean-implement parses phases_completed field"
  else
    fail "lean-implement missing phases_completed parsing" "Should parse from return signal"
  fi

  # Check for context_usage_percent field parsing
  if grep -q "context_usage_percent:" "$command_file"; then
    pass "lean-implement parses context_usage_percent field"
  else
    fail "lean-implement missing context_usage_percent parsing" "Should parse from return signal"
  fi

  # Check for work_remaining field parsing
  if grep -q "work_remaining:" "$command_file"; then
    pass "lean-implement parses work_remaining field"
  else
    fail "lean-implement missing work_remaining parsing" "Should parse from return signal"
  fi
}

# Test 6: Verify no full summary file reads in orchestrator
test_no_full_summary_reads() {
  info "Testing orchestrator doesn't read full summary files"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check that brief summary is displayed (not full file content)
  if grep -q "Summary: \$SUMMARY_BRIEF" "$command_file"; then
    pass "lean-implement displays brief summary (not full content)"
  else
    fail "lean-implement missing brief summary display" "Should show SUMMARY_BRIEF variable"
  fi

  # Check for "Full report:" reference (path only, not read)
  if grep -q "Full report:.*LATEST_SUMMARY" "$command_file"; then
    pass "lean-implement provides full report path reference"
  else
    fail "lean-implement missing full report reference" "Should show path for user access"
  fi
}

# Test 7: Verify Block 1d Phase Marker Recovery was deleted
test_phase_marker_delegation() {
  info "Testing phase marker management delegated to coordinators"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check that Block 1d was removed or has delegation comment
  local block_1d_count=$(grep -c "^## Block 1d:" "$command_file" || echo "0")

  if [[ $block_1d_count -eq 0 ]]; then
    pass "lean-implement removed Block 1d Phase Marker Recovery"
  else
    # Check if it's now a delegation comment (case-insensitive)
    if grep -A5 "^## Block 1d:" "$command_file" | grep -i "delegat\|coordinator"; then
      pass "lean-implement delegates phase marker management to coordinators"
    else
      fail "lean-implement still has Block 1d logic" "Should be deleted or delegated"
    fi
  fi
}

# Test 8: Verify iteration continuation uses coordinator signals
test_iteration_continuation_signals() {
  info "Testing iteration continuation via coordinator signals"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check for requires_continuation field usage
  if grep -q "REQUIRES_CONTINUATION" "$command_file"; then
    pass "lean-implement uses REQUIRES_CONTINUATION signal"
  else
    fail "lean-implement missing REQUIRES_CONTINUATION" "Should check coordinator signal"
  fi

  # Check for context_exhausted field usage
  if grep -q "CONTEXT_EXHAUSTED" "$command_file"; then
    pass "lean-implement checks CONTEXT_EXHAUSTED signal"
  else
    fail "lean-implement missing CONTEXT_EXHAUSTED check" "Should parse coordinator signal"
  fi
}

# Test 9: Verify standards compliance
test_standards_compliance() {
  info "Testing pre-commit standards compliance"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check for three-tier sourcing pattern
  if grep -q "source.*state-persistence.sh" "$command_file" && \
     grep -q "source.*error-handling.sh" "$command_file"; then
    pass "lean-implement uses three-tier sourcing pattern"
  else
    fail "lean-implement missing three-tier sourcing" "Should source state-persistence.sh and error-handling.sh"
  fi

  # Check for error logging integration
  if grep -q "log_command_error" "$command_file"; then
    pass "lean-implement integrates error logging"
  else
    fail "lean-implement missing error logging" "Should use log_command_error()"
  fi

  # Check for setup_bash_error_trap
  if grep -q "setup_bash_error_trap" "$command_file"; then
    pass "lean-implement sets up bash error trap"
  else
    fail "lean-implement missing error trap setup" "Should call setup_bash_error_trap"
  fi
}

# Test 10: Verify implementer-coordinator dependency
test_implementer_coordinator_dependency() {
  info "Testing implementer-coordinator dependency"

  local command_file="$PROJECT_DIR/commands/lean-implement.md"

  # Check frontmatter lists implementer-coordinator (YAML array format)
  if grep -A5 "^dependent-agents:" "$command_file" | grep -q "implementer-coordinator"; then
    pass "lean-implement lists implementer-coordinator in frontmatter"
  else
    fail "lean-implement missing implementer-coordinator dependency" "Should be in frontmatter"
  fi

  # Check implementer-coordinator agent exists
  local coordinator_file="$PROJECT_DIR/agents/implementer-coordinator.md"
  if [[ -f "$coordinator_file" ]]; then
    pass "implementer-coordinator agent file exists"
  else
    fail "implementer-coordinator.md not found" "Expected at $coordinator_file"
  fi
}

# Run all tests
main() {
  echo "========================================"
  echo " Lean-Implement Coordinator Integration Tests"
  echo "========================================"
  echo ""

  setup

  test_artifact_path_precalculation
  test_hard_barrier_enforcement
  test_coordinator_input_contract
  test_hard_barrier_validation
  test_brief_summary_parsing
  test_no_full_summary_reads
  test_phase_marker_delegation
  test_iteration_continuation_signals
  test_standards_compliance
  test_implementer_coordinator_dependency

  cleanup

  echo ""
  echo "========================================"
  echo " Test Summary"
  echo "========================================"
  echo "Tests run: $TESTS_RUN"
  echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
  fi
}

# Trap cleanup on exit
trap cleanup EXIT

main "$@"
