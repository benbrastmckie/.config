# Error Logging Infrastructure Migration Plan

## Metadata
- **Date**: 2025-11-21
- **Revised**: 2025-11-21
- **Feature**: Error Logging Infrastructure Enhancement
- **Scope**: Enhance source-libraries-inline.sh with centralized error logging, add error logging to expand.md and collapse.md, optionally migrate research.md as proof-of-concept
- **Estimated Phases**: 3
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 39.5
- **Research Reports**:
  - [Library Sourcing Gap Analysis](/home/benjamin/.config/.claude/specs/896_error_logging_infrastructure_migration/reports/001_library_sourcing_gap_analysis.md)
  - [Standards Compliance Analysis](/home/benjamin/.config/.claude/specs/896_error_logging_infrastructure_migration/reports/002_standards_compliance_analysis.md)

## Overview

This plan addresses gaps in the error logging infrastructure identified in the research report. The current system has:
- Library sourcing utilities (source-libraries.sh, source-libraries-inline.sh) that NO commands use
- Function validation in source-libraries-inline.sh that only outputs to stderr (no centralized logging)
- 85% error logging coverage (11/13 commands) - expand.md and collapse.md lack log_command_error

The implementation follows a three-phase approach:
1. **Phase 1**: Enhance source-libraries-inline.sh with centralized error logging
2. **Phase 2**: Add error logging to expand.md and collapse.md for 100% coverage
3. **Phase 3** (Optional): Migrate research.md as proof-of-concept for using source-libraries-inline.sh

## Research Summary

Key findings from the Library Sourcing Gap Analysis report:

1. **Unused Utilities**: Two library sourcing utilities exist but no commands use them:
   - `source-libraries.sh` - Block-type based sourcing with function validation
   - `source-libraries-inline.sh` - Three-tier sourcing pattern with built-in validation

2. **Function Validation Gap**: Existing validation only outputs to stderr:
   ```bash
   if ! type append_workflow_state &>/dev/null; then
     echo "ERROR: append_workflow_state function not available" >&2  # Only stderr!
     return 1
   }
   # Missing: log_command_error call
   ```

3. **Error Logging Coverage**: 85% (11/13 commands)
   - Missing: expand.md, collapse.md

4. **Recommended Approach**:
   - Add error logging to source-libraries-inline.sh function validation
   - Add error logging to expand.md and collapse.md
   - Migrate one command as proof-of-concept

## Success Criteria

- [ ] source-libraries-inline.sh logs function validation failures to centralized error log
- [ ] expand.md has full error logging integration (ensure_error_log_exists, log_command_error, setup_bash_error_trap)
- [ ] collapse.md has full error logging integration (ensure_error_log_exists, log_command_error, setup_bash_error_trap)
- [ ] Error logging coverage reaches 100% (13/13 commands)
- [ ] All existing tests pass after changes
- [ ] New validation tests pass for error logging in source-libraries-inline.sh
- [ ] Pre-commit hooks pass for all modified files (expand.md, collapse.md, source-libraries-inline.sh)
- [ ] Linter validation passes: `bash .claude/scripts/lint/check-library-sourcing.sh expand.md collapse.md`
- [ ] Tests use proper isolation (CLAUDE_TEST_MODE=1, temp CLAUDE_SPECS_ROOT)
- [ ] (Optional) research.md uses source-libraries-inline.sh for library sourcing

## Technical Design

### Architecture Overview

The error logging system follows a centralized pattern:

```
Command (e.g., /build, /research)
    |
    v
error-handling.sh
    |-- log_command_error()  --> writes to .claude/data/logs/errors.jsonl
    |-- setup_bash_error_trap() --> ERR/EXIT traps
    |-- ensure_error_log_exists()
    |
    v
source-libraries-inline.sh (enhanced)
    |-- source_critical_libraries()
    |   |-- Tier 1: state-persistence.sh, workflow-state-machine.sh, error-handling.sh
    |   |-- Function validation with error logging (NEW)
    |
    v
Centralized JSONL Log (.claude/data/logs/errors.jsonl)
```

### Enhancement Points

1. **source-libraries-inline.sh**: Add `log_command_error` calls to function validation:
   - Must check if `log_command_error` is available before using (chicken-egg: error-handling.sh sources first)
   - Use `dependency_error` type for missing functions
   - Include context JSON with function name and library name

2. **expand.md / collapse.md**: Follow the error logging pattern from research.md:
   - Source error-handling.sh after project directory detection
   - Call `ensure_error_log_exists` during setup
   - Set `COMMAND_NAME`, `WORKFLOW_ID`, `USER_ARGS` environment variables
   - Call `setup_bash_error_trap` for bash-level errors
   - Add `log_command_error` calls at failure points

