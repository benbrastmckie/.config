# State-Based Orchestration: Troubleshooting

**Related Documents**:
- [Overview](state-orchestration-overview.md) - Architecture summary
- [States](state-orchestration-states.md) - State definitions
- [Transitions](state-orchestration-transitions.md) - State transitions

---

## Common Issues

### Issue 1: sm_init Returns Error

**Symptom**: State machine initialization fails.

**Causes**:
1. Library not sourced
2. Invalid workflow description
3. Classification network failure

**Solution**:
```bash
# Ensure libraries sourced
source "${LIB_DIR}/workflow-state-machine.sh"
source "${LIB_DIR}/state-persistence.sh"

# Check error handling
if ! sm_init "$WORKFLOW_DESC" "coordinate" 2>&1; then
  handle_state_error "sm_init failed" 1
fi

# Verify exports
if [ -z "${WORKFLOW_SCOPE:-}" ]; then
  echo "CRITICAL: WORKFLOW_SCOPE not exported"
  exit 1
fi
```

---

### Issue 2: Invalid State Transition

**Symptom**: `sm_transition` returns error.

**Cause**: Attempting invalid transition.

**Solution**:
```bash
# Check valid transitions
echo "Valid from 'testing': ${VALID_TRANSITIONS[testing]}"

# Use correct transition
if [ "$TEST_STATUS" = "pass" ]; then
  sm_transition "testing" "documentation"  # Valid
else
  sm_transition "testing" "debug"  # Valid
fi

# NOT: sm_transition "testing" "complete"  # Invalid
```

---

### Issue 3: State File Not Found

**Symptom**: Cannot resume workflow.

**Cause**: State file deleted or not created.

**Solution**:
```bash
# Check if state file exists
STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${ID}.sh"

if [ ! -f "$STATE_FILE" ]; then
  echo "State file not found, starting fresh"
  sm_init "$WORKFLOW_DESC" "coordinate"
  init_workflow_state "$ID"
fi
```

---

### Issue 4: Corrupt State File

**Symptom**: Cannot parse state values.

**Cause**: Incomplete writes or manual edits.

**Solution**:
```bash
# Validate state file
validate_state_file() {
  local file="$1"

  # Check required keys
  for key in WORKFLOW_ID WORKFLOW_SCOPE CURRENT_STATE; do
    if ! grep -q "^${key}=" "$file"; then
      echo "WARN: Missing $key"
      return 1
    fi
  done

  return 0
}

# Rebuild if corrupt
if ! validate_state_file "$STATE_FILE"; then
  echo "Rebuilding state file"
  sm_init "$WORKFLOW_DESC" "coordinate"
fi
```

---

### Issue 5: Variables Not Exported

**Symptom**: Empty variables after sm_init.

**Cause**: Function scope issues.

**Solution**:
```bash
# sm_init should export variables
sm_init() {
  # ...
  export WORKFLOW_SCOPE
  export RESEARCH_COMPLEXITY
  export RESEARCH_TOPICS_JSON
}

# Verify after call
sm_init "$DESC" "$CMD"
echo "WORKFLOW_SCOPE=${WORKFLOW_SCOPE:-EMPTY}"
```

---

### Issue 6: Context Not Passed to Supervisor

**Symptom**: Supervisor doesn't receive topics.

**Cause**: Missing context in Task prompt.

**Solution**:
```yaml
Task {
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    # Must include context
    Topics:
    - topic: "auth", path: "${PATH_1}"
    - topic: "security", path: "${PATH_2}"
}
```

---

## Diagnostic Commands

### Check Current State

```bash
# From state file
CURRENT=$(load_workflow_state "CURRENT_STATE")
echo "Current state: $CURRENT"

# From checkpoint
jq -r '.state' ".claude/checkpoints/coordinate.json"
```

### Verify State Machine

```bash
# Run state machine tests
bash .claude/tests/test_workflow_state_machine.sh

# Check all states valid
for state in initialize research planning implementation testing debug documentation complete; do
  if sm_is_valid_state "$state"; then
    echo "Valid: $state"
  else
    echo "Invalid: $state"
  fi
done
```

### Check Persistence

```bash
# List state files
ls -la .claude/tmp/workflow_*.sh

# Show state file contents
cat "${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${ID}.sh"

# Check specific value
load_workflow_state "PLAN_PATH"
```

### Debug Transitions

```bash
# Enable verbose mode
set -x

# Trace transition
sm_transition "research" "planning"

set +x
```

---

## Error Messages

### "Invalid transition from X to Y"

**Cause**: Attempted invalid state change.

**Fix**: Check valid transitions table.

### "State file not found"

**Cause**: State file deleted or not initialized.

**Fix**: Initialize state file with `init_workflow_state`.

### "WORKFLOW_SCOPE not exported"

**Cause**: sm_init failed or didn't export.

**Fix**: Check sm_init return code and add verification.

### "Classification failed"

**Cause**: Network error during classification.

**Fix**: Add retry logic or use fallback classification.

---

## Recovery Procedures

### Manual State Reset

```bash
# Reset to specific state
echo "CURRENT_STATE=planning" >> "$STATE_FILE"

# Clear and restart
rm -f "$STATE_FILE"
sm_init "$WORKFLOW_DESC" "coordinate"
```

### Skip Failed Phase

```bash
# Mark phase complete manually
append_workflow_state "CURRENT_STATE" "testing"
append_workflow_state "COMPLETED_PHASES" '["Phase 1","Phase 2","Phase 3"]'
```

### Rebuild Checkpoint

```bash
# Create new checkpoint from state
CHECKPOINT=$(cat <<EOF
{
  "state": "$(load_workflow_state CURRENT_STATE)",
  "scope": "$(load_workflow_state WORKFLOW_SCOPE)",
  "plan_path": "$(load_workflow_state PLAN_PATH)"
}
EOF
)

save_checkpoint "coordinate" "$CHECKPOINT"
```

---

## Performance Issues

### Slow State Operations

**Cause**: State file too large.

**Fix**: Clean up old state files.
```bash
# Remove old state files
find .claude/tmp -name "workflow_*.sh" -mtime +7 -delete
```

### Context Overflow

**Cause**: Not using metadata extraction.

**Fix**: Use supervisor pattern for 4+ agents.

---

## Testing State Machine

### Unit Tests

```bash
# Run state machine tests
bash .claude/tests/test_workflow_state_machine.sh

# Expected: 50 tests passing
```

### Integration Tests

```bash
# Test full workflow
bash .claude/tests/test_orchestrate_workflow.sh

# Test resume capability
bash .claude/tests/test_workflow_resume.sh
```

---

## Related Documentation

- [Overview](state-orchestration-overview.md)
- [States](state-orchestration-states.md)
- [Transitions](state-orchestration-transitions.md)
- [Examples](state-orchestration-examples.md)
