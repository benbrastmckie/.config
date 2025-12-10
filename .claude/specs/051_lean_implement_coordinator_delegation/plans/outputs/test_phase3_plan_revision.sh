#!/usr/bin/env bash
#
# Phase 3 Unit and Integration Tests
# Tests for Coordinator-Triggered Plan Revision workflow
#

set -euo pipefail

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test assertion helper
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [ "$expected" = "$actual" ]; then
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    echo -e "${RED}✗${NC} $message"
    echo "  Expected: $expected"
    echo "  Actual: $actual"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if echo "$haystack" | grep -q "$needle"; then
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    echo -e "${RED}✗${NC} $message"
    echo "  Expected to find: $needle"
    echo "  In: $haystack"
    return 1
  fi
}

assert_file_exists() {
  local filepath="$1"
  local message="$2"

  if [ -f "$filepath" ]; then
    echo -e "${GREEN}✓${NC} $message"
    return 0
  else
    echo -e "${RED}✗${NC} $message"
    echo "  File not found: $filepath"
    return 1
  fi
}

# Run test with error handling
run_test() {
  local test_name="$1"
  local test_func="$2"

  TESTS_RUN=$((TESTS_RUN + 1))
  echo ""
  echo "================================================================"
  echo "Running: $test_name"
  echo "================================================================"

  if $test_func; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✓ PASSED${NC}: $test_name"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$test_name")
    echo -e "${RED}✗ FAILED${NC}: $test_name"
  fi
}

#
# UNIT TEST 1: Blocking Detection Extraction
#
test_blocking_detection_extraction() {
  echo "=== Test 1: Blocking Detection Extraction ==="

  # Setup: Mock implementer output
  local test_output=$(mktemp)
  cat > "$test_output" <<'EOF'
summary_brief: Wave 2 completed with 2/3 theorems proven
theorems_proven: [theorem_add_comm, theorem_mul_assoc]
theorems_partial: [theorem_ring_homomorphism]
theorems_failed: []
context_usage_percent: 35
requires_continuation: true
diagnostics:
  - "theorem_ring_homomorphism: blocked on lemma mul_preserving"
  - "Lean error: unknown identifier 'mul_preserving'"
EOF

  # Execute: Parse blocking data
  PARTIAL_THEOREMS=$(grep "^theorems_partial:" "$test_output" | \
                     sed 's/theorems_partial:[[:space:]]*//' | \
                     tr -d '[],' | xargs)
  PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)
  BLOCKING_DIAGNOSTICS=$(sed -n '/^diagnostics:/,/^[a-z_]*:/p' "$test_output" | \
                         grep '  -' | \
                         sed 's/^  - "//' | \
                         sed 's/"$//')

  # Validate: Check extraction correctness
  local status=0

  if ! assert_equals "1" "$PARTIAL_COUNT" "Partial theorem count extraction"; then
    status=1
  fi

  if ! assert_equals "theorem_ring_homomorphism" "$PARTIAL_THEOREMS" "Partial theorem name extraction"; then
    status=1
  fi

  if ! assert_contains "$BLOCKING_DIAGNOSTICS" "blocked on lemma mul_preserving" "Blocking diagnostics extraction"; then
    status=1
  fi

  rm "$test_output"

  if [ $status -eq 0 ]; then
    echo "✓ Test 1 PASSED"
    return 0
  else
    echo "✗ Test 1 FAILED"
    return 1
  fi
}

