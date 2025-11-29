# Error Log Status Lifecycle Research Report

## Date
2025-11-29

## Research Question
Does the repair workflow include instructions to update error log status from FIX_PLANNED to FIXED/RESOLVED after fixes are implemented? If not, how should this be addressed?

## Executive Summary

**Finding**: The current repair workflow marks errors as `FIX_PLANNED` when a repair plan is created, but there is **NO mechanism** to update the status to `FIXED` or `RESOLVED` after the fixes are implemented via `/build`.

This creates stale error log entries that remain in `FIX_PLANNED` status indefinitely, even after fixes are successfully implemented and verified.

## Current Error Status Lifecycle

### Status Constants (from error-handling.sh:1094-1097)
```bash
readonly ERROR_STATUS_ERROR="ERROR"
readonly ERROR_STATUS_FIX_PLANNED="FIX_PLANNED"
readonly ERROR_STATUS_RESOLVED="RESOLVED"
```

### Current Flow
```
Error Occurs → ERROR status (logged automatically)
     ↓
/repair runs → FIX_PLANNED status (automated by repair.md:961-964)
     ↓
/build runs → ??? (NO STATUS UPDATE)
     ↓
Errors remain FIX_PLANNED forever
```

### What /repair Does (repair.md:961-964)
```bash
# Mark matching errors as FIX_PLANNED with plan path
ERRORS_UPDATED=$(mark_errors_fix_planned "$PLAN_PATH" $FILTER_ARGS)
echo "Updated $ERRORS_UPDATED error entries with FIX_PLANNED status"
```

### What /build Does NOT Do
- No call to `update_error_status` to mark errors as RESOLVED
- No awareness of whether the plan being built is a repair plan
- No mechanism to track which errors are associated with a plan

## Analysis of Existing Repair Plan

**Reviewed**: `/home/benjamin/.config/.claude/specs/941_debug_errors_repair/plans/001-debug-errors-repair-plan.md`

**Finding**: The plan has `Status: [COMPLETE]` but contains **NO phase or task** to:
- Update error log entries to RESOLVED status
- Verify that fixed errors are marked as resolved
- Clean up the error log after fixes are implemented

The plan's testing phases verify the fixes work but don't close the error lifecycle loop.

## Gap Analysis

### Missing Components

1. **Plan Template Gap**: Plan architect agent doesn't include error status update phase for repair plans
2. **Build Command Gap**: /build doesn't detect repair plans or trigger error status updates
3. **Manual Verification Gap**: No workflow exists to verify and mark errors as RESOLVED

### Available Infrastructure

The infrastructure exists but is unused:

```bash
# update_error_status function exists (error-handling.sh:1099-1123)
update_error_status <workflow_id> <timestamp> <new_status> [repair_plan_path]

# Status constants defined
ERROR_STATUS_RESOLVED="RESOLVED"
```

## Proposed Solution

### Option A: Add Phase to Repair Plans (Recommended)

Modify the plan-architect agent to automatically include an "Error Status Update" phase when creating repair plans:

```markdown
### Phase N: Update Error Log Status [NOT STARTED]
dependencies: [all previous phases]

**Objective**: Mark resolved errors in error log

Tasks:
- [ ] Identify errors linked to this repair plan
- [ ] Verify fixes are working (tests pass, no new errors)
- [ ] Update error log entries to RESOLVED status:
  ```bash
  # Update errors marked with this plan path
  query_errors --status FIX_PLANNED | \
    jq -r 'select(.repair_plan_path == "/path/to/this-plan.md") | [.workflow_id, .timestamp] | @tsv' | \
    while read wf_id ts; do
      update_error_status "$wf_id" "$ts" "RESOLVED"
    done
  ```
- [ ] Verify no FIX_PLANNED errors remain for this plan
```

### Option B: Automate in /build Command

Add automatic error status update to /build when completing a repair plan:

```bash
# In build.md completion block
if [[ "$PLAN_PATH" == *"repair"* ]]; then
  # Mark associated errors as RESOLVED
  mark_errors_resolved_for_plan "$PLAN_PATH"
fi
```

### Option C: Hybrid Approach

1. Plan architect adds verification task (awareness)
2. /build automates the status update (execution)

## Recommendations

1. **Immediate**: Update plan-architect agent to include error status update phase for repair plans
2. **Future**: Consider automating in /build for seamless lifecycle management
3. **Documentation**: Add error lifecycle documentation to error-handling pattern docs

## Files Requiring Changes

| File | Change Required |
|------|-----------------|
| `.claude/agents/plan-architect.md` | Add error status update phase template for repair plans |
| `.claude/lib/core/error-handling.sh` | Add `mark_errors_resolved_for_plan()` helper function |
| `.claude/commands/build.md` | (Optional) Add repair plan detection and auto-update |
| `.claude/docs/concepts/patterns/error-handling.md` | Document complete error lifecycle |

## Verification Query

To find errors stuck in FIX_PLANNED status:

```bash
# Query FIX_PLANNED errors
query_errors --status FIX_PLANNED

# Count by repair plan
query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | sort | uniq -c
```
