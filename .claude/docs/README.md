# Docs Directory

Comprehensive documentation and integration guides for Claude Code configuration, organized using the Diataxis framework for enhanced discoverability and usability.

## Purpose

This directory provides structured documentation following the [Diataxis framework](https://diataxis.fr/), organizing content by user need:

- **Reference** - Information-oriented quick lookup materials
- **Guides** - Task-focused how-to guides for specific goals
- **Concepts** - Understanding-oriented explanations of architecture and patterns
- **Workflows** - Learning-oriented step-by-step tutorials

This organization ensures developers can quickly find the right documentation based on their immediate need: looking up syntax, solving a specific problem, understanding a concept, or learning a new workflow.

## I Want To...

Common tasks and where to find guidance:

1. **Create a new slash command**
   → [Command Development Guide](guides/command-development-guide.md)
   → [Command Architecture Standards](reference/command_architecture_standards.md)

2. **Build a specialized agent**
   → [Agent Development Guide](guides/agent-development-guide.md)
   → [Agent Reference](reference/agent-reference.md)

3. **Run multi-phase workflows**
   → [Orchestration Best Practices](guides/orchestration-best-practices.md)
   → [Orchestration Guide](workflows/orchestration-guide.md)

4. **Debug agent delegation failures**
   → [Agent Delegation Troubleshooting](troubleshooting/agent-delegation-troubleshooting.md)
   → [Orchestration Reference](reference/orchestration-reference.md)

5. **Optimize context usage**
   → [Context Budget Management](workflows/context-budget-management.md)
   → [Phase 0 Optimization Guide](guides/phase-0-optimization.md)

6. **Add standards to my project**
   → [Setup Command Guide](guides/setup-command-guide.md)
   → [CLAUDE.md Section Schema](reference/claude-md-section-schema.md)

7. **Understand architectural patterns**
   → [Patterns Catalog](concepts/patterns/README.md)
   → [Hierarchical Agents](concepts/hierarchical_agents.md)

8. **Implement wave-based parallel execution**
   → [Parallel Execution Pattern](concepts/patterns/parallel-execution.md)
   → [Phase Dependencies Reference](reference/phase_dependencies.md)

9. **Create implementation plans**
   → [Adaptive Planning Guide](workflows/adaptive-planning-guide.md)
   → [Directory Protocols](concepts/directory-protocols.md)

10. **Fix broken orchestration workflows**
    → [Orchestration Troubleshooting Guide](guides/orchestration-troubleshooting.md)
    → [Error Handling Flowchart](quick-reference/error-handling-flowchart.md)

## Quick Navigation for Agents

Looking to work on a specific area? Use these quick-start paths:

### Working on Commands?
→ **Start**: [Command Development Guide](guides/command-development-guide.md)
→ **Patterns**: [Behavioral Injection Pattern](concepts/patterns/behavioral-injection.md)
→ **Reference**: [Command Reference](reference/command-reference.md)

### Working on Agents?
→ **Start**: [Agent Development Guide](guides/agent-development-guide.md)
→ **Architecture**: [Hierarchical Agents](concepts/hierarchical_agents.md)
→ **Reference**: [Agent Reference](reference/agent-reference.md)

### Refactoring .claude/?
→ **Standards**: [Command Architecture Standards](reference/command_architecture_standards.md)
→ **Migration**: [Execution Enforcement Guide](guides/execution-enforcement-guide.md)
→ **Testing**: [Testing Patterns](guides/testing-patterns.md)

### Content Ownership

**Single Source of Truth**:
- **Patterns**: `concepts/patterns/` catalog is authoritative for architectural patterns
- **Command Syntax**: `reference/command-reference.md` is authoritative for command usage
- **Agent Syntax**: `reference/agent-reference.md` is authoritative for agent capabilities
- **Architecture**: `concepts/hierarchical_agents.md` is authoritative for system design

Guides should cross-reference these authoritative sources rather than duplicating content.

## Documentation Structure

```
docs/
├── README.md                    Main documentation index (this file)
│
├── reference/                   Information-oriented quick lookup (11 files)
│   ├── README.md                Reference documentation index
│   ├── command-reference.md     Complete command catalog
│   ├── agent-reference.md       Complete agent catalog
│   ├── claude-md-section-schema.md  CLAUDE.md section format specification
│   ├── command_architecture_standards.md  Command/agent architecture standards
│   ├── phase_dependencies.md    Wave-based parallel execution syntax
│   ├── debug-structure.md       Debug report template structure
│   ├── refactor-structure.md    Refactor report template structure
│   ├── report-structure.md      Research report template structure
│   ├── orchestration-reference.md  Unified orchestration reference (commands, patterns, metrics)
│   └── workflow-phases.md       Detailed workflow phase descriptions
│
├── guides/                      Task-focused how-to guides (19 files)
│   ├── README.md                How-to guides index
│   ├── creating-commands.md     Command development guide
│   ├── agent-development-guide.md  Complete agent guide (create, invoke, context, advanced)
│   ├── orchestration-best-practices.md  Unified 7-phase orchestration framework (Spec 508)
│   ├── phase-0-optimization.md  Phase 0 breakthrough (85% reduction, 25x speedup)
│   ├── using-agents.md          → Redirects to agent-development-guide.md (archived)
│   ├── standards-integration.md Standards discovery and application
│   ├── imperative-language-guide.md  MUST/WILL/SHALL usage for required actions
│   ├── command-patterns.md      Command pattern catalog
│   ├── command-examples.md      Reusable command patterns
│   ├── logging-patterns.md      Standardized logging formats
│   ├── setup-command-guide.md   /setup command usage patterns (enhanced with cleanup content)
│   ├── implementation-guide.md  Phase execution and implementation workflows
│   ├── revision-guide.md        Revise auto-mode and revision types
│   ├── performance-optimization.md      Performance optimization
│   ├── error-enhancement-guide.md Error handling patterns
│   ├── data-management.md       Data handling and persistence
│   ├── testing-patterns.md      Test organization and coverage
│   ├── migration-validation.md  Enforcement migration verification
│   └── performance-optimization.md Context reduction and time savings
│
├── concepts/                    Understanding-oriented explanations (4 files + patterns)
│   ├── README.md                Concepts documentation index
│   ├── hierarchical_agents.md   Multi-level agent coordination
│   ├── writing-standards.md     Development philosophy and documentation
│   ├── directory-protocols.md   Topic-based artifact organization
│   ├── development-workflow.md  Development workflow patterns
│   └── patterns/                Architectural patterns catalog (9 patterns)
│       ├── README.md            Patterns catalog index
│       ├── behavioral-injection.md      Commands inject context into agents
│       ├── hierarchical-supervision.md  Multi-level agent coordination
│       ├── forward-message.md           Direct subagent response passing
│       ├── metadata-extraction.md       95-99% context reduction via summaries
│       ├── context-management.md        <30% context usage techniques
│       ├── verification-fallback.md     100% file creation via checkpoints
│       ├── checkpoint-recovery.md       State preservation and restoration
│       ├── parallel-execution.md        Wave-based concurrent execution
│       └── workflow-scope-detection.md  Conditional phase execution by scope
│
├── workflows/                   Learning-oriented step-by-step tutorials (7 files)
│   ├── README.md                Workflow tutorials index
│   ├── orchestration-guide.md   Multi-agent workflow tutorial (includes behavioral injection example)
│   ├── context-budget-management.md  Layered context architecture tutorial (21% target)
│   ├── adaptive-planning-guide.md Progressive plan structures
│   ├── checkpoint_template_guide.md Template-based planning
│   ├── spec_updater_guide.md    Spec updater agent usage
│   ├── tts-integration-guide.md TTS system setup tutorial
│   └── conversion-guide.md      Document conversion workflows
│
└── archive/                     Historical documentation (5 files)
    ├── README.md                Archive index with redirects
    ├── artifact_organization.md Topic-based organization guide (archived)
    ├── topic_based_organization.md Directory structure guide (archived)
    ├── development-philosophy.md Development philosophy (archived)
    ├── timeless_writing_guide.md Writing standards (archived)
    ├── migration-guide-adaptive-plans.md Adaptive planning migration (archived)
    └── orchestration_enhancement_guide.md Orchestration enhancements (archived)
```

## Hierarchical Agent Workflow System

Claude Code uses a sophisticated **hierarchical agent architecture** where commands orchestrate specialized subagents to execute multi-phase development workflows while preserving context through metadata-only passing.

### How It Works

**Primary Agent** (supervisor) → **Subagents** (workers) → **Artifacts** (organized by topic)

Commands invoke subagents that perform specialized tasks and return **summary + reference** (not full content), achieving 92-97% context reduction. Artifacts are organized in numbered topic directories (`specs/{NNN_topic}/`) with type-specific subdirectories.

### Command Workflow Chains

Commands orchestrate specialized subagents through structured workflows:

**`/plan`**: Creates implementation plans with automatic complexity-based expansion
- Invokes: plan-architect → complexity-evaluator → expander (if needed)
- Context: 96% reduction (8000 tokens → 350 tokens)

**`/implement`**: Executes plans phase-by-phase with testing and debugging
- Invokes: implementation-researcher (complex phases) → code-writer → test-specialist
- Debug loop: debug-specialist (max 3 iterations) when tests fail
- Context: 98% reduction through aggressive pruning

**`/research`**: Research with parallel subagents (2-4 agents concurrently)
- Context: 95% reduction (5000 tokens → 250 tokens per report)

**`/document`**: Documentation updates
- Context: 95% reduction

**`/orchestrate`**: Complete end-to-end workflow (6 phases: research → planning → implementation → testing → debugging → documentation)
- Target: <30% context usage throughout

**For Complete Command Workflow Details**: See [Hierarchical Agent Architecture - Tutorial Walkthrough](concepts/hierarchical_agents.md#tutorial-walkthrough)

### Layered Context Architecture

Agent invocations use five context layers to minimize token consumption while maintaining clarity:

1. **Meta-Context**: Agent behavior definition (0 tokens - file read via behavioral injection)
2. **Operational Context**: Task instructions (200-500 tokens)
3. **Domain Context**: Project standards reference (50-100 tokens)
4. **Historical Context**: Prior results metadata only (250 tokens vs 5000 for full content)
5. **Environmental Context**: Workflow state (100-200 tokens)

**Benefits**: 90-95% context reduction through separation of concerns and metadata-only passing

**Example**: Traditional invocation (11,500 tokens) → Layered invocation (700 tokens) = 94% reduction

**For Complete Details**: See [Layered Context Architecture](guides/agent-development-guide.md#layered-context-architecture)

### Artifact Organization

**Topic-Based Structure**: `specs/{NNN_topic}/`
```
027_authentication/
├── reports/          Research reports (gitignored)
│   ├── 027_research/             # Multiple reports from one task
│   │   ├── 027_auth_security.md
│   │   ├── 027_auth_frameworks.md
│   │   └── 027_auth_patterns.md
│   └── 028_single_report.md      # Single report (no subdirectory)
├── plans/            Implementation plans (gitignored)
│   ├── 027_auth_implementation/  # Structured plan subdirectory
│   │   ├── 027_auth_implementation.md  # Level 0 (main plan)
│   │   ├── phase_2_backend.md          # Level 1 (expanded phase)
│   │   ├── phase_4_integration.md      # Level 1 (expanded phase)
│   │   └── phase_2/                    # Level 2 (stages)
│   │       ├── stage_1_database.md
│   │       └── stage_2_api.md
│   └── 028_simple_fix.md         # Simple plan (no subdirectory)
├── summaries/        Workflow summaries (gitignored)
├── debug/            Debug reports (COMMITTED for history!)
├── scripts/          Investigation scripts (temp, gitignored)
└── outputs/          Test outputs (temp, gitignored)
```

**Plan Expansion**: Automatic expansion based on complexity thresholds
- **Level 0**: Single file, all phases inline
- **Level 1**: High-complexity phases → separate files
- **Level 2**: Complex phases → staged subdirectories

**Checkbox Propagation**: Changes cascade through plan hierarchy (L2 → L1 → L0)

### Key Features

- **Metadata-Only Passing**: 92-97% context reduction (summary + reference, not full content)
- **Layered Context Architecture**: 5-layer separation of concerns (90-95% reduction)
- **Forward Message Pattern**: Direct subagent response passing (no paraphrasing overhead)
- **Recursive Supervision**: Supervisors manage sub-supervisors (10+ agents vs 4)
- **Context Pruning**: Aggressive cleanup after phases (80-90% reduction)
- **Wave-Based Execution**: Parallel phase execution with dependencies (40-60% time savings)
- **Spec Updater Integration**: Automatic artifact management and cross-referencing

### Context Preservation

**Metadata Extraction**: Subagents return summaries, not full content
- Report metadata: 5000 tokens → 250 tokens (95% reduction)
- Plan metadata: 8000 tokens → 350 tokens (96% reduction)

**Forward Message Pattern**: Pass subagent responses directly without re-summarization

**Context Pruning**: Clear completed phase data, retain only references (80-90% reduction)

**Target**: <30% context usage throughout workflows

**For Technical Details**: See [Hierarchical Agents Guide](concepts/hierarchical_agents.md)

### Parallel Execution with Dependencies

**Phase Dependencies**: Enables wave-based parallel execution
```yaml
Phase 1: Database Setup      [no dependencies]
Phase 2: Backend API         [depends_on: [1]]
Phase 3: Frontend UI         [depends_on: [1]]
Phase 4: Integration         [depends_on: [2, 3]]

Waves:
  Wave 1: Phase 1              (30 min)
  Wave 2: Phase 2 | Phase 3    (45 min in parallel)
  Wave 3: Phase 4              (35 min)

Sequential: 150 min
Parallel: 110 min
Savings: 40 min (27%)
```

**Kahn's Algorithm**: Topological sorting for wave calculation

### Spec Updater Agent

**Purpose**: Manages artifacts and maintains cross-references throughout workflow

**Automatic Triggers**:
- Phase completion
- Context window <20% free
- Plan expansion complete
- Workflow complete

**Actions**:
- Create artifacts in topic directories
- Update plan hierarchy checkboxes (L2 → L1 → L0)
- Maintain cross-references between artifacts
- Create implementation summaries
- Verify gitignore compliance (debug/ committed, others ignored)

### Performance Metrics

**Context Reduction**: 92-97% throughout workflows (target: <30% usage)

**Time Savings with Parallelization**:
- Research phase: 40-60% faster (parallel subagents)
- Implementation phase: 40-60% faster (wave-based execution)
- Overall workflows: 35-50% faster vs sequential

**For Complete Details**: See [Hierarchical Agent Architecture](concepts/hierarchical_agents.md) and [Tutorial Walkthrough](concepts/hierarchical_agents.md#tutorial-walkthrough)

---

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
- [Creating Commands](guides/command-development-guide.md) - Complete command development guide
- [Creating Agents](guides/agent-development-guide.md) - Agent creation and design guide
- [Using Agents](guides/agent-development-guide.md) - Agent invocation and coordination patterns
- [Standards Integration](guides/standards-integration.md) - Implementing CLAUDE.md standards discovery
- [Command Patterns](guides/command-patterns.md) - Reusable command design patterns
- [Efficiency Guide](guides/performance-optimization.md) - Performance optimization techniques

### [Concepts](concepts/README.md)
Understanding-oriented explanations of architecture and design. Use when you need to understand the "why" and "how it works" behind system components.

**Core Concepts**:
- [Template vs Behavioral Distinction](reference/template-vs-behavioral-distinction.md) - Critical architectural principle for inline vs reference
- [Behavioral Injection Pattern](concepts/patterns/behavioral-injection.md) - Reference behavioral files, inject context

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
1. [Creating Commands](guides/command-development-guide.md) - Complete development guide
2. [Standards Integration](guides/standards-integration.md) - Using CLAUDE.md standards
3. [Command Patterns](guides/command-patterns.md) - Reusable patterns
4. [Using Agents](guides/agent-development-guide.md) - Integrate agents in commands

### For Agent Developers
1. [Creating Agents](guides/agent-development-guide.md) - Agent development guide
2. [Using Agents](guides/agent-development-guide.md) - Agent invocation patterns
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
- [Creating Commands](guides/command-development-guide.md) - Command development
- [Creating Agents](guides/agent-development-guide.md) - Agent creation
- [Using Agents](guides/agent-development-guide.md) - Agent integration
- [Standards Integration](guides/standards-integration.md) - Standards usage
- [Command Patterns](guides/command-patterns.md) - Pattern catalog
- [Command Examples](guides/command-examples.md) - Command examples
- [Logging Patterns](guides/logging-patterns.md) - Logging standards
- [Efficiency Guide](guides/performance-optimization.md) - Performance optimization
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
- [Creating Commands](guides/command-development-guide.md)

**Standards**:
- [Standards Integration](guides/standards-integration.md)
- [CLAUDE.md Section Schema](reference/claude-md-section-schema.md)
- [Command Architecture Standards](reference/command_architecture_standards.md)
- [Writing Standards](concepts/writing-standards.md)

**Testing**:
- [Creating Commands](guides/command-development-guide.md#testing)
- [Orchestration Guide](workflows/orchestration-guide.md#validation)

**Agents**:
- [Creating Agents](guides/agent-development-guide.md)
- [Using Agents](guides/agent-development-guide.md)
- [Agent Reference](reference/agent-reference.md)
- [Hierarchical Agents](concepts/hierarchical_agents.md)

**Commands**:
- [Creating Commands](guides/command-development-guide.md)
- [Command Reference](reference/command-reference.md)
- [Command Patterns](guides/command-patterns.md)

**TTS**:
- [TTS Integration Guide](workflows/tts-integration-guide.md)

**Conversion**:
- [Conversion Guide](workflows/conversion-guide.md)

### Related Directories

- [← Parent Directory](../README.md)
- [agents/](../agents/README.md) - Agent definitions
- [commands/](../../commands/README.md) - Command definitions
- [tts/](../tts/README.md) - TTS implementation
- [hooks/](../hooks/README.md) - Hook scripts
- [lib/](../lib/README.md) - Shared utilities

## Quick Reference

### Template Usage Decision Tree
See: [Template Usage Decision Tree](quick-reference/template-usage-decision-tree.md)

```
Should this content be inline in command file?
├─ Is it STRUCTURAL? → YES → Inline (Task blocks, bash, schemas)
└─ Is it BEHAVIORAL? → YES → Reference agent file (STEP sequences, workflows)
```

Quick decisions for inline vs reference patterns. Use when creating commands and unsure whether to duplicate content or reference agent files.

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
See: [Creating Commands](guides/command-development-guide.md)

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
See: [Using Agents](guides/agent-development-guide.md)

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
- [Using Agents](guides/agent-development-guide.md)
- [Command Reference](reference/command-reference.md)

### Implementation Planning
- [Adaptive Planning Guide](workflows/adaptive-planning-guide.md)
- [Template System Guide](workflows/checkpoint_template_guide.md)
- [Creating Commands](guides/command-development-guide.md)

### Standards and Quality
- [Command Architecture Standards](reference/command_architecture_standards.md)
- [Standards Integration](guides/standards-integration.md)
- [CLAUDE.md Section Schema](reference/claude-md-section-schema.md)
- [Writing Standards](concepts/writing-standards.md)
- [Creating Commands](guides/command-development-guide.md#quality-checklist)
- [Command Patterns](guides/command-patterns.md)

### Agent System
- [Creating Agents](guides/agent-development-guide.md)
- [Using Agents](guides/agent-development-guide.md)
- [Agent Reference](reference/agent-reference.md)
- [Hierarchical Agents](concepts/hierarchical_agents.md)
- [../agents/README.md](../agents/README.md)

### Command System
- [Creating Commands](guides/command-development-guide.md)
- [Command Reference](reference/command-reference.md)
- [Command Patterns](guides/command-patterns.md)
- [../commands/README.md](../../commands/README.md)

### TTS System
- [TTS Integration Guide](workflows/tts-integration-guide.md)
- [../tts/README.md](../tts/README.md)
- [../hooks/tts-dispatcher.sh](../hooks/tts-dispatcher.sh)

### Document Conversion
- [Conversion Guide](workflows/conversion-guide.md)
- [../agents/doc-converter.md](../agents/doc-converter.md)
- [../commands/convert-docs.md](../commands/convert-docs.md)

### Performance and Optimization
- [Efficiency Guide](guides/performance-optimization.md)
- [Error Enhancement Guide](guides/error-enhancement-guide.md)
- [Orchestration Guide](workflows/orchestration-guide.md#troubleshooting)

## About Diataxis

This documentation follows the [Diataxis framework](https://diataxis.fr/), which organizes documentation into four categories based on user needs:

- **Reference** (information-oriented): Dry, factual information for lookup
- **Guides** (task-oriented): Practical instructions to achieve specific goals
- **Concepts** (understanding-oriented): Explanations to build comprehension
- **Workflows** (learning-oriented): Lessons to acquire skills

This structure ensures developers can quickly find documentation that matches their current need, whether they're learning, solving a problem, understanding architecture, or looking up syntax.
