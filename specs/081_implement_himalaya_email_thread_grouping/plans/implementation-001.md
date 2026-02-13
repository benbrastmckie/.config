# Implementation Plan: Task #81

- **Task**: 81 - Implement Himalaya Email Thread Grouping
- **Status**: [IMPLEMENTING]
- **Effort**: 6-8 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Implement email thread grouping in the Himalaya sidebar to consolidate emails from the same conversation into a single entry. The research found that Himalaya CLI v1.1.0 does not natively support threading, but provides access to threading headers (Message-ID, In-Reply-To, References) via `himalaya message read --header`. The recommended approach is a hybrid strategy: subject-based grouping for fast initial display with optional header-based threading on-demand.

### Research Integration

Key findings from research-001.md integrated into this plan:
- Himalaya CLI lacks native thread grouping - client-side implementation required
- Threading headers available via `message read --header` command
- Subject normalization patterns defined for Re:, AW:, Fwd:, FW:, SV:, Rif: prefixes
- JWZ threading algorithm identified for accurate header-based threading
- Existing plugin architecture has TODO placeholder for threading in email_list.lua

## Goals & Non-Goals

**Goals**:
- Group emails by normalized subject for instant thread display
- Show thread count indicator in sidebar (e.g., `[5]` for 5 messages)
- Display most recent email data for thread groups
- Implement expand/collapse functionality for thread groups
- Add configuration option to enable/disable thread grouping
- Maintain backward compatibility with existing selection/preview functionality

**Non-Goals**:
- Full JWZ threading algorithm implementation (deferred to future enhancement)
- Cross-folder thread grouping (emails must be in same folder)
- Thread-level operations (archive/delete entire thread at once)
- Header-based thread verification on initial load (performance concern)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Unrelated emails grouped by coincidental subject | Medium | Medium | Display thread indicator, allow collapse to verify |
| Performance degradation with large email lists | High | Low | Subject normalization is O(n), minimal overhead |
| Selection state confusion with collapsed threads | Medium | Medium | Clear UI distinction, selection applies to visible email |
| Breaking existing keymaps/workflows | High | Low | Preserve all existing functionality, threading is additive |

## Implementation Phases

### Phase 1: Subject Normalization and Thread Data Structure [COMPLETED]

**Goal**: Create the foundation for thread grouping with subject normalization and thread index data structure.

**Tasks**:
- [ ] Create `lua/neotex/plugins/tools/himalaya/utils/threading.lua` module
- [ ] Implement `normalize_subject()` function to strip Re:, AW:, Fwd:, FW:, SV:, Rif: prefixes
- [ ] Implement `build_thread_index()` function to group emails by normalized subject
- [ ] Add thread index data structure with: normalized_subject, emails array, latest_date, thread_count, has_unread
- [ ] Add unit tests for subject normalization patterns
- [ ] Add unit tests for thread index building

