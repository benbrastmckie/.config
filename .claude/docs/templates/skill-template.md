# Skill Template

[Back to Templates](README.md) | [Skills Reference](../skills/README.md)

Use this template when creating new skills for the ModelChecker `.claude/` system.

---

## Template

Create directory `.claude/skills/skill-{name}/` and add `SKILL.md`:

```markdown
---
name: skill-{name}
description: {Brief description}. Invoke when {trigger condition}.
allowed-tools: {Tool1, Tool2, ...}
context: fork
---

# {Skill Name} Skill

{Brief description of what this skill does.}

## Trigger Conditions

This skill activates when:
- {Condition 1}
- {Condition 2}

## Responsibilities

1. **{Responsibility 1}**: {Description}
2. **{Responsibility 2}**: {Description}
3. **{Responsibility 3}**: {Description}

## Workflow

### Step 1: {Name}

{Description of what happens in this step}

### Step 2: {Name}

{Description of what happens in this step}

### Step 3: {Name}

{Description of what happens in this step}

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `task_number` | integer | Yes | Task to operate on |
| `{input}` | {type} | {Yes/No} | {Description} |

## Outputs

### Artifacts

| Artifact | Location | Format |
|----------|----------|--------|
| {Type} | `.claude/specs/{N}_{SLUG}/{path}` | Markdown |

### Return Format

\`\`\`json
{
  "status": "completed|partial|failed",
  "summary": "Brief description of work done",
  "artifacts": [
    {
      "type": "{artifact_type}",
      "path": ".claude/specs/{N}_{SLUG}/{path}",
      "summary": "Artifact description"
    }
  ],
  "metadata": {
    "session_id": "sess_{timestamp}",
    "duration_seconds": 123,
    "agent_type": "skill-{name}"
  },
  "errors": [],
  "next_steps": "Recommended next action"
}
\`\`\`

## Error Handling

| Error Type | Response |
|------------|----------|
| {Error 1} | {How to handle} |
| {Error 2} | {How to handle} |

## Integration

### Called By

- {Command or skill that invokes this}

### Calls

- {Skills this delegates to, if any}
```

---

## Field Reference

### Frontmatter Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Skill identifier | `skill-python-research` |
| `description` | Yes | Brief description with trigger | "Research Z3 patterns. Invoke for python research tasks." |
| `allowed-tools` | Yes | Tools the skill can use | `Read, Write, Bash(pytest)` |
| `context` | Yes | Context handling mode | `fork` |

### Common Tool Sets

| Skill Type | Typical Tools |
|------------|---------------|
| Research | `WebSearch, WebFetch, Read, Grep, Glob` |
| Planning | `Read, Write` |
| Implementation | `Read, Write, Edit, Bash(pytest), Bash(git:*)` |
| Status Sync | `Read, Write` |
| Git | `Bash(git:*)` |

---

## Example: skill-code-analyzer

```markdown
---
name: skill-code-analyzer
description: Analyze code quality and patterns. Invoke when code analysis needed.
allowed-tools: Read, Grep, Glob, Write
context: fork
---

# Code Analyzer Skill

Analyzes Python/Z3 code for quality issues, patterns, and improvement opportunities.

## Trigger Conditions

This skill activates when:
- `/analyze` command invoked on python task
- Code quality review needed
- Pattern discovery requested

## Responsibilities

1. **Pattern Analysis**: Identify common patterns in codebase
2. **Quality Check**: Find potential issues and anti-patterns
3. **Report Generation**: Create structured analysis report

## Workflow

### Step 1: Scope Discovery

1. Load task context from state.json
2. Determine analysis scope (full or focused)
3. Build file list for analysis

### Step 2: Pattern Analysis

1. Search for common patterns:
   - Z3 constraint patterns
   - Theory structure patterns
   - Test patterns
2. Identify deviations from standards
3. Note potential improvements

### Step 3: Quality Check

1. Check for common issues:
   - Missing type hints
   - Complex functions (high cyclomatic complexity)
   - Missing tests
   - Documentation gaps
2. Prioritize findings

### Step 4: Report Generation

1. Create analysis report at:
   `.claude/specs/{N}_{SLUG}/reports/analysis-{NNN}.md`
2. Structure findings by category
3. Include specific file:line references

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `task_number` | integer | Yes | Task context |
| `scope` | string | No | Limit to path (default: task scope) |

## Outputs

### Artifacts

| Artifact | Location | Format |
|----------|----------|--------|
| Analysis Report | `.claude/specs/{N}_{SLUG}/reports/analysis-{NNN}.md` | Markdown |

### Return Format

\`\`\`json
{
  "status": "completed",
  "summary": "Analyzed 45 files, found 12 issues (3 high, 5 medium, 4 low)",
  "artifacts": [
    {
      "type": "analysis_report",
      "path": ".claude/specs/350_task/reports/analysis-001.md",
      "summary": "Code quality analysis with 12 findings"
    }
  ],
  "metadata": {
    "session_id": "sess_20260109_abc123",
    "duration_seconds": 45,
    "agent_type": "skill-code-analyzer"
  },
  "errors": [],
  "next_steps": "Review high-priority findings and create fix tasks"
}
\`\`\`

## Error Handling

| Error Type | Response |
|------------|----------|
| No files found | Return partial with empty findings |
| Read permission denied | Skip file, note in report |
| Scope not found | Fall back to full codebase |

## Integration

### Called By

- `/analyze` command
- `/review` command (for code analysis portion)

### Calls

- None (leaf skill)
```

