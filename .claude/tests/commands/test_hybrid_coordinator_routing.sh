#!/usr/bin/env bash
# Test: Hybrid Coordinator Routing
# Tests phase classification and coordinator routing for pure lean, pure software, and mixed plans

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/.." && pwd)"

# Source test utilities
source "${CLAUDE_DIR}/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_DIR}/lib/plan/plan-core-bundle.sh" 2>/dev/null || exit 1

# Test fixtures directory
FIXTURES_DIR="${CLAUDE_DIR}/tests/fixtures/hybrid_plans"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$expected" = "$actual" ]; then
    echo "  ✓ $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Expected: $expected"
    echo "    Actual: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

assert_contains() {
  local substring="$1"
  local text="$2"
  local test_name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$text" | grep -q "$substring"; then
    echo "  ✓ $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    return 0
  else
    echo "  ✗ $test_name"
    echo "    Expected substring: $substring"
    echo "    Not found in: $text"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
}

# Test 1: Pure Lean Plan Classification
test_pure_lean_plan() {
  echo ""
  echo "Test 1: Pure Lean Plan Classification"

  local plan_file="${FIXTURES_DIR}/pure_lean_plan.md"

  # Extract phase metadata
  local phase1_impl=$(grep -A 3 "^### Phase 1:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')
  local phase2_impl=$(grep -A 3 "^### Phase 2:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')

  assert_equals "lean" "$phase1_impl" "Phase 1 has lean implementer"
  assert_equals "lean" "$phase2_impl" "Phase 2 has lean implementer"

  # Verify lean_file metadata present
  local phase1_lean_file=$(grep -A 3 "^### Phase 1:" "$plan_file" | grep "^lean_file:" | sed 's/lean_file:[[:space:]]*//')
  assert_contains "/tmp/test_basic.lean" "$phase1_lean_file" "Phase 1 has lean_file path"
}

# Test 2: Pure Software Plan Classification
test_pure_software_plan() {
  echo ""
  echo "Test 2: Pure Software Plan Classification"

  local plan_file="${FIXTURES_DIR}/pure_software_plan.md"

  # Extract phase metadata
  local phase1_impl=$(grep -A 3 "^### Phase 1:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')
  local phase2_impl=$(grep -A 3 "^### Phase 2:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')

  assert_equals "software" "$phase1_impl" "Phase 1 has software implementer"
  assert_equals "software" "$phase2_impl" "Phase 2 has software implementer"
}

# Test 3: Mixed Plan Classification
test_mixed_plan() {
  echo ""
  echo "Test 3: Mixed Lean/Software Plan Classification"

  local plan_file="${FIXTURES_DIR}/mixed_plan.md"

  # Extract phase metadata
  local phase1_impl=$(grep -A 3 "^### Phase 1:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')
  local phase2_impl=$(grep -A 3 "^### Phase 2:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')
  local phase3_impl=$(grep -A 3 "^### Phase 3:" "$plan_file" | grep "^implementer:" | sed 's/implementer:[[:space:]]*//')

  assert_equals "lean" "$phase1_impl" "Phase 1 has lean implementer"
  assert_equals "software" "$phase2_impl" "Phase 2 has software implementer"
  assert_equals "lean" "$phase3_impl" "Phase 3 has lean implementer"

  # Verify dependencies
  local phase3_deps=$(grep -A 3 "^### Phase 3:" "$plan_file" | grep "^dependencies:" | sed 's/dependencies:[[:space:]]*//')
  assert_contains "1, 2" "$phase3_deps" "Phase 3 has dependencies on Phase 1 and 2"
}

# Test 4: Legacy Plan Fallback Classification
test_legacy_plan() {
  echo ""
  echo "Test 4: Legacy Plan Fallback Classification"

  local plan_file="${FIXTURES_DIR}/legacy_plan.md"

  # Verify Phase 1 has lean_file but no implementer (should classify as lean via Tier 2)
  local phase1_lean_file=$(grep -A 3 "^### Phase 1:" "$plan_file" | grep "^lean_file:" || echo "")
  assert_contains "lean_file:" "$phase1_lean_file" "Phase 1 has lean_file for fallback classification"

  # Verify Phase 2 has no explicit metadata (should classify as software via Tier 3 keywords)
  local phase2_impl=$(grep -A 3 "^### Phase 2:" "$plan_file" | grep "^implementer:" || echo "none")
  assert_equals "none" "$phase2_impl" "Phase 2 has no explicit implementer (fallback classification)"
}

# Run all tests
echo "=========================================="
echo "Hybrid Coordinator Routing Tests"
echo "=========================================="

test_pure_lean_plan
test_pure_software_plan
test_mixed_plan
test_legacy_plan

# Print summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo "✓ All hybrid coordinator routing tests passed!"
  exit 0
else
  echo ""
  echo "✗ Some tests failed"
  exit 1
fi
