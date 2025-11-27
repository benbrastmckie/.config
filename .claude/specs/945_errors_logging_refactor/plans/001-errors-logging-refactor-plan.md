# Error Logging Coverage Refactor Implementation Plan

## Metadata
- **Date**: 2025-11-24
- **Feature**: Error Logging Coverage Refactor
- **Scope**: Improve error logging throughout all commands to ensure /errors and /repair commands capture all errors that occur
- **Estimated Phases**: 5
- **Estimated Hours**: 32
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 142.0
- **Research Reports**:
  - [Error Logging Gaps Analysis](/home/benjamin/.config/.claude/specs/945_errors_logging_refactor/reports/001-error-logging-gaps-analysis.md)
  - [Research Errors Validation](/home/benjamin/.config/.claude/specs/938_research_errors_validation/reports/001-validation-report.md)
  - [Debug Error Coverage Validation](/home/benjamin/.config/.claude/specs/942_debug_error_report_validation/reports/001_error_coverage_validation.md)
  - [Build Error Coverage Validation](/home/benjamin/.config/.claude/specs/937_build_error_coverage_validation/reports/001-error-coverage-validation-report.md)
  - [Repair Error Coverage Validation](/home/benjamin/.config/.claude/specs/944_repair_error_coverage_validation/reports/001-error-coverage-validation-report.md)

## Overview

Analysis of error logging coverage across the /research, /debug, /build, and /repair commands reveals critical gaps where 88-96% of error exit points lack error logging. While all 13 commands have error logging integrated, only 2-12% of error exit points actually log before exit, creating blind spots in the /errors and /repair workflows.

This implementation plan addresses three primary gap categories:
1. **Unbound Variable Errors (Gap-UV)**: Exit code 127 from `set -u` violations not logged
2. **State Restoration Failures (Gap-SR)**: Variable restoration between bash blocks fails silently
3. **Early Initialization Failures (Gap-EI)**: Errors before error logging initialized

The refactor will improve error logging coverage from 4-6% to 80%+, ensuring comprehensive error capture for debugging and repair workflows.

## Research Summary

Based on analysis of five validation reports, the following critical gaps were identified:

**From Error Logging Gaps Analysis Report**:
- All 13 commands have error logging integrated (100%)
- Only 10/13 commands have bash error traps (77%)
- Average error exit coverage: 6% (273 total exits, 16 with logging)
- 60% of error exits are validation failures without logging
- Unbound variable errors (exit 127) are completely invisible to error log

**From Validation Reports**:
- Research: 2/3 errors captured (67%), missing `ORIGINAL_PROMPT_FILE_PATH` unbound variable
- Debug: 2/2 errors captured (100%), but root cause misidentified (wrong library stated)
- Build: 0/1 errors captured (0%), state file cleanup error not logged
- Repair: 0/2 errors captured (0%), both unbound variable errors not logged

**Systematic Patterns Identified**:
- Early initialization vulnerability: USER_ARGS fails before error trap configured
- Unbound variables without default syntax: `$VAR` instead of `${VAR:-}`
- Validation failures without logging: ~60% of all error exits
- State restoration failures: Variables not available in subsequent bash blocks

**Infrastructure Assessment**:
- Existing error-handling.sh provides comprehensive tooling (bash traps, environment detection, rotation, lifecycle tracking)
- Commands inconsistently apply patterns documented in standards
- Need for early error logging fallback (before trap initialization)
- Need for state restoration validation helpers

## Success Criteria

- [ ] Error logging coverage increases from 4-6% to 80%+ across all commands
- [ ] All unbound variable errors (exit 127) are logged with context
- [ ] Early initialization failures are captured before trap configuration
- [ ] State restoration failures are detected and logged
- [ ] Validation failure exits include log_command_error calls
- [ ] All commands follow updated bash block initialization pattern
- [ ] Pre-commit hooks enforce error logging coverage (80% threshold)
- [ ] Integration tests verify error logging captures all error scenarios
- [ ] Documentation updated with new patterns and examples
- [ ] Linters prevent future error logging coverage regressions

