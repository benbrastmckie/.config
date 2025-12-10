# State System Patterns

## Overview

This document describes state persistence patterns used in hierarchical agent architectures to maintain workflow state across bash block boundaries. State systems enable long-running workflows with multiple iterations, cross-block data sharing, and workflow resumption after errors.

**Purpose**: Enable multi-block workflows with persistent state management and cross-block data sharing.

**Scope**: All commands and agents using state-persistence.sh library for workflow state management.

**Related Standards**:
- [Code Standards - Bash Sourcing](../reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern) - Three-tier library sourcing
- [Error Handling Pattern](patterns/error-handling.md) - Error logging integration
- [Concurrent Execution Safety](../reference/standards/concurrent-execution-safety.md) - Multi-instance state isolation

---

## Core Concepts

### State File Structure

State files use simple KEY=VALUE format for bash sourcing:

```bash
# State file: /home/user/.claude/data/state/implement_workflow_1733846400.state
WORKFLOW_ID="implement_workflow_1733846400"
COMMAND_NAME="/implement"
PLAN_PATH="/path/to/plan.md"
TOPIC_PATH="/path/to/topic"
CURRENT_PHASE="4"
ITERATION="2"
MAX_ITERATIONS="5"
CONTEXT_USAGE_PERCENT="37"
PHASES_COMPLETED="1 2 3"
WORK_REMAINING="4 5 6"
```

**File Naming Convention**: `{command_name}_workflow_{timestamp}.state`

**Storage Location**: `$HOME/.claude/data/state/`

**Persistence Scope**: Across all bash blocks in a workflow, including coordinator iterations

---

### State Lifecycle

```
┌──────────────┐
│ Block 1:     │
│ Initialize   │──────┐
│ State        │      │
└──────────────┘      │
                      │ save_workflow_state
                      ↓
                ┌──────────────┐
                │  State File  │
                │  Created     │
                └──────────────┘
                      │
                      │ discover_latest_state_file
                      ↓
┌──────────────┐      │
│ Block 2:     │      │
│ Restore      │←─────┘
│ State        │
└──────────────┘      │
                      │ save_workflow_state (update)
                      ↓
                ┌──────────────┐
                │  State File  │
                │  Updated     │
                └──────────────┘
                      │
                      │ discover_latest_state_file
                      ↓
┌──────────────┐      │
│ Block 3:     │      │
│ Restore      │←─────┘
│ State        │
└──────────────┘
```

**Lifecycle Stages**:
1. **Initialize**: Block 1 creates initial state with `generate_unique_workflow_id` and `save_workflow_state`
2. **Persist**: Each block saves state before exit with `save_workflow_state`
3. **Restore**: Subsequent blocks restore state with `discover_latest_state_file` and `source`
4. **Update**: Each block updates state variables before saving
5. **Cleanup**: Final block optionally removes state file (not recommended for debugging)

---

## State Initialization Patterns

### Pattern 1: Generate Unique Workflow ID

Used in **Block 1** of all commands to create unique workflow identifier:

```bash
#!/bin/bash

# Source state persistence library
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

# Generate unique workflow ID with nanosecond precision
WORKFLOW_ID=$(generate_unique_workflow_id "implement")

# Initialize workflow state
COMMAND_NAME="/implement"
PLAN_PATH="$1"  # From user arguments
ITERATION=1
MAX_ITERATIONS=5

# Save initial state
save_workflow_state \
  "WORKFLOW_ID" \
  "COMMAND_NAME" \
  "PLAN_PATH" \
  "ITERATION" \
  "MAX_ITERATIONS"

echo "Initialized workflow: $WORKFLOW_ID"
```

**Requirements**:
- MUST use `generate_unique_workflow_id` for nanosecond-precision timestamps
- MUST save state before block exit
- MUST NOT use shared state ID files (breaks concurrent execution)

**Anti-Pattern**: Shared state ID files
```bash
# WRONG: Creates shared state ID file (breaks concurrent execution)
WORKFLOW_ID="implement_workflow_$(date +%s)"
echo "$WORKFLOW_ID" > "$STATE_DIR/implement_state_id.txt"
```

