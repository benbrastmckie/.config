# Docs Directory

Comprehensive documentation and integration guides for Claude Code configuration, organized using the Diataxis framework for enhanced discoverability and usability.

## Purpose

This directory provides structured documentation following the [Diataxis framework](https://diataxis.fr/), organizing content by user need:

- **Reference** - Information-oriented quick lookup materials
- **Guides** - Task-focused how-to guides for specific goals
- **Concepts** - Understanding-oriented explanations of architecture and patterns
- **Workflows** - Learning-oriented step-by-step tutorials

This organization ensures developers can quickly find the right documentation based on their immediate need: looking up syntax, solving a specific problem, understanding a concept, or learning a new workflow.

## Documentation Structure

```
docs/
├── README.md                    Main documentation index (this file)
│
├── reference/                   Information-oriented quick lookup (5 files)
│   ├── README.md                Reference documentation index
│   ├── command-reference.md     Complete command catalog
│   ├── agent-reference.md       Complete agent catalog
│   ├── claude-md-section-schema.md  CLAUDE.md section format specification
│   ├── command_architecture_standards.md  Command/agent architecture standards
│   └── phase_dependencies.md    Wave-based parallel execution syntax
│
├── guides/                      Task-focused how-to guides (11 files)
│   ├── README.md                How-to guides index
│   ├── creating-commands.md     Command development guide
│   ├── creating-agents.md       Agent creation guide
│   ├── using-agents.md          Agent integration patterns
│   ├── standards-integration.md Standards discovery and application
│   ├── command-patterns.md      Command pattern catalog
│   ├── command-examples.md      Reusable command patterns
│   ├── logging-patterns.md      Standardized logging formats
│   ├── setup-command-guide.md   /setup command usage patterns
│   ├── efficiency-guide.md      Performance optimization
│   ├── error-enhancement-guide.md Error handling patterns
│   └── data-management.md       Data handling and persistence
│
├── concepts/                    Understanding-oriented explanations (4 files)
│   ├── README.md                Concepts documentation index
│   ├── hierarchical_agents.md   Multi-level agent coordination
│   ├── writing-standards.md     Development philosophy and documentation
│   ├── directory-protocols.md   Topic-based artifact organization
│   └── development-workflow.md  Development workflow patterns
│
├── workflows/                   Learning-oriented step-by-step tutorials (6 files)
│   ├── README.md                Workflow tutorials index
│   ├── orchestration-guide.md   Multi-agent workflow tutorial
│   ├── adaptive-planning-guide.md Progressive plan structures
│   ├── checkpoint_template_guide.md Template-based planning
│   ├── spec_updater_guide.md    Spec updater agent usage
│   ├── tts-integration-guide.md TTS system setup tutorial
│   └── conversion-guide.md      Document conversion workflows
│
└── archive/                     Historical documentation
    └── README.md                Archive index with redirects
```

## Browse by Category

### [Reference Documentation](reference/README.md)
Quick lookup for commands, agents, schemas, and syntax. Use when you know what you're looking for and need exact syntax or parameter details.

**Key Documents**:
- [Command Reference](reference/command-reference.md) - Complete catalog of all available commands
- [Agent Reference](reference/agent-reference.md) - Directory of specialized agents with capabilities
- [CLAUDE.md Section Schema](reference/claude-md-section-schema.md) - Section format specification
- [Command Architecture Standards](reference/command_architecture_standards.md) - Architecture requirements for commands/agents
- [Phase Dependencies](reference/phase_dependencies.md) - Wave-based parallel execution syntax

### [How-To Guides](guides/README.md)
Task-focused guides for accomplishing specific goals. Use when you have a concrete task and need step-by-step instructions.

**Key Documents**:
- [Creating Commands](guides/creating-commands.md) - Complete command development guide
- [Creating Agents](guides/creating-agents.md) - Agent creation and design guide
- [Using Agents](guides/using-agents.md) - Agent invocation and coordination patterns
- [Standards Integration](guides/standards-integration.md) - Implementing CLAUDE.md standards discovery
- [Command Patterns](guides/command-patterns.md) - Reusable command design patterns
- [Efficiency Guide](guides/efficiency-guide.md) - Performance optimization techniques

### [Concepts](concepts/README.md)
Understanding-oriented explanations of architecture and design. Use when you need to understand the "why" and "how it works" behind system components.

**Key Documents**:
- [Hierarchical Agents](concepts/hierarchical_agents.md) - Multi-level agent coordination architecture
- [Writing Standards](concepts/writing-standards.md) - Development philosophy and documentation principles
- [Directory Protocols](concepts/directory-protocols.md) - Topic-based artifact organization system
- [Development Workflow](concepts/development-workflow.md) - Standard workflow patterns and artifact management

### [Workflows](workflows/README.md)
Learning-oriented step-by-step tutorials. Use when you're learning a new feature or workflow and want guided instruction.

**Key Documents**:
- [Orchestration Guide](workflows/orchestration-guide.md) - Multi-agent workflow coordination tutorial
- [Adaptive Planning Guide](workflows/adaptive-planning-guide.md) - Progressive plan structures and checkpointing
- [Template System Guide](workflows/checkpoint_template_guide.md) - Template-based plan generation
- [Spec Updater Guide](workflows/spec_updater_guide.md) - Using the spec updater agent
- [TTS Integration Guide](workflows/tts-integration-guide.md) - Setting up TTS notifications
- [Conversion Guide](workflows/conversion-guide.md) - Document format conversion workflows

## Quick Start by Role

### For New Users
1. [Orchestration Guide](workflows/orchestration-guide.md) - Learn multi-agent workflows
2. [Command Reference](reference/command-reference.md) - Browse available commands
3. [Agent Reference](reference/agent-reference.md) - See what agents can do

### For Command Developers
1. [Creating Commands](guides/creating-commands.md) - Complete development guide
2. [Standards Integration](guides/standards-integration.md) - Using CLAUDE.md standards
3. [Command Patterns](guides/command-patterns.md) - Reusable patterns
4. [Using Agents](guides/using-agents.md) - Integrate agents in commands

### For Agent Developers
1. [Creating Agents](guides/creating-agents.md) - Agent development guide
2. [Using Agents](guides/using-agents.md) - Agent invocation patterns
3. [Agent Reference](reference/agent-reference.md) - Existing agent catalog

### For Contributors
1. [CLAUDE.md Section Schema](reference/claude-md-section-schema.md) - Section format specification
2. [Standards Integration](guides/standards-integration.md) - Standards system overview
3. [Documentation Standards](#documentation-standards) - Style guide

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

* ├─ reference/               Quick lookup reference materials
  ├─ guides/                  Task-focused how-to guides
  ├─ concepts/                Understanding-oriented explanations
  └─ workflows/               Step-by-step tutorials
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
" Select workflows/tts-integration-guide.md
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
- **Diataxis framework** for organization

See [/home/benjamin/.config/nvim/docs/CODE_STANDARDS.md](../../nvim/docs/CODE_STANDARDS.md) for complete standards.

## Contributing Documentation

### Creating New Guides

1. Determine appropriate Diataxis category:
   - **Reference**: Pure information lookup (syntax, parameters, schemas)
   - **Guides**: Task-focused how-to (achieving specific goals)
   - **Concepts**: Understanding-oriented (architecture, design, "why")
   - **Workflows**: Learning-oriented tutorials (step-by-step)

2. Choose appropriate filename (kebab-case)
3. Include clear purpose statement
4. Use diagrams where helpful (Unicode box-drawing)
5. Provide code examples with syntax highlighting
6. Add to appropriate subdirectory README index
7. Update this main README if document is key to category

### Updating Existing Guides

1. Maintain existing structure and Diataxis category
2. Update examples if patterns change
3. Keep diagrams synchronized with current implementation
4. Update navigation links in subdirectory READMEs
5. Follow timeless writing standards (see [Writing Standards](concepts/writing-standards.md))

### Documentation Review

Before committing:
- [ ] No emojis in content
- [ ] Box-drawing characters for diagrams
- [ ] All links work and use correct subdirectory paths
- [ ] Code examples tested
- [ ] Appropriate Diataxis category
- [ ] Navigation section complete in subdirectory README
- [ ] Timeless writing (no temporal markers like "New" or "Previously")

## Navigation

### By Document Type

**Reference Documentation**:
- [Command Reference](reference/command-reference.md) - Command catalog
- [Agent Reference](reference/agent-reference.md) - Agent catalog
- [CLAUDE.md Section Schema](reference/claude-md-section-schema.md) - Section schema
- [Command Architecture Standards](reference/command_architecture_standards.md) - Architecture standards
- [Phase Dependencies](reference/phase_dependencies.md) - Wave-based execution

**How-To Guides**:
- [Creating Commands](guides/creating-commands.md) - Command development
- [Creating Agents](guides/creating-agents.md) - Agent creation
- [Using Agents](guides/using-agents.md) - Agent integration
- [Standards Integration](guides/standards-integration.md) - Standards usage
- [Command Patterns](guides/command-patterns.md) - Pattern catalog
- [Command Examples](guides/command-examples.md) - Command examples
- [Logging Patterns](guides/logging-patterns.md) - Logging standards
- [Efficiency Guide](guides/efficiency-guide.md) - Performance optimization
- [Error Enhancement Guide](guides/error-enhancement-guide.md) - Error handling

**Concepts**:
- [Hierarchical Agents](concepts/hierarchical_agents.md) - Multi-level agent coordination
- [Writing Standards](concepts/writing-standards.md) - Documentation and code standards
- [Directory Protocols](concepts/directory-protocols.md) - Directory structure and artifacts
- [Development Workflow](concepts/development-workflow.md) - Development workflow patterns

**Workflows**:
- [Orchestration Guide](workflows/orchestration-guide.md) - Multi-agent workflows
- [Adaptive Planning Guide](workflows/adaptive-planning-guide.md) - Progressive plans
- [Template System Guide](workflows/checkpoint_template_guide.md) - Plan templates
- [Spec Updater Guide](workflows/spec_updater_guide.md) - Spec updater agent
- [TTS Integration Guide](workflows/tts-integration-guide.md) - TTS setup
- [Conversion Guide](workflows/conversion-guide.md) - Document conversion

### By Topic

**Orchestration**:
- [Orchestration Guide](workflows/orchestration-guide.md)
- [Command Reference](reference/command-reference.md)
- [Agent Reference](reference/agent-reference.md)

**Planning**:
- [Adaptive Planning Guide](workflows/adaptive-planning-guide.md)
- [Template System Guide](workflows/checkpoint_template_guide.md)
- [Creating Commands](guides/creating-commands.md)

**Standards**:
- [Standards Integration](guides/standards-integration.md)
- [CLAUDE.md Section Schema](reference/claude-md-section-schema.md)
- [Command Architecture Standards](reference/command_architecture_standards.md)
- [Writing Standards](concepts/writing-standards.md)

**Testing**:
- [Creating Commands](guides/creating-commands.md#testing)
- [Orchestration Guide](workflows/orchestration-guide.md#validation)

**Agents**:
- [Creating Agents](guides/creating-agents.md)
- [Using Agents](guides/using-agents.md)
- [Agent Reference](reference/agent-reference.md)
- [Hierarchical Agents](concepts/hierarchical_agents.md)

**Commands**:
- [Creating Commands](guides/creating-commands.md)
- [Command Reference](reference/command-reference.md)
- [Command Patterns](guides/command-patterns.md)

**TTS**:
- [TTS Integration Guide](workflows/tts-integration-guide.md)

**Conversion**:
- [Conversion Guide](workflows/conversion-guide.md)

### Related Directories

- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agent definitions
- [commands/](../commands/README.md) - Command definitions
- [tts/](../tts/README.md) - TTS implementation
- [hooks/](../hooks/README.md) - Hook scripts
- [lib/](../lib/README.md) - Shared utilities

## Quick Reference

### Orchestration Workflow
See: [Orchestration Guide](workflows/orchestration-guide.md)

```bash
# Run multi-agent workflow
/orchestrate "Implement user authentication"

# Workflow phases:
# 1. Research (parallel agents)
# 2. Planning (plan-architect)
# 3. Implementation (code-writer)
# 4. Testing (test-specialist)
# 5. Documentation (doc-writer)
```

### Command Development
See: [Creating Commands](guides/creating-commands.md)

```markdown
---
allowed-tools: Read, Edit, Bash
argument-hint: <feature> [options]
description: Command description
command-type: primary
---

# Command Name

[Command implementation with standards discovery]
```

### Agent Usage
See: [Using Agents](guides/using-agents.md)

```yaml
Task {
  subagent_type: "general-purpose"
  description: "Task description using agent-name protocol"
  prompt: "
    Read and follow: .claude/agents/agent-name.md
    You are acting as [Agent Name].

    [Task details]
  "
}
```

### Standards Discovery
See: [Standards Integration](guides/standards-integration.md)

```markdown
## Standards Discovery
1. Locate CLAUDE.md (recursive upward)
2. Check subdirectory-specific CLAUDE.md
3. Parse relevant sections ([Used by: ...])
4. Apply to code generation
5. Fall back to language defaults if missing
```

## Index by Topic

### Orchestration and Workflows
- [Orchestration Guide](workflows/orchestration-guide.md)
- [Agent Reference](reference/agent-reference.md)
- [Using Agents](guides/using-agents.md)
- [Command Reference](reference/command-reference.md)

### Implementation Planning
- [Adaptive Planning Guide](workflows/adaptive-planning-guide.md)
- [Template System Guide](workflows/checkpoint_template_guide.md)
- [Creating Commands](guides/creating-commands.md)

### Standards and Quality
- [Command Architecture Standards](reference/command_architecture_standards.md)
- [Standards Integration](guides/standards-integration.md)
- [CLAUDE.md Section Schema](reference/claude-md-section-schema.md)
- [Writing Standards](concepts/writing-standards.md)
- [Creating Commands](guides/creating-commands.md#quality-checklist)
- [Command Patterns](guides/command-patterns.md)

### Agent System
- [Creating Agents](guides/creating-agents.md)
- [Using Agents](guides/using-agents.md)
- [Agent Reference](reference/agent-reference.md)
- [Hierarchical Agents](concepts/hierarchical_agents.md)
- [../agents/README.md](../agents/README.md)

### Command System
- [Creating Commands](guides/creating-commands.md)
- [Command Reference](reference/command-reference.md)
- [Command Patterns](guides/command-patterns.md)
- [../commands/README.md](../commands/README.md)

### TTS System
- [TTS Integration Guide](workflows/tts-integration-guide.md)
- [../tts/README.md](../tts/README.md)
- [../hooks/tts-dispatcher.sh](../hooks/tts-dispatcher.sh)

### Document Conversion
- [Conversion Guide](workflows/conversion-guide.md)
- [../agents/doc-converter.md](../agents/doc-converter.md)
- [../commands/convert-docs.md](../commands/convert-docs.md)

### Performance and Optimization
- [Efficiency Guide](guides/efficiency-guide.md)
- [Error Enhancement Guide](guides/error-enhancement-guide.md)
- [Orchestration Guide](workflows/orchestration-guide.md#troubleshooting)

## About Diataxis

This documentation follows the [Diataxis framework](https://diataxis.fr/), which organizes documentation into four categories based on user needs:

- **Reference** (information-oriented): Dry, factual information for lookup
- **Guides** (task-oriented): Practical instructions to achieve specific goals
- **Concepts** (understanding-oriented): Explanations to build comprehension
- **Workflows** (learning-oriented): Lessons to acquire skills

This structure ensures developers can quickly find documentation that matches their current need, whether they're learning, solving a problem, understanding architecture, or looking up syntax.
