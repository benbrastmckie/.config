# Context Organization

**Updated**: 2026-02-02 (Task 22 - Neovim Focus)
**Purpose**: Organize context files for efficient loading and clear separation of concerns

---

## Directory Structure

```
.opencode/context/
├── core/                           # General/reusable context (36 files)
│   ├── orchestration/              # System orchestration (8 files)
│   │   ├── architecture.md         # Three-layer delegation pattern
│   │   ├── orchestrator.md         # Orchestrator design and guide
│   │   ├── routing.md              # Routing logic and patterns
│   │   ├── delegation.md           # Delegation patterns and safety
│   │   ├── validation.md           # Validation strategies and rules
│   │   ├── state-management.md     # State and artifact management
│   │   └── sessions.md             # Session management
│   │
│   ├── formats/                    # Output formats and structures (7 files)
│   │   ├── command-structure.md    # Command files as agents
│   │   ├── subagent-return.md      # Subagent return format
│   │   ├── command-output.md       # Command output format
│   │   ├── plan-format.md          # Implementation plan format
│   │   ├── report-format.md        # Research report format
│   │   ├── summary-format.md       # Summary format
│   │   └── frontmatter.md          # Frontmatter standard
│   │
│   ├── standards/                  # Quality standards (8 files)
│   │   ├── code-patterns.md        # Code and pattern standards
│   │   ├── error-handling.md       # Error handling patterns
│   │   ├── git-safety.md           # Git safety patterns
│   │   ├── documentation.md        # Documentation standards
│   │   ├── testing.md              # Testing standards
│   │   ├── xml-structure.md        # XML structure patterns
│   │   ├── task-management.md      # Task management standards
│   │   └── analysis-framework.md   # Analysis framework
│   │
│   ├── workflows/                  # Workflow patterns (5 files)
│   │   ├── command-lifecycle.md    # Command lifecycle
│   │   ├── status-transitions.md   # Status transition rules
│   │   ├── task-breakdown.md       # Task breakdown patterns
│   │   ├── review-process.md       # Review process workflow
│   │   └── preflight-postflight.md # Workflow timing standards
│   │
│   ├── templates/                  # Reusable templates (6 files)
│   │   ├── agent-template.md       # Agent template
│   │   ├── subagent-template.md    # Subagent template
│   │   ├── command-template.md     # Command template
│   │   ├── orchestrator-template.md # Orchestrator template
│   │   ├── delegation-context.md   # Delegation context template
│   │   └── state-template.json     # State.json template
│   │
│   └── schemas/                    # JSON/YAML schemas (2 files)
│       ├── frontmatter-schema.json # Frontmatter JSON schema
│       └── subagent-frontmatter.yaml # Subagent frontmatter template
│
├── project/                        # Domain-specific context
│   ├── meta/                       # Meta-builder context (4 files)
│   │   ├── domain-patterns.md      # Domain pattern recognition
│   │   ├── architecture-principles.md # Architecture principles
│   │   ├── meta-guide.md           # Meta-builder guide
│   │   └── interview-patterns.md   # Interview patterns
│   │
  │   ├── neovim/                     # Neovim configuration knowledge
  │   │   ├── domain/                 # API and concepts
  │   │   ├── patterns/               # Configuration patterns
  │   │   ├── standards/              # Coding standards
  │   │   ├── templates/              # Template files
  │   │   └── tools/                  # Tool documentation (lazy.nvim, etc.)
  │   │
  │   ├── hooks/                      # Git hooks context
│   │
│   ├── processes/                  # Process documentation
│   │
│   └── repo/                       # Repository-specific
│       ├── project-overview.md
│       └── self-healing-implementation-details.md
│
└── README.md                       # This file
```

---

## Core vs Project

### core/ (36 files across 6 directories)

**Purpose**: General, reusable context applicable to any project

**Contents**:

- **orchestration/** - System architecture, routing, delegation, state management
- **formats/** - Output formats for plans, reports, summaries, returns
- **standards/** - Quality standards for code, errors, git, documentation, testing
- **workflows/** - Workflow patterns for commands, status transitions, reviews
- **templates/** - Reusable templates for agents, commands, orchestrator
- **schemas/** - JSON/YAML schemas for validation

**When to use**: Context that doesn't depend on project-specific domains

**Key Files**:

- `orchestration/architecture.md` - Three-layer delegation pattern (critical for meta-builder)
- `formats/command-structure.md` - Commands as agents pattern
- `workflows/preflight-postflight.md` - Workflow timing standards
- `orchestration/state-management.md` - State management and fast lookup patterns (8x faster than TODO.md)

### project/

**Purpose**: Domain-specific knowledge for supported languages

**Contents**:

- **meta/** - Meta-builder context (domain patterns, architecture principles)
- **neovim/** - Neovim configuration knowledge (API, patterns, plugins)
- **hooks/** - Git hooks context
- **processes/** - Process documentation
- **repo/** - Repository-specific information

**When to use**: Context specific to the language being worked on

---

## Context Loading Strategy

### Three-Tier Loading

**Tier 1: Orchestrator (Minimal)**

- Budget: <5% context window (~10KB)
- Files: `orchestration/routing.md`, `orchestration/delegation.md`
- Purpose: Routing and delegation safety

**Tier 2: Commands (Targeted)**

- Budget: 10-20% context window (~20-40KB)
- Files: `formats/subagent-return.md`, `workflows/status-transitions.md`, command-specific
- Purpose: Command validation and formatting

**Tier 3: Agents (Domain-Specific)**

- Budget: 60-80% context window (~120-160KB)
- Files: `project/neovim/*`, `project/web/*`, etc.
- Purpose: Domain-specific work with full context

**Performance Optimization**:

- State.json queries are 8x faster than TODO.md parsing (12ms vs 100ms)
- See `orchestration/state-management.md` for query patterns

---

## File Naming Conventions

**Pattern**: `{topic}-{type}.md`

**Examples**:

- `subagent-return.md` (not `subagent-return-format.md`)
- `plan-format.md` (not `plan.md`)
- `code-patterns.md` (not `code.md` or `patterns.md`)

**Rules**:

- Use kebab-case
- Be descriptive but concise
- Avoid redundant suffixes (e.g., `-format` only when needed for clarity)
- Group by purpose in appropriate directory

---

## Adding New Context Files

### For General/Reusable Context

Add to `core/`:

- Orchestration → `core/orchestration/`
- Formats → `core/formats/`
- Standards → `core/standards/`
- Workflows → `core/workflows/`
- Templates → `core/templates/`
- Schemas → `core/schemas/`

### For Domain-Specific Context

Add to `project/`:

- Meta-builder → `project/meta/`
- Neovim → `project/neovim/`
- Web → `project/web/`
- Repo-specific → `project/repo/`
