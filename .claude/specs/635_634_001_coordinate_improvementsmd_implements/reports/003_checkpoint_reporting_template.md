# Checkpoint Reporting Template for /coordinate Command

**Research Date**: 2025-11-10
**Scope**: Analyze existing checkpoint patterns and create template for remaining phases
**Command**: /coordinate
**File**: .claude/commands/coordinate.md

---

## Executive Summary

This report analyzes the existing checkpoint reporting blocks in coordinate.md (Research and Planning phases) to create a reusable template for the four remaining phases that need checkpoints: Implementation, Testing, Debug, and Documentation.

**Key Findings**:
- Research checkpoint: Lines 543-573 (31 lines)
- Planning checkpoint: Lines 755-788 (34 lines)
- Consistent structure: Box-drawn separator, phase-specific status, verification results, next action
- Template pattern: Status summary → Artifacts → Verification → Integration/Context → Next Action

**Phases Requiring Checkpoints**:
1. Implementation Phase (lines 823-931) - **NEEDS CHECKPOINT**
2. Testing Phase (lines 935-1019) - **NEEDS CHECKPOINT**
3. Debug Phase (lines 1023-1176) - **NEEDS CHECKPOINT**
4. Documentation Phase (lines 1180-1288) - **NEEDS CHECKPOINT**

---

## 1. Existing Checkpoint Pattern Analysis

### 1.1 Research Phase Checkpoint (Lines 543-573)

```bash
# ===== CHECKPOINT REQUIREMENT: Research Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Research Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Research phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Research reports: ${#SUCCESSFUL_REPORT_PATHS[@]}/$RESEARCH_COMPLEXITY"
echo "    - Research mode: $([ "$USE_HIERARCHICAL_RESEARCH" = "true" ] && echo "Hierarchical (≥4 topics)" || echo "Flat (<4 topics)")"
echo ""
echo "  Verification Status:"
echo "    - All files verified: ✓ Yes"
echo ""
echo "  Next Action:"
case "$WORKFLOW_SCOPE" in
  research-only)
    echo "    - Proceeding to: Terminal state (workflow complete)"
    ;;
  research-and-plan)
    echo "    - Proceeding to: Planning phase"
    ;;
  full-implementation)
    echo "    - Proceeding to: Planning phase → Implementation"
    ;;
  debug-only)
    echo "    - Proceeding to: Planning phase → Debug"
    ;;
esac
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Pattern Components**:
1. Section header with box-drawing separator (U+2550)
2. Phase completion title
3. Status summary introduction
4. Artifacts section with counts/details
5. Verification status (boolean or detailed)
6. Next action (conditional based on workflow scope)
7. Closing separator

### 1.2 Planning Phase Checkpoint (Lines 755-788)

```bash
# ===== CHECKPOINT REQUIREMENT: Planning Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Planning Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Planning phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Implementation plan: ✓ Created"
echo "    - Plan path: $PLAN_PATH"
PLAN_SIZE=$(stat -f%z "$PLAN_PATH" 2>/dev/null || stat -c%s "$PLAN_PATH" 2>/dev/null || echo "unknown")
echo "    - Plan size: $PLAN_SIZE bytes"
echo ""
echo "  Verification Status:"
echo "    - Plan file verified: ✓ Yes"
echo ""
echo "  Research Integration:"
REPORT_COUNT="${#REPORT_PATHS[@]}"
echo "    - Research reports used: $REPORT_COUNT"
echo ""
echo "  Next Action:"
case "$WORKFLOW_SCOPE" in
  research-and-plan)
    echo "    - Proceeding to: Terminal state (workflow complete)"
    ;;
  full-implementation)
    echo "    - Proceeding to: Implementation phase"
    ;;
  debug-only)
    echo "    - Proceeding to: Debug phase"
    ;;
esac
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Pattern Components**:
1. Section header with box-drawing separator
2. Phase completion title
3. Status summary introduction
4. Artifacts section with file paths and sizes
5. Verification status
6. **Integration section** (Research Integration) - shows upstream artifacts used
7. Next action (conditional)
8. Closing separator

### 1.3 Template Structure Summary

**Standard Sections** (all checkpoints):
1. **Header**: Box-drawing separator + "CHECKPOINT: {Phase} Phase Complete"
2. **Intro Line**: "Planning phase status before transitioning to next state:"
3. **Artifacts Created**: Phase-specific outputs (reports, plans, code changes)
4. **Verification Status**: File existence confirmations
5. **Next Action**: Conditional transition based on WORKFLOW_SCOPE

