# State Machine Checkpoint Coordination with Classification

## Metadata
- **Date**: 2025-11-14
- **Agent**: research-specialist
- **Topic**: State machine checkpoint coordination with LLM classification metadata
- **Report Type**: codebase analysis
- **Synthesis**: [OVERVIEW.md](OVERVIEW.md) - LLM Classification State Machine Integration Overview
- **Related Subtopics**: [001_agent_invocation_pattern_and_task_tool_integration.md](001_agent_invocation_pattern_and_task_tool_integration.md), [003_command_level_classification_flow_and_error_handling.md](003_command_level_classification_flow_and_error_handling.md), [004_backward_compatibility_and_library_migration_strategy.md](004_backward_compatibility_and_library_migration_strategy.md)

## Executive Summary

LLM classification metadata (workflow_type, research_complexity, research_topics) currently persists through GitHub Actions-style state files but has NO integration with v2.0 checkpoint schema. This creates a coordination gap where classification results exist in bash process memory and state files but are not preserved in resumable checkpoints, preventing proper workflow resume after failures. The integration requires adding classification metadata to checkpoint schema and coordinating atomic writes with state machine transitions.

## Findings

### Current Checkpoint Schema (V2.0)

**Location**: `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (lines 23-152)

**Schema Version**: 2.0

**Structure**:
```json
{
  "schema_version": "2.0",
  "checkpoint_id": "coordinate_auth_20251114_143000",
  "workflow_type": "coordinate",
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "transition_table": {...},
    "workflow_config": {
      "scope": "full-implementation",
      "description": "Add user authentication",
      "command": "coordinate"
    }
  },
  "phase_data": {},
  "supervisor_state": {},
  "error_state": {
    "last_error": null,
    "retry_count": 0,
    "failed_state": null
  }
}
```

**Key Observations**:
1. **state_machine section** exists as first-class citizen (added in v2.0)
2. **workflow_config subsection** contains scope and description
3. **NO classification metadata fields** (research_complexity, research_topics)
4. Migration from v1.3 to v2.0 (lines 389-472) adds state_machine wrapper

### State Persistence Pattern (GitHub Actions Style)

**Location**: `/home/benjamin/.config/.claude/lib/state-persistence.sh`

**Mechanism**: File-based key-value export statements
```bash
# State file format: ~/.claude/tmp/workflow_<id>.sh
export CLAUDE_PROJECT_DIR="/path/to/project"
export WORKFLOW_SCOPE="full-implementation"
export RESEARCH_COMPLEXITY="2"
export RESEARCH_TOPICS_JSON='[{"short_name":"..."}]'
```

**Functions**:
- `init_workflow_state()` - Creates state file with initial vars
- `append_workflow_state()` - Appends key-value pairs
- `load_workflow_state()` - Sources state file to restore vars
- `save_json_checkpoint()` - Atomic JSON writes (temp + mv)
- `load_json_checkpoint()` - Read JSON checkpoints with graceful degradation

**Critical State Items Using File Persistence** (7 identified):
1. Supervisor metadata (P0): 95% context reduction
2. Benchmark dataset (P0): Cross-subprocess accumulation
3. Implementation supervisor state (P0): Parallel execution tracking
4. Testing supervisor state (P0): Lifecycle coordination
5. Migration progress (P1): Resumable multi-hour workflows
6. Performance benchmarks (P1): Phase dependencies
7. POC metrics (P1): Success criterion validation

**Performance Characteristics**:
- CLAUDE_PROJECT_DIR detection: 70% improvement (50ms → 15ms via caching)
- JSON checkpoint write: 5-10ms (atomic with temp + mv)
- JSON checkpoint read: 2-5ms (cat + optional jq validation)

### State Machine Integration Points

**Location**: `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh`

**sm_init() Function** (lines 334-476):

Key behavior:
```bash
sm_init() {
  local workflow_desc="$1"
  local command_name="$2"

  # Perform comprehensive workflow classification
  source "$SCRIPT_DIR/workflow-scope-detection.sh"
  classification_result=$(classify_workflow_comprehensive "$workflow_desc" "$workflow_id")

  # Parse and export classification dimensions
  WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type')
  RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity')
  RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics')

  # CRITICAL: Export for cross-bash-block availability
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON

  # Configure terminal state based on scope
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    research-and-plan) TERMINAL_STATE="$STATE_PLAN" ;;
    full-implementation) TERMINAL_STATE="$STATE_COMPLETE" ;;
  esac

  # Return research complexity for dynamic allocation
  echo "$RESEARCH_COMPLEXITY"
  return 0
}
```

**Critical Gap**: Classification results exported to bash environment BUT NOT saved to checkpoints.

**sm_save() Function** (lines 698-768):

Current implementation:
```bash
sm_save() {
  local checkpoint_file="$1"

  # Build state machine checkpoint (v2.0 schema)
  state_machine_json=$(jq -n \
    --arg current_state "$CURRENT_STATE" \
    --argjson completed_states "$completed_states_json" \
    --arg scope "$WORKFLOW_SCOPE" \
    --arg description "$WORKFLOW_DESCRIPTION" \
    --arg command "$COMMAND_NAME" \
    '{
      current_state: $current_state,
      completed_states: $completed_states,
      workflow_config: {
        scope: $scope,
        description: $description,
        command: $command
      }
    }')

  echo "$state_machine_json" > "$checkpoint_file"
}
```

**Gap**: Only saves `scope` (workflow_type), missing `research_complexity` and `research_topics`.

**sm_load() Function** (lines 478-559):

Current implementation:
```bash
sm_load() {
  local checkpoint_file="$1"

  # Load v2.0 checkpoint
  CURRENT_STATE=$(jq -r '.state_machine.current_state' "$checkpoint_file")
  WORKFLOW_SCOPE=$(jq -r '.state_machine.workflow_config.scope' "$checkpoint_file")
  WORKFLOW_DESCRIPTION=$(jq -r '.state_machine.workflow_config.description' "$checkpoint_file")

  # Determine terminal state from scope
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    # ... other cases
  esac
}
```

**Gap**: No restoration of `RESEARCH_COMPLEXITY` or `RESEARCH_TOPICS_JSON`.

### LLM Classification Metadata Storage

**Location**: `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh`

**classify_workflow_llm_comprehensive() Output** (lines 86-204):

Returns structured JSON:
```json
{
  "workflow_type": "research-and-plan",
  "confidence": 0.95,
  "research_complexity": 2,
  "research_topics": [
    {
      "short_name": "Implementation architecture",
      "detailed_description": "Analyze current implementation...",
      "filename_slug": "implementation_architecture",
      "research_focus": "Key questions: How is..."
    }
  ],
  "subtopics": ["Implementation architecture"],
  "reasoning": "..."
}
```

**File-Based Signaling Pattern** (lines 297-359):

Temporary files for LLM communication:
- Request: `~/.claude/tmp/llm_request_${workflow_id}.json`
- Response: `~/.claude/tmp/llm_response_${workflow_id}.json`

**Semantic Filename Scoping** (Spec 704 Phase 2):
- Uses `workflow_id` instead of `$$` (PID)
- Enables persistence across bash block boundaries
- Cleanup at workflow completion, not bash block exit

**Validation Requirements** (lines 384-474):

Enhanced topic validation:
- Each topic has 4 required fields: `short_name`, `detailed_description`, `filename_slug`, `research_focus`
- `filename_slug` must match `^[a-z0-9_]{1,50}$`
- `detailed_description` must be 50-500 characters
- Topic count must match `research_complexity` exactly

### Command Integration Patterns

**Location**: `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 164-286)

