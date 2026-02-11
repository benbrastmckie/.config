# Research Report: Task 60

**Task**: 60 - fix_himalaya_post_task59_issues
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:10:00Z
**Effort**: 1-2 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**: specs/060_fix_himalaya_post_task59_issues/reports/research-001.md
**Standards**: report-format.md, neovim-research-agent

## Executive Summary

- Issue 1: `fetch_folder_count()` returns string "1000+" when count exceeds binary search limit, but `string.format()` expects a number
- Issue 2: `show_help()` function is called in sidebar keymaps but does not exist in commands/ui.lua
- Issue 3: Action keys (d/a/r) were intentionally moved to `<leader>me` prefix in task 56/59, users need better discoverability
- Issue 4: Preload delay is set to 1000ms in email_list.lua:494, could be reduced to 500ms

## Context & Scope

This research investigates four issues that emerged after task 59 implementation:

1. **String format error**: `sync/manager.lua:271` uses `%d` format specifier with a value that can be string "1000+"
2. **Missing show_help function**: Sidebar '?' keymap calls `commands.show_help('sidebar')` but the function doesn't exist
3. **Action key discoverability**: Users expect d/a/r keys to work in email list, but they were moved to `<leader>me` prefix
4. **Preload delay**: 1000ms delay before preloading adjacent pages may be excessive

## Findings

### Issue 1: String Format Error in fetch_folder_count

**Location**: `sync/manager.lua:266-273` and `utils.lua:432-478`

**Root Cause**:
- `utils.fetch_folder_count()` performs binary search to determine folder email count
- When count exceeds 10,000 emails, it returns `last_known_count .. '+'` (e.g., "1000+")
- Line 477: `return last_known_count .. '+'`
- This string value is passed to `string.format()` with `%d` format specifier

**Affected Code** (sync/manager.lua:270-273):
```lua
state.set_folder_count(current_account, current_folder, count)
logger.debug(string.format('Updated folder count after sync: %s/%s = %d',
  current_account, current_folder, count))
notify.himalaya(string.format('Updated count: %s/%s = %d', current_account, current_folder, count), notify.categories.BACKGROUND)
```

**Note**: `state.set_folder_count()` already handles this by doing `count = tonumber(count) or 0` (state.lua:433), but the logging/notification uses `%d` before that conversion.

**Fix Strategy**:
- Option A: Change `%d` to `%s` in string.format calls (allows "1000+" display)
- Option B: Convert to number before logging, use "1000+" only for display
- Option C: Modify `fetch_folder_count()` to return a table `{count=N, approximate=bool}`

Recommended: Option A - simpler and preserves the "1000+" indicator for users

### Issue 2: Missing show_help Function

**Location**: `config/ui.lua:391-396` (sidebar keymaps)

**Current Code**:
```lua
keymap('n', '?', function()
  local ok, commands = pcall(require, 'neotex.plugins.tools.himalaya.commands.ui')
  if ok and commands.show_help then
    commands.show_help('sidebar')
  end
end, vim.tbl_extend('force', opts, { desc = 'Show help' }))
```

**Problem**: `commands.ui` does not export a `show_help` function. The file has been searched and no such function exists.

**Similar Pattern Exists In**:
- compose keymaps (config/ui.lua:345-350): Same issue with `commands.show_help('compose')`
- sidebar keymaps (config/ui.lua:391-396): Same issue with `commands.show_help('sidebar')`

**Note**: Email list keymaps (config/ui.lua:264-267) use a different approach:
```lua
keymap('n', '?', function()
  local notify = require('neotex.util.notifications')
  notify.himalaya('Actions: <leader>med (delete) | <leader>mea (archive) | <leader>mer (reply) | gH for full help', notify.categories.STATUS)
end, vim.tbl_extend('force', opts, { desc = 'Show help hint' }))
```

**Fix Strategy**:
- Option A: Implement `show_help(context)` in commands/ui.lua that displays context-aware help
- Option B: Use same notification pattern as email_list keymaps (simpler)
- Option C: Delegate to existing `ui/folder_help.lua:show_folder_help()` which already exists

Recommended: Option B for consistency with email_list, or Option C for richer help

### Issue 3: Action Keys Not Working

**Intentional Design**: Per task 56 and 59, action keys were intentionally moved to `<leader>me` prefix.

