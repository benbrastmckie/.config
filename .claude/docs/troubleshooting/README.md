# Troubleshooting Guide Index

This directory contains troubleshooting guides for common issues in the .claude/ system.

## Anti-Pattern Detection and Remediation

### [Inline Template Duplication](./inline-template-duplication.md)
- **Problem**: Behavioral content duplicated in command files instead of referenced from agent files
- **Category**: Anti-Pattern
- **Priority**: Medium (affects maintainability, not functionality)
- **Symptoms**: Large command files, STEP sequences in commands, maintenance burden
- **Fix Time**: 15-30 minutes per command
- **Impact**: 90% code reduction per agent invocation when fixed

## Agent Delegation Issues

### [Agent Delegation Issues](./agent-delegation-issues.md)
- **Problem**: Commands not properly delegating to agents
- **Category**: Configuration/Implementation
- **Symptoms**: Commands executing tasks directly instead of invoking agents
- **Related**: Behavioral injection pattern

### [Command Not Delegating to Agents](./command-not-delegating-to-agents.md)
- **Problem**: Commands failing to delegate work to specialized agents
- **Category**: Implementation
- **Symptoms**: Commands doing work that should be delegated
- **Related**: Agent integration patterns

## Quick Reference

### By Problem Type

**Anti-Patterns:**
- [Inline Template Duplication](./inline-template-duplication.md)

**Configuration Issues:**
- [Agent Delegation Issues](./agent-delegation-issues.md)
- [Command Not Delegating to Agents](./command-not-delegating-to-agents.md)

### By Symptom

**Large/Bloated Files:**
- [Inline Template Duplication](./inline-template-duplication.md) - Command files >2000 lines

**Agent Invocation Problems:**
- [Agent Delegation Issues](./agent-delegation-issues.md) - Agents not being invoked
- [Command Not Delegating to Agents](./command-not-delegating-to-agents.md) - Commands not using agents

**Maintenance Burden:**
- [Inline Template Duplication](./inline-template-duplication.md) - Updating behavior in multiple files

## Related Documentation

- [Command Architecture Standards](../reference/command_architecture_standards.md)
- [Template vs Behavioral Distinction](../reference/template-vs-behavioral-distinction.md)
- [Behavioral Injection Pattern](../concepts/patterns/behavioral-injection.md)
- [Agent Development Guide](../guides/agent-development-guide.md)
- [Command Development Guide](../guides/command-development-guide.md)
