# Implementation Plan: Task #62 - Fix Broken Himalaya Commands

- **Task**: 62 - himalaya_broken_commands_fix
- **Status**: [NOT STARTED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-002.md](../reports/research-002.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

Restore single-letter action keymaps (d, a, r, R, f, m, c, /) to the himalaya email list buffer. These keys were removed in Task 56 to redirect to `<leader>me` which-key menu, but this approach is fundamentally broken because `<Space>` (the leader key) is already used for toggle selection in the email list. Research confirmed all required functions exist in `ui/main.lua` and are ready to be mapped.

### Research Integration

- Analyzed current keymaps in `config/ui.lua` (lines 169-268)
- Verified all action functions exist in `ui/main.lua` with line numbers
- Confirmed no conflicts with existing keymaps (q, n, p, Space, CR)
- Selection-aware functions already handle batch vs single operations

## Goals & Non-Goals

**Goals**:
- Restore single-letter action keymaps in email list buffer
- Make `?` key show the full help window instead of a notification
- Update `get_keybinding()` table to reflect new keymaps

**Non-Goals**:
- Fixing the `<leader>me` which-key section (optional, deferred)
- Adding new email actions beyond what was originally available
- Modifying sidebar keymaps

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Key conflicts with vim motions | Low | Low | All chosen keys (d, a, r, R, f, m, c, /) are safe in non-editable buffer |
| `a` conflicts with sidebar account switch | Low | None | Different filetypes (himalaya-list vs himalaya-sidebar) |
| Function signature changes | Medium | Low | Use pcall for safe require, check function exists before calling |

## Implementation Phases

### Phase 1: Add Action Keymaps [NOT STARTED]

**Goal**: Add the missing single-letter action keymaps to `setup_email_list_keymaps()` function

**Tasks**:
- [ ] Add delete keymap (d) - selection-aware
- [ ] Add archive keymap (a) - selection-aware
- [ ] Add reply keymap (r)
- [ ] Add reply-all keymap (R)
- [ ] Add forward keymap (f)
- [ ] Add move keymap (m) - selection-aware
- [ ] Add compose keymap (c)
- [ ] Add search keymap (/)

**Timing**: 30-45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Add keymaps after line 267 (before closing `end` of `setup_email_list_keymaps()`)

**Code to add** (after line 267, before the closing `end`):

```lua
  -- Email action keymaps (restored for single-key access)
  -- Delete emails (selection-aware)
  keymap('n', 'd', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if state.is_selection_mode() and #state.get_selected_emails() > 0 then
        main.delete_selected_emails()
      else
        main.delete_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Delete email(s)' }))

  -- Archive emails (selection-aware)
  keymap('n', 'a', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if state.is_selection_mode() and #state.get_selected_emails() > 0 then
        main.archive_selected_emails()
      else
        main.archive_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Archive email(s)' }))

  -- Reply to current email
  keymap('n', 'r', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.reply_current_email then
      main.reply_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply' }))

  -- Reply all to current email
  keymap('n', 'R', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.reply_all_current_email then
      main.reply_all_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Reply all' }))

  -- Forward current email
  keymap('n', 'f', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.forward_current_email then
      main.forward_current_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Forward' }))

  -- Move emails (selection-aware)
  keymap('n', 'm', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok then
      local state = require('neotex.plugins.tools.himalaya.core.state')
      if state.is_selection_mode() and #state.get_selected_emails() > 0 then
        main.move_selected_emails()
      else
        main.move_current_email()
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Move email(s)' }))

  -- Compose new email
  keymap('n', 'c', function()
    local ok, main = pcall(require, 'neotex.plugins.tools.himalaya.ui.main')
    if ok and main.compose_email then
      main.compose_email()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Compose new email' }))

  -- Search emails
  keymap('n', '/', function()
    local ok, search = pcall(require, 'neotex.plugins.tools.himalaya.data.search')
    if ok and search.show_search_ui then
      search.show_search_ui()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Search emails' }))
```

**Verification**:
- Open himalaya sidebar and view email list
- Press `?` to see keybinding help (should show new keys)
- Verify d, a, r, R, f, m, c, / keys are shown in help

---

### Phase 2: Update Help and Keybinding Table [NOT STARTED]

**Goal**: Update the `?` key to show full help window and update `get_keybinding()` table

**Tasks**:
- [ ] Replace `?` keymap to show `folder_help.show_folder_help()` instead of notification
- [ ] Update `keybindings` table in `get_keybinding()` function to include new keys

**Timing**: 20-30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Lines 264-267 (replace `?` mapping) and around line 403 (update keybindings table)

**Code changes**:

1. Replace the `?` keymap (lines 264-267) with:
```lua
  -- Show keybinding help
  keymap('n', '?', function()
    local ok, folder_help = pcall(require, 'neotex.plugins.tools.himalaya.ui.folder_help')
    if ok and folder_help.show_folder_help then
      folder_help.show_folder_help()
    end
  end, vim.tbl_extend('force', opts, { desc = 'Show keybindings help' }))
```

2. Update the `keybindings` table in `get_keybinding()` (around line 403) to include:
```lua
    ['himalaya-list'] = {
      open = '<CR>',
      toggle_select = '<Space>',
      select = 'n',
      deselect = 'p',
      next_page = '<C-d>',
      prev_page = '<C-u>',
      refresh = 'F',
      close = 'q',
      help = '?',
      -- Action keys (restored)
      delete = 'd',
      archive = 'a',
      reply = 'r',
      reply_all = 'R',
      forward = 'f',
      move = 'm',
      compose = 'c',
      search = '/'
    },
```

**Verification**:
- Press `?` in email list buffer to see help window
- Verify new keybindings are shown in the help window

---

### Phase 3: Verification and Testing [NOT STARTED]

**Goal**: Verify all keymaps work correctly

**Tasks**:
- [ ] Test single email operations (d, a, r, R, f, m on single email)
- [ ] Test batch operations (select multiple with Space/n, then d, a, m)
- [ ] Test compose (c) and search (/)
- [ ] Test help display (?)
- [ ] Verify no keymap conflicts with existing functionality

**Timing**: 15-20 minutes

**Verification**:
- Open himalaya sidebar
- View email list for any folder
- Test each key individually
- Test selection mode with batch operations
- Verify help window shows all keybindings

**Verification commands**:
```bash
# Test that module loads without errors
nvim --headless -c "lua require('neotex.plugins.tools.himalaya').setup({})" -c "q"

# Verify keymaps are registered (check in headless mode)
nvim --headless -c "lua local ui = require('neotex.plugins.tools.himalaya.config.ui'); print(vim.inspect(ui.get_keybinding('himalaya-list')))" -c "q"
```

## Testing & Validation

- [ ] Module loads without errors in headless mode
- [ ] Keybindings table includes all new keys
- [ ] `?` shows folder help window (not notification)
- [ ] Single-email operations work (d, a, r, R, f, m, c)
- [ ] Batch operations work with selection mode (d, a, m)
- [ ] Search (/) opens search UI
- [ ] No conflicts with existing keymaps (q, n, p, Space, CR, F)

## Artifacts & Outputs

- Modified: `lua/neotex/plugins/tools/himalaya/config/ui.lua`
- Plan: `specs/062_himalaya_broken_commands_fix/plans/implementation-001.md`
- Summary: `specs/062_himalaya_broken_commands_fix/summaries/implementation-summary-20260210.md` (after completion)

## Rollback/Contingency

If keymaps cause issues:
1. Revert changes to `config/ui.lua` using git
2. The keymaps are buffer-local, so restarting nvim clears any cached state
3. Previous behavior (notification for `?`, no action keys) is restored immediately

Note: Changes are isolated to the himalaya plugin and do not affect global keymaps.
