---
next_project_number: 42
---

# TODO

## Tasks

### 41. Fix leanls LSP client exit error in Neovim
- **Effort**: TBD
- **Status**: [PLANNED]
- **Language**: neovim
- **Research**: [research-001.md](specs/041_fix_leanls_lsp_client_exit_error/reports/research-001.md)
- **Plan**: [implementation-002.md](specs/041_fix_leanls_lsp_client_exit_error/plans/implementation-002.md)

**Description**: Fix leanls LSP client errors when opening Lean files: "Client leanls quit with exit code 1 and signal 0" and "Watchdog error: no such file or directory (error code: 2)". Check LSP log at ~/.local/state/nvim/lsp.log for details.

### 40. Standardize multi-task creation patterns
- **Effort**: 4-6 hours
- **Status**: [COMPLETED]
- **Completed**: 2026-02-03
- **Summary**: [implementation-summary-20260203.md](specs/040_standardize_multi_task_creation_patterns/summaries/implementation-summary-20260203.md)
- **Language**: meta
- **Research**: [research-001.md](specs/040_standardize_multi_task_creation_patterns/reports/research-001.md)
- **Plan**: [implementation-001.md](specs/040_standardize_multi_task_creation_patterns/plans/implementation-001.md)

**Description**: Check all commands/skills/agents that create tasks, ensuring multi-task creators use the interactive selection pattern from /learn (user selects which to create and how to group them). Standardize the dependency display and task creation order pattern from /meta (topological sorting, layered graph visualization). Create a common best practice pattern to be used consistently across: /task --review, /errors, /review, /learn, /meta, and any other multi-task creators.

---

*No other active tasks. Use `/task "description"` to create a new task.*