**Phase 0: State Machine Initialization**

```bash
# Block 1: Initialize state machine
sm_init "$SAVED_WORKFLOW_DESC" "coordinate"
SM_INIT_EXIT_CODE=$?

# Verification checkpoint: Ensure exports succeeded
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not exported" 1
fi

if [ -z "${RESEARCH_COMPLEXITY:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_COMPLEXITY not exported" 1
fi

if [ -z "${RESEARCH_TOPICS_JSON:-}" ]; then
  handle_state_error "CRITICAL: RESEARCH_TOPICS_JSON not exported" 1
fi

# Save to workflow state for bash block persistence
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"
append_workflow_state "RESEARCH_COMPLEXITY" "$RESEARCH_COMPLEXITY"
append_workflow_state "RESEARCH_TOPICS_JSON" "$RESEARCH_TOPICS_JSON"
```

**Key Pattern**:
1. `sm_init()` performs classification and exports to bash env
2. Verification checkpoints confirm exports succeeded
3. `append_workflow_state()` persists to state file
4. **NO checkpoint save at this point** (no checkpoint created yet)

**Coordination Gap**:
- State file has classification metadata
- Bash process memory has classification metadata
- Checkpoint does NOT have classification metadata
- If workflow fails before first checkpoint save, resume is impossible

