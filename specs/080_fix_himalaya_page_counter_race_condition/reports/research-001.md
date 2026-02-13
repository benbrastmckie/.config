# Research Report: Task #80

**Task**: 80 - Fix Himalaya sidebar page counter race condition
**Started**: 2026-02-13T10:00:00Z
**Completed**: 2026-02-13T10:45:00Z
**Effort**: 2-4 hours
**Dependencies**: None
**Sources/Inputs**: Local codebase analysis, existing async utilities
**Artifacts**: specs/080_fix_himalaya_page_counter_race_condition/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- The race condition occurs because `state.set_current_page()` is called synchronously but the async callback that renders the page content fires at an unpredictable time
- Rapid key presses result in multiple async requests being dispatched; when callbacks fire out of order, the UI shows stale page content with a mismatched page counter
- The codebase already has debounce/throttle utilities in `utils/async.lua` and a page cache generation system that can detect stale results
- Recommended solution: Request-level state lock with generation-based validation, combined with optional debouncing for extra safety

## Context & Scope

### What Was Researched
1. The page navigation flow when C-d/C-u is pressed
2. The async callback mechanism for email fetching
3. State management for page counters
4. Existing patterns for debouncing and cache invalidation
5. The relationship between page state and header rendering

### Constraints
- Must maintain current instant cache-hit behavior for responsive UX
- Cannot introduce noticeable lag on key presses
- Must handle both cache hits (synchronous) and cache misses (async)

## Findings

### Current Navigation Flow

When `<C-d>` is pressed (in `config/ui.lua`):
1. Keymap callback calls `email_list.next_page()`
2. `next_page()` immediately calls `state.set_current_page(next_page_num)` (synchronous)
3. Checks page cache for instant render
4. If cache hit: `render_cached_page()` renders immediately (synchronous path - no race)
5. If cache miss: `refresh_email_list()` is called, which triggers `utils.get_emails_async()`
6. Async callback eventually fires and calls `process_email_list_results()` -> `format_email_list()` -> `generate_header_lines()`

### Race Condition Point

The race condition occurs specifically in the **cache miss path**:

```
Time T0: User presses C-d (page 1 -> 2)
  - state.set_current_page(2) executes immediately
  - Cache miss - async request R1 dispatched for page 2

Time T1: User presses C-d again (page 2 -> 3)
  - state.set_current_page(3) executes immediately
  - Cache miss - async request R2 dispatched for page 3

Time T2: R2 callback fires (page 3 content arrives)
  - generate_header_lines() reads state.get_current_page() = 3
  - Renders "Page 3 / N" with page 3 content
  - UI is correct

Time T3: R1 callback fires (page 2 content arrives - LATE!)
  - generate_header_lines() reads state.get_current_page() = 3
  - Renders "Page 3 / N" with page 2 content
  - UI shows WRONG content for the displayed page number!
```

### Existing Safeguards (Partially Effective)

The codebase already has a **page cache generation system** (`page_generation` variable in `email_list.lua`):

```lua
-- From email_list.lua lines 36-37, 163-166, 196-200
local page_generation = 0

function M.invalidate_page_cache(account, folder)
  page_generation = page_generation + 1
  -- ...
end

function M.is_cache_generation_valid(generation)
  return generation == page_generation
end
```

This is used in `preload_adjacent_pages()` to discard stale preload results:
```lua
-- From preload_page() in email_list.lua
utils.get_emails_async(account, folder, page, page_size, function(emails, _, error)
  -- Check if generation is still valid
  if not M.is_cache_generation_valid(generation) then
    logger.debug('Preload discarded - stale generation', { page = page })
    return
  end
  -- ...
end)
```

**However**, this safeguard is NOT applied to the main navigation callbacks (`next_page`/`prev_page`), only to background preloading.

### Async Utilities Available

The codebase provides ready-to-use utilities in `utils/async.lua`:

| Utility | Description | Signature |
|---------|-------------|-----------|
| `debounce(fn, delay)` | Delays execution until no calls for `delay` ms | Returns wrapped function |
| `throttle(fn, delay)` | Limits calls to once per `delay` ms | Returns wrapped function |
| `rate_limit(fn, limit, window)` | Limits to `limit` calls per `window` ms | Returns wrapped function |

### Header Regeneration Timing

`generate_header_lines()` reads the current page from state:
```lua
-- From email_list.lua line 791
local current_page = state.get_current_page()
```

This means if an async callback fires after the state has advanced to a different page, the header will show the **current** page number (correct) but with **stale** email content (incorrect).

