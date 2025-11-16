#!/usr/bin/env bash
# Test suite for /optimize-claude agents
# Tests claude-md-analyzer, docs-structure-analyzer, and cleanup-plan-architect agents

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$SCRIPT_DIR/../agents"

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
TEST_DIR="/tmp/optimize_claude_tests_$$"

# Setup test environment
setup() {
  echo "Setting up test environment: $TEST_DIR"
  rm -rf "$TEST_DIR"
  mkdir -p "$TEST_DIR"
}

# Cleanup test environment
cleanup() {
  echo "Cleaning up test environment"
  rm -rf "$TEST_DIR"
}

# Test helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
  ((TESTS_RUN++)) || true
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_FAILED++)) || true
  ((TESTS_RUN++)) || true
}

skip() {
  echo -e "${YELLOW}⊘ SKIP${NC}: $1"
  echo "  Reason: $2"
  ((TESTS_RUN++)) || true
}

# Assert helper functions
assert_file_exists() {
  local file="$1"
  local msg="$2"

  if [ -f "$file" ]; then
    pass "$msg"
  else
    fail "$msg" "File not found: $file"
  fi
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local msg="$3"

  if [ ! -f "$file" ]; then
    fail "$msg" "File not found: $file"
    return
  fi

  if grep -q "$pattern" "$file"; then
    pass "$msg"
  else
    fail "$msg" "Pattern not found: $pattern"
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="$3"

  if [ "$expected" = "$actual" ]; then
    pass "$msg"
  else
    fail "$msg" "Expected: '$expected', Got: '$actual'"
  fi
}

# ============================================================================
# Agent File Structure Tests
# ============================================================================

test_agent_files_exist() {
  echo ""
  echo "Test Group: Agent Files Exist"
  echo "=============================="

  assert_file_exists "$AGENTS_DIR/claude-md-analyzer.md" \
    "claude-md-analyzer.md agent file exists"

  assert_file_exists "$AGENTS_DIR/docs-structure-analyzer.md" \
    "docs-structure-analyzer.md agent file exists"

  assert_file_exists "$AGENTS_DIR/cleanup-plan-architect.md" \
    "cleanup-plan-architect.md agent file exists"
}

test_agent_frontmatter() {
  echo ""
  echo "Test Group: Agent Frontmatter"
  echo "=============================="

  # Test claude-md-analyzer frontmatter
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "allowed-tools:" \
    "claude-md-analyzer has allowed-tools"

  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "model:" \
    "claude-md-analyzer has model selection"

  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "description:" \
    "claude-md-analyzer has description"

  # Test docs-structure-analyzer frontmatter
  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "allowed-tools:" \
    "docs-structure-analyzer has allowed-tools"

  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "model:" \
    "docs-structure-analyzer has model selection"

  # Test cleanup-plan-architect frontmatter
  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "allowed-tools:" \
    "cleanup-plan-architect has allowed-tools"

  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "model:" \
    "cleanup-plan-architect has model selection"
}

test_agent_steps() {
  echo ""
  echo "Test Group: Agent Step Structure"
  echo "================================="

  # Test claude-md-analyzer has required steps
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "### STEP 1" \
    "claude-md-analyzer has STEP 1"

  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "### STEP 2" \
    "claude-md-analyzer has STEP 2"

  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "### STEP 3" \
    "claude-md-analyzer has STEP 3"

  # Test docs-structure-analyzer has required steps
  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "### STEP 1" \
    "docs-structure-analyzer has STEP 1"

  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "### STEP 2" \
    "docs-structure-analyzer has STEP 2"

  # Test cleanup-plan-architect has required steps
  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "### STEP 1" \
    "cleanup-plan-architect has STEP 1"

  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "### STEP 2" \
    "cleanup-plan-architect has STEP 2"
}

test_agent_completion_signals() {
  echo ""
  echo "Test Group: Agent Completion Signals"
  echo "====================================="

  # Test claude-md-analyzer completion signal
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "REPORT_CREATED:" \
    "claude-md-analyzer has REPORT_CREATED signal"

  # Test docs-structure-analyzer completion signal
  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "REPORT_CREATED:" \
    "docs-structure-analyzer has REPORT_CREATED signal"

  # Test cleanup-plan-architect completion signal
  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "PLAN_CREATED:" \
    "cleanup-plan-architect has PLAN_CREATED signal"
}

test_agent_library_integration() {
  echo ""
  echo "Test Group: Agent Library Integration"
  echo "======================================"

  # Test claude-md-analyzer uses optimize-claude-md.sh
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "optimize-claude-md.sh" \
    "claude-md-analyzer sources optimize-claude-md.sh"

  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "analyze_bloat" \
    "claude-md-analyzer calls analyze_bloat()"

  # Test all agents use unified-location-detection.sh
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "unified-location-detection.sh" \
    "claude-md-analyzer sources unified-location-detection.sh"

  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "unified-location-detection.sh" \
    "docs-structure-analyzer sources unified-location-detection.sh"

  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "unified-location-detection.sh" \
    "cleanup-plan-architect sources unified-location-detection.sh"
}

