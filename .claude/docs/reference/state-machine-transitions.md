# State Machine Transitions Reference

## Overview

This document describes the state transition rules for the workflow state machine used in /build, /plan, and other workflow commands. Understanding these transitions is critical for avoiding invalid state transition errors.

## Core States

The workflow state machine defines 8 core states:

1. **initialize** - Workflow initialization and setup
2. **research** - Research and analysis phase
3. **plan** - Planning and design phase
4. **implement** - Implementation phase
5. **test** - Testing phase (REQUIRED after implement)
6. **debug** - Debugging failed tests
7. **document** - Documentation updates
8. **complete** - Terminal state (workflow finished)

## State Transition Table

The following table defines all valid state transitions. Any transition not listed is INVALID and will be rejected by `sm_transition()`.

| Current State | Valid Next States | Notes |
|--------------|-------------------|-------|
| initialize | research, implement | Can skip research for /build workflows |
| research | plan, complete | Can skip to complete for research-only |
| plan | implement, complete, debug | Can skip to complete for research-and-plan, debug for debug-only |
| implement | test | **MUST** transition to test (cannot skip to complete) |
| test | debug, document, complete | Conditional: debug if failed, document if passed |
| debug | test, document, complete | Can retry testing, document, or abandon |
| document | complete | Must proceed to completion |
| complete | *(none)* | Terminal state - no outgoing transitions |

## Required Sequences

Certain state sequences are enforced to maintain workflow integrity:

### implement → test → complete

The most important sequence is **implement → test → complete**. After implementation, testing is MANDATORY:

```
✓ VALID:   implement → test → document → complete
✓ VALID:   implement → test → debug → test → complete
✗ INVALID: implement → complete (skips testing)
✗ INVALID: implement → document (skips testing)
```

**Reason**: All code changes must be tested before completion to prevent untested code from being merged.

### Conditional Transitions from test

The test phase has conditional transitions based on test results:

```
test --[tests passed]--> document → complete
test --[tests failed]--> debug → test (retry)
test --[skip docs]----> complete
```

### Debug Workflows

Debug can transition to multiple states for flexibility:

```
debug --[fixed]--> test (retry tests)
debug --[documented fix]--> document → complete
debug --[cannot fix]--> complete (abandon)
```

## Idempotent Transitions

Same-state transitions are idempotent (no-op, always succeed):

```bash
# Example: Already in 'test' state
sm_transition "$STATE_TEST" "reason"  # Returns 0 immediately, no error
```

**Use case**: Retry logic and resume scenarios can safely call transitions without checking current state first.

## Terminal State Protection

Terminal states (`complete`, `abandoned`) cannot be transitioned from:

```bash
# If already in 'complete' state:
sm_transition "$STATE_IMPLEMENT" "..."  # ERROR: Cannot transition from terminal state
```

**Reason**: Workflows must be restarted for new work, not resumed from completion.

## Examples

### Valid Transition Sequences

**Full implementation workflow** (/build):
```
initialize → implement → test → document → complete
```

**Failed tests with debug** (/build):
```
initialize → implement → test → debug → test → document → complete
```

**Research and plan** (/plan):
```
initialize → research → plan → complete
```

**Debug-only workflow** (/debug):
```
initialize → plan → debug → complete
```

### Invalid Transition Sequences

**Skipping tests after implementation**:
```
initialize → implement → complete  ❌ ERROR: Invalid transition
                                      (implement can only go to test)
```

**Transitioning from terminal state**:
```
... → complete → implement  ❌ ERROR: Cannot transition from terminal state
```

**Invalid debug transition**:
```
... → document → debug  ❌ ERROR: Invalid transition
                          (document can only go to complete)
```

## Error Messages

### Invalid Transition Error

```
ERROR: Invalid state transition: implement → complete
Valid transitions from 'implement': test
```

**Resolution**: Follow the required sequence (implement → test → ...).

### STATE_FILE Not Set Error

```
ERROR: STATE_FILE not set in sm_transition()
DIAGNOSTIC: Call load_workflow_state() before sm_transition()
```

**Resolution**: Ensure `load_workflow_state()` is called before first `sm_transition()`.

### Terminal State Error

```
ERROR: Cannot transition from terminal state: complete
Terminal states are final - workflow must be restarted for new transitions
```

**Resolution**: Start a new workflow instead of trying to resume a completed one.

## Implementation Notes

### Pre-Transition Validation

`sm_transition()` performs validation before attempting transitions:

1. **STATE_FILE check**: Ensures workflow state is loaded
2. **CURRENT_STATE check**: Ensures state machine is initialized
3. **Idempotency check**: Same-state transitions return early
4. **Terminal state check**: Prevents transitions from complete/abandoned
5. **Transition table check**: Validates target state is in allowed list

### Error Logging

Invalid transitions are automatically logged to `.claude/data/logs/errors.jsonl` with:
- Current state
- Target state
- Valid transitions list
- Transition reason (if provided)

Use `/errors --type state_error` to query state transition failures.

## Troubleshooting

### Common Issues

**Issue**: Tests keep failing but I want to mark work complete
**Solution**: Transition to debug state first, document known issues, then complete. Don't skip testing.

**Issue**: Want to retry implementation after tests fail
**Solution**: Use debug → test → ... cycle. Fix code, re-run tests.

**Issue**: Getting "Invalid transition" errors
**Solution**: Check current state with `echo $CURRENT_STATE`, then consult transition table above.

### Debugging State Transitions

Enable state transition debugging:

```bash
# In workflow state file
DEBUG=1

# State transitions will log to ~/.claude/tmp/workflow_debug.log
tail -f ~/.claude/tmp/workflow_debug.log
```

## See Also

- [Workflow State Machine Library](../../lib/workflow/workflow-state-machine.sh) - Implementation
- [State Persistence Library](../../lib/core/state-persistence.sh) - State file management
- [Build Command Guide](../guides/commands/build-command-guide.md) - /build workflow details
- [Error Handling Pattern](../concepts/patterns/error-handling.md) - Error logging integration

## Version History

- **2025-11-29**: Initial documentation (Spec 976, Phase 6)
  - Documented 8 core states
  - Documented transition table with all valid transitions
  - Added implement→test→complete requirement
  - Added debug→document transition (new in Spec 976)
  - Added idempotent transition behavior
  - Added terminal state protection
