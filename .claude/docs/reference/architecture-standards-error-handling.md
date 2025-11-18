# Architecture Standards: Error Handling

**Related Documents**:
- [Overview](architecture-standards-overview.md) - Standards index and fundamentals
- [Validation](architecture-standards-validation.md) - Execution enforcement patterns
- [Dependencies](architecture-standards-dependencies.md) - Content separation patterns

---

## Standard 15: Library Sourcing Order

### Requirement

Orchestration commands MUST source libraries in dependency order before calling any functions from those libraries.

### Rationale

The bash block execution model enforces subprocess isolation. Functions are only available AFTER sourcing, not before. Premature function calls (before sourcing) result in "command not found" errors that terminate workflow initialization.

**Core Principle**: Each bash block runs in a separate subprocess, so functions don't persist across blocks and must be sourced in every block that uses them.

### Standard Sourcing Pattern

All orchestration commands must source libraries in this specific order:

```bash
# 1. State machine foundation (FIRST)
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# 2. Error handling and verification (BEFORE any verification checkpoints)
source "${LIB_DIR}/error-handling.sh"
source "${LIB_DIR}/verification-helpers.sh"

# 3. Additional libraries as needed (AFTER core libraries)
source "${LIB_DIR}/workflow-initialization.sh"
source "${LIB_DIR}/unified-logger.sh"
# ... other libraries via source_required_libraries()
```

### Dependency Justification

**Why this specific order**:

1. **State machine -> State persistence**: State machine defines workflow states, state persistence manages cross-block state
2. **State persistence -> Error/Verification**: Error handling and verification functions depend on `append_workflow_state()` and `STATE_FILE` variable
3. **Error/Verification -> Checkpoints**: Verification checkpoints call `verify_state_variable()`, `verify_file_created()`, and `handle_state_error()` throughout initialization
4. **Other libraries AFTER**: All other libraries can load after these foundations are established

### Source Guards Enable Safe Re-Sourcing

All library files use source guards to prevent duplicate execution:

```bash
# From verification-helpers.sh:11-14
if [ -n "${VERIFICATION_HELPERS_SOURCED:-}" ]; then
  return 0
fi
export VERIFICATION_HELPERS_SOURCED=1
```

**Implication**: Including a library in both early sourcing AND in REQUIRED_LIBS array is safe, recommended, and zero-overhead (guard check is instant).

### Validation

**Automated Testing**:
```bash
bash .claude/tests/test_library_sourcing_order.sh
```

This test validates:
- Functions are sourced before first call (no premature calls)
- Libraries have source guards (safe for multiple sourcing)
- Dependency order is correct (state-persistence before dependent libraries)
- Early sourcing (critical libraries loaded within first 150 lines)

**Manual Code Review**:
- Verify no function calls appear before library sourcing
- Check sourcing order matches standard pattern
- Ensure all bash blocks re-source required libraries

**Runtime Testing**:
- Test with all workflow scopes before merging
- Verify no "command not found" errors during initialization
- Check that verification checkpoints execute successfully

### Examples

**Compliant**: `/coordinate` command (after Spec 675 fix)

Lines 88-127 demonstrate correct sourcing order:
- Line 93: workflow-state-machine.sh sourced
- Line 105: state-persistence.sh sourced
- Line 113: error-handling.sh sourced (EARLY)
- Line 122: verification-helpers.sh sourced (EARLY)
- Line 162: First handle_state_error() call (AFTER sourcing)
- Line 177: First verify_state_variable() call (AFTER sourcing)

**Violation**: Pre-Spec-675 coordinate.md

Functions called at lines 155-239 before sourcing at line 265+:
- Lines 155, 164, 237: `verify_state_variable()` calls
- Lines 162, 167, 209: `handle_state_error()` calls
- Line 335: error-handling.sh sourced (TOO LATE)
- Line 337: verification-helpers.sh sourced (TOO LATE)

**Result**: "command not found" errors terminated initialization.

### Anti-Pattern: Premature Function Calls

```bash
# WRONG: Function called before library sourced
verify_state_variable "WORKFLOW_SCOPE" || exit 1
handle_state_error "Initialization failed" 1

# ... many lines later ...
source "${LIB_DIR}/verification-helpers.sh"
source "${LIB_DIR}/error-handling.sh"
```

**Error Symptoms**:
```
bash: verify_state_variable: command not found
bash: handle_state_error: command not found
```

**Fix**: Source libraries before calling functions

```bash
# CORRECT: Source libraries first
source "${LIB_DIR}/verification-helpers.sh"
source "${LIB_DIR}/error-handling.sh"

# ... now functions are available ...
verify_state_variable "WORKFLOW_SCOPE" || exit 1
handle_state_error "Initialization failed" 1
```

### References

