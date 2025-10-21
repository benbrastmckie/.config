# Fix /implement Command Spec-Updater Integration - Implementation Plan

## Metadata
- **Date**: 2025-10-20
- **Feature**: Fix /implement command structure to properly integrate spec-updater agent invocation
- **Scope**: Restructure `.claude/commands/implement.md` to place STEP A/B in correct sequential position after STEP 4
- **Estimated Phases**: 4
- **Complexity**: Medium (Score: 65/100)
- **Standards File**: `/home/benjamin/.config/CLAUDE.md`
- **Debug Report**: `.claude/specs/002_report_creation/debug/001_spec_updater_not_called.md`

## Overview

**Problem**: The spec-updater agent invocation logic (STEP A/B) is orphaned in `/implement` command documentation, appearing ~500 lines before the main execution steps (STEP 2-5). This structural defect causes the spec-updater to never be invoked after phase completion, breaking plan hierarchy consistency.

**Root Cause**: STEP A/B are located at lines 434-553, in a separate "Plan Hierarchy Update After Phase Completion" section that appears BEFORE the main execution flow (STEP 2-5 at lines 928+). AI agents executing the command follow STEP 2 → 3 → 4 → 5 sequentially and never encounter the orphaned STEP A/B.

**Solution**: Restructure the command documentation to:
1. Remove the orphaned section (lines 415-553)
2. Reinsert STEP A/B as **STEP 4.5** immediately after STEP 4 (Git Commit)
3. Renumber subsequent steps appropriately
4. Remove redundant manual checkbox updates from STEP 5
5. Add validation to ensure spec-updater is called

**Impact**:
- **Before**: Plan hierarchies out of sync, completed phases not reflected in parent plans
- **After**: Automatic plan hierarchy updates via spec-updater agent, 100% consistency

## Success Criteria

### Code Changes
- [ ] STEP A/B removed from lines 415-553 (orphaned section)
- [ ] STEP A/B reinserted as STEP 4.5 after STEP 4 (Git Commit)
- [ ] STEP 5 simplified to remove redundant checkbox updates
- [ ] Subsequent steps renumbered (current STEP 5 → new STEP 6, etc.)
- [ ] All cross-references updated to new step numbers

### Documentation Quality
- [ ] Clear sequential flow: STEP 2 → 3 → 4 → 4.5 (A/B) → 5 → 6
- [ ] No orphaned sections remaining
- [ ] Execution flow clearly documented
- [ ] Checkpoint reporting updated with new step numbers

### Testing
- [ ] Integration test verifies spec-updater invoked after STEP 4
- [ ] Test covers Level 0, 1, and 2 plan structures
- [ ] Validation confirms hierarchy consistency after phase completion
- [ ] All existing /implement tests still passing

### Validation
- [ ] Command structure validated (no orphaned sections)
- [ ] Step numbering sequence verified
- [ ] Checkpoint validation added for spec-updater execution
- [ ] Diagnostic warnings when spec-updater skipped

## Technical Design

### Current Structure (Broken)

```
Line 334: ## Phase Execution Protocol
Line 350-412: Wave Execution Flow (steps 1-6)
Line 415: ### Plan Hierarchy Update After Phase Completion  ← ORPHANED
Line 434: **STEP A** - Invoke Spec-Updater Agent           ← NEVER EXECUTED
Line 487: **STEP B** - Mandatory Verification              ← NEVER EXECUTED
Line 555: ### 1.4. Check Expansion Status
...
[~500 lines of other content]
...
Line 928: **STEP 2** - Implementation                       ← EXECUTION STARTS HERE
Line 939: **STEP 3** - Testing
Line 1139: **STEP 4** - Git Commit
Line 1209: **STEP 5** - Plan Update (manual checkboxes)    ← REDUNDANT WITH STEP A/B
```

**Problem Flow**:
```
Agent reads command → Sees "Wave Execution Flow" → Encounters orphaned section
→ Skips to "1.4 Check Expansion Status" → Continues to STEP 2
→ Executes STEP 2, 3, 4, 5 sequentially → NEVER sees STEP A/B
```

### Target Structure (Fixed)