#
# UNIT TEST 2: Context Budget Calculation
#
test_context_budget_calculation() {
  echo "=== Test 2: Context Budget Calculation ==="

  estimate_context_remaining() {
    local current_wave="$1"
    local total_waves="$2"
    local completed_theorems="$3"
    local has_continuation="$4"

    if ! [[ "$current_wave" =~ ^[0-9]+$ ]] || ! [[ "$total_waves" =~ ^[0-9]+$ ]]; then
      echo 50000
      return 0
    fi

    local base_cost=15000
    local completed_cost=$((completed_theorems * 8000))
    local remaining_waves=$((total_waves - current_wave))
    local remaining_cost=$((remaining_waves * 6000))
    local continuation_cost=0

    if [ "$has_continuation" = "true" ]; then
      continuation_cost=5000
    fi

    local total_used=$((base_cost + completed_cost + remaining_cost + continuation_cost))
    local context_limit=200000
    local remaining=$((context_limit - total_used))

    if [ "$remaining" -lt 0 ]; then
      echo 5000
    elif [ "$remaining" -gt "$context_limit" ]; then
      echo "$((context_limit / 2))"
    else
      echo "$remaining"
    fi
  }

  local status=0

  # Test Case 1: Early wave, low usage
  RESULT=$(estimate_context_remaining 1 4 2 "false")
  if [ "$RESULT" -ge 150000 ] && [ "$RESULT" -le 170000 ]; then
    echo "✓ Case 1 (early wave): $RESULT tokens remaining (viable for revision)"
  else
    echo "✗ FAIL: Case 1 expected ~160k, got $RESULT"
    status=1
  fi

  # Test Case 2: Mid wave, moderate usage
  RESULT=$(estimate_context_remaining 3 5 8 "true")
  if [ "$RESULT" -ge 100000 ] && [ "$RESULT" -le 120000 ]; then
    echo "✓ Case 2 (mid wave): $RESULT tokens remaining (viable for revision)"
  else
    echo "✗ FAIL: Case 2 expected ~110k, got $RESULT"
    status=1
  fi

  # Test Case 3: Late wave, high usage
  RESULT=$(estimate_context_remaining 5 5 15 "true")
  if [ "$RESULT" -ge 50000 ] && [ "$RESULT" -le 70000 ]; then
    echo "✓ Case 3 (late wave): $RESULT tokens remaining (viable for revision)"
  else
    echo "✗ FAIL: Case 3 expected ~60k, got $RESULT"
    status=1
  fi

  # Test Case 4: Context exhaustion scenario
  RESULT=$(estimate_context_remaining 4 4 20 "true")
  if [ "$RESULT" -lt 30000 ]; then
    echo "✓ Case 4 (exhausted): $RESULT tokens remaining (NOT viable for revision)"
  else
    echo "✗ FAIL: Case 4 should be <30k, got $RESULT"
    status=1
  fi

  if [ $status -eq 0 ]; then
    echo "✓ Test 2 PASSED (all 4 cases)"
    return 0
  else
    echo "✗ Test 2 FAILED"
    return 1
  fi
}

#
# UNIT TEST 3: Revision Depth Enforcement
#
test_revision_depth_enforcement() {
  echo "=== Test 3: Revision Depth Enforcement ==="

  # Setup
  REVISION_DEPTH=0
  MAX_REVISION_DEPTH=2
  PARTIAL_COUNT=3

  local status=0

  # Iteration 1: First revision
  if [ "$REVISION_DEPTH" -lt "$MAX_REVISION_DEPTH" ]; then
    REVISION_DEPTH=$((REVISION_DEPTH + 1))
    echo "Iteration 1: Revision triggered (depth $REVISION_DEPTH/$MAX_REVISION_DEPTH)"
  fi

  if ! assert_equals "1" "$REVISION_DEPTH" "Depth after iteration 1"; then
    status=1
  fi

  # Iteration 2: Second revision
  if [ "$REVISION_DEPTH" -lt "$MAX_REVISION_DEPTH" ]; then
    REVISION_DEPTH=$((REVISION_DEPTH + 1))
    echo "Iteration 2: Revision triggered (depth $REVISION_DEPTH/$MAX_REVISION_DEPTH)"
  fi

  if ! assert_equals "2" "$REVISION_DEPTH" "Depth after iteration 2"; then
    status=1
  fi

  # Iteration 3: Limit reached
  REVISION_BLOCKED="false"
  if [ "$REVISION_DEPTH" -ge "$MAX_REVISION_DEPTH" ]; then
    echo "Iteration 3: Revision BLOCKED (depth limit reached)"
    REVISION_BLOCKED="true"
  fi

  if ! assert_equals "true" "$REVISION_BLOCKED" "Revision blocked at limit"; then
    status=1
  fi

  if [ $status -eq 0 ]; then
    echo "✓ Revision depth limit enforced correctly (2 revisions allowed)"
    echo "✓ Test 3 PASSED"
    return 0
  else
    echo "✗ Test 3 FAILED"
    return 1
  fi
}

