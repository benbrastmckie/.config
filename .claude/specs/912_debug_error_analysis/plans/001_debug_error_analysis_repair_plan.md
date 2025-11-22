# Implementation Plan: /debug Command Library Sourcing Fix

## Metadata
| Field | Value |
|-------|-------|
| Plan ID | 001 |
| Feature | Fix /debug command library sourcing errors |
| Complexity | 2 |
| Workflow Type | repair |
| Research Report | reports/001_error_report.md |
| Created | 2025-11-21 |
| Target Command | .claude/commands/debug.md |

## Executive Summary

The `/debug` command is experiencing exit code 127 (command not found) errors due to inconsistent library sourcing across bash blocks. The primary issue is that `initialize_workflow_paths` function is being called in Part 3 without first sourcing `workflow-initialization.sh`. While Part 2a correctly sources this library, Part 3 only sources `unified-location-detection.sh` but omits `workflow-initialization.sh`. This violates the mandatory three-tier bash sourcing pattern documented in code-standards.md.

**Root Cause Analysis**:
- 50% of errors: `initialize_workflow_paths` not found (exit code 127)
- 25% of errors: Benign bashrc sourcing (expected behavior, can be filtered)
- 25% of errors: Cascading `return 1` failures from above

**Fix Strategy**: Add `workflow-initialization.sh` sourcing to Part 3 bash block before calling `initialize_workflow_paths`, ensuring consistency with the three-tier sourcing pattern used in other commands like `/plan` and `/repair`.

## Phase 1: Fix Library Sourcing in Part 3

### Stage 1.1: Add workflow-initialization.sh Sourcing to Part 3

**Location**: `/home/benjamin/.config/.claude/commands/debug.md`, Part 3 bash block (lines ~515-672)

**Current Code** (line 530):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh"
```

**Required Fix**: Add `workflow-initialization.sh` sourcing after `unified-location-detection.sh`:

- [x] Add sourcing of `workflow-initialization.sh` with fail-fast handler after line 530
- [x] Follow the three-tier pattern: error-handling.sh already sourced (Tier 1), add workflow-initialization.sh (Tier 2)
- [x] Use `2>/dev/null || { echo "ERROR:..."; exit 1; }` pattern for fail-fast

**Expected Change**:
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-initialization.sh" >&2
  exit 1
}
```

**Acceptance Criteria**:
- `workflow-initialization.sh` is sourced before `initialize_workflow_paths` is called
- Fail-fast error handling is in place
- Pattern matches other commands (plan.md, repair.md)

### Stage 1.2: Verify Sourcing Consistency Across All Bash Blocks

Review all bash blocks in `/debug` command to ensure consistent library sourcing.

- [x] Part 1 (lines ~28-161): Verify error-handling.sh sourced - CONFIRMED
- [x] Part 2 (lines ~167-306): Verify all Tier 1 and Tier 2 libraries sourced - CONFIRMED
- [x] Part 2a (lines ~340-509): Verify workflow-initialization.sh sourced - CONFIRMED (line 356)
- [x] Part 3 (lines ~515-672): Add workflow-initialization.sh - FIXED (line 534)
- [x] Part 4 (lines ~800-917): Does not call initialize_workflow_paths - OK
- [x] Part 5 (lines ~1047-1167): Does not call initialize_workflow_paths - OK
- [x] Part 6 (lines ~1276-1422): Does not call initialize_workflow_paths - OK

**Acceptance Criteria**:
- All bash blocks that call `initialize_workflow_paths` have `workflow-initialization.sh` sourced
- No bash block calls functions from libraries not sourced in that block

## Phase 2: Add Defensive Function Validation

### Stage 2.1: Add Pre-flight Function Check Before initialize_workflow_paths

Following the pattern from `/plan` command, add a defensive check before calling `initialize_workflow_paths`.

**Location**: Part 3 bash block, before the `initialize_workflow_paths` call (around line 633)

- [x] Add function existence validation using `declare -f` or `type` command
- [x] Log error via `log_command_error` if function not available
- [x] Provide diagnostic message pointing to workflow-initialization.sh

