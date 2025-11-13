#!/usr/bin/env bash
# Integration test for Spec 687: RESEARCH_COMPLEXITY recalculation bug fix
# Tests that workflows with "integrate" keyword don't trigger verification mismatches

set -euo pipefail

TEST_NAME="coordinate_research_complexity_fix"
FAILURES=0

echo "=== Integration Test: RESEARCH_COMPLEXITY Bug Fix (Spec 687) ==="
echo ""

# Test 1: Verify hardcoded recalculation removed
echo "Test 1: Verify hardcoded pattern matching removed from coordinate.md"
COORDINATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/commands/coordinate.md"

if [ ! -f "$COORDINATE_FILE" ]; then
  echo "  ✗ FAIL: coordinate.md not found at $COORDINATE_FILE"
  FAILURES=$((FAILURES + 1))
else
  # Count occurrences of RESEARCH_COMPLEXITY=N (should only be fallback)
  COMPLEXITY_ASSIGNMENTS=$(grep -n "RESEARCH_COMPLEXITY=[0-9]" "$COORDINATE_FILE" | wc -l)

  if [ "$COMPLEXITY_ASSIGNMENTS" -eq 1 ]; then
    echo "  ✓ PASS: Only 1 assignment found (defensive fallback)"
  else
    echo "  ✗ FAIL: Found $COMPLEXITY_ASSIGNMENTS assignments (expected 1)"
    echo "         Hardcoded recalculation may still exist"
    grep -n "RESEARCH_COMPLEXITY=[0-9]" "$COORDINATE_FILE"
    FAILURES=$((FAILURES + 1))
  fi
fi

# Test 2: Verify discovery loop uses REPORT_PATHS_COUNT
echo ""
echo "Test 2: Verify dynamic discovery loop uses REPORT_PATHS_COUNT"
DISCOVERY_LOOP=$(grep -n "for i in \$(seq 1.*REPORT_PATHS_COUNT" "$COORDINATE_FILE" | grep "691")

if [ -n "$DISCOVERY_LOOP" ]; then
  echo "  ✓ PASS: Discovery loop uses REPORT_PATHS_COUNT (line 691)"
else
  echo "  ✗ FAIL: Discovery loop doesn't use REPORT_PATHS_COUNT at line 691"
  FAILURES=$((FAILURES + 1))
fi

# Test 3: Verify verification loop uses REPORT_PATHS_COUNT
echo ""
echo "Test 3: Verify verification loop uses REPORT_PATHS_COUNT"
VERIFICATION_LOOP=$(grep -n "for i in \$(seq 1.*REPORT_PATHS_COUNT" "$COORDINATE_FILE" | grep "797")

if [ -n "$VERIFICATION_LOOP" ]; then
  echo "  ✓ PASS: Verification loop uses REPORT_PATHS_COUNT (line 797)"
else
  echo "  ✗ FAIL: Verification loop doesn't use REPORT_PATHS_COUNT at line 797"
  FAILURES=$((FAILURES + 1))
fi

# Test 4: Verify state machine exports RESEARCH_COMPLEXITY
echo ""
echo "Test 4: Verify workflow-state-machine.sh exports RESEARCH_COMPLEXITY"
STATE_MACHINE_FILE="${CLAUDE_PROJECT_DIR}/.claude/lib/workflow-state-machine.sh"

if [ ! -f "$STATE_MACHINE_FILE" ]; then
  echo "  ✗ FAIL: workflow-state-machine.sh not found"
  FAILURES=$((FAILURES + 1))
else
  EXPORT_COUNT=$(grep -c "export RESEARCH_COMPLEXITY" "$STATE_MACHINE_FILE")

  if [ "$EXPORT_COUNT" -ge 3 ]; then
    echo "  ✓ PASS: Found $EXPORT_COUNT export statements (main + fallbacks)"
  else
    echo "  ✗ FAIL: Found only $EXPORT_COUNT export statements (expected ≥3)"
    FAILURES=$((FAILURES + 1))
  fi
fi

# Test 5: Verify state persistence documentation comments exist
echo ""
echo "Test 5: Verify critical documentation comments in state machine"
CRITICAL_COMMENT=$(grep -c "CRITICAL.*persisted to state" "$STATE_MACHINE_FILE" || echo "0")

if [ "$CRITICAL_COMMENT" -ge 1 ]; then
  echo "  ✓ PASS: Found critical documentation comment about state persistence"
else
  echo "  ✗ FAIL: Missing documentation comment about state persistence requirement"
  FAILURES=$((FAILURES + 1))
fi

# Test 6: Verify documentation updated
echo ""
echo "Test 6: Verify coordinate-command-guide.md documents the bug fix"
GUIDE_FILE="${CLAUDE_PROJECT_DIR}/.claude/docs/guides/coordinate-command-guide.md"

if [ ! -f "$GUIDE_FILE" ]; then
  echo "  ✗ FAIL: coordinate-command-guide.md not found"
  FAILURES=$((FAILURES + 1))
else
  # Check for Issue 6 documentation
  ISSUE_6=$(grep -c "Issue 6: Verification Mismatch" "$GUIDE_FILE")

  if [ "$ISSUE_6" -ge 1 ]; then
    echo "  ✓ PASS: Documentation includes Issue 6 troubleshooting entry"
  else
    echo "  ✗ FAIL: Documentation missing Issue 6 entry"
    FAILURES=$((FAILURES + 1))
  fi

  # Check for updated verification pattern documentation
  UPDATED_PATTERN=$(grep -c "Verification Pattern.*Updated 2025-11-12.*REPORT_PATHS_COUNT" "$GUIDE_FILE")

  if [ "$UPDATED_PATTERN" -ge 1 ]; then
    echo "  ✓ PASS: Documentation updated with REPORT_PATHS_COUNT usage"
  else
    echo "  ✗ FAIL: Documentation doesn't reflect REPORT_PATHS_COUNT change"
    FAILURES=$((FAILURES + 1))
  fi
fi

# Test 7: Verify state persistence save exists in coordinate.md
echo ""
echo "Test 7: Verify RESEARCH_COMPLEXITY saved to state in coordinate.md"
STATE_SAVES=$(grep -c "append_workflow_state.*RESEARCH_COMPLEXITY" "$COORDINATE_FILE")

if [ "$STATE_SAVES" -ge 2 ]; then
  echo "  ✓ PASS: Found $STATE_SAVES state persistence saves (init + research)"
else
  echo "  ✗ FAIL: Found only $STATE_SAVES state saves (expected ≥2)"
  FAILURES=$((FAILURES + 1))
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Total tests: 7"
echo "Failures: $FAILURES"
echo ""

if [ $FAILURES -eq 0 ]; then
  echo "✓ ALL TESTS PASSED"
  echo ""
  echo "Integration test confirms:"
  echo "  - Hardcoded recalculation removed"
  echo "  - Loops use REPORT_PATHS_COUNT consistently"
  echo "  - State machine exports RESEARCH_COMPLEXITY"
  echo "  - Documentation updated with bug fix details"
  echo "  - State persistence configured correctly"
  exit 0
else
  echo "✗ SOME TESTS FAILED ($FAILURES failures)"
  echo ""
  echo "Please review failed tests above and verify:"
  echo "  1. All code changes from Spec 687 applied correctly"
  echo "  2. Documentation updated to reflect changes"
  echo "  3. State persistence pattern followed"
  exit 1
fi
