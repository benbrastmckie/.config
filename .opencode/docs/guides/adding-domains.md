# Adding New Domains Guide

[Back to Docs](../README.md) | [Copy .opencode/ Guide](copy-claude-directory.md)

Step-by-step guide for adding new domain contexts, agents, and skills to the .opencode/ system.

---

## Overview

The .opencode/ system is designed to be extended with new domains. A "domain" is a specialized area of knowledge (like Neovim, React, Rust, etc.) that benefits from:

1. **Domain Context Files**: Background knowledge and patterns
2. **Domain Agents**: Specialized research and implementation agents
3. **Domain Skills**: Thin wrappers that route to domain agents
4. **Domain Rules**: Auto-applied coding standards

---

## Architecture

```
Command (/research, /implement)
    │
    ▼
Orchestrator (skill-orchestrator)
    │
    ├── language: neovim → skill-neovim-research / skill-neovim-implementation
    ├── language: react  → skill-react-research  / skill-react-implementation
    └── language: rust   → skill-rust-research   / skill-rust-implementation
```

Each language type routes to specialized skills, which delegate to specialized agents.

---

## Step 1: Create Domain Context Directory

Create the context directory structure:

```bash
mkdir -p .opencode/context/project/your-domain/{domain,patterns,standards,tools,templates}
```

### Required Files

**README.md** - Overview and loading strategy:
```markdown
# Your Domain Context

Domain knowledge for [Your Domain] development.

## Directory Structure
- domain/ - Core concepts
- patterns/ - Common implementation patterns
- standards/ - Coding conventions
- tools/ - Tool-specific guides
- templates/ - Boilerplate templates

## Loading Strategy
- Always load README.md first
- Load domain/*.md for core concepts
- Load patterns/*.md for implementation work

## Agent Context Loading
| Task Type | Required Context |
|-----------|-----------------|
| Setup | domain/overview.md, patterns/setup.md |
| Feature | patterns/feature-pattern.md |
```

### Example Domain Files

**domain/overview.md** - Core concepts:
```markdown
# Your Domain Overview

## Key Concepts
- Concept 1: Description
- Concept 2: Description

## Architecture
[Describe the domain's typical architecture]

## Common Patterns
[List common patterns used in this domain]
```

**patterns/common-pattern.md** - Implementation patterns:
```markdown
# Common Pattern Name

## When to Use
[Describe when this pattern applies]

## Implementation
[Code examples and explanations]

## Variations
[Common variations of the pattern]
```

**standards/style-guide.md** - Coding conventions:
```markdown
# Style Guide

## Naming Conventions
- [Convention 1]
- [Convention 2]

## Code Organization
[How to organize code]

## Documentation
[Documentation requirements]
```

---

## Step 2: Create Domain Agents

Create research and implementation agents in `.opencode/agents/`:

### Research Agent Template

**your-domain-research-agent.md**:
```markdown
---
name: your-domain-research-agent
description: Research [Your Domain] tasks
---

# Your Domain Research Agent

## Overview

Research agent for [Your Domain] tasks. Invoked by `skill-your-domain-research`.

## Context References

Load these on-demand:
- `@.opencode/context/project/your-domain/README.md`
- `@.opencode/context/project/your-domain/domain/overview.md`

## Research Strategy

1. Check local codebase for existing patterns
2. Search for documentation and best practices
3. Identify implementation approach
4. Create research report

## Execution Flow

### Stage 0: Initialize Early Metadata
[Create metadata file before substantive work]

### Stage 1: Parse Delegation Context
[Extract task information]

### Stage 2: Determine Search Strategy
[Plan research approach]

### Stage 3: Execute Searches
[Perform codebase and web searches]

### Stage 4: Synthesize Findings
[Compile discoveries]

### Stage 5: Create Research Report
[Write report to specs/{NNN}_{SLUG}/reports/]

### Stage 6: Write Metadata File
[Write to .return-meta.json]

### Stage 7: Return Brief Summary
[Return 3-6 bullet point summary]
```

### Implementation Agent Template

**your-domain-implementation-agent.md**:
```markdown
---
name: your-domain-implementation-agent
description: Implement [Your Domain] tasks from plans
---

# Your Domain Implementation Agent

## Overview

Implementation agent for [Your Domain] tasks. Invoked by `skill-your-domain-implementation`.

## Context References

Load these on-demand:
- `@.opencode/context/project/your-domain/standards/style-guide.md`
- `@.opencode/context/project/your-domain/patterns/common-pattern.md`

## Verification Commands

[Domain-specific verification commands, e.g.:]
```bash
# Test command
your-tool --check
```

## Execution Flow

### Stage 0: Initialize Early Metadata
[Create metadata file]

### Stage 1: Parse Delegation Context
[Extract task and plan path]

### Stage 2: Load Implementation Plan
[Read and parse plan file]

### Stage 3: Find Resume Point
[Identify first incomplete phase]

### Stage 4: Execute Implementation Loop
[Execute each phase]

### Stage 5: Run Final Verification
[Verify all changes work]

### Stage 6: Create Implementation Summary
[Write summary to specs/{NNN}_{SLUG}/summaries/]

### Stage 7: Write Metadata File
[Write to .return-meta.json]

### Stage 8: Return Brief Summary
[Return 3-6 bullet point summary]
```

