# Library Modules

This directory contains shared library modules that provide common functionality across the Neovim configuration.

## Modules

### wezterm.lua

Purpose: WezTerm terminal integration via OSC escape sequences

**Primary Exports**:
- `is_available()` - Check if running inside WezTerm
- `emit_user_var(name, value)` - Set or clear a WezTerm user variable
- `clear_user_var(name)` - Clear a WezTerm user variable
- `set_task_number(n)` - Set TASK_NUMBER for tab title display
- `clear_task_number()` - Clear TASK_NUMBER user variable

**Dependencies**: None (uses only Lua standard library and vim API)

**Usage**:
```lua
local wezterm = require('neotex.lib.wezterm')

-- Only execute WezTerm-specific code when inside WezTerm
if wezterm.is_available() then
  wezterm.set_task_number(792)
end
```

**Notes**:
- Functions are no-ops when not running in WezTerm
- Base64 encoding is implemented in pure Lua for Lua 5.1 compatibility
- OSC 1337 escape sequences are written directly to stdout

## Navigation

- [Config Modules](../config/README.md) - Core configuration (uses wezterm for autocmds)
- [Parent Directory](../README.md) - Neotex namespace overview
