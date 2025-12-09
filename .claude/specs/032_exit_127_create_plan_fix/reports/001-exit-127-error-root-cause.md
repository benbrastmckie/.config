# Exit 127 Error Root Cause Analysis

## Executive Summary

The exit 127 error (`append_workflow_state: command not found`) in the `/create-plan` workflow is caused by **missing library sourcing in Block 1f**. While Block 1a correctly sources state-persistence.sh and other libraries, **Block 1f only sources error-handling.sh and state-persistence.sh but fails to verify function availability before calling append_workflow_state**.

The root cause is a **source guard race condition**: state-persistence.sh has a source guard (`if [ -n "${STATE_PERSISTENCE_SOURCED:-}" ]; then return 0; fi`) that prevents re-sourcing within the same bash process. However, each bash block in Claude Code commands runs as a **separate process**, so the source guard should not cause issues. The actual issue is simpler.

## Findings

### 1. Block 1f Missing Pre-Flight Function Validation

Looking at create-plan.md lines 1464-1483 (Block 1f), the library sourcing is present:

```bash
# Source libraries (three-tier pattern)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {...}

# Tier 2: state-persistence.sh (required for append_workflow_state at line 1573)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {...}
```

However, **there is NO pre-flight function validation** after sourcing. Compare to Block 2 (lines 1650-1663):

```bash
# === PRE-FLIGHT FUNCTION VALIDATION (Block 2) ===
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  exit 1
fi
```

**Block 1f lacks this validation pattern**, causing silent failures.

### 2. Sourcing Success vs Function Availability Gap

The `2>/dev/null` suppression in the source command (`source ... 2>/dev/null || {...}`) can mask issues:
- If the file exists but has errors, stderr is suppressed
- The `||` only catches complete source failures (file not found)
- Internal parse errors or early exits can leave functions undefined

### 3. Line 317 Error Location

The original error shows:
```
/run/current-system/sw/bin/bash: line 317: append_workflow_state: command not found
```

Line 317 in the Block 1f bash block corresponds to the `append_workflow_state` call at line 1579 of create-plan.md:
```bash
append_workflow_state "AGGREGATED_METADATA<<METADATA_EOF
```

### 4. Inconsistent Validation Patterns Across Blocks

| Block | Sources Libraries | Pre-flight Validation | Result |
|-------|-------------------|----------------------|--------|
| Block 1a | Yes | Yes (via validate_library_functions) | Works |
| Block 1b | Yes | No | Potential risk |
| Block 1c | Yes | Yes (partial) | Works |
| Block 1d | Yes | No | Potential risk |
| Block 1f | Yes | **No** | **Fails with exit 127** |
| Block 2 | Yes | Yes | Works |
| Block 3 | Yes | Yes | Works |

### 5. State Persistence Library Source Guard

The state-persistence.sh source guard at lines 30-33:
```bash
if [ -n "${STATE_PERSISTENCE_SOURCED:-}" ]; then
  return 0
fi
STATE_PERSISTENCE_SOURCED=1
```

This guard is designed to prevent redundant sourcing **within the same process**, but since each bash block is a separate process, it should not cause the issue. The guard does NOT export `STATE_PERSISTENCE_SOURCED`, confirming this.

## Recommendations

### 1. Add Pre-Flight Function Validation to Block 1f (Priority: HIGH)

Add after line 1480 in create-plan.md:
```bash
# === PRE-FLIGHT FUNCTION VALIDATION (Block 1f) ===
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available" >&2
  echo "This indicates state-persistence.sh failed to load correctly" >&2
  exit 1
fi
```

### 2. Standardize Library Sourcing Pattern Across All Blocks

Create a consistent pattern that all blocks follow:
1. Source libraries with fail-fast
2. Validate function availability with pre-flight checks
3. Only proceed if all required functions are available

### 3. Use _source_with_diagnostics Instead of Direct Source

Replace:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {...}
```

With:
```bash
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
```

This provides better error diagnostics when sourcing fails.

### 4. Update Command Authoring Standards

Add to command-authoring.md:
- All bash blocks MUST validate function availability after sourcing libraries
- Use validate_library_functions() from state-persistence.sh for standardized validation
- Pre-flight validation is mandatory for any block calling library functions

## Technical Details

### Exit Code 127 Meaning

Exit code 127 in bash specifically means "command not found". This confirms the function was not defined when called, proving the library sourcing failed silently.

### NixOS-Specific Consideration

The error path `/run/current-system/sw/bin/bash` indicates this is running on NixOS. NixOS handles bash differently than traditional Linux distributions, but the core issue (missing function) is not NixOS-specific.

## Related Files

- `/home/benjamin/.config/.claude/commands/create-plan.md` (affected command)
- `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` (defines append_workflow_state)
- `/home/benjamin/.config/.claude/lib/workflow/validation-utils.sh` (validation patterns)
- `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (standards to update)
