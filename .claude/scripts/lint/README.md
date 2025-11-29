# Linting Scripts

Code quality validation scripts for .claude/ codebase standards compliance.

## Purpose

This directory contains specialized linting scripts that enforce code quality standards across the .claude/ codebase. Scripts are invoked by validate-all-standards.sh during pre-commit hooks and CI validation to ensure consistent code quality.

## Files in This Directory

### check-library-sourcing.sh
**Purpose**: Validates three-tier library sourcing pattern compliance
**Checks**:
- Tier 1 libraries include fail-fast error handlers
- All bash blocks follow mandatory sourcing pattern
- State persistence and workflow libraries properly sourced
**Usage**: `bash check-library-sourcing.sh [file|directory]`
**Exit Code**: 0 (compliant), 1 (violations found)

### check-error-logging-coverage.sh
**Purpose**: Validates error logging integration across commands and agents
**Checks**:
- Commands source error-handling.sh library
- Error logging initialized (ensure_error_log_exists)
- Workflow metadata set (COMMAND_NAME, WORKFLOW_ID)
- Errors logged using log_command_error()
**Usage**: `bash check-error-logging-coverage.sh [file|directory]`
**Exit Code**: 0 (compliant), 1 (violations found)

### check-unbound-variables.sh
**Purpose**: Detects unbound variable references in bash scripts
**Checks**:
- Variables referenced before assignment
- Undefined parameter expansions
- Unset variables in conditional expressions
**Usage**: `bash check-unbound-variables.sh [file|directory]`
**Exit Code**: 0 (compliant), 1 (violations found)

## Integration with validate-all-standards.sh

Linters are invoked by the unified validation script:

```bash
# Run all linters
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --all

# Run specific linter category
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --sourcing
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --error-logging
bash /home/benjamin/.config/.claude/scripts/validate-all-standards.sh --unbound-vars
```

## Enforcement

Linters are integrated into:
- **Pre-commit hooks**: Automatic validation on staged .claude/ files
- **CI validation**: Comprehensive validation on all changes
- **Manual validation**: Developer-initiated quality checks

Violations block commits (ERROR-level) or generate warnings (WARNING-level) depending on severity.

## Navigation

- [← Parent Directory](../README.md)
- [Scripts Overview](../README.md)
- [Enforcement Mechanisms](../../docs/reference/standards/enforcement-mechanisms.md)
