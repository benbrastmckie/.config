# Skills Authoring Standards

[Used by: all commands, all agents, skill developers]

## Purpose

This document defines formal standards and compliance requirements for creating skills in the `.claude/skills/` directory. Skills are model-invoked capabilities that Claude automatically uses when relevant needs are detected.

For detailed guides, examples, and troubleshooting, see [Skills README](../../../skills/README.md).

## Table of Contents

1. [SKILL.md Structure Requirements](#skillmd-structure-requirements)
2. [YAML Frontmatter Standards](#yaml-frontmatter-standards)
3. [Size Constraints](#size-constraints)
4. [Tool Restrictions](#tool-restrictions)
5. [Model Selection](#model-selection)
6. [Description Discoverability](#description-discoverability)
7. [Integration Standards](#integration-standards)
8. [Validation Commands](#validation-commands)
9. [Compliance Checklist](#compliance-checklist)
10. [References](#references)

---

## SKILL.md Structure Requirements

Every skill MUST have a `SKILL.md` file at `.claude/skills/<skill-name>/SKILL.md` with the following structure:

```
---
[YAML frontmatter metadata]
---

# Skill Name

[Core instructions section]
```

### Required Components

| Component | Requirement | Purpose |
|-----------|-------------|---------|
| YAML frontmatter | MUST be present | Metadata for discovery and configuration |
| Core instructions | MUST be present | Execution guidance for Claude |
| Size limit | MUST be < 500 lines | Token efficiency via progressive disclosure |

### Optional Files

| File | Purpose |
|------|---------|
| `reference.md` | Detailed technical documentation, API specs |
| `examples.md` | Usage examples and integration patterns |
| `scripts/` | Helper scripts (symlink to lib/ for zero duplication) |
| `templates/` | Workflow templates for batch processing |

---

## YAML Frontmatter Standards

### Required Fields

```yaml
---
name: skill-name
description: Short description (max 200 chars, include trigger keywords)
allowed-tools: Bash, Read, Glob, Write
---
```

| Field | Requirement | Validation |
|-------|-------------|------------|
| `name` | MUST match directory name | `name` == `<skill-name>` in path |
| `description` | MUST be <= 200 characters | Character count validation |
| `description` | MUST include trigger keywords | Keywords that Claude recognizes |
| `allowed-tools` | MUST list permitted tools | Comma-separated tool names |

### Optional Fields

```yaml
dependencies:
  - tool>=version
model: haiku-4.5
model-justification: Brief explanation of model choice
fallback-model: sonnet-4.5
```

| Field | Purpose | Default |
|-------|---------|---------|
| `dependencies` | External tool requirements | None |
| `model` | Preferred model for skill execution | Claude's default |
| `model-justification` | Why this model is appropriate | None |
| `fallback-model` | Backup model if primary unavailable | None |

### YAML Syntax Requirements

- Use spaces for indentation (NOT tabs)
- Quote strings with special characters
- Include closing `---` delimiter
- Use lowercase field names

---

## Size Constraints

### Hard Limits

| Metric | Limit | Rationale |
|--------|-------|-----------|
| SKILL.md total lines | < 500 lines | Progressive disclosure efficiency |
| Description length | <= 200 characters | Metadata scanning optimization |
| Core instructions | Focus on essentials | Token budget conservation |

### Progressive Disclosure Pattern

```
                    +-------------------+
                    |  Skill Metadata   |  <-- Always scanned
                    |  (YAML frontmatter)|
                    +-------------------+
                           |
                    Relevant need detected?
                           |
                    +------+------+
                    |             |
                   No            Yes
                    |             |
              Skip skill    Load SKILL.md
                    |             |
                    |      +------+------+
                    |      |             |
                    |  Simple task   Complex task
                    |      |             |
                    |  Core only    Load reference.md
                    +------+------+------+
```

---

## Tool Restrictions

### Security Policy

Skills MUST explicitly declare allowed tools via the `allowed-tools` field. This restricts what operations the skill can perform.

### Standard Tool Sets

**Minimal (Read-only)**:
```yaml
allowed-tools: Read, Glob, Grep
```

**Standard (File operations)**:
```yaml
allowed-tools: Bash, Read, Glob, Write
```

**Extended (Web access)**:
```yaml
allowed-tools: Bash, Read, Glob, Write, WebFetch
```

### Prohibited Patterns

| Pattern | Issue | Alternative |
|---------|-------|-------------|
| No `allowed-tools` field | Unlimited access | Always declare tools |
| `allowed-tools: all` | Security risk | List specific tools |
| Unnecessary tools | Attack surface | Minimal required set |

---

## Model Selection

### When to Specify Model

Specify `model` when the skill requires:
- Specific capabilities (vision, code execution)
- Cost optimization (use haiku for simple tasks)
- Performance tuning (use sonnet for complex reasoning)

### Model Selection Matrix

| Task Complexity | Recommended Model | Use Case |
|-----------------|-------------------|----------|
| Simple extraction | haiku-4.5 | Text parsing, format conversion |
| Standard operations | Default (unspecified) | General purpose |
| Complex reasoning | sonnet-4.5 | Research, analysis, planning |

### Fallback Policy

Always specify `fallback-model` when specifying `model`:

```yaml
model: haiku-4.5
model-justification: Simple format conversion, no complex reasoning needed
fallback-model: sonnet-4.5
```

---

## Description Discoverability

### Trigger Keywords

The `description` field MUST include keywords Claude uses to recognize when the skill is relevant.

**Good Example**:
```yaml
description: Convert between Markdown, DOCX, and PDF formats bidirectionally. Handles text extraction from PDF/DOCX, markdown to document conversion.
```

Keywords: `convert`, `Markdown`, `DOCX`, `PDF`, `text extraction`, `document conversion`

**Bad Example**:
```yaml
description: A utility for file processing
```

Issue: Too generic, no specific trigger keywords.

### Testing Discoverability

Test skill discovery with these prompts:
1. Task that should trigger skill (e.g., "Convert this PDF to markdown")
2. Related task (e.g., "Extract text from document")
3. Negative test (e.g., unrelated task should NOT trigger)

---

## Integration Standards

### Command Delegation Pattern

Commands delegate to agents that load skills. This is the **preferred** pattern for skill integration:

```markdown
# Command invokes agent via Task tool
# Agent has skills: field in frontmatter
# Agent automatically receives skill context
```

**Example** (convert-docs):
```yaml
# .claude/agents/doc-converter.md
---
skills: document-converter
---
```

```markdown
# .claude/commands/convert-docs.md (STEP 4)
Task {
  subagent_type: "general-purpose"
  prompt: "Read and follow: .claude/agents/doc-converter.md ..."
}
```

Commands do NOT load skills directly. Skill context is loaded by agents via the `skills:` frontmatter field.

### Agent Auto-Loading Pattern

Agents can auto-load skills via the `skills:` frontmatter field:

```yaml
# .claude/agents/my-agent.md
---
skills: skill-name
---
```

Requirements:
- Skill name MUST match directory name exactly
- Skill MUST exist at `.claude/skills/<skill-name>/`
- Agent receives skill context automatically

### Skill Composition Pattern

Skills can declare dependencies on other skills:

```yaml
# .claude/skills/research-specialist/SKILL.md
---
dependencies:
  - document-converter  # Auto-loads for PDF analysis
---
```

---

## Validation Commands

### YAML Syntax Validation

```bash
# Validate YAML frontmatter
python3 -c "import yaml; yaml.safe_load(open('.claude/skills/<skill-name>/SKILL.md').read().split('---')[1])"
```

### Size Validation

```bash
# Check line count (must be < 500)
LINES=$(wc -l < .claude/skills/<skill-name>/SKILL.md)
if [ "$LINES" -ge 500 ]; then
  echo "ERROR: SKILL.md exceeds 500 lines ($LINES)"
  exit 1
fi
echo "Size OK: $LINES lines"
```

### Structure Validation

```bash
# Verify required files exist
test -f .claude/skills/<skill-name>/SKILL.md || echo "ERROR: Missing SKILL.md"

# Verify frontmatter present
head -1 .claude/skills/<skill-name>/SKILL.md | grep -q "^---$" || echo "ERROR: Missing frontmatter"

# Verify name field matches directory
NAME=$(grep "^name:" .claude/skills/<skill-name>/SKILL.md | awk '{print $2}')
DIR_NAME=$(basename .claude/skills/<skill-name>)
if [ "$NAME" != "$DIR_NAME" ]; then
  echo "ERROR: name field ($NAME) doesn't match directory ($DIR_NAME)"
fi
```

### Description Validation

```bash
# Check description length (must be <= 200 chars)
DESC=$(grep "^description:" .claude/skills/<skill-name>/SKILL.md | cut -d: -f2-)
LEN=${#DESC}
if [ "$LEN" -gt 200 ]; then
  echo "ERROR: Description exceeds 200 characters ($LEN)"
  exit 1
fi
echo "Description length OK: $LEN characters"
```

---

## Compliance Checklist

Before committing a new skill, verify:

### Structure

- [ ] Skill directory exists at `.claude/skills/<skill-name>/`
- [ ] SKILL.md file exists with YAML frontmatter
- [ ] SKILL.md is under 500 lines
- [ ] Optional reference.md/examples.md for detailed docs

### Frontmatter

- [ ] `name` field matches directory name
- [ ] `description` field is <= 200 characters
- [ ] `description` includes trigger keywords
- [ ] `allowed-tools` field lists permitted tools
- [ ] `model` has corresponding `fallback-model` (if specified)

### Integration

- [ ] Commands delegate to agents that load skills (via Task tool)
- [ ] Agents using skill have correct `skills:` field in frontmatter
- [ ] Cross-references validated (no broken links)

### Documentation

- [ ] Skill listed in skills/README.md
- [ ] Skill guide created (if complex)
- [ ] No emojis in documentation
- [ ] CommonMark compliance

---

## References

### Project Documentation

- [Skills README](../../../skills/README.md) - Complete skills guide with creating skills, best practices, migration, troubleshooting
- [Document Converter Skill Guide](../../guides/skills/document-converter-skill-guide.md) - Example skill implementation
- [Directory Organization](../../concepts/directory-organization.md) - File placement standards
- [Code Standards](code-standards.md) - General coding conventions
- [Command Authoring](command-authoring.md) - Command development standards

### Skills Architecture

- [Skills vs Commands vs Agents](../../../skills/README.md#skills-vs-commands-vs-agents) - Architecture comparison table
- [Creating New Skills](../../../skills/README.md#creating-new-skills) - Step-by-step guide
- [Migration from Commands](../../../skills/README.md#migration-from-commands) - Migration template

---

**Last Updated**: 2025-11-21
**Spec Reference**: 882_skills_documentation_standards_update
