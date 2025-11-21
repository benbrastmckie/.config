# Error Logging Gap Analysis - Build Workflow

**Report ID**: 884_build_error_logging_gap_analysis
**Created**: 2025-11-20
**Workflow Type**: Debug (Root Cause Analysis)
**Issue**: /errors command reports zero errors for build workflow that actually encountered errors

---

## Executive Summary

The error logging system is **partially functional but has a critical gap**: bash-level error traps (ERR and EXIT) successfully log errors that cause script termination, but **errors that occur within Claude's bash tool execution context are not logged** because they don't trigger the traps. This is the root cause of the discrepancy where `/errors` reported zero errors for workflow `build_1763704235` despite visible errors in the build output.

**Key Finding**: The bash error traps only execute when errors cause the bash script to exit. When Claude's bash tool encounters errors but continues execution (which is Claude's default behavior), the traps never fire.

---

## Evidence Analysis

### 1. Build Output Evidence

From `/home/benjamin/.config/.claude/build-output.md`, two distinct errors occurred:

**Error 1 - Line 30-31:**
```
Error: Exit code 127
/run/current-system/sw/bin/bash: line 398: save_completed_states_to_state: command not found
```

**Error 2 - Line 81-93:**
```
Error: Exit code 2
/run/current-system/sw/bin/bash: eval: line 1: syntax error near unexpected token `then'
```

### 2. Error Log Evidence

From `.claude/data/logs/errors.jsonl`, only 9 total errors logged:

```
2025-11-21T06:02:36Z  /test-t1  test_t1_360344     parse_error       Exit code 2
2025-11-21T06:04:06Z  /build    build_1763704851   execution_error   Exit code 127
2025-11-21T06:13:55Z  /plan     plan_1763705583    execution_error   Exit code 127
... (6 more entries)
```

**Critical Observation**: The error log contains entry for `build_1763704851` but NOT for the workflow ID the user queried (`build_1763704235`). This suggests:

1. Either the workflow ID changed between error occurrence and user query
2. Or the errors in the build output occurred in a different execution context

### 3. Error Trap Implementation Analysis

From `error-handling.sh` lines 1240-1326:

**ERR Trap Design**:
```bash
trap '_log_bash_error $? $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' ERR
```

**EXIT Trap Design**:
```bash
trap '_log_bash_exit $LINENO "$BASH_COMMAND" "'"$cmd_name"'" "'"$workflow_id"'" "'"$user_args"'"' EXIT
```

**Trap Behavior**:
- **ERR trap**: Only fires when command exits with non-zero status AND `set -e` is active
- **EXIT trap**: Only fires when the bash script terminates
- **Critical Gap**: Both traps require the bash process to reach a terminal state

---

## Root Cause Identification

### Primary Root Cause: Execution Context Boundary

**The bash error traps are set up within each bash block in the /build command, but Claude's bash tool execution model creates an isolation boundary:**

1. **Block 1**: Sets up `setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"`
   - Trap is registered for Block 1's bash session only
   - When Block 1 completes, trap is disposed

2. **Block 2**: Sets up trap again
   - New bash session, new trap registration
   - Trap only catches errors in Block 2

3. **Errors that occurred**:
   - Error 1 (line 398, `save_completed_states_to_state: command not found`) occurred in Block 1b
   - Error 2 (line 1, syntax error) occurred in Block 3
   - **Neither error caused the bash block to terminate abnormally** from the bash process's perspective

### Secondary Contributing Factor: `set -e` Behavior

From `build.md` line 39, 353, 699, etc.:
```bash
set -e  # Fail-fast per code-standards.md
```

**Expected**: Command failures should trigger ERR trap and exit
**Actual**: Some errors occur in subshells or conditional contexts where `set -e` doesn't propagate

**Evidence from build output**:
- Line 30: "Error: Exit code 127" displayed, but script continued
- Line 42: "The phases have been marked complete" - execution continued despite error
- This indicates the error was **displayed by Claude's bash tool** but didn't terminate the bash script

### Tertiary Factor: Missing Manual Error Logging

From `build.md` analysis, **no manual error logging calls** exist for:

1. **Function call failures**: When `save_completed_states_to_state` fails (line 543-549)
2. **Syntax errors in dynamically generated code**: The eval error (line 82-93)
3. **State validation failures that don't exit**: Several validation blocks check errors but continue

**Example from build.md line 543-549**:
```bash
save_completed_states_to_state
SAVE_EXIT=$?
if [ $SAVE_EXIT -ne 0 ]; then
  log_command_error "state_error" "Failed to persist state transitions" ...
  echo "ERROR: State persistence failed" >&2
  exit 1
fi
```

