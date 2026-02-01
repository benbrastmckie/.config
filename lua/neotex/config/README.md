# Core Configuration

This directory contains the core configuration modules for NeoVim.

## File Structure

```
config/
├── README.md           # This documentation
├── init.lua           # Main loader and initialization
├── options.lua        # Core Vim/NeoVim options
├── notifications.lua  # Unified notification system configuration
├── keymaps.lua        # Key mappings for different modes
└── autocmds.lua       # Autocommands for different events
```

## Module Structure

- **init.lua**: Main loader that initializes all configuration modules
- **options.lua**: Core Vim/NeoVim options (tab settings, line numbers, etc.)
- **notifications.lua**: Unified notification system with intelligent filtering and module-specific controls
- **keymaps.lua**: Key mappings for different modes
- **autocmds.lua**: Autocommands for different events

## Options (options.lua)

The options module sets up various Vim and NeoVim options to create a better editing experience:

- UI options (line numbers, cursor, colors)
- Editing behavior (tab settings, indentation)
- Search behavior
- Clipboard integration
- Split behavior
- Backup and file handling

## Notifications (notifications.lua)

The notifications module configures the unified notification system that provides consistent feedback across all plugins and modules:

### Key Features
- **Smart Filtering**: Category-based filtering (ERROR, WARNING, USER_ACTION, STATUS, BACKGROUND)
- **Module Control**: Per-module notification preferences (Himalaya, AI, LSP, Editor, Startup)
- **Debug Mode**: Toggle detailed notifications for troubleshooting
- **Performance**: Rate limiting and batching to prevent notification spam

### Configuration
```lua
-- Example: Disable background notifications for Himalaya
local notify_config = require('neotex.config.notifications')
notify_config.config.modules.himalaya.background_sync = false
```

### Commands
- `:Notifications` - Show notification management interface
- `:NotifyDebug [module]` - Toggle debug mode globally or per module  
- `:NotificationConfig` - Manage notification preferences

See [NOTIFICATIONS.md](../../docs/NOTIFICATIONS.md) for complete documentation.

## Keymaps (keymaps.lua)

The keymaps module defines key mappings for various operations:

- **Navigation**: Buffer switching, window movement, display line movement
- **Editing Operations**: Format, search/replace, line movement, indentation
- **Quickfix/Location List**: Navigation with `]q`/`[q` (next/prev), `]Q`/`[Q` (first/last), `]l`/`[l`, `]L`/`[L`
- **Plugin-Specific Mappings**: AI assistants, terminal toggle, commenting
- **Custom Command Shortcuts**: All mappings include centered cursor (`zz`) for better visibility

### Key Features
- Context-aware `<C-c>` binding: Claude Code toggle in most contexts, checkbox toggle in autolist
- Terminal mode bindings for window navigation and terminal toggle
- Visual mode support for line movement and indentation while preserving selection

## Autocommands (autocmds.lua)

The autocommands module sets up automatic behaviors for different events:

- **Filetype-Specific Settings**: Automatic configuration based on file type
- **Terminal Behavior**: Terminal mode setup and window management
- **Cursor Position Restoration**: Resume editing at last cursor position
- **Auto-Formatting on Save**: Format code before writing (configurable per filetype)
- **Efficient File Reload**: Detect external file changes using FocusGained and BufEnter events
- **WezTerm Integration**: OSC escape sequence emission for tab title updates

### Performance Optimizations
- **No CursorHold Events**: Removed CursorHold/CursorHoldI autocmds for file reload detection
  - Eliminated 5-10ms cursor pause lag
  - Reduced autocmd fires by 98%
  - FocusGained and BufEnter events are sufficient for detecting external changes
- **Minimal Event Listening**: Only essential autocmds are registered for better responsiveness

## WezTerm Integration

The autocmds module provides WezTerm terminal integration via OSC escape sequences. Features are only active when running inside WezTerm (detected via `WEZTERM_PANE` environment variable).

### OSC 7 Directory Updates

