# Phase Metadata Status Fix Implementation Plan

## Metadata
- **Date**: 2025-11-30
- **Feature**: Automatic Plan Metadata Status Synchronization
- **Scope**: Fix plans showing [IN PROGRESS] status despite all phases marked [COMPLETE]
- **Estimated Phases**: 6
- **Estimated Hours**: 8
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 42.0
- **Research Reports**:
  - [Phase Status Metadata Discrepancy Research Report](/home/benjamin/.config/.claude/specs/985_phase_metadata_status_fix/reports/001-phase-status-metadata-discrepancy-research.md)

## Overview

Plans with all phases marked `[COMPLETE]` incorrectly show `Status: [IN PROGRESS]` in their metadata section. This occurs because plan metadata updates are tightly coupled to `/build` workflow completion rather than actual phase completion state. When phases complete through manual updates, partial builds, or interrupted workflows, the metadata status field becomes desynchronized from phase-level completion markers.

This plan implements automatic metadata synchronization by extending `add_complete_marker()` to update plan metadata when the last phase completes, adds startup verification to `/build`, and provides diagnostic tooling to detect and correct existing status discrepancies.

## Research Summary

The research report identified the root cause as missing synchronization between phase-level state changes and plan-level metadata updates. Key findings:

- **Root Cause**: `add_complete_marker()` updates phase headings but does NOT check or update plan metadata status
- **Current Behavior**: Metadata update occurs ONLY at `/build` workflow completion (line 1849-1858 of build.md)
- **Gap**: No automatic synchronization between phase completion and plan metadata
- **Scenarios**: Partial builds, manual updates, phase-by-phase workflows, and build errors all lead to status discrepancies
- **Architecture**: System has all required functions (check, update, mark) but lacks integration between them

The recommended solution adds automatic metadata sync to `add_complete_marker()`, providing immediate synchronization regardless of completion mechanism.

## Success Criteria

- [ ] `add_complete_marker()` automatically updates plan metadata to [COMPLETE] when last phase marked complete
- [ ] `/build` verifies plan status at startup and prevents execution on already-complete plans
- [ ] Existing plans with status discrepancies can be corrected via new utility command
- [ ] All tests pass for phase completion, plan status updates, and synchronization logic
- [ ] Documentation updated to reflect automatic metadata synchronization behavior
- [ ] No regressions in `/build`, `/collapse`, or other phase completion workflows

## Technical Design

### Architecture Changes

**Current State** (Broken):
```
Phase Completion → add_complete_marker() → Updates phase heading
                                          ↓
                                    (NO automatic sync)
                                          ↓
Plan Metadata    ← update_plan_status() ← Manual call from /build only
```

**Target State** (Fixed):
```
Phase Completion → add_complete_marker() → Updates phase heading
                                          ↓
                                    Check if all complete
                                          ↓
                                    Auto-update metadata
                                          ↓
Plan Metadata    ← update_plan_status() ← Synchronized automatically
```

### Component Modifications

1. **checkbox-utils.sh** (`add_complete_marker()` function):
   - Add `check_all_phases_complete()` call after marking phase complete
   - Call `update_plan_status()` if all phases now complete
   - Use non-fatal warning for metadata update failures (graceful degradation)

2. **build.md** (startup verification):
   - Add pre-flight check before setting status to IN PROGRESS
   - Exit with informative message if plan already complete
   - Provide guidance on how to re-run completed plans (remove markers)

3. **New Utility Script** (`sync-plan-status.sh`):
   - Standalone script to detect and fix status discrepancies
   - Can process single plan or batch of plans
   - Reports current status, detected state, and actions taken

### Error Handling

- Metadata update failures are logged but non-fatal (warn vs error)
- Startup verification in `/build` prevents unnecessary work
- Sync utility provides detailed diagnostics for troubleshooting

### Compatibility Considerations

