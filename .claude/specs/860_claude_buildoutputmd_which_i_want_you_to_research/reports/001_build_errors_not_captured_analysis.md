# Build Errors Not Captured by /errors Command - Root Cause Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Build command error logging gap analysis
- **Report Type**: Root cause analysis

## Executive Summary

The /build command encountered a state machine error ("ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete") that was not captured by the /errors command. This occurred because the error happened in Block 4 of the build command (lines 1024-1025 in `/home/benjamin/.config/.claude/commands/build.md`) and the command exited with `exit 1` before calling `log_command_error`. The root cause is that **validation errors written directly to stderr with `echo` statements are not automatically logged** - only errors explicitly logged via `log_command_error()` function calls appear in the queryable error log.

## Findings

### 1. Error That Occurred

**Location**: `/home/benjamin/.config/.claude/commands/build.md`, Block 4, lines 1013-1025

The build command encountered this error:
```
ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete (see /home/benjamin/.claude/tmp/workflow_debug.log)
```

**Error Context** (from build-output.md lines 54-58):
- Command was in the workflow completion phase (Block 4)
- State machine detected that CURRENT_STATE was still "implement"
- Expected state transitions through "test" and "document/debug" phases had not occurred
- Detailed diagnostics were written to workflow_debug.log
- Command exited with code 1

### 2. Why Error Was Not Captured

**Analysis of build.md Block 4** (lines 1011-1026):

```bash
implement)
  {
    echo "[$(date)] ERROR: Invalid predecessor state for completion"
    echo "WHICH: sm_transition to complete"
    echo "WHAT: Cannot transition to complete from implement state - Blocks 2 and 3 did not execute"
    echo "WHERE: Block 4, workflow completion"
    echo "CURRENT_STATE: $CURRENT_STATE"
    echo ""
    echo "TROUBLESHOOTING:"
    echo "1. Check Block 2 for errors (testing phase)"
    echo "2. Check Block 3 for errors (debug/document phase)"
    echo "3. Verify state file contains expected transitions"
  } >> "$DEBUG_LOG"
  echo "ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete (see $DEBUG_LOG)" >&2
  exit 
  ;;
```

**Problem Identified**: The error handling code:
1. Writes detailed diagnostics to DEBUG_LOG file
2. Echoes user-facing error message to stderr
3. **Exits immediately without calling `log_command_error()`**

**Comparison with Other Error Paths**: Looking at lines 221-232 in build.md (Block 1 state file validation):

```bash
if [ -z "$STATE_FILE" ] || [ ! -f "$STATE_FILE" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "state_error" \
    "Failed to initialize workflow state file" \
    "bash_block_1" \
    "$(jq -n --arg path "${STATE_FILE:-UNDEFINED}" '{expected_path: $path}')"

  echo "ERROR: Failed to initialize workflow state" >&2
  exit 1
fi
```

**Key Difference**: Earlier blocks (1, 2, 3) call `log_command_error()` before echoing to stderr and exiting, but **Block 4's predecessor state validation does NOT** call `log_command_error()` before exiting.

### 3. Error Logging System Architecture

**Central Error Log**: `/home/benjamin/.config/.claude/data/logs/errors.jsonl`

**Logging Function**: `log_command_error()` in `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 410-506)

**How Errors Are Logged**:
1. Commands must explicitly call `log_command_error()` with parameters:
   - command name (e.g., "/build")
   - workflow_id
   - user_args
   - error_type (state_error, validation_error, agent_error, etc.)
   - message
   - source (e.g., "bash_block_4")
   - context JSON

2. The function writes JSONL entry to errors.jsonl
3. The /errors command queries this file using `query_errors()` function

**Current Status**: Error log file exists at `/home/benjamin/.config/.claude/data/logs/errors.jsonl` and contains 1 entry (a manual test entry), confirming the logging infrastructure is functional.

### 4. Gap Analysis: Missing Error Logging Calls

**Search Results**: build.md contains 18 `log_command_error` calls (per grep output), but none are in the Block 4 predecessor state validation section (lines 990-1045).

**Affected Code Paths** in build.md Block 4:
- Line 1008: "test" state predecessor check - NO log_command_error
- Line 1024: "implement" state predecessor check - NO log_command_error
- Line 1039: unknown state predecessor check - NO log_command_error

**Pattern Observed**:
- Blocks 1-3: Error paths include both `log_command_error()` AND debug log writes
- Block 4: Error paths ONLY write to debug log, skip centralized error logging

### 5. Additional Context Issues

**History Expansion Error** (build-output.md line 46):
```
/run/current-system/sw/bin/bash: line 293: !: command not found
```

This indicates bash history expansion was active despite `set +H` at block start. However:
- This is a **warning**, not an error
- It did not cause the workflow failure
- It appears in output but doesn't trigger error logging (correct behavior for warnings)

**State File Issue** (build-output.md lines 70-77):
```bash
● Bash(cat /home/benjamin/.claude/data/states/build_1763675699.txt 2>/dev/null | tail -20)
  ⎿  (No content)
