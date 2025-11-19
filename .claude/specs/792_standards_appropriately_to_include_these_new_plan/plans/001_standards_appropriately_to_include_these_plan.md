# Plan Metadata Update Patterns Implementation Plan

## Metadata
- **Date**: 2025-11-18
- **Feature**: Plan metadata progress tracking with [NOT STARTED], [IN PROGRESS], and [COMPLETE] markers
- **Scope**: Extend plan-architect agent, checkbox-utils.sh, modify build.md, update documentation standards
- **Estimated Phases**: 7
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 58.5
- **Research Reports**:
  - [Plan Metadata Update Research](../reports/001_plan_metadata_update_research.md)
  - [Plan Command NOT STARTED Markers Research](../reports/001_plan_command_not_started_markers.md)

## Overview

This plan implements comprehensive plan metadata progress tracking across the entire plan lifecycle. The implementation establishes a three-state marker system:
- **[NOT STARTED]**: Applied during plan creation by plan-architect agent
- **[IN PROGRESS]**: Applied by /build command when phase execution begins
- **[COMPLETE]**: Applied by /build command when phase execution ends

This creates end-to-end visibility of phase status from plan creation through implementation completion.

## Research Summary

Key findings from the research reports:

**From Plan Metadata Update Research**:
- Existing infrastructure: checkbox-utils.sh already has `add_complete_marker()` and `mark_phase_complete()` functions
- Gap identified: No `[IN PROGRESS]` markers applied when phases begin execution
- Build command integration: Phase updates happen at lines 303-371 in build.md

**From Plan Command NOT STARTED Markers Research**:
- Plan creation delegation: /plan command delegates entirely to plan-architect agent
- Template location: plan-architect.md lines 508-586 contains the standard plan template
- Current gap: Phase headings formatted as `### Phase N: [Name]` without status markers
- Target state: Phase headings should be `### Phase N: [Name] [NOT STARTED]`
- Marker regex needs to include `NOT STARTED` for proper transitions

Recommended approach: Modify plan-architect template first, then extend checkbox-utils.sh with lifecycle-aware functions, update build.md to call them, and create comprehensive documentation.

## Success Criteria

- [ ] Plan-architect agent template generates phases with `[NOT STARTED]` markers
- [ ] New plans created by /plan command have `[NOT STARTED]` on all phase headings
- [ ] `add_in_progress_marker()` function exists in checkbox-utils.sh and works correctly
- [ ] `remove_status_marker()` function handles all four marker types including [NOT STARTED]
- [ ] Build command marks phases as `[IN PROGRESS]` before implementer-coordinator starts each phase
- [ ] Build command properly replaces `[IN PROGRESS]` with `[COMPLETE]` when phases finish
- [ ] Parent plan metadata updates work for Level 1/2 expanded plans
- [ ] New plan-progress-tracking.md documentation file created in .claude/docs/reference/
- [ ] build-command-guide.md updated with progress tracking section
- [ ] workflow-phases-planning.md updated with [NOT STARTED] marker examples
- [ ] All test cases pass for progress marker functions
- [ ] Plan files show correct progress indicators throughout their lifecycle

## Technical Design

### Architecture

The implementation creates a complete marker lifecycle by modifying multiple components:

```
┌─────────────────────────────────────────┐
│    Plan Creation (/plan command)         │
├─────────────────────────────────────────┤
│ plan-architect agent:                    │
│   └── Generate phases with               │
│       [NOT STARTED] markers              │
└─────────────────────────────────────────┘
              │
              v
┌─────────────────────────────────────────┐
│    Build Execution (/build command)      │
├─────────────────────────────────────────┤
│ Block 1: Setup                           │
│   └── Mark starting phase                │
│       [NOT STARTED] -> [IN PROGRESS]     │
├─────────────────────────────────────────┤
│ implementer-coordinator                  │
│   └── (For each phase)                   │
│       - Mark previous [COMPLETE]         │
│       - Mark current [IN PROGRESS]       │
├─────────────────────────────────────────┤
│ Block 2: Phase Updates                   │
│   └── Mark all phases [COMPLETE]         │
│       with checkbox updates              │
└─────────────────────────────────────────┘
```

### Marker Lifecycle