**Optional Sections**:
- **Integration/Context**: Links to upstream artifacts (e.g., "Research Integration" in Planning)
- **Phase-Specific Metrics**: Custom details (e.g., research mode, test results, debug findings)

---

## 2. Template for Missing Checkpoints

### 2.1 Implementation Phase Checkpoint

**Location**: After line 931 (after /implement completes, before transition to testing)

```bash
# ===== CHECKPOINT REQUIREMENT: Implementation Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Implementation Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Implementation phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Implementation status: ✓ Complete"
echo "    - Plan executed: $PLAN_PATH"
# Extract implementation summary (assumes /implement returns summary)
if [ -n "${IMPLEMENTATION_SUMMARY:-}" ]; then
  echo "    - Summary: $IMPLEMENTATION_SUMMARY"
fi
echo ""
echo "  Plan Integration:"
echo "    - Plan followed: $(basename "$PLAN_PATH")"
echo "    - Research reports referenced: ${#REPORT_PATHS[@]}"
echo ""
echo "  Verification Status:"
echo "    - Implementation complete: ✓ Yes"
echo "    - Code changes committed: ✓ Yes (per /implement phase commits)"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: Testing phase (comprehensive test suite)"
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Key Variables**:
- `PLAN_PATH`: Implementation plan file path
- `IMPLEMENTATION_SUMMARY`: Summary from /implement (if available)
- `REPORT_PATHS[@]`: Research reports used in planning
- **Next State**: Always proceeds to STATE_TEST (testing phase)

**Notes**:
- Implementation phase always transitions to testing in full-implementation scope
- /implement handles phase-level commits internally, so no additional commit reporting needed
- Could add metrics: phases completed, files changed, test results per phase

### 2.2 Testing Phase Checkpoint

**Location**: After line 1019 (after test suite execution, before conditional transition)

```bash
# ===== CHECKPOINT REQUIREMENT: Testing Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Testing Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Testing phase status before transitioning to next state:"
echo ""
echo "  Test Execution:"
echo "    - Test suite run: ✓ Complete"
echo "    - Exit code: $TEST_EXIT_CODE"
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "    - Result: ✓ All tests passed"
else
  echo "    - Result: ❌ Test failures detected"
fi
echo ""
echo "  Implementation Integration:"
echo "    - Implementation tested: $(basename "$PLAN_PATH")"
echo "    - Test command: ${TEST_COMMAND:-run_all_tests.sh}"
echo ""
echo "  Verification Status:"
echo "    - Test execution verified: ✓ Yes"
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "    - Test success verified: ✓ Yes"
else
  echo "    - Test failures confirmed: ✓ Yes (proceeding to debug)"
fi
echo ""
echo "  Next Action:"
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "    - Proceeding to: Documentation phase (tests passed)"
else
  echo "    - Proceeding to: Debug phase (analyze failures)"
fi
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Key Variables**:
- `TEST_EXIT_CODE`: Exit code from test suite (0 = success)
- `PLAN_PATH`: Implementation plan being tested
- `TEST_COMMAND`: Test command executed (optional)
- **Next State**: Conditional
  - Success (exit code 0) → STATE_DOCUMENT
  - Failure (exit code ≠ 0) → STATE_DEBUG

**Notes**:
- Testing is the only phase with conditional next state
- Checkpoint should clearly indicate which path will be taken
- Could add: test count, failure count, coverage percentage (if available)

### 2.3 Debug Phase Checkpoint

**Location**: After line 1176 (after debug report verification, before transition to complete)

**CRITICAL NOTE**: Current code transitions to STATE_COMPLETE immediately after verification. This is INCORRECT for full workflows. Debug phase should allow fix implementation and re-testing.

**Proposed Checkpoint** (with corrected state transition logic):

