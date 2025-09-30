# AI Claude Utilities

Utility modules for Claude AI integration.

## Modules

### terminal-detection.lua
Detects terminal emulator type and verifies remote control capabilities for tab management features. Supports identification of Kitty and WezTerm terminals with capability validation.

**Key Functions:**
- `detect()` - Returns terminal type ('kitty', 'wezterm', or nil)
- `has_remote_control()` - Verifies if remote control is actually enabled
- `supports_tabs()` - Checks if terminal supports remote tab control (uses has_remote_control)
- `get_display_name()` - Returns human-readable terminal name with capability status
- `validate_capability()` - Tests actual remote control commands (kitten @ ls, wezterm cli)
- `check_kitty_config()` - Verifies Kitty configuration for allow_remote_control setting
- `get_kitty_config_path()` - Finds Kitty configuration file location

**Kitty Remote Control:**
For Kitty terminals, remote control must be enabled in configuration:
```conf
# In ~/.config/kitty/kitty.conf
allow_remote_control yes
```

### terminal-commands.lua
Provides terminal-agnostic command generation for tab operations. Abstracts the differences between Kitty and WezTerm command-line interfaces.

**Key Functions:**
- `spawn_tab(path, command)` - Generates command to create new terminal tab
- `activate_tab(tab_id)` - Generates command to switch to specific tab
- `parse_spawn_result(result)` - Extracts tab/pane ID from spawn output
- `set_tab_title(tab_id, title)` - Generates command to set tab title

### terminal.lua
Manages Claude terminal buffers and windows.

## Dependencies
- Uses: None (self-contained utilities)
- Used by: `neotex.ai-claude.core.worktree`

## Examples
```lua
-- Detect terminal type
local terminal_detect = require('neotex.ai-claude.utils.terminal-detection')
local terminal = terminal_detect.detect()  -- Returns 'kitty' or 'wezterm'

-- Generate spawn command
local terminal_cmds = require('neotex.ai-claude.utils.terminal-commands')
local cmd = terminal_cmds.spawn_tab('/path/to/worktree', 'nvim CLAUDE.md')
```

## Navigation
- [← Parent Directory](../README.md)