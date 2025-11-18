# Agent Development: Advanced Patterns

**Related Documents**:
- [Fundamentals](agent-development-fundamentals.md) - Creating agents
- [Patterns](agent-development-patterns.md) - Invocation patterns
- [Examples](agent-development-examples.md) - Reference implementations

---

## Part 4: Advanced Patterns

### 4.1 Agent Responsibilities and Boundaries

Each agent has clearly defined responsibilities:

| Agent | Responsible For | Not Responsible For |
|-------|-----------------|---------------------|
| research-specialist | Research, analysis, recommendations | Planning, implementation |
| plan-architect | Plan structure, phases, dependencies | Research, implementation |
| implementation-agent | Code changes, tests | Research, planning |

### 4.2 Agent Consolidation

When to consolidate multiple agents into one:

**Consolidate When**:
- Tasks are always performed together
- No benefit to separate invocation
- Combined context fits comfortably

**Keep Separate When**:
- Tasks can be parallel
- Different tool requirements
- Different model requirements
- Reusability across workflows

### 4.3 Performance Optimization

#### Context Efficiency

```markdown
# Minimal context injection
Read and follow: .claude/agents/research-specialist.md
Topic: Authentication
Output: /path/to/report.md

# vs Full context (avoid)
[500+ lines of instructions]
```

#### Model Selection

```yaml
# Match model to task
Simple/Deterministic: haiku-4.5 (fast, cheap)
Standard: sonnet-4.5 (balanced)
Critical: opus-4 (thorough)
```

#### Parallel Execution

```markdown
# Send all parallel tasks in single message
Task { ... topic 1 ... }
Task { ... topic 2 ... }
Task { ... topic 3 ... }
```

---

## Supervisor Pattern

### When to Use

- 4+ parallel agents
- Need metadata aggregation
- Context reduction critical

### Supervisor Agent Structure

```markdown
# Research Supervisor

## Purpose
Coordinate parallel research workers and aggregate metadata.

## STEP 1: Parse Assignments
Extract topics from orchestrator context.

## STEP 2: Invoke Workers (Parallel)
**EXECUTE NOW**: For each topic, invoke research-specialist

## STEP 3: Extract Metadata
From each output:
- Title
- Path
- Summary (200 chars)

## STEP 4: Return Aggregation
Return combined metadata to orchestrator.
```

### Invoking Supervisor

```yaml
Task {
  description: "Coordinate research phase"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics:
    - auth: ${PATH_AUTH}
    - errors: ${PATH_ERRORS}
    - logging: ${PATH_LOGGING}
}
```

---

## Error Recovery Patterns

### Retry Pattern

```bash
invoke_with_retry() {
  local max=3
  local attempt=0

  while [ $attempt -lt $max ]; do
    ((attempt++))
    echo "Attempt $attempt/$max"

    if invoke_agent "$@"; then
      return 0
    fi

    echo "Failed, retrying..."
    sleep 2
  done

  echo "All attempts failed"
  return 1
}
```

### Fallback Pattern

```bash
invoke_with_fallback() {
  # Primary: Invoke agent
  if invoke_agent "$@"; then
    return 0
  fi

  # Fallback: Use simpler agent or default
  echo "Primary failed, using fallback"
  invoke_fallback_agent "$@"
}
```

### Graceful Degradation

```markdown
## Phase: Research (with degradation)

Primary: Use research-specialist with full capabilities
If failed: Use simplified research with fewer sources
If failed: Use cached/default recommendations

Always produce some output.
```

---

## Custom Agent Development

### Step 1: Define Scope

```markdown
What specific task does this agent perform?
What inputs does it receive?
What outputs does it produce?
What tools does it need?
```

### Step 2: Choose Model

```markdown
Is task deterministic? -> haiku-4.5
Standard complexity? -> sonnet-4.5
Critical decisions? -> opus-4
```

### Step 3: Define Contract

```yaml
Input:
  - field: string (required)
  - field: number (optional)

Output:
  - SIGNAL: value
  - FILE: /path/to/file.md
```

### Step 4: Write Behavioral File

```markdown
---
allowed-tools: [tools]
description: [purpose]
model: [model]
---

# Agent Name

## Core Capabilities
- [capability]

## Expected Input
- [field]: description

## Expected Output
- [format]

## Behavioral Guidelines
- [guideline]
```

### Step 5: Test

```bash
# Unit test
bash .claude/tests/agents/test_new_agent.sh

# Integration test
/command-using-new-agent
```

---

## Metrics and Monitoring

### Key Metrics

| Metric | How to Measure | Target |
|--------|----------------|--------|
| File creation rate | Files created / expected | 100% |
| Format compliance | Valid sections / required | 100% |
| Response time | End - start | <30s |
| Context usage | Tokens used | <10k |

### Monitoring Pattern

```bash
monitor_agent() {
  local start=$(date +%s.%N)

  # Invoke
  OUTPUT=$(invoke_agent "$@")

  local end=$(date +%s.%N)
  local duration=$(echo "$end - $start" | bc)

  # Log metrics
  echo "Duration: ${duration}s"
  echo "Output size: ${#OUTPUT} chars"
  echo "File created: $([ -f "$EXPECTED" ] && echo yes || echo no)"
}
```

---

## Agent Composition

### Sequential Composition

```markdown
Agent A -> Agent B -> Agent C

Output of A is input to B
Output of B is input to C
```

### Parallel Composition

```markdown
    Orchestrator
        |
   +----+----+
   |    |    |
   A    B    C
   |    |    |
   +----+----+
        |
    Aggregator
```

### Hierarchical Composition

```markdown
Orchestrator
    |
    +-- Supervisor A
    |       +-- Worker A1
    |       +-- Worker A2
    |
    +-- Supervisor B
            +-- Worker B1
            +-- Worker B2
```

---

## Agent Versioning

### Version in Filename

```
.claude/agents/
    research-specialist.md      # Current version
    research-specialist-v1.md   # Previous version (deprecated)
```

### Version in Frontmatter

```yaml
---
version: 2.1.0
deprecated: false
replaces: research-specialist-v1.md
---
```

### Migration

```markdown
# Migration from v1 to v2

Changes:
- Added SUMMARY signal requirement
- Changed section order
- Added quality criteria

Commands to update:
- /orchestrate
- /research
```

---

## Security Considerations

### Tool Restrictions

Only allow necessary tools:
```yaml
allowed-tools: Read, Write  # Minimal
# NOT: Read, Write, Edit, Bash, WebSearch, WebFetch  # Excessive
```

### Path Validation

Agents should only write to expected locations:
```markdown
Output paths must be within:
- .claude/specs/
- .claude/docs/
- Explicitly specified paths

NOT arbitrary filesystem locations.
```

### Input Validation

Verify inputs before use:
```bash
if [ ! -d "$(dirname "$OUTPUT_PATH")" ]; then
  echo "Invalid output directory"
  exit 1
fi
```

---

## Related Documentation

- [Fundamentals](agent-development-fundamentals.md)
- [Patterns](agent-development-patterns.md)
- [Examples](agent-development-examples.md)
- [Hierarchical Agents](../concepts/hierarchical-agents-overview.md)