**Expected Pattern** (already exists in Part 2a, ensure Part 3 has it too):
```bash
# === DEFENSIVE CHECK: Verify initialize_workflow_paths available ===
if ! type initialize_workflow_paths &>/dev/null; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "dependency_error" \
    "initialize_workflow_paths function not available" \
    "bash_block_3" \
    "$(jq -n '{missing_function: "initialize_workflow_paths", expected_library: "workflow-initialization.sh"}')"

  echo "ERROR: initialize_workflow_paths function not available" >&2
  echo "DIAGNOSTIC: workflow-initialization.sh library not properly sourced" >&2
  exit 1
fi
```

**Acceptance Criteria**:
- Function existence check present in Part 3 before `initialize_workflow_paths` call
- Error logged to centralized error log for queryability
- Clear diagnostic message provided

### Stage 2.2: Verify Error Trap Setup in Part 3

Ensure bash error trap is set up correctly to catch any remaining issues.

- [x] Verify `setup_bash_error_trap` is called after error-handling.sh sourcing
- [x] Confirm COMMAND_NAME, WORKFLOW_ID, USER_ARGS are exported before trap setup
- [x] Check trap catches exit code 127 errors and logs them

**Acceptance Criteria**:
- Error trap is active in Part 3
- Exit code 127 errors are logged with full context

## Phase 3: Validation and Testing

### Stage 3.1: Manual Validation

- [x] Run `/debug "test issue"` and verify no exit code 127 errors
- [x] Check error log after run: `/errors --command /debug --limit 5`
- [x] Verify workflow completes through all phases (research, plan, debug)

**Acceptance Criteria**:
- No `initialize_workflow_paths not found` errors
- Workflow progresses through all phases
- Error log shows no new errors from /debug command

### Stage 3.2: Verify Library Sourcing Linter Compliance

- [x] Run bash sourcing linter on debug.md: `bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/debug.md`
- [x] Fix any reported violations
- [x] Ensure pre-commit hook would pass

**Acceptance Criteria**:
- Linter reports no errors for debug.md
- Pattern matches reference commands (plan.md, repair.md)

## Implementation Notes

### Three-Tier Sourcing Pattern Reference

From code-standards.md, the mandatory pattern is:

**Tier 1: Critical Foundation** (fail-fast required)
- state-persistence.sh
- workflow-state-machine.sh
- error-handling.sh

**Tier 2: Workflow Support** (graceful degradation allowed)
- unified-location-detection.sh
- workflow-initialization.sh
- library-version-check.sh

**Tier 3: Optional Features** (silent failures acceptable)
- summary-formatting.sh

### Pattern from /plan Command (Reference Implementation)

The `/plan` command correctly sources libraries in Block 1a:
```bash
# Tier 1: Critical Foundation (fail-fast required)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true
```

### Benign Error Filtering

The bashrc sourcing error (Pattern 2 in error report) is benign and expected. This is documented in `.claude/docs/troubleshooting/exit-code-127-command-not-found.md`. No action required - the error handling infrastructure correctly identifies this as benign.

## Dependencies

- Phase 2 depends on Phase 1 completion (sourcing must work before validation can be added)
- Phase 3 depends on Phase 1 and Phase 2 completion

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking existing /debug functionality | Low | High | Follow exact pattern from working commands |
| Introducing new sourcing errors | Low | Medium | Run linter before committing |
| Missing edge cases | Low | Low | Error traps will catch and log any issues |

## Estimated Effort

| Phase | Estimated Time |
|-------|----------------|
| Phase 1 | 15 minutes |
| Phase 2 | 10 minutes |
| Phase 3 | 10 minutes |
| **Total** | **35 minutes** |

## Success Criteria

1. `/debug` command executes without exit code 127 errors
2. `initialize_workflow_paths` function is always available when called
3. Library sourcing pattern matches reference commands (plan.md, repair.md)
4. Bash sourcing linter passes on debug.md
5. Error log shows no new errors from subsequent /debug executions
