# Plan Status Discrepancy - Clean-Break Fix

## Metadata
- **Date**: 2025-11-20
- **Feature**: Fix plan status marker validation bug
- **Scope**: Add validation to add_complete_marker() function and fix affected plan
- **Estimated Phases**: 1
- **Estimated Hours**: 1
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 8.0
- **Research Reports**:
  - [Plan Status Discrepancy Root Cause Analysis](../reports/001_plan_status_discrepancy_root_cause_analysis.md)
  - [Clean-Break Revision Insights](../reports/002_clean_break_revision_insights.md)

## Overview

This plan implements a minimal, clean-break fix for the plan status marker validation bug. The problem: `add_complete_marker()` adds `[COMPLETE]` markers without validating task completion. The solution: add 5 lines calling the existing `verify_phase_complete()` function before applying markers.

**Problem Impact**: Plan 859 shows all phases complete when summary shows 15% completion.

**Solution**: Single function modification + manual fix of affected plan file.

## Research Summary

Key findings from research reports:

**Root Cause** (Report 001):
- `add_complete_marker()` at line 472 of checkbox-utils.sh never validates completion
- `verify_phase_complete()` exists at line 547 but isn't called
- Build command already handles `add_complete_marker()` failures gracefully
- Only one plan affected (859) - appears to be one-time bulk marking error

**Clean-Break Approach** (Report 002):
- No force flag needed (defeats validation purpose)
- No new validation library needed (verify_phase_complete exists)
- No repair command needed (one file, one-time fix)
- No extensive documentation needed (5-line change)
- Function signature unchanged (backward compatible for free)

**Recommended Approach**: Minimal intervention - add validation call, fix affected file, test, done.

## Success Criteria
- [ ] add_complete_marker() validates before adding marker
- [ ] Function returns error when validation fails
- [ ] Affected plan (859) status markers corrected
- [ ] Build command continues working correctly
- [ ] Tests verify validation works for complete/incomplete phases

## Technical Design

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│         checkbox-utils.sh (BEFORE)                      │
├─────────────────────────────────────────────────────────┤
│  add_complete_marker(plan, phase)                       │
│    ├─ remove_status_marker()                            │
│    ├─ awk: add [COMPLETE] to heading                    │
│    └─ return 0 (ALWAYS SUCCEEDS)                        │
└─────────────────────────────────────────────────────────┘

                         ↓ FIX (5 lines)

┌─────────────────────────────────────────────────────────┐
│         checkbox-utils.sh (AFTER)                       │
├─────────────────────────────────────────────────────────┤
│  add_complete_marker(plan, phase)                       │
│    ├─ verify_phase_complete() ← NEW                     │
│    │   └─ return 1 if incomplete ← NEW                  │
│    ├─ remove_status_marker()                            │
│    ├─ awk: add [COMPLETE] to heading                    │
│    └─ return 0                                          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│         build.md (UNCHANGED)                            │
├─────────────────────────────────────────────────────────┤
│  if add_complete_marker "$plan" "$phase"; then          │
│    echo "✓ [COMPLETE] marker added"                     │
│  else                                                    │
│    echo "⚠ [COMPLETE] marker failed" ← Already handles │
│  fi                                                      │
└─────────────────────────────────────────────────────────┘
```

### Component Design

**Modified Function**: `add_complete_marker()`
- **Location**: `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:472`
- **Change**: Add validation check before marker application
- **Dependencies**: Existing `verify_phase_complete()` function at line 547
- **Return**: 0 on success, 1 on validation failure
- **Error Message**: "Cannot mark Phase N complete - incomplete tasks remain"

**No New Components**:
- No status-validation.sh library (verify_phase_complete exists)
- No /fix-plan-status command (manual edit simpler for one file)
- No force flag (clean-break: validation should always run)
- No documentation updates (inline comment sufficient)

### Integration Points

**Existing Infrastructure Used**:
- `verify_phase_complete()` - Returns 0 if all tasks [x], 1 if incomplete
- `error()` - From base-utils.sh for error messages
- Build command error handling - Already catches failures

**Backward Compatibility**:
- Function signature unchanged (2 required params)
- Return value already checked by build.md:438
- Error branch already implemented in caller
- No breaking changes (free backward compatibility)

## Implementation Phases

### Phase 1: Fix and Validate [COMPLETE]
dependencies: []

**Objective**: Add validation to add_complete_marker(), fix affected plan, test integration

**Complexity**: Low

Tasks:
- [x] Read current add_complete_marker() implementation at checkbox-utils.sh:472
- [x] Add validation check calling verify_phase_complete() before marker application (5 lines)
- [x] Add error message for validation failure
- [x] Test function with complete phase (all tasks [x]) - should succeed
- [x] Test function with incomplete phase (tasks [ ]) - should fail with error
- [x] Fix affected plan manually: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md
  - [x] Phase 1: [COMPLETE] → [IN PROGRESS] (15% done per summary)
  - [x] Phase 2: [COMPLETE] → [NOT STARTED]
  - [x] Phase 3: [COMPLETE] → [NOT STARTED]
  - [x] Phase 4: [COMPLETE] → [NOT STARTED]
- [x] Test build command with incomplete phase - verify error handling works
- [x] Create git commit with changes

Testing:
```bash
# Test 1: Function validation works
source /home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh

# Create test plan with complete phase
# Call add_complete_marker - should succeed

