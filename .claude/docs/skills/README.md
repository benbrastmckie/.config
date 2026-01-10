# Skills Reference

[Back to Docs](../README.md) | [Commands](../commands/README.md) | [Workflows](../workflows/README.md)

Skills are specialized agents that execute specific types of work. They are invoked by commands or the orchestrator based on task language and operation type.

---

## Skill Index

| Skill | Category | Purpose |
|-------|----------|---------|
| [skill-orchestrator](#skill-orchestrator) | Core | Central routing and coordination |
| [skill-status-sync](#skill-status-sync) | Core | Atomic multi-file status updates |
| [skill-git-workflow](#skill-git-workflow) | Core | Scoped git commits |
| [skill-researcher](#skill-researcher) | Research | General web and codebase research |
| [skill-python-research](#skill-python-research) | Research | Z3 API and pattern research |
| [skill-planner](#skill-planner) | Implementation | Create phased implementation plans |
| [skill-implementer](#skill-implementer) | Implementation | General implementation |
| [skill-theory-implementation](#skill-theory-implementation) | Implementation | TDD for semantic theories |

---

## Core Skills

### skill-orchestrator

Central routing intelligence for the task management system.

**Definition**: [.claude/skills/skill-orchestrator/SKILL.md](../../skills/skill-orchestrator/SKILL.md)

**Tools**: Read, Glob, Grep, Task

**Trigger Conditions**:
- Slash command needs language-based routing
- Task context needs to be gathered before delegation
- Multi-step workflows require coordination

**Responsibilities**:
1. **Task Lookup**: Retrieve task context from state.json
2. **Language-Based Routing**: Route to appropriate skill
3. **Status Validation**: Verify operation is allowed
4. **Context Preparation**: Package context for delegated skill

**Routing Table**:

| Language | Research Skill | Implementation Skill |
|----------|---------------|---------------------|
| `python` | skill-python-research | skill-theory-implementation |
| `general` | skill-researcher | skill-implementer |
| `meta` | skill-researcher | skill-implementer |

**Status Validation**:

| Operation | Allowed Statuses |
|-----------|------------------|
| research | not_started, planned, partial, blocked |
| plan | not_started, researched, partial |
| implement | planned, implementing, partial, researched |
| revise | planned, implementing, partial, blocked |

---

### skill-status-sync

Atomic multi-file status updates.

**Definition**: [.claude/skills/skill-status-sync/SKILL.md](../../skills/skill-status-sync/SKILL.md)

**Tools**: Read, Write

**Trigger Conditions**:
- Task status needs to change
- Multiple files need synchronized updates
- Called by other skills after operations complete

**Files Updated**:
- `.claude/specs/TODO.md` - Status marker in task entry
- `.claude/specs/state.json` - Status field in project entry
- Plan files - Phase status markers (if applicable)

**Two-Phase Commit Pattern**:
```
1. Read both files
2. Prepare updates in memory
3. Write state.json first (machine state)
4. Write TODO.md second (user-facing)
5. Rollback all on any failure
```

---

### skill-git-workflow

Scoped git commits for task operations.

**Definition**: [.claude/skills/skill-git-workflow/SKILL.md](../../skills/skill-git-workflow/SKILL.md)

**Tools**: Bash(git:*)

**Trigger Conditions**:
- Task operation completed successfully
- Artifacts created that need versioning
- Called by other skills after postflight

**Commit Message Format**:
```
task {N}: {action} {description}

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Standard Commit Actions**:

| Operation | Commit Message |
|-----------|----------------|
| Create task | `task {N}: create {title}` |
| Complete research | `task {N}: complete research` |
| Create plan | `task {N}: create implementation plan` |
| Complete phase | `task {N} phase {P}: {phase_name}` |
| Complete implementation | `task {N}: complete implementation` |
| Archive tasks | `todo: archive {N} completed tasks` |

**Safety Rules**:
- Never use `--force` or `--no-verify`
- Never commit to main/master without explicit request
- Failures are logged but don't block operations

---

## Research Skills

### skill-researcher

General web and codebase research.

**Definition**: [.claude/skills/skill-researcher/SKILL.md](../../skills/skill-researcher/SKILL.md)

**Tools**: WebSearch, WebFetch, Read, Grep, Glob

**Trigger Conditions**:
- `/research` on general or meta language tasks
- Non-Python research needed

**Responsibilities**:
1. Search web for relevant information
2. Explore codebase for patterns
3. Read documentation
4. Synthesize findings into research report

**Output**: `reports/research-{NNN}.md`

**Report Structure**:
```markdown
# Research Report: Task #{N}

**Task**: {title}
**Date**: {ISO_DATE}
**Focus**: {optional focus}

## Summary
## Findings
## Recommendations
## References
## Next Steps
```

---

### skill-python-research

Specialized Z3 API and Python pattern research.

**Definition**: [.claude/skills/skill-python-research/SKILL.md](../../skills/skill-python-research/SKILL.md)

**Tools**: WebSearch, WebFetch, Read, Grep, Glob

**Trigger Conditions**:
- `/research` on python language tasks
- Z3 API exploration needed
- Theory implementation pattern discovery

**Research Targets**:
- Z3 API patterns and solver strategies
- Existing codebase patterns in `theory_lib/`
- Theory implementation approaches
- Testing strategies for semantic theories

**Output**: `reports/research-{NNN}.md`

**ModelChecker-Specific Focus**:
- Z3 constraint patterns
- Semantic theory structures
- Model iteration patterns
- pytest integration

---

## Implementation Skills

### skill-planner

Create phased implementation plans from research.

**Definition**: [.claude/skills/skill-planner/SKILL.md](../../skills/skill-planner/SKILL.md)

**Tools**: Read, Write

**Trigger Conditions**:
- `/plan` command invoked
- Task needs implementation plan

**Responsibilities**:
1. Load research report (if available)
2. Analyze task requirements
3. Break into phases with steps
4. Define verification criteria
5. Write implementation plan

**Output**: `plans/implementation-{NNN}.md`

**Plan Structure**:
```markdown
# Implementation Plan: Task #{N}

**Task**: {title}
**Version**: {NNN}
**Created**: {ISO_DATE}
**Language**: {language}

## Overview

## Phases

### Phase 1: {Name}
**Status**: [NOT STARTED]

**Objectives**:
1. ...

**Steps**:
1. ...

**Verification**:
- [ ] ...

## Success Criteria
```

**Phase Status Markers**:
| Marker | Meaning |
|--------|---------|
| `[NOT STARTED]` | Phase not begun |
| `[IN PROGRESS]` | Currently executing |
| `[COMPLETED]` | Phase finished |
| `[PARTIAL]` | Interrupted (enables resume) |
| `[BLOCKED]` | Cannot proceed |

---

### skill-implementer

General implementation skill.

**Definition**: [.claude/skills/skill-implementer/SKILL.md](../../skills/skill-implementer/SKILL.md)

**Tools**: Read, Write, Edit, Bash

**Trigger Conditions**:
- `/implement` on general or meta language tasks
- Non-Python implementation needed

**Responsibilities**:
1. Load implementation plan
2. Detect resume point
3. Execute phases sequentially
4. Update phase status markers
5. Create implementation summary

**Output**: `summaries/implementation-summary-{DATE}.md`

---

### skill-theory-implementation

TDD workflow for semantic theories (Python/Z3).

**Definition**: [.claude/skills/skill-theory-implementation/SKILL.md](../../skills/skill-theory-implementation/SKILL.md)

**Tools**: Read, Write, Edit, Bash(pytest), Bash(python)

**Trigger Conditions**:
- `/implement` on python language tasks
- Semantic theory implementation
- Z3-based code changes

**TDD Workflow**:
```
1. Load implementation plan
2. For each phase:
   a. Write failing test first
   b. Implement minimal code to pass
   c. Run tests to verify
   d. Refactor while tests pass
   e. Mark phase complete
   f. Git commit
3. Run full test suite
4. Create implementation summary
```

**Testing Commands**:
```bash
# Run all tests
PYTHONPATH=Code/src pytest Code/tests/ -v

# Run theory-specific tests
PYTHONPATH=Code/src pytest Code/src/model_checker/theory_lib/logos/tests/ -v

# Run with coverage
pytest --cov=model_checker --cov-report=term-missing
```

**Output**: `summaries/implementation-summary-{DATE}.md`

**ModelChecker-Specific Patterns**:
- Theory structure: semantic.py, operators.py, examples.py
- Z3 constraint patterns
- Model iteration integration
- pytest fixtures for theories

---

## Skill Structure

### Frontmatter

All skills have YAML frontmatter defining their behavior:

```yaml
---
name: skill-name
description: Brief skill description
allowed-tools: Read, Write, Edit, Bash(pytest)
context: fork
---
```

### Common Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `name` | Skill identifier | `skill-python-research` |
| `description` | Brief description | "Z3 API research" |
| `allowed-tools` | Tools the skill can use | `Read, Write, Bash(pytest)` |
| `context` | Context handling | `fork` |

---

## Return Format

All skills return structured JSON:

```json
{
  "status": "completed|partial|failed|blocked",
  "summary": "Brief 2-5 sentence summary",
  "artifacts": [
    {
      "type": "research_report|implementation_plan|summary",
      "path": ".claude/specs/{N}_{SLUG}/...",
      "summary": "Artifact description"
    }
  ],
  "metadata": {
    "session_id": "sess_{timestamp}_{random}",
    "duration_seconds": 123,
    "agent_type": "skill-name",
    "delegation_depth": 1
  },
  "errors": [],
  "next_steps": "Recommended next action"
}
```

---

## Creating New Skills

See [guides/creating-skills.md](../guides/creating-skills.md) for detailed instructions.

**Quick checklist**:
1. Create `.claude/skills/skill-{name}/SKILL.md`
2. Add frontmatter with `name`, `description`, `allowed-tools`
3. Define trigger conditions
4. Implement workflow
5. Ensure proper return format
6. Update orchestrator routing if needed
7. Update this documentation

---

## Related Documentation

- [Commands Reference](../commands/README.md) - Commands that invoke skills
- [Workflows](../workflows/README.md) - Task lifecycle and state transitions
- [Skill Template](../templates/skill-template.md) - Template for new skills
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - System architecture

---

[Back to Docs](../README.md) | [Commands](../commands/README.md) | [Workflows](../workflows/README.md)
