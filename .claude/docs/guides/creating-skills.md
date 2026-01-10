# Creating Skills Guide

[Back to Docs](../README.md) | [Skill Template](../templates/skill-template.md)

How to create new skills for the ModelChecker `.claude/` agent system.

---

## Overview

Skills are specialized agents that execute specific types of work. They are invoked by commands or the orchestrator.

### Key Principles

1. **Skills execute, commands delegate**: Skills do the actual work
2. **Structured returns**: Always return JSON matching the standard format
3. **Resume support**: Handle interruptions gracefully
4. **Artifact creation**: Create outputs in task directories

---

## Step-by-Step Process

### Step 1: Plan the Skill

Before creating the skill, answer:

1. **What does this skill do?**
   - Single, focused purpose
   - Clear inputs and outputs

2. **When is it triggered?**
   - Which commands invoke it?
   - What language(s) route to it?

3. **What tools does it need?**
   - Read, Write, Edit?
   - Bash commands?
   - Web search?

4. **What artifacts does it create?**
   - Reports, plans, summaries?
   - Location in `.claude/specs/`?

### Step 2: Create Skill Directory

Create the skill directory and file:

```bash
mkdir -p .claude/skills/skill-{name}
```

Create `SKILL.md` in that directory.

### Step 3: Define Frontmatter

```yaml
---
name: skill-{name}
description: {Description}. Invoke when {trigger condition}.
allowed-tools: Read, Write, Edit, Bash(pytest)
context: fork
---
```

**Fields**:

| Field | Purpose | Example |
|-------|---------|---------|
| `name` | Skill identifier | `skill-python-research` |
| `description` | Description with trigger | "Research Z3 patterns. Invoke for python tasks." |
| `allowed-tools` | Available tools | `Read, Write, Bash(pytest)` |
| `context` | Context handling | `fork` |

### Step 4: Define Trigger Conditions

Document when the skill activates:

```markdown
## Trigger Conditions

This skill activates when:
- `/research` command on python language task
- Z3 API exploration needed
- Codebase pattern discovery requested
```

### Step 5: Define Responsibilities

List what the skill does:

```markdown
## Responsibilities

1. **Search**: Find relevant information
2. **Analyze**: Process and synthesize findings
3. **Report**: Create structured output
```

### Step 6: Define Workflow

Detail the execution steps:

```markdown
## Workflow

### Step 1: Context Loading

1. Read task from state.json
2. Load any existing research
3. Determine focus area

### Step 2: Research

1. Search web for Z3 patterns
2. Explore codebase for existing patterns
3. Collect findings

### Step 3: Report Generation

1. Create report structure
2. Write findings
3. Save to `.claude/specs/{N}_{SLUG}/reports/`
```

### Step 7: Define Return Format

All skills must return structured JSON:

```json
{
  "status": "completed",
  "summary": "Brief description of work done",
  "artifacts": [
    {
      "type": "research_report",
      "path": ".claude/specs/350_task/reports/research-001.md",
      "summary": "Research findings on Z3 patterns"
    }
  ],
  "metadata": {
    "session_id": "sess_20260109_abc123",
    "duration_seconds": 120,
    "agent_type": "skill-python-research"
  },
  "errors": [],
  "next_steps": "Create implementation plan with /plan 350"
}
```

### Step 8: Update Orchestrator Routing

If the skill should be auto-routed, update the orchestrator:

```markdown
## Language-Based Routing

| Language | Research Skill | Implementation Skill |
|----------|---------------|---------------------|
| python | skill-python-research | skill-theory-implementation |
| general | skill-researcher | skill-implementer |
| meta | skill-researcher | skill-implementer |
```

### Step 9: Test the Skill

Test through the command that invokes it:

```bash
# Create test task
/task "Test new skill"

# Invoke command that routes to skill
/research 350

# Verify artifacts
cat .claude/specs/350_test_new_skill/reports/research-001.md

# Verify status updated
grep "350" .claude/specs/TODO.md
```

---

## Skill Patterns

### Research Skill

```yaml
---
name: skill-{domain}-research
description: Research {domain} patterns. Invoke for {language} research tasks.
allowed-tools: WebSearch, WebFetch, Read, Grep, Glob
context: fork
---
```

**Workflow**:
1. Load task context
2. Search for information
3. Explore codebase
4. Create research report

**Output**: `reports/research-{NNN}.md`

### Implementation Skill

```yaml
---
name: skill-{domain}-implementation
description: Implement {domain} code. Invoke for {language} implementation.
allowed-tools: Read, Write, Edit, Bash(pytest), Bash(python)
context: fork
---
```

**Workflow**:
1. Load implementation plan
2. Detect resume point
3. Execute phases with TDD
4. Create implementation summary

**Output**: `summaries/implementation-summary-{DATE}.md`

### Planning Skill

```yaml
---
name: skill-planner
description: Create implementation plans. Invoke for /plan command.
allowed-tools: Read, Write
context: fork
---
```

**Workflow**:
1. Load research (if available)
2. Analyze task requirements
3. Create phased plan
4. Write plan file

**Output**: `plans/implementation-{NNN}.md`

### Utility Skill

```yaml
---
name: skill-{utility}
description: {Utility function}. Invoke when {condition}.
allowed-tools: Read, Write
context: fork
---
```

**Examples**:
- `skill-status-sync` - Update TODO.md and state.json
- `skill-git-workflow` - Create git commits

---

## ModelChecker-Specific Skills

### skill-python-research

