# /research Command Error Repair Implementation Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Research Command Error Repair
- **Scope**: Fix state machine initialization, validation errors, and execution error classification in /research workflow
- **Estimated Phases**: 4
- **Estimated Hours**: 10
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 43.5 (fix=3 base + 15 tasks/2 + 6 files*3 + 2 integrations*5 = 3 + 7.5 + 18 + 10 = 38.5, adjusted to 43.5 for cross-component coordination)
- **Research Reports**:
  - [Error Analysis Report](../reports/001-error-report.md)
  - [Topic Lock Dependencies Report](../reports/001-topic-lock-dependencies.md)

## Overview

This plan addresses three categories of errors identified in the /research command error analysis:

1. **State Machine Initialization** (High Priority): `sm_transition` called without prior `load_workflow_state` initialization, causing STATE_FILE not set errors
2. **Classification Agent Validation** (Medium Priority): Empty `research_topics` array returned by classification agent while `topic_directory_slug` is valid
3. **Execution Error Classification** (Low Priority): Bash trap handlers logging intentional validation returns (exit code 1) as errors

The repairs focus on defensive programming, improved error context, and distinguishing intentional failures from unexpected errors.

## Research Summary

From the error reports:

- **Error Distribution**: 40% validation errors, 40% execution errors, 20% state errors
- **Root Cause Analysis**: State machine transition attempted in Block 2 (completion phase) without proper state restoration when research agent fails or times out
- **Classification Agent Behavior**: Haiku LLM agent sometimes returns valid `topic_directory_slug` but empty `research_topics` array - this is acceptable with current fallback handling (generates `topic1`, `topic2`, etc.)
- **Lock File Dependencies**: The `.topic_number.lock` file is critical infrastructure used by 8+ workflow commands - no changes needed to lock mechanism
- **Execution Error Context**: Exit code 127 errors from `/etc/bashrc` sourcing are environment-specific and not actionable; exit code 1 from `return 1` is intentional validation behavior

**Recommended Approach**: Focus on state machine robustness and error classification rather than trying to prevent all errors.

## Success Criteria
- [ ] No more STATE_FILE not set errors from `sm_transition` in /research command
- [ ] Classification agent validation errors logged as warnings (not errors) when fallback succeeds
- [ ] Intentional validation returns (exit code 1) not logged as errors by bash trap
- [ ] All existing tests pass after changes
- [ ] Error log shows improved error classification (state_error vs validation_warning vs execution_error)

## Technical Design

### Architecture Overview

The /research command uses a multi-block bash execution pattern:
- **Block 1a**: Initial setup, state initialization, library sourcing
- **Block 1b**: Topic naming agent invocation (subagent task)
- **Block 1c**: Parse agent output, initialize workflow paths
- **Block 2**: Verification and completion (separate bash execution context)

The state machine issue occurs because:
1. Block 2 sources libraries fresh (new bash context)
2. `load_workflow_state` is called but may fail silently
3. `sm_transition "$STATE_COMPLETE"` is called without verifying state machine is initialized
4. `sm_transition` fails because `STATE_FILE` not set

### Solution Architecture

```
Block 2 Entry
    │
    ▼
source libraries ──► state-persistence.sh, workflow-state-machine.sh
    │
    ▼
load_workflow_state() ──► Sets STATE_FILE, sources state file
    │
    ▼
[NEW] validate_state_machine_ready() ──► Check STATE_FILE and CURRENT_STATE
    │
    ▼
sm_transition() ──► Now safe to call
```

### Key Changes

1. **Add state machine readiness check**: New guard function `validate_state_machine_ready()` in workflow-state-machine.sh
2. **Improve load_workflow_state error handling**: Return non-zero on failure, set explicit error context
3. **Reclassify validation fallbacks**: Change error logging level for successful fallback scenarios
4. **Filter intentional exits from trap**: Add exit code filtering to bash error trap

## Implementation Phases

### Phase 1: State Machine Robustness [NOT STARTED]
dependencies: []

**Objective**: Ensure state machine is properly initialized before any transitions in Block 2

**Complexity**: Medium

**Tasks**:
- [ ] Add `validate_state_machine_ready()` function to `.claude/lib/workflow/workflow-state-machine.sh`
  - Returns 0 if STATE_FILE set and file exists, CURRENT_STATE set
  - Returns 1 with diagnostic message if not ready
  - Provides clear remediation steps in error message
- [ ] Update `sm_transition()` to call `validate_state_machine_ready()` at entry (line 606)
  - Already has STATE_FILE check, add CURRENT_STATE validation
  - Ensure both checks run before attempting transition
- [ ] Update `/research` Block 2 to check state machine readiness after `load_workflow_state`
  - Add explicit check before `sm_transition "$STATE_COMPLETE"`
  - Log diagnostic info if check fails
- [ ] Add `load_workflow_state` return value check in Block 2 (line 497)
  - Capture return value: `load_workflow_state "$WORKFLOW_ID" false; LOAD_EXIT=$?`
  - Check `LOAD_EXIT` and log error if non-zero

**Testing**:
```bash
# Test state machine guard
bash .claude/tests/workflow/test_state_machine_guards.sh

# Test full research workflow
/research "test query" --complexity 1
```

**Expected Duration**: 3 hours

---

### Phase 2: Classification Agent Validation Improvements [NOT STARTED]
dependencies: [1]

**Objective**: Reclassify successful fallback scenarios from errors to warnings

**Complexity**: Low