```
Line 334: ## Phase Execution Protocol
Line 350-412: Wave Execution Flow (steps 1-6)
Line 415: ### 1.4. Check Expansion Status                  ← MOVES UP
...
[other sections in original order]
...
Line ~900: **STEP 2** - Implementation
Line ~911: **STEP 3** - Testing
Line ~1120: **STEP 4** - Git Commit
Line ~1190: **STEP 4.5 (A/B)** - Invoke Spec-Updater Agent ← NEW PLACEMENT
    Line ~1192: **STEP A** - Invoke Spec-Updater Agent
    Line ~1245: **STEP B** - Mandatory Verification with Fallback
Line ~1318: **CHECKPOINT REQUIREMENT** - Report Phase Completion
Line ~1340: **STEP 5** - Update Progress Section (simplified) ← RENUMBERED, SIMPLIFIED
Line ~1370: **STEP 6** - Incremental Summary Generation    ← RENUMBERED
```

**Correct Flow**:
```
STEP 2: Implementation
  ↓
STEP 3: Testing
  ↓
STEP 4: Git Commit
  ↓
STEP 4.5 (A/B): Invoke spec-updater agent ← INTEGRATED
  ↓
CHECKPOINT: Report Phase Completion
  ↓
STEP 5: Update progress section (no manual checkboxes)
  ↓
STEP 6: Incremental summary generation
```

### Key Changes

#### Change 1: Remove Orphaned Section

**Location**: Lines 415-553

**Action**: Delete entire "### Plan Hierarchy Update After Phase Completion" section

**Content Removed**:
- Section header
- "When to Update" guidelines
- STEP A (lines 434-486)
- STEP B (lines 487-553)

**Rationale**: This section is not integrated into execution flow and causes STEP A/B to be skipped

#### Change 2: Insert STEP 4.5 After STEP 4

**Location**: After STEP 4 (Git Commit), before CHECKPOINT REQUIREMENT section

**New Content**:
```markdown
**STEP 4.5 - Invoke Spec-Updater Agent and Update Plan Hierarchy**

**YOU MUST update plan hierarchy after each phase completion. This is NOT optional.**

After successfully completing a phase (tests passing and git commit created), update the plan hierarchy to ensure all parent/grandparent plan files reflect completion status.

**When to Update**:
- After git commit succeeds for the phase (STEP 4 complete)
- Before saving the checkpoint
- For all hierarchy levels (Level 0, Level 1, Level 2)

**CRITICAL INSTRUCTIONS**:
- Plan hierarchy updates are MANDATORY
- DO NOT skip verification steps
- DO NOT proceed to next phase if hierarchy update fails
- Fallback mechanism ensures 100% update success

---

**STEP A (REQUIRED BEFORE STEP B) - Invoke Spec-Updater Agent**

[Insert full STEP A content from lines 434-486]

---

**STEP B (REQUIRED AFTER STEP A) - Mandatory Verification with Fallback**

[Insert full STEP B content from lines 487-553]
```

**Rationale**: Places spec-updater invocation in correct sequential position

#### Change 3: Simplify STEP 5

**Location**: Current STEP 5 (lines 1209+)

**Current Content**:
```markdown
**STEP 5 (REQUIRED) - Plan Update (After Git Commit Succeeds)**

**Update Steps**:
1. **Mark tasks complete**: Use Edit tool to change `- [ ]` → `- [x]`
2. **Add completion marker**: Change `### Phase N` → `### Phase N [COMPLETED]`
3. **Verify updates**: Read updated file and verify all phase tasks show `[x]`
4. **Update progress section**: Add/update "## Implementation Progress"
```

**New Content**:
```markdown
**STEP 5 (REQUIRED) - Update Progress Section**

**EXECUTE NOW - Update Implementation Progress**

After spec-updater has updated plan hierarchy (STEP 4.5), update the "Implementation Progress" section with phase completion details.

**Update Steps**:
1. **Update progress section**: Add/update "## Implementation Progress" with:
   - Last completed phase
   - Completion date
   - Git commit hash
   - Status "In Progress (M/N phases complete)"
   - Resume instructions `/implement <plan-file> <next-phase-number>`