```

The state file was expected but empty/missing, which is why Block 4's predecessor validation failed. However, this **symptom** (missing state file) was detected by the validation logic, but the validation logic itself failed to log the error before exiting.

## Recommendations

### 1. Add Missing Error Logging Calls in Block 4

**Action**: Update `/home/benjamin/.config/.claude/commands/build.md` Block 4 (lines 990-1045) to include `log_command_error()` calls before each `exit 1`.

**Pattern to Follow** (from Block 1):
```bash
case "$CURRENT_STATE" in
  implement)
    # Log error FIRST
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "state_error" \
      "Invalid predecessor state - Blocks 2 and 3 did not complete" \
      "bash_block_4" \
      "$(jq -n --arg state "$CURRENT_STATE" '{current_state: $state}')"

    # THEN write debug log
    {
      echo "[$(date)] ERROR: Invalid predecessor state for completion"
      # ... rest of debug output
    } >> "$DEBUG_LOG"

    # THEN user message and exit
    echo "ERROR: Invalid predecessor state - Blocks 2 and 3 did not complete (see $DEBUG_LOG)" >&2
    exit 1
    ;;
esac
```

**Files Affected**:
- `/home/benjamin/.config/.claude/commands/build.md` lines 997-1008 (test state case)
- `/home/benjamin/.config/.claude/commands/build.md` lines 1013-1025 (implement state case)
- `/home/benjamin/.config/.claude/commands/build.md` lines 1028-1039 (default case)

### 2. Audit All Commands for Similar Gaps

**Action**: Search all command files for error exit paths that bypass `log_command_error()`.

**Pattern to Detect**:
```bash
grep -r "exit 1" .claude/commands/*.md | grep -v "log_command_error"
```

**Commands to Audit**:
- /plan
- /debug
- /research
- /revise
- /repair
- /errors (verify it handles empty log gracefully)

**Expected**: Any `exit 1` after `echo "ERROR:"` should be preceded by `log_command_error()`.

### 3. Add Error Logging Standards Enforcement

**Action**: Update `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` to explicitly require:

```markdown
## Error Handling Requirements

All command error exits MUST follow this sequence:

1. Call log_command_error() with complete context
2. Write detailed diagnostics to DEBUG_LOG (optional)
3. Echo user-facing error message to stderr
4. Exit with non-zero code

Example:
```bash
if [ error_condition ]; then
  # 1. Log to centralized error log
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "error_type" "error message" "source" '{"context": "json"}'

  # 2. Detailed diagnostics (optional)
  { echo "Details..." } >> "$DEBUG_LOG"

  # 3. User message
  echo "ERROR: Summary (see $DEBUG_LOG)" >&2

  # 4. Exit
  exit 1
fi
```

**Anti-Pattern** (DO NOT DO THIS):
```bash
# Missing log_command_error call
echo "ERROR: Something failed" >&2
exit 1
```
```

### 4. Create Compliance Test

**Action**: Create `/home/benjamin/.config/.claude/tests/test_error_logging_compliance.sh` to verify all commands properly log errors.

**Test Logic**:
1. Parse each command file for `exit 1` statements
2. Verify each has corresponding `log_command_error` call in same code block
3. Flag violations for manual review

**Success Criteria**: All error exits in commands have error logging.

### 5. Document Error Logging in Command Development Guide

**Action**: Update `/home/benjamin/.config/.claude/docs/guides/development/command-development/command-development-fundamentals.md` to include error logging as a core requirement.

**Section to Add**:
```markdown
## Error Logging Integration

Every command MUST integrate centralized error logging:

1. Source error-handling library in Block 1
2. Initialize error log with ensure_error_log_exists
3. Set COMMAND_NAME and USER_ARGS for context
4. Call log_command_error() before EVERY error exit

See: .claude/docs/concepts/patterns/error-handling.md
```

## References

### Primary Files Analyzed
- `/home/benjamin/.config/.claude/build-output.md` (lines 1-111) - Build command execution output showing error
- `/home/benjamin/.config/.claude/commands/build.md` (lines 1-300, focused on 83, 221-232, 990-1045) - Build command implementation
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` (lines 1-1262, focused on 410-506, 586-595) - Error logging infrastructure
- `/home/benjamin/.config/.claude/commands/errors.md` (lines 1-256) - Error query command implementation
- `/home/benjamin/.config/.claude/data/logs/errors.jsonl` - Centralized error log (currently 1 entry)

### Supporting Analysis
- Grep results showing 18 `log_command_error` calls in build.md, none in Block 4 validation
- State machine error pattern from `/home/benjamin/.config/.claude/specs/790_fix_state_machine_transition_error_build_command/`
- Error handling pattern documentation expectations

### Error Types Referenced
- `state_error` - Workflow state persistence/validation issues (lines 369 in error-handling.sh)
- `validation_error` - Input validation failures (line 370)
- Other types: `agent_error`, `parse_error`, `file_error`, `timeout_error`, `execution_error` (lines 371-376)