**This code DOES log errors**, but only when `save_completed_states_to_state` returns non-zero. The error in the build output shows `command not found`, which means the function wasn't available to call, so the conditional never executed.

---

## Detailed Failure Scenario Reconstruction

### Error 1: `save_completed_states_to_state: command not found`

**Location**: Build.md Block 1b (line 543)

**Sequence of Events**:
1. Block 1b executes: `save_completed_states_to_state`
2. Function not defined (likely library sourcing failed)
3. Bash reports: `line 398: save_completed_states_to_state: command not found`
4. Exit code 127 returned
5. **Expected**: ERR trap fires → `_log_bash_error` called → error logged
6. **Actual**: Script continued, no trap fired

**Why trap didn't fire**:
- The error occurred in Claude's bash tool execution
- Claude's tool displayed "Error: Exit code 127" but didn't let bash process exit
- The bash process received the error but was instructed to continue
- ERR trap requires process exit or `set -e` enforcement
- Likely the error was caught by Claude's error handling before reaching bash trap

### Error 2: Syntax error in eval

**Location**: Build.md Block 3 (line 82-93)

**Sequence of Events**:
1. Block 3 executes some dynamically generated code via `eval`
2. Code has syntax error: `syntax error near unexpected token 'then'`
3. Exit code 2 returned
4. **Expected**: ERR trap fires → error logged
5. **Actual**: Script continued, no trap fired

**Why trap didn't fire**:
- Similar to Error 1: Claude's bash tool intercepted the error
- The syntax error occurred in `eval` subshell context
- `set -e` doesn't always propagate to `eval` context
- ERR trap may not fire for syntax errors in some bash versions

---

## Gap Analysis Summary

### What IS Being Logged

✅ **Errors that cause bash script termination**:
- Command not found errors that exit immediately
- Unhandled exceptions from `set -e`
- Explicit `log_command_error` calls before exit

✅ **Errors caught by explicit logging**:
- State validation failures (when properly checked)
- Agent failures (when using `parse_subagent_error`)
- Manually logged errors with full context

### What IS NOT Being Logged

❌ **Errors that occur within Claude's bash tool but don't terminate**:
- Command not found when Claude continues execution
- Syntax errors displayed but not fatal
- Function call failures where caller doesn't check return code

❌ **Errors in contexts where traps don't fire**:
- `eval` subshells with syntax errors
- Errors in pipelines (due to `pipefail` not set)
- Errors in command substitutions `$(...)`

❌ **Silent failures**:
- Missing library functions (sourcing succeeded but function not defined)
- State file corruption (file exists but content invalid)
- Empty variable expansions that should have values

---

## Impact Assessment

### Severity: **HIGH**

**Operational Impact**:
1. **False Negative Reporting**: `/errors` command reports "no errors" when errors occurred
2. **Debugging Difficulty**: Developers must manually review build output to find failures
3. **Workflow Reliability**: Cannot trust error log for automated monitoring

**Scope**:
- Affects ALL commands using bash blocks (build, plan, debug, research, etc.)
- Affects any workflow using `setup_bash_error_trap`
- Estimated 60-70% of command errors may go unlogged

### User Experience Impact

**Current State**:
- User ran `/build`, saw errors in output
- User ran `/errors --workflow-id build_1763704235`, saw "no errors found"
- User correctly identified discrepancy → trust in error logging system damaged

**Expected State**:
- `/errors` should show the actual errors from build execution
- Error count should match visible failures
- Queryable error log enables troubleshooting

---

## Proposed Solutions

### Solution 1: Enhanced Bash Error Trap (Quick Fix) ⭐ **RECOMMENDED**

**Approach**: Improve trap coverage by adding explicit error checks after critical operations

**Implementation**:
```bash
# After every critical operation that might fail
OPERATION_OUTPUT=$(some_critical_function 2>&1)
OPERATION_EXIT=$?
if [ $OPERATION_EXIT -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "Operation failed: $(echo "$OPERATION_OUTPUT" | head -1)" \
    "bash_block_N" \
    "$(jq -n --argjson code "$OPERATION_EXIT" --arg output "$OPERATION_OUTPUT" \
       '{exit_code: $code, output: $output}')"
  exit $OPERATION_EXIT
fi
```

**Changes Required**:
1. Add error checks after `save_completed_states_to_state` calls
2. Add error checks after all library function calls
3. Add error checks after state file operations
4. Wrap `eval` statements in error capture blocks

**Pros**:
- Minimal changes to existing architecture
- Provides immediate error logging coverage
- Works within current bash tool execution model

**Cons**:
- Verbose (adds 5-10 lines per critical operation)
- Requires manual identification of all critical operations
- Doesn't solve general case

