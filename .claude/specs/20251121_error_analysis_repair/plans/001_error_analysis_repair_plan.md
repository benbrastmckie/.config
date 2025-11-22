# Error Analysis and Repair Implementation Plan

## Metadata
- **Date**: 2025-11-21 (Revised)
- **Feature**: State Persistence and Missing Function Error Repair
- **Scope**: Fix library sourcing and state persistence issues in workflow commands
- **Estimated Phases**: 4
- **Estimated Hours**: 5.5
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 28.5
- **Research Reports**:
  - [Error Analysis Report](/home/benjamin/.config/.claude/specs/20251121_error_analysis_repair/reports/001_error_analysis.md)
  - [Plan Revision Research](/home/benjamin/.config/.claude/specs/20251121_error_analysis_repair/reports/002_plan_revision_research.md)

## Overview

This plan addresses systemic errors identified in the error analysis report affecting multiple workflow commands. The primary issues are:

1. **Exit Code 127 Errors** (55% of execution errors): Functions `save_completed_states_to_state`, `append_workflow_state`, and `get_next_topic_number` are called without proper library sourcing in bash blocks.

2. **State File Parsing Errors** (5% of errors): State files missing expected keys, causing grep failures when parsing.

3. **Environment Compatibility Errors** (10% of errors): `/etc/bashrc` sourcing failures on NixOS systems.

The root cause is that bash blocks in Claude Code commands do NOT share shell state - each block runs in a new process. Libraries must be re-sourced in every bash block that uses their functions.

## Out of Scope

- **Topic Naming Agent Failures** (4 errors, 7%): Agent communication issues, not library sourcing. Requires separate investigation of Haiku agent output mechanism.
- **Input Validation Errors** (/convert-docs): Expected behavior for invalid user input.
- **Test Command Errors** (/test-t1 through /test-t6): Intentional test errors.

## Research Summary

Key findings from the error analysis and plan revision research reports:

- **Pattern 1**: `save_completed_states_to_state` missing in 8 errors (13%), affecting /build and /revise
- **Pattern 2**: `append_workflow_state` missing in 3 errors (5%), affecting /plan
- **Pattern 6**: `get_next_topic_number` missing in 5 errors (8%), affecting /errors
- **Root Cause 1**: Library sourcing failures account for 27% of all errors (16 errors)
- **Root Cause 3**: Environment-specific bashrc issues account for 10% (6 errors)
- **Root Cause 4**: State file robustness issues cause grep to fail when parsing incomplete state files

## Success Criteria

- [ ] `bash .claude/scripts/lint/check-library-sourcing.sh` returns exit code 0 (no errors)
- [ ] `bash .claude/tests/utilities/lint_error_suppression.sh` returns PASS
- [ ] Zero exit code 127 errors for affected functions in last 24 hours of error log
- [ ] All affected commands pass smoke test with --complexity 1
- [ ] Pre-commit hook blocks new sourcing violations
- [ ] State file parsing includes defensive checks with default values

## Technical Design

### Library Sourcing Architecture

The three-tier sourcing pattern MUST be followed in EVERY bash block. This pattern matches the documented standard in [code-standards.md](../../docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern):

```bash
# 1. Bootstrap: Detect project directory
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi

if [ -z "$CLAUDE_PROJECT_DIR" ] || [ ! -d "$CLAUDE_PROJECT_DIR/.claude" ]; then
  echo "ERROR: Failed to detect project directory" >&2
  exit 1
fi
export CLAUDE_PROJECT_DIR

# 2. Source Critical Libraries (Tier 1 - FAIL-FAST REQUIRED)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2; exit 1
}

# 3. Source Tier 2 Libraries (for specific functionality)
# For commands using get_next_topic_number:
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || {
  echo "ERROR: Failed to source unified-location-detection.sh" >&2; exit 1
}

# 4. Optional Libraries (Tier 3 - graceful degradation allowed)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || true

# 5. Initialize error logging
ensure_error_log_exists
```

### Affected Commands

Commands requiring library sourcing audit (ordered by error count):

| Command | Function Missing | Error Count | Priority |
|---------|------------------|-------------|----------|
| `/build.md` | `save_completed_states_to_state` | 5 | High |
| `/errors.md` | `get_next_topic_number` | 5 | High |
| `/plan.md` | `append_workflow_state` | 3 | High |
| `/revise.md` | `save_completed_states_to_state` | 3 | High |
| `/research.md` | `save_completed_states_to_state` | 1 | Medium |
| `/debug.md` | bashrc environment | 1 | Low |

### Library Dependencies