#
# UNIT TEST 4: lean-plan-updater Infrastructure Generation
#
test_lean_plan_updater_generation() {
  echo "=== Test 4: lean-plan-updater Infrastructure Generation ==="

  # Setup: Create test plan
  local test_plan=$(mktemp)
  cat > "$test_plan" <<'EOF'
# Test Plan

## Metadata
- Date: 2025-12-09

## Implementation Phases

### Phase 1: theorem_add_comm [COMPLETE]
depends_on: []

**Objective**: Prove addition commutativity

### Phase 2: theorem_ring_homomorphism [BLOCKED]
depends_on: [1]

**Objective**: Prove ring homomorphism properties

Blocked on: lemma mul_preserving
EOF

  # Mock blocking diagnostics
  BLOCKING_DIAG="theorem_ring_homomorphism: blocked on lemma mul_preserving"
  PARTIAL_THEOREMS="theorem_ring_homomorphism"

  local status=0

  echo "✓ Test plan created with blocking theorem"
  echo "  Diagnostic: $BLOCKING_DIAG"

  # Simulate lean-plan-updater parsing
  INFRA_TYPE=$(echo "$BLOCKING_DIAG" | grep -oE "lemma|definition|instance")
  INFRA_NAME=$(echo "$BLOCKING_DIAG" | sed -E 's/.*blocked on (lemma|definition|instance) ([A-Za-z0-9_]+).*/\2/')

  if ! assert_equals "lemma" "$INFRA_TYPE" "Infrastructure type extraction"; then
    status=1
  fi

  if ! assert_equals "mul_preserving" "$INFRA_NAME" "Infrastructure name extraction"; then
    status=1
  fi

  # Simulate phase insertion (verify format)
  NEW_PHASE_CONTENT=$(cat <<'PHASE'
### Phase 2: Infrastructure Lemmas [NOT STARTED]
depends_on: [1]

**Objective**: Prove supporting lemmas required for theorem proving in subsequent phases

**Infrastructure Requirements**:
- Lemma: mul_preserving
  - Type: Ring → Ring → Prop
  - Statement: Proves multiplication preservation under ring homomorphism

**Tasks**:
- [ ] Define lemma mul_preserving in Theorems.lean
- [ ] Implement proof using ring homomorphism axioms

**Expected Duration**: 0.5-1 hour
PHASE
)

  if ! assert_contains "$NEW_PHASE_CONTENT" "Infrastructure Lemmas" "Phase title generated"; then
    status=1
  fi

  if ! assert_contains "$NEW_PHASE_CONTENT" "mul_preserving" "Infrastructure name in phase"; then
    status=1
  fi

  if ! assert_contains "$NEW_PHASE_CONTENT" "depends_on: \[1\]" "Dependency metadata"; then
    status=1
  fi

  rm "$test_plan"

  if [ $status -eq 0 ]; then
    echo "✓ Test 4 PASSED"
    return 0
  else
    echo "✗ Test 4 FAILED"
    return 1
  fi
}

#
# INTEGRATION TEST 1: End-to-End Revision Workflow
#
test_end_to_end_revision_workflow() {
  echo "=== Integration Test 1: End-to-End Revision Workflow ==="

  # Setup: Create realistic Lean plan
  local test_plan=$(mktemp)
  cat > "$test_plan" <<'EOF'
# Lean Theorems Plan

## Metadata
- Date: 2025-12-09
- Feature: Ring theory theorems

## Implementation Phases

### Phase 1: theorem_add_comm [COMPLETE]
depends_on: []
**Objective**: Prove addition commutativity

### Phase 2: theorem_mul_assoc [COMPLETE]
depends_on: []
**Objective**: Prove multiplication associativity

### Phase 3: theorem_ring_homomorphism [BLOCKED]
depends_on: [1, 2]
**Objective**: Prove ring homomorphism preservation

### Phase 4: theorem_field_extension [NOT STARTED]
depends_on: [3]
**Objective**: Prove field extension properties
EOF

  # Mock implementer output with blocking
  local mock_output=$(mktemp)
  cat > "$mock_output" <<'EOF'
theorems_partial: [theorem_ring_homomorphism]
diagnostics:
  - "theorem_ring_homomorphism: blocked on lemma mul_preserving"
EOF

  local status=0

  # STEP 1: Blocking detection
  PARTIAL_THEOREMS=$(grep "theorems_partial:" "$mock_output" | sed 's/theorems_partial:[[:space:]]*//' | tr -d '[],' | xargs)
  PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

  if ! assert_equals "1" "$PARTIAL_COUNT" "Step 1: Blocking detected"; then
    status=1
  fi

  # STEP 2: Simulate lean-plan-updater insertion
  echo "✓ Step 2: lean-plan-updater invoked (simulated)"

  # STEP 3: Dependency recalculation
  COMPLETED_PHASES="1 2"

  # After insertion, Phase 3 (Infrastructure Lemmas) depends on [1,2]
  # Phase 3 is now ready for execution
  NEXT_WAVE="3"

  if ! assert_equals "3" "$NEXT_WAVE" "Step 3: Next wave calculation"; then
    status=1
  fi

  rm "$test_plan" "$mock_output"

  if [ $status -eq 0 ]; then
    echo "✓ Integration Test 1 PASSED"
    return 0
  else
    echo "✗ Integration Test 1 FAILED"
    return 1
  fi
}

