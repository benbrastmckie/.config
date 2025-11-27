# /plan Command Errors Repair Plan

## Metadata
- **Date**: 2025-11-23
- **Feature**: Fix /plan command errors and improve reliability
- **Scope**: Error handling, library sourcing, state machine initialization, topic naming agent
- **Estimated Phases**: 4
- **Estimated Hours**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Status**: [NOT STARTED]
- **Structure Level**: 0
- **Complexity Score**: 30
- **Research Reports**:
  - [Repair Analysis Report](/home/benjamin/.config/.claude/specs/904_plan_command_errors_repair/reports/003_repair_analysis.md)

## Overview

This repair plan addresses the critical errors identified in the /plan command workflow based on comprehensive error analysis. The analysis found 96 total errors, with 22 (23%) specifically affecting the /plan command. The primary issues are:

1. **Missing Library Functions (30% of errors)**: Exit code 127 failures due to functions like `save_completed_states_to_state` and `append_workflow_state` not being available when called
2. **Topic Naming Agent Failures (4 errors)**: Agent fails to create output file, causing fallback to `no_name` directories
3. **State Machine Initialization Issues (6 errors)**: `sm_transition` called before state machine properly initialized
4. **Empty Research Topics (3 errors)**: Classification returns empty `research_topics` array

## Research Summary

Based on the repair analysis report (003_repair_analysis.md):

- **Error Distribution**: /plan command has highest error rate (22 errors, 23% of total)
- **Root Causes Identified**:
  1. Library sourcing order issues causing function unavailability
  2. Topic naming agent timeout/environment problems
  3. State machine not initialized before transition attempts
  4. Classification agent missing research topics in output
- **Prioritized Fixes**: Library sourcing (HIGH), State machine init (HIGH), Topic naming (MEDIUM), Classification (LOW)
- **Estimated Impact**: Fixing library sourcing alone eliminates 36.5% of errors

## Success Criteria

- [ ] All /plan command executions complete without exit code 127 errors
- [ ] Topic naming agent creates valid output files or fails gracefully with clear error messages
- [ ] State machine transitions only occur after proper initialization
- [ ] No `no_name` directories created due to agent failures (fallback only for validation failures)
- [ ] Error logging captures all failure scenarios with actionable diagnostics
- [ ] Existing test suite passes after changes

## Technical Design

### Architecture Changes

The fixes involve three layers:

1. **Library Layer** (`lib/core/`, `lib/workflow/`):
   - Add function existence validation before export
   - Implement defensive checks in state machine functions
   - Create utility for pre-flight function validation

2. **Agent Layer** (topic-naming-agent):
   - Increase timeout for agent invocation
   - Add retry logic with exponential backoff
   - Improve error diagnostics

3. **Command Layer** (`commands/plan.md`):
   - Add pre-flight validation for critical functions
   - Improve state machine initialization sequence
   - Enhance error recovery paths

### Dependency Graph

```
Phase 1 (Foundation) -> Phase 2 (State Machine) -> Phase 3 (Agent Reliability) -> Phase 4 (Validation)
```

## Implementation Phases

### Phase 1: Library Function Validation [NOT STARTED]
dependencies: []

**Objective**: Ensure all library functions are validated as available before use, preventing exit code 127 errors.

**Complexity**: Medium

Tasks:
- [ ] Add `validate_library_functions` utility to `lib/core/library-version-check.sh` that checks function availability
- [ ] Add defensive checks in `save_completed_states_to_state` function to verify `append_workflow_state` exists before calling
- [ ] Add defensive checks in `sm_transition` to verify required functions exist
- [ ] Update `/plan` command Block 1a to call `validate_library_functions` for state-persistence, workflow-state-machine, and error-handling libraries
- [ ] Update `/plan` command Block 2 to call `validate_library_functions` before using state persistence functions
- [ ] Update `/plan` command Block 3 to call `validate_library_functions` before using state persistence functions

Testing:
```bash
# Run unit test for library function validation
bash .claude/tests/unit/test_error_logging.sh

# Verify validate_library_functions works correctly
bash -c 'source .claude/lib/core/library-version-check.sh; validate_library_functions "state-persistence"'
```

**Expected Duration**: 1.5 hours

### Phase 2: State Machine Defensive Initialization [NOT STARTED]
dependencies: [1]

**Objective**: Modify state machine functions to handle uninitialized state gracefully with clear error messages.

