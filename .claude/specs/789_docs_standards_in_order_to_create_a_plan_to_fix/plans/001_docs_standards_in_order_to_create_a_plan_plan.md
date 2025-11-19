# Implementation Plan: Build Command Phase Update Integration

## Metadata
- **Date**: 2025-11-18
- **Feature**: Implementer subagent phase update mechanism for /build command
- **Scope**: Fix missing phase completion updates in build workflow
- **Estimated Phases**: 4
- **Estimated Hours**: 10-12 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 38
- **Research Reports**:
  - [Phase Update Investigation](/home/benjamin/.config/.claude/specs/789_docs_standards_in_order_to_create_a_plan_to_fix/reports/001_phase_update_investigation.md)

## Overview

The /build command's implementer subagent does not update plan phases when work is completed. While the infrastructure for plan updates exists (checkbox-utils.sh, spec-updater agent), the build.md command has no integration point that calls these utilities after phase completion. This plan addresses the missing integration between the implementer-coordinator agent and the plan update mechanisms.

## Research Summary

Key findings from the phase update investigation:

- **Root Cause**: build.md does not invoke spec-updater or checkbox-utils.sh after implementation phases complete
- **Infrastructure Exists**: checkbox-utils.sh has mark_phase_complete(), propagate_checkbox_update(), verify_checkbox_consistency()
- **Documentation Gap**: implementation-executor documents spec-updater invocation but build.md never triggers it
- **Prior Plan**: Spec 23 already identifies this gap and proposes Phase 2 solution (plan update integration)

Recommended approach: Add phase update integration between implementer-coordinator completion and testing phase in build.md.

## Success Criteria

- [x] Phases marked as complete after successful implementation
- [x] Plan file checkboxes updated from [ ] to [x] for completed tasks
- [x] [COMPLETE] marker added to phase headings
- [x] Phase update works with Level 0, 1, and 2 plan structures
- [x] Fallback mechanism if spec-updater agent fails
- [x] State persistence includes phase completion status
- [x] Integration tests verify end-to-end flow

## Technical Design

### Architecture Overview

The fix adds a phase update step between implementation completion and testing:

```
┌─────────────────┐     ┌─────────────────────┐     ┌────────────────┐
│  Implementer    │────>│  Phase Update Step  │────>│  Testing Phase │
│  Coordinator    │     │  (NEW INTEGRATION)  │     │  (Block 2)     │
└─────────────────┘     └─────────────────────┘     └────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            ┌───────▼───────┐         ┌───────▼───────┐
            │ spec-updater  │         │ Direct        │
            │ Agent         │         │ checkbox-utils│
            │ (primary)     │         │ (fallback)    │
            └───────────────┘         └───────────────┘
```

### Integration Points

1. **build.md Block 1** (after line 233): Add Task invocation for spec-updater agent
2. **implementer-coordinator**: Update output format to report phases completed
3. **state-persistence**: Store phase completion status for recovery
4. **checkbox-utils.sh**: Called by spec-updater for actual updates

### Phase Completion Flow

1. Implementer-coordinator returns list of completed phases
2. Build.md parses completion report and extracts phase numbers
3. For each completed phase, invoke spec-updater agent
4. Spec-updater calls mark_phase_complete() and adds [COMPLETE] marker
5. Verify checkbox consistency across hierarchy
6. Persist updated state before testing phase

## Implementation Phases

### Phase 1: Build Command Integration Point [COMPLETE]
dependencies: []

**Objective**: Add spec-updater agent invocation after implementer-coordinator completes

**Complexity**: Medium

Tasks:
- [x] Read build.md to identify exact insertion point (after line 233, before Block 2)
- [x] Add bash section to parse IMPLEMENTATION_COMPLETE response for completed phases
- [x] Extract phase count from implementer-coordinator structured return
- [x] Add loop to invoke spec-updater for each completed phase
- [x] Implement Task tool invocation pattern for spec-updater agent
- [x] Pass PLAN_FILE and phase number to spec-updater
- [x] Capture and log spec-updater response (files updated, checkboxes marked)
- [x] Add error handling for spec-updater invocation failures

