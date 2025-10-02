# Docs Directory

Comprehensive documentation and integration guides for Claude Code configuration, including TTS system, agent development, command standardization, and CLAUDE.md schema.

## Purpose

This directory provides:

- **Integration guides** for TTS, agents, and commands
- **Development guides** for creating custom components
- **Standards documentation** for consistent patterns
- **Schema definitions** for CLAUDE.md sections
- **Examples** demonstrating best practices

## Documentation Structure

```
docs/
├── agent-development-guide.md       Agent creation guide
├── agent-integration-guide.md       Agent invocation patterns
├── claude-md-section-schema.md      CLAUDE.md section format
├── command-standardization-checklist.md  Command quality checklist
├── command-standards-flow.md        Standards discovery flow
├── standards-integration-examples.md     Standards usage examples
├── standards-integration-pattern.md Standards application pattern
├── tts-integration-guide.md         TTS system guide
├── tts-message-examples.md          TTS message examples
└── command-modules/                 Command module documentation
    ├── orchestration/               Orchestration modules
    │   ├── monitoring/             Monitoring components
    │   └── workflow-coordination/  Workflow coordination
    └── utilities/                   Utility modules
        ├── performance/             Performance utilities
        ├── status-reporting/        Status reporting
        └── validation/              Validation utilities
```

## Key Documents

### Agent Documentation

#### agent-development-guide.md
**Purpose**: Complete guide for creating custom agents

**Contents**:
- Agent definition format
- Tool selection guidelines
- Capability documentation
- Testing and validation
- Best practices

**Use Cases**:
- Creating new specialized agents
- Understanding agent architecture
- Learning agent design patterns

---

#### agent-integration-guide.md
**Purpose**: Guide for invoking and coordinating agents

**Contents**:
- Agent invocation patterns
- Context passing
- Result handling
- Multi-agent coordination
- Error handling

**Use Cases**:
- Invoking agents from commands
- Building agent workflows
- Debugging agent issues

---

### Command Documentation

#### command-standardization-checklist.md
**Purpose**: Quality checklist for command definitions

**Contents**:
- Metadata completeness
- Standards discovery implementation
- Documentation requirements
- Testing coverage
- Error handling

**Use Cases**:
- Creating new commands
- Reviewing command quality
- Ensuring consistency

---

#### command-standards-flow.md
**Purpose**: Standards discovery and application flow

**Contents**:
- Discovery process diagram
- Section parsing logic
- Standards merging rules
- Application patterns
- Fallback behavior

**Use Cases**:
- Understanding standards system
- Implementing discovery in commands
- Debugging standards issues

---

### Standards Documentation

#### claude-md-section-schema.md
**Purpose**: Schema for CLAUDE.md sections

**Contents**:
- Section format specification
- Metadata requirements
- Content structure
- Usage markers
- Examples

**Use Cases**:
- Creating CLAUDE.md files
- Validating section format
- Understanding section purpose

---

#### standards-integration-pattern.md
**Purpose**: Pattern for applying standards in commands

**Contents**:
- Discovery algorithm
- Parsing implementation
- Application logic
- Error handling
- Examples

**Use Cases**:
- Implementing standards in commands
- Understanding integration flow
- Debugging standards application

---

#### standards-integration-examples.md
**Purpose**: Real-world examples of standards usage

**Contents**:
- Code generation with standards
- Test execution with standards
- Documentation with standards
- Multi-section usage
- Edge cases

**Use Cases**:
- Learning by example
- Understanding best practices
- Solving specific problems

---

### TTS Documentation

#### tts-integration-guide.md
**Purpose**: Comprehensive TTS system guide

**Contents**:
- Architecture overview
- Configuration guide
- Category descriptions
- Message customization
- Troubleshooting

**Use Cases**:
- Setting up TTS
- Understanding TTS flow
- Customizing notifications
- Debugging TTS issues

---

#### tts-message-examples.md
**Purpose**: Example TTS messages for all categories

**Contents**:
- Message format examples
- Context variations
- Voice parameter effects
- Customization examples
- Common patterns

**Use Cases**:
- Understanding message format
- Customizing messages
- Testing TTS output

---

## Command Modules Directory

### Purpose
Documentation for modular command components that can be reused across commands.

### Structure

#### orchestration/
Documentation for orchestration-related modules:

