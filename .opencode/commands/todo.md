---
description: Maintain TODO.md and sync repository state
allowed-tools: Read(specs/*), Edit(specs/TODO.md), Bash(jq:*), Bash(git:*), Bash(mv:*), Bash(date:*), Bash(sed:*), Read(/tmp/*.json), Bash(rm:*)
---

# /todo Command

Clean up TODO.md by archiving completed and abandoned tasks.

## Usage

```
/todo
```

## Workflow

1. **Analyze TODO.md**: Find all [COMPLETED] and [ABANDONED] tasks
2. **Sync State**: Ensure state.json matches TODO.md
3. **Archive Tasks**: Move completed/abandoned to archive section
4. **Update Metrics**: Calculate completion statistics
5. **Report**: Show summary of cleaned tasks

## Archive Format

Completed tasks moved to:

```markdown
## Archive

### 42. Navigation component [COMPLETED]

- **Completed**: 2026-02-05
- **Summary**: Created responsive navigation with mobile menu
```

## Example

User: `/todo`

Agent:

- Finds 5 completed tasks
- Finds 1 abandoned task
- Archives all 6 tasks
- Updates state.json
- Reports: "Archived 6 tasks (5 completed, 1 abandoned)"
