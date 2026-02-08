---
next_project_number: 52
---

# TODO

## Tasks

### 51. Complete Himalaya email configuration in Neovim
- **Effort**: TBD
- **Status**: [NOT STARTED]
- **Language**: neovim

**Description**: Complete the Himalaya email configuration in Neovim. Research what remains to be done to fully configure Himalaya to keep all email for two accounts synced with local copies: primary account 'benjamin@logos-labs.ai' and secondary account 'benbrastmckie@gmail.com'. Investigate both the Himalaya CLI/backend setup for IMAP sync and the Neovim integration configuration.

### 50. Fix <leader>rf keymap for multiple filetypes
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-06
- **Language**: neovim
- **Research**: [research-050.md](050_fix_leader_rf_formatting/reports/research-050.md)
- **Plan**: [implementation-051.md](050_fix_leader_rf_formatting/plans/implementation-051.md)
- **Summary**: [implementation-summary-20260206.md](050_fix_leader_rf_formatting/summaries/implementation-summary-20260206.md)

**Description**: Fix <leader>rf formatting keymap to work properly with .astro, markdown, and other filetypes. Improve functionality to automatically format based on detected language.

### 49. Fix Astro indentation on CR in middle of line
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-06
- **Summary**: [implementation-summary-20260206.md](049_astro_indentation/summaries/implementation-summary-20260206.md)
- **Language**: neovim
- **Research**: [research-049.md](049_astro_indentation/reports/research-049.md)
- **Plan**: [implementation-049.md](049_astro_indentation/plans/implementation-049.md)

**Description**: Fix unwanted un-indenting when hitting <CR> in middle of line in .astro files. Currently when pressing Enter mid-line, text loses proper indentation.

### 48. Add Phase Checkpoint Protocol to neovim-implementation-agent
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](048_add_phase_checkpoint_protocol_to_neovim/summaries/implementation-summary-20260205.md)
- **Language**: meta
- **Started**: 2026-02-05
- **Research**: [research-001.md](048_add_phase_checkpoint_protocol_to_neovim/reports/research-001.md)
- **Plan**: [implementation-001.md](048_add_phase_checkpoint_protocol_to_neovim/plans/implementation-001.md)

**Description**: Add Phase Checkpoint Protocol to neovim-implementation-agent for per-phase status marker updates during plan execution.

### 47. Fix leader-ac sync source path
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](047_fix_leader_ac_sync_source_path/summaries/implementation-summary-20260205.md)
- **Language**: neovim
- **Started**: 2026-02-05
- **Research**: [research-001.md](047_fix_leader_ac_sync_source_path/reports/research-001.md)
- **Plan**: [implementation-001.md](047_fix_leader_ac_sync_source_path/plans/implementation-001.md)

**Description**: Fix the `<leader>ac` sync source path to ensure the agent management tool reads from the correct source directory.

### 46. Migrate LogosWebsite to padded directory convention
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](046_migrate_logosweb_to_padded_directory_conv/summaries/implementation-summary-20260205.md)
- **Language**: meta
- **Research**: [research-001.md](046_migrate_logosweb_to_padded_directory_conv/reports/research-001.md)
- **Plan**: [implementation-002.md](046_migrate_logosweb_to_padded_directory_conv/plans/implementation-002.md)

**Description**: Change the `{N}` unpadded directory convention in LogosWebsite to use `{NNN}` zero-padded directories for lexicographic sorting consistency with the nvim repo.

### 45. Fix LogosWebsite agent system gaps identified in task 44 research
- **Effort**: Medium
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](045_fix_logosweb_agent_gaps_from_task_44/summaries/implementation-summary-20260205.md)
- **Language**: meta
- **Research**: [research-001.md](045_fix_logosweb_agent_gaps_from_task_44/reports/research-001.md)
- **Plan**: [implementation-001.md](045_fix_logosweb_agent_gaps_from_task_44/plans/implementation-001.md)

**Description**: Research task 44 and compare the issues identified in the reports to find and fix any gaps in the agent system /home/benjamin/Projects/Logos/LogosWebsite/.claude/ which was copied from /home/benjamin/.config/nvim/.claude/ using the leader-ac agent management tool before task 44 was implemented.

