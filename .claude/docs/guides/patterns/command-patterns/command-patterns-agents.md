# Command Patterns: Agent Invocation

**Related Documents**:
- [Overview](command-patterns-overview.md) - Pattern index
- [Checkpoints](command-patterns-checkpoints.md) - State management
- [Integration](command-patterns-integration.md) - Testing and PR

---

## Basic Agent Invocation

Commands use the Task tool to invoke specialized agents:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Brief task description (3-5 words)"
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/agent-name.md

    You are acting as [Agent Name] with the tools and constraints
    defined in that file.

    [Specific task instructions]

    Context:
    - [Context item 1]
    - [Context item 2]
}
```

### Key Elements

1. **subagent_type**: Always "general-purpose"
2. **description**: Brief, 3-5 words
3. **prompt**: Must reference behavioral file

### Agent Reference Pattern

```yaml
prompt: |
  Read and follow behavioral guidelines from:
  .claude/agents/research-specialist.md

  [workflow-specific instructions]
```

---

## Parallel Agent Invocation

For independent operations, invoke all agents in a single message:

```markdown
**EXECUTE NOW**: Launch all research agents in parallel

Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Authentication patterns
    Output: ${PATH_1}
}

Task {
  subagent_type: "general-purpose"
  description: "Research error handling"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Error handling
    Output: ${PATH_2}
}

Task {
  subagent_type: "general-purpose"
  description: "Research logging"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Logging patterns
    Output: ${PATH_3}
}
```

**CRITICAL**: Send ALL Task invocations in SINGLE message for true parallelism.

### Benefits

- 40-60% time savings vs sequential
- Independent execution
- Better resource utilization

---

## Sequential Agent Invocation

For dependent operations, wait for completion:

```markdown
## Phase 1: Research

**EXECUTE NOW**: Research agent

Task {
  description: "Research patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${TOPIC}
    Output: ${RESEARCH_PATH}
}

**VERIFICATION**: Wait for research completion

## Phase 2: Planning (depends on Phase 1)

**EXECUTE NOW**: Create plan from research

Task {
  description: "Create implementation plan"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md
    Research: ${RESEARCH_PATH}
    Output: ${PLAN_PATH}
}
```

---

## Thinking Mode Selection

Match agent thinking mode to task complexity:

```bash
calculate_thinking_mode() {
  local complexity="$1"

  if [ "$complexity" -le 3 ]; then
    echo "standard"
  elif [ "$complexity" -le 6 ]; then
    echo "think"
  elif [ "$complexity" -le 9 ]; then
    echo "think hard"
  else
    echo "think harder"
  fi
}
```

### Thinking Mode Matrix

| Score | Mode | Use Case |
|-------|------|----------|
| 0-3 | standard | Simple tasks |
| 4-6 | think | Moderate complexity |
| 7-9 | think hard | High complexity |
| 10+ | think harder | Critical decisions |

### Applying Thinking Mode

```yaml
Task {
  description: "Research security patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Thinking Mode: think hard

    Topic: Security patterns for authentication
    Output: ${PATH}
}
```

---

## Context Injection Pattern

Inject workflow-specific context into generic agents:

```yaml
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    **Workflow Context**:
    - Project: ${PROJECT_NAME}
    - Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}

    **Requirements**:
    - Focus on Lua/Neovim patterns
    - Include code examples
    - Reference existing codebase

    Return: CREATED: ${REPORT_PATH}
}
```

### Benefits

- Generic agents, specific context
- Single source of behavioral truth
- Easy customization

---

## Agent Output Verification

Always verify agent outputs:

```bash
verify_agent_output() {
  local expected_path="$1"
  local signal="$2"

  # Check file created
  if [ ! -f "$expected_path" ]; then
    echo "CRITICAL: File not created at $expected_path"
    return 1
  fi

  # Check signal returned
  if ! echo "$AGENT_OUTPUT" | grep -q "^$signal:"; then
    echo "WARN: Missing $signal signal"
  fi

  echo "Verified: $expected_path"
  return 0
}
```

---

## Supervisor Pattern

For 4+ parallel agents, use supervisor to reduce context:

```markdown
**EXECUTE NOW**: Invoke research supervisor

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research phase"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics:
    - topic: "auth", path: "${PATH_1}"
    - topic: "errors", path: "${PATH_2}"
    - topic: "logging", path: "${PATH_3}"
    - topic: "testing", path: "${PATH_4}"
}
```

### Context Reduction

```
Without Supervisor: 4 x 2,500 = 10,000 tokens
With Supervisor: 4 x 110 = 440 tokens
Reduction: 95.6%
```

---

## Anti-Patterns

### Documentation-Only Blocks

```yaml
# WRONG: Will not execute
Example:
```yaml
Task { ... }
```

# CORRECT: Will execute
**EXECUTE NOW**: Invoke agent

Task { ... }
```

### Serial Parallel Tasks

```markdown
# WRONG: Sequential invocation
Task { ... }
[wait]
Task { ... }

# CORRECT: Parallel invocation
Task { ... }
Task { ... }
Task { ... }
```

### Missing Verification

```bash
# WRONG: Trust output
invoke_agent

# CORRECT: Verify output
invoke_agent
verify_agent_output "$PATH"
```

---

## Related Documentation

- [Overview](command-patterns-overview.md)
- [Checkpoints](command-patterns-checkpoints.md)
- [Agent Development](agent-development-patterns.md)
