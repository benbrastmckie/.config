# Agent Selection Flowchart

**Path**: docs → reference → decision-trees → agent-selection-flowchart.md

Quick decision tree for selecting the right specialized agent for your task.

## Decision Tree

```
┌──────────────────────────────────────────────┐
│ I need to delegate a task to a subagent     │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
     ┌─────────────────────────────┐
     │ What type of task is it?    │
     └──────────┬──────────────────┘
                │
    ┌───────────┼───────────┬──────────────┬──────────────┐
    │           │           │              │              │
    ▼           ▼           ▼              ▼              ▼
┌────────┐  ┌────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│Research│  │Planning│  │Implement │  │Debugging │  │Document  │
└────┬───┘  └───┬────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
     │          │            │             │             │
     ▼          ▼            ▼             ▼             ▼
research-   plan-     implementation-  debug-       doc-writer
analyst   architect    researcher    analyst
```

## Agent Catalog

### Research Agents

#### research-analyst
**Purpose**: Investigate topics, gather findings, analyze patterns

**Use When**:
- Researching best practices or patterns
- Analyzing existing codebase architecture
- Evaluating library/framework options
- Gathering requirements or specifications

**Invoked By**: `/research`, `/orchestrate`, `/plan`

**Specialization**: Research methodology, parallel investigation

**Returns**: Report with findings, recommendations, references

**Example**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Research authentication patterns"
  prompt: "
    Read and follow: .claude/agents/research-analyst.md
    You are acting as Research Analyst.

    Research authentication patterns for Node.js applications...
  "
}
```

### Planning Agents

#### plan-architect
**Purpose**: Design structured implementation plans with complexity analysis

**Use When**:
- Creating new implementation plans
- Designing multi-phase workflows
- Evaluating feature complexity
- Structuring development approach

**Invoked By**: `/plan`, `/orchestrate`

**Specialization**: Plan structure, complexity evaluation, phase design

**Returns**: Implementation plan with phases, tasks, estimates

**Example**:
```yaml
Task {
  subagent_type: "general-purpose"
  description: "Design authentication implementation plan"
  prompt: "
    Read and follow: .claude/agents/plan-architect.md
    You are acting as Plan Architect.

    Create implementation plan for user authentication...
  "
}
```

#### complexity-evaluator
**Purpose**: Calculate plan complexity scores for expansion decisions

**Use When**:
- Determining if phase should be expanded
- Evaluating plan scope and effort
- Triggering progressive plan structures

**Invoked By**: `/plan`, `/expand`

**Specialization**: Complexity scoring, expansion thresholds

**Returns**: Complexity score (0.0-15.0) with breakdown

### Implementation Agents

#### implementation-researcher
**Purpose**: Explore codebase before complex implementation phases

**Use When**:
- Phase complexity ≥8
- Need to find existing patterns/utilities
- Identifying integration points
- Understanding current architecture

**Invoked By**: `/implement`

**Specialization**: Codebase analysis, pattern identification

**Returns**: 50-word summary + artifact path with findings

**Example**:
```yaml
Task {
  subagent_type: "Explore"
  model: "haiku"
  description: "Explore authentication codebase patterns"
  prompt: "
    Read and follow: .claude/agents/implementation-researcher.md
    You are acting as Implementation Researcher.

    Explore codebase for existing authentication patterns...
  "
}
```

#### code-writer
**Purpose**: Generate code following project standards

**Use When**:
- Implementing features from plans
- Writing new modules or functions
- Refactoring existing code

**Invoked By**: `/implement`, `/orchestrate`

**Specialization**: Code generation, standards compliance

**Returns**: Implementation with code changes

### Debugging Agents

#### debug-analyst
**Purpose**: Investigate root causes in parallel

**Use When**:
- Test failures need diagnosis
- Multiple potential causes to investigate
- Parallel hypothesis testing
- Complex bugs requiring focused analysis

**Invoked By**: `/debug`, `/implement`

**Specialization**: Debugging techniques, root cause analysis

**Returns**: Structured findings + proposed fixes

**Example**:
```yaml
# Parallel debug investigations
Task {
  subagent_type: "general-purpose"
  description: "Debug authentication failure - database connection"
  prompt: "
    Read and follow: .claude/agents/debug-analyst.md
    You are acting as Debug Analyst.

    Investigate database connection as potential root cause...
  "
}

