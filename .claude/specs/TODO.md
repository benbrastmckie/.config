---
last_updated: 2026-02-02T12:00:00Z
next_project_number: 21
repository_health:
  overall_score: 0
  production_readiness: initial
  last_assessed: 2026-01-10T19:00:00Z
task_counts:
  active: 10
  completed: 3
  in_progress: 0
  not_started: 7
  abandoned: 1
  total: 10
priority_distribution:
  high: 2
  medium: 4
  low: 1
---

# TODO

---

## In Progress

---

## High Priority

### 14. Update rules to define 3-digit padded directory numbering standard
- **Effort**: 30 minutes
- **Status**: [PLANNED]
- **Priority**: High
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/014_update_rules_padded_directory_numbers/plans/implementation-001.md)

**Description**: Update artifact-formats.md and state-management.md rules to define the standard for 3-digit zero-padded directory names ({NNN}_{SLUG}) while keeping task numbers unpadded in TODO.md, state.json, and commit messages.

---

### 15. Update /task command to create directories with 3-digit padded numbers
- **Effort**: 40 minutes
- **Status**: [PLANNED]
- **Priority**: High
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/015_update_task_command_padded_dirs/plans/implementation-001.md)

**Description**: Update the /task command to create task directories with 3-digit zero-padded numbers (e.g., 014_task_name instead of 14_task_name). This is the core implementation that affects directory creation.

---

## Medium Priority

### 16. Update workflow commands to use padded directory paths
- **Effort**: 1.5 hours
- **Status**: [PLANNED]
- **Priority**: Medium
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/016_update_workflow_commands_padded_paths/plans/implementation-001.md)

**Description**: Update /research, /plan, /implement, /revise, and /todo commands to construct and reference task directories using 3-digit padded numbers.

---

### 17. Update skills to use padded directory paths
- **Effort**: 1 hour
- **Status**: [PLANNED]
- **Priority**: Medium
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/017_update_skills_padded_paths/plans/implementation-001.md)

**Description**: Update all skill files that reference task directory paths to use the 3-digit padded format {NNN}_{SLUG}.

---

### 18. Update agents to use padded directory paths
- **Effort**: 1 hour
- **Status**: [PLANNED]
- **Priority**: Medium
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/018_update_agents_padded_paths/plans/implementation-001.md)

**Description**: Update all agent files that reference task directory paths to use the 3-digit padded format {NNN}_{SLUG}.

---

### 19. Update documentation to reflect padded directory paths
- **Effort**: 1.5 hours
- **Status**: [PLANNED]
- **Priority**: Medium
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/019_update_documentation_padded_paths/plans/implementation-001.md)

**Description**: Update CLAUDE.md, ARCHITECTURE.md, user guides, templates, and context files to document the 3-digit padded directory naming convention.

---

### 13. Refactor leader-ac management tool
- **Started**: 2026-01-11
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Priority**: Medium
- **Language**: lua
- **Completed**: 2026-01-11
- **Research**: [research-001.md](.claude/specs/13_refactor_leader_ac_management_tool/reports/research-001.md)
- **Plan**: [implementation-001.md](.claude/specs/13_refactor_leader_ac_management_tool/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260111.md](.claude/specs/13_refactor_leader_ac_management_tool/summaries/implementation-summary-20260111.md)

**Description**: Refactor the `<leader>ac` management tool in accordance with the extensively refactored .claude/ agent system, improving the implementation as appropriate but without making unnecessary or overly complex changes. The aim is quality and functionality with minimal complexity.

---

### 12. Remove all goose.nvim traces
- **Effort**: 45 minutes
- **Status**: [COMPLETED]
- **Priority**: Medium
- **Language**: lua
- **Completed**: 2026-01-11
- **Research**: [research-001.md](.claude/specs/12_remove_goose_nvim_traces/reports/research-001.md)
- **Plan**: [implementation-001.md](.claude/specs/12_remove_goose_nvim_traces/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260111.md](.claude/specs/12_remove_goose_nvim_traces/summaries/implementation-summary-20260111.md)

**Description**: Systematically remove all traces of goose.nvim from Neovim config, documentation, code comments, etc.

---

### 11. Fix task command implementation bug
- **Effort**: TBD
- **Status**: [ABANDONED]
- **Priority**: Medium
- **Language**: meta
- **Research**: [research-001.md](.claude/specs/11_fix_task_command_implementation_bug/reports/research-001.md)
- **Reason**: Bug already fixed in repository

**Description**: Use /home/benjamin/.config/.claude/specs/task-command-implementation-bug.md to fix this bug in an elegant way.

---

### 10. Replace 'context: fork' with explicit context file references in SKILL.md files
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Priority**: Medium
- **Language**: meta
- **Research**: [research-001.md](.claude/specs/10_skill_context_file_references/reports/research-001.md)
- **Plan**: [implementation-001.md](.claude/specs/10_skill_context_file_references/plans/implementation-001.md)
- **Completed**: 2026-01-10
- **Summary**: [implementation-summary-20260110.md](.claude/specs/10_skill_context_file_references/summaries/implementation-summary-20260110.md)

**Description**: Replace 'context: fork' in various SKILL.md files with explicit loading of the correct context files from .claude/context/ that provide relevant information while avoiding bloat.

---

## Low Priority

### 20. Migrate existing unpadded directories to padded format
- **Effort**: 1 hour
- **Status**: [PLANNED]
- **Priority**: Low
- **Language**: meta
- **Plan**: [implementation-001.md](.claude/specs/020_migrate_existing_directories_padded/plans/implementation-001.md)

**Description**: Create and execute a migration script to rename existing unpadded task directories (e.g., 19_task_name) to the new padded format (e.g., 019_task_name).

---

## Backlog

---

## Completed

_Tasks archived on 2026-01-10. See `.claude/specs/archive/state.json` for details._

---
