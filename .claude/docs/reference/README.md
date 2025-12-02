# Reference Documentation

## Purpose

Information-oriented quick lookup documentation organized into focused subdirectories: architecture, workflows, library-api, standards, and templates. Use this section when you need rapid access to specific technical details, API signatures, or architectural requirements.

## Navigation

- [Documentation Index](../README.md)
- [Guides](../guides/) - Task-focused how-to documentation
- [Concepts](../concepts/) - Understanding-oriented architectural explanations
- [Workflows](../workflows/) - Step-by-step workflow tutorials

## Subdirectories

### [Decision Trees](decision-trees/README.md)
Decision flowcharts and visual guides for rapid decision-making when working with the .claude/ system.

**Contents**:
- `README.md` - Decision trees index
- `command-vs-agent-flowchart.md` - When to use commands vs agents
- `agent-selection-flowchart.md` - Which agent to use for different tasks
- `error-handling-flowchart.md` - Systematic error diagnosis and resolution
- `template-usage-decision-tree.md` - When to use plan templates vs custom plans
- `executable-vs-guide-content.md` - Distinguishing executable from guide documentation
- `step-pattern-classification-flowchart.md` - Classifying step patterns in workflows

---

### [Architecture](architecture/README.md)
Architecture standards documentation for command and component design patterns.

**Contents**:
- `overview.md` - Architecture standards overview and core principles
- `validation.md` - Validation patterns and requirements
- `documentation.md` - Architecture documentation standards
- `integration.md` - Integration patterns and approaches
- `dependencies.md` - Dependency management standards
- `error-handling.md` - Error handling patterns
- `testing.md` - Architecture testing requirements
- `template-vs-behavioral.md` - Distinction between template and behavioral content

---

### [Workflows](workflows/README.md)
Workflow phase documentation for planning, implementation, testing, and documentation lifecycles.

**Contents**:
- `phases-overview.md` - Overview of workflow phases and structure
- `phases-research.md` - Research phase patterns and practices
- `phases-planning.md` - Planning phase patterns and practices
- `phases-implementation.md` - Implementation phase patterns and practices
- `phases-testing.md` - Testing phase patterns and practices
- `phases-documentation.md` - Documentation phase patterns and practices
- `orchestration-reference.md` - Orchestration patterns reference
- `phase-dependencies.md` - Phase dependency definitions and patterns

---

### [Library API](library-api/README.md)
API reference documentation for the shell library functions powering the Claude workflow system.

**Contents**:
- `overview.md` - Library API overview and organization
- `state-machine.md` - State machine API reference
- `persistence.md` - Persistence utilities API reference
- `utilities.md` - General utility functions API reference

---

### [Standards](standards/README.md)
Core standards documentation governing command authoring, testing, code quality, and system configuration.

**Contents**:
- `command-reference.md` - Complete command catalog with syntax and examples
- `command-patterns-quick-reference.md` - Quick reference for common command patterns
- `agent-reference.md` - Agent catalog with roles and capabilities
- `testing-protocols.md` - Test discovery, patterns, and coverage requirements
- `code-standards.md` - Coding conventions and architectural requirements
- `output-formatting.md` - Output suppression and formatting standards
- `command-authoring.md` - Command development standards
- `claude-md-schema.md` - CLAUDE.md section schema reference
- `test-isolation.md` - Test isolation standards
- `adaptive-planning.md` - Adaptive planning configuration
- `plan-progress.md` - Plan progress tracking patterns

---

### [Templates](templates/README.md)
Template and structure documentation for consistent artifact creation and management.

**Contents**:
- `debug-structure.md` - Debug report structure template
- `refactor-structure.md` - Refactoring plan structure template
- `report-structure.md` - Research report structure template
- `backup-policy.md` - Backup retention policy documentation

---

## Quick Start

### Look Up a Command
```bash
# Open command reference and search for command name
less .claude/docs/reference/standards/command-reference.md
# Search: /commandname
```

### Find the Right Agent
```bash
# Open agent reference and browse by capability
less .claude/docs/reference/standards/agent-reference.md
# Look for "Capabilities" sections
```

### Check Standards Schema
```bash
# View section format requirements
less .claude/docs/reference/standards/claude-md-schema.md
# Look for "Standard Sections" for examples
```

### Look Up Library API
```bash
# Find utility function signatures
less .claude/docs/reference/library-api/overview.md
```

### Pattern Discovery
```bash
# Find architecture standards
less .claude/docs/reference/architecture/overview.md

# Look up workflow phases
less .claude/docs/reference/workflows/phases-overview.md
```

## Directory Structure

```
reference/
├── README.md                           (this file)
├── decision-trees/                      Decision Flowcharts (7 files)
│   ├── README.md
│   ├── command-vs-agent-flowchart.md
│   ├── agent-selection-flowchart.md
│   ├── error-handling-flowchart.md
│   ├── template-usage-decision-tree.md
│   ├── executable-vs-guide-content.md
│   └── step-pattern-classification-flowchart.md
├── architecture/                        Architecture Standards (8 files)
│   ├── README.md
│   ├── overview.md
│   ├── validation.md
│   ├── documentation.md
│   ├── integration.md
│   ├── dependencies.md
│   ├── error-handling.md
│   ├── testing.md
│   └── template-vs-behavioral.md
├── workflows/                           Workflow Documentation (8 files)
│   ├── README.md
│   ├── phases-overview.md
│   ├── phases-research.md
│   ├── phases-planning.md
│   ├── phases-implementation.md
│   ├── phases-testing.md
│   ├── phases-documentation.md
│   ├── orchestration-reference.md
│   └── phase-dependencies.md
├── library-api/                         Library API Reference (4 files)
│   ├── README.md
│   ├── overview.md
│   ├── state-machine.md
│   ├── persistence.md
│   └── utilities.md
├── standards/                           Core Standards (10 files)
│   ├── README.md
│   ├── command-reference.md
│   ├── agent-reference.md
│   ├── testing-protocols.md
│   ├── code-standards.md
│   ├── output-formatting.md
│   ├── command-authoring.md
│   ├── claude-md-schema.md
│   ├── test-isolation.md
│   ├── adaptive-planning.md
│   └── plan-progress.md
└── templates/                           Templates (4 files)
    ├── README.md
    ├── debug-structure.md
    ├── refactor-structure.md
    ├── report-structure.md
    └── backup-policy.md
```

## Related Documentation

**Other Categories**:
- [Guides](../guides/) - Task-focused how-to guides build on reference specifications
- [Concepts](../concepts/) - Architectural concepts explain the design rationale behind reference standards
- [Decision Trees](decision-trees/) - Fast decision tools and flowcharts for common choices
- [Workflows](../workflows/) - Step-by-step workflows apply reference specifications to real tasks

**Key Frameworks** (Cross-Directory):
- [Robustness Framework](../concepts/robustness-framework.md) - Unified index of 9 reliability patterns
- [Defensive Programming](../concepts/patterns/defensive-programming.md) - 5 defensive patterns with examples
- [Architectural Decisions](../concepts/architectural-decision-framework.md) - Decision criteria for fundamental choices

**External Directories**:
- [Commands](../../commands/) - Command implementation files
- [Agents](../../agents/) - Agent implementation files
- [Libraries](../../lib/) - Utility libraries referenced in standards

## Navigation

- [← Parent Directory](../README.md)
- [Subdirectory: architecture/](architecture/README.md)
- [Subdirectory: standards/](standards/README.md)
- [Subdirectory: workflows/](workflows/README.md)
- [Subdirectory: library-api/](library-api/README.md)
- [Subdirectory: decision-trees/](decision-trees/README.md)
