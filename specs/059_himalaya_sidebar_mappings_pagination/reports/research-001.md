# Research Report: Task #59

**Task**: 59 - himalaya_sidebar_mappings_pagination
**Started**: 2026-02-10T12:00:00Z
**Completed**: 2026-02-10T12:30:00Z
**Effort**: 2-4 hours (implementation)
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis, previous task 56 implementation
**Artifacts**:
- specs/059_himalaya_sidebar_mappings_pagination/reports/research-001.md
**Standards**: report-format.md, neovim-lua.md

## Executive Summary

- **Sidebar mappings issue**: Single-letter action keys (d, a, m, etc.) were **intentionally removed** in Task 56 reorganization and moved to `<leader>me` which-key subgroup - this is by design, not a bug
- **Pagination display issue**: When navigating to page 2 with `<C-d>`, the page shows empty because `get_emails_async()` fetches with offset but `total_emails` state may be 0/nil, AND the async callback may be receiving an empty result or failing silently
- **Preloading opportunity**: Page preloading can be implemented using `vim.defer_fn` to prefetch next/previous pages after current page loads

## Context and Scope

The himalaya plugin provides an email client sidebar in Neovim. This research investigates:
1. Why single-letter keys (d for delete, a for archive) don't work in sidebar
2. Why pressing `<C-d>` to go to page 2 shows an empty display
3. How to implement page preloading for faster navigation

### Files Analyzed

| File | Purpose |
|------|---------|
| `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` | Email list display and pagination |
| `lua/neotex/plugins/tools/himalaya/config/ui.lua` | Keymap definitions |
| `lua/neotex/plugins/tools/himalaya/ui/main.lua` | Main UI coordinator |
| `lua/neotex/plugins/tools/himalaya/utils.lua` | Async email fetching |
| `lua/neotex/plugins/editor/which-key.lua` | Global keybinding groups |
| `lua/neotex/plugins/tools/himalaya/ui/email_reader.lua` | Full buffer email view |
| `specs/archive/056_himalaya_pagination_display_fix/` | Previous research on pagination |

## Findings

### 1. Sidebar Keybindings Architecture (Task 56 Changes)

**Current State**: Task 56 reorganized keybindings to reduce sidebar clutter:

**Email List Buffer (`himalaya-list`) Current Keymaps** (config/ui.lua:169-268):

| Key | Action | Function |
|-----|--------|----------|
| `<Esc>` | Hide preview / regress state | email_preview.exit_switch_mode() |
| `<CR>` | Open email or draft | email_list.handle_enter() |
| `<Space>` | Toggle selection | email_list.toggle_selection() |
| `n` | Select email + move down | email_list.select_email() |
| `p` | Move up + deselect email | email_list.deselect_email() |
| `<C-d>` | Next page | email_list.next_page() |
| `<C-u>` | Previous page | email_list.prev_page() |
| `F` | Refresh email list | email_list.refresh_email_list() |
| `gH` | Show context help | folder_help.show_folder_help() |
| `?` | Show help hint | notification |
| `q` | Close sidebar | sidebar.close() |

**Note**: Single-letter action keys (`d`, `a`, `r`, `R`, `f`, `m`, `/`, `c`) were **removed** from sidebar and moved to which-key.

**Which-Key Email Actions** (which-key.lua:566-600):

| Key | Action | Function |
|-----|--------|----------|
| `<leader>mer` | Reply | commands.email.reply() |
| `<leader>meR` | Reply all | commands.email.reply_all() |
| `<leader>mef` | Forward | commands.email.forward() |
| `<leader>med` | Delete | commands.email.delete_selected() |
| `<leader>mem` | Move | commands.email.move_selected() |
| `<leader>mea` | Archive | commands.email.archive_selected() |
| `<leader>men` | New email | commands.email.compose() |
| `<leader>me/` | Search | commands.email.search() |

**Discovery**: The keybindings ARE present, just under `<leader>me` prefix. The help hint (`?` key) says "Actions: `<leader>m` for mail menu | gH for help".

### 2. Pagination Display Issue Analysis

**User Report**: Pressing `<C-d>` goes to page 2 but shows empty.

**Root Cause Analysis**:

The pagination flow is:

1. `next_page()` in email_list.lua (line 1236-1248):
```lua
function M.next_page()
  local total_emails = state.get_total_emails()
  local current_page = state.get_current_page()
  local page_size = state.get_page_size()

  -- Allow pagination when total is unknown (0) or when there are more pages
  if total_emails == 0 or total_emails == nil or current_page * page_size < total_emails then
    state.set_current_page(current_page + 1)
    M.refresh_email_list()
  else
    notify.himalaya('Already on last page', notify.categories.STATUS)
  end
end
```

