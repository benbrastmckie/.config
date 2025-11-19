# Hierarchical Agent Architecture: Coordination

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Communication](hierarchical-agents-communication.md) - Agent communication protocols
- [Patterns](hierarchical-agents-patterns.md) - Design patterns

---

## Multi-Agent Coordination Patterns

### Wave-Based Parallel Execution

Organize agents into waves based on dependencies:

```
Wave 1 (Parallel):
  - Research Agent: Authentication patterns
  - Research Agent: Error handling patterns
  - Research Agent: Logging patterns

Wave 2 (After Wave 1):
  - Plan Architect: Create implementation plan

Wave 3 (Parallel):
  - Implementation Agent: Module A
  - Implementation Agent: Module B
  - Test Agent: Integration tests
```

### Dependency Declaration

Use phase dependencies in plans to enable parallel execution:

```yaml
phases:
  - name: "Research Authentication"
    dependencies: []
  - name: "Research Logging"
    dependencies: []
  - name: "Create Plan"
    dependencies: ["Research Authentication", "Research Logging"]
  - name: "Implement Auth"
    dependencies: ["Create Plan"]
  - name: "Implement Logging"
    dependencies: ["Create Plan"]
```

### Supervisor Coordination Protocol

Supervisors coordinate workers using this protocol:

```markdown
## Coordination Protocol

### STEP 1: Parse Assignments
Extract worker tasks from orchestrator context.

### STEP 2: Pre-Calculate Paths
Calculate output paths for all workers BEFORE invocation.

### STEP 3: Invoke Workers (Parallel)
**CRITICAL**: Send ALL Task invocations in SINGLE message.

### STEP 4: Verify Completions
Check all workers completed successfully.

### STEP 5: Extract Metadata
Extract summary from each worker output.

### STEP 6: Return Aggregation
Return combined metadata to orchestrator.
```

## Context Management

### Pre-Calculation Pattern

Always pre-calculate paths before invoking agents:

```bash
# Phase 0: Pre-calculate all paths
source "${LIB_DIR}/artifact-creation.sh"

TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW_DESC" ".claude/specs")

declare -A REPORT_PATHS
for topic in "${TOPICS[@]}"; do
  REPORT_PATHS["$topic"]=$(create_topic_artifact "$TOPIC_DIR" "reports" "$topic" "")
done

export TOPIC_DIR REPORT_PATHS
```

### Context Injection

Inject pre-calculated context into agent prompts:

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Pre-Calculated Context**:
    - Output Path: ${REPORT_PATHS[$topic]}
    - Topic Directory: ${TOPIC_DIR}
    - Project Standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md
}
```

### Metadata Extraction

Extract only essential information from worker outputs:

```bash
# From supervisor output, extract metadata only
extract_worker_metadata() {
  local worker_output="$1"

  # Extract key fields
  TITLE=$(echo "$worker_output" | grep -oP 'TITLE:\s*\K.+')
  PATH=$(echo "$worker_output" | grep -oP 'CREATED:\s*\K.+')
  SUMMARY=$(echo "$worker_output" | grep -oP 'SUMMARY:\s*\K.+' | head -c 200)

  # Return metadata object
  cat <<EOF
{
  "title": "$TITLE",
  "path": "$PATH",
  "summary": "$SUMMARY"
}
EOF
}
```

## Cross-Agent Dependencies

### Input/Output Contracts

Define clear contracts between agents:

```markdown
## Research Agent Output Contract

**Required Fields**:
- CREATED: /absolute/path/to/report.md
- TITLE: Report title (50 chars max)
- SUMMARY: Key findings (200 chars max)

**File Structure**:
- ## Overview (required)
- ## Findings (required)
- ## Recommendations (required)
```

### Verification Checkpoints

Verify agent outputs at each level:

```bash
# Orchestrator verifies supervisor output
for topic in "${!EXPECTED_PATHS[@]}"; do
  EXPECTED="${EXPECTED_PATHS[$topic]}"

  if [ ! -f "$EXPECTED" ]; then
    echo "CRITICAL: Missing report at $EXPECTED"
    exit 1
  fi

  # Verify required sections
  if ! grep -q "## Findings" "$EXPECTED"; then
    echo "WARNING: Missing Findings section in $EXPECTED"
  fi
done
```

## Parallel Execution Strategies

### All-At-Once Pattern

For independent tasks, invoke all in single message:

```markdown
**EXECUTE NOW**: Invoke all research agents in parallel

Task {
  subagent_type: "general-purpose"
  description: "Research topic 1"
  prompt: "..."
}

Task {
  subagent_type: "general-purpose"
  description: "Research topic 2"
  prompt: "..."
}

Task {
  subagent_type: "general-purpose"
  description: "Research topic 3"
  prompt: "..."
}
```

### Wave-Based Pattern

For dependencies, use waves:

```markdown
## Wave 1

**EXECUTE NOW**: Invoke research agents

[Task invocations for research]

**VERIFICATION**: Wait for all research to complete

## Wave 2

**EXECUTE NOW**: Invoke planning agent with research outputs

[Task invocation using research metadata]
```

## Resource Management

### Context Budget Allocation

```
Total Context Budget: 100,000 tokens

Allocation:
- Command/Orchestrator: 30,000 tokens
- Per-Supervisor: 20,000 tokens
- Per-Worker: 10,000 tokens

With 4 workers per supervisor:
- Orchestrator: 30,000
- Supervisor: 20,000
- 4 Workers: 40,000
- Reserve: 10,000
```

### Thinking Mode Selection

Allocate thinking based on complexity:

| Complexity | Mode | Tokens |
|------------|------|--------|
| Simple | standard | +0 |
| Moderate | think | +1,000 |
| High | think hard | +2,000 |
| Critical | think harder | +4,000 |

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Communication](hierarchical-agents-communication.md)
- [Patterns](hierarchical-agents-patterns.md)
- [State Persistence](../architecture/state-based-orchestration-overview.md)