**Note**: Plan checkboxes and completion markers are handled by spec-updater agent in STEP 4.5. This step only updates the progress tracking section.
```

**Rationale**:
- Removes redundant manual checkbox operations (now handled by STEP 4.5)
- Focuses STEP 5 on progress section only
- Clarifies dependency on STEP 4.5

#### Change 4: Renumber Subsequent Steps

**Affected Sections**:
- Current "STEP 5" → New "STEP 5" (simplified, as above)
- Current "### 5.5. Automatic Collapse Detection" → "### 5.5." (no change needed)
- Current "### 6. Incremental Summary Generation" → "### STEP 6. Incremental Summary Generation"
- Update all cross-references to these steps throughout the document

## Implementation Phases

### Phase 1: Restructure Command Documentation

**Objective**: Move STEP A/B to correct position and renumber steps

**Complexity**: Medium (structural refactoring of large file)

**Tasks**:

- [ ] Read `/implement` command file (line 1-1800) to understand full structure
  - File: `.claude/commands/implement.md`
  - Purpose: Map all sections and cross-references

- [ ] Extract STEP A content (lines 434-486)
  - Save to temporary variable/file for reinsertion
  - Verify all STEP A instructions preserved

- [ ] Extract STEP B content (lines 487-553)
  - Save to temporary variable/file for reinsertion
  - Verify all STEP B instructions preserved

- [ ] Delete orphaned section (lines 415-553)
  - Remove "### Plan Hierarchy Update After Phase Completion" section header
  - Remove STEP A and STEP B
  - Verify "### 1.4. Check Expansion Status" now follows "Wave Execution Flow"

- [ ] Insert new STEP 4.5 after STEP 4 (Git Commit)
  - Location: After line ~1183 (end of STEP 4)
  - Before "CHECKPOINT REQUIREMENT" section
  - Format:
    ```markdown
    **STEP 4.5 - Invoke Spec-Updater Agent and Update Plan Hierarchy**

    [Introductory content about plan hierarchy updates]

    ---

    **STEP A (REQUIRED BEFORE STEP B) - Invoke Spec-Updater Agent**

    [STEP A content from original lines 434-486]

    ---

    **STEP B (REQUIRED AFTER STEP A) - Mandatory Verification with Fallback**

    [STEP B content from original lines 487-553]
    ```

- [ ] Simplify STEP 5 to remove manual checkbox updates
  - Remove "Mark tasks complete" step (now in STEP 4.5)
  - Remove "Add completion marker" step (now in STEP 4.5)
  - Remove "Verify updates" step (now in STEP 4.5)
  - Keep only "Update progress section" step
  - Add note: "Plan checkboxes handled by spec-updater in STEP 4.5"

- [ ] Renumber section "### 6. Incremental Summary Generation"
  - Change to "### STEP 6. Incremental Summary Generation"
  - Update heading to be consistent with STEP numbering

- [ ] Update all cross-references to STEP 5
  - Search for "STEP 5" references
  - Verify context (is it referring to old STEP 5 or new STEP 5?)
  - Update if necessary (most should remain valid)

- [ ] Verify "CHECKPOINT REQUIREMENT" placement
  - Should appear after STEP 4.5 (B)
  - Before STEP 5
  - No changes needed to content, just verify position

**Testing**:
```bash
# Verify no broken structure
grep -n "^\*\*STEP" .claude/commands/implement.md

# Expected output:
# Line ~900: **STEP 2**
# Line ~911: **STEP 3**
# Line ~1120: **STEP 4**
# Line ~1190: **STEP 4.5**
# Line ~1192: **STEP A**
# Line ~1245: **STEP B**
# Line ~1340: **STEP 5**

# Verify no orphaned "Plan Hierarchy Update" section
grep -n "### Plan Hierarchy Update" .claude/commands/implement.md
# Expected: No results (section removed)

# Verify STEP A follows STEP 4
grep -A 50 "^**STEP 4 " .claude/commands/implement.md | grep -q "^**STEP 4.5"
echo $?  # Should be 0 (found)