**Complexity**: Low

Tasks:
- [ ] Update `sm_transition` in `lib/workflow/workflow-state-machine.sh` to check STATE_FILE is set before validation (already partially implemented per analysis)
- [ ] Update `sm_transition` to check CURRENT_STATE is set before transition validation (already partially implemented per analysis)
- [ ] Add initialization check in `sm_validate_state` to provide actionable error messages
- [ ] Add `sm_is_initialized` helper function that commands can call before transitions
- [ ] Update error messages in state machine functions to follow five-component format

Testing:
```bash
# Run state transition tests
bash .claude/tests/state/test_build_state_transitions.sh

# Test state machine validation
bash -c 'source .claude/lib/core/state-persistence.sh; source .claude/lib/workflow/workflow-state-machine.sh; sm_validate_state || echo "Validation correctly failed for uninitialized state"'
```

**Expected Duration**: 1 hour

### Phase 3: Topic Naming Agent Reliability [NOT STARTED]
dependencies: [1]

**Objective**: Improve topic naming agent reliability with timeout increase, retry logic, and better error diagnostics.

**Complexity**: Medium

Tasks:
- [ ] Increase `validate_agent_output_with_retry` timeout in Block 1b from 10s to 15s per attempt
- [ ] Add environment validation before topic naming agent invocation (verify output directory writable)
- [ ] Add verbose error logging with workflow context when agent fails
- [ ] Update Block 1c to distinguish between agent timeout vs format validation failure in error messages
- [ ] Add agent output file path validation before cleanup to preserve diagnostics

Testing:
```bash
# Run topic naming tests
bash .claude/tests/topic-naming/test_topic_naming_agent.sh
bash .claude/tests/topic-naming/test_topic_naming_fallback.sh
bash .claude/tests/topic-naming/test_topic_naming_integration.sh
```

**Expected Duration**: 1.5 hours

### Phase 4: Integration Testing and Validation [NOT STARTED]
dependencies: [2, 3]

**Objective**: Validate all fixes work together and no regressions introduced.

**Complexity**: Medium

Tasks:
- [ ] Run full test suite to verify no regressions
- [ ] Test /plan command with valid feature description
- [ ] Test /plan command with --complexity flag
- [ ] Test /plan command with --file flag
- [ ] Verify error log captures failures with proper context
- [ ] Verify no exit code 127 errors in clean execution
- [ ] Document any remaining edge cases in troubleshooting section

Testing:
```bash
# Run full test suite
bash .claude/tests/run_all_tests.sh

# Test /plan command manually
# /plan "test feature for validation"

# Check error logs for new entries
bash -c 'tail -20 .claude/data/logs/errors.jsonl | jq -r ".command" | grep -c "/plan" || echo "No new /plan errors"'
```

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Tests
- `test_error_logging.sh`: Validates error logging functions
- `test_state_persistence_across_blocks.sh`: Validates state persistence between bash blocks
- `test_benign_error_filter.sh`: Validates error filtering

### Integration Tests
- `test_build_state_transitions.sh`: Validates state machine transitions
- Topic naming test suite: Validates agent output handling

### Manual Validation
1. Execute `/plan "simple test feature"` - should complete without errors
2. Execute `/plan "test feature" --complexity 2` - should complete with lower complexity
3. Verify no exit code 127 errors in execution
4. Check `.claude/data/logs/errors.jsonl` for reduced error count

## Documentation Requirements

- Update troubleshooting section in `/plan` command if new error patterns identified
- Add comments in modified library functions explaining defensive patterns
- No external documentation changes required (internal fix)

## Dependencies

### Internal Dependencies
- `lib/core/state-persistence.sh` - State persistence functions
- `lib/core/error-handling.sh` - Error logging functions
- `lib/workflow/workflow-state-machine.sh` - State machine functions
- `lib/core/library-version-check.sh` - Version checking utilities
- `commands/plan.md` - Main command file

### External Dependencies
- `jq` - JSON processing (already required)
- No new external dependencies

## Risk Assessment

### Low Risk
- Adding defensive checks to existing functions (non-breaking)
- Improving error messages (informational only)

### Medium Risk
- Increasing agent timeout (may slow execution for edge cases)
- Adding retry logic (could mask underlying issues)

### Mitigation
- All changes maintain backward compatibility
- Defensive patterns fail-fast when functions missing
- Error logging preserves diagnostic context for debugging
