# Option B: State Machine Extension Implementation Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Implementing THEN breakpoint syntax via State Machine Extension with Explicit Phase Transitions
- **Report Type**: Implementation Architecture Analysis

## Executive Summary

This report provides detailed implementation guidance for Option B (State Machine Extension with Explicit Phase Transitions) to enable THEN breakpoint syntax in workflow commands. The approach leverages the existing state-based orchestration architecture in `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` by adding a new STATE_THEN_PENDING state, extending the transition table, and implementing `sm_queue_then_command()` for storing queued commands. This approach requires approximately 150-250 lines of modifications across the state machine library, state persistence, and individual commands, with checkpoint schema updates to v2.2 for THEN command persistence.

## Findings

### 1. Current State Machine Architecture Analysis

#### 1.1 Core State Enumeration

The state machine defines 8 core workflow states (lines 40-48 of workflow-state-machine.sh):

```bash
readonly STATE_INITIALIZE="initialize"    # Phase 0
readonly STATE_RESEARCH="research"        # Phase 1
readonly STATE_PLAN="plan"                # Phase 2
readonly STATE_IMPLEMENT="implement"      # Phase 3
readonly STATE_TEST="test"                # Phase 4
readonly STATE_DEBUG="debug"              # Phase 5
readonly STATE_DOCUMENT="document"        # Phase 6
readonly STATE_COMPLETE="complete"        # Phase 7
```

#### 1.2 State Transition Table

Current transition table (lines 55-64):

```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research,implement"
  [research]="plan,complete"
  [plan]="implement,complete"
  [implement]="test"
  [test]="debug,document"
  [debug]="test,complete"
  [document]="complete"
  [complete]=""
)
```

**Key Observation**: The transition table uses comma-separated strings to define valid next states. Adding `then_pending` requires appending to multiple state transitions.

#### 1.3 State Machine Global Variables

The state machine maintains these critical variables (lines 70-86):

```bash
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"
declare -ga COMPLETED_STATES=()
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"
```

#### 1.4 Workflow Scopes

The state machine supports 5 workflow scopes (lines 419-428):

1. `research-only` - Terminal: research
2. `research-and-plan` - Terminal: plan
3. `research-and-revise` - Terminal: plan
4. `full-implementation` - Terminal: complete
5. `debug-only` - Terminal: debug

### 2. State Persistence Analysis

#### 2.1 State Persistence Library

The state persistence library (`/home/benjamin/.config/.claude/lib/state-persistence.sh`) provides:

- `init_workflow_state()` - Creates state file (lines 130-169)
- `load_workflow_state()` - Loads state file (lines 212-296)
- `append_workflow_state()` - Appends key-value pairs (lines 321-336)
- `save_json_checkpoint()` - Saves JSON checkpoints (lines 359-377)
- `load_json_checkpoint()` - Loads JSON checkpoints (lines 398-414)

**Key Pattern for THEN**: Use `append_workflow_state()` to persist THEN_NEXT_COMMAND and THEN_NEXT_ARGS across bash block boundaries.

#### 2.2 Checkpoint Schema

Current checkpoint schema version is 2.1 (line 25 of checkpoint-utils.sh). The checkpoint structure includes:

- `state_machine` section (lines 112, 432-454)
- `transition_table` within state_machine (lines 439-448)
- `workflow_config` with scope, description, command (lines 449-453)

**Schema Update Requirement**: Add THEN command fields to checkpoint schema.

### 3. sm_transition() Function Analysis

The `sm_transition()` function (lines 606-651) performs:

1. **Validation**: Checks if transition is in `STATE_TRANSITIONS[$CURRENT_STATE]` (lines 609-617)
2. **Pre-transition checkpoint**: Placeholder for checkpoint coordination (line 622)
3. **State update**: Sets `CURRENT_STATE` (line 625)
4. **History tracking**: Adds to `COMPLETED_STATES` array (lines 628-638)
5. **Post-transition checkpoint**: Placeholder (line 641)
6. **Persistence**: Calls `save_completed_states_to_state()` (lines 645-647)

**Integration Point**: After completing a state that has a queued THEN command, the system must detect and execute it.

### 4. Command Integration Points

#### 4.1 Argument Capture Pattern

Commands use two-step argument capture (argument-capture.sh:78-168):

1. **Part 1**: `capture_argument_part1()` writes to temp file
2. **Part 2**: `capture_argument_part2()` reads and exports variable

**THEN Parsing Location**: Parse THEN syntax in Part 2 after capturing the full argument.

#### 4.2 State Machine Initialization

Commands initialize state machine via `sm_init()` with 5 parameters (coordinate.md:370):

```bash
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" "$WORKFLOW_TYPE" "$RESEARCH_COMPLEXITY" "$RESEARCH_TOPICS_JSON"
```