# Verify STEP 5 simplified (no manual checkbox references)
grep -A 20 "^**STEP 5 " .claude/commands/implement.md | grep -q "Mark tasks complete"
echo $?  # Should be 1 (not found)
```

**Validation**:
- [ ] All STEP numbers sequential (2, 3, 4, 4.5, 5, 6)
- [ ] No orphaned sections
- [ ] STEP A/B content preserved exactly
- [ ] STEP 5 simplified correctly
- [ ] File structure remains valid markdown

---

### Phase 2: Add Validation and Enforcement

**Objective**: Add checkpoint validation to ensure spec-updater was called

**Complexity**: Low (add validation checks)

**Tasks**:

- [ ] Add validation check after STEP 4.5 (B)
  - Location: At end of STEP B, before "CHECKPOINT REQUIREMENT"
  - Purpose: Verify spec-updater was actually invoked
  - Implementation:
    ```markdown
    **Validation Check** (after STEP B):

    Before proceeding to checkpoint, verify plan hierarchy update succeeded:

    1. Check that parent plan file was modified (timestamp check)
    2. Verify at least one file in hierarchy updated
    3. If no updates detected:
       - Log warning: "STEP 4.5 may have been skipped"
       - Recommend manual verification
       - Proceed with caution (non-blocking)
    ```

- [ ] Update checkpoint data schema
  - File: Referenced in STEP B (line ~530)
  - Add field: `"spec_updater_invoked": true|false`
  - Purpose: Track whether spec-updater was called
  - Update checkpoint save in STEP B:
    ```bash
    CHECKPOINT_DATA='{
      "workflow_description":"implement",
      "plan_path":"'$PLAN_PATH'",
      "current_phase":'$NEXT_PHASE',
      "total_phases":'$TOTAL_PHASES',
      "status":"in_progress",
      "tests_passing":true,
      "hierarchy_updated":true,
      "spec_updater_invoked":true,  ← NEW FIELD
      "replan_count":'$REPLAN_COUNT'
    }'
    ```

- [ ] Add diagnostic output when STEP 4.5 skipped
  - Location: "CHECKPOINT REQUIREMENT" section (after STEP 4.5)
  - Check: If proceeding directly from STEP 4 to STEP 5 without STEP 4.5
  - Action: Display warning
  - Implementation:
    ```markdown
    **Diagnostic Check**:

    If you are reading this section and STEP 4.5 was not executed:
    - ⚠️ WARNING: Plan hierarchy may be out of sync
    - Required action: Return to STEP 4.5 and execute spec-updater invocation
    - Do NOT proceed to STEP 5 without updating plan hierarchy
    ```

- [ ] Update auto-resume logic
  - File: "Checkpoint Detection and Resume" section (lines ~1714+)
  - Add safety check: Verify `spec_updater_invoked` field in checkpoint
  - If false: Display warning about potential hierarchy inconsistency
  - Implementation:
    ```bash
    # In auto-resume safety checks
    SPEC_UPDATER_INVOKED=$(echo "$CHECKPOINT_DATA" | jq -r '.spec_updater_invoked // false')

    if [ "$SPEC_UPDATER_INVOKED" = "false" ]; then
      echo "⚠️ Warning: Previous execution may have skipped spec-updater"
      echo "   Plan hierarchy may be inconsistent"
      echo "   Recommend verifying plan status before continuing"
    fi
    ```

**Testing**:
```bash
# Test validation check logic
# Create test checkpoint without spec_updater_invoked field
echo '{"workflow_description":"implement","spec_updater_invoked":false}' > /tmp/test_checkpoint.json

# Verify diagnostic warning would trigger
cat /tmp/test_checkpoint.json | jq -r '.spec_updater_invoked // false'
# Expected: false