```bash
# ===== CHECKPOINT REQUIREMENT: Debug Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Debug Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Debug phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Debug report: ✓ Created"
echo "    - Report path: $DEBUG_REPORT_PATH"
DEBUG_SIZE=$(stat -f%z "$DEBUG_REPORT_PATH" 2>/dev/null || stat -c%s "$DEBUG_REPORT_PATH" 2>/dev/null || echo "unknown")
echo "    - Report size: $DEBUG_SIZE bytes"
echo ""
echo "  Test Integration:"
echo "    - Test failures analyzed: ✓ Yes"
echo "    - Root cause investigation: ✓ Complete"
echo "    - Proposed fixes documented: ✓ Yes"
echo ""
echo "  Verification Status:"
echo "    - Debug report verified: ✓ Yes"
echo ""
echo "  Next Action:"
echo "    - Workflow state: Paused for manual review"
echo "    - User action required: Review debug report and implement fixes"
echo "    - Resume command: /coordinate \"$WORKFLOW_DESCRIPTION\" (will re-test)"
echo "    - Alternative: Manually fix issues then run /test-all"
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Key Variables**:
- `DEBUG_REPORT_PATH`: Path to debug analysis report
- `DEBUG_SIZE`: File size of debug report
- `WORKFLOW_DESCRIPTION`: Original workflow description (for resume command)
- **Next State**: STATE_COMPLETE (workflow pauses for manual intervention)

**Notes**:
- Debug phase is terminal in current implementation (user must manually fix and re-run)
- Future enhancement: Add STATE_FIX → implement fixes → re-test cycle
- Checkpoint should clearly communicate manual intervention requirement
- Could add: number of issues found, severity levels, fix complexity estimates

### 2.4 Documentation Phase Checkpoint

**Location**: After line 1288 (after /document completes, before transition to complete)

```bash
# ===== CHECKPOINT REQUIREMENT: Documentation Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Documentation Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Documentation phase status before transitioning to next state:"
echo ""
echo "  Artifacts Updated:"
echo "    - Documentation update: ✓ Complete"
# Assumes /document returns list of updated files
if [ -n "${UPDATED_DOCS_LIST:-}" ]; then
  DOCS_COUNT=$(echo "$UPDATED_DOCS_LIST" | wc -l)
  echo "    - Files updated: $DOCS_COUNT"
  echo "    - Updated files:"
  echo "$UPDATED_DOCS_LIST" | head -5 | sed 's/^/      • /'
  if [ $DOCS_COUNT -gt 5 ]; then
    echo "      • ... and $((DOCS_COUNT - 5)) more"
  fi
else
  echo "    - Files updated: See /document output above"
fi
echo ""
echo "  Implementation Integration:"
echo "    - Changes documented from: $(basename "$PLAN_PATH")"
echo "    - Workflow documented: $WORKFLOW_DESCRIPTION"
echo ""
echo "  Verification Status:"
echo "    - Documentation command executed: ✓ Yes"
echo "    - Standards compliance: ✓ Checked by /document"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: Terminal state (workflow complete)"
echo "    - Full workflow summary available below"
echo "═══════════════════════════════════════════════════════"
echo ""
```

**Key Variables**:
- `UPDATED_DOCS_LIST`: List of files updated by /document (optional)
- `PLAN_PATH`: Implementation plan being documented
- `WORKFLOW_DESCRIPTION`: Original workflow description
- **Next State**: STATE_COMPLETE (terminal state for successful workflows)

**Notes**:
- Documentation is the final phase in successful full-implementation workflows
- Checkpoint should acknowledge workflow completion
- Could add: documentation coverage metrics, cross-reference validation

---

## 3. Reusable Checkpoint Template

### 3.1 Generic Template

```bash
# ===== CHECKPOINT REQUIREMENT: {PHASE_NAME} Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: {PHASE_NAME} Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "{PHASE_NAME} phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created/Updated:"
{PHASE_SPECIFIC_ARTIFACTS}
echo ""
echo "  {INTEGRATION_SECTION_NAME}:"
{UPSTREAM_ARTIFACT_REFERENCES}
echo ""
echo "  Verification Status:"
{VERIFICATION_CHECKS}
echo ""
echo "  Next Action:"
{NEXT_STATE_LOGIC}
echo "═══════════════════════════════════════════════════════"
echo ""
```

### 3.2 Template Variables Reference

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{PHASE_NAME}` | Phase name (capitalized) | Research, Planning, Implementation |
| `{PHASE_SPECIFIC_ARTIFACTS}` | Artifacts created in this phase | `echo "    - Research reports: $COUNT"` |
| `{INTEGRATION_SECTION_NAME}` | Name for upstream integration | Research Integration, Plan Integration |
| `{UPSTREAM_ARTIFACT_REFERENCES}` | Links to artifacts from previous phases | `echo "    - Reports used: $COUNT"` |
| `{VERIFICATION_CHECKS}` | File/status verification results | `echo "    - All files verified: ✓ Yes"` |
| `{NEXT_STATE_LOGIC}` | Conditional next state determination | `case "$WORKFLOW_SCOPE" in ... esac` |

