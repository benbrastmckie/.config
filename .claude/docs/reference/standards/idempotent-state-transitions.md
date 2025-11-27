# Idempotent State Transitions Standard

## Definition

Idempotent state transitions allow the workflow state machine to handle same-state transition requests gracefully without error. When `sm_transition()` is called with a target state that matches the current state, the function succeeds immediately with an early-exit optimization rather than processing the full transition logic.

## Behavior

### Same-State Transition Handling

When `sm_transition(next_state)` is called where `next_state == CURRENT_STATE`:

1. **Early-Exit Check**: Function detects same-state condition after defensive validation
2. **Informational Logging**: Logs INFO message to stderr (not ERROR)
3. **Success Return**: Returns exit code 0 (success)
4. **No Processing**: Skips transition validation, state persistence, and checkpoint saves

### Code Implementation

Location: `/home/benjamin/.config/.claude/lib/workflow/workflow-state-machine.sh` (lines 644-648)

```bash
# Idempotent: Same-state transitions succeed immediately (no-op)
if [ "${CURRENT_STATE:-}" = "$next_state" ]; then
  echo "INFO: Already in state '$next_state', transition skipped (idempotent)" >&2
  return 0  # Success, no error
fi
```

### Execution Order

The same-state check occurs after defensive validation but before transition validation:

```
sm_transition(next_state)
  ├── Validate STATE_FILE set (lines 609-625)
  ├── Validate CURRENT_STATE set (lines 627-642)
  ├── Check same-state (lines 644-648) ← Idempotent check
  ├── Validate transition allowed (lines 650-683)
  ├── Save pre-transition checkpoint (lines 685-688)
  ├── Update CURRENT_STATE (lines 690-702)
  ├── Update COMPLETED_STATES (lines 704-715)
  └── Save post-transition checkpoint (lines 717-724)
```

## Use Cases

### Checkpoint Resume Scenarios

The `/build` command's checkpoint resume feature can trigger same-state transitions when:

- Resuming from a checkpoint at the same state as `--starting-phase`
- Retrying a failed phase that was already partially completed
- Multi-iteration builds where subsequent iterations start from the same state

Example:
```bash
# Build interrupted during implement phase
/build plan.md --starting-phase 3

# Resume from checkpoint (state is already "implement")
/build plan.md --resume checkpoint.json --starting-phase 3
# Result: INFO message, no error, continues successfully
```

### Defensive State Validation

Commands can defensively call `sm_transition()` even when state might already be correct:

```bash
# Ensure we're in research state (safe even if already there)
sm_transition "$STATE_RESEARCH" || exit 1

# Continue with research tasks
research_topic "$description"
```

### Retry Logic

Workflows with retry capabilities benefit from idempotent transitions:

```bash
# Retry implementation phase
for attempt in 1 2 3; do
  sm_transition "$STATE_IMPLEMENT"  # Idempotent on subsequent attempts
  if run_implementation; then
    break
  fi
done
```

## Logging

### Informational Message Format

Same-state transitions log an INFO-level message to stderr:

```
INFO: Already in state 'implement', transition skipped (idempotent)
```

### No Error Logging

Idempotent transitions do NOT trigger error logging via `log_command_error()`. This is intentional because same-state transitions are valid, expected behavior in retry/resume scenarios.

### Log Filtering

Commands can filter INFO messages if needed:

```bash
sm_transition "$STATE_RESEARCH" 2>/dev/null  # Suppress INFO output
```

## Commands Benefiting

### Primary Beneficiary: /build

The `/build` command gains the most benefit through:

- Checkpoint resume with `--resume` flag (8 occurrences in build.md)
- Multi-iteration execution for large plans
- Retry logic after transient failures

### All Commands (Defensive Programming)

All workflow commands benefit from defensive state validation:

- `/plan` - Safe state initialization
- `/repair` - Retry logic support
- `/debug` - Multiple debug attempts
- `/revise` - Plan revision workflows
- `/research` - Research retry scenarios

### Commands NOT Requiring Idempotency

These commands use linear state progressions with no retry/resume logic:

- Standard `/plan` workflow (no checkpoint resume)
- Standard `/research` workflow (no retry logic)
- `/debug` without retry attempts

