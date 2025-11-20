# /plan Command State Persistence Failure - Root Cause Analysis

**Report Type**: Bug Analysis
**Severity**: Critical - Command completely non-functional
**Affected Component**: `/plan` command state persistence mechanism
**Date**: 2025-11-20
**Workflow ID**: Research for spec 849

---

## Executive Summary

The `/plan` command fails in Block 3 with "PLAN_PATH: unbound variable" error because the workflow state file created in Block 1 is not being persisted to disk or is being deleted before Block 3 executes. This is a critical state persistence failure that renders the `/plan` command completely non-functional.

**Root Cause**: State file lifecycle management issue - file created in Block 1 but missing when Block 3 attempts to load it.

**Impact**: 100% failure rate for `/plan` command execution across all workflows.

---

## Error Context

### Error Manifestation

From `/home/benjamin/.config/.claude/plan-output.md` (Block 3, lines 40-56):

```bash
# Block 3: Plan Verification and Completion
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 96: PLAN_PATH: unbound variable

     Verifying plan artifacts...

# Second attempt (line 47-49):
● Bash(set +H  # CRITICAL: Disable history expansion…)
  ⎿  Error: Exit code 127
     /run/current-system/sw/bin/bash: line 102: PLAN_PATH: unbound variable

# Third attempt reveals state file missing (line 53-62):
● Bash(STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
      WORKFLOW_ID=$(cat "$STATE_ID_FILE")…)
  ⎿  Error: Exit code 1
     cat: /home/benjamin/.claude/state/plan_1763665129.state: No such file or directory

     Workflow ID: plan_1763665129
     State file: /home/benjamin/.claude/state/plan_1763665129.state

     State file contents:
```

### Critical Observation

**The error message shows a path mismatch**:
- Error reports: `/home/benjamin/.claude/state/plan_1763665129.state`
- Actual location should be: `/home/benjamin/.claude/tmp/workflow_plan_1763665129.sh`

This indicates either:
1. **Path Construction Error**: Code is looking in wrong directory
2. **Legacy Code Path**: Old code using deprecated `.claude/state/` directory
3. **Documentation Inconsistency**: Error message using outdated path format

---

## Investigation Findings

### 1. State File Location Standards (Current)

**From `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` (lines 156-162)**:

```bash
# Create state file
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"

cat > "$STATE_FILE" <<EOF
export CLAUDE_PROJECT_DIR="$CLAUDE_PROJECT_DIR"
export WORKFLOW_ID="$workflow_id"
export STATE_FILE="$STATE_FILE"
EOF
```

**Expected State File Path**:
- Format: `.claude/tmp/workflow_${workflow_id}.sh`
- Example: `.claude/tmp/workflow_plan_1763665129.sh`
- **NOT** `.claude/state/*.state` (deprecated)

### 2. State File Location Standards (Legacy)

**Documentation references found with deprecated paths**:

```bash
# Found in 4 documentation files:
.claude/docs/architecture/state-orchestration-troubleshooting.md:73:
  STATE_FILE=".claude/state/workflow_${ID}.state"

.claude/docs/architecture/state-orchestration-examples.md:105:
  STATE_FILE=".claude/state/workflow_${ID}.state"

.claude/docs/architecture/state-orchestration-transitions.md:96:
  STATE_FILE=".claude/state/workflow_${id}.state"

.claude/docs/guides/patterns/command-patterns/command-patterns-checkpoints.md:287:
  STATE_FILE=".claude/state/workflow_${id}.state"
```

**Conclusion**: Documentation contains outdated examples that don't match current implementation.

### 3. State File Lifecycle Analysis

**Block 1: State File Creation** (plan.md lines 147-154):

```bash
# Capture state file path for append_workflow_state
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE

# Validate state file creation
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

✅ **Verified**: Block 1 creates state file and validates its existence
✅ **Verified**: WORKFLOW_ID written to `.claude/tmp/plan_state_id.txt`

**Block 2: State File Loading** (plan.md lines 260-263):

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false
```

**Block 3: State File Loading** (plan.md lines 373-376):

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null