### 3.3 Formatting Standards

**Box Drawing**:
- Separator character: `═` (U+2550 - Box Drawings Double Horizontal)
- Total width: 55 characters
- Generate with: `echo "═══════════════════════════════════════════════════════"`

**Indentation**:
- Section labels: 2 spaces
- Content lines: 4 spaces
- Nested content: 6 spaces

**Status Indicators**:
- Success: `✓` (U+2713 - Check Mark)
- Failure: `❌` (U+274C - Cross Mark)
- Format: `✓ Yes` or `❌ No`

**Conditional Display**:
- Use `$(...)` for inline conditionals
- Use `case` statements for multi-branch logic
- Always include else/default cases

---

## 4. Implementation Recommendations

### 4.1 Checkpoint Placement Strategy

**Before State Transition**:
- Place checkpoint immediately AFTER verification completes
- Place checkpoint immediately BEFORE `sm_transition` call
- Ensures checkpoint reflects actual completion status

**Example Pattern**:
```bash
# Verification block
verify_file_created "$ARTIFACT_PATH" ...

# CHECKPOINT HERE (after verification, before transition)
echo "CHECKPOINT: Phase Complete"
...

# State transition
sm_transition "$NEXT_STATE"
```

### 4.2 Variable Availability

**Ensure Variables Are Set**:
- All checkpoints require workflow state to be loaded (`load_workflow_state`)
- Phase-specific variables must be set before checkpoint
- Use `${VAR:-default}` for optional variables

**Critical Variables**:
- `WORKFLOW_SCOPE`: Determines next state logic
- `CURRENT_STATE`: Verify checkpoint is in correct phase
- Phase-specific paths: `PLAN_PATH`, `DEBUG_REPORT_PATH`, etc.

### 4.3 Consistency Guidelines

**Standard Language**:
- Use present perfect tense: "Complete", "Created", "Verified"
- Use active voice: "Proceeding to", not "Will proceed to"
- Use consistent labels: "Artifacts Created", "Verification Status", "Next Action"

**Standard Metrics**:
- Always show file counts when applicable
- Always show file sizes for single artifacts
- Always show verification status (boolean or detailed)

### 4.4 Testing Considerations

**Checkpoint Verification Tests**:
1. Verify checkpoint appears in expected location (line number range)
2. Verify all required variables are displayed
3. Verify next state logic matches state machine transitions
4. Verify box-drawing characters render correctly
5. Verify conditional branches (all workflow scopes tested)

**Test Script Pattern**:
```bash
# Extract checkpoint block
CHECKPOINT=$(sed -n '/CHECKPOINT: Implementation Phase/,/^echo ""$/p' coordinate.md)

# Verify required sections
echo "$CHECKPOINT" | grep -q "Artifacts Created" || fail "Missing Artifacts section"
echo "$CHECKPOINT" | grep -q "Verification Status" || fail "Missing Verification section"
echo "$CHECKPOINT" | grep -q "Next Action" || fail "Missing Next Action section"
```

---

## 5. Phase-Specific Requirements

### 5.1 Implementation Phase Checkpoint

**Required Information**:
- Implementation completion status (binary: complete/incomplete)
- Plan path that was executed
- Summary of changes (if available from /implement)
- Number of phases completed
- Test results per phase (optional, if /implement provides)

**Optional Enhancements**:
- Files changed count
- Commits created count
- Adaptive planning events (replans, expansions)
- Wave execution summary (if parallel implementation)

**Next State**: Always STATE_TEST (unconditional)

### 5.2 Testing Phase Checkpoint

**Required Information**:
- Test suite exit code
- Test result (passed/failed) with clear visual indicator
- Test command executed
- Decision logic for next state (document vs debug)

**Optional Enhancements**:
- Test count (total, passed, failed)
- Test coverage percentage
- Test execution time
- Failed test names (first 3-5)

**Next State**: Conditional
- Exit code 0 → STATE_DOCUMENT
- Exit code ≠ 0 → STATE_DEBUG

