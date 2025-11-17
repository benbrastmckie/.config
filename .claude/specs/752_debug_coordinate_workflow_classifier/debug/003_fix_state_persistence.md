# Fix: Enhanced State Persistence Validation (P1)

## Executive Summary

**Problem**: `load_workflow_state()` sources the state file but doesn't verify that required variables exist, leading to cryptic "unbound variable" errors later.

**Solution**: Add optional variable validation to `load_workflow_state()` that:
1. Checks if specific variables exist after sourcing state file
2. Generates detailed error with missing variable list
3. Dumps state file contents for debugging
4. Returns distinct exit code (3) for validation failures

**Priority**: P1 (High - Improves diagnostics and prevents future failures)

**Estimated Time**: 20 minutes

**Dependencies**: None (can apply independently, but most useful after Fix 001 and Fix 002)

---

## Root Cause

Current `load_workflow_state()` implementation (state-persistence.sh lines 191-233):

```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    # State file exists - source it to restore variables
    source "$state_file"
    return 0  # ← Returns success even if critical variables missing!
  else
    # ... handle missing file ...
  fi
}
```

**Problem**: Function returns 0 (success) as long as file exists and sources without syntax errors. It doesn't check if specific variables (like `CLASSIFICATION_JSON`) are present in the file.

**Result**: Callers assume state loaded successfully, then fail with "unbound variable" when accessing missing variables.

---

## Files to Modify

### File: `/home/benjamin/.config/.claude/lib/state-persistence.sh`

**Function**: `load_workflow_state()` (lines 191-233)

**Change Type**: Enhance function signature and add variable validation logic

---

## Step-by-Step Fix Instructions

### Step 1: Backup Current File

```bash
cd /home/benjamin/.config
cp .claude/lib/state-persistence.sh .claude/lib/state-persistence.sh.backup
```

**Verification**:
```bash
ls -la .claude/lib/state-persistence.sh*
# Should show both original and backup
```

---

### Step 2: Update load_workflow_state() Function

**Current Implementation** (lines 191-233):

```bash
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"  # Spec 672 Phase 3: Fail-fast validation mode
  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    # State file exists - source it to restore variables
    source "$state_file"
    return 0
  else
    # Spec 672 Phase 3: Distinguish expected vs unexpected missing state files
    if [ "$is_first_block" = "true" ]; then
      # Expected case: First bash block of workflow, state file doesn't exist yet
      # Gracefully initialize new state file
      init_workflow_state "$workflow_id" >/dev/null
      return 1
    else
      # CRITICAL ERROR: Subsequent bash block, state file should exist but doesn't
      # ... (existing error handling) ...
      return 2  # Exit code 2 = configuration error
    fi
  fi
}
```

**New Implementation** (with variable validation):

