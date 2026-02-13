# Implementation Plan: Task #80

- **Task**: 80 - Fix Himalaya sidebar page counter race condition
- **Status**: [COMPLETED]
- **Effort**: 2-4 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

This plan addresses a race condition in the Himalaya email sidebar where rapid `<C-d>` or `<C-u>` key presses cause page content to desynchronize from the displayed page counter. The root cause is that `state.set_current_page()` executes synchronously, but async email fetch callbacks fire at unpredictable times, allowing late responses to overwrite correct page content.

The solution applies generation-based validation (already present for preloading) to the main navigation path, combined with optional debouncing for extra safety. This preserves instant cache-hit behavior while ensuring stale async responses are discarded.

### Research Integration

Research report `research-001.md` identified:
- Race condition occurs specifically in the cache-miss path when async callbacks fire out of order
- Existing `page_generation` system is only applied to background preloading, not main navigation
- Async utilities (`debounce`, `throttle`) are available in `utils/async.lua`
- Recommended hybrid approach: request validation (primary) + light debouncing (secondary)

## Goals & Non-Goals

**Goals**:
- Eliminate race condition where page content mismatches displayed page number
- Preserve instant cache-hit navigation (no added latency for cached pages)
- Discard stale async responses using generation-based validation
- Add debug logging for discarded requests to aid future troubleshooting

**Non-Goals**:
- Changing the async email fetching mechanism
- Implementing request cancellation (complex, not needed)
- Modifying the cache system itself
- Adding request queuing (overkill for this problem)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Debouncing adds perceived lag | Low | Medium | Keep delay under 100ms, only apply to cache-miss path |
| Complex state tracking bugs | Medium | Low | Use simple generation ID, not complex state machine |
| Breaking instant cache-hit navigation | High | Low | Only add validation to cache-miss path, test cache hits separately |
| Memory leaks from closures | Low | Low | Clear navigation_request reference on successful render |
| Regression in email list display | Medium | Low | Verify header regeneration still works correctly |

## Implementation Phases

### Phase 1: Add Request Validation to Async Callbacks [COMPLETED]

**Goal**: Discard stale async responses using generation + target page validation

**Tasks**:
- [ ] Add `navigation_request` module-level state variable to track in-flight request
- [ ] Modify `next_page()` to capture `target_page` and `generation` before async call
- [ ] Modify `prev_page()` to capture `target_page` and `generation` before async call
- [ ] Add validation checks in async callback before rendering
- [ ] Add debug logging for discarded requests
- [ ] Expose `get_cache_generation()` function if not already public

**Timing**: 1-1.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
  - Add `navigation_request` table (~line 40)
  - Modify `next_page()` function (~line 1477)
  - Modify `prev_page()` function (~line 1559)
  - Add validation in async callback (~within `refresh_email_list` or its callback)

**Verification**:
- Rapid `<C-d>` presses (5+ times) show final page number matches content
- Rapid `<C-u>` presses (5+ times) show final page number matches content
- Debug logs show "discarding stale request" messages when appropriate
- Cache hit navigation still works instantly

---

### Phase 2: Add Debouncing for Cache-Miss Refreshes [COMPLETED]

**Goal**: Coalesce rapid cache-miss refreshes to reduce unnecessary async requests

**Tasks**:
- [ ] Import `debounce` utility from `utils/async.lua`
- [ ] Create `debounced_refresh` wrapper with 50ms delay
- [ ] Modify cache-miss path in `next_page()` to use debounced refresh
- [ ] Modify cache-miss path in `prev_page()` to use debounced refresh
- [ ] Pass generation through debounce for validation on execution
- [ ] Ensure debounced wrapper clears navigation_request on completion

**Timing**: 0.5-1 hour

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`
  - Add import for `utils/async.lua` debounce function
  - Create `debounced_refresh` wrapper (~line 45)
  - Modify cache-miss branches in `next_page()` and `prev_page()`

**Verification**:
- Rapid navigation coalesces into single refresh (check logs)
- 50ms delay is not perceptible in normal use
- Debounce does not affect cache-hit path (still instant)

---

### Phase 3: Verification and Edge Case Testing [COMPLETED]

**Goal**: Comprehensive testing of race condition fix across all scenarios

**Tasks**:
- [ ] Test rapid `<C-d>` presses crossing page boundaries
- [ ] Test rapid `<C-u>` presses crossing page boundaries
- [ ] Test alternating `<C-d>`/`<C-u>` rapidly
- [ ] Test cache-hit path remains instant (pre-cached pages)
- [ ] Test normal single-press navigation still works
- [ ] Test page counter accuracy at first/last page boundaries
- [ ] Test folder change invalidates navigation_request correctly
- [ ] Verify no memory leaks with repeated navigation cycles

**Timing**: 0.5-1 hour

**Files to modify**:
- None (manual testing phase)

**Verification**:
- All test scenarios pass without page/counter mismatch
- Performance is acceptable (no perceptible lag)
- Logger shows expected behavior (validation, debouncing)

## Testing & Validation

- [ ] Load Neovim with Himalaya sidebar open
- [ ] Navigate to folder with multiple pages of emails
- [ ] Rapid `<C-d>` (5+ presses) - counter matches content
- [ ] Rapid `<C-u>` (5+ presses) - counter matches content
- [ ] Alternating rapid `<C-d>`/`<C-u>` - no visual glitches
- [ ] Single press navigation - still works normally
- [ ] Cache hit navigation - still instant
- [ ] Check debug logs for "discarding stale" messages during rapid nav
- [ ] Module loads without errors: `nvim --headless -c "lua require('neotex.plugins.tools.himalaya.ui.email_list')" -c "q"`

## Artifacts & Outputs

- `plans/implementation-001.md` (this file)
- `summaries/implementation-summary-YYYYMMDD.md` (after completion)
- Modified: `lua/neotex/plugins/tools/himalaya/ui/email_list.lua`

## Rollback/Contingency

If the changes introduce regressions:
1. Revert changes to `email_list.lua` via git
2. The `navigation_request` state can be disabled by setting validation checks to always pass
3. Debounce wrapper can be bypassed by calling refresh directly

The changes are additive (validation checks, debounce wrapper) and do not modify the core async mechanism, making rollback straightforward.