```
Plan Creation:        ### Phase 1: Setup [NOT STARTED]
                      ### Phase 2: Implementation [NOT STARTED]
                      ### Phase 3: Testing [NOT STARTED]

Build Phase 1 Start:  ### Phase 1: Setup [IN PROGRESS]
                      ### Phase 2: Implementation [NOT STARTED]
                      ### Phase 3: Testing [NOT STARTED]

Build Phase 1 End:    ### Phase 1: Setup [COMPLETE]
                      ### Phase 2: Implementation [IN PROGRESS]
                      ### Phase 3: Testing [NOT STARTED]

Build Phase 2 End:    ### Phase 1: Setup [COMPLETE]
                      ### Phase 2: Implementation [COMPLETE]
                      ### Phase 3: Implementation [IN PROGRESS]

Build Complete:       ### Phase 1: Setup [COMPLETE]
                      ### Phase 2: Implementation [COMPLETE]
                      ### Phase 3: Testing [COMPLETE]
```

### Function Design

**add_in_progress_marker()**
- Input: plan_path, phase_num
- Behavior: Remove existing status markers (including NOT STARTED), add [IN PROGRESS] to phase heading
- Error handling: Return 1 if file not found, awk failure

**remove_status_marker()**
- Input: plan_path, phase_num
- Behavior: Remove any status marker from phase heading (COMPLETE, IN PROGRESS, BLOCKED, SKIPPED, NOT STARTED)
- Used by: add_in_progress_marker, add_complete_marker (to ensure clean state)

**Modified add_complete_marker()**
- Update regex to remove [NOT STARTED] and [IN PROGRESS] before adding [COMPLETE]

### Integration Points

1. **Plan-architect.md template** (lines 508-586): Update phase heading format to include [NOT STARTED]
2. **Plan-architect.md phase format** (after line 288): Add explicit instruction for status markers
3. **Build.md Block 1** (line ~196): After plan file validation, before Task invocation
   - Source checkbox-utils.sh
   - Call `add_in_progress_marker()` for starting phase
4. **Implementer-coordinator agent prompt**: Add instruction for phase status updates
5. **Build.md Phase Update Block** (lines 303-371): After implementation complete
   - Existing `add_complete_marker()` calls remain
   - Ensure all markers replaced with COMPLETE

## Implementation Phases

### Phase 1: Plan-Architect Template Updates
dependencies: []

**Objective**: Modify plan-architect agent to generate phases with [NOT STARTED] markers

**Complexity**: Low

Tasks:
- [x] Update standard plan template in plan-architect.md (file: /home/benjamin/.config/.claude/agents/plan-architect.md, lines 545-569)
  - Change `### Phase 1: Foundation` to `### Phase 1: Foundation [NOT STARTED]`
  - Change `### Phase 2: [Next Phase]` to `### Phase 2: [Next Phase] [NOT STARTED]`
  - Update all phase heading examples in template
- [x] Add Phase Heading Format section after line 288 in plan-architect.md
  - Document that phase headings MUST include `[NOT STARTED]` status marker
  - Format: `### Phase N: Name [NOT STARTED]`
  - Explain lifecycle: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
  - List all four status markers: [NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED]
- [x] Update example usage sections (lines 376-472) to show [NOT STARTED] markers
  - Update all Task prompt examples that show phase structures
- [x] Add instruction in STEP 2 (lines 63-112) about including status markers
  - Ensure plan-architect understands to add markers during generation

Testing:
```bash
# Verify template contains [NOT STARTED] markers
grep -q "\[NOT STARTED\]" /home/benjamin/.config/.claude/agents/plan-architect.md && echo "PASS: Template updated" || echo "FAIL: No markers in template"

# Verify Phase Heading Format section exists
grep -q "Phase Heading Format" /home/benjamin/.config/.claude/agents/plan-architect.md && echo "PASS: Section added" || echo "FAIL: Section missing"
```

**Expected Duration**: 1 hour

### Phase 2: Core Library Functions
dependencies: [1]

**Objective**: Create the new progress marker functions in checkbox-utils.sh

**Complexity**: Medium

Tasks:
- [x] Add `remove_status_marker()` function to checkbox-utils.sh (file: /home/benjamin/.config/.claude/lib/checkbox-utils.sh)
  - Accept plan_path and phase_num parameters
  - Use awk to remove any status marker including [NOT STARTED], [IN PROGRESS], [COMPLETE], [BLOCKED], [SKIPPED]
  - Keep heading text intact
  - Place before add_in_progress_marker for proper call order
- [x] Add `add_in_progress_marker()` function to checkbox-utils.sh (after line 361)
  - Accept plan_path and phase_num parameters
  - Call remove_status_marker first for clean state
  - Use awk to find phase heading and add [IN PROGRESS] marker
  - Handle file not found and awk errors