3. **research.md migration** (optional): Replace manual sourcing with `source_all_standard_libraries()`:
   - Source source-libraries-inline.sh first
   - Call `source_critical_libraries || exit 1`
   - Call `source_workflow_libraries` for graceful degradation
   - Remove individual source statements

### Error Logging Integration Pattern

Commands must follow this standard pattern. **CRITICAL**: All error-handling.sh sourcing MUST use the mandatory fail-fast pattern enforced by `check-library-sourcing.sh`. Bare `2>/dev/null` without `|| { exit 1 }` is prohibited and will fail pre-commit hooks.

```bash
# 1. Project directory detection (inline bootstrap)
if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
  CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
else
  # Fallback: directory walk
fi

# 2. Source error-handling.sh (MANDATORY fail-fast pattern for Tier 1 libraries)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/error-handling.sh" 2>/dev/null || {
  echo "ERROR: Failed to source error-handling.sh" >&2
  exit 1
}

# 3. Initialize error log
ensure_error_log_exists

# 4. Set workflow metadata
COMMAND_NAME="/command"
WORKFLOW_ID="workflow_$(date +%s)"
USER_ARGS="$*"
export COMMAND_NAME WORKFLOW_ID USER_ARGS

# 5. Setup bash error trap
setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"

# 6. Log errors at failure points
if [ "$SOME_CONDITION" = "failed" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "validation_error" \
    "Description of what failed" \
    "location_in_code" \
    '{"key": "value"}'
  exit 1
fi
```

### Output Suppression Requirements

Per output formatting standards:
- Error logging initialization should be **silent on success**
- Only emit summary line after all setup complete
- Error messages to stderr should use **WHICH/WHAT/WHERE** structure:
  - WHICH: Command or function name
  - WHAT: What failed
  - WHERE: File/line location if available

## Implementation Phases

### Phase 1: Enhance source-libraries-inline.sh with Error Logging [COMPLETE]
dependencies: []

**Objective**: Add centralized error logging to function validation in source-libraries-inline.sh so that validation failures are queryable via /errors command.

**Complexity**: Low

**Scope**:
- Modify `source_critical_libraries()` function to log validation failures
- Ensure error-handling.sh is sourced before validation occurs (already done)
- Add conditional logging (only if `log_command_error` function exists)

**Mandatory Pattern**: All error-handling.sh sourcing MUST use the fail-fast pattern enforced by `check-library-sourcing.sh`.

Tasks:
- [x] Read current source_critical_libraries() implementation (file: .claude/lib/core/source-libraries-inline.sh, lines 57-91)
- [x] Add error logging after `append_workflow_state` function check (line 81-84)
- [x] Add error logging after `save_completed_states_to_state` function check (line 86-89)
- [x] Use conditional check: `if type log_command_error &>/dev/null; then ... fi`
- [x] Use error_type: `dependency_error`
- [x] Include context JSON: `{"function": "function_name", "library": "library_name"}`
- [x] Write unit test to verify error logging on validation failure

Testing:
```bash
# Set test isolation flags (REQUIRED for test isolation)
export CLAUDE_TEST_MODE=1
export CLAUDE_SPECS_ROOT="/tmp/test_error_logging_$$"
export CLAUDE_PROJECT_DIR="/tmp/test_error_logging_$$"
mkdir -p "$CLAUDE_SPECS_ROOT/.claude/data/logs"
trap 'rm -rf "$CLAUDE_SPECS_ROOT"' EXIT

# Test that validation failures are logged
cd /home/benjamin/.config
# Create test script that sources libraries but breaks state-persistence.sh
bash .claude/tests/unit/test_source_libraries_inline_error_logging.sh
```

**Expected Duration**: 1.5 hours

### Phase 2: Add Error Logging to expand.md and collapse.md [COMPLETE]
dependencies: [1]

**Objective**: Add full error logging integration to expand.md and collapse.md to achieve 100% error logging coverage across all commands.

**Complexity**: Medium

**Scope**:
- Add error-handling.sh sourcing to both commands
- Initialize error log and workflow metadata
- Setup bash error traps
- Add log_command_error calls at failure points
- Integrate agent error protocol for complexity-estimator invocations

**Mandatory Pattern**: All error-handling.sh sourcing MUST use the fail-fast pattern enforced by `check-library-sourcing.sh`.

**Specific Integration Points**:
- **expand.md**: Add error-handling.sh sourcing after line 106 (after `export CLAUDE_PROJECT_DIR`)
- **collapse.md**: Add error-handling.sh sourcing after line 108 (after `export CLAUDE_PROJECT_DIR`)

