# Hierarchical Agent Architecture: Overview

**Related Documents**:
- [Coordination](hierarchical-agents-coordination.md) - Multi-agent coordination patterns
- [Communication](hierarchical-agents-communication.md) - Agent communication protocols
- [Patterns](hierarchical-agents-patterns.md) - Design patterns and best practices
- [Examples](hierarchical-agents-examples.md) - Reference implementations
- [Troubleshooting](hierarchical-agents-troubleshooting.md) - Common issues and solutions

---

## Purpose

The hierarchical agent architecture provides a structured approach to coordinating multiple specialized agents within Claude Code workflows. This architecture enables complex multi-step operations while maintaining context efficiency and clear responsibility boundaries.

## Core Principles

### 1. Hierarchical Supervision

Agents are organized in a hierarchy where supervisors coordinate worker agents:

```
Orchestrator Command
    |
    +-- Research Supervisor
    |       +-- Research Agent 1
    |       +-- Research Agent 2
    |       +-- Research Agent 3
    |
    +-- Implementation Supervisor
            +-- Code Writer
            +-- Test Specialist
```

### 2. Behavioral Injection

Agents receive behavior through runtime injection rather than hardcoded instructions:

```yaml
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: .claude/agents/research-specialist.md

    Context:
    - Topic: ${RESEARCH_TOPIC}
    - Output Path: ${REPORT_PATH}
}
```

### 3. Metadata-Only Context Passing

Between hierarchy levels, pass metadata summaries rather than full content:

- **Full content**: 2,500 tokens per agent
- **Metadata summary**: 110 tokens per agent
- **Context reduction**: 95%+

### 4. Single Source of Truth

Agent behavioral guidelines exist in ONE location only (`.claude/agents/*.md`). Commands reference these files rather than duplicating content.

## Architecture Overview

### Agent Roles

| Role | Purpose | Tools | Invoked By |
|------|---------|-------|------------|
| **Orchestrator** | Coordinates workflow phases | All | User command |
| **Supervisor** | Coordinates parallel workers | Task | Orchestrator |
| **Specialist** | Executes specific tasks | Domain-specific | Supervisor |

### Communication Flow

1. **Command -> Orchestrator**: User invokes slash command
2. **Orchestrator -> Supervisor**: Pre-calculates paths, invokes supervisor
3. **Supervisor -> Workers**: Invokes parallel worker agents
4. **Workers -> Supervisor**: Return metadata (path + summary)
5. **Supervisor -> Orchestrator**: Return aggregated metadata
6. **Orchestrator -> User**: Display results

### Context Efficiency

```
Traditional Approach:
  4 Workers x 2,500 tokens = 10,000 tokens to orchestrator

Hierarchical Approach:
  4 Workers x 2,500 tokens -> Supervisor
  Supervisor extracts 110 tokens/worker = 440 tokens to orchestrator

Reduction: 95.6%
```

## When to Use Hierarchical Architecture

### Use When

- Workflow has 4+ parallel agents
- Context reduction is critical
- Workers produce large outputs (>1,000 tokens each)
- Need clear responsibility boundaries
- Workflow has distinct phases (research, plan, implement)

### Don't Use When

- Single agent workflow
- Simple sequential operations
- Minimal context management needs
- No parallel execution benefits

## Quick Start

### 1. Create Supervisor Behavioral File

```markdown
# Research Supervisor

You coordinate parallel research agents and aggregate their findings.

## STEP 1: Receive Worker Assignments
Parse the topics list and verify all assignments.

## STEP 2: Invoke Workers in Parallel
Use Task tool to invoke research-specialist for each topic.

## STEP 3: Extract Metadata
From each worker output, extract: title, summary (50 words), key findings.

## STEP 4: Return Aggregated Metadata
Return combined metadata to orchestrator.
```

### 2. Invoke from Command

```markdown
**EXECUTE NOW**: Invoke research supervisor

Task {
  subagent_type: "general-purpose"
  description: "Coordinate research phase"
  prompt: |
    Read and follow: .claude/agents/research-supervisor.md

    Topics: ${RESEARCH_TOPICS}
    Output Directory: ${REPORTS_DIR}
}
```

### 3. Process Results

```bash
# Supervisor returns aggregated metadata
METADATA=$(parse_supervisor_output)
REPORTS=$(echo "$METADATA" | jq -r '.reports[]')
```

## Key Benefits

1. **Context Efficiency**: 95%+ reduction at scale
2. **Clear Boundaries**: Each agent has defined responsibilities
3. **Parallel Execution**: 40-60% time savings
4. **Maintainability**: Single source of truth for behavior
5. **Reliability**: Verification at each level

## Related Documentation

- [Coordination](hierarchical-agents-coordination.md) - Multi-agent coordination patterns
- [Communication](hierarchical-agents-communication.md) - Agent communication protocols
- [Patterns](hierarchical-agents-patterns.md) - Design patterns and best practices
- [Examples](hierarchical-agents-examples.md) - Reference implementations (includes hard barrier pattern)
- [Troubleshooting](hierarchical-agents-troubleshooting.md) - Common issues and solutions
- [Hard Barrier Pattern](patterns/hard-barrier-subagent-delegation.md) - Enforcing mandatory subagent delegation
- [State-Based Orchestration](../architecture/state-based-orchestration-overview.md)
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md)
- [Behavioral Injection Pattern](patterns/behavioral-injection.md)
