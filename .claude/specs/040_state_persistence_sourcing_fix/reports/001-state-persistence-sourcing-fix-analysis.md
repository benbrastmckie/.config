# State Persistence Sourcing Violations Analysis

**Research Date**: 2025-12-09
**Research Complexity**: 2
**Commands Analyzed**: repair.md, todo.md
**Reference Command**: create-plan.md (correct pattern)

## Executive Summary

Identified state-persistence sourcing violations in repair.md and todo.md command files where multiple bash blocks are missing required Tier 1 library sourcing patterns. The three-tier sourcing pattern is mandatory per code-standards.md but several blocks in both commands use state persistence functions without re-sourcing the library, which will cause exit code 127 failures due to subprocess isolation.

**Key Findings**:
- repair.md: 5 blocks missing state-persistence.sh sourcing (Blocks 1b, 1c, 2b, 2a-standards, 2c)
- todo.md: 3 blocks missing complete Tier 1 sourcing (Blocks 2c, 3, Completion block)
- Missing validation-utils.sh sourcing in both files (required as Tier 1 per code-standards.md line 64-66)
- All affected blocks call state persistence functions without re-sourcing

## Standards Reference

### Three-Tier Sourcing Pattern (code-standards.md lines 34-89)

**Tier 1: Critical Foundation (fail-fast required)**:
```bash
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2
  exit 1
}
```

**Why Mandatory** (code-standards.md lines 85-88):
> "Each bash block in Claude Code runs in a **new subprocess**. Variables and functions from previous blocks are NOT available. Without re-sourcing libraries, function calls fail with exit code 127 ("command not found")."

## Detailed Violation Analysis

### repair.md Violations

#### Block 1b: Report Path Pre-Calculation (Lines 387-538)

**Issue**: Missing state-persistence.sh sourcing
**Current Pattern** (lines 433-441):
```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

**Functions Used**:
- Line 527: `append_workflow_state "REPORT_PATH" "$REPORT_PATH"`
- Line 528: `append_workflow_state "REPORT_NUMBER" "$REPORT_NUMBER"`
- Line 529: `append_workflow_state "REPORT_SLUG" "$REPORT_SLUG"`

**Missing Libraries**:
- validation-utils.sh (Tier 1 - required per code-standards.md line 64-66)
- workflow-state-machine.sh (Tier 1 - required for state operations)

**Impact**: Low (currently sources state-persistence.sh and error-handling.sh correctly, but incomplete pattern)

#### Block 1c: Error Analysis Verification (Lines 578-699)

**Issue**: Missing state-persistence.sh sourcing entirely
**Current Pattern** (lines 632-636):
```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
```

**Functions Used**: None directly, but follows standard pattern requiring state persistence for error logging

**Missing Libraries**:
- state-persistence.sh (Tier 1 - CRITICAL)
- workflow-state-machine.sh (Tier 1)
- validation-utils.sh (Tier 1)

**Impact**: Medium (no state functions called, but violates mandatory pattern)

#### Block 2a: Planning Setup (Lines 701-927)

**Issue**: Complete Tier 1 sourcing present (lines 736-746), no violation in this block

#### Block 2a-standards: Extract Project Standards (Lines 929-1037)

**Issue**: Missing state-persistence.sh and validation-utils.sh sourcing
**Current Pattern** (lines 980-986):
```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

**Functions Used**:
- Line 1024-1026: `append_workflow_state "FORMATTED_STANDARDS<<STANDARDS_EOF...`

**Missing Libraries**:
- workflow-state-machine.sh (Tier 1)
- validation-utils.sh (Tier 1)

**Impact**: Low (has state-persistence.sh, missing other Tier 1 libs)

#### Block 2b: Plan Path Pre-Calculation (Lines 1039-1203)