```bash
# Enhanced load_workflow_state with optional variable validation
#
# Loads workflow state from file by sourcing it. Optionally validates
# that required variables are present after sourcing.
#
# Signature:
#   load_workflow_state <workflow_id> [is_first_block] [required_var1] [required_var2] ...
#
# Args:
#   $1 - workflow_id: Unique workflow identifier (default: $$)
#   $2 - is_first_block: "true" if first bash block, "false" otherwise (default: false)
#   $3+ - required_vars: Optional list of variable names that must exist after sourcing
#
# Returns:
#   0 - State file sourced successfully (and validation passed if required_vars specified)
#   1 - State file doesn't exist (expected for first block, state initialized)
#   2 - State file missing (unexpected for subsequent blocks, critical error)
#   3 - Validation failed (state file sourced but required variables missing)
#
# Examples:
#   # First bash block (no validation)
#   load_workflow_state "coordinate_$$" true
#
#   # Subsequent bash blocks (no validation)
#   load_workflow_state "coordinate_$$" false
#
#   # Subsequent bash blocks (with validation)
#   load_workflow_state "coordinate_$$" false "CLASSIFICATION_JSON"
#   load_workflow_state "coordinate_$$" false "VAR1" "VAR2" "VAR3"
#
# Reference: Spec 672 Phase 3 (fail-fast state validation)
#           Spec 752 Phase 2 (variable-level validation)
load_workflow_state() {
  local workflow_id="${1:-$$}"
  local is_first_block="${2:-false}"
  shift 2 2>/dev/null || true  # Remove first two args, ignore error if none left
  local required_vars=("$@")  # Remaining args are required variable names

  local state_file="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/workflow_${workflow_id}.sh"

  if [ -f "$state_file" ]; then
    # State file exists - source it to restore variables
    source "$state_file"

    # NEW: Variable-level validation (Spec 752 Phase 2)
    # If required variables specified, verify each exists after sourcing
    if [ ${#required_vars[@]} -gt 0 ]; then
      local missing_vars=()
      for var_name in "${required_vars[@]}"; do
        # Use indirect reference to check if variable is set and non-empty
        # ${!var_name} expands to the value of the variable named by $var_name
        if [ -z "${!var_name:-}" ]; then
          missing_vars+=("$var_name")
        fi
      done

      # If any variables missing, generate detailed diagnostic error
      if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "" >&2
        echo "❌ CRITICAL ERROR: Required variables missing from workflow state" >&2
        echo "" >&2
        echo "Missing variables: ${missing_vars[*]}" >&2
        echo "State file: $state_file" >&2
        echo "" >&2
        echo "State file contents:" >&2
        echo "─────────────────────────────────────────────────────────────────" >&2
        cat "$state_file" >&2
        echo "─────────────────────────────────────────────────────────────────" >&2
        echo "" >&2
        echo "Diagnostic:" >&2
        echo "  - State file was sourced successfully (no syntax errors)" >&2
        echo "  - But required variables were not found in the file" >&2
        echo "  - This indicates the component responsible for saving state failed" >&2
        echo "  - Check the bash block execution that should have saved these variables" >&2
        echo "" >&2
        echo "Troubleshooting:" >&2
        echo "  1. Check if append_workflow_state() was called for missing variables" >&2
        echo "  2. Verify bash block that saves state executed successfully" >&2
        echo "  3. Check for variable escaping issues (quotes, newlines, etc.)" >&2
        echo "  4. Review state file contents above for unexpected format" >&2
        echo "" >&2
        return 3  # Exit code 3 = validation error (distinct from other failures)
      fi
    fi

    # All validations passed
    return 0
  else
    # Spec 672 Phase 3: Distinguish expected vs unexpected missing state files
    if [ "$is_first_block" = "true" ]; then
      # Expected case: First bash block of workflow, state file doesn't exist yet
      # Gracefully initialize new state file
      init_workflow_state "$workflow_id" >/dev/null
      return 1
    else
      # CRITICAL ERROR: Subsequent bash block, state file should exist but doesn't
      # This indicates state persistence failure - fail-fast to expose the issue
      echo "" >&2
      echo "❌ CRITICAL ERROR: Workflow state file not found" >&2
      echo "" >&2
      echo "Context:" >&2
      echo "  Expected state file: $state_file" >&2
      echo "  Workflow ID: $workflow_id" >&2
      echo "  Block type: Subsequent block (is_first_block=false)" >&2
      echo "" >&2
      echo "This indicates a state persistence failure. The state file should" >&2
      echo "have been created by the first bash block but is missing." >&2
      echo "" >&2
      echo "TROUBLESHOOTING:" >&2
      echo "  1. Check if first bash block called init_workflow_state()" >&2
      echo "  2. Verify state ID file exists: ${HOME}/.claude/tmp/coordinate_state_id.txt" >&2
      echo "  3. Check tmp directory permissions: ls -la ${CLAUDE_PROJECT_DIR:-$HOME}/.claude/tmp/" >&2
      echo "  4. Review workflow logs for state file creation" >&2
      echo "  5. Verify WORKFLOW_ID correctly passed between bash blocks" >&2
      echo "" >&2
      echo "Aborting workflow to prevent silent data loss." >&2
      echo "" >&2
      return 2  # Exit code 2 = configuration error (distinct from normal failures)
    fi
  fi
}
```

