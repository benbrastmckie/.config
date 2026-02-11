---
next_project_number: 61
---

# TODO

## Tasks

### 60. Fix himalaya post-task 59 issues
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-10
- **Completed**: 2026-02-10
- **Research**: [research-001.md](060_fix_himalaya_post_task59_issues/reports/research-001.md)
- **Plan**: [implementation-001.md](060_fix_himalaya_post_task59_issues/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260210.md](060_fix_himalaya_post_task59_issues/summaries/implementation-summary-20260210.md)

**Description**: Fix remaining himalaya issues from task 59: (1) String format error in sync/manager.lua:271 where fetch_folder_count() returns string "1000+" but string.format expects number - need to handle string counts or convert to number. (2) '?' key doesn't work in sidebar - keymap calls commands.show_help('sidebar') but function doesn't exist, should implement show_help or show notification with available keys. (3) Action keys ('d', 'a', 'r') don't work in email list - were moved to <leader>me prefix in Task 56 but no indication to user, need to make which-key menu more discoverable or restore single-letter keys. (4) Page preloading delay uses 1000ms defer_fn, could be reduced to 300-500ms for better UX.

### 59. Fix himalaya sidebar mappings and pagination display
- **Effort**: TBD
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-10
- **Completed**: 2026-02-10
- **Research**: [research-001.md](059_himalaya_sidebar_mappings_pagination/reports/research-001.md)
- **Plan**: [implementation-001.md](059_himalaya_sidebar_mappings_pagination/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260210.md](059_himalaya_sidebar_mappings_pagination/summaries/implementation-summary-20260210.md)

**Description**: Fix himalaya sidebar mappings that don't work (d for delete, a for archive, etc.), fix pagination display issue where <C-d> goes to page 2 but shows empty, and implement page preloading for faster switching.

