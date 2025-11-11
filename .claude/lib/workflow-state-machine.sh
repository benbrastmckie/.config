#!/usr/bin/env bash
# Workflow State Machine Library
# Provides formal state machine abstraction for orchestration commands
#
# This library implements an explicit state machine for workflow orchestration,
# replacing implicit phase-based tracking with clear states, transitions, and validation.
#
# Architecture:
# - 8 core workflow states (initialize, research, plan, implement, test, debug, document, complete)
# - State transition table defines valid state transitions
# - Atomic two-phase commit for state transitions (pre + post checkpoints)
# - Workflow scope integration (maps scope to terminal state)
# - State history tracking (completed_states array)
#
# Dependencies:
# - workflow-scope-detection.sh: detect_workflow_scope() [primary - supports revision patterns]
# - workflow-detection.sh: detect_workflow_scope() [fallback - for /supervise compatibility]
# - checkpoint-utils.sh: save_checkpoint(), restore_checkpoint()

# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_STATE_MACHINE_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_STATE_MACHINE_SOURCED=1

set -euo pipefail

# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"

# ==============================================================================
# State Enumeration (8 Core States)
# ==============================================================================

# Core workflow states (explicit, not implicit phase numbers)
readonly STATE_INITIALIZE="initialize"       # Phase 0: Setup, scope detection, path pre-calculation
readonly STATE_RESEARCH="research"           # Phase 1: Research topic via specialist agents
readonly STATE_PLAN="plan"                   # Phase 2: Create implementation plan
readonly STATE_IMPLEMENT="implement"         # Phase 3: Execute implementation
readonly STATE_TEST="test"                   # Phase 4: Run test suite
readonly STATE_DEBUG="debug"                 # Phase 5: Debug failures (conditional)
readonly STATE_DOCUMENT="document"           # Phase 6: Update documentation (conditional)
readonly STATE_COMPLETE="complete"           # Phase 7: Finalization, cleanup

# ==============================================================================
# State Transition Table
# ==============================================================================

# Defines valid state transitions (comma-separated list of allowed next states)
declare -gA STATE_TRANSITIONS=(
  [initialize]="research"
  [research]="plan,complete"        # Can skip to complete for research-only
  [plan]="implement,complete"       # Can skip to complete for research-and-plan
  [implement]="test"
  [test]="debug,document"           # Conditional: debug if failed, document if passed
  [debug]="test,complete"           # Retry testing or complete if unfixable
  [document]="complete"
  [complete]=""                     # Terminal state
)

# ==============================================================================
# State Machine Variables (Global State)
# ==============================================================================

# Current state of the state machine
# Use conditional initialization to preserve values across library re-sourcing
CURRENT_STATE="${CURRENT_STATE:-${STATE_INITIALIZE}}"

# Array of completed states (state history)
# Spec 672 Phase 2: Loaded from state at end of file after function definitions
declare -ga COMPLETED_STATES=()

# Terminal state for this workflow (determined by scope)
TERMINAL_STATE="${TERMINAL_STATE:-${STATE_COMPLETE}}"

# Workflow configuration
# Preserve values across bash subprocess boundaries (Pattern 5)
WORKFLOW_SCOPE="${WORKFLOW_SCOPE:-}"
WORKFLOW_DESCRIPTION="${WORKFLOW_DESCRIPTION:-}"
COMMAND_NAME="${COMMAND_NAME:-}"

# ==============================================================================
# Core State Machine Functions
# ==============================================================================

# ==============================================================================
# COMPLETED_STATES Array Persistence (Spec 672, Phase 2)
# ==============================================================================

