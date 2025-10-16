# Bufferline Tab Visibility Issues Research Report

## Metadata
- **Date**: 2025-10-01
- **Scope**: Bufferline tab visibility behavior when switching between normal buffers, terminals, and sidebars
- **Primary Directory**: /home/benjamin/.config/nvim
- **Files Analyzed**: 6 configuration files related to bufferline, terminal behavior, and buffer management
- **Report Number**: 023

## Executive Summary

The Neovim configuration exhibits tab visibility issues in the bufferline plugin where tabs disappear when switching to terminal buffers or sidebars (Neo-tree, Claude Code), and only reappear when returning to the original buffer. This is caused by the interaction between:

1. **Dynamic `showtabline` management** - The tabline is hidden/shown based on buffer count and context
2. **Buffer listing behavior** - Terminal and special buffers are marked as `buflisted = false`
3. **Missing window/buffer event handlers** - No autocmds to preserve tabline visibility when switching windows
4. **`always_show_bufferline = false`** - Configured to hide bufferline when only one buffer exists

The core issue is that when switching to unlisted terminal/sidebar buffers, the bufferline disappears because the system treats these as "no visible buffers" contexts, even though regular file buffers remain open in other windows.

## Background

### User Problem Statement
The user reports two related visibility issues:
1. Tabs for git-ignored or git-tracked files sometimes don't show properly in the bufferline
2. When in terminal or Claude Code sidebar, the tab for the previously focused buffer disappears but reappears when switching back
3. Expected behavior: Always see the tab for the last-focused regular buffer, even when terminal/sidebar is active

### Bufferline Configuration Context
The bufferline.nvim plugin provides a tab-like interface for managing buffers in Neovim. The configuration uses several mechanisms to control when tabs are visible:
- Event-driven loading via `BufAdd` event
- Dynamic `showtabline` option management
- Custom filtering to exclude certain buffer types
- Integration with Alpha dashboard

## Current State Analysis

### 1. Bufferline Configuration
**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua`

#### Key Configuration Settings

**Initial Setup (lines 7-21)**:
```lua
init = function()
  vim.opt.showtabline = 0  -- Hidden at startup

  vim.api.nvim_create_autocmd("BufAdd", {
    callback = function()
      local buffers = vim.fn.getbufinfo({buflisted = 1})
      if #buffers > 1 then
        vim.opt.showtabline = 2  -- Show when multiple buffers
      end
    end,
  })
end
```

**Problem**: Only checks on `BufAdd` event, not on window/buffer switches.

**Main Configuration (lines 26-48)**:
```lua
always_show_bufferline = false  -- Only show when more than one buffer
custom_filter = function(buf_number, buf_numbers)
  local buf_ft = vim.bo[buf_number].filetype
  local buf_name = vim.api.nvim_buf_get_name(buf_number)

  if buf_ft == "qf" then return false end
  if string.match(buf_name, "claude%-code") then return false end

  return true
end
```

**Analysis**:
- `always_show_bufferline = false` causes bufferline to hide when it thinks only one buffer exists
- Filter excludes quickfix and claude-code buffers, which is correct
- However, when switching to terminal/sidebar, `showtabline` remains set but bufferline doesn't render

**Alpha Dashboard Integration (lines 111-126)**:
```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "AlphaReady",
  callback = function()
    vim.opt.showtabline = 0  -- Hide for dashboard
  end,
})

vim.api.nvim_create_autocmd("BufUnload", {
  buffer = 0,
  callback = function()
    vim.opt.showtabline = 2  -- Re-enable after dashboard
  end,
})
```

**Analysis**: Good pattern for contextual visibility, but not applied to terminal/sidebar transitions.

### 2. Claude Code Terminal Configuration
**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`

**Terminal Behavior (lines 78-104)**:
```lua
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*claude*",
  callback = function()
    vim.bo.buflisted = false      -- Remove from buffer list
    vim.bo.buftype = "terminal"
    vim.bo.bufhidden = "hide"
  end,
})

vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
  pattern = "*",
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    if bufname:match("claude") or bufname:match("ClaudeCode") then
      vim.bo.buflisted = false
      vim.bo.bufhidden = "hide"
    end
  end,
})
```

