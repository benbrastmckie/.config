# Plan Progress Tracking Fix - Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Fix /implement plan file progress tracking to update phase markers in real-time during execution
- **Scope**: Integrate checkbox-utils.sh into implementation-executor agent to mark phases [IN PROGRESS] and [COMPLETE] as they execute, replacing deferred batch updates with real-time progress visibility
- **Status**: [COMPLETE]
- **Estimated Hours**: 11-13 hours
- **Complexity Score**: 125 (Medium-High)
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Progress Tracking Analysis](../reports/001-progress-tracking-analysis.md)

## Overview

The /implement command currently updates plan file phase markers ([COMPLETE]) only after all implementation finishes (Block 1d batch update), providing no real-time progress visibility during long-running implementations. This causes poor user experience as users cannot track which phase is executing or completed.

**Root Cause**: The implementer-coordinator passes "Progress Tracking Instructions" to itself but does NOT execute them. The implementation-executor has write permissions but only updates task checkboxes, not phase status markers. Progress tracking responsibility falls through the architectural gap between orchestration (coordinator) and execution (executor).

**Solution**: Integrate checkbox-utils.sh into implementation-executor agent to call `add_in_progress_marker()` at phase start and `add_complete_marker()` at phase end. Simplify /implement Block 1d from batch-update to validation-and-recovery mode. Apply same fix to /build command for consistency.

## Research Summary

Comprehensive research analysis identified three architectural gaps:

1. **No Real-Time Phase Marker Updates**: implementer-coordinator receives progress tracking instructions but does not execute them (no checkbox-utils.sh integration, no bash blocks calling marker functions)

2. **Block 1d Batch Update Only**: /implement Block 1d marks ALL phases complete in single loop after workflow finishes, providing no visibility during execution

3. **Missing Coordinator-to-Executor Contract**: Coordinator lacks write permissions (orchestration-focused), executor has write permissions but is not instructed to update phase markers (task-focused)

Research recommends Solution 1 (Executor-Level Phase Tracking) as it provides real-time tracking, maintains architectural separation, and works naturally with parallel execution.

## Success Criteria

- [ ] Phase markers update as phases complete (not batch after)
- [ ] User can `cat plan.md` to see current progress during execution
- [ ] All phases marked [COMPLETE] after successful execution
- [ ] Block 1d detects and recovers missing markers (graceful degradation)
- [ ] Marker update failures are non-fatal (logged as warnings)
- [ ] Same pattern applied to both /implement and /build commands
- [ ] Integration tests verify real-time behavior
- [ ] Performance impact negligible (<100ms per phase)

## Technical Design

### Architecture Overview

```
/implement (Block 1a-1d, Block 2)
  └─> Task: implementer-coordinator.md
        └─> Task(s): implementation-executor.md (per phase)
              ├─> STEP 1: Source checkbox-utils.sh + mark phase [IN PROGRESS]  ← NEW
              ├─> STEP 2: Execute tasks + mark checkboxes [x]  ← EXISTING
              ├─> STEP 3: Mark phase [COMPLETE] + invoke spec-updater  ← MODIFIED
              └─> Return: PHASE_COMPLETE with marker status  ← MODIFIED
```

### Key Changes

1. **implementation-executor.md STEP 1**: Add checkbox-utils.sh sourcing and `add_in_progress_marker()` call
2. **implementation-executor.md STEP 3**: Add `add_complete_marker()` call before spec-updater invocation
3. **implementation-executor.md STEP 5**: Update return signal to include `phase_marker_updated: true|false`
4. **implementer-coordinator.md STEP 4**: Update progress monitoring to validate marker updates (optional)
5. **/implement Block 1d**: Refactor from batch-update to validation-and-recovery mode
6. **/build Block 1d**: Apply same validation-and-recovery logic

### Failure Handling

- Marker update failures are non-fatal (executor logs warning, continues execution)
- Block 1d detects phases with all checkboxes complete but missing [COMPLETE] marker
- Block 1d applies recovery logic: `verify_phase_complete()` + `add_complete_marker()`
- Users retain visibility even if real-time tracking partially fails

### Standards Compliance

- Follows three-tier sourcing pattern (checkbox-utils.sh sourced in STEP 1 with fail-fast handler)
- Error suppression uses `2>/dev/null || true` pattern for non-critical operations
- Checkpoint format maintained in Block 1d with validation output
- Clean-break approach: No deprecation period, direct replacement of batch logic with validation logic

