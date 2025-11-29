# Agent Templates

This directory contains reusable templates for specialized agents.

## Purpose

Agent templates provide structured starting points for creating new specialized agents. They include standard sections, behavioral patterns, and integration guidelines that ensure consistency across the agent ecosystem.

## Templates

### sub-supervisor-template.md

Template for creating hierarchical supervisors that coordinate multiple specialized subagents.

**Use Cases**:
- Research supervision: Coordinating 2-4 research agents for complex topics
- Implementation supervision: Managing parallel implementation tracks
- Testing supervision: Coordinating unit, integration, and E2E test agents

**Key Features**:
- Metadata extraction pattern for context reduction
- Forward message pattern for efficiency
- Subagent delegation with behavioral injection
- Progress tracking and checkpoint coordination

**Usage**:
```bash
# When creating a new supervisor agent
cp .claude/agents/templates/sub-supervisor-template.md .claude/agents/my-new-supervisor.md

# Customize the following sections:
# 1. Agent name and purpose
# 2. Subagent types and roles
# 3. Coordination logic
# 4. Output format
```

## Template Structure

All agent templates follow this structure:

1. **Metadata**: Agent name, purpose, complexity
2. **Context**: What information the agent receives
3. **Behavioral Instructions**: How the agent should operate
4. **Subagent Delegation**: How to invoke specialized subagents (if applicable)
5. **Output Format**: What the agent should return

## Creating New Templates

When creating a new agent template:

1. **Document the use case**: When should this template be used?
2. **Include examples**: Show concrete usage scenarios
3. **Follow patterns**: Use established patterns (metadata extraction, forward message, etc.)
4. **Test thoroughly**: Ensure the template produces working agents
5. **Update this README**: Add the new template to the list above

## Related Documentation

- [Agent Development Guide](../../docs/guides/development/agent-development/agent-development-fundamentals.md) - Complete guide to creating agents
- [Agent Reference](../../docs/reference/standards/agent-reference.md) - Catalog of all specialized agents
- [Hierarchical Agent Architecture](../../docs/concepts/hierarchical-agents.md) - Multi-level coordination patterns
- [Behavioral Injection Pattern](../../docs/concepts/patterns/behavioral-injection.md) - Agent invocation pattern

## vs Commands Templates

**Agent templates** (this directory):
- Used to create new specialized agents
- Define agent behavior and coordination
- Invoked via Task tool with behavioral files

**Command templates** (../commands/templates/):
- Used to generate implementation plans
- Define project structure and phases
- Invoked via /plan-from-template command

Both types of templates serve different purposes and should not be confused.

## Navigation

- [← Parent Directory](../README.md)
- [Related: Agent Development Guide](../../docs/guides/development/agent-development/README.md)
- [Related: Command Templates](../../commands/templates/README.md)
