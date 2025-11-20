# Command vs Agent Decision Flowchart

**Path**: docs → reference → decision-trees → command-vs-agent-flowchart.md

Quick decision tree for determining whether to create a slash command or specialized agent.

## Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ I need to implement new functionality in Claude Code        │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
           ┌───────────────────────────────┐
           │ Is it user-facing functionality? │
           └───────────┬───────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
        ▼ YES                         ▼ NO
┌──────────────────┐          ┌─────────────────┐
│ CREATE COMMAND   │          │ CREATE AGENT    │
│                  │          │                 │
│ User types       │          │ Commands invoke │
│ /command-name    │          │ via Task tool   │
└──────────────────┘          └─────────────────┘
        │                             │
        │                             │
        ▼                             ▼
   Does command              Does agent need
   need specialized          multiple variants
   sub-workflows?            or specializations?
        │                             │
        ▼ YES                         ▼ YES
┌──────────────────┐          ┌─────────────────┐
│ Command invokes  │          │ Create multiple │
│ agents via       │          │ agent variants  │
│ Task tool with   │          │ (e.g., research │
│ behavioral       │          │ -analyst,       │
│ injection        │          │ debug-analyst)  │
└──────────────────┘          └─────────────────┘
```

## Decision Criteria

### Create a Slash Command When:

1. **User-Facing Workflow**
   - Users type `/command-name` directly
   - Primary entry point for functionality
   - Examples: `/plan`, `/implement`, `/research`

2. **Multi-Step Coordination**
   - Orchestrates multiple agents or phases
   - Manages workflow state and checkpoints
   - Handles user input and validation

3. **Standards Discovery**
   - Reads CLAUDE.md for project configuration
   - Applies standards to generated code
   - Discovers testing protocols

4. **File Management**
   - Creates artifacts in specs/ directories
   - Updates plan files and checkpoints
   - Manages git operations

### Create a Specialized Agent When:

1. **Delegated Sub-Task**
   - Called by commands via Task tool
   - Not directly user-facing
   - Examples: `plan-architect`, `implementation-researcher`

2. **Focused Expertise**
   - Single, well-defined responsibility
   - Reusable across multiple commands
   - Clear behavioral specification

3. **Parallel Execution**
   - Can run concurrently with other agents
   - Independent workflow with minimal coordination
   - Returns metadata to supervisor

4. **Context Isolation**
   - Operates on isolated domain context
   - Doesn't need full workflow state
   - Returns structured results

## Examples

### Commands (User-Facing)

| Command | Purpose | Agents Invoked |
|---------|---------|----------------|
| `/plan` | Create implementation plans | plan-architect, complexity-evaluator, expander |
| `/implement` | Execute plans phase-by-phase | implementation-researcher, code-writer, test-specialist |
| `/research` | Research topics | research-analyst (2-4 parallel) |
| `/orchestrate` | Full workflow coordination | Multiple agents across 7 phases |
| `/debug` | Investigate issues | debug-analyst (parallel investigations) |

### Agents (Command-Invoked)

| Agent | Purpose | Invoked By | Specialization |
|-------|---------|------------|----------------|
| plan-architect | Design implementation plans | /plan, /orchestrate | Planning expertise |
| implementation-researcher | Explore codebase before phases | /implement | Codebase analysis |
| research-analyst | Investigate topics in parallel | /research, /orchestrate | Research methodology |
| debug-analyst | Root cause investigation | /debug, /implement | Debugging techniques |
| test-specialist | Run and analyze tests | /implement, /orchestrate | Test execution |

## Anti-Patterns

### Don't Create Commands When:

- ❌ Functionality is only called by other commands
- ❌ No user input or workflow coordination needed
- ❌ Task is too narrow/focused
- ❌ Command would just wrap a single agent call

**Instead**: Create an agent and invoke via Task tool

### Don't Create Agents When:

- ❌ Users need to invoke directly
- ❌ Requires complex multi-phase coordination
- ❌ Needs to manage checkpoints and state
- ❌ Performs standards discovery from CLAUDE.md

**Instead**: Create a command that orchestrates workflow

## Hybrid Pattern: Command + Agents

Most complex workflows use both:

```
/orchestrate (COMMAND)
    ↓
    ├─ Phase 1: Research
    │   ├─ research-analyst (AGENT) [parallel]
    │   ├─ research-analyst (AGENT) [parallel]
    │   └─ research-analyst (AGENT) [parallel]
    │
    ├─ Phase 2: Planning
    │   └─ plan-architect (AGENT)
    │
    ├─ Phase 3: Implementation
    │   ├─ implementation-researcher (AGENT) [per complex phase]
    │   └─ code-writer (AGENT)
    │
    └─ Phase 4: Debugging
        ├─ debug-analyst (AGENT) [parallel]
        └─ debug-analyst (AGENT) [parallel]
```

**Pattern**: Command coordinates workflow, agents execute specialized tasks

## Quick Decision Matrix

| Criteria | Command | Agent |
|----------|---------|-------|
| User invokes directly | ✓ | ✗ |
| Called via Task tool | ✗ | ✓ |
| Multi-phase coordination | ✓ | ✗ |
| Single focused task | ✗ | ✓ |
| Standards discovery | ✓ | ✗ |
| Parallel execution | ✗ | ✓ |
| Checkpoint management | ✓ | ✗ |
| Context isolation | ✗ | ✓ |
| File/artifact creation | ✓ | Mixed |
| Returns to supervisor | ✗ | ✓ |

## Related Documentation

- [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md) - How to create commands
- [Agent Development Guide](../guides/development/agent-development/agent-development-fundamentals.md) - How to create agents
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md) - How commands invoke agents
- [Command Reference](../reference/standards/command-reference.md) - All available commands
- [Agent Reference](../reference/standards/agent-reference.md) - All available agents

## Navigation

**Docs Index**: [← Back to Docs](../README.md)
**Quick Reference**: [← Back to Quick Reference](./README.md)
