#!/bin/bash
# Validate that orchestrate.md has no SlashCommand calls and all Task invocations are present

ORCHESTRATE_FILE=".claude/commands/orchestrate.md"

echo "=== Orchestrate Implementation Validation ==="
echo ""

# Test 1: No SlashCommand tool usage (only documentation references)
echo "Test 1: Checking for prohibited SlashCommand invocations..."
# Exclude lines that are comments (start with <!-- or #)
if grep -v '^[[:space:]]*<!--' "$ORCHESTRATE_FILE" | grep -v '^[[:space:]]*#' | grep -q 'SlashCommand('; then
  echo "❌ FAIL: Found SlashCommand invocation (prohibited)"
  echo "Found at:"
  grep -v '^[[:space:]]*<!--' "$ORCHESTRATE_FILE" | grep -v '^[[:space:]]*#' | grep -n 'SlashCommand('
  exit 1
fi
echo "✓ PASS: No SlashCommand invocations found"
echo ""

# Test 2: Task invocations present in retry loops
echo "Test 2: Counting Task invocations..."
TASK_COUNT=$(grep -c "^  *Task {" "$ORCHESTRATE_FILE" || echo 0)
echo "Found: $TASK_COUNT Task invocations"
if [ "$TASK_COUNT" -lt 6 ]; then
  echo "❌ FAIL: Expected at least 6 Task invocations (3 research + 3 planning)"
  echo "  Found: $TASK_COUNT"
  exit 1
fi
echo "✓ PASS: Found $TASK_COUNT Task invocations (expected ≥6)"
echo ""

# Test 3: Research retry loop has invocations
echo "Test 3: Verifying research retry loop has Task invocations..."
RESEARCH_TASKS=$(awk '/for topic in.*REPORT_PATHS/,/^done$/' "$ORCHESTRATE_FILE" | grep -c "Task {" || echo 0)
if [ "$RESEARCH_TASKS" -ne 3 ]; then
  echo "❌ FAIL: Research loop should have 3 Task invocations"
  echo "  Found: $RESEARCH_TASKS"
  exit 1
fi
echo "✓ PASS: Research retry loop has 3 Task invocations"
echo ""

# Test 4: Planning retry loop has invocations
echo "Test 4: Verifying planning retry loop has Task invocations..."
PLANNING_TASKS=$(awk '/Planning phase with auto-retry/,/Planning phase complete/' "$ORCHESTRATE_FILE" | grep -c "Task {" || echo 0)
if [ "$PLANNING_TASKS" -ne 3 ]; then
  echo "❌ FAIL: Planning loop should have 3 Task invocations"
  echo "  Found: $PLANNING_TASKS"
  exit 1
fi
echo "✓ PASS: Planning retry loop has 3 Task invocations"
echo ""

# Test 5: Case statements have all 3 branches
echo "Test 5: Verifying case statement completeness..."
STANDARD_CASES=$(grep -c 'standard)' "$ORCHESTRATE_FILE" || echo 0)
ULTRA_CASES=$(grep -c 'ultra_explicit)' "$ORCHESTRATE_FILE" || echo 0)
STEP_CASES=$(grep -c 'step_by_step)' "$ORCHESTRATE_FILE" || echo 0)

if [ "$STANDARD_CASES" -lt 2 ] || [ "$ULTRA_CASES" -lt 2 ] || [ "$STEP_CASES" -lt 2 ]; then
  echo "❌ FAIL: Case statements incomplete"
  echo "  standard) cases: $STANDARD_CASES (expected ≥2)"
  echo "  ultra_explicit) cases: $ULTRA_CASES (expected ≥2)"
  echo "  step_by_step) cases: $STEP_CASES (expected ≥2)"
  exit 1
fi
echo "✓ PASS: All case statements complete"
echo "  standard) cases: $STANDARD_CASES"
  echo "  ultra_explicit) cases: $ULTRA_CASES"
echo "  step_by_step) cases: $STEP_CASES"
echo ""

# Test 6: Context preparation exists
echo "Test 6: Verifying context preparation..."
if ! grep -q "Prepare planning context" "$ORCHESTRATE_FILE"; then
  echo "❌ FAIL: Planning context preparation not found"
  exit 1
fi
if ! grep -q "WORKFLOW_DESCRIPTION=" "$ORCHESTRATE_FILE"; then
  echo "❌ FAIL: WORKFLOW_DESCRIPTION variable not set"
  exit 1
fi
if ! grep -q "RESEARCH_REPORTS_LIST=" "$ORCHESTRATE_FILE"; then
  echo "❌ FAIL: RESEARCH_REPORTS_LIST variable not set"
  exit 1
fi
echo "✓ PASS: Context preparation exists"
echo ""

echo "=== All Validation Tests Passed ==="
echo ""
echo "Summary:"
echo "  ✓ No SlashCommand invocations (pure Task tool usage)"
echo "  ✓ $TASK_COUNT total Task invocations"
echo "  ✓ Research retry loop: 3 Task invocations"
echo "  ✓ Planning retry loop: 3 Task invocations"
echo "  ✓ All case statements complete (3 branches each)"
echo "  ✓ Context preparation implemented"
echo ""
echo "/orchestrate is correctly implemented with behavioral injection pattern!"