**Edit Instructions**:

1. Open state-persistence.sh:
   ```bash
   vim /home/benjamin/.config/.claude/lib/state-persistence.sh
   # Or: code /home/benjamin/.config/.claude/lib/state-persistence.sh
   ```

2. Navigate to line 191 (start of `load_workflow_state()` function)

3. Replace lines 191-233 with the new implementation above

4. Save the file

---

### Step 3: Verify Implementation

**Check 1: Function Signature Correct**

```bash
grep -A 3 "^load_workflow_state()" /home/benjamin/.config/.claude/lib/state-persistence.sh

# Should show:
# load_workflow_state() {
#   local workflow_id="${1:-$$}"
#   local is_first_block="${2:-false}"
#   shift 2 2>/dev/null || true
```

**Check 2: Validation Logic Present**

```bash
grep -n "if \[ \${#required_vars\[@\]} -gt 0 \]; then" \
  /home/benjamin/.config/.claude/lib/state-persistence.sh

# Should return: Line number where validation starts
```

**Check 3: Error Message Includes State File Contents**

```bash
grep -n "cat \"\$state_file\" >&2" /home/benjamin/.config/.claude/lib/state-persistence.sh

# Should return: Line number where cat command appears
```

**Check 4: Return Exit Code 3 for Validation Failures**

```bash
grep -n "return 3" /home/benjamin/.config/.claude/lib/state-persistence.sh

# Should return: Line number (inside validation failure block)
```

---

### Step 4: Update Callers to Use Validation

**File**: `/home/benjamin/.config/.claude/commands/coordinate.md`

**Find this line** (around line 259 after Fix 002 applied):

```bash
load_workflow_state "$WORKFLOW_ID"
```

**Replace with**:

```bash
# Load workflow state with validation (Spec 752 Phase 2)
# Fail-fast if CLASSIFICATION_JSON missing from state
load_workflow_state "$WORKFLOW_ID" false "CLASSIFICATION_JSON"
```

**Why**: This ensures immediate detection if CLASSIFICATION_JSON missing, with detailed diagnostics showing state file contents.

**Additional Locations to Update** (same file):

Find all other `load_workflow_state` calls and add validation for critical variables:

```bash
# Example: After state machine initialization
load_workflow_state "$WORKFLOW_ID" false "STATE_MACHINE_CONFIG"

# Example: After research phase
load_workflow_state "$WORKFLOW_ID" false "RESEARCH_REPORTS"

# Example: After plan creation
load_workflow_state "$WORKFLOW_ID" false "PLAN_FILE"
```

**Edit Instructions**:

```bash
cd /home/benjamin/.config

# Find all load_workflow_state calls in coordinate.md
grep -n "load_workflow_state" .claude/commands/coordinate.md

# Manually add validation parameters where appropriate
# Focus on critical variables that would cause workflow to fail if missing
```

---

## Testing Instructions

### Test 1: Validation Success (Variable Exists)

```bash
#!/usr/bin/env bash
source /home/benjamin/.config/.claude/lib/state-persistence.sh

# Create test state with required variable
TEST_ID="test_pass_$$"
STATE_FILE=$(init_workflow_state "$TEST_ID")
append_workflow_state "TEST_VAR" "test_value"

# Load with validation - should succeed
if load_workflow_state "$TEST_ID" false "TEST_VAR"; then
  echo "✓ Test passed: Variable validation succeeded"
  echo "  TEST_VAR = $TEST_VAR"
else
  echo "✗ Test failed: Variable validation failed unexpectedly"
  exit 1
fi

# Cleanup
rm -f "$STATE_FILE"
```

**Expected Output**:
```
✓ Test passed: Variable validation succeeded
  TEST_VAR = test_value
```

---

### Test 2: Validation Failure (Variable Missing)