**Testing**:
```bash
# Test with mock plan file
/build .claude/specs/test_plan/plans/001_test.md --dry-run
# Verify spec-updater invocation appears in output
```

**Expected Duration**: 3 hours

### Phase 2: Fallback and Verification Mechanism [COMPLETE]
dependencies: [1]

**Objective**: Add direct checkbox-utils.sh fallback and verification

**Complexity**: Medium

Tasks:
- [x] Add fallback logic when spec-updater agent fails or returns error
- [x] Source checkbox-utils.sh in build.md for fallback operations
- [x] Call mark_phase_complete() directly as fallback
- [x] Add [COMPLETE] marker to phase heading using sed
- [x] Implement verify_phase_complete() function to confirm completion
- [x] Add count-based verification (no unchecked tasks in phase)
- [x] Add git-based verification (recent commits exist)
- [x] Handle Level 0, 1, and 2 plan structures in verification

**Testing**:
```bash
# Force fallback by invalid agent path
# Verify direct checkbox-utils.sh is called
# Check plan file has [x] checkboxes
```

**Expected Duration**: 3 hours

### Phase 3: State Persistence and Recovery [COMPLETE]
dependencies: [1]

**Objective**: Persist phase completion status for workflow recovery

**Complexity**: Low

Tasks:
- [x] Add COMPLETED_PHASES array to workflow state
- [x] Update append_workflow_state to track completed phases
- [x] Save phase completion status in checkpoint before testing
- [x] Load completed phases on auto-resume to skip already-done phases
- [x] Add phase completion to build completion summary output
- [x] Update git log message to include phases completed count

**Testing**:
```bash
# Start build, interrupt after Phase 1
# Resume with /build (auto-resume)
# Verify Phase 1 not re-executed
```

**Expected Duration**: 2 hours

### Phase 4: Testing and Documentation [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Create tests and update documentation

**Complexity**: Low

Tasks:
- [x] Create test_plan_updates.sh test suite
- [x] Test Level 0 plan updates (single file)
- [x] Test Level 1 plan updates (phase expansion)
- [x] Test Level 2 plan updates (stage expansion)
- [x] Test fallback mechanism with agent failure simulation
- [x] Test state persistence and recovery
- [x] Update build-command-guide.md with phase update behavior
- [x] Document [COMPLETE] marker format and visibility
- [x] Add troubleshooting section for phase update failures

**Testing**:
```bash
# Run complete test suite
bash .claude/tests/test_plan_updates.sh
# All tests should pass
```

**Expected Duration**: 3 hours

## Testing Strategy

### Unit Tests
- Test mark_phase_complete() with various plan structures
- Test verify_phase_complete() with complete/incomplete phases
- Test state persistence save/load cycle

### Integration Tests
- End-to-end /build workflow with phase updates
- Auto-resume after interruption
- Fallback to direct checkbox-utils when agent fails

### Regression Tests
- Existing /build functionality unaffected
- State machine transitions work correctly
- Checkpoint recovery functions properly

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` - Add phase update section
- `/home/benjamin/.config/.claude/commands/build.md` - Add inline comments for new integration
- `/home/benjamin/.config/.claude/agents/implementer-coordinator.md` - Update output format documentation

### New Documentation
- None (updates only, no new doc files needed)

## Dependencies

### Internal Dependencies
- checkbox-utils.sh (>=1.0.0)
- spec-updater agent
- state-persistence.sh (>=1.5.0)
- workflow-state-machine.sh (>=2.0.0)

### External Dependencies
- None

## Risk Assessment

### Technical Risks

1. **Agent Invocation Failure** (Medium)
   - Mitigation: Fallback to direct checkbox-utils.sh
   - Detection: Check for error in Task tool response

2. **Plan File Corruption** (Low)
   - Mitigation: Use atomic updates with temp files
   - Detection: verify_checkbox_consistency() after updates

3. **State Persistence Issues** (Low)
   - Mitigation: Validate state before/after phase updates
   - Detection: Recovery test in Phase 4

### Schedule Risks

1. **Implementation Complexity** (Low)
   - Prior plan (Spec 23) provides detailed implementation template
   - Infrastructure already exists, only wiring needed