## Technical Design

### Architecture Principles

1. **Fail-Fast Error Logging**: Errors must be logged before they occur (defensive pattern)
2. **Early Trap Initialization**: Bash error traps configured before variable initialization
3. **Defensive Variable Expansion**: All variable references use default syntax `${VAR:-}`
4. **State Restoration Validation**: Explicit validation after `load_workflow_state`
5. **Comprehensive Coverage**: Every error exit point calls `log_command_error`

### Component Changes

**Error Handling Library Enhancements** (`.claude/lib/core/error-handling.sh`):
- Add `log_early_error()` function for pre-trap initialization errors
- Add `validate_state_restoration()` helper for multi-block workflows
- Add `check_unbound_vars()` helper for defensive variable checking
- Export all new functions for command usage

**Command Updates** (All 13 commands in `.claude/commands/`):
- Update bash block initialization pattern (trap before variables)
- Add default value syntax to all variable expansions
- Add `log_command_error` before all validation exits
- Add state restoration validation in multi-block commands
- Add bash error traps to commands missing them (setup, convert-docs, errors)

**Code Standards Updates** (`.claude/docs/reference/standards/code-standards.md`):
- Add "Error Logging Requirements" section (mandatory log before exit)
- Update "Mandatory Bash Block Pattern" with new trap timing
- Add validation failure logging examples
- Document error_type selection guide

**Linters and Validators**:
- Create `check-error-logging-coverage.sh` (80% threshold)
- Create `check-unbound-variables.sh` (detect unsafe expansions)
- Update `validate-all-standards.sh` with new validators
- Add validators to pre-commit hooks

**Integration Tests**:
- Test validation error logging capture
- Test unbound variable error logging capture
- Test state restoration validation
- Test early initialization error capture
- Add tests to `.claude/tests/run_all_tests.sh`

### Error Classification

Error types used in logging (from error-handling pattern):
- `state_error`: State file missing/corrupted
- `validation_error`: Invalid user input
- `agent_error`: Subagent invocation failure
- `parse_error`: Output parsing failure
- `file_error`: File I/O failure
- `timeout_error`: Operation timeout
- `execution_error`: General execution failure
- `initialization_error`: Early initialization failure (new)

### Integration Points

- **State Persistence**: Commands already use state persistence pattern
- **Error Handling Library**: All commands source error-handling.sh
- **Bash Error Traps**: 10/13 commands already have traps
- **Subagent Error Parsing**: Most commands parse TASK_ERROR signals
- **Documentation Standards**: Follow clean-break development standard

## Implementation Phases

### Phase 1: Critical Gaps - Unbound Variables and Early Initialization [COMPLETE]
dependencies: []

**Objective**: Fix unbound variable errors and early initialization failures that make errors invisible to error logging system

**Complexity**: High

**Tasks**:
- [x] Add default value syntax to ORIGINAL_PROMPT_FILE_PATH in research.md (lines 75, 78, 81, 82, 86, 88, 411, 413, 414, 425)
- [x] Add default value syntax to USER_ARGS in repair.md (line 178)
- [x] Add default value syntax to PLAN_PATH in repair.md (line 890)
- [x] Apply same pattern to plan.md, debug.md, revise.md for similar variables
- [x] Move setup_bash_error_trap before variable initialization in all commands (13 files)
- [x] Add early error trap with placeholder values ("unknown" workflow ID)
- [x] Update trap after variables initialized with actual values
- [x] Test with empty arguments to verify trap catches failures

**Testing**:
```bash
# Test research without --file option (triggers ORIGINAL_PROMPT_FILE_PATH path)
/research "simple query" --complexity 1
# Should not produce unbound variable error

# Test repair without arguments (triggers USER_ARGS failure)
/repair
# Should log error before exit (not exit 127)

# Verify error logged
/errors --command /repair --limit 1 --type initialization_error
# Should show error entry with workflow context
```

**Expected Duration**: 6 hours

### Phase 2: High-Frequency Gaps - Validation Failure Logging [COMPLETE]
dependencies: [1]

