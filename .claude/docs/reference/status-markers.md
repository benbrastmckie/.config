# Status Markers Reference

[Back to Docs](../README.md) | [Workflows](../workflows/README.md)

Complete reference for status markers used in the ModelChecker `.claude/` agent system.

---

## Task Status Markers

Used in TODO.md task entries and state.json.

### Active States

| Marker | state.json | Description |
|--------|------------|-------------|
| `[NOT STARTED]` | `not_started` | Task created, no work done |
| `[RESEARCHING]` | `researching` | Research in progress |
| `[RESEARCHED]` | `researched` | Research complete |
| `[PLANNING]` | `planning` | Plan creation in progress |
| `[PLANNED]` | `planned` | Plan complete, ready for implementation |
| `[IMPLEMENTING]` | `implementing` | Implementation in progress |
| `[COMPLETED]` | `completed` | Task finished successfully |

### Exception States

| Marker | state.json | Description |
|--------|------------|-------------|
| `[PARTIAL]` | `partial` | Interrupted, can resume |
| `[BLOCKED]` | `blocked` | Cannot proceed (needs reason) |
| `[ABANDONED]` | `abandoned` | Task cancelled |

---

## State Machine

```
[NOT STARTED]
      │
      │ /research
      ▼
[RESEARCHING]
      │
      │ complete
      ▼
[RESEARCHED]
      │
      │ /plan
      ▼
[PLANNING]
      │
      │ complete
      ▼
[PLANNED]
      │
      │ /implement
      ▼
[IMPLEMENTING] ──────► [PARTIAL]
      │                     │
      │ complete           │ /implement
      ▼                     │ (resumes)
[COMPLETED]  ◄──────────────┘

From any state:
  ──► [BLOCKED]   (with reason)
  ──► [ABANDONED] (moves to archive)
```

---

## Allowed Transitions

### By Command

| Command | From States | To States |
|---------|-------------|-----------|
| /research | NOT STARTED, PLANNED, PARTIAL, BLOCKED | RESEARCHING → RESEARCHED |
| /plan | NOT STARTED, RESEARCHED, PARTIAL | PLANNING → PLANNED |
| /implement | PLANNED, IMPLEMENTING, PARTIAL, RESEARCHED | IMPLEMENTING → COMPLETED or PARTIAL |
| /revise | PLANNED, IMPLEMENTING, PARTIAL, BLOCKED | PLANNED |
| /todo | COMPLETED, ABANDONED | (archived) |

### Special Transitions

| Transition | Trigger |
|------------|---------|
| Any → BLOCKED | Manual or error with blocking issue |
| Any → ABANDONED | `/task --abandon N` |
| IMPLEMENTING → PARTIAL | Interruption or timeout |
| PARTIAL → IMPLEMENTING | `/implement N` (auto-resume) |

---

## Phase Status Markers

Used in implementation plan phase headers.

| Marker | Description |
|--------|-------------|
| `[NOT STARTED]` | Phase not begun |
| `[IN PROGRESS]` | Currently executing |
| `[COMPLETED]` | Phase finished successfully |
| `[PARTIAL]` | Interrupted (enables resume) |
| `[BLOCKED]` | Cannot proceed |

### Phase Status in Plans

```markdown
### Phase 1: Setup
**Status**: [COMPLETED]
...

### Phase 2: Implementation
**Status**: [IN PROGRESS]
...

### Phase 3: Testing
**Status**: [NOT STARTED]
...
```

---

## Resume Detection

When `/implement N` is invoked:

1. Load implementation plan
2. Scan phases for status markers
3. `[COMPLETED]` → Skip
4. `[PARTIAL]` or `[IN PROGRESS]` → Resume here
5. `[NOT STARTED]` → Execute normally

### Example

```markdown
### Phase 1: Setup
**Status**: [COMPLETED]
→ Skip

### Phase 2: Core Implementation
**Status**: [PARTIAL]
→ Resume from here

### Phase 3: Testing
**Status**: [NOT STARTED]
→ Execute after Phase 2
```

---

## TODO.md Format

### Task Entry

```markdown
### {N}. {Title}
- **Effort**: {estimate}
- **Status**: [PLANNED]
- **Priority**: {High|Medium|Low}
- **Language**: {python|general|meta}
- **Created**: {ISO_DATE}
- **Research**: [research-001.md](path)
- **Plan**: [implementation-001.md](path)

**Description**: {details}
```

### Status Update

When status changes:
1. Find task entry in TODO.md
2. Update `- **Status**: [NEW_STATUS]`
3. Also update state.json `status` field

---

## state.json Format

### Project Entry

```json
{
  "project_number": 350,
  "project_name": "add_modal_operator",
  "status": "planned",
  "language": "python",
  "priority": "high",
  "created": "2026-01-09T10:00:00Z",
  "last_updated": "2026-01-09T12:00:00Z"
}
```

### Status Values

Use lowercase in state.json:
- `not_started`
- `researching`
- `researched`
- `planning`
- `planned`
- `implementing`
- `completed`
- `partial`
- `blocked`
- `abandoned`

---

## Synchronization

TODO.md and state.json must stay synchronized.

### Two-Phase Update

```
1. Read both files
2. Prepare updates in memory
3. Write state.json first
4. Write TODO.md second
5. Rollback all on failure
```

### Sync Command

If files get out of sync:

```bash
/task --sync
```

---

## Error Handling

### On Operation Failure

| Scenario | Action |
|----------|--------|
| Test failure | Keep [IMPLEMENTING], log error |
| Timeout | Mark phase [PARTIAL], commit progress |
| Tool failure | Log error, continue if possible |
| Git failure | Log error, don't block |

### On Status Mismatch

1. Use git blame to find latest
2. Sync to latest version
3. Log resolution

---

## Related Documentation

- [Workflows Reference](../workflows/README.md) - Task lifecycle
- [State Management Rule](../../rules/state-management.md) - State patterns
- [Error Handling Rule](../../rules/error-handling.md) - Error recovery

---

[Back to Docs](../README.md) | [Workflows](../workflows/README.md)
