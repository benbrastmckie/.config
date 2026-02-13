---
next_project_number: 74
---

# TODO

## Tasks

### 73. Fix which-key conditional mappings not displaying for compose-specific keybindings
- **Effort**: TBD
- **Status**: [NOT STARTED]
- **Language**: neovim
- **Dependencies**: None

**Description**: Compose-specific keybindings (`<leader>me`, `<leader>md`, `<leader>mq`) do not appear in which-key menu when composing emails, despite fixes implemented in task 52. Expected: When pressing `<leader>m` in a compose buffer, should see: e → send email, d → save draft, q → quit/discard. Actual: Only base mail commands appear (switch account, change folder, toggle sidebar, sync, etc.). Diagnostics completed: filetype is correct (mail), condition function works (`vim.tbl_contains({ "mail", "himalaya-compose" }, vim.bo.filetype)` returns true), Neovim restarted after changes, `is_mail()` helper updated to include both filetypes. Hypothesis: The `cond` parameter syntax may be incorrect for which-key v3 - may need `cond = function() return is_mail() end` instead of `cond = is_mail`.

### 72. Fix himalaya sidebar help showing leader keybindings that conflict with toggle selection
- **Effort**: TBD
- **Status**: [NOT STARTED]
- **Language**: neovim
- **Dependencies**: None

**Description**: Fix himalaya sidebar help display (shown via '?') incorrectly showing leader keybindings (`<leader>mA` - Switch account, `<leader>mf` - Change folder, `<leader>ms` - Sync folder) in the Folder Management section. These leader commands should not be accessible or defined in the sidebar since `<leader>` is `<Space>` which is used for toggle selections in that buffer.

### 71. Refactor himalaya keybindings to flatten email actions and eliminate leader me group conflicts
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Started**: 2026-02-12
- **Completed**: 2026-02-12
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](071_refactor_himalaya_keybindings_flatten_email_actions/reports/research-001.md)
- **Plan**: [implementation-001.md](071_refactor_himalaya_keybindings_flatten_email_actions/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260212.md](071_refactor_himalaya_keybindings_flatten_email_actions/summaries/implementation-summary-20260212.md)

**Description**: Refactor himalaya keybindings to flatten email actions and eliminate `<leader>me` group conflicts. Remove the `<leader>me` subgroup and flatten all email actions to 2-letter sequences. Coordinate keymaps across sidebar (single-letter), email list (single-letter), preview (`<leader>m`), and compose (`<leader>m`) buffers. Key changes: `<leader>mA` for switch account, `<leader>mc` for change folder globally, `<leader>mf` for forward in email contexts, `<leader>ma` for archive, `<leader>md` for delete/discard uniformly, `<leader>w` for save draft in compose.

### 70. Fix email_composer setup_compose_keymaps missing leader keymaps
- **Effort**: 30 minutes
- **Status**: [COMPLETED]
- **Started**: 2026-02-12
- **Completed**: 2026-02-12
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](070_fix_email_composer_setup_compose_keymaps/reports/research-001.md)
- **Plan**: [implementation-001.md](070_fix_email_composer_setup_compose_keymaps/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260212.md](070_fix_email_composer_setup_compose_keymaps/summaries/implementation-summary-20260212.md)

**Description**: Add leader keymaps to email_composer.lua setup_compose_keymaps function - task 69 added keymaps to wrong function (config/ui.lua) but email_composer.lua has its own setup_compose_keymaps that shadows it and gets called instead. Need to add `<leader>me`, `<leader>md`, `<leader>mq` keymaps to email_composer.lua lines 134-153.

### 69. Fix compose buffer which-key mappings not appearing
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Started**: 2026-02-12
- **Completed**: 2026-02-12
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](069_fix_compose_buffer_whichkey_mappings/reports/research-001.md)
- **Plan**: [implementation-001.md](069_fix_compose_buffer_whichkey_mappings/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260211.md](069_fix_compose_buffer_whichkey_mappings/summaries/implementation-summary-20260211.md)

