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

# generate_descriptive_topics_from_plans: Generate descriptive topic names from plan analysis
# Usage: generate_descriptive_topics_from_plans <workflow-description> <complexity>
# Returns: JSON array of descriptive topic names
generate_descriptive_topics_from_plans() {
  local workflow_desc="$1"
  local complexity="${2:-4}"  # Default to 4 topics

  # Extract plan paths from description (pattern: /specs/NNN_topic/plans/001_*.md or .claude/specs/...)
  local source_plan=$(echo "$workflow_desc" | grep -oE '(/[^ ]*)?\.claude/specs/[0-9]+_[^/]+/plans/[^/]+\.md' | head -1)
  local target_plan=$(echo "$workflow_desc" | grep -oE '(/[^ ]*)?\.claude/specs/[0-9]+_[^/]+/plans/[^/]+\.md' | tail -1)

  # If no absolute path, try relative paths and convert to absolute
  if [ -z "$source_plan" ]; then
    local relative_plan=$(echo "$workflow_desc" | grep -oE '\.claude/specs/[0-9]+_[^/]+/plans/[^/]+\.md' | head -1)
    if [ -n "$relative_plan" ] && [ -f "$CLAUDE_PROJECT_DIR/$relative_plan" ]; then
      source_plan="$CLAUDE_PROJECT_DIR/$relative_plan"
    fi
  fi

  if [ -n "$source_plan" ] && [ -f "$source_plan" ]; then
    # Read source plan to determine what was implemented
    local plan_title=$(grep -m1 "^# " "$source_plan" | sed 's/^# //' | sed 's/ Plan$//' | sed 's/ Implementation$//')

    # Extract target topic name from target plan path if available
    local target_topic_name=""
    if [ -n "$target_plan" ] && [ "$target_plan" != "$source_plan" ]; then
      target_topic_name=$(basename $(dirname $(dirname "$target_plan")) | sed 's/^[0-9]\+_//' | tr '_' ' ')
    fi

    # Generate descriptive topics based on complexity
    case "$complexity" in
      2)
        jq -n --arg t1 "$(echo "$plan_title" | sed 's/ implementation//') implementation architecture" \
              --arg t2 "Integration approach and lessons learned" \
              '[$t1, $t2]'
        ;;
      3)
        jq -n --arg t1 "$(echo "$plan_title" | sed 's/ implementation//') implementation architecture" \
              --arg t2 "${target_topic_name:-Target system} integration points" \
              --arg t3 "Performance characteristics and optimization opportunities" \
              '[$t1, $t2, $t3]'
        ;;
      *)  # 4 or more
        jq -n --arg t1 "$(echo "$plan_title" | sed 's/ implementation//') implementation architecture" \
              --arg t2 "${target_topic_name:-Target system} integration points" \
              --arg t3 "Performance characteristics and metrics" \
              --arg t4 "Optimization opportunities and lessons learned" \
              '[$t1, $t2, $t3, $t4]'
        ;;
    esac
  else
    # Fallback: Could not find or read plan file
    # Generate generic topics matching complexity count
    case "$complexity" in
      2)
        echo '["Topic 1","Topic 2"]'
        ;;
      3)
        echo '["Topic 1","Topic 2","Topic 3"]'
        ;;
      *)
        echo '["Topic 1","Topic 2","Topic 3","Topic 4"]'
        ;;
    esac
  fi
}

