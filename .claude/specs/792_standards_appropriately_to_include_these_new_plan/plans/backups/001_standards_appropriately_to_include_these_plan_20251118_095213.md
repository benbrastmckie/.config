# Plan Metadata Update Patterns Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Plan metadata progress tracking with [IN PROGRESS] and [COMPLETE] markers
- **Scope**: Extend checkbox-utils.sh, modify build.md, update documentation standards
- **Estimated Phases**: 5
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 41.5
- **Research Reports**:
  - [Plan Metadata Update Research](../reports/001_plan_metadata_update_research.md)

## Overview

This plan implements comprehensive plan metadata progress tracking for the /build command workflow. The implementation adds [IN PROGRESS] markers when phases begin execution and ensures [COMPLETE] markers are properly applied when phases finish. It also supports parent plan metadata updates for expanded (Level 1/2) plans and documents these new patterns in .claude/docs/ standards.

## Research Summary

Key findings from the research report:
- **Existing infrastructure**: checkbox-utils.sh already has `add_complete_marker()` and `mark_phase_complete()` functions
- **Gap identified**: No `[IN PROGRESS]` markers applied when phases begin execution
- **Prior research**: Prior spec 23 proposed `update_phase_heading_status()` function pattern
- **Build command integration**: Phase updates happen at lines 303-371 in build.md
- **Documentation gap**: build-command-guide.md documents phase updates but not progress tracking patterns

Recommended approach: Extend checkbox-utils.sh with progress marker functions, update build.md to call them at appropriate points, and create comprehensive documentation.

## Success Criteria

- [ ] `add_in_progress_marker()` function exists in checkbox-utils.sh and works correctly
- [ ] `remove_status_marker()` function exists for clearing markers before applying new ones
- [ ] Build command marks phases as `[IN PROGRESS]` before implementer-coordinator starts each phase
- [ ] Build command properly replaces `[IN PROGRESS]` with `[COMPLETE]` when phases finish
- [ ] Parent plan metadata updates work for Level 1/2 expanded plans
- [ ] New plan-progress-tracking.md documentation file created in .claude/docs/reference/
- [ ] build-command-guide.md updated with progress tracking section
- [ ] All test cases pass for progress marker functions
- [ ] Plan files show correct progress indicators during and after /build execution

## Technical Design

### Architecture

The implementation extends the existing checkbox-utils.sh library with two new functions and modifies the build.md command to invoke them at the appropriate workflow points.

```
┌─────────────────────────────────────┐
│         /build command              │
├─────────────────────────────────────┤
│ Block 1: Setup                      │
│   └── Mark starting phase           │
│       [IN PROGRESS]                 │
├─────────────────────────────────────┤
│ implementer-coordinator             │
│   └── (For each phase)              │
│       - Mark previous [COMPLETE]    │
│       - Mark current [IN PROGRESS]  │
├─────────────────────────────────────┤
│ Block 2: Phase Updates              │
│   └── Mark all phases [COMPLETE]    │
│       with checkbox updates         │
└─────────────────────────────────────┘
```

### Function Design

**add_in_progress_marker()**
- Input: plan_path, phase_num
- Behavior: Remove existing status markers, add [IN PROGRESS] to phase heading
- Error handling: Return 1 if file not found, awk failure

**remove_status_marker()**
- Input: plan_path, phase_num
- Behavior: Remove any status marker from phase heading
- Used by: add_in_progress_marker, add_complete_marker (to ensure clean state)

**Modified add_complete_marker()**
- Update to remove [IN PROGRESS] before adding [COMPLETE]

### Integration Points

1. **Build.md Block 1** (line ~196): After plan file validation, before Task invocation
   - Source checkbox-utils.sh
   - Call `add_in_progress_marker()` for starting phase

2. **Implementer-coordinator agent prompt**: Add instruction for phase status updates
   - Mark previous phase complete
   - Mark current phase in progress

3. **Build.md Phase Update Block** (lines 303-371): After implementation complete
   - Existing `add_complete_marker()` calls remain
   - Ensure IN PROGRESS is replaced with COMPLETE

## Implementation Phases

### Phase 1: Core Library Functions
dependencies: []

**Objective**: Create the new progress marker functions in checkbox-utils.sh

**Complexity**: Medium

Tasks:
- [ ] Add `add_in_progress_marker()` function to checkbox-utils.sh (file: /home/benjamin/.config/.claude/lib/checkbox-utils.sh, after line 361)
  - Accept plan_path and phase_num parameters
  - Use awk to find phase heading and remove existing markers
  - Add [IN PROGRESS] marker to end of heading
  - Handle file not found and awk errors
- [ ] Add `remove_status_marker()` function to checkbox-utils.sh
  - Accept plan_path and phase_num parameters
  - Use awk to remove any status marker ([COMPLETE], [IN PROGRESS], [BLOCKED], [SKIPPED])
  - Keep heading text intact
- [ ] Update `add_complete_marker()` function to remove existing markers first (file: checkbox-utils.sh:335-361)
  - Add marker removal before adding [COMPLETE]
  - Prevents duplicate markers like [IN PROGRESS] [COMPLETE]
