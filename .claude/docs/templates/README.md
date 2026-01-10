# Templates

[Back to Docs](../README.md) | [Commands](../commands/README.md) | [Skills](../skills/README.md)

Templates for creating new commands and skills in the ModelChecker `.claude/` agent system.

---

## Available Templates

| Template | Purpose | Use When |
|----------|---------|----------|
| [Command Template](command-template.md) | New slash commands | Adding user-facing commands |
| [Skill Template](skill-template.md) | New skills | Adding specialized agents |

---

## Command Template

**File**: [command-template.md](command-template.md)

Create new slash commands that users invoke with `/command` syntax.

### Quick Start

1. Copy template to `.claude/commands/{name}.md`
2. Replace placeholders with actual values
3. Define frontmatter (description, tools, arguments)
4. Document usage and workflow
5. Test with valid and invalid inputs

### Key Requirements

- Commands delegate to skills (don't execute directly)
- Keep under 300 lines
- Include usage examples
- Document all arguments

---

## Skill Template

**File**: [skill-template.md](skill-template.md)

Create new skills that execute specific types of work.

### Quick Start

1. Create directory `.claude/skills/skill-{name}/`
2. Copy template to `SKILL.md` in that directory
3. Replace placeholders with actual values
4. Define frontmatter (name, tools, context)
5. Implement workflow
6. Update orchestrator routing if needed

### Key Requirements

- Return structured JSON matching format
- Handle errors gracefully
- Support resume for long operations
- Create artifacts in task directories

---

## Frontmatter Standards

### Command Frontmatter

```yaml
---
description: Brief command description
allowed-tools: Read, Write, Edit, Bash(git:*)
argument-hint: TASK_NUMBER [focus]
model: claude-opus-4-5-20251101
---
```

### Skill Frontmatter

```yaml
---
name: skill-name
description: Brief skill description
allowed-tools: Read, Write, Edit, Bash(pytest)
context: fork
---
```

---

## ModelChecker-Specific Patterns

### Python/Z3 Skills

For skills working with Python/Z3 code:

**Tools**: `Read, Write, Edit, Bash(pytest), Bash(python)`

**Testing**:
```bash
PYTHONPATH=Code/src pytest Code/tests/ -v
```

**Theory Structure**:
```
theory_lib/{theory}/
├── semantic.py      # Core semantic framework
├── operators.py     # Operator registry
├── examples.py      # Test cases
├── iterate.py       # Theory-specific iteration
└── tests/           # Unit & integration tests
```

### Research Skills

For skills that conduct research:

**Tools**: `WebSearch, WebFetch, Read, Grep, Glob`

**Output**: `reports/research-{NNN}.md`

### Implementation Skills

For skills that implement code:

**Tools**: `Read, Write, Edit, Bash(pytest)`

**Output**: `summaries/implementation-summary-{DATE}.md`

---

## Validation Checklists

### Command Checklist

- [ ] Frontmatter includes all required fields
- [ ] Description is clear and concise
- [ ] Usage section with examples
- [ ] Workflow documented
- [ ] Arguments documented
- [ ] Under 300 lines
- [ ] Tested with valid inputs
- [ ] Tested with invalid inputs

### Skill Checklist

- [ ] Frontmatter includes all required fields
- [ ] Trigger conditions documented
- [ ] Workflow steps defined
- [ ] Return format matches standard
- [ ] Error handling implemented
- [ ] Artifacts created in correct locations
- [ ] Tested with valid inputs
- [ ] Tested with invalid inputs

---

## Related Documentation

- [Creating Commands Guide](../guides/creating-commands.md)
- [Creating Skills Guide](../guides/creating-skills.md)
- [Commands Reference](../commands/README.md)
- [Skills Reference](../skills/README.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

[Back to Docs](../README.md) | [Commands](../commands/README.md) | [Skills](../skills/README.md)
