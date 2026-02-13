# Research Report: Task #79

**Task**: 79 - fix_himalaya_sidebar_page_counter_increment
**Date**: 2026-02-13
**Focus**: Page counter bug where page number stays at 1 for first 3 C-d presses

## Summary

The page counter display bug occurs because `total_pages` is calculated from `total_emails`, which is only updated with an accurate count after fetching emails from Himalaya. On initial load, `total_emails` defaults to the number of emails returned in the first page (25), causing `total_pages = ceil(25/25) = 1`. The page counter stays at "Page 1 / 1" until Himalaya returns fewer emails than page_size (indicating end of folder) or a full count fetch occurs.

## Root Cause Analysis

### The Bug Mechanism

1. **Initial State**: When sidebar opens, `state.set_total_emails()` is called with the count returned by Himalaya's envelope list command. If a full page (25 emails) is returned, the code cannot determine the true total.

2. **Page Counter Calculation** (email_list.lua:803):
   ```lua
   local total_pages = math.max(1, math.ceil(total_emails / page_size))
   ```

3. **The Problem**: When `total_emails = 25` and `page_size = 25`:
   - `total_pages = ceil(25/25) = 1`
   - Display shows "Page 1 / 1" even when user is on page 2, 3, or 4

4. **Why it "fixes" after page 4**: On page 4 (emails 76-100), if fewer than 25 emails are returned, the code knows the exact count and updates `total_emails` correctly. Also, background count fetch may complete by this time.

### Code Flow

**File**: `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

**format_email_list()** (lines 735-1065):
```lua
-- Lines 766-795: Getting total_emails
local total_emails = state.get_folder_count(account, folder)

-- If no stored count, use what we got from the email list
if not total_emails or total_emails == 0 then
  total_emails = state.get_total_emails()
  -- If still no count, check if we have a full page (might be more)
  if not total_emails or total_emails == 0 then
    local page_size = state.get_page_size()
    if #emails >= page_size then
      -- We have a full page, so there might be more
      total_emails = nil  -- Will show as "?" or "30+" etc
    else
      total_emails = #emails
    end
  end
end
```

**The Key Issue**: The code sets `total_emails = nil` when a full page is detected, intending to show "Page X / ?". However, this only happens when `total_emails` was already 0 or nil. If `state.get_total_emails()` returns a stale value (e.g., 25 from page 1), the nil-setting branch is never reached.

### Data Flow Trace

1. **Page 1 Load** (`show_email_list`):
   - Calls `utils.get_emails_async()` with page=1, page_size=25
   - Returns 25 emails, total_count=25 (Himalaya only knows about returned emails)
   - `state.set_total_emails(25)` is called
   - `format_email_list()` sees `total_emails=25`, calculates `total_pages=1`
   - Display: "Page 1 / 1 | 25 emails"

2. **C-d Press 1** (`next_page`):
   - `state.set_current_page(2)`
   - Renders from cache or fetches page 2
   - `format_email_list()` gets `total_emails=25` from state (unchanged)
   - Display: "Page 2 / 1 | 25 emails" -- **BUG: total_pages still shows 1**
   - Actually displays "Page 1 / 1" because of how the display string is formatted

3. **Wait, Why Still "Page 1"?**:
   - Looking closer at the display logic, `current_page` is correct (2)
   - The issue is `total_pages` calculation showing 1
   - But the pagination_info shows `current_page` correctly...

### Re-examining the Bug

Let me trace through more carefully:

**Lines 823-824**:
```lua
pagination_info = string.format('Page %d / %d | %s',
  current_page, total_pages, count_display)
```

If `current_page=2` and `total_pages=1`, this would show "Page 2 / 1", not "Page 1 / 1".

**Alternative Hypothesis**: The bug might be in how `state.get_current_page()` is returning the value. Let me check the state module.

**File**: `lua/neotex/plugins/tools/himalaya/core/state.lua`

```lua
function M.get_current_page()
  return M.get("ui.current_page", 1)
end

function M.set_current_page(page)
  M.set("ui.current_page", page)
end
```

The state management looks correct.

### Cache-Related Hypothesis

**In `next_page()` (lines 1481-1561)**:

```lua
function M.next_page()
  -- ...
  local next_page_num = current_page + 1
  state.set_current_page(next_page_num)

  -- Check cache for instant page switch (synchronous path)
  local cached = M.get_cached_page(account, folder, next_page_num)
  if cached and cached.formatted_lines then
    -- Instant render from pre-formatted cache
    M.render_cached_page(cached)  -- <-- Uses CACHED formatted lines!
    -- ...
  }
