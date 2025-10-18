# Docs Directory

Comprehensive documentation and integration guides for Claude Code configuration, including command development, agent integration, adaptive planning, and standards implementation.

## Purpose

This directory provides:

- **Integration guides** for TTS, agents, and commands
- **Development guides** for creating custom components
- **Standards documentation** for consistent patterns
- **Reference materials** for quick lookup
- **Examples** demonstrating best practices

## Documentation Structure

```
docs/
├── README.md                          Main documentation index
│
Core System Guides (5)
├── command-reference.md               Complete command catalog
├── agent-reference.md                 Complete agent catalog
├── claude-md-section-schema.md        CLAUDE.md section format
├── command_architecture_standards.md  Command/agent architecture standards
└── phase_dependencies.md              Wave-based parallel execution
│
Advanced Features (10)
├── orchestration-guide.md             Multi-agent workflows
├── adaptive-planning-guide.md         Progressive plans and checkpointing
├── template-system-guide.md           Template-based planning
├── efficiency-guide.md                Performance optimization
├── error-enhancement-guide.md         Error handling patterns
├── directory-protocols.md             Topic-based artifact structure
├── spec_updater_guide.md              Spec updater agent guide
├── hierarchical_agents.md             Multi-level agent coordination
├── development-workflow.md            Development workflow patterns
└── writing-standards.md               Documentation and code standards
│
Development Guides (8)
├── creating-commands.md               Command development guide
├── creating-agents.md                 Agent creation guide
├── using-agents.md                    Agent integration patterns
├── standards-integration.md           Standards discovery and application
├── command-patterns.md                Command pattern catalog
├── command-examples.md                Reusable command patterns
└── logging-patterns.md                Standardized logging formats
│
Integration Guides (2)
├── tts-integration-guide.md           TTS system setup
└── conversion-guide.md                Document conversion
│
Archive/
└── archive/                           Historical documentation
    ├── topic_based_organization.md    → See directory-protocols.md
    ├── artifact_organization.md       → See directory-protocols.md
    ├── development-philosophy.md      → See writing-standards.md
    └── timeless_writing_guide.md      → See writing-standards.md
```

**Note**: Archived files (marked with →) have been consolidated into unified guides. See archive/README.md for details.

## Quick Start by Role

### For New Users
1. [Orchestration Guide](orchestration-guide.md) - Understanding multi-agent workflows
2. [Command Reference](command-reference.md) - Browse available commands
3. [Agent Reference](agent-reference.md) - See what agents can do

### For Command Developers
1. [Creating Commands](creating-commands.md) - Complete development guide
2. [Standards Integration](standards-integration.md) - Using CLAUDE.md standards
3. [Command Patterns](command-patterns.md) - Reusable patterns
4. [Using Agents](using-agents.md) - Integrate agents in commands

### For Agent Developers
1. [Creating Agents](creating-agents.md) - Agent development guide
2. [Using Agents](using-agents.md) - Agent invocation patterns
3. [Agent Reference](agent-reference.md) - Existing agent catalog