**Integration Point**: After `sm_init()`, store queued THEN command if present.

#### 4.3 Completion Points

Each command has a completion point where it transitions to terminal state (research.md:349):

```bash
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
```

**Integration Point**: Before transitioning to terminal state, check for queued THEN command.

### 5. Implementation Design for Option B

#### 5.1 New State Definition

Add to workflow-state-machine.sh after line 48:

```bash
readonly STATE_THEN_PENDING="then_pending"  # Special state: queued command waiting
```

#### 5.2 Extended State Transitions

Modify STATE_TRANSITIONS to allow transition to then_pending from completion-capable states:

```bash
declare -gA STATE_TRANSITIONS=(
  [initialize]="research,implement"
  [research]="plan,complete,then_pending"      # MODIFIED
  [plan]="implement,complete,then_pending"     # MODIFIED
  [implement]="test"
  [test]="debug,document"
  [debug]="test,complete,then_pending"         # MODIFIED
  [document]="complete,then_pending"           # MODIFIED
  [complete]=""
  [then_pending]="research,debug,plan,revise"  # NEW: can transition to any target command state
)
```

#### 5.3 New State Machine Functions

##### sm_queue_then_command()

```bash
# sm_queue_then_command: Store queued THEN command in state
# Usage: sm_queue_then_command <next-command> <next-args>
# Example: sm_queue_then_command "/plan" ""
sm_queue_then_command() {
  local next_cmd="$1"
  local next_args="${2:-}"

  # Validate command is a valid target
  local valid_commands="research|debug|plan|revise"
  if ! echo "$next_cmd" | grep -qE "^/($valid_commands)$"; then
    echo "ERROR: Invalid THEN command: $next_cmd" >&2
    echo "Valid commands: /research, /debug, /plan, /revise" >&2
    return 1
  fi

  # Persist to workflow state
  append_workflow_state "THEN_NEXT_COMMAND" "$next_cmd"
  append_workflow_state "THEN_NEXT_ARGS" "$next_args"

  # Flag that THEN is queued
  append_workflow_state "THEN_QUEUED" "true"

  echo "Queued THEN command: $next_cmd $next_args" >&2
  return 0
}
export -f sm_queue_then_command
```

##### sm_has_queued_then()

```bash
# sm_has_queued_then: Check if a THEN command is queued
# Usage: if sm_has_queued_then; then ... fi
sm_has_queued_then() {
  [ "${THEN_QUEUED:-}" = "true" ]
}
export -f sm_has_queued_then
```

##### sm_execute_queued_then()

```bash
# sm_execute_queued_then: Execute the queued THEN command
# Usage: sm_execute_queued_then
# Returns: Command path and args, or 1 if no command queued
sm_execute_queued_then() {
  if ! sm_has_queued_then; then
    echo "ERROR: No THEN command queued" >&2
    return 1
  fi

  local next_cmd="${THEN_NEXT_COMMAND:-}"
  local next_args="${THEN_NEXT_ARGS:-}"

  # Clear queued state
  append_workflow_state "THEN_QUEUED" "false"
  append_workflow_state "THEN_EXECUTED" "true"

  # Return command info
  echo "$next_cmd $next_args"
  return 0
}
export -f sm_execute_queued_then
```

##### sm_get_then_artifact_context()

```bash
# sm_get_then_artifact_context: Get artifact paths from completed workflow
# Usage: context=$(sm_get_then_artifact_context)
# Returns: JSON with artifact paths for next command
sm_get_then_artifact_context() {
  # Build context JSON from workflow state
  local context
  context=$(jq -n \
    --arg topic_path "${TOPIC_PATH:-}" \
    --arg research_dir "${RESEARCH_DIR:-}" \
    --arg plan_path "${PLAN_PATH:-}" \
    --arg report_count "${REPORT_COUNT:-0}" \
    '{
      topic_path: $topic_path,
      research_dir: $research_dir,
      plan_path: $plan_path,
      report_count: ($report_count | tonumber)
    }')

  echo "$context"
}
export -f sm_get_then_artifact_context
```

#### 5.4 THEN Syntax Parsing Function

Add to argument-capture.sh:

