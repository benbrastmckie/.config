---
paths: .claude/specs/**/*
---

# State Management Rules

## File Synchronization

TODO.md and state.json MUST stay synchronized. Any update to one requires updating the other.

### Canonical Sources
- **state.json**: Machine-readable source of truth
  - next_project_number
  - active_projects array with status, language, priority
  - Faster to query (12ms vs 100ms for TODO.md parsing)

- **TODO.md**: User-facing source of truth
  - Human-readable task list with descriptions
  - Status markers in brackets: [STATUS]
  - Grouped by priority (High/Medium/Low)

## Status Transitions

### Valid Transitions
```
[NOT STARTED] → [RESEARCHING] → [RESEARCHED]
[RESEARCHED] → [PLANNING] → [PLANNED]
[PLANNED] → [IMPLEMENTING] → [COMPLETED]

Any state → [BLOCKED] (with reason)
Any state → [ABANDONED] (moves to archive)
[IMPLEMENTING] → [PARTIAL] (on timeout/error)
```

### Invalid Transitions
- Cannot skip phases (e.g., NOT STARTED → PLANNED)
- Cannot regress (e.g., PLANNED → RESEARCHED) except for revisions
- Cannot mark COMPLETED without all phases done

## Two-Phase Update Pattern

When updating task status:

### Phase 1: Prepare
```
1. Read current state.json
2. Read current TODO.md
3. Validate task exists in both
4. Prepare updated content in memory
5. Validate updates are consistent
```

### Phase 2: Commit
```
1. Write state.json (machine state first)
2. Write TODO.md (user-facing second)
3. Verify both writes succeeded
4. If either fails: log error, preserve original state
```

## Task Entry Format

### TODO.md Entry
```markdown
### {NUMBER}. {TITLE}
- **Effort**: {estimate}
- **Status**: [{STATUS}]
- **Priority**: {High|Medium|Low}
- **Language**: {lean|general|meta|markdown}
- **Started**: {ISO timestamp}
- **Completed**: {ISO timestamp}
- **Research**: [link to report]
- **Plan**: [link to plan]

**Description**: {full description}
```

### state.json Entry
```json
{
  "project_number": 334,
  "project_name": "task_slug_here",
  "status": "planned",
  "language": "lean",
  "priority": "high",
  "effort": "4 hours",
  "created": "2026-01-08T10:00:00Z",
  "last_updated": "2026-01-08T14:30:00Z"
}
```

## Status Values Mapping

| TODO.md Marker | state.json status |
|----------------|-------------------|
| [NOT STARTED] | not_started |
| [RESEARCHING] | researching |
| [RESEARCHED] | researched |
| [PLANNING] | planning |
| [PLANNED] | planned |
| [IMPLEMENTING] | implementing |
| [COMPLETED] | completed |
| [BLOCKED] | blocked |
| [ABANDONED] | abandoned |
| [PARTIAL] | partial |

## Artifact Linking

When creating artifacts, update TODO.md with links:

### Research Completion
```markdown
- **Status**: [RESEARCHED]
- **Research**: [.claude/specs/{N}_{SLUG}/reports/research-001.md]
```

### Plan Completion
```markdown
- **Status**: [PLANNED]
- **Plan**: [.claude/specs/{N}_{SLUG}/plans/implementation-001.md]
```

### Implementation Completion
```markdown
- **Status**: [COMPLETED]
- **Completed**: 2026-01-08
- **Summary**: [.claude/specs/{N}_{SLUG}/summaries/implementation-summary-20260108.md]
```

## Directory Creation

Create task directories lazily (only when first artifact is created):
```
.claude/specs/{NUMBER}_{SLUG}/
├── reports/      # Created on first research
├── plans/        # Created on first plan
└── summaries/    # Created on completion
```

## Error Handling

### On Write Failure
1. Do not update either file partially
2. Log error with context
3. Preserve original state
4. Return error to caller

### On Inconsistency Detection
1. Log the inconsistency
2. Use git blame to determine latest
3. Sync to latest version
4. Create backup of overwritten version