Neovim emits OSC 7 escape sequences to update WezTerm tab titles with the current working directory:

| Event | Behavior |
|-------|----------|
| `VimEnter` | Emit initial directory on startup |
| `DirChanged` | Emit on `:cd`, `:lcd`, `:tcd`, or autochdir |
| `BufEnter` | Emit when entering non-terminal buffers |

The `BufEnter` handler only fires for non-terminal buffers to avoid conflicts with the shell's own OSC 7 emission.

### Claude Code Task Number Monitoring

Neovim monitors Claude Code terminal buffers for task-related commands and updates WezTerm tab titles:

**Pattern Detection**:
- `/research N`, `/plan N`, `/implement N`, `/revise N`

**Implementation**:
1. `TermOpen` autocmd detects Claude Code terminals (buffers matching `claude` or `ClaudeCode`)
2. `nvim_buf_attach` monitors buffer changes for command patterns
3. Task numbers are emitted via `neotex.lib.wezterm.set_task_number()`
4. Debouncing (100ms) prevents rapid updates during typing

**Cleanup**:
- Task number clears when the Claude terminal buffer closes
- Buffer state cleanup on `BufDelete`/`BufWipeout`

### WezTerm Library Module

The `neotex.lib.wezterm` module provides the OSC 1337 emission API:

```lua
local wezterm = require('neotex.lib.wezterm')

-- Check if WezTerm integration is available
if wezterm.is_available() then
  -- Set task number (displayed as #N in tab title)
  wezterm.set_task_number(792)

  -- Clear task number
  wezterm.clear_task_number()

  -- Set arbitrary user variable
  wezterm.emit_user_var('VARIABLE_NAME', 'value')
end
```

**API Reference**:

| Function | Parameters | Description |
|----------|------------|-------------|
| `is_available()` | none | Returns true if running in WezTerm |
| `set_task_number(n)` | number or string | Set TASK_NUMBER user variable |
| `clear_task_number()` | none | Clear TASK_NUMBER user variable |
| `emit_user_var(name, value)` | string, string or nil | Set or clear any user variable |
| `clear_user_var(name)` | string | Clear a user variable |

### Integration Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Neovim                                                      │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────────────────────┐│
│  │ autocmds.lua    │    │ lib/wezterm.lua                 ││
│  │                 │    │                                 ││
│  │ DirChanged ─────┼───>│ emit_osc7() ──────────────────┐ ││
│  │ VimEnter        │    │                               │ ││
│  │ BufEnter        │    │ set_task_number() ────────────┤ ││
│  │                 │    │   (via emit_user_var)         │ ││
│  │ Claude monitor ─┼───>│                               │ ││
│  │   TermOpen      │    │                               │ ││
│  │   nvim_buf_attach    │                               │ ││
│  └─────────────────┘    └───────────────────────────────┼─┘│
│                                                         │  │
└─────────────────────────────────────────────────────────┼──┘
                                                          │
                                                          ▼
                                              ┌───────────────────┐
                                              │ WezTerm           │
                                              │                   │
                                              │ OSC 7 ─> Tab dir  │
                                              │ OSC 1337 ─> User  │
                                              │            vars   │
                                              └───────────────────┘
```

### Related Documentation

- **WezTerm configuration**: `~/.dotfiles/docs/terminal.md`
- **Claude Code hooks**: Project-specific `.claude/hooks/` directory
- **Notification system**: [NOTIFICATIONS.md](../../docs/NOTIFICATIONS.md)

## Usage

These configuration modules are loaded automatically during startup. You can also manually reload them:

```lua
-- Reload all configuration
require("neotex.config").setup()

-- Or reload a specific module
require("neotex.config.options").setup()
```

## Navigation

- [Plugins Overview →](../plugins/README.md)
- [Tools Plugins →](../plugins/tools/README.md)
- [Editor Plugins →](../plugins/editor/README.md)
- [LSP Configuration →](../plugins/lsp/README.md)
- [← Main Configuration](../README.md)