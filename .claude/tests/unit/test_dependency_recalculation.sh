#!/usr/bin/env bash
# Unit tests for dependency-recalculation.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the utility
source "$PROJECT_ROOT/lib/plan/dependency-recalculation.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# TEST HELPERS
# ============================================================================

assert_equals() {
  local expected="$1"
  local actual="$2"
  local test_name="$3"

  if [[ "$expected" == "$actual" ]]; then
    echo "✓ PASS: $test_name"
    ((TESTS_PASSED++))
  else
    echo "✗ FAIL: $test_name"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    ((TESTS_FAILED++))
  fi
}

create_test_plan() {
  local plan_file="$1"
  local content="$2"

  cat > "$plan_file" <<EOF
$content
EOF
}

# ============================================================================
# TEST CASES
# ============================================================================

test_simple_dependency_chain() {
  local test_plan="/tmp/test_plan_simple_$$.md"

  create_test_plan "$test_plan" '# Test Plan

## Phase 1: Setup [COMPLETE]

**Dependencies**: depends_on: []

Tasks...

## Phase 2: Implementation [NOT STARTED]

**Dependencies**: depends_on: [1]

Tasks...

## Phase 3: Testing [NOT STARTED]

**Dependencies**: depends_on: [2]

Tasks...

## Phase 4: Documentation [NOT STARTED]

**Dependencies**: depends_on: [2]

Tasks...
'

  # Test 1: Phase 1 complete, should return phases 2
  local result=$(recalculate_wave_dependencies "$test_plan" "1")
  assert_equals "2" "$result" "Simple chain: Phase 1 complete -> Phase 2 ready"

  # Test 2: Phases 1,2 complete, should return phases 3,4 (parallel wave)
  result=$(recalculate_wave_dependencies "$test_plan" "1 2")
  # Sort the result for comparison
  result=$(echo "$result" | tr ' ' '\n' | sort -n | tr '\n' ' ' | xargs)
  assert_equals "3 4" "$result" "Simple chain: Phases 1,2 complete -> Phases 3,4 ready"

  # Test 3: All complete, should return empty
  result=$(recalculate_wave_dependencies "$test_plan" "1 2 3 4")
  assert_equals "" "$result" "Simple chain: All complete -> No phases ready"

  rm -f "$test_plan"
}

test_complex_dependencies() {
  local test_plan="/tmp/test_plan_complex_$$.md"

  create_test_plan "$test_plan" '# Test Plan

## Phase 0: Pre-Implementation [COMPLETE]

**Dependencies**: depends_on: []

## Phase 0.5: Standards Fix [COMPLETE]

**Dependencies**: depends_on: [0]

## Phase 1: Task Invocation [NOT STARTED]

**Dependencies**: depends_on: [0.5]

## Phase 2: Phase Marker Logic [NOT STARTED]

**Dependencies**: depends_on: [1]

## Phase 3: Context Tracking [NOT STARTED]

**Dependencies**: depends_on: [2]
'

  # Test: Phases 0, 0.5 complete, should return phase 1
  local result=$(recalculate_wave_dependencies "$test_plan" "0 0.5")
  assert_equals "1" "$result" "Complex deps: Phases 0,0.5 complete -> Phase 1 ready"

  rm -f "$test_plan"
}

test_no_dependencies() {
  local test_plan="/tmp/test_plan_nodeps_$$.md"

  create_test_plan "$test_plan" '# Test Plan

## Phase 1: Independent Task A [NOT STARTED]

**Dependencies**: depends_on: []

## Phase 2: Independent Task B [NOT STARTED]

**Dependencies**: depends_on: []

## Phase 3: Independent Task C [NOT STARTED]

**Dependencies**: depends_on: []
'

  # Test: No phases complete, all should be ready (full parallel)
  local result=$(recalculate_wave_dependencies "$test_plan" "")
  result=$(echo "$result" | tr ' ' '\n' | sort -n | tr '\n' ' ' | xargs)
  assert_equals "1 2 3" "$result" "No deps: All phases ready for parallel execution"

  rm -f "$test_plan"
}

test_empty_completed_phases() {
  local test_plan="/tmp/test_plan_empty_$$.md"

  create_test_plan "$test_plan" '# Test Plan

## Phase 1: First Phase [NOT STARTED]

**Dependencies**: depends_on: []

## Phase 2: Second Phase [NOT STARTED]

**Dependencies**: depends_on: [1]
'

  # Test: Empty completed list, should return phases with no dependencies
  local result=$(recalculate_wave_dependencies "$test_plan" "")
  assert_equals "1" "$result" "Empty completed: Only phase 1 (no deps) ready"

  rm -f "$test_plan"
}

test_phase_status_markers() {
  local test_plan="/tmp/test_plan_markers_$$.md"

  create_test_plan "$test_plan" '# Test Plan

## Phase 1: Setup [COMPLETE]

**Dependencies**: depends_on: []

## Phase 2: Implementation [IN PROGRESS]

**Dependencies**: depends_on: [1]

## Phase 3: Testing [NOT STARTED]

**Dependencies**: depends_on: [2]
'

  # Test: Phase status from markers (phase 1 complete via marker)
  local result=$(recalculate_wave_dependencies "$test_plan" "")
  assert_equals "2" "$result" "Status markers: Phase 1 [COMPLETE] -> Phase 2 ready"

  rm -f "$test_plan"
}

# ============================================================================
# RUN TESTS
# ============================================================================

echo "Running dependency-recalculation.sh unit tests..."
echo ""

test_simple_dependency_chain
test_complex_dependencies
test_no_dependencies
test_empty_completed_phases
test_phase_status_markers

echo ""
echo "================================================"
echo "Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "================================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
  exit 1
fi

exit 0
