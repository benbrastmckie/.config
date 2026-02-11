# Implementation Plan: Fix Himalaya Post-Task 59 Issues

- **Task**: 60 - fix_himalaya_post_task59_issues
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

This plan addresses four issues discovered after task 59 implementation: a string format error in sync/manager.lua, missing show_help function for sidebar/compose contexts, action key discoverability improvements, and aggressive page preloading optimization. User priority is CRITICAL for responsive pagination with `<C-d>` and `<C-u>` - the goal is instant page switching with no perceptible delay.

### Research Integration

Key findings from research-001.md:
- `fetch_folder_count()` returns "1000+" string when count exceeds binary search limit, causing `%d` format error
- `show_help()` function is called but not implemented in commands/ui.lua
- Action keys (d/a/r) were intentionally moved to `<leader>me` prefix; users need better discoverability
- Preload delays total 1500-1700ms (initial 1000ms + staggered 500ms/700ms)

## Goals & Non-Goals

**Goals**:
- Fix runtime string format error in sync/manager.lua
- Implement show_help function for sidebar and compose contexts
- Improve help hint messaging for action key discoverability
- Achieve near-instant page switching with aggressive preloading

**Non-Goals**:
- Adding back single-letter action shortcuts (intentional design from task 56)
- Restructuring the entire email list navigation system
- Adding persistent status bar (out of scope)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Aggressive preloading causes UI lag | M | L | Monitor performance, add conditional preloading based on page cache |
| String format change affects log parsers | L | L | Use %s which is display-only change |
| Help notifications are too brief | M | M | Make notifications longer duration or use which-key integration |

## Implementation Phases

### Phase 1: Fix String Format Error [NOT STARTED]

**Goal**: Eliminate runtime error when fetch_folder_count returns "1000+" string

**Tasks**:
- [ ] Change `%d` to `%s` in sync/manager.lua lines 271-273
- [ ] Verify `state.set_folder_count()` already handles the string conversion
- [ ] Test with large folder counts (simulated "1000+" scenario)

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/sync/manager.lua` - lines 271-273: change format specifiers

**Verification**:
- `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.sync.manager')" -c "q"` loads without error
- No string format errors in :messages after sync operations

---

### Phase 2: Implement Aggressive Page Preloading [NOT STARTED]

**Goal**: Make `<C-d>` and `<C-u>` pagination feel instant with no perceptible delay

**Tasks**:
- [ ] Reduce initial preload delay from 1000ms to 100ms
- [ ] Reduce next page preload delay from 500ms to 50ms
- [ ] Reduce previous page preload delay from 700ms to 100ms
- [ ] Add immediate preload of both next AND previous pages (bidirectional)
- [ ] Preload 2 pages ahead in each direction when on middle pages
- [ ] Add page cache size check before preloading (avoid redundant fetches)

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - preload_adjacent_pages function and defer_fn delays

**Implementation Details**:
```lua
-- Current: 1000ms initial, 500ms/700ms staggered = 1500-1700ms total
-- Target: 100ms initial, 50ms/100ms staggered = 150-200ms total

-- In render_email_list() after main render:
vim.defer_fn(function()
  M.preload_adjacent_pages(state.get_current_page())
end, 100)  -- Was 1000

-- In preload_adjacent_pages():
-- Next page: 50ms delay (was 500ms)
-- Previous page: 100ms delay (was 700ms)
-- Add: Preload page+2 and page-2 for deeper cache
```

**Verification**:
- `<C-d>` and `<C-u>` feel instant (no visible loading delay)
- Adjacent pages are cached before user navigates
- No UI lag during preloading

---

### Phase 3: Implement show_help Function [NOT STARTED]

**Goal**: Make '?' key work in sidebar and compose contexts

**Tasks**:
- [ ] Create show_help(context) function in commands/ui.lua
- [ ] Implement context-aware help messages for 'sidebar', 'compose', and 'list'
- [ ] Update sidebar keymap to use new function
- [ ] Update compose keymap to use new function
- [ ] Consider using longer notification duration for help messages

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/commands/ui.lua` - add M.show_help function

**Implementation Details**:
```lua
--- Show context-aware help for himalaya buffers
--- @param context string 'sidebar'|'compose'|'list'
function M.show_help(context)
  local notify = require('neotex.util.notifications')
  local messages = {
    sidebar = 'Sidebar: <CR> select folder | q close | ? help | gH full help',
    compose = 'Compose: <C-c> cancel | <leader>mes send | ? help | gH full help',
    list = 'Actions: <leader>med delete | <leader>mea archive | <leader>mer reply | gH full help',
  }
  local msg = messages[context] or messages.list
  notify.himalaya(msg, notify.categories.STATUS)
end
```

**Verification**:
- Press '?' in sidebar buffer - shows help notification
- Press '?' in compose buffer - shows help notification
- No Lua errors when pressing '?'

---

### Phase 4: Improve Action Key Help Messaging [NOT STARTED]

**Goal**: Make it clear that actions are under `<leader>me` prefix

**Tasks**:
- [ ] Update email_list '?' help hint to be more descriptive
- [ ] Include reference to gH for full which-key help
- [ ] Consider adding "Press <leader>m to see all mail actions" hint
- [ ] Use consistent formatting across all help contexts

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - update '?' keymap message (line ~264-267)

**Implementation Details**:
```lua
-- Current (vague):
'Actions: <leader>med (delete) | <leader>mea (archive) | <leader>mer (reply) | gH for full help'

-- Improved (clear prefix emphasis):
'Email Actions under <leader>me: d=delete a=archive r=reply R=reply-all | Press gH for full keybindings'
```

**Verification**:
- Press '?' in email list - shows improved help message
- Help message clearly indicates <leader>me prefix
- gH reference is visible

---

## Testing & Validation

- [ ] Module loads: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya')" -c "q"`
- [ ] Open himalaya list buffer, verify '?' shows help
- [ ] Open himalaya sidebar, verify '?' shows help
- [ ] Navigate with `<C-d>`/`<C-u>`, verify instant page switching
- [ ] Trigger folder count update, verify no string format errors
- [ ] Check :messages for any Lua errors

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-20260210.md (after completion)

## Rollback/Contingency

If aggressive preloading causes issues:
1. Restore original delay values (1000ms, 500ms, 700ms)
2. Add conditional check: only preload if page not in cache
3. Consider user-configurable preload aggressiveness setting

If show_help causes issues:
1. Revert to notification-only pattern from email_list
2. Remove function definition, keep inline notification
