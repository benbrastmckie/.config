#!/usr/bin/env bash
# Unit test: Dependency parsing from Lean plan files

set -euo pipefail

TEST_NAME="Dependency Parsing from Lean Plans"
PASS_COUNT=0
FAIL_COUNT=0

echo "═══════════════════════════════════════════════════════════"
echo " TEST: $TEST_NAME"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test fixture directory
FIXTURE_DIR="$(dirname "$0")/../fixtures"
TEST_PLAN="$FIXTURE_DIR/six_theorem_test_plan.md"

# Test 1: Extract dependency clauses
echo "Test 1: Extract dependency clauses from plan"

# Count phases with dependencies
phases_with_deps=$(grep "^\*\*Dependencies\*\*:" "$TEST_PLAN" | grep -v "depends_on: \[\]" | wc -l)
expected_with_deps=3  # Phases 4, 5, 6 have dependencies

if [ "$phases_with_deps" -eq "$expected_with_deps" ]; then
  echo "  ✅ PASS: Found $phases_with_deps phases with dependencies"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Found $phases_with_deps phases with dependencies (expected $expected_with_deps)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 2: Extract Phase 4 dependencies
echo ""
echo "Test 2: Extract Phase 4 dependencies"
phase4_deps=$(awk '/^### Phase 4:/{flag=1; next} /^### Phase/{flag=0} flag && /^\*\*Dependencies\*\*:/{print; exit}' "$TEST_PLAN" | sed 's/.*depends_on: \[\(.*\)\]/\1/')
expected_deps="Phase 1, Phase 3"

if [ "$phase4_deps" = "$expected_deps" ]; then
  echo "  ✅ PASS: Phase 4 dependencies correct: $phase4_deps"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Phase 4 dependencies incorrect"
  echo "    Expected: $expected_deps"
  echo "    Actual: $phase4_deps"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 3: Extract Phase 5 dependencies
echo ""
echo "Test 3: Extract Phase 5 dependencies"
phase5_deps=$(awk '/^### Phase 5:/{flag=1; next} /^### Phase/{flag=0} flag && /^\*\*Dependencies\*\*:/{print; exit}' "$TEST_PLAN" | sed 's/.*depends_on: \[\(.*\)\]/\1/')
expected_deps="Phase 2"

if [ "$phase5_deps" = "$expected_deps" ]; then
  echo "  ✅ PASS: Phase 5 dependencies correct: $phase5_deps"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Phase 5 dependencies incorrect"
  echo "    Expected: $expected_deps"
  echo "    Actual: $phase5_deps"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 4: Extract Phase 6 dependencies
echo ""
echo "Test 4: Extract Phase 6 dependencies"
phase6_deps=$(awk '/^### Phase 6:/{flag=1; next} /^### Phase/{flag=0} flag && /^\*\*Dependencies\*\*:/{print; exit}' "$TEST_PLAN" | sed 's/.*depends_on: \[\(.*\)\]/\1/')
expected_deps="Phase 2"

if [ "$phase6_deps" = "$expected_deps" ]; then
  echo "  ✅ PASS: Phase 6 dependencies correct: $phase6_deps"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Phase 6 dependencies incorrect"
  echo "    Expected: $expected_deps"
  echo "    Actual: $phase6_deps"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Test 5: Verify independent phases (no dependencies)
echo ""
echo "Test 5: Verify independent phases (Phases 1, 2, 3)"
independent_phases=$(grep "^\*\*Dependencies\*\*: depends_on: \[\]" "$TEST_PLAN" | wc -l)
expected_independent=3

if [ "$independent_phases" -eq "$expected_independent" ]; then
  echo "  ✅ PASS: $independent_phases independent phases found"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo "  ❌ FAIL: Found $independent_phases independent phases (expected $expected_independent)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo " TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"
echo "Total: $((PASS_COUNT + FAIL_COUNT))"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "Result: ✅ ALL TESTS PASSED"
  exit 0
else
  echo "Result: ❌ SOME TESTS FAILED"
  exit 1
fi