---

## Step 3: Create Domain Skills

Create skill wrappers in `.opencode/skills/`:

### Research Skill

**skill-your-domain-research/SKILL.md**:
```markdown
---
name: skill-your-domain-research
description: Conduct [Your Domain] research. Invoke for your-domain research tasks.
allowed-tools: Task, Bash, Edit, Read, Write
---

# Your Domain Research Skill

Thin wrapper that delegates to `your-domain-research-agent`.

## Execution Flow

1. Validate task exists and language matches
2. Update status to "researching"
3. Create postflight marker
4. Invoke your-domain-research-agent via Task tool
5. Read metadata file
6. Update status to "researched"
7. Link artifacts
8. Git commit
9. Cleanup and return summary
```

### Implementation Skill

**skill-your-domain-implementation/SKILL.md**:
```markdown
---
name: skill-your-domain-implementation
description: Implement [Your Domain] changes from plans. Invoke for your-domain implementation.
allowed-tools: Task, Bash, Edit, Read, Write
---

# Your Domain Implementation Skill

Thin wrapper that delegates to `your-domain-implementation-agent`.

## Execution Flow

1. Validate task exists and plan exists
2. Update status to "implementing"
3. Create postflight marker
4. Invoke your-domain-implementation-agent via Task tool
5. Read metadata file
6. Update status to "completed"
7. Link artifacts
8. Git commit
9. Cleanup and return summary
```

---

## Step 4: Create Domain Rule

Create a rule file in `.opencode/rules/`:

**your-domain.md**:
```markdown
# Your Domain Development Rules

## Path Pattern

Applies to: `your-path/**/*.ext`

## Coding Standards

### Naming Conventions
- [Convention 1]
- [Convention 2]

### Code Organization
[Organization rules]

### Error Handling
[Error handling patterns]

## Related Context

Load for detailed patterns:
- `@.opencode/context/project/your-domain/standards/style-guide.md`
```

---

## Step 5: Update Routing

### Update skill-orchestrator

Edit `.opencode/skills/skill-orchestrator/SKILL.md`:

```markdown
### 2. Language-Based Routing

| Language | Research Skill | Implementation Skill |
|----------|---------------|---------------------|
| neovim | skill-neovim-research | skill-neovim-implementation |
| your-domain | skill-your-domain-research | skill-your-domain-implementation |
| general | skill-researcher | skill-implementer |
```

### Update CLAUDE.md

Add to Language-Based Routing table:
```markdown
| `your-domain` | WebSearch, Read | Read, Write, Edit, Bash (your-tool) |
```

Add to Skill-to-Agent Mapping:
```markdown
| skill-your-domain-research | your-domain-research-agent | [Your Domain] research |
| skill-your-domain-implementation | your-domain-implementation-agent | [Your Domain] implementation |
```

Add to Rules References:
```markdown
- @.opencode/rules/your-domain.md - [Your Domain] development (your-path/**)
```

Add to Context Imports:
```markdown
- @.opencode/context/project/your-domain/domain/overview.md
```

---

## Step 6: Update Context Index

Edit `.opencode/context/index.md` to add your domain section:

```markdown
### Your Domain Context (project/your-domain/)

Load for: [Your Domain] implementation tasks (Language: your-domain)

**Overview**:
- **README.md** - Directory overview and loading strategy

**Domain**:
- **overview.md** - Core concepts

**Patterns**:
- **common-pattern.md** - Common implementation patterns

**Standards**:
- **style-guide.md** - Coding conventions

**Tools**:
- **tool-guide.md** - Tool usage

**When to Load**:
- Load README.md for overview
- Load style-guide.md for implementation
- Load patterns/*.md for specific patterns
```

---

## Verification Checklist

After adding a new domain:

- [ ] Context directory created with README.md
- [ ] Domain context files populated
- [ ] Research agent created
- [ ] Implementation agent created
- [ ] Research skill created
- [ ] Implementation skill created
- [ ] Rule file created
- [ ] Orchestrator routing updated
- [ ] CLAUDE.md updated
- [ ] Context index updated
- [ ] Test with `/task "Test" --language your-domain`
- [ ] Test `/research N`
- [ ] Test `/plan N`
- [ ] Test `/implement N`

---

## Example: Adding React Domain

```bash
# Create context structure
mkdir -p .opencode/context/project/react/{domain,patterns,standards,tools,templates}

# Create agents
touch .opencode/agents/react-research-agent.md
touch .opencode/agents/react-implementation-agent.md

# Create skills
mkdir -p .opencode/skills/skill-react-research
mkdir -p .opencode/skills/skill-react-implementation
touch .opencode/skills/skill-react-research/SKILL.md
touch .opencode/skills/skill-react-implementation/SKILL.md

# Create rule
touch .opencode/rules/react.md
```

Then populate each file following the templates above.

---

[Back to Docs](../README.md) | [Copy .opencode/ Guide](copy-claude-directory.md)
