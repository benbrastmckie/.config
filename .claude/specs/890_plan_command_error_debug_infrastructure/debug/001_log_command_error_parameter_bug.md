# Debug Report: log_command_error Parameter Count Bug

## Metadata
- **Date**: 2025-11-21
- **Agent**: debug-analyst
- **Issue**: Tests failed with exit code 1 - validate_agent_output() function calls log_command_error with incorrect parameter count
- **Hypothesis**: Missing parameters in log_command_error calls cause unbound variable errors
- **Status**: Complete

## Issue Description

Tests failed with exit code 1. Critical bug found: validate_agent_output() function in error-handling.sh calls log_command_error with only 3 parameters instead of required 7, causing "unbound variable" error.

**Test Results**: 1/4 passed, 3/4 failed
**Test Command**: bash /home/benjamin/.config/.claude/tests/unit/test_plan_command_fixes.sh
**Failed Phase**: testing

## Failed Tests

Test suite executed 4 test cases with 5 successful assertions before encountering a critical bug in the `validate_agent_output` function. The bug prevents Test 2 from completing execution.

**Test 1**: append_workflow_state available after state block sourcing - PASSED (5/5 assertions)
**Test 2**: Agent output validation detects missing file - FAILED (0/3 assertions executed)
**Test 3**: State validation detects missing variables - NOT RUN
**Test 4**: Library sourcing helper function works - NOT RUN

**Error Output**:
```
.claude/lib/core/error-handling.sh: line 421: $7: unbound variable
```

## Investigation

### Issue Reproduction

**Test Command**: `bash /home/benjamin/.config/.claude/tests/unit/test_plan_command_fixes.sh`

**Reproduction Steps**:
1. Test suite sources error-handling.sh library
2. Test 1 passes completely (5/5 assertions)
3. Test 2 attempts to call validate_agent_output() function
4. validate_agent_output() calls log_command_error with only 3 parameters
5. log_command_error function attempts to access $7 parameter
6. Script terminates with "unbound variable" error due to `set -u` in error-handling.sh

**Reproduction Result**:
- [x] Issue reproduced consistently
- [ ] Issue not reproduced
- [ ] Intermittent

### Code Analysis

**Function Signature** (line 414):
```bash
log_command_error() {
  local command="${1:-unknown}"
  local workflow_id="${2:-unknown}"
  local user_args="${3:-}"
  local error_type="${4:-unknown}"
  local message="${5:-}"
  local source="${6:-unknown}"
  local context_json="$7"  # Line 421: UNBOUND VARIABLE ERROR
```

The function requires 7 parameters, but parameter $7 is accessed directly without a default value, causing the unbound variable error when fewer than 7 parameters are provided.

### Affected Code Locations

**Audit Results**: Found 4 calls to log_command_error in error-handling.sh

1. **Line 1263-1271** (bash_error_trap): CORRECT - 7 parameters provided
   ```bash
   log_command_error \
     "$command_name" \
     "$workflow_id" \
     "$user_args" \
     "$error_type" \
     "Bash error at line $line_no: exit code $exit_code" \
     "bash_trap" \
     "$(jq -n ...)"
   ```

2. **Line 1299-1307** (bash_trap_handler): CORRECT - 7 parameters provided
   ```bash
   log_command_error \
     "$command_name" \
     "$workflow_id" \
     "$user_args" \
     "$error_type" \
     "Bash error at line $line_no: exit code $exit_code" \
     "bash_trap" \
     "$(jq -n ...)"
   ```

3. **Line 1358-1361** (validate_agent_output): INCORRECT - only 3 parameters
   ```bash
   log_command_error \
     "agent_error" \
     "Agent $agent_name did not create output file within ${timeout_seconds}s" \
     "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" '{agent: $agent, expected_file: $file}')"
   ```
   **Missing**: command, workflow_id, user_args, source

4. **Line 1385-1388** (validate_agent_output_with_retry): INCORRECT - only 3 parameters
   ```bash
   log_command_error \
     "validation_error" \
     "Agent $agent_name output file failed format validation (retry $retry/$max_retries)" \
     "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retry "$retry" '{agent: $agent, output_file: $file, retry: $retry}')"
   ```
   **Missing**: command, workflow_id, user_args, source

