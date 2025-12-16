# Project Specifications Directory

This directory contains all research, planning, debugging, and review artifacts organized by project.

## Directory Structure

```
specs/
├── .lockfile                    # Tracks next available project number
├── README.md                    # This file
└── NNN_project_name/            # Individual project directories
    ├── reports/                 # Research reports
    │   ├── OVERVIEW.md          # Summary with links to individual reports
    │   ├── 001_topic.md         # Individual research reports
    │   └── 002_topic.md
    ├── plans/                   # Implementation plans
    │   ├── 001_plan_name.md     # Initial plan
    │   └── 002_plan_name.md     # Revised plan (same name, incremented number)
    ├── debug/                   # Debug reports and analysis
    │   └── issue_name.md        # Debug investigation reports
    └── reviews/                 # Implementation reviews
        └── review_name.md       # Review linking to implemented plan
```

## Project Numbering

Projects are numbered sequentially using 3-digit zero-padded numbers (001, 002, 003, etc.).

The `.lockfile` contains the next available number. When creating a new project:

1. Read the current number from `.lockfile`
2. Create the project directory with that number
3. Increment the number and write back to `.lockfile`

## Subdirectory Creation

Subdirectories (reports/, plans/, debug/, reviews/) are created on-demand when needed:

- **reports/**: Created by the researcher agent for research tasks
- **plans/**: Created by the planner agent for implementation planning
- **debug/**: Created by the debugger agent for issue investigation
- **reviews/**: Created by the reviewer agent for implementation reviews

## File Naming Conventions

### Reports
- Individual reports: `NNN_descriptive_name.md` (e.g., `001_lazy_loading_patterns.md`)
- Overview file: `OVERVIEW.md` (always present when reports/ exists)

### Plans
- Plans: `NNN_plan_name.md` (e.g., `001_telescope_integration.md`)
- Revisions keep the same name but increment the number

### Debug Reports
- Debug files: `descriptive_issue_name.md` (e.g., `lsp_completion_failure.md`)

### Reviews
- Review files: `review_plan_name.md` (e.g., `review_telescope_integration.md`)

## Cross-Referencing

All artifacts should include cross-references:

- Plans link to relevant reports in the same project
- Reviews link to the plan they are reviewing
- Debug reports link to related plans or reviews if applicable

## Navigation

- [Parent Directory](../) - .opencode root
- [TODO.md](../TODO.md) - Active task list
