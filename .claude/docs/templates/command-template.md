# Command Template

[Back to Templates](README.md) | [Commands Reference](../commands/README.md)

Use this template when creating new slash commands for the ModelChecker `.claude/` system.

---

## Template

Copy this template to `.claude/commands/{command-name}.md`:

```markdown
---
description: {Brief description of what this command does}
allowed-tools: {Comma-separated list: Read, Write, Edit, Bash(git:*)}
argument-hint: {REQUIRED_ARG [optional_arg]}
model: claude-opus-4-5-20251101
---

# /{command-name} Command

{Brief description of what this command does and when to use it.}

## Usage

\`\`\`bash
/{command-name} REQUIRED_ARG              # Basic usage
/{command-name} REQUIRED_ARG "optional"   # With optional arg
\`\`\`

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `REQUIRED_ARG` | Yes | {Description} |
| `optional_arg` | No | {Description} (default: {value}) |

## What This Does

1. {Step 1 - e.g., Validates arguments}
2. {Step 2 - e.g., Updates status}
3. {Step 3 - e.g., Routes to skill}
4. {Step 4 - e.g., Creates artifacts}
5. {Step 5 - e.g., Creates git commit}

## Language-Based Routing

| Language | Skill |
|----------|-------|
| `python` | {skill for python tasks} |
| `general` | {skill for general tasks} |
| `meta` | {skill for meta tasks} |

## Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| {Type} | `.claude/specs/{N}_{SLUG}/{path}` | {Description} |

## Status Transitions

| From | To |
|------|-----|
| `{starting_status}` | `{in_progress_status}` |
| `{in_progress_status}` | `{completed_status}` |

## Prerequisites

- {Prerequisite 1}
- {Prerequisite 2}

## Examples

### Example 1: {Description}

\`\`\`bash
/{command-name} 350
\`\`\`

Result: {Expected outcome}

### Example 2: {Description}

\`\`\`bash
/{command-name} 350 "focus area"
\`\`\`

Result: {Expected outcome}

## Related Commands

| Command | Relationship |
|---------|-------------|
| `/{related}` | {How they relate} |

## See Also

- [Skill Definition](../../skills/{skill-name}/SKILL.md)
- [Commands Reference](../../docs/commands/README.md)
- [Workflows](../../docs/workflows/README.md)
```

---

## Field Reference

### Frontmatter Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `description` | Yes | Brief description for help | "Conduct research on a task" |
| `allowed-tools` | Yes | Tools the command can use | `Read, Write, Bash(git:*)` |
| `argument-hint` | Yes | Argument syntax | `TASK_NUMBER [focus]` |
| `model` | No | Model to use | `claude-opus-4-5-20251101` |

### Common Tool Sets

| Command Type | Typical Tools |
|--------------|---------------|
| Read-only | `Read, Grep, Glob` |
| Research | `Read, Grep, Glob, WebSearch, WebFetch` |
| Modification | `Read, Write, Edit, Bash(git:*)` |
| Implementation | `Read, Write, Edit, Bash(pytest), Bash(git:*)` |

---

## Example: /analyze Command

```markdown
---
description: Analyze code patterns and quality
allowed-tools: Read, Grep, Glob, Write
argument-hint: TASK_NUMBER [scope]
model: claude-opus-4-5-20251101
---

# /analyze Command

Analyze code patterns and quality for a task, identifying issues and improvement opportunities.

## Usage

\`\`\`bash
/analyze 350                    # Analyze task scope
/analyze 350 "theory_lib"       # Analyze specific area
\`\`\`

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `TASK_NUMBER` | Yes | Task to analyze for |
| `scope` | No | Limit analysis to area (default: full codebase) |

## What This Does

1. Validates task exists
2. Determines analysis scope from task or argument
3. Routes to skill-analyzer
4. Scans code for patterns
5. Creates analysis report

## Language-Based Routing

| Language | Skill |
|----------|-------|
| `python` | skill-python-analyzer |
| `general` | skill-analyzer |

## Artifacts

| Artifact | Location | Description |
|----------|----------|-------------|
| Analysis Report | `.claude/specs/{N}_{SLUG}/reports/analysis-001.md` | Quality findings |

## Status Transitions

| From | To |
|------|-----|
| Any | (no status change) |

## Prerequisites

- Task must exist in TODO.md/state.json

## Examples

### Example 1: Full Analysis

\`\`\`bash
/analyze 350
\`\`\`

Result: Creates analysis report covering task scope

### Example 2: Focused Analysis

\`\`\`bash
/analyze 350 "model_checker/theory_lib/logos"
\`\`\`

Result: Creates analysis report for logos theory only

## Related Commands

| Command | Relationship |
|---------|-------------|
| `/review` | Similar but broader scope |
| `/research` | Precedes analysis for context |

## See Also

- [Skills Reference](../../docs/skills/README.md)
- [Commands Reference](../../docs/commands/README.md)
```

---

## Validation Checklist

Before committing a new command:

### Frontmatter
- [ ] `description` is clear and concise
- [ ] `allowed-tools` lists all needed tools
- [ ] `argument-hint` shows proper syntax
- [ ] Model specified if non-default

### Documentation
- [ ] Purpose clearly stated
- [ ] Usage with examples
- [ ] All arguments documented
- [ ] Workflow steps listed
- [ ] Artifacts documented
- [ ] Status transitions shown
- [ ] Prerequisites listed
- [ ] Related commands linked

### Quality
- [ ] Under 300 lines
- [ ] No embedded execution logic
- [ ] Delegates to skill(s)
- [ ] Consistent formatting

### Testing
- [ ] Works with valid arguments
- [ ] Handles invalid arguments gracefully
- [ ] Creates expected artifacts
- [ ] Status updates correctly
- [ ] Git commits created

---

## Common Patterns

### Task-Based Command

Most commands operate on tasks:

```yaml
argument-hint: TASK_NUMBER [options]
```

Workflow:
1. Parse task number from arguments
2. Validate task exists in state.json
3. Check status allows operation
4. Route to appropriate skill
5. Update status and commit

### Flag-Based Command

Some commands use flags:

```yaml
argument-hint: --flag [value]
```

Examples: `/task --sync`, `/task --abandon 123`

### No-Argument Command

Simple operations:

```yaml
argument-hint: (no arguments)
```

Examples: `/todo`, `/errors`

---

## Related Documentation

- [Creating Commands Guide](../guides/creating-commands.md)
- [Skill Template](skill-template.md)
- [Commands Reference](../commands/README.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

[Back to Templates](README.md) | [Commands Reference](../commands/README.md)