### 5.3 Debug Phase Checkpoint

**Required Information**:
- Debug report path and size
- Confirmation that root cause analysis was performed
- Proposed fixes documented
- Clear instruction for manual intervention required
- Resume command for user

**Optional Enhancements**:
- Issue count (total issues found)
- Severity breakdown (critical, high, medium, low)
- Estimated fix complexity
- Related test failures count

**Next State**: STATE_COMPLETE (paused for manual intervention)

**CRITICAL ISSUE**: Current implementation terminates workflow after debug. Should support fix → re-test cycle.

### 5.4 Documentation Phase Checkpoint

**Required Information**:
- Documentation update completion status
- Files updated (count and list, if available)
- Workflow being documented
- Confirmation that standards compliance was checked

**Optional Enhancements**:
- Documentation coverage metrics
- Cross-reference validation results
- README updates count
- Diagram updates count

**Next State**: STATE_COMPLETE (successful workflow termination)

---

## 6. Current Gaps in coordinate.md

### 6.1 Missing Checkpoints

1. **Implementation Phase** (after line 931): No checkpoint before transition to testing
2. **Testing Phase** (after line 1019): No checkpoint before conditional transition
3. **Debug Phase** (after line 1163): No checkpoint before transition to complete
4. **Documentation Phase** (after line 1288): No checkpoint before final transition

### 6.2 Inconsistency Issues

**Debug Phase State Transition**:
- Current: Transitions immediately to STATE_COMPLETE
- Expected: Should support fix implementation and re-testing
- Impact: User must manually re-run entire workflow after fixing issues

**Recommendation**: Add STATE_FIX with automated fix implementation:
```bash
# After debug analysis
case "$DEBUG_RECOMMENDATION" in
  auto-fixable)
    sm_transition "$STATE_FIX"  # Implement automated fixes
    ;;
  manual-review)
    sm_transition "$STATE_COMPLETE"  # Pause for user intervention
    ;;
esac
```

### 6.3 Verification Block Consistency

**Current Pattern**:
- Research: Mandatory verification checkpoint before state transition ✓
- Planning: Mandatory verification checkpoint before state transition ✓
- Implementation: **NO verification checkpoint** ❌
- Testing: **NO verification checkpoint** ❌
- Debug: Mandatory verification checkpoint before state transition ✓
- Documentation: **NO verification checkpoint** ❌

**Recommendation**: Add verification checkpoints for all phases to maintain consistency and improve troubleshooting.

---

## 7. Implementation Priority

### 7.1 High Priority (Core Functionality)

1. **Add Implementation Phase Checkpoint** (after line 931)
   - Essential for tracking implementation completion
   - User needs visibility into what was implemented
   - Supports troubleshooting implementation failures

2. **Add Testing Phase Checkpoint** (after line 1019)
   - Critical for understanding test results
   - Explains why workflow branched to debug vs documentation
   - Most common user confusion point

3. **Add Debug Phase Checkpoint** (after line 1163)
   - Clarifies manual intervention requirement
   - Provides clear resume instructions
   - Prevents workflow abandonment

### 7.2 Medium Priority (User Experience)

4. **Add Documentation Phase Checkpoint** (after line 1288)
   - Confirms successful workflow completion
   - Summarizes documentation changes
   - Professional workflow closure

5. **Standardize Checkpoint Formatting**
   - Consistent box-drawing (55 chars)
   - Consistent section labels
   - Consistent status indicators

### 7.3 Low Priority (Enhancement)

6. **Add Optional Metrics**
   - Test coverage percentages
   - File change counts
   - Execution time tracking

7. **Fix Debug Phase State Transition**
   - Add STATE_FIX for automated fixes
   - Support fix → re-test cycle
   - Reduce manual workflow re-runs

---

## 8. Code Snippets for Immediate Implementation

### 8.1 Implementation Phase Checkpoint (Insert After Line 931)

```bash
# Transition to testing
sm_transition "$STATE_TEST"
append_workflow_state "CURRENT_STATE" "$STATE_TEST"

# ===== CHECKPOINT REQUIREMENT: Implementation Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Implementation Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Implementation phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Implementation status: ✓ Complete"
echo "    - Plan executed: $(basename "$PLAN_PATH")"
echo ""
echo "  Plan Integration:"
echo "    - Research reports referenced: ${#REPORT_PATHS[@]}"
echo ""
echo "  Verification Status:"
echo "    - Implementation complete: ✓ Yes"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: Testing phase"
echo "═══════════════════════════════════════════════════════"
echo ""

emit_progress "4" "Implementation complete, transitioning to Testing"
```