# save_completed_states_to_state: Serialize COMPLETED_STATES array to workflow state
#
# Saves the COMPLETED_STATES array to the GitHub Actions-style state file
# using JSON serialization for reliable cross-bash-block persistence.
#
# Purpose:
#   State machine completed states must persist across bash block boundaries
#   in orchestration commands (coordinate.md, orchestrate.md, etc.). This function
#   serializes the array to JSON and saves via state-persistence.sh.
#
# Dependencies:
#   - jq (JSON processing)
#   - state-persistence.sh: append_workflow_state()
#
# Effects:
#   Writes to workflow state file:
#   - COMPLETED_STATES_JSON: JSON array of completed state names
#   - COMPLETED_STATES_COUNT: Integer count for validation
#
# Returns:
#   0 on success, 1 on error
#
# Example:
#   COMPLETED_STATES=("initialize" "research" "plan")
#   save_completed_states_to_state
#   # State file now contains:
#   #   export COMPLETED_STATES_JSON='["initialize","research","plan"]'
#   #   export COMPLETED_STATES_COUNT=3
#
# Reference: Spec 672 Phase 2 (state machine array persistence)
#
save_completed_states_to_state() {
  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "WARNING: jq not available, skipping COMPLETED_STATES persistence" >&2
    return 1
  fi

  # Check if state persistence function is available
  if ! command -v append_workflow_state &> /dev/null; then
    echo "WARNING: append_workflow_state not available, skipping COMPLETED_STATES persistence" >&2
    return 1
  fi

  # Serialize array to JSON (handle empty array explicitly)
  local completed_states_json
  if [ "${#COMPLETED_STATES[@]}" -eq 0 ]; then
    completed_states_json="[]"
  else
    completed_states_json=$(printf '%s\n' "${COMPLETED_STATES[@]}" | jq -R . | jq -s .)
  fi

  # Save to workflow state
  append_workflow_state "COMPLETED_STATES_JSON" "$completed_states_json"
  append_workflow_state "COMPLETED_STATES_COUNT" "${#COMPLETED_STATES[@]}"

  return 0
}

# load_completed_states_from_state: Reconstruct COMPLETED_STATES array from workflow state
#
# Loads the COMPLETED_STATES array from the GitHub Actions-style state file
# using the generic defensive reconstruction pattern (Spec 672 Phase 1).
#
# Purpose:
#   Restore completed states history after bash block boundaries. Used in
#   orchestration commands when re-sourcing state machine library.
#
# Dependencies:
#   - jq (JSON processing)
#   - workflow-initialization.sh: reconstruct_array_from_indexed_vars() (optional fallback)
#
# Effects:
#   Sets global COMPLETED_STATES array from state file
#   Prints warnings to stderr if state missing or invalid
#
# Returns:
#   0 always (defensive graceful degradation)
#
# Example:
#   # State file contains:
#   #   export COMPLETED_STATES_JSON='["initialize","research"]'
#   #   export COMPLETED_STATES_COUNT=2
#   load_completed_states_from_state
#   # Result: COMPLETED_STATES=("initialize" "research")
#
# Reference: Spec 672 Phase 2 (state machine array persistence)
#
load_completed_states_from_state() {
  # Defensive: Initialize empty array first
  COMPLETED_STATES=()

  # Check if COMPLETED_STATES_JSON exists in state
  if [ -z "${COMPLETED_STATES_JSON:-}" ]; then
    # Not an error - initial workflow won't have completed states yet
    return 0
  fi

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "WARNING: jq not available, cannot load COMPLETED_STATES" >&2
    return 0  # Graceful degradation
  fi

  # Validate JSON before parsing
  if ! echo "$COMPLETED_STATES_JSON" | jq empty 2>/dev/null; then
    echo "WARNING: COMPLETED_STATES_JSON is invalid, defaulting to empty array" >&2
    return 0
  fi

  # Reconstruct array from JSON
  mapfile -t COMPLETED_STATES < <(echo "$COMPLETED_STATES_JSON" | jq -r '.[]' 2>/dev/null || true)

  # Validate against count (if available)
  if [ -n "${COMPLETED_STATES_COUNT:-}" ]; then
    if [ "${#COMPLETED_STATES[@]}" -ne "$COMPLETED_STATES_COUNT" ]; then
      echo "WARNING: COMPLETED_STATES count mismatch (expected $COMPLETED_STATES_COUNT, got ${#COMPLETED_STATES[@]})" >&2
    fi
  fi

  return 0
}

