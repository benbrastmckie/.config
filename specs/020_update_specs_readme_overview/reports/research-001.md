# Research Report: Task #20

**Task**: Update specs/README.md with directory overview
**Date**: 2026-02-01
**Focus**: Review specs/README.md current state and document conventions for directory structure, project numbering, and /todo archival process

## Summary

The current specs/README.md is comprehensive and largely accurate, covering directory structure, project numbering, subdirectory creation, file naming conventions, cross-referencing, and gitignore compliance. However, it is missing documentation about the archival process via the `/todo` command, which is a key workflow for managing the accumulation of project directories. The README also contains some outdated information (e.g., references to `.lockfile` which no longer exists in this setup, and 3-digit zero-padded project numbers which are now unpadded).

## Findings

### Current README Coverage

The existing specs/README.md documents:

1. **Directory Structure**: Shows the hierarchy with project directories and their subdirectories (reports/, plans/, summaries/, debug/, scripts/, outputs/, artifacts/, backups/)

2. **Project Numbering**: States "3-digit zero-padded numbers (001, 002, 003)" - but actual practice uses unpadded numbers (e.g., `19_adapt_claude_system_for_stock_neovim`, not `019_`)

3. **Subdirectory Creation**: Documents lazy directory creation patterns

4. **File Naming Conventions**: Covers reports, plans, summaries, debug reports, and other artifacts

5. **Cross-Referencing**: Documents linking between artifacts

6. **Gitignore Compliance**: Shows which artifact types are committed vs ignored

### Missing Documentation

The README does not document:

1. **Archive Process**: No mention of `specs/archive/` directory or the `/todo` command archival workflow

2. **State Management Files**: No documentation of:
   - `state.json` - machine-readable task state
   - `TODO.md` - user-facing task list
   - `archive/state.json` - archived task registry

3. **Directory Lifecycle**: No explanation that project directories accumulate in specs/ and are moved to specs/archive/ when tasks complete or are abandoned

4. **Orphan Handling**: No documentation of orphaned directory detection and tracking

### Current Directory State

Actual specs/ directory contents:
```
specs/
├── README.md           # This file
├── TODO.md             # Active task list (frontmatter has next_project_number)
├── state.json          # Machine state with active_projects array
├── archive/            # Archived task directories
│   └── state.json      # Registry of completed_projects
├── 001_status_tracking_enhancement/
├── 018_agent_modes_vs_commands/
├── 19_adapt_claude_system_for_stock_neovim/
└── 20_update_specs_readme_overview/
```

### Project Numbering Conventions

From state-management.md and actual practice:
- Task numbers are **unpadded integers** (e.g., `19`, `20`, not `019`, `020`)
- The `{N}_{SLUG}` pattern uses the task number directly
- Artifact versions within a task use 3-digit padding (`research-001.md`)
- The distinction is documented in artifact-formats.md: "Task numbers ({N}) are unpadded because they grow indefinitely. Artifact versions ({NNN}) are padded because they rarely exceed 999 per task."

### Archival Process (from /todo command)

Key archival behaviors documented in `.claude/commands/todo.md`:

1. **Trigger**: Run `/todo` command manually

2. **Eligible Tasks**: Tasks with status = "completed" or "abandoned"

3. **Operations**:
   - Task entry removed from TODO.md
   - Task entry moved from state.json `active_projects` to archive/state.json `completed_projects` or `archived_projects`
   - Physical directory moved from `specs/{N}_{SLUG}/` to `specs/archive/{N}_{SLUG}/`

4. **Orphan Detection**: Scans for directories not tracked in any state file

5. **Misplaced Detection**: Scans for directories in specs/ that should be in archive/

### Referenced but Outdated

The README references:
- `.lockfile` for tracking next project number - this mechanism is not present; `next_project_number` is in TODO.md frontmatter and state.json

## Recommendations

1. **Add Archive Section**: Document the archive/ subdirectory, its purpose, and the `/todo` command workflow

2. **Fix Project Numbering**: Update from "3-digit zero-padded" to "unpadded integers" to match actual practice

3. **Add State Files Section**: Document state.json, TODO.md, and archive/state.json roles

4. **Remove .lockfile Reference**: Replace with documentation of where next_project_number is stored

5. **Simplify Structure**: The README is quite detailed; consider keeping the overview brief and linking to more detailed documentation (state-management.md, artifact-formats.md)

6. **Add Directory Lifecycle**: Briefly explain that directories accumulate during active work and are archived by /todo

## References

- `.claude/rules/state-management.md` - Canonical source for state file formats and status transitions
- `.claude/rules/artifact-formats.md` - Placeholder conventions and artifact naming
- `.claude/commands/todo.md` - Complete /todo command workflow including archival
- `specs/state.json` - Current machine state
- `specs/archive/state.json` - Archived project registry

## Next Steps

Create implementation plan for updating specs/README.md with:
1. Corrected project numbering documentation
2. Archive section describing /todo archival process
3. State files documentation
4. Remove outdated .lockfile reference