However, idempotent transitions provide no harm and enable future retry capabilities.

## Examples

### Basic Same-State Transition

```bash
#!/usr/bin/env bash
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh"
source "$CLAUDE_LIB/core/state-persistence.sh"

# Initialize state machine
sm_init "example workflow" "/example" "full-implementation" "3" "[]"

# Transition to research
sm_transition "$STATE_RESEARCH"
echo "Current state: $(sm_get_current_state)"  # Output: research

# Attempt same-state transition (idempotent)
sm_transition "$STATE_RESEARCH"
# Output: INFO: Already in state 'research', transition skipped (idempotent)
echo "Current state: $(sm_get_current_state)"  # Output: research (unchanged)
```

### Checkpoint Resume Pattern

```bash
#!/usr/bin/env bash
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh"
source "$CLAUDE_LIB/workflow/checkpoint-utils.sh"

# Load checkpoint state
restore_from_checkpoint "$checkpoint_path" || exit 1
# CURRENT_STATE restored from checkpoint (e.g., "implement")

# Safe to transition even if already in implement state
sm_transition "$STATE_IMPLEMENT"  # Idempotent if state already "implement"

# Continue with implementation
execute_implementation_phase
```

### Defensive State Validation

```bash
#!/usr/bin/env bash
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh"

# Ensure we're in the correct state before critical operation
ensure_research_state() {
  local current=$(sm_get_current_state)

  if [ "$current" = "$STATE_RESEARCH" ]; then
    echo "Already in research state"
  else
    sm_transition "$STATE_RESEARCH" || return 1
  fi
}

# Safe to call multiple times
ensure_research_state
ensure_research_state  # Second call is idempotent
```

### Retry Loop with Idempotent Transitions

```bash
#!/usr/bin/env bash
source "$CLAUDE_LIB/workflow/workflow-state-machine.sh"

# Retry implementation with exponential backoff
MAX_RETRIES=3
for attempt in $(seq 1 $MAX_RETRIES); do
  # Safe to transition even on retry attempts
  sm_transition "$STATE_IMPLEMENT"  # Idempotent on attempts 2-3

  if run_implementation_phase; then
    echo "Implementation succeeded on attempt $attempt"
    break
  else
    echo "Attempt $attempt failed, retrying..."
    sleep $((2 ** attempt))
  fi
done
```

## Implementation Details

### Performance Optimization

The early-exit check provides a small performance improvement:

- **Time Saved**: ~5-10ms per same-state transition (skips validation, persistence)
- **Context Impact**: Minimal (one string comparison)
- **Memory Impact**: None (no additional allocations)

### Non-Breaking Change

Adding idempotent transitions is a non-breaking change:

- **API Compatibility**: No function signature changes
- **Return Values**: Exit code 0 (success) matches normal transition behavior
- **Side Effects**: No state changes (as expected for same-state)
- **Backward Compatibility**: Existing code continues to work unchanged

### Error Handling Integration

Idempotent transitions integrate with existing error handling:

- **No Error Logging**: `log_command_error()` not called for same-state
- **Defensive Validation Preserved**: STATE_FILE and CURRENT_STATE checks still run
- **Checkpoint Safety**: No checkpoint saves for same-state (no state change)

### COMPLETED_STATES Array

The COMPLETED_STATES array already prevented duplicates (lines 705-716):

```bash
# Add to completed states history (avoid duplicates)
local already_completed=0
for state in "${COMPLETED_STATES[@]}"; do
  if [ "$state" = "$next_state" ]; then
    already_completed=1
    break
  fi
done

if [ "$already_completed" -eq 0 ]; then
  COMPLETED_STATES+=("$next_state")
fi
```

With idempotent transitions, same-state transitions never reach this code (early-exit before state update).

## See Also

- [Workflow State Machine Documentation](../../architecture/workflow-state-machine.md)
- [State Orchestration Transitions](../../architecture/state-orchestration-transitions.md)
- [Checkpoint Resume Guide](../../guides/workflows/checkpoint-resume-guide.md)
- [Code Standards - Error Handling](./code-standards.md#error-handling)
