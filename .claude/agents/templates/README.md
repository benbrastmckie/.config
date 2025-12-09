# Agent Templates

This directory contains reusable templates for specialized agents.

## Purpose

Agent templates provide structured starting points for creating new specialized agents. They include standard sections, behavioral patterns, and integration guidelines that ensure consistency across the agent ecosystem.

## Templates

### coordinator-template.md

Template for creating coordinator agents that implement the three-tier agent pattern (orchestrator -> coordinator -> specialist). Coordinators manage parallel specialist invocation, hard barrier validation, and metadata aggregation.

**Use Cases**:
- Testing coordination: Parallel test-specialist invocation for multi-module test suites
- Debug coordination: Parallel investigation vectors for root cause analysis
- Repair coordination: Parallel error dimension analysis for comprehensive fix plans

**Key Features**:
- Hard barrier pattern enforcement (path pre-calculation, artifact validation, fail-fast)
- Parallel Task invocation for 40-60% time savings
- Metadata-only context passing for 95% context reduction
- Two invocation modes: automated decomposition vs pre-decomposed tasks
- Structured error return protocol
- Template variables for easy customization

**Template Variables**:
- `{{COORDINATOR_TYPE}}`: Name of coordinator (e.g., Testing Coordinator)
- `{{SPECIALIST_TYPE}}`: Specialist agent type (e.g., test-specialist)
- `{{ARTIFACT_TYPE}}`: Type of artifact produced (e.g., reports)
- `{{METADATA_FIELDS}}`: Fields to extract (e.g., title, findings_count)
- See template for complete variable list

**Usage**:
```bash
# When creating a new coordinator agent
cp .claude/agents/templates/coordinator-template.md .claude/agents/my-coordinator.md

# Replace template variables:
# 1. {{COORDINATOR_TYPE}} -> Testing Coordinator
# 2. {{SPECIALIST_TYPE}} -> test-specialist
# 3. {{ARTIFACT_TYPE}} -> results
# 4. Configure metadata extraction and return format
```

**Related Documentation**:
- [Three-Tier Agent Pattern Guide](../../docs/concepts/three-tier-agent-pattern.md)
- [Research Coordinator](../research-coordinator.md) - Reference implementation

---

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