**Objective**: Add error logging to validation failure exit points (60% of all error exits)

**Complexity**: High

**Tasks**:
- [x] Audit all commands for validation exit points: `grep -n 'exit 1' *.md | grep -v 'log_command_error'`
- [x] Add log_command_error before argument validation exits (estimated 96 exits)
- [x] Add log_command_error before file/path validation exits (estimated 48 exits)
- [x] Add log_command_error before directory validation exits (estimated 16 exits)
- [x] Choose appropriate error_type for each validation exit (validation_error, file_error, state_error)
- [x] Include diagnostic context in JSON (expected vs actual values)
- [x] Verify error logging coverage: `bash check-error-logging-coverage.sh`

**Pattern Examples**:

Argument validation:
```bash
if [ -z "$PLAN_FILE" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "validation_error" "Plan file path required" "argument_validation" \
    "$(jq -n --arg provided "$*" '{provided_args: $provided}')"
  echo "ERROR: Plan file required" >&2
  exit 1
fi
```

File validation:
```bash
if [ ! -f "$STATE_FILE" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "state_error" "State file not found" "state_validation" \
    "$(jq -n --arg path "$STATE_FILE" '{expected_path: $path}')"
  echo "ERROR: State file not found" >&2
  exit 1
fi
```

Directory validation:
```bash
if [ ! -d "$INPUT_DIR" ]; then
  log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
    "file_error" "Directory not found" "directory_validation" \
    "$(jq -n --arg path "$INPUT_DIR" '{expected_directory: $path}')"
  echo "ERROR: Directory not found" >&2
  exit 1
fi
```

**Testing**:
```bash
# Test validation failures are logged
/build invalid-plan.md 2>&1
/errors --command /build --type validation_error --limit 1
# Should show error entry

# Test file validation failures are logged
/plan nonexistent-file --complexity 2 2>&1
/errors --command /plan --type file_error --limit 1
# Should show error entry

# Run coverage linter
bash .claude/scripts/lint/check-error-logging-coverage.sh
# All commands should show >= 80% coverage
```

**Expected Duration**: 12 hours

### Phase 3: Infrastructure Enhancements [COMPLETE]
dependencies: [1]

**Objective**: Add library helpers and update code standards to support comprehensive error logging

**Complexity**: Medium

**Tasks**:
- [x] Implement `log_early_error()` in error-handling.sh (after line 615)
- [x] Implement `validate_state_restoration()` helper in error-handling.sh
- [x] Implement `check_unbound_vars()` helper in error-handling.sh
- [x] Export all new functions (add to export section at end of file)
- [x] Add unit tests for each helper function
- [x] Add bash error traps to setup.md (currently missing)
- [x] Add bash error traps to convert-docs.md (currently missing)
- [x] Add bash error traps to errors.md (currently missing)
- [x] Update code-standards.md with "Error Logging Requirements" section
- [x] Update code-standards.md with new "Mandatory Bash Block Pattern"
- [x] Add validation failure logging examples to code-standards.md
- [x] Document error_type selection guide in error-handling.md

**log_early_error() Implementation**:
```bash
# Add after line 615 in error-handling.sh
log_early_error() {
  local error_msg="$1"
  local error_context="${2:-{}}"

  # Minimal logging without USER_ARGS dependency
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local cmd="${COMMAND_NAME:-unknown}"
  local wf="${WORKFLOW_ID:-unknown_$(date +%s)}"

  jq -n \
    --arg ts "$ts" \
    --arg cmd "$cmd" \
    --arg wf "$wf" \
    --arg msg "$error_msg" \
    --argjson ctx "$error_context" \
    '{
      timestamp: $ts,
      environment: "production",
      command: $cmd,
      workflow_id: $wf,
      user_args: "",
      error_type: "initialization_error",
      error_message: $msg,
      source: "early_initialization",
      stack: [],
      context: $ctx,
      status: "ERROR",
      status_updated_at: null,
      repair_plan_path: null
    }' >> "${CLAUDE_PROJECT_DIR}/.claude/data/logs/errors.jsonl" 2>/dev/null || true
}

export -f log_early_error
```