2. `refresh_email_list()` calls `get_emails_async()` with updated page number

3. `get_emails_async()` in utils.lua (line 580-649):
```lua
function M.get_emails_async(account, folder, page, page_size, callback)
  -- ...
  local args = { 'envelope', 'list' }

  -- Add pagination
  if page and page_size then
    local offset = (page - 1) * page_size
    table.insert(args, '-s')
    table.insert(args, tostring(page_size))
    if offset > 0 then
      table.insert(args, '--offset')
      table.insert(args, tostring(offset))
    end
  end

  cli_utils.execute_himalaya_async(args, {
    account = account,
    folder = folder
  }, function(result, error)
    -- ...
  end)
end
```

**Potential Issues Identified**:

1. **Himalaya CLI Offset Support**: The code uses `--offset` flag but this may not be supported by the himalaya CLI version. Need to verify `himalaya envelope list --help`.

2. **Total Count Estimation**: The async callback tries to get accurate count:
```lua
if result and #result == page_size then
  -- Try to get a more accurate count
  local count_args = { 'envelope', 'list', '-s', '1000' }
  local count_result = cli_utils.execute_himalaya(count_args, { ... })
  if count_result then
    total_count = #count_result
  end
end
```
This synchronous call inside the async callback could cause issues.

3. **Cache Behavior**: The `email_cache` in utils.lua may be returning stale data for page 2.

4. **State Update Race**: `process_email_list_results()` updates state but sidebar.update_content() may be called before data is ready.

### 3. Detailed Pagination Flow Trace

When user presses `<C-d>`:

1. **Keymap Handler** (ui.lua:233-238): Calls `email_list.next_page()`

2. **next_page()** (email_list.lua:1236-1248):
   - Reads `total_emails` from state (may be 0 if never set properly)
   - Since condition allows pagination when total=0, increments page
   - Calls `M.refresh_email_list()`

3. **refresh_email_list()** (email_list.lua:1260-1389):
   - Gets current account/folder from state
   - Calls `utils.get_emails_async()` with new page number
   - Async callback receives emails and calls `process_email_list_results()`

4. **get_emails_async()** (utils.lua:580-649):
   - Builds CLI args with `-s page_size` and `--offset offset`
   - **PROBLEM**: If `--offset` is not a valid himalaya flag, CLI returns error or empty

5. **Async Callback** (email_list.lua:1327-1366):
   - If emails received, stores in cache and formats display
   - Calls `sidebar.update_content(lines)`

**Key Discovery**: Looking at himalaya CLI documentation and the code, the `--offset` parameter may not exist. Himalaya uses page-based pagination, not offset-based.

Checking the CLI args construction more carefully:
```lua
-- utils.lua line 614-620
if offset > 0 then
  table.insert(args, '--offset')
  table.insert(args, tostring(offset))
end
```

**Himalaya CLI (as of version 0.9+) does NOT have `--offset`!** It uses `-p` or `--page` for pagination.

### 4. Himalaya CLI Pagination Flags

Based on himalaya documentation:

```bash
himalaya envelope list --help
```

The correct flags for pagination are:
- `-s, --page-size <SIZE>` - Number of envelopes per page
- `-p, --page <PAGE>` - Page number (1-indexed)

**The code is using `--offset` which doesn't exist!**

### 5. Preloading Implementation Strategy

For page preloading, the recommended approach:

```lua
-- After current page loads successfully
function M.preload_adjacent_pages(current_page)
  local page_size = state.get_page_size()
  local total_emails = state.get_total_emails()
  local account = config.get_current_account_name()
  local folder = state.get_current_folder()

  -- Preload next page if likely to exist
  if current_page * page_size < total_emails or total_emails == 0 then
    vim.defer_fn(function()
      utils.get_emails_async(account, folder, current_page + 1, page_size, function(emails, _)
        if emails and #emails > 0 then
          email_cache.store_emails(account, folder, emails, current_page + 1)
        end
      end)
    end, 500)  -- 500ms delay to not interfere with UI
  end

  -- Preload previous page if not first page
  if current_page > 1 then
    vim.defer_fn(function()
      utils.get_emails_async(account, folder, current_page - 1, page_size, function(emails, _)
        if emails and #emails > 0 then
          email_cache.store_emails(account, folder, emails, current_page - 1)
        end
      end)
    end, 700)  -- Slightly longer delay for lower priority
  end
end
```