The `render_cached_page()` function was patched to regenerate headers fresh (line 1645), but this only helps for cache hits, not cache misses.

## Recommendations

### Primary Solution: Request-State Locking with Generation Validation

Extend the existing generation-based validation to the main navigation path:

```lua
-- In next_page() and prev_page()
local function next_page()
  -- ... existing code ...

  -- For cache miss path:
  local target_page = next_page_num
  local generation = M.get_cache_generation()

  -- Store the target page for this request
  local request_state = {
    target_page = target_page,
    generation = generation
  }

  M.refresh_email_list_with_validation(request_state)
end
```

In the async callback:
```lua
function M.refresh_email_list_with_validation(request_state)
  utils.get_emails_async(account, folder, request_state.target_page, page_size, function(emails, total_count, error)
    -- Validate request is still relevant
    if not M.is_cache_generation_valid(request_state.generation) then
      logger.debug('Navigation request obsolete - discarding')
      return
    end

    -- Verify we're still on the target page (user didn't navigate elsewhere)
    if state.get_current_page() ~= request_state.target_page then
      logger.debug('Page changed during async fetch - discarding')
      return
    end

    -- Proceed with rendering
    M.process_email_list_results(emails, total_count, folder, account_name)
  end)
end
```

### Alternative Solution: Debounced Navigation

Wrap the navigation functions with debouncing:

```lua
-- In email_list.lua module scope
local async_utils = require('neotex.plugins.tools.himalaya.utils.async')
local debounced_refresh = async_utils.debounce(function(page, generation)
  -- Only refresh if generation is still current
  if M.is_cache_generation_valid(generation) then
    M.refresh_email_list()
  end
end, 100) -- 100ms debounce

function M.next_page()
  -- ... existing cache hit logic (synchronous, fast) ...

  -- For cache miss:
  local generation = M.get_cache_generation()
  debounced_refresh(next_page_num, generation)
end
```

**Trade-off**: Adds 100ms latency but eliminates all race conditions.

### Recommended Hybrid Approach

Combine both solutions for maximum robustness:

1. **Request validation** (Primary): Discard stale async results using generation + target page validation
2. **Light debouncing** (Secondary): 50ms debounce on cache-miss refreshes to coalesce rapid presses
3. **Instant cache hits** (Preserve): No changes to synchronous cache-hit path

Implementation priority:
1. First: Add request validation to async callbacks (most impact, lowest risk)
2. Second: Add light debouncing as extra safety layer
3. Third: Consider request queuing if issues persist

## Implementation Approach

### Phase 1: Request Validation (Essential)

1. Create `navigation_request` table to track in-flight request state
2. Capture `target_page` and `generation` when dispatching async request
3. In callback, validate both before rendering
4. Log discarded requests for debugging

### Phase 2: Debouncing (Recommended)

1. Create debounced wrapper for `refresh_email_list()` in cache-miss path
2. Use 50-100ms delay to coalesce rapid presses
3. Pass generation ID through debounce to validate on execution

### Phase 3: Request Queue (Optional)

If race conditions persist:
1. Implement request queue that serializes async fetches
2. Cancel pending requests when new navigation occurs
3. Use vim.loop job cancellation if available

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Debouncing adds perceived lag | Medium | Low | Keep delay under 100ms, preserve instant cache hits |
| Complex state tracking | Low | Medium | Use simple generation ID, not complex state machine |
| Breaking instant navigation | Low | High | Only add validation/debounce to cache-miss path |
| Memory leaks from closures | Low | Low | Clear navigation_request on successful render |

## Appendix

### Files to Modify

1. `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
   - `next_page()` function (~line 1477)
   - `prev_page()` function (~line 1559)
   - `refresh_email_list()` function (~line 1761)
   - Add new `navigation_request` state tracking

2. `lua/neotex/plugins/tools/himalaya/core/state.lua` (Optional)
   - Add `set_navigation_in_flight()` / `get_navigation_in_flight()` if needed

### Test Cases

1. Rapid C-d presses (5+ times quickly) - verify page counter matches content
2. Rapid C-u presses (5+ times quickly) - verify page counter matches content
3. Alternating C-d/C-u rapidly - verify no visual glitches
4. Cache hit navigation - verify still instant
5. Network delay simulation - verify graceful handling

### References

- Existing generation system: `email_list.lua:36-37, 163-200`
- Async utilities: `utils/async.lua:9-52` (debounce, throttle)
- State module: `core/state.lua:275-281` (page getters/setters)
- Keybindings: `config/ui.lua:232-245` (C-d/C-u mappings)