# sm_init: Initialize new state machine from workflow description
# Usage: sm_init <workflow-description> <command-name>
# Example: sm_init "Research authentication patterns" "coordinate"
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Store workflow configuration
  WORKFLOW_DESCRIPTION="$workflow_desc"
  COMMAND_NAME="$command_name"

  # Detect workflow scope using existing detection library
  # Note: workflow-scope-detection.sh is for /coordinate (supports revision patterns)
  #       workflow-detection.sh is for /supervise (older pattern matching)
  if [ -f "$SCRIPT_DIR/workflow-scope-detection.sh" ]; then
    source "$SCRIPT_DIR/workflow-scope-detection.sh"
    WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_desc")
  elif [ -f "$SCRIPT_DIR/workflow-detection.sh" ]; then
    # Fallback to older library if newer one not available
    source "$SCRIPT_DIR/workflow-detection.sh"
    WORKFLOW_SCOPE=$(detect_workflow_scope "$workflow_desc")
  else
    # Fallback: assume full-implementation if detection unavailable
    WORKFLOW_SCOPE="full-implementation"
  fi

  # Configure terminal state based on workflow scope
  case "$WORKFLOW_SCOPE" in
    research-only)
      TERMINAL_STATE="$STATE_RESEARCH"
      ;;
    research-and-plan)
      TERMINAL_STATE="$STATE_PLAN"
      ;;
    research-and-revise)
      TERMINAL_STATE="$STATE_PLAN"  # Same terminal as research-and-plan
      ;;
    full-implementation)
      TERMINAL_STATE="$STATE_COMPLETE"
      ;;
    debug-only)
      TERMINAL_STATE="$STATE_DEBUG"
      ;;
    *)
      echo "WARNING: Unknown workflow scope '$WORKFLOW_SCOPE', defaulting to full-implementation" >&2
      TERMINAL_STATE="$STATE_COMPLETE"
      ;;
  esac

  # Initialize state machine
  CURRENT_STATE="$STATE_INITIALIZE"
  COMPLETED_STATES=()

  # Return initialization status
  echo "State machine initialized: scope=$WORKFLOW_SCOPE, terminal=$TERMINAL_STATE" >&2
  return 0
}