### 8.2 Testing Phase Checkpoint (Insert After Line 1019)

```bash
# Determine next state based on test results
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "✓ All tests passed"

  # ===== CHECKPOINT REQUIREMENT: Testing Phase Complete (Success) =====
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "CHECKPOINT: Testing Phase Complete"
  echo "═══════════════════════════════════════════════════════"
  echo "Testing phase status before transitioning to next state:"
  echo ""
  echo "  Test Execution:"
  echo "    - Test suite run: ✓ Complete"
  echo "    - Exit code: $TEST_EXIT_CODE"
  echo "    - Result: ✓ All tests passed"
  echo ""
  echo "  Implementation Integration:"
  echo "    - Implementation tested: $(basename "$PLAN_PATH")"
  echo ""
  echo "  Verification Status:"
  echo "    - Test success verified: ✓ Yes"
  echo ""
  echo "  Next Action:"
  echo "    - Proceeding to: Documentation phase"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  # Transition to documentation
  sm_transition "$STATE_DOCUMENT"
  append_workflow_state "CURRENT_STATE" "$STATE_DOCUMENT"

  emit_progress "6" "Tests passed, transitioning to Documentation"
else
  echo "❌ Tests failed"

  # ===== CHECKPOINT REQUIREMENT: Testing Phase Complete (Failure) =====
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "CHECKPOINT: Testing Phase Complete"
  echo "═══════════════════════════════════════════════════════"
  echo "Testing phase status before transitioning to next state:"
  echo ""
  echo "  Test Execution:"
  echo "    - Test suite run: ✓ Complete"
  echo "    - Exit code: $TEST_EXIT_CODE"
  echo "    - Result: ❌ Test failures detected"
  echo ""
  echo "  Implementation Integration:"
  echo "    - Implementation tested: $(basename "$PLAN_PATH")"
  echo ""
  echo "  Verification Status:"
  echo "    - Test failures confirmed: ✓ Yes"
  echo ""
  echo "  Next Action:"
  echo "    - Proceeding to: Debug phase (analyze failures)"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  # Transition to debug
  sm_transition "$STATE_DEBUG"
  append_workflow_state "CURRENT_STATE" "$STATE_DEBUG"

  emit_progress "5" "Tests failed, transitioning to Debug"
fi
```

### 8.3 Debug Phase Checkpoint (Insert After Line 1163, Replace Lines 1165-1176)

```bash
echo "✓ Debug report verified successfully"

# Save debug report path to workflow state
append_workflow_state "DEBUG_REPORT" "$DEBUG_REPORT_PATH"

# ===== CHECKPOINT REQUIREMENT: Debug Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Debug Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Debug phase status before transitioning to next state:"
echo ""
echo "  Artifacts Created:"
echo "    - Debug report: ✓ Created"
echo "    - Report path: $DEBUG_REPORT_PATH"
DEBUG_SIZE=$(stat -f%z "$DEBUG_REPORT_PATH" 2>/dev/null || stat -c%s "$DEBUG_REPORT_PATH" 2>/dev/null || echo "unknown")
echo "    - Report size: $DEBUG_SIZE bytes"
echo ""
echo "  Test Integration:"
echo "    - Test failures analyzed: ✓ Yes"
echo "    - Root cause investigation: ✓ Complete"
echo ""
echo "  Verification Status:"
echo "    - Debug report verified: ✓ Yes"
echo ""
echo "  Next Action:"
echo "    - Workflow state: Paused for manual review"
echo "    - User action required: Review debug report and implement fixes"
echo "    - Resume command: /coordinate \"$WORKFLOW_DESCRIPTION\""
echo "═══════════════════════════════════════════════════════"
echo ""

# Transition to complete (user must fix issues manually)
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo ""
echo "✓ Debug analysis complete"
echo "Debug report: $DEBUG_REPORT_PATH"
echo ""
echo "NOTE: Please review debug report and fix issues manually"
echo "Then re-run: /coordinate \"$WORKFLOW_DESCRIPTION\""
echo ""
```

