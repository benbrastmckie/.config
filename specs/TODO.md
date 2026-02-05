---
next_project_number: 44
---

# TODO

## Tasks

### 43. Fix web language routing gaps
- **Effort**: TBD
- **Status**: [NOT STARTED]
- **Language**: general

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

