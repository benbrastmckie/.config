# Bash Command Compliance Checklist

Use this checklist before submitting any new or modified command in `.claude/commands/`.

## Pre-Submission Verification

### Bootstrap Requirements

- [ ] Every bash block has project directory detection (git-based or directory walk)
- [ ] `CLAUDE_PROJECT_DIR` is exported after detection
- [ ] `set +H` is included at start of every bash block (prevents history expansion errors)

### Tier 1 Library Sourcing (MANDATORY)

- [ ] Every bash block sources `state-persistence.sh` with fail-fast handler
- [ ] Every bash block sources `workflow-state-machine.sh` with fail-fast handler
- [ ] Every bash block sources `error-handling.sh` with fail-fast handler
- [ ] No bare `2>/dev/null` on any Tier 1 library

**Fail-Fast Pattern**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

### Function Availability Checks

- [ ] Defensive `type` checks before critical function calls
- [ ] Check appears within 10 lines before the function call
- [ ] Error message includes diagnostic information

**Example**:
```bash
if ! type save_completed_states_to_state &>/dev/null; then
  echo "ERROR: save_completed_states_to_state not found" >&2
  echo "DIAGNOSTIC: workflow-state-machine.sh not sourced in this block" >&2
  exit 1
fi
```

### Automated Validation

- [ ] Linter passes: `bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/YOUR_COMMAND.md`
- [ ] No errors reported
- [ ] No warnings for critical functions (warnings acceptable for non-critical)

### Manual Testing

- [ ] Run command through at least one complete workflow
- [ ] Verify no exit code 127 errors: `/errors --command /YOUR_COMMAND --since 10m`
- [ ] Verify state persistence works across bash blocks
- [ ] Test error recovery paths

## Common Violations and Fixes

| Violation | Detection | Fix |
|-----------|-----------|-----|
| Missing library re-source | Exit 127 on function call | Add source statement in block |
| Bare error suppression | Linter ERROR | Add `\|\| { echo "ERROR"; exit 1; }` |
| Missing defensive check | Linter WARNING | Add `type FUNC &>/dev/null` check |
| Wrong sourcing order | State errors | Source state-persistence before workflow-state-machine |
| Missing `set +H` | Bad substitution error | Add `set +H` at block start |
| Missing `CLAUDE_PROJECT_DIR` | Path resolution fails | Add git-based detection |

## Quick Validation Script

Run this before committing:

```bash
#!/usr/bin/env bash
# Quick validation for command compliance

COMMAND_FILE="${1:-.claude/commands/YOUR_COMMAND.md}"

echo "Validating $COMMAND_FILE..."

# Run linter
if bash .claude/scripts/lint/check-library-sourcing.sh "$COMMAND_FILE"; then
  echo "Linter: PASSED"
else
  echo "Linter: FAILED"
  exit 1
fi

# Check for bare suppressions on critical libraries
if grep -E 'source.*/(state-persistence|workflow-state-machine|error-handling)\.sh.*2>/dev/null\s*$' "$COMMAND_FILE"; then
  echo "ERROR: Bare error suppression on critical library"
  exit 1
fi

echo "Validation complete"
```

## Automated Enforcement

Pre-commit hook validates these requirements automatically. Bypass with `git commit --no-verify` only if you have documented justification in commit message.

**When Bypass is Acceptable**:
- Documentation-only changes (no bash code)
- Emergency hotfixes (with follow-up compliance fix)
- False positive confirmed by team

**When Bypass is NOT Acceptable**:
- New command development
- Modifications to bash blocks
- Adding new library dependencies

## Related Documentation

- [Code Standards - Mandatory Bash Block Sourcing Pattern](../standards/code-standards.md#mandatory-bash-block-sourcing-pattern)
- [Output Formatting Standards - Error Suppression](../standards/output-formatting.md#mandatory-error-suppression-on-critical-libraries)
- [Bash Block Execution Model](../../concepts/bash-block-execution-model.md)
- [Exit Code 127 Troubleshooting Guide](../../troubleshooting/exit-code-127-command-not-found.md)
- [Linting Bash Sourcing Guide](../../guides/development/linting-bash-sourcing.md)

---

**Last Updated**: 2025-11-21
**Spec Reference**: 105_build_state_management_bash_errors_fix (Phase 7)
