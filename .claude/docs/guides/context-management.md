# Context Management Guide

[Back to Docs](../README.md) | [Context Index](../../context/README.md)

How to manage context files effectively in the ModelChecker `.claude/` system.

---

## Overview

Context files provide domain knowledge and standards that skills use during execution. They are organized in `.claude/context/` with core patterns and project-specific knowledge.

### Directory Structure

```
.claude/context/
├── index.md                     # Context index
├── README.md                    # Context organization docs
├── core/                        # Reusable patterns
│   ├── formats/                 # File format specs
│   ├── orchestration/           # Orchestration patterns
│   ├── schemas/                 # JSON/YAML schemas
│   ├── standards/               # Coding standards
│   ├── templates/               # File templates
│   └── workflows/               # Workflow patterns
└── project/                     # Project-specific
    ├── lean4/                   # Lean 4 context
    ├── logic/                   # Logic domain
    ├── math/                    # Math domain
    ├── meta/                    # Meta-programming
    ├── modelchecker/            # ModelChecker-specific
    └── processes/               # Process patterns
```

---

## Loading Strategies

### Lazy Loading (Recommended)

Load context files only when needed:

```markdown
## Context Loading

1. Check if context is needed for current operation
2. Load specific files on-demand
3. Avoid loading entire directories
```

**Benefits**:
- Minimal context window usage
- Faster operations
- Lower token costs

### Eager Loading

Load all needed context upfront (use sparingly):

```markdown
## Context Loading

Load at start:
- core/orchestration/delegation.md
- core/orchestration/state-management.md
- project/modelchecker/architecture.md
```

**When to use**:
- Complex operations needing multiple context files
- Operations where context is always needed

---

## Context Categories

### Core Context

Reusable patterns applicable across projects:

| Category | Purpose | Examples |
|----------|---------|----------|
| `formats/` | File format specs | plan-format.md, report-format.md |
| `orchestration/` | Orchestration patterns | delegation.md, routing.md |
| `schemas/` | JSON/YAML schemas | frontmatter-schema.json |
| `standards/` | Coding standards | error-handling.md, git-safety.md |
| `templates/` | File templates | command-template.md |
| `workflows/` | Workflow patterns | command-lifecycle.md |

### Project Context

ModelChecker-specific knowledge:

| Category | Purpose | Examples |
|----------|---------|----------|
| `modelchecker/` | System architecture | architecture.md, theories.md, z3-patterns.md |
| `logic/` | Logic domain | kripke-semantics-overview.md |
| `math/` | Math domain | lattices.md, partial-orders.md |
| `lean4/` | Lean 4 (legacy) | lean4-style-guide.md |
| `meta/` | Meta-programming | architecture-principles.md |

---

## Best Practices

### 1. Use the Context Index

Start with `.claude/context/index.md` to discover available context:

```markdown
## Finding Context

1. Read .claude/context/index.md
2. Identify relevant categories
3. Load specific files needed
```

### 2. Load Minimally

Only load what you need:

**Wrong**:
```markdown
Load all of:
- core/orchestration/
- core/standards/
- project/modelchecker/
```

**Right**:
```markdown
Load:
- core/orchestration/delegation.md (for delegation patterns)
- project/modelchecker/z3-patterns.md (for Z3 specifics)
```

### 3. Document Loading

In skills, document what context is loaded:

```markdown
## Context Loading

This skill loads:
- `core/orchestration/delegation.md` - For delegation patterns
- `project/modelchecker/theories.md` - For theory structure
```

### 4. Check Before Loading

Verify the file exists and is relevant:

```markdown
1. Check if operation needs this context
2. Verify file exists at expected path
3. Load and parse relevant sections
```

---

## Common Context Files

### For Task Operations

| File | When to Load |
|------|--------------|
| `core/orchestration/state-management.md` | Status updates |
| `core/orchestration/delegation.md` | Skill delegation |
| `core/standards/git-safety.md` | Git commits |

### For Research

| File | When to Load |
|------|--------------|
| `project/modelchecker/architecture.md` | Understanding codebase |
| `project/modelchecker/theories.md` | Theory patterns |
| `project/modelchecker/z3-patterns.md` | Z3 specifics |

### For Implementation

| File | When to Load |
|------|--------------|
| `core/formats/plan-format.md` | Reading plans |
| `project/modelchecker/z3-patterns.md` | Z3 patterns |
| `core/standards/error-handling.md` | Error handling |

---

## Context File Format

### Standard Structure

```markdown
# {Title}

{Brief description}

## Overview

{Detailed description}

## {Section 1}

{Content}

## {Section 2}

{Content}

## See Also

- [Related File](path)
```

### File Size Guidelines

| Type | Target | Maximum |
|------|--------|---------|
| Standards | 300-500 lines | 700 lines |
| Formats | 200-400 lines | 600 lines |
| Templates | 200-300 lines | 400 lines |
| Domain | 500-800 lines | 1000 lines |

**If exceeding maximum**: Split into focused files or create summary.

---

## Creating Context Files

### Step 1: Determine Category

- Core patterns → `core/{category}/`
- ModelChecker-specific → `project/modelchecker/`
- Domain knowledge → `project/{domain}/`

### Step 2: Create File

```markdown
# {Topic}

{Brief description of what this context provides.}

## Overview

{Detailed explanation}

## {Main Sections}

{Content organized by topic}

## Examples

{Practical examples}

## See Also

- [Related Context](path)
```

### Step 3: Update Index

Add entry to `.claude/context/index.md`:

```markdown
## {Category}

- [{filename}.md]({path}) - {Brief description}
```

---

## Troubleshooting

### Context Not Found

**Symptom**: Skill can't find context file

**Solution**:
1. Verify path in index.md
2. Check file exists at expected location
3. Use relative paths from .claude/

### Context Too Large

**Symptom**: Loading takes too long or exceeds limits

**Solution**:
1. Load only needed sections
2. Create summary file for large contexts
3. Split into focused files

### Stale Context

**Symptom**: Context doesn't match current code

**Solution**:
1. Review and update context file
2. Add "Last Updated" metadata
3. Link to source of truth (if applicable)

---

## ModelChecker-Specific Context

### Z3 Patterns

**File**: `project/modelchecker/z3-patterns.md`

Contains:
- Z3 constraint patterns
- Solver strategies
- Common idioms

### Theory Structure

**File**: `project/modelchecker/theories.md`

Contains:
- Theory component structure
- Standard files (semantic.py, operators.py)
- Testing patterns

### Architecture

**File**: `project/modelchecker/architecture.md`

Contains:
- System overview
- Package structure
- Key components

---

## Related Documentation

- [Context Index](../../context/README.md) - Full context listing
- [Skills Reference](../skills/README.md) - How skills use context
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - System architecture

---

[Back to Docs](../README.md) | [Context Index](../../context/README.md)