# Test with valid checkpoint
echo '{"workflow_description":"implement","spec_updater_invoked":true}' > /tmp/test_checkpoint_valid.json
cat /tmp/test_checkpoint_valid.json | jq -r '.spec_updater_invoked // false'
# Expected: true
```

**Validation**:
- [ ] Checkpoint schema includes `spec_updater_invoked` field
- [ ] Validation check added after STEP B
- [ ] Diagnostic output in place for skipped execution
- [ ] Auto-resume logic checks spec-updater invocation

---

### Phase 3: Integration Testing

**Objective**: Verify spec-updater is invoked correctly in all scenarios

**Complexity**: Medium (requires test execution and verification)

**Tasks**:

- [ ] Create integration test script
  - File: `.claude/tests/test_implement_spec_updater_integration.sh`
  - Purpose: Verify spec-updater called after phase completion
  - Test cases:
    1. Level 0 plan (single file)
    2. Level 1 plan (phase-expanded)
    3. Level 2 plan (stage-expanded)
    4. Fallback mechanism (agent unavailable)

- [ ] Test Case 1: Level 0 Plan
  - Create test plan: `test_plans/001_level0_test.md`
  - Plan structure: Single file, 3 phases
  - Execute: `/implement test_plans/001_level0_test.md 1`
  - Verify after Phase 1:
    - [ ] spec-updater agent invoked
    - [ ] Phase 1 tasks marked `[x]` in main plan
    - [ ] Phase 1 heading has `[COMPLETED]` marker
    - [ ] Checkpoint has `spec_updater_invoked: true`
    - [ ] Progress section updated

- [ ] Test Case 2: Level 1 Plan
  - Create test plan: `test_plans/002_level1_test/002_level1_test.md`
  - Plan structure: Main plan + phase_1.md (expanded)
  - Execute: `/implement test_plans/002_level1_test/002_level1_test.md 1`
  - Verify after Phase 1:
    - [ ] spec-updater agent invoked
    - [ ] Phase 1 tasks marked `[x]` in `phase_1.md`
    - [ ] Phase 1 heading has `[COMPLETED]` in `phase_1.md`
    - [ ] Main plan Phase 1 entry updated with completion marker
    - [ ] Hierarchy consistency verified

- [ ] Test Case 3: Level 2 Plan
  - Create test plan: `test_plans/003_level2_test/003_level2_test.md`
  - Plan structure: Main plan + phase_1/ directory + stage files
  - Execute: `/implement test_plans/003_level2_test/003_level2_test.md 1`
  - Verify after Phase 1:
    - [ ] spec-updater agent invoked
    - [ ] Stage files updated
    - [ ] Phase file updated
    - [ ] Main plan updated
    - [ ] All three levels consistent

- [ ] Test Case 4: Fallback Mechanism
  - Create test plan: `test_plans/004_fallback_test.md`
  - Simulate: spec-updater agent unavailable
  - Execute: `/implement test_plans/004_fallback_test.md 1`
  - Verify:
    - [ ] Fallback to direct checkbox-utils.sh invocation
    - [ ] Plan hierarchy still updated correctly
    - [ ] Warning logged about fallback usage
    - [ ] Checkpoint shows `hierarchy_updated: true`

- [ ] Regression test: Existing tests still pass
  - Run: `.claude/tests/run_all_tests.sh`
  - Verify: All existing tests pass
  - Focus areas:
    - [ ] test_adaptive_planning.sh (checkpoint schema change)
    - [ ] test_revise_automode.sh (plan updates)
    - [ ] test_parsing_utilities.sh (plan structure)

- [ ] Performance test: Verify no significant slowdown
  - Measure: Time for one phase execution
  - Baseline: Before changes
  - After: With spec-updater invocation
  - Acceptable: <5% increase (agent invocation overhead)

**Testing**:
```bash
# Run integration tests
.claude/tests/test_implement_spec_updater_integration.sh

# Expected output:
# Test 1: Level 0 Plan..................... ✓ PASSED
# Test 2: Level 1 Plan..................... ✓ PASSED
# Test 3: Level 2 Plan..................... ✓ PASSED
# Test 4: Fallback Mechanism............... ✓ PASSED
# Test 5: Checkpoint Schema................ ✓ PASSED
# Test 6: Hierarchy Consistency............ ✓ PASSED
# Test 7: Diagnostic Warnings.............. ✓ PASSED
#
# All tests passed (7/7)

# Run regression tests
.claude/tests/run_all_tests.sh | grep -E "(PASS|FAIL)"