**monitoring/**:
- Progress tracking
- Status monitoring
- Health checks

**workflow-coordination/**:
- Task sequencing
- Agent coordination
- State management

#### utilities/
Documentation for utility modules:

**performance/**:
- Timing utilities
- Profiling helpers
- Optimization tools

**status-reporting/**:
- Status formatters
- Progress indicators
- Completion summaries

**validation/**:
- Input validation
- State verification
- Dependency checking

## Using the Documentation

### For New Users
Start with:
1. [TTS Integration Guide](tts-integration-guide.md) - Set up notifications
2. [Command Standards Flow](command-standards-flow.md) - Understand standards
3. [Standards Integration Examples](standards-integration-examples.md) - Learn by example

### For Command Developers
Read:
1. [Command Standardization Checklist](command-standardization-checklist.md) - Quality requirements
2. [Standards Integration Pattern](standards-integration-pattern.md) - Implementation pattern
3. [CLAUDE.md Section Schema](claude-md-section-schema.md) - Section format

### For Agent Developers
Study:
1. [Agent Development Guide](agent-development-guide.md) - Create agents
2. [Agent Integration Guide](agent-integration-guide.md) - Use agents
3. Examples in [../agents/](../agents/README.md) - Real implementations

### For Troubleshooting
Consult:
1. [TTS Integration Guide](tts-integration-guide.md) - TTS issues
2. [Command Standards Flow](command-standards-flow.md) - Standards discovery
3. [Agent Integration Guide](agent-integration-guide.md) - Agent problems

## Documentation Standards

All documentation in this directory follows:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear, concise** language
- **Code examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/GUIDELINES.md](../../nvim/docs/GUIDELINES.md) for complete standards.

## Contributing Documentation

### Creating New Guides
1. Choose appropriate filename (kebab-case)
2. Include clear purpose statement
3. Use diagrams where helpful
4. Provide code examples
5. Add to this README's index

### Updating Existing Guides
1. Maintain existing structure
2. Update examples if patterns change
3. Keep diagrams synchronized
4. Update navigation links

### Documentation Review
Before committing:
- [ ] No emojis in content
- [ ] Box-drawing characters for diagrams
- [ ] All links work
- [ ] Code examples tested
- [ ] Navigation section complete

## Navigation

### Integration Guides
- [agent-development-guide.md](agent-development-guide.md) - Agent creation
- [agent-integration-guide.md](agent-integration-guide.md) - Agent usage
- [tts-integration-guide.md](tts-integration-guide.md) - TTS setup
- [tts-message-examples.md](tts-message-examples.md) - TTS messages

### Standards Documentation
- [claude-md-section-schema.md](claude-md-section-schema.md) - Section schema
- [command-standardization-checklist.md](command-standardization-checklist.md) - Quality checklist
- [command-standards-flow.md](command-standards-flow.md) - Discovery flow
- [standards-integration-examples.md](standards-integration-examples.md) - Examples
- [standards-integration-pattern.md](standards-integration-pattern.md) - Pattern

### Command Modules
- [command-modules/orchestration/](command-modules/orchestration/) - Orchestration modules
- [command-modules/utilities/](command-modules/utilities/) - Utility modules

### Related
- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agent definitions
- [commands/](../commands/README.md) - Command definitions
- [tts/](../tts/README.md) - TTS implementation
- [hooks/](../hooks/README.md) - Hook scripts

## Quick Reference

### TTS Setup
See: [tts-integration-guide.md](tts-integration-guide.md)

```bash
# Edit config
nvim .claude/tts/tts-config.sh

# Set TTS_ENABLED=true
# Enable desired categories
# Test: espeak-ng "Test"
```

### Create Agent
See: [agent-development-guide.md](agent-development-guide.md)

```markdown
---
allowed-tools: Read, Write, Bash
description: Your agent description
---

# Agent Name

[Agent definition content]
```

### Create Command
See: [command-standardization-checklist.md](command-standardization-checklist.md)

```markdown
---
allowed-tools: Read, Edit, Bash
argument-hint: <required> [optional]
description: Command description
command-type: primary
---

# Command Name

[Command implementation]
```

### Use Standards
See: [standards-integration-pattern.md](standards-integration-pattern.md)

```markdown
## Standards Discovery
1. Locate CLAUDE.md
2. Parse relevant sections
3. Apply to code generation
4. Fall back if missing
```

## Index by Topic

### TTS System
- [tts-integration-guide.md](tts-integration-guide.md)
- [tts-message-examples.md](tts-message-examples.md)
- [../tts/README.md](../tts/README.md)
- [../hooks/tts-dispatcher.sh](../hooks/tts-dispatcher.sh)

### Agents
- [agent-development-guide.md](agent-development-guide.md)
- [agent-integration-guide.md](agent-integration-guide.md)
- [../agents/README.md](../agents/README.md)

### Commands
- [command-standardization-checklist.md](command-standardization-checklist.md)
- [command-standards-flow.md](command-standards-flow.md)
- [../commands/README.md](../commands/README.md)

### Standards
- [claude-md-section-schema.md](claude-md-section-schema.md)
- [standards-integration-pattern.md](standards-integration-pattern.md)
- [standards-integration-examples.md](standards-integration-examples.md)
- [/home/benjamin/.config/CLAUDE.md](../../CLAUDE.md)
