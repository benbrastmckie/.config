# Workflows Reference

[Back to Docs](../README.md) | [Commands](../commands/README.md) | [Skills](../skills/README.md)

Workflows define how tasks progress through the development lifecycle, from creation to completion.

---

## Table of Contents

1. [Task Lifecycle](#task-lifecycle)
2. [Status Markers](#status-markers)
3. [Development Cycle](#development-cycle)
4. [Command Lifecycle](#command-lifecycle)
5. [Resume Pattern](#resume-pattern)
6. [Error Recovery](#error-recovery)
7. [State Synchronization](#state-synchronization)

---

## Task Lifecycle

### State Machine

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
             [NOT STARTED]                                    │
                    │                                         │
                    │ /research                               │
                    ▼                                         │
             [RESEARCHING]                                    │
                    │                                         │
                    │ complete                                │
                    ▼                                         │
             [RESEARCHED]                                     │
                    │                                         │
                    │ /plan                                   │
                    ▼                                         │
              [PLANNING]                                      │
                    │                                         │
                    │ complete                                │
                    ▼                                         │
               [PLANNED]                                      │
                    │                                         │
                    │ /implement                              │
                    ▼                                         │
            [IMPLEMENTING] ────────┐                          │
                    │              │                          │
                    │ complete    │ interrupted              │
                    ▼              ▼                          │
             [COMPLETED]      [PARTIAL] ──────────────────────┘
                    │              │
                    │              │ /implement (resumes)
                    ▼              └──────────────────────────►
               [ARCHIVED]

Exception states (from any state):
  ─► [BLOCKED] (with reason, can resume)
  ─► [ABANDONED] (moves to archive)
```

### State Descriptions

| State | Description | Next States |
|-------|-------------|-------------|
| `NOT STARTED` | Task created, no work done | RESEARCHING, PLANNING, BLOCKED, ABANDONED |
| `RESEARCHING` | Research in progress | RESEARCHED, BLOCKED |
| `RESEARCHED` | Research complete | PLANNING, BLOCKED, ABANDONED |
| `PLANNING` | Plan creation in progress | PLANNED, BLOCKED |
| `PLANNED` | Plan complete, ready for implementation | IMPLEMENTING, BLOCKED, ABANDONED |
| `IMPLEMENTING` | Implementation in progress | COMPLETED, PARTIAL, BLOCKED |
| `PARTIAL` | Implementation interrupted | IMPLEMENTING (resume), BLOCKED, ABANDONED |
| `COMPLETED` | Task finished successfully | ARCHIVED |
| `BLOCKED` | Cannot proceed (with reason) | Any previous state, ABANDONED |
| `ABANDONED` | Task cancelled | ARCHIVED |

---

## Status Markers

Status markers appear in TODO.md entries and plan phase headers.

### Task Status Markers

Used in TODO.md task entries:

| Marker | Meaning | In state.json |
|--------|---------|---------------|
| `[NOT STARTED]` | No work begun | `not_started` |
| `[RESEARCHING]` | Research in progress | `researching` |
| `[RESEARCHED]` | Research complete | `researched` |
| `[PLANNING]` | Plan in progress | `planning` |
| `[PLANNED]` | Plan complete | `planned` |
| `[IMPLEMENTING]` | Implementation in progress | `implementing` |
| `[COMPLETED]` | Task finished | `completed` |
| `[PARTIAL]` | Interrupted, resumable | `partial` |
| `[BLOCKED]` | Cannot proceed | `blocked` |
| `[ABANDONED]` | Task cancelled | `abandoned` |

### Phase Status Markers

Used in implementation plan phases:

| Marker | Meaning |
|--------|---------|
| `[NOT STARTED]` | Phase not begun |
| `[IN PROGRESS]` | Currently executing |
| `[COMPLETED]` | Phase finished |
| `[PARTIAL]` | Interrupted (enables resume) |
| `[BLOCKED]` | Cannot proceed |

---

## Development Cycle

### Typical Workflow

```bash
# 1. Create task
/task "Add new modal operator to logos theory"
# Creates task #350, status: [NOT STARTED]

# 2. Research (optional but recommended)
/research 350
# Status: [RESEARCHING] → [RESEARCHED]
# Creates: .claude/specs/350_add_modal_operator/reports/research-001.md

# 3. Plan
/plan 350
# Status: [RESEARCHED] → [PLANNING] → [PLANNED]
# Creates: .claude/specs/350_add_modal_operator/plans/implementation-001.md

# 4. Implement
/implement 350
# Status: [PLANNED] → [IMPLEMENTING] → [COMPLETED]
# Creates: .claude/specs/350_add_modal_operator/summaries/implementation-summary-{DATE}.md

# 5. Archive
/todo
# Moves completed tasks to archive
```

### Skip Research

For simple tasks, research can be skipped:

```bash
/task "Fix typo in documentation"
/plan 351                          # Direct to planning
/implement 351
```

### Revise Plan

When plan needs changes:

```bash
/implement 350                     # Hits problem
/revise 350                        # Creates implementation-002.md
/implement 350                     # Uses new plan
```

---

## Command Lifecycle

### Preflight → Execute → Postflight

Every command follows this pattern:

```
┌──────────────────────────────────────────┐
│            PREFLIGHT                      │
├──────────────────────────────────────────┤
│ 1. Parse and validate arguments           │
│ 2. Check task exists and status allows    │
│ 3. Update status to "in progress" variant │
│ 4. Log session start                      │
└──────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│            EXECUTE                        │
├──────────────────────────────────────────┤
│ 1. Route to appropriate skill by language │
│ 2. Execute steps/phases                   │
│ 3. Track progress                         │
│ 4. Handle errors gracefully               │
└──────────────────────────────────────────┘
                    │
                    ▼
┌──────────────────────────────────────────┐
│            POSTFLIGHT                     │
├──────────────────────────────────────────┤
│ 1. Update status to completed variant     │
│ 2. Create artifacts                       │
│ 3. Git commit changes                     │
│ 4. Return results                         │
└──────────────────────────────────────────┘
```

### Research Workflow

```
/research N [focus]
       │
       ▼
┌─────────────────┐
│ Validate task   │
│ exists, status  │
│ allows research │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update status   │
│ [RESEARCHING]   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Route by lang   │
│ python→Z3       │
│ other→general   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create report   │
│ research-NNN.md │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update status   │
│ [RESEARCHED]    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Git commit      │
└─────────────────┘
```

### Implementation Workflow

```
/implement N
       │
       ▼
┌─────────────────┐
│ Load plan,      │
│ find resume pt  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update status   │
│ [IMPLEMENTING]  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ For each phase: │
│ ┌─────────────┐ │
│ │ Mark IN     │ │
│ │ PROGRESS    │ │
│ ├─────────────┤ │
│ │ Execute     │ │
│ │ steps       │ │
│ ├─────────────┤ │
│ │ Mark        │ │
│ │ COMPLETED   │ │
│ ├─────────────┤ │
│ │ Git commit  │ │
│ │ phase       │ │
│ └─────────────┘ │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Create summary  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update status   │
│ [COMPLETED]     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Final commit    │
└─────────────────┘
```

---

## Resume Pattern

When implementation is interrupted, the system can resume:

### Detection

```
/implement N (resumed)
       │
       ▼
┌─────────────────┐
│ Load plan       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Scan phases:    │
│ [COMPLETED] → ✓ │ Skip
│ [PARTIAL] → ◀── │ Resume here
│ [NOT STARTED]   │ Execute
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Continue from   │
│ resume point    │
└─────────────────┘
```

### Phase Status Detection

The skill scans the plan file for phase status markers:

1. `[COMPLETED]` phases are skipped
2. First `[PARTIAL]` or `[IN PROGRESS]` phase is the resume point
3. Remaining `[NOT STARTED]` phases execute normally

### Automatic Resume

When you run `/implement N` again after interruption:
- Task status shows `[PARTIAL]` or `[IMPLEMENTING]`
- Skill loads plan and finds resume point
- Continues without user intervention

---

## Error Recovery

### Error Categories

| Type | Description | Recovery |
|------|-------------|----------|
| `tool_failure` | External tool failed | Retry or manual fix |
| `status_sync_failure` | TODO.md/state.json desync | Run `/task --sync` |
| `test_failure` | Tests failed | Fix code and retry |
| `import_error` | Python import failed | Fix imports and retry |
| `z3_timeout` | Z3 solver timed out | Simplify constraints |
| `git_commit_failure` | Git operation failed | Manual commit |

### Error Handling Pattern

```
On error during phase:
       │
       ▼
┌─────────────────┐
│ Keep phase      │
│ [IN PROGRESS]   │
│ or [PARTIAL]    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Log error       │
│ to errors.json  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Commit partial  │
│ progress        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Return partial  │
│ with resume     │
│ info            │
└─────────────────┘
```

### Non-Blocking Errors

These are logged but don't stop execution:
- Git commit failures
- Metric collection failures
- Non-critical logging failures

---

## State Synchronization

### Dual-File System

| File | Purpose | Format |
|------|---------|--------|
| `TODO.md` | User-facing task list | Markdown |
| `state.json` | Machine-readable state | JSON |

### Two-Phase Commit

Both files MUST stay synchronized:

```
1. Read both files
2. Prepare all updates in memory
3. Validate updates are consistent
4. Write state.json first (machine state)
5. Write TODO.md second (user-facing)
6. If either fails, rollback all
```

### Sync Command

When files get out of sync:

```bash
/task --sync
```

This command:
1. Compares TODO.md and state.json
2. Uses git blame to determine latest
3. Synchronizes to latest version
4. Logs resolution

### TODO.md Format

```markdown
### {N}. {Title}
- **Effort**: {estimate}
- **Status**: [PLANNED]
- **Priority**: {High|Medium|Low}
- **Language**: {python|general|meta}
- **Created**: {ISO_DATE}
- **Research**: [link]
- **Plan**: [link]

**Description**: {details}
```

### state.json Format

```json
{
  "next_project_number": 351,
  "active_projects": [
    {
      "project_number": 350,
      "project_name": "add_modal_operator",
      "status": "planned",
      "language": "python",
      "priority": "high",
      "created": "2026-01-09T10:00:00Z",
      "last_updated": "2026-01-09T12:00:00Z"
    }
  ]
}
```

---

## Related Documentation

- [Commands Reference](../commands/README.md) - Command details
- [Skills Reference](../skills/README.md) - Skill details
- [State Management Rule](../../rules/state-management.md) - State patterns
- [Workflows Rule](../../rules/workflows.md) - Command lifecycle
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - System architecture

---

[Back to Docs](../README.md) | [Commands](../commands/README.md) | [Skills](../skills/README.md)