**validate_state_restoration() Implementation**:
```bash
validate_state_restoration() {
  local required_vars=("$@")
  local missing_vars=()

  set +u  # Temporarily allow unset
  for var in "${required_vars[@]}"; do
    if [ -z "${!var:-}" ]; then
      missing_vars+=("$var")
    fi
  done
  set -u

  if [ ${#missing_vars[@]} -gt 0 ]; then
    local missing_list=$(printf '%s,' "${missing_vars[@]}")
    log_command_error "${COMMAND_NAME:-unknown}" "${WORKFLOW_ID:-unknown}" \
      "${USER_ARGS:-}" "state_error" \
      "State restoration incomplete: ${missing_list%,}" "state_validation" \
      "$(jq -n --arg vars "$missing_list" '{missing_variables: $vars}')"
    return 1
  fi

  return 0
}

export -f validate_state_restoration
```

**Testing**:
```bash
# Test log_early_error function
bash -c 'source .claude/lib/core/error-handling.sh; log_early_error "test error" "{}"'
tail -1 .claude/data/logs/errors.jsonl | jq .
# Should show initialization_error entry

# Test validate_state_restoration function
bash -c 'source .claude/lib/core/error-handling.sh; validate_state_restoration "NONEXISTENT_VAR"'
# Should return 1 and log state_error

# Test bash traps added to setup, convert-docs, errors
/setup --invalid-flag 2>&1
/errors --command /setup --limit 1
# Should show error logged
```

**Expected Duration**: 8 hours

### Phase 4: State Restoration and Subagent Error Parsing [COMPLETE]
dependencies: [1, 3]

**Objective**: Add state restoration validation to multi-block commands and complete subagent error parsing

**Complexity**: Medium

**Tasks**:
- [x] Add validate_state_restoration calls after load_workflow_state in build.md
- [x] Add validate_state_restoration calls after load_workflow_state in debug.md
- [x] Add validate_state_restoration calls after load_workflow_state in plan.md
- [x] Add validate_state_restoration calls after load_workflow_state in repair.md
- [x] Add validate_state_restoration calls after load_workflow_state in research.md
- [x] Add validate_state_restoration calls after load_workflow_state in revise.md
- [x] Add validate_state_restoration calls in 2 other multi-block commands
- [x] Add parse_subagent_error to expand.md (currently missing)
- [x] Add parse_subagent_error to collapse.md (currently missing)
- [x] Add parse_subagent_error to optimize-claude.md (currently missing)
- [x] Test state restoration validation by deleting state file between blocks
- [x] Test subagent error parsing with intentionally failing agent

**State Restoration Pattern**:
```bash
# Block 2+
load_workflow_state "$WORKFLOW_ID" false

# Validate critical variables restored
validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" "PLAN_PATH" || {
  echo "ERROR: State restoration failed" >&2
  exit 1
}

# Now safe to use variables
```

**Subagent Error Parsing Pattern**:
```bash
output=$(invoke_agent "specialist" "Task") || {
  error_json=$(parse_subagent_error "$output")

  if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
    log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
      "$(echo "$error_json" | jq -r '.error_type')" \
      "Agent failed: $(echo "$error_json" | jq -r '.message')" \
      "subagent_specialist" \
      "$(echo "$error_json" | jq -c '.context')"
  fi

  exit 1
}
```

**Testing**:
```bash
# Test state restoration validation
# Delete state file between blocks and verify error logged
STATE_ID=$(ls .claude/tmp/repair_*.sh | head -1 | xargs basename | cut -d_ -f2 | cut -d. -f1)
rm .claude/tmp/repair_${STATE_ID}.sh
# Continue repair workflow - should fail and log state_error

/errors --type state_error --limit 1
# Should show state restoration failure

# Test subagent error parsing
# Modify agent to fail intentionally, run command
/expand plan.md 1
/errors --type agent_error --limit 1
# Should show agent failure logged
```

**Expected Duration**: 4 hours

