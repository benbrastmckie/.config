# Implementation Plan: Fix Himalaya sidebar page counter increment

- **Task**: 79 - fix_himalaya_sidebar_page_counter_increment
- **Status**: [COMPLETED]
- **Effort**: 1.5-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

The page counter display bug occurs because cached page data includes pre-formatted header lines that contain stale pagination information. When `preload_adjacent_pages()` pre-formats display lines, it uses the current page state (page 1) to format the header. When the user navigates to a cached page, `render_cached_page()` displays those cached lines without regenerating the header with the updated current page number.

The fix will modify `render_cached_page()` to regenerate the header lines with the current page state before rendering, while preserving the cached email content lines for performance.

### Research Integration

- Root cause confirmed: Pre-formatted cache lines contain stale `pagination_info` string
- Fix approach: Regenerate header on cache hit (Fix Option 1 from research)
- Key insight: Header is lines 1-4 (account, pagination, separator, blank), email content starts at line 5+

## Goals & Non-Goals

**Goals**:
- Fix page counter to display correct current page number when rendering from cache
- Preserve performance benefits of pre-formatted email content caching
- Maintain backward compatibility with existing cache structure

**Non-Goals**:
- Fixing the underlying total_emails accuracy issue (separate concern)
- Refactoring the entire caching system
- Adding new features to pagination display

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Header line count varies (sync status line) | M | M | Calculate header boundary dynamically using `email_start_line` metadata |
| Breaking cache structure | H | L | Minimal changes to existing structure; only modify render path |
| Performance regression | M | L | Header regeneration is lightweight (4 lines); measure with timing instrumentation |

## Implementation Phases

### Phase 1: Extract Header Generation Function [COMPLETED]

**Goal**: Create a reusable function to generate header lines with current pagination state

**Tasks**:
- [ ] Create `M.generate_header_lines(emails)` function in email_list.lua
- [ ] Extract header generation logic from `format_email_list()` (lines 735-858)
- [ ] Ensure function returns header lines array and `email_start_line` value
- [ ] Keep original `format_email_list()` working by calling the new function

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Add generate_header_lines function

**Verification**:
- Existing pagination display unchanged (no regression)
- `format_email_list()` continues to work correctly
- New function is tested via `:lua print(vim.inspect(require('neotex.plugins.tools.himalaya.ui.email_list').generate_header_lines({})))`

---

### Phase 2: Modify render_cached_page to Regenerate Header [COMPLETED]

**Goal**: Update `render_cached_page()` to use fresh header with cached email content

**Tasks**:
- [ ] Modify `render_cached_page()` to call `generate_header_lines()` with cached emails
- [ ] Replace header portion of `cached.formatted_lines` with fresh header
- [ ] Preserve email content lines from cache (starting at `email_start_line`)
- [ ] Update metadata (line_map, email_start_line) with fresh values

**Timing**: 30 minutes

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Modify render_cached_page function

**Verification**:
- Page counter updates correctly when navigating with C-d/C-u
- Cached email content still renders instantly
- No visual glitches or flickering

---

### Phase 3: Testing and Verification [COMPLETED]

**Goal**: Comprehensive verification of the fix across multiple scenarios

**Tasks**:
- [ ] Test initial page load shows correct "Page 1 / X"
- [ ] Test C-d from page 1 shows "Page 2 / X" (not "Page 1")
- [ ] Test C-d x4 shows pages 2, 3, 4, 5 consecutively
- [ ] Test C-u decrements correctly
- [ ] Test with cache cold (first navigation)
- [ ] Test with cache warm (repeated navigation)
- [ ] Test folder switch resets pagination correctly
- [ ] Verify timing performance with instrumentation enabled

**Timing**: 30 minutes

**Files to modify**:
- None (testing only)

**Verification**:
- All manual test cases pass
- Cache hit timing remains under 16ms target
- No regressions in folder selection or email display

## Testing & Validation

- [ ] Manual: Open sidebar with 100+ emails, press C-d 4 times, verify counter shows 2/3/4/5
- [ ] Manual: Press C-u to verify decrement works correctly
- [ ] Manual: Switch folders and verify pagination resets
- [ ] Manual: Enable timing with `:lua require('neotex.plugins.tools.himalaya.ui.email_list').set_timing_enabled(true)` and verify cache hits under 16ms
- [ ] Automated: Run `:checkhealth himalaya` if available

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (on completion)
- Modified file: `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

## Rollback/Contingency

If the fix causes issues:
1. Revert changes to `email_list.lua` using git
2. The original caching behavior will be restored
3. Page counter bug returns but no data loss or crashes

Alternative approach if Phase 2 proves problematic:
- Disable pre-formatted line caching entirely (set `formatted_lines = nil` in cache)
- This forces `render_cached_page()` to always call `format_email_list()` with fresh state
- Performance impact: ~50ms instead of ~16ms per cache hit (still acceptable)
