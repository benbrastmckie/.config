# WezTerm Neovim Plugins Overview

## Active and Useful WezTerm Integration Plugins (2024)

### 1. smart-splits.nvim ⭐ Highly Recommended
**Repository**: [mrjones2014/smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)  
**Status**: Actively maintained  
**Requirements**: Neovim 0.8+, WezTerm (nightly for resizing)

#### What it provides:
- **Seamless navigation** between Neovim splits and WezTerm panes using vim keys (h/j/k/l)
- **Unified resizing** of splits/panes from within Neovim
- **Smart edge detection** with wrap/split/stop behaviors
- Replaces vim-tmux-navigator for WezTerm users
- Minimal performance impact (~0.07ms startup)

#### Installation:
```lua
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,  -- Important: Don't lazy load for WezTerm integration
  keys = {
    -- Navigation
    { "<C-h>", function() require("smart-splits").move_cursor_left() end, desc = "Move left" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end, desc = "Move down" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end, desc = "Move up" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move right" },
    -- Resizing (requires WezTerm nightly)
    { "<A-h>", function() require("smart-splits").resize_left() end, desc = "Resize left" },
    { "<A-j>", function() require("smart-splits").resize_down() end, desc = "Resize down" },
    { "<A-k>", function() require("smart-splits").resize_up() end, desc = "Resize up" },
    { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize right" },
  },
  config = function()
    require("smart-splits").setup({
      ignored_filetypes = { "nofile", "quickfix", "prompt" },
      ignored_buftypes = { "NvimTree" },
      default_amount = 3,
      at_edge = "wrap",  -- 'wrap', 'split', or 'stop'
      cursor_follows_swapped_bufs = false,
      resize_mode = {
        quit_key = "<ESC>",
        resize_keys = { "h", "j", "k", "l" },
        silent = false,
      },
    })
  end,
}
```

#### WezTerm Configuration Required:
Add to `~/.config/wezterm/wezterm.lua`:
```lua
local function is_vim(pane)
  local user_vars = pane:get_user_vars()
  return user_vars.IS_NVIM == "true"
end

-- Key bindings for navigation
config.keys = {
  {
    key = "h",
    mods = "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        win:perform_action(wezterm.action.SendKey({ key = "h", mods = "CTRL" }), pane)
      else
        win:perform_action(wezterm.action.ActivatePaneDirection("Left"), pane)
      end
    end),
  },
  -- Repeat for j, k, l...
}
```

---

