# Snacks Module

This directory contains the configuration for snacks.nvim, a collection of polished utilities and UI enhancements for Neovim that improve the overall editing experience.

## File Structure

```
snacks/
├── README.md           # This documentation
├── init.lua           # Main snacks configuration
├── dashboard.lua      # Dashboard setup and customization
└── utils.lua          # Snacks utility functions
```

## Overview

Snacks.nvim provides a suite of small, focused utilities that enhance various aspects of Neovim. The configuration is modular and carefully tuned to integrate seamlessly with the existing setup while providing essential quality-of-life improvements.

## Module Structure

```
snacks/
├── README.md       # This documentation
├── init.lua        # Main snacks.nvim configuration
├── dashboard.lua   # Custom dashboard preset and sections
└── utils.lua       # Utility functions and integrations
```

## Enabled Components

### Core UI Enhancements

#### 1. **Dashboard** (`dashboard.lua`)
- **Custom startup screen** with ASCII art header
- **Quick actions** for common tasks (sessions, files, config)
- **Keyboard shortcuts** for efficient navigation
- **Recent files integration**

#### 2. **Status Column** (`statuscolumn`)
- **Git signs integration** with gitsigns.nvim and mini.diff
- **Fold indicators** for code folding
- **Mark and sign display** 
- **Optimized rendering** with 50ms refresh rate

#### 3. **Indentation Guides** (`indent`)
- **Scope highlighting** for current indentation level
- **Visual guides** using `|` and `│` characters
- **High performance** with treesitter integration disabled for speed

#### 4. **Notification System** (`notifier`)
- **Enhanced notifications** with configurable timeout (4s)
- **Sorting and filtering** by level and time
- **Compact style** with top-down display
- **History tracking** for message review

### Developer Tools

#### 5. **Git Integration** (`git`, `gitbrowse`, `lazygit`)
- **Git blame display** with floating window
- **Repository browsing** with gitbrowse
- **LazyGit integration** with fallback handling
- **Safe launching** with error recovery

#### 6. **Buffer Management** (`bufdelete`)
- **Smart buffer deletion** preserving window layout
- **Integration with which-key** for `<leader>d` mapping

#### 7. **Input Enhancement** (`input`)
- **Improved input dialogs** with rounded borders
- **Consistent styling** across all prompts
- **Enhanced positioning** and backdrop options

#### 8. **File Operations** (`quickfile`, `rename`)
- **Fast file operations** for small files
- **Smart renaming** with LSP integration
- **Performance optimizations**

### Text Objects & Navigation

#### 9. **Scope Text Objects** (`scope`)
- **Inner scope** (`ii`) - content within current scope
- **Outer scope** (`ai`) - full scope including boundaries
- **Treesitter integration** with block detection disabled
- **Minimum size requirements** for scope detection

## Configuration Details

### Dashboard Configuration
```lua
-- Custom dashboard preset
preset = {
  keys = {
    { icon = " ", key = "s", desc = "Restore Session" },
    { icon = " ", key = "r", desc = "Recent Files" },
    { icon = " ", key = "e", desc = "Explorer" },
    { icon = " ", key = "f", desc = "Find File" },
    { icon = "󰱼 ", key = "g", desc = "Find Text" },
    { icon = " ", key = "n", desc = "New File" },
    { icon = " ", key = "c", desc = "Config" },
    { icon = " ", key = "q", desc = "Quit" },
  }
}
```

### Status Column Setup
```lua
statuscolumn = {
  left = { 'mark', 'sign' },    -- Left side indicators
  right = { 'fold', 'git' },    -- Right side indicators
  git = {
    patterns = { 'GitSign', 'MiniDiffSign' }  -- Git sign integration
  }
}
```

### Notification Configuration
```lua
notifier = {
  timeout = 4000,                 -- 4 second display
  style = 'compact',              -- Compact notification style
  level = vim.log.levels.TRACE,   -- Show all message levels
  top_down = true,                -- New notifications at top
}
```

## Utility Functions

### LazyGit Integration (`utils.lua`)

**Safe LazyGit Launcher:**
```lua
M.safe_lazygit = function()
  -- Try Snacks.lazygit() first
  -- Fall back to ToggleTerm if failed
  -- Provides error recovery and user notification
end
```

