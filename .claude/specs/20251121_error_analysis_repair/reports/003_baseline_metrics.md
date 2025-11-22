# Baseline Metrics Report

**Date**: 2025-11-21
**Phase**: 0 - Baseline Validation

## Sourcing Linter Violations

**Total Violations**: 128 warnings

### Breakdown by Command

| Command | Violation Count | Functions Missing |
|---------|-----------------|-------------------|
| `/repair.md` | ~20 | `save_completed_states_to_state`, `append_workflow_state`, `load_workflow_state` |
| `/revise.md` | ~15 | `save_completed_states_to_state`, `append_workflow_state` |
| `/build.md` | ~30 | `save_completed_states_to_state`, `append_workflow_state` |
| `/plan.md` | ~25 | `append_workflow_state` |
| `/research.md` | ~10 | `save_completed_states_to_state` |
| Other files | ~28 | Various |

## Error Log Counts (errors.jsonl)

| Command | Error Count |
|---------|-------------|
| `/build` | 10 |
| `/errors` | 7 |
| `/plan` | 12 |
| `/revise` | 3 |
| `/research` | 2 |
| `/debug` | 3 |
| `/repair` | 0 |

## Exit Code 127 Errors

**Total**: 15 exit code 127 errors in test error log

## Error Suppression Linter

**Status**: PASS (0 violations)

## Pre-commit Hook Status

**Status**: NOT INSTALLED

The pre-commit hook file does not exist at `.git/hooks/pre-commit`.

## Summary

- Library sourcing violations are widespread across workflow commands
- Primary functions missing defensive checks: `save_completed_states_to_state`, `append_workflow_state`, `load_workflow_state`
- Error suppression patterns are compliant
- Pre-commit hook needs installation as part of Phase 3

## Next Steps

1. Fix library sourcing in Phase 1 (highest priority commands: build, errors, plan, revise, research)
2. Install pre-commit hook in Phase 3 for regression prevention