5. **Line 1409-1412** (validate_agent_output_with_retry): INCORRECT - only 3 parameters
   ```bash
   log_command_error \
     "agent_error" \
     "Agent $agent_name did not create valid output file after $max_retries attempts" \
     "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retries "$max_retries" '{agent: $agent, expected_file: $file, retries: $retries}')"
   ```
   **Missing**: command, workflow_id, user_args, source

### Root Cause Summary

**Primary Issue**: Three function calls (lines 1358, 1385, 1409) incorrectly call log_command_error with only 3 parameters instead of the required 7. The parameters are shifted incorrectly:
- Parameter 1: error_type (should be command)
- Parameter 2: message (should be workflow_id)
- Parameter 3: context_json (should be user_args)
- Parameters 4-7: MISSING

**Secondary Issue**: log_command_error function (line 421) accesses $7 directly without providing a default value, making it incompatible with `set -u` (unbound variable checking) when called with fewer parameters.

## Root Cause Analysis

### Hypothesis Validation
Missing parameters in log_command_error calls cause unbound variable errors: **CONFIRMED**

### Evidence
1. **Direct observation**: Line 421 uses `local context_json="$7"` without default value
2. **Test failure**: Test 2 terminates at validate_agent_output() call with "unbound variable" error
3. **Code audit**: 3 out of 5 calls to log_command_error provide incorrect parameter count
4. **Function signature mismatch**: Documentation states 7 parameters required, but 3 calls provide only 3
5. **Strict mode conflict**: `set -u` in error-handling.sh enforces parameter checking

### Root Cause

The root cause is a **function signature mismatch** caused by incorrect parameter ordering in three validation functions (validate_agent_output and validate_agent_output_with_retry). These functions were likely written before the log_command_error function signature was standardized, or were copied from an older codebase version.

The bug pattern shows:
1. **Missing context variables**: Functions don't capture COMMAND_NAME, WORKFLOW_ID, USER_ARGS before calling log_command_error
2. **Parameter position confusion**: Developers passed error_type as first parameter (should be 4th)
3. **No defensive coding**: log_command_error doesn't validate parameter count or provide defaults for optional parameters

## Impact Assessment

### Scope
- **Affected files**:
  - `.claude/lib/core/error-handling.sh` (lines 421, 1358, 1385, 1409)
- **Affected components**:
  - `validate_agent_output()` - completely non-functional
  - `validate_agent_output_with_retry()` - completely non-functional
  - All code paths using agent output validation
  - Test suite execution (3/4 tests blocked)
- **Severity**: **Critical**

### Impact Details

**Production Impact**:
- Any workflow using validate_agent_output() will fail immediately
- Agent orchestration cannot verify subagent outputs
- Error logging for agent failures is broken
- Silent failures possible if validation is wrapped in error suppression

**Test Impact**:
- 75% of test suite blocked (3/4 tests cannot run)
- Test coverage drops from 100% to 25%
- Integration tests likely affected
- CI/CD pipeline may be failing

**Development Impact**:
- Bug prevents validation of agent outputs in all workflows
- Error logs missing critical agent failure data
- Debugging agent issues becomes significantly harder

### Related Issues
- Any command using validate_agent_output() will fail (/plan, /build, /research, etc.)
- Error log queries (/errors command) will be missing agent error entries
- Repair workflow (/repair command) cannot analyze agent failures

## Proposed Fix

### Fix Description

The fix requires two changes:

**Fix 1**: Make $7 parameter optional in log_command_error function (line 421)
**Fix 2**: Correct all three incorrect log_command_error calls to pass all 7 parameters

### Code Changes

**File**: `/home/benjamin/.config/.claude/lib/core/error-handling.sh`

**Change 1: Line 421** - Add default value for $7 parameter
```bash
# BEFORE:
local context_json="$7"

# AFTER:
local context_json="${7:-{}}"
```

**Change 2: Lines 1358-1361** - Fix validate_agent_output() call
```bash
# BEFORE:
log_command_error \
  "agent_error" \
  "Agent $agent_name did not create output file within ${timeout_seconds}s" \
  "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" '{agent: $agent, expected_file: $file}')"

# AFTER:
log_command_error \
  "${COMMAND_NAME:-/unknown}" \
  "${WORKFLOW_ID:-unknown}" \
  "${USER_ARGS:-}" \
  "agent_error" \
  "Agent $agent_name did not create output file within ${timeout_seconds}s" \
  "validate_agent_output" \
  "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" '{agent: $agent, expected_file: $file}')"
```