# Expected: All tests PASS
```

**Validation**:
- [ ] All 4 integration test cases passing
- [ ] All hierarchy levels (0, 1, 2) tested
- [ ] Fallback mechanism verified
- [ ] Regression tests passing
- [ ] Performance acceptable

---

### Phase 4: Documentation and Validation

**Objective**: Update related documentation and validate complete fix

**Complexity**: Low (documentation updates)

**Tasks**:

- [ ] Update command-authoring-guide.md
  - File: `.claude/docs/guides/command-authoring-guide.md`
  - Section: "Agent Invocation Patterns"
  - Add: Importance of sequential step execution
  - Add: Warning about orphaned sections
  - Reference: `/implement` as corrected example

- [ ] Update hierarchical_agents.md
  - File: `.claude/docs/concepts/hierarchical_agents.md`
  - Section: "Spec-Updater Agent" (if exists)
  - Update: Invocation pattern (STEP 4.5 in /implement)
  - Add: Timing requirements (after git commit, before checkpoint)

- [ ] Add troubleshooting entry
  - File: Create if doesn't exist: `.claude/docs/troubleshooting/plan-hierarchy-issues.md`
  - Issue: "Plan hierarchy out of sync after phase completion"
  - Cause: "spec-updater not invoked"
  - Solution: "Verify STEP 4.5 executed"
  - Manual fix: Use checkbox-utils.sh directly

- [ ] Update CHANGELOG.md
  - File: `.claude/CHANGELOG.md`
  - Entry:
    ```markdown
    ### 2025-10-20 - Fix /implement Command Structure

    **Issue**: spec-updater agent invocation (STEP A/B) orphaned at lines 415-553, appearing before main execution flow, causing plan hierarchy inconsistency.

    **Changes**:
    - Moved STEP A/B to new STEP 4.5 position after STEP 4 (Git Commit)
    - Simplified STEP 5 to remove redundant manual checkbox updates
    - Added validation checks for spec-updater invocation
    - Updated checkpoint schema with `spec_updater_invoked` field
    - Renumbered subsequent steps for sequential flow

    **Impact**:
    - Plan hierarchies now automatically updated after phase completion
    - No more manual checkbox synchronization required
    - Improved reliability and consistency

    **Testing**:
    - Integration tests for Level 0, 1, 2 plan structures
    - Fallback mechanism verified
    - All regression tests passing

    **Files Modified**:
    - `.claude/commands/implement.md` (restructured)
    - `.claude/tests/test_implement_spec_updater_integration.sh` (new)
    - `.claude/docs/guides/command-authoring-guide.md` (updated)
    - `.claude/docs/troubleshooting/plan-hierarchy-issues.md` (new)
    ```

- [ ] Create example document
  - File: `.claude/docs/examples/implement-phase-execution-flow.md`
  - Purpose: Visual guide to correct /implement execution flow
  - Content:
    - Flowchart of STEP 2 → 3 → 4 → 4.5 (A/B) → 5 → 6
    - Explanation of each step
    - Common mistakes (skipping STEP 4.5)
    - Validation checkpoints

- [ ] Validate complete fix
  - [ ] Re-read implement.md to verify structure
  - [ ] Check step numbering: 2, 3, 4, 4.5, 5, 6 (sequential)
  - [ ] Verify no orphaned sections
  - [ ] Confirm STEP A/B content preserved
  - [ ] Test with real plan execution
  - [ ] Verify plan hierarchy updates correctly

- [ ] Apply fix to current issue (Phase 5 not marked)
  - File: `.claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation/002_fix_all_command_subagent_delegation.md`
  - Action: Run manual workaround from debug report
  - Command:
    ```bash
    cd /home/benjamin/.config
    source .claude/lib/checkbox-utils.sh
    mark_phase_complete ".claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation/002_fix_all_command_subagent_delegation.md" 5
    verify_checkbox_consistency ".claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation/002_fix_all_command_subagent_delegation.md" 5
    ```
  - Verify: Phase 5 marked COMPLETED in both files

**Testing**:
```bash
# Verify documentation updates
grep -n "spec-updater" .claude/docs/guides/command-authoring-guide.md
grep -n "STEP 4.5" .claude/docs/concepts/hierarchical_agents.md

# Verify CHANGELOG entry
grep -A 20 "2025-10-20 - Fix /implement Command Structure" .claude/CHANGELOG.md

# Test manual workaround
mark_phase_complete ".claude/specs/002_report_creation/plans/002_fix_all_command_subagent_delegation/002_fix_all_command_subagent_delegation.md" 5
# Expected: Phase 5 marked complete, hierarchy updated