# sm_load: Load state machine from checkpoint file
# Usage: sm_load <checkpoint-file>
# Example: sm_load /path/to/checkpoint.json
sm_load() {
  local checkpoint_file="$1"

  if [ ! -f "$checkpoint_file" ]; then
    echo "ERROR: Checkpoint file not found: $checkpoint_file" >&2
    return 1
  fi

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required for checkpoint loading" >&2
    return 1
  fi

  # Detect checkpoint format and load accordingly
  if echo "$(cat "$checkpoint_file")" | jq -e '.state_machine' &> /dev/null; then
    # v2.0 checkpoint with .state_machine wrapper: Load from state_machine section
    CURRENT_STATE=$(jq -r '.state_machine.current_state' "$checkpoint_file")
    WORKFLOW_SCOPE=$(jq -r '.state_machine.workflow_config.scope // "full-implementation"' "$checkpoint_file")
    WORKFLOW_DESCRIPTION=$(jq -r '.state_machine.workflow_config.description // ""' "$checkpoint_file")
    COMMAND_NAME=$(jq -r '.state_machine.workflow_config.command // ""' "$checkpoint_file")

    # Load completed states array
    mapfile -t COMPLETED_STATES < <(jq -r '.state_machine.completed_states[]' "$checkpoint_file" 2>/dev/null || echo "")

    # Determine terminal state from scope
    case "$WORKFLOW_SCOPE" in
      research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
      research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
      full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
      debug-only) TERMINAL_STATE="$STATE_DEBUG" ;;
      *) TERMINAL_STATE="$STATE_COMPLETE" ;;
    esac
  elif echo "$(cat "$checkpoint_file")" | jq -e '.current_state' &> /dev/null; then
    # Direct state machine format (saved by sm_save): Load from root
    CURRENT_STATE=$(jq -r '.current_state' "$checkpoint_file")
    WORKFLOW_SCOPE=$(jq -r '.workflow_config.scope // "full-implementation"' "$checkpoint_file")
    WORKFLOW_DESCRIPTION=$(jq -r '.workflow_config.description // ""' "$checkpoint_file")
    COMMAND_NAME=$(jq -r '.workflow_config.command // ""' "$checkpoint_file")

    # Load completed states array
    mapfile -t COMPLETED_STATES < <(jq -r '.completed_states[]' "$checkpoint_file" 2>/dev/null || echo "")

    # Determine terminal state from scope
    case "$WORKFLOW_SCOPE" in
      research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
      research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
      full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
      debug-only) TERMINAL_STATE="$STATE_DEBUG" ;;
      *) TERMINAL_STATE="$STATE_COMPLETE" ;;
    esac
  else
    # v1.3 checkpoint: Migrate from phase-based to state-based
    local current_phase
    current_phase=$(jq -r '.workflow_state.current_phase // 0' "$checkpoint_file")

    # Map phase number to state name
    CURRENT_STATE=$(map_phase_to_state "$current_phase")

    # Extract scope if available (v1.3 might not have it)
    WORKFLOW_SCOPE="full-implementation"  # Default for v1.3
    TERMINAL_STATE="$STATE_COMPLETE"
    WORKFLOW_DESCRIPTION=""
    COMMAND_NAME=""

    # Load completed phases and convert to states
    local completed_phases
    mapfile -t completed_phases < <(jq -r '.workflow_state.completed_phases[]?' "$checkpoint_file" 2>/dev/null || echo "")
    COMPLETED_STATES=()
    for phase in "${completed_phases[@]}"; do
      if [ -n "$phase" ]; then
        COMPLETED_STATES+=("$(map_phase_to_state "$phase")")
      fi
    done
  fi

  echo "State machine loaded: current=$CURRENT_STATE, scope=$WORKFLOW_SCOPE" >&2
  return 0
}

# sm_current_state: Get current state
# Usage: state=$(sm_current_state)
sm_current_state() {
  echo "$CURRENT_STATE"
}

# sm_transition: Validate and execute state transition
# Usage: sm_transition <next-state>
# Example: sm_transition "$STATE_RESEARCH"
sm_transition() {
  local next_state="$1"

  # Phase 1: Validate transition is allowed
  local valid_transitions="${STATE_TRANSITIONS[$CURRENT_STATE]}"

  # Check if next_state is in valid_transitions (comma-separated)
  if ! echo ",$valid_transitions," | grep -q ",$next_state,"; then
    echo "ERROR: Invalid transition: $CURRENT_STATE → $next_state" >&2
    echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
    return 1
  fi

  # Phase 2: Save pre-transition checkpoint (atomic state transition)
  # Note: Actual checkpoint save requires checkpoint-utils.sh integration
  # This is a placeholder for checkpoint coordination
  echo "DEBUG: Pre-transition checkpoint (state=$CURRENT_STATE → $next_state)" >&2

  # Phase 3: Update state
  CURRENT_STATE="$next_state"

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

  # Phase 4: Save post-transition checkpoint
  echo "DEBUG: Post-transition checkpoint (state=$CURRENT_STATE)" >&2

  # Spec 672 Phase 2: Persist COMPLETED_STATES array to workflow state
  # Save after state update so subsequent bash blocks can restore state history
  if command -v save_completed_states_to_state &> /dev/null; then
    save_completed_states_to_state || true  # Non-critical, continue on failure
  fi

  echo "State transition: $CURRENT_STATE (completed: ${#COMPLETED_STATES[@]} states)" >&2
  return 0
}

