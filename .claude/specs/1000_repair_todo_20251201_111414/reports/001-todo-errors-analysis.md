# /todo Command Error Analysis Report

**Report ID**: 001-todo-errors-analysis
**Workflow**: /todo errors repair
**Analysis Date**: 2025-12-01
**Complexity**: 2 (Moderate)

---

## Executive Summary

The `/todo` command fails during Block 2a (Status Classification Setup) with repeated **"ERROR: STATE_FILE not set. Call init_workflow_state first."** errors followed by exit code 141. Root cause analysis reveals a critical **state persistence initialization failure** where:

1. Block 1 completes successfully and sets `WORKFLOW_ID`
2. Block 2a sources `state-persistence.sh` **without calling `init_workflow_state()`** before attempting `append_workflow_state()`
3. The `append_workflow_state()` function fails because `STATE_FILE` variable is never initialized
4. Exit code 141 indicates subprocess signaled termination

The fix requires implementing proper state initialization protocol in Block 2a before any state persistence operations.

---

## Error Analysis

### Error Manifestations

**Primary Error Message** (4 occurrences):
```
ERROR: STATE_FILE not set. Call init_workflow_state first.
```

**Context**:
- Occurs in Block 2a - Status Classification Setup
- Triggered by `append_workflow_state()` function calls
- Followed by exit code 141 (subprocess killed by signal 13 = SIGPIPE)

### Root Cause Analysis

#### Issue 1: Missing State Initialization in Block 2a

**Location**: `.claude/commands/todo.md`, Block 2a, lines 322-327

```bash
# === PERSIST VARIABLES ===
# Persist variables for Block 2c verification
append_workflow_state "DISCOVERED_PROJECTS" "$DISCOVERED_PROJECTS"
append_workflow_state "CLASSIFIED_RESULTS" "$CLASSIFIED_RESULTS"
append_workflow_state "SPECS_ROOT" "$SPECS_ROOT"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
```

**Problem**: These `append_workflow_state()` calls are invoked in a new bash subprocess (Block 2a) without first initializing the state file. Block 1 creates variables but **does not persist them** because `/todo` is a utility command.

#### Issue 2: Library Sourcing Order Violation

**Location**: `.claude/commands/todo.md`, Block 2a, lines 301-310

The command correctly sources `state-persistence.sh` but **does not call the initialization function** before using its state persistence operations.

**Proper Three-Tier Pattern**:
1. Source core libraries (error-handling.sh, state-persistence.sh)
2. **Call init_workflow_state() to initialize STATE_FILE**
3. Use append_workflow_state(), load_workflow_state(), etc.

**Current Pattern**:
1. Source core libraries
2. **Skip init_workflow_state()**
3. Call append_workflow_state() → **FAILURE** (STATE_FILE not set)

#### Issue 3: Design Mismatch - Utility Command State Handling

**Location**: `.claude/commands/todo.md`, lines 265-268

```bash
# === NOTE: /todo is a utility command ===
# Utility commands do NOT use the research state machine (sm_init/sm_transition)
# State machine is for research workflows: research-only, research-and-plan, full-implementation
# Error handling is already configured via setup_bash_error_trap above
```

The comment acknowledges that `/todo` is a utility command and doesn't use state machine. However, **the implementation still attempts to use state persistence** (append_workflow_state) without properly initializing it.

---

## State Persistence Library Reference

### state-persistence.sh Functions

**`init_workflow_state()`** (lines 146-185):
- Creates workflow state file at `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${workflow_id}.sh`
- **Initializes STATE_FILE variable**
- Must be called before any append/load operations

**`append_workflow_state()`** (lines 398-413):
- Appends key-value pairs to workflow state file
- **REQUIRES STATE_FILE to be set**
- Returns exit code 1 if STATE_FILE is unset (line 402-404)

```bash
append_workflow_state() {
  local key="$1"
  local value="$2"

  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set. Call init_workflow_state first." >&2
    return 1
  fi
  # ... rest of function
}
```

### Why STATE_FILE is Not Set

In Block 2a (new bash subprocess):
1. `WORKFLOW_ID` is passed from Block 1 output but **not exported**
2. `STATE_FILE` is never set in Block 2a's environment
3. `init_workflow_state()` is never called to create it
4. `append_workflow_state()` checks `[ -z "${STATE_FILE:-}" ]` → TRUE → ERROR

---

## Current Error Flow