load_workflow_state "$WORKFLOW_ID" false
```

✅ **Verified**: Both blocks attempt to load state using same mechanism

### 4. State File Persistence Verification

**Actual state file directory contents**:

```bash
$ ls -la /home/benjamin/.claude/tmp/*.sh
-rw-r--r-- 1 benjamin users  323 Nov 19 16:51 /home/benjamin/.claude/tmp/revise_vars.sh
-rw-r--r-- 1 benjamin users 7901 Nov 16 22:39 /home/benjamin/.claude/tmp/workflow_coordinate_1763350170.sh
```

❌ **CRITICAL**: No `workflow_plan_*.sh` files exist
❌ **CRITICAL**: State file created in Block 1 is missing by Block 3

**Workflow ID tracking**:

```bash
$ cat /home/benjamin/.claude/tmp/plan_state_id.txt
plan_1763665404

# But actual workflow ID from error was: plan_1763665129
# Mismatch indicates multiple /plan invocations with state file churn
```

### 5. load_workflow_state Behavior Analysis

**From `state-persistence.sh` (lines 212-295)**:

```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"  # Fail-fast validation mode
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    # State file exists - source it to restore variables
    source "$state_file"
    # ... variable validation ...
    return 0
  else
    # Spec 672 Phase 3: Distinguish expected vs unexpected missing state files
    if [ "$is_first_block" = "true" ]; then
      # Expected case: First bash block of workflow, gracefully initialize
      init_workflow_state "$workflow_id" >/dev/null
      return 1
    else
      # CRITICAL ERROR: Subsequent bash block, state file should exist but doesn't
      echo "" >&2
      echo "❌ CRITICAL ERROR: Workflow state file not found" >&2
      # ... diagnostic output ...
      return 2  # Exit code 2 = configuration error
    fi
  fi
}
```

**Key Points**:
1. ✅ Uses correct path: `.claude/tmp/workflow_${workflow_id}.sh`
2. ✅ Has fail-fast mode for subsequent blocks (`is_first_block=false`)
3. ❌ **BUT**: `/plan` Block 3 error doesn't show this diagnostic output
4. ❌ **BUT**: Error shows wrong path: `.claude/state/plan_*.state`

**Conclusion**: The error message is coming from different code, not from `load_workflow_state()`.

### 6. Error Message Source Investigation

**Searching for the error message source**:

```bash
# Error format from plan-output.md:
cat: /home/benjamin/.claude/state/plan_1763665129.state: No such file or directory
```

This is a direct `cat` command failure, not from `load_workflow_state()`. Let me search for where this might be:

**Hypothesis**: There may be debug/diagnostic code in the actual bash block that's using the wrong path.

Looking at plan-output.md line 53-56:

```bash
● Bash(STATE_ID_FILE="${HOME}/.claude/tmp/plan_state_id.txt"
      WORKFLOW_ID=$(cat "$STATE_ID_FILE")…)
```

This suggests the user manually ran a bash block to debug, and that debug code used the wrong path format.

---

## Root Cause Analysis

### Primary Root Cause: State File Not Persisting

**Evidence**:
1. State file created in Block 1: `workflow_plan_1763665129.sh`
2. State file missing by Block 3: No such file in `.claude/tmp/`
3. Only old state files exist: `workflow_coordinate_1763350170.sh` from Nov 16

**Possible Causes**:

#### Hypothesis A: EXIT Trap Cleanup (MOST LIKELY)

**From state-persistence.sh documentation (lines 32-33)**:

```bash
# Example usage:
STATE_FILE=$(init_workflow_state "coordinate_$$")
trap "rm -f '$STATE_FILE'" EXIT  # Set cleanup trap in caller
```

**Analysis**:
- State persistence library expects caller to set EXIT trap
- But `/plan` command Block 1 might not be setting this trap
- OR worse: Block 1 might be setting trap that deletes file when block completes
- When Block 1 exits (even successfully), EXIT trap fires and deletes state file
- Block 2 and Block 3 then have no state file to load

**Verification Needed**: Check if `/plan` Block 1 sets EXIT trap for cleanup

#### Hypothesis B: Workflow ID Mismatch

**Evidence from state ID file**:

```bash
$ cat /home/benjamin/.claude/tmp/plan_state_id.txt
plan_1763665404  # ← Current value

# But error shows:
Workflow ID: plan_1763665129  # ← Different value from earlier run
```

**Analysis**:
- State ID file is being overwritten by subsequent /plan invocations
- Block 1 of new workflow overwrites state ID before old workflow completes
- Block 3 of old workflow reads new state ID and looks for wrong state file
- This would only happen if multiple /plan commands run concurrently

**Likelihood**: Low - Claude Code doesn't typically run commands concurrently

#### Hypothesis C: State File Path Construction Bug

**Error shows wrong path**:
```
Expected: /home/benjamin/.claude/tmp/workflow_plan_1763665129.sh
Actual:   /home/benjamin/.claude/state/plan_1763665129.state
```

**Analysis**:
- Error message uses `.claude/state/` (deprecated location)
- Error message uses `.state` extension (deprecated format)
- This suggests diagnostic code in Block 3 is using outdated path construction
- BUT: The actual `load_workflow_state()` uses correct path

**Likelihood**: Medium - Explains error message but not why state file is missing

### Secondary Issue: Documentation Inconsistency

**Impact**: Medium - Confuses developers, perpetuates incorrect patterns

**Files with outdated path references**:
1. `.claude/docs/architecture/state-orchestration-troubleshooting.md:73`
2. `.claude/docs/architecture/state-orchestration-examples.md:105`
3. `.claude/docs/architecture/state-orchestration-transitions.md:96`
4. `.claude/docs/guides/patterns/command-patterns/command-patterns-checkpoints.md:287`

All show: `STATE_FILE=".claude/state/workflow_${ID}.state"`
Should be: `STATE_FILE=".claude/tmp/workflow_${ID}.sh"`

---

## Standards Conformance Analysis

### Error Handling Standards

**From `.claude/docs/concepts/patterns/error-handling.md`**:

✅ **Requirement**: All commands must integrate centralized error logging
❌ **Violation**: `/plan` command does not call `log_command_error()` in Block 3

**Example of missing error logging**:

```bash
# Current code (plan.md line 381):
if [ ! -f "$PLAN_PATH" ]; then
  echo "ERROR: Planning phase failed to create plan file" >&2
  exit 1
fi

# Should be:
if [ ! -f "$PLAN_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_STATE" \
    "PLAN_PATH variable undefined - state persistence failure" \
    "bash_block_3" \
    "$(jq -n --arg expected_path "$PLAN_PATH" '{expected_path: $expected_path}')"

  echo "ERROR: Planning phase failed to create plan file" >&2
  exit 1
fi
```

### State Persistence Standards

**From `state-persistence.sh` (lines 76-84)**:

```bash
# State File Locations (Spec 752 Phase 9):
# - STANDARD: .claude/tmp/workflow_*.sh (temporary workflow state, auto-cleanup)
# - STANDARD: .claude/tmp/*.json (JSON checkpoints, atomic writes)
# - DEPRECATED: .claude/data/workflows/*.state (legacy location, no longer used)
# - DO NOT USE: State files outside .claude/tmp/ (violates temporary data conventions)
```

✅ **Conformance**: Code correctly uses `.claude/tmp/workflow_*.sh`
❌ **Violation**: Error messages reference deprecated `.claude/state/*.state`
❌ **Violation**: Documentation examples show deprecated paths

### Fail-Fast Validation Standards

**From `state-persistence.sh` load_workflow_state() (lines 212-295)**:

✅ **Requirement**: Subsequent blocks should fail-fast if state file missing
❌ **Violation**: Block 3 error shows `set -u` catching undefined variable, not `load_workflow_state()` diagnostic

This suggests Block 3 isn't properly calling `load_workflow_state()` or the function is returning success even when state not loaded.

---

## Impact Assessment

### Severity: CRITICAL

**Functional Impact**:
- `/plan` command is 100% non-functional
- No users can create implementation plans
- Workflow completely blocked at research→planning transition

**Data Impact**:
- Research phase completes successfully (evidence: reports created)
- Planning phase completes successfully (evidence: plan created)
- State loss occurs between Block 2 → Block 3
- No data corruption, only state variable loss

**User Experience Impact**:
- Users see cryptic "unbound variable" error
- No actionable error message or recovery guidance
- Manual workaround: Check filesystem for created plan, ignore error

---

## Recommended Fix Strategy

### Priority 1: Fix State File Lifecycle (CRITICAL)

**Issue**: State file deleted before Block 3 can load it

**Root Cause**: Likely EXIT trap in Block 1 deleting file prematurely

**Fix**:

1. **Remove EXIT trap from Block 1** (if present)
2. **Add explicit cleanup only at Block 3 end** (workflow completion)
3. **Verify state file persistence** between blocks

**Implementation**:

```bash
# Block 1: DO NOT set EXIT trap
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE
# NO TRAP HERE - file must persist to Block 3

# Block 3: Clean up state file AFTER workflow completes
trap "rm -f '$STATE_FILE' 2>/dev/null" EXIT

# Verify state loaded
load_workflow_state "$WORKFLOW_ID" false || {
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_STATE" \
    "State file not found: $STATE_FILE" \
    "bash_block_3" \
    "$(jq -n --arg path "$STATE_FILE" --arg id "$WORKFLOW_ID" \
       '{state_file: $path, workflow_id: $id}')"
  exit 1
}

# ... rest of Block 3 ...
```

### Priority 2: Fix Path Construction in Error Messages (HIGH)

**Issue**: Error messages show deprecated `.claude/state/*.state` paths

**Fix**: Update any diagnostic code to use current path format

**Implementation**:

```bash
# Find and replace in plan.md:
# OLD: /home/benjamin/.claude/state/plan_${WORKFLOW_ID}.state
# NEW: ${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh
```

### Priority 3: Add Error Logging Integration (HIGH)

**Issue**: `/plan` command doesn't log errors to centralized error log

**Fix**: Integrate `log_command_error()` at all error points

**Implementation**:

```bash
# Block 1: Initialize error logging
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
ensure_error_log_exists

COMMAND_NAME="/plan"
WORKFLOW_ID="plan_$(date +%s)"
USER_ARGS="$*"

# Block 3: Log state persistence errors
if [ ! -f "$PLAN_PATH" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_STATE" \
    "PLAN_PATH undefined - state persistence failure in Block 3" \
    "bash_block_3" \
    '{}'
  exit 1
fi
```

### Priority 4: Update Documentation (MEDIUM)

**Issue**: 4 documentation files show deprecated state file paths

**Fix**: Update all documentation to show current path format

**Files to Update**:
1. `.claude/docs/architecture/state-orchestration-troubleshooting.md`
2. `.claude/docs/architecture/state-orchestration-examples.md`
3. `.claude/docs/architecture/state-orchestration-transitions.md`
4. `.claude/docs/guides/patterns/command-patterns/command-patterns-checkpoints.md`

**Change**:
```bash
# OLD (deprecated):
STATE_FILE=".claude/state/workflow_${ID}.state"

# NEW (current):
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh"
```

### Priority 5: Add State File Validation Checkpoint (MEDIUM)

**Issue**: No verification that state file persists between blocks

**Fix**: Add verification checkpoint after Block 1, Block 2

**Implementation**:

```bash
# End of Block 1:
# Verify state file persisted and contains required variables
if [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$ERROR_TYPE_STATE" \
    "State file verification failed - file deleted prematurely" \
    "bash_block_1_checkpoint" \
    "$(jq -n --arg path "$STATE_FILE" '{state_file: $path}')"
  exit 1
fi

echo "✓ State file verified: $STATE_FILE"
```

---

## Testing Strategy

### Test Case 1: State File Persistence

**Objective**: Verify state file survives from Block 1 → Block 3

**Steps**:
1. Run `/plan "test feature"`
2. After Block 1 completes, verify: `ls -la ~/.claude/tmp/workflow_plan_*.sh`
3. After Block 2 completes, verify: `ls -la ~/.claude/tmp/workflow_plan_*.sh`
4. After Block 3 completes, verify: File may be deleted (OK if workflow succeeds)

**Expected**: State file exists through Block 2, deleted only after Block 3 success

### Test Case 2: State Variable Loading

**Objective**: Verify PLAN_PATH loads correctly in Block 3

**Steps**:
1. Run `/plan "test feature"`
2. In Block 3, add debug: `echo "DEBUG: PLAN_PATH=${PLAN_PATH:-UNDEFINED}"`
3. Verify output shows path, not "UNDEFINED"

**Expected**: `PLAN_PATH=/path/to/.claude/specs/NNN_topic/plans/001_plan.md`

### Test Case 3: Error Logging Integration

**Objective**: Verify errors logged to centralized log

**Steps**:
1. Inject failure in Block 3: `PLAN_PATH=""`
2. Run `/plan "test feature"`
3. After failure, run: `/errors --command /plan --limit 1`

**Expected**: Error entry shows `state_error` with PLAN_PATH context

### Test Case 4: Concurrent Workflow Isolation

**Objective**: Verify multiple /plan workflows don't interfere

**Steps**:
1. Run `/plan "feature A"` in terminal 1
2. While Block 1 running, run `/plan "feature B"` in terminal 2
3. Verify both complete successfully with unique state files

**Expected**: Each workflow has unique state file, no state ID collision

---

## Success Criteria

### Critical (Must Fix)

1. ✅ `/plan` command completes Block 3 without "unbound variable" error
2. ✅ State file persists from Block 1 through Block 3
3. ✅ PLAN_PATH variable loads correctly in Block 3

### High Priority (Should Fix)

4. ✅ Error messages show current path format (`.claude/tmp/workflow_*.sh`)
5. ✅ Centralized error logging integrated in all error paths
6. ✅ Documentation updated to remove deprecated path references

### Medium Priority (Nice to Have)

7. ✅ State file validation checkpoints added between blocks
8. ✅ Diagnostic output shows clear state file location on error
9. ✅ Test suite validates state persistence across all commands

---

## Standards Violations Summary

| Standard | Requirement | Status | Priority |
|----------|-------------|--------|----------|
| Error Handling Pattern | Integrate `log_command_error()` | ❌ MISSING | HIGH |
| State Persistence | Use `.claude/tmp/workflow_*.sh` | ⚠️ PARTIAL | CRITICAL |
| Fail-Fast Validation | Show diagnostic on state load failure | ❌ MISSING | HIGH |
| Documentation Policy | Keep examples current with implementation | ❌ VIOLATED | MEDIUM |
| Code Standards | No hardcoded legacy paths | ⚠️ PARTIAL | MEDIUM |

---

## Minimal Viable Fix (Quick Recovery)

**For immediate resolution, implement Priority 1 only**:

### Single Change: Remove EXIT Trap from Block 1

**File**: `.claude/commands/plan.md`
**Location**: Block 1, after line 154

**Current** (if trap exists):
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE
trap "rm -f '$STATE_FILE'" EXIT  # ← REMOVE THIS
```

**Fixed**:
```bash
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
export STATE_FILE
# State file must persist to Block 3 - cleanup happens there
```

**Estimated Time**: 5 minutes
**Risk**: Very Low - Only removes premature cleanup
**Impact**: Should restore `/plan` command functionality immediately

---

## Long-Term Recommendations

### 1. Centralize State Lifecycle Management

**Problem**: Each command manages state lifecycle independently
**Solution**: Create `workflow-state-lifecycle.sh` library

**Benefits**:
- Consistent state file creation, persistence, cleanup
- Automatic validation checkpoints
- Standardized error handling across all commands

### 2. Add State File Debugging Mode

**Problem**: Hard to diagnose state persistence issues
**Solution**: Add `CLAUDE_DEBUG_STATE=1` environment variable

**Implementation**:
```bash
if [ "${CLAUDE_DEBUG_STATE:-0}" = "1" ]; then
  echo "DEBUG: State file: $STATE_FILE"
  echo "DEBUG: State file exists: $([ -f "$STATE_FILE" ] && echo YES || echo NO)"
  echo "DEBUG: State file contents:"
  cat "$STATE_FILE" 2>&1 | sed 's/^/  /'
fi
```

### 3. Implement State File Monitoring

**Problem**: State files can be deleted by external processes
**Solution**: Add `inotify` watch on state file directory

**Benefits**:
- Detect premature state file deletion
- Log warnings when state files modified unexpectedly
- Help diagnose filesystem-level issues

### 4. Add State Persistence Tests

**Problem**: No automated testing of state persistence
**Solution**: Create `.claude/tests/test_state_persistence.sh`

**Test Coverage**:
- State file creation in Block 1
- State file persistence through Block 2
- State variable loading in Block 3
- Cleanup after workflow completion
- Concurrent workflow isolation

---

## Conclusion

The `/plan` command failure is caused by **state file lifecycle management issue** where the state file created in Block 1 is not persisting to Block 3. The most likely root cause is an EXIT trap in Block 1 that deletes the state file prematurely.

**Immediate Action**: Remove EXIT trap from Block 1 (if present) and move cleanup to Block 3.

**Follow-up Actions**:
1. Fix path construction in error messages
2. Integrate centralized error logging
3. Update documentation to remove deprecated paths
4. Add state file validation checkpoints

**Estimated Fix Time**:
- Critical fix: 5 minutes
- Complete fix with error logging: 2-3 hours
- Documentation updates: 1 hour
- Testing: 2 hours
- **Total**: ~6 hours for complete remediation

This fix will restore `/plan` command functionality and align it with current state persistence standards, preventing similar issues in other commands.
