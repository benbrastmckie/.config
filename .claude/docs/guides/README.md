# Guides Documentation

## Purpose

Task-focused how-to guides for specific development activities. Use this section when you have a concrete task to accomplish and need step-by-step instructions for command creation, agent integration, standards implementation, or system optimization.

## Navigation

- [← Documentation Index](../README.md)
- [Reference](../reference/) - Quick lookup for commands, agents, and standards
- [Concepts](../concepts/) - Understanding-oriented architectural explanations
- [Workflows](../workflows/) - Learning-oriented step-by-step tutorials

## Documents in This Section

### [Creating Commands](creating-commands.md)
**Purpose**: Comprehensive guide for developing custom slash commands with standards integration, agent coordination, and testing protocols.

**Use Cases**:
- When creating a new slash command for a repetitive workflow
- To understand command file structure, metadata fields, and workflow patterns
- When integrating standards discovery and application in commands
- To learn how to coordinate multiple agents within a command

**See Also**: [Command Reference](../reference/command-reference.md), [Command Patterns](command-patterns.md), [Command Architecture Standards](../reference/command_architecture_standards.md)

---

### [Creating Agents](creating-agents.md)
**Purpose**: Guide for creating and maintaining custom Claude Code agents with proper tool restrictions and behavioral guidelines.

**Use Cases**:
- When you need a specialized agent for a specific task domain
- To understand agent file structure, frontmatter metadata, and output requirements
- When designing agents compatible with metadata extraction utilities
- To learn proper tool selection for different agent capabilities

**See Also**: [Agent Reference](../reference/agent-reference.md), [Using Agents](using-agents.md), [Command Architecture Standards](../reference/command_architecture_standards.md)

---

### [Using Agents in Commands](using-agents.md)
**Purpose**: Comprehensive guide for integrating and using specialized agents in the Claude Code workflow system with layered context architecture.

**Use Cases**:
- When implementing agent invocation in a command (REQUIRED reading)
- To understand the correct pattern for behavioral injection and context layering
- When optimizing multi-agent workflows for context efficiency
- To debug agent invocation failures or context consumption issues

**See Also**: [Creating Agents](creating-agents.md), [Agent Reference](../reference/agent-reference.md), [Hierarchical Agents](../concepts/hierarchical_agents.md)

---

### [Standards Integration Guide](standards-integration.md)
**Purpose**: Comprehensive guide for discovering, parsing, and applying project standards from CLAUDE.md files in slash commands.

**Use Cases**:
- When implementing standards discovery in a new command
- To understand how to parse CLAUDE.md sections and extract relevant rules
- When handling subdirectory-specific standards and inheritance
- To debug standards discovery or parsing issues

**See Also**: [CLAUDE.md Section Schema](../reference/claude-md-section-schema.md), [Command Architecture Standards](../reference/command_architecture_standards.md)

---

### [Command Implementation Patterns](command-patterns.md)
**Purpose**: Reusable patterns for agent invocation, checkpoint management, error recovery, and testing integration.

**Use Cases**:
- When implementing common command patterns like agent chains or parallel execution
- To find tested patterns for checkpoint management and error recovery
- When integrating testing, logging, or progress streaming in commands
- To ensure consistent implementation across related commands

**See Also**: [Command Examples](command-examples.md), [Creating Commands](creating-commands.md), [Logging Patterns](logging-patterns.md)

---

### [Command Examples Reference](command-examples.md)
**Purpose**: Reusable command patterns and examples for dry-run mode, dashboard progress, checkpoints, testing, and git commits.

**Use Cases**:
- When implementing dry-run preview functionality in commands
- To add dashboard progress tracking to long-running workflows
- When creating checkpoint save/restore patterns
- To standardize test execution and git commit patterns across commands

**See Also**: [Command Patterns](command-patterns.md), [Logging Patterns](logging-patterns.md)

---

### [Logging Patterns Reference](logging-patterns.md)
**Purpose**: Standardized logging patterns for agents and commands to ensure consistent, parseable output with progress markers and error logging.

**Use Cases**:
- When adding progress markers to long-running operations
- To implement structured logging for agent invocations and phase transitions
- When creating parseable error logs with specific formats
- To ensure consistency across command logging output

**See Also**: [Command Patterns](command-patterns.md), [Command Examples](command-examples.md)