# Final validation: Run /implement on test plan
/implement test_plans/001_level0_test.md 1
# Verify: spec-updater invoked, plan updated correctly
```

**Validation**:
- [ ] All documentation updated
- [ ] CHANGELOG entry complete
- [ ] Example document created
- [ ] Troubleshooting guide added
- [ ] Manual fix applied to Phase 5 issue
- [ ] Complete fix validated with real execution

---

## Testing Strategy

### Unit Tests
- **Focus**: Individual components (checkpoint schema, validation checks)
- **Coverage**:
  - Checkpoint data structure with `spec_updater_invoked` field
  - Validation logic for hierarchy updates
  - Diagnostic output triggers

### Integration Tests
- **Focus**: Complete phase execution flow
- **Coverage**:
  - Level 0, 1, 2 plan structures
  - spec-updater agent invocation
  - Plan hierarchy consistency
  - Fallback mechanism

### Regression Tests
- **Focus**: Existing functionality preserved
- **Coverage**:
  - All existing /implement tests
  - Checkpoint management tests
  - Plan parsing tests
  - Adaptive planning tests

### Manual Validation
- **Focus**: Real-world usage
- **Coverage**:
  - Execute /implement on actual plan
  - Verify spec-updater invoked
  - Check plan hierarchy updated
  - Confirm user experience improved

## Documentation Requirements

### Updated Documents
1. `.claude/commands/implement.md` - Restructured with STEP 4.5
2. `.claude/docs/guides/command-authoring-guide.md` - Sequential step importance
3. `.claude/docs/concepts/hierarchical_agents.md` - spec-updater invocation
4. `.claude/CHANGELOG.md` - Fix documentation

### New Documents
1. `.claude/docs/troubleshooting/plan-hierarchy-issues.md` - Troubleshooting guide
2. `.claude/docs/examples/implement-phase-execution-flow.md` - Visual guide
3. `.claude/tests/test_implement_spec_updater_integration.sh` - Integration tests

## Dependencies

### Internal Dependencies
- **checkbox-utils.sh**: Utility library for plan hierarchy updates (existing)
- **spec-updater.md**: Agent behavioral file (existing)
- **implement.md**: Command file (modified)
- **Checkpoint system**: Requires schema update

### External Dependencies
- None (all changes internal to .claude/ system)

### Risk Mitigation
- **Regression**: Comprehensive test suite ensures existing functionality preserved
- **Adoption**: Clear documentation and examples
- **Validation**: Multiple test scenarios cover all plan structure levels

## Notes

### Design Decisions

**Decision 1**: Use STEP 4.5 numbering instead of renumbering all steps
- **Rationale**: Minimizes cross-reference updates throughout document
- **Trade-off**: Non-integer step number, but clear insertion point
- **Benefit**: Less risk of breaking existing references

**Decision 2**: Keep fallback mechanism from original STEP B
- **Rationale**: Graceful degradation if agent unavailable
- **Trade-off**: Additional complexity
- **Benefit**: 100% reliability even with agent failures

**Decision 3**: Add checkpoint validation (Phase 2)
- **Rationale**: Prevents future regressions and provides diagnostics
- **Trade-off**: Additional checkpoint fields
- **Benefit**: Self-documenting execution, easier debugging

**Decision 4**: Comprehensive integration testing (Phase 3)
- **Rationale**: High-risk change to critical command
- **Trade-off**: Significant test development time
- **Benefit**: Confidence in fix, regression prevention

### Implementation Notes

**Note 1: Line Number References**
- Current line numbers are approximate (~)
- Will shift after Phase 1 restructuring
- Use content search, not absolute line numbers

**Note 2: Checkpoint Schema**
- New field `spec_updater_invoked` is optional (backward compatible)
- Default value: false if missing
- Migration: Existing checkpoints remain valid

**Note 3: Documentation Scope**
- Focus on /implement command fix
- Related guides updated for consistency
- Future: May inspire similar structural reviews of other commands

**Note 4: Manual Fix Application**
- Phase 5 issue can be fixed immediately with checkbox-utils.sh
- Long-term fix prevents future occurrences
- Both approaches documented in debug report

### Complexity Analysis

**Overall Complexity: Medium (65/100)**

Breakdown:
- Phase 1 (Restructure): Medium (45/100) - Large file editing, careful content preservation
- Phase 2 (Validation): Low (30/100) - Simple validation checks
- Phase 3 (Testing): Medium (60/100) - Multiple test scenarios, hierarchy validation
- Phase 4 (Documentation): Low (35/100) - Standard documentation updates

**Risk Factors**:
- ⚠️ Large file modification (~1800 lines)
- ⚠️ Critical command affects all /implement usage
- ✅ Clear problem definition and solution design
- ✅ Comprehensive testing strategy
- ✅ Fallback mechanisms preserve reliability

### Performance Metrics

**Baseline (Before Fix)**:
- spec-updater: Never called (0% invocation rate)
- Plan hierarchy: Manual updates or out of sync
- User frustration: High (confusion about completion status)

**Target (After Fix)**:
- spec-updater: Called after every phase (100% invocation rate)
- Plan hierarchy: Always consistent
- User experience: Seamless (automatic updates)
- Performance overhead: <5% (single agent invocation per phase)

### Git Commit Strategy

**Phase 1 Commit**:
```
fix: restructure /implement command to integrate spec-updater invocation

