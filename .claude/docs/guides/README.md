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
├── setup/                      Setup and configuration guides
├── skills/                     Skills development guides
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
- **[Command Development](development/command-development/)**: Architecture, patterns, testing, troubleshooting
- **[Agent Development](development/agent-development/)**: Fundamentals, patterns, testing, advanced topics
- Model selection and utility library guides

### [Orchestration](orchestration/)
Workflow orchestration documentation:
- Orchestration best practices and troubleshooting
- State machine development and migration
- Workflow classification and hierarchical supervision

### [Patterns](patterns/)
Reusable implementation patterns:
- **[Command Patterns](patterns/command-patterns/)**: Agent invocation, checkpoints, integration
- **[Execution Enforcement](patterns/execution-enforcement/)**: Ensuring reliable execution
- Logging, testing, error handling, performance patterns

### [Setup](setup/)
Setup and configuration guides:
- Setup command modes and analysis
- Standards extraction strategies
- Bloat detection and cleanup

### [Skills](skills/)
Skills development and usage guides:
- Document converter skill development
- Skills architecture and authoring

### [Templates](templates/)
File templates for new components:
- Bash block templates
- Command guide templates
- Executable command templates


## Navigation

- [← Parent Directory](../README.md)
- [Subdirectory: commands/](commands/README.md)
- [Subdirectory: development/](development/README.md)
- [Subdirectory: orchestration/](orchestration/README.md)
- [Subdirectory: patterns/](patterns/README.md)
- [Related: Reference](../reference/README.md)
- [Related: Concepts](../concepts/README.md)
