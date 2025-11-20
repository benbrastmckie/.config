# Agent Development: Fundamentals

**Related Documents**:
- [Patterns](agent-development-patterns.md) - Agent invocation and integration
- [Testing](agent-development-testing.md) - Testing and validation
- [Troubleshooting](agent-development-troubleshooting.md) - Common issues
- [Advanced](agent-development-advanced.md) - Advanced patterns
- [Examples](agent-development-examples.md) - Reference implementations

---

## Quick Start: Your First Agent

**Goal**: Create a simple agent and invoke it from a command in under 10 minutes.

### Step 1: Create Agent File (2 minutes)

Create `.claude/agents/hello-agent.md`:

```markdown
---
allowed-tools: Read, Write
description: Simple demonstration agent that creates greeting files
model: haiku-4.5
model-justification: "Deterministic file creation with template, no complex reasoning required"
---

# Hello Agent

I am a demonstration agent that creates greeting files.

## Core Capabilities
- Create greeting files at specified paths
- Use simple template-based content

## Expected Input
- **Output Path**: Absolute path where greeting file should be created
- **Name**: Name to include in greeting

## Expected Output
- Greeting file created at exact path
- Confirmation message with file path
```

### Step 2: Invoke from Command (3 minutes)

In any command file, invoke the agent:

```markdown
**EXECUTE NOW**: USE the Task tool to invoke hello-agent:

Task {
  subagent_type: "general-purpose"
  description: "Create greeting using hello-agent protocol"
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/hello-agent.md

    Output Path: /tmp/greeting.txt
    Name: Claude
}
```

### Step 3: Verify (1 minute)

Check that `/tmp/greeting.txt` was created with greeting content.

---

## Part 1: Creating Agents

### 1.1 Agent Behavioral Files Overview

Agent behavioral files (`.claude/agents/*.md`) define the behavior, capabilities, and constraints for specialized AI agents within the Claude Code workflow system.

**Purpose**:
- Define agent responsibilities and boundaries
- Specify allowed tools and restrictions
- Provide behavioral guidelines for consistent execution
- Enable behavioral injection pattern for context efficiency

**Location**: `.claude/agents/` directory

### 1.2 The Behavioral Injection Pattern

Rather than duplicating agent instructions in every command, use behavioral injection:

```markdown
**Command File Pattern**:
Task {
  prompt: |
    Read and follow behavioral guidelines from:
    .claude/agents/research-specialist.md

    Context-specific information:
    - Topic: ${TOPIC}
    - Output: ${PATH}
}
```

**Benefits**:
- **Single Source of Truth**: Behavior defined once
- **Consistency**: All invocations use same behavior
- **Maintainability**: Update once, affect all usages
- **Context Efficiency**: 90% reduction in tokens per invocation

### 1.3 Agent Files as Single Source of Truth

Agent behavioral files serve as the authoritative source for:
- Role definition and responsibilities
- Tool restrictions and permissions
- Output format requirements
- Quality criteria and success metrics
- Error handling procedures

**Anti-Pattern**: Duplicating behavior in commands

```yaml
# WRONG: 200+ lines duplicated
Task {
  prompt: |
    You are a research specialist.
    Your role is to...
    You MUST use these tools...
    Your output format is...
    [180 more lines]
}

# CORRECT: Reference + context
Task {
  prompt: |
    Read and follow: .claude/agents/research-specialist.md
    Topic: ${TOPIC}
    Output: ${PATH}
}
```

### 1.4 Agent File Structure

#### Frontmatter (YAML)

```yaml
---
allowed-tools: Grep, Read, Write, WebSearch, WebFetch
description: One-line description of agent purpose
model: sonnet-4.5 | haiku-4.5 | opus-4
model-justification: "Why this model is appropriate"
---
```

**Required Fields**:
- `allowed-tools`: Tools the agent can use
- `description`: Brief purpose description

**Optional Fields**:
- `model`: Specific model override (default: sonnet-4.5)
- `model-justification`: Why model was chosen

#### Core Content Sections

1. **Agent Title and Summary**
   ```markdown
   # Research Specialist Agent

   Specialized agent for thorough codebase analysis and best practices research.
   ```

2. **Core Capabilities**
   ```markdown
   ## Core Capabilities
   - Codebase pattern analysis
   - Best practices research
   - Structured report creation
   ```

3. **Expected Input**
   ```markdown
   ## Expected Input
   - **Research Topic**: What to research
   - **Output Path**: Where to create report
   - **Thinking Mode**: Complexity level
   ```

4. **Expected Output**
   ```markdown
   ## Expected Output
   - Research report at specified path
   - Structured sections: Overview, Findings, Recommendations
   - Confirmation signal: CREATED: /path/to/report.md
   ```

5. **Behavioral Guidelines**
   ```markdown
   ## Behavioral Guidelines
   - Always verify file creation
   - Include code examples
   - Use 2025 best practices
   ```

### 1.5 Creating a New Agent

#### Step-by-Step Process

1. **Identify Need**: What specialized behavior is required?
2. **Choose Tools**: What tools does the agent need?
3. **Define Format**: What should outputs look like?
4. **Write Guidelines**: What behavioral constraints apply?
5. **Test**: Verify agent works as expected

#### Template

```markdown
---
allowed-tools: [list tools needed]
description: [one-line purpose]
model: [model if not default]
model-justification: "[why this model]"
---

# [Agent Name]

[1-2 sentence description of agent role]

## Core Capabilities
- [Capability 1]
- [Capability 2]
- [Capability 3]

## Expected Input
- **[Field 1]**: Description
- **[Field 2]**: Description

## Expected Output
- [Output description]
- [Format requirements]
- [Confirmation signal]

## Behavioral Guidelines
- [Guideline 1]
- [Guideline 2]

## Quality Criteria
- [Criterion 1]
- [Criterion 2]
```

---

## Agent Types

### Research Agents

Research codebase and external sources:
- `research-specialist.md` - General research
- Focus on analysis and recommendations

**Tools**: Grep, Glob, Read, WebSearch, WebFetch, Write

### Planning Agents

Create implementation plans:
- `plan-architect.md` - Implementation planning
- Focus on structured, actionable plans

**Tools**: Read, Write

### Implementation Agents

Execute code changes:
- `implementation-agent.md` - Code modification
- Focus on accurate changes with tests

**Tools**: Read, Write, Edit, Bash

### Testing Agents

Execute and validate tests:
- `test-specialist.md` - Test execution
- Focus on comprehensive coverage

**Tools**: Read, Bash

### Documentation Agents

Create and update documentation:
- `doc-writer.md` - Documentation creation
- Focus on clear, comprehensive docs

**Tools**: Read, Write

---

## Model Selection

### When to Use Which Model

| Model | Use When | Examples |
|-------|----------|----------|
| **haiku-4.5** | Simple, deterministic tasks | File creation, templated output |
| **sonnet-4.5** | Most tasks (default) | Research, planning, implementation |
| **opus-4** | Critical, complex decisions | Architecture decisions, security |

### Model Selection Criteria

```markdown
Use haiku-4.5 when:
- Task is deterministic/templated
- No complex reasoning required
- Speed is important

Use sonnet-4.5 when:
- Standard complexity
- Needs reasoning but not critical
- Good balance of capability/cost

Use opus-4 when:
- Critical decisions
- Complex multi-step reasoning
- Security/architecture implications
```

---

## Related Documentation

- [Patterns](agent-development-patterns.md) - Invocation patterns
- [Testing](agent-development-testing.md) - Testing agents
- [Hierarchical Agents](../concepts/hierarchical-agents-overview.md)
