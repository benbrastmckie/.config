# AI Claude Utilities

Utility modules for Claude AI integration, focusing on terminal management, command queueing, and state tracking.

## Modules

### terminal-state.lua
Event-driven terminal state management and command queueing for Claude Code integration. Provides smart command insertion with automatic timing, mode handling, and window management.

**Key Features:**
- **State Machine**: CLOSED -> OPENING -> READY -> BUSY lifecycle
- **Command Queue**: Automatic queuing with 30-second freshness check
- **Smart Timing**: Check-before-focus pattern with conditional delays
  - Window visible: `vim.schedule()` (immediate, next event loop)
  - Window needs reopen: `vim.defer_fn(150ms)` (wait for window)
- **Mode Handling**: Automatic insert mode entry (handles both `n` and `nt` modes)
- **SessionStart Hook Integration**: Works with Claude Code SessionStart hook
- **Debug Mode**: Conditional debug output via `vim.g.neotex_debug_mode`

**Key Functions:**
- `queue_command(command_text, opts)` - Queue command with smart timing
- `flush_queue(claude_buf)` - Send all queued commands to terminal
- `focus_terminal(claude_buf)` - Focus terminal and enter insert mode
- `send_to_terminal(claude_buf, text, opts)` - Send command via chansend
- `on_claude_ready()` - Called by SessionStart hook when Claude is ready
- `find_claude_terminal()` - Locate Claude Code terminal buffer
- `is_ready()` / `get_state()` - State query functions
- `setup()` - Initialize autocommands for event-driven monitoring

**Options:**
- `ensure_open` - Open Claude Code if terminal doesn't exist
- `notification` - Callback to execute after successful send

**Hook Integration:**
Works with `~/.config/nvim/scripts/claude-ready-signal.sh` SessionStart hook that calls `on_claude_ready()` when Claude starts or resumes.

**Implementation Details:**
- No timer-based polling (event-driven only)
- Handles three scenarios:
  1. Fresh start: SessionStart hook triggers flush
  2. Already open: Immediate flush via vim.schedule()
  3. Toggled closed: 150ms delay for window reopen
- Terminal normal mode (`nt`) detection for proper insert mode entry
- 100ms delay in hook callback for Claude initialization

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