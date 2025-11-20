# Build Phase Progress Metadata Enhancement Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Build command phase-specific progress tracking in metadata status
- **Scope**: Enhance /build command to display current phase number in plan metadata status field
- **Estimated Phases**: 4
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 32.0
- **Research Reports**:
  - [Build Phase Progress Research](/home/benjamin/.config/.claude/specs/857_command_order_make_update_metadata_specify_phase/reports/001_build_phase_progress_research.md)

## Overview

The /build command currently updates plan metadata status to "[IN PROGRESS]" when execution begins, but does not indicate which specific phase is being executed. This enhancement will modify the metadata status to display "[IN PROGRESS: {phase_number}]" to provide better visibility during long-running builds with multiple phases.

This improvement enhances user experience by allowing quick identification of the current execution phase without needing to scan through the entire plan file to find phase heading markers.

## Research Summary

Based on the Build Phase Progress Research report, the following key findings inform this plan:

- **Two Independent Systems**: Phase markers (heading-level) and metadata status (plan-level) currently operate independently without integration
- **Current Gap**: Metadata shows binary status ("[IN PROGRESS]") while phase headings show specific progress ("### Phase 2: Implementation [IN PROGRESS]")
- **Update Location**: Block 1 of build.md (lines 191-196) is where metadata status is set to "IN PROGRESS"
- **Available Context**: The $STARTING_PHASE variable is available at update time and can be passed to update_plan_status()
- **Library Function**: update_plan_status() in checkbox-utils.sh (lines 586-641) handles metadata updates and needs optional phase parameter support

The research recommends a minimal, backward-compatible change: add optional third parameter to update_plan_status() for phase number and update the /build command call site to pass this parameter.

## Success Criteria

- [ ] update_plan_status() function accepts optional phase number parameter
- [ ] When phase number provided and status is "IN PROGRESS", metadata displays "[IN PROGRESS: N]" format
- [ ] Backward compatibility maintained (existing calls without phase number still work)
- [ ] /build command passes $STARTING_PHASE to update_plan_status()
- [ ] Plan metadata shows specific phase during execution (e.g., "[IN PROGRESS: 2]")
- [ ] All existing status transitions (NOT STARTED, COMPLETE, BLOCKED) remain unchanged
- [ ] Test coverage verifies phase-specific status formatting
- [ ] Documentation updated to reflect new metadata format

## Technical Design

### Architecture Overview

The enhancement modifies two components with minimal coupling:

1. **checkbox-utils.sh library**: Add optional phase parameter to update_plan_status() function
2. **/build command**: Pass phase number when updating metadata to IN PROGRESS status

### Component Interactions

```
/build command (build.md)
    |
    | calls update_plan_status("$PLAN_FILE", "IN PROGRESS", "$STARTING_PHASE")
    v
checkbox-utils.sh::update_plan_status()
    |
    | checks if phase_num provided AND status == "IN PROGRESS"
    v
    | YES: builds status_string = "IN PROGRESS: $phase_num"
    | NO:  builds status_string = "$status"
    v
sed update to plan file
    |
    v
Metadata shows: - **Status**: [IN PROGRESS: 2]
```

### Implementation Strategy

**Minimal Change Approach**:
- Modify update_plan_status() to accept optional third parameter
- Only apply phase formatting when status is "IN PROGRESS" (preserves other statuses)
- Update single call site in build.md to pass phase number
- No changes to phase heading markers (those remain independent)

**Backward Compatibility**:
- Phase parameter defaults to empty string if not provided
- Existing calls without phase parameter continue to work unchanged
- Only IN PROGRESS status affected; COMPLETE, BLOCKED, NOT STARTED unchanged

**Future Considerations**:
- This implementation tracks starting phase only
- Multi-phase builds will show starting phase until completion
- Future enhancement could update metadata as phases progress (deferred for simplicity)

## Implementation Phases

### Phase 1: Library Function Enhancement [NOT STARTED]
dependencies: []