See [Concurrent Execution Safety](../reference/standards/concurrent-execution-safety.md) for details.

---

### Pattern 2: Discover Latest State File

Used in **Block 2+** of all commands to restore workflow state:

```bash
#!/bin/bash

# Source state persistence library
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || {
  echo "Error: Cannot load state-persistence library"
  exit 1
}

# Discover latest state file by pattern matching
STATE_FILE=$(discover_latest_state_file "implement")

if [ -z "$STATE_FILE" ]; then
  echo "Error: No state file found for workflow"
  exit 1
fi

# Restore state variables
source "$STATE_FILE"

# Validate required state
if [ -z "$WORKFLOW_ID" ] || [ -z "$PLAN_PATH" ]; then
  echo "Error: Invalid state file (missing WORKFLOW_ID or PLAN_PATH)"
  exit 1
fi

echo "Restored workflow: $WORKFLOW_ID (Iteration $ITERATION)"
```

**Requirements**:
- MUST use `discover_latest_state_file` for state restoration
- MUST validate required state variables after sourcing
- MUST handle missing state file gracefully

**State Discovery Logic**:
```bash
discover_latest_state_file() {
  local command_name="$1"
  local state_dir="${STATE_DIR:-$HOME/.claude/data/state}"

  # Find most recent state file by modification time
  find "$state_dir" -name "${command_name}_workflow_*.state" -type f -printf '%T@ %p\n' \
    | sort -n -r \
    | head -1 \
    | cut -d' ' -f2-
}
```

---

## Workflow State Machine Patterns

### Pattern 3: Linear State Progression

**Use Case**: Simple workflows with sequential phases (no branching).

**State Diagram**:
```
initialize → research → plan → implement → test → complete
```

**Implementation**:
```bash
# Initialize state machine
WORKFLOW_STATE="initialize"
save_workflow_state "WORKFLOW_STATE"

# Transition to next state
transition_to_research() {
  WORKFLOW_STATE="research"
  save_workflow_state "WORKFLOW_STATE"
}

transition_to_plan() {
  WORKFLOW_STATE="plan"
  save_workflow_state "WORKFLOW_STATE"
}

transition_to_implement() {
  WORKFLOW_STATE="implement"
  save_workflow_state "WORKFLOW_STATE"
}

transition_to_complete() {
  WORKFLOW_STATE="complete"
  save_workflow_state "WORKFLOW_STATE"
}

# State-based execution
case "$WORKFLOW_STATE" in
  initialize)
    echo "Initializing workflow..."
    transition_to_research
    ;;
  research)
    echo "Running research phase..."
    transition_to_plan
    ;;
  plan)
    echo "Creating implementation plan..."
    transition_to_implement
    ;;
  implement)
    echo "Executing implementation..."
    transition_to_complete
    ;;
  complete)
    echo "Workflow complete"
    ;;
  *)
    echo "Error: Unknown state: $WORKFLOW_STATE"
    exit 1
    ;;
esac
```

**Examples**: `/research`, `/create-plan`, `/implement` (without testing)

---

### Pattern 4: Iterative State Progression

**Use Case**: Workflows with multiple iterations of the same phase (coordinator loops).

**State Diagram**:
```
initialize → delegate → aggregate → [continuation check] → delegate | complete
                ↑                                              |
                └──────────────────────────────────────────────┘
```

