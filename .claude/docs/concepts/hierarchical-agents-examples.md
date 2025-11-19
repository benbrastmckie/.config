# Hierarchical Agent Architecture: Examples

**Related Documents**:
- [Overview](hierarchical-agents-overview.md) - Architecture fundamentals
- [Patterns](hierarchical-agents-patterns.md) - Design patterns
- [Troubleshooting](hierarchical-agents-troubleshooting.md) - Common issues

---

## Example 1: Research Workflow

### Scenario

Research 3 topics in parallel, then create implementation plan.

### Hierarchy

```
/orchestrate command
    |
    +-- Research Phase (Wave 1)
    |       +-- Research Agent: Authentication
    |       +-- Research Agent: Error Handling
    |       +-- Research Agent: Logging
    |
    +-- Planning Phase (Wave 2)
            +-- Plan Architect
```

### Implementation

```markdown
## Phase 0: Pre-Calculate Paths

```bash
TOPIC_DIR=$(get_or_create_topic_dir "$WORKFLOW" ".claude/specs")

declare -A REPORT_PATHS
REPORT_PATHS["auth"]="${TOPIC_DIR}/reports/001_authentication.md"
REPORT_PATHS["errors"]="${TOPIC_DIR}/reports/002_error_handling.md"
REPORT_PATHS["logging"]="${TOPIC_DIR}/reports/003_logging.md"

PLAN_PATH="${TOPIC_DIR}/plans/001_implementation.md"
```

## Phase 1: Research (Parallel)

**EXECUTE NOW**: Invoke research agents

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Authentication patterns in Lua
    Output: ${REPORT_PATHS["auth"]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research error handling"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Error handling best practices
    Output: ${REPORT_PATHS["errors"]}
}

Task {
  subagent_type: "general-purpose"
  description: "Research logging"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Structured logging patterns
    Output: ${REPORT_PATHS["logging"]}
}

## Phase 2: Planning (Sequential)

**EXECUTE NOW**: Create implementation plan

Task {
  subagent_type: "general-purpose"
  description: "Create implementation plan"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    Research Reports:
    - ${REPORT_PATHS["auth"]}
    - ${REPORT_PATHS["errors"]}
    - ${REPORT_PATHS["logging"]}

    Output: ${PLAN_PATH}
}
```

### Expected Output

```
.claude/specs/042_feature/
    reports/
        001_authentication.md
        002_error_handling.md
        003_logging.md
    plans/
        001_implementation.md
```

---

## Example 2: Supervisor Pattern

### Scenario

Use a supervisor to coordinate workers and aggregate metadata.

### Supervisor Agent File

```markdown
# Research Supervisor Agent

**Location**: .claude/agents/research-supervisor.md

## PURPOSE

Coordinate parallel research workers and aggregate their outputs.

## STEP 1: Parse Worker Assignments

Extract topics and paths from orchestrator context.

## STEP 2: Invoke Workers (Parallel)

**EXECUTE NOW**: Invoke research-specialist for each topic

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${topic}
    Output: ${path}
}
```

## STEP 3: Verify Completions

Check all expected files exist.

## STEP 4: Extract Metadata

For each worker output:
- TITLE: First heading
- SUMMARY: First 200 chars of overview
- PATH: File path

## STEP 5: Return Aggregation

```json
{
  "status": "complete",
  "reports": [
    {"title": "...", "path": "...", "summary": "..."},
    ...
  ]
}
```
```

### Orchestrator Invocation

```markdown
**EXECUTE NOW**: Invoke research supervisor

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research phase"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics:
    - topic: "auth", path: "${PATHS['auth']}"
    - topic: "errors", path: "${PATHS['errors']}"
    - topic: "logging", path: "${PATHS['logging']}"
}
```

### Metadata Flow

```
Worker Output (each): 2,500 tokens
    |
    v
Supervisor extracts: 110 tokens per worker
    |
    v
Orchestrator receives: 330 tokens total

Context Reduction: 87%
```

---

## Example 3: Wave-Based Implementation

### Scenario

Implement features in waves based on dependencies.

### Wave Structure

```yaml
phases:
  - name: "Setup Core Infrastructure"
    dependencies: []
  - name: "Implement Authentication"
    dependencies: ["Setup Core Infrastructure"]
  - name: "Implement Logging"
    dependencies: ["Setup Core Infrastructure"]
  - name: "Implement Error Handling"
    dependencies: ["Implement Authentication", "Implement Logging"]
  - name: "Integration Testing"
    dependencies: ["Implement Error Handling"]
```

### Execution

```markdown
## Wave 1: Core Infrastructure

**EXECUTE NOW**: Setup core infrastructure

Task {
  description: "Setup core infrastructure"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Setup Core Infrastructure
    Plan: ${PLAN_PATH}
}

**VERIFICATION**: Core infrastructure complete

## Wave 2: Auth + Logging (Parallel)

**EXECUTE NOW**: Implement in parallel

Task {
  description: "Implement authentication"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Implement Authentication
}

Task {
  description: "Implement logging"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Implement Logging
}

## Wave 3: Error Handling

**EXECUTE NOW**: Implement error handling

Task {
  description: "Implement error handling"
  prompt: |
    Read and follow: .claude/agents/implementation-agent.md
    Phase: Implement Error Handling
}

## Wave 4: Testing

**EXECUTE NOW**: Run integration tests

Task {
  description: "Integration testing"
  prompt: |
    Read and follow: .claude/agents/test-specialist.md
    Phase: Integration Testing
}
```

---

## Example 4: Error Recovery

### Scenario

Handle worker failure gracefully.

### Implementation

```bash
# Invoke worker with verification
invoke_with_recovery() {
  local topic="$1"
  local path="$2"
  local max_retries=2

  for attempt in $(seq 1 $max_retries); do
    # Invoke agent
    invoke_research_agent "$topic" "$path"

    # Verify output
    if [ -f "$path" ]; then
      echo "SUCCESS: $topic completed"
      return 0
    fi

    echo "RETRY $attempt: $topic failed, retrying..."
    sleep 2
  done

  # All retries failed
  echo "ERROR: $topic failed after $max_retries attempts"
  return 1
}

# Use in workflow
for topic in "${TOPICS[@]}"; do
  if ! invoke_with_recovery "$topic" "${PATHS[$topic]}"; then
    echo "CRITICAL: Cannot proceed without $topic"
    exit 1
  fi
done
```

---

## Example 5: Context Injection

### Scenario

Inject workflow-specific context into generic agent.

### Generic Agent

```markdown
# Research Specialist Agent

## STEP 1: Read Context
Parse workflow context from prompt.

## STEP 2: Execute Research
Use context to guide research.

## STEP 3: Create Output
Create file at specified path.
```

### Context Injection

```yaml
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Workflow Context**:
    - Topic: OAuth 2.0 patterns
    - Focus Areas: Security, performance, maintainability
    - Codebase: Lua/Neovim configuration
    - Output: /path/to/report.md

    **Research Requirements**:
    - Analyze existing auth in codebase
    - Research 2025 best practices
    - Provide actionable recommendations

    **Quality Bar**:
    - Minimum 5 recommendations
    - Include code examples
    - Reference specific codebase files
}
```

### Benefits

1. Generic agent, specific context
2. Single behavioral source
3. Easy to customize per workflow
4. Clear separation of concerns

---

## Related Documentation

- [Overview](hierarchical-agents-overview.md)
- [Coordination](hierarchical-agents-coordination.md)
- [Patterns](hierarchical-agents-patterns.md)
- [Troubleshooting](hierarchical-agents-troubleshooting.md)
