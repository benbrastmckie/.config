#!/usr/bin/env bash
# Test orchestrate planning phase behavioral injection pattern

set -euo pipefail

# Test framework
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  echo "✓ PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "✗ FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "════════════════════════════════════════════════"
echo "Orchestrate Planning Behavioral Injection Tests"
echo "════════════════════════════════════════════════"
echo ""

# ============================================================================
# Test 1: Plan path pre-calculation uses topic-based structure
# ============================================================================

echo "Test 1: Verify plan path pre-calculation uses topic-based structure"

# Check orchestrate.md contains path pre-calculation logic
ORCHESTRATE_FILE="$PROJECT_ROOT/commands/orchestrate.md"

# Updated to check for unified location detection library (replaces create_topic_artifact)
if grep -q "unified-location-detection.sh\|ARTIFACT_PLANS" "$ORCHESTRATE_FILE"; then
  pass "orchestrate.md uses unified location detection for plan path"
else
  fail "orchestrate.md missing unified location detection for plan path"
fi

# Verify topic-based path format is documented (flexible pattern matching)
if grep -q "specs/.*NNN.*plans\|specs/{NNN_workflow}/plans\|specs/{NNN_topic}" "$ORCHESTRATE_FILE"; then
  pass "Topic-based path format documented in orchestrate.md"
else
  fail "Topic-based path format not documented"
fi

# ============================================================================
# Test 2: plan-architect agent does NOT invoke /plan
# ============================================================================

echo ""
echo "Test 2: Verify plan-architect agent does NOT invoke /plan"

AGENT_FILE="$PROJECT_ROOT/agents/plan-architect.md"

# Verify no SlashCommand(/plan) instructions
if grep -q "SlashCommand.*\/plan\|invoke \/plan\|USE.*\/plan.*command" "$AGENT_FILE"; then
  fail "plan-architect.md contains /plan invocation instructions"
  grep -n "SlashCommand\|invoke /plan\|USE.*\/plan" "$AGENT_FILE" | head -3
else
  pass "plan-architect.md does NOT invoke /plan"
fi

# Verify instructs to use Write tool instead
if grep -q "Write tool\|CREATE.*at.*path\|PLAN_PATH" "$AGENT_FILE"; then
  pass "plan-architect.md instructs direct file creation"
else
  fail "plan-architect.md missing Write tool instructions"
fi

# Verify return format is PLAN_CREATED (not PLAN_PATH)
if grep -q "PLAN_CREATED:" "$AGENT_FILE"; then
  pass "plan-architect.md uses PLAN_CREATED return format"
else
  fail "plan-architect.md missing PLAN_CREATED return format"
fi

# ============================================================================
# Test 3: Plan includes research reports in metadata
# ============================================================================

echo ""
echo "Test 3: Verify plan-architect includes research reports cross-reference requirement"

# Verify agent behavioral file requires research reports in metadata
if grep -q "Research Reports.*metadata\|Include ALL.*research reports" "$AGENT_FILE"; then
  pass "plan-architect.md requires research reports in metadata"
else
  fail "plan-architect.md missing research reports requirement"
fi

# Verify orchestrate.md passes research reports to agent
if grep -q "RESEARCH_REPORT_PATHS_FORMATTED" "$ORCHESTRATE_FILE" && \
   grep -q "Cross-Reference Requirements" "$ORCHESTRATE_FILE"; then
  pass "orchestrate.md passes research reports for cross-referencing"
else
  fail "orchestrate.md missing research report cross-reference passing"
fi

# Verify orchestrate.md verification checks for cross-references
if grep -q "Verify.*research reports.*cross-reference\|Research Reports.*metadata" "$ORCHESTRATE_FILE"; then
  pass "orchestrate.md verifies research reports cross-referenced"
else
  fail "orchestrate.md missing cross-reference verification"
fi

# ============================================================================
# Test 4: Summary includes all artifacts cross-reference
# ============================================================================

echo ""
echo "Test 4: Verify summary template includes all artifacts"

# Verify summary template has "Artifacts Generated" section
if grep -q "### Artifacts Generated" "$ORCHESTRATE_FILE"; then
  pass "Summary template includes 'Artifacts Generated' section"
else
  fail "Summary template missing 'Artifacts Generated' section"
fi

# Verify summary template includes Research Reports subsection
if grep -A 10 "### Artifacts Generated" "$ORCHESTRATE_FILE" | grep -q "\*\*Research Reports\*\*:"; then
  pass "Summary template includes 'Research Reports' subsection"
else
  fail "Summary template missing 'Research Reports' subsection"
fi

# Verify summary template includes Implementation Plan subsection
if grep -A 20 "### Artifacts Generated" "$ORCHESTRATE_FILE" | grep -q "\*\*Implementation Plan\*\*:"; then
  pass "Summary template includes 'Implementation Plan' subsection"
else
  fail "Summary template missing 'Implementation Plan' subsection"
fi

# ============================================================================
# Test 5: workflow-phases.md updated with behavioral injection pattern
# ============================================================================

echo ""
echo "Test 5: Verify workflow-phases.md planning template updated"

WORKFLOW_PHASES_FILE="$PROJECT_ROOT/docs/reference/workflow-phases.md"

# Verify path pre-calculation documented
if grep -q "Path Pre-Calculation\|create_topic_artifact.*plans" "$WORKFLOW_PHASES_FILE"; then
  pass "workflow-phases.md documents path pre-calculation"
else
  fail "workflow-phases.md missing path pre-calculation"
fi

# Verify behavioral injection documented
if grep -q "Behavioral Injection.*PLAN_PATH\|Pass pre-calculated PLAN_PATH" "$WORKFLOW_PHASES_FILE"; then
  pass "workflow-phases.md documents behavioral injection"
else
  fail "workflow-phases.md missing behavioral injection documentation"
fi

# Verify does NOT say "can invoke /plan"
if grep -q "can invoke \/plan\|Agent.*\/plan.*command" "$WORKFLOW_PHASES_FILE"; then
  fail "workflow-phases.md still mentions /plan invocation"
else
  pass "workflow-phases.md does NOT mention /plan invocation"
fi

# ============================================================================
# Test 6: Context reduction metadata extraction
# ============================================================================

echo ""
echo "Test 6: Verify metadata extraction for context reduction"

# Verify orchestrate.md extracts metadata (not full plan)
if grep -q "PLAN_PHASE_COUNT\|PLAN_COMPLEXITY\|PLAN_HOURS.*Extract" "$ORCHESTRATE_FILE"; then
  pass "orchestrate.md extracts plan metadata"
else
  fail "orchestrate.md missing metadata extraction"
fi

# Verify context reduction documented
if grep -q "Context reduction.*metadata.*not full plan\|95% reduction" "$ORCHESTRATE_FILE"; then
  pass "Context reduction strategy documented"
else
  fail "Context reduction strategy not documented"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "════════════════════════════════════════════════"
echo "Test Summary"
echo "════════════════════════════════════════════════"
echo "PASS: $PASS_COUNT"
echo "FAIL: $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Some tests failed"
  exit 1
fi