Tasks:
- [x] Update expand.md: Add error-handling.sh sourcing after project directory detection (after line 106)
- [x] Update expand.md: Add error logging initialization (ensure_error_log_exists, COMMAND_NAME, WORKFLOW_ID, USER_ARGS, setup_bash_error_trap)
- [x] Update expand.md: Add log_command_error at "ERROR: Failed to detect project directory" (line 99-102)
- [x] Update expand.md: Add log_command_error at "ERROR: Plan file not found" (line 131)
- [x] Update expand.md: Add log_command_error at "ERROR: Phase not found" (line 157)
- [x] Update expand.md: Add log_command_error at "CRITICAL ERROR: Phase file not created" (line 231)
- [x] Update expand.md: Add log_command_error at "ERROR: Phase file too small" (line 238)
- [x] Update collapse.md: Add error-handling.sh sourcing after project directory detection (after line 108)
- [x] Update collapse.md: Add error logging initialization
- [x] Update collapse.md: Add log_command_error at error points in Phase Collapse Process
- [x] Update collapse.md: Add log_command_error at error points in Stage Collapse Process
- [x] Verify expand.md and collapse.md still function correctly
- [x] Add parse_subagent_error() after complexity-estimator agent invocations in auto-analysis mode
- [x] Add validate_agent_output() for artifact verification after expansion/collapse

**Agent Error Protocol** (for complexity-estimator agent invocations):
```bash
# After agent invocation in auto-analysis mode
error_json=$(parse_subagent_error "$agent_response")
if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
  log_command_error \
    "$COMMAND_NAME" \
    "$WORKFLOW_ID" \
    "$USER_ARGS" \
    "$(echo "$error_json" | jq -r '.error_type')" \
    "Agent complexity-estimator failed: $(echo "$error_json" | jq -r '.message')" \
    "subagent_complexity-estimator" \
    "$(echo "$error_json" | jq -c '.context')"
fi

# Use validate_agent_output for artifact verification
validate_agent_output "complexity-estimator" "$ARTIFACT_PATH" 10
```

Testing:
```bash
# Test expand.md error logging
cd /home/benjamin/.config
# Run expand with invalid path and verify error logged
/expand nonexistent/path.md 2>&1 | grep -i error
cat .claude/data/logs/errors.jsonl | tail -1 | jq '.command'

# Test collapse.md error logging
/collapse nonexistent/path/ 2 2>&1 | grep -i error
cat .claude/data/logs/errors.jsonl | tail -1 | jq '.command'

# Verify error query shows new commands
/errors --command /expand --limit 5
/errors --command /collapse --limit 5

# Validate pre-commit compliance (REQUIRED before merging)
bash .claude/scripts/validate-all-standards.sh --sourcing --suppression --conditionals

# Validate linter compliance
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/expand.md .claude/commands/collapse.md
```

**Expected Duration**: 2.5 hours

### Phase 3: Migrate research.md to source-libraries-inline.sh (Optional) [SKIPPED]
dependencies: [1]

**Objective**: Migrate research.md to use source-libraries-inline.sh as a proof-of-concept, demonstrating the utility's value and establishing a migration pattern for other commands.

**Complexity**: Medium

**Scope**:
- Replace manual library sourcing in Block 1a with source-libraries-inline.sh
- Validate that all required functions are available
- Document migration pattern for future command migrations

Tasks:
- [ ] Read current research.md Block 1a library sourcing (file: .claude/commands/research.md, lines 117-139)
- [ ] Replace manual Tier 1 sourcing with source_critical_libraries() call
- [ ] Replace manual Tier 2 sourcing with source_workflow_libraries() call
- [ ] Add source-libraries-inline.sh sourcing before other library loads
- [ ] Verify library-version-check.sh is still sourced (not in source-libraries-inline.sh)
- [ ] Test research command with various inputs
- [ ] Document migration pattern in implementation notes

Migration Pattern:
```bash
# BEFORE (manual sourcing)
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

# AFTER (using source-libraries-inline.sh)
source "${CLAUDE_PROJECT_DIR}/.claude/lib/core/source-libraries-inline.sh" 2>/dev/null || {
  echo "ERROR: Failed to source source-libraries-inline.sh" >&2
  exit 1
}
source_critical_libraries || exit 1
source_workflow_libraries  # Graceful degradation
```

Testing:
```bash
# Test research command functionality
cd /home/benjamin/.config
/research "test topic for validation" --complexity 1

# Verify state management still works
cat ~/.claude/tmp/state_research_*.sh | head -20

# Verify error logging still works
/errors --command /research --limit 3
```

**Expected Duration**: 2 hours

## Testing Strategy

### Test Isolation Requirements (MANDATORY)

All tests MUST use proper isolation to avoid polluting production logs:

```bash
# Set test isolation flags at start of each test
export CLAUDE_TEST_MODE=1
export CLAUDE_SPECS_ROOT="/tmp/test_error_logging_$$"
export CLAUDE_PROJECT_DIR="$CLAUDE_SPECS_ROOT"
mkdir -p "$CLAUDE_SPECS_ROOT/.claude/data/logs"
trap 'rm -rf "$CLAUDE_SPECS_ROOT"' EXIT
```

