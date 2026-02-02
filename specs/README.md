# Project Specifications Directory

This directory contains all research, planning, debugging, and review artifacts organized by project.

## Directory Structure

```
specs/
├── README.md                    # This file
├── TODO.md                      # Active task list with status tracking
├── state.json                   # Machine-readable state (project tracking)
├── archive/                     # Completed/abandoned tasks (managed by /todo)
│   └── state.json               # Archive state tracking
└── {N}_project_name/            # Individual project directories (unpadded)
    ├── reports/                 # Research reports (gitignored)
    │   └── research-001.md      # Versioned research reports
    ├── plans/                   # Implementation plans (gitignored)
    │   └── implementation-001.md # Versioned implementation plans
    ├── summaries/               # Implementation summaries (gitignored)
    │   └── implementation-summary-YYYYMMDD.md  # Date-stamped summaries
    ├── debug/                   # Debug reports (COMMITTED to git)
    │   └── issue_name.md        # Debug investigation reports
    ├── scripts/                 # Investigation scripts (gitignored, temporary)
    ├── outputs/                 # Test outputs (gitignored, temporary)
    ├── artifacts/               # Operation artifacts (gitignored)
    └── backups/                 # Backups (gitignored)
```

## Project Numbering

Projects are numbered sequentially using unpadded integers (1, 2, 19, 20, etc.).

The next available number is tracked in two locations:
- **TODO.md frontmatter**: `next_project_number` field
- **state.json**: `next_project_number` field

When creating a new project (via `/task` command):
1. Read the current number from state.json
2. Create the task entry in TODO.md and state.json
3. Increment `next_project_number` in both files

Project directories (`{N}_{slug}/`) are created lazily - only when the first artifact is written by a research, planning, or implementation agent.

## State Management Files

### TODO.md
Human-readable task list with status tracking. Contains:
- YAML frontmatter with `next_project_number`
- Single `## Tasks` section with task entries (newest first)
- Status markers: `[NOT STARTED]`, `[RESEARCHING]`, `[PLANNED]`, `[IMPLEMENTING]`, `[COMPLETED]`, etc.

### state.json
Machine-readable project state. Contains:
- `next_project_number`: Next available task number
- `active_projects`: Array of current tasks with status, language, artifacts
- `repository_health`: Metrics for repository-wide technical debt

### archive/state.json
Tracks completed and abandoned projects that have been archived.

## Directory Lifecycle

Numbered project directories follow this lifecycle:

1. **Creation**: Task created via `/task` command (only adds entries to TODO.md and state.json)
2. **Artifact Accumulation**: Research, planning, and implementation agents create artifacts in `{N}_{slug}/` subdirectories
3. **Completion**: Task marked `[COMPLETED]` or `[ABANDONED]`
4. **Archival**: `/todo` command moves completed/abandoned tasks to `archive/` and cleans up project directories

This accumulation-then-archive pattern keeps the specs directory focused on active work while preserving history.

## Subdirectory Creation

Subdirectories are created on-demand when needed (lazy directory creation):

- **reports/**: Created by research agents for research tasks
- **plans/**: Created by planning agents for implementation planning
- **summaries/**: Created by implementation agents for post-implementation summaries
- **debug/**: Created by debug agents for issue investigation (COMMITTED to git)
- **scripts/**: Created for temporary investigation scripts (auto-cleaned)
- **outputs/**: Created for test outputs (auto-cleaned)
- **artifacts/**: Created for operation metadata (optional cleanup)
- **backups/**: Created for backup files (optional cleanup)

## File Naming Conventions

### Reports
- Research reports: `research-{NNN}.md` (e.g., `research-001.md`)
- `{NNN}` is 3-digit zero-padded for artifact versioning

### Plans
- Implementation plans: `implementation-{NNN}.md` (e.g., `implementation-001.md`)
- Revisions increment the version number

### Summaries
- Implementation summaries: `implementation-summary-{DATE}.md` (e.g., `implementation-summary-20260201.md`)
- `{DATE}` is YYYYMMDD format
- Created after implementation completion, links to plan

### Debug Reports
- Debug files: `{NNN}_descriptive_issue_name.md` (e.g., `001_lsp_completion_failure.md`)
- Committed to git for project history

### Scripts, Outputs, Artifacts, Backups
- Temporary or operational files
- Auto-cleaned or optionally retained
- See [Directory Protocols](../.claude/docs/concepts/directory-protocols.md) for details

## Cross-Referencing

All artifacts should include cross-references:

- Plans link to relevant reports in the same project
- Summaries link to plans and document implementation outcomes
- Debug reports link to related plans or phases if applicable
- Use relative paths for portability (e.g., `../reports/001_report.md`)

## Gitignore Compliance

| Artifact Type | Committed to Git | Reason |
|---------------|------------------|--------|
| `debug/` | YES | Project history, issue tracking |
| `reports/` | NO | Local working artifacts |
| `plans/` | NO | Local working artifacts |
| `summaries/` | NO | Local working artifacts |
| `scripts/` | NO | Temporary investigation |
| `outputs/` | NO | Regenerable test results |
| `artifacts/` | NO | Operational metadata |
| `backups/` | NO | Temporary recovery files |

## Navigation

- [Parent Directory](../) - Project root
- [TODO.md](./TODO.md) - Active task list
- [state.json](./state.json) - Machine-readable project state
- [Archive](./archive/) - Completed and abandoned tasks