**Analysis**:
- Terminal buffers are correctly marked as unlisted
- When entering Claude terminal, `BufEnter` fires but no tabline visibility handling occurs
- No autocmd to maintain `showtabline = 2` when switching to terminal

### 3. Neo-tree Sidebar Configuration
**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua`

**Neo-tree has no explicit showtabline management**, but references bufferline:
```lua
-- Line 346: Checks for BufferLineFill highlight
local bg_groups = {
  "BufferLineFill",
  "BufferlineBackground",
  "TabLineFill",
  -- ...
}
```

**Analysis**: Neo-tree buffers are implicitly handled by bufferline's filtering, but no explicit visibility preservation.

### 4. Buffer Management Utilities
**Location**: `/home/benjamin/.config/nvim/lua/neotex/util/buffer.lua`

The buffer utility module provides navigation and management functions but **does not handle tabline visibility**. Key observations:
- `goto_buffer()` switches buffers but doesn't ensure tabline visibility
- No integration with `showtabline` option management
- Buffer state changes don't trigger bufferline refresh

## Key Findings

### Finding 1: Conditional Showtabline Logic is Incomplete

**Current Behavior**:
```lua
-- Only triggers on BufAdd
vim.api.nvim_create_autocmd("BufAdd", {
  callback = function()
    local buffers = vim.fn.getbufinfo({buflisted = 1})
    if #buffers > 1 then
      vim.opt.showtabline = 2
    end
  end,
})
```

**Problem**:
- Doesn't handle `BufEnter`, `WinEnter`, or `TermLeave` events
- When switching to terminal/sidebar, tabline disappears even though listed buffers still exist
- No mechanism to preserve visibility state across window switches

### Finding 2: always_show_bufferline Conflicts with Terminal Workflow

**Setting**: `always_show_bufferline = false`

**Consequence**: When the active window contains an unlisted buffer (terminal/sidebar), bufferline thinks "only 0-1 listed buffers visible" and hides itself.

**Expected**: Should show tabs for all listed buffers regardless of what's in the current window.

### Finding 3: Missing TermLeave/WinLeave Handlers

When leaving a regular buffer to enter terminal:
1. `BufLeave` fires for the file buffer
2. `BufEnter` fires for the terminal buffer
3. **No code preserves `showtabline = 2`**
4. Bufferline recalculates and hides (thinks only 0 listed buffers)

When returning from terminal to file buffer:
1. `BufEnter` fires for the file buffer
2. Bufferline refreshes and shows tabs again

**Gap**: No persistence of tabline visibility during temporary switches.

### Finding 4: Git-Ignored File Behavior

User mentions git-ignored files don't show properly. Analysis shows:
- No special handling for git-ignored files in `custom_filter`
- Bufferline doesn't filter by git status by default
- Likely related to the `always_show_bufferline = false` issue

**Hypothesis**: Git-ignored files may be opened in certain contexts where bufferline thinks "not enough buffers to show" and hides itself.

## Technical Deep Dive

### Event Flow for Terminal Switch

```
[File Buffer Active] -> User presses <C-c> to open Claude
↓
BufLeave (file buffer) - no showtabline handling
↓
WinEnter (terminal window) - no showtabline handling
↓
BufEnter (terminal buffer) - sets buflisted=false, no visibility preservation
↓
Bufferline evaluates: getbufinfo({buflisted=1})
  - Finds listed buffers exist BUT always_show_bufferline=false
  - Current window has unlisted buffer
  - Decision: Hide bufferline
↓
[Result: Tabs disappear even though file buffer still exists]
```

### Event Flow for Returning from Terminal

```
[Terminal Active] -> User presses <C-c> to return
↓
BufLeave (terminal buffer)
↓
WinEnter (file buffer window)
↓
BufEnter (file buffer)
  - Buffer is listed
  - Bufferline re-evaluates
  - Finds listed buffer in current window
  - Decision: Show bufferline