- [ ] Export new functions at end of checkbox-utils.sh (line ~412)
  - Add `export -f add_in_progress_marker`
  - Add `export -f remove_status_marker`

Testing:
```bash
# Test add_in_progress_marker
source .claude/lib/checkbox-utils.sh
echo "### Phase 1: Setup" > /tmp/test_plan.md
add_in_progress_marker "/tmp/test_plan.md" "1"
grep -q "\[IN PROGRESS\]" /tmp/test_plan.md && echo "PASS" || echo "FAIL"

# Test remove_status_marker
echo "### Phase 1: Setup [IN PROGRESS]" > /tmp/test_plan.md
remove_status_marker "/tmp/test_plan.md" "1"
! grep -q "\[IN PROGRESS\]" /tmp/test_plan.md && echo "PASS" || echo "FAIL"

# Test add_complete_marker replaces IN PROGRESS
echo "### Phase 1: Setup [IN PROGRESS]" > /tmp/test_plan.md
add_complete_marker "/tmp/test_plan.md" "1"
grep -q "\[COMPLETE\]" /tmp/test_plan.md && ! grep -q "\[IN PROGRESS\]" /tmp/test_plan.md && echo "PASS" || echo "FAIL"
```

**Expected Duration**: 1.5 hours

### Phase 2: Build Command Integration
dependencies: [1]

**Objective**: Integrate progress tracking into /build command workflow

**Complexity**: Medium

