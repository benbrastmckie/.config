# Agent Integration Guide

Comprehensive guide for integrating and using specialized agents in the Claude Code workflow system.

## Overview

This project uses specialized agent behaviors to handle specific workflow tasks. Agent behaviors are defined in `.claude/agents/` and are invoked using the `general-purpose` agent type with behavioral injection, following the supervisor pattern for multi-agent coordination.

## Critical: Agent Invocation Pattern

**Available Agent Types** (via Task tool):
- `general-purpose` - General-purpose agent for all specialized behaviors
- `statusline-setup` - Configure statusline settings
- `output-style-setup` - Create output styles

**Specialized Agent Behaviors** (via behavioral injection):
- `research-specialist`, `code-writer`, `test-specialist`, `plan-architect`, `doc-writer`, `code-reviewer`, `debug-specialist`, `metrics-specialist`

**Correct Invocation Pattern**:
```yaml
Task {
  subagent_type: "general-purpose"  # Always use general-purpose
  description: "Create plan using plan-architect protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/plan-architect.md

    You are acting as a Plan Architect with the constraints and capabilities
    defined in that file.

    [Your actual task description here]
}
```

**Incorrect Pattern** (will cause errors):
```yaml
Task {
  subagent_type: "plan-architect"  # ERROR: Not a valid agent type
  ...
}
```

## Agent Directory

### Core Agents (Phase 1)

#### 1. research-specialist
- **Purpose**: Read-only research and codebase analysis
- **Tools**: Read, Grep, Glob, WebSearch, WebFetch
- **Use Cases**: Codebase pattern discovery, best practices research, alternative approaches
- **Output**: Concise summaries (max 150-200 words)
- **Invoked By**: /orchestrate (research phase), /plan (optional), /report (optional)

#### 2. code-writer
- **Purpose**: Code generation and modification following project standards
- **Tools**: Read, Write, Edit, Bash, TodoWrite
- **Use Cases**: Implementation, applying fixes, code generation
- **Standards**: Discovers and applies CLAUDE.md standards automatically
- **Invoked By**: /orchestrate (implementation phase), /orchestrate (fix application)

#### 3. test-specialist
- **Purpose**: Test execution and failure analysis
- **Tools**: Bash, Read, Grep
- **Use Cases**: Running tests, analyzing failures, coverage reporting
- **Frameworks**: Multi-framework support (Jest, pytest, Neovim tests, etc.)
- **Invoked By**: /test (optional), /test-all (optional), /orchestrate (validation)

#### 4. plan-architect
- **Purpose**: Phased implementation plan generation
- **Tools**: Read, Write, Grep, Glob, WebSearch
- **Use Cases**: Creating structured plans from research, /implement compatibility
- **Output**: specs/plans/NNN_*.md files
- **Invoked By**: /plan, /orchestrate (planning phase)

### Specialized Agents (Phase 2)

#### 5. doc-writer
- **Purpose**: Documentation creation and maintenance
- **Tools**: Read, Write, Edit, Grep, Glob
- **Use Cases**: README updates, documentation sync, cross-referencing
- **Standards**: Unicode box-drawing, no emojis, CommonMark compliance
- **Invoked By**: /document, /orchestrate (documentation phase)

#### 6. code-reviewer
- **Purpose**: Standards compliance and quality review
- **Tools**: Read, Grep, Glob, Bash
- **Use Cases**: Refactoring analysis, standards enforcement, code quality
- **Output**: Structured reports with severity levels (Blocking/Warning/Suggestion)
- **Invoked By**: /refactor, /orchestrate (optional pre-commit checks)

#### 7. debug-specialist
- **Purpose**: Root cause analysis and diagnostic investigations
- **Tools**: Read, Bash, Grep, Glob, WebSearch
- **Use Cases**: Issue investigation, evidence gathering, solution proposals
- **Output**: Debug reports with multiple solution options
- **Invoked By**: /debug, /orchestrate (debugging loop)

#### 8. metrics-specialist
- **Purpose**: Performance analysis and optimization recommendations
- **Tools**: Read, Bash, Grep
- **Use Cases**: Analyzing metrics from .claude/data/metrics/, identifying bottlenecks
- **Output**: Statistical analysis with optimization suggestions
- **Dependencies**: Requires metrics infrastructure (hooks)
- **Invoked By**: Custom performance analysis commands (future)