### Phase 5: Validation and Testing [COMPLETE]
dependencies: [2, 3, 4]

**Objective**: Create linters, integration tests, and documentation to prevent regression

**Complexity**: Medium

**Tasks**:
- [x] Create check-error-logging-coverage.sh linter (80% threshold)
- [x] Create check-unbound-variables.sh linter (detect unsafe expansions)
- [x] Add linters to validate-all-standards.sh
- [x] Add linters to pre-commit hooks
- [x] Create test_error_logging_coverage.sh integration test
- [x] Create test_validation_error_logged.sh integration test
- [x] Create test_unbound_variable_logged.sh integration test
- [x] Create test_state_restoration_validation.sh integration test
- [x] Create test_early_initialization_error_capture.sh integration test
- [x] Add integration tests to run_all_tests.sh
- [x] Update error-handling.md with new patterns and examples
- [x] Update errors-command-guide.md with coverage improvements note
- [x] Update repair-command-guide.md with expected coverage metrics
- [x] Create "Error Logging Limitations" section in documentation
- [x] Run full test suite and verify all tests pass
- [x] Run all linters and verify 100% compliance

**check-error-logging-coverage.sh Implementation**:
```bash
#!/usr/bin/env bash
# Validates error logging coverage for all commands

ERROR_COUNT=0

for cmd in .claude/commands/*.md; do
  [[ "$cmd" == *"README.md" ]] && continue

  # Count total error exits
  total_exits=$(grep -c 'exit 1' "$cmd" 2>/dev/null || echo 0)

  # Count exits with logging (within 3 lines before exit)
  logged_exits=$(grep -B3 'exit 1' "$cmd" | grep -c 'log_command_error' 2>/dev/null || echo 0)

  if [ "$total_exits" -gt 0 ]; then
    coverage=$((logged_exits * 100 / total_exits))

    if [ "$coverage" -lt 80 ]; then
      echo "ERROR: $(basename "$cmd") error logging coverage: ${coverage}% (${logged_exits}/${total_exits})"
      echo "  Expected: >= 80%"
      ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
  fi
done

exit $ERROR_COUNT
```

**check-unbound-variables.sh Implementation**:
```bash
#!/usr/bin/env bash
# Detects unsafe variable expansions without default syntax

ERROR_COUNT=0

for cmd in .claude/commands/*.md; do
  [[ "$cmd" == *"README.md" ]] && continue

  # Find variable references without default syntax in critical contexts
  unsafe_vars=$(grep -n 'append_workflow_state.*"\$[^{]' "$cmd" | grep -v ':-' | grep -v '\${' || true)

  if [ -n "$unsafe_vars" ]; then
    echo "ERROR: $(basename "$cmd") has unsafe variable expansions:"
    echo "$unsafe_vars" | sed 's/^/  /'
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

exit $ERROR_COUNT
```

**Testing**:
```bash
# Run error logging coverage linter
bash .claude/scripts/lint/check-error-logging-coverage.sh
# All commands should pass (>= 80% coverage)

# Run unbound variables linter
bash .claude/scripts/lint/check-unbound-variables.sh
# No unsafe expansions should be found

# Run integration tests
bash .claude/tests/integration/test_error_logging_coverage.sh
bash .claude/tests/integration/test_validation_error_logged.sh
bash .claude/tests/integration/test_unbound_variable_logged.sh
bash .claude/tests/integration/test_state_restoration_validation.sh
bash .claude/tests/integration/test_early_initialization_error_capture.sh
# All tests should pass

# Run full test suite
bash .claude/tests/run_all_tests.sh
# Verify no regressions

# Run all validators
bash .claude/scripts/validate-all-standards.sh --all
# All validators should pass
```

**Expected Duration**: 6 hours

## Testing Strategy

### Unit Tests

**Library Function Tests**:
- Test `log_early_error()` logs without USER_ARGS
- Test `validate_state_restoration()` detects missing variables
- Test `check_unbound_vars()` detects unset variables
- Verify all functions exported correctly

### Integration Tests

