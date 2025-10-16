#!/usr/bin/env bash
# Test Expansion Coordination
# Tests for plan_expander agent and expansion coordination logic

# Don't exit on first error - we want to run all tests
set +e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Setup test environment
setup() {
  TEST_DIR=$(mktemp -d)
  TEST_PLAN="$TEST_DIR/test_plan.md"

  # Copy test plan fixture
  cp "$SCRIPT_DIR/fixtures/test_plan_expansion.md" "$TEST_PLAN"

  echo "Test environment: $TEST_DIR"
}

# Cleanup test environment
cleanup() {
  if [[ -d "$TEST_DIR" ]]; then
    rm -rf "$TEST_DIR"
  fi
}

# Register cleanup on exit
trap cleanup EXIT

# Test 1: Verify test plan fixture loaded
test_fixture_loaded() {
  ((TESTS_RUN++))
  echo "Test 1: Verify test plan fixture loaded"

  if [[ ! -f "$TEST_PLAN" ]]; then
    echo "  ✗ FAILED: Test plan not found"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify plan has 4 implementation phases (not counting risk sections)
  PHASE_COUNT=$(grep "^### Phase [0-9]:" "$TEST_PLAN" | wc -l)
  if [[ $PHASE_COUNT -ne 4 ]]; then
    echo "  ✗ FAILED: Expected 4 implementation phases, found $PHASE_COUNT"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "  ✓ PASSED: Test plan fixture loaded with 4 phases"
  ((TESTS_PASSED++))
}

# Test 2: Verify plan_expander agent exists
test_agent_exists() {
  ((TESTS_RUN++))
  echo "Test 2: Verify plan_expander agent exists"

  AGENT_FILE="$HOME/.config/.claude/agents/plan-expander.md"

  if [[ ! -f "$AGENT_FILE" ]]; then
    echo "  ✗ FAILED: plan-expander.md not found"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify agent has required sections
  if ! grep -q "## Role" "$AGENT_FILE"; then
    echo "  ✗ FAILED: Agent missing 'Role' section"
    ((TESTS_FAILED++))
    return 1
  fi

  if ! grep -q "## Behavioral Guidelines" "$AGENT_FILE"; then
    echo "  ✗ FAILED: Agent missing 'Behavioral Guidelines' section"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "  ✓ PASSED: plan_expander agent exists with required sections"
  ((TESTS_PASSED++))
}

# Test 3: Verify /expand command supports --auto-mode
test_expand_auto_mode() {
  ((TESTS_RUN++))
  echo "Test 3: Verify /expand command supports --auto-mode"

  EXPAND_CMD="$HOME/.config/.claude/commands/expand.md"

  if [[ ! -f "$EXPAND_CMD" ]]; then
    echo "  ✗ FAILED: expand.md not found"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify --auto-mode flag documented
  if ! grep -q "\-\-auto-mode" "$EXPAND_CMD"; then
    echo "  ✗ FAILED: expand.md missing --auto-mode documentation"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify JSON output format documented
  if ! grep -q '"expansion_status"' "$EXPAND_CMD"; then
    echo "  ✗ FAILED: expand.md missing JSON output format"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "  ✓ PASSED: /expand command supports --auto-mode with JSON output"
  ((TESTS_PASSED++))
}

# Test 4: Verify orchestration patterns include expansion integration
test_orchestration_patterns() {
  ((TESTS_RUN++))
  echo "Test 4: Verify orchestration patterns include expansion integration"

  PATTERNS_FILE="$HOME/.config/.claude/templates/orchestration-patterns.md"

  if [[ ! -f "$PATTERNS_FILE" ]]; then
    echo "  ✗ FAILED: orchestration-patterns.md not found"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify Plan Expansion Integration section exists
  if ! grep -q "## Plan Expansion Integration" "$PATTERNS_FILE"; then
    echo "  ✗ FAILED: Missing 'Plan Expansion Integration' section"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify parallel invocation pattern documented
  if ! grep -q "Parallel Invocation Pattern" "$PATTERNS_FILE"; then
    echo "  ✗ FAILED: Missing parallel invocation pattern"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify sequential invocation pattern documented
  if ! grep -q "Sequential Invocation Pattern" "$PATTERNS_FILE"; then
    echo "  ✗ FAILED: Missing sequential invocation pattern"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "  ✓ PASSED: Orchestration patterns include expansion integration"
  ((TESTS_PASSED++))
}

# Test 5: Verify agent JSON output format
test_agent_output_format() {
  ((TESTS_RUN++))
  echo "Test 5: Verify agent JSON output format"

  AGENT_FILE="$HOME/.config/.claude/agents/plan-expander.md"

  # Verify output format documented
  if ! grep -q '"expansion_status"' "$AGENT_FILE"; then
    echo "  ✗ FAILED: Agent missing expansion_status in output format"
    ((TESTS_FAILED++))
    return 1
  fi

  if ! grep -q '"validation"' "$AGENT_FILE"; then
    echo "  ✗ FAILED: Agent missing validation field in output format"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify error handling documented
  if ! grep -q '"error_type"' "$AGENT_FILE"; then
    echo "  ✗ FAILED: Agent missing error handling documentation"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "  ✓ PASSED: Agent JSON output format properly documented"
  ((TESTS_PASSED++))
}

# Test 6: Verify progressive-planning-utils functions
test_progressive_utils() {
  ((TESTS_RUN++))
  echo "Test 6: Verify progressive-planning-utils functions"

  UTILS_FILE="$HOME/.config/.claude/lib/progressive-planning-utils.sh"

  if [[ ! -f "$UTILS_FILE" ]]; then
    echo "  ✗ FAILED: progressive-planning-utils.sh not found"
    ((TESTS_FAILED++))
    return 1
  fi

  # Source the utilities
  if ! source "$UTILS_FILE" 2>/dev/null; then
    echo "  ✗ FAILED: Could not source progressive-planning-utils.sh"
    ((TESTS_FAILED++))
    return 1
  fi

  # Verify key functions exist
  if ! declare -f update_expansion_metadata > /dev/null; then
    echo "  ✗ FAILED: update_expansion_metadata function not found"
    ((TESTS_FAILED++))
    return 1
  fi

  if ! declare -f merge_markdown_sections > /dev/null; then
    echo "  ✗ FAILED: merge_markdown_sections function not found"
    ((TESTS_FAILED++))
    return 1
  fi

  echo "  ✓ PASSED: Progressive planning utilities functions available"
  ((TESTS_PASSED++))
}

# Main test execution
main() {
  echo "========================================="
  echo "Phase 3: Plan Expander Agent Tests"
  echo "========================================="
  echo ""

  setup

  # Run all tests
  test_fixture_loaded
  test_agent_exists
  test_expand_auto_mode
  test_orchestration_patterns
  test_agent_output_format
  test_progressive_utils

  # Summary
  echo ""
  echo "========================================="
  echo "Test Summary"
  echo "========================================="
  echo "Tests Run:    $TESTS_RUN"
  echo "Tests Passed: $TESTS_PASSED"
  echo "Tests Failed: $TESTS_FAILED"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ ALL TESTS PASSED"
    exit 0
  else
    echo "✗ SOME TESTS FAILED"
    exit 1
  fi
}

# Run tests
main