### Unit Tests
1. **source-libraries-inline.sh validation**:
   - Test that validation failures trigger log_command_error
   - Test that error log entries have correct format (error_type, message, context)
   - Test conditional logging (only logs if log_command_error available)

2. **expand.md / collapse.md error logging**:
   - Test that errors at each failure point are logged
   - Test that setup_bash_error_trap captures bash-level errors
   - Test that error log entries include correct command name

### Behavioral Compliance Tests
1. **Error logging integration follows mandatory pattern**:
   - Verify fail-fast handlers present on all Tier 1 library sourcing
   - Verify error log entries have correct JSONL schema
   - Verify error messages use WHICH/WHAT/WHERE structure

2. **Linter validation**:
   - Run `bash .claude/scripts/lint/check-library-sourcing.sh` on modified files
   - Verify no violations

### Integration Tests
1. **Error query verification**:
   - Run commands that fail intentionally
   - Query errors with /errors command
   - Verify all logged errors are queryable

2. **Workflow continuity**:
   - Verify expand.md and collapse.md work correctly after changes
   - Verify research.md (if migrated) completes workflows successfully

### Pre-commit Validation (REQUIRED before merge)
```bash
# Run unified validation
bash .claude/scripts/validate-all-standards.sh --sourcing --suppression --conditionals

# Run specific linter for modified commands
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/expand.md .claude/commands/collapse.md
```

### Regression Tests
```bash
# Run existing test suites
cd /home/benjamin/.config/.claude/tests
bash run_tests.sh
```

## Documentation Requirements

1. Update `.claude/docs/reference/standards/code-standards.md`:
   - Add example showing error logging pattern for new commands
   - Reference source-libraries-inline.sh as recommended approach

2. Update `CLAUDE.md` error logging section if needed:
   - Verify current documentation covers all error types used

3. No new documentation files required (existing patterns sufficient)

## Dependencies

### External Dependencies
- None (all dependencies are internal to .claude/)

### Internal Dependencies
- error-handling.sh: log_command_error, ensure_error_log_exists, setup_bash_error_trap
- source-libraries-inline.sh: source_critical_libraries, source_workflow_libraries
- state-persistence.sh: append_workflow_state
- workflow-state-machine.sh: save_completed_states_to_state

### Prerequisites
- Phase 0 of superseded plan is RESOLVED: save_completed_states_to_state function exists
- Error logging infrastructure is operational (11/13 commands already use it)

---

## Revision History

### Revision 1 (2025-11-21)

**Trigger**: Standards compliance analysis identified gaps requiring plan revision.

**Research Report**: [Standards Compliance Analysis](/home/benjamin/.config/.claude/specs/896_error_logging_infrastructure_migration/reports/002_standards_compliance_analysis.md)

**Changes Made**:

1. **Added mandatory fail-fast pattern documentation** (HIGH PRIORITY)
   - Updated Technical Design section to explicitly state mandatory fail-fast pattern
   - Added "Mandatory Pattern" notes to Phase 1 and Phase 2
   - Referenced `check-library-sourcing.sh` enforcement

2. **Added test isolation requirements** (HIGH PRIORITY)
   - Added "Test Isolation Requirements" section to Testing Strategy
   - Updated Phase 1 Testing to include CLAUDE_TEST_MODE, CLAUDE_SPECS_ROOT setup
   - Added trap for cleanup

3. **Added pre-commit validation steps** (HIGH PRIORITY)
   - Added "Pre-commit Validation" section to Testing Strategy
   - Added linter validation commands to Phase 2 Testing
   - Updated Success Criteria with pre-commit and linter requirements

4. **Added agent error protocol to Phase 2** (MEDIUM PRIORITY)
   - Added parse_subagent_error() integration task
   - Added validate_agent_output() integration task
   - Included code example for agent error protocol

5. **Added specific line numbers for integration points**
   - expand.md: After line 106 (after `export CLAUDE_PROJECT_DIR`)
   - collapse.md: After line 108 (after `export CLAUDE_PROJECT_DIR`)

6. **Updated Technical Design with output suppression requirements** (LOW PRIORITY)
   - Added "Output Suppression Requirements" section
   - Documented WHICH/WHAT/WHERE structure for error messages

7. **Updated metadata**
   - Added second research report to Research Reports section
   - Added "Revised" date field

8. **Updated Success Criteria**
   - Added pre-commit hooks validation criterion
   - Added linter validation criterion
   - Added test isolation criterion

**Compliance Status**: Plan now addresses all HIGH and MEDIUM priority gaps from standards compliance analysis.
