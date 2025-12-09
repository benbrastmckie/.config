#!/usr/bin/env bash
# Integration test for /lean-plan research-coordinator integration
# Tests multi-topic research, metadata-only passing, partial success mode

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
TEST_DIR="/tmp/lean_plan_coordinator_test_$$"

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

# Test 1: Verify lean-plan command has research-coordinator integration
test_lean_plan_research_coordinator_integration() {
  info "Testing lean-plan research-coordinator integration"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  if [[ ! -f "$command_file" ]]; then
    fail "lean-plan.md not found" "Expected at $command_file"
    return
  fi

  # Check frontmatter has research-coordinator dependency
  if grep -A5 "^dependent-agents:" "$command_file" | grep -q "research-coordinator"; then
    pass "lean-plan lists research-coordinator in dependent-agents"
  else
    fail "lean-plan missing research-coordinator dependency" "Should list research-coordinator in frontmatter"
  fi

  # Check Block 1d-topics exists
  if grep -q "^## Block 1d-topics: Research Topics Classification" "$command_file"; then
    pass "lean-plan has Block 1d-topics for topic classification"
  else
    fail "lean-plan missing Block 1d-topics" "Should have topic classification block"
  fi

  # Check Block 1e-exec invokes research-coordinator
  if grep -q "research-coordinator" "$command_file" && grep -q "Task tool" "$command_file"; then
    pass "lean-plan invokes research-coordinator via Task tool"
  else
    fail "lean-plan missing research-coordinator invocation" "Should use Task tool to invoke coordinator"
  fi
}

# Test 2: Verify complexity-based topic count
test_complexity_based_topic_count() {
  info "Testing complexity-based topic count logic"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check complexity mapping exists
  if grep -q "1|2) TOPIC_COUNT=2" "$command_file"; then
    pass "lean-plan maps complexity 1-2 to 2 topics"
  else
    fail "lean-plan missing complexity 1-2 mapping" "Should map to 2 topics"
  fi

  if grep -q "3)   TOPIC_COUNT=3" "$command_file"; then
    pass "lean-plan maps complexity 3 to 3 topics"
  else
    fail "lean-plan missing complexity 3 mapping" "Should map to 3 topics"
  fi

  if grep -q "4)   TOPIC_COUNT=4" "$command_file"; then
    pass "lean-plan maps complexity 4 to 4 topics"
  else
    fail "lean-plan missing complexity 4 mapping" "Should map to 4 topics"
  fi
}

# Test 3: Verify Lean-specific topics array
test_lean_topics_array() {
  info "Testing Lean-specific topics array"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check for Lean-specific topic names
  local required_topics=(
    "Mathlib Theorems"
    "Proof Strategies"
    "Project Structure"
    "Style Guide"
  )

  for topic in "${required_topics[@]}"; do
    if grep -q "\"$topic\"" "$command_file"; then
      pass "lean-plan includes topic: $topic"
    else
      fail "lean-plan missing topic: $topic" "Should be in LEAN_TOPICS array"
    fi
  done
}

# Test 4: Verify partial success mode in Block 1f validation
test_partial_success_mode() {
  info "Testing partial success mode validation"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check for success percentage calculation
  if grep -q "SUCCESS_PERCENTAGE=\$((SUCCESSFUL_REPORTS \* 100 / TOTAL_REPORTS))" "$command_file"; then
    pass "lean-plan calculates success percentage"
  else
    fail "lean-plan missing success percentage calculation" "Should calculate percentage"
  fi

  # Check for 50% threshold
  if grep -q "if \[ \$SUCCESS_PERCENTAGE -lt 50 \]" "$command_file"; then
    pass "lean-plan fails if <50% success"
  else
    fail "lean-plan missing <50% failure check" "Should fail below 50%"
  fi

  # Check for warning on 50-99% success
  if grep -q "if \[ \$SUCCESS_PERCENTAGE -lt 100 \]" "$command_file"; then
    pass "lean-plan warns if 50-99% success"
  else
    fail "lean-plan missing 50-99% warning" "Should warn on partial success"
  fi
}

# Test 5: Verify metadata extraction in Block 1f-metadata
test_metadata_extraction() {
  info "Testing metadata extraction for context reduction"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check Block 1f-metadata exists
  if grep -q "^## Block 1f-metadata: Extract Report Metadata" "$command_file"; then
    pass "lean-plan has Block 1f-metadata for metadata extraction"
  else
    fail "lean-plan missing Block 1f-metadata" "Should extract metadata from reports"
  fi

  # Check for metadata fields extraction
  if grep -q "title" "$command_file" && grep -q "findings_count" "$command_file"; then
    pass "lean-plan extracts metadata fields (title, findings_count)"
  else
    fail "lean-plan missing metadata extraction" "Should extract title, findings_count, etc."
  fi
}

# Test 6: Verify metadata-only passing to plan-architect
test_metadata_only_passing() {
  info "Testing metadata-only context passing to plan-architect"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check Block 2 uses metadata instead of full reports
  if grep -q "FORMATTED_METADATA" "$command_file"; then
    pass "lean-plan passes FORMATTED_METADATA to plan-architect"
  else
    fail "lean-plan not using metadata-only passing" "Should pass FORMATTED_METADATA"
  fi

  # Check for CRITICAL instruction about Read tool
  if grep -q "CRITICAL INSTRUCTION" "$command_file" && grep -q "Read tool access" "$command_file"; then
    pass "lean-plan includes CRITICAL instruction about delegated reads"
  else
    fail "lean-plan missing CRITICAL instruction" "Should explain Read tool access"
  fi
}

# Test 7: Verify hard barrier validation
test_hard_barrier_validation() {
  info "Testing hard barrier validation"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check for REPORT_PATHS array validation
  if grep -q "REPORT_PATHS not found in workflow state" "$command_file"; then
    pass "lean-plan validates REPORT_PATHS array exists"
  else
    fail "lean-plan missing REPORT_PATHS validation" "Should check array exists"
  fi

  # Check for report file validation loop
  if grep -q "for REPORT_PATH in \"\${REPORT_PATHS\[@\]}" "$command_file"; then
    pass "lean-plan validates each report in REPORT_PATHS array"
  else
    fail "lean-plan missing report validation loop" "Should validate each report"
  fi
}

# Test 8: Verify pre-commit standards compliance
test_standards_compliance() {
  info "Testing pre-commit standards compliance"

  local command_file="$PROJECT_DIR/commands/lean-plan.md"

  # Check for three-tier sourcing pattern
  if grep -q "source.*state-persistence.sh" "$command_file" && \
     grep -q "source.*error-handling.sh" "$command_file"; then
    pass "lean-plan uses three-tier sourcing pattern"
  else
    fail "lean-plan missing three-tier sourcing" "Should source state-persistence.sh and error-handling.sh"
  fi

  # Check for error logging integration
  if grep -q "log_command_error" "$command_file"; then
    pass "lean-plan integrates error logging"
  else
    fail "lean-plan missing error logging" "Should use log_command_error()"
  fi
}

# Run all tests
main() {
  echo "========================================"
  echo " Lean-Plan Coordinator Integration Tests"
  echo "========================================"
  echo ""

  setup

  test_lean_plan_research_coordinator_integration
  test_complexity_based_topic_count
  test_lean_topics_array
  test_partial_success_mode
  test_metadata_extraction
  test_metadata_only_passing
  test_hard_barrier_validation
  test_standards_compliance

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
