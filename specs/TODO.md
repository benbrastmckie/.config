---
next_project_number: 31
---

# TODO

## Tasks

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

### 28. Reconcile duplicate specs data
- **Effort**: 2-3 hours
- **Status**: [ABANDONED]
- **Language**: meta
- **Priority**: medium
- **Plan**: [implementation-001.md](specs/028_reconcile_duplicate_specs_data/plans/implementation-001.md)

**Description**: Reconcile duplicate specs data between nvim/specs/ and nvim/.claude/specs/. **Abandoned**: No longer needed - duplicate data issue resolved during task migration; orphaned .claude/specs/ directory removed.

### 27. Migrate specs data to project root
- **Effort**: 1-2 hours
- **Status**: [ABANDONED]
- **Language**: meta
- **Priority**: high
- **Plan**: [implementation-001.md](specs/027_migrate_specs_to_project_root/plans/implementation-001.md)

**Description**: Move specs data from .claude/specs/ to specs/ at project root. **Abandoned**: No longer needed - specs/ already at project root; .claude/specs/ was orphaned directory that has been removed.

### 26. Fix specs path references in .claude/ files
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Priority**: high
- **Completed**: 2026-02-02
- **Plan**: [implementation-001.md](specs/026_fix_specs_path_references/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/026_fix_specs_path_references/summaries/implementation-summary-20260202.md)

**Description**: Update all .claude/ files to use specs/ instead of .claude/specs/. Fixed 2 files with incorrect references.

### 25. Migrate git repository from .config/ to .config/nvim/
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: general
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/25_migrate_git_repo_to_nvim_directory/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/25_migrate_git_repo_to_nvim_directory/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/25_migrate_git_repo_to_nvim_directory/summaries/implementation-summary-20260202.md)

**Description**: Migrate the git repository from managing the entire .config/ directory to only managing .config/nvim/, since everything else is now managed by .dotfiles/ using home-manager and NixOS configuration. Move the .git/ directory into .config/nvim/ using a standard approach that preserves the full commit history for this (primarily Neovim) configuration.

### 24. Add .gitignore, README.md, CLAUDE.md, and settings.local.json to leader-ac picker
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: neovim
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Plan**: [implementation-001.md](specs/24_add_root_files_to_leader_ac_picker/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/24_add_root_files_to_leader_ac_picker/summaries/implementation-summary-20260202.md)

**Description**: Add .gitignore, README.md, CLAUDE.md, and settings.local.json to `<leader>ac` picker for complete .claude/ directory management.

### 23. Check leader-ac picker manages all .claude/ contents by directory
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Language**: neovim
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/23_leader_ac_picker_claude_directory_management/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/23_leader_ac_picker_claude_directory_management/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/23_leader_ac_picker_claude_directory_management/summaries/implementation-summary-20260202.md)

**Description**: Check that the `<leader>ac` picker is equipped to manage all of the contents in .claude/ by directory so that I can load this configuration easily into other project directories.

### 22. Review .claude/ directory for Neovim improvements
- **Effort**: 2-4 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/22_review_claude_directory_neovim_improvements/reports/research-001.md)
- **Plan**: [implementation-002.md](specs/22_review_claude_directory_neovim_improvements/plans/implementation-002.md)
- **Summary**: [implementation-summary-20260202.md](specs/22_review_claude_directory_neovim_improvements/summaries/implementation-summary-20260202.md)

**Description**: Review .claude/ directory for remaining improvements needed for Neovim configuration focus. After completing tasks 19, 20, and 21 which adapted the system from Lean to Neovim, identify what else needs updating - specifically focusing on context/ files that may need improvement or expansion for the new Neovim maintenance use case.

### 21. Update .claude/ documentation to remove Lean references
- **Effort**: 4-8 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/21_update_claude_docs_neovim_focus/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/21_update_claude_docs_neovim_focus/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/21_update_claude_docs_neovim_focus/summaries/implementation-summary-20260202.md)

**Description**: Update .claude/ documentation to remove Lean references and reflect Neovim focus. Found 128+ files with Lean/theorem/proof references including: .claude/README.md (51 refs), docs/architecture/system-overview.md (14 refs), context/index.md (4 refs), plus extensive refs in docs/guides/, context/core/, context/project/, skills/, agents/, commands/, and rules/. Need systematic review to replace Lean examples with Neovim examples, update architecture descriptions, fix outdated language routing tables, and ensure all documentation accurately reflects the stock Neovim configuration system.

### 20. Update specs/README.md with directory overview
- **Effort**: 0.5-1 hours
- **Status**: [COMPLETED]
- **Language**: general
- **Research**: [research-001.md](specs/20_update_specs_readme_overview/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/20_update_specs_readme_overview/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260201.md](specs/20_update_specs_readme_overview/summaries/implementation-summary-20260201.md)

**Description**: Update specs/README.md to provide a brief overview of the directory contents, noting that numbered project directories accumulate and are archived to specs/archive/ by the /todo command

### 19. Adapt Claude agent system for stock Neovim configuration
- **Effort**: 14-21 hours
- **Status**: [COMPLETED]
- **Language**: meta
- **Started**: 2026-02-02
- **Completed**: 2026-02-02
- **Research**: [research-001.md](specs/19_adapt_claude_system_for_stock_neovim/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/19_adapt_claude_system_for_stock_neovim/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/19_adapt_claude_system_for_stock_neovim/summaries/implementation-summary-20260202.md)

**Description**: Adapt the current .claude/ agent system (designed for Lean codebase) to produce a stock .claude/ agent system for Neovim configuration maintenance that can be systematically extended for specific applications

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
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: medium
- **Plan**: [implementation-001.md](specs/016_update_workflow_commands_padded_paths/plans/implementation-001.md)

**Description**: Update /research, /plan, /implement, /revise, /todo commands to use 3-digit padded directory numbers.

### 15. Update /task command for 3-digit padded directories
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: high
- **Plan**: [implementation-001.md](specs/015_update_task_command_padded_dirs/plans/implementation-001.md)

**Description**: Update the /task command to create directories with 3-digit zero-padded numbers (e.g., `015_task_name` instead of `15_task_name`).

### 14. Update rules for 3-digit padded directory numbers
- **Effort**: 1-2 hours
- **Status**: [PLANNED]
- **Language**: meta
- **Priority**: high
- **Plan**: [implementation-001.md](specs/014_update_rules_padded_directory_numbers/plans/implementation-001.md)

**Description**: Update artifact-formats.md and state-management.md rules to specify 3-digit zero-padded directory numbers for proper lexicographic sorting.