↓
[Result: Tabs reappear]
```

### The Core Problem

The issue is **context-awareness**: bufferline doesn't distinguish between:
- **Session has only one buffer** (should hide)
- **Session has multiple buffers, but current window shows unlisted buffer** (should still show)

Current logic: `if #listed_buffers > 1 and always_show_bufferline == false then show()`

Needed logic: `if #listed_buffers > 1 OR (any_window_has_listed_buffer and not_in_alpha_dashboard) then show()`

## Recommendations

### Solution 1: Enable always_show_bufferline (Simple Fix)

**Change**: Set `always_show_bufferline = true` in bufferline configuration

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua:28`

```lua
options = {
  mode = "buffers",
  always_show_bufferline = true,  -- Changed from false
  -- ...
}
```

**Pros**:
- Simple one-line change
- Ensures tabs always visible when any listed buffers exist
- No complex event handling needed

**Cons**:
- Tabs will show even with single buffer (may be unwanted)
- Doesn't preserve "minimal on startup" aesthetic

**Recommendation Level**: ⭐⭐⭐⭐ (High - Simple and effective)

### Solution 2: Enhanced showtabline Event Handling (Robust Fix)

**Change**: Add autocmds for window/buffer events to preserve tabline visibility

**Implementation**:
```lua
-- Add to bufferline.lua config function after line 126
local function ensure_tabline_visible()
  local buffers = vim.fn.getbufinfo({buflisted = 1})
  if #buffers > 1 then
    vim.opt.showtabline = 2
  elseif #buffers <= 1 then
    vim.opt.showtabline = 0
  end
end

-- Enhanced event handling
vim.api.nvim_create_autocmd({"BufEnter", "WinEnter"}, {
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    local filetype = vim.bo.filetype

    -- Don't show in alpha dashboard
    if filetype == "alpha" then
      vim.opt.showtabline = 0
      return
    end

    -- Always check and update tabline visibility
    ensure_tabline_visible()
  end,
  desc = "Preserve bufferline visibility across window switches"
})

-- Ensure tabline shows when leaving terminal
vim.api.nvim_create_autocmd("TermLeave", {
  pattern = "*",
  callback = function()
    vim.defer_fn(ensure_tabline_visible, 10)
  end,
  desc = "Restore bufferline when leaving terminal"
})
```

**Pros**:
- Maintains "hide on single buffer" behavior
- Preserves tabline during terminal/sidebar usage
- Graceful handling of alpha dashboard

**Cons**:
- More complex implementation
- Potential performance impact from frequent checks
- Need to test interaction with existing autocmds

**Recommendation Level**: ⭐⭐⭐⭐⭐ (Highest - Solves root cause)

### Solution 3: Conditional always_show_bufferline (Hybrid Approach)

**Change**: Use `always_show_bufferline = true` but add special handling for single buffer case

**Implementation**:
```lua
-- In deferred setup (line 62)
bufferline.setup({
  options = {
    always_show_bufferline = true,
    -- ...
  },
})