```
Block 1 (Success)
  ├─ CLAUDE_PROJECT_DIR detected ✓
  ├─ Libraries sourced ✓
  ├─ Error trap configured ✓
  ├─ init_workflow_state() called ✓
  ├─ WORKFLOW_ID created: "todo_1764616157" ✓
  └─ Output: WORKFLOW_ID=todo_1764616157

Block 2a (FAILURE)
  ├─ New bash subprocess starts
  ├─ Detects CLAUDE_PROJECT_DIR ✓
  ├─ Sources state-persistence.sh ✓
  ├─ WORKFLOW_ID from previous block → shell variable (lost)
  ├─ STATE_FILE not set (never initialized) ✗
  ├─ Calls: append_workflow_state "DISCOVERED_PROJECTS" ...
  │   └─ Function checks: [ -z "${STATE_FILE:-}" ]
  │   └─ Result: TRUE → Print error → Return 1
  └─ Exit code 141 (SIGPIPE from error output)
```

---

## Why Exit Code 141?

Exit code 141 is **128 + 13 = SIGPIPE (Broken Pipe Signal)**.

Occurs when:
1. `append_workflow_state()` fails and writes to stderr
2. Process chain breaks due to `set -e` (fail-fast) enforcement
3. Signal handler or pipe closure triggers SIGPIPE

The actual issue is the unset STATE_FILE, but the exit code masks it under a signal error.

---

## Solution Overview

### Fix Strategy

**Option A (Recommended): Initialize State in Block 2a**
- Call `init_workflow_state()` at start of Block 2a
- Use the previously created state file from Block 1
- Properly export WORKFLOW_ID between blocks

**Option B: Skip State Persistence in Utility Commands**
- Remove all `append_workflow_state()` calls from `/todo`
- Use temporary file coordination instead
- Simpler for utility commands that don't need cross-block state

### Recommended Approach: Option A

Modify Block 2a to properly initialize state:

1. Pass WORKFLOW_ID from Block 1 to Block 2a (already done via output)
2. Call `init_workflow_state("todo_${WORKFLOW_ID}")` in Block 2a
3. This recreates the state file in current subprocess
4. State persistence operations now work correctly

---

## Detailed Fix Specifications

### Block 2a Modifications

**Location**: `.claude/commands/todo.md` lines 282-335

**Change 1: Add State Initialization**

Insert after library sourcing (after line 310):

```bash
# === INITIALIZE WORKFLOW STATE ===
# Regenerate state file in this subprocess using WORKFLOW_ID from Block 1
# The state file was created in Block 1 but is not accessible here (subprocess isolation)
# We recreate it with the same WORKFLOW_ID to maintain continuity
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Verify state file creation
if [ ! -f "$STATE_FILE" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "Failed to initialize state file: $STATE_FILE" \
    "Block2a:StateInit" \
    '{"workflow_id":"'"$WORKFLOW_ID"'"}'
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

**Change 2: Set Error Logging Context**

Insert before `append_workflow_state()` calls (add after state initialization):

```bash
# === SET ERROR LOGGING CONTEXT ===
COMMAND_NAME="/todo"
USER_ARGS="$([ "$CLEAN_MODE" = "true" ] && echo "--clean")$([ "$DRY_RUN" = "true" ] && echo " --dry-run")"
export COMMAND_NAME USER_ARGS WORKFLOW_ID STATE_FILE
```

**Change 3: Export State Variables**

Modify the export statements to ensure persistence:

```bash
# === PERSIST VARIABLES ===
# Persist variables for Block 2c verification
append_workflow_state "DISCOVERED_PROJECTS" "$DISCOVERED_PROJECTS"
append_workflow_state "CLASSIFIED_RESULTS" "$CLASSIFIED_RESULTS"
append_workflow_state "SPECS_ROOT" "$SPECS_ROOT"
append_workflow_state "WORKFLOW_ID" "$WORKFLOW_ID"
append_workflow_state "COMMAND_NAME" "$COMMAND_NAME"
append_workflow_state "USER_ARGS" "$USER_ARGS"
append_workflow_state "CLEAN_MODE" "$CLEAN_MODE"
append_workflow_state "DRY_RUN" "$DRY_RUN"
```

### Block 1 Modifications (Optional but Recommended)

**Location**: `.claude/commands/todo.md` lines 119-278

**Change: Initialize State in Block 1**

Add after library sourcing (after line 202):

```bash
# === INITIALIZE WORKFLOW STATE ===
# Initialize state file for cross-block persistence
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")

# Set cleanup trap for state file
trap "rm -f '$STATE_FILE' 2>/dev/null" EXIT