For Python/Z3 research:

```yaml
allowed-tools: WebSearch, WebFetch, Read, Grep, Glob
```

**Focus areas**:
- Z3 API patterns
- Solver strategies
- Existing theory patterns
- Testing approaches

### skill-theory-implementation

For semantic theory implementation:

```yaml
allowed-tools: Read, Write, Edit, Bash(pytest), Bash(python)
```

**TDD workflow**:
```bash
# 1. Write failing test
PYTHONPATH=Code/src pytest Code/tests/test_new.py -v

# 2. Implement minimal code
# 3. Verify tests pass
# 4. Refactor
```

**Theory structure**:
```
theory_lib/{theory}/
├── semantic.py      # Core semantic framework
├── operators.py     # Operator registry
├── examples.py      # Test cases
└── tests/           # Unit tests
```

---

## Return Format Reference

### Status Values

| Status | When to Use |
|--------|-------------|
| `completed` | All work finished successfully |
| `partial` | Some work done, can resume |
| `failed` | Could not complete, error occurred |
| `blocked` | Cannot proceed, external dependency |

### Artifact Types

| Type | Description |
|------|-------------|
| `research_report` | Research findings |
| `implementation_plan` | Phased implementation plan |
| `implementation_summary` | Completion summary |
| `analysis_report` | Code analysis |
| `review_report` | Code review |

### Error Format

```json
{
  "errors": [
    {
      "type": "test_failure",
      "message": "3 tests failed in test_semantic.py",
      "recoverable": true,
      "recommendation": "Fix failing assertions"
    }
  ]
}
```

---

## Common Mistakes

### Mistake 1: No Return Format

**Wrong**: Just outputs text, no structured return

**Right**: Always return JSON matching the standard format

### Mistake 2: Missing Error Handling

**Wrong**: Crashes on error

**Right**: Catch errors, return with `status: "failed"` and error details

### Mistake 3: No Resume Support

**Wrong**: Starts from beginning on retry

**Right**: Detect partial progress and resume

### Mistake 4: Wrong Artifact Location

**Wrong**: Creates files in arbitrary locations

**Right**: Always use `.claude/specs/{N}_{SLUG}/` structure

---

## Validation Checklist

Before committing:

### Frontmatter
- [ ] `name` follows `skill-{name}` convention
- [ ] `description` includes trigger condition
- [ ] `allowed-tools` lists all needed tools
- [ ] `context` is set

### Documentation
- [ ] Trigger conditions documented
- [ ] Responsibilities listed
- [ ] Workflow steps defined
- [ ] Inputs documented
- [ ] Outputs documented
- [ ] Return format shown
- [ ] Error handling documented

### Implementation
- [ ] Returns structured JSON
- [ ] Handles errors gracefully
- [ ] Creates artifacts in correct locations
- [ ] Supports resume for long operations

### Testing
- [ ] Works with valid inputs
- [ ] Handles invalid inputs
- [ ] Creates expected artifacts
- [ ] Return format is correct
- [ ] Integrates with commands

---

## Example: Complete Skill

```markdown
---
name: skill-code-analyzer
description: Analyze code quality and patterns. Invoke for /analyze command.
allowed-tools: Read, Grep, Glob, Write
context: fork
---

# Code Analyzer Skill

Analyzes Python/Z3 code for quality issues and patterns.

## Trigger Conditions

This skill activates when:
- `/analyze` command invoked
- Code quality review needed

## Responsibilities

1. **Pattern Analysis**: Find common patterns in code
2. **Quality Check**: Identify issues and anti-patterns
3. **Report Generation**: Create structured findings

## Workflow

### Step 1: Scope Discovery

1. Load task from state.json
2. Determine analysis scope
3. Build file list

### Step 2: Analysis

1. Search for patterns:
   - Z3 constraint patterns
   - Theory structure patterns
   - Test patterns
2. Check for issues:
   - Missing type hints
   - Complex functions
   - Missing tests

### Step 3: Report Generation

1. Create report at `.claude/specs/{N}_{SLUG}/reports/analysis-001.md`
2. Structure by category
3. Include file:line references

## Inputs

| Input | Type | Required | Description |
|-------|------|----------|-------------|
| `task_number` | integer | Yes | Task context |
| `scope` | string | No | Limit to path |

## Outputs

### Artifacts

| Type | Location |
|------|----------|
| Analysis Report | `reports/analysis-{NNN}.md` |

### Return Format

\`\`\`json
{
  "status": "completed",
  "summary": "Analyzed 45 files, found 12 issues",
  "artifacts": [
    {
      "type": "analysis_report",
      "path": ".claude/specs/350_task/reports/analysis-001.md",
      "summary": "Code quality analysis"
    }
  ],
  "metadata": {
    "session_id": "sess_20260109_abc123",
    "duration_seconds": 45,
    "agent_type": "skill-code-analyzer"
  },
  "errors": [],
  "next_steps": "Review findings and create fix tasks"
}
\`\`\`

## Error Handling

| Error | Response |
|-------|----------|
| No files found | Return partial with empty findings |
| Permission denied | Skip file, note in report |

## Integration

### Called By
- `/analyze` command

### Calls
- None (leaf skill)
```

---

## Related Documentation

- [Skill Template](../templates/skill-template.md)
- [Creating Commands Guide](creating-commands.md)
- [Skills Reference](../skills/README.md)
- [Commands Reference](../commands/README.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

[Back to Docs](../README.md) | [Skill Template](../templates/skill-template.md)
