# Pre-Commit Hooks Guide

This guide covers the pre-commit hooks available for the `.claude/` infrastructure, focusing on automated validation before commits.

## Overview

Pre-commit hooks provide automated enforcement of code standards at commit time, catching violations before they enter the codebase. This enables a shift-left approach to quality where issues are fixed during development rather than discovered in code review or runtime.

## Available Pre-Commit Hooks

### Library Sourcing Linter Hook

**File**: `.claude/hooks/pre-commit-library-sourcing.sh`

**Purpose**: Validates that bash blocks in command files follow the three-tier sourcing pattern.

**Checks Performed**:
1. **Bare Error Suppression**: Detects critical libraries sourced with `2>/dev/null` but no fail-fast handler
2. **Defensive Checks**: Warns when critical function calls lack preceding `type` checks

**Blocked Patterns**:
```bash
# BLOCKED - bare error suppression on critical library
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null

# ALLOWED - fail-fast handler present
source "${CLAUDE_LIB}/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
```

**Critical Libraries** (fail-fast required):
- `state-persistence.sh`
- `workflow-state-machine.sh`
- `error-handling.sh`

## Installation

### Option 1: Symlink (Recommended)

Creates a symlink from `.git/hooks/pre-commit` to the hook script, ensuring updates to the script are automatically used:

```bash
cd /path/to/project
ln -sf ../../.claude/hooks/pre-commit-library-sourcing.sh .git/hooks/pre-commit
```

### Option 2: Direct Copy

Copies the hook to `.git/hooks/`. Note: Updates to the source script won't be reflected:

```bash
cd /path/to/project
cp .claude/hooks/pre-commit-library-sourcing.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Option 3: Append to Existing Hook

If you have an existing pre-commit hook, add a call to the library sourcing hook:

```bash
# In .git/hooks/pre-commit
# ... existing hook logic ...

# Add library sourcing validation
if [ -f "$PROJECT_DIR/.claude/hooks/pre-commit-library-sourcing.sh" ]; then
  bash "$PROJECT_DIR/.claude/hooks/pre-commit-library-sourcing.sh" || exit 1
fi
```

### Option 4: Using /setup Command

The `/setup` command can automatically install the pre-commit hook during project setup.

## Bypassing the Hook

When you need to commit despite violations (e.g., work in progress, documented exception), use the `--no-verify` flag:

```bash
git commit --no-verify -m "WIP: Partial implementation (sourcing fix pending)"
```

**Important**: When bypassing:
1. Document the reason in the commit message
2. Create a follow-up task to fix the violations
3. Do not merge to main branch with violations

### Valid Bypass Reasons

- **Work in Progress**: Saving incomplete work for context switching
- **Legacy Code**: Updating unrelated parts of a file with existing violations
- **Documented Exception**: Library intentionally uses different pattern (must be documented)
- **Emergency Fix**: Critical production fix that cannot wait for full compliance

### Invalid Bypass Reasons

- **Convenience**: "It takes too long to fix"
- **Ignorance**: "I don't understand the pattern"
- **Disagreement**: "I don't think this check is necessary"

## Troubleshooting

### Hook Not Running

1. **Check hook is executable**:
   ```bash
   ls -la .git/hooks/pre-commit
   # Should show: -rwxr-xr-x
   ```

2. **Check hook path**:
   ```bash
   # Hook should exist and point to correct location
   readlink .git/hooks/pre-commit
   ```

3. **Run hook manually**:
   ```bash
   bash .git/hooks/pre-commit
   ```

### False Positives

If the linter incorrectly flags compliant code:

1. **Verify pattern matches documentation**:
   - Check `code-standards.md` for exact required pattern
   - Compare with template at `.claude/docs/guides/templates/_template-bash-block.md`

2. **Report false positive**:
   - Open issue describing the pattern flagged
   - Include file path and line number
   - Explain why pattern should be allowed

### Hook Blocks Valid Commit

If you believe the hook is incorrectly blocking a commit:

1. **Review the violations**: Are they truly false positives?
2. **Check recent linter updates**: Was the check recently added?
3. **Bypass with documentation**: Use `--no-verify` and document in commit message
4. **Fix the violations**: Often faster than investigating edge cases

### Linter Not Found

```
WARNING: Linter not found at .claude/scripts/lint/check-library-sourcing.sh
```

The linter script is missing. Either:
1. Run `git pull` to get the linter script
2. Check if `.claude/scripts/lint/` directory exists
3. Reinstall the hook infrastructure

## How the Hook Works

```
                                   git commit
                                       |
                                       v
                            +---------------------+
                            | .git/hooks/pre-commit |
                            +---------------------+
                                       |
                                       v
                            +---------------------+
                            | Detect staged files |
                            | (*.md in commands/) |
                            +---------------------+
                                       |
                          +------------+------------+
                          |                         |
                          v                         v
                  No command files          Command files staged
                     staged                        |
                          |                        v
                          |           +-------------------------+
                          |           | Run library sourcing    |
                          |           | linter on staged files  |
                          |           +-------------------------+
                          |                        |
                          |           +------------+------------+
                          |           |                         |
                          v           v                         v
                   Exit 0 (allow)  No violations           Violations found
                                       |                        |
                                       v                        v
                                 Exit 0 (allow)           Exit 1 (block)
                                                                |
                                                                v
                                                         Print violations
                                                         and remediation
```

## Related Documentation

- [Linting Bash Sourcing](linting-bash-sourcing.md) - Manual linter usage and violation fixes
- [Code Standards](../../reference/standards/code-standards.md) - Complete coding standards
- [Bash Block Execution Model](../../concepts/bash-block-execution-model.md) - Why re-sourcing is required
- [Three-Tier Sourcing Pattern](../../reference/standards/code-standards.md#three-tier-library-sourcing-pattern) - Pattern specification

## Best Practices

### For Command Authors

1. **Use the template**: Start from `.claude/docs/guides/templates/_template-bash-block.md`
2. **Run linter locally**: Test before committing with `bash .claude/scripts/lint/check-library-sourcing.sh`
3. **Fix immediately**: Address violations as they appear, not later

### For Repository Maintainers

1. **Install hooks in CI**: Run linter in CI pipeline as a backup
2. **Keep linter updated**: Add new checks as patterns evolve
3. **Document exceptions**: Maintain list of known acceptable patterns

---

**Parent**: [Development Guides](README.md)
**Related**: [Hook Scripts](../../../hooks/README.md) | [Linter Scripts](../../../scripts/lint/)