---

## ModelChecker-Specific Patterns

### Python/Z3 Research Skill

```yaml
---
name: skill-python-research
description: Research Z3 API and Python patterns. Invoke for python research tasks.
allowed-tools: WebSearch, WebFetch, Read, Grep, Glob
context: fork
---
```

**Research targets**:
- Z3 API patterns
- Solver strategies
- Existing codebase patterns
- Theory implementation approaches

### Theory Implementation Skill

```yaml
---
name: skill-theory-implementation
description: Implement semantic theories with TDD. Invoke for python implementation.
allowed-tools: Read, Write, Edit, Bash(pytest), Bash(python)
context: fork
---
```

**TDD workflow**:
1. Write failing test
2. Implement minimal code
3. Run tests
4. Refactor

**Testing command**:
```bash
PYTHONPATH=Code/src pytest Code/tests/ -v
```

---

## Validation Checklist

Before committing a new skill:

### Frontmatter
- [ ] `name` follows `skill-{name}` convention
- [ ] `description` includes trigger condition
- [ ] `allowed-tools` lists all needed tools
- [ ] `context` is set to `fork`

### Documentation
- [ ] Trigger conditions documented
- [ ] Responsibilities listed
- [ ] Workflow steps defined
- [ ] Inputs documented
- [ ] Outputs documented
- [ ] Return format shown
- [ ] Error handling documented
- [ ] Integration documented

### Implementation
- [ ] Returns structured JSON
- [ ] Handles errors gracefully
- [ ] Creates artifacts in correct locations
- [ ] Updates status via skill-status-sync
- [ ] Creates git commits via skill-git-workflow

### Testing
- [ ] Works with valid inputs
- [ ] Handles invalid inputs
- [ ] Creates expected artifacts
- [ ] Return format is correct

---

## Return Format Reference

All skills must return this structure:

```json
{
  "status": "completed|partial|failed|blocked",
  "summary": "Brief 2-5 sentence summary (<100 tokens)",
  "artifacts": [
    {
      "type": "research_report|implementation_plan|summary|...",
      "path": ".claude/specs/{N}_{SLUG}/...",
      "summary": "Brief artifact description"
    }
  ],
  "metadata": {
    "session_id": "sess_{timestamp}_{random}",
    "duration_seconds": 123,
    "agent_type": "skill-name",
    "delegation_depth": 1
  },
  "errors": [
    {
      "type": "error_type",
      "message": "Error description",
      "recoverable": true,
      "recommendation": "How to fix"
    }
  ],
  "next_steps": "Recommended next action for user"
}
```

### Status Values

| Status | When to Use |
|--------|-------------|
| `completed` | All work finished successfully |
| `partial` | Some work done, can resume |
| `failed` | Could not complete, error occurred |
| `blocked` | Cannot proceed, external dependency |

---

## Related Documentation

- [Creating Skills Guide](../guides/creating-skills.md)
- [Command Template](command-template.md)
- [Skills Reference](../skills/README.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

[Back to Templates](README.md) | [Skills Reference](../skills/README.md)