# Create test plan with incomplete phase
# Call add_complete_marker - should fail with error message

# Test 2: Build command handles failure gracefully
# Run /build on plan with incomplete phase
# Verify phase remains [IN PROGRESS] when tasks incomplete

# Test 3: Verify affected plan corrected
grep "^### Phase" /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan/001_leaderac_command_nvim_order_check_that_t_plan.md

# Expected output:
# ### Phase 1: ... [IN PROGRESS]
# ### Phase 2: ... [NOT STARTED]
# ### Phase 3: ... [NOT STARTED]
# ### Phase 4: ... [NOT STARTED]
```

**Expected Duration**: 1 hour

## Testing Strategy

### Unit Tests
Test the modified function directly:

1. **Complete Phase Test**: Phase with all tasks `[x]`
   - Call: `add_complete_marker plan.md 1`
   - Expected: Returns 0, marker added

2. **Incomplete Phase Test**: Phase with tasks `[ ]`
   - Call: `add_complete_marker plan.md 1`
   - Expected: Returns 1, error message, no marker added

3. **Mixed Phase Test**: Phase with some `[x]` some `[ ]`
   - Call: `add_complete_marker plan.md 1`
   - Expected: Returns 1, validation fails

### Integration Tests
Test build command integration:

1. **Normal Flow**: Build phase completely
   - Run: `/build plan.md 1` (complete all tasks)
   - Expected: Phase marked [COMPLETE]

2. **Incomplete Flow**: Build phase partially
   - Run: `/build plan.md 1` (leave tasks incomplete)
   - Expected: Phase remains [IN PROGRESS], error message shown

3. **Existing Plans**: Run on existing plans
   - Expected: No breaking changes, validation works

### Regression Tests
Verify existing functionality:

- [ ] verify_phase_complete() still works correctly
- [ ] remove_status_marker() unaffected
- [ ] add_in_progress_marker() unaffected
- [ ] Checkbox propagation in hierarchical plans
- [ ] Build command phase transitions

## Documentation Requirements

### Inline Documentation
Add comment in checkbox-utils.sh above validation:
```bash
# Validate all tasks complete before marking phase
```

### No Additional Documentation
- No new command documentation (no new command)
- No extensive guides (5-line change)
- No troubleshooting docs (error message is clear)
- No architecture updates (existing infrastructure)

Standard inline comment is sufficient for this change.

## Dependencies

### Internal Dependencies
- `verify_phase_complete()` - Existing function at checkbox-utils.sh:547
- `error()` - From base-utils.sh for error messages
- Build command - Consumer of add_complete_marker()

### Prerequisites
- Bash 4.0+ (existing requirement)
- AWK (existing requirement)
- No new dependencies

## Risk Assessment

### Risk 1: Validation Breaks Workflows
**Likelihood**: Very Low
**Impact**: Low
**Mitigation**: Function signature unchanged, build command already handles failures, return value already checked

### Risk 2: False Validation Failures
**Likelihood**: Very Low
**Impact**: Low
**Mitigation**: Using existing battle-tested verify_phase_complete() function

### Risk 3: Incomplete Fix
**Likelihood**: Very Low
**Impact**: Low
**Mitigation**: Root cause is clear, fix is complete - validation prevents future occurrences

## Success Metrics

- **Correctness**: 100% - Markers only added when all tasks complete
- **Simplicity**: 5 lines of code changed
- **Testing**: All tests pass (unit, integration, regression)
- **Reliability**: Affected plan corrected, future occurrences prevented
- **Compatibility**: 0 breaking changes (free backward compatibility)

## Notes

### Design Decisions

**Why no force flag?**
Clean-break approach: if validation fails, it should fail. Manual plan editing available for edge cases.

**Why no repair command?**
One file needs fixing (plan 859). Manual edit with Edit tool is simpler than creating infrastructure.

**Why no validation library?**
verify_phase_complete() already exists and does what's needed. No new infrastructure required.

**Why no extensive documentation?**
5-line change with inline comment is self-documenting. Over-documentation creates maintenance burden.

### Clean-Break Principles Applied

1. **Coherence over Compatibility**: Validation always runs (no bypass)
2. **No Legacy Burden**: Old behavior (no validation) replaced entirely
3. **Minimal Intervention**: Smallest change that solves problem
4. **Free Backward Compatibility**: Function signature unchanged

### Implementation Code

**Exact Change to checkbox-utils.sh:472**:

```bash
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  if [[ ! -f "$plan_path" ]]; then
    error "Plan file not found: $plan_path"
    return 1
  fi

  # NEW: Validate phase completion before marking
  if ! verify_phase_complete "$plan_path" "$phase_num"; then
    error "Cannot mark Phase $phase_num complete - incomplete tasks remain"
    return 1
  fi
  # END NEW

  # First remove any existing status marker
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  local temp_file=$(mktemp)
  awk -v phase="$phase_num" '
    /^### Phase / {
      phase_field = $3
      gsub(/:/, "", phase_field)
      if (phase_field == phase && !/\[COMPLETE\]/) {
        sub(/$/, " [COMPLETE]")
      }
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  mv "$temp_file" "$plan_path"
  return 0
}
```

**Lines Added**: 5 (validation check + error message)
**Lines Modified**: 0 (existing code unchanged)
**Total Impact**: Minimal