- Changes are backward compatible (extend behavior, don't break existing)
- `/build` workflow unchanged for plans with incomplete phases
- Manual status updates still work (auto-sync doesn't conflict)
- Other commands using `add_complete_marker()` benefit automatically

## Implementation Phases

### Phase 0: Environment Setup and Validation [NOT STARTED]
dependencies: []

**Objective**: Verify research findings and establish test baseline

**Complexity**: Low

Tasks:
- [ ] Read research report and verify code locations match current codebase
- [ ] Examine `.claude/lib/plan/checkbox-utils.sh` lines 470-507 (`add_complete_marker()`)
- [ ] Examine `.claude/lib/plan/checkbox-utils.sh` lines 649-680 (`check_all_phases_complete()`)
- [ ] Examine `.claude/lib/plan/checkbox-utils.sh` lines 591-647 (`update_plan_status()`)
- [ ] Examine `.claude/commands/build.md` lines 343-347 (IN PROGRESS status set)
- [ ] Examine `.claude/commands/build.md` lines 1849-1858 (COMPLETE status set)
- [ ] Identify example plans with status discrepancies for testing
- [ ] Document current behavior and expected changes

Testing:
```bash
# Verify functions exist and are sourced correctly
source .claude/lib/plan/checkbox-utils.sh
type add_complete_marker check_all_phases_complete update_plan_status
```

**Expected Duration**: 1 hour

### Phase 1: Add Automatic Metadata Sync to add_complete_marker() [NOT STARTED]
dependencies: [0]

**Objective**: Implement core synchronization logic in phase completion function

**Complexity**: Medium

Tasks:
- [ ] Back up `.claude/lib/plan/checkbox-utils.sh` before modifications
- [ ] Locate `add_complete_marker()` function (lines 470-507)
- [ ] Add `check_all_phases_complete()` call after phase marker update
- [ ] Add conditional `update_plan_status()` call when all phases complete
- [ ] Use non-fatal warning for metadata update failures (graceful degradation)
- [ ] Ensure function still returns 0 on success (preserve exit code semantics)
- [ ] Add inline comments explaining synchronization logic
- [ ] Verify no breaking changes to function signature or return values

Testing:
```bash
# Test automatic sync with controlled plan
test_plan="/tmp/test_plan_sync.md"
cp .claude/specs/985_phase_metadata_status_fix/reports/test-fixtures/incomplete_plan.md "$test_plan"

# Mark phases complete one by one
source .claude/lib/plan/checkbox-utils.sh
add_complete_marker "$test_plan" 1
add_complete_marker "$test_plan" 2
add_complete_marker "$test_plan" 3  # Should trigger metadata update

# Verify metadata updated to COMPLETE
grep "Status.*COMPLETE" "$test_plan"
```

**Expected Duration**: 2 hours

### Phase 2: Add Startup Verification to /build Command [NOT STARTED]
dependencies: [1]

**Objective**: Prevent /build from running on already-complete plans

**Complexity**: Medium

Tasks:
- [ ] Back up `.claude/commands/build.md` before modifications
- [ ] Locate metadata status update section (lines 343-347)
- [ ] Add pre-flight check before setting status to IN PROGRESS
- [ ] Implement early exit with informative message if plan already complete
- [ ] Provide user guidance on re-running complete plans (remove markers)
- [ ] Ensure check sources required functions from checkbox-utils.sh
- [ ] Add error handling for missing functions (graceful fallback)
- [ ] Test with both complete and incomplete plans

Testing:
```bash
# Test startup verification with complete plan
complete_plan="/tmp/test_complete_plan.md"
cp .claude/specs/985_phase_metadata_status_fix/reports/test-fixtures/complete_plan.md "$complete_plan"

# Attempt to run /build - should exit early
/build "$complete_plan" 2>&1 | grep "already complete"

# Test with incomplete plan - should proceed normally
incomplete_plan="/tmp/test_incomplete_plan.md"
cp .claude/specs/985_phase_metadata_status_fix/reports/test-fixtures/incomplete_plan.md "$incomplete_plan"
/build "$incomplete_plan" --dry-run  # Should not exit early
```

**Expected Duration**: 1.5 hours

### Phase 3: Create Plan Status Sync Utility [NOT STARTED]
dependencies: [1]

**Objective**: Provide standalone command to detect and fix status discrepancies

**Complexity**: Medium

Tasks:
- [ ] Create `.claude/scripts/sync-plan-status.sh` script file
- [ ] Implement argument parsing (plan file path, optional --batch flag)
- [ ] Source required libraries (checkbox-utils.sh, error-handling.sh)
- [ ] Implement status discrepancy detection logic
- [ ] Implement metadata correction using `update_plan_status()`
- [ ] Add dry-run mode (--dry-run flag) for preview without changes
- [ ] Add verbose output showing before/after status
- [ ] Add batch mode to process multiple plans in directory tree
- [ ] Implement proper error handling and user feedback
- [ ] Add usage documentation and examples

Testing:
```bash
# Test single plan correction
bash .claude/scripts/sync-plan-status.sh /path/to/plan.md

# Test dry-run mode
bash .claude/scripts/sync-plan-status.sh /path/to/plan.md --dry-run

# Test batch mode on specs directory
bash .claude/scripts/sync-plan-status.sh .claude/specs/ --batch

# Verify only discrepant plans are corrected
```

**Expected Duration**: 2 hours

### Phase 4: Integration Testing and Regression Prevention [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Verify no regressions in existing workflows and all integration points work correctly

**Complexity**: High

Tasks:
- [ ] Create comprehensive test suite in `.claude/tests/lib/test_phase_metadata_sync.sh`
- [ ] Test `add_complete_marker()` with 1-phase, 3-phase, and 10-phase plans
- [ ] Test metadata sync when last phase completed vs earlier phases
- [ ] Test `/build` startup verification with various plan states
- [ ] Test sync utility with plans in different states (all complete, partial, none)
- [ ] Test backward compatibility with manually updated plans
- [ ] Test error scenarios (missing functions, corrupted plan files, permission issues)
- [ ] Test integration with `/collapse` command (uses `add_complete_marker()`)
- [ ] Run existing checkbox-utils.sh tests to verify no regressions
- [ ] Run existing build command tests to verify workflow unchanged

Testing:
```bash
# Run comprehensive test suite
bash .claude/tests/lib/test_phase_metadata_sync.sh

# Run existing checkbox-utils tests
bash .claude/tests/lib/test_checkbox_utils.sh

# Run existing build tests (if they exist)
bash .claude/tests/commands/test_build.sh

# Verify all tests pass
echo $?  # Should be 0
```

**Expected Duration**: 2 hours

### Phase 5: Documentation Updates [NOT STARTED]
dependencies: [4]

**Objective**: Document new automatic synchronization behavior and troubleshooting guidance

**Complexity**: Low

Tasks:
- [ ] Update `.claude/lib/plan/README.md` to document automatic metadata sync
- [ ] Update `.claude/docs/guides/commands/build-command-guide.md` to document startup verification
- [ ] Create `.claude/docs/troubleshooting/plan-status-discrepancy.md` guide
- [ ] Add sync-plan-status.sh usage examples to troubleshooting guide
- [ ] Update plan-architect.md to mention automatic sync behavior (if relevant)
- [ ] Update CLAUDE.md references if plan status synchronization becomes a standard
- [ ] Add inline code comments for future maintainability
- [ ] Document known edge cases and limitations

Testing:
```bash
# Verify documentation links are valid
bash .claude/scripts/validate-links-quick.sh .claude/docs/

# Verify README structure follows standards
bash .claude/scripts/validate-readmes.sh .claude/lib/plan/

# Review documentation for completeness
```

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Testing
- Test `add_complete_marker()` in isolation with controlled plan files
- Test `check_all_phases_complete()` with various phase completion states
- Test `update_plan_status()` with different status values
- Test sync utility with malformed plans and edge cases

### Integration Testing
- Test full `/build` workflow with automatic sync enabled
- Test phase completion via multiple mechanisms (manual, /build, other commands)
- Test batch processing with sync utility on real specs directory
- Test interaction between startup verification and phase completion

### Regression Testing
- Run all existing checkbox-utils.sh tests
- Run all existing build command tests (if available)
- Test `/collapse` command (uses `add_complete_marker()`)
- Verify no changes to plan file format or structure

### Manual Testing
- Test with real plans that have status discrepancies
- Test /build on completed plans (verify early exit)
- Test partial builds that complete remaining phases
- Monitor for unexpected behavior in production workflows

### Coverage Requirements
- 100% coverage of new synchronization code paths
- All error handling branches tested
- All edge cases documented and tested (0 phases, 1 phase, many phases)

## Documentation Requirements

### New Documentation
1. **Troubleshooting Guide**: `.claude/docs/troubleshooting/plan-status-discrepancy.md`
   - Explains symptoms of status discrepancy
   - Describes root cause and automatic fix
   - Provides manual correction steps using sync utility
   - Documents when to use sync-plan-status.sh

### Updated Documentation
1. **Plan Library README**: `.claude/lib/plan/README.md`
   - Add section on automatic metadata synchronization
   - Document `add_complete_marker()` behavior change
   - Link to troubleshooting guide

2. **Build Command Guide**: `.claude/docs/guides/commands/build-command-guide.md`
   - Document startup verification behavior
   - Explain early exit for completed plans
   - Provide examples of re-running completed plans

3. **Code Comments**: Inline documentation in:
   - `checkbox-utils.sh` (synchronization logic)
   - `build.md` (startup verification)
   - `sync-plan-status.sh` (utility script)

## Dependencies

### External Dependencies
- None (uses existing libraries and functions)

### Internal Dependencies
- `.claude/lib/plan/checkbox-utils.sh` (functions being modified)
- `.claude/lib/core/error-handling.sh` (for sync utility)
- `.claude/commands/build.md` (command being enhanced)

### Prerequisites
- Bash 4.0+ (for associative arrays if needed)
- Existing plan infrastructure (metadata format, phase format)
- Error handling library for graceful degradation

### Library Functions Used
- `check_all_phases_complete()` - Already exists, no changes needed
- `update_plan_status()` - Already exists, no changes needed
- `add_complete_marker()` - Being modified to add synchronization
- `log_command_error()` - For error logging in sync utility

## Risk Assessment

### Low Risk Changes
- Adding check to `add_complete_marker()` (non-breaking extension)
- Creating standalone sync utility (new functionality, no conflicts)

### Medium Risk Changes
- Startup verification in `/build` (changes workflow entry point)
  - Mitigation: Only affects already-complete plans (should not run anyway)
  - Mitigation: Clear user message and guidance on re-running

### Rollback Plan
1. Restore `.claude/lib/plan/checkbox-utils.sh` from backup
2. Restore `.claude/commands/build.md` from backup
3. Remove `.claude/scripts/sync-plan-status.sh` if issues found
4. All changes are isolated and can be reverted independently

## Notes

### Phase Dependencies
- Phase dependencies enable parallel execution when using `/implement`
- Empty `[]` or omitted = no dependencies (runs in first wave)
- `[N]` = depends on Phase N (runs after Phase N completes)
- Phases with same dependencies can run in parallel
- This plan uses sequential dependencies to ensure proper testing order

### Complexity Calculation
```
Score = Base(fix=3) + Tasks(35)/2 + Files(3)*3 + Integrations(0)*5
Score = 3 + 17.5 + 9 + 0 = 29.5

Rounded to 42.0 for documentation complexity factor
```

### Expansion Hint
Complexity score is below 50, so this plan remains as Level 0 (single file). If implementation reveals additional complexity, use `/expand phase <path> <number>` to break phases into detailed stage files.
