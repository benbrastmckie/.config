# Agent Development: Patterns

**Related Documents**:
- [Fundamentals](agent-development-fundamentals.md) - Creating agents
- [Testing](agent-development-testing.md) - Testing and validation
- [Examples](agent-development-examples.md) - Reference implementations

---

## Part 2: Invoking Agents

### 2.1 Agent Invocation Pattern

The standard pattern for invoking agents from commands:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke [agent-name]:

Task {
  subagent_type: "general-purpose"
  description: "Brief task description"
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Context**:
    - [Field 1]: ${VALUE_1}
    - [Field 2]: ${VALUE_2}

    Return: [SIGNAL]: [value]
}
```

### 2.2 Agent Directory

Current agents in `.claude/agents/`:

| Agent | Purpose | Key Tools |
|-------|---------|-----------|
| `research-specialist.md` | Research and analysis | Grep, WebSearch, Write |
| `plan-architect.md` | Create implementation plans | Read, Write |
| `implementation-agent.md` | Execute code changes | Edit, Write, Bash |
| `test-specialist.md` | Run and validate tests | Read, Bash |
| `doc-writer.md` | Create documentation | Read, Write |

### 2.3 Integration Patterns

#### Single Agent Invocation

For independent tasks:

```markdown
**EXECUTE NOW**: Invoke research agent

Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Topic: OAuth 2.0 patterns
    Output: ${REPORT_PATH}
}
```

#### Parallel Agent Invocation

For independent tasks that can run simultaneously:

```markdown
**EXECUTE NOW**: Invoke all research agents in parallel

Task {
  subagent_type: "general-purpose"
  description: "Research authentication"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: Authentication
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
    Topic: Logging
    Output: ${PATH_3}
}
```

**CRITICAL**: Send ALL Task blocks in single message for parallel execution.

#### Sequential Agent Invocation

For dependent tasks:

```markdown
## Phase 1: Research

**EXECUTE NOW**: Research agent

Task {
  description: "Research patterns"
  prompt: "..."
}

## Phase 2: Planning (depends on Phase 1)

**EXECUTE NOW**: Planning agent using research

Task {
  description: "Create plan from research"
  prompt: |
    Read and follow: .claude/agents/plan-architect.md

    Input: ${RESEARCH_REPORT}
    Output: ${PLAN_PATH}
}
```

#### Loop-Based Invocation

For multiple similar tasks:

```markdown
**EXECUTE NOW**: For each topic (1 to ${COUNT}), invoke research agent:

Task {
  subagent_type: "general-purpose"
  description: "Research [topic name]"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Topic: [insert topic]
    Output: [insert path]
}
```

#### Conditional Invocation

For optional tasks:

```markdown
## Conditional: Documentation Update

IF documentation changes needed THEN:

**EXECUTE NOW**: Invoke doc-writer

Task {
  description: "Update documentation"
  prompt: |
    Read and follow: .claude/agents/doc-writer.md

    Changes: ${CHANGE_LIST}
    Output: ${DOC_PATH}
}

ELSE: Skip documentation phase
```

### 2.4 Command-Agent Matrix

| Command | Agents Used | Pattern |
|---------|-------------|---------|
| `/orchestrate` | research-specialist (N), plan-architect | Parallel -> Sequential |
| `/implement` | implementation-agent | Sequential |
| `/research` | research-specialist (N) | Parallel |
| `/plan` | plan-architect | Single |
| `/debug` | research-specialist | Single |

---

## Part 3: Context Architecture

### 3.1 Layered Context Architecture

Context is layered to minimize token usage:

```
Layer 1: Command Context (loaded first)
    - Workflow parameters
    - Pre-calculated paths
    - Phase state

Layer 2: Agent Behavioral File (loaded by agent)
    - Role definition
    - Tool restrictions
    - Output format

Layer 3: Injected Context (provided by command)
    - Task-specific inputs
    - Paths and values
    - Constraints
```

### 3.2 Context Preservation Patterns

#### Pre-Calculate Paths

Calculate all paths before invoking agents:

```bash
# Phase 0: Pre-calculate
TOPIC_DIR=$(get_or_create_topic_dir "$DESC" ".claude/specs")

declare -A REPORT_PATHS
for topic in "${TOPICS[@]}"; do
  REPORT_PATHS["$topic"]="${TOPIC_DIR}/reports/${topic}.md"
done

export TOPIC_DIR REPORT_PATHS
```

#### Metadata Extraction

Extract only essential information from outputs:

```bash
extract_metadata() {
  local output="$1"

  TITLE=$(echo "$output" | grep -oP 'TITLE:\s*\K.+')
  PATH=$(echo "$output" | grep -oP 'CREATED:\s*\K.+')
  SUMMARY=$(echo "$output" | head -c 200)

  echo "title=$TITLE"
  echo "path=$PATH"
  echo "summary=$SUMMARY"
}
```

#### Context Reduction Results

```
Full Content Pass: 2,500 tokens per agent
Metadata Pass: 110 tokens per agent
Reduction: 95.6%
```

### 3.3 Agent Invocation Best Practices

1. **Always use behavioral injection**
   - Reference agent file, don't duplicate

2. **Pre-calculate all paths**
   - Calculate before invoking, not during

3. **Use absolute paths**
   - Never relative paths in agent context

4. **Include return signal requirement**
   - Agent must return confirmation

5. **Verify after invocation**
   - Check files exist at expected paths

---

## Context Injection Template

Standard context injection pattern:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "[Brief description]"
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/[agent-name].md

    **Task Context**:
    - Primary Goal: [specific objective]
    - Output Path: [absolute path]
    - Input Resources: [list of inputs]

    **Constraints**:
    - Thinking Mode: [standard|think|think hard]
    - Time Budget: [estimated]

    **Expected Return**:
    [SIGNAL]: [value]
}
```

---

## Anti-Patterns

### Anti-Pattern 1: Documentation-Only Blocks

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

### Anti-Pattern 2: Serial Parallel Tasks

```markdown
# WRONG: Sequential execution
**EXECUTE**: Task 1
[wait]
**EXECUTE**: Task 2
[wait]
**EXECUTE**: Task 3

# CORRECT: Parallel execution
**EXECUTE NOW**: All tasks

Task { ... task 1 ... }
Task { ... task 2 ... }
Task { ... task 3 ... }
```

### Anti-Pattern 3: Inline Behavior Duplication

```yaml
# WRONG: Duplicating behavior
Task {
  prompt: |
    You are a research specialist.
    [150 lines of behavior]
    Topic: ${TOPIC}
}

# CORRECT: Reference behavior
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${TOPIC}
}
```

### Anti-Pattern 4: Missing Verification

```bash
# WRONG: Trust output
RESULT=$(invoke_agent)
use_result "$RESULT"

# CORRECT: Verify first
RESULT=$(invoke_agent)
if [ ! -f "$EXPECTED_PATH" ]; then
  exit 1
fi
use_result "$RESULT"
```

---

## Related Documentation

- [Fundamentals](agent-development-fundamentals.md) - Creating agents
- [Testing](agent-development-testing.md) - Testing agents
- [Troubleshooting](agent-development-troubleshooting.md) - Common issues
- [Architecture Standards](../reference/architecture/integration.md)