**Issue**: Missing validation-utils.sh sourcing
**Current Pattern** (lines 1092-1099):
```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

**Functions Used**:
- Line 1173: `append_workflow_state "PLAN_PATH" "$PLAN_PATH"`
- Line 1174-1177: Multiple append_workflow_state calls
- Line 1180: `save_completed_states_to_state`

**Missing Libraries**:
- workflow-state-machine.sh (Tier 1)
- validation-utils.sh (Tier 1)

**Impact**: Medium (save_completed_states_to_state call requires full Tier 1 context)

#### Block 2c: Plan Verification (Lines 1264-1386)

**Issue**: Missing state-persistence.sh entirely
**Current Pattern** (lines 1319-1323):
```bash
# Source libraries
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
```

**Functions Used**: None directly

**Missing Libraries**:
- state-persistence.sh (Tier 1 - CRITICAL)
- workflow-state-machine.sh (Tier 1)
- validation-utils.sh (Tier 1)

**Impact**: Medium (violates mandatory pattern, error logging may fail)

### todo.md Violations

#### Block 2c: TODO.md Semantic Verification (Lines 466-621)

**Issue**: Missing validation-utils.sh and workflow-state-machine.sh
**Current Pattern** (lines 488-495):
```bash
# === SOURCE LIBRARIES ===
# Re-source libraries (subprocess isolation requires re-sourcing)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
```

**Functions Used**:
- Line 499: `STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)` (direct file access, not function)
- Line 501: `source "$STATE_FILE"` (state file sourcing)

**Missing Libraries**:
- workflow-state-machine.sh (Tier 1 - NOTE: /todo is utility command, may not need SM)
- validation-utils.sh (Tier 1)

**Impact**: Low (todo is utility command without state machine requirement per line 199)

#### Block 3: Atomic File Replace (Lines 623-756)

**Issue**: Missing validation-utils.sh (if needed)
**Current Pattern** (lines 649-650):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || exit 1
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || exit 1
```

**Functions Used**:
- Line 653: `STATE_FILE=$(ls -t ~/.claude/data/state/todo_*.state 2>/dev/null | head -1)`
- Line 706: `log_command_error` (requires error-handling.sh - present)

**Missing Libraries**:
- workflow-state-machine.sh (Tier 1 - NOTE: /todo is utility command)
- validation-utils.sh (Tier 1)

**Impact**: Low (utility command pattern, no state machine usage)

#### Completion Block (Default Mode) (Lines 1272-1323)

**Issue**: Missing error-handling.sh and state-persistence.sh entirely
**Current Pattern** (lines 1295):
```bash
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/summary-formatting.sh" 2>/dev/null || exit 1
```

**Functions Used**: None requiring state persistence

**Missing Libraries**:
- error-handling.sh (Tier 1)
- state-persistence.sh (Tier 1)
- validation-utils.sh (Tier 1)

**Impact**: Low (only uses summary-formatting.sh, no state operations)

## Pre-Flight Validation Patterns Missing

### State Restoration Validation (code-standards.md lines 145-156)

Neither repair.md nor todo.md implement the recommended state restoration validation pattern:

```bash
# Block 2+ (after load_workflow_state)
load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" "PLAN_PATH" || {
  echo "ERROR: State restoration failed" >&2
  exit 1
}
```

**Current Pattern** (repair.md Block 2a, lines 841-862):
- Manual validation via if-then checks
- No validate_state_restoration function call
- Defensive but verbose

**Impact**: Medium (no standardized validation, manual checks are inconsistent)

## Working Reference: create-plan.md

### Correct Tier 1 Sourcing Pattern (Lines 123-145)

```bash
# === SOURCE LIBRARIES (Three-Tier Pattern) ===
# Tier 1: Critical Foundation (fail-fast required)
# NOTE: error-handling.sh MUST be sourced first to enable _buffer_early_error
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# Now use _source_with_diagnostics for remaining libraries
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-state-machine.sh" || exit 1
_source_with_diagnostics "${CLAUDE_PROJECT_DIR}/.claude/lib/core/library-version-check.sh" || exit 1

# Tier 2: Workflow Support (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/unified-location-detection.sh" 2>/dev/null || true
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/workflow-initialization.sh" 2>/dev/null || true

# Tier 3: Helper utilities (graceful degradation)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Cannot load validation-utils.sh - required for workflow validation" >&2
  exit 1
}
```

**Note**: create-plan.md treats validation-utils.sh as Tier 3 with fail-fast, but code-standards.md line 64-66 classifies it as Tier 1. This indicates a standards inconsistency that should be clarified.

## Summary of Required Fixes

### repair.md

| Block | Line Range | Missing Libraries | Priority |
|-------|-----------|-------------------|----------|
| Block 1b | 387-538 | validation-utils.sh, workflow-state-machine.sh | Medium |
| Block 1c | 578-699 | state-persistence.sh, workflow-state-machine.sh, validation-utils.sh | **HIGH** |
| Block 2a-standards | 929-1037 | workflow-state-machine.sh, validation-utils.sh | Medium |
| Block 2b | 1039-1203 | workflow-state-machine.sh, validation-utils.sh | Medium |
| Block 2c | 1264-1386 | state-persistence.sh, workflow-state-machine.sh, validation-utils.sh | **HIGH** |