Tasks:
- [ ] Add IN PROGRESS marker in Block 1 after plan validation (file: /home/benjamin/.config/.claude/commands/build.md, after line 196)
  - Source checkbox-utils.sh if not already sourced
  - Call `add_in_progress_marker "$PLAN_FILE" "$STARTING_PHASE"`
  - Handle errors gracefully (don't fail build if marker fails)
- [ ] Update implementer-coordinator Task prompt to include progress tracking instructions (file: build.md, lines 203-239)
  - Add instruction: "Before starting each phase, call add_in_progress_marker"
  - Add instruction: "After completing each phase, mark_phase_complete and add_complete_marker"
  - Reference checkbox-utils.sh sourcing
- [ ] Verify Phase Update Block properly replaces markers (file: build.md, lines 303-371)
  - Confirm add_complete_marker now handles removal of IN PROGRESS
  - Add comment explaining marker replacement behavior
- [ ] Add persist for completed phase tracking (file: build.md, after line 361)
  - Track which phases have been marked complete
  - Support recovery after interruption

Testing:
```bash
# Create test plan
cat > /tmp/test_build_plan.md <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-11-18

## Implementation Phases

### Phase 1: Setup

Tasks:
- [ ] Task 1

### Phase 2: Implementation

Tasks:
- [ ] Task 2
EOF

# Run build in dry-run to verify marker calls
/build /tmp/test_build_plan.md --dry-run
# Verify plan shows Phase 1 with [IN PROGRESS] marker
```

**Expected Duration**: 2 hours

### Phase 3: Parent Plan Hierarchy Support
dependencies: [1]

**Objective**: Ensure progress markers propagate to parent plans in Level 1/2 structures

**Complexity**: Low

Tasks:
- [ ] Create `propagate_progress_marker()` function in checkbox-utils.sh
  - Accept plan_path, phase_num, and status parameter
  - Detect structure level using `detect_structure_level()`
  - Update both expanded phase file and main plan
  - Handle Level 0 (single file) - direct update only
  - Handle Level 1 (phase expansion) - update phase file + main plan
  - Handle Level 2 (stage expansion) - update stage file + phase file + main plan
- [ ] Update `add_in_progress_marker()` to call `propagate_progress_marker()` for Level 1/2
- [ ] Update `add_complete_marker()` to call `propagate_progress_marker()` for Level 1/2
- [ ] Export `propagate_progress_marker()` function

Testing:
```bash
# Test with Level 1 expanded plan structure
mkdir -p /tmp/test_topic/plans/001_test
echo "### Phase 1: Setup" > /tmp/test_topic/plans/001_test.md
echo "### Phase 1: Setup" > /tmp/test_topic/plans/001_test/phase_1_setup.md

source .claude/lib/checkbox-utils.sh
add_in_progress_marker "/tmp/test_topic/plans/001_test.md" "1"

# Verify both files updated
grep -q "\[IN PROGRESS\]" /tmp/test_topic/plans/001_test.md && \
grep -q "\[IN PROGRESS\]" /tmp/test_topic/plans/001_test/phase_1_setup.md && \
echo "PASS" || echo "FAIL"
```

**Expected Duration**: 1.5 hours

### Phase 4: Documentation Standards
dependencies: [1, 2]

**Objective**: Create comprehensive documentation for plan progress tracking patterns

**Complexity**: Low

Tasks:
- [ ] Create plan-progress-tracking.md in .claude/docs/reference/ (new file)
  - Document all four status markers: [IN PROGRESS], [COMPLETE], [BLOCKED], [SKIPPED]
  - Provide usage patterns with code examples
  - Show visual example of plan progress
  - Document implementation functions and their signatures
  - Include integration notes for /build command
- [ ] Update build-command-guide.md with Progress Tracking section (file: /home/benjamin/.config/.claude/docs/guides/build-command-guide.md, after line 135)
  - Add "Progress Tracking During Execution" subsection
  - Show workflow diagram for status transitions
  - Document when markers are applied
  - Reference plan-progress-tracking.md for complete details
- [ ] Update library-api.md or library-api-utilities.md with new function documentation
  - Document add_in_progress_marker() signature and behavior
  - Document remove_status_marker() signature and behavior
  - Document propagate_progress_marker() signature and behavior
- [ ] Update checkbox-utils.sh header comment with new functions list

Testing:
```bash
# Verify documentation files exist and have required content
test -f .claude/docs/reference/plan-progress-tracking.md && echo "plan-progress-tracking.md exists"
grep -q "IN PROGRESS" .claude/docs/reference/plan-progress-tracking.md && echo "Contains IN PROGRESS"
grep -q "add_in_progress_marker" .claude/docs/reference/plan-progress-tracking.md && echo "Documents function"
grep -q "Progress Tracking" .claude/docs/guides/build-command-guide.md && echo "build-command-guide updated"
```

**Expected Duration**: 1.5 hours

### Phase 5: Testing and Validation
dependencies: [1, 2, 3, 4]

**Objective**: Comprehensive testing of progress tracking implementation

**Complexity**: Low

Tasks:
- [ ] Create test file test_plan_progress_markers.sh in .claude/tests/ (new file)
  - Test add_in_progress_marker() for various phase numbers
  - Test remove_status_marker() for all marker types
  - Test add_complete_marker() replacing IN PROGRESS
  - Test propagate_progress_marker() for Level 1 plans
  - Test edge cases: phase not found, invalid phase number, file not found
- [ ] Create integration test for /build command progress tracking
  - Create test plan with multiple phases
  - Run /build and verify markers applied correctly
  - Verify final state shows all phases [COMPLETE]
- [ ] Verify existing checkbox-utils tests still pass
  - Run .claude/tests/test_build_state_transitions.sh
  - Ensure no regressions in mark_phase_complete, verify_phase_complete
- [ ] Manual validation with real plan file
  - Run /build on an existing spec plan
  - Verify progress markers appear during execution
  - Confirm final state is correct

Testing:
```bash
# Run all progress marker tests
bash .claude/tests/test_plan_progress_markers.sh

# Run existing checkbox tests
bash .claude/tests/test_build_state_transitions.sh

# Verify no errors
echo "All tests passed: $?"
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Tests
- Each new function in checkbox-utils.sh tested in isolation
- Test files created in /tmp or test fixtures directory
- Verify return codes and file modifications

### Integration Tests
- End-to-end /build command execution
- Verify state transitions and marker application
- Test with Level 0, 1, and 2 plan structures

### Regression Tests
- Existing mark_phase_complete tests must pass
- Existing verify_phase_complete tests must pass
- No changes to existing test behavior

### Manual Validation
- Real plan file execution
- Visual verification of markers in plan files
- Confirm documentation accuracy

## Documentation Requirements

### New Documentation
- `/home/benjamin/.config/.claude/docs/reference/plan-progress-tracking.md` - Complete reference for progress tracking patterns

### Updated Documentation
- `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` - Add Progress Tracking section
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` - Update header comment with new functions

### Cross-References
- build-command-guide.md should reference plan-progress-tracking.md
- plan-progress-tracking.md should reference checkbox-utils.sh library
- CLAUDE.md may need reference in testing_protocols section

## Dependencies

### Required Libraries
- checkbox-utils.sh (existing, to be extended)
- plan-core-bundle.sh (existing, provides detect_structure_level, get_plan_directory)
- base-utils.sh (existing, provides error/warn/log functions)

### External Dependencies
- awk (standard Unix utility)
- sed (standard Unix utility)
- bash 4.0+ (for associative arrays if needed)

### Prerequisite Conditions
- .claude/lib/ directory must exist
- Existing checkbox-utils.sh functions must work correctly
- Build command must source checkbox-utils.sh

## Risks and Mitigations

### Risk 1: Awk Pattern Matching Failures
- **Risk**: Phase headings with unusual formatting may not match
- **Mitigation**: Use flexible regex patterns, test with various heading formats

### Risk 2: Marker Duplication
- **Risk**: [IN PROGRESS] [COMPLETE] appearing on same heading
- **Mitigation**: Always remove existing markers before adding new ones

### Risk 3: Performance Impact
- **Risk**: Additional file I/O for marker updates
- **Mitigation**: Marker operations are lightweight, single pass through file

### Risk 4: Level 2 Plan Complexity
- **Risk**: Stage-level propagation may be complex
- **Mitigation**: Start with Level 0/1 support, extend to Level 2 if needed
