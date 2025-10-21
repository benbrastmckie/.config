# Guides Documentation

## Purpose

Task-focused how-to guides for specific development activities. Use this section when you have a concrete task to accomplish and need step-by-step instructions for command creation, agent integration, standards implementation, or system optimization.

## Navigation

- [← Documentation Index](../README.md)
- [Reference](../reference/) - Quick lookup for commands, agents, and standards
- [Concepts](../concepts/) - Understanding-oriented architectural explanations
- [Workflows](../workflows/) - Learning-oriented step-by-step tutorials

## Documents in This Section

### [Command Development Guide](command-development-guide.md)
**Purpose**: Comprehensive guide for developing custom slash commands with standards integration, agent coordination, and testing protocols. Consolidates command creation and authoring best practices.

**Use Cases**:
- When creating a new slash command for a repetitive workflow
- To understand command file structure, metadata fields, and workflow patterns
- When integrating standards discovery and application in commands
- To learn how to coordinate multiple agents using behavioral injection
- When implementing metadata-only context passing (95% context reduction)

**See Also**: [Command Reference](../reference/command-reference.md), [Command Patterns](command-patterns.md), [Command Architecture Standards](../reference/command_architecture_standards.md), [Hierarchical Agents](../concepts/hierarchical_agents.md)

---

### [Agent Development Guide](agent-development-guide.md)
**Purpose**: Comprehensive guide for creating agent behavioral files that follow the behavioral injection pattern. Consolidates agent creation and authoring best practices.

**Use Cases**:
- When creating new agent behavioral files (REQUIRED reading)
- To understand agent file structure, frontmatter metadata, and output requirements
- To understand anti-patterns and correct patterns for agent development
- When designing agents compatible with metadata extraction utilities
- To ensure agents never invoke slash commands for artifact creation

**See Also**: [Agent Reference](../reference/agent-reference.md), [Command Development Guide](command-development-guide.md), [Hierarchical Agents](../concepts/hierarchical_agents.md), [Troubleshooting](../troubleshooting/agent-delegation-issues.md)

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

### [Execution Enforcement Guide](execution-enforcement-guide.md)
**Purpose**: Comprehensive guide for creating and migrating commands and agents to use execution enforcement patterns (Standards 0 and 0.5). Consolidates migration process, enforcement patterns, validation techniques, and troubleshooting.

**Use Cases**:
- When creating new commands or agents with reliability requirements
- To migrate existing commands/agents from descriptive to enforcement language
- To achieve 100% file creation rates (vs 60-80% without enforcement)
- When improving audit scores to ≥95/100 for production readiness
- To understand the 11 enforcement patterns and their scoring impact

**See Also**: [Migration Testing Guide](migration-testing.md), [Command Architecture Standards](../reference/command_architecture_standards.md), [Command Development Guide](command-development-guide.md), [Agent Development Guide](agent-development-guide.md)

---

### [Migration Testing Guide](migration-testing.md)
**Purpose**: Testing procedures for execution enforcement migrations including test infrastructure, file creation validation, and tracking/reporting.

**Use Cases**:
- When testing command/agent migrations for enforcement compliance
- To run file creation rate tests (target: 10/10 successes)
- When validating audit scores (target: ≥95/100)
- To test verification checkpoints and fallback mechanisms

**See Also**: [Execution Enforcement Guide](execution-enforcement-guide.md), [Command Architecture Standards](../reference/command_architecture_standards.md)

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
├── README.md                         (this file)
├── command-development-guide.md      Comprehensive command development (consolidated)
├── agent-development-guide.md        Comprehensive agent development (consolidated)
├── using-agents.md                   Agent integration patterns
├── standards-integration.md          CLAUDE.md standards discovery
├── command-patterns.md               Reusable implementation patterns
├── command-examples.md               Example command patterns
├── logging-patterns.md               Structured logging standards
├── setup-command-guide.md            /setup utilities documentation
├── efficiency-guide.md               Performance optimization features
├── error-enhancement-guide.md        Error analysis and suggestions
├── data-management.md                .claude/data/ ecosystem guide
├── execution-enforcement-guide.md    Execution enforcement (Standards 0 & 0.5)
└── migration-testing.md              Testing procedures for migrations
```

**Note**: The following guides were consolidated into `execution-enforcement-guide.md` (2025-10-21):
- `execution-enforcement-migration-guide.md` (migration process)
- `enforcement-patterns.md` (pattern library)
- `migration-validation.md` (validation techniques)
- `audit-execution-enforcement.md` (audit process)

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
