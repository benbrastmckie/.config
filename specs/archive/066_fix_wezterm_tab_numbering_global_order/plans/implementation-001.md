# Implementation Plan: Task #66

- **Task**: 66 - fix_wezterm_tab_numbering_global_order
- **Status**: [COMPLETED]
- **Effort**: 1-2 hours
- **Dependencies**: None
- **Research Inputs**: [research-001.md](../reports/research-001.md)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: general

## Overview

Fix the mismatch between WezTerm tab bar numbers (per-window, starting at 1) and TTS announcements (global creation order). The solution modifies the `format-tab-title` event handler in wezterm.lua to compute global tab position by iterating all windows via `wezterm.mux.all_windows()`, sorting tab_ids, and finding the current tab's position. This matches the existing TTS algorithm without requiring changes to the TTS hook.

### Research Integration

- **Key Finding**: `tab_id` is globally unique, assigned at creation time. Sorted unique tab_ids represent creation order across all windows.
- **Recommended API**: `wezterm.mux.all_windows()` provides access to all MuxWindow objects; each MuxWindow has `:tabs()` returning MuxTab objects with `:tab_id()` method.
- **Risk Mitigation**: Add pcall wrapper with fallback to `tab.tab_index + 1` if computation fails.

## Goals & Non-Goals

**Goals**:
- Tab bar displays global position matching TTS announcements
- Sequential numbering (1, 2, 3...) across all windows
- Error-resilient implementation with graceful fallback

**Non-Goals**:
- Changing TTS hook behavior (already correct)
- Caching tab positions (fresh computation preferred for reliability)
- Modifying other tab bar formatting (colors, icons, etc.)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `wezterm.mux.all_windows()` unavailable in format-tab-title | High | Low | Add pcall wrapper; fall back to tab_index + 1 |
| Performance with many tabs (50+) | Low | Low | Performance acceptable for typical usage; monitor if needed |
| Tab creation/closure during render | Medium | Low | Fresh computation on each render handles dynamic changes |

## Implementation Phases

### Phase 1: Implement Global Tab Position Computation [COMPLETED]

**Goal**: Modify format-tab-title handler to display global tab position instead of per-window index.

**Tasks**:
- [ ] Read current wezterm.lua and locate format-tab-title handler
- [ ] Add helper function to compute global tab position using wezterm.mux.all_windows()
- [ ] Replace `tab.tab_index + 1` with computed global position
- [ ] Wrap computation in pcall with fallback to tab.tab_index + 1

**Timing**: 30-45 minutes

**Files to modify**:
- `/home/benjamin/.dotfiles/config/wezterm.lua` - Modify format-tab-title event handler

**Implementation Details**:
```lua
-- Helper function to compute global tab position
local function get_global_tab_position(current_tab_id)
  local ok, result = pcall(function()
    local all_tab_ids = {}
    for _, mux_window in ipairs(wezterm.mux.all_windows()) do
      for _, mux_tab in ipairs(mux_window:tabs()) do
        table.insert(all_tab_ids, mux_tab:tab_id())
      end
    end
    table.sort(all_tab_ids)
    for i, tid in ipairs(all_tab_ids) do
      if tid == current_tab_id then
        return i
      end
    end
    return nil
  end)
  return ok and result or nil
end

-- In format-tab-title handler:
local tab_number = get_global_tab_position(tab.tab_id) or (tab.tab_index + 1)
```

**Verification**:
- Open 2+ WezTerm windows with multiple tabs each
- Tab numbers should be unique across all windows
- Tab numbers should match TTS announcements
- Closing/creating tabs should update numbers correctly

---

### Phase 2: Manual Testing with Multiple Windows [COMPLETED]

**Goal**: Verify global tab numbering works correctly across multiple WezTerm windows.

**Tasks**:
- [ ] Open 3 WezTerm windows
- [ ] Create tabs in different windows (Window 1: 2 tabs, Window 2: 3 tabs, Window 3: 1 tab)
- [ ] Verify tab numbers are globally sequential (1-6 total)
- [ ] Close middle tabs and verify renumbering
- [ ] Create new tabs and verify correct position assignment
- [ ] Trigger TTS notification and confirm tab number matches display

**Timing**: 15-20 minutes

**Files to modify**: None (testing phase)

**Verification**:
- All tabs have unique numbers across windows
- Numbers match what TTS announces
- No rendering errors or fallbacks triggered

---

### Phase 3: Documentation Update [COMPLETED]

**Goal**: Document the global tab numbering behavior in the wezterm integration context file.

**Tasks**:
- [ ] Update wezterm-integration.md context file with global numbering explanation
- [ ] Note the relationship between tab_id and global position
- [ ] Document the fallback behavior if computation fails

**Timing**: 10-15 minutes

**Files to modify**:
- `/home/benjamin/.config/nvim/.claude/context/project/hooks/wezterm-integration.md` - Add section on global tab numbering

**Verification**:
- Documentation accurately describes the implementation
- Fallback behavior is documented

## Testing & Validation

- [ ] Tab bar shows global position numbers (not per-window)
- [ ] TTS announcements match displayed tab numbers
- [ ] Multiple windows each show correct global positions
- [ ] Tab creation assigns correct incremental number
- [ ] Tab closure causes appropriate renumbering
- [ ] No errors in WezTerm logs when switching tabs
- [ ] Fallback to per-window numbering works if mux unavailable

## Artifacts & Outputs

- plans/implementation-001.md (this file)
- summaries/implementation-summary-YYYYMMDD.md (after completion)

## Rollback/Contingency

If the global numbering causes issues:
1. Revert the format-tab-title handler to use `tab.tab_index + 1`
2. The fallback in the helper function should handle most edge cases automatically
3. Full rollback is a single-line change in wezterm.lua
