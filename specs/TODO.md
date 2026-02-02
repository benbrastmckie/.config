---
next_project_number: 32
---

# TODO

## Tasks

### 31. Fix plan file status update in /implement
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Language**: meta

**Description**: Add plan file status verification to /implement GATE OUT checkpoint and make implementation skills more explicit about plan file updates. Currently plan files are not reliably updated to [COMPLETED] status after implementation finishes (documented in skills but not executed). Fix: (1) Add verification step in implement.md GATE OUT that checks plan file status matches task status and updates if needed (defensive backup), (2) Make the sed command in skills Stage 7 more explicit with error checking and verification output.

### 30. Migrate existing directories to 3-digit padded format
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: low
- **Plan**: [implementation-001.md](specs/030_migrate_existing_directories_padded/plans/implementation-001.md)

**Description**: Create migration script to rename existing task directories from unpadded (e.g., `19_task_name`) to 3-digit padded format (e.g., `019_task_name`). Update all internal references.

### 29. Update documentation for 3-digit padded paths
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: medium
- **Plan**: [implementation-001.md](specs/029_update_documentation_padded_paths/plans/implementation-001.md)

**Description**: Update all documentation files to use 3-digit padded directory numbers in examples and references.

### 18. Update agents for 3-digit padded directory paths
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: medium
- **Plan**: [implementation-001.md](specs/018_update_agents_padded_paths/plans/implementation-001.md)

**Description**: Update all agent files to use 3-digit padded directory numbers in path references.

### 17. Update skills for 3-digit padded directory paths
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: medium
- **Plan**: [implementation-001.md](specs/017_update_skills_padded_paths/plans/implementation-001.md)

**Description**: Update all skill files to use 3-digit padded directory numbers in path references.

### 16. Update workflow commands for 3-digit padded directory paths
- **Effort**: 2-3 hours
- **Status**: [IMPLEMENTING]
- **Language**: meta
- **Priority**: medium
- **Plan**: [implementation-001.md](specs/016_update_workflow_commands_padded_paths/plans/implementation-001.md)

**Description**: Update /research, /plan, /implement, /revise, /todo commands to use 3-digit padded directory numbers.

### 15. Update /task command for 3-digit padded directories
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Priority**: high
- **Plan**: [implementation-001.md](specs/015_update_task_command_padded_dirs/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/015_update_task_command_padded_dirs/summaries/implementation-summary-20260202.md)

**Description**: Update the /task command to create directories with 3-digit zero-padded numbers (e.g., `015_task_name` instead of `15_task_name`).

### 14. Update rules for 3-digit padded directory numbers
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Priority**: high
- **Plan**: [implementation-002.md](specs/014_update_rules_padded_directory_numbers/plans/implementation-002.md)
- **Research**: [research-001.md](specs/014_update_rules_padded_directory_numbers/reports/research-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/014_update_rules_padded_directory_numbers/summaries/implementation-summary-20260202.md)

**Description**: Update artifact-formats.md and state-management.md rules to specify 3-digit zero-padded directory numbers for proper lexicographic sorting.

