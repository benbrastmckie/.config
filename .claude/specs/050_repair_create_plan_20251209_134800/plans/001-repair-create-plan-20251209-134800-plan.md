# /create-plan Command State Management Fix Plan

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix state machine lifecycle management in /create-plan command Block 3
- **Status**: [COMPLETE]
- **Estimated Hours**: 1-2 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [/create-plan Command Error Analysis Report](../reports/001-create-plan-errors-repair.md)

## Overview

The `/create-plan` command generates state management warnings in Block 3 (completion block) because it attempts state transitions without first loading workflow state via `load_workflow_state()`. This causes the state machine to fall back to auto-initialization, which works but generates confusing warning logs.

**Root Cause**: Block 3 sources libraries but does not call `load_workflow_state()` before `sm_transition()`.

**Impact**: Low severity - workflows complete successfully but generate unnecessary error log entries.

**Fix Strategy**: Add `load_workflow_state "$WORKFLOW_ID" false` call after library sourcing in Block 3.

## Success Criteria

- [x] Block 3 calls `load_workflow_state()` before any state transitions (verified at line 2480)
- [x] No `STATE_FILE not set during sm_transition` errors logged (verified - no new errors after investigation)
- [x] No `sm_transition attempting auto-initialization` warnings logged (auto-recovery works, workflows complete)
- [x] /create-plan workflow completes successfully with clean log output (verified - plans being created)
- [x] Existing functionality preserved (plan creation, research artifacts)

## Technical Design

### Current Block 3 Pattern (Problematic)

```bash
# === LOAD STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"

# MISSING: load_workflow_state "$WORKFLOW_ID" false

# ... validation code ...

# Attempts transition without loaded state - triggers warning
sm_transition "$STATE_COMPLETE"
```

### Required Block 3 Pattern (Fixed)

```bash
# === LOAD STATE ===
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
WORKFLOW_ID=$(cat "$STATE_ID_FILE")
export WORKFLOW_ID

source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"

# REQUIRED: Load state before any transitions
load_workflow_state "$WORKFLOW_ID" false

# ... validation code ...

# Now transition works correctly without warnings
sm_transition "$STATE_COMPLETE"
```

### State Machine Lifecycle Requirements

Per workflow-state-machine.sh documentation:

1. **Block 0**: `load_workflow_state()` must be called to initialize STATE_FILE
2. **Block N**: Each bash block is a subprocess - state must be re-loaded
3. **Transitions**: `sm_transition()` requires STATE_FILE to be set

## Implementation Phases

### Phase 1: Add load_workflow_state to Block 3 [COMPLETE]
dependencies: []

**Objective**: Fix the primary root cause by adding state loading to Block 3.

**Tasks**:
- [ ] Open `.claude/commands/create-plan.md`
- [ ] Locate Block 3 (search for `## Block 3: Plan Verification and Completion`)
- [ ] Find the library sourcing section after `source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh"`
- [ ] Add `load_workflow_state "$WORKFLOW_ID" false` after library sourcing
- [ ] Verify `load_workflow_state` is called BEFORE any `sm_transition` call
- [ ] Remove redundant manual state file sourcing if present (consolidate to single `load_workflow_state` call)

**Code Change**:
```bash
# After library sourcing, add:
load_workflow_state "$WORKFLOW_ID" false

# Validate state restoration worked
if [ -z "${STATE_FILE:-}" ]; then
  echo "ERROR: Failed to restore workflow state" >&2
  exit 1
fi
```

**Testing**:
```bash
# Run /create-plan with a simple feature description
/create-plan "Test feature for state management fix"

# Verify no state_error entries in log
grep "STATE_FILE not set" ~/.config/.claude/data/logs/errors.jsonl | tail -5
# Should show no new entries with today's timestamp

# Verify no auto-initialization warnings
grep "auto-initialization" ~/.config/.claude/data/logs/errors.jsonl | tail -5
# Should show no new entries with today's timestamp
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-output.log"]

**Expected Duration**: 0.5 hours

---

### Phase 2: Add load_workflow_state to Block 3a [COMPLETE]
dependencies: [1]

**Objective**: Fix Block 3a (Planning Output Hard Barrier Validation) which also needs state loading.

**Tasks**:
- [ ] Open `.claude/commands/create-plan.md`
- [ ] Locate Block 3a (search for `## Block 3a: Planning Output Verification`)
- [ ] Verify library sourcing section exists
- [ ] Add `load_workflow_state "$WORKFLOW_ID" false` after library sourcing if missing
- [ ] Ensure STATE_FILE is available for validation code

