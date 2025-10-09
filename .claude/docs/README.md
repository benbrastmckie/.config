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
└── tts-message-examples.md          TTS message examples
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

## Neovim Integration

Documentation files are integrated with the Neovim artifact picker for easy browsing and reference.

### Accessing Documentation via Picker

- **Keybinding**: `<leader>ac` in normal mode
- **Command**: `:ClaudeCommands`
- **Category**: [Docs] section in picker

### Picker Features for Documentation

**Visual Display**:
- Documentation files listed with descriptions from frontmatter
- Local docs marked with `*` prefix
- Descriptions automatically extracted from markdown metadata

**Display Format**:
```
[Docs]                        Integration guides

* ├─ template-system-guide.md  Template system documentation
  └─ api-integration-guide.md  API integration patterns
```

**Quick Actions**:
- `<CR>` - Open documentation file for editing
- `<C-l>` - Load documentation locally to project
- `<C-g>` - Update from global version
- `<C-s>` - Save local documentation to global
- `<C-e>` - Edit file in buffer
- `<C-u>`/`<C-d>` - Scroll preview up/down

**Example Workflow**:
```vim
" Open picker
:ClaudeCommands

" Navigate to [Docs] category
" Select tts-integration-guide.md
" Press Return to view/edit documentation
" Use <C-u>/<C-d> to scroll through guide
```

### Documentation File Structure

Documentation files appear in the picker with descriptions extracted from their metadata:

```markdown
# TTS Integration Guide

Brief description of TTS integration.  # Shown in picker

## Contents
...
```

The picker automatically parses the first paragraph or description to display document purpose.

### Quick Reference Access

The picker provides immediate access to integration guides while working:

- **Browse documentation** without leaving Neovim
- **Preview content** before opening files
- **Jump to guides** when implementing features
- **Edit documentation** alongside code

This tight integration makes documentation a first-class part of the development workflow.

### Documentation

- [Neovim Claude Integration](../../nvim/lua/neotex/plugins/ai/claude/README.md) - Integration overview
- [Commands Picker](../../nvim/lua/neotex/plugins/ai/claude/commands/README.md) - Picker documentation
- [Picker Implementation](../../nvim/lua/neotex/plugins/ai/claude/commands/picker.lua) - Source code

## Documentation Standards

All documentation in this directory follows:

- **NO emojis** in file content
- **Unicode box-drawing** for diagrams
- **Clear, concise** language
- **Code examples** with syntax highlighting
- **CommonMark** specification

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

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