**Error Logging Coverage Tests**:
- Test validation errors are logged before exit
- Test unbound variable errors are logged
- Test state restoration failures are logged
- Test early initialization errors are logged
- Test file/directory validation errors are logged

**Command-Specific Tests**:
- Test each command with invalid arguments (validation)
- Test each command with missing files (file_error)
- Test each command with state file deleted (state_error)
- Test each command without initialization (initialization_error)

**Linter Tests**:
- Test coverage linter detects low coverage commands
- Test unbound variables linter detects unsafe expansions
- Test linters integrate with pre-commit hooks
- Test linters block commits on violations

### Validation Tests

**Coverage Validation**:
- Verify error logging coverage >= 80% for all commands
- Verify no unsafe variable expansions remain
- Verify all bash blocks follow updated initialization pattern
- Verify all validation exits include log_command_error

**Pattern Compliance**:
- Verify bash error traps in all 13 commands
- Verify trap initialized before variable assignment
- Verify default syntax used for all variable references
- Verify state restoration validation in multi-block commands

### End-to-End Tests

**Error Analysis Workflow**:
1. Run command with invalid input
2. Verify error logged to errors.jsonl
3. Run `/errors --command /cmd --limit 1`
4. Verify error appears in report
5. Run `/repair --command /cmd --complexity 2`
6. Verify repair plan addresses error

**Error Recovery Workflow**:
1. Trigger each error type (validation, state, file, initialization)
2. Verify all errors logged with context
3. Run `/errors --summary`
4. Verify error distribution accurate
5. Run `/repair --since 1h`
6. Verify all error patterns captured in plan

## Documentation Requirements

### Code Standards Updates

**Add New Sections**:
- "Error Logging Requirements" (mandatory log before exit)
- Update "Mandatory Bash Block Pattern" (trap before variables)
- Add validation failure logging examples
- Document error_type selection guide

### Error Handling Pattern Updates

**Update Sections**:
- Add `log_early_error()` function documentation
- Add `validate_state_restoration()` helper documentation
- Add `check_unbound_vars()` helper documentation
- Update error logging integration examples
- Add early initialization error pattern
- Add state restoration validation pattern

### Command Guide Updates

**errors-command-guide.md**:
- Note coverage improvements (4-6% → 80%+)
- Update expected error types
- Add "Error Logging Limitations" section
- Document initialization_error type

**repair-command-guide.md**:
- Update expected coverage metrics
- Note improved error capture
- Update error pattern examples

### Migration Guide

**Create New Document**: `error-logging-migration-guide.md`

**Content**:
- Overview of changes (bash block pattern, validation logging)
- Before/after examples for each pattern
- Checklist for command developers
- Common pitfalls and solutions
- Testing recommendations

## Dependencies

### External Dependencies
- `jq`: JSON processing for log formatting (already installed)
- `bash`: Version 4.0+ for array operations (already available)
- `git`: For pre-commit hooks (already installed)

### Internal Dependencies
- `.claude/lib/core/error-handling.sh`: Core error logging functions
- `.claude/lib/core/state-persistence.sh`: State management
- `.claude/lib/workflow/workflow-state-machine.sh`: State machine integration
- `.claude/scripts/validate-all-standards.sh`: Validation framework
- `.claude/tests/run_all_tests.sh`: Test runner

### Prerequisites
- All commands currently source error-handling.sh (100%)
- 10/13 commands have bash error traps (77%)
- Error log rotation already implemented
- /errors and /repair commands functional

## Risk Assessment and Mitigation

### Risk 1: Breaking Existing Workflows
**Probability**: Low
**Impact**: High

**Mitigation**:
- Phased rollout (one command at a time)
- Comprehensive testing before deployment
- No changes to error-handling.sh API (only additions)
- Backward compatible enhancements
- Run full test suite after each phase

### Risk 2: False Positive Error Logging
**Probability**: Medium
**Impact**: Low

**Mitigation**:
- Preserve existing `_is_benign_bash_error()` filter
- Test with intentionally failing commands
- Monitor error log volume after deployment
- Add filtering for new benign patterns if needed