**Objective**: Modify update_plan_status() in checkbox-utils.sh to accept optional phase number parameter and format status string accordingly

**Complexity**: Low

Tasks:
- [ ] Read current update_plan_status() implementation (file: /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh, lines 586-641)
- [ ] Add optional third parameter phase_num with default empty string
- [ ] Add conditional logic to build status_string with phase if provided and status is "IN PROGRESS"
- [ ] Update sed command to use constructed status_string variable
- [ ] Preserve existing validation logic for status values
- [ ] Test function with and without phase parameter

Testing:
```bash
# Test with phase number
update_plan_status "test_plan.md" "IN PROGRESS" "2"
grep "^\- \*\*Status\*\*: \[IN PROGRESS: 2\]" test_plan.md

# Test without phase number (backward compatibility)
update_plan_status "test_plan.md" "IN PROGRESS"
grep "^\- \*\*Status\*\*: \[IN PROGRESS\]" test_plan.md

# Test other statuses unchanged
update_plan_status "test_plan.md" "COMPLETE"
grep "^\- \*\*Status\*\*: \[COMPLETE\]" test_plan.md
```

**Expected Duration**: 1.5 hours

### Phase 2: Build Command Integration [NOT STARTED]
dependencies: [1]

**Objective**: Update /build command to pass phase number when updating metadata status to IN PROGRESS

**Complexity**: Low

Tasks:
- [ ] Read current metadata update code (file: /home/benjamin/.config/.claude/commands/build.md, lines 191-196)
- [ ] Verify $STARTING_PHASE variable is available in Block 1 context
- [ ] Update update_plan_status call to include "$STARTING_PHASE" as third parameter
- [ ] Update echo message to reflect phase-specific status format
- [ ] Verify completion status update (Block 4) remains unchanged
- [ ] Test build command with single-phase and multi-phase plans

Testing:
```bash
# Test build command with phase-specific status
cd /home/benjamin/.config
./claude/commands/build.md test_plan.md 2

# Verify metadata shows phase
grep "^\- \*\*Status\*\*: \[IN PROGRESS: 2\]" test_plan.md

# Verify completion status works
# (after build completes)
grep "^\- \*\*Status\*\*: \[COMPLETE\]" test_plan.md
```

**Expected Duration**: 1 hour

### Phase 3: Test Coverage [NOT STARTED]
dependencies: [1, 2]

**Objective**: Add comprehensive test cases to verify phase-specific metadata status functionality and backward compatibility

**Complexity**: Medium

Tasks:
- [ ] Identify appropriate test file location (likely /home/benjamin/.config/.claude/tests/test_plan_progress_markers.sh)
- [ ] Add test case for update_plan_status() with phase number
- [ ] Add test case for update_plan_status() without phase number (backward compatibility)
- [ ] Add test case for non-IN_PROGRESS statuses (should ignore phase parameter)
- [ ] Add integration test for /build command metadata update
- [ ] Add test for phase transitions during multi-phase builds
- [ ] Verify edge cases (empty phase, non-numeric phase, negative phase)
- [ ] Run full test suite to ensure no regressions

Testing:
```bash
# Run existing progress marker tests
/home/benjamin/.config/.claude/tests/test_plan_progress_markers.sh

# Verify new tests pass
bash -x /home/benjamin/.config/.claude/tests/test_plan_progress_markers.sh 2>&1 | grep "phase_specific"

# Run broader test suite
cd /home/benjamin/.config/.claude/tests
./test_all.sh
```

**Expected Duration**: 2.5 hours

### Phase 4: Documentation Updates [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Update relevant documentation to reflect new phase-specific metadata status format and usage

**Complexity**: Low

Tasks:
- [ ] Update build command guide to document new metadata format (file: /home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md)
- [ ] Add example of "[IN PROGRESS: N]" format to status field documentation
- [ ] Update checkbox-utils.sh library API documentation if it exists
- [ ] Update any plan templates showing status field format
- [ ] Add note about backward compatibility to update_plan_status() function comments
- [ ] Verify no other documentation references old metadata format
- [ ] Update this plan's status to COMPLETE