**Timing**: 1.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/utils/threading.lua` - New file
- `lua/neotex/plugins/tools/himalaya/test/unit/utils/test_threading.lua` - New test file

**Verification**:
- Unit tests pass for subject normalization
- Thread index correctly groups emails by normalized subject
- Latest email per thread is correctly identified

---

### Phase 2: Thread-Aware Email List Formatting [COMPLETED]

**Goal**: Modify format_email_list() to display thread groups with count indicators in collapsed view.

**Tasks**:
- [ ] Add threading state to module state (threading_enabled, expanded_threads set)
- [ ] Modify `format_email_list()` to accept optional thread_index parameter
- [ ] Implement `format_threaded_email_list()` function for collapsed thread view
- [ ] Add thread count indicator format: `[ ][N] Sender | Subject  Date` where `[N]` is thread count
- [ ] Update line metadata to include thread information (is_thread_root, thread_id, thread_count)
- [ ] Preserve existing format for single-email threads (no visual change)
- [ ] Update process_email_list_results() to build thread index before formatting

**Timing**: 2 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Modify format_email_list()
- `lua/neotex/plugins/tools/himalaya/utils/threading.lua` - Add formatting helpers

**Verification**:
- Emails with same normalized subject appear as single entry with count
- Single-email threads display normally (no count indicator)
- Thread groups show most recent email's date
- Line metadata includes thread information for navigation

---

### Phase 3: Expand/Collapse Thread Functionality [COMPLETED]

**Goal**: Implement keybindings and UI for expanding/collapsing thread groups.

**Tasks**:
- [ ] Add `expanded_threads` set to track which threads are expanded
- [ ] Implement `toggle_thread_expansion()` function
- [ ] Add keymap `<Tab>` or `zo`/`zc` for thread expand/collapse
- [ ] Implement visual indentation for expanded thread children (2-space indent)
- [ ] Update cursor navigation to handle expanded threads correctly
- [ ] Update selection behavior for expanded threads (select individual email, not thread)
- [ ] Implement `expand_all_threads()` and `collapse_all_threads()` functions
- [ ] Add keymaps `zR` (expand all) and `zM` (collapse all)

**Timing**: 2 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Add expand/collapse logic
- `lua/neotex/plugins/tools/himalaya/core/config.lua` - Add keymaps for threading
- `lua/neotex/plugins/tools/himalaya/utils/threading.lua` - Add expansion state management

**Verification**:
- Tab/zo expands thread to show all emails with indentation
- Tab/zc collapses expanded thread back to single line
- Cursor moves correctly through expanded/collapsed threads
- Selection works on individual emails within expanded threads
- zR/zM expand/collapse all threads

---

### Phase 4: Configuration and User Preferences [IN PROGRESS]

**Goal**: Add configuration options for thread grouping behavior.

**Tasks**:
- [ ] Add `threading.enabled` config option (default: true)
- [ ] Add `threading.default_collapsed` config option (default: true)
- [ ] Add `threading.show_count` config option (default: true)
- [ ] Implement `:HimalayaThreadingToggle` command
- [ ] Add threading state persistence across sessions
- [ ] Update config validation to include threading options
- [ ] Document configuration options in plugin help

**Timing**: 1 hour

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/core/config.lua` - Add threading config options
- `lua/neotex/plugins/tools/himalaya/core/state.lua` - Add threading state persistence
- `lua/neotex/plugins/tools/himalaya/commands/init.lua` - Add toggle command

**Verification**:
- Threading can be disabled via config
- Default collapsed/expanded state works correctly
- Toggle command switches between threaded and flat views
- State persists across sidebar open/close

---

### Phase 5: Integration Testing and Edge Cases [NOT STARTED]

**Goal**: Comprehensive testing and handling of edge cases.

**Tasks**:
- [ ] Test with emails having empty subjects
- [ ] Test with emails having only Re:/AW: as subject
- [ ] Test interaction with page caching (ensure thread state survives pagination)
- [ ] Test interaction with email selection (multi-select across threads)
- [ ] Test interaction with email preview (preview individual email in thread)
- [ ] Test performance with 100+ emails per thread
- [ ] Test draft folder behavior (drafts should not be threaded)
- [ ] Update scheduled emails section to not interfere with threading
- [ ] Create integration test for full threading workflow

**Timing**: 1.5 hours

**Files to modify**:
- `lua/neotex/plugins/tools/himalaya/test/features/test_threading.lua` - New integration test
- `lua/neotex/plugins/tools/himalaya/ui/email_list.lua` - Edge case handling

**Verification**:
- All edge cases handled gracefully
- No regression in existing functionality
- Performance acceptable with large thread counts
- Integration test passes

## Testing & Validation

- [ ] Unit tests for subject normalization (all prefix patterns)
- [ ] Unit tests for thread index building
- [ ] Integration test for expand/collapse workflow
- [ ] Manual testing with real email threads
- [ ] Performance test with 100+ emails in single thread
- [ ] Regression test for existing email list functionality
- [ ] Verify selection/preview work correctly with threads

## Artifacts & Outputs

- `lua/neotex/plugins/tools/himalaya/utils/threading.lua` - New threading module
- `lua/neotex/plugins/tools/himalaya/test/unit/utils/test_threading.lua` - Unit tests
- `lua/neotex/plugins/tools/himalaya/test/features/test_threading.lua` - Integration tests
- `specs/081_implement_himalaya_email_thread_grouping/summaries/implementation-summary-YYYYMMDD.md` - Summary

## Rollback/Contingency

If implementation causes issues:
1. Threading is opt-in via config flag - can be disabled without code changes
2. Existing format_email_list() logic preserved - flat view always available
3. No database/state schema changes - clean rollback possible
4. Delete threading.lua and revert email_list.lua changes to restore original behavior
