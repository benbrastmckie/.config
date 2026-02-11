# Research Report: Task #66

**Task**: 66 - fix_wezterm_tab_numbering_global_order
**Started**: 2026-02-11T12:00:00Z
**Completed**: 2026-02-11T12:15:00Z
**Effort**: 1-2 hours implementation
**Dependencies**: None
**Sources/Inputs**: Codebase analysis, WezTerm documentation, wezterm CLI inspection
**Artifacts**: This report
**Standards**: report-format.md

## Executive Summary

- TTS currently announces global tab position (1-indexed position in sorted unique tab_id list)
- WezTerm tab bar displays per-window tab numbers (tab.tab_index + 1)
- The mismatch occurs because `format-tab-title` receives only per-window `tab_index`, while TTS uses global `tab_id` ordering
- Solution: Modify wezterm.lua to track and display global tab numbers using `wezterm.mux.all_windows()` or `wezterm.GLOBAL` state
- All changes belong in `.dotfiles/config/wezterm.lua` (NixOS configuration); no neovim changes required

## Context & Scope

The user runs multiple WezTerm windows, each with multiple tabs. When Claude Code finishes a task, TTS announces "Tab N" based on global tab creation order. However, WezTerm's tab bar shows per-window numbering (each window starts at 1), causing confusion.

**Example Scenario**:
- Window 1: Tabs with tab_ids 0, 1, 8, 12, 14 (displayed as 1, 2, 3, 4, 5)
- Window 2: Tabs with tab_ids 7, 13 (displayed as 1, 2)
- TTS announces "Tab 5" for tab_id 7 (5th unique tab globally)
- User sees "1" in window 2 tab bar

## Findings

### Current TTS Implementation

**File**: `/home/benjamin/.config/nvim/.claude/hooks/tts-notify.sh`

The TTS hook calculates global tab position by:
1. Getting all panes via `wezterm cli list --format=json`
2. Finding current tab's `tab_id` from `WEZTERM_PANE`
3. Getting unique `tab_id` values sorted (jq `unique` preserves order)
4. Finding 1-indexed position of current tab_id in that list

```bash
UNIQUE_TAB_IDS=$(echo "$ALL_PANES" | jq -r '[.[].tab_id] | unique | .[]')
# Then iterates to find position
```

**Key Insight**: The `tab_id` is a globally unique identifier assigned at tab creation time. The sorted unique list represents creation order across all windows.

### Current WezTerm Tab Display

**File**: `/home/benjamin/.dotfiles/config/wezterm.lua`

The `format-tab-title` handler uses:
```lua
local title = tostring(tab.tab_index + 1) .. " " .. project_name
```

Where `tab.tab_index` is "the logical tab position within its containing window, with 0 indicating the leftmost tab" (per WezTerm docs).

### WezTerm API Analysis

The `format-tab-title` event receives:
- `tab` - TabInformation for current tab (includes `tab_id`, `tab_index`, `window_id`)
- `tabs` - Array of TabInformation for tabs **in the same window only**
- No direct access to tabs in other windows

Available APIs for global access:
- `wezterm.mux.all_windows()` - Returns all MuxWindow objects
- `wezterm.GLOBAL` - Persistent global state storage (copy-on-access semantics)

**Limitation**: `format-tab-title` is synchronous and may not support async operations. However, `wezterm.mux.all_windows()` should be available since it's not async.

### Observed tab_id Behavior

From `wezterm cli list`:
```
tab_id  window_id  pane_id
0       0          0
1       0          1
8       0          8
12      0          12
14      0          14
7       2          7
13      2          13
```

The `tab_id` values (0, 1, 7, 8, 12, 13, 14) when sorted represent the global creation order. This matches what TTS uses.

## Recommendations

### Solution A: Compute Global Position in format-tab-title (Recommended)

Modify `format-tab-title` to calculate global position using `wezterm.mux`:

```lua
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  -- Get global tab position
  local global_position = 1
  local all_tab_ids = {}

  -- Collect all tab_ids across all windows
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    for _, mux_tab in ipairs(mux_window:tabs()) do
      table.insert(all_tab_ids, mux_tab:tab_id())
    end
  end

  -- Sort to get creation order
  table.sort(all_tab_ids)

  -- Find position of current tab
  for i, tid in ipairs(all_tab_ids) do
    if tid == tab.tab_id then
      global_position = i
      break
    end
  end

  -- Use global_position instead of tab.tab_index + 1
  local title = tostring(global_position) .. " " .. project_name
  -- ... rest of handler
end)
```