### 2. wezterm.nvim
**Repository**: [willothy/wezterm.nvim](https://github.com/willothy/wezterm.nvim)  
**Status**: Actively maintained  
**Requirements**: Neovim 0.10+

#### What it provides:
- **CLI integration** - Control WezTerm from within Neovim
- **Tab/pane management** - Switch tabs, spawn new panes programmatically
- **Task spawning** - Run commands in new WezTerm tabs
- **Desktop notifications** via `wezterm.notify`
- Lightweight alternative to full pane navigation

#### Installation:
```lua
return {
  "willothy/wezterm.nvim",
  config = true,  -- Or { create_commands = false } to skip WeztermSpawn command
  keys = {
    { "<leader>ht", function() require("wezterm").switch_tab.index(vim.v.count) end, desc = "Switch WezTerm tab" },
    { "<leader>hp", function() require("wezterm").switch_pane.id(vim.v.count) end, desc = "Switch WezTerm pane" },
  },
  cmd = { "WeztermSpawn" },
}
```

#### Usage Examples:
```lua
-- Spawn a task in new tab
:WeztermSpawn npm run dev

-- Switch to tab 3
:lua require('wezterm').switch_tab.index(3)

-- Send notification
:lua require('wezterm').notify("Build complete!")
```

---

### 3. wezterm-config.nvim
**Repository**: [winter-again/wezterm-config.nvim](https://github.com/winter-again/wezterm-config.nvim)  
**Status**: Maintained  
**Requirements**: Neovim, WezTerm

#### What it provides:
- **Dynamic configuration** - Change WezTerm settings from within Neovim
- **Config overrides** - Temporarily modify terminal appearance
- **Bidirectional communication** - Neovim ↔ WezTerm

#### Installation:
```lua
return {
  "winter-again/wezterm-config.nvim",
  config = function()
    require("wezterm-config").setup({
      -- Your config
    })
  end,
}
```

---

### 4. Navigator.nvim (with WezTerm support)
**Repository**: [numToStr/Navigator.nvim](https://github.com/numToStr/Navigator.nvim)  
**Status**: Actively maintained  
**Requirements**: Neovim

#### What it provides:
- **Multiplexer agnostic** navigation (supports tmux, WezTerm, Kitty)
- **Minimal configuration** needed
- **Consistent keybindings** across different terminals

#### Installation:
```lua
return {
  "numToStr/Navigator.nvim",
  config = function()
    require("Navigator").setup()
  end,
  keys = {
    { "<C-h>", "<cmd>NavigatorLeft<cr>", desc = "Navigator left" },
    { "<C-j>", "<cmd>NavigatorDown<cr>", desc = "Navigator down" },
    { "<C-k>", "<cmd>NavigatorUp<cr>", desc = "Navigator up" },
    { "<C-l>", "<cmd>NavigatorRight<cr>", desc = "Navigator right" },
  },
}
```

---

### 5. flatten.nvim
**Repository**: [willothy/flatten.nvim](https://github.com/willothy/flatten.nvim)  
**Status**: Actively maintained  
**Requirements**: Neovim 0.8+

#### What it provides:
- **Nested session handling** - Open files from terminal in parent Neovim
- **Smart file opening** - Like `code -r` but for Neovim
- Prevents nested Neovim instances
- Works with WezTerm, Kitty, and Neovim terminals

#### Installation:
```lua
return {
  "willothy/flatten.nvim",
  config = true,
  lazy = false,
  priority = 1001,  -- Load before other plugins
}
```

---

## Recommendations for Your Workflow

Based on your goal of managing multiple Claude Code sessions with git worktrees:

### 1. **Essential: smart-splits.nvim**
- Provides seamless navigation between Neovim and WezTerm panes
- Critical for switching between different Claude sessions in different panes
- No external scripts needed

### 2. **Useful: wezterm.nvim**
- Programmatically create new WezTerm tabs for worktrees
- Switch tabs from within Neovim
- Could integrate with your `ClaudeWorktreeCreate` command

### 3. **Optional: flatten.nvim**
- Prevents accidental nested Neovim sessions
- Useful when opening files from Claude Code terminal

## Example Integration with Your Claude Workflow

```lua
-- Extend your claude-worktree.lua with WezTerm integration

local M = {}

-- Using wezterm.nvim to create new tab for worktree
function M.create_worktree_wezterm_tab()
  local wezterm = require("wezterm")
  local worktree_path = M.create_worktree()
  if worktree_path then
    -- Spawn new WezTerm tab in worktree directory
    wezterm.spawn_tab({
      cwd = worktree_path,
      args = { "nvim", "CLAUDE.md", "+ClaudeCode" },
    })
  end
end

-- Using smart-splits for better navigation
function M.focus_claude_pane(direction)
  local smart_splits = require("smart-splits")
  if direction == "left" then
    smart_splits.move_cursor_left()
  elseif direction == "right" then
    smart_splits.move_cursor_right()
  end
end

return M
```

## Installation Priority

1. **Phase 1**: Install smart-splits.nvim for seamless navigation
2. **Phase 2**: Add wezterm.nvim for programmatic control
3. **Phase 3**: Consider flatten.nvim if you often edit from terminals

These plugins are all actively maintained as of 2024 and provide robust integration between Neovim and WezTerm, perfect for your multi-session Claude Code workflow.