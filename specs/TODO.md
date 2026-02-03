---
next_project_number: 40
---

# TODO

## Tasks

### 35. Add dependencies field to state.json schema
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: meta
- **Dependencies**: None
- **Research**: [research-001.md](specs/035_add_dependencies_field_to_state_schema/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/035_add_dependencies_field_to_state_schema/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260203.md](specs/035_add_dependencies_field_to_state_schema/summaries/implementation-summary-20260203.md)

**Description**: Update state-management.md to add dependencies array field to task entries for machine-readable dependency tracking. This is the foundational schema change that enables all other dependency handling improvements.

---

### 36. Enhance interview Stage 3 dependency capture
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: meta
- **Dependencies**: Task #35
- **Research**: [research-001.md](specs/036_enhance_interview_stage3_dependency_capture/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/036_enhance_interview_stage3_dependency_capture/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260203.md](specs/036_enhance_interview_stage3_dependency_capture/summaries/implementation-summary-20260203.md)

**Description**: Update meta-builder-agent.md Stage 3 IdentifyUseCases to explicitly capture dependency relationships with validation (must reference valid task numbers, no circular dependencies).

---

### 37. Implement topological sorting in Stage 6
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: meta
- **Dependencies**: Task #35, Task #36
- **Research**: [research-001.md](specs/037_implement_topological_sorting_stage6/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/037_implement_topological_sorting_stage6/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260203.md](specs/037_implement_topological_sorting_stage6/summaries/implementation-summary-20260203.md)

**Description**: Update meta-builder-agent.md Stage 6 CreateTasks to implement topological sorting of tasks based on dependency graph so foundational tasks get lower numbers and are created first.

---

### 38. Update TODO.md insertion for dependency order
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: meta
- **Dependencies**: Task #37
- **Research**: [research-001.md](specs/038_update_todomd_insertion_dependency_order/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/038_update_todomd_insertion_dependency_order/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260203.md](specs/038_update_todomd_insertion_dependency_order/summaries/implementation-summary-20260203.md)

**Description**: Modify TODO.md insertion logic to insert tasks in dependency order (foundational tasks higher in file) instead of always prepending.

---

### 39. Enhance Stage 7 dependency visualization
- **Effort**: 1-2 hours
- **Status**: [NOT STARTED]
- **Language**: meta
- **Dependencies**: Task #37, Task #38

**Description**: Update meta-builder-agent.md Stage 7 DeliverSummary to show dependency graph visualization and execution order based on actual assigned task numbers.

---

### 34. Research best practices for Claude Code statusline display formatting
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: neovim
- **Research**: [research-001.md](specs/034_statusline_display_best_practices/reports/research-001.md)
- **Plan**: [implementation-002.md](specs/034_statusline_display_best_practices/plans/implementation-002.md)
- **Summary**: [implementation-summary-20260203.md](specs/034_statusline_display_best_practices/summaries/implementation-summary-20260203.md)

**Description**: Research best practices for Claude Code statusline display formatting - improve visual presentation of context usage percentage bar, token counts, model name, and cost. Current display shows progress bars with brackets and equals signs that could be more readable and aesthetically pleasing.

### 33. Fix Claude Code settings.json statusLine configuration
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: neovim
- **Research**: [research-001.md](specs/033_fix_statusline_settings_config/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/033_fix_statusline_settings_config/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260203.md](specs/033_fix_statusline_settings_config/summaries/implementation-summary-20260203.md)

**Description**: Fix Claude Code settings.json statusLine configuration - move statusLine from hooks object to top-level field with correct schema per research-003.md. Current error: "statusLine: Invalid key in record" because statusLine was incorrectly nested inside hooks object when it should be a separate top-level configuration.

### 32. Improve Neovim sidebar panel to display Claude Code context usage
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Language**: neovim
- **Research**: [research-001.md](specs/032_neovim_sidebar_context_display/reports/research-001.md), [research-002.md](specs/032_neovim_sidebar_context_display/reports/research-002.md), [research-003.md](specs/032_neovim_sidebar_context_display/reports/research-003.md)
- **Plan**: [implementation-001.md](specs/032_neovim_sidebar_context_display/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260203.md](specs/032_neovim_sidebar_context_display/summaries/implementation-summary-20260203.md)

**Description**: Research how to add a context indicator to the Neovim sidebar panel showing percentage of context used, similar to the VS Code extension's prompt box footer display. Investigate available APIs, hooks, or customization options for displaying real-time context usage information.

### 31. Fix plan file status update in /implement
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-02
- **Language**: meta
- **Research**: [research-001.md](specs/031_fix_plan_file_status_update_in_implement/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/031_fix_plan_file_status_update_in_implement/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260202.md](specs/031_fix_plan_file_status_update_in_implement/summaries/implementation-summary-20260202.md)

**Description**: Add plan file status verification to /implement GATE OUT checkpoint and make implementation skills more explicit about plan file updates. Currently plan files are not reliably updated to [COMPLETED] status after implementation finishes (documented in skills but not executed). Fix: (1) Add verification step in implement.md GATE OUT that checks plan file status matches task status and updates if needed (defensive backup), (2) Make the sed command in skills Stage 7 more explicit with error checking and verification output.


