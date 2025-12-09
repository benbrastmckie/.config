# Create-Plan Workflow State Management Integration

## Executive Summary

This report analyzes how the `/create-plan` workflow integrates with state persistence infrastructure and identifies patterns causing the exit 127 error. The workflow has **10 distinct bash blocks**, each running as a separate process, requiring independent library sourcing and state restoration in every block.

## Findings

### 1. Multi-Block Architecture

The `/create-plan` command uses a sequential multi-block architecture:

| Block | Purpose | Libraries Required | State Operations |
|-------|---------|-------------------|------------------|
| Block 1a | Initialize workflow | All core libraries | init_workflow_state, sm_init |
| Block 1b | Pre-calculate topic path | state-persistence | append_workflow_state |
| Block 1b-exec | Topic naming agent (Task) | N/A (agent) | N/A |
| Block 1c | Validate topic name | validation-utils | None (validation only) |
| Block 1d | Parse topic and init paths | state-persistence | append_workflow_state_bulk |
| Block 1d-topics-auto | Topic detection prep | state-persistence | append_workflow_state |
| Block 1d-topics-auto-exec | Topic detection (Task) | N/A (agent) | N/A |
| Block 1d-topics-auto-validate | Validate topics JSON | validation-utils | append_workflow_state |
| Block 1d-topics | Decompose topics | state-persistence | append_workflow_state_bulk |
| Block 1e-exec | Research coordinator (Task) | N/A (agent) | N/A |
| **Block 1f** | Validate research output | **state-persistence** | **append_workflow_state (FAILS)** |
| Block 2 | Prepare for planning | All core libraries | append_workflow_state |
| Block 2-exec | Plan architect (Task) | N/A (agent) | N/A |
| Block 3a | Validate plan output | validation-utils | None |
| Block 3 | Complete workflow | All core libraries | sm_transition, save_completed_states |

### 2. State Persistence Function Requirements

The `append_workflow_state` function from state-persistence.sh is called in these blocks:
- Block 1b: Line ~455 (TOPIC_NAME_FILE)
- Block 1d: Lines ~809 (bulk append)
- Block 1d-topics-auto: Lines ~(multiple)
- Block 1d-topics-auto-validate: Line ~ (TOPIC_DETECTION_*)
- Block 1d-topics: Lines ~ (bulk append)
- **Block 1f**: Lines 1579 (AGGREGATED_METADATA) - **THIS FAILS**
- Block 2: Lines ~ (multiple state vars)

### 3. Library Sourcing Inconsistencies

Comparing library sourcing patterns:

**Block 1a (WORKS - Full pattern with validation):**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
# ...
validate_library_functions "state-persistence" || exit 1
validate_library_functions "error-handling" || exit 1
```

**Block 1f (FAILS - Missing validation):**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {...}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {...}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {...}
# NO validate_library_functions call
# NO declare -f check
# append_workflow_state called at line 1579 without validation
```

**Block 2 (WORKS - Full pattern with validation):**
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {...}
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
# ...
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available" >&2
  exit 1
fi
```

### 4. State File Path Consistency

The workflow correctly uses `CLAUDE_PROJECT_DIR` for state file paths:

```bash
STATE_ID_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/plan_state_id.txt"
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

This follows the documented pattern from state-persistence.sh lines 11-24:
```
# CORRECT pattern (in command bash blocks AFTER CLAUDE_PROJECT_DIR detection):
#   STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
#
# INCORRECT pattern (causes PATH MISMATCH bug):
#   STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"
```

### 5. Block 1f Error Context

The error output from the original failure:
```
Error: Exit code 127
/run/current-system/sw/bin/bash: line 317: append_workflow_state: command not found

=== Research Output Hard Barrier Validation ===

Expected reports: 3
  Validating: .../001-doc-link-status-analysis.md
  ✓ Validated
  ...
```

Key observations:
1. The validation logic (using validation-utils.sh) **worked correctly**
2. Reports were successfully validated
3. The failure occurred AFTER validation when trying to persist metadata
4. This proves validation-utils.sh sourced correctly but state-persistence.sh functions were not available

### 6. Sourcing Order Analysis

The `2>/dev/null || {...}` pattern has a subtle issue:

```bash
source "file.sh" 2>/dev/null || { echo "ERROR"; exit 1; }
```

This pattern:
- Catches file-not-found errors (good)
- Suppresses all stderr during sourcing (problematic)
- Does NOT catch cases where the file sources successfully but functions are undefined

When state-persistence.sh is sourced, it:
1. Checks source guard (line 30-33)
2. Sets pipefail mode (line 129)
3. Detects CLAUDE_PROJECT_DIR (lines 132-135)
4. Defines functions (lines 165-1041)

If any step fails after the source command "succeeds", functions may be undefined.

## Recommendations

### 1. Add validate_library_functions to Block 1f

After sourcing state-persistence.sh in Block 1f (~line 1474), add:

```bash
# PRE-FLIGHT FUNCTION VALIDATION
validate_library_functions "state-persistence" || {
  echo "ERROR: state-persistence.sh functions not available" >&2
  exit 1
}
```

### 2. Create Standard Block Template

All blocks that call `append_workflow_state` should follow this template:

```bash
# === SOURCE LIBRARIES ===
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# === PRE-FLIGHT VALIDATION ===
validate_library_functions "state-persistence" || exit 1

# === NOW SAFE TO USE FUNCTIONS ===
append_workflow_state "KEY" "value"
```

### 3. Update Blocks 1b, 1d, 1d-topics-auto, 1d-topics-auto-validate, 1d-topics

All these blocks call `append_workflow_state` but lack consistent validation. Apply the same fix pattern to each.

### 4. Document in Command Authoring Standards

Add explicit requirement to command-authoring.md:
> Every bash block that calls library functions MUST validate function availability immediately after sourcing, using either `validate_library_functions()` or explicit `declare -f` checks.

## Implementation Priority

1. **Block 1f** - Immediate fix (causes the documented error)
2. **Block 1d-topics blocks** - High priority (same pattern, different blocks)
3. **Other blocks** - Medium priority (for consistency)

## Related Files

- `/home/benjamin/.config/.claude/commands/create-plan.md` - Command definition
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` - State functions
- `/home/benjamin/.config/.claude/lib/core/error-handling.sh` - Error trap functions
- `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh` - Validation helpers