# sm_execute: Execute handler for current state
# Usage: sm_execute
# Note: This delegates to state-specific handler functions (must be defined externally)
sm_execute() {
  local state="$CURRENT_STATE"

  # Delegate to state-specific handler
  # Handlers must be defined in orchestrator command (coordinate.md, orchestrate.md, supervise.md)
  case "$state" in
    initialize)
      if declare -f execute_initialize_phase &> /dev/null; then
        execute_initialize_phase
      else
        echo "ERROR: execute_initialize_phase not defined" >&2
        return 1
      fi
      ;;
    research)
      if declare -f execute_research_phase &> /dev/null; then
        execute_research_phase
      else
        echo "ERROR: execute_research_phase not defined" >&2
        return 1
      fi
      ;;
    plan)
      if declare -f execute_plan_phase &> /dev/null; then
        execute_plan_phase
      else
        echo "ERROR: execute_plan_phase not defined" >&2
        return 1
      fi
      ;;
    implement)
      if declare -f execute_implement_phase &> /dev/null; then
        execute_implement_phase
      else
        echo "ERROR: execute_implement_phase not defined" >&2
        return 1
      fi
      ;;
    test)
      if declare -f execute_test_phase &> /dev/null; then
        execute_test_phase
      else
        echo "ERROR: execute_test_phase not defined" >&2
        return 1
      fi
      ;;
    debug)
      if declare -f execute_debug_phase &> /dev/null; then
        execute_debug_phase
      else
        echo "ERROR: execute_debug_phase not defined" >&2
        return 1
      fi
      ;;
    document)
      if declare -f execute_document_phase &> /dev/null; then
        execute_document_phase
      else
        echo "ERROR: execute_document_phase not defined" >&2
        return 1
      fi
      ;;
    complete)
      if declare -f execute_complete_phase &> /dev/null; then
        execute_complete_phase
      else
        # Complete phase can have default implementation
        echo "Workflow complete" >&2
        return 0
      fi
      ;;
    *)
      echo "ERROR: Unknown state: $state" >&2
      return 1
      ;;
  esac
}

# sm_save: Save state machine to checkpoint
# Usage: sm_save <checkpoint-file>
# Example: sm_save /path/to/checkpoint.json
sm_save() {
  local checkpoint_file="$1"

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is required for checkpoint saving" >&2
    return 1
  fi

  # Build completed_states JSON array
  local completed_states_json="[]"
  if [ "${#COMPLETED_STATES[@]}" -gt 0 ]; then
    completed_states_json=$(printf '%s\n' "${COMPLETED_STATES[@]}" | jq -R . | jq -s .)
  fi

  # Build transition table JSON
  local transition_table_json
  transition_table_json=$(jq -n \
    --arg init "${STATE_TRANSITIONS[initialize]}" \
    --arg research "${STATE_TRANSITIONS[research]}" \
    --arg plan "${STATE_TRANSITIONS[plan]}" \
    --arg implement "${STATE_TRANSITIONS[implement]}" \
    --arg test "${STATE_TRANSITIONS[test]}" \
    --arg debug "${STATE_TRANSITIONS[debug]}" \
    --arg document "${STATE_TRANSITIONS[document]}" \
    --arg complete "${STATE_TRANSITIONS[complete]}" \
    '{
      initialize: $init,
      research: $research,
      plan: $plan,
      implement: $implement,
      test: $test,
      debug: $debug,
      document: $document,
      complete: $complete
    }')

  # Build state machine checkpoint (v2.0 schema)
  local state_machine_json
  state_machine_json=$(jq -n \
    --arg current_state "$CURRENT_STATE" \
    --argjson completed_states "$completed_states_json" \
    --argjson transition_table "$transition_table_json" \
    --arg scope "$WORKFLOW_SCOPE" \
    --arg description "$WORKFLOW_DESCRIPTION" \
    --arg command "$COMMAND_NAME" \
    '{
      current_state: $current_state,
      completed_states: $completed_states,
      transition_table: $transition_table,
      workflow_config: {
        scope: $scope,
        description: $description,
        command: $command
      }
    }')

  # Write state machine section to checkpoint file
  # Note: This writes only the state_machine section
  # Full checkpoint should include phase_data, supervisor_state, error_state, metadata
  local checkpoint_dir
  checkpoint_dir=$(dirname "$checkpoint_file")
  mkdir -p "$checkpoint_dir"

  echo "$state_machine_json" > "$checkpoint_file"
  echo "State machine saved: $checkpoint_file" >&2
  return 0
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# map_phase_to_state: Convert phase number to state name (for v1.3 migration)
# Usage: state=$(map_phase_to_state <phase-number>)
# Example: state=$(map_phase_to_state 0)  # Returns "initialize"
map_phase_to_state() {
  local phase="$1"

  case "$phase" in
    0) echo "$STATE_INITIALIZE" ;;
    1) echo "$STATE_RESEARCH" ;;
    2) echo "$STATE_PLAN" ;;
    3) echo "$STATE_IMPLEMENT" ;;
    4) echo "$STATE_TEST" ;;
    5) echo "$STATE_DEBUG" ;;
    6) echo "$STATE_DOCUMENT" ;;
    7) echo "$STATE_COMPLETE" ;;
    *) echo "$STATE_INITIALIZE" ;;  # Default fallback
  esac
}