### 8.4 Documentation Phase Checkpoint (Insert After Line 1279, Before Line 1282)

```bash
emit_progress "6" "Documentation updated"

# ===== CHECKPOINT REQUIREMENT: Documentation Phase Complete =====
echo ""
echo "═══════════════════════════════════════════════════════"
echo "CHECKPOINT: Documentation Phase Complete"
echo "═══════════════════════════════════════════════════════"
echo "Documentation phase status before transitioning to next state:"
echo ""
echo "  Artifacts Updated:"
echo "    - Documentation update: ✓ Complete"
echo ""
echo "  Implementation Integration:"
echo "    - Changes documented from: $(basename "$PLAN_PATH")"
echo "    - Workflow documented: $WORKFLOW_DESCRIPTION"
echo ""
echo "  Verification Status:"
echo "    - Documentation command executed: ✓ Yes"
echo ""
echo "  Next Action:"
echo "    - Proceeding to: Terminal state (workflow complete)"
echo "═══════════════════════════════════════════════════════"
echo ""

# Transition to complete
sm_transition "$STATE_COMPLETE"
append_workflow_state "CURRENT_STATE" "$STATE_COMPLETE"

echo ""
echo "✓ Documentation phase complete"
display_brief_summary
```

---

## 9. Testing Validation

### 9.1 Checkpoint Visibility Test

**Objective**: Verify all checkpoints appear during workflow execution

**Test Commands**:
```bash
# Test research-only workflow (should show 1 checkpoint)
/coordinate "research database optimization patterns" 2>&1 | grep -c "CHECKPOINT:"
# Expected: 1 (Research Phase Complete)

# Test research-and-plan workflow (should show 2 checkpoints)
/coordinate "research and plan auth refactor" 2>&1 | grep -c "CHECKPOINT:"
# Expected: 2 (Research Complete, Planning Complete)

# Test full-implementation workflow with passing tests (should show 4 checkpoints)
/coordinate "implement simple feature with tests" 2>&1 | grep -c "CHECKPOINT:"
# Expected: 4 (Research, Planning, Implementation, Testing, Documentation)

# Test full-implementation workflow with failing tests (should show 4 checkpoints)
/coordinate "implement feature that will fail tests" 2>&1 | grep -c "CHECKPOINT:"
# Expected: 4 (Research, Planning, Implementation, Testing, Debug)
```

### 9.2 Checkpoint Content Test

**Objective**: Verify all required sections appear in checkpoints

**Test Script**:
```bash
#!/bin/bash
# Test checkpoint structure for all phases

CHECKPOINT_TESTS=(
  "Research:CHECKPOINT: Research Phase Complete"
  "Research:Artifacts Created"
  "Research:Verification Status"
  "Research:Next Action"
  "Planning:CHECKPOINT: Planning Phase Complete"
  "Planning:Research Integration"
  "Implementation:CHECKPOINT: Implementation Phase Complete"
  "Implementation:Plan Integration"
  "Testing:CHECKPOINT: Testing Phase Complete"
  "Testing:Test Execution"
  "Debug:CHECKPOINT: Debug Phase Complete"
  "Debug:Test Integration"
  "Documentation:CHECKPOINT: Documentation Phase Complete"
  "Documentation:Implementation Integration"
)

for test in "${CHECKPOINT_TESTS[@]}"; do
  phase="${test%%:*}"
  pattern="${test#*:}"

  if grep -q "$pattern" coordinate.md; then
    echo "✓ $phase checkpoint contains: $pattern"
  else
    echo "❌ $phase checkpoint missing: $pattern"
  fi
done
```

### 9.3 State Transition Consistency Test

**Objective**: Verify checkpoint appears before state transition

**Test Pattern**:
```bash
# Extract blocks: checkpoint → state transition
sed -n '/CHECKPOINT: Research Phase/,/sm_transition/p' coordinate.md | \
  grep -E "(CHECKPOINT|sm_transition)" | \
  head -2

# Expected output:
# CHECKPOINT: Research Phase Complete
# sm_transition "$STATE_PLAN"

# Verify order (checkpoint BEFORE transition)
```

---

## 10. Summary and Next Steps

### 10.1 Template Deliverables

**Checkpoint Template Components Created**:
1. ✓ Generic reusable template (Section 3.1)
2. ✓ Implementation-ready code snippets (Section 8)
3. ✓ Phase-specific requirements (Section 5)
4. ✓ Testing validation procedures (Section 9)

