# Implementation Plan: Fix Exit 127 Errors in Create-Plan Workflow

## Metadata

- **Date**: 2025-12-08
- **Feature**: Fix exit 127 (append_workflow_state: command not found) errors in /create-plan by adding pre-flight function validation to affected bash blocks
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-3 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [001-exit-127-error-root-cause.md](../reports/001-exit-127-error-root-cause.md)
  - [002-create-plan-state-integration.md](../reports/002-create-plan-state-integration.md)
  - [003-standards-compliant-fix-plan.md](../reports/003-standards-compliant-fix-plan.md)

## Problem Summary

The `/create-plan` command fails with exit 127 (`append_workflow_state: command not found`) in Block 1f because the block sources state-persistence.sh but does not validate that functions are actually available before calling them. This is a silent library sourcing failure - the source command succeeds but functions are not defined.

**Root Cause**: Missing pre-flight function validation in Block 1f (and other blocks).

**Evidence**: The error occurs at line 317 of the bash block, corresponding to line 1579 in create-plan.md where `append_workflow_state` is called without prior validation.

## Solution Overview

Add pre-flight function validation to all bash blocks that call library functions without validation. This follows the pattern already used in Blocks 1a, 2, and 3.

---

### Phase 1: Fix Block 1f in create-plan.md [COMPLETE]

**Objective**: Add pre-flight function validation to Block 1f to prevent exit 127 errors.

**Files to Modify**:
- `.claude/commands/create-plan.md`

**Implementation Steps**:
1. Locate Block 1f (starts around line 1420, "Research Output Hard Barrier Validation")
2. After line 1480 (after sourcing validation-utils.sh), add pre-flight validation:
   ```bash
   # === PRE-FLIGHT FUNCTION VALIDATION (Block 1f) ===
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
       "$(jq -n '{library: \"state-persistence.sh\", function: \"append_workflow_state\"}')"
     echo "ERROR: append_workflow_state function not available after sourcing state-persistence.sh" >&2
     exit 1
   fi
   ```

**Success Criteria**:
- [x] Pre-flight validation added to Block 1f
- [x] Validation uses same pattern as Block 2
- [x] Error logging follows error-handling.md pattern
- [x] Block 1f no longer fails with exit 127 when append_workflow_state is called

---

### Phase 2: Fix Other Affected Blocks in create-plan.md [COMPLETE]

**Objective**: Add pre-flight function validation to all other blocks that call append_workflow_state without validation.

**Files to Modify**:
- `.claude/commands/create-plan.md`

**Blocks to Fix**:
1. **Block 1b** (around line 420): Add validation after sourcing state-persistence.sh
2. **Block 1d-topics-auto** (around line 1030): Add validation after sourcing
3. **Block 1d-topics-auto-validate** (around line 1100): Add validation after sourcing
4. **Block 1d-topics** (around line 1190): Add validation after sourcing

**Implementation Pattern for Each Block**:
```bash
# After sourcing state-persistence.sh
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state function not available" >&2
  exit 1
fi
```

**Success Criteria**:
- [x] Block 1b has pre-flight validation
- [x] Block 1d-topics-auto has pre-flight validation
- [x] Block 1d-topics-auto-validate has pre-flight validation
- [x] Block 1d-topics has pre-flight validation
- [x] All blocks use consistent validation pattern

---

### Phase 3: Update Command Authoring Standards [COMPLETE]

**Objective**: Document pre-flight function validation requirement in command authoring standards.

**Files to Modify**:
- `.claude/docs/reference/standards/command-authoring.md`

**Implementation Steps**:
1. Add new section "Pre-Flight Library Function Validation" after existing library sourcing section
2. Document the validation pattern with code examples
3. Add anti-pattern section showing what NOT to do
4. Reference enforcement mechanisms

**Content to Add**:
```markdown
### Pre-Flight Library Function Validation

**MANDATORY**: All bash blocks that call library functions MUST validate function availability
immediately after sourcing. This prevents exit 127 "command not found" errors.

**Pattern:**
\`\`\`bash
# After sourcing state-persistence.sh
declare -f append_workflow_state >/dev/null 2>&1
FUNCTION_CHECK=$?
if [ $FUNCTION_CHECK -ne 0 ]; then
  echo "ERROR: append_workflow_state not available" >&2
  exit 1
fi
\`\`\`

**Anti-Pattern (PROHIBITED):**
\`\`\`bash
# WRONG: Direct source without validation
source "state-persistence.sh" 2>/dev/null || exit 1
append_workflow_state "KEY" "value"  # May fail with exit 127!
\`\`\`
```

**Success Criteria**:
- [x] New section added to command-authoring.md
- [x] Pattern clearly documented with examples
- [x] Anti-pattern documented
- [x] Section linked from Quick Reference in CLAUDE.md (table of contents updated)

---

### Phase 4: Apply Fix to Other Commands [COMPLETE]

**Objective**: Ensure other commands follow the same pre-flight validation pattern.

**Files to Review and Potentially Modify**:
- `.claude/commands/lean-plan.md`
- `.claude/commands/research.md`
- `.claude/commands/debug.md`
- `.claude/commands/implement.md`

**Implementation Steps**:
1. Audit each command for blocks calling append_workflow_state
2. Check if pre-flight validation exists
3. Add validation where missing
4. Use consistent pattern across all commands

**Validation Checks**:
```bash
# For each command file, check for this pattern:
# 1. Sources state-persistence.sh
# 2. Has declare -f or validate_library_functions before append_workflow_state
```

**Success Criteria**:
- [x] lean-plan.md audited and fixed if needed (already has validation)
- [x] research.md audited and fixed if needed (already has validation)
- [x] debug.md audited and fixed if needed (fixed - added validation)
- [x] implement.md audited and fixed if needed (already has validation)
- [x] revise.md audited and fixed if needed (fixed - added validation)
- [x] lean-implement.md audited (uses validate_workflow_prerequisites)
- [x] All commands use consistent validation pattern

---

### Phase 5: Testing and Verification [NOT STARTED]

**Objective**: Verify the fix works and doesn't introduce regressions.

**Test Cases**:
1. Run `/create-plan "test feature description"` - should complete without exit 127
2. Run `/lean-plan` if available - should complete without errors
3. Run `/research "test topic"` - should complete without errors
4. Intentionally break library path and verify error message is helpful

**Verification Steps**:
1. Execute test commands with verbose output
2. Check for any exit 127 errors in output
3. Verify error messages are clear when validation fails
4. Check error logs for proper error capture

**Success Criteria**:
- [ ] /create-plan completes without exit 127
- [ ] All test commands pass
- [ ] Error messages are clear and actionable
- [ ] No regressions in working blocks

---

## Implementation Notes

### Key Files
- `.claude/commands/create-plan.md` - Primary fix target
- `.claude/lib/core/state-persistence.sh` - Defines append_workflow_state
- `.claude/lib/core/error-handling.sh` - Provides _source_with_diagnostics
- `.claude/docs/reference/standards/command-authoring.md` - Standards to update

### Related Patterns
- Three-tier library sourcing (code-standards.md)
- Error handling pattern (error-handling.md)
- Pre-flight validation (state-persistence.sh validate_library_functions)

### Risks and Mitigations
- **Risk**: Adding validation overhead to each block
- **Mitigation**: declare -f is extremely fast (<1ms), negligible impact

- **Risk**: Breaking existing working blocks
- **Mitigation**: Only add validation, don't modify existing logic

### Future Enhancements
- Add pre-commit hook to enforce pre-flight validation
- Create linting script to detect missing validation
- Consider automatic validation injection in command preprocessor