# map_state_to_phase: Convert state name to phase number (for backward compatibility)
# Usage: phase=$(map_state_to_phase <state-name>)
# Example: phase=$(map_state_to_phase "research")  # Returns 1
map_state_to_phase() {
  local state="$1"

  case "$state" in
    "$STATE_INITIALIZE") echo 0 ;;
    "$STATE_RESEARCH") echo 1 ;;
    "$STATE_PLAN") echo 2 ;;
    "$STATE_IMPLEMENT") echo 3 ;;
    "$STATE_TEST") echo 4 ;;
    "$STATE_DEBUG") echo 5 ;;
    "$STATE_DOCUMENT") echo 6 ;;
    "$STATE_COMPLETE") echo 7 ;;
    *) echo 0 ;;  # Default fallback
  esac
}

# sm_is_terminal: Check if current state is terminal state for this workflow
# Usage: if sm_is_terminal; then ... fi
sm_is_terminal() {
  [ "$CURRENT_STATE" = "$TERMINAL_STATE" ] || [ "$CURRENT_STATE" = "$STATE_COMPLETE" ]
}

# sm_get_scope: Get workflow scope
# Usage: scope=$(sm_get_scope)
sm_get_scope() {
  echo "$WORKFLOW_SCOPE"
}

# sm_get_completed_count: Get number of completed states
# Usage: count=$(sm_get_completed_count)
sm_get_completed_count() {
  echo "${#COMPLETED_STATES[@]}"
}

# sm_print_status: Print state machine status (for debugging)
# Usage: sm_print_status
sm_print_status() {
  echo "=== State Machine Status ===" >&2
  echo "Current State: $CURRENT_STATE" >&2
  echo "Workflow Scope: $WORKFLOW_SCOPE" >&2
  echo "Terminal State: $TERMINAL_STATE" >&2
  echo "Completed States: ${COMPLETED_STATES[*]}" >&2
  echo "Completed Count: ${#COMPLETED_STATES[@]}" >&2
  echo "Is Terminal: $(sm_is_terminal && echo 'yes' || echo 'no')" >&2
  echo "=========================" >&2
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Make functions available to sourcing scripts
export -f sm_init
export -f sm_load
export -f sm_current_state
export -f sm_transition
export -f sm_execute
export -f sm_save
export -f map_phase_to_state
export -f map_state_to_phase
export -f sm_is_terminal
export -f sm_get_scope
export -f sm_get_completed_count
export -f sm_print_status

# Spec 672 Phase 2: Export COMPLETED_STATES persistence functions
export -f save_completed_states_to_state
export -f load_completed_states_from_state

# ==============================================================================
# Library Initialization (Spec 672 Phase 2)
# ==============================================================================

# Conditionally load COMPLETED_STATES from state on library re-sourcing
# This preserves state history across bash subprocess boundaries
if [ "${#COMPLETED_STATES[@]}" -eq 0 ] && [ -n "${COMPLETED_STATES_JSON:-}" ]; then
  load_completed_states_from_state
fi