```
Tier 1: Critical Foundation (FAIL-FAST REQUIRED)
├── state-persistence.sh
│   ├── init_workflow_state()
│   ├── load_workflow_state()
│   └── append_workflow_state()  <-- Required by workflow-state-machine.sh
├── workflow-state-machine.sh
│   ├── save_completed_states_to_state()  <-- Calls append_workflow_state()
│   ├── load_completed_states_from_state()
│   ├── sm_transition()
│   └── sm_get_current_state()
└── error-handling.sh
    ├── ensure_error_log_exists()
    ├── log_command_error()
    └── setup_bash_error_trap()

Tier 2: Workflow Support (FAIL-FAST for affected commands)
├── unified-location-detection.sh
│   ├── detect_project_root()
│   ├── detect_specs_directory()
│   └── get_next_topic_number()  <-- Used by /errors
└── workflow-initialization.sh

Tier 3: Optional (graceful degradation)
├── summary-formatting.sh
└── checkbox-utils.sh
```

## Implementation Phases

### Phase 0: Baseline Validation [COMPLETE]
dependencies: []

**Objective**: Establish baseline violations and verify enforcement tools work.

**Complexity**: Low

Tasks:
- [x] Run `bash .claude/scripts/lint/check-library-sourcing.sh` and document current violation count
- [x] Run `bash .claude/tests/utilities/lint_error_suppression.sh` and document violations
- [x] Verify pre-commit hook is installed: `ls -la .git/hooks/pre-commit`
- [x] Document current error count from `errors.jsonl` for each affected command:
  ```bash
  for cmd in /build /errors /plan /revise /research /debug; do
    echo "$cmd: $(grep "\"command\":\"$cmd\"" ~/.config/.claude/data/logs/errors.jsonl | wc -l) errors"
  done
  ```
- [x] Save baseline metrics to reports/003_baseline_metrics.md

**Expected Duration**: 30 minutes

### Phase 1: Fix Library Sourcing in Affected Commands [COMPLETE]
dependencies: [0]

**Objective**: Ensure all bash blocks that use state management functions source the required libraries with the documented three-tier pattern.

**Complexity**: Medium

Tasks:
- [x] Audit `/build.md` bash blocks:
  - Identify all blocks calling `save_completed_states_to_state`
  - Add full bootstrap pattern (not simplified `${VAR:-...}` pattern)
  - Add fail-fast handlers per code-standards.md
  - Source error-handling.sh and call `ensure_error_log_exists`
- [x] Audit `/errors.md` bash blocks:
  - Identify all blocks calling `get_next_topic_number`
  - Add `unified-location-detection.sh` sourcing with fail-fast
  - Verify Tier 1 libraries also sourced
- [x] Audit `/plan.md` bash blocks:
  - Identify all blocks calling `append_workflow_state`
  - Verify state-persistence.sh sourced in each block
  - Add full bootstrap pattern
- [x] Audit `/revise.md` bash blocks:
  - Identify all blocks calling `save_completed_states_to_state`
  - Add workflow-state-machine.sh sourcing with fail-fast
- [x] Audit `/research.md` bash blocks:
  - Verify consistent sourcing pattern across all blocks

**Pattern for Each Block**:
```bash
# At start of EVERY bash block that uses state functions:
set +H  # Disable history expansion

# Full bootstrap pattern (NOT simplified)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  current_dir="$(pwd)"
  while [ "$current_dir" != "/" ]; do
    [ -d "$current_dir/.claude" ] && { CLAUDE_PROJECT_DIR="$current_dir"; break; }
    current_dir="$(dirname "$current_dir")"
  done
fi
export CLAUDE_PROJECT_DIR

# Source required libraries with fail-fast
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" 2>/dev/null || {
  echo "ERROR: Failed to source workflow-state-machine.sh" >&2; exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2; exit 1
}

# Defensive function availability check
if ! type save_completed_states_to_state &>/dev/null; then
  echo "ERROR: save_completed_states_to_state not available" >&2
  exit 1
fi
```

**Verification after each command fix**:
```bash
# Run linter on modified command
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/COMMAND.md
```

**Expected Duration**: 2 hours

### Phase 1.5: Environment Compatibility Fix [COMPLETE]
dependencies: [1]

**Objective**: Handle NixOS and similar environments where /etc/bashrc doesn't exist.

**Complexity**: Low

Tasks:
- [x] Search for bashrc sourcing in commands:
  ```bash
  grep -r "/etc/bashrc" .claude/commands/ .claude/agents/
  ```
- [x] Replace direct sourcing with conditional:
  ```bash
  # Before (fails on NixOS)
  . /etc/bashrc

  # After (graceful handling)
  [[ -f /etc/bashrc ]] && . /etc/bashrc || true
  ```
- [x] Or remove bashrc sourcing if not required for functionality
- [x] Test on NixOS environment

**Expected Duration**: 30 minutes

### Phase 2: Add State File Parsing Safeguards [COMPLETE]
dependencies: [1]

