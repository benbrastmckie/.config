# Build Command Metadata Status Update Plan

## Metadata
- **Date**: 2025-11-19
- **Feature**: Update plan metadata status to [COMPLETE] when all phases finish
- **Scope**: Add status update functions and integrate with /build command
- **Estimated Phases**: 3
- **Estimated Hours**: 2.0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Complexity Score**: 12 (Tier 1 - Single Library + Command)
- **Structure Level**: 0
- **Research Reports**:
  - [Build Metadata Status Analysis](/home/benjamin/.config/.claude/specs/820_build_command_metadata_status_update/reports/001_build_metadata_status_analysis.md)
  - [Metadata Update Patterns](/home/benjamin/.config/.claude/specs/820_build_command_metadata_status_update/reports/002_metadata_update_patterns.md)

## Overview

This plan addresses the issue where `/build` successfully marks individual phases with `[COMPLETE]` but fails to update the plan's metadata status field from `[NOT STARTED]` to `[COMPLETE]`. The solution adds two new functions to `checkbox-utils.sh` and integrates them into the `/build` command flow.

## Research Summary

**Key Findings from Build Metadata Status Analysis**:
- Phase markers work correctly via `add_complete_marker()`
- No function exists to update metadata status field
- Build command marks phases individually but never checks overall completion
- Metadata status update pattern exists in `plan-core-bundle.sh` but not applied to status

**Key Findings from Metadata Update Patterns**:
- Pattern 1 (grep + sed) is best for simple field updates
- Should add after Date field if Status doesn't exist
- Helper function needed to check if all phases complete
- Integration needed at two build command blocks: start and completion

## Success Criteria
- [ ] `update_plan_status()` function added to checkbox-utils.sh
- [ ] `check_all_phases_complete()` function added to checkbox-utils.sh
- [ ] Build command Block 1 updates status to [IN PROGRESS] when starting
- [ ] Build command Block 4 updates status to [COMPLETE] when all phases done
- [ ] Functions handle edge cases (missing field, invalid status, partial completion)
- [ ] Existing tests pass (run_all_tests.sh)
- [ ] Manual test confirms status updates correctly on plan completion

## Technical Design

### New Functions in checkbox-utils.sh

**update_plan_status()**
- Updates `**Status**:` field in plan metadata
- Accepts: plan_path, status (NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)
- Uses sed for inline replacement when field exists
- Uses awk to add field if missing

**check_all_phases_complete()**
- Counts phases with [COMPLETE] marker
- Compares to total phase count
- Returns 0 if all complete, 1 otherwise

### Build Command Integration

**Block 1 Addition** (after line ~185):
```bash
# Update plan status to IN PROGRESS
if type update_plan_status &>/dev/null; then
  update_plan_status "$PLAN_FILE" "IN PROGRESS"
  echo "Plan status updated to [IN PROGRESS]"
fi
```

**Block 4 Addition** (after line ~881):
```bash
# Update metadata status if all phases complete
if check_all_phases_complete "$PLAN_FILE"; then
  update_plan_status "$PLAN_FILE" "COMPLETE"
  echo "✓ Plan metadata status updated to [COMPLETE]"
else
  echo "⚠ Some phases incomplete, status not updated"
fi
```

## Implementation Phases

### Phase 1: Add Status Update Functions to checkbox-utils.sh [COMPLETE]
dependencies: []

**Objective**: Implement update_plan_status() and check_all_phases_complete() functions

**Complexity**: Medium

Tasks:
- [x] Read current checkbox-utils.sh to find insertion point (file: /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh)
- [x] Add `update_plan_status()` function after `verify_phase_complete()` (line ~581)
  - Handle grep check for existing field
  - Use sed for inline update
  - Use awk for adding new field after Date
  - Validate status values (NOT STARTED|IN PROGRESS|COMPLETE|BLOCKED)
- [x] Add `check_all_phases_complete()` function after update_plan_status
  - Count total phases with grep
  - Count complete phases with grep
  - Return comparison result
- [x] Add export statements for new functions (after line ~594)
- [x] Test functions in isolation