**Description**: Fix compose buffer which-key mappings not appearing in popup. The conditional cond parameter in which-key.lua lines 553-557 isn't working - compose-specific mappings (`<leader>me` send, `<leader>md` draft, `<leader>mq` quit) don't show in which-key popup even though is_compose_buffer() returns true in compose buffers. Root cause: which-key's cond parameter doesn't dynamically update the popup display. Solution: Remove conditional which-key registrations and instead set up buffer-local keymaps in config/ui.lua setup_compose_keymaps() using vim.keymap.set() with buffer parameter, same pattern as existing `<C-d>`, `<C-q>`, `<C-a>` shortcuts.

### 68. Fix syntax highlighting interruption on long lines
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Started**: 2026-02-11
- **Completed**: 2026-02-11
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](068_fix_syntax_highlighting_long_lines/reports/research-001.md)
- **Plan**: [implementation-001.md](068_fix_syntax_highlighting_long_lines/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260211.md](068_fix_syntax_highlighting_long_lines/summaries/implementation-summary-20260211.md)

**Description**: Fix syntax highlighting in Neovim that gets interrupted on long lines. When lines are very long (wrapping across multiple screen lines), the syntax highlighting appears to stop mid-line, leaving portions of the text unhighlighted. This is visible in TypeScript files where string highlighting cuts off partway through wrapped lines.

### 67. Review and revise himalaya compose buffer mappings
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Started**: 2026-02-11
- **Completed**: 2026-02-11
- **Language**: neovim
- **Dependencies**: None
- **Research**: [research-001.md](067_review_himalaya_compose_mappings/reports/research-001.md), [research-002.md](067_review_himalaya_compose_mappings/reports/research-002.md)
- **Plan**: [implementation-002.md](067_review_himalaya_compose_mappings/plans/implementation-002.md)
- **Summary**: [implementation-summary-20260211.md](067_review_himalaya_compose_mappings/summaries/implementation-summary-20260211.md)

**Description**: Review and revise himalaya compose buffer mappings to add send email capability and ensure all mappings use maximum two letters (e.g., `<leader>ms` not `<leader>mes`). Current compose buffer lacks a send mapping.

### 66. Fix wezterm tab numbering to use global order matching TTS
- **Effort**: 1-2 hours
- **Status**: [COMPLETED]
- **Language**: general
- **Dependencies**: None
- **Started**: 2026-02-11
- **Completed**: 2026-02-11
- **Research**: [research-001.md](066_fix_wezterm_tab_numbering_global_order/reports/research-001.md)
- **Plan**: [implementation-001.md](066_fix_wezterm_tab_numbering_global_order/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260211.md](066_fix_wezterm_tab_numbering_global_order/summaries/implementation-summary-20260211.md)

**Description**: When Claude Code finishes a task or needs input in neovim, TTS announces the tab number. However, with multiple wezterm windows open, wezterm tracks tab creation order globally but displays per-window tab numbers (each window starts at 1). Research what needs to change to display global tab numbers matching the TTS announcements. Identify which changes belong in .dotfiles/ for NixOS wezterm configuration vs any neovim-side changes.

### 65. Fix task 64 move and send regressions
- **Effort**: 1 hour
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-11
- **Completed**: 2026-02-11
- **Research**: [research-001.md](065_fix_task64_move_and_send_regressions/reports/research-001.md)
- **Plan**: [implementation-001.md](065_fix_task64_move_and_send_regressions/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260211.md](065_fix_task64_move_and_send_regressions/summaries/implementation-summary-20260211.md)

**Description**: Fix himalaya move command showing table addresses instead of folder names (regression from task 64), and change compose send mapping from <C-s> to <leader>m prefix to avoid spelling conflict. The move command needs to extract folder.name from table objects returned by utils.get_folders(), and the send mapping should use <leader>mes (or similar) instead of conflicting with spell-check.

### 64. Fix remaining himalaya keymap issues
- **Effort**: 2-3 hours
- **Status**: [COMPLETED]
- **Language**: neovim
- **Dependencies**: None
- **Started**: 2026-02-11
- **Completed**: 2026-02-11
- **Research**: [research-001.md](064_fix_remaining_himalaya_keymap_issues/reports/research-001.md)
- **Plan**: [implementation-001.md](064_fix_remaining_himalaya_keymap_issues/plans/implementation-001.md)
- **Summary**: [implementation-summary-20260211.md](064_fix_remaining_himalaya_keymap_issues/summaries/implementation-summary-20260211.md)

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

