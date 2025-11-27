# State-Based Orchestration: Transitions and Persistence

**Related Documents**:
- [Overview](state-orchestration-overview.md) - Architecture summary
- [States](state-orchestration-states.md) - State definitions
- [Examples](state-orchestration-examples.md) - Reference implementations

---

## State Transitions

State transitions are validated operations that move the workflow from one state to another while updating persistence.

## Transition API

### Basic Transition

```bash
# Transition with validation
if ! sm_transition "research" "planning"; then
  echo "ERROR: Invalid transition"
  exit 1
fi
```

### Transition with Checkpoint

```bash
# Transition and save checkpoint
sm_transition_with_checkpoint "research" "planning" '{
  "research_reports": ["/path/to/report1.md"]
}'
```

### Conditional Transition

```bash
# Transition based on condition
if [ "$TEST_STATUS" = "pass" ]; then
  sm_transition "testing" "documentation"
else
  sm_transition "testing" "debug"
fi
```

### Idempotent Transition (Same-State)

```bash
# Safe to call even if already in target state
sm_transition "$STATE_RESEARCH"
# If already in research state: logs INFO message, returns success (exit 0)
# If not in research state: performs normal transition

# Useful for retry/resume scenarios
for attempt in 1 2 3; do
  sm_transition "$STATE_IMPLEMENT"  # Idempotent on subsequent attempts
  if run_implementation; then
    break
  fi
done
```

## Selective State Persistence

### Persistence Library

```bash
source "${LIB_DIR}/state-persistence.sh"

# Initialize state file
init_workflow_state "$WORKFLOW_ID"

# Append state variable
append_workflow_state "PLAN_PATH" "$PLAN_PATH"

# Load state variable
PLAN=$(load_workflow_state "PLAN_PATH")
```

### What to Persist

| Item | Persist | Reason |
|------|---------|--------|
| WORKFLOW_SCOPE | Yes | Classification result (network call) |
| TOPIC_PATH | Yes | Artifact location |
| PLAN_PATH | Yes | Created artifact |
| REPORT_PATHS | Yes | Created artifacts |
| CURRENT_WAVE | Yes | Resume point |
| thinking_mode | No | Recalculable from scope |
| progress_markers | No | Transient state |

### Persistence Format

GitHub Actions-style workflow state file:

```bash
# .claude/tmp/workflow_<id>.sh
WORKFLOW_ID=abc123
WORKFLOW_SCOPE=standard
TOPIC_PATH=/path/to/specs/042_feature
PLAN_PATH=/path/to/specs/042_feature/plans/001.md
REPORT_PATHS=["/path/to/report1.md","/path/to/report2.md"]
CURRENT_STATE=implementation
CURRENT_WAVE=2
```

### State File Operations

```bash
# Initialize
init_workflow_state() {
  local id="$1"
  STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${id}.sh"
  echo "WORKFLOW_ID=$id" > "$STATE_FILE"
}

# Append (thread-safe)
append_workflow_state() {
  local key="$1"
  local value="$2"
  echo "${key}=${value}" >> "$STATE_FILE"
}

# Load
load_workflow_state() {
  local key="$1"
  grep "^${key}=" "$STATE_FILE" | tail -1 | cut -d'=' -f2-
}
```

## Graceful Degradation

If state file unavailable, recalculate:

```bash
load_or_recalculate() {
  local key="$1"

  # Try loading from state
  value=$(load_workflow_state "$key" 2>/dev/null)

  if [ -z "$value" ]; then
    # Recalculate
    case "$key" in
      "WORKFLOW_SCOPE")
        value=$(classify_workflow "$WORKFLOW_DESC")
        ;;
      "thinking_mode")
        value=$(calculate_thinking_mode "$RESEARCH_COMPLEXITY")
        ;;
    esac
  fi

  echo "$value"
}
```

## Checkpoint Schema V2.0

### Schema Definition

```json
{
  "version": "2.0",
  "workflow_id": "uuid",
  "command": "coordinate|orchestrate|implement",
  "state": "current_state_name",
  "scope": "micro|focused|standard|comprehensive",
  "topic_path": "/absolute/path/to/topic",
  "phases": {
    "research": {
      "completed": true,
      "reports": ["/path/to/report1.md"],
      "metadata": {}
    },
    "planning": {
      "completed": false,
      "plan_path": null
    }
  },
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

### Checkpoint Operations

```bash
# Save checkpoint
save_checkpoint() {
  local command="$1"
  local data="$2"

  echo "$data" > ".claude/checkpoints/${command}.json"
}

# Load checkpoint
load_checkpoint() {
  local command="$1"

  if [ -f ".claude/checkpoints/${command}.json" ]; then
    cat ".claude/checkpoints/${command}.json"
  else
    return 1
  fi
}

# Update checkpoint
update_checkpoint() {
  local command="$1"
  local key="$2"
  local value="$3"

  jq --arg k "$key" --arg v "$value" '.[$k] = $v' \
    ".claude/checkpoints/${command}.json" > tmp && \
    mv tmp ".claude/checkpoints/${command}.json"
}
```

## Migration from Phase-Based

### Old Pattern (Phase-Based)

```bash
# Phase numbers
PHASE=1
do_research
((PHASE++))
do_planning
((PHASE++))
do_implementation
```

### New Pattern (State-Based)

```bash
# Named states
sm_init "$WORKFLOW_DESC" "coordinate"

sm_transition "initialize" "research"
do_research

sm_transition "research" "planning"
do_planning

sm_transition "planning" "implementation"
do_implementation
```

### Migration Steps

1. **Replace phase variables**
   ```bash
   # Old
   PHASE=1

   # New
   sm_init "$DESC" "$CMD"
   ```

2. **Replace phase increments**
   ```bash
   # Old
   ((PHASE++))

   # New
   sm_transition "from" "to"
   ```

3. **Replace checkpoint format**
   ```bash
   # Old
   echo "PHASE=$PHASE" > checkpoint

   # New
   save_checkpoint "$CMD" '{"state":"planning"}'
   ```

4. **Add state persistence**
   ```bash
   # Old
   (no persistence)

   # New
   append_workflow_state "PLAN_PATH" "$PLAN_PATH"
   ```

## Performance Characteristics

### State File I/O

| Operation | Time |
|-----------|------|
| init_workflow_state | 2ms |
| append_workflow_state | 1ms |
| load_workflow_state | 1ms |

### Comparison with Checkpoint

| Approach | Write | Read | Resume |
|----------|-------|------|--------|
| Full JSON | 10ms | 15ms | 15ms |
| State file | 1ms | 1ms | 5ms |

### Memory Usage

State file approach uses minimal memory:
- Parse on demand
- No JSON library required
- Append-only writes

---

## Related Documentation

- [Overview](state-orchestration-overview.md)
- [States](state-orchestration-states.md)
- [Examples](state-orchestration-examples.md)
- [Troubleshooting](state-orchestration-troubleshooting.md)