```bash
# parse_then_syntax: Extract THEN command from description
# Usage: parse_then_syntax "description THEN /command args"
# Sets: PARSED_DESCRIPTION, THEN_COMMAND, THEN_ARGS
parse_then_syntax() {
  local input="$1"

  # Initialize outputs
  PARSED_DESCRIPTION="$input"
  THEN_COMMAND=""
  THEN_ARGS=""

  # Check for THEN delimiter (case-sensitive)
  if [[ "$input" =~ (.+)[[:space:]]THEN[[:space:]]+(/?[a-z-]+)(.*) ]]; then
    PARSED_DESCRIPTION="${BASH_REMATCH[1]}"
    local cmd="${BASH_REMATCH[2]}"
    THEN_ARGS=$(echo "${BASH_REMATCH[3]}" | xargs)  # Trim whitespace

    # Normalize command (ensure leading slash)
    if [[ ! "$cmd" =~ ^/ ]]; then
      cmd="/$cmd"
    fi
    THEN_COMMAND="$cmd"
  fi

  export PARSED_DESCRIPTION
  export THEN_COMMAND
  export THEN_ARGS
}
export -f parse_then_syntax
```

#### 5.5 Checkpoint Schema Update (v2.2)

Add to checkpoint structure in save_checkpoint():

```bash
then_command: ($state.then_command // {
  next_command: null,
  next_args: null,
  queued: false,
  executed: false,
  artifact_context: null
})
```

### 6. Per-Command Integration

#### 6.1 Command Modification Pattern

Each command (/research, /plan, /debug, /revise) needs these modifications:

##### Part 2: Parse THEN syntax

```bash
# After reading description
parse_then_syntax "$FEATURE_DESCRIPTION"
FEATURE_DESCRIPTION="$PARSED_DESCRIPTION"

# Queue THEN command if present
if [ -n "$THEN_COMMAND" ]; then
  # Will be stored after sm_init
  PENDING_THEN_COMMAND="$THEN_COMMAND"
  PENDING_THEN_ARGS="$THEN_ARGS"
fi
```

##### After sm_init:

```bash
# Store queued THEN command
if [ -n "${PENDING_THEN_COMMAND:-}" ]; then
  sm_queue_then_command "$PENDING_THEN_COMMAND" "$PENDING_THEN_ARGS"
fi
```

##### Before completion transition:

```bash
# Check for queued THEN command
if sm_has_queued_then; then
  # Get artifact context for next command
  ARTIFACT_CONTEXT=$(sm_get_then_artifact_context)
  append_workflow_state "THEN_ARTIFACT_CONTEXT" "$ARTIFACT_CONTEXT"

  # Transition to then_pending instead of complete
  if ! sm_transition "$STATE_THEN_PENDING" 2>&1; then
    echo "ERROR: Failed to transition to then_pending state" >&2
    exit 1
  fi

  # Execute queued command
  THEN_INFO=$(sm_execute_queued_then)
  NEXT_CMD=$(echo "$THEN_INFO" | cut -d' ' -f1)
  NEXT_ARGS=$(echo "$THEN_INFO" | cut -d' ' -f2-)

  echo ""
  echo "=== Executing THEN Command ==="
  echo "Command: $NEXT_CMD $NEXT_ARGS"
  echo "Artifact Context: $ARTIFACT_CONTEXT"
  echo ""

  # Signal to Claude to invoke next command
  echo "THEN_EXECUTE: $NEXT_CMD $NEXT_ARGS"
  exit 0
fi

# Normal completion
if ! sm_transition "$STATE_COMPLETE" 2>&1; then
  ...
fi
```

### 7. Testing Requirements

#### 7.1 Unit Tests for State Machine Functions

Create `/home/benjamin/.config/.claude/tests/test_then_state_machine.sh`:

1. **Test sm_queue_then_command()**
   - Valid commands: /research, /plan, /debug, /revise
   - Invalid commands: /invalid, /build, /coordinate
   - Empty command
   - Command with arguments

2. **Test sm_has_queued_then()**
   - Before queueing
   - After queueing
   - After execution

3. **Test sm_execute_queued_then()**
   - With queued command
   - Without queued command
   - Clears queued state after execution

4. **Test state transitions**
   - research -> then_pending (valid)
   - plan -> then_pending (valid)
   - complete -> then_pending (invalid)
   - then_pending -> plan (valid)

#### 7.2 Integration Tests

1. **Test /research THEN /plan**
   - Creates research reports
   - Transitions to then_pending
   - Signals THEN_EXECUTE
   - Plan receives artifact context

2. **Test /debug THEN /plan**
   - Creates debug report
   - Queues plan command
   - Passes debug findings to plan

3. **Test error cases**
   - Invalid THEN target
   - Missing artifact context
   - State persistence failures

#### 7.3 Checkpoint Migration Test

Test migration from v2.1 to v2.2:
- Preserves existing checkpoint data
- Adds then_command section with defaults
- Handles missing fields gracefully

### 8. Risk Assessment and Mitigation

#### 8.1 Risk: State Machine Corruption

**Risk**: Invalid transitions could leave state machine in unrecoverable state.

**Mitigation**:
- Validate THEN target commands before queueing
- Add then_pending to valid transitions only for completion-capable states
- Implement rollback on transition failure