# Verify state file
if [ ! -f "$STATE_FILE" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "Failed to initialize state file: $STATE_FILE" \
    "Block1:StateInit" \
    '{"workflow_id":"'"$WORKFLOW_ID"'"}'
  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi

# Export for subprocesses
export STATE_FILE
```

This ensures the state file exists in a persistent location that Block 2a can access.

---

## Testing Strategy

### Test Case 1: Basic /todo Execution

```bash
# Execute /todo without flags
/todo

# Expected behavior:
# - Block 1 completes successfully
# - Block 2a initializes state correctly
# - append_workflow_state() calls succeed
# - todo-analyzer invocation proceeds
# - Block 2c verification completes
# - TODO.md updated successfully

# Verification:
# - No "STATE_FILE not set" errors
# - No exit code 141
# - Exit code 0
# - TODO.md modified with current date
```

### Test Case 2: Clean Mode

```bash
# Execute /todo --clean
/todo --clean

# Expected behavior:
# - State initialization in Block 2a (same as Test Case 1)
# - Block 4a/4b cleanup logic executes
# - Eligible directories removed
# - Git commit created
# - TODO.md regenerated

# Verification:
# - No "STATE_FILE not set" errors
# - Completion output shows removal count
# - Git log shows cleanup commit
```

### Test Case 3: Dry-Run Preview

```bash
# Execute /todo --dry-run
/todo --dry-run

# Expected behavior:
# - State initialization works (same pattern)
# - Classification completes
# - TODO.md changes shown but not written
# - No git operations

# Verification:
# - Preview output displayed
# - No file modifications
# - No git commits
```

### Test Case 4: State File Verification

```bash
# During Block 2a, verify state file exists:
# - Location: /home/benjamin/.config/.claude/tmp/workflow_todo_1764616157.sh
# - Content includes all appended variables
# - File readable by Block 2c

# Verification:
ls -la /home/benjamin/.config/.claude/tmp/workflow_todo_*.sh
cat /home/benjamin/.config/.claude/tmp/workflow_todo_*.sh
```

---

## Implementation Checklist

- [ ] Modify Block 2a to call `init_workflow_state()` after library sourcing
- [ ] Add STATE_FILE export to Block 2a
- [ ] Verify append_workflow_state() calls in Block 2a
- [ ] Add state verification checks in Block 2a
- [ ] Update Block 1 to initialize state (recommended)
- [ ] Add EXIT trap in Block 1 for state cleanup (recommended)
- [ ] Test /todo execution without flags
- [ ] Test /todo --clean mode
- [ ] Test /todo --dry-run mode
- [ ] Verify state file persistence between blocks
- [ ] Confirm exit code 0 on successful completion

---

## References

### Library Documentation
- **state-persistence.sh**: Version 1.6.0 (lines 1-185 for init_workflow_state)
- **append_workflow_state()**: Lines 398-413 (error check at line 402)

### Command Documentation
- **todo.md**: Block 1 (lines 119-278), Block 2a (lines 280-335)
- **Lines 265-268**: Design note about utility command state handling

### State File Location
- **Pattern**: `${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh`
- **Example**: `/home/benjamin/.config/.claude/tmp/workflow_todo_1764616157.sh`
- **Lifespan**: Per-workflow (auto-cleaned via EXIT trap)

### Related Standards
- Three-Tier Library Sourcing Pattern: `.claude/docs/reference/standards/code-standards.md`
- State Persistence Architecture: `.claude/docs/concepts/patterns/state-persistence.md`
- Fail-Fast Error Handling: `.claude/docs/concepts/patterns/error-handling.md`

---

## Impact Assessment

### Severity: CRITICAL

- **Frequency**: Every /todo invocation fails at Block 2a
- **User Impact**: TODO.md never updates; cleanup feature non-functional
- **Recovery**: Manual /todo command retries, but systematic failure persists
- **Workaround**: None (core functionality broken)

### Affected Components

1. **Direct Impact**:
   - `/todo` command (all modes: default, --clean, --dry-run)
   - Block 2a state persistence operations
   - Cross-block variable sharing

2. **Indirect Impact**:
   - Dependent commands that rely on TODO.md (any command reading project status)
   - Cleanup workflow (cannot remove completed projects)
   - Error logging chain (if commands read TODO.md state)

### Fix Priority: P0 (Critical)

**Effort**: Moderate (code modification in one block + testing)
**Risk**: Low (isolated to state initialization, well-scoped)
**Validation**: Unit test (state file creation) + integration test (/todo execution)

---

## Prevention Guidelines

### For Future Command Development

1. **Always initialize state in Block 1** before any state operations
2. **Explicitly export STATE_FILE** to subprocesses
3. **Document state initialization** in block comments
4. **Test state persistence** across block boundaries
5. **Use load_workflow_state()** with proper validation in subsequent blocks

### Code Review Checklist

- [ ] Does command use `append_workflow_state()` or `load_workflow_state()`?
- [ ] Is `init_workflow_state()` called before first state operation?
- [ ] Is STATE_FILE exported in bash `set` declarations?
- [ ] Are required variables validated after state load?
- [ ] Does EXIT trap clean up state files?

---

## Conclusion

The `/todo` command fails due to missing state initialization in Block 2a. The `append_workflow_state()` function requires STATE_FILE to be set, but it's never initialized in the subprocess context. Implementing proper initialization (calling `init_workflow_state()` with the workflow ID from Block 1) will resolve all 4 error occurrences and restore full /todo functionality.

The fix is straightforward, low-risk, and aligns with established state-persistence library patterns used throughout the codebase.