# generate_descriptive_topics_from_description: Extract key concepts from workflow description
# Usage: generate_descriptive_topics_from_description <workflow-description> <complexity>
# Returns: JSON array of descriptive topic names
generate_descriptive_topics_from_description() {
  local workflow_desc="$1"
  local complexity="${2:-4}"

  # Extract key terms (simple noun/verb extraction)
  # This is a basic implementation - can be enhanced with more sophisticated NLP
  local key_terms=$(echo "$workflow_desc" | \
    grep -oE '\b[A-Z][a-z]+\b|\b(implement|create|add|refactor|optimize|fix|debug|test|document)[a-z]*\b' | \
    head -8 | \
    tr '\n' ' ')

  # If we found meaningful terms, use them
  if [ -n "$key_terms" ]; then
    # Generate topics based on extracted terms and complexity
    case "$complexity" in
      2)
        jq -n --arg t1 "$key_terms architecture and design" \
              --arg t2 "Implementation approach and testing" \
              '[$t1, $t2]'
        ;;
      3)
        jq -n --arg t1 "$key_terms architecture and design" \
              --arg t2 "Implementation approach and patterns" \
              --arg t3 "Testing and validation strategy" \
              '[$t1, $t2, $t3]'
        ;;
      *)  # 4 or more
        jq -n --arg t1 "$key_terms architecture and design" \
              --arg t2 "Implementation approach and patterns" \
              --arg t3 "Testing and validation strategy" \
              --arg t4 "Performance and optimization considerations" \
              '[$t1, $t2, $t3, $t4]'
        ;;
    esac
  else
    # Fallback: No meaningful terms found
    case "$complexity" in
      2)
        echo '["Topic 1","Topic 2"]'
        ;;
      3)
        echo '["Topic 1","Topic 2","Topic 3"]'
        ;;
      *)
        echo '["Topic 1","Topic 2","Topic 3","Topic 4"]'
        ;;
    esac
  fi
}