**Current Configuration** (config/ui.lua:402-422):
```lua
local keybindings = {
  ['himalaya-list'] = {
    open = '<CR>',
    toggle_select = '<Space>',
    select = 'n',
    deselect = 'p',
    next_page = '<C-d>',
    prev_page = '<C-u>',
    refresh = 'F',
    close = 'q',
    help = 'gH',
    help_hint = '?'
    -- Actions removed: use <leader>m menu
  },
```

**which-key Integration** (which-key.lua:567-599):
- `<leader>me` - email actions group (visible in himalaya-list and himalaya-email buffers)
- `<leader>mer` - reply
- `<leader>meR` - reply all
- `<leader>mef` - forward
- `<leader>med` - delete
- `<leader>mem` - move
- `<leader>mea` - archive
- `<leader>men` - new email
- `<leader>me/` - search

**Discoverability Issues**:
1. '?' key shows hint but help message could be clearer
2. Users familiar with other email clients expect single-letter shortcuts
3. The help hint is shown via notification which disappears

**Fix Strategy**:
- Option A: Add single-letter shortcuts back with buffer-local scope (regression)
- Option B: Improve help hint message to be more prominent
- Option C: Add a persistent status line showing available actions
- Option D: Make 'gH' more discoverable (show it in '?' message)

Recommended: Option B - improve '?' help hint to clearly show `<leader>me` prefix and `gH` for full help

### Issue 4: Preload Delay

**Location**: `ui/email_list.lua:491-494`

**Current Code**:
```lua
-- Preload adjacent pages for faster navigation
vim.defer_fn(function()
  M.preload_adjacent_pages(state.get_current_page())
end, 1000)
```

**Additional Delays in preload_adjacent_pages()** (lines 507, 518):
- Next page preload: 500ms delay
- Previous page preload: 700ms delay

**Total Delays**:
- Next page: 1000ms + 500ms = 1500ms after initial load
- Previous page: 1000ms + 700ms = 1700ms after initial load

**Rationale for Current Values**:
- Initial 1000ms: Let main content render first
- Staggered delays: Prevent network congestion

**Fix Strategy**:
- Reduce initial delay from 1000ms to 500ms (or even 300ms)
- Keep staggered delays for adjacent pages (500ms/700ms)
- This reduces total preload time by 500-700ms

Recommended: Reduce initial delay to 500ms. Total times would become:
- Next page: 500ms + 500ms = 1000ms
- Previous page: 500ms + 700ms = 1200ms

## Recommendations

### Priority Order

1. **Issue 1 (String format)**: High priority - causes runtime errors
2. **Issue 2 (Missing show_help)**: Medium priority - silent failure, confusing UX
3. **Issue 3 (Action keys)**: Low priority - intentional design, needs UX polish
4. **Issue 4 (Preload delay)**: Low priority - performance optimization

### Implementation Plan

**Phase 1: Fix String Format Error**
- File: `sync/manager.lua`
- Change: Replace `%d` with `%s` in lines 271-273
- Also check: Other uses of `fetch_folder_count` return value

**Phase 2: Fix show_help Function**
- File: `config/ui.lua`
- Option A (Simple): Replace `commands.show_help()` calls with notification pattern from email_list
- Option B (Complete): Create `M.show_help(context)` function in commands/ui.lua

**Phase 3: Improve Help Hint**
- File: `config/ui.lua`
- Improve the '?' key notification message
- Make it clear that actions are under `<leader>me`

**Phase 4: Reduce Preload Delay**
- File: `ui/email_list.lua`
- Change line 494: `end, 1000)` to `end, 500)`

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| String format change could affect logging parsers | Review any log analysis tools first |
| Reducing preload delay could cause UI lag | Monitor performance, have easy rollback |
| show_help changes could regress compose/sidebar | Test all three contexts (list, compose, sidebar) |

## Appendix

### Files Analyzed

| File | Purpose | Issues Found |
|------|---------|--------------|
| sync/manager.lua | Sync orchestration | Issue 1 |
| utils.lua | Utility functions | Issue 1 (source) |
| config/ui.lua | Keymap configuration | Issues 2, 3, 4 |
| commands/ui.lua | UI commands | Missing show_help |
| ui/email_list.lua | Email list display | Issue 4 |
| which-key.lua | Keybinding display | Context for Issue 3 |

### Search Queries Used

- `fetch_folder_count` - Found return type issue
- `show_help` - Confirmed function doesn't exist
- `defer_fn.*1000` - Found preload delay locations
- `<leader>me` - Understood action key architecture