**Tasks**:
- [ ] Update `validate_and_generate_filename_slugs()` in workflow-initialization.sh (line 169-186)
  - Change from `log_command_error` to `log_command_warning` when fallback succeeds
  - Keep error logging only for complete failures
  - Current code already handles fallback correctly - just change log severity
- [ ] Update error message text to indicate warning vs error
  - FROM: "validation_error" type
  - TO: "validation_warning" type (or remove from error log entirely)
- [ ] Add context field to indicate fallback was used successfully
  - Include: `"fallback_reason": "empty_research_topics", "fallback_result": "success"`
- [ ] Document expected LLM behavior in plan-complexity-classifier.md
  - Add note that empty research_topics is handled gracefully
  - Emphasize topic_directory_slug is the critical field

**Testing**:
```bash
# Test with intentionally empty research_topics
bash .claude/tests/topic-naming/test_topic_naming_fallback.sh

# Verify no error logged for successful fallback
grep -c "validation_error.*research_topics" .claude/data/logs/errors.jsonl
```

**Expected Duration**: 2 hours

---

### Phase 3: Execution Error Classification [NOT STARTED]
dependencies: [1]

**Objective**: Distinguish intentional validation returns from unexpected errors in bash trap

**Complexity**: Medium

**Tasks**:
- [ ] Update `setup_bash_error_trap()` in error-handling.sh to filter exit code 1
  - Add parameter for expected exit codes: `setup_bash_error_trap "$CMD" "$WF" "$ARGS" "1"`
  - Do not log if exit code matches expected list
  - Still log exit code 127 (command not found) as actual error
- [ ] Add trap context for intentional returns
  - Create `INTENTIONAL_EXIT_CODES` array variable
  - Check against array before logging
- [ ] Update /research command to declare intentional exit codes
  - After `setup_bash_error_trap`, set `INTENTIONAL_EXIT_CODES=(1)`
  - Document this pattern in code comments
- [ ] Add filtering for `/etc/bashrc` sourcing errors (exit 127)
  - These are environment-specific and not actionable
  - Add environment normalization note to troubleshooting docs

**Testing**:
```bash
# Test trap filtering
bash -c 'source .claude/lib/core/error-handling.sh; setup_bash_error_trap "/test" "test_1" "args"; return 1'

# Verify no error logged
tail -1 .claude/data/logs/errors.jsonl | jq .
```

**Expected Duration**: 3 hours

---

### Phase 4: Testing and Documentation [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Validate all fixes and document the changes

**Complexity**: Low

**Tasks**:
- [ ] Run full test suite for affected libraries
  ```bash
  bash .claude/tests/workflow/run_all_workflow_tests.sh
  bash .claude/tests/topic-naming/run_all_topic_tests.sh
  ```
- [ ] Create integration test for state machine recovery scenario
  - Test that Block 2 properly recovers state
  - Test that sm_transition works after load_workflow_state
- [ ] Update troubleshooting documentation
  - Add state machine initialization troubleshooting to research-command-guide.md
  - Document expected exit codes and error types
- [ ] Verify error log shows improved classification
  - Run /research command
  - Check error log for correct error types
  - Confirm no false-positive errors logged

**Testing**:
```bash
# Full validation
bash .claude/scripts/validate-all-standards.sh --all

# Research command smoke test
/research "test workflow" --complexity 1
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- `test_state_machine_guards.sh`: Test `validate_state_machine_ready()` function
- `test_topic_naming_fallback.sh`: Test classification fallback behavior (existing)
- `test_error_trap_filtering.sh`: Test bash trap exit code filtering

### Integration Tests
- `test_research_workflow_completion.sh`: Full /research workflow from start to completion
- `test_block2_state_recovery.sh`: Verify Block 2 properly recovers state from Block 1

### Regression Tests
- All existing tests in `.claude/tests/workflow/` must pass
- All existing tests in `.claude/tests/topic-naming/` must pass

### Error Log Verification
After implementation:
- `validation_error` count for "research_topics" should decrease
- `state_error` count for "STATE_FILE not set" should be zero
- `execution_error` count for exit code 1 should decrease

## Documentation Requirements

Update the following documentation:
- [ ] `.claude/docs/guides/commands/research-command-guide.md` - Add troubleshooting section for state machine errors
- [ ] `.claude/docs/reference/standards/code-standards.md` - Document intentional exit code pattern
- [ ] `.claude/agents/plan-complexity-classifier.md` - Note about empty research_topics handling (line ~110)

## Dependencies

### Library Dependencies
- `workflow-state-machine.sh` (>=2.0.0) - State machine functions
- `state-persistence.sh` (>=1.5.0) - State file management
- `error-handling.sh` - Error logging and trap setup
- `workflow-initialization.sh` - Path initialization and validation

### External Dependencies
- `jq` command - JSON parsing
- Bash 4.0+ - For associative arrays in state machine

### Prerequisites
- Research reports read and analyzed (complete)
- Lock file infrastructure verified as stable (no changes needed)

## Risk Assessment

### Low Risk
- Phase 2 changes are log-level only, no functional impact
- Phase 4 is documentation only

### Medium Risk
- Phase 1 changes affect state machine core - thorough testing required
- Phase 3 changes bash trap behavior - could mask real errors if filter too aggressive

### Mitigation
- Add `validate_state_machine_ready()` as separate function (not inline) for easy rollback
- Make exit code filtering opt-in (not default) to avoid masking unexpected errors
- All changes guarded by version checks where applicable
