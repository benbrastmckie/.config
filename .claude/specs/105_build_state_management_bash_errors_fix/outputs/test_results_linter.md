# Test Execution Report

## Metadata
- **Date**: 2025-11-21 (execution time)
- **Plan**: /home/benjamin/.config/.claude/specs/105_build_state_management_bash_errors_fix/plans/001_debug_strategy.md
- **Test Framework**: bash-linter
- **Test Command**: bash /home/benjamin/.config/.claude/scripts/lint/check-library-sourcing.sh
- **Exit Code**: 1
- **Execution Time**: <1s
- **Environment**: test

## Summary
- **Total Tests**: 15 (files checked)
- **Passed**: 9 (files with 0 errors)
- **Failed**: 6 (files with errors)
- **Skipped**: 0
- **Coverage**: N/A

## Error Summary
- **Total Errors**: 51
- **Total Warnings**: 109

## Failed Tests (Files with Errors)

1. `.claude/commands/repair.md` - 9 errors, 21 warnings
   - Lines 122, 123, 125, 306, 307, 308, 522, 523, 524: Bare error suppression on critical libraries (state-persistence.sh, workflow-state-machine.sh, error-handling.sh)

2. `.claude/commands/revise.md` - 7 errors, 17 warnings
   - Lines 44, 372, 537, 538, 800, 801, 894: Bare error suppression on critical libraries

3. `.claude/commands/optimize-claude.md` - 1 error
   - Line 258: Bare error suppression on error-handling.sh

4. `.claude/commands/research.md` - 4 errors, 13 warnings
   - Lines 312, 477, 478, 479: Bare error suppression on critical libraries

5. `.claude/commands/debug.md` - 30 errors, many warnings
   - Lines 144-1150: Multiple bare error suppressions across 9 bash blocks

6. Additional warnings in passing files:
   - `.claude/commands/build.md` - 22 warnings (missing defensive checks)
   - `.claude/commands/plan.md` - 21 warnings (missing defensive checks)

## Error Categories

### ERROR: Bare error suppression on critical libraries
Pattern: `source ".../{critical_lib}" 2>/dev/null` without fail-fast handler

**Critical libraries requiring fail-fast handlers:**
- `state-persistence.sh` - 17 violations
- `workflow-state-machine.sh` - 10 violations
- `error-handling.sh` - 24 violations

**Fix:** Add fail-fast handler: `|| { echo "ERROR: Cannot load {lib}"; exit 1; }`

### WARNING: Missing defensive checks
Pattern: Function calls without prior type checks

**Functions requiring defensive checks:**
- `save_completed_states_to_state` - 10 instances
- `append_workflow_state` - 79 instances
- `load_workflow_state` - 20 instances

**Fix:** Add defensive check: `if ! type {func} &>/dev/null; then exit 1; fi`

## Full Output

```bash
Checking library sourcing patterns in 15 file(s)...

Checking: .claude/commands/repair.md
ERROR: .claude/commands/repair.md:122
  Bare error suppression on critical library: state-persistence.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:306
  Bare error suppression on critical library: state-persistence.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:522
  Bare error suppression on critical library: state-persistence.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:123
  Bare error suppression on critical library: workflow-state-machine.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:307
  Bare error suppression on critical library: workflow-state-machine.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:523
  Bare error suppression on critical library: workflow-state-machine.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:125
  Bare error suppression on critical library: error-handling.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:308
  Bare error suppression on critical library: error-handling.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }
ERROR: .claude/commands/repair.md:524
  Bare error suppression on critical library: error-handling.sh

  Found:   source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null
  Fix:     Add fail-fast handler: || { echo "ERROR: ..."; exit 1; }

[... additional errors and warnings for repair.md ...]

Checking: .claude/commands/errors.md
Checking: .claude/commands/expand.md
Checking: .claude/commands/templates/README.md
Checking: .claude/commands/revise.md
ERROR: .claude/commands/revise.md:537
  Bare error suppression on critical library: state-persistence.sh
ERROR: .claude/commands/revise.md:800
  Bare error suppression on critical library: state-persistence.sh
ERROR: .claude/commands/revise.md:44
  Bare error suppression on critical library: error-handling.sh
ERROR: .claude/commands/revise.md:372
  Bare error suppression on critical library: error-handling.sh
ERROR: .claude/commands/revise.md:538
  Bare error suppression on critical library: error-handling.sh
ERROR: .claude/commands/revise.md:801
  Bare error suppression on critical library: error-handling.sh
ERROR: .claude/commands/revise.md:894
  Bare error suppression on critical library: error-handling.sh

[... additional warnings for revise.md ...]

Checking: .claude/commands/shared/README.md
Checking: .claude/commands/convert-docs.md
Checking: .claude/commands/optimize-claude.md
ERROR: .claude/commands/optimize-claude.md:258
  Bare error suppression on critical library: error-handling.sh

Checking: .claude/commands/research.md
ERROR: .claude/commands/research.md:477
  Bare error suppression on critical library: state-persistence.sh
ERROR: .claude/commands/research.md:478
  Bare error suppression on critical library: workflow-state-machine.sh
ERROR: .claude/commands/research.md:312
  Bare error suppression on critical library: error-handling.sh
ERROR: .claude/commands/research.md:479
  Bare error suppression on critical library: error-handling.sh

[... additional warnings for research.md ...]

Checking: .claude/commands/build.md
[22 warnings for missing defensive checks]

Checking: .claude/commands/plan.md
[21 warnings for missing defensive checks]

Checking: .claude/commands/collapse.md
Checking: .claude/commands/debug.md
ERROR: .claude/commands/debug.md:144
  Bare error suppression on critical library: state-persistence.sh
[... 29 more errors across multiple bash blocks ...]

==========================================
SUMMARY
==========================================
Errors:   51
Warnings: 109

FAILED: 51 error(s) must be fixed
```
