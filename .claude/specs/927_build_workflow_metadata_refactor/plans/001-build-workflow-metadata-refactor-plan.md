# Build Workflow Metadata Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Refactor /build Block 4 to prevent skipping critical metadata status updates
- **Scope**: Minor refactor of build.md Block 4 completion logic
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 20
- **Research Reports**:
  - [Build Workflow Metadata Refactor Research](../reports/001-build-workflow-metadata-refactor-research.md)

## Overview

This plan addresses a critical bug where the `update_plan_status` function call in /build command Block 4 can be skipped during workflow completion. The research report identified that Block 4 is ~110 lines with the metadata update positioned late in the block (lines 2029-2037) after non-critical console output, making it vulnerable to partial execution or simplification.

**Goals**:
1. Ensure `update_plan_status` is always called when workflow completes successfully
2. Add missing `save_completed_states_to_state` call (found in plan.md/research.md but missing from build.md)
3. Source checkbox-utils.sh explicitly in Block 4 for function availability
4. Remove error suppression that masks failures

**Constraints**:
- MINOR refactor only - no major structural changes
- Maintain backward compatibility with existing /build workflow
- Follow existing code standards from .claude/docs/

## Research Summary

Key findings from the research report:

1. **Block Size Issue**: Build Block 4 at ~110 lines is 2x larger than comparable final blocks in plan.md (55 lines) and research.md (52 lines)
2. **Late Position**: Metadata update appears after console output (line 2027), making it appear optional
3. **Missing Library Source**: checkbox-utils.sh not sourced in Block 4 (relies on Block 1 sourcing, but bash blocks are independent execution contexts)
4. **Missing State Save**: No `save_completed_states_to_state` call between state transition and cleanup, unlike plan.md and research.md patterns
5. **Error Suppression**: `2>/dev/null` in `update_plan_status` call suppresses error messages

**Recommended approach**: Apply high-priority quick fixes (add state save, source library, remove suppression) rather than major block restructuring to minimize risk.

## Success Criteria
- [x] `update_plan_status` function is available in Block 4 (explicit sourcing)
- [x] `save_completed_states_to_state` called after state transition (matches plan.md pattern)
- [x] Metadata update errors are visible (not suppressed)
- [x] All existing /build tests pass
- [x] Manual test: /build on a test plan shows "Plan metadata status updated to [COMPLETE]"

## Technical Design

### Architecture Overview

The fix applies targeted changes to build.md Block 4 without restructuring the overall block:

```
Block 4 Current Structure:
[1] Library Sourcing (Tier 1/2) ─────────────────────────────────┐
[2] State Loading with Recovery                                  │
[3] State Validation (STATE_FILE, CURRENT_STATE)                 │
[4] Predecessor Validation (document|debug)                      │
[5] State Transition: sm_transition "$STATE_COMPLETE" ◄──────────┤
[6] Summary Validation (plan link check)                         │ FIX HERE: Add save_completed_states_to_state after [5]
[7] Console Summary: print_artifact_summary                      │
[8] Metadata Update: update_plan_status ◄────────────────────────┤ FIX HERE: Source library, remove suppression
[9] Checkpoint Cleanup                                           │
[10] File Cleanup                                                │
                                                                 ┘

Changes Required:
A. Add Tier 3 sourcing for checkbox-utils.sh after line 1793
B. Add save_completed_states_to_state call after line 1961
C. Remove 2>/dev/null from update_plan_status call at line 2032
```

### Design Rationale

1. **Explicit Library Sourcing**: Each bash block executes in an independent context. Block 1's sourcing of checkbox-utils.sh does not carry to Block 4. Explicit sourcing ensures function availability.

2. **State Persistence Call**: The `save_completed_states_to_state` function persists workflow state before any cleanup operations. Plan.md (line 1088) and research.md (line 662) both call this after transition. Build.md should follow the same pattern.

3. **Error Visibility**: The `2>/dev/null` in `update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null` masks failures. Removing it allows debugging when metadata updates fail.

## Implementation Phases

### Phase 1: Add Tier 3 Library Sourcing [COMPLETE]
dependencies: []

**Objective**: Ensure checkbox-utils.sh functions are available in Block 4

**Complexity**: Low

**Tasks**:
- [x] Add Tier 3 sourcing comment and checkbox-utils.sh source after line 1793 (after `ensure_error_log_exists`)
  - File: `/home/benjamin/.config/.claude/commands/build.md`
  - Insert after line 1793: `# Tier 3: Command-Specific (graceful degradation)`
  - Insert: `source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true`
- [x] Verify sourcing follows three-tier pattern from code-standards.md

**Testing**:
```bash
# Verify sourcing syntax is correct
bash -n /home/benjamin/.config/.claude/commands/build.md

# Verify function availability after sourcing
source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh && type update_plan_status
```

**Expected Duration**: 0.5 hours

---

### Phase 2: Add State Persistence Call [COMPLETE]
dependencies: [1]

**Objective**: Add `save_completed_states_to_state` call after state transition to match plan.md pattern

**Complexity**: Low

**Tasks**:
- [x] Add `save_completed_states_to_state` call after successful state transition (after line 1961)
  - File: `/home/benjamin/.config/.claude/commands/build.md`
  - Insert after `fi` at line 1961 (after state transition error handling)