### State Transition Dependencies on Classification

**Terminal State Calculation** (workflow-state-machine.sh:442-463):

```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    TERMINAL_STATE="$STATE_RESEARCH"
    ;;
  research-and-plan)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  research-and-revise)
    TERMINAL_STATE="$STATE_PLAN"
    ;;
  full-implementation)
    TERMINAL_STATE="$STATE_COMPLETE"
    ;;
  debug-only)
    TERMINAL_STATE="$STATE_DEBUG"
    ;;
esac
```

**Critical Dependency**: Terminal state depends on `WORKFLOW_SCOPE` classification result.

**Dynamic Path Allocation** (coordinate.md:266-298):

```bash
# initialize_workflow_paths uses RESEARCH_COMPLEXITY
if initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"; then
  : # Success - paths initialized with dynamic allocation
fi

# Allocate report paths based on research_complexity
# REPORT_PATHS_COUNT = RESEARCH_COMPLEXITY
```

**Critical Dependency**: Report path allocation depends on `RESEARCH_COMPLEXITY`.

**Research Phase Execution** (coordinate.md Phase 1):

Research supervisor receives topics from `RESEARCH_TOPICS_JSON`:
```bash
# Extract topics from RESEARCH_TOPICS_JSON
TOPICS=$(echo "$RESEARCH_TOPICS_JSON" | jq -r '.[]')

# Invoke research agents (one per topic)
for topic in $TOPICS; do
  # Task invocation with topic context
done
```

**Critical Dependency**: Research agent invocations depend on `RESEARCH_TOPICS_JSON` structure.

### Atomic Coordination Requirements

**Current State Transition Pattern** (workflow-state-machine.sh:570-615):

```bash
sm_transition() {
  local next_state="$1"

  # Phase 1: Validate transition
  if ! echo ",$valid_transitions," | grep -q ",$next_state,"; then
    return 1
  fi

  # Phase 2: Pre-transition checkpoint (placeholder)
  echo "DEBUG: Pre-transition checkpoint (state=$CURRENT_STATE → $next_state)"

  # Phase 3: Update state
  CURRENT_STATE="$next_state"
  COMPLETED_STATES+=("$next_state")

  # Phase 4: Post-transition checkpoint (placeholder)
  echo "DEBUG: Post-transition checkpoint (state=$CURRENT_STATE)"

  # Persist completed states to workflow state (Spec 672 Phase 2)
  save_completed_states_to_state || true
}
```

**Coordination Gaps**:
1. Pre/post checkpoint logic is placeholder only (DEBUG messages)
2. No integration with `checkpoint-utils.sh::save_checkpoint()`
3. No atomic coordination between state file and checkpoint file
4. Classification metadata not included in transition checkpoints

**Required Atomicity Properties**:

For proper coordination, state transitions need:
1. **Atomic writes**: State file + checkpoint file updated together
2. **Rollback capability**: Failed transition reverts both files
3. **Metadata consistency**: Classification results same in state and checkpoint
4. **Resume integrity**: Checkpoint restore must restore classification metadata

### Checkpoint Resume Scenarios

