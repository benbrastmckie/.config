#!/usr/bin/env bash
# Workflow State Machine Library
# Provides formal state machine abstraction for orchestration commands
#
# Version: 2.0.0
# Last Modified: 2025-11-17
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
# - Idempotent transitions: Same-state transitions succeed immediately (early-exit optimization)
#
# Complexity Normalization:
# - Automatically normalizes complexity scores to 1-4 range during sm_init
# - Legacy scores (e.g., 78.5) mapped to valid range: <30→1, 30-49→2, 50-69→3, ≥70→4
# - Invalid inputs default to 2 with WARNING, ensuring initialization always succeeds
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
export WORKFLOW_STATE_MACHINE_VERSION="2.0.0"

set -euo pipefail

# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../core/detect-project-dir.sh"

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
  [initialize]="research,implement" # Can go to research or directly to implement (for /build)
  [research]="plan,complete"        # Can skip to complete for research-only
  [plan]="implement,complete,debug" # Can skip to complete for research-and-plan, or debug for debug-only workflows
  [implement]="test,complete"       # Can go to testing or complete (implement-only workflows)
  [test]="debug,document,complete"  # Conditional: debug if failed, document if passed, complete if skipping documentation
  [debug]="test,document,complete"  # Can retry testing, go to documentation, or complete if unfixable
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