-- Add special case for single buffer
vim.api.nvim_create_autocmd({"BufAdd", "BufDelete"}, {
  callback = function()
    local buffers = vim.fn.getbufinfo({buflisted = 1})
    local filetype = vim.bo.filetype

    if filetype == "alpha" or #buffers <= 1 then
      vim.opt.showtabline = 0
    else
      vim.opt.showtabline = 2
    end
  end,
  desc = "Hide bufferline for single buffer or alpha"
})
```

**Pros**:
- Combines simplicity with customization
- Preserves minimal aesthetic
- Solves terminal/sidebar issue

**Cons**:
- Still more complex than Solution 1
- May have edge cases with buffer delete timing

**Recommendation Level**: ⭐⭐⭐⭐ (High - Good balance)

### Solution 4: Custom Bufferline Module (Advanced)

**Change**: Create a dedicated bufferline manager module

**Location**: Create `/home/benjamin/.config/nvim/lua/neotex/util/bufferline-manager.lua`

**Benefits**:
- Centralized visibility logic
- Easier to debug and maintain
- Can add features like "pin tab visibility" command

**Recommendation Level**: ⭐⭐⭐ (Medium - Over-engineering for this issue)

## Implementation Priority

1. **Immediate Fix**: Implement Solution 2 (Enhanced showtabline Event Handling)
   - Addresses root cause
   - Maintains desired UX
   - Future-proof

2. **Quick Alternative**: Implement Solution 1 if Solution 2 causes issues
   - One-line fallback
   - Guaranteed to work

3. **Future Enhancement**: Consider Solution 4 for long-term maintainability
   - Only if additional bufferline customization needed

## Testing Plan

### Test Cases

1. **Single Buffer Startup**
   - Expected: No tabline visible
   - Test: Open Neovim with single file

2. **Multiple Buffer Startup**
   - Expected: Tabline visible
   - Test: Open multiple files

3. **Terminal Switch**
   - Expected: Tabline remains visible when switching to terminal
   - Test: Open file buffer, press `<C-c>`, verify tabs still show

4. **Sidebar Switch**
   - Expected: Tabline remains visible with Neo-tree open
   - Test: Toggle Neo-tree, verify tabs persist

5. **Git-Ignored Files**
   - Expected: Tabs visible for git-ignored files
   - Test: Open `.env` or similar, verify tab shows

6. **Alpha Dashboard**
   - Expected: No tabline on dashboard
   - Test: Return to alpha, verify clean display

7. **Buffer Close**
   - Expected: Tabline hides when closing to single buffer
   - Test: Close all but one buffer, verify tabline disappears

## References

### Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua:9` - showtabline initialization
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua:28` - always_show_bufferline setting
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/bufferline.lua:115` - Alpha integration autocmds
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua:78` - TermOpen autocmd for Claude
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua` - Neo-tree configuration

### Related Autocmds
- `BufAdd` (line 12) - Current showtabline trigger
- `TermOpen` (claudecode.lua:78) - Terminal buffer configuration
- `BufEnter/BufWinEnter` (claudecode.lua:93) - Claude buffer tracking
- `User AlphaReady` (bufferline.lua:112) - Dashboard integration

### External Resources
- [bufferline.nvim GitHub](https://github.com/akinsho/bufferline.nvim)
- [Stack Overflow: bufferline not appearing](https://stackoverflow.com/questions/78923945/neovim-akinsho-bufferline-plugin-tabs-not-appearing)
- Neovim `:help showtabline`
- Neovim `:help buflisted`

## Appendix: Diagnostic Commands

To investigate bufferline visibility issues in a live session:

```vim
" Check current showtabline setting
:set showtabline?

" List all buffers with listing status
:lua vim.print(vim.fn.getbufinfo())

" Check bufferline state
:lua vim.print(require('bufferline.state'))

" Force bufferline refresh
:lua require('bufferline.ui').refresh()

" List all autocmds for bufferline
:au BufAdd,BufEnter,WinEnter
```

## Conclusion

The bufferline tab visibility issue stems from incomplete event handling when switching between normal buffers and unlisted terminal/sidebar buffers. The `always_show_bufferline = false` setting, combined with the lack of `BufEnter`/`WinEnter` autocmds to preserve `showtabline = 2`, causes tabs to disappear when entering contexts with unlisted buffers.

**Recommended Solution**: Implement Solution 2 (Enhanced showtabline Event Handling) to add proper event handling for window switches while maintaining the desired "minimal on startup" behavior.

**Expected Outcome**:
- Tabs remain visible when switching to terminal/Claude Code sidebar
- Tabs remain visible when opening git-ignored files
- Tabs still hide appropriately on alpha dashboard and single-buffer sessions
- Smooth transition between all buffer contexts
