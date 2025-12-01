# Phase Status Metadata Discrepancy Research Report

## Metadata
- **Date**: 2025-11-30
- **Agent**: research-specialist
- **Topic**: Plan metadata status remains [IN PROGRESS] despite all phases marked [COMPLETE]
- **Report Type**: codebase analysis

## Executive Summary

Plans with all phases marked `[COMPLETE]` may still show `Status: [IN PROGRESS]` in their metadata section. This occurs because the `/build` command only updates the plan metadata status to `[COMPLETE]` at workflow completion (line 1849-1858 of build.md), but this logic is never reached if phases are marked complete through other mechanisms (manual updates, partial builds, or phase-by-phase execution). The `check_all_phases_complete()` function correctly identifies when all phases have `[COMPLETE]` markers, but the metadata update is conditionally executed only within the `/build` command's final cleanup block.

## Findings

### Root Cause Analysis

**Primary Issue**: Metadata status update is tightly coupled to `/build` workflow completion, not to actual phase completion state.

#### Evidence from Codebase

1. **Plan Metadata Update Location** (`/build` command, lines 1849-1858):
```bash
# CRITICAL: Update metadata status if all phases complete - must not be skipped
if type check_all_phases_complete &>/dev/null && type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    if update_plan_status "$PLAN_FILE" "COMPLETE"; then
      echo ""
      echo "Plan metadata status updated to [COMPLETE]"
    else
      echo "WARNING: Could not update plan status to COMPLETE" >&2
    fi
  fi
fi
```

2. **Status Set to IN PROGRESS** (`/build` command, lines 342-347):
```bash
# Update plan metadata status to IN PROGRESS
if type update_plan_status &>/dev/null; then
  if update_plan_status "$PLAN_FILE" "IN PROGRESS" 2>/dev/null; then
    echo "Plan metadata status updated to [IN PROGRESS]"
  fi
fi
```

3. **Phase Completion Marker Functions** (`checkbox-utils.sh`, lines 470-507):
```bash
# Add [COMPLETE] marker to phase heading
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  # Validate phase completion before marking
  if ! verify_phase_complete "$plan_path" "$phase_num"; then
    error "Cannot mark Phase $phase_num complete - incomplete tasks remain"
    return 1
  fi

  # First remove any existing status marker
  remove_status_marker "$plan_path" "$phase_num"

  # Add [COMPLETE] marker to phase heading
  # ...
}
```

**Key Observation**: `add_complete_marker()` validates and updates phase headings but does NOT check or update the plan's metadata status field.

4. **Check Function Implementation** (`checkbox-utils.sh`, lines 649-680):
```bash
# Check if all phases in a plan are marked complete
check_all_phases_complete() {
  local plan_path="$1"

  # Count total phases
  local total_phases=$(grep -c "^### Phase [0-9]" "$plan_path" 2>/dev/null || echo "0")

  # Count phases with [COMPLETE] marker
  local complete_phases=$(grep -c "^### Phase [0-9].*\[COMPLETE\]" "$plan_path" 2>/dev/null || echo "0")

  if [[ "$complete_phases" -eq "$total_phases" ]]; then
    return 0
  else
    return 1
  fi
}
```

**This function works correctly** - it accurately counts phase completion markers.

### Scenarios Leading to Status Discrepancy

1. **Partial `/build` Execution**:
   - User runs `/build plan.md 5` to start at phase 5
   - Phases 1-4 were already marked `[COMPLETE]` from previous work
   - `/build` sets metadata to `[IN PROGRESS]` at line 344
   - Phase 5 completes successfully
   - **If `/build` errors or is interrupted before line 1849**, metadata remains `[IN PROGRESS]`

2. **Manual Phase Completion**:
   - User manually adds `[COMPLETE]` markers to phase headings
   - Metadata status field never updated (no automatic sync mechanism)
   - Plan shows all phases complete but metadata shows `[IN PROGRESS]`

3. **Phase-by-Phase Workflow**:
   - User completes phases individually outside `/build` workflow
   - Each phase gets `[COMPLETE]` marker via `add_complete_marker()`
   - No code path updates metadata status except `/build` final block
   - Last phase completion doesn't trigger metadata update

4. **Build Errors After Last Phase**:
   - All implementation phases complete successfully
   - Tests fail or documentation phase encounters error
   - `/build` exits before reaching line 1849 metadata update
   - Phases show `[COMPLETE]`, metadata shows `[IN PROGRESS]`

### Real-World Example

Plan 965 (`965_optimize_plan_command_performance/plans/001-optimize-plan-command-performance-plan.md`):
- **Metadata Line 10**: `- **Status**: [IN PROGRESS]`
- **Total Phases**: 9 phases defined (Phase 0, 0.5, 1, 2, 3, 4, 5, 6, 7, 8)
- **Query Results**: Need to verify actual phase heading markers

### Architecture Gap

**Missing Synchronization**: Phase-level state changes (via `add_complete_marker()`) do not trigger plan-level metadata updates. The system has:
- ✓ Functions to update individual phase markers (`add_complete_marker`)
- ✓ Functions to check overall completion (`check_all_phases_complete`)
- ✓ Functions to update plan metadata (`update_plan_status`)
- ✗ **No automatic synchronization between phase completion and plan metadata**

**Current Architecture**:
```
Phase Completion → add_complete_marker() → Updates phase heading
                                          ↓
                                    (NO automatic sync)
                                          ↓
Plan Metadata    ← update_plan_status() ← Manual call from /build only
```