- [x] Update `add_complete_marker()` function to handle [NOT STARTED] removal (file: checkbox-utils.sh:335-361)
  - Update regex from `\[(COMPLETE|IN PROGRESS|BLOCKED|SKIPPED)\]` to `\[(COMPLETE|IN PROGRESS|BLOCKED|SKIPPED|NOT STARTED)\]`
  - Prevents duplicate markers
- [x] Export new functions at end of checkbox-utils.sh (line ~412)
  - Add `export -f add_in_progress_marker`
  - Add `export -f remove_status_marker`

Testing:
```bash
# Test remove_status_marker
source .claude/lib/checkbox-utils.sh
echo "### Phase 1: Setup [NOT STARTED]" > /tmp/test_plan.md
remove_status_marker "/tmp/test_plan.md" "1"
! grep -q "\[NOT STARTED\]" /tmp/test_plan.md && echo "PASS: remove_status_marker" || echo "FAIL"

# Test add_in_progress_marker
echo "### Phase 1: Setup [NOT STARTED]" > /tmp/test_plan.md
add_in_progress_marker "/tmp/test_plan.md" "1"
grep -q "\[IN PROGRESS\]" /tmp/test_plan.md && ! grep -q "\[NOT STARTED\]" /tmp/test_plan.md && echo "PASS" || echo "FAIL"

# Test add_complete_marker replaces IN PROGRESS
echo "### Phase 1: Setup [IN PROGRESS]" > /tmp/test_plan.md
add_complete_marker "/tmp/test_plan.md" "1"
grep -q "\[COMPLETE\]" /tmp/test_plan.md && ! grep -q "\[IN PROGRESS\]" /tmp/test_plan.md && echo "PASS" || echo "FAIL"

# Test add_complete_marker replaces NOT STARTED
echo "### Phase 1: Setup [NOT STARTED]" > /tmp/test_plan.md
add_complete_marker "/tmp/test_plan.md" "1"
grep -q "\[COMPLETE\]" /tmp/test_plan.md && ! grep -q "\[NOT STARTED\]" /tmp/test_plan.md && echo "PASS" || echo "FAIL"
```

**Expected Duration**: 1.5 hours

### Phase 3: Build Command Integration
dependencies: [2]

**Objective**: Integrate progress tracking into /build command workflow

**Complexity**: Medium