- **Spec 675** (2025-11-11): Library sourcing order fix
- **Spec 620**: Bash history expansion fixes (subprocess isolation discovery)
- **Spec 630**: State persistence architecture (cross-block state management)
- [Bash Block Execution Model](../concepts/bash-block-execution-model.md#function-availability-and-sourcing-order)

---

## Standard 16: Critical Function Return Code Verification

### Requirement

All critical initialization functions MUST have their return codes checked.

### Rationale

Bash `set -euo pipefail` does not exit on function failures, only simple command failures. Silent function failures lead to incomplete state initialization and delayed errors.

### Critical Functions (non-exhaustive list)

- `sm_init()` - State machine initialization (exports WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON)
- `initialize_workflow_paths()` - Path allocation (exports TOPIC_PATH, PLAN_PATH, REPORT_PATHS)
- `source_required_libraries()` - Library loading (makes functions available)
- `classify_workflow_comprehensive()` - Workflow classification (network-dependent)

### Required Pattern

```bash
# Inline error handling (RECOMMENDED for orchestration commands)
if ! critical_function arg1 arg2 2>&1; then
  handle_state_error "critical_function failed: description" 1
fi

# Compound operator (ACCEPTABLE for simple commands)
critical_function arg1 arg2 || exit 1
```

### Prohibited Patterns

```bash
# WRONG: No return code check
critical_function arg1 arg2

# WRONG: Output redirection hides errors
critical_function arg1 arg2 >/dev/null

# WRONG: Redirect stdout only (stderr still visible but return code ignored)
critical_function arg1 arg2 1>/dev/null
```

### Verification Checkpoints

After successful critical function call, verify exported variables:

```bash
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "State machine initialization failed" 1
fi

# VERIFICATION: Ensure critical variables exported
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported despite successful return code" 1
fi
```

### Historical Context

Discovered in Spec 698 where missing return code check in `/coordinate` and `/orchestrate` commands allowed `sm_init()` classification failures to silently proceed, causing unbound variable errors 78 lines later instead of immediate fail-fast behavior.

### Test Requirements

All commands using critical functions must include unit tests for failure paths (see `.claude/tests/test_sm_init_error_handling.sh` for template).

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Reference-Only Sections

**BAD**:
```markdown
## Implementation Phase

The implementation phase executes the plan with testing and commits.

**See**: [Implementation Workflow](../workflows/development-workflow.md) for complete execution steps.

**Quick Reference**: Execute phases -> Test -> Commit -> Update checkpoint
```

**GOOD**:
```markdown
## Implementation Phase

Execute the implementation plan phase by phase with testing and git commits.

**Step 1: Load Plan and Checkpoint**
```bash
source .claude/lib/checkpoint-utils.sh
CHECKPOINT=$(load_checkpoint "implement")
PLAN_PATH=$(echo "$CHECKPOINT" | jq -r '.plan_path')
CURRENT_PHASE=$(echo "$CHECKPOINT" | jq -r '.current_phase')
```

**For Extended Examples**: See [Implementation Workflow](../workflows/development-workflow.md) for additional scenarios and edge cases.
```

### Anti-Pattern 2: Truncated Templates

**BAD**:
```markdown
**Agent Invocation Template**:
```yaml
Task {
  subagent_type: "general-purpose"
  prompt: "See agent definition file for complete prompt structure"
}
```
```

**GOOD**: Include complete, copy-paste ready templates

### Anti-Pattern 3: Vague Quick References

**BAD**:
```markdown
**Quick Reference**: Discover plan -> Execute phases -> Generate summary
```

**GOOD**:
```markdown
**Quick Reference**:
1. Discover plan using find + parse-adaptive-plan.sh
2. Load checkpoint with load_checkpoint "implement"
3. Execute phases sequentially (or in waves if dependencies present)
4. Run tests after each phase using standards-defined test commands
5. Create git commit on phase completion
6. Update checkpoint after each phase
7. Generate implementation summary in specs/{topic}/summaries/
```

### Anti-Pattern 4: Missing Critical Warnings

**BAD**:
```markdown
**Step 2: Launch Research Agents**

Invoke multiple research-specialist agents for parallel research.
```

**GOOD**:
```markdown
**Step 2: Launch Research Agents**

**CRITICAL**: Send ALL Task tool invocations in SINGLE message block. Do NOT send separate messages per agent - this breaks parallelization.

Invoke multiple research-specialist agents for parallel research.
```

---

## Migration Path for Broken Commands

If a command has been broken by over-extraction:

**Step 1: Identify Missing Patterns**

Compare current file with version before extraction:
```bash
git show <commit-before-extraction>:.claude/commands/commandname.md > original.md
git show HEAD:.claude/commands/commandname.md > current.md
diff -u original.md current.md | grep "^-" | head -100
```

**Step 2: Restore Critical Content**

For each section identified in Step 1:
1. Check if content is in shared/ files
2. If execution-critical: Copy back to command file
3. If supplemental: Leave in shared/ and add reference to command file

**Step 3: Validate Restoration**

Run all tests from Testing Standards section.

**Step 4: Document Changes**

Update command file with structural annotations:
```markdown
## Restored Section
[EXECUTION-CRITICAL: Restored from commit <hash> after over-extraction]
```

---

## Related Documentation

- [Architecture Standards Overview](architecture-standards-overview.md)
- [Validation Standards](architecture-standards-validation.md)
- [Testing Standards](architecture-standards-testing.md)
- [Dependencies](architecture-standards-dependencies.md)
