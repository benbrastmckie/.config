# Concepts Documentation

## Purpose

Understanding-oriented explanations of system architecture and principles. Use this section when you need to deeply understand how the Claude Code system works, why it's designed this way, and how different components interact.

## Navigation

- [← Documentation Index](../README.md)
- [Reference](../reference/) - Quick lookup for specifications
- [Guides](../guides/) - Task-focused how-to documentation
- [Workflows](../workflows/) - Step-by-step tutorials

## Documents in This Section

### [Hierarchical Agent Architecture](hierarchical-agents.md)
**Purpose**: Complete architecture guide for multi-level agent coordination with metadata-based context passing, recursive supervision, and context pruning strategies. Includes comprehensive tutorial walkthrough section with step-by-step examples of /orchestrate, /implement, and /plan workflows.

**Use Cases**:
- To understand how hierarchical agents minimize context consumption
- When designing multi-agent workflows that need to scale beyond 4-5 agents
- To learn metadata extraction patterns and forward message techniques
- When debugging context exhaustion issues in complex workflows
- For step-by-step tutorial walkthroughs of complete workflows (see Tutorial Walkthrough section)

**See Also**: [Using Agents](../guides/development/agent-development/agent-development-fundamentals.md), [Orchestration Guide](../workflows/orchestration-guide.md), [Command Architecture Standards](../reference/architecture/overview.md)

---

### [Writing Standards](writing-standards.md)
**Purpose**: Comprehensive guide covering project development philosophy, documentation standards, and timeless writing principles including clean-break refactoring and present-focused documentation.

**Use Cases**:
- To understand the project's philosophy on refactoring and backward compatibility
- When writing or updating documentation to ensure timeless, present-focused content
- To learn which patterns are banned (temporal markers like "New", "Updated") and why
- When deciding whether to preserve historical context or create clean documentation

**See Also**: [Development Workflow](development-workflow.md), [Documentation Policy in CLAUDE.md](../../../CLAUDE.md#documentation_policy)

---

### [Directory Protocols](directory-protocols.md)
**Purpose**: Comprehensive guide for the topic-based artifact organization system used in specs/ directories, including artifact taxonomy, lifecycle, and gitignore compliance.

**Use Cases**:
- To understand how artifacts are organized in topic-based directories
- When creating new topics or organizing implementation artifacts
- To learn which artifacts are gitignored vs committed (debug/ is committed)
- When implementing artifact cleanup or retention policies

**See Also**: [Development Workflow](development-workflow.md), [Spec Updater Guide](../workflows/spec_updater_guide.md)

---

### [Directory Organization](directory-organization.md)
**Purpose**: Complete directory structure guide for .claude/ system including scripts/, lib/, commands/, agents/ descriptions, file placement rules, decision matrix, and anti-patterns.

**Use Cases**:
- To understand where to place new files in .claude/ directory
- When implementing new commands or agents and need file placement guidance
- To learn the decision process for scripts/ vs lib/ placement
- When reviewing code and ensuring proper directory organization

**See Also**: [Directory Protocols](directory-protocols.md), [Command Development Guide](../guides/development/command-development/command-development-fundamentals.md)

---

### [Development Workflow](development-workflow.md)
**Purpose**: Overview of the standard development workflow including research, planning, implementation, testing, and summarization phases with spec updater integration.

**Use Cases**:
- To understand the complete development lifecycle from research to summary
- When learning how the spec updater agent manages artifacts
- To understand artifact lifecycle and when cleanup occurs
- When implementing plan hierarchy updates and checkbox propagation

**See Also**: [Directory Protocols](directory-protocols.md), [Spec Updater Guide](../workflows/spec_updater_guide.md), [Orchestration Guide](../workflows/orchestration-guide.md)

---

## Quick Start

### Understand Agent Architecture
1. Start with [Hierarchical Agent Architecture](hierarchical-agents.md)
2. Review metadata extraction examples and context reduction metrics
3. Study forward message pattern for efficient subagent coordination
4. Learn recursive supervision for scaling beyond 5 agents

### Learn Documentation Philosophy
1. Read [Writing Standards](writing-standards.md) development philosophy
2. Understand clean-break refactoring principles
3. Study banned patterns and timeless writing guidelines
4. Review decision framework for historical vs functional content

### Master Artifact Organization
1. Study [Directory Protocols](directory-protocols.md) topic structure
2. Learn artifact categories and lifecycle management
3. Understand gitignore compliance (debug/ committed, others ignored)
4. Review shell utilities for artifact operations

## Directory Structure

```
concepts/
├── README.md                   (this file)
├── hierarchical-agents.md      Multi-level agent coordination architecture
├── writing-standards.md        Development philosophy and documentation standards
├── directory-protocols.md      Topic-based artifact organization system
├── directory-organization.md   Directory structure and file placement rules
└── development-workflow.md     Standard development lifecycle and spec updater
```

## Related Documentation

**Other Categories**:
- [Reference](../reference/) - Specifications that implement these concepts
- [Guides](../guides/) - How-to guides that apply these concepts
- [Workflows](../workflows/) - Tutorials demonstrating these concepts in practice

**External Directories**:
- [Agents](../../agents/) - Agent implementations using hierarchical architecture
- [Libraries](../../lib/) - Utilities implementing directory protocols
- [Data](../../data/) - Runtime data following lifecycle policies
- [Commands](../../commands/) - Commands following architecture standards

## Understanding the System

### Architecture Layers

The Claude Code system uses a layered architecture:

1. **Concept Layer** (this directory): Core principles and design philosophy
2. **Reference Layer**: Specifications and schemas implementing concepts
3. **Guide Layer**: Practical how-to documentation applying concepts
4. **Workflow Layer**: End-to-end tutorials demonstrating complete workflows

### Key Principles

**Hierarchical Agents**:
- Minimize context through metadata-only passing (99% reduction)
- Enable recursive supervision for scalable multi-agent workflows
- Aggressive context pruning after phase completion

**Writing Standards**:
- Clean-break refactors over backward compatibility
- Present-focused documentation without historical markers
- Timeless writing that describes current state

**Directory Protocols**:
- Topic-based organization co-locates related artifacts
- Lifecycle management from creation to cleanup
- Gitignore compliance ensures proper version control

**Development Workflow**:
- 5-phase standard workflow (research → plan → implement → test → summarize)
- Spec updater manages artifacts and cross-references
- Adaptive planning adjusts during implementation

### Reading Path

**For New Developers**:
1. [Development Workflow](development-workflow.md) - Overview of standard process
2. [Directory Protocols](directory-protocols.md) - Where things go
3. [Writing Standards](writing-standards.md) - How to document
4. [Hierarchical Agents](hierarchical-agents.md) - Advanced coordination

**For Command Developers**:
1. [Hierarchical Agents](hierarchical-agents.md) - Agent coordination patterns
2. [Directory Protocols](directory-protocols.md) - Artifact management
3. [Development Workflow](development-workflow.md) - Workflow integration
4. [Writing Standards](writing-standards.md) - Documentation quality

**For System Architects**:
1. All concept documents in sequence
2. Cross-reference with [Command Architecture Standards](../reference/architecture/overview.md)
3. Study utilities in [Libraries](../../lib/)
4. Review command implementations in [Commands](../../commands/)
