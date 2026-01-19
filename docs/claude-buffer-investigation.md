# Claude Code Buffer Leak Investigation

## Problem Statement

When Claude Code is open in the sidebar and the user closes buffers in the main editor area, Neovim reliably displays the Claude terminal buffer in the main editor window after closing the second buffer. This does not happen with other sidebar tools.

**Reproduction steps:**
1. Open Claude Code in the sidebar
2. Open 2+ files in the main editor
3. Close the first buffer - switches to another file (correct)
4. Close the second buffer - switches to Claude Code in main editor (wrong)

**Key observation:** This problem does NOT occur with:
- **nvim-tree** - File explorer stays in sidebar, never appears in main editor
- **Regular terminal** - Terminal sidebars don't leak into main editor

This suggests Claude Code is missing some configuration that nvim-tree and terminal plugins use to prevent this behavior.

## Comparison: Why nvim-tree and toggleterm Don't Have This Problem

### nvim-tree Buffer Settings

nvim-tree uses these buffer/window options ([source](https://github.com/nvim-tree/nvim-tree.lua/blob/master/lua/nvim-tree/view.lua)):

```lua
-- Buffer options
buftype    = "nofile"   -- NOT a file, special buffer
bufhidden  = "wipe"     -- Wiped when hidden (not just hidden)
buflisted  = false      -- Not in buffer list
filetype   = "NvimTree" -- Custom filetype for identification
modifiable = false      -- Read-only

-- Window options
winfixwidth  = true     -- Prevents width changes
winfixheight = true     -- Prevents height changes
```

**Key insight:** `buftype=nofile` tells Neovim this is a special non-file buffer that should not be considered for normal buffer operations.

### toggleterm.nvim Approach

The toggleterm.nvim maintainer was asked this exact question in [Issue #389](https://github.com/akinsho/toggleterm.nvim/issues/389): "How to prevent other buffers from taking over the terminal window?"

**Their answer:** Use [stickybuf.nvim](https://github.com/stevearc/stickybuf.nvim). The maintainer explicitly stated this is "definitely a desirable trait/feature" but recommended the dedicated plugin rather than building it into toggleterm.

### Claude Code Current Settings

```lua
buftype   = "terminal"  -- Terminal buffer (required for terminal to work)
bufhidden = "hide"      -- Hidden when abandoned
buflisted = false       -- Not in buffer list
```

**The problem:** `buftype=terminal` cannot be changed to `nofile` because Claude Code needs actual terminal functionality. Terminal buffers are treated differently by Neovim's buffer selection algorithm - they can still be selected as alternates or fallbacks even when unlisted.

## Root Cause Analysis

### How Neovim Selects the Next Buffer

When a buffer is deleted, Neovim uses this priority order:

1. **Jump list** - Most recent entry pointing to a loaded buffer
2. **Alternate buffer** (`#`) - The previous buffer in that window
3. **Any available buffer** - Fallback when nothing else works

### Why Claude Gets Selected

The Claude terminal buffer has these settings:
- `buflisted = false` - Excluded from buffer lists
- `buftype = "terminal"` - Marked as terminal
- `bufhidden = "hide"` - Hidden when abandoned, not deleted

**The problem**: `buflisted = false` only affects buffer list commands (`:buffers`, `:bnext`, buffer pickers). It does **not** prevent:
- The buffer from being in the jump list
- The buffer from being the alternate buffer (`#`)
- Neovim's fallback selection when no other buffers exist

### Two Buffer Deletion Paths

| Method | Command | Selection Algorithm |
|--------|---------|---------------------|
| `<leader>d` | `Snacks.bufdelete()` | Filters by `buflisted=1`, respects unlisted |
| Bufferline X | `bdelete! %d` | Uses jump list, ignores `buflisted` flag |

The native `:bdelete` command uses the jump list algorithm which can select Claude if:
1. User navigated to/from Claude (added to jump list)
2. Claude was the alternate buffer in that window
3. No other buffers remain (fallback to any buffer)

## Solution Options

### Option A: Unify Buffer Deletion (Simplest) - IMPLEMENTED

Change bufferline to use `Snacks.bufdelete()` instead of native `:bdelete`:

```lua
-- In bufferline.lua
close_command = function(bufnr)
  Snacks.bufdelete({ buf = bufnr, force = true })
end,
right_mouse_command = function(bufnr)
  Snacks.bufdelete({ buf = bufnr, force = true })
end,
```

**Pros:**
- Single line change per command
- Consistent behavior everywhere
- Snacks properly filters by `buflisted`

**Cons:**
- Changes next-buffer selection from jump-list-based to MRU-based
- May still fail if Claude becomes the MRU buffer (user focused sidebar)

**Risk**: Medium - behavior change may have edge cases

---

### Option B: Prevent Claude from Entering Jump List

Use `keepjumps` for all programmatic navigation to Claude:

```lua
-- In terminal-state.lua focus_terminal()
-- Replace: vim.api.nvim_set_current_win(wins[1])
-- With: vim.cmd('keepjumps ' .. wins[1] .. 'wincmd w')
```

**Pros:**
- Addresses root cause for native `:bdelete`
- No behavior change for buffer selection algorithm

**Cons:**
- Requires modifying terminal-state.lua
- Doesn't help if user manually clicks Claude sidebar
- No Lua API equivalent for `keepjumps` with `nvim_win_set_buf`

**Risk**: Low-Medium - surgical change but incomplete coverage

---

### Option C: BufEnter Guard with Window Detection

Detect when Claude appears in wrong window and redirect:

```lua
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    -- If Claude terminal entered in wide window (>50%), redirect
    if is_claude_terminal() and window_is_main_editor() then
      switch_to_mru_listed_buffer()
    end
  end,
})
```

**Pros:**
- Catches all cases regardless of cause
- Defensive approach

**Cons:**
- Adds overhead to every BufEnter event
- Window width heuristic may have edge cases
- Can cause visual flicker (brief Claude display before redirect)
- Previous attempts caused slowdowns

**Risk**: Medium-High - complexity and performance concerns

---

### Option D: Accept and Document Behavior

The issue is intermittent and has workarounds:
- Use `<leader>d` instead of clicking X (uses Snacks.bufdelete)
- If Claude appears in main area, press `<C-o>` to jump back or toggle Claude

**Pros:**
- No code changes
- No risk of regressions

**Cons:**
- Doesn't fix the UX issue
- Requires user awareness

**Risk**: None

---

### Option E: Track Sidebar Window Explicitly

Store the sidebar window ID and use it for detection:

```lua
-- On Claude open, store: vim.g.claude_sidebar_winid = win
-- On BufEnter, check: current_win ~= vim.g.claude_sidebar_winid
```

**Pros:**
- More precise than width heuristic

**Cons:**
- Window ID changes if sidebar is closed/reopened
- Requires reliable hook into Claude window creation
- Previous attempts had timing issues

**Risk**: Medium - state management complexity

## Additional Research (2026-01-19)

Option A was tested but **did not resolve the issue** - Claude still appeared in the main window when closing buffers. The problem appears to be deeper than buffer selection logic.

### New Discovery: stickybuf.nvim

[stickybuf.nvim](https://github.com/stevearc/stickybuf.nvim) is a plugin specifically designed to solve this exact problem. It pins buffers to windows and automatically redirects any buffer that tries to open in a pinned window.

**How it works:**
- Stores pinning information in window-local variables
- On `BufEnter`, checks if window is pinned
- If pinned, restores the original buffer and opens the new buffer in an unpinned window
- Built-in support for 18+ plugins (neo-tree, toggleterm, aerial, etc.)

**Configuration for Claude Code:**
```lua
require("stickybuf").setup({
  get_auto_pin = function(bufnr)
    -- Auto-pin Claude Code terminal buffers
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if vim.bo[bufnr].buftype == "terminal" and bufname:match("claude") then
      return "bufnr"  -- Pin by buffer number
    end
    return require("stickybuf").should_auto_pin(bufnr)
  end
})
```

### New Option F: Use stickybuf.nvim (Recommended)

**Pros:**
- Purpose-built solution for this exact problem
- Handles the redirect logic automatically
- Well-maintained, MIT licensed
- Works at the window level, not buffer deletion level
- No performance overhead on every BufEnter (optimized implementation)

**Cons:**
- Adds a new plugin dependency
- May conflict with plugins expecting immediate buffer destruction

**Risk:** Low - established plugin with clear scope

### Related: claude-code.nvim Issue #38

There's an [open issue](https://github.com/greggh/claude-code.nvim/issues/38) on claude-code.nvim about window management integration with edgy.nvim. The proposed solution is a buffer-centric architecture where the plugin manages buffers and external tools (edgy, stickybuf) manage windows.

## Updated Recommendation

**Option F (stickybuf.nvim)** is the recommended approach for these reasons:

1. **It's what toggleterm.nvim recommends** - The maintainer explicitly points users to stickybuf.nvim for this exact problem ([Issue #389](https://github.com/akinsho/toggleterm.nvim/issues/389))

2. **nvim-tree uses `buftype=nofile`** which isn't possible for Claude Code since it needs terminal functionality

3. **It solves the problem at the correct level** - Preventing the buffer from appearing in the wrong window, rather than trying to fix buffer selection logic after the fact

4. **Options A-E all failed or had significant drawbacks** - Buffer deletion logic changes didn't help because the issue is window-level, not buffer-level

## Technical References

- [Neovim windows.txt](https://neovim.io/doc/user/windows.html) - Buffer deletion behavior
- [Snacks.nvim bufdelete](https://github.com/folke/snacks.nvim/blob/main/lua/snacks/bufdelete.lua) - Smart buffer deletion
- [GitHub Issue #20799](https://github.com/neovim/neovim/issues/20799) - No `keepjumps` for Lua API
- [GitHub Issue #3489](https://github.com/neovim/neovim/issues/3489) - Feature request for per-buffer jumplist disable