Tasks:
- [x] Add IN PROGRESS marker in Block 1 after plan validation (file: /home/benjamin/.config/.claude/commands/build.md, after line 196)
  - Source checkbox-utils.sh if not already sourced
  - Call `add_in_progress_marker "$PLAN_FILE" "$STARTING_PHASE"`
  - Handle errors gracefully (don't fail build if marker fails)
- [x] Update implementer-coordinator Task prompt to include progress tracking instructions (file: build.md, lines 203-239)
  - Add instruction: "Before starting each phase, call add_in_progress_marker"
  - Add instruction: "After completing each phase, mark_phase_complete and add_complete_marker"
  - Reference checkbox-utils.sh sourcing
- [x] Verify Phase Update Block properly replaces markers (file: build.md, lines 303-371)
  - Confirm add_complete_marker now handles removal of IN PROGRESS and NOT STARTED
  - Add comment explaining marker replacement behavior
- [x] Add persist for completed phase tracking (file: build.md, after line 361)
  - Track which phases have been marked complete
  - Support recovery after interruption

Testing:
```bash
# Create test plan with NOT STARTED markers
cat > /tmp/test_build_plan.md <<'EOF'
# Test Plan

## Metadata
- **Date**: 2025-11-18

## Implementation Phases

### Phase 1: Setup [NOT STARTED]

Tasks:
- [ ] Task 1

### Phase 2: Implementation [NOT STARTED]

Tasks:
- [ ] Task 2
EOF

# Run build in dry-run to verify marker calls
/build /tmp/test_build_plan.md --dry-run
# Verify plan shows Phase 1 with [IN PROGRESS] marker
```

**Expected Duration**: 2 hours

### Phase 4: Parent Plan Hierarchy Support
dependencies: [2]

**Objective**: Ensure progress markers propagate to parent plans in Level 1/2 structures

**Complexity**: Low

Tasks:
- [x] Create `propagate_progress_marker()` function in checkbox-utils.sh
  - Accept plan_path, phase_num, and status parameter
  - Detect structure level using `detect_structure_level()`
  - Update both expanded phase file and main plan
  - Handle Level 0 (single file) - direct update only
  - Handle Level 1 (phase expansion) - update phase file + main plan
  - Handle Level 2 (stage expansion) - update stage file + phase file + main plan
- [x] Update `add_in_progress_marker()` to call `propagate_progress_marker()` for Level 1/2
- [x] Update `add_complete_marker()` to call `propagate_progress_marker()` for Level 1/2
- [x] Export `propagate_progress_marker()` function

Testing:
```bash
# Test with Level 1 expanded plan structure
mkdir -p /tmp/test_topic/plans/001_test
echo "### Phase 1: Setup [NOT STARTED]" > /tmp/test_topic/plans/001_test.md
echo "### Phase 1: Setup [NOT STARTED]" > /tmp/test_topic/plans/001_test/phase_1_setup.md

source .claude/lib/checkbox-utils.sh
add_in_progress_marker "/tmp/test_topic/plans/001_test.md" "1"

# Verify both files updated
grep -q "\[IN PROGRESS\]" /tmp/test_topic/plans/001_test.md && \
grep -q "\[IN PROGRESS\]" /tmp/test_topic/plans/001_test/phase_1_setup.md && \
echo "PASS" || echo "FAIL"
```

**Expected Duration**: 1.5 hours

### Phase 5: Legacy Plan Compatibility
dependencies: [2, 3]

**Objective**: Support legacy plans without status markers

**Complexity**: Low

Tasks:
- [x] Add plan validation in /build command Block 1 (file: build.md)
  - Check for status markers in phase headings
  - If plan lacks markers, add `[NOT STARTED]` markers automatically
- [x] Create `add_not_started_markers()` function in checkbox-utils.sh
  - Scan all phase headings
  - Add [NOT STARTED] to any phase without a status marker
  - Preserve existing markers (don't overwrite [COMPLETE] etc.)
- [x] Add logging for marker additions
  - Log when legacy plan is detected and markers added
  - Inform user about marker lifecycle support
- [x] Export `add_not_started_markers()` function

Testing:
```bash
# Test with legacy plan (no markers)
cat > /tmp/legacy_plan.md <<'EOF'
### Phase 1: Setup

Tasks:
- [ ] Task 1

### Phase 2: Implementation

Tasks:
- [ ] Task 2
EOF

source .claude/lib/checkbox-utils.sh
add_not_started_markers "/tmp/legacy_plan.md"

# Verify markers added
grep -q "\[NOT STARTED\]" /tmp/legacy_plan.md && echo "PASS" || echo "FAIL"
grep -c "\[NOT STARTED\]" /tmp/legacy_plan.md | grep -q "2" && echo "PASS: Both phases marked" || echo "FAIL"
```

**Expected Duration**: 1 hour

### Phase 6: Documentation Standards
dependencies: [1, 2, 3]

**Objective**: Create comprehensive documentation for plan progress tracking patterns

**Complexity**: Low

Tasks:
- [x] Create plan-progress-tracking.md in .claude/docs/reference/ (new file)
  - Document complete marker lifecycle: [NOT STARTED] -> [IN PROGRESS] -> [COMPLETE]
  - Create status marker table with Applied By and When columns
  - Provide usage patterns with code examples
  - Show visual example of plan progress through all states
  - Document implementation functions and their signatures
  - Include integration notes for /plan and /build commands
  - Document legacy plan compatibility
- [x] Update build-command-guide.md with Progress Tracking section (file: /home/benjamin/.config/.claude/docs/guides/build-command-guide.md, after line 135)
  - Add "Progress Tracking During Execution" subsection
  - Show workflow diagram for status transitions from [NOT STARTED]
  - Document when markers are applied
  - Reference plan-progress-tracking.md for complete details
- [x] Update workflow-phases-planning.md with [NOT STARTED] markers (file: /home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md, lines 141-175)
  - Update expected plan format to show `[NOT STARTED]` markers
  - Add note about marker lifecycle
- [x] Update library-api.md or library-api-utilities.md with new function documentation
  - Document add_in_progress_marker() signature and behavior
  - Document remove_status_marker() signature and behavior
  - Document propagate_progress_marker() signature and behavior
  - Document add_not_started_markers() signature and behavior
- [x] Update checkbox-utils.sh header comment with new functions list

Testing:
```bash
# Verify documentation files exist and have required content
test -f .claude/docs/reference/plan-progress-tracking.md && echo "plan-progress-tracking.md exists"
grep -q "NOT STARTED" .claude/docs/reference/plan-progress-tracking.md && echo "Contains NOT STARTED"
grep -q "IN PROGRESS" .claude/docs/reference/plan-progress-tracking.md && echo "Contains IN PROGRESS"
grep -q "add_in_progress_marker" .claude/docs/reference/plan-progress-tracking.md && echo "Documents function"
grep -q "Progress Tracking" .claude/docs/guides/build-command-guide.md && echo "build-command-guide updated"
grep -q "NOT STARTED" .claude/docs/reference/workflow-phases-planning.md && echo "workflow-phases-planning updated"
```

**Expected Duration**: 2 hours

### Phase 7: Testing and Validation
dependencies: [1, 2, 3, 4, 5, 6]

**Objective**: Comprehensive testing of progress tracking implementation

**Complexity**: Low

Tasks:
- [x] Create test file test_plan_progress_markers.sh in .claude/tests/ (new file)
  - Test add_in_progress_marker() for various phase numbers
  - Test remove_status_marker() for all marker types including [NOT STARTED]
  - Test add_complete_marker() replacing IN PROGRESS and NOT STARTED
  - Test propagate_progress_marker() for Level 1 plans
  - Test add_not_started_markers() for legacy plans
  - Test edge cases: phase not found, invalid phase number, file not found
- [x] Create integration test for /plan command marker generation
  - Verify new plans have [NOT STARTED] on all phases
  - Test that template generates correct format
- [x] Create integration test for /build command progress tracking
  - Create test plan with [NOT STARTED] markers
  - Run /build and verify markers transition correctly
  - Verify final state shows all phases [COMPLETE]
- [x] Verify existing checkbox-utils tests still pass
  - Run .claude/tests/test_build_state_transitions.sh
  - Ensure no regressions in mark_phase_complete, verify_phase_complete
- [x] Manual validation with real plan file
  - Run /plan to create a new test plan
  - Verify phases have [NOT STARTED] markers
  - Run /build on the plan
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

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- Each new function in checkbox-utils.sh tested in isolation
- Test files created in /tmp or test fixtures directory
- Verify return codes and file modifications
- Test all marker types including [NOT STARTED]

### Integration Tests
- End-to-end /plan command plan generation
- End-to-end /build command execution
- Verify state transitions and marker application
- Test with Level 0, 1, and 2 plan structures
- Test legacy plan compatibility

### Regression Tests
- Existing mark_phase_complete tests must pass
- Existing verify_phase_complete tests must pass
- No changes to existing test behavior

### Manual Validation
- Real plan file creation and execution
- Visual verification of markers in plan files
- Confirm documentation accuracy
- Verify marker lifecycle from creation to completion

## Documentation Requirements

### New Documentation
- `/home/benjamin/.config/.claude/docs/reference/plan-progress-tracking.md` - Complete reference for progress tracking patterns and marker lifecycle

### Updated Documentation
- `/home/benjamin/.config/.claude/docs/guides/build-command-guide.md` - Add Progress Tracking section
- `/home/benjamin/.config/.claude/docs/reference/workflow-phases-planning.md` - Add [NOT STARTED] markers to examples
- `/home/benjamin/.config/.claude/agents/plan-architect.md` - Update template and add Phase Heading Format section
- `/home/benjamin/.config/.claude/lib/checkbox-utils.sh` - Update header comment with new functions

### Cross-References
- build-command-guide.md should reference plan-progress-tracking.md
- plan-progress-tracking.md should reference checkbox-utils.sh library
- plan-architect.md should reference documentation standards
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
- Plan-architect agent must use template for plan generation

## Risks and Mitigations

### Risk 1: Awk Pattern Matching Failures
- **Risk**: Phase headings with unusual formatting may not match
- **Mitigation**: Use flexible regex patterns, test with various heading formats

### Risk 2: Marker Duplication
- **Risk**: [NOT STARTED] [IN PROGRESS] [COMPLETE] appearing on same heading
- **Mitigation**: Always remove existing markers before adding new ones with remove_status_marker()

### Risk 3: Performance Impact
- **Risk**: Additional file I/O for marker updates
- **Mitigation**: Marker operations are lightweight, single pass through file

### Risk 4: Level 2 Plan Complexity
- **Risk**: Stage-level propagation may be complex
- **Mitigation**: Start with Level 0/1 support, extend to Level 2 if needed

### Risk 5: Legacy Plan Compatibility
- **Risk**: Existing plans without markers may cause issues
- **Mitigation**: Automatic [NOT STARTED] marker addition for legacy plans

### Risk 6: Plan-Architect Template Consistency
- **Risk**: Plan-architect may not consistently apply [NOT STARTED] markers
- **Mitigation**: Explicit instruction in Phase Heading Format section, update all template examples