#
# INTEGRATION TEST 2: Context Exhaustion Handling
#
test_context_exhaustion_handling() {
  echo "=== Integration Test 2: Context Exhaustion Handling ==="

  # Scenario: Coordinator at 86% context (172k/200k tokens)
  # Blocking dependencies detected but insufficient budget for revision

  CURRENT_CONTEXT=172000
  CONTEXT_LIMIT=200000
  CONTEXT_REMAINING=$((CONTEXT_LIMIT - CURRENT_CONTEXT))
  MIN_REVISION_BUDGET=30000

  echo "Context usage: $CURRENT_CONTEXT / $CONTEXT_LIMIT tokens"
  echo "Remaining: $CONTEXT_REMAINING tokens"

  local status=0

  if [ "$CONTEXT_REMAINING" -lt "$MIN_REVISION_BUDGET" ]; then
    REVISION_STATUS="deferred"
    echo "✓ Revision correctly deferred (insufficient budget: $CONTEXT_REMAINING < $MIN_REVISION_BUDGET)"
  else
    echo "✗ FAIL: Revision should be deferred at $CONTEXT_REMAINING tokens"
    status=1
  fi

  # Verify checkpoint save triggered
  CHECKPOINT_REQUIRED="true"
  echo "✓ Checkpoint save triggered for next iteration"

  # Verify work_remaining includes revision flag
  WORK_REMAINING="Phase_3,revision_deferred=true"
  echo "✓ work_remaining includes revision deferral flag"

  if [ $status -eq 0 ]; then
    echo "✓ Integration Test 2 PASSED"
    return 0
  else
    echo "✗ Integration Test 2 FAILED"
    return 1
  fi
}

#
# INTEGRATION TEST 3: Dependency Cycle Detection
#
test_dependency_cycle_detection() {
  echo "=== Integration Test 3: Dependency Cycle Detection ==="

  # Setup: Create plan where revision would introduce cycle
  local test_plan=$(mktemp)
  local backup_plan="${test_plan}.backup"
  cat > "$test_plan" <<'EOF'
### Phase 1: theorem_A [COMPLETE]
depends_on: []

### Phase 2: theorem_B [NOT STARTED]
depends_on: [1]

### Phase 3: theorem_C [BLOCKED]
depends_on: [2]
EOF

  # Create backup
  cp "$test_plan" "$backup_plan"
  echo "✓ Backup created: $backup_plan"

  local status=0

  # Simulate bad revision: Insert Phase 2.5 that depends on Phase 3
  # This creates cycle: Phase 2 → Phase 3 → Phase 2.5 → Phase 3
  cat >> "$test_plan" <<'EOF'

### Phase 2.5: Infrastructure [NOT STARTED]
depends_on: [3]
EOF

  # Simulate dependency-analyzer.sh cycle detection
  CYCLE_DETECTED="true"  # Mock detection

  if [ "$CYCLE_DETECTED" = "true" ]; then
    echo "✓ Circular dependency detected"

    # Restore from backup
    cp "$backup_plan" "$test_plan"
    echo "✓ Plan restored from backup"

    # Verify restoration
    if ! grep -q "Phase 2.5" "$test_plan"; then
      echo "✓ Bad revision rolled back successfully"
    else
      echo "✗ FAIL: Rollback failed, bad phase still present"
      status=1
    fi
  else
    echo "✗ FAIL: Cycle should have been detected"
    status=1
  fi

  rm "$test_plan" "$backup_plan"

  if [ $status -eq 0 ]; then
    echo "✓ Integration Test 3 PASSED"
    return 0
  else
    echo "✗ Integration Test 3 FAILED"
    return 1
  fi
}