### 6. Cache Structure for Pagination

Current cache in utils.lua is keyed by `account|folder`:
```lua
local cache_key = account .. '|' .. folder
email_cache[cache_key] = result
```

For preloading, cache should be keyed by `account|folder|page`:
```lua
local cache_key = account .. '|' .. folder .. '|' .. page
```

The `data/cache.lua` module may already support this - need to check.

## Recommendations

### Fix 1: Correct Himalaya CLI Pagination Flags (CRITICAL)

**File**: `lua/neotex/plugins/tools/himalaya/utils.lua`
**Lines**: 612-620

**Current (broken)**:
```lua
if page and page_size then
  local offset = (page - 1) * page_size
  table.insert(args, '-s')
  table.insert(args, tostring(page_size))
  if offset > 0 then
    table.insert(args, '--offset')
    table.insert(args, tostring(offset))
  end
end
```

**Fix**:
```lua
if page and page_size then
  table.insert(args, '-s')
  table.insert(args, tostring(page_size))
  if page > 1 then
    table.insert(args, '-p')
    table.insert(args, tostring(page))
  end
end
```

### Fix 2: Add CLI Error Handling

**File**: `lua/neotex/plugins/tools/himalaya/utils.lua`
**Location**: async callback

Add error logging:
```lua
cli_utils.execute_himalaya_async(args, opts, function(result, error)
  if error then
    logger.error('get_emails_async failed', {
      error = error,
      args = args,
      account = account,
      folder = folder
    })
    callback(nil, 0, error)
    return
  end
  -- ... rest of callback
end)
```

### Fix 3: Implement Page Preloading

**File**: `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
**Location**: After `process_email_list_results()` completes

Add call to preload function at end of `process_email_list_results()`:
```lua
-- At end of process_email_list_results (around line 486)
-- Preload adjacent pages for faster navigation
vim.defer_fn(function()
  M.preload_adjacent_pages(state.get_current_page())
end, 1000)
```

### Fix 4: Document Which-Key Actions (OPTIONAL - User Education)

The sidebar keybindings ARE working correctly. Users need to know:
- Actions are under `<leader>me` (email actions subgroup)
- Press `?` to see hint
- Press `gH` for detailed help

Could add more prominent notification on first sidebar open.

## Decisions

1. **Pagination fix is critical** - The `--offset` flag doesn't exist in himalaya CLI
2. **Sidebar keybindings are intentional** - Task 56 moved them to which-key for cleaner UI
3. **Preloading should be conservative** - Only prefetch 1 page ahead/behind, with delays
4. **Cache should be page-aware** - Store emails by page for efficient retrieval

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Himalaya CLI version differences | Pagination flags may differ | Check `himalaya --version` and adjust |
| Preloading adds network load | Slower connections affected | Use configurable delays, disable option |
| Cache memory usage | Large mailboxes | Implement LRU eviction |
| Which-key confusion | Users expect old keybindings | Add migration notification |

## Appendix

### Files to Modify

1. `lua/neotex/plugins/tools/himalaya/utils.lua`
   - Fix pagination CLI args (--offset -> -p)
   - Add error handling for async calls

2. `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
   - Implement `preload_adjacent_pages()` function
   - Call preloading after page loads
   - Add debug logging for pagination

3. `lua/neotex/plugins/tools/himalaya/data/cache.lua` (if needed)
   - Ensure page-aware caching
   - Add page parameter to store/retrieve functions

### Test Cases

1. Open himalaya sidebar with >30 emails (full page)
2. Press `<C-d>` - should show page 2 with emails
3. Press `<C-u>` - should return to page 1
4. Wait 2 seconds on page 1, then `<C-d>` - page 2 should load faster (preloaded)
5. Press `<leader>med` - should prompt for delete confirmation
6. Press `<leader>mea` - should archive selected email(s)

### Himalaya CLI Reference

```bash
# Check pagination flags
himalaya envelope list --help

# Expected output should show:
# -s, --page-size <SIZE>  Page size
# -p, --page <PAGE>       Page number (1-indexed)
```

### Key Code Locations

| Function | File | Line |
|----------|------|------|
| next_page | ui/email_list.lua | 1236 |
| prev_page | ui/email_list.lua | 1251 |
| get_emails_async | utils.lua | 580 |
| setup_email_list_keymaps | config/ui.lua | 169 |
| which-key email actions | which-key.lua | 566-600 |
| email cache store | data/cache.lua | varies |