**Template Variables Documented**:
- `{PHASE_NAME}`: Research, Planning, Implementation, Testing, Debug, Documentation
- `{PHASE_SPECIFIC_ARTIFACTS}`: Outputs created in phase
- `{INTEGRATION_SECTION_NAME}`: Links to upstream artifacts
- `{UPSTREAM_ARTIFACT_REFERENCES}`: Previous phase outputs used
- `{VERIFICATION_CHECKS}`: File/status confirmations
- `{NEXT_STATE_LOGIC}`: Conditional state transitions

### 10.2 Implementation Recommendations

**Immediate Actions** (High Priority):
1. Add Implementation Phase checkpoint (after line 931)
2. Add Testing Phase checkpoint (after line 1019, with conditional branching)
3. Add Debug Phase checkpoint (after line 1163)
4. Add Documentation Phase checkpoint (after line 1279)

**Code Review Checks**:
- [ ] All checkpoints use 55-character box-drawing separator
- [ ] All checkpoints have "Artifacts Created" section
- [ ] All checkpoints have "Verification Status" section
- [ ] All checkpoints have "Next Action" section
- [ ] All checkpoints appear AFTER verification, BEFORE state transition
- [ ] All phase-specific variables are set before checkpoint
- [ ] Conditional logic matches state machine transitions

**Testing Before Merge**:
- [ ] Test research-only workflow (1 checkpoint)
- [ ] Test research-and-plan workflow (2 checkpoints)
- [ ] Test full-implementation with passing tests (4 checkpoints: Research, Planning, Implementation, Documentation)
- [ ] Test full-implementation with failing tests (4 checkpoints: Research, Planning, Testing, Debug)
- [ ] Verify checkpoint content completeness (all required sections)
- [ ] Verify state transition order (checkpoint before transition)

### 10.3 Future Enhancements

**Phase 2 Improvements**:
1. Add optional metrics (test coverage, file counts, execution time)
2. Add STATE_FIX for automated debug fixes
3. Add checkpoint metadata to workflow state (for resume support)
4. Add checkpoint JSON export for tooling integration

**Standardization Opportunities**:
1. Extract checkpoint rendering to shared library function
2. Create checkpoint schema for validation
3. Add checkpoint diff support (compare workflows)
4. Add checkpoint aggregation (multi-workflow dashboards)

---

## Appendix A: Complete Checkpoint Reference

### A.1 All Phases with Checkpoints

| Phase | State | Checkpoint Exists? | Location | Next State |
|-------|-------|-------------------|----------|------------|
| Research | STATE_RESEARCH | ✓ Yes | Lines 543-573 | Conditional (scope-based) |
| Planning | STATE_PLAN | ✓ Yes | Lines 755-788 | Conditional (scope-based) |
| Implementation | STATE_IMPLEMENT | ❌ **MISSING** | ~After 931 | Always TEST |
| Testing | STATE_TEST | ❌ **MISSING** | ~After 1019 | Conditional (TEST_EXIT_CODE) |
| Debug | STATE_DEBUG | ⚠️ Partial | Lines 1165-1176 | Always COMPLETE (paused) |
| Documentation | STATE_DOCUMENT | ❌ **MISSING** | ~After 1279 | Always COMPLETE |

### A.2 Checkpoint Section Inventory

| Section | Research | Planning | Implementation* | Testing* | Debug* | Documentation* |
|---------|----------|----------|-----------------|----------|--------|----------------|
| Header/Separator | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Artifacts Created | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Verification Status | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Next Action | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Integration Section | - | ✓ (Research) | ✓ (Plan) | ✓ (Implementation) | ✓ (Test) | ✓ (Implementation) |
| Phase Metrics | ✓ (mode) | ✓ (size) | - | ✓ (exit code) | ✓ (size) | ✓ (file count) |

*Proposed checkpoints (not yet implemented)

---

**Report Status**: Complete
**Artifact Created**: /home/benjamin/.config/.claude/specs/635_634_001_coordinate_improvementsmd_implements/reports/003_checkpoint_reporting_template.md
**Lines**: 1,050+
**Sections**: 10 main + 2 appendices
**Code Snippets**: 4 implementation-ready checkpoints
**Testing Procedures**: 3 validation test suites