### todo.md

| Block | Line Range | Missing Libraries | Priority |
|-------|-----------|-------------------|----------|
| Block 2c | 466-621 | validation-utils.sh (SM not needed per line 199) | Low |
| Block 3 | 623-756 | validation-utils.sh (SM not needed) | Low |
| Completion | 1272-1323 | error-handling.sh, state-persistence.sh, validation-utils.sh | Low |

**Note**: todo.md is a utility command (not research workflow), so workflow-state-machine.sh is NOT required per line 199 comment. Priority is lower.

## Recommended Fix Pattern

### Standard Block Header (All Blocks)

```bash
set +H  # CRITICAL: Disable history expansion

# === DETECT PROJECT DIRECTORY ===
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

# === SOURCE LIBRARIES (Three-Tier Pattern) ===
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
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2
  exit 1
}

# === RESTORE STATE ===
# (state restoration code here)
```

### For todo.md (Utility Command Pattern)

```bash
# === SOURCE LIBRARIES (Three-Tier Pattern - Utility Command) ===
# Tier 1: Critical Foundation (fail-fast required)
# NOTE: workflow-state-machine.sh NOT required for utility commands
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/state-persistence.sh" 2>/dev/null || {
  echo "ERROR: Failed to source state-persistence.sh" >&2
  exit 1
}
source "${CLAUDE_PROJECT_DIR}/.claude/lib/workflow/validation-utils.sh" 2>/dev/null || {
  echo "ERROR: Failed to source validation-utils.sh" >&2
  exit 1
}
```

## Validation Strategy

### Pre-Commit Validation

Run existing linter to verify fixes:
```bash
bash .claude/scripts/lint/check-library-sourcing.sh
```

Expected output after fix: **No violations**

### Runtime Testing

1. Test repair.md with typical workflow:
   ```bash
   /repair --type state_error --complexity 2
   ```

2. Test todo.md with typical workflow:
   ```bash
   /todo
   /todo --clean --dry-run
   ```

3. Verify no exit code 127 errors in command output

## Standards Clarification Needed

**Issue**: Inconsistency between code-standards.md and create-plan.md regarding validation-utils.sh tier classification:

- code-standards.md (lines 64-66): Classifies validation-utils.sh as **Tier 1** (fail-fast required)
- create-plan.md (lines 141-145): Treats validation-utils.sh as **Tier 3** (but with fail-fast)
- code-standards.md table (lines 74-78): Does NOT list validation-utils.sh in any tier

**Recommendation**: Clarify validation-utils.sh tier classification in code-standards.md table and align all commands to consistent pattern.

## Related Documentation

- [Bash Block Execution Model](.claude/docs/concepts/bash-block-execution-model.md) - Subprocess isolation explanation
- [Exit Code 127 Troubleshooting](.claude/docs/troubleshooting/exit-code-127-command-not-found.md) - Debugging sourcing failures
- [Code Standards](.claude/docs/reference/standards/code-standards.md) - Three-tier sourcing pattern definition
- [Command Authoring Standards](.claude/docs/reference/standards/command-authoring.md) - Command development patterns

## Conclusion

Both repair.md and todo.md have multiple blocks violating the mandatory three-tier sourcing pattern. The most critical violations are:

1. **repair.md Block 1c**: Missing state-persistence.sh entirely (HIGH priority)
2. **repair.md Block 2c**: Missing state-persistence.sh entirely (HIGH priority)
3. **All blocks**: Missing validation-utils.sh sourcing (Tier 1 requirement per code-standards.md)

The fix is straightforward: Add the complete Tier 1 sourcing pattern to each affected block header. The implementation plan should include:

1. Fix all repair.md blocks (5 blocks)
2. Fix all todo.md blocks (3 blocks, lower priority)
3. Add pre-flight validation patterns using validate_state_restoration
4. Clarify validation-utils.sh tier classification in standards
5. Run linter validation
6. Runtime testing of both commands

Estimated implementation time: 2-3 hours (including testing and validation).

## Implementation Status

- **Status**: Implementation Complete
- **Plan**: [../plans/001-state-persistence-sourcing-fix-plan.md](../plans/001-state-persistence-sourcing-fix-plan.md)
- **Date Completed**: 2025-12-09
- **Validation Results**:
  - Linter reports 0 errors for both repair.md and todo.md
  - All 8 blocks fixed with complete Tier 1 sourcing pattern
  - todo.md correctly omits workflow-state-machine.sh (utility command pattern)
  - Additional sourcing added to repair.md continuation block (line ~323)