# sm_init: Initialize new state machine with pre-computed classification
# Usage: sm_init <workflow-description> <command-name> <workflow-type> <research-complexity> <research-topics-json>
# Example: sm_init "Research authentication patterns" "coordinate" "research-and-plan" 2 '[{"short_name":"Auth Patterns",...}]'
#
# BREAKING CHANGE (Spec 1763161992 Phase 2): Classification now performed by invoking command BEFORE sm_init.
# sm_init accepts classification results as parameters (no internal classification).
# sm_init: Initialize state machine and persist classification variables
#
# Purpose:
#   Initialize state machine with workflow classification parameters and persist
#   all critical state variables to both bash environment and state file.
#
# Parameters:
#   $1 - workflow_desc: Description of the workflow/task
#   $2 - command_name: Name of the command invoking sm_init (e.g., "coordinate")
#   $3 - workflow_type: Workflow scope (research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
#   $4 - research_complexity: Integer 1-4 indicating research depth
#   $5 - research_topics_json: JSON array of research topics
#
# Environment Exports:
#   WORKFLOW_SCOPE - Workflow type (same as workflow_type parameter)
#   RESEARCH_COMPLEXITY - Research depth (1-4)
#   RESEARCH_TOPICS_JSON - JSON array of topics
#   TERMINAL_STATE - Terminal state for this workflow (computed from workflow_type)
#   CURRENT_STATE - Initial state (always "initialize")
#
# State File Persistence:
#   All 5 environment variables are persisted to STATE_FILE using append_workflow_state()
#   This ensures verification checkpoints can validate state file contents
#   Follows COMPLETED_STATES persistence pattern (see lines 144-145)
#
# Returns:
#   0 - Success (all validation passed, variables exported and persisted)
#   1 - Validation failure (invalid parameters, missing classification)
#
# Calling Pattern:
#   1. Invoke workflow-classifier agent to get CLASSIFICATION_JSON
#   2. Extract workflow_type, research_complexity, research_topics_json from CLASSIFICATION_JSON
#   3. Call sm_init with extracted parameters
#   4. Verify environment variables exported (WORKFLOW_SCOPE, etc.)
#   5. Verify state file persistence (using verify_state_variables)
#
# Example:
#   sm_init "$WORKFLOW_DESC" "coordinate" "research-only" "2" '["topic1","topic2"]'
#   # Check return code
#   if [ $? -ne 0 ]; then
#     echo "State machine initialization failed"
#     exit 1
#   fi
#   # Verify exports
#   [ -n "${WORKFLOW_SCOPE:-}" ] || { echo "WORKFLOW_SCOPE not exported"; exit 1; }
#   # Verify state file
#   verify_state_variables "$STATE_FILE" "WORKFLOW_SCOPE" "TERMINAL_STATE" "CURRENT_STATE" "RESEARCH_COMPLEXITY" "RESEARCH_TOPICS_JSON"
#
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"
  local workflow_type="$3"
  local research_complexity="$4"
  local research_topics_json="$5"

  # Store workflow configuration
  WORKFLOW_DESCRIPTION="$workflow_desc"
  COMMAND_NAME="$command_name"

  # Parameter validation (fail-fast)
  if [ -z "$workflow_type" ] || [ -z "$research_complexity" ] || [ -z "$research_topics_json" ]; then
    echo "ERROR: sm_init requires classification parameters" >&2
    echo "  Usage: sm_init WORKFLOW_DESC COMMAND_NAME WORKFLOW_TYPE RESEARCH_COMPLEXITY RESEARCH_TOPICS_JSON" >&2
    echo "" >&2
    echo "  Missing parameters:" >&2
    [ -z "$workflow_type" ] && echo "    - workflow_type" >&2
    [ -z "$research_complexity" ] && echo "    - research_complexity" >&2
    [ -z "$research_topics_json" ] && echo "    - research_topics_json" >&2
    echo "" >&2
    echo "  IMPORTANT: Commands must invoke workflow-classifier agent BEFORE calling sm_init" >&2
    echo "  See: .claude/agents/workflow-classifier.md" >&2
    return 1
  fi

  # Validate workflow_type enum
  case "$workflow_type" in
    research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
      : # Valid
      ;;
    *)
      echo "ERROR: Invalid workflow_type: $workflow_type" >&2
      echo "  Valid types: research-only, research-and-plan, research-and-revise, full-implementation, debug-only" >&2
      return 1
      ;;
  esac

  # Validate research_complexity range
  if ! [[ "$research_complexity" =~ ^[0-9]+$ ]] || [ "$research_complexity" -lt 1 ] || [ "$research_complexity" -gt 4 ]; then
    echo "ERROR: research_complexity must be integer 1-4, got: $research_complexity" >&2
    return 1
  fi

  # Validate research_topics_json is valid JSON array
  if ! echo "$research_topics_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
    echo "ERROR: research_topics_json must be valid JSON array" >&2
    echo "  Received: $research_topics_json" >&2
    return 1
  fi

  # Store validated classification parameters
  WORKFLOW_SCOPE="$workflow_type"
  RESEARCH_COMPLEXITY="$research_complexity"
  RESEARCH_TOPICS_JSON="$research_topics_json"

  # Export classification dimensions for use by orchestration commands
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON

  # Persist classification variables to state file (following COMPLETED_STATES pattern)
  # This ensures verification checkpoints can validate state file persistence
  if command -v append_workflow_state &> /dev/null; then
    append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
    append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
    append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
  else
    echo "WARNING: append_workflow_state not available, skipping classification persistence" >&2
  fi

  # Log accepted classification
  echo "Classification accepted: scope=$WORKFLOW_SCOPE, complexity=$RESEARCH_COMPLEXITY, topics=$(echo "$RESEARCH_TOPICS_JSON" | jq -r 'length')" >&2

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

  # Export and persist terminal state and current state for verification
  export TERMINAL_STATE
  export CURRENT_STATE

  # Persist state machine variables to state file
  if command -v append_workflow_state &> /dev/null; then
    append_workflow_state "TERMINAL_STATE" "$TERMINAL_STATE"
    append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
  else
    echo "WARNING: append_workflow_state not available, skipping state machine persistence" >&2
  fi

  # Log initialization status
  echo "State machine initialized: scope=$WORKFLOW_SCOPE, terminal=$TERMINAL_STATE" >&2

  # CRITICAL: Return RESEARCH_COMPLEXITY value for use in dynamic path allocation
  # This enables Phase 0 just-in-time allocation (eliminates pre-allocation tension)
  echo "$RESEARCH_COMPLEXITY"
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