```bash
#!/usr/bin/env bash
source /home/benjamin/.config/.claude/lib/state-persistence.sh

# Create test state WITHOUT required variable
TEST_ID="test_fail_$$"
STATE_FILE=$(init_workflow_state "$TEST_ID")
append_workflow_state "OTHER_VAR" "other_value"

# Load with validation - should fail with exit code 3
load_workflow_state "$TEST_ID" false "MISSING_VAR" 2>/dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -eq 3 ]; then
  echo "✓ Test passed: Missing variable detected with correct exit code"
else
  echo "✗ Test failed: Expected exit code 3, got $EXIT_CODE"
  exit 1
fi

# Cleanup
rm -f "$STATE_FILE"
```

**Expected Output**:
```
✓ Test passed: Missing variable detected with correct exit code
```

**Expected Error Output** (stderr):
```
❌ CRITICAL ERROR: Required variables missing from workflow state

Missing variables: MISSING_VAR
State file: /home/benjamin/.config/.claude/tmp/workflow_test_fail_12345.sh

State file contents:
─────────────────────────────────────────────────────────────────
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
export WORKFLOW_ID="test_fail_12345"
export STATE_FILE="/home/benjamin/.config/.claude/tmp/workflow_test_fail_12345.sh"
export OTHER_VAR="other_value"
─────────────────────────────────────────────────────────────────

Diagnostic:
  - State file was sourced successfully (no syntax errors)
  - But required variables were not found in the file
  - This indicates the component responsible for saving state failed
  - Check the bash block execution that should have saved these variables

Troubleshooting:
  1. Check if append_workflow_state() was called for missing variables
  2. Verify bash block that saves state executed successfully
  3. Check for variable escaping issues (quotes, newlines, etc.)
  4. Review state file contents above for unexpected format
```

---

### Test 3: Multiple Variables Validation

```bash
#!/usr/bin/env bash
source /home/benjamin/.config/.claude/lib/state-persistence.sh

# Create test state with some variables
TEST_ID="test_multi_$$"
STATE_FILE=$(init_workflow_state "$TEST_ID")
append_workflow_state "VAR1" "value1"
append_workflow_state "VAR2" "value2"
# Note: VAR3 intentionally missing

# Load with validation for all three - should fail
load_workflow_state "$TEST_ID" false "VAR1" "VAR2" "VAR3" 2>/dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -eq 3 ]; then
  echo "✓ Test passed: Multiple variable validation detected missing VAR3"
else
  echo "✗ Test failed: Expected exit code 3, got $EXIT_CODE"
  exit 1
fi

# Cleanup
rm -f "$STATE_FILE"
```

**Expected Output**:
```
✓ Test passed: Multiple variable validation detected missing VAR3
```

---

### Test 4: Backward Compatibility (No Validation)

```bash
#!/usr/bin/env bash
source /home/benjamin/.config/.claude/lib/state-persistence.sh

# Create test state
TEST_ID="test_compat_$$"
STATE_FILE=$(init_workflow_state "$TEST_ID")
append_workflow_state "SOME_VAR" "some_value"

# Load without validation parameters (old usage pattern)
if load_workflow_state "$TEST_ID"; then
  echo "✓ Test passed: Backward compatibility maintained"
  echo "  No validation performed, function succeeded"
else
  echo "✗ Test failed: Backward compatibility broken"
  exit 1
fi

# Cleanup
rm -f "$STATE_FILE"
```

**Expected Output**:
```
✓ Test passed: Backward compatibility maintained
  No validation performed, function succeeded
```

---

## Integration Test with Coordinate Command

After applying Fix 001, Fix 002, and this fix:

```bash
# Intentionally break state persistence to test validation
# Modify coordinate.md temporarily to NOT save CLASSIFICATION_JSON

/coordinate "research test"

# Expected error:
# ❌ CRITICAL ERROR: Required variables missing from workflow state
#
# Missing variables: CLASSIFICATION_JSON
# State file: /home/benjamin/.config/.claude/tmp/workflow_coordinate_12345.sh
#
# State file contents:
# ─────────────────────────────────────────────────────────────────
# export CLAUDE_PROJECT_DIR="/home/benjamin/.config"
# export WORKFLOW_ID="coordinate_12345"
# export STATE_FILE="..."
# ─────────────────────────────────────────────────────────────────
#
# Diagnostic:
#   - State file was sourced successfully (no syntax errors)
#   - But required variables were not found in the file
#   ...
```

