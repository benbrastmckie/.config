# Exit Code 127: Command Not Found - Troubleshooting Guide

## Overview

Exit code 127 indicates a "command not found" error in bash. In Claude Code command files, this error most commonly occurs due to **subprocess isolation** - each bash block runs in a new process where functions from previously-sourced libraries are not available.

This guide provides a diagnostic flowchart for identifying and resolving these errors.

---

## Diagnostic Flowchart

```
                    Exit Code 127 Error
                           |
                           v
    +----------------------------------------------+
    | 1. Is the function defined in a library?     |
    +----------------------------------------------+
                |                    |
               YES                   NO
                |                    |
                v                    v
    +------------------+   +------------------------+
    | Continue to 2    |   | Function doesn't exist |
    +------------------+   | - Check spelling       |
                |          | - Check library docs   |
                v          +------------------------+
    +----------------------------------------------+
    | 2. Is the library sourced in THIS bash block?|
    |    (Not a previous block - subprocess issue) |
    +----------------------------------------------+
                |                    |
               YES                   NO
                |                    |
                v                    v
    +------------------+   +------------------------+
    | Continue to 3    |   | ADD: source statement  |
    +------------------+   | in current bash block  |
                |          +------------------------+
                v
    +----------------------------------------------+
    | 3. Is CLAUDE_PROJECT_DIR set correctly?      |
    +----------------------------------------------+
                |                    |
               YES                   NO
                |                    |
                v                    v
    +------------------+   +------------------------+
    | Continue to 4    |   | ADD: CLAUDE_PROJECT_DIR|
    +------------------+   | detection (git-based)  |
                |          +------------------------+
                v
    +----------------------------------------------+
    | 4. Does the library file exist at path?      |
    +----------------------------------------------+
                |                    |
               YES                   NO
                |                    |
                v                    v
    +------------------+   +------------------------+
    | Continue to 5    |   | Check library path     |
    +------------------+   | - File moved/renamed?  |
                |          | - Typo in path?        |
                v          +------------------------+
    +----------------------------------------------+
    | 5. Does sourcing use fail-fast pattern?      |
    +----------------------------------------------+
                |                    |
               YES                   NO
                |                    |
                v                    v
    +------------------+   +------------------------+
    | Error is visible |   | ADD: fail-fast handler |
    | Check error msg  |   | to detect source fail  |
    +------------------+   +------------------------+
```

---

## Root Cause: Subprocess Isolation

Each bash block in Claude Code commands runs in a **separate subprocess**. This means:

1. **Functions do not persist** between bash blocks
2. **Environment variables are lost** between blocks
3. **Libraries must be re-sourced** in every bash block

**Common Misconception**: "I sourced the library in Block 1, so it should be available in Block 2."

**Reality**: Block 2 is a new process. The library must be sourced again.

```
Block 1 (PID: 12345)          Block 2 (PID: 12346)
+-------------------+         +-------------------+
| source lib.sh     |         | # lib NOT sourced |
| func_from_lib()   | ------> | func_from_lib()   |
| (works)           |   NEW   | EXIT CODE 127!    |
+-------------------+ PROCESS +-------------------+
```

---

## Diagnostic Steps

### Step 1: Identify the Missing Function

**Error Message Format**:
```
bash: save_completed_states_to_state: command not found
```

The function name appears after "bash:" and before ": command not found".

### Step 2: Find the Library Containing the Function

**Common Function-to-Library Mappings**:

| Function | Library |
|----------|---------|
| `save_completed_states_to_state` | `workflow/workflow-state-machine.sh` |
| `append_workflow_state` | `workflow/workflow-state-machine.sh` |
| `load_workflow_state` | `core/state-persistence.sh` |
| `log_command_error` | `core/error-handling.sh` |
| `ensure_error_log_exists` | `core/error-handling.sh` |
| `emit_progress` | `core/unified-logger.sh` |
| `display_brief_summary` | `core/unified-logger.sh` |
| `verify_file_created` | `core/verification-helpers.sh` |

**Find Library Using Grep**:
```bash
grep -r "function_name\(\)" .claude/lib/
```

### Step 3: Verify Library is Sourced in Current Block

**Check Pattern**: Look for `source` statement in the SAME bash block (above the function call):

