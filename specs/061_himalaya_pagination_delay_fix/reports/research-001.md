# Research Report: Task #61

**Task**: himalaya_pagination_delay_fix
**Date**: 2026-02-10
**Focus**: Investigate remaining pagination delays in C-d/C-u despite preloading

## Summary

Despite task 60's preloading implementation, C-d/C-u pagination still experiences perceptible delays. Analysis reveals multiple sources of latency: synchronous cache checks during navigation, UI redraws after async completion, state management overhead, and preload timing that doesn't always beat user input. The current flow has 5-7 sequential operations that accumulate delay even when data is cached.

## Findings

### Current Pagination Flow Analysis

When user presses C-d (next page), the following sequence occurs:

1. **Keymap handler** (ui.lua:233-238):
   - Calls `email_list.next_page()`

2. **next_page function** (email_list.lua:1294-1307):
   - Reads `state.get_total_emails()` (sync)
   - Reads `state.get_current_page()` (sync)
   - Reads `state.get_page_size()` (sync)
   - Validates pagination bounds
   - Calls `state.set_current_page()` (sync)
   - Calls `M.refresh_email_list()` (triggers async fetch)

3. **refresh_email_list function** (email_list.lua:1319-1447):
   - Scheduler sync from disk (1323-1326)
   - Saves current window/mode for focus restoration
   - Gets sidebar buffer
   - Calls `utils.get_emails_async()` - **ASYNC BOUNDARY**

4. **get_emails_async** (utils.lua:580-656):
   - In test mode: returns immediately
   - Otherwise: calls `cli_utils.execute_himalaya_async()`

5. **execute_himalaya_async** (cli.lua:244-291):
   - Wraps `async_commands.execute_async()`

6. **async_commands.execute_async** (async_commands.lua:377-416):
   - Generates job ID
   - Either executes immediately or queues based on concurrency
   - Uses `vim.fn.jobstart()` with flock for CLI locking

### Delay Sources Identified

#### 1. **Preloading Misses Cache Target** (MAJOR)

The preloading from task 60 (email_list.lua:491-547) occurs AFTER `process_email_list_results()` completes:
```lua
vim.defer_fn(function()
  M.preload_adjacent_pages(state.get_current_page())
end, 100)
```

Problem: If user presses C-d within 50-100ms of page render, preload hasn't completed yet.

Preload delays from task 60:
- Next page: 50ms delay
- Previous page: 100ms delay
- 2 pages ahead: 200ms delay
- 2 pages behind: 300ms delay

These delays mean preloading only helps if user waits 50-300ms after page load before navigating.

#### 2. **No True Cache Hit Path** (MAJOR)

The `get_emails_async` function (utils.lua:580-656) does NOT check the data cache before making CLI calls. It always calls `cli_utils.execute_himalaya_async()`.

The cache (`email_cache` module in utils.lua:36-49 and data/cache.lua) is only used for:
- Storing results AFTER async fetch
- Serving `get_email_by_id()` lookups

The pagination path never queries the cache for already-loaded pages.

#### 3. **Full UI Refresh on Every Page** (MODERATE)

`refresh_email_list()` does a complete content refresh:
1. Fetch emails via async (even if cached)
2. `M.format_email_list()` - Creates new lines array with metadata
3. `sidebar.update_content()` - Full buffer replacement
4. State updates for line_map, email_start_line
5. Focus restoration logic

Even when content is identical, this creates visible redraw.

#### 4. **CLI Locking Overhead** (MODERATE)

async_commands.lua uses `flock` with 30-second timeout for every Himalaya CLI call:
```lua
local cmd = {
  'flock',
  '-w', '30',
  '-x',
  lock_file,
  executable
}
```

While necessary for concurrent access safety, this adds subprocess overhead.

#### 5. **State Read/Write Overhead** (MINOR)

Multiple synchronous state operations:
- `state.get_total_emails()`
- `state.get_current_page()`
- `state.get_page_size()`
- `state.set_current_page()`
- `state.set()` calls for email_list data
- `state.save()` at end

Each is fast individually (~1-2ms), but 10+ calls accumulate.

#### 6. **vim.schedule Delays** (MINOR)