**Scenario 1: Failure During Research Phase**

Current behavior:
1. `sm_init()` classifies workflow → exports to bash env
2. Classification saved to state file
3. Research phase starts
4. **Failure occurs before first checkpoint save**
5. No checkpoint exists → cannot resume

Expected behavior:
1. `sm_init()` classifies workflow
2. **Immediate checkpoint with classification metadata**
3. Research phase starts
4. Failure occurs
5. Resume loads checkpoint → restores classification metadata

**Scenario 2: Checkpoint Resume After Classification**

Current behavior:
1. Checkpoint exists (created during Phase 2: Plan)
2. `restore_checkpoint()` loads checkpoint
3. `sm_load()` extracts `WORKFLOW_SCOPE` only
4. **RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON are NOT restored**
5. Dynamic path allocation uses wrong values (defaults or re-classification)

Expected behavior:
1. Checkpoint exists with full classification metadata
2. `restore_checkpoint()` loads checkpoint
3. `sm_load()` extracts all classification fields
4. State machine fully restored with correct paths

**Scenario 3: Plan File Modified During Resume**

Current behavior (checkpoint-utils.sh:825-834):
```bash
check_safe_resume_conditions() {
  # Check if plan file modified since checkpoint
  if [ "$plan_modification_time" != "null" ]; then
    local current_plan_mtime=$(stat "$plan_path")
    if [ "$current_plan_mtime" != "$plan_modification_time" ]; then
      return 1  # Cannot auto-resume
    fi
  fi
}
```

Classification impact:
- Plan modification invalidates checkpoint
- Resume requires re-classification
- **But classification might return different results** (workflow description unchanged but plan content changed)
- Need to decide: Trust checkpoint classification or re-classify?

### Gap Analysis Summary

**Missing Checkpoint Schema Fields**:
1. `research_complexity` (integer 1-4)
2. `research_topics` (array of enhanced topic objects)
3. `classification_confidence` (float 0.0-1.0)
4. `classification_reasoning` (string)
5. `classification_timestamp` (ISO 8601)

**Missing Integration Functions**:
1. `save_checkpoint_with_classification()` - Save checkpoint including classification
2. `restore_classification_from_checkpoint()` - Extract classification from checkpoint
3. `validate_classification_consistency()` - Compare state file vs checkpoint classification

**Missing Coordination Logic**:
1. Atomic write coordination (state file + checkpoint file)
2. Two-phase commit for state transitions
3. Rollback mechanism for failed transitions
4. Classification metadata merge during migration (v2.0 → v2.1)

## Recommendations

### 1. Extend Checkpoint Schema to v2.1 with Classification Metadata

**Add classification section to checkpoint schema**:

```json
{
  "schema_version": "2.1",
  "state_machine": {
    "current_state": "research",
    "completed_states": ["initialize"],
    "workflow_config": {
      "scope": "full-implementation",
      "description": "Add user authentication",
      "command": "coordinate"
    },
    "classification": {
      "workflow_type": "full-implementation",
      "research_complexity": 2,
      "research_topics": [
        {
          "short_name": "Authentication patterns",
          "detailed_description": "Analyze current authentication...",
          "filename_slug": "authentication_patterns",
          "research_focus": "Key questions: How is auth handled?"
        }
      ],
      "confidence": 0.95,
      "reasoning": "Workflow requires...",
      "classified_at": "2025-11-14T14:30:00Z"
    }
  }
}
```

**Migration path (v2.0 → v2.1)**:
- Preserve existing v2.0 checkpoints (backward compatible)
- Add classification section with defaults for old checkpoints
- Use workflow description to re-classify if needed

**Implementation location**: `checkpoint-utils.sh::save_checkpoint()` (lines 58-186)

### 2. Add Classification Save/Restore Functions to State Machine Library

**New function: sm_save_with_classification()**