---

### [Setup Command Guide](setup-command-guide.md)
**Purpose**: Guide for /setup command ecosystem utilities including testing detection, protocol generation, context optimization, and README scaffolding.

**Use Cases**:
- When configuring CLAUDE.md for a new project with /setup
- To understand testing framework detection and scoring system
- When optimizing bloated CLAUDE.md files (IMPORTANT: CLAUDE.md only, not command files)
- To generate README files across project directories

**See Also**: [Standards Integration Guide](standards-integration.md), [CLAUDE.md Section Schema](../reference/claude-md-section-schema.md)

---

### [Workflow Efficiency Guide](efficiency-guide.md)
**Purpose**: Documentation of efficiency enhancements including dynamic agent selection, progress streaming, intelligent parallelization, and plan wizard.

**Use Cases**:
- To understand how dynamic agent selection optimizes execution based on phase complexity
- When implementing progress streaming in long-running operations
- To leverage intelligent parallelization with dependency management
- When using the plan wizard for guided plan creation

**See Also**: [Orchestration Guide](../workflows/orchestration-guide.md), [Adaptive Planning Guide](../workflows/adaptive-planning-guide.md)

---

### [Error Enhancement Guide](error-enhancement-guide.md)
**Purpose**: Complete guide to enhanced error messages and intelligent fix suggestions for test failures and command errors.

**Use Cases**:
- To understand how error enhancement works and which commands use it
- When implementing error analysis in new commands
- To interpret enhanced error messages with location context and suggestions
- When debugging syntax errors, test failures, or file-not-found issues

**See Also**: [Command Patterns](command-patterns.md), [Logging Patterns](logging-patterns.md)

---

### [Data Management Guide](data-management.md)
**Purpose**: Comprehensive guide to the .claude/data/ directory ecosystem including checkpoints, logs, metrics, and registry.

**Use Cases**:
- To understand checkpoint format, creation, and auto-resume behavior
- When implementing checkpoint support in long-running commands
- To interpret logs, metrics, and registry data for debugging
- When managing data cleanup and retention policies

**See Also**: [Checkpoint Template Guide](../workflows/checkpoint_template_guide.md), [Development Workflow](../concepts/development-workflow.md)

---

## Quick Start

### Create Your First Command
1. Review [Command Architecture Standards](../reference/command_architecture_standards.md)
2. Follow [Creating Commands](creating-commands.md) guide
3. Reference [Command Patterns](command-patterns.md) for implementation
4. Test with examples from [Command Examples](command-examples.md)

### Integrate an Agent
1. Review [Agent Reference](../reference/agent-reference.md) for available agents
2. Follow [Using Agents](using-agents.md) for correct invocation pattern
3. Reference [Command Patterns](command-patterns.md) for agent chains
4. Optimize with [Hierarchical Agents](../concepts/hierarchical_agents.md)

### Add Standards Discovery
1. Review [CLAUDE.md Section Schema](../reference/claude-md-section-schema.md)
2. Follow [Standards Integration Guide](standards-integration.md)
3. Test discovery with example CLAUDE.md files

## Directory Structure

```
guides/
├── README.md                    (this file)
├── creating-commands.md         Command development guide
├── creating-agents.md           Agent creation guide
├── using-agents.md              Agent integration patterns
├── standards-integration.md     CLAUDE.md standards discovery
├── command-patterns.md          Reusable implementation patterns
├── command-examples.md          Example command patterns
├── logging-patterns.md          Structured logging standards
├── setup-command-guide.md       /setup utilities documentation
├── efficiency-guide.md          Performance optimization features
├── error-enhancement-guide.md   Error analysis and suggestions
└── data-management.md           .claude/data/ ecosystem guide
```

## Related Documentation

**Other Categories**:
- [Reference](../reference/) - Quick lookup for command/agent APIs and standards schemas
- [Concepts](../concepts/) - Architectural principles underlying these guides
- [Workflows](../workflows/) - End-to-end tutorials combining multiple guides

**External Directories**:
- [Commands](../../commands/) - Command implementations to reference
- [Agents](../../agents/) - Agent implementations to reference
- [Libraries](../../lib/) - Utility functions used in guides
- [Templates](../../templates/) - Templates referenced in guides
- [Data](../../data/) - Runtime data managed by guides