**Implementation**:
```bash
# Initialize iteration state
WORKFLOW_STATE="initialize"
ITERATION=1
MAX_ITERATIONS=5
save_workflow_state "WORKFLOW_STATE" "ITERATION" "MAX_ITERATIONS"

# Iteration loop
while [ "$ITERATION" -le "$MAX_ITERATIONS" ]; do
  case "$WORKFLOW_STATE" in
    initialize|delegate)
      echo "Iteration $ITERATION: Delegating to coordinator..."
      WORKFLOW_STATE="aggregate"
      save_workflow_state "WORKFLOW_STATE"

      # Delegate to coordinator (Task tool)
      # ...
      ;;

    aggregate)
      echo "Iteration $ITERATION: Aggregating coordinator results..."

      # Parse coordinator return signal
      requires_continuation=$(echo "$coordinator_output" | grep "^requires_continuation:" | awk '{print $2}')

      if [ "$requires_continuation" = "true" ]; then
        ITERATION=$((ITERATION + 1))
        WORKFLOW_STATE="delegate"
        save_workflow_state "WORKFLOW_STATE" "ITERATION"
        echo "Continuing to iteration $ITERATION..."
      else
        WORKFLOW_STATE="complete"
        save_workflow_state "WORKFLOW_STATE"
        break
      fi
      ;;

    complete)
      echo "Workflow complete after $ITERATION iterations"
      break
      ;;

    *)
      echo "Error: Unknown state: $WORKFLOW_STATE"
      exit 1
      ;;
  esac
done
```

**Examples**: `/lean-implement`, `/lean-plan` (with coordinator iterations)

---

### Pattern 5: Hybrid State Progression

**Use Case**: Workflows with conditional branching based on complexity or mode.

**State Diagram**:
```
initialize → [mode check] → research-only | research → plan → implement → test → complete
                                   ↓                              ↓
                                complete                      complete
```

**Implementation**:
```bash
# Initialize with mode detection
WORKFLOW_STATE="initialize"
WORKFLOW_MODE="auto"  # auto, research-only, implement-only
save_workflow_state "WORKFLOW_STATE" "WORKFLOW_MODE"

# Mode-based state transitions
case "$WORKFLOW_STATE" in
  initialize)
    if [ "$WORKFLOW_MODE" = "research-only" ]; then
      WORKFLOW_STATE="research"
    else
      WORKFLOW_STATE="research"
    fi
    save_workflow_state "WORKFLOW_STATE"
    ;;

  research)
    if [ "$WORKFLOW_MODE" = "research-only" ]; then
      WORKFLOW_STATE="complete"
    else
      WORKFLOW_STATE="plan"
    fi
    save_workflow_state "WORKFLOW_STATE"
    ;;

  plan)
    if [ "$WORKFLOW_MODE" = "implement-only" ]; then
      WORKFLOW_STATE="implement"
    else
      WORKFLOW_STATE="research"  # Loop back for additional research
    fi
    save_workflow_state "WORKFLOW_STATE"
    ;;

  implement)
    WORKFLOW_STATE="test"
    save_workflow_state "WORKFLOW_STATE"
    ;;

  test)
    WORKFLOW_STATE="complete"
    save_workflow_state "WORKFLOW_STATE"
    ;;

  complete)
    echo "Workflow complete"
    ;;
esac
```

**Examples**: `/lean-implement` (auto, lean-only, software-only modes)

---

## Cross-Block Data Sharing Patterns

### Pattern 6: Artifact Path Persistence

**Use Case**: Passing artifact paths between blocks for validation or continuation.

```bash
# Block 1: Create artifact and save path
report_path="/path/to/research-report.md"
plan_path="/path/to/implementation-plan.md"

save_workflow_state \
  "WORKFLOW_ID" \
  "REPORT_PATH=$report_path" \
  "PLAN_PATH=$plan_path"

# Block 2: Restore and validate artifact
source "$STATE_FILE"

if [ ! -f "$REPORT_PATH" ]; then
  echo "Error: Research report not found: $REPORT_PATH"
  exit 1
fi

if [ ! -f "$PLAN_PATH" ]; then
  echo "Error: Implementation plan not found: $PLAN_PATH"
  exit 1
fi

echo "Artifacts validated: $REPORT_PATH, $PLAN_PATH"
```

**Requirements**:
- MUST use absolute paths (not relative)
- MUST validate artifact existence after restoration
- SHOULD log artifact creation for debugging

---

### Pattern 7: Coordinator Metadata Persistence

**Use Case**: Passing coordinator return signal metadata across iterations.