## Implementation Phases

### Phase 1: Update implementation-executor Agent [COMPLETE]
dependencies: []

**Objective**: Add checkbox-utils.sh integration to implementation-executor for phase-level status markers

**Complexity**: Medium

**Tasks**:
- [x] Add STEP 1 initialization: Source checkbox-utils.sh with error handling (file: .claude/agents/implementation-executor.md, after line 50)
- [x] Add STEP 1 marker update: Call `add_in_progress_marker()` for phase start (file: .claude/agents/implementation-executor.md, after sourcing block)
- [x] Add STEP 3 completion marker: Call `add_complete_marker()` after all tasks complete (file: .claude/agents/implementation-executor.md, before spec-updater invocation at line 109)
- [x] Add STEP 3 fallback logic: Use `mark_phase_complete()` if `add_complete_marker()` verification fails (file: .claude/agents/implementation-executor.md, in STEP 3)
- [x] Update STEP 5 return signal: Add `phase_marker_updated: true|false` field to PHASE_COMPLETE signal (file: .claude/agents/implementation-executor.md, return signal section)
- [x] Add error handling section: Document non-fatal marker update failures (file: .claude/agents/implementation-executor.md, error handling section)

**Testing**:
```bash
# Create test plan with single phase
cat > /tmp/test_plan.md <<'EOF'
### Phase 1: Test Phase [COMPLETE]

**Tasks**:
- [x] Task 1
- [x] Task 2
EOF

# Manually invoke implementation-executor agent (via /implement)
/implement /tmp/test_plan.md 1

# Verify phase marker appears during execution
cat /tmp/test_plan.md | grep "### Phase 1:"
# Expected: ### Phase 1: Test Phase [IN PROGRESS] (during execution)

# After completion
cat /tmp/test_plan.md | grep "### Phase 1:"
# Expected: ### Phase 1: Test Phase [COMPLETE]
```

**Expected Duration**: 2-3 hours

### Phase 2: Update implementer-coordinator Agent [COMPLETE]
dependencies: [1]

**Objective**: Modify coordinator to expect and validate phase marker updates from executors

**Complexity**: Low-Medium

**Tasks**:
- [x] Update STEP 4 progress monitoring: Add optional validation for phase [COMPLETE] markers (file: .claude/agents/implementer-coordinator.md, STEP 4 section around line 332)
- [x] Add marker validation bash block: Check if phase heading has [COMPLETE] marker after executor reports success (file: .claude/agents/implementer-coordinator.md, in STEP 4)
- [x] Update output format: Add `phases_with_markers: N` field to IMPLEMENTATION_COMPLETE signal (file: .claude/agents/implementer-coordinator.md, output format section around line 522)
- [x] Add non-fatal warning: Log warning if marker missing but do not fail (coordinator trusts Block 1d recovery)

**Testing**:
```bash
# Run full implementation with multi-phase plan
/implement test_plan.md

# Check coordinator report includes marker status
grep "phases_with_markers" .claude/specs/*/summaries/*.md

# Expected: phases_with_markers: N (where N = total phases)
```

**Expected Duration**: 1-2 hours

### Phase 3: Simplify /implement Block 1d [COMPLETE]
dependencies: [1, 2]

**Objective**: Convert Block 1d from batch-update to validation-and-recovery mode

**Complexity**: Medium

**Tasks**:
- [x] Update Block 1d header: Change title from "Phase Marker Update" to "Phase Marker Validation and Recovery" (file: .claude/commands/implement.md, line 1041)
- [x] Refactor Block 1d logic: Replace batch marking loop with validation check (file: .claude/commands/implement.md, lines 1070-1180)
- [x] Add validation output: Count phases with [COMPLETE] marker vs total phases (file: .claude/commands/implement.md, Block 1d)
- [x] Add recovery logic: Mark phases with all checkboxes complete but missing [COMPLETE] marker (file: .claude/commands/implement.md, Block 1d)
- [x] Add verification step: Call `verify_checkbox_consistency()` after recovery (file: .claude/commands/implement.md, end of Block 1d)
- [x] Update Block 1d comments: Document validation-and-recovery rationale (file: .claude/commands/implement.md, Block 1d header)