#### 9. github-specialist
- **Purpose**: GitHub operations including PRs, issues, and CI/CD monitoring
- **Tools**: Read, Grep, Glob, Bash
- **Use Cases**: PR creation with metadata, issue management, CI workflow monitoring
- **Primary Tool**: gh CLI via Bash (MCP server optional supplement)
- **Output**: PR/issue URLs, CI status reports
- **Invoked By**: /implement (--create-pr), /orchestrate (workflow PRs)

#### 10. complexity_estimator
- **Purpose**: Context-aware complexity analysis for plan expansion/collapse decisions
- **Tools**: Read, Grep, Glob
- **Use Cases**: Auto-analysis mode in /expand and /collapse commands
- **Analysis Factors**: Architectural significance, integration complexity, risk, testing needs
- **Output**: JSON recommendations with 1-10 complexity scores and reasoning
- **Invoked By**: /expand (auto-analysis mode), /collapse (auto-analysis mode)

## Integration Patterns

### Pattern 1: Single Agent Delegation

Simple command delegates single task to specialized agent using behavioral injection:

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Investigate [issue] using debug-specialist protocol"
  prompt: "
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/debug-specialist.md

    You are acting as a Debug Specialist with the tools and constraints
    defined in that file.

    Debug Task: [Detailed investigation instructions]

    Context:
    - Issue description: [from user]
    - Project standards: CLAUDE.md

    Requirements:
    - Gather evidence
    - Identify root cause
    - Propose solutions

    Output: Debug report with findings
  "
}
```

**Used By**: /debug, /document, /refactor

### Pattern 2: Parallel Multi-Agent

Multiple agents of same type work on different topics simultaneously using behavioral injection:

```yaml
# Research Phase in /orchestrate - all in single message for parallel execution
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 1 using research-specialist protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    You are acting as a Research Specialist.
    [Topic 1 research task]
}
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 2 using research-specialist protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    You are acting as a Research Specialist.
    [Topic 2 research task]
}
Task {
  subagent_type: "general-purpose"
  description: "Research Topic 3 using research-specialist protocol"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    You are acting as a Research Specialist.
    [Topic 3 research task]
}
```

**Benefits**: Significant time savings (2-3x faster than sequential)

**Used By**: /orchestrate (research phase)

### Pattern 3: Sequential Pipeline

Output of one agent feeds into next agent in sequence using behavioral injection:

```yaml
# Planning Pipeline
# Step 1: Research using research-specialist behavior
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/research-specialist.md
    [Research task that generates summary]
}
# Extract research summary from output

# Step 2: Planning using plan-architect behavior
Task {
  subagent_type: "general-purpose"
  prompt: |
    Read and follow: /home/benjamin/.config/.claude/agents/plan-architect.md
    You are acting as a Plan Architect.

    Research findings: [summary from step 1]
    [Planning task]
}
```

**Used By**: /orchestrate (research → planning), /plan (optional research then planning)

### Pattern 4: Conditional Agent Loop

Agent invoked repeatedly until condition met or max iterations using behavioral injection:

```yaml
# Debugging Loop (max 3 iterations)
while tests_failing and iteration < 3:
  # 1. Debug using debug-specialist behavior
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/debug-specialist.md
      [Debug task]
  }

  # 2. Fix using code-writer behavior
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/code-writer.md
      [Apply fixes]
  }

  # 3. Test using test-specialist behavior
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/test-specialist.md
      [Validate fixes]
  }

  if tests_pass:
    break
```

**Used By**: /orchestrate (debugging loop)

### Pattern 5: Optional Agent Enhancement

Command works independently but can delegate to agent for better results using behavioral injection:

```yaml
# Direct execution for simple cases
if simple_task:
  execute_directly()
else:
  # Delegate to agent for complex cases
  Task {
    subagent_type: "general-purpose"
    prompt: |
      Read and follow: /home/benjamin/.config/.claude/agents/test-specialist.md
      [Test execution task]
  }