Task {
  subagent_type: "general-purpose"
  description: "Debug authentication failure - token validation"
  prompt: "
    Read and follow: .claude/agents/debug-analyst.md
    You are acting as Debug Analyst.

    Investigate token validation as potential root cause...
  "
}
```

### Documentation Agents

#### doc-writer
**Purpose**: Create and update documentation

**Use When**:
- Generating API documentation
- Creating user guides
- Updating README files
- Documenting architecture changes

**Invoked By**: `/document`, `/orchestrate`

**Specialization**: Technical writing, documentation standards

**Returns**: Documentation files following project standards

### Test Agents

#### test-specialist
**Purpose**: Execute tests and analyze results

**Use When**:
- Running project test suites
- Analyzing test failures
- Validating implementations
- Checking coverage requirements

**Invoked By**: `/implement`, `/orchestrate`

**Specialization**: Test execution, failure diagnosis

**Returns**: Test results with pass/fail status and diagnostics

### Coordination Agents

#### sub-supervisor
**Purpose**: Manage 2-3 specialized subagents per domain

**Use When**:
- Managing complex multi-agent workflows
- Coordinating 10+ total research topics
- Hierarchical supervision needed
- Recursive workflow orchestration

**Invoked By**: `/orchestrate`, supervisors

**Specialization**: Agent coordination, aggregated metadata

**Returns**: Aggregated metadata only (not full subagent outputs)

**Pattern**: Enables hierarchical supervision (supervisor → sub-supervisor → workers)

## Selection Matrix

| Task Type | Primary Agent | Parallel? | Model | Returns |
|-----------|--------------|-----------|-------|---------|
| Research topics | research-analyst | Yes (2-4) | Sonnet | Report + metadata |
| Design plans | plan-architect | No | Sonnet | Plan file |
| Evaluate complexity | complexity-evaluator | No | Haiku | Score + breakdown |
| Explore codebase | implementation-researcher | No | Haiku | Summary + findings |
| Write code | code-writer | No | Sonnet | Code changes |
| Debug issues | debug-analyst | Yes (per hypothesis) | Sonnet | Findings + fixes |
| Write docs | doc-writer | No | Sonnet | Documentation |
| Run tests | test-specialist | No | Haiku | Test results |
| Coordinate agents | sub-supervisor | No | Sonnet | Aggregated metadata |

## Model Selection Guide

### Use Haiku When:
- Quick, straightforward tasks
- Codebase exploration
- File searches
- Complexity calculations
- Test execution
- Cost/latency optimization

### Use Sonnet When:
- Complex reasoning needed
- Code generation
- Research analysis
- Planning/architecture
- Debugging investigations
- High-quality writing

### Use Opus When:
- Exceptional complexity
- Novel problem domains
- Critical path decisions
- (Rarely needed in practice)

See: [Model Selection Guide](../guides/development/model-selection-guide.md) for complete details

## Agent Invocation Pattern

All agents use the **behavioral injection pattern**:

```yaml
Task {
  subagent_type: "general-purpose"  # or "Explore" for codebase search
  model: "sonnet"                   # or "haiku" for quick tasks
  description: "Brief task description (3-5 words)"
  prompt: "
    # 1. BEHAVIORAL INJECTION
    Read and follow: .claude/agents/AGENT-NAME.md
    You are acting as [Agent Name].

    # 2. OPERATIONAL CONTEXT
    [Specific task instructions]

    # 3. DOMAIN CONTEXT
    [Project standards, requirements]

    # 4. HISTORICAL CONTEXT (optional)
    Previous findings: [metadata only, not full content]

    # 5. ENVIRONMENTAL CONTEXT
    Working directory: [path]
    Current phase: [phase info]

    # 6. DELIVERABLE
    Return: [specific format/structure expected]
  "
}
```

See: [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)

## Common Scenarios

### Scenario: Multi-Topic Research

**Task**: Research 3 authentication approaches

**Agents**: 3x research-analyst (parallel)

**Invocation**:
```yaml
# Invoke all three in parallel (single message, multiple Task blocks)
Task { research OAuth 2.0 }
Task { research JWT }
Task { research session-based }
```

**Returns**: 3 research reports with metadata extraction

**Context Savings**: 95% reduction (15K tokens → 750 tokens)

### Scenario: Complex Implementation Phase

**Task**: Implement Phase 3 with complexity=9.2

**Agents**: implementation-researcher → code-writer

**Flow**:
1. implementation-researcher explores codebase (finds patterns, utilities)
2. Returns 50-word summary + findings path
3. code-writer implements using discovered patterns

**Context Savings**: 98% reduction through metadata passing

### Scenario: Test Failures

**Task**: 3 test failures in authentication module

**Agents**: 3x debug-analyst (parallel, one per hypothesis)

**Hypotheses**:
1. Database connection issue
2. Token validation failure
3. Session management bug

**Flow**:
1. Launch 3 debug-analyst agents in parallel
2. Each investigates one hypothesis
3. Return findings + proposed fixes
4. Aggregate results, implement fix

**Time Savings**: 60% faster than sequential debugging

## Anti-Patterns

### Don't Use Agents When:

❌ **Task is too simple**
- Simple file reads → Use Read tool directly
- Basic grep → Use Grep tool directly
- Single command execution → Use Bash tool directly

❌ **No clear specialization**
- Generic "do this task" → Break down into specialized sub-tasks
- Overlapping responsibilities → Design clearer agent boundaries

❌ **Synchronous dependencies**
- Agent A needs Agent B's full output → Consider merging into one agent
- Sequential pipeline with no parallelism → Consider direct implementation

### Don't Use Too Many Agents:

⚠️ **Coordination overhead** increases with agent count

**Good**: 2-4 parallel agents per phase
**Acceptable**: 5-6 with clear boundaries
**Problematic**: 7+ agents (consider sub-supervisors)

**Solution**: Use hierarchical supervision for 10+ agents

## Agent Development

Need to create a new agent?

→ See [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md)

Key steps:
1. Define clear specialization
2. Create behavioral file in `.claude/agents/`
3. Document agent in [Agent Reference](../reference/standards/agent-reference.md)
4. Test with behavioral injection pattern
5. Measure context reduction

## Related Documentation

- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - Creating new agents
- [Agent Reference](../reference/standards/agent-reference.md) - Complete agent catalog
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - Agent invocation
- [Model Selection Guide](../guides/development/model-selection-guide.md) - Choosing Claude models
- [Command vs Agent Flowchart](./command-vs-agent-flowchart.md) - When to create commands vs agents

## Navigation

**Docs Index**: [← Back to Docs](../README.md)
**Quick Reference**: [← Back to Quick Reference](./README.md)
