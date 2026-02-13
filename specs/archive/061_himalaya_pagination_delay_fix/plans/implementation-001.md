# Implementation Plan: Task #61

- **Task**: 61 - himalaya_pagination_delay_fix
- **Status**: [COMPLETED]
- **Effort**: 3-4 hours
- **Dependencies**: Task #60 (completed)
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Despite task 60's preloading implementation, C-d/C-u pagination still experiences 150-1050ms delays. Research identified 6 delay sources, with the two most critical being: (1) no cache hit path - pages are always re-fetched even when preloaded, and (2) preload timing that doesn't beat user input. This plan implements a synchronous cache hit path for instant page switching when data is available, optimistic UI updates, and pre-rendering of adjacent pages.

### Research Integration

Key findings from research-001.md integrated into this plan:
- Current flow has 5-7 sequential operations accumulating delay even when data is cached
- `get_emails_async` never checks cache before CLI calls
- Preload delays (50-300ms) mean preloading only helps if user waits before navigating
- Target performance: cache hit < 5ms, cache miss < 100ms with loading indicator

## Goals & Non-Goals

**Goals**:
- Achieve < 16ms keypress-to-visual-update for cache hits (60fps frame time)
- Implement synchronous cache lookup before async fetch
- Pre-render adjacent pages for instant buffer swaps
- Show loading indicator only on cache misses

**Non-Goals**:
- Rewriting the entire cache architecture
- Background prefetch threads (complexity vs benefit)
- Unified cache key restructuring (low priority per research)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Cache staleness shows outdated emails | Medium | Low | Keep async refresh as background update, display cached immediately |
| Pre-rendering memory usage | Low | Low | Limit to +/- 2 pages, clear on folder change |
| Race conditions between cache and async | Medium | Medium | Use page generation ID to discard stale async results |

## Implementation Phases

### Phase 1: Implement Page-Level Cache with Synchronous Lookup [COMPLETED]

**Goal**: Create a page-indexed cache that `next_page()` and `prev_page()` can query synchronously before triggering async fetch.

**Tasks**:
- [ ] Add `page_cache` table to email_list.lua for storing pre-formatted page data
- [ ] Create `get_cached_page(account, folder, page)` function returning cached emails or nil
- [ ] Create `set_cached_page(account, folder, page, emails, formatted_lines)` function
- [ ] Add cache invalidation on folder change or manual refresh
- [ ] Add page generation ID to detect stale async results

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/himalaya/email_list.lua` - Add page_cache table and accessor functions

**Verification**:
- [ ] Cache functions are callable without errors
- [ ] Cache correctly stores and retrieves page data
- [ ] Cache invalidates on folder change

---

### Phase 2: Integrate Cache Hit Path into Pagination [COMPLETED]

**Goal**: Modify `next_page()` and `prev_page()` to check cache synchronously and render immediately when cached.

**Tasks**:
- [ ] Modify `next_page()` to check `get_cached_page()` before calling `refresh_email_list()`
- [ ] Modify `prev_page()` with same cache-first pattern
- [ ] When cache hit: call optimized render path (skip async, skip full refresh)
- [ ] When cache miss: show loading indicator, proceed with async fetch
- [ ] Update preload functions to populate the new page cache

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/himalaya/email_list.lua` - Modify next_page, prev_page, preload_adjacent_pages

**Verification**:
- [ ] C-d with warm cache shows instant page switch (< 50ms perceived)
- [ ] C-u with warm cache shows instant page switch
- [ ] First navigation still works (cache miss path)
- [ ] Preloaded pages populate the cache correctly

---

### Phase 3: Implement Pre-Rendered Page Buffer [COMPLETED]

**Goal**: Store pre-formatted display lines alongside cached emails for instant buffer swap without re-formatting.

**Tasks**:
- [ ] Extend page cache to store `formatted_lines` alongside `emails`
- [ ] Modify `preload_adjacent_pages()` to call `format_email_list()` and cache the result
- [ ] Create `render_cached_page()` that directly updates sidebar buffer without re-formatting
- [ ] Use `nvim_buf_set_lines()` with cached lines for instant swap

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/himalaya/email_list.lua` - Extend cache structure, add render_cached_page
- `lua/neotex/plugins/himalaya/ui/sidebar.lua` - Potentially optimize update_content for pre-formatted lines

**Verification**:
- [ ] Pre-rendered pages display correctly (no formatting artifacts)
- [ ] Buffer swap is visually instantaneous
- [ ] Metadata (line_map, email_start_line) correctly updated for cached pages

---

### Phase 4: Optimistic UI Updates with Background Refresh [COMPLETED]

**Goal**: Update UI immediately with cached data, then silently refresh in background to catch any changes.

**Tasks**:
- [ ] Implement `render_page_optimistic()` that shows cache immediately
- [ ] After instant render, trigger silent background refresh
- [ ] Use page generation ID to discard stale background results
- [ ] Only update UI if background fetch finds different data
- [ ] Remove loading indicator from cache hit path

**Timing**: 45 minutes

**Files to modify**:
- `lua/neotex/plugins/himalaya/email_list.lua` - Add optimistic render and background refresh logic

**Verification**:
- [ ] No loading indicator appears on cache hits
- [ ] Background refresh updates UI if emails changed
- [ ] Stale async results are correctly discarded
- [ ] No visual flicker from redundant updates

---

### Phase 5: Testing and Performance Validation [COMPLETED]

**Goal**: Verify pagination meets performance targets and functions correctly across all scenarios.

**Tasks**:
- [ ] Test rapid C-d/C-u sequences (5+ key presses quickly)
- [ ] Test folder switching clears cache appropriately
- [ ] Test cold start (no cache) still functions correctly
- [ ] Test mixed scenarios (some pages cached, some not)
- [ ] Add timing instrumentation to verify < 16ms target on cache hits
- [ ] Test edge cases: first page, last page, single-page folder

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/himalaya/email_list.lua` - Add optional timing logging

**Verification**:
- [ ] All test scenarios pass
- [ ] Cache hit timing consistently < 16ms
- [ ] No regressions in email list functionality

## Testing & Validation

- [ ] C-d/C-u with warm cache: < 50ms perceived delay
- [ ] C-d/C-u with cold cache: loading indicator shown, completes < 1s
- [ ] Folder switching clears cache
- [ ] Rapid pagination (C-d C-d C-d) works smoothly without errors
- [ ] Email selection and opening works after cached page switch
- [ ] No memory leaks from accumulating cached pages

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Modified files: email_list.lua, potentially sidebar.lua

## Rollback/Contingency

If cache implementation causes issues:
1. Cache functions are additive - can be disabled by returning nil from `get_cached_page()`
2. Original async flow remains intact as fallback
3. Pre-rendering can be disabled independently of cache lookup
4. Revert to task 60 state by removing cache-related code blocks