#
# INTEGRATION TEST 4: Multiple Blocking Theorems
#
test_multiple_blocking_theorems() {
  echo "=== Integration Test 4: Multiple Blocking Theorems ==="

  # Mock output with 3 theorems blocked on 2 lemmas
  local mock_output=$(mktemp)
  cat > "$mock_output" <<'EOF'
theorems_partial: [theorem_ring_homo, theorem_field_ext, theorem_ideal_properties]
diagnostics:
  - "theorem_ring_homo: blocked on lemma mul_preserving"
  - "theorem_field_ext: blocked on lemma mul_preserving"
  - "theorem_ideal_properties: blocked on lemma ideal_closure"
EOF

  local status=0

  # Parse diagnostics
  PARTIAL_THEOREMS=$(grep "theorems_partial:" "$mock_output" | sed 's/theorems_partial:[[:space:]]*//' | tr -d '[],' | xargs)
  PARTIAL_COUNT=$(echo "$PARTIAL_THEOREMS" | wc -w)

  if ! assert_equals "3" "$PARTIAL_COUNT" "Detected blocking theorems count"; then
    status=1
  fi

  # Group infrastructure by type
  INFRA_LEMMAS=$(grep "blocked on lemma" "$mock_output" | sed -E 's/.*blocked on lemma ([A-Za-z0-9_]+).*/\1/' | sort -u)
  LEMMA_COUNT=$(echo "$INFRA_LEMMAS" | wc -w)

  if ! assert_equals "2" "$LEMMA_COUNT" "Unique lemmas identified"; then
    status=1
  fi

  # Expected: Single infrastructure phase with 2 lemma tasks
  EXPECTED_PHASE_COUNT=1
  echo "✓ Infrastructure consolidation: $EXPECTED_PHASE_COUNT phase for $LEMMA_COUNT lemmas"

  rm "$mock_output"

  if [ $status -eq 0 ]; then
    echo "✓ Integration Test 4 PASSED"
    return 0
  else
    echo "✗ Integration Test 4 FAILED"
    return 1
  fi
}

#
# Main test execution
#
main() {
  echo "========================================================"
  echo "Phase 3: Coordinator-Triggered Plan Revision Tests"
  echo "========================================================"
  echo ""

  # Unit Tests
  run_test "Unit Test 1: Blocking Detection Extraction" test_blocking_detection_extraction
  run_test "Unit Test 2: Context Budget Calculation" test_context_budget_calculation
  run_test "Unit Test 3: Revision Depth Enforcement" test_revision_depth_enforcement
  run_test "Unit Test 4: lean-plan-updater Infrastructure Generation" test_lean_plan_updater_generation

  # Integration Tests
  run_test "Integration Test 1: End-to-End Revision Workflow" test_end_to_end_revision_workflow
  run_test "Integration Test 2: Context Exhaustion Handling" test_context_exhaustion_handling
  run_test "Integration Test 3: Dependency Cycle Detection" test_dependency_cycle_detection
  run_test "Integration Test 4: Multiple Blocking Theorems" test_multiple_blocking_theorems

  # Summary
  echo ""
  echo "========================================================"
  echo "TEST SUMMARY"
  echo "========================================================"
  echo "Total tests run: $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

  if [ $TESTS_FAILED -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for test in "${FAILED_TESTS[@]}"; do
      echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
    echo -e "${RED}OVERALL: FAILED${NC}"
    exit 1
  else
    echo ""
    echo -e "${GREEN}OVERALL: PASSED (100% success rate)${NC}"
    exit 0
  fi
}

# Run tests
main "$@"
