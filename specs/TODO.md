---
next_project_number: 65
---

# TODO

## Tasks

### 64. Fix remaining himalaya keymap issues
- **Effort**: 2-3 hours
- **Status**: [NOT STARTED]
- **Language**: neovim
- **Dependencies**: None

**Description**: Fix remaining himalaya sidebar keymap errors after task 63: (1) 'm' (move) throws nil method 'lower' error at main.lua:1502, (2) 'd', 'r', 'R' produce errors, (3) '/' (search) throws invalid key: buffer at search.lua:781, (4) 'c' composes but no mapping exists to send email, (5) help menu shows inappropriate leader-based mappings when <Space> is used for selection toggle. Investigate root causes and implement elegant refactor to fix all issues.

### 63. Fix himalaya keymap errors and help menu
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-10
- **Completed**: 2026-02-11
- **Research**: [research-001.md](063_fix_himalaya_keymap_errors/reports/research-001.md)
- **Plan**: [implementation-001.md](063_fix_himalaya_keymap_errors/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260211.md](063_fix_himalaya_keymap_errors/summaries/implementation-summary-20260211.md)

**Description**: Task 62 restored single-letter keymaps but they produce errors: "No email to reply to", "Himalaya command failed", "No email to forward". The help menu also doesn't show the right information. Systematically fix all keymap function calls to work correctly (verify function signatures, context requirements, state management) and update the help menu to display accurate keybinding information.

### 62. Fix broken himalaya commands (d, a, ?)
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-10
- **Completed**: 2026-02-10
- **Research**: [research-002.md](062_himalaya_broken_commands_fix/reports/research-002.md)
- **Plan**: [implementation-001.md](062_himalaya_broken_commands_fix/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260210.md](062_himalaya_broken_commands_fix/summaries/implementation-summary-20260210.md)

**Description**: Many himalaya commands don't work in the email list view: 'd' for delete, 'a' for archive, '?' for help, 'r' for reply, etc. Task 60 implemented show_help function but the action keys are still not functional. These were moved to <leader>me prefix in Task 56 but users need either: (1) single-letter convenience keys restored in email list, or (2) clear visual indication and easy access to the <leader>me menu. Verify which keys should work where and ensure they're properly mapped.

### 61. Fix himalaya pagination delay for instant C-d/C-u
- **Effort**: 3-4 hours
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-10
- **Completed**: 2026-02-10
- **Research**: [research-001.md](061_himalaya_pagination_delay_fix/reports/research-001.md)
- **Plan**: [implementation-001.md](061_himalaya_pagination_delay_fix/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260210.md](061_himalaya_pagination_delay_fix/summaries/implementation-summary-20260210.md)

**Description**: The C-d and C-u pagination keys still have a slight delay and don't feel snappy despite the preloading implementation in task 60. The page switching should be instantaneous with no perceptible delay. Investigate and eliminate any remaining delays in the pagination flow (e.g., UI updates, state management, async callbacks).

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

