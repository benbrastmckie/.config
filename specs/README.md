# Project Specifications Directory

This directory contains all research, planning, debugging, and review artifacts organized by project.

## Directory Structure

```
specs/
├── .lockfile                    # Tracks next available project number
├── README.md                    # This file
└── NNN_project_name/            # Individual project directories
    ├── reports/                 # Research reports (gitignored)
    │   ├── OVERVIEW.md          # Summary with links to individual reports
    │   ├── 001_topic.md         # Individual research reports
    │   └── 002_topic.md
    ├── plans/                   # Implementation plans (gitignored)
    │   ├── 001_plan_name.md     # Initial plan
    │   └── 002_plan_name.md     # Revised plan (same name, incremented number)
    ├── summaries/               # Implementation summaries (gitignored)
    │   └── 001_summary.md       # Post-implementation summaries
    ├── debug/                   # Debug reports (COMMITTED to git)
    │   └── issue_name.md        # Debug investigation reports
    ├── scripts/                 # Investigation scripts (gitignored, temporary)
    ├── outputs/                 # Test outputs (gitignored, temporary)
    ├── artifacts/               # Operation artifacts (gitignored)
    └── backups/                 # Backups (gitignored)
```

## Project Numbering

Projects are numbered sequentially using 3-digit zero-padded numbers (001, 002, 003, etc.).

The `.lockfile` contains the next available number. When creating a new project:

1. Read the current number from `.lockfile`
2. Create the project directory with that number
3. Increment the number and write back to `.lockfile`

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
- Individual reports: `NNN_descriptive_name.md` (e.g., `001_lazy_loading_patterns.md`)
- Overview file: `OVERVIEW.md` (always present when reports/ exists)

### Plans
- Plans: `NNN_plan_name.md` (e.g., `001_telescope_integration.md`)
- Revisions keep the same name but increment the number

### Summaries
- Summaries: `NNN_summary_name.md` (e.g., `001_implementation_summary.md`)
- Created after implementation completion
- Link to plans and document implementation outcomes

### Debug Reports
- Debug files: `NNN_descriptive_issue_name.md` (e.g., `001_lsp_completion_failure.md`)
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

- [Parent Directory](../) - .opencode root
- [TODO.md](../TODO.md) - Active task list
- [Directory Protocols](../.claude/docs/concepts/directory-protocols.md) - Complete directory structure documentation