```bash
# Block 2: Parse coordinator return signal and save metadata
coordinator_type=$(echo "$coordinator_output" | grep "^coordinator_type:" | awk '{print $2}')
summary_brief=$(echo "$coordinator_output" | grep "^summary_brief:" | sed 's/^summary_brief: "//' | sed 's/"$//')
phases_completed=$(echo "$coordinator_output" | grep "^phases_completed:" | sed 's/^phases_completed: //' | tr -d '[]')
work_remaining=$(echo "$coordinator_output" | grep "^work_remaining:" | sed 's/^work_remaining: //')
context_usage_percent=$(echo "$coordinator_output" | grep "^context_usage_percent:" | awk '{print $2}')

save_workflow_state \
  "WORKFLOW_ID" \
  "COORDINATOR_TYPE=$coordinator_type" \
  "SUMMARY_BRIEF=$summary_brief" \
  "PHASES_COMPLETED=$phases_completed" \
  "WORK_REMAINING=$work_remaining" \
  "CONTEXT_USAGE_PERCENT=$context_usage_percent"

# Block 3: Restore coordinator metadata for next iteration
source "$STATE_FILE"

echo "Previous iteration: $SUMMARY_BRIEF"
echo "Phases completed: $PHASES_COMPLETED"
echo "Work remaining: $WORK_REMAINING"
echo "Context usage: ${CONTEXT_USAGE_PERCENT}%"
```

**Benefits**:
- Enables iteration-to-iteration progress tracking
- Supports context budget management across iterations
- Allows continuation decision logic based on previous iteration

---

### Pattern 8: Array Serialization

**Use Case**: Persisting bash arrays across state boundaries.

```bash
# Block 1: Serialize array to state
topics=("authentication" "token_expiry" "security" "testing")
topics_serialized=$(IFS=,; echo "${topics[*]}")

save_workflow_state \
  "WORKFLOW_ID" \
  "TOPICS_SERIALIZED=$topics_serialized"

# Block 2: Deserialize array from state
source "$STATE_FILE"

IFS=',' read -r -a topics <<< "$TOPICS_SERIALIZED"

echo "Restored topics: ${topics[@]}"
echo "Topic count: ${#topics[@]}"

for topic in "${topics[@]}"; do
  echo "Processing topic: $topic"
done
```

**Requirements**:
- MUST use delimiter that doesn't appear in array values (e.g., comma, pipe)
- MUST restore array with same delimiter
- SHOULD validate array count after deserialization

---

## State Validation Patterns

### Pattern 9: Required State Validation

**Use Case**: Ensuring critical state variables are present before execution.

```bash
validate_required_state() {
  local required_vars="$@"

  for var in $required_vars; do
    if [ -z "${!var}" ]; then
      echo "Error: Required state variable missing: $var"
      log_command_error "state_error" "Missing required state variable: $var" "State file: $STATE_FILE"
      return 1
    fi
  done

  return 0
}

# Block 2+: Validate required state after restoration
source "$STATE_FILE"

if ! validate_required_state "WORKFLOW_ID" "PLAN_PATH" "ITERATION" "MAX_ITERATIONS"; then
  echo "Error: Invalid state file"
  exit 1
fi

echo "State validated successfully"
```

**Validation Checklist**:
- [ ] WORKFLOW_ID present and non-empty
- [ ] COMMAND_NAME present and non-empty
- [ ] Critical path variables (PLAN_PATH, TOPIC_PATH) present and valid
- [ ] Iteration counters (ITERATION, MAX_ITERATIONS) present and numeric
- [ ] Workflow state (WORKFLOW_STATE) present and valid

---

### Pattern 10: State File Integrity Check

**Use Case**: Detecting corrupted or incomplete state files.

```bash
validate_state_file_integrity() {
  local state_file="$1"

  # Check file exists
  if [ ! -f "$state_file" ]; then
    echo "Error: State file not found: $state_file"
    return 1
  fi

  # Check file is readable
  if [ ! -r "$state_file" ]; then
    echo "Error: State file not readable: $state_file"
    return 1
  fi

  # Check file is not empty
  if [ ! -s "$state_file" ]; then
    echo "Error: State file is empty: $state_file"
    return 1
  fi

  # Check file contains valid bash syntax
  if ! bash -n "$state_file" 2>/dev/null; then
    echo "Error: State file contains invalid syntax: $state_file"
    return 1
  fi

  return 0
}

# Usage
STATE_FILE=$(discover_latest_state_file "implement")

if ! validate_state_file_integrity "$STATE_FILE"; then
  echo "Error: State file integrity check failed"
  exit 1
fi

source "$STATE_FILE"
```

