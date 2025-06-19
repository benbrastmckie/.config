# Autolist Module

This directory contains the configuration and utilities for autolist.nvim, providing intelligent list handling for markdown and note-taking in Neovim.

## Overview

The autolist module enhances list editing with automatic numbering, smart indentation, and seamless list type cycling. It's specifically configured to work well with completion systems and avoid keybinding conflicts.

## Module Structure

```
autolist/
├── README.md           # This documentation
├── init.lua           # Main autolist.nvim configuration
└── util/
    ├── init.lua           # Module exports
    ├── commands.lua       # User commands and global functions
    ├── integration.lua    # Keymapping and integration setup
    ├── list_operations.lua # Core list manipulation functions
    └── utils.lua          # Helper functions and utilities
```

## Core Features

### Intelligent List Management
- **Auto-increment**: Numbered lists automatically continue (1. → 2. → 3.)
- **List cycling**: Seamlessly switch between numbered, dashed, asterisk, and plus lists
- **Smart continuation**: New lines in lists automatically add appropriate bullets
- **Checkbox support**: Toggle between unchecked [ ], checked [x], and partial [~] states

### Enhanced Integration
- **Completion compatibility**: Works with blink.cmp without conflicts
- **Tab handling**: Smart Tab/Shift-Tab behavior for indentation
- **Command integration**: Comprehensive user commands for all operations
- **Filetype support**: Optimized for markdown and Neorg files

## Configuration Details

### Base Configuration
```lua
-- lua/neotex/plugins/tools/autolist/init.lua
autolist.setup({
  lists = {
    markdown = {"1.", "-", "*", "+"},  -- Supported list types
    norg = {"1.", "-", "*", "+"}
  },
  enabled = true,
  cycle = {"1.", "-", "*", "+"},       -- Cycling order
  smart_indent = false,                -- Prevent Tab conflicts
  custom_keys = false                  -- Use our custom keymaps
})
```

### Key Design Decisions
- **Disabled smart_indent**: Prevents conflicts with Tab key
- **Disabled custom_keys**: Allows custom Tab/Shift-Tab handling
- **No colon indentation**: Prevents unwanted list creation after colons

## Module Components

### 1. Core Operations (`list_operations.lua`)

**Primary Functions:**
- `tab_handler()` - Smart Tab behavior in insert mode
- `shift_tab_handler()` - Smart Shift-Tab behavior
- `indent_list_item()` - Increase list item indentation
- `unindent_list_item()` - Decrease list item indentation
- `cycle_next()` - Cycle to next list type (1. → - → * → +)
- `cycle_prev()` - Cycle to previous list type
- `recalculate_list()` - Fix numbering in numbered lists
- `toggle_checkbox()` - Cycle checkboxes ([ ] → [x] → [~])

**Tab Integration Logic:**
```lua
function M.tab_handler()
  -- 1. Check if we're in a list item
  -- 2. Close completion menu if open
  -- 3. Use list indentation if in list
  -- 4. Fall back to normal Tab behavior
end
```

### 2. User Commands (`commands.lua`)

**Available Commands:**
```vim
:AutolistIndent           " Indent current list item
:AutolistUnindent         " Unindent current list item  
:AutolistRecalculate      " Fix numbering in list
:AutolistCycleNext        " Cycle to next list type
:AutolistCyclePrev        " Cycle to previous list type
:AutolistIncrementCheckbox " Toggle checkbox forward
:AutolistDecrementCheckbox " Toggle checkbox backward
:AutolistNewBullet        " Create new bullet item
:AutolistNewBulletBefore  " Create bullet before current
:DebugMappings           " Debug Tab/Shift-Tab mappings
```

**Global Functions:**
```lua
_G.IncrementCheckbox = operations.toggle_checkbox
_G.DecrementCheckbox = operations.toggle_checkbox_reverse
```

### 3. Integration Setup (`integration.lua`)

**Keybinding Configuration:**
- Smart Tab/Shift-Tab handling for list contexts
- Integration with completion systems
- Filetype-specific behavior
- Global state tracking for Tab behavior

