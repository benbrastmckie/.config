# Research Report: Task #56

**Task**: 56 - himalaya_pagination_display_fix
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:15:00Z
**Effort**: 1-2 hours (implementation)
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis
**Artifacts**:
- specs/056_himalaya_pagination_display_fix/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- **Pagination display issue**: The `next_page()` function uses a flawed condition that compares against `state.get_total_emails()`, which may return 0 if the total count was never properly stored, blocking pagination entirely
- **'N' keymap conflict**: The 'N' key is NOT mapped as a previous-page binding in `config/ui.lua` - only 'n' (next) and 'p' (previous) are defined, so 'N' falls through to Vim's default behavior (search backwards)
- **Root cause for display**: When `next_page()` does execute, it calls `refresh_email_list()` which should work - the issue is likely that pagination is blocked by the guard condition because `total_emails` is 0

## Context and Scope

The himalaya plugin provides an email client sidebar in Neovim. The research investigates:
1. Why pressing 'n' moves to page 2 but shows no content
2. Why pressing 'N' triggers Vim's search backwards instead of previous page

### Files Analyzed
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Pagination logic
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Keymap definitions
- `lua/neotex/plugins/tools/himalaya/core/state.lua` - State management
- `lua/neotex/plugins/tools/himalaya/utils.lua` - Async email fetching

## Findings

### 1. Keymap Definitions (config/ui.lua)

The email list keymaps are defined in `setup_email_list_keymaps()` (lines 251-263):

```lua
-- Navigation
keymap('n', 'n', function()
  local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
  if ok and email_list.next_page then
    email_list.next_page()
  end
end, vim.tbl_extend('force', opts, { desc = 'Next page' }))

keymap('n', 'p', function()
  local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
  if ok and email_list.prev_page then
    email_list.prev_page()
  end
end, vim.tbl_extend('force', opts, { desc = 'Previous page' }))
```

**Key finding**:
- 'n' is mapped to `next_page()`
- 'p' is mapped to `prev_page()`
- **'N' is NOT defined as a keymap** - there is no keymap for shift+n

This explains why 'N' falls through to Vim's default behavior (search backwards for last pattern).

### 2. Pagination Logic (ui/email_list.lua)

The `next_page()` function at line 1236:

```lua
function M.next_page()
  if state.get_current_page() * state.get_page_size() < state.get_total_emails() then
    state.set_current_page(state.get_current_page() + 1)
    M.refresh_email_list()
  else
    notify.himalaya('Already on last page', notify.categories.STATUS)
  end
end
```

**Problem identified**: The guard condition uses `state.get_total_emails()`. If this returns 0 (no total stored), the condition `current_page * page_size < 0` is false, preventing pagination.

Looking at state.lua line 291:
```lua
function M.get_total_emails()
  return M.get("ui.total_emails", 0)
end
```

Default value is 0, so if `total_emails` was never set, pagination is blocked.

### 3. Total Count Setting (ui/email_list.lua)

The total count is set in `process_email_list_results()` (lines 419-429):

```lua
if total_count and total_count > 0 then
  state.set_total_emails(total_count)

  -- Only store as folder count if it's an exact count (not an estimate)
  local page_size = state.get_page_size()
  if emails and #emails < page_size then
    -- This is the exact total count, store it
    state.set_folder_count(account_name, folder, total_count)
  end
end
```

And in the async callback in `get_emails_async()` (utils.lua lines 631-646):
```lua
local total_count = #(result or {})

-- If we got a full page, there might be more
if result and #result == page_size then
  -- Try to get a more accurate count
  local count_args = { 'envelope', 'list', '-s', '1000' }
  local count_result = cli_utils.execute_himalaya(count_args, {
    account = account,
    folder = folder
  })
  if count_result then
    total_count = #count_result
  end
end
```

**Issue**: The total count is only set if the async callback completes successfully AND returns a positive count. If there's any issue with the count fetching, or if the first page loads but the count fetch fails, `total_emails` remains 0.

### 4. Potential Display Issue

Even if `next_page()` executes:
1. It increments the page number in state
2. Calls `refresh_email_list()`
3. `refresh_email_list()` calls `get_emails_async()` with the new page number
4. The async result should update the sidebar via `sidebar.update_content()`

If content doesn't display, it could be:
- The async callback failing silently
- The offset calculation being incorrect
- The sidebar buffer not being updated

## Recommendations

### Fix 1: Add 'N' keymap for previous page (config/ui.lua)

Add after the 'n' keymap (around line 257):

```lua
keymap('n', 'N', function()
  local ok, email_list = pcall(require, 'neotex.plugins.tools.himalaya.ui.email_list')
  if ok and email_list.prev_page then
    email_list.prev_page()
  end
end, vim.tbl_extend('force', opts, { desc = 'Previous page' }))
```

This gives users intuitive 'n'/'N' for next/previous (matching Vim's search pattern).

### Fix 2: Fix pagination guard condition (ui/email_list.lua)

Replace the strict guard with a more permissive approach:

```lua
function M.next_page()
  local total = state.get_total_emails()
  local current_page = state.get_current_page()
  local page_size = state.get_page_size()

  -- Allow pagination if:
  -- 1. We don't know the total (total == 0 means unknown)
  -- 2. OR there are more pages
  if total == 0 or (current_page * page_size < total) then
    state.set_current_page(current_page + 1)
    M.refresh_email_list()
  else
    notify.himalaya('Already on last page', notify.categories.STATUS)
  end
end
```

### Fix 3: Add debug logging for pagination (ui/email_list.lua)

Add logging to trace the issue:

```lua
function M.next_page()
  local total = state.get_total_emails()
  local current_page = state.get_current_page()
  local page_size = state.get_page_size()

  logger.debug('next_page called', {
    total_emails = total,
    current_page = current_page,
    page_size = page_size,
    can_advance = (total == 0 or current_page * page_size < total)
  })

  -- ... rest of function
end
```

### Fix 4: Ensure total is set on initial load

In `get_emails_async()`, ensure we always attempt to store a reasonable total even if the count fetch fails:

```lua
-- At minimum, use the current page count if we have no total
if not total_count or total_count == 0 then
  total_count = #result
end
callback(result, total_count)
```

## Decisions

1. 'N' should be added as a keymap for previous page to match Vim conventions
2. The pagination guard should allow advancement when total is unknown (0)
3. Both 'n'/'N' and 'p' should work for pagination (n/N for Vim users, p for intuitive previous)

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Allowing pagination when total=0 might go past end | Server returns empty page, UI shows "no emails" |
| Adding 'N' keymap might conflict with other plugins | Buffer-local keymap only applies in himalaya-list buffers |
| Pagination flicker during async load | Already handled by `refresh_email_list()` showing loading state |

## Appendix

### Files to Modify

1. `lua/neotex/plugins/tools/himalaya/config/ui.lua`
   - Add 'N' keymap for previous page (line ~258)

2. `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
   - Fix `next_page()` guard condition (line 1237)
   - Add debug logging for troubleshooting

### Test Cases

1. Open himalaya sidebar with multiple pages of emails
2. Press 'n' - should advance to page 2 and display content
3. Press 'N' or 'p' - should return to page 1
4. On last page, press 'n' - should show "Already on last page"
5. On first page, press 'N' or 'p' - should show "Already on first page"

### Key Code Locations

| Function | File | Line |
|----------|------|------|
| next_page | ui/email_list.lua | 1236 |
| prev_page | ui/email_list.lua | 1245 |
| setup_email_list_keymaps | config/ui.lua | 163 |
| get_emails_async | utils.lua | 580 |
| get_total_emails | core/state.lua | 291 |