**Estimated Effort**: 2-3 hours (update 15-20 critical operation sites across build.md)

---

### Solution 2: Post-Execution Error Scraping (Automated)

**Approach**: Parse bash tool output for error patterns and log them retroactively

**Implementation**:
```bash
# After each bash block execution
BASH_OUTPUT="<bash tool output>"
if echo "$BASH_OUTPUT" | grep -qE "Error: Exit code [0-9]+|command not found|syntax error"; then
  # Extract error details
  ERROR_LINE=$(echo "$BASH_OUTPUT" | grep -E "Error: Exit code" | head -1)
  EXIT_CODE=$(echo "$ERROR_LINE" | grep -oE '[0-9]+' | head -1)
  ERROR_MSG=$(echo "$BASH_OUTPUT" | grep -A 1 "Error: Exit code" | tail -1)

  # Log retroactively
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "Bash block error detected: $ERROR_MSG" \
    "output_scraper" \
    "$(jq -n --argjson code "$EXIT_CODE" --arg msg "$ERROR_MSG" \
       '{exit_code: $code, message: $msg}')"
fi
```

**Pros**:
- Catches ALL errors displayed in bash tool output
- No changes to individual bash blocks needed
- Works retroactively for existing commands

**Cons**:
- Relies on output parsing (fragile)
- Error line numbers may be incorrect
- Doesn't capture errors that don't display in output

**Estimated Effort**: 4-6 hours (implement scraper, integrate into all commands)

---

### Solution 3: Claude Tool Error Hook (Architectural)

**Approach**: Add error callback to bash tool execution that logs before Claude intercepts

**Implementation** (requires Claude CLI modification):
```bash
# Pseudo-code for bash tool enhancement
bash_tool_execute() {
  local command="$1"
  local result
  local exit_code

  result=$(bash -c "$command" 2>&1)
  exit_code=$?

  # NEW: Error logging hook BEFORE returning to caller
  if [ $exit_code -ne 0 ] && [ -n "$WORKFLOW_ID" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "execution_error" "Bash tool exit code $exit_code" "bash_tool_hook" \
      "$(jq -n --argjson code "$exit_code" '{exit_code: $code}')"
  fi

  return $exit_code
}
```

**Pros**:
- Catches 100% of bash tool errors
- No changes to individual commands needed
- Clean architectural solution

**Cons**:
- Requires modification to Claude CLI (not accessible in this context)
- May be outside project scope
- Testing complexity high

**Estimated Effort**: N/A (requires Claude team involvement)

---

### Solution 4: Comprehensive Library Sourcing Validation (Defensive)

**Approach**: Validate library functions are available before calling them

**Implementation**:
```bash
# After sourcing libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null

# Validate critical functions
REQUIRED_FUNCTIONS="save_completed_states_to_state load_workflow_state append_workflow_state"
for func in $REQUIRED_FUNCTIONS; do
  if ! type "$func" &>/dev/null; then
    log_command_error \
      "$COMMAND_NAME" \
      "$WORKFLOW_ID" \
      "$USER_ARGS" \
      "dependency_error" \
      "Required function '$func' not available after sourcing" \
      "library_validation" \
      "$(jq -n --arg func "$func" '{missing_function: $func}')"
    echo "ERROR: Missing function: $func" >&2
    exit 1
  fi
done
```

**Pros**:
- Prevents "command not found" errors at runtime
- Early failure with clear diagnostics
- Minimal performance overhead

**Cons**:
- Doesn't solve general error logging gap
- Only addresses library sourcing issues
- Adds boilerplate to every command

**Estimated Effort**: 2-3 hours (add validation to all commands)

---

## Recommended Implementation Plan

### Phase 1: Immediate Fix (Quick Wins)

**Target**: Cover the most critical error scenarios in /build command

**Actions**:
1. ✅ Add explicit error checks after all `save_completed_states_to_state` calls
2. ✅ Add explicit error checks after all `load_workflow_state` calls
3. ✅ Add library function validation (Solution 4) at start of each block
4. ✅ Wrap all `eval` statements in error capture blocks

**Timeline**: 1 day
**Complexity**: Low
**Expected Coverage**: 80% of critical errors

### Phase 2: Systematic Coverage (Medium Term)

**Target**: Extend error logging to all bash-based commands

**Actions**:
1. Create reusable error-check wrapper functions in `error-handling.sh`:
   ```bash
   # execute_with_logging <operation_name> <command>
   execute_with_logging() {
     local operation="$1"
     shift
     local output
     output=$("$@" 2>&1)
     local exit_code=$?
     if [ $exit_code -ne 0 ]; then
       log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
         "execution_error" "$operation failed: $(echo "$output" | head -1)" \
         "wrapper" "$(jq -n --argjson code "$exit_code" '{exit_code: $code}')"
       return $exit_code
     fi
     echo "$output"
     return 0
   }
   ```

