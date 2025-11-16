# Claude Code Session Management

Terminal session management utilities for Claude Code integration, handling state tracking, command queueing, and terminal operations.

## Purpose

This directory contains Claude Code-specific session management utilities that were previously located at `ai/claude/utils/`. These modules handle terminal state coordination, subprocess isolation, and command execution for Claude Code integration.

## Modules

### terminal-state.lua
Event-driven terminal state management and command queueing for Claude Code integration.

**Key Features:**
- State machine lifecycle: CLOSED → OPENING → READY → BUSY
- Command queue with 30-second freshness check
- Smart timing (check-before-focus pattern with conditional delays)
- Mode handling (automatic insert mode entry)
- SessionStart hook integration
- Debug mode support

**Key Functions:**
- `queue_command(command_text, opts)` - Queue command with smart timing
- `flush_queue(claude_buf)` - Send all queued commands to terminal
- `focus_terminal(claude_buf)` - Focus terminal and enter insert mode
- `send_to_terminal(claude_buf, text, opts)` - Send command via chansend
- `on_claude_ready()` - Called by SessionStart hook when Claude is ready
- `find_claude_terminal()` - Locate Claude Code terminal buffer
- `is_ready()` / `get_state()` - State query functions
- `setup()` - Initialize autocommands for event-driven monitoring

### terminal-detection.lua
Terminal emulator type detection and capability verification for tab management.

**Key Features:**
- Detects Kitty and WezTerm terminals
- Verifies remote control capabilities
- Configuration validation
- Human-readable capability status

**Key Functions:**
- `detect()` - Returns terminal type ('kitty', 'wezterm', or nil)
- `has_remote_control()` - Verifies if remote control is enabled
- `supports_tabs()` - Checks if terminal supports remote tab control
- `get_display_name()` - Returns human-readable terminal name with status
- `validate_capability()` - Tests actual remote control commands
- `check_kitty_config()` - Verifies Kitty configuration
- `get_kitty_config_path()` - Finds Kitty configuration file location

**Kitty Remote Control:**
For Kitty terminals, remote control must be enabled in configuration:
```conf
# In ~/.config/kitty/kitty.conf
allow_remote_control yes
```

### terminal-commands.lua
Terminal-agnostic command generation for tab operations.

**Key Features:**
- Abstracts Kitty and WezTerm command-line interfaces
- Tab creation and activation
- Result parsing
- Tab title management

**Key Functions:**
- `spawn_tab(path, command)` - Generates command to create new terminal tab
- `activate_tab(tab_id)` - Generates command to switch to specific tab
- `parse_spawn_result(result)` - Extracts tab/pane ID from spawn output
- `set_tab_title(tab_id, title)` - Generates command to set tab title

### terminal.lua
Claude terminal buffer and window management.

**Key Features:**
- Terminal buffer lifecycle management
- Window creation and focus
- Buffer validation

### claude-code.lua
Claude Code integration coordinator.

**Key Features:**
- Session initialization
- Terminal coordination
- Integration with Claude Code plugin

### git.lua
Git operations for session management.

**Key Features:**
- Repository detection
- Branch information
- Git worktree integration

### persistence.lua
Session data persistence across subprocess boundaries.

**Key Features:**
- File-based state storage
- Session restoration
- Data serialization/deserialization

## Usage Examples

### Terminal State Management
```lua
local terminal_state = require('neotex.plugins.ai.claude.claude-session.terminal-state')

-- Initialize session
terminal_state.setup()

-- Queue command
terminal_state.queue_command("echo 'Hello'", { ensure_open = true })

-- Check state
if terminal_state.is_ready() then
  terminal_state.send_to_terminal(buf, "command\n")
end
```

### Terminal Detection
```lua
local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')

-- Detect terminal type
local terminal = terminal_detect.detect()  -- Returns 'kitty' or 'wezterm'

-- Check capabilities
if terminal_detect.supports_tabs() then
  print("Remote tab control available")
end
```

### Terminal Commands
```lua
local terminal_cmds = require('neotex.plugins.ai.claude.claude-session.terminal-commands')

-- Generate spawn command
local cmd = terminal_cmds.spawn_tab('/path/to/worktree', 'nvim CLAUDE.md')
vim.fn.system(cmd)
```

## Architecture Notes

### State Management
- Event-driven (no timer-based polling)
- Hook integration with SessionStart
- Subprocess isolation with file-based persistence

### Terminal Integration
- Terminal-agnostic command generation
- Capability detection and validation
- Cross-platform support

## Architectural Separation

[IMPORTANT] This directory contains Claude Code session management. Avante-related functionality is in `../avante/mcp/` to maintain proper architectural boundaries.

## Navigation

- [← Claude Integration](../README.md)
- [← AI Plugins](../../README.md)