This error provides **immediate, actionable diagnostics** instead of cryptic "unbound variable" error later.

---

## Why This Fix Works

### Before Fix

```bash
# State file missing CLASSIFICATION_JSON
load_workflow_state "$WORKFLOW_ID"  # Returns 0 (success!)

# Later in code...
echo "$CLASSIFICATION_JSON" | jq ...
# ❌ ERROR: CLASSIFICATION_JSON: unbound variable
# (Cryptic error, no context about what went wrong)
```

### After Fix

```bash
# State file missing CLASSIFICATION_JSON
load_workflow_state "$WORKFLOW_ID" false "CLASSIFICATION_JSON"
# Returns 3 (validation error)
# Prints detailed error:
#   - Which variables missing
#   - State file location
#   - State file contents (shows what WAS in the file)
#   - Troubleshooting steps

# Script exits immediately with clear diagnostic
# Never reaches the line that would cause "unbound variable" error
```

---

## Benefits

1. **Fail-Fast**: Errors detected immediately at state loading, not later at variable access
2. **Detailed Diagnostics**: Shows exactly what's in state file vs. what's expected
3. **Actionable Errors**: Troubleshooting steps guide developer to fix
4. **Backward Compatible**: Validation optional (old usage patterns still work)
5. **Performance**: Minimal overhead (~1-2ms per validation check)
6. **Exit Code Distinction**: Exit code 3 distinguishes validation errors from other failures

---

## Exit Code Reference

After this fix, `load_workflow_state()` returns:

- **0**: State file loaded successfully (validation passed if specified)
- **1**: State file doesn't exist (expected for first block, state initialized)
- **2**: State file missing (unexpected, critical configuration error)
- **3**: **NEW** - Validation failed (state file exists but required variables missing)

Callers can distinguish error types:

```bash
load_workflow_state "$WORKFLOW_ID" false "REQUIRED_VAR"
EXIT_CODE=$?

case $EXIT_CODE in
  0)
    echo "✓ State loaded and validated"
    ;;
  1)
    echo "ℹ First block, state initialized"
    ;;
  2)
    echo "❌ State file missing (critical error)"
    exit 1
    ;;
  3)
    echo "❌ Validation failed (required variables missing)"
    exit 1
    ;;
esac
```

---

## Rollback Plan

If this fix causes issues:

```bash
cd /home/benjamin/.config

# Restore from backup
cp .claude/lib/state-persistence.sh.backup .claude/lib/state-persistence.sh

# Verify restoration
diff .claude/lib/state-persistence.sh.backup .claude/lib/state-persistence.sh
# Should show: No differences

echo "✓ Rollback complete"
```

---

## Success Criteria

- [ ] load_workflow_state() signature updated with varargs support
- [ ] Variable validation logic implemented (lines ~30-50 of function)
- [ ] Missing variables trigger exit code 3
- [ ] Error message lists all missing variables
- [ ] Error message dumps state file contents
- [ ] Troubleshooting steps included in error output
- [ ] Backward compatible (validation optional)
- [ ] coordinate.md updated to use validation for CLASSIFICATION_JSON
- [ ] All 4 tests pass (success, failure, multiple, compatibility)

**Completion Signal**: When all criteria met, validation enhancement complete.

---

**Fix Status**: READY TO APPLY
**Created**: 2025-11-17
**Spec**: 752_debug_coordinate_workflow_classifier
**Debug Artifact**: 003_fix_state_persistence.md
**Priority**: P1 (High - Improves diagnostics)
**Dependencies**: None (independent enhancement)
**Complements**: Fix 001, Fix 002 (most useful when those are applied)