Callback processing uses `vim.schedule()` which defers to next event loop iteration:
```lua
on_exit = function(_, exit_code)
  vim.schedule(function()
    M.handle_job_completion(job_id, exit_code)
  end)
end
```

Each schedule adds one event loop delay (typically 5-10ms in practice).

### Task 60 Preloading Assessment

Task 60 added aggressive preloading with these changes:
- Reduced initial preload delay from 1000ms to 100ms
- Next page preload: 50ms (was 500ms)
- Previous page preload: 100ms (was 700ms)
- Added 2-page-ahead bidirectional preloading

However, the implementation has issues:
1. Preloads call `utils.get_emails_async()` which doesn't store to the right cache
2. The cache lookup path is never used by pagination
3. Results are logged but not persisted where `refresh_email_list()` can find them

### Cache Architecture Gap

Two separate cache systems exist:
1. **utils.lua email_cache** (lines 36-49): Simple table with timeout
2. **data/cache.lua**: Full caching module with normalization

Neither is queried on the pagination hot path. The `refresh_email_list()` always fetches fresh data via async CLI.

## Recommendations

### 1. Implement Synchronous Cache Hit Path (HIGH PRIORITY)

Add cache check BEFORE async fetch in `refresh_email_list()`:
```lua
-- Check if page is already cached
local cached_emails = email_cache.get_folder_emails(account, folder)
if cached_emails and #cached_emails >= (page * page_size) then
  -- Use cached data immediately, skip async
  M.process_email_list_results(vim.list_slice(cached_emails, start, end), ...)
  return
end
-- Otherwise proceed with async fetch
```

### 2. Pre-render Adjacent Pages (MEDIUM PRIORITY)

Instead of just preloading data, pre-format the display lines:
```lua
local prerendered_pages = {}
function M.prerender_page(page)
  local emails = email_cache.get_page(page)
  if emails then
    prerendered_pages[page] = M.format_email_list(emails)
  end
end
```

Then `next_page()` can instantly swap buffer content.

### 3. Differential UI Updates (MEDIUM PRIORITY)

Instead of full `sidebar.update_content()`, update only changed lines:
- Email lines rarely change between page renders
- Header/pagination info changes
- Use `nvim_buf_set_lines()` with precise line ranges

### 4. Optimistic Page Switching (HIGH PRIORITY)

Update UI immediately, fetch in background:
```lua
function M.next_page()
  -- Optimistic: Update state and try cache first
  state.set_current_page(current_page + 1)

  local cached = get_cached_page(current_page + 1)
  if cached then
    -- Instant render from cache
    render_page(cached)
    return
  end

  -- Show loading indicator only if no cache
  show_loading_indicator()
  fetch_async(function(emails) render_page(emails) end)
end
```

### 5. Unified Cache Key by Page (LOW PRIORITY)

Current cache uses folder-level storage. Add page-indexed access:
```lua
-- Current: cache[account][folder] = all_emails
-- Better:  cache[account][folder][page] = page_emails
```

### 6. Background Prefetch Thread (LOW PRIORITY)

Use Neovim's `vim.loop` to continuously prefetch adjacent pages without blocking:
```lua
vim.loop.new_thread(function()
  while true do
    prefetch_adjacent_pages()
    vim.loop.sleep(100)
  end
end)
```

## Performance Budget

For instantaneous pagination, target:
- Keypress to visual update: < 16ms (one frame at 60fps)
- Cache hit path: < 5ms total
- Cache miss path: < 100ms (with loading indicator)

Current approximate timings:
- Keypress to async start: ~20-30ms
- Async CLI (cached): ~100-200ms
- Async CLI (fresh): ~500-1000ms
- UI update after callback: ~30-50ms

Total current latency: 150-1050ms

## References

- Task 60 implementation summary: `specs/060_fix_himalaya_post_task59_issues/summaries/implementation-summary-20260210.md`
- Neovim API for buffer updates: `:help nvim_buf_set_lines`
- Lua tables for caching: https://www.lua.org/pil/11.5.html

## Next Steps

1. Create implementation plan with phased approach
2. Phase 1: Implement synchronous cache hit path (biggest impact)
3. Phase 2: Add optimistic page switching
4. Phase 3: Differential UI updates
5. Test with timing instrumentation to verify improvements
