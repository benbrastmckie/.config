# Claude Agent System Documentation

[Back to ProofChecker](../../README.md) | [Architecture](../README.md) | [CLAUDE.md](../CLAUDE.md)

This directory contains the documentation for the `.claude/` agent system. The system provides structured task management, research workflows, and implementation automation for ProofChecker development. For comprehensive system details, see [architecture/system-overview.md](architecture/system-overview.md).

---

## Documentation Map

```
.claude/docs/
├── README.md                    # This file - documentation hub
├── guides/                      # How-to guides
│   ├── user-guide.md           # Comprehensive command workflows guide
│   ├── user-installation.md    # Quick-start for new users
│   ├── copy-claude-directory.md # Copy .claude/ to another project
│   ├── neovim-integration.md   # Hook-based readiness signaling and TTS/STT
│   ├── component-selection.md  # When to create command vs skill vs agent
│   ├── creating-commands.md    # How to create commands
│   ├── creating-skills.md      # How to create skills
│   ├── creating-agents.md      # How to create agents
│   ├── context-loading-best-practices.md # Context loading patterns
│   └── permission-configuration.md # Permission setup
├── examples/                    # Integration examples
│   ├── research-flow-example.md # End-to-end research flow
│   └── learn-flow-example.md    # Tag extraction and task creation
├── templates/                   # Reusable templates
│   ├── README.md               # Template overview
│   ├── command-template.md     # Command template
│   └── agent-template.md       # Agent template
└── architecture/               # Architecture documentation
    └── system-overview.md      # Three-layer architecture overview
```

---

## System Architecture

The `.claude/` directory implements a three-layer architecture: Commands, Skills, and Agents, with checkpoint-based execution and language-specific routing. All system details, including the task lifecycle, state management, and git integration patterns, are documented in [architecture/system-overview.md](architecture/system-overview.md).

---

## Guides

### Getting Started
- [User Installation Guide](guides/user-installation.md) - Install Claude Code, set up ProofChecker, and learn the basics
- [Command Workflows User Guide](guides/user-guide.md) - Comprehensive guide to all commands with examples and troubleshooting
- [Copy .claude/ Directory](guides/copy-claude-directory.md) - Install the agent system in another project
- [Neovim Integration](guides/neovim-integration.md) - Hook-based readiness signaling, TTS notifications, and STT voice input

### Component Development
- [Component Selection](guides/component-selection.md) - Decision tree for creating commands, skills, or agents
- [Creating Commands](guides/creating-commands.md) - Define new user-invocable operations
- [Creating Skills](guides/creating-skills.md) - Implement specialized workflow skills using the thin wrapper pattern
- [Creating Agents](guides/creating-agents.md) - Build execution agents for research and implementation

### Advanced Topics
- [Context Loading Best Practices](guides/context-loading-best-practices.md) - Lazy context loading patterns and strategies
- [Permission Configuration](guides/permission-configuration.md) - Configure file access and tool permissions

---

## Examples

- [Research Flow Example](examples/research-flow-example.md) - Complete walkthrough of the research command execution flow
- [Learn Flow Example](examples/learn-flow-example.md) - Tag extraction from source files and interactive task creation

---

## Templates

Reusable templates for creating new system components are available in [templates/](templates/). See [templates/README.md](templates/README.md) for an overview of available templates and usage instructions.

---

## Related Documentation

### Core References
- [CLAUDE.md](../CLAUDE.md) - Quick reference entry point with command syntax and workflow summaries
- [README.md](../README.md) - Detailed system architecture and component specifications

### ProofChecker Project
- [ProofChecker README](../../README.md) - Main project documentation
- [ProofChecker docs/](../../docs/) - Project-specific documentation

---

[Back to ProofChecker](../../README.md) | [Architecture](../README.md) | [CLAUDE.md](../CLAUDE.md)