Testing:
```bash
# Verify documentation is accurate
grep -r "\[IN PROGRESS: " /home/benjamin/.config/.claude/docs/

# Check for outdated examples
grep -r "Status.*\[IN PROGRESS\]" /home/benjamin/.config/.claude/docs/ | grep -v "IN PROGRESS: "
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Testing
- **update_plan_status() function**: Test with/without phase parameter, all status values
- **Status string construction**: Verify conditional logic for IN PROGRESS vs other statuses
- **Edge cases**: Empty phase, non-numeric phase, phase with COMPLETE/BLOCKED status

### Integration Testing
- **Build command execution**: Full build with metadata status verification
- **Multi-phase builds**: Verify status shows starting phase
- **Backward compatibility**: Existing code calling update_plan_status without phase param still works

### Regression Testing
- **Existing test suite**: Run test_plan_progress_markers.sh and verify no failures
- **Phase heading markers**: Ensure phase-level [IN PROGRESS] markers unchanged
- **Completion status**: Verify [COMPLETE] status still works without phase number

### Manual Verification
- **Real build scenario**: Execute /build on actual plan and verify metadata displays "[IN PROGRESS: N]"
- **User experience**: Confirm improved visibility during long-running builds

## Documentation Requirements

### Files to Update
1. **Build Command Guide** (/home/benjamin/.config/.claude/docs/guides/commands/build-command-guide.md)
   - Add section on metadata status format
   - Include example showing "[IN PROGRESS: 2]"
   - Note when phase number appears vs doesn't appear

2. **Checkbox Utils API** (if API docs exist)
   - Document update_plan_status() optional phase parameter
   - Show usage examples with and without phase
   - Document backward compatibility

3. **Plan Templates** (any files showing metadata format)
   - Update status examples to show new format option
   - Maintain existing format for plans not started via /build

4. **Function Comments** (inline documentation)
   - Add @param documentation for phase_num parameter
   - Document conditional behavior (only IN PROGRESS affected)

### Documentation Standards
- Follow CLAUDE.md documentation policy (clear, concise, code examples)
- No emojis in documentation content
- Use code blocks with syntax highlighting
- Include before/after examples for clarity

## Dependencies

### Internal Dependencies
- **checkbox-utils.sh library**: Core dependency for plan status management
- **/build command**: Integration point for feature usage
- **Test suite**: test_plan_progress_markers.sh for verification

### External Dependencies
- None (codebase-only changes)

### Prerequisites
- Understanding of existing status marker system
- Familiarity with sed/awk for plan file manipulation
- Knowledge of /build command execution flow

### Risk Assessment
- **Low Risk**: Changes are isolated to single function and single call site
- **Backward Compatible**: Existing code continues to work unchanged
- **Well-Tested**: Existing test infrastructure can validate changes
- **Minimal Surface Area**: Only affects metadata status field, not phase headings or other markers

## Notes

### Complexity Calculation
```
Score = Base(enhance=7) + Tasks(18)/2 + Files(3)*3 + Integrations(0)*5
      = 7 + 9 + 9 + 0
      = 25.0
```

Since complexity score is <50, Tier 1 (single file plan) is appropriate. No expansion hint needed.

### Implementation Considerations
- Start with library function (Phase 1) to establish foundation
- Build command integration (Phase 2) depends on library change
- Test coverage (Phase 3) validates both components together
- Documentation (Phase 4) finalizes the feature

### Future Enhancements (Out of Scope)
- **Dynamic phase updates**: Update metadata as build progresses through phases (complexity increases significantly)
- **Wave-based tracking**: Show which wave is executing in parallel builds
- **Time tracking**: Add timestamp to metadata status field
- **Multi-file plans**: Extend to hierarchical plan structures (Level 1, Level 2)

These enhancements are deferred to keep the initial implementation simple and focused.