- [x] Add exit code check and error logging for state persistence failure
  - Pattern from plan.md lines 1088-1094:
    ```bash
    save_completed_states_to_state
    SAVE_EXIT=$?
    if [ $SAVE_EXIT -ne 0 ]; then
      log_command_error "state_error" "Failed to persist state transitions" "$(jq -n --arg file "${STATE_FILE:-unknown}" '{state_file: $file}')"
      echo "ERROR: State persistence failed" >&2
      exit 1
    fi
    ```
- [x] Verify logging follows error-handling.md pattern

**Testing**:
```bash
# Verify syntax after edit
bash -n /home/benjamin/.config/.claude/commands/build.md

# Verify log_command_error function is available
source /home/benjamin/.config/.claude/lib/core/error-handling.sh && type log_command_error
```

**Expected Duration**: 0.75 hours

---

### Phase 3: Remove Error Suppression [COMPLETE]
dependencies: [1]

**Objective**: Make metadata update errors visible for debugging

**Complexity**: Low

**Tasks**:
- [x] Remove `2>/dev/null` from `update_plan_status` call at line 2032
  - File: `/home/benjamin/.config/.claude/commands/build.md`
  - Change: `if update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null; then`
  - To: `if update_plan_status "$PLAN_FILE" "COMPLETE"; then`
- [x] Add else branch with warning message for visibility
  - Add after successful message (line 2035):
    ```bash
    else
      echo "WARNING: Could not update plan status to COMPLETE" >&2
    fi
    ```
- [x] Verify warning message follows output-formatting.md standards

**Testing**:
```bash
# Test with non-existent plan file to verify error visibility
source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh
update_plan_status "/tmp/nonexistent.md" "COMPLETE"
# Should show error, not silent failure
```

**Expected Duration**: 0.5 hours

---

### Phase 4: Integration Testing and Documentation [COMPLETE]
dependencies: [2, 3]

**Objective**: Validate all changes work together and document for maintainability

**Complexity**: Medium

**Tasks**:
- [x] Create test plan file with phases for integration testing
  - Create: `/home/benjamin/.config/.claude/tmp/test_metadata_update_plan.md`
  - Include: Metadata section with Status field, 2 phases with [COMPLETE] markers
- [x] Run manual integration test simulating Block 4 execution
  - Source all required libraries in sequence
  - Execute metadata update logic
  - Verify plan file status updated to [COMPLETE]
- [x] Run existing /build command tests (if any exist)
  - Check `.claude/tests/` for build-related tests
- [x] Verify no regressions in related commands
  - Quick test: `/plan` and `/research` commands still work
- [x] Update build.md inline comments to document critical operations
  - Add comment before metadata update: `# CRITICAL: Update plan metadata status - must not be skipped`

**Testing**:
```bash
# Integration test script
cd /home/benjamin/.config

# Create test plan
cat > .claude/tmp/test_metadata_plan.md << 'EOF'
# Test Plan

## Metadata
- **Date**: 2025-11-23
- **Status**: [COMPLETE]

## Implementation Phases

### Phase 1: Test Phase [COMPLETE]
- [x] Task 1

### Phase 2: Test Phase 2 [COMPLETE]
- [x] Task 2
EOF

# Source libraries and test update
source .claude/lib/plan/checkbox-utils.sh
check_all_phases_complete ".claude/tmp/test_metadata_plan.md" && echo "All phases complete"
update_plan_status ".claude/tmp/test_metadata_plan.md" "COMPLETE"
grep "Status" ".claude/tmp/test_metadata_plan.md"
# Expected: - **Status**: [COMPLETE]

# Cleanup
rm -f .claude/tmp/test_metadata_plan.md
```

**Expected Duration**: 1.25 hours

## Testing Strategy

### Unit Tests
- Verify checkbox-utils.sh functions work in isolation
- Test `update_plan_status` with various plan formats
- Test `check_all_phases_complete` with complete/incomplete plans

### Integration Tests
- End-to-end test: Create plan, mark phases complete, run Block 4 logic
- Verify state file written before cleanup
- Verify plan metadata updated to [COMPLETE]

### Regression Tests
- Existing /build tests must pass
- /plan and /research commands unaffected
- Dry-run mode still works

### Manual Validation
- Run `/build` on a real plan and verify completion message includes metadata update confirmation

## Documentation Requirements

- [x] Add inline comments in build.md explaining critical operations
- [x] No README updates needed (internal refactor)
- [x] No CLAUDE.md updates needed (no new patterns introduced)

## Dependencies

### Prerequisites
- checkbox-utils.sh library exists at `.claude/lib/plan/checkbox-utils.sh`
- workflow-state-machine.sh provides `save_completed_states_to_state` function
- error-handling.sh provides `log_command_error` function

### Integration Points
- build.md Block 4 (lines 1750-2053)
- checkbox-utils.sh functions (lines 594-680)
- workflow-state-machine.sh state save function (lines 126-152)

## Risk Mitigation

**Risk**: Changes break existing workflows
**Mitigation**: All changes are additive (new sourcing, new call) or removal of suppression (makes errors visible, doesn't change logic). No structural changes to control flow.

**Risk**: Library sourcing fails silently
**Mitigation**: Uses `2>/dev/null || true` pattern for Tier 3 (graceful degradation). Functions check availability with `type` before calling.

**Risk**: State persistence call adds failure point
**Mitigation**: This matches proven pattern from plan.md and research.md. Error logging ensures visibility if issues occur.