Testing:
```bash
# Test update_plan_status
source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh
echo "- **Status**: [NOT STARTED]" > /tmp/test_plan.md
update_plan_status /tmp/test_plan.md "COMPLETE"
grep -q '\[COMPLETE\]' /tmp/test_plan.md && echo "update_plan_status: PASS" || echo "FAIL"

# Test check_all_phases_complete
cat > /tmp/test_plan.md << 'EOF'
### Phase 1: Setup [COMPLETE]
### Phase 2: Build [COMPLETE]
EOF
check_all_phases_complete /tmp/test_plan.md && echo "check_all_phases_complete: PASS" || echo "FAIL"
```

**Expected Duration**: 0.75 hours

---

### Phase 2: Integrate Functions into /build Command [COMPLETE]
dependencies: [1]

**Objective**: Add status update calls to build.md at appropriate points

**Complexity**: Low

Tasks:
- [x] Read current build.md to locate integration points (file: /home/benjamin/.config/.claude/commands/build.md)
- [x] Add IN PROGRESS update in Block 1 (after line ~185, after marking starting phase)
  - Source checkbox-utils.sh if not already sourced
  - Call update_plan_status "$PLAN_FILE" "IN PROGRESS"
  - Add progress message
- [x] Add COMPLETE update in Block 4 (after line ~881, in completion section)
  - Call check_all_phases_complete "$PLAN_FILE"
  - If true, call update_plan_status "$PLAN_FILE" "COMPLETE"
  - Add appropriate success/skip message
- [x] Ensure proper error handling (non-fatal if functions unavailable)

Testing:
```bash
# Manual test with actual plan
/build /home/benjamin/.config/.claude/specs/820_build_command_metadata_status_update/plans/001_build_metadata_status_update_plan.md --dry-run
# Should show: "Plan status updated to [IN PROGRESS]" in output
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Test Integration and Edge Cases [COMPLETE]
dependencies: [2]

**Objective**: Verify complete workflow and handle edge cases

**Complexity**: Low

Tasks:
- [x] Create test plan file with multiple phases
- [x] Run /build on test plan
- [x] Verify metadata status changes: NOT STARTED -> IN PROGRESS -> COMPLETE
- [x] Test edge case: Plan without Status field (should add it)
- [x] Test edge case: Partial completion (should not update to COMPLETE)
- [x] Test edge case: Plan with BLOCKED status (should not overwrite if any phase failed)
- [x] Run existing tests to ensure no regressions
- [x] Update function documentation in checkbox-utils.sh header comment

Testing:
```bash
# Run full test suite
cd /home/benjamin/.config/.claude/tests && ./run_all_tests.sh

# Manual integration test
# 1. Create test plan
cat > /tmp/test_build_plan.md << 'EOF'
## Metadata
- **Date**: 2025-11-19
- **Status**: [COMPLETE]

### Phase 1: Test Phase [COMPLETE]
Tasks:
- [x] Task 1
EOF

# 2. Run build (would need actual implementation)
# 3. Check metadata status updated
grep "Status.*COMPLETE" /tmp/test_build_plan.md && echo "PASS" || echo "FAIL"
```

**Expected Duration**: 0.75 hours

## Testing Strategy

### Unit Tests
- `update_plan_status()` with existing field
- `update_plan_status()` without Status field
- `update_plan_status()` with invalid status value
- `check_all_phases_complete()` with all complete
- `check_all_phases_complete()` with partial
- `check_all_phases_complete()` with zero phases

### Integration Tests
- Build command with fresh plan (NOT STARTED -> IN PROGRESS -> COMPLETE)
- Build command with partial completion (should not reach COMPLETE)
- Build command failure handling (status should reflect)

### Regression Tests
- Run existing test suite to ensure no breakage

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh` - Add new functions
- `/home/benjamin/.config/.claude/commands/build.md` - Add status update calls

### Documentation Updates
- Update checkbox-utils.sh header comment to list new functions
- No README changes required (internal library functions)

## Dependencies

### Prerequisites
- checkbox-utils.sh must be sourceable without errors
- plan-core-bundle.sh patterns available for reference
- Existing build.md structure unchanged

### External Dependencies
- None

### Constraints
- Must not break existing phase marker functionality
- Must be backward compatible with plans lacking Status field
- Non-fatal if functions unavailable (graceful degradation)

## Risk Mitigation

### Risk: sed -i Portability
**Mitigation**: The existing codebase uses `sed -i` successfully; follow same pattern

### Risk: Breaking Existing Tests
**Mitigation**: Run full test suite after implementation; revert if failures

### Risk: Race Condition in Parallel Execution
**Mitigation**: Functions are called after all phases complete (sequential point)