**Usage in keymaps:**
```lua
-- In which-key configuration
g = {
  g = { 
    "<cmd>lua vim.schedule(function() require('neotex.plugins.tools.snacks.utils').safe_lazygit() end)<cr>", 
    "lazygit" 
  },
}
```

## Key Mappings Integration

### Dashboard Actions
Available when dashboard is open:
```
s  - Restore Session
r  - Recent Files  
e  - Explorer
f  - Find File
g  - Find Text
n  - New File
c  - Config
i  - Info (CheatSheet)
m  - Manage Plugins
h  - Checkhealth
q  - Quit
```

### Which-key Integration
```lua
-- Buffer deletion
<leader>d  -- Delete buffer (uses Snacks.bufdelete())

-- Git operations  
<leader>gg -- LazyGit (with safe launcher)

-- Notifications
<leader>rm -- Show message history (Snacks.notifier.show_history())
```

## Disabled Components

The following snacks components are intentionally disabled:

- **bigfile**: File size optimization (disabled, using 100KB threshold)
- **profiler**: Performance profiling (not needed)
- **scratch**: Scratch buffers (not used)
- **scroll**: Smooth scrolling (conflicts with other plugins)
- **terminal**: Terminal utilities (using toggleterm instead)
- **toggle**: Buffer toggling (using custom solutions)
- **words**: Word highlighting (using mini.cursorword)
- **zen**: Zen mode (not currently used)

## Performance Considerations

### Optimizations
- **Indent animation disabled**: Prevents performance issues
- **Treesitter blocks disabled**: In scope detection for speed
- **50ms refresh rate**: For statuscolumn updates
- **Compact notifications**: Reduced visual overhead

### Resource Usage
- **High priority loading** (priority = 1000)
- **Not lazy-loaded** for immediate availability
- **Selective component enabling** to minimize overhead

## Advanced Features

### Git Blame Styling
```lua
styles = {
  blame_lines = {
    width = 0.6,
    height = 0.6,
    border = "rounded",
    title = " Git Blame ",
    title_pos = "center",
    ft = "git",
  }
}
```

### Scope Text Objects
```lua
-- Available text objects
ii  -- Inner scope (content only)
ai  -- Outer scope (including boundaries)

-- Usage examples
dii  -- Delete inner scope
dai  -- Delete outer scope
vii  -- Select inner scope
```

## Integration Points

### With Other Plugins
- **Gitsigns**: Status column git indicators
- **Toggleterm**: LazyGit fallback integration
- **SessionManager**: Dashboard session restoration
- **Neo-tree**: Dashboard explorer integration
- **Which-key**: Comprehensive keymap integration

### With LSP
- **Rename operations**: Enhanced input dialogs
- **File operations**: Quick file handling
- **Buffer management**: Smart deletion preserving layout

## Troubleshooting

### Common Issues

**Dashboard not showing:**
- Check if another dashboard plugin is interfering
- Verify `dashboard.enabled = true` in configuration

**Git signs not appearing:**
- Ensure gitsigns.nvim is properly configured
- Check `statuscolumn.git.patterns` settings

**LazyGit not launching:**
- The safe launcher will fall back to ToggleTerm
- Check that lazygit is installed system-wide

### Debug Commands

**Check Snacks status:**
```vim
:lua print(vim.inspect(Snacks))
```

**Test notifications:**
```vim
:lua Snacks.notify("Test message", "info")
```

**Check statuscolumn:**
```vim
:lua print(vim.inspect(Snacks.statuscolumn))
```

## Dependencies

### Required
- **snacks.nvim**: Core plugin (folke/snacks.nvim)
- **Neovim 0.9+**: For modern features

### Optional Integrations
- **gitsigns.nvim**: Git sign integration
- **toggleterm.nvim**: LazyGit fallback
- **neo-tree.nvim**: Dashboard explorer action
- **telescope.nvim**: File picking actions
- **session-manager**: Session restoration

## Related Documentation

- [Tools README](../README.md) - Parent module overview
- [UI Plugins](../../ui/README.md) - Related interface tools
- [Git Integration](../gitsigns.lua) - Git functionality
- [Which-key Configuration](../../editor/which-key.lua) - Keymap setup

## Supported Use Cases

- **Startup efficiency**: Quick access to common tasks
- **Visual feedback**: Clear indicators for git changes and structure
- **Developer workflow**: Integrated git tools and file operations
- **User experience**: Polished notifications and input dialogs

## Navigation

- [← Tools Plugins](../README.md)