### For Contributors
1. [CLAUDE.md Section Schema](claude-md-section-schema.md) - Section format specification
2. [Standards Integration](standards-integration.md) - Standards system overview
3. [Documentation Standards](#documentation-standards) - Style guide

## Key Documents

### Core System Guides

#### command-reference.md
**Purpose**: Alphabetical catalog of all available commands with usage syntax

**Contents**:
- Complete command listing
- Usage syntax for each command
- Command categories and organization
- Quick lookup reference

**Use Cases**:
- Discovering available commands
- Finding command syntax quickly
- Understanding command relationships
- Planning workflow automation

---

#### agent-reference.md
**Purpose**: Alphabetical catalog of all specialized agents with capabilities

**Contents**:
- Complete agent directory (15 agents)
- Tool restrictions per agent
- Commands that use each agent
- Capabilities summary
- Tool access matrix

**Use Cases**:
- Selecting appropriate agent for task
- Understanding agent capabilities
- Finding which commands use agents
- Planning agent workflows

---

#### command_architecture_standards.md
**Purpose**: Architecture standards for command and agent files to ensure execution clarity

**Contents**:
- Fundamental understanding: Command files as AI execution scripts
- Core standards: Executable instructions must be inline
- Reference patterns: When and how to use external references
- Refactoring guidelines: What to extract vs keep inline
- Testing standards: Validation criteria before commits
- Anti-patterns: Common mistakes to avoid
- Pre-commit validation scripts

**Use Cases**:
- Creating or modifying command files
- Refactoring commands without breaking execution
- Reviewing pull requests for command changes
- Understanding why certain patterns are required
- Preventing regression of command functionality

**Critical**: This document must be followed when modifying any files in `.claude/commands/` or `.claude/agents/`

---

#### claude-md-section-schema.md
**Purpose**: Schema for CLAUDE.md section format

**Contents**:
- Section format specification
- Metadata requirements (`[Used by: ...]`)
- Content structure guidelines
- Standard section names
- Examples

**Use Cases**:
- Creating CLAUDE.md files
- Validating section format
- Understanding section purpose
- Adding new sections

---

#### phase_dependencies.md
**Purpose**: Wave-based parallel execution with phase dependencies

**Contents**:
- Dependency syntax and formats
- Validation rules (no cycles, no forward deps)
- Wave calculation using Kahn's algorithm
- Common dependency patterns (fan-out, fan-in, diamond)
- Performance optimization strategies
- Integration with /orchestrate and /implement

**Use Cases**:
- Declaring phase dependencies in implementation plans
- Understanding wave-based execution
- Optimizing parallelization (40-60% time savings)
- Troubleshooting dependency errors

---

### Advanced Features

#### orchestration-guide.md
**Purpose**: Multi-agent workflows and parallel execution patterns

**Contents**:
- /orchestrate command usage
- Parallel execution architecture
- Agent coordination patterns
- Troubleshooting workflows
- Performance optimization

**Use Cases**:
- Running multi-phase workflows
- Coordinating multiple agents
- Parallel task execution
- Debugging workflow issues

---

#### adaptive-planning-guide.md
**Purpose**: Progressive plan structures (L0/L1/L2) and workflow checkpointing

**Contents**:
- Plan structure levels (single file, phase directory, hierarchical)
- Complexity scoring and thresholds
- Automatic expansion triggers
- Checkpoint system and resume workflows
- Migration between tiers

**Use Cases**:
- Creating scalable implementation plans
- Managing complex projects
- Resuming interrupted workflows
- Understanding plan organization

---

#### template-system-guide.md
**Purpose**: Template-based plan generation

**Contents**:
- Template structure and format
- Variable substitution
- Template creation guidelines
- Using templates with /plan-from-template

**Use Cases**:
- Creating reusable plan templates
- Standardizing project structures
- Rapid plan generation

---

#### efficiency-guide.md
**Purpose**: Performance optimization patterns

**Contents**:
- Tool usage optimization
- Context management
- Parallel execution patterns
- Resource conservation

**Use Cases**:
- Optimizing command performance
- Reducing token usage
- Improving workflow speed

---

#### error-enhancement-guide.md
**Purpose**: Error handling and enhancement patterns

**Contents**:
- Error detection patterns
- Error enhancement strategies
- Recovery workflows
- User feedback guidelines

**Use Cases**:
- Improving error messages
- Implementing error recovery
- Debugging command failures

---

#### directory-protocols.md
**Purpose**: Topic-based artifact organization system and directory structure protocols

**Contents**:
- Directory structure (`specs/{NNN_topic}/`)
- Artifact taxonomy (reports, plans, summaries, debug, scripts, outputs)
- Gitignore rules (debug/ committed, others gitignored)
- Artifact lifecycle management
- Shell utilities for artifact operations
- Cleanup patterns for temporary artifacts
- Progressive plan organization (Level 0 → Level 1 → Level 2)
- Phase dependencies and wave-based execution

**Use Cases**:
- Understanding spec directory organization
- Managing workflow artifacts
- Creating debug reports and investigation scripts
- Cleaning up temporary files after workflows
- Organizing implementation plans

---

#### spec_updater_guide.md
**Purpose**: Spec updater agent usage and integration

**Contents**:
- Agent responsibilities (artifact management, cross-references, organization)
- Usage patterns from /orchestrate, /implement, /plan
- Debug report creation workflows
- Investigation script creation
- Implementation summary generation
- Gitignore compliance verification

**Use Cases**:
- Using spec updater agent in commands
- Creating properly structured artifacts
- Maintaining cross-references between artifacts
- Understanding topic-based artifact structure

---

### Architecture and System Patterns

#### Context Preservation Utilities
**Purpose**: Metadata extraction and context-efficient artifact passing

**Contents**:
- Metadata extraction utilities (extract_report_metadata, extract_plan_metadata)
- Forward message pattern for subagent responses
- Context pruning workflows and policies
- Layered context architecture (5 layers: Meta/Operational/Domain/Historical/Environmental)
- Context reduction metrics (95% reduction: 5000 tokens → 250 tokens)

**Use Cases**:
- Passing reports/plans between agents without full content
- Reducing context usage in multi-agent workflows
- Maintaining <30% context usage throughout orchestration
- Implementing metadata-only artifact references

**See Also**:
- [command_architecture_standards.md](command_architecture_standards.md#context-preservation-standards) - Standards 6-8
- [orchestration-guide.md](orchestration-guide.md) - Context pruning workflows
- [using-agents.md](using-agents.md) - Layered context architecture
- [hierarchical_agents.md](hierarchical_agents.md) - Context pruning for multi-agent coordination
- `.claude/lib/artifact-operations.sh` - Metadata extraction utilities
- `.claude/lib/context-pruning.sh` - Context pruning utilities

---

#### Pattern Libraries
**Purpose**: Reusable procedure patterns for commands (bash-patterns, implementation-patterns)

**Contents**:
- Bash utility patterns (utility initialization, checkpoint setup, metadata extraction)
- Implementation workflow patterns (phase-by-phase execution, test-after-phase, git commits)
- Variable substitution syntax for pattern adaptation
- Cross-references to command architecture standards (Standard 9)

**Use Cases**:
- Reducing command file size by extracting procedures
- Standardizing utility initialization across commands
- Implementing consistent checkpoint workflows
- Following DRY principles for command development

**See Also**:
- `.claude/templates/bash-patterns.yaml` - Bash procedure patterns (Phase 6, to be created)
- `.claude/templates/implementation-patterns.yaml` - Implementation workflow patterns (Phase 6, to be created)
- [command_architecture_standards.md](command_architecture_standards.md#standard-9) - Pattern extraction guidelines
- [creating-commands.md](creating-commands.md) - Pattern library integration
- [command-patterns.md](command-patterns.md) - Command pattern catalog

---

#### Spec Maintenance
**Purpose**: Artifact lifecycle management and cross-referencing protocols

**Contents**:
- Bidirectional cross-referencing (reports ↔ plans ↔ summaries)
- Artifact lifecycle stages (Creation → Usage → Completion → Archival)
- Retention policies (debug: permanent, scripts: 0-day, artifacts: 30-day)
- Gitignore compliance (debug/ committed, other artifacts gitignored)
- Spec updater agent integration patterns
- Cleanup automation utilities

**Use Cases**:
- Creating properly cross-referenced artifacts
- Managing artifact lifecycle from creation to archival
- Automating cleanup of temporary artifacts
- Maintaining bidirectional links between plans and reports
- Validating gitignore compliance

**See Also**:
- [spec_updater_guide.md](spec_updater_guide.md) - Spec updater agent guide
- [directory-protocols.md](directory-protocols.md) - Artifact lifecycle management and gitignore compliance
- `.claude/lib/artifact-operations.sh` - Bidirectional cross-referencing utilities

---

#### Topic-Based Organization
**Purpose**: Unified artifact organization system (`specs/{NNN_topic}/`)

**Contents**:
- Topic directory structure with numbered topics (001, 002, 003...)
- Artifact subdirectories (plans/, reports/, summaries/, debug/, scripts/, outputs/)
- Topic creation and management utilities
- Cross-topic linking for related features
- Metadata-only artifact references
- Context-efficient artifact usage patterns

**Use Cases**:
- Organizing all artifacts for a feature in one directory
- Creating and managing topic directories
- Migrating legacy flat structure to topic-based structure
- Implementing cross-topic references
- Following gitignore compliance protocols

**See Also**:
- [directory-protocols.md](directory-protocols.md) - Complete directory structure protocols, artifact taxonomy, and lifecycle management
- `.claude/lib/template-integration.sh` - Topic management utilities

---

#### hierarchical_agents.md
**Purpose**: Multi-level agent coordination architecture

**Contents**:
- Metadata extraction patterns (99% context reduction)
- Forward message pattern for subagent responses
- Recursive supervision for complex workflows
- Context pruning strategies
- Agent delegation patterns
- Performance metrics and optimization

**Use Cases**:
- Coordinating multiple agents in workflows
- Minimizing context window consumption
- Delegating complex tasks to specialized subagents
- Managing sub-supervisors for large workflows

**See Also**:
- [using-agents.md](using-agents.md) - Agent invocation patterns
- [command_architecture_standards.md](command_architecture_standards.md) - Context preservation standards
- `.claude/lib/artifact-operations.sh` - Metadata extraction utilities
- `.claude/lib/context-pruning.sh` - Context pruning utilities

---

#### development-workflow.md
**Purpose**: Standard development workflow patterns and artifact management

**Contents**:
- 5-phase workflow: research → plan → implement → test → summarize
- Spec updater integration for artifact management
- Plan hierarchy updates and checkbox propagation
- Git workflow patterns (feature branches, atomic commits)
- Adaptive planning integration
- Cross-reference maintenance

**Use Cases**:
- Understanding standard development workflow
- Managing artifacts in topic-based structure
- Integrating spec updater agent
- Following git best practices

**See Also**:
- [directory-protocols.md](directory-protocols.md) - Artifact organization
- [spec_updater_guide.md](spec_updater_guide.md) - Spec updater agent
- [adaptive-planning-guide.md](adaptive-planning-guide.md) - Adaptive planning

---

#### writing-standards.md
**Purpose**: Development philosophy, documentation standards, and timeless writing principles

**Contents**:
- Clean-break refactor philosophy
- Development core values (clarity, quality, coherence)
- Present-focused documentation standards
- Banned patterns and temporal markers
- Rewriting patterns for timeless writing
- Decision framework for documentation
- Review process and enforcement tools

**Use Cases**:
- Writing timeless documentation
- Refactoring without historical burden
- Removing temporal references from docs
- Following project documentation standards

**See Also**:
- [command_architecture_standards.md](command_architecture_standards.md) - Command-specific refactoring rules

---

### Development Guides

#### creating-commands.md
**Purpose**: Complete guide for command development

**Contents**:
- Command file structure
- Frontmatter fields
- Standards discovery implementation
- Testing protocols
- Quality checklist
- Agent integration

**Use Cases**:
- Creating new slash commands
- Understanding command architecture
- Implementing standards compliance
- Integrating agents in commands

---

#### creating-agents.md
**Purpose**: Guide for creating custom agents

**Contents**:
- Agent file structure
- Frontmatter fields (allowed-tools, description)
- System prompt structure
- Behavioral guidelines
- Testing and validation
- Best practices

**Use Cases**:
- Creating specialized agents
- Understanding agent design
- Selecting appropriate tools
- Defining agent capabilities

---

#### using-agents.md
**Purpose**: Agent invocation patterns and multi-agent coordination

**Contents**:
- Critical invocation pattern (general-purpose + behavioral injection)
- Agent directory with purposes and tools
- Integration patterns (single, parallel, sequential, conditional, optional)
- Context passing and error handling
- Command-agent matrix

**Use Cases**:
- Invoking agents from commands
- Building agent workflows
- Understanding agent coordination
- Debugging agent issues

---

#### standards-integration.md
**Purpose**: Standards discovery and application from CLAUDE.md

**Contents**:
- Discovery process (4 steps)
- Section parsing examples
- Standards application patterns
- Verification and compliance
- Error handling and fallbacks
- 10 concrete examples with code

**Use Cases**:
- Implementing standards in commands
- Understanding discovery flow
- Parsing CLAUDE.md sections
- Applying standards to code generation

---

#### command-patterns.md
**Purpose**: Reusable command patterns and best practices

**Contents**:
- Common command patterns
- Error handling patterns
- Testing patterns
- Documentation patterns

**Use Cases**:
- Learning command development
- Implementing consistent patterns
- Solving common problems

---

#### command-examples.md
**Purpose**: Reusable command patterns and examples

**Contents**:
- Dry-run mode examples with analysis output
- Dashboard progress tracking patterns
- Checkpoint save/restore workflows
- Test execution patterns
- Git commit patterns with pre-commit validation

**Use Cases**:
- Implementing dry-run mode in commands
- Adding progress dashboards
- Creating resumable workflows with checkpoints
- Standardizing test execution
- Automating git commits

---

#### logging-patterns.md
**Purpose**: Standardized logging patterns for agents and commands

**Contents**:
- Progress markers (PROGRESS: format)
- Structured logging format
- Error logging patterns with recovery suggestions
- Summary report format
- File path output format (REPORT_PATH, PLAN_PATH, etc.)

**Use Cases**:
- Implementing consistent logging in commands
- Parsing agent output programmatically
- Providing actionable error messages
- Creating workflow summaries

---

### Integration Guides

#### tts-integration-guide.md
**Purpose**: TTS system setup and configuration

**Contents**:
- Architecture overview
- Configuration guide
- Category descriptions (completion and permission notifications)
- Message customization (uniform "directory, branch" format)
- Integration with commands
- Troubleshooting

**Use Cases**:
- Setting up TTS notifications
- Understanding TTS flow
- Customizing voice parameters
- Debugging TTS issues

---

#### conversion-guide.md
**Purpose**: Document format conversion (Markdown, DOCX, PDF)

**Contents**:
- Conversion workflows
- Format support
- Batch processing
- Metadata preservation
- Troubleshooting

**Use Cases**:
- Converting between document formats
- Batch document processing
- Preserving formatting

---

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

### By Document Type

**Core System Guides**:
- [command-reference.md](command-reference.md) - Command catalog
- [agent-reference.md](agent-reference.md) - Agent catalog
- [claude-md-section-schema.md](claude-md-section-schema.md) - Section schema
- [command_architecture_standards.md](command_architecture_standards.md) - Architecture standards
- [phase_dependencies.md](phase_dependencies.md) - Wave-based execution

**Advanced Features**:
- [orchestration-guide.md](orchestration-guide.md) - Multi-agent workflows
- [adaptive-planning-guide.md](adaptive-planning-guide.md) - Progressive plans
- [template-system-guide.md](template-system-guide.md) - Plan templates
- [efficiency-guide.md](efficiency-guide.md) - Performance optimization
- [error-enhancement-guide.md](error-enhancement-guide.md) - Error handling
- [directory-protocols.md](directory-protocols.md) - Directory structure and artifacts
- [spec_updater_guide.md](spec_updater_guide.md) - Spec updater agent
- [hierarchical_agents.md](hierarchical_agents.md) - Multi-level agent coordination
- [development-workflow.md](development-workflow.md) - Development workflow patterns
- [writing-standards.md](writing-standards.md) - Documentation and code standards

**Development Guides**:
- [creating-commands.md](creating-commands.md) - Command development
- [creating-agents.md](creating-agents.md) - Agent creation
- [using-agents.md](using-agents.md) - Agent integration
- [standards-integration.md](standards-integration.md) - Standards usage
- [command-patterns.md](command-patterns.md) - Pattern catalog
- [command-examples.md](command-examples.md) - Command examples
- [logging-patterns.md](logging-patterns.md) - Logging standards

**Integration Guides**:
- [tts-integration-guide.md](tts-integration-guide.md) - TTS setup
- [conversion-guide.md](conversion-guide.md) - Document conversion

### By Topic

**Orchestration**:
- [orchestration-guide.md](orchestration-guide.md)
- [command-reference.md](command-reference.md)
- [agent-reference.md](agent-reference.md)

**Planning**:
- [adaptive-planning-guide.md](adaptive-planning-guide.md)
- [creating-commands.md](creating-commands.md)
- [template-system-guide.md](template-system-guide.md)

**Standards**:
- [standards-integration.md](standards-integration.md)
- [claude-md-section-schema.md](claude-md-section-schema.md)
- [command_architecture_standards.md](command_architecture_standards.md)
- [creating-commands.md](creating-commands.md#standards-discovery)

**Testing**:
- [creating-commands.md](creating-commands.md#testing)
- [orchestration-guide.md](orchestration-guide.md#validation)

**Agents**:
- [creating-agents.md](creating-agents.md)
- [using-agents.md](using-agents.md)
- [agent-reference.md](agent-reference.md)

**Commands**:
- [creating-commands.md](creating-commands.md)
- [command-reference.md](command-reference.md)
- [command-patterns.md](command-patterns.md)

**TTS**:
- [tts-integration-guide.md](tts-integration-guide.md)

**Conversion**:
- [conversion-guide.md](conversion-guide.md)

### Related Directories

- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agent definitions
- [commands/](../commands/README.md) - Command definitions
- [tts/](../tts/README.md) - TTS implementation
- [hooks/](../hooks/README.md) - Hook scripts
- [lib/](../lib/README.md) - Shared utilities

## Quick Reference

### Orchestration Workflow
See: [orchestration-guide.md](orchestration-guide.md)

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
See: [creating-commands.md](creating-commands.md)

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
See: [using-agents.md](using-agents.md)

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
See: [standards-integration.md](standards-integration.md)

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
- [orchestration-guide.md](orchestration-guide.md)
- [agent-reference.md](agent-reference.md)
- [using-agents.md](using-agents.md)
- [command-reference.md](command-reference.md)

### Implementation Planning
- [adaptive-planning-guide.md](adaptive-planning-guide.md)
- [template-system-guide.md](template-system-guide.md)
- [creating-commands.md](creating-commands.md)

### Standards and Quality
- [command_architecture_standards.md](command_architecture_standards.md)
- [standards-integration.md](standards-integration.md)
- [claude-md-section-schema.md](claude-md-section-schema.md)
- [creating-commands.md](creating-commands.md#quality-checklist)
- [command-patterns.md](command-patterns.md)

### Agent System
- [creating-agents.md](creating-agents.md)
- [using-agents.md](using-agents.md)
- [agent-reference.md](agent-reference.md)
- [../agents/README.md](../agents/README.md)

### Command System
- [creating-commands.md](creating-commands.md)
- [command-reference.md](command-reference.md)
- [command-patterns.md](command-patterns.md)
- [../commands/README.md](../commands/README.md)

### TTS System
- [tts-integration-guide.md](tts-integration-guide.md)
- [../tts/README.md](../tts/README.md)
- [../hooks/tts-dispatcher.sh](../hooks/tts-dispatcher.sh)

### Document Conversion
- [conversion-guide.md](conversion-guide.md)
- [../agents/doc-converter.md](../agents/doc-converter.md)
- [../commands/convert-docs.md](../commands/convert-docs.md)

### Performance and Optimization
- [efficiency-guide.md](efficiency-guide.md)
- [error-enhancement-guide.md](error-enhancement-guide.md)
- [orchestration-guide.md](orchestration-guide.md#troubleshooting)
