# Implementation Summary: Task #80

**Completed**: 2026-02-13
**Duration**: ~45 minutes

## Changes Made

Fixed race condition in Himalaya email sidebar where rapid `<C-d>` or `<C-u>` key presses caused page content to desynchronize from the displayed page counter. The fix implements a hybrid approach combining request validation with debouncing.

### Root Cause

When navigating pages, `state.set_current_page()` executes synchronously, but the async email fetch callback fires at unpredictable times. Rapid key presses dispatch multiple async requests, and when callbacks fire out of order, the UI displays stale page content with a mismatched page counter.

### Solution

1. **Request Validation (Primary)**: Track in-flight navigation requests with generation IDs and target page numbers. Async callbacks validate that the request is still relevant before rendering, discarding stale responses.

2. **Debouncing (Secondary)**: Coalesce rapid cache-miss navigation requests using a 50ms debounce. This reduces unnecessary async fetches while remaining imperceptible to users.

3. **Instant Cache Hits (Preserved)**: No changes to the synchronous cache-hit path, maintaining instant page switching for pre-cached pages.

## Files Modified

- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
  - Added `navigation_request` state variable to track in-flight requests
  - Added `debounced_nav_refresh` wrapper using async utilities
  - Added `do_debounced_nav_refresh()` function with pre-execution validation
  - Added `init_debounced_nav_refresh()` to initialize debounce on module load
  - Modified `M.init()` to initialize debounced navigation refresh
  - Modified `next_page()` to capture request state and use debounced refresh
  - Modified `prev_page()` to capture request state and use debounced refresh
  - Modified `refresh_email_list()` async callback to validate requests before rendering

## Technical Details

### Request Validation Logic

```lua
-- Captured at request time
navigation_request = {
  target_page = page_num,
  generation = M.get_cache_generation(),
  timestamp = vim.loop.now()
}

-- Validated in async callback
if not M.is_cache_generation_valid(request_generation) then
  return  -- Discard stale response
end
if state.get_current_page() ~= request_page then
  return  -- Page changed, discard
end
```

### Debounce Configuration

- Delay: 50ms
- Applied only to cache-miss path
- Validates generation and page before executing

## Verification

- Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.email_list')" -c "q"` - PASS
- Cache generation functions work correctly - PASS
- Debounce utility coalesces rapid calls correctly (only last call executes) - PASS
- Async utilities module loads - PASS
- Sidebar module loads - PASS

## Notes

- The fix is additive and does not modify the core async mechanism, making rollback straightforward
- Debug logging added for discarded requests to aid future troubleshooting
- The 50ms debounce is below perceptible threshold but effective at coalescing rapid navigation
- Cache-hit path remains unchanged, preserving instant navigation for pre-cached pages
- Navigation request tracking is cleared on successful render to prevent memory accumulation