```

**Found It!** When rendering from cache, `render_cached_page()` uses **pre-formatted lines** that were cached when the page was preloaded. Those cached lines contain the old pagination display string with the wrong total_pages.

### The Caching Bug

**File**: `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

**preload_adjacent_pages()** (lines 673-732):

```lua
function M.preload_adjacent_pages(current_page)
  -- ...
  local function preload_page(page, delay)
    vim.defer_fn(function()
      -- ...
      utils.get_emails_async(account, folder, page, page_size, function(emails, _, error)
        -- ...
        -- Pre-format display lines for instant buffer swap
        local lines = M.format_email_list(emails)  -- <-- Formats with current state!

        -- Store in page cache with pre-formatted lines
        M.set_cached_page(account, folder, page, emails, lines)
      end)
    end, delay)
  end
```

When preloading pages 2, 3, 4, the `format_email_list(emails)` call uses the **current** `state.get_current_page()` (which is 1) to format the pagination header. The cached `lines` object contains "Page 1 / 1" (or whatever was current at preload time).

When the user actually navigates to page 2, `render_cached_page()` displays those cached lines without regenerating the header.

## Recommendations

### Fix Option 1: Regenerate Header on Cache Hit (Recommended)

Modify `render_cached_page()` to regenerate the header lines instead of using cached header:

```lua
function M.render_cached_page(cached)
  if not cached then return end

  if cached.formatted_lines then
    -- Regenerate header with current page state
    local header_lines = M.generate_header_lines(cached.emails)

    -- Replace cached header with fresh header
    local content_lines = cached.formatted_lines
    for i = 1, #header_lines do
      content_lines[i] = header_lines[i]
    end

    sidebar.update_content(content_lines)
    -- ...
  end
end
```

**Pros**: Minimal changes, preserves caching benefits for email content
**Cons**: Slight overhead to regenerate header (negligible)

### Fix Option 2: Don't Cache Header Lines

Modify `set_cached_page()` and `get_cached_page()` to only cache email content, not header:

- Store `email_start_line` index
- On render, generate fresh header + cached email lines

**Pros**: Clean separation of concerns
**Cons**: More invasive changes

### Fix Option 3: Update Cached Lines on State Change

Add a mechanism to invalidate/update cached lines when `current_page` or `total_emails` changes:

```lua
function M.set_current_page(page)
  local old_page = M.get("ui.current_page", 1)
  M.set("ui.current_page", page)

  if old_page ~= page then
    -- Invalidate header portion of page cache
    M.invalidate_cached_headers()
  end
end
```

**Pros**: Cache stays consistent
**Cons**: Complex cache management

## Additional Findings

### Related Variables

| Variable | Location | Purpose |
|----------|----------|---------|
| `ui.current_page` | state.lua:34 | Current page number (1-indexed) |
| `ui.page_size` | state.lua:35 | Emails per page (default 25) |
| `ui.total_emails` | state.lua:36 | Total email count (may be inaccurate) |
| `page_cache` | email_list.lua:35 | Page-level cache with formatted lines |

### Email Count Sources

1. **`state.get_folder_count(account, folder)`**: Stored from sync operation
2. **`state.get_total_emails()`**: Set during email list loading
3. **`#emails`**: Direct count from current page fetch

### The Count Accuracy Problem

The underlying count accuracy issue is that Himalaya's `envelope list` command doesn't return the total folder count, only the requested page of emails. The code attempts to work around this by:

1. Fetching up to 1000 emails to estimate count (utils.lua:848-857)
2. Using binary search for large folders (utils.lua:638-685)
3. Storing counts after sync operations

But none of these are triggered during normal pagination, so `total_emails` can remain stale.

## Files to Modify

| File | Change |
|------|--------|
| `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` | Fix `render_cached_page()` to regenerate header |
| `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` | Possibly extract header generation to separate function |

## Verification Steps

1. Open Himalaya sidebar with INBOX having 100+ emails
2. Note the page counter shows "Page 1 / X"
3. Press C-d four times
4. Verify page counter shows "Page 2 / X", "Page 3 / X", "Page 4 / X", "Page 5 / X" respectively
5. Press C-u to go back and verify counter decrements correctly

## References

- Previous pagination research: specs/archive/056_himalaya_pagination_display_fix/
- Keymap research: specs/archive/056_himalaya_pagination_display_fix/reports/research-002.md
- Page cache implementation: email_list.lua lines 33-201

## Next Steps

Run `/plan 79` to create implementation plan based on Fix Option 1 (regenerate header on cache hit).