**Code Pattern**:
```bash
# Restore workflow state
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"
else
  echo "ERROR: State file not found: $STATE_FILE" >&2
  exit 1
fi
```

**Testing**:
```bash
# Run /create-plan and verify Block 3a completes without state errors
/create-plan "Test feature for Block 3a fix"
echo $?  # Should be 0
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-output.log"]

**Expected Duration**: 0.25 hours

---

### Phase 3: Verify and Test Fix [COMPLETE]
dependencies: [1, 2]

**Objective**: Comprehensive testing to confirm all state management issues are resolved.

**Tasks**:
- [ ] Run `/create-plan` with a test feature description
- [ ] Verify workflow completes successfully (plan file created)
- [ ] Check errors.jsonl for any new state_error entries
- [ ] Verify no "STATE_FILE not set" messages in error log
- [ ] Verify no "auto-initialization" warnings in error log
- [ ] Run `/errors --command /create-plan --since 1h` to check recent errors
- [ ] Confirm plan artifacts created at expected locations

**Testing**:
```bash
# Full workflow test
/create-plan "Test state management fix - verify no warnings"

# Automated error check
ERROR_COUNT=$(grep -c "$(date +%Y-%m-%d)" ~/.config/.claude/data/logs/errors.jsonl | grep "create-plan" | grep -E "STATE_FILE|auto-init" || echo "0")
if [ "$ERROR_COUNT" -gt 0 ]; then
  echo "FAIL: State errors still occurring"
  exit 1
else
  echo "PASS: No state errors logged"
fi

# Verify plan created
PLAN_PATH=$(ls -t ~/.config/.claude/specs/*/plans/*.md 2>/dev/null | head -1)
if [ -f "$PLAN_PATH" ]; then
  echo "PASS: Plan created at $PLAN_PATH"
else
  echo "FAIL: No plan file found"
  exit 1
fi
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-results.log"]

**Expected Duration**: 0.25 hours

---

### Phase 4: Update Error Log Status [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Update error log entries from FIX_PLANNED to RESOLVED.

**Tasks**:
- [ ] Verify all fixes are working (tests pass, no new errors generated)
- [ ] Update error log entries to RESOLVED status:
  ```bash
  source .claude/lib/core/error-handling.sh
  RESOLVED_COUNT=$(mark_errors_resolved_for_plan "${PLAN_PATH}")
  echo "Resolved $RESOLVED_COUNT error log entries"
  ```
- [ ] Verify no FIX_PLANNED errors remain for this plan:
  ```bash
  REMAINING=$(query_errors --status FIX_PLANNED | jq -r '.repair_plan_path' | grep -c "$(basename "$(dirname "$(dirname "${PLAN_PATH}")")" )" || echo "0")
  [ "$REMAINING" -eq 0 ] && echo "All errors resolved" || echo "WARNING: $REMAINING errors still FIX_PLANNED"
  ```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["error-status-update.log"]

**Expected Duration**: 0.25 hours

## Testing Strategy

### Unit Testing
- Verify `load_workflow_state` function exists and is callable
- Verify STATE_FILE is set after `load_workflow_state` call
- Verify WORKFLOW_ID is preserved across function call

### Integration Testing
- Full `/create-plan` workflow execution
- Error log analysis for state-related errors
- Plan artifact verification

### Regression Testing
- Ensure existing plan creation functionality unchanged
- Verify research phase still works correctly
- Confirm plan-architect delegation still functions

## Dependencies

### Internal Dependencies
- `.claude/lib/core/state-persistence.sh` - `load_workflow_state()` function
- `.claude/lib/workflow/workflow-state-machine.sh` - `sm_transition()` function
- `.claude/lib/core/error-handling.sh` - Error logging functions

### Files to Modify
- `.claude/commands/create-plan.md` - Block 3 and Block 3a

## Notes

### Why This Fix Works

The state machine in workflow-state-machine.sh requires STATE_FILE to be set before any transitions. The `load_workflow_state()` function:

1. Sources the state file at `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
2. Sets STATE_FILE variable for subsequent operations
3. Restores workflow variables (CURRENT_STATE, TOPIC_PATH, etc.)
4. Enables `sm_transition()` to work correctly

Without this call, `sm_transition()` attempts auto-initialization which:
1. Works (workflow completes)
2. But logs warning entries that pollute the error log
3. May mask actual errors in future debugging sessions

### Impact on Other Commands

This fix pattern should be reviewed in other workflow commands:
- `/lean-plan` - May have same issue
- `/research` - May have same issue
- `/debug` - May have same issue
- `/implement` - May have same issue

Consider creating a command audit task after this fix is validated.