**Integrity Checks**:
- [ ] File exists
- [ ] File is readable
- [ ] File is not empty
- [ ] File contains valid bash syntax
- [ ] File modification time is recent (within expected workflow duration)

---

## Error Recovery Patterns

### Pattern 11: State Restoration After Error

**Use Case**: Resuming workflow after coordinator error or timeout.

```bash
# Block 2: Error-safe coordinator delegation
if [ -f "$STATE_FILE" ]; then
  source "$STATE_FILE"

  # Check if previous iteration encountered error
  if [ "$WORKFLOW_STATE" = "error" ]; then
    echo "Previous iteration encountered error. Analyzing..."

    # Read error details from state
    echo "Error type: $ERROR_TYPE"
    echo "Error message: $ERROR_MESSAGE"

    # Decide recovery strategy
    if [ "$ITERATION" -lt "$MAX_ITERATIONS" ]; then
      echo "Retrying coordinator delegation (iteration $ITERATION)..."
      WORKFLOW_STATE="delegate"
      save_workflow_state "WORKFLOW_STATE"
    else
      echo "Max iterations reached. Aborting workflow."
      exit 1
    fi
  fi
fi

# Delegate to coordinator with error handling
if ! coordinator_output=$(delegate_to_coordinator); then
  echo "Error: Coordinator delegation failed"

  # Save error state
  WORKFLOW_STATE="error"
  ERROR_TYPE="coordinator_error"
  ERROR_MESSAGE="Coordinator delegation failed at iteration $ITERATION"
  save_workflow_state "WORKFLOW_STATE" "ERROR_TYPE" "ERROR_MESSAGE"

  # Log error for debugging
  log_command_error "$ERROR_TYPE" "$ERROR_MESSAGE" "Iteration: $ITERATION"
  exit 1
fi
```

**Recovery Strategies**:
- Retry with same parameters (transient errors)
- Retry with reduced scope (resource exhaustion)
- Skip failed phase and continue (partial success mode)
- Abort workflow and log error (critical failures)

---

### Pattern 12: Checkpoint-Based Recovery

**Use Case**: Saving workflow checkpoints for incremental progress resumption.

```bash
# Block 2: Save checkpoint after each phase completion
create_checkpoint() {
  local checkpoint_dir="${CHECKPOINT_DIR:-$HOME/.claude/data/checkpoints}"
  local checkpoint_file="$checkpoint_dir/${WORKFLOW_ID}_phase_${CURRENT_PHASE}.md"

  cat > "$checkpoint_file" <<EOF
# Workflow Checkpoint: Phase $CURRENT_PHASE

**Workflow ID**: $WORKFLOW_ID
**Phase**: $CURRENT_PHASE
**Iteration**: $ITERATION
**Context Usage**: ${CONTEXT_USAGE_PERCENT}%
**Timestamp**: $(date -Iseconds)

## Completed Work

$(cat "$PHASE_SUMMARY_PATH")

## Next Steps

- Continue to Phase $((CURRENT_PHASE + 1))
- Estimated remaining effort: X hours
EOF

  echo "$checkpoint_file"
}

# Save checkpoint after phase completion
CURRENT_PHASE=3
checkpoint_path=$(create_checkpoint)

save_workflow_state \
  "WORKFLOW_ID" \
  "CURRENT_PHASE" \
  "CHECKPOINT_PATH=$checkpoint_path"

echo "Checkpoint saved: $checkpoint_path"
```

**Checkpoint Benefits**:
- Enables workflow resumption from last successful phase
- Provides audit trail of workflow progress
- Supports partial result recovery after errors
- Facilitates debugging by preserving intermediate state

---

## State System Integration

### Integration with Error Logging

State system integrates with error logging for queryable error tracking:

```bash
# Source both libraries
source "$CLAUDE_LIB/core/state-persistence.sh" 2>/dev/null || { echo "Error: Cannot load state-persistence library"; exit 1; }
source "$CLAUDE_LIB/core/error-handling.sh" 2>/dev/null || { echo "Error: Cannot load error-handling library"; exit 1; }

# Initialize both systems
ensure_error_log_exists
WORKFLOW_ID=$(generate_unique_workflow_id "implement")

# Log error with workflow context
log_error_with_state() {
  local error_type="$1"
  local error_message="$2"
  local error_details="$3"

  # Add workflow state to error details
  error_details="$error_details | WORKFLOW_ID: $WORKFLOW_ID | ITERATION: $ITERATION | WORKFLOW_STATE: $WORKFLOW_STATE"

  # Log error
  log_command_error "$error_type" "$error_message" "$error_details"

  # Save error state
  WORKFLOW_STATE="error"
  ERROR_TYPE="$error_type"
  ERROR_MESSAGE="$error_message"
  save_workflow_state "WORKFLOW_STATE" "ERROR_TYPE" "ERROR_MESSAGE"
}

# Usage
if ! validate_required_state "WORKFLOW_ID" "PLAN_PATH"; then
  log_error_with_state "state_error" "Missing required state" "State file: $STATE_FILE"
  exit 1
fi
```

See [Error Handling Pattern](patterns/error-handling.md) for complete error logging integration.

---

### Integration with Concurrent Execution Safety

State system supports concurrent execution of multiple workflow instances:

```bash
# Block 1: Generate unique workflow ID (nanosecond precision)
WORKFLOW_ID=$(generate_unique_workflow_id "create_plan")
# Result: create_plan_workflow_1733846400123456789 (timestamp in nanoseconds)

# State file: create_plan_workflow_1733846400123456789.state
save_workflow_state "WORKFLOW_ID" "COMMAND_NAME" "PLAN_PATH"

# Block 2: Discover latest state file (pattern matching by command name)
STATE_FILE=$(discover_latest_state_file "create_plan")
# Finds most recent state file by modification time for "create_plan" command
```

**Concurrent Safety Requirements**:
- MUST use `generate_unique_workflow_id` for unique WORKFLOW_ID per instance
- MUST use `discover_latest_state_file` for state restoration (no shared state ID files)
- MUST embed WORKFLOW_ID in state file name (enables pattern matching)

See [Concurrent Execution Safety](../reference/standards/concurrent-execution-safety.md) for complete concurrent safety patterns.

---

## Anti-Patterns

### Anti-Pattern 1: Shared State ID Files

**Problem**: Breaks concurrent execution by creating race conditions.

```bash
# WRONG: Creates shared state ID file
WORKFLOW_ID="implement_workflow_$(date +%s)"
echo "$WORKFLOW_ID" > "$STATE_DIR/implement_state_id.txt"

# Block 2: Reads shared state ID file (race condition)
WORKFLOW_ID=$(cat "$STATE_DIR/implement_state_id.txt")
STATE_FILE="$STATE_DIR/${WORKFLOW_ID}.state"
```

**Solution**: Use state discovery pattern.

```bash
# CORRECT: No shared state ID file
WORKFLOW_ID=$(generate_unique_workflow_id "implement")
save_workflow_state "WORKFLOW_ID"

# Block 2: Discover state file by pattern
STATE_FILE=$(discover_latest_state_file "implement")
source "$STATE_FILE"
```

---

### Anti-Pattern 2: Hardcoded State File Paths

**Problem**: Prevents concurrent execution and breaks portability.

```bash
# WRONG: Hardcoded state file path
STATE_FILE="$HOME/.claude/data/state/implement_state.txt"
save_workflow_state "WORKFLOW_ID"
```

**Solution**: Use dynamic state file naming.

```bash
# CORRECT: Dynamic state file naming
WORKFLOW_ID=$(generate_unique_workflow_id "implement")
save_workflow_state "WORKFLOW_ID"
# Creates: $STATE_DIR/implement_workflow_{timestamp}.state
```

---

