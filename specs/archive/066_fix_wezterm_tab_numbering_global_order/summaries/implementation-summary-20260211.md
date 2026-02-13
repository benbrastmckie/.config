# Implementation Summary: Task #66

**Completed**: 2026-02-11
**Duration**: ~30 minutes

## Changes Made

Implemented global tab numbering in WezTerm to match TTS announcement tab numbers. Previously, each WezTerm window displayed per-window tab numbers (1, 2, 3...) while TTS announced global creation order. Now tab bar displays match TTS.

## Files Modified

- `/home/benjamin/.dotfiles/config/wezterm.lua` - Added `get_global_tab_position()` helper function and integrated it into `format-tab-title` handler with pcall fallback
- `/home/benjamin/.config/nvim/.claude/context/project/hooks/wezterm-integration.md` - Added "Global Tab Numbering" documentation section

## Implementation Details

### Helper Function

Added `get_global_tab_position(current_tab_id)` that:
1. Iterates all windows via `wezterm.mux.all_windows()`
2. Collects tab IDs from all tabs across all windows
3. Sorts tab IDs (ascending = creation order since IDs are assigned sequentially)
4. Returns 1-indexed position of current tab ID

### Integration

Modified tab title building to use:
```lua
local tab_number = get_global_tab_position(tab.tab_id) or (tab.tab_index + 1)
```

The fallback to `tab.tab_index + 1` ensures tabs always display a number even if global computation fails.

## Verification

- [x] Helper function wrapped in pcall for error safety
- [x] Fallback behavior preserves per-window numbering if mux unavailable
- [x] Documentation updated with algorithm explanation and example

## Manual Verification Required

User should verify:
- Open 2+ WezTerm windows with multiple tabs
- Tab numbers should be unique across all windows
- Tab numbers should match TTS announcements
- Closing/creating tabs should update numbers correctly

## Notes

The change is in `.dotfiles/` which is managed by NixOS home-manager. After rebuilding the NixOS configuration, WezTerm will pick up the changes on next launch.
