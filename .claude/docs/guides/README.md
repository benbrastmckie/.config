# Guides Documentation

## Purpose

Task-focused how-to guides for specific development activities. Use this section when you have a concrete task to accomplish and need step-by-step instructions for command creation, agent integration, standards implementation, or system optimization.

## Navigation

- [Documentation Index](../README.md)
- [Reference](../reference/) - Quick lookup for commands, agents, and standards
- [Concepts](../concepts/) - Understanding-oriented architectural explanations
- [Workflows](../workflows/) - Learning-oriented step-by-step tutorials

## Directory Structure

The guides are organized into subdirectories by topic:

```
guides/
├── README.md                   This index file
├── commands/                   Command-specific documentation (12 files)
├── development/                Creating commands and agents (14 files)
│   ├── command-development/    Command creation guides
│   └── agent-development/      Agent creation guides
├── orchestration/              Workflow orchestration (10 files)
├── patterns/                   Reusable patterns (22 files)
│   ├── command-patterns/       Command implementation patterns
│   └── execution-enforcement/  Execution reliability patterns
└── templates/                  File templates (3 files)
```

## Quick Start by Task

### I want to create a new command
Start with [Command Development Fundamentals](development/command-development/command-development-fundamentals.md)

### I want to create a new agent
Start with [Agent Development Fundamentals](development/agent-development/agent-development-fundamentals.md)

### I want to use a specific command
Browse [Command Guides](commands/) for detailed usage instructions

### I want to orchestrate a workflow
Start with [Orchestration Best Practices](orchestration/orchestration-best-practices.md)

### I want to find a reusable pattern
Browse [Patterns](patterns/) for tested implementation patterns

## Subdirectory Index

### [Commands](commands/)
Detailed documentation for each slash command:
- Build, Debug, Plan, Research, Revise commands
- Setup, Test, Document, Expand, Collapse commands

### [Development](development/)
Guides for creating commands and agents:
- **Command Development**: Architecture, patterns, testing, troubleshooting
- **Agent Development**: Fundamentals, patterns, testing, advanced topics
- Model selection and utility library guides

### [Orchestration](orchestration/)
Workflow orchestration documentation:
- Orchestration best practices and troubleshooting
- State machine development and migration
- Workflow classification and hierarchical supervision

### [Patterns](patterns/)
Reusable implementation patterns:
- **Command Patterns**: Agent invocation, checkpoints, integration
- **Execution Enforcement**: Ensuring reliable execution
- Logging, testing, error handling, performance patterns

### [Templates](templates/)
File templates for new components:
- Bash block templates
- Command guide templates
- Executable command templates

## Document Migration Note

This directory was restructured in November 2025. Files were moved from a flat structure into organized subdirectories for improved discoverability. If you're looking for a specific guide:

1. **Command guides** (e.g., build-command-guide.md) → [commands/](commands/)
2. **Agent development guides** → [development/agent-development/](development/agent-development/)
3. **Command development guides** → [development/command-development/](development/command-development/)
4. **Orchestration guides** → [orchestration/](orchestration/)
5. **Pattern guides** → [patterns/](patterns/)
6. **Template files** → [templates/](templates/)

Archived files (redirect stubs and unused content) are in [../archive/guides/](../archive/guides/).

## Related Documentation

- [Command Reference](../reference/standards/command-reference.md) - Complete command catalog
- [Agent Reference](../reference/standards/agent-reference.md) - Complete agent catalog
- [Command Architecture Standards](../reference/architecture/overview.md)
- [Patterns Catalog](../concepts/patterns/README.md) - Architectural patterns