```bash
sm_save_with_classification() {
  local checkpoint_file="$1"

  # Build classification section from current exports
  local classification_json
  classification_json=$(jq -n \
    --arg workflow_type "$WORKFLOW_SCOPE" \
    --argjson research_complexity "$RESEARCH_COMPLEXITY" \
    --argjson research_topics "$RESEARCH_TOPICS_JSON" \
    --arg classified_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      workflow_type: $workflow_type,
      research_complexity: ($research_complexity | tonumber),
      research_topics: $research_topics,
      confidence: 0.95,
      reasoning: "Loaded from checkpoint",
      classified_at: $classified_at
    }')

  # Merge into state machine JSON
  state_machine_json=$(jq -n \
    --argjson classification "$classification_json" \
    --arg current_state "$CURRENT_STATE" \
    # ... existing fields ...
    '{
      current_state: $current_state,
      classification: $classification,
      workflow_config: {...}
    }')

  echo "$state_machine_json" > "$checkpoint_file"
}
```

**New function: sm_load_with_classification()**

```bash
sm_load_with_classification() {
  local checkpoint_file="$1"

  # Load v2.1 checkpoint with classification
  WORKFLOW_SCOPE=$(jq -r '.state_machine.classification.workflow_type' "$checkpoint_file")
  RESEARCH_COMPLEXITY=$(jq -r '.state_machine.classification.research_complexity' "$checkpoint_file")
  RESEARCH_TOPICS_JSON=$(jq -c '.state_machine.classification.research_topics' "$checkpoint_file")

  # Export to bash environment
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON

  # Set terminal state from classification
  case "$WORKFLOW_SCOPE" in
    research-only) TERMINAL_STATE="$STATE_RESEARCH" ;;
    # ... other cases
  esac
}
```

**Implementation location**: `workflow-state-machine.sh` (after line 768)

### 3. Implement Atomic Checkpoint Coordination in sm_transition()

**Replace placeholder checkpoint logic with atomic coordination**:

```bash
sm_transition() {
  local next_state="$1"

  # Phase 1: Validate transition
  if ! validate_transition "$CURRENT_STATE" "$next_state"; then
    return 1
  fi

  # Phase 2: Pre-transition checkpoint (atomic save)
  local pre_checkpoint_file="${CHECKPOINT_DIR}/pre_transition_${next_state}.json"
  if ! sm_save_with_classification "$pre_checkpoint_file"; then
    echo "ERROR: Pre-transition checkpoint failed" >&2
    return 1
  fi

  # Phase 3: Update state (in-memory only, not persisted yet)
  local old_state="$CURRENT_STATE"
  CURRENT_STATE="$next_state"
  COMPLETED_STATES+=("$next_state")

  # Phase 4: Persist to state file
  if ! append_workflow_state "CURRENT_STATE" "$CURRENT_STATE"; then
    # Rollback in-memory state
    CURRENT_STATE="$old_state"
    unset 'COMPLETED_STATES[-1]'
    echo "ERROR: State file update failed, rolled back" >&2
    return 1
  fi

  # Phase 5: Post-transition checkpoint (atomic save)
  local post_checkpoint_file="${CHECKPOINT_DIR}/post_transition_${next_state}.json"
  if ! sm_save_with_classification "$post_checkpoint_file"; then
    echo "WARNING: Post-transition checkpoint failed (state updated)" >&2
    # Continue - state file updated successfully
  fi

  # Phase 6: Cleanup pre-transition checkpoint
  rm -f "$pre_checkpoint_file"

  echo "State transition: $old_state → $CURRENT_STATE (atomic)" >&2
}
```

**Key properties**:
- Pre-transition checkpoint captures state before change
- State file update is atomic (append operation)
- Rollback on failure restores in-memory state
- Post-transition checkpoint captures final state
- Pre-checkpoint cleanup only after successful transition

**Implementation location**: `workflow-state-machine.sh::sm_transition()` (lines 570-615)

### 4. Add Early Checkpoint Save After sm_init()

**Coordinate.md modification (after line 188)**:

```bash
# Verify state machine variables
echo "✓ State machine variables verified: WORKFLOW_SCOPE=$WORKFLOW_SCOPE, RESEARCH_COMPLEXITY=$RESEARCH_COMPLEXITY"

# ADDED: Save initial checkpoint with classification metadata (Spec XXX Phase X)
# This enables resume even if workflow fails during Phase 0 or early Phase 1
INITIAL_CHECKPOINT_FILE=$(save_checkpoint "coordinate" "$(basename "$TOPIC_PATH")" \
  "$(jq -n \
    --arg workflow_desc "$SAVED_WORKFLOW_DESC" \
    --arg scope "$WORKFLOW_SCOPE" \
    --argjson complexity "$RESEARCH_COMPLEXITY" \
    --argjson topics "$RESEARCH_TOPICS_JSON" \
    '{
      workflow_description: $workflow_desc,
      workflow_scope: $scope,
      research_complexity: $complexity,
      research_topics: $topics,
      current_state: "initialize",
      status: "in_progress"
    }')")

echo "✓ Initial checkpoint saved: $INITIAL_CHECKPOINT_FILE"

# Save checkpoint path to workflow state
append_workflow_state "CHECKPOINT_FILE" "$INITIAL_CHECKPOINT_FILE"
```

**Benefit**: Immediate checkpoint creation after classification enables resume even during early phases.

**Implementation location**: All orchestration commands (coordinate.md, orchestrate.md, supervise.md)

### 5. Validate Classification Consistency During Checkpoint Restore

**New function: validate_classification_consistency()**

```bash
validate_classification_consistency() {
  local checkpoint_file="$1"
  local state_file="$2"

  # Extract classification from checkpoint
  local checkpoint_scope checkpoint_complexity
  checkpoint_scope=$(jq -r '.state_machine.classification.workflow_type' "$checkpoint_file")
  checkpoint_complexity=$(jq -r '.state_machine.classification.research_complexity' "$checkpoint_file")

  # Extract classification from state file (if exists)
  source "$state_file"
  local state_scope="${WORKFLOW_SCOPE:-}"
  local state_complexity="${RESEARCH_COMPLEXITY:-}"

  # Compare values
  if [ -n "$state_scope" ] && [ "$checkpoint_scope" != "$state_scope" ]; then
    echo "WARNING: Classification mismatch: checkpoint=$checkpoint_scope, state=$state_scope" >&2
    echo "  Using checkpoint value as source of truth" >&2
  fi

  if [ -n "$state_complexity" ] && [ "$checkpoint_complexity" != "$state_complexity" ]; then
    echo "WARNING: Complexity mismatch: checkpoint=$checkpoint_complexity, state=$state_complexity" >&2
    echo "  Using checkpoint value as source of truth" >&2
  fi

  # Return checkpoint values as authoritative
  export WORKFLOW_SCOPE="$checkpoint_scope"
  export RESEARCH_COMPLEXITY="$checkpoint_complexity"

  return 0
}
```

**Usage in resume flow**:

```bash
# Load checkpoint
CHECKPOINT_JSON=$(restore_checkpoint "coordinate" "$project_name")

# Validate consistency with state file
validate_classification_consistency "$CHECKPOINT_FILE" "$STATE_FILE"

# Use validated classification for resume
sm_load_with_classification "$CHECKPOINT_FILE"
```

**Implementation location**: `checkpoint-utils.sh` (new utility function section)

## References

- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:23-152` - Checkpoint schema v2.0 definition
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:389-472` - v1.3 → v2.0 migration logic
- `/home/benjamin/.config/.claude/lib/state-persistence.sh:1-393` - GitHub Actions-style state persistence
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:334-476` - sm_init() classification integration
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:570-615` - sm_transition() coordination
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:698-768` - sm_save() checkpoint creation
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:478-559` - sm_load() checkpoint restoration
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh:86-204` - LLM classification output format
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh:384-474` - Enhanced topic validation
- `/home/benjamin/.config/.claude/commands/coordinate.md:164-286` - Classification persistence pattern
- `/home/benjamin/.config/.claude/commands/coordinate.md:285-286` - append_workflow_state integration
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh:825-834` - Safe resume condition checks