```

**Used By**: /test, /test-all, /implement (potential)

## Agent Invocation Best Practices

### 1. Prompt Construction

**DO**:
- Provide complete task description with objective
- Include necessary context from prior phases (summaries only)
- Reference CLAUDE.md for project standards
- Specify explicit success criteria
- Define expected output format

**DON'T**:
- Include orchestration routing logic
- Pass information about other parallel agents
- Provide excessive context (keep summaries <200 words)
- Use vague instructions without specifics

### 2. Context Management

**Supervisor (Command) Context**: Minimal
- Current workflow state
- High-level summaries only
- File paths (not contents)
- Checkpoint data

**Agent Context**: Comprehensive for their task
- Complete task description
- Relevant prior phase summaries
- Project standards reference
- Explicit requirements

### 3. Error Handling

All agent invocations should handle:
- **Timeout**: Retry with extended timeout or split task
- **Tool Access Errors**: Retry with fallback tools
- **Validation Failures**: Clarify prompt and retry
- **Max Retries**: Escalate to user with context

### 4. Agent Selection

Choose agent based on primary task:
- **Research/Analysis**: research-specialist
- **Code Generation**: code-writer
- **Testing**: test-specialist
- **Planning**: plan-architect
- **Documentation**: doc-writer
- **Code Review**: code-reviewer
- **Debugging**: debug-specialist
- **Performance**: metrics-specialist
- **Complexity Analysis**: complexity_estimator

## Command-Agent Matrix

| Command | Primary Agent | Secondary Agents | Pattern |
|---------|---------------|------------------|---------|
| /orchestrate | Varies by phase | All 10 agents | Pipeline + Parallel |
| /implement | None (direct) | Potential: code-writer, test-specialist, github-specialist | Direct execution |
| /expand | complexity_estimator (auto-mode) | None | Single delegation |
| /collapse | complexity_estimator (auto-mode) | None | Single delegation |
| /debug | debug-specialist | None | Single delegation |
| /plan | plan-architect | Optional: research-specialist | Sequential pipeline |
| /document | doc-writer | None | Single delegation |
| /refactor | code-reviewer | None | Single delegation |
| /test | test-specialist (optional) | None | Optional enhancement |
| /test-all | test-specialist (optional) | None | Optional enhancement |
| /report | research-specialist (optional) | None | Optional enhancement |

## Creating New Agents

To add a new specialized agent:

### 1. Define Agent Specification

Create `.claude/agents/new-agent.md` with frontmatter:

```markdown
---
allowed-tools: Read, Bash, Grep
description: One-line description of agent purpose
---

# New Agent Name

Purpose and responsibilities description.

## Core Capabilities
[What the agent can do]

## Standards Compliance
[How it follows project standards]

## Behavioral Guidelines
[How it should operate]

## Example Usage
[Example Task invocations]
```

### 2. Specify Tool Access

Only grant tools actually needed:
- **Read-only research**: Read, Grep, Glob, WebSearch, WebFetch
- **Code modification**: Read, Write, Edit, Bash
- **Testing**: Bash, Read, Grep
- **Documentation**: Read, Write, Edit, Grep, Glob

**Never grant unnecessary tools** (security through restriction)

### 3. Document Integration

Add to relevant commands' "Agent Usage" sections:
- When agent is invoked
- What prompts are used
- How output is processed
- Benefits of using agent

### 4. Test Agent

Verify:
- Frontmatter is valid YAML
- allowed-tools list is correct
- Agent can be invoked via Task tool
- Agent produces expected output
- Agent respects tool restrictions

## Troubleshooting

### Agent Not Found

**Symptom**: Task tool reports "unknown subagent type"

**Solutions**:
1. Verify agent file exists in `.claude/agents/`
2. Check frontmatter has `description:` field
3. Ensure filename matches `subagent_type` value

### Agent Access Denied

**Symptom**: Agent reports tool permission errors

**Solutions**:
1. Check `allowed-tools:` in agent frontmatter
2. Verify tool name spelling matches exactly
3. Ensure tool is available in Claude Code v2.0.1

### Agent Timeout

**Symptom**: Agent execution exceeds time limits

**Solutions**:
1. Increase timeout parameter in Task invocation
2. Split task into smaller subtasks
3. Reduce agent workload (less context, focused scope)

### Poor Agent Output

**Symptom**: Agent returns low-quality or incorrect results

**Solutions**:
1. Improve prompt clarity and specificity
2. Provide better context (but keep concise)
3. Add explicit success criteria
4. Show example of expected output format

## Command-Specific Agent Patterns

### /expand-phase Agent Integration

**Purpose**: Use agents to research complex phases before generating detailed 300-500+ line specifications.

**Agent Selection Logic**:
```bash
# Complexity indicators
if [[ $task_count > 5 ]] || [[ $file_count >= 10 ]] || [[ $unique_dirs > 2 ]]; then
  is_complex=true
  # Select appropriate agent behavior
