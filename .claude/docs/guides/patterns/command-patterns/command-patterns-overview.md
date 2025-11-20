# Command Implementation Patterns: Overview

**Related Documents**:
- [Agent Patterns](command-patterns-agents.md) - Agent invocation and coordination
- [Checkpoint Patterns](command-patterns-checkpoints.md) - State and error handling
- [Integration Patterns](command-patterns-integration.md) - Testing and PR creation

---

## Purpose

This document provides reusable patterns and examples for implementing Claude Code commands. Commands should reference these patterns rather than duplicating documentation inline.

For command architecture standards, see [Architecture Standards](../reference/architecture/overview.md).

## Pattern Index

| Category | Document | Patterns |
|----------|----------|----------|
| Agent Patterns | [command-patterns-agents.md](command-patterns-agents.md) | Invocation, parallel execution, thinking modes |
| Checkpoint Patterns | [command-patterns-checkpoints.md](command-patterns-checkpoints.md) | State management, error recovery |
| Integration Patterns | [command-patterns-integration.md](command-patterns-integration.md) | Testing, PR creation, streaming |

---

## Quick Reference

### Agent Invocation

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Brief description"
  prompt: |
    Read and follow: .claude/agents/agent-name.md

    Context:
    - [field]: ${VALUE}

    Return: [SIGNAL]: /path/to/output
}
```

### Checkpoint Save

```bash
CHECKPOINT=$(cat <<EOF
{
  "phase": "$PHASE",
  "plan_path": "$PLAN_PATH",
  "completed": $COMPLETED
}
EOF
)

save_checkpoint "$WORKFLOW" "$CHECKPOINT"
```

### Checkpoint Load

```bash
if CHECKPOINT=$(load_checkpoint "$WORKFLOW"); then
  PHASE=$(echo "$CHECKPOINT" | jq -r '.phase')
  PLAN_PATH=$(echo "$CHECKPOINT" | jq -r '.plan_path')
fi
```

### Error Recovery

```bash
execute_with_retry() {
  local cmd="$1"
  local max=3
  local attempt=0

  while [ $attempt -lt $max ]; do
    ((attempt++))
    if eval "$cmd"; then
      return 0
    fi
    sleep 2
  done
  return 1
}
```

### Progress Streaming

```bash
emit_progress() {
  local phase="$1"
  local message="$2"

  echo "PROGRESS: [$phase] $message"
}

emit_progress "research" "Analyzing codebase..."
```

### Testing Integration

```bash
# Discover tests
discover_tests() {
  find .claude/tests -name "*_spec.lua" -o -name "test_*.sh"
}

# Run tests
run_tests() {
  local cmd=$(get_test_command)
  eval "$cmd"
}
```

### PR Creation

```bash
gh pr create \
  --title "feat: $TITLE" \
  --body "$(cat <<'EOF'
## Summary
$SUMMARY

## Test Plan
- [ ] Tests pass
- [ ] Reviewed

Generated with Claude Code
EOF
)"
```

---

## Pattern Guidelines

### When to Use Patterns

1. **Agent Invocation**: Any command that uses subagents
2. **Checkpoints**: Commands with multiple phases
3. **Error Recovery**: Operations that can fail
4. **Testing**: Commands that modify code
5. **Progress**: Long-running operations

### Pattern Composition

Patterns can be combined:

```bash
# Combine checkpoint + retry + progress
execute_phase_with_recovery() {
  local phase="$1"

  emit_progress "$phase" "Starting..."

  if ! execute_with_retry "run_phase $phase"; then
    emit_progress "$phase" "Failed, saving checkpoint"
    save_checkpoint "$WORKFLOW" "$(get_state)"
    return 1
  fi

  emit_progress "$phase" "Complete"
}
```

### Pattern Selection

| Task | Pattern |
|------|---------|
| Invoke agent | Basic Agent Invocation |
| Parallel agents | Parallel Execution |
| Resume workflow | Checkpoint Management |
| Handle failures | Error Recovery |
| Run tests | Testing Integration |
| Create PR | PR Creation |

---

## Related Documentation

- [Agent Patterns](command-patterns-agents.md)
- [Checkpoint Patterns](command-patterns-checkpoints.md)
- [Integration Patterns](command-patterns-integration.md)
- [Architecture Standards](../reference/architecture/overview.md)
