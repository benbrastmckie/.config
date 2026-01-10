---
description: Archive completed and abandoned tasks
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git:*), TodoWrite
argument-hint: [--dry-run]
model: claude-opus-4-5-20251101
---

# /todo Command

Archive completed and abandoned tasks to clean up active task list.

## Arguments

- `--dry-run` - Show what would be archived without making changes

## Execution

### 1. Parse Arguments

```
dry_run = "--dry-run" in $ARGUMENTS
```

### 2. Scan for Archivable Tasks

Read .claude/specs/state.json and identify:
- Tasks with status = "completed"
- Tasks with status = "abandoned"

Read .claude/specs/TODO.md and cross-reference:
- Entries marked [COMPLETED]
- Entries marked [ABANDONED]

### 3. Prepare Archive List

For each archivable task, collect:
- project_number
- project_name
- status
- completion/abandonment date
- artifact paths

### 4. Dry Run Output (if --dry-run)

```
Tasks to archive:

Completed:
- #{N1}: {title} (completed {date})
- #{N2}: {title} (completed {date})

Abandoned:
- #{N3}: {title} (abandoned {date})

Total: {N} tasks

Run without --dry-run to archive.
```

Exit here if dry run.

### 5. Archive Tasks

**A. Update archive/state.json**

Ensure .claude/specs/archive/ exists.

Read or create .claude/specs/archive/state.json:
```json
{
  "archived_projects": []
}
```

Move each task from active_projects to archived_projects.

**B. Update state.json**

Remove archived tasks from active_projects array.
Update task_counts.

**C. Update TODO.md**

Remove archived task entries from main sections.
Optionally add to archive section at bottom (collapsed).

**D. Preserve Artifacts**

Task directories remain in .claude/specs/{N}_{SLUG}/
(Don't move or delete - they're still valuable reference)

### 6. Git Commit

```bash
git add .claude/specs/
git commit -m "todo: archive {N} completed tasks"
```

### 7. Output

```
Archived {N} tasks:

Completed ({N}):
- #{N1}: {title}
- #{N2}: {title}

Abandoned ({N}):
- #{N3}: {title}

Active tasks remaining: {N}
- High priority: {N}
- Medium priority: {N}
- Low priority: {N}

Archives: .claude/specs/archive/state.json
```

## Notes

- Artifacts (plans, reports, summaries) are preserved
- Tasks can be recovered with `/task --recover N`
- Archive is append-only (for audit trail)
- Run periodically to keep TODO.md manageable