**Testing**:
```bash
# Run implementation that succeeds normally
/implement test_plan.md
# Expected: Block 1d reports "All phases marked complete by executors"

# Simulate executor failure (manually remove [COMPLETE] from Phase 2)
sed -i 's/### Phase 2:.* \[COMPLETE\]/### Phase 2: Testing/' test_plan.md

# Re-run Block 1d logic (via /implement resume or manual execution)
# Expected: Block 1d reports "Recovering Phase 2 (all tasks complete but marker missing)"

# Verify recovery worked
cat test_plan.md | grep "### Phase 2:"
# Expected: ### Phase 2: Testing [COMPLETE]
```

**Expected Duration**: 2 hours

### Phase 4: Update /build Command [COMPLETE]
dependencies: [3]

**Objective**: Apply the same fix to /build command for consistency

**Complexity**: Low

**Tasks**:
- [x] Copy validation-and-recovery logic from /implement Block 1d (file: .claude/commands/build.md, Block 1d section around lines 980-1000)
- [x] Adjust variable names if needed: Change PLAN_FILE to match /build naming conventions (file: .claude/commands/build.md, Block 1d)
- [x] Verify implementer-coordinator integration: Confirm /build uses same coordinator agent (no changes needed)
- [x] Update Block 1d comments: Document validation behavior (file: .claude/commands/build.md, Block 1d)

**Testing**:
```bash
# Run /build workflow with multi-phase plan
/build test_plan.md

# Verify phase markers updated during execution
cat test_plan.md | grep "### Phase [0-9]"
# Expected: All phases show [COMPLETE] markers

# Check build output for validation message
grep "Phase Marker Validation" .claude/output/build-output.md
# Expected: "✓ All phases marked complete by executors"
```

**Expected Duration**: 1 hour

### Phase 5: Create Integration Tests [COMPLETE]
dependencies: [3, 4]

**Objective**: Add comprehensive tests to prevent regression

**Complexity**: Medium

**Tasks**:
- [x] Create test file: `.claude/tests/integration/test_implement_progress_tracking.sh`
- [x] Write test 1: Verify `add_in_progress_marker()` called at phase start
- [x] Write test 2: Verify `add_complete_marker()` called at phase end
- [x] Write test 3: Verify Block 1d recovery for missing markers
- [x] Write test 4: Verify parallel execution does not corrupt plan file
- [x] Add to test suite: Update `.claude/tests/integration/test_all_fixes_integration.sh` to include new test
- [x] Document test usage: Add test description to test file header

**Testing**:
```bash
# Run integration test
bash .claude/tests/integration/test_implement_progress_tracking.sh

# Expected output:
# ✓ Test 1 passed: Phase marked [IN PROGRESS] at start
# ✓ Test 2 passed: Phase marked [COMPLETE] at end
# ✓ Test 3 passed: Block 1d recovery works
# ✓ Test 4 passed: Parallel execution safe
# All progress tracking tests passed

# Run full test suite to verify no regressions
bash .claude/tests/integration/test_all_fixes_integration.sh
```

**Expected Duration**: 3 hours

### Phase 6: Update Documentation [COMPLETE]
dependencies: [5]

**Objective**: Document the progress tracking behavior and troubleshooting

**Complexity**: Low

**Tasks**:
- [x] Update implementation-executor docs: Add "Progress Tracking" section documenting marker updates (file: .claude/agents/implementation-executor.md, new section after Core Responsibilities)
- [x] Update implement command guide: Add section on real-time progress tracking (file: .claude/docs/guides/commands/implement-command-guide.md, new section)
- [x] Update plan progress standards: Document executor responsibility for phase markers (file: .claude/docs/reference/standards/plan-progress.md, update responsibilities section)
- [x] Add troubleshooting section: Document missing marker recovery in implement command guide
- [x] Update CLAUDE.md if needed: Add reference to real-time tracking in relevant sections