#### 8.2 Risk: Artifact Context Loss

**Risk**: Artifact paths may not be available when THEN command executes.

**Mitigation**:
- Persist artifact context immediately before transition
- Validate all required paths exist before queueing
- Include fallback paths in context

#### 8.3 Risk: Checkpoint Schema Incompatibility

**Risk**: Old checkpoints may fail with new schema.

**Mitigation**:
- Implement v2.1 -> v2.2 migration in checkpoint-utils.sh
- Add defaults for all new fields
- Test migration with existing checkpoints

#### 8.4 Risk: Concurrent Execution Conflicts

**Risk**: Multiple THEN-enabled commands executing simultaneously could conflict.

**Mitigation**:
- Use timestamp-based workflow IDs (existing pattern)
- Separate state files per workflow
- Include workflow ID in THEN command signal

## Recommendations

### Recommendation 1: Implement Core State Machine Extensions First

**Priority**: P0

Implement the core state machine functions (sm_queue_then_command, sm_has_queued_then, sm_execute_queued_then) in workflow-state-machine.sh before modifying any commands. This allows isolated testing of the state machine logic.

**Files to modify**:
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 48, 55-64, new functions after line 900)

**Estimated effort**: 100-150 lines

### Recommendation 2: Add THEN Parsing to argument-capture.sh

**Priority**: P1

Implement parse_then_syntax() in argument-capture.sh to provide consistent THEN parsing across all commands. This centralizes the parsing logic and reduces code duplication.

**Files to modify**:
- `/home/benjamin/.config/.claude/lib/argument-capture.sh` (new function after line 205)

**Estimated effort**: 40-50 lines

### Recommendation 3: Update Checkpoint Schema to v2.2

**Priority**: P1

Add then_command section to checkpoint schema and implement v2.1 -> v2.2 migration. This ensures THEN command state survives across bash block boundaries and can be resumed after failures.

**Files to modify**:
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (lines 25, 92-152, new migration function after line 512)

**Estimated effort**: 60-80 lines

### Recommendation 4: Integrate with /research Command First

**Priority**: P2

Use /research as the pilot command for THEN integration since it has the simplest completion flow (research-only). This validates the integration pattern before applying to more complex commands.

**Files to modify**:
- `/home/benjamin/.config/.claude/commands/research.md` (Part 2 after argument capture, Part 4 before completion)

**Estimated effort**: 30-40 lines per command

### Recommendation 5: Implement Comprehensive Test Suite

**Priority**: P2

Create dedicated test file for THEN state machine functionality. Include unit tests for all new functions and integration tests for command chaining.

**Files to create**:
- `/home/benjamin/.config/.claude/tests/test_then_state_machine.sh`

**Estimated effort**: 200-300 lines

### Recommendation 6: Document THEN Artifact Context Contract

**Priority**: P3

Define and document the artifact context JSON structure that passes between commands. This enables consistent artifact passing regardless of source/target command combination.

**Documentation update**:
- Add to `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`

## References

### Files Analyzed

- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`: Lines 40-48 (state enumeration), 55-64 (transition table), 70-86 (global variables), 392-512 (sm_init), 606-651 (sm_transition), 737-804 (sm_save), 884-900 (exports)
- `/home/benjamin/.config/.claude/lib/state-persistence.sh`: Lines 130-169 (init_workflow_state), 212-296 (load_workflow_state), 321-336 (append_workflow_state), 427-453 (save/load_classification_checkpoint)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh`: Lines 22-28 (schema version), 54-186 (save_checkpoint), 294-515 (migrate_checkpoint_format), 960-1026 (state machine checkpoint functions)
- `/home/benjamin/.config/.claude/lib/argument-capture.sh`: Lines 78-97 (capture_argument_part1), 119-168 (capture_argument_part2)
- `/home/benjamin/.config/.claude/commands/coordinate.md`: Lines 32-43 (Part 1 capture), 100-500 (state machine initialization), 370 (sm_init invocation)
- `/home/benjamin/.config/.claude/commands/research.md`: Lines 300-378 (completion flow, sm_transition to COMPLETE)
- `/home/benjamin/.config/.claude/specs/774_for_the_research_debug_plan_research_and_revise_co/reports/001_then_breakpoint_syntax.md`: Lines 223-262 (Option B overview)

### Related Documentation

- `/home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md`: State machine architecture
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`: Subprocess isolation and state persistence
- `/home/benjamin/.config/.claude/docs/reference/command-authoring-standards.md`: Command integration patterns

## Implementation Status

- **Status**: Planning In Progress
- **Plan**: [../plans/001_option_b_state_machine_then_plan.md](../plans/001_option_b_state_machine_then_plan.md)
- **Implementation**: [Will be updated by orchestrator]
- **Date**: 2025-11-17
