# Standards-Compliant Fix Implementation

## Executive Summary

This report designs a fix for the exit 127 errors that integrates naturally with existing `.claude/` infrastructure, follows error logging standards, adheres to bash sourcing patterns, and complies with `.claude/docs/` standards documentation. The fix focuses on adding pre-flight function validation to blocks that call library functions without validation.

## Findings

### 1. Existing Standards Compliance Requirements

From CLAUDE.md and related documentation:

#### Code Standards (from `.claude/docs/reference/standards/code-standards.md`):
- All bash blocks MUST follow three-tier sourcing pattern
- Tier 1 libraries require fail-fast handlers
- Library sourcing uses `_source_with_diagnostics` for diagnostic output

#### Command Authoring (from `.claude/docs/reference/standards/command-authoring.md`):
- Commands must use consistent block structure
- Error handling must use `setup_bash_error_trap`
- State must be validated before use

#### Error Handling Pattern (from `.claude/docs/concepts/patterns/error-handling.md`):
- Log errors using `log_command_error`
- Setup bash error trap for automatic error capture
- Use pre-flight validation to prevent errors

### 2. Identified Non-Compliant Blocks

Blocks that call `append_workflow_state` without pre-flight validation:

| Block | Location in create-plan.md | Missing Pattern |
|-------|---------------------------|-----------------|
| Block 1f | Lines 1420-1586 | No `validate_library_functions` or `declare -f` check |
| Block 1d-topics-auto | Lines 1030-1090 | No validation after sourcing |
| Block 1d-topics-auto-validate | Lines 1100-1180 | No validation after sourcing |
| Block 1d-topics | Lines 1190-1300 | No validation after sourcing |

### 3. Correct Pattern (From Blocks 1a, 2, 3)

The working blocks use this pattern:

```bash
# Step 1: Source libraries with _source_with_diagnostics
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1

# Step 2: Pre-flight function validation
validate_library_functions "state-persistence" || exit 1
# OR
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available" >&2
  exit 1
fi

# Step 3: Safe to use functions
append_workflow_state "KEY" "value"
```

### 4. Integration Points

The fix must integrate with:

1. **error-handling.sh** - For error logging when validation fails
2. **state-persistence.sh** - Uses `validate_library_functions()` from this library
3. **validation-utils.sh** - Follows same validation pattern as `validate_agent_artifact()`
4. **command-authoring.md** - Updates documentation for future commands

### 5. Standards Documentation Updates Needed

#### command-authoring.md Updates:

Add new section "Pre-Flight Function Validation":
```markdown
### Pre-Flight Function Validation

Every bash block that calls library functions MUST validate function availability
immediately after sourcing. This prevents exit 127 "command not found" errors.

**Pattern:**
\`\`\`bash
# After sourcing state-persistence.sh
validate_library_functions "state-persistence" || exit 1

# OR use explicit check if validate_library_functions not available
declare -f append_workflow_state >/dev/null 2>&1 || {
  echo "ERROR: Function not available" >&2
  exit 1
}
\`\`\`

**Enforcement:** Pre-commit hooks validate this pattern (future enhancement).
```

#### enforcement-mechanisms.md Updates:

Add exit 127 prevention to enforcement categories:
```markdown
### Exit 127 Prevention (CRITICAL)

- All bash blocks MUST validate library functions before use
- Check: `grep -l "append_workflow_state" | xargs grep -L "validate_library_functions\|declare -f append_workflow_state"`
- Severity: ERROR (blocks commits)
```

## Recommendations

### 1. Immediate Fix: Add Validation to Block 1f

Insert after line 1480 (after sourcing validation-utils.sh):

```bash
# === PRE-FLIGHT FUNCTION VALIDATION (Block 1f) ===
# Verify state-persistence functions available before using them
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "execution_error" \
    "append_workflow_state function not available - library sourcing failed" \
    "bash_block_1f" \
    "$(jq -n '{library: "state-persistence.sh", function: "append_workflow_state"}')"
  echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
  echo "This indicates a library sourcing failure. Check library paths and permissions." >&2
  exit 1
fi
```

### 2. Apply Same Pattern to Other Affected Blocks

For each affected block (1d-topics-auto, 1d-topics-auto-validate, 1d-topics), add the same validation pattern after library sourcing.

### 3. Use _source_with_diagnostics Consistently

Replace:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Cannot load state-persistence library" >&2
  exit 1
}
```

With:
```bash
# error-handling.sh provides _source_with_diagnostics
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
```

This provides better diagnostics when sourcing fails.

### 4. Update Command Authoring Standards

Add to `.claude/docs/reference/standards/command-authoring.md`:

```markdown
## Pre-Flight Library Function Validation

**MANDATORY**: All bash blocks that call library functions MUST validate function availability.

### When to Add Validation

Add pre-flight validation when your block:
- Calls `append_workflow_state` or `append_workflow_state_bulk`
- Calls `sm_init`, `sm_transition`, or other state machine functions
- Calls `log_command_error` or error handling functions
- Uses any function from sourced libraries

### Validation Pattern

\`\`\`bash
# After sourcing libraries
validate_library_functions "state-persistence" || exit 1

# OR if validate_library_functions not available (error-handling not sourced first)
declare -f append_workflow_state >/dev/null 2>&1 || {
  echo "ERROR: append_workflow_state not available" >&2
  exit 1
}
\`\`\`

### Anti-Pattern (PROHIBITED)

\`\`\`bash
# WRONG: Direct source without validation
source "state-persistence.sh" 2>/dev/null || exit 1
append_workflow_state "KEY" "value"  # May fail with exit 127!
\`\`\`
```

### 5. Add Enforcement Script

Create `.claude/scripts/check-preflight-validation.sh`:

```bash
#!/bin/bash
# Check for missing pre-flight validation in command files

find .claude/commands -name "*.md" | while read -r cmd_file; do
  # Find blocks that use append_workflow_state
  if grep -q "append_workflow_state" "$cmd_file"; then
    # Check if validation exists
    if ! grep -qE "validate_library_functions.*state-persistence|declare -f append_workflow_state" "$cmd_file"; then
      echo "WARNING: $cmd_file uses append_workflow_state without pre-flight validation"
    fi
  fi
done
```

## Implementation Checklist

1. [ ] Fix Block 1f in create-plan.md (add pre-flight validation)
2. [ ] Fix Block 1d-topics-auto in create-plan.md
3. [ ] Fix Block 1d-topics-auto-validate in create-plan.md
4. [ ] Fix Block 1d-topics in create-plan.md
5. [ ] Update command-authoring.md with pre-flight validation section
6. [ ] Add check-preflight-validation.sh enforcement script
7. [ ] Update enforcement-mechanisms.md with exit 127 prevention category
8. [ ] Apply same fix pattern to other commands (lean-plan.md, research.md, etc.)

## Related Standards Files

- `.claude/docs/reference/standards/command-authoring.md` - Primary standards document
- `.claude/docs/reference/standards/code-standards.md` - Bash sourcing patterns
- `.claude/docs/reference/standards/enforcement-mechanisms.md` - Enforcement tools
- `.claude/docs/concepts/patterns/error-handling.md` - Error patterns