**Testing**:
```bash
# Verify documentation is consistent
grep -r "add_in_progress_marker" .claude/docs/
grep -r "add_complete_marker" .claude/docs/

# Verify cross-references are valid
bash .claude/scripts/validate-all-standards.sh --links

# Expected: No broken links, consistent terminology
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- Test checkbox-utils.sh functions in isolation (already exist in `.claude/tests/lib/`)
- Test marker update logic separately from execution logic
- Verify error handling for missing files, invalid phase numbers

### Integration Testing
- Test executor marker updates during actual /implement execution
- Test Block 1d recovery logic with various failure scenarios
- Test parallel execution with multiple executors writing simultaneously
- Test continuation scenarios (context exhaustion mid-implementation)

### End-to-End Testing
- Run /implement on real multi-phase plans
- Verify markers appear in real-time (manual `cat plan.md` during execution)
- Verify final plan state matches expected (all phases [COMPLETE])
- Run /build workflow to verify consistency

### Regression Testing
- Run existing test suite to verify no behavioral changes
- Test legacy plans (no status markers) to verify migration logic still works
- Test error scenarios to verify graceful degradation

## Documentation Requirements

### Files to Create
- `.claude/tests/integration/test_implement_progress_tracking.sh` - Integration test suite

### Files to Update
- `.claude/agents/implementation-executor.md` - Add Progress Tracking section, update STEP 1/3/5
- `.claude/agents/implementer-coordinator.md` - Update STEP 4 progress monitoring, output format
- `.claude/commands/implement.md` - Refactor Block 1d to validation mode
- `.claude/commands/build.md` - Refactor Block 1d to validation mode
- `.claude/docs/guides/commands/implement-command-guide.md` - Document real-time tracking behavior
- `.claude/docs/reference/standards/plan-progress.md` - Update responsibility assignments
- `.claude/tests/integration/test_all_fixes_integration.sh` - Add new test to suite

### Documentation Sections to Add
- **implementation-executor.md**: "Progress Tracking" section explaining when markers are updated
- **implement-command-guide.md**: "Real-Time Progress Tracking" section with examples
- **implement-command-guide.md**: "Troubleshooting Missing Markers" section for Block 1d recovery

## Dependencies

### External Dependencies
- checkbox-utils.sh library (already exists, no changes needed)
- spec-updater.md agent (already exists, no changes needed)
- dependency-analyzer.sh utility (used by coordinator, no changes needed)

### Internal Dependencies
- Phase 2 depends on Phase 1 (coordinator validates executor marker updates)
- Phase 3 depends on Phases 1-2 (Block 1d validates markers set by executor)
- Phase 4 depends on Phase 3 (uses same validation logic)
- Phase 5 depends on Phases 3-4 (tests both /implement and /build)
- Phase 6 depends on Phase 5 (documents tested behavior)

### Standards Dependencies
- Three-tier sourcing pattern (Code Standards)
- Checkpoint format for console output (Output Formatting Standards)
- Error suppression patterns for non-critical failures (Error Logging Standards)
- Clean-break development (no deprecation periods) (Clean-Break Development Standard)

## Risk Assessment

### Risk 1: Executor Context Increase
- **Likelihood**: Low
- **Impact**: Low (checkbox-utils.sh is <700 lines)
- **Mitigation**: Monitor context usage after changes, extract minimal subset if needed

### Risk 2: Marker Update Failures Go Unnoticed
- **Likelihood**: Low (functions well-tested)
- **Impact**: Medium (poor UX, but Block 1d recovers)
- **Mitigation**: Explicit error logging in executor, Block 1d detection, integration tests

### Risk 3: Parallel Execution Race Conditions
- **Likelihood**: Very Low (each executor updates different phase headings)
- **Impact**: High (file corruption)
- **Mitigation**: Plan file edits isolated to phase headings, checkbox-utils.sh uses atomic temp file + mv, integration tests with parallel execution

### Risk 4: Backward Compatibility
- **Likelihood**: Low (legacy plans migrated by `add_not_started_markers()`)
- **Impact**: Low (cosmetic only)
- **Mitigation**: /implement Block 1a already handles legacy plans, test with both formats

## Timeline Estimate

- **Phase 1**: 2-3 hours (executor agent updates)
- **Phase 2**: 1-2 hours (coordinator agent updates)
- **Phase 3**: 2 hours (implement Block 1d refactor)
- **Phase 4**: 1 hour (build Block 1d refactor)
- **Phase 5**: 3 hours (integration tests)
- **Phase 6**: 2 hours (documentation)

**Total**: 11-13 hours

## Completion Signal

After implementation:
- Phase markers update in real-time during /implement execution
- Users see progress via `cat plan.md` (Phase 1 [COMPLETE], Phase 2 [IN PROGRESS], etc.)
- Block 1d validates markers and recovers any missing
- Same behavior applies to /build command
- Integration tests verify real-time tracking
- Documentation explains new behavior and troubleshooting
