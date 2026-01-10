# Context Organization

[Back to Docs](../docs/README.md) | [Architecture](../ARCHITECTURE.md) | [CLAUDE.md](../CLAUDE.md)

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Core Context](#core-context)
4. [Project Context](#project-context)
5. [Context Loading Strategy](#context-loading-strategy)
6. [File Naming Conventions](#file-naming-conventions)
7. [Adding New Context Files](#adding-new-context-files)

---

## Overview

The `context/` directory organizes domain knowledge and standards for the Claude agent system. Files are loaded on-demand based on task requirements.

**Structure**:
- `core/` - Reusable patterns applicable to any project (41 files)
- `project/` - ModelChecker-specific domain knowledge (54 files)

---

## Directory Structure

```
.claude/context/
├── README.md                           # This file
├── index.md                            # Context loading index
│
├── core/                               # Reusable patterns (41 files)
│   ├── orchestration/                  # System orchestration (11 files)
│   ├── formats/                        # Output formats (7 files)
│   ├── standards/                      # Quality standards (10 files)
│   ├── workflows/                      # Workflow patterns (5 files)
│   ├── templates/                      # Reusable templates (5 files)
│   └── schemas/                        # JSON/YAML schemas (2 files)
│
└── project/                            # ModelChecker-specific (54 files)
    ├── modelchecker/                   # Core project context
    ├── meta/                           # Meta-builder context
    ├── logic/                          # Logic domain knowledge
    ├── lean4/                          # Lean 4 knowledge (shared)
    ├── math/                           # Math domain knowledge
    ├── physics/                        # Physics domain knowledge
    ├── processes/                      # Development workflows
    └── repo/                           # Repository-specific
```

---

## Core Context

Reusable patterns applicable to any Claude agent system.

### orchestration/ (11 files)

System architecture, routing, and delegation patterns.

| File | Purpose |
|------|---------|
| `architecture.md` | Three-layer delegation pattern |
| `orchestrator.md` | Orchestrator design and guide |
| `routing.md` | Routing logic and patterns |
| `delegation.md` | Delegation patterns and safety |
| `validation.md` | Validation strategies |
| `subagent-validation.md` | Subagent return validation |
| `state-management.md` | State and artifact management |
| `state-lookup.md` | State.json query patterns (jq) |
| `sessions.md` | Session management |
| `preflight-pattern.md` | Pre-execution patterns |
| `postflight-pattern.md` | Post-execution patterns |

### formats/ (7 files)

Output formats and document structures.

| File | Purpose |
|------|---------|
| `command-structure.md` | Command files as agents |
| `command-output.md` | Command output format |
| `subagent-return.md` | Subagent return JSON format |
| `plan-format.md` | Implementation plan format |
| `report-format.md` | Research report format |
| `summary-format.md` | Summary document format |
| `frontmatter.md` | Frontmatter standard |

### standards/ (10 files)

Quality standards for code, documentation, and processes.

| File | Purpose |
|------|---------|
| `code-patterns.md` | Code and pattern standards |
| `error-handling.md` | Error handling patterns |
| `git-safety.md` | Git safety patterns |
| `git-integration.md` | Git integration patterns |
| `documentation.md` | Documentation standards |
| `testing.md` | Testing standards |
| `xml-structure.md` | XML structure patterns |
| `task-management.md` | Task management standards |
| `status-markers.md` | Status marker conventions |
| `analysis-framework.md` | Analysis framework |

### workflows/ (5 files)

Command and task workflow patterns.

| File | Purpose |
|------|---------|
| `command-lifecycle.md` | Command execution lifecycle |
| `status-transitions.md` | Status transition rules |
| `task-breakdown.md` | Task breakdown patterns |
| `review-process.md` | Review process workflow |
| `preflight-postflight.md` | Workflow timing standards |

### templates/ (5 files)

Reusable templates for creating new components.

| File | Purpose |
|------|---------|
| `agent-template.md` | Agent definition template |
| `subagent-template.md` | Subagent template |
| `command-template.md` | Command file template |
| `orchestrator-template.md` | Orchestrator template |
| `delegation-context.md` | Delegation context template |

### schemas/ (2 files)

JSON and YAML schemas for validation.

| File | Purpose |
|------|---------|
| `frontmatter-schema.json` | Frontmatter JSON schema |
| `subagent-frontmatter.yaml` | Subagent frontmatter template |

---

## Project Context

ModelChecker-specific domain knowledge and patterns.

### modelchecker/ (3 files)

Core ModelChecker project context.

| File | Purpose |
|------|---------|
| `architecture.md` | ModelChecker system architecture |
| `theories.md` | Theory library overview (logos, exclusion, imposition, bimodal) |
| `z3-patterns.md` | Z3 solver patterns and best practices |

### meta/ (6 files)

Meta-builder context for creating agent systems.

| File | Purpose |
|------|---------|
| `domain-patterns.md` | Domain pattern recognition |
| `architecture-principles.md` | Architecture design principles |
| `meta-guide.md` | Meta-builder guide |
| `interview-patterns.md` | Interview patterns for system design |
| `context-revision-guide.md` | Context revision guide |
| `standards-checklist.md` | Standards compliance checklist |

### logic/ (12 files)

Logic domain knowledge for semantic theory development.

```
logic/
├── README.md
├── domain/                     # Core concepts
│   ├── kripke-semantics-overview.md
│   ├── metalogic-concepts.md
│   ├── proof-theory-concepts.md
│   └── task-semantics.md
├── processes/                  # Proof workflows
│   ├── modal-proof-strategies.md
│   ├── proof-construction.md
│   ├── temporal-proof-strategies.md
│   └── verification-workflow.md
└── standards/                  # Conventions
    ├── naming-conventions.md
    ├── notation-standards.md
    └── proof-conventions.md
```

### lean4/ (22 files)

Lean 4 theorem proving knowledge (shared from ProofChecker).

```
lean4/
├── README.md
├── domain/                     # Lean 4 concepts
├── patterns/                   # Tactic patterns
├── processes/                  # Proof workflows
├── standards/                  # Style guides
├── templates/                  # File templates
└── tools/                      # Tool integration (LSP, LeanSearch, Loogle)
```

### math/ (5 files)

Mathematical domain knowledge.

| Directory | Topics |
|-----------|--------|
| `algebra/` | Groups, monoids, rings, fields |
| `lattice-theory/` | Lattice structures |
| `order-theory/` | Partial orders |
| `topology/` | Topological spaces |

### physics/ (1 file)

Physics domain knowledge.

| Directory | Topics |
|-----------|--------|
| `dynamical-systems/` | Dynamical systems concepts |

### processes/ (3 files)

Development workflow processes.

| File | Purpose |
|------|---------|
| `research-workflow.md` | Research phase workflow |
| `planning-workflow.md` | Planning phase workflow |
| `implementation-workflow.md` | Implementation phase workflow |

### repo/ (2 files)

Repository-specific information.

| File | Purpose |
|------|---------|
| `project-overview.md` | Project overview |
| `self-healing-implementation-details.md` | Self-healing patterns |

---

## Context Loading Strategy

### Three-Tier Loading

Context is loaded based on operation type to minimize context window usage.

**Tier 1: Orchestrator (Minimal)**
- Budget: <5% context window (~10KB)
- Files: `orchestration/routing.md`, `orchestration/delegation.md`
- Purpose: Routing and delegation safety

**Tier 2: Commands (Targeted)**
- Budget: 10-20% context window (~20-40KB)
- Files: `formats/subagent-return.md`, `workflows/status-transitions.md`
- Purpose: Command validation and formatting

**Tier 3: Skills (Domain-Specific)**
- Budget: 60-80% context window (~120-160KB)
- Files: `project/modelchecker/*`, `project/logic/*`
- Purpose: Domain-specific work with full context

### Performance Note

State.json queries via jq are 8x faster than TODO.md parsing (12ms vs 100ms). See `orchestration/state-lookup.md` for query patterns.

---

## File Naming Conventions

**Pattern**: `{topic}-{qualifier}.md`

**Examples**:
- `subagent-return.md` (topic: subagent, qualifier: return)
- `plan-format.md` (topic: plan, qualifier: format)
- `code-patterns.md` (topic: code, qualifier: patterns)

**Rules**:
- Use kebab-case
- Be descriptive but concise
- Avoid redundant suffixes
- Group by purpose in appropriate directory

---

## Adding New Context Files

### For Reusable Patterns

Add to `core/` in the appropriate subdirectory:

| Type | Directory |
|------|-----------|
| Orchestration | `core/orchestration/` |
| Output formats | `core/formats/` |
| Quality standards | `core/standards/` |
| Workflows | `core/workflows/` |
| Templates | `core/templates/` |
| Schemas | `core/schemas/` |

### For ModelChecker-Specific Context

Add to `project/` in the appropriate subdirectory:

| Type | Directory |
|------|-----------|
| Project architecture | `project/modelchecker/` |
| Meta-builder | `project/meta/` |
| Logic domain | `project/logic/` |
| Lean 4 knowledge | `project/lean4/` |
| Math concepts | `project/math/` |
| Physics concepts | `project/physics/` |
| Workflows | `project/processes/` |
| Repository-specific | `project/repo/` |

---

[Back to Docs](../docs/README.md) | [Architecture](../ARCHITECTURE.md) | [CLAUDE.md](../CLAUDE.md)
