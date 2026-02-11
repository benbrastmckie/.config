# Implementation Plan: Task #59

- **Task**: 59 - himalaya_sidebar_mappings_pagination
- **Status**: [NOT STARTED]
- **Effort**: 2-3 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim

## Overview

This plan addresses three issues with the himalaya email plugin: (1) fixing pagination CLI flags from incorrect `--offset` to correct `-p` (page) flag, (2) documenting that sidebar action keys were intentionally moved to which-key, and (3) implementing page preloading for faster navigation.

### Research Integration

Key findings from research-001.md:
- Himalaya CLI uses `-p` (page) flag, not `--offset` (which doesn't exist)
- Sidebar single-letter keys (d, a, r, etc.) were intentionally moved to `<leader>me` in Task 56
- Preloading can use `vim.defer_fn` with delayed async fetches

## Goals & Non-Goals

**Goals**:
- Fix pagination to correctly fetch page 2+ emails
- Add page preloading for faster navigation
- Improve error handling in async email fetch
- Document the which-key action key location

**Non-Goals**:
- Restoring single-letter action keys to sidebar (they were removed by design)
- Changing the overall keybinding architecture
- Modifying himalaya CLI behavior

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Himalaya CLI version differences | Pagination flags may differ | Low | Check `himalaya --version` compatibility |
| Preloading adds network load | Slower connections affected | Medium | Use configurable delays, conservative prefetch |
| Cache memory usage | Large mailboxes | Low | Existing LRU eviction handles this |

## Implementation Phases

### Phase 1: Fix Pagination CLI Flags [NOT STARTED]

**Goal**: Replace incorrect `--offset` flag with correct `-p` (page) flag in himalaya CLI calls.

**Tasks**:
- [ ] Modify `get_emails_async()` to use `-p` page flag instead of `--offset`
- [ ] Add error logging for CLI failures
- [ ] Verify CLI args construction

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils.lua` (lines 612-620)
  - Replace offset calculation with page flag
  - Add error logging in async callback

**Code Change**:

Current (broken):
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

Fixed:
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

**Verification**:
- Open himalaya sidebar with >30 emails (full first page)
- Press `<C-d>` to go to page 2
- Verify page 2 displays emails (not empty)
- Press `<C-u>` to return to page 1
- Verify page 1 displays correctly

---

### Phase 2: Add CLI Error Handling [NOT STARTED]

**Goal**: Improve error handling in async email fetch to diagnose issues.

**Tasks**:
- [ ] Add error logging when CLI command fails
- [ ] Ensure callback receives proper error state
- [ ] Add debug logging for CLI args

**Timing**: 20 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils.lua` (async callback around line 624-640)
  - Add logger.error call when result is nil or error is set
  - Log CLI args for debugging

**Code Addition**:
```lua
cli_utils.execute_himalaya_async(args, opts, function(result, error)
  if error then
    logger.error('get_emails_async failed', {
      error = error,
      args = args,
      account = account,
      folder = folder,
      page = page
    })
    callback(nil, 0, error)
    return
  end
  -- ... rest of callback
end)
```

**Verification**:
- Test with invalid folder name, verify error logged
- Test normal pagination, verify no spurious errors

---

### Phase 3: Implement Page Preloading [NOT STARTED]

**Goal**: Preload adjacent pages after current page loads for faster navigation.

**Tasks**:
- [ ] Create `preload_adjacent_pages()` function in email_list.lua
- [ ] Call preload function after successful page load
- [ ] Ensure preloaded data goes to cache

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
  - Add `preload_adjacent_pages()` function (new function)
  - Call from end of `process_email_list_results()` (around line 486)

**Code Addition**:
```lua
--- Preload adjacent pages for faster navigation
--- @param current_page number Current page number
function M.preload_adjacent_pages(current_page)
  local page_size = state.get_page_size()
  local total_emails = state.get_total_emails()
  local account = config.get_current_account_name()
  local folder = state.get_current_folder()

  -- Preload next page if likely to exist
  if total_emails == 0 or total_emails == nil or current_page * page_size < total_emails then
    vim.defer_fn(function()
      utils.get_emails_async(account, folder, current_page + 1, page_size, function(emails, _)
        if emails and #emails > 0 then
          logger.debug('Preloaded page ' .. (current_page + 1))
        end
      end)
    end, 500)  -- 500ms delay to not interfere with UI
  end

  -- Preload previous page if not first page
  if current_page > 1 then
    vim.defer_fn(function()
      utils.get_emails_async(account, folder, current_page - 1, page_size, function(emails, _)
        if emails and #emails > 0 then
          logger.debug('Preloaded page ' .. (current_page - 1))
        end
      end)
    end, 700)  -- Slightly longer delay for lower priority
  end
end
```

**At end of process_email_list_results**:
```lua
-- Preload adjacent pages for faster navigation
vim.defer_fn(function()
  M.preload_adjacent_pages(state.get_current_page())
end, 1000)
```

**Verification**:
- Load page 1, wait 2 seconds
- Press `<C-d>` to go to page 2
- Observe faster load time (data already cached)
- Check debug logs for "Preloaded page" messages

---

### Phase 4: Add Help Notification for Action Keys [NOT STARTED]

**Goal**: Improve discoverability of which-key action key location.

**Tasks**:
- [ ] Enhance the `?` key notification in sidebar
- [ ] Update gH help to emphasize action key location

**Timing**: 15 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/config/ui.lua` (line ~244-249)
  - Update notification text for `?` key

**Code Change**:

Current:
```lua
{ '?', function() notify.himalaya('Actions: `<leader>m` for mail menu | gH for help', notify.categories.STATUS) end, desc = 'Show help hint' },
```

Enhanced:
```lua
{ '?', function() notify.himalaya('Actions: <leader>med (delete) | <leader>mea (archive) | <leader>mer (reply) | gH for full help', notify.categories.STATUS) end, desc = 'Show help hint' },
```

**Verification**:
- Open himalaya sidebar
- Press `?`
- Verify notification shows specific action key examples

---

### Phase 5: Verification and Testing [NOT STARTED]

**Goal**: Comprehensive testing of all changes.

**Tasks**:
- [ ] Test pagination with multi-page inbox (>30 emails)
- [ ] Verify page 2 displays correctly
- [ ] Verify preloading improves navigation speed
- [ ] Test action keys via `<leader>me` prefix
- [ ] Verify no regressions in other functionality

**Timing**: 30 minutes

**Test Cases**:
1. Open himalaya sidebar with >30 emails (full page)
2. Press `<C-d>` - should show page 2 with emails
3. Press `<C-u>` - should return to page 1
4. Wait 2 seconds on page 1, then `<C-d>` - page 2 should load faster (preloaded)
5. Select an email, press `<leader>med` - should prompt for delete confirmation
6. Press `<leader>mea` - should archive selected email(s)
7. Press `?` - should show specific action key hints

**Verification**:
- All test cases pass
- No error notifications
- No console errors

---

## Testing & Validation

- [ ] Pagination test: Navigate to page 2 and back, verify emails display
- [ ] Preloading test: Measure page 2 load time before/after preload
- [ ] Error handling test: Invalid folder produces logged error
- [ ] Action keys test: `<leader>med` deletes, `<leader>mea` archives
- [ ] Help hint test: `?` shows specific key examples

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- Modified files:
  - `lua/neotex/plugins/tools/himalaya/utils.lua` - Fixed CLI flags, added error handling
  - `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Added preloading
  - `lua/neotex/plugins/tools/himalaya/config/ui.lua` - Enhanced help notification
- summaries/implementation-summary-YYYYMMDD.md (on completion)

## Rollback/Contingency

If pagination fix causes issues:
1. Revert `utils.lua` changes to restore `--offset` flag
2. Check himalaya CLI version with `himalaya --version`
3. Consult himalaya documentation for correct pagination flags

If preloading causes performance issues:
1. Comment out `preload_adjacent_pages()` call
2. Increase delay values (500ms -> 1000ms, 700ms -> 1500ms)
3. Add configuration option to disable preloading