**Objective**: Add defensive checks when parsing state files to handle missing keys gracefully.

**Complexity**: Low

Tasks:
- [x] Update state file parsing in `/build.md` to check file existence before grep
- [x] Add default value handling for missing PLAN_FILE key
- [x] Add default value handling for missing STATE_FILE key
- [x] Add informative error messages when state files are incomplete

**Pattern for State File Parsing**:
```bash
# Before (causes exit code 1 on missing key)
PLAN_FILE=$(grep "^PLAN_FILE=" "$STATE_FILE" | cut -d'=' -f2-)

# After (handles missing key gracefully)
if [ -f "$STATE_FILE" ]; then
  PLAN_FILE=$(grep "^PLAN_FILE=" "$STATE_FILE" 2>/dev/null | cut -d'=' -f2- || echo "")
  if [ -z "$PLAN_FILE" ]; then
    echo "WARNING: PLAN_FILE not found in state file, using default" >&2
    PLAN_FILE=""
  fi
else
  echo "WARNING: State file not found: $STATE_FILE" >&2
  PLAN_FILE=""
fi
```

**Expected Duration**: 1 hour

### Phase 3: Verification and Regression Prevention [COMPLETE]
dependencies: [1, 1.5, 2]

**Objective**: Verify fixes pass all enforcement tools and document for future reference.

**Complexity**: Low

Tasks:
- [x] Run all validators and verify pass:
  ```bash
  bash .claude/scripts/validate-all-standards.sh --sourcing
  # Expected: PASSED
  ```
- [x] Run error suppression linter:
  ```bash
  bash .claude/tests/utilities/lint_error_suppression.sh
  # Expected: PASS
  ```
- [x] Run affected commands with smoke test:
  ```bash
  /plan "test feature" --complexity 1
  /research "test topic" --complexity 1
  /errors --since 1h --summary
  ```
- [x] Verify error log doesn't contain new 127 errors:
  ```bash
  # Check last 24 hours for exit code 127
  grep '"exit_code":127' ~/.config/.claude/data/logs/errors.jsonl | \
    jq -r 'select(.timestamp > (now - 86400 | todate))' | wc -l
  # Expected: 0 or significantly reduced
  ```
- [x] Verify pre-commit hook blocks intentional violations:
  - Temporarily introduce a sourcing violation
  - Attempt `git commit`
  - Verify commit is blocked
  - Revert the intentional violation
- [x] Update Phase 0 baseline with post-fix metrics
- [x] Create summary report at reports/004_fix_verification.md

**Expected Duration**: 1.5 hours

## Testing Strategy

### Unit Tests
1. Verify library functions are exported correctly after sourcing
2. Test state file parsing with missing keys
3. Test defensive `type` checks fail appropriately

### Integration Tests
1. Run `/plan`, `/revise`, `/research` commands with complexity 1
2. Monitor `errors.jsonl` for new exit code 127 errors
3. Verify workflow state persists across bash blocks

### Linter-Based Verification
```bash
# Full validation suite
bash .claude/scripts/validate-all-standards.sh --all

# Targeted library sourcing check
bash .claude/scripts/lint/check-library-sourcing.sh

# Error suppression patterns
bash .claude/tests/utilities/lint_error_suppression.sh
```

### Command Smoke Tests
```bash
# After fixes, run these and check error log
/plan "smoke test" --complexity 1
/research "smoke test" --complexity 1
/errors --since 1h --summary

# Verify no new 127 errors
tail -50 ~/.config/.claude/data/logs/errors.jsonl | grep -c '"exit_code":127'
```

## Documentation Requirements

- [ ] Update bash-block-execution-model.md if new patterns discovered
- [ ] Add troubleshooting entry for exit-code-127 scenarios if not covered
- [ ] Document any environment-specific considerations (NixOS, etc.)

## Dependencies

- **jq**: Required for JSON serialization in state management
- **flock**: Required for atomic topic number allocation
- **git**: Required for project directory detection
- **Pre-commit hook**: Must be installed for regression prevention

## Risk Assessment

### Low Risk
- Adding library sourcing to existing commands is additive, not modifying core logic
- Defensive checks are fail-fast, won't silently corrupt state
- Existing enforcement tools catch violations

### Mitigation
- Test each command individually after modification
- Run linter before committing changes
- Roll back if error rate increases after deployment
- Phase 0 baseline enables before/after comparison

## References

- [Code Standards - Mandatory Bash Block Sourcing Pattern](../../docs/reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern)
- [Bash Block Execution Model](../../docs/concepts/bash-block-execution-model.md)
- [Enforcement Mechanisms Reference](../../docs/reference/standards/enforcement-mechanisms.md)
- [Exit Code 127 Troubleshooting Guide](../../docs/troubleshooting/exit-code-127-command-not-found.md)