### Risk 3: Performance Impact
**Probability**: Low
**Impact**: Low

**Analysis**:
- Current `log_command_error()` takes <10ms
- Adding 160 new logging points adds ~1.6 seconds total
- Distributed across error paths (not hot path)
- No performance degradation expected

### Risk 4: Error Log Volume Increase
**Probability**: High
**Impact**: Medium

**Mitigation**:
- Current rotation at 10MB (10,000 errors)
- Expected increase: 3-5x more entries
- Still well within rotation threshold
- Monitor rotation frequency
- Adjust threshold if needed (20MB, 10 backups)

### Risk 5: Incomplete Coverage
**Probability**: Medium
**Impact**: Medium

**Mitigation**:
- Use linters to enforce 80% coverage threshold
- Integration tests verify error capture
- Pre-commit hooks block low coverage
- Manual review of critical error paths

## Success Metrics

### Metric 1: Error Logging Coverage
**Current**: 4-5% of error exits log before exit
**Target**: 80%+ of error exits log before exit
**Measurement**: Linter check-error-logging-coverage.sh

### Metric 2: Validation Report Completeness
**Current**: 67% of errors captured in validation reports
**Target**: 95%+ of errors captured
**Measurement**: Re-run validation reports after fixes, compare coverage

### Metric 3: /errors Query Accuracy
**Current**: Queries miss 33% of actual errors
**Target**: Queries capture 95%+ of actual errors
**Measurement**: Manual testing with intentionally failing commands

### Metric 4: /repair Plan Accuracy
**Current**: Plans address 94% of logged errors but miss 33% of actual errors
**Target**: Plans address 95%+ of all actual errors
**Measurement**: Validation reports compare repair plans to actual output errors

### Metric 5: Developer Experience
**Current**: Developers must read command output to find all errors
**Target**: Developers can rely on /errors query for complete error history
**Measurement**: Post-deployment survey of command developers

### Metric 6: Pre-Commit Hook Coverage
**Current**: No error logging coverage enforcement
**Target**: 100% of commits checked by coverage linter
**Measurement**: Git hook execution logs

## Notes

### Implementation Approach
- Follow clean-break development standard (no deprecation periods)
- Apply changes incrementally (one command at a time)
- Run tests after each command updated
- Commit each phase separately for easy rollback

### Phase Dependencies
Phase dependencies enable efficient parallel execution:
- Phase 1 (Critical Gaps) has no dependencies - start immediately
- Phase 2 (Validation Logging) depends on Phase 1 (trap initialization must work)
- Phase 3 (Infrastructure) depends on Phase 1 (early error pattern needs testing)
- Phase 4 (State Restoration) depends on Phases 1 and 3 (needs helpers)
- Phase 5 (Validation) depends on Phases 2, 3, 4 (needs all patterns implemented)

Phases 2 and 3 can run in parallel after Phase 1 completes.

### Complexity Calculation
```
Score = Base(refactor=5) + Tasks/2 + Files*3 + Integrations*5
     = 5 + (46/2) + (13*3) + (3*5)
     = 5 + 23 + 39 + 15
     = 82

Adjusted for infrastructure work: 82 * 1.7 = 139.4 ≈ 142.0

Tier Selection: Score 142.0 → Tier 2 (50-200)
Note: Starting with Level 0 (single file), can expand with /expand if needed
```

### Standards Conformity
This plan conforms to:
- Clean-Break Development Standard (no deprecation wrappers)
- Error Handling Pattern (centralized JSONL logging)
- Code Standards (defensive programming, three-tier sourcing)
- Output Formatting Standards (WHAT not WHY comments)
- Testing Protocols (coverage requirements, isolation)
- Enforcement Mechanisms (pre-commit hooks, linters)

### Related Work
- Spec 938: Research errors validation
- Spec 942: Debug error coverage validation
- Spec 937: Build error coverage validation
- Spec 944: Repair error coverage validation
- Spec 869: Empty debug/ directory root cause (lazy creation pattern)
- Error Logging Standards: Centralized JSONL logging pattern