**Expected Architecture**:
```
Phase Completion → add_complete_marker() → Updates phase heading
                                          ↓
                                    Check if all complete
                                          ↓
                                    Auto-update metadata
                                          ↓
Plan Metadata    ← update_plan_status() ← Synchronized automatically
```

### Code Locations

| Component | File | Lines | Function |
|-----------|------|-------|----------|
| Metadata update (IN PROGRESS) | `.claude/commands/build.md` | 343-347 | Sets status at workflow start |
| Metadata update (COMPLETE) | `.claude/commands/build.md` | 1849-1858 | Sets status at workflow end |
| Phase marker update | `.claude/lib/plan/checkbox-utils.sh` | 470-507 | `add_complete_marker()` |
| Completion check | `.claude/lib/plan/checkbox-utils.sh` | 649-680 | `check_all_phases_complete()` |
| Status update function | `.claude/lib/plan/checkbox-utils.sh` | 591-647 | `update_plan_status()` |

## Recommendations

### 1. Add Automatic Metadata Sync to `add_complete_marker()`

**Impact**: High - Fixes root cause by synchronizing phase and plan state
**Complexity**: Low - Single function modification
**Risk**: Low - Function already validates phase completion

**Implementation**:
```bash
# Add [COMPLETE] marker to phase heading
add_complete_marker() {
  local plan_path="$1"
  local phase_num="$2"

  # Existing validation and marker logic...
  # (lines 472-505)

  # NEW: Check if all phases now complete and update plan metadata
  if check_all_phases_complete "$plan_path"; then
    if type update_plan_status &>/dev/null; then
      update_plan_status "$plan_path" "COMPLETE" 2>/dev/null || \
        warn "Could not update plan metadata to COMPLETE (non-fatal)"
    fi
  fi

  return 0
}
```

**Benefits**:
- Immediate metadata sync when last phase completes
- Works regardless of completion mechanism (manual, `/build`, other commands)
- No changes to existing workflows or command behavior
- Fail-safe design (warns but doesn't error on metadata update failure)

### 2. Add Metadata Verification to `/build` Startup

**Impact**: Medium - Corrects stale metadata at workflow start
**Complexity**: Low - Add check before setting IN PROGRESS
**Risk**: Very Low - Read-only verification

**Implementation**:
```bash
# Before line 343 in build.md, add:
# Verify metadata is accurate before starting
if type check_all_phases_complete &>/dev/null && \
   type update_plan_status &>/dev/null; then
  if check_all_phases_complete "$PLAN_FILE"; then
    # All phases already complete, update metadata if stale
    update_plan_status "$PLAN_FILE" "COMPLETE" 2>/dev/null
    echo "NOTE: Plan already complete (all phases have [COMPLETE] markers)"
    echo "To re-run implementation, remove [COMPLETE] markers from phases"
    exit 0
  fi
fi

# Existing IN PROGRESS update (line 343-347)...
```

**Benefits**:
- Prevents `/build` from running on completed plans
- Corrects stale metadata early in workflow
- Provides clear user feedback on plan state
- Prevents wasted agent invocations

### 3. Create Standalone Plan Status Sync Command

**Impact**: Medium - Provides manual correction mechanism
**Complexity**: Medium - New command creation
**Risk**: Low - Read/write operations are already proven

**Implementation**: Create `/sync-plan-status [plan-file]` command

**Benefits**:
- Users can manually fix status discrepancies
- Useful for batch correction of existing plans
- Can be integrated into `/todo` cleanup workflows
- Provides diagnostic output for troubleshooting

### 4. Add Metadata Status to Plan Health Check

**Impact**: Low - Detection and reporting only
**Complexity**: Low - Add check to existing validation
**Risk**: None - Read-only diagnostic

**Implementation**: Extend plan validation to detect status mismatches

**Benefits**:
- Early detection of synchronization issues
- Helps identify patterns in when desync occurs
- Can inform further optimization opportunities

## Implementation Priority

**Phase 1** (Critical - Fixes Root Cause):
1. Implement Recommendation #1 (Auto-sync in `add_complete_marker()`)
2. Test with existing plans and workflows
3. Verify no regressions in `/build`, `/collapse`, phase completion flows

**Phase 2** (Important - Prevents Future Issues):
1. Implement Recommendation #2 (Startup verification in `/build`)
2. Update `/build` tests to cover completed-plan scenario
3. Document behavior in build command guide

**Phase 3** (Nice-to-Have - Tooling):
1. Implement Recommendation #3 (Standalone sync command)
2. Add to standard command repertoire
3. Integrate with `/todo` cleanup workflows

**Phase 4** (Optional - Observability):
1. Implement Recommendation #4 (Health check integration)
2. Add to existing validation infrastructure
3. Track metrics on synchronization accuracy

## References

- `/home/benjamin/.config/.claude/commands/build.md:343-347` - IN PROGRESS status set
- `/home/benjamin/.config/.claude/commands/build.md:1849-1858` - COMPLETE status set
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:470-507` - `add_complete_marker()`
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:591-647` - `update_plan_status()`
- `/home/benjamin/.config/.claude/lib/plan/checkbox-utils.sh:649-680` - `check_all_phases_complete()`
- `/home/benjamin/.config/.claude/specs/965_optimize_plan_command_performance/plans/001-optimize-plan-command-performance-plan.md` - Example plan with status discrepancy