# normalize_complexity: Normalize complexity score to valid 1-4 range
# Usage: normalize_complexity <complexity_score>
# Returns: Normalized complexity (1-4) on stdout
# Effect: Preserves valid 1-4 values unchanged, maps legacy scores to 1-4 range
# Complexity Mapping:
#   1-4   → unchanged (valid values pass through)
#   <30   → 1 (Low)
#   30-49 → 2 (Medium)
#   50-69 → 3 (High)
#   ≥70   → 4 (Very High)
#   Invalid → 2 (default with WARNING)
# Examples:
#   normalize_complexity "2"    # Returns "2" (unchanged)
#   normalize_complexity "78.5" # Returns "4" (normalized)
normalize_complexity() {
  local input="$1"

  # Validate numeric input (integer or decimal)
  if ! [[ "$input" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "WARNING: Invalid complexity '$input', using default 2" >&2
    echo "2"
    return 0
  fi

  # Convert to integer (truncate decimals)
  local value=${input%.*}

  # Early return: Valid 1-4 values pass through unchanged
  if [ "$value" -ge 1 ] && [ "$value" -le 4 ]; then
    echo "$value"
    return 0
  fi

  # Map legacy/out-of-range values to 1-4 range
  local normalized
  if [ "$value" -lt 30 ]; then
    normalized="1"
  elif [ "$value" -lt 50 ]; then
    normalized="2"
  elif [ "$value" -lt 70 ]; then
    normalized="3"
  else
    normalized="4"
  fi

  # Emit INFO message for normalization (only for out-of-range values)
  echo "INFO: Normalized complexity $input → $normalized" >&2

  echo "$normalized"
}

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
#   - state-persistence.sh: append_workflow_state()
#
# Effects:
#   Writes to workflow state file using indexed variables pattern:
#   - COMPLETED_STATES_COUNT: Integer count for validation
#   - COMPLETED_STATE_0, COMPLETED_STATE_1, ...: Individual state names
#
# Returns:
#   0 on success, 1 on error
#
# Example:
#   COMPLETED_STATES=("initialize" "research" "plan")
#   save_completed_states_to_state
#   # State file now contains:
#   #   export COMPLETED_STATES_COUNT=3
#   #   export COMPLETED_STATE_0="initialize"
#   #   export COMPLETED_STATE_1="research"
#   #   export COMPLETED_STATE_2="plan"
#
# Reference: Spec 672 Phase 2 (state machine array persistence)
#
save_completed_states_to_state() {

  # Check if state persistence function is available
  if ! command -v append_workflow_state &> /dev/null; then
    echo "WARNING: append_workflow_state not available, skipping COMPLETED_STATES persistence" >&2
    return 1
  fi

  # Save completed states using indexed variables pattern (scalar-only storage)
  # Store count first
  append_workflow_state "COMPLETED_STATES_COUNT" "${#COMPLETED_STATES[@]}"

  # Store each state with indexed key (COMPLETED_STATE_0, COMPLETED_STATE_1, etc.)
  local i
  for i in "${!COMPLETED_STATES[@]}"; do
    append_workflow_state "COMPLETED_STATE_${i}" "${COMPLETED_STATES[$i]}"
  done

  return 0
}

# load_completed_states_from_state: Reconstruct COMPLETED_STATES array from workflow state
#
# Loads the COMPLETED_STATES array from the GitHub Actions-style state file
# using indexed variables pattern (scalar-only storage).
#
# Purpose:
#   Restore completed states history after bash block boundaries. Used in
#   orchestration commands when re-sourcing state machine library.
#
# Dependencies:
#   None (uses bash built-ins only)
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
#   #   export COMPLETED_STATES_COUNT=2
#   #   export COMPLETED_STATE_0="initialize"
#   #   export COMPLETED_STATE_1="research"
#   load_completed_states_from_state
#   # Result: COMPLETED_STATES=("initialize" "research")
#
# Reference: Spec 672 Phase 2 (state machine array persistence)
#
load_completed_states_from_state() {
  # Defensive: Initialize empty array first
  COMPLETED_STATES=()

  # Check if COMPLETED_STATES_COUNT exists in state
  if [ -z "${COMPLETED_STATES_COUNT:-}" ]; then
    # Not an error - initial workflow won't have completed states yet
    return 0
  fi

  # Reconstruct array from indexed variables (COMPLETED_STATE_0, COMPLETED_STATE_1, etc.)
  local i
  for i in $(seq 0 $((COMPLETED_STATES_COUNT - 1))); do
    local var_name="COMPLETED_STATE_${i}"
    local value="${!var_name:-}"
    if [ -n "$value" ]; then
      COMPLETED_STATES+=("$value")
    else
      echo "WARNING: Missing indexed state variable $var_name" >&2
    fi
  done

  # Validate reconstructed array matches count
  if [ "${#COMPLETED_STATES[@]}" -ne "$COMPLETED_STATES_COUNT" ]; then
    echo "WARNING: COMPLETED_STATES count mismatch (expected $COMPLETED_STATES_COUNT, got ${#COMPLETED_STATES[@]})" >&2
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
#   $4 - research_complexity: Integer 1-4 indicating research depth (auto-normalized from legacy values)
#   $5 - research_topics_json: JSON array of research topics
#
# Complexity Normalization:
#   research_complexity is automatically normalized to 1-4 range:
#   - Legacy scores (e.g., 78.5) mapped to valid range
#   - Invalid inputs default to 2 with WARNING
#   - Graceful degradation ensures initialization always succeeds
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
    research-only|research-and-plan|research-and-revise|full-implementation|debug-only|implement-only|test-and-debug)
      : # Valid
      ;;
    *)
      echo "ERROR: Invalid workflow_type: $workflow_type" >&2
      echo "  Valid types: research-only, research-and-plan, research-and-revise, full-implementation, debug-only, implement-only, test-and-debug" >&2
      return 1
      ;;
  esac

  # Normalize complexity score to 1-4 range
  # Handles legacy scores (e.g., 78.5) and out-of-range values
  local normalized_complexity
  normalized_complexity=$(normalize_complexity "$research_complexity")

  # Update research_complexity to use normalized value
  research_complexity="$normalized_complexity"

  # Validate normalized complexity with graceful degradation
  # Defensive check with fallback to ensure initialization always succeeds
  if ! [[ "$research_complexity" =~ ^[1-4]$ ]]; then
    echo "WARNING: Complexity validation failed after normalization, using default 2" >&2
    echo "  Got: $research_complexity (original: $4)" >&2
    research_complexity="2"  # Safe default for degraded initialization
    # Continue with initialization instead of failing
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

  # Persist classification variables to state file (scalar values only)
  # RESEARCH_TOPICS_JSON is kept in memory only (not persisted due to JSON format)
  if command -v append_workflow_state &> /dev/null; then
    append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
    append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
    # RESEARCH_TOPICS_JSON skipped - JSON format incompatible with scalar-only state persistence
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
    implement-only)
      TERMINAL_STATE="$STATE_IMPLEMENT"
      ;;
    test-and-debug)
      TERMINAL_STATE="$STATE_COMPLETE"
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
      implement-only) TERMINAL_STATE="$STATE_IMPLEMENT" ;;
      test-and-debug) TERMINAL_STATE="$STATE_COMPLETE" ;;
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
      implement-only) TERMINAL_STATE="$STATE_IMPLEMENT" ;;
      test-and-debug) TERMINAL_STATE="$STATE_COMPLETE" ;;
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
# Usage: sm_transition <next-state> [transition-reason]
# Parameters:
#   next-state: Target state constant (e.g., $STATE_RESEARCH)
#   transition-reason: Optional reason for transition (for audit trail and debugging)
# Example: sm_transition "$STATE_RESEARCH" "user requested research phase"
# Example: sm_transition "$STATE_DEBUG" "test-executor recommendation"
sm_transition() {
  local next_state="$1"
  local transition_reason="${2:-}" # Optional transition reason for audit trail

  # Auto-initialization guard: Attempt to recover if STATE_FILE not set
  # This prevents hard failures from command authoring gaps where load_workflow_state was omitted
  if [ -z "${STATE_FILE:-}" ]; then
    echo "⚠️  WARNING: Auto-initializing state machine (load_workflow_state not called explicitly)" >&2
    echo "  This is a fallback mechanism - commands should call load_workflow_state in Block 0" >&2

    # Log auto-initialization attempt for monitoring
    if declare -f log_command_error &>/dev/null; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "state_error" \
        "sm_transition called before initialization - auto-initializing" \
        "sm_transition" \
        "$(jq -n --arg target "$next_state" '{target_state: $target, auto_init: true}')"
    fi

    # Attempt auto-initialization
    if declare -f load_workflow_state &>/dev/null; then
      # Try to load state using WORKFLOW_ID if available, otherwise use $$
      local workflow_id_for_load="${WORKFLOW_ID:-$$}"
      # Call with is_first_block=false (no required variable validation)
      if ! load_workflow_state "$workflow_id_for_load" false 2>/dev/null; then
        # Auto-initialization failed
        if declare -f log_command_error &>/dev/null; then
          log_command_error \
            "${COMMAND_NAME:-/unknown}" \
            "${WORKFLOW_ID:-unknown}" \
            "${USER_ARGS:-}" \
            "state_error" \
            "Auto-initialization failed - no existing state file found" \
            "sm_transition" \
            "$(jq -n --arg target "$next_state" --arg wid "$workflow_id_for_load" \
               '{target_state: $target, workflow_id: $wid, auto_init_failed: true}')"
        fi
        echo "ERROR: STATE_FILE not set and auto-initialization failed" >&2
        echo "DIAGNOSTIC: Call load_workflow_state() explicitly before sm_transition()" >&2
        echo "DIAGNOSTIC: Attempted to load workflow ID: $workflow_id_for_load" >&2
        return 1
      fi
      # Auto-initialization succeeded
      echo "  ✓ Auto-initialization successful (loaded workflow ID: $workflow_id_for_load)" >&2
    else
      # load_workflow_state function not available
      echo "ERROR: STATE_FILE not set and load_workflow_state function not available" >&2
      return 1
    fi
  fi

  # Validate CURRENT_STATE is set (prevents undefined variable errors)
  if [ -z "${CURRENT_STATE:-}" ]; then
    if declare -f log_command_error &>/dev/null; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "state_error" \
        "CURRENT_STATE not set during sm_transition - state machine not initialized" \
        "sm_transition" \
        "$(jq -n --arg target "$next_state" '{target_state: $target}')"
    fi
    echo "ERROR: CURRENT_STATE not set in sm_transition()" >&2
    echo "DIAGNOSTIC: Call sm_init() before sm_transition()" >&2
    return 1
  fi

  # Idempotent: Same-state transitions succeed immediately (no-op)
  if [ "${CURRENT_STATE:-}" = "$next_state" ]; then
    echo "INFO: Already in state '$next_state', transition skipped (idempotent)" >&2
    return 0  # Success, no error
  fi

  # Terminal State Protection: Prevent transitions from terminal states
  TERMINAL_STATES=("complete" "abandoned")
  for terminal in "${TERMINAL_STATES[@]}"; do
    if [ "${CURRENT_STATE:-}" = "$terminal" ]; then
      if declare -f log_command_error &>/dev/null; then
        log_command_error \
          "${COMMAND_NAME:-/unknown}" \
          "${WORKFLOW_ID:-unknown}" \
          "${USER_ARGS:-}" \
          "state_error" \
          "Cannot transition from terminal state: $CURRENT_STATE -> $next_state" \
          "sm_transition" \
          "$(jq -n --arg current "$CURRENT_STATE" --arg target "$next_state" \
             '{current_state: $current, target_state: $target, error: "Terminal state transition blocked"}')"
      fi
      echo "ERROR: Cannot transition from terminal state: $CURRENT_STATE" >&2
      echo "Terminal states are final - workflow must be restarted for new transitions" >&2
      return 1
    fi
  done

  # Phase 1: Validate transition is allowed
  local valid_transitions="${STATE_TRANSITIONS[$CURRENT_STATE]:-}"

  # Check if valid_transitions is empty (indicates invalid current state)
  if [ -z "$valid_transitions" ]; then
    if declare -f log_command_error &>/dev/null; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "state_error" \
        "No valid transitions defined for current state: $CURRENT_STATE" \
        "sm_transition" \
        "$(jq -n --arg current "$CURRENT_STATE" --arg target "$next_state" \
           '{current_state: $current, target_state: $target}')"
    fi
    echo "ERROR: No valid transitions defined for state: $CURRENT_STATE" >&2
    return 1
  fi

  # Check if next_state is in valid_transitions (comma-separated)
  if ! echo ",$valid_transitions," | grep -q ",$next_state,"; then
    # Log invalid transition to centralized error log
    if declare -f log_command_error &>/dev/null; then
      local error_details
      if [ -n "$transition_reason" ]; then
        error_details="$(jq -n --arg current "$CURRENT_STATE" --arg target "$next_state" --arg valid "$valid_transitions" --arg reason "$transition_reason" \
           '{current_state: $current, target_state: $target, valid_transitions: $valid, transition_reason: $reason}')"
      else
        error_details="$(jq -n --arg current "$CURRENT_STATE" --arg target "$next_state" --arg valid "$valid_transitions" \
           '{current_state: $current, target_state: $target, valid_transitions: $valid}')"
      fi
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "state_error" \
        "Invalid state transition attempted: $CURRENT_STATE -> $next_state${transition_reason:+ (reason: $transition_reason)}" \
        "sm_transition" \
        "$error_details"
    fi
    echo "ERROR: Invalid transition: $CURRENT_STATE → $next_state" >&2
    if [ -n "$transition_reason" ]; then
      echo "Transition reason: $transition_reason" >&2
    fi
    echo "Valid transitions from $CURRENT_STATE: $valid_transitions" >&2
    echo "DIAGNOSTIC: If CURRENT_STATE seems wrong, check state persistence between blocks" >&2
    echo "DIAGNOSTIC: Verify load_workflow_state() was called and STATE_FILE is set" >&2
    return 1
  fi

  # Phase 2: Save pre-transition checkpoint (atomic state transition)
  # Note: Actual checkpoint save requires checkpoint-utils.sh integration
  # This is a placeholder for checkpoint coordination
  if [ -n "$transition_reason" ]; then
    echo "DEBUG: Pre-transition checkpoint (state=$CURRENT_STATE → $next_state, reason: $transition_reason)" >&2
  else
    echo "DEBUG: Pre-transition checkpoint (state=$CURRENT_STATE → $next_state)" >&2
  fi

  # Phase 3: Update state
  CURRENT_STATE="$next_state"

  # Persist CURRENT_STATE to state file (following sm_init pattern)
  # This ensures subsequent bash blocks can read the correct state
  if command -v append_workflow_state &> /dev/null; then
    append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"
  else
    echo "WARNING: append_workflow_state not available - state may not persist across blocks" >&2
  fi

  # Export for immediate use in current block
  export CURRENT_STATE

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
  if [ -n "$transition_reason" ]; then
    echo "DEBUG: Post-transition checkpoint (state=$CURRENT_STATE, reason: $transition_reason)" >&2
  else
    echo "DEBUG: Post-transition checkpoint (state=$CURRENT_STATE)" >&2
  fi

  # Spec 672 Phase 2: Persist COMPLETED_STATES array to workflow state
  # Save after state update so subsequent bash blocks can restore state history
  if command -v save_completed_states_to_state &> /dev/null; then
    save_completed_states_to_state || true  # Non-critical, continue on failure
  fi

  if [ -n "$transition_reason" ]; then
    echo "State transition: $CURRENT_STATE (reason: $transition_reason, completed: ${#COMPLETED_STATES[@]} states)" >&2
  else
    echo "State transition: $CURRENT_STATE (completed: ${#COMPLETED_STATES[@]} states)" >&2
  fi
  return 0
}

# sm_validate_state: Validate state machine is properly initialized
# Usage: sm_validate_state || exit 1
# Returns: 0 if valid, 1 if invalid
sm_validate_state() {
  local errors=0

  if [ -z "${STATE_FILE:-}" ]; then
    echo "ERROR: STATE_FILE not set" >&2
    errors=$((errors + 1))
  elif [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: STATE_FILE does not exist: $STATE_FILE" >&2
    errors=$((errors + 1))
  fi

  if [ -z "${CURRENT_STATE:-}" ]; then
    echo "ERROR: CURRENT_STATE not set" >&2
    errors=$((errors + 1))
  fi

  if [ -z "${WORKFLOW_SCOPE:-}" ]; then
    echo "WARNING: WORKFLOW_SCOPE not set" >&2
    # Not a hard error, but worth noting
  fi

  if [ "$errors" -gt 0 ]; then
    echo "State validation failed with $errors errors" >&2
    return 1
  fi

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

  # Build transition table JSON (reads from STATE_TRANSITIONS, already updated)
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
export -f sm_validate_state
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
if [ "${#COMPLETED_STATES[@]}" -eq 0 ] && [ -n "${COMPLETED_STATES_COUNT:-}" ]; then
  load_completed_states_from_state
fi