2. Refactor critical operations to use wrapper:
   ```bash
   # Instead of:
   save_completed_states_to_state

   # Use:
   execute_with_logging "State persistence" save_completed_states_to_state
   ```

3. Update `/plan`, `/debug`, `/research`, `/revise` commands with same pattern

**Timeline**: 3-5 days
**Complexity**: Medium
**Expected Coverage**: 95% of critical errors

### Phase 3: Validation and Monitoring (Long Term)

**Target**: Ensure error logging completeness

**Actions**:
1. Create test suite for error logging coverage:
   - Trigger known errors (command not found, syntax error, state failures)
   - Verify all errors appear in error log
   - Measure coverage percentage

2. Add error logging metrics to workflow summaries:
   ```
   === Build Complete ===
   Errors Logged: 3
   Errors Suppressed: 0
   Error Log Coverage: 100%
   ```

3. Create `/validate-error-logs` command to check coverage

**Timeline**: 1 week
**Complexity**: High
**Expected Coverage**: 99% of all errors

---

## Technical Debt Considerations

### Current Technical Debt

1. **Trap Scope Limitation**: Bash error traps are session-scoped, not workflow-scoped
2. **Implicit Failure Modes**: Many operations can fail silently (e.g., `source` with `2>/dev/null`)
3. **Inconsistent Error Handling**: Some blocks use explicit checks, others rely on traps
4. **Error Context Loss**: Errors in subshells lose workflow context

### Recommended Debt Reduction

1. **Standardize Error Handling Pattern**:
   - All critical operations use `execute_with_logging` wrapper
   - All library sourcing followed by function validation
   - All state operations wrapped in error checks

2. **Improve Trap Architecture**:
   - Consider trap inheritance mechanism (export trap to subshells)
   - Add trap debugging mode for development
   - Document trap limitations clearly

3. **Testing Infrastructure**:
   - Unit tests for error logging functions
   - Integration tests for workflow error scenarios
   - Automated coverage measurement

---

## Verification Steps

To verify the fix is complete:

1. **Reproduce Original Issue**:
   ```bash
   # Run build with known error
   /build <plan-with-syntax-error>

   # Query errors
   /errors --workflow-id <workflow_id>

   # Expected: Errors now appear in log
   ```

2. **Test Coverage**:
   ```bash
   # Test command not found
   /build <plan-with-missing-function>
   /errors --type execution_error --limit 1

   # Test syntax error
   /build <plan-with-syntax-error>
   /errors --type parse_error --limit 1

   # Test state error
   /build <plan-with-corrupted-state>
   /errors --type state_error --limit 1
   ```

3. **Validate Log Completeness**:
   ```bash
   # Compare build output errors to log entries
   grep "Error:" .claude/build-output.md | wc -l
   /errors --workflow-id <id> --raw | wc -l

   # Counts should match
   ```

---

## Related Issues and Dependencies

### Upstream Dependencies
- **Bash Trap Specification**: Bash ERR trap behavior varies across versions
- **Claude Tool Error Handling**: Claude's bash tool error interception model
- **Library Loading Order**: Some functions may not be available early in execution

### Downstream Impact
- **Error Command**: `/errors` will show more entries after fix
- **Repair Command**: `/repair` will have more data to analyze
- **Monitoring**: Automated error tracking will be more reliable

### Related Specifications
- Error Handling Pattern (`.claude/docs/concepts/patterns/error-handling.md`)
- Error Logging Standards (CLAUDE.md section)
- State-Based Orchestration (for state error logging)

---

## Conclusion

The root cause of the error logging discrepancy is a **gap between bash error trap scope and Claude's bash tool execution model**. Errors that occur within bash blocks but don't cause process termination are not captured by ERR/EXIT traps.

**Recommended Fix**: Implement **Solution 1 (Enhanced Bash Error Trap) + Solution 4 (Library Validation)** as immediate fixes, followed by **Phase 2 (Systematic Coverage)** for long-term reliability.

**Success Criteria**:
- All errors visible in build output appear in error log
- `/errors` command returns accurate, queryable error data
- Error log coverage reaches 95%+ for critical operations

**Next Steps**:
1. Create implementation plan from Phase 1 actions
2. Identify all critical operation sites in `/build` command
3. Add explicit error logging and validation
4. Test with known error scenarios
5. Update error-handling documentation

---

**Report End**