### 44. Complete LogosWebsite task 9 equivalent in this repo
- **Effort**: Small
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](044_complete_logosweb_task_9_equivalent/summaries/implementation-summary-20260205.md)
- **Language**: meta
- **Research**: [research-001.md](044_complete_logosweb_task_9_equivalent/reports/research-001.md), [research-002.md](044_complete_logosweb_task_9_equivalent/reports/research-002.md)
- **Plan**: [implementation-001.md](044_complete_logosweb_task_9_equivalent/plans/implementation-001.md)

**Description**: Draw on task 9 in /home/benjamin/Projects/Logos/LogosWebsite/specs/TODO.md to complete the same work in this repository. Research what task 9 involves and adapt it for the Neovim configuration .claude/ agent system.

---

### 43. Fix web language routing gaps
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](043_fix_web_language_routing_gaps/summaries/implementation-summary-20260205.md)
- **Language**: general
- **Research**: [research-001.md](043_fix_web_language_routing_gaps/reports/research-001.md)
- **Plan**: [implementation-001.md](043_fix_web_language_routing_gaps/plans/implementation-001.md)

**Description**: Fix gaps identified in phase 4 of /home/benjamin/Projects/Logos/LogosWebsite/specs/3_add_web_language_routing/plans/implementation-001.md. Draw on the phase 4 analysis to create targeted fixes for the web language routing implementation.

---

### 42. Fix specs/ prefix in TODO.md artifact links
- **Effort**: Medium
- **Status**: [COMPLETED]
- **Completed**: 2026-02-05
- **Summary**: [implementation-summary-20260205.md](042_fix_specs_prefix_in_todo_artifact_links/summaries/implementation-summary-20260205.md)
- **Language**: meta
- **Research**: [research-001.md](042_fix_specs_prefix_in_todo_artifact_links/reports/research-001.md)
- **Plan**: [implementation-001.md](042_fix_specs_prefix_in_todo_artifact_links/plans/implementation-001.md)

**Description**: TODO.md artifact links incorrectly include the `specs/` prefix (e.g., `specs/1_slug/reports/research-001.md`). Since TODO.md lives inside `specs/`, links should be relative to that directory (e.g., `1_slug/reports/research-001.md`). Root cause: agents write `specs/`-prefixed paths in `.return-meta.json`, and skill postflight code passes these verbatim into TODO.md links without stripping the prefix. Files to fix (12 total): Rules: `state-management.md` (lines 210, 216, 223), `inline-status-update.md` (lines 188, 193, 198). Skills: `skill-researcher`, `skill-neovim-research`, `skill-planner`, `skill-implementer`, `skill-typst-implementation`, `skill-latex-implementation`, `skill-neovim-implementation`, `skill-status-sync`. Docs: `research-workflow.md`, `planning-workflow.md`. Fix: Add `todo_link_path="${artifact_path#specs/}"` in skill postflight before TODO.md Edit.

---

### 41. Fix leanls LSP client exit error in Neovim
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Completed**: 2026-02-04
- **Summary**: [implementation-summary-20260204.md](041_fix_leanls_lsp_client_exit_error/summaries/implementation-summary-20260204.md)
- **Language**: neovim
- **Research**: [research-001.md](041_fix_leanls_lsp_client_exit_error/reports/research-001.md), [research-002.md](041_fix_leanls_lsp_client_exit_error/reports/research-002.md)
- **Plan**: [implementation-003.md](041_fix_leanls_lsp_client_exit_error/plans/implementation-003.md)

**Description**: Fix leanls LSP client errors when opening Lean files: "Client leanls quit with exit code 1 and signal 0" and "Watchdog error: no such file or directory (error code: 2)". Check LSP log at ~/.local/state/nvim/lsp.log for details.

### 40. Standardize multi-task creation patterns
- **Effort**: 4-6 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Summary**: [implementation-summary-20260203.md](040_standardize_multi_task_creation_patterns/summaries/implementation-summary-20260203.md)
- **Language**: meta
- **Research**: [research-001.md](040_standardize_multi_task_creation_patterns/reports/research-001.md)
- **Plan**: [implementation-001.md](040_standardize_multi_task_creation_patterns/plans/implementation-001.md)

**Description**: Check all commands/skills/agents that create tasks, ensuring multi-task creators use the interactive selection pattern from /learn (user selects which to create and how to group them). Standardize the dependency display and task creation order pattern from /meta (topological sorting, layered graph visualization). Create a common best practice pattern to be used consistently across: /task --review, /errors, /review, /learn, /meta, and any other multi-task creators.

---

*No other active tasks. Use `/task "description"` to create a new task.*

