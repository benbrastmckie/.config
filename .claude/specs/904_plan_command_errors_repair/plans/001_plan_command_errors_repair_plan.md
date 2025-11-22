# Plan Command Errors Repair Implementation Plan

## Metadata
- **Date**: 2025-11-21
- **Last Revised**: 2025-11-21
- **Feature**: Plan command errors repair
- **Scope**: Fix exit code 127 bash sourcing failures, unbound variable errors, topic naming agent failures, and workflow state management issues
- **Estimated Phases**: 5
- **Estimated Hours**: 12
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 47.5 (fix=3 + tasks=19/2=9.5 + files=9*3=27 + integrations=2*5=10)
- **Research Reports**:
  - [Error Analysis Report](../reports/001_error_analysis.md)
  - [Plan Revision Insights](../reports/002_plan_revision_insights.md)

## Overview

This plan addresses four categories of errors affecting the `/plan` command:

1. **Exit Code 127 Errors (8 occurrences, 61.5%)**: Bash environment initialization failures during `. /etc/bashrc` and `append_workflow_state` operations
2. **Unbound Variable Errors**: `ORIGINAL_PROMPT_FILE_PATH: unbound variable` at line 327 before workflow operations
3. **Topic Naming Agent Failures (3 occurrences, 23.1%)**: Agent not producing output file within validation timeout, plus `research_topics array empty` parsing failures
4. **Workflow State Management Issues (2 occurrences, 15.4%)**: State persistence and transition failures

The errors were captured over a 16-hour period on 2025-11-21 and indicate infrastructure-level issues requiring targeted fixes rather than architectural changes.

## Research Summary

Key findings from error analysis and plan revision reports:

1. **Exit code 127 pattern**: Errors occur at script initialization attempting to source `/etc/bashrc` (which doesn't exist on NixOS) and during `append_workflow_state` calls. Previous analysis confirmed no commands hardcode `/etc/bashrc` anymore, suggesting the error originates from bash environment pre-initialization rather than command code.

2. **Unbound variable pattern** (from plan-output.md line 30-31): `ORIGINAL_PROMPT_FILE_PATH: unbound variable` error occurs before trap filtering or function validation would take effect. This represents a failure mode not covered by exit code 127 handling and requires explicit variable initialization.

3. **Topic naming agent pattern**: Agent fails to produce output file (`agent_no_output_file` fallback reason), triggering secondary exit code 127 errors. Additionally, `research_topics array empty` errors indicate agent output parsing issues separate from file creation failures.

4. **Workflow state pattern**: Exit code 1 at line 252 in error-handling.sh indicates logical errors in state management code, separate from infrastructure issues.

Recommended approach: Fix variable binding issues first (Phase 0), then infrastructure issues in order of impact (exit code 127, then agent failures, then state management).

## Success Criteria

- [ ] All exit code 127 errors eliminated from /plan command execution
- [ ] No unbound variable errors (`ORIGINAL_PROMPT_FILE_PATH` and similar) during execution
- [ ] Topic naming agent reliably produces output files within 5 second timeout
- [ ] Agent output parsing handles empty/malformed research_topics arrays gracefully
- [ ] Workflow state transitions complete without errors
- [ ] /plan command executes successfully end-to-end on test cases
- [ ] Error log shows 0 errors for `/errors --command /plan --since 1h` after fixes applied
- [ ] All modified files pass linter validation (`check-library-sourcing.sh` exits 0)
- [ ] No new violations in `lint_error_suppression.sh` output

## Technical Design

### Architecture Overview

The /plan command uses a multi-block execution model with bash blocks communicating via state files:

```
Block 1a (Setup) --> Block 1b (Topic Naming Agent) --> Block 1c (Path Init) --> Block 1d (Research)
     |                      |                              |
     v                      v                              v
state-persistence.sh   topic-naming-agent.md         workflow-initialization.sh
     |                      |                              |
     v                      v                              v
STATE_FILE creation    Output file write            append_workflow_state calls
```

### Root Causes Identified

1. **Unbound variable errors**: `ORIGINAL_PROMPT_FILE_PATH: unbound variable` at line 327 occurs before any error handling can intercept. Variables are used before being initialized, causing immediate failure when `set -u` is active.

2. **Exit code 127 from `. /etc/bashrc`**: Claude Code's bash environment may source system bashrc at startup. This is NOT in command code but in bash initialization. Fix requires defensive handling in trap setup.

3. **Exit code 127 from `append_workflow_state`**: If state-persistence.sh fails to source correctly (e.g., due to PATH issues or trap interference), the function becomes unavailable. Fix requires pre-flight validation.

4. **Topic naming agent failures**: Agent has 5-second timeout but may be failing due to LLM response delays or Write tool failures. Additionally, `research_topics array empty` errors indicate parsing issues even when agent produces output file. Fix requires better error propagation, retry logic, and structural validation.

5. **State management exit code 1**: Line 252 in error-handling.sh contains `return 1` in error path. May be triggered by unexpected state conditions. Fix requires defensive state validation.

### Fix Strategy

| Error Type | Root Cause | Fix Approach | Phase |
|------------|------------|--------------|-------|
| Unbound variable | Variable used before initialization | Add defensive variable initialization with defaults | Phase 0 |
| Exit 127 (bashrc) | System bashrc missing | Add defensive trap that ignores bashrc errors | Phase 1 |
| Exit 127 (append_workflow_state) | Function not available | Add pre-flight function availability check | Phase 2 |
| Agent no output | Timeout or Write failure | Add retry logic and better error propagation | Phase 3 |
| Agent parse failure | research_topics array empty | Add structural validation of agent output | Phase 3 |
| State exit 1 | Invalid state transition | Add state validation before transitions | Phase 4 |

## Implementation Phases

### Phase 0: Variable Binding Defensive Setup [COMPLETE]
dependencies: []

**Objective**: Prevent unbound variable errors by initializing required variables with defaults before use

**Complexity**: Low

**Rationale**: The `ORIGINAL_PROMPT_FILE_PATH: unbound variable` error (plan-output.md line 30-31) occurs at line 327 before any trap filtering or function validation can intercept. This is a distinct failure mode that requires explicit variable initialization at the top of bash blocks.

Tasks:
- [x] Identify all bash blocks in plan.md that use `ORIGINAL_PROMPT_FILE_PATH`
- [x] Add defensive initialization at top of affected bash blocks:
  ```bash
  # Initialize required variables with defaults to prevent unbound variable errors
  ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"
  ```
- [x] Audit plan.md for other potentially unbound variables used in workflows
- [x] Add validation block for required variables before critical operations:
  ```bash
  # Validate required variables are set (not just initialized)
  if [ -z "${ORIGINAL_PROMPT_FILE_PATH:-}" ]; then
    log_command_error "validation_error" "ORIGINAL_PROMPT_FILE_PATH not set" "plan.md"
    exit 1
  fi
  ```
- [x] Consider adding `set +u` temporarily around sections with optional variables as fallback
- [x] Document variable initialization requirements in block comments

Testing:
```bash
# Test variable binding defensive setup
# Simulate unbound variable scenario
unset ORIGINAL_PROMPT_FILE_PATH 2>/dev/null || true

# Source the pattern
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-}"

# Verify no error occurs
if [ -z "$ORIGINAL_PROMPT_FILE_PATH" ]; then
  echo "PASS: Variable initialized to empty (no unbound error)"
else
  echo "INFO: Variable has value: $ORIGINAL_PROMPT_FILE_PATH"
fi

# Test with set -u active
set -u
ORIGINAL_PROMPT_FILE_PATH="${ORIGINAL_PROMPT_FILE_PATH:-default}"
echo "PASS: No error with set -u and default value: $ORIGINAL_PROMPT_FILE_PATH"
```

**Expected Duration**: 1.5 hours

---

### Phase 1: Defensive Bash Trap Setup [COMPLETE]
dependencies: [0]

**Objective**: Make bash error traps resilient to pre-command initialization failures

**Complexity**: Medium

**Rationale**: Exit code 127 errors from `. /etc/bashrc` occur before command code executes. The error trap captures these but they're not actionable. Adding filter logic prevents noise.

Tasks:
- [x] Review current `setup_bash_error_trap` implementation in error-handling.sh (lines 1316-1326)
- [x] Add filter in `_log_bash_error` to ignore known benign errors:
  - `/etc/bashrc` sourcing failures (system-level, not command code)
  - `/etc/bash.bashrc` sourcing failures
  - `~/.bashrc` sourcing failures
- [x] Update `_log_bash_exit` similarly to filter benign exit codes
- [x] Add test case for bash trap filtering in test suite
- [x] Verify error log no longer captures bashrc sourcing failures

Testing:
```bash
# Test bash trap setup
source .claude/lib/core/error-handling.sh 2>/dev/null
setup_bash_error_trap "/plan" "test_workflow" "test args"
# Verify trap is set
trap -p ERR | grep -q '_log_bash_error' && echo "PASS: ERR trap set"
trap -p EXIT | grep -q '_log_bash_exit' && echo "PASS: EXIT trap set"
```

**Expected Duration**: 2 hours

---

### Phase 2: Pre-flight Function Availability Checks [COMPLETE]
dependencies: [0, 1]

**Objective**: Ensure required functions exist before calling them to prevent exit code 127

**Complexity**: Medium

**Rationale**: `append_workflow_state: command not found` indicates the function wasn't exported or library wasn't sourced. Pre-flight checks catch this early with clear error messages.

Tasks:
- [x] Create pre-flight validation function `validate_library_functions` in state-persistence.sh
  - Check for presence of: `append_workflow_state`, `load_workflow_state`, `init_workflow_state`
  - Return clear error message if any function missing
- [x] Add pre-flight call after library sourcing in plan.md Block 1a:
  ```bash
  # After source statements
  validate_library_functions "state-persistence" || exit 1
  ```
- [x] Add similar validation to Block 1c and Block 2/3
- [x] Update source-libraries-inline.sh to include validation (already partially exists at line 81-92)
- [x] Add test case for pre-flight validation failure scenarios

Testing:
```bash
# Test function availability check
source .claude/lib/core/state-persistence.sh 2>/dev/null
if command -v append_workflow_state &>/dev/null; then
  echo "PASS: append_workflow_state available"
else
  echo "FAIL: append_workflow_state not available"
fi
```

**Expected Duration**: 2 hours

---

### Phase 3: Topic Naming Agent Reliability [COMPLETE]
dependencies: []

**Objective**: Improve topic naming agent output reliability, error propagation, and output parsing validation

**Complexity**: Medium

**Rationale**: Agent failures cascade into secondary errors. The `research_topics array empty` error indicates that even when an agent produces output, the parsing may fail. Better error isolation and structural validation prevents confusion and enables targeted debugging.

Tasks:
- [x] Update validate_agent_output function to use retry logic (error-handling.sh line 1343-1368)
  - Use `validate_agent_output_with_retry` pattern already defined at line 1373
  - Default to 3 retries with 2-second timeout each (6 seconds total)
- [x] Update plan.md Block 1b agent invocation to include explicit Write tool error handling:
  - Add instruction for agent to return TASK_ERROR if Write fails
  - Already in topic-naming-agent.md but verify it's followed
- [x] Update Block 1b validation bash block (lines 280-339) to:
  - Use validate_agent_output_with_retry instead of validate_agent_output
  - Log more detailed diagnostic information on failure
- [x] **NEW**: Add structural validation for parsed agent output in `validate_and_generate_filename_slugs`:
  - Verify required fields are present in agent output file
  - Check `research_topics` array is non-empty after parsing
  - Log detailed parse errors with line/position information for debugging
  - Return clear error message distinguishing file-missing vs parse-failure scenarios
- [x] **NEW**: Update validate_and_generate_filename_slugs to handle malformed agent output gracefully:
  ```bash
  # After reading agent output file
  if [ -z "${research_topics[*]:-}" ] || [ ${#research_topics[@]} -eq 0 ]; then
    log_command_error "parse_error" "research_topics array empty after parsing" "$(cat "$AGENT_OUTPUT_FILE")"
    # Fall back to generic filenames but continue workflow
    return 1
  fi
  ```
- [x] Add integration test for topic naming agent timeout scenarios
- [x] **NEW**: Add integration test for agent output with malformed/empty content
- [x] Update topic-naming-agent.md to clarify error return requirements (already specified but may need emphasis)

Testing:
```bash
# Test agent output validation with retry
source .claude/lib/core/error-handling.sh 2>/dev/null
TEST_FILE="/tmp/test_agent_output_$$.txt"

# Test 1: File doesn't exist
validate_agent_output_with_retry "test-agent" "$TEST_FILE" "none" 2 2
RESULT=$?
[ $RESULT -eq 1 ] && echo "PASS: Correctly detected missing file"

# Test 2: File exists with valid content
echo "research_topics=(\"auth_patterns\" \"security_best_practices\")" > "$TEST_FILE"
validate_agent_output_with_retry "test-agent" "$TEST_FILE" "none" 2 2
RESULT=$?
[ $RESULT -eq 0 ] && echo "PASS: Correctly found file"

# Test 3: File exists but content is malformed (empty array)
echo "research_topics=()" > "$TEST_FILE"
source "$TEST_FILE" 2>/dev/null
if [ -z "${research_topics[*]:-}" ] || [ ${#research_topics[@]} -eq 0 ]; then
  echo "PASS: Correctly detected empty research_topics array"
fi

# Test 4: File exists but missing required field
echo "topic_name=\"test\"" > "$TEST_FILE"  # Missing research_topics
source "$TEST_FILE" 2>/dev/null
if [ -z "${research_topics[*]:-}" ]; then
  echo "PASS: Correctly detected missing research_topics field"
fi

rm -f "$TEST_FILE"
```

**Expected Duration**: 4 hours

---

### Phase 4: State Transition Validation [COMPLETE]
dependencies: [0, 1, 2]

**Objective**: Add defensive validation to prevent invalid state transitions causing exit code 1

**Complexity**: Low

**Rationale**: Exit code 1 at line 252 suggests a controlled error return. Adding validation before state operations prevents reaching error conditions.

Tasks:
- [x] Review error-handling.sh line 252 context to understand when return 1 is triggered
- [x] Add pre-transition validation in workflow-state-machine.sh `sm_transition` function:
  - Validate current state before attempting transition
  - Check that target state is a valid transition from current state
  - Log warning if invalid transition attempted
- [x] Update plan.md state transitions to check return codes more explicitly:
  ```bash
  if ! sm_transition "$STATE_RESEARCH"; then
    log_command_error ... "Invalid state transition to RESEARCH"
    exit 1
  fi
  ```
- [x] Add state validation after load_workflow_state calls to ensure state integrity
- [x] Create test case for invalid state transition handling

Testing:
```bash
# Test state transition validation
source .claude/lib/workflow/workflow-state-machine.sh 2>/dev/null
source .claude/lib/core/state-persistence.sh 2>/dev/null

# Initialize state machine
WORKFLOW_ID="test_$(date +%s)"
STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
sm_init "test feature" "/plan" "research-and-plan" 3 "[]"

# Valid transition
sm_transition "$STATE_RESEARCH"
[ $? -eq 0 ] && echo "PASS: Valid transition succeeded"

# Invalid transition (try to go directly to COMPLETE)
sm_transition "$STATE_COMPLETE" 2>/dev/null
[ $? -ne 0 ] && echo "PASS: Invalid transition blocked"

# Cleanup
rm -f "$STATE_FILE"
```

**Expected Duration**: 3 hours

---

## Testing Strategy

### Unit Tests

Each phase includes inline testing commands. Additionally:

1. **Variable binding test**: Verify unbound variables are handled gracefully
2. **Bash trap filtering test**: Verify benign errors are filtered from error log
3. **Function availability test**: Verify pre-flight checks detect missing functions
4. **Agent retry test**: Verify retry logic handles transient failures
5. **Agent parsing test**: Verify empty/malformed research_topics handled gracefully
6. **State validation test**: Verify invalid transitions are blocked

### Integration Tests

After all phases complete:

```bash
# End-to-end /plan test
/plan "Test feature for error handling verification" --complexity 1

# Verify no errors logged
/errors --command /plan --since 5m --type execution_error
# Expected: No results or only expected warnings

# Verify artifacts created
ls -la .claude/specs/*/plans/*.md | tail -1
# Expected: Plan file exists with reasonable size
```

### Error Log Verification

```bash
# Before fixes: Baseline error count
/errors --command /plan --since 24h --summary

# After fixes: Compare error count
/errors --command /plan --since 1h --summary
# Expected: Significant reduction or elimination of errors
```

### Linter Validation

After each phase implementation, verify linter compliance:

```bash
# Check library sourcing patterns
bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/plan.md
# Expected: Exit 0, no violations

# Check for error suppression anti-patterns
bash .claude/tests/utilities/lint_error_suppression.sh
# Expected: No new violations

# Run all staged file validators (pre-commit mode)
bash .claude/scripts/validate-all-standards.sh --staged
# Expected: All validators pass

# Full validation (before merge)
bash .claude/scripts/validate-all-standards.sh --all
# Expected: No ERROR-level violations
```

## Documentation Requirements

- [ ] Update troubleshooting guide: `.claude/docs/troubleshooting/plan-command-errors.md`
  - Add new error patterns and fixes
  - Document pre-flight validation usage
  - Document retry logic for agent output
- [ ] Update error-handling.sh inline documentation for new filter logic
- [ ] Update state-persistence.sh documentation for validation function
- [ ] No new documentation files needed (update existing only)

## Dependencies

### Internal Dependencies
- `.claude/lib/core/error-handling.sh` - Bash trap and error logging
- `.claude/lib/core/state-persistence.sh` - State file management
- `.claude/lib/workflow/workflow-state-machine.sh` - State transitions
- `.claude/commands/plan.md` - Main command implementation
- `.claude/agents/topic-naming-agent.md` - Topic naming agent

### External Dependencies
- `jq` - JSON processing (already required by codebase)
- Bash 4.0+ - Array features (already required by codebase)

## Rollback Plan

If fixes introduce regressions:

### Pre-Rollback Verification

Before rolling back any phase, capture error log state:
```bash
# Capture current error log state
/errors --since 24h > pre_rollback_errors.txt
```

### Phase-Specific Rollback

0. **Phase 0 rollback**: Remove defensive variable initialization from plan.md bash blocks
   - Restore original variable usage without `${VAR:-}` patterns
   - Remove validation blocks for required variables
1. **Phase 1 rollback**: Remove filter logic from `_log_bash_error`, restore original trap behavior
2. **Phase 2 rollback**: Remove pre-flight validation calls from plan.md blocks
3. **Phase 3 rollback**: Revert to `validate_agent_output` without retry, remove structural validation
4. **Phase 4 rollback**: Remove state validation from `sm_transition`

Each phase can be rolled back independently without affecting others.

### Post-Rollback Verification

After rollback:
```bash
# Verify no error suppression patterns introduced
bash .claude/tests/utilities/lint_error_suppression.sh

# Compare error counts
/errors --since 1h > post_rollback_errors.txt
diff pre_rollback_errors.txt post_rollback_errors.txt

# Run linter to ensure rollback didn't break standards
bash .claude/scripts/validate-all-standards.sh --sourcing
```

## Risk Assessment

| Risk | Probability | Impact | Mitigation | Phase |
|------|-------------|--------|------------|-------|
| Variable defaults mask bugs | Low | Medium | Use empty string default, validate before critical ops | Phase 0 |
| Filter hides real errors | Low | Medium | Filter only specific benign patterns | Phase 1 |
| Pre-flight slows execution | Very Low | Low | Function checks are <1ms | Phase 2 |
| Retry delays execution | Low | Low | Total retry time capped at 6s | Phase 3 |
| Parsing validation too strict | Low | Low | Log warnings but fall back to generic names | Phase 3 |
| State validation too strict | Low | Medium | Use warning logs not hard failures | Phase 4 |

## Notes

- Unbound variable errors (`ORIGINAL_PROMPT_FILE_PATH: unbound variable`) occur before any error handling can intercept. Phase 0 prevents these by initializing variables with defaults at the top of bash blocks.
- Exit code 127 errors from bashrc sourcing are likely from Claude Code's bash initialization, not command code. The fix filters these from error logs rather than preventing them.
- The topic naming agent already has error handling, but the cascade effect with secondary exit 127 errors makes debugging difficult. Better error isolation is the goal.
- The `research_topics array empty` error is separate from agent output file creation - Phase 3 now addresses both file creation and content parsing failures.
- All fixes maintain backward compatibility with existing command behavior.
- Plan revised based on insights from 002_plan_revision_insights.md research report which identified gaps in unbound variable handling and agent output parsing validation.