fi
```

**Invocation Pattern**:

`/expand-phase` uses **general-purpose agents** with **behavioral injection**:

```markdown
Task tool:
  subagent_type: general-purpose  # Only valid agent type
  description: "Research phase context using research-specialist protocol"
  prompt: |
    Read and follow the behavioral guidelines from:
    /path/to/.claude/agents/research-specialist.md

    You are acting as a Research Specialist with constraints:
    - Read-only operations (tools: Read, Glob, Grep only)
    - Concise summaries (200-250 words max)
    - Specific file references with line numbers
    - Evidence-based findings only

    Research Task: [Phase objective]

    Phase Tasks:
    [List all tasks from phase]

    Requirements:
    1. Search codebase for files mentioned in tasks
    2. Identify existing patterns and implementations
    3. Find dependencies and integration points
    4. Assess current state vs target state

    Output Format:
    ## Current State
    - [File:line references]

    ## Patterns Found
    - [Concrete patterns]

    ## Recommendations
    - [Specific approaches]

    ## Challenges
    - [Potential issues]

    Word limit: 250 words
```

**Behavior Selection**:

- **research-specialist**: Default for codebase analysis (most complex phases)
- **code-reviewer**: For refactor/consolidate phases (standards compliance)
- **plan-architect**: For very complex phases (structure recommendations)

**Synthesis Process**:

After agent returns 200-250 word research:

1. Extract key findings (file:line refs, patterns, recommendations, challenges)
2. Map findings to each task in phase
3. Generate code examples based on patterns found
4. Create testing strategy covering current → target transition
5. Write implementation steps using actual file paths discovered

**Output**: 300-500+ line detailed specification with concrete details

**Performance**:
- Simple phases (direct expansion): <2 minutes
- Complex phases (agent-assisted): 3-5 minutes (acceptable for quality gain)

**Benefits**:
- Agent discovers actual file locations and patterns
- Specifications use concrete file:line references
- Testing strategy based on current codebase state
- Implementation steps reference real structures
- Reduces generic placeholder content

## Metrics Integration

Agents work with hooks for metrics collection:

**post-command-metrics.sh**: Collects agent invocation data
- Operation: agent name
- Duration: execution time
- Status: success/failure

**Metrics Location**: `.claude/data/metrics/YYYY-MM.jsonl`

**Analysis**: Use metrics-specialist to analyze agent performance

## Future Enhancements

Potential agent system improvements:

1. **Agent Composition**: Agents that invoke other agents
2. **Specialized Variants**: Language-specific agents (lua-specialist, etc.)
3. **Learning Agents**: Agents that improve from past executions
4. **Validation Agents**: Pre-commit quality gates
5. **Migration Agents**: Automated refactoring specialists

## References

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code/)
- [Task Tool Reference](https://docs.claude.com/en/docs/claude-code/task-tool)
- [Agent System Design](../specs/reports/015_agents_and_hooks_extension_opportunities.md)
- [Implementation Plan](../specs/plans/014_agents_and_necessary_hooks_implementation.md)

## Quick Reference

### Agent Tool Access Summary

| Agent | Read | Write | Edit | Bash | Grep | Glob | TodoWrite | WebSearch | WebFetch |
|-------|------|-------|------|------|------|------|-----------|-----------|----------|
| research-specialist | ✓ | | | | ✓ | ✓ | | ✓ | ✓ |
| code-writer | ✓ | ✓ | ✓ | ✓ | | | ✓ | | |
| test-specialist | ✓ | | | ✓ | ✓ | | | | |
| plan-architect | ✓ | ✓ | | | ✓ | ✓ | | ✓ | |
| doc-writer | ✓ | ✓ | ✓ | | ✓ | ✓ | | | |
| code-reviewer | ✓ | | | ✓ | ✓ | ✓ | | | |
| debug-specialist | ✓ | | | ✓ | ✓ | ✓ | | ✓ | |
| metrics-specialist | ✓ | | | ✓ | ✓ | | | | |
| github-specialist | ✓ | | | ✓ | ✓ | ✓ | | | |
| complexity_estimator | ✓ | | | | ✓ | ✓ | | | |

### Common Invocation Template

```yaml
Task {
  subagent_type: "general-purpose"
  description: "[concise task description] using [agent-name] protocol"
  prompt: "
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/[agent-name].md

    You are acting as a [Agent Name] with the tools and constraints
    defined in that file.

    [Task Type]: [Specific task]

    Context:
    - [Key context 1]
    - [Key context 2]
    - Project Standards: CLAUDE.md

    Requirements:
    - [Requirement 1]
    - [Requirement 2]

    Output:
    - [Expected output description]
  "
}
```