**Pros**:
- Single source of truth - matches TTS exactly
- No state synchronization needed
- Computed fresh each render

**Cons**:
- Slight performance overhead (iterates all windows/tabs on each title update)
- `wezterm.mux.all_windows()` availability in format-tab-title needs verification

### Solution B: Cache Global Positions in wezterm.GLOBAL

Use event handlers to maintain a global tab_id to position mapping:

```lua
-- Update on tab creation/destruction events
local function update_global_positions()
  local tab_ids = {}
  for _, mux_window in ipairs(wezterm.mux.all_windows()) do
    for _, mux_tab in ipairs(mux_window:tabs()) do
      table.insert(tab_ids, mux_tab:tab_id())
    end
  end
  table.sort(tab_ids)

  local positions = {}
  for i, tid in ipairs(tab_ids) do
    positions[tostring(tid)] = i
  end
  wezterm.GLOBAL.tab_positions = positions
end

-- Hook into relevant events
wezterm.on("window-config-reloaded", function() update_global_positions() end)
-- Would also need new-tab, close-tab events if available

wezterm.on("format-tab-title", function(tab, ...)
  local positions = wezterm.GLOBAL.tab_positions or {}
  local global_pos = positions[tostring(tab.tab_id)] or (tab.tab_index + 1)
  -- ...
end)
```

**Pros**:
- O(1) lookup in format-tab-title
- Amortizes computation cost

**Cons**:
- Requires state synchronization
- May miss updates if events don't fire reliably
- Copy-on-access semantics require careful handling

### Solution C: Display tab_id Directly

Simply display the `tab_id` instead of position:

```lua
local title = tostring(tab.tab_id + 1) .. " " .. project_name
```

And modify TTS to also use `tab_id + 1`:

```bash
TAB_NUM=$((CURRENT_TAB_ID + 1))
```

**Pros**:
- Simplest implementation
- No global state or iteration needed

**Cons**:
- Numbers may have gaps (e.g., 1, 2, 8, 13)
- Not intuitive sequential numbering
- Requires changes to both files

## Decisions

**Recommended Approach**: Solution A (compute in format-tab-title)

Rationale:
1. Maintains intuitive sequential numbering (1, 2, 3, 4, 5, 6, 7)
2. Single location for implementation (.dotfiles/config/wezterm.lua)
3. No changes needed to TTS hook
4. Fresh computation avoids stale state bugs
5. Performance overhead likely negligible for typical tab counts (<20 tabs)

## Implementation Location

All changes belong in:
- **Primary**: `/home/benjamin/.dotfiles/config/wezterm.lua`
  - Modify `format-tab-title` handler to compute global position
  - No changes to keybindings or other handlers needed

- **No changes needed**:
  - `/home/benjamin/.config/nvim/.claude/hooks/tts-notify.sh` - already using correct global ordering
  - `/home/benjamin/.config/nvim/lua/neotex/lib/wezterm.lua` - unrelated to tab numbering display

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `wezterm.mux.all_windows()` not available in format-tab-title | Low | Test first; fall back to Solution B if needed |
| Performance degradation with many tabs | Low | Tab count typically <20; optimize only if measured |
| Rendering issues if computation fails | Medium | Add pcall wrapper, fall back to tab_index + 1 |

## Appendix

### Search Queries Used
- "wezterm lua tab_id global order vs per-window tab_index format-tab-title"
- "wezterm mux all_windows global tab list lua API across windows"
- "wezterm format-tab-title mux.all_windows global tab numbering access from event handler"

### Key Documentation References
- [TabInformation object](https://wezterm.org/config/lua/TabInformation.html) - tab_id, tab_index fields
- [format-tab-title event](https://wezterm.org/config/lua/window-events/format-tab-title.html) - function signature and limitations
- [wezterm.mux module](https://wezterm.org/config/lua/wezterm.mux/index.html) - all_windows() function
- [GitHub Discussion #2983](https://github.com/wezterm/wezterm/discussions/2983) - wezterm.GLOBAL usage patterns

### Files Analyzed
- `/home/benjamin/.config/nvim/.claude/hooks/tts-notify.sh` - TTS implementation
- `/home/benjamin/.config/nvim/.claude/hooks/wezterm-task-number.sh` - Task number OSC hook
- `/home/benjamin/.dotfiles/config/wezterm.lua` - WezTerm configuration with format-tab-title
- `/home/benjamin/.config/nvim/lua/neotex/lib/wezterm.lua` - Neovim wezterm OSC library
- `/home/benjamin/.config/nvim/.claude/context/project/hooks/wezterm-integration.md` - Integration documentation