**Change 3: Lines 1385-1388** - Fix validate_agent_output_with_retry() call (validation failure)
```bash
# BEFORE:
log_command_error \
  "validation_error" \
  "Agent $agent_name output file failed format validation (retry $retry/$max_retries)" \
  "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retry "$retry" '{agent: $agent, output_file: $file, retry: $retry}')"

# AFTER:
log_command_error \
  "${COMMAND_NAME:-/unknown}" \
  "${WORKFLOW_ID:-unknown}" \
  "${USER_ARGS:-}" \
  "validation_error" \
  "Agent $agent_name output file failed format validation (retry $retry/$max_retries)" \
  "validate_agent_output_with_retry" \
  "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retry "$retry" '{agent: $agent, output_file: $file, retry: $retry}')"
```

**Change 4: Lines 1409-1412** - Fix validate_agent_output_with_retry() call (timeout)
```bash
# BEFORE:
log_command_error \
  "agent_error" \
  "Agent $agent_name did not create valid output file after $max_retries attempts" \
  "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retries "$max_retries" '{agent: $agent, expected_file: $file, retries: $retries}')"

# AFTER:
log_command_error \
  "${COMMAND_NAME:-/unknown}" \
  "${WORKFLOW_ID:-unknown}" \
  "${USER_ARGS:-}" \
  "agent_error" \
  "Agent $agent_name did not create valid output file after $max_retries attempts" \
  "validate_agent_output_with_retry" \
  "$(jq -n --arg agent "$agent_name" --arg file "$expected_file" --argjson retries "$max_retries" '{agent: $agent, expected_file: $file, retries: $retries}')"
```

### Fix Rationale

**Defensive Parameter Handling**: Using `${7:-{}}` makes the context_json parameter truly optional, allowing log_command_error to work even if called with 6 parameters. This prevents future unbound variable errors.

**Environment Variable Fallbacks**: Using `${COMMAND_NAME:-/unknown}` ensures the function works even when called from contexts where these variables aren't set (e.g., test environments, standalone scripts).

**Source Parameter**: Adding "validate_agent_output" or "validate_agent_output_with_retry" as the source parameter provides better traceability in error logs.

**Backward Compatibility**: The fix maintains backward compatibility - existing correct calls continue to work, and the defensive parameter handling prevents future errors.

### Fix Complexity
- **Estimated time**: 15 minutes (4 simple parameter fixes)
- **Risk level**: Low (fixes are straightforward parameter additions)
- **Testing required**:
  - Re-run test suite: `bash .claude/tests/unit/test_plan_command_fixes.sh`
  - Verify all 4 tests pass
  - Run integration tests with agent validation
  - Check error log for proper entries

## Recommendations

### Immediate Actions (Required)
1. **Apply all 4 fixes** to error-handling.sh (lines 421, 1358, 1385, 1409)
2. **Re-run test suite** to verify 4/4 tests pass
3. **Verify error logging** works by triggering an agent timeout
4. **Check error log format** using `/errors --type agent_error --limit 1`

### Short-term Improvements (High Priority)
1. **Audit all library files** for similar parameter count issues:
   ```bash
   grep -rn "log_command_error" .claude/lib/ | grep -v "^.*#"
   ```
2. **Add parameter validation** to log_command_error function:
   ```bash
   if [ $# -lt 6 ]; then
     echo "ERROR: log_command_error requires at least 6 parameters" >&2
     return 1
   fi
   ```
3. **Add unit tests** for log_command_error with various parameter counts

### Medium-term Enhancements (Recommended)
1. **Create wrapper functions** to simplify common error patterns:
   ```bash
   log_agent_error() {
     local agent_name="$1"
     local message="$2"
     local context="$3"
     log_command_error "${COMMAND_NAME:-/unknown}" "${WORKFLOW_ID:-unknown}" \
       "${USER_ARGS:-}" "agent_error" "$message" "$agent_name" "$context"
   }
   ```
2. **Document parameter requirements** in function header comments
3. **Add shellcheck directives** to catch parameter mismatches

### Long-term Improvements (Nice to Have)
1. **Standardize error handling** across all library functions
2. **Create error handling style guide** with examples
3. **Add pre-commit hooks** to validate function call signatures
4. **Consider structured error types** (enum-like pattern in Bash)