```bash
# Correct: Source before call in same block
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || exit 1
save_completed_states_to_state  # Now this works
```

```bash
# Incorrect: Source only in previous block
# Block 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh"

# Block 2 (NEW SUBPROCESS - library not available!)
save_completed_states_to_state  # EXIT CODE 127!
```

### Step 4: Verify CLAUDE_PROJECT_DIR Detection

**Required Pattern**:
```bash
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    if [ -d "$current_dir/.claude" ]; then
      CLAUDE_PROJECT_DIR="$current_dir"
      break
    fi
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR
```

### Step 5: Add Defensive Function Check

**Pattern**: Before calling critical functions, verify they exist:
```bash
if ! type save_completed_states_to_state &>/dev/null; then
  echo "ERROR: save_completed_states_to_state function not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh library not sourced" >&2
  exit 1
fi
save_completed_states_to_state
```

---

## Real-World Examples

### Example 1: /build Command Block 2 Violation (Fixed)

**Original Error** (57% of /build errors):
```
bash: save_completed_states_to_state: command not found
```

**Root Cause**: Block 2 called `save_completed_states_to_state()` without sourcing `workflow-state-machine.sh`.

**Before (Violation)**:
```bash
# Block 2 - Lines 377-380
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null
# workflow-state-machine.sh NOT sourced!

# Line 543: Function call fails
save_completed_states_to_state  # EXIT 127!
```

**After (Fixed)**:
```bash
# Block 2 - Three-tier sourcing pattern
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 3: Command-Specific (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true

# Line 543: Now works
save_completed_states_to_state
```

### Example 2: /debug Command Multiple Violations (Fixed)

**Pattern**: 29 sourcing statements, 25 with bare error suppression.

**Violations Found**:
- `log_command_error` called without `error-handling.sh`
- `emit_progress` called without `unified-logger.sh`
- Multiple blocks missing library re-sourcing

**Fix Applied**: Three-tier sourcing pattern in all bash blocks with defensive checks.

---

## Prevention: Three-Tier Sourcing Pattern

### Tier 1: Critical Foundation (Fail-Fast Required)

These libraries MUST be sourced with fail-fast handlers:

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
```

### Tier 2: Workflow Support (Graceful Degradation)

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/checkpoint-utils.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-logger.sh" 2>/dev/null || true
```

### Tier 3: Command-Specific (Optional)

```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/plan/checkbox-utils.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || true
```

---

## Automated Detection

### Linter Check

Run the library sourcing linter to detect violations:

```bash
bash .claude/scripts/lint/check-library-sourcing.sh
```

**Linter Detects**:
1. Bare error suppression on critical libraries
2. Function calls without library sourcing in same block
3. Missing defensive function availability checks

### Pre-Commit Hook

The pre-commit hook automatically validates sourcing patterns before commits:

```bash
# Hook location: .git/hooks/pre-commit
# Validates: All staged command files pass linter
```

---

## Quick Reference

### Symptoms to Solutions

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| `bash: FUNC: command not found` | Library not sourced in block | Add source statement |
| Error appears intermittently | Different execution paths | Ensure all paths source library |
| Works in Block 1, fails in Block 2 | Subprocess isolation | Re-source in Block 2 |
| Source statement present but fails | Bare error suppression | Add fail-fast handler |
| CLAUDE_PROJECT_DIR empty | Missing detection | Add git-based detection |

### Debug Commands

```bash
# Verify function exists
type save_completed_states_to_state

# Check if library was sourced
declare -F | grep function_name

# List available functions from library
source .claude/lib/workflow/workflow-state-machine.sh
declare -F | grep -E "(sm_|save_|append_)"
```

---

## Related Documentation

- [Bash Block Execution Model](../concepts/bash-block-execution-model.md) - Complete subprocess isolation documentation
- [Three-Tier Sourcing Pattern](../reference/standards/code-standards.md#three-tier-library-sourcing-pattern) - Standard sourcing pattern
- [Linting Bash Sourcing Guide](../guides/development/linting-bash-sourcing.md) - Linter usage
- [Output Formatting Standards](../reference/standards/output-formatting.md) - Error suppression guidelines

---

**Last Updated**: 2025-11-21
**Spec Reference**: 105_build_state_management_bash_errors_fix (Phase 6)