### 4. Utilities (`utils.lua`)

**Helper Functions:**
- List item detection and parsing
- Indentation level calculation
- List type identification
- Line content manipulation utilities

## Usage Examples

### Basic List Operations

**Auto-incrementing Lists:**
```markdown
1. First item
2. [cursor here, press Enter] → automatically creates "3. "
```

**List Type Cycling:**
```markdown
1. Numbered item    [<leader>Ln] →  - Dashed item
- Dashed item      [<leader>Ln] →  * Asterisk item  
* Asterisk item    [<leader>Ln] →  + Plus item
+ Plus item        [<leader>Ln] →  1. Numbered item
```

**Checkbox Management:**
```markdown
- [ ] Unchecked     [<leader>Lc] →  - [x] Checked
- [x] Checked       [<leader>Lc] →  - [~] Partial  
- [~] Partial       [<leader>Lc] →  - [ ] Unchecked
```

### Smart Indentation

**Tab Behavior in Lists:**
```markdown
1. First level
   [Tab] → creates proper indentation
   - Second level item
     [Tab] → deeper indentation
     * Third level item
```

**Shift-Tab Unindentation:**
```markdown
     * Deep item
   [Shift-Tab] → moves back one level
   - Less deep item
[Shift-Tab] → moves to top level  
1. Top level item
```

## Key Mappings

Defined in which-key configuration:

```lua
-- List operations
<leader>Lc  -- Toggle checkbox
<leader>Ln  -- Next list item / cycle list type
<leader>Lp  -- Previous list item
<leader>Lr  -- Recalculate list numbering

-- Action mappings
<leader>ar  -- Recalculate autolist (same as <leader>Lr)
```

## Integration Features

### Completion System Compatibility
- **blink.cmp integration**: Tab works correctly with completion
- **Menu handling**: Automatically closes completion when using Tab for indentation
- **State tracking**: Prevents completion triggering after list indentation

### Smart Context Detection
- **List recognition**: Automatically detects when cursor is in a list item
- **Filetype awareness**: Only activates in markdown and Neorg files
- **Indentation respect**: Maintains proper list indentation levels

## Advanced Configuration

### Global State Variables
```lua
_G._last_tab_was_indent = false    -- Tracks Tab usage for completion
_G._prevent_cmp_menu = false       -- Controls completion menu behavior
```

### Autocmd Integration
```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "norg" },
  callback = function()
    -- Set up markdown-specific keymaps
    if type(_G.set_markdown_keymaps) == "function" then
      _G.set_markdown_keymaps()
    end
  end
})
```

## Troubleshooting

### Common Issues

**Tab Key Not Working:**
```vim
:DebugMappings  " Check current Tab mappings
```

**List Not Auto-incrementing:**
- Ensure cursor is at end of list item
- Check that filetype is markdown or norg
- Verify list format matches configured patterns

**Completion Conflicts:**
- The module automatically handles blink.cmp integration
- If issues persist, check global state variables

### Debug Commands

**Check Plugin Status:**
```vim
:lua print(vim.inspect(require('autolist.auto')))
```

**Verify Keymaps:**
```vim
:verbose imap <Tab>
:verbose imap <S-Tab>
```

## Dependencies

### Required
- **autolist.nvim**: Core plugin (gaoDean/autolist.nvim)
- **Neovim 0.8+**: For modern Lua API features

### Optional
- **blink.cmp**: Enhanced completion integration
- **Telescope**: For TODO comment integration
- **Which-key**: For keymap documentation

## Related Documentation

- [Tools README](../README.md) - Parent module overview
- [Editor Plugins](../../editor/README.md) - Related editing tools
- [Which-key Configuration](../../editor/which-key.lua) - Keymap definitions

## Supported File Types

- **Markdown** (`.md`, `.markdown`)
- **Neorg** (`.norg`)

The module is specifically optimized for note-taking and documentation workflows in these formats.

## Navigation

- [Autolist Utilities →](util/README.md)
- [← Tools Plugins](../README.md)