test_agent_verification_checkpoints() {
  echo ""
  echo "Test Group: Agent Verification Checkpoints"
  echo "==========================================="

  # Test claude-md-analyzer has checkpoints
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "CHECKPOINT" \
    "claude-md-analyzer has verification checkpoints"

  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "VERIFICATION" \
    "claude-md-analyzer has verification blocks"

  # Test docs-structure-analyzer has checkpoints
  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "CHECKPOINT" \
    "docs-structure-analyzer has verification checkpoints"

  # Test cleanup-plan-architect has checkpoints
  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "CHECKPOINT" \
    "cleanup-plan-architect has verification checkpoints"
}

test_agent_imperative_language() {
  echo ""
  echo "Test Group: Agent Imperative Language"
  echo "======================================"

  # Test agents use imperative language (MUST/WILL/SHALL)
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "MUST" \
    "claude-md-analyzer uses imperative language (MUST)"

  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "MUST" \
    "docs-structure-analyzer uses imperative language (MUST)"

  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "MUST" \
    "cleanup-plan-architect uses imperative language (MUST)"
}

# ============================================================================
# Agent Behavioral Compliance Tests
# ============================================================================

test_agent_file_size_limits() {
  echo ""
  echo "Test Group: Agent File Size Limits"
  echo "==================================="

  # Check agent files are under 400 lines (executable/documentation separation)
  local analyzer_lines=$(wc -l < "$AGENTS_DIR/claude-md-analyzer.md")
  local docs_lines=$(wc -l < "$AGENTS_DIR/docs-structure-analyzer.md")
  local architect_lines=$(wc -l < "$AGENTS_DIR/cleanup-plan-architect.md")

  if [ "$analyzer_lines" -le 400 ]; then
    pass "claude-md-analyzer.md is within 400 line limit ($analyzer_lines lines)"
  else
    fail "claude-md-analyzer.md exceeds 400 line limit" "$analyzer_lines lines (should be ≤400)"
  fi

  if [ "$docs_lines" -le 400 ]; then
    pass "docs-structure-analyzer.md is within 400 line limit ($docs_lines lines)"
  else
    fail "docs-structure-analyzer.md exceeds 400 line limit" "$docs_lines lines (should be ≤400)"
  fi

  if [ "$architect_lines" -le 400 ]; then
    pass "cleanup-plan-architect.md is within 400 line limit ($architect_lines lines)"
  else
    fail "cleanup-plan-architect.md exceeds 400 line limit" "$architect_lines lines (should be ≤400)"
  fi
}

test_agent_absolute_paths_only() {
  echo ""
  echo "Test Group: Agent Absolute Path Requirements"
  echo "============================================="

  # Test agents require absolute paths
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "absolute" \
    "claude-md-analyzer requires absolute paths"

  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "absolute" \
    "docs-structure-analyzer requires absolute paths"

  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "absolute" \
    "cleanup-plan-architect requires absolute paths"
}

test_agent_create_file_first_pattern() {
  echo ""
  echo "Test Group: Agent Create File FIRST Pattern"
  echo "============================================"

  # Test agents create file FIRST before analysis
  assert_file_contains "$AGENTS_DIR/claude-md-analyzer.md" "Create Report File FIRST" \
    "claude-md-analyzer creates report file FIRST"

  assert_file_contains "$AGENTS_DIR/docs-structure-analyzer.md" "Create Report File FIRST" \
    "docs-structure-analyzer creates report file FIRST"

  assert_file_contains "$AGENTS_DIR/cleanup-plan-architect.md" "Create Plan File FIRST" \
    "cleanup-plan-architect creates plan file FIRST"
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
  echo "=========================================="
  echo "  /optimize-claude Agent Test Suite"
  echo "=========================================="

  setup

  # Run test groups
  test_agent_files_exist
  test_agent_frontmatter
  test_agent_steps
  test_agent_completion_signals
  test_agent_library_integration
  test_agent_verification_checkpoints
  test_agent_imperative_language
  test_agent_file_size_limits
  test_agent_absolute_paths_only
  test_agent_create_file_first_pattern

  cleanup

  # Print summary
  echo ""
  echo "=========================================="
  echo "  Test Summary"
  echo "=========================================="
  echo "Tests Run:    $TESTS_RUN"
  echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
  echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
  echo ""

  # Exit with appropriate code
  if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
  fi
}

# Run main if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
