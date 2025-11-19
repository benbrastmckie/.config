# Hierarchical Agent Architecture: Patterns

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Coordination](hierarchical-agents-coordination.md) - Multi-agent coordination
- [Examples](hierarchical-agents-examples.md) - Reference implementations

---

## Design Patterns

### Pattern 1: Supervisor-Worker

**Use When**: Multiple agents perform similar tasks in parallel

**Structure**:
```
Supervisor
    +-- Worker 1
    +-- Worker 2
    +-- Worker 3
```

**Implementation**:
```yaml
# Supervisor invokes workers
Task {
  description: "Research supervisor"
  prompt: |
    You are a research supervisor coordinating 3 workers.

    **STEP 1**: Invoke workers in parallel
    **STEP 2**: Collect results
    **STEP 3**: Aggregate metadata

    Topics: auth, logging, errors
    Output Dir: /path/to/reports/
}
```

### Pattern 2: Pipeline

**Use When**: Sequential processing with handoffs

**Structure**:
```
Stage 1 -> Stage 2 -> Stage 3
  |          |          |
Research   Planning   Implementation
```

**Implementation**:
```markdown
## Phase 1: Research
[Invoke research agents]

## Phase 2: Planning (depends on Phase 1)
**Context**: Use metadata from Phase 1
[Invoke planning agent]

## Phase 3: Implementation (depends on Phase 2)
**Context**: Use plan from Phase 2
[Invoke implementation agents]
```

### Pattern 3: Fan-Out/Fan-In

**Use When**: Parallel work followed by aggregation

**Structure**:
```
    Orchestrator
        |
   +----+----+
   |    |    |
  W1   W2   W3
   |    |    |
   +----+----+
        |
    Aggregator
```

**Implementation**:
```markdown
## Fan-Out
Invoke workers in parallel for each topic.

## Fan-In
Aggregate all results into summary document.
```

### Pattern 4: Hierarchical Delegation

**Use When**: Complex workflows with multiple hierarchy levels

**Structure**:
```
Orchestrator
    |
    +-- Research Supervisor
    |       +-- Worker 1
    |       +-- Worker 2
    |
    +-- Implementation Supervisor
            +-- Worker 3
            +-- Worker 4
```

## Anti-Patterns

### Anti-Pattern 1: Context Explosion

**Problem**: Passing full outputs up hierarchy

```yaml
# WRONG: Passing full content
"Here are the complete research reports:
[2,500 tokens from worker 1]
[2,500 tokens from worker 2]
..."

# CORRECT: Passing metadata only
"Research completed:
- auth_report.md: 15 patterns found
- logging_report.md: 8 patterns found"
```

### Anti-Pattern 2: Behavioral Duplication

**Problem**: Duplicating agent behavior in commands

```yaml
# WRONG: 200 lines of behavior inline
Task {
  prompt: |
    You are a research specialist.
    [180 lines of behavioral instructions]
    Topic: ${topic}
}

# CORRECT: Reference + context
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${topic}
}
```

### Anti-Pattern 3: Missing Verification

**Problem**: Not verifying agent outputs

```bash
# WRONG: Trust agent output
RESULT=$(invoke_agent)
use_result "$RESULT"

# CORRECT: Verify before using
RESULT=$(invoke_agent)
if [ ! -f "$EXPECTED_PATH" ]; then
  echo "CRITICAL: Agent didn't create file"
  exit 1
fi
use_result "$RESULT"
```

### Anti-Pattern 4: Serial Invocation

**Problem**: Invoking parallel agents sequentially

```markdown
# WRONG: Sequential invocation
**EXECUTE**: Task 1
[wait]
**EXECUTE**: Task 2
[wait]
**EXECUTE**: Task 3

# CORRECT: Parallel invocation
**EXECUTE NOW**: All tasks in single message

Task { ... topic 1 ... }
Task { ... topic 2 ... }
Task { ... topic 3 ... }
```

## Best Practices

### 1. Pre-Calculate Everything

Calculate all paths and assignments before invoking agents:

```bash
# Phase 0: Pre-calculate
for topic in "${TOPICS[@]}"; do
  PATHS["$topic"]=$(calculate_path "$topic")
done

# Phase 1: Invoke with pre-calculated context
for topic in "${TOPICS[@]}"; do
  invoke_agent "$topic" "${PATHS[$topic]}"
done
```

### 2. Define Clear Contracts

Specify exact input/output formats:

```markdown
## Input Contract
- topic: string (research topic)
- output_path: string (absolute path)
- thinking_mode: enum (standard|think|think_hard)

## Output Contract
- CREATED: string (file path)
- TITLE: string (50 chars max)
- SUMMARY: string (200 chars max)
```

### 3. Use Verification Checkpoints

Verify at each hierarchy level:

```bash
# After workers complete
verify_worker_outputs() {
  for path in "${EXPECTED[@]}"; do
    [ -f "$path" ] || exit 1
  done
}

# After supervisor completes
verify_supervisor_aggregation() {
  [ -n "$METADATA" ] || exit 1
  [ $(echo "$METADATA" | jq length) -eq $WORKER_COUNT ] || exit 1
}
```

### 4. Handle Failures Gracefully

```bash
# Invoke with timeout
if ! timeout 300 invoke_agent; then
  echo "ERROR: Agent timeout"
  # Decide: retry or fail workflow
fi

# Verify output
if [ ! -f "$OUTPUT" ]; then
  echo "ERROR: Missing output"
  # Decide: retry or use fallback
fi
```

### 5. Maintain Single Source of Truth

All agent behavior in `.claude/agents/*.md`:

```
.claude/agents/
    research-specialist.md   # Research behavior
    plan-architect.md        # Planning behavior
    implementation-agent.md  # Implementation behavior
    test-specialist.md       # Testing behavior
```

Commands reference these files, never duplicate content.

## Performance Optimization

### Context Efficiency

| Approach | Context Per Worker | Total (4 workers) |
|----------|-------------------|-------------------|
| Full duplication | 2,500 | 10,000 |
| Metadata only | 110 | 440 |
| **Savings** | | **95.6%** |

### Parallel Execution

| Approach | Time (4 workers) |
|----------|------------------|
| Sequential | 4 x T |
| Parallel | T + overhead |
| **Savings** | **60-75%** |

### Thinking Mode Allocation

Reserve thinking budget for complexity:

```
Simple workers: standard (0 extra tokens)
Complex supervisor: think hard (+2,000 tokens)
Critical orchestrator decisions: think harder (+4,000)
```

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Coordination](hierarchical-agents-coordination.md)
- [Examples](hierarchical-agents-examples.md)
- [Troubleshooting](hierarchical-agents-troubleshooting.md)