### Anti-Pattern 3: Missing State Validation

**Problem**: Silent failures from missing or corrupted state.

```bash
# WRONG: No state validation
source "$STATE_FILE"
echo "Restored workflow: $WORKFLOW_ID"  # May be empty!
```

**Solution**: Always validate required state.

```bash
# CORRECT: Validate required state
source "$STATE_FILE"

if ! validate_required_state "WORKFLOW_ID" "PLAN_PATH"; then
  echo "Error: Invalid state file"
  exit 1
fi

echo "Restored workflow: $WORKFLOW_ID"
```

---

### Anti-Pattern 4: State Mutation Without Persistence

**Problem**: State changes lost across block boundaries.

```bash
# WRONG: Mutate state without saving
ITERATION=$((ITERATION + 1))
WORKFLOW_STATE="delegate"
# State changes lost if block exits here!
```

**Solution**: Always save state after mutation.

```bash
# CORRECT: Save state after mutation
ITERATION=$((ITERATION + 1))
WORKFLOW_STATE="delegate"
save_workflow_state "ITERATION" "WORKFLOW_STATE"
```

---

## Performance Considerations

### State File Size

**Typical State File Size**: 200-500 bytes (10-15 variables)

**Recommendations**:
- Avoid storing large strings in state (use file paths instead)
- Serialize arrays efficiently (comma-separated values)
- Clean up old state files periodically (>7 days old)

---

### State Discovery Performance

**Discovery Time**: <10ms for 100 state files

**Optimization**:
```bash
# Fast: Uses find with printf for timestamp sorting
discover_latest_state_file() {
  find "$STATE_DIR" -name "${command_name}_workflow_*.state" -type f -printf '%T@ %p\n' \
    | sort -n -r \
    | head -1 \
    | cut -d' ' -f2-
}

# Slow: Uses ls with stat for timestamp sorting
discover_latest_state_file() {
  ls -t "$STATE_DIR/${command_name}_workflow_"*.state 2>/dev/null | head -1
}
```

**Recommendation**: Use `find` with `printf` for better performance.

---

## State System Library Reference

### Function: generate_unique_workflow_id

**Signature**: `generate_unique_workflow_id <command_name>`

**Description**: Generates unique workflow ID with nanosecond precision timestamp.

**Example**:
```bash
WORKFLOW_ID=$(generate_unique_workflow_id "implement")
# Result: implement_workflow_1733846400123456789
```

---

### Function: save_workflow_state

**Signature**: `save_workflow_state <var1> [var2] [var3] ...`

**Description**: Saves specified variables to state file.

**Example**:
```bash
save_workflow_state "WORKFLOW_ID" "PLAN_PATH" "ITERATION"
```

---

### Function: discover_latest_state_file

**Signature**: `discover_latest_state_file <command_name>`

**Description**: Discovers most recent state file for given command.

**Example**:
```bash
STATE_FILE=$(discover_latest_state_file "implement")
```

---

### Function: cleanup_old_state_files

**Signature**: `cleanup_old_state_files <command_name> [max_age_days]`

**Description**: Removes state files older than specified age (default: 7 days).

**Example**:
```bash
cleanup_old_state_files "implement" 7
```

---

## Related Documentation

- [Bash Block Execution Model](bash-block-execution-model.md) - Multi-block workflow patterns
- [Error Handling Pattern](patterns/error-handling.md) - Error logging integration
- [Concurrent Execution Safety](../reference/standards/concurrent-execution-safety.md) - Multi-instance state isolation
- [Code Standards - Bash Sourcing](../reference/standards/code-standards.md#mandatory-bash-block-sourcing-pattern) - Library sourcing requirements
- [Coordinator Patterns Standard](../reference/standards/coordinator-patterns-standard.md) - Coordinator state management

---

## Revision History

- **2025-12-10**: Initial documentation created (Phase 5 of hierarchical agent architecture documentation)
- Documents state initialization, restoration, and validation patterns
- Describes workflow state machine patterns (linear, iterative, hybrid)
- Documents cross-block data sharing and error recovery patterns
- Integrates with error logging and concurrent execution safety standards