- Remove orphaned "Plan Hierarchy Update" section (lines 415-553)
- Insert STEP A/B as STEP 4.5 after STEP 4 (Git Commit)
- Simplify STEP 5 to remove redundant manual checkbox updates
- Renumber STEP 6 (Incremental Summary Generation)
- Update all cross-references to new step numbers

Fixes spec-updater never being invoked after phase completion.
Plan hierarchies now automatically updated via spec-updater agent.

Related: .claude/specs/002_report_creation/debug/001_spec_updater_not_called.md
```

**Phase 2 Commit**:
```
feat: add validation for spec-updater invocation in /implement

- Add checkpoint field: spec_updater_invoked (boolean)
- Add validation check after STEP 4.5 (B)
- Add diagnostic output when STEP 4.5 skipped
- Update auto-resume logic to check spec-updater invocation
- Provide warnings for hierarchy inconsistency

Ensures spec-updater execution is tracked and validated.
```

**Phase 3 Commit**:
```
test: add integration tests for /implement spec-updater invocation

- Create test_implement_spec_updater_integration.sh
- Test Level 0, 1, 2 plan structures
- Verify spec-updater agent invocation
- Test fallback mechanism
- Verify hierarchy consistency after phase completion

All tests passing (7/7).
```

**Phase 4 Commit**:
```
docs: document /implement spec-updater integration fix

- Update command-authoring-guide.md (sequential step importance)
- Update hierarchical_agents.md (spec-updater invocation pattern)
- Add troubleshooting/plan-hierarchy-issues.md
- Add examples/implement-phase-execution-flow.md
- Update CHANGELOG.md with fix details

Complete fix validated and documented.
```

---

## Summary

This plan fixes a critical structural defect in the `/implement` command where the spec-updater agent invocation logic (STEP A/B) was orphaned in a separate section, appearing ~500 lines before the main execution flow. This caused the spec-updater to never be invoked after phase completion, leading to plan hierarchy inconsistencies.

### Impact

**Before**:
- ❌ spec-updater invoked: 0% of the time
- ❌ Plan hierarchies out of sync
- ❌ Completed phases not reflected in parent plans
- ❌ Manual checkbox updates required
- ❌ Confusion about completion status

**After**:
- ✅ spec-updater invoked: 100% of the time
- ✅ Plan hierarchies always consistent
- ✅ Automatic updates across all hierarchy levels
- ✅ No manual intervention required
- ✅ Clear execution flow and validation

### Deliverables

**Code Changes**:
- `/implement` command restructured (STEP A/B moved to STEP 4.5)
- STEP 5 simplified (redundant operations removed)
- Checkpoint schema enhanced (validation field added)

**Documentation**:
- Command-authoring guide updated
- Troubleshooting guide created
- Example execution flow documented
- CHANGELOG updated

**Testing**:
- Integration test suite (4 test cases)
- Regression tests (all existing tests)
- Manual validation (real-world execution)

### Timeline

**Estimated Implementation Time**: 8-10 hours across 4 phases

**Phase Breakdown**:
- Phase 1 (Restructure): 3-4 hours
- Phase 2 (Validation): 1-2 hours
- Phase 3 (Testing): 2-3 hours
- Phase 4 (Documentation): 2 hours

**Risk Level**: Medium (critical command modification, but clear solution design and comprehensive testing)

**Priority**: High (affects all /implement usage, currently causing user confusion)

### Success Metrics

Upon completion:
- ✅ spec-updater invoked after every phase completion
- ✅ Plan hierarchies always consistent (all levels)
- ✅ No orphaned sections in /implement command
- ✅ Clear sequential step flow (2, 3, 4, 4.5, 5, 6)
- ✅ All integration tests passing
- ✅ All regression tests passing
- ✅ Complete documentation and examples

**Next Steps**: Begin Phase 1 (Restructure Command Documentation) and proceed sequentially through phases with testing at each step.
