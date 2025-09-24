# Claude AI Integration Module

This module provides comprehensive Claude Code integration for Neovim, organizing all Claude-related functionality into a clean, maintainable structure.

## Features

- **Smart Session Management** - Automatically tracks and restores Claude sessions with context awareness
- **Git Worktree Integration** - Create isolated development environments with dedicated Claude sessions
- **Visual Selection Sending** - Send selected code directly to Claude with context
- **Project-Aware Sessions** - Sessions are automatically scoped to your current project
- **Simple & Full Pickers** - Quick access to recent sessions or browse all sessions

## Directory Structure

```
lua/neotex/ai-claude/
├── init.lua                    # Main entry point and public API
├── config.lua                   # Configuration management
├── README.md                    # This file
│
├── core/                        # Core business logic
│   ├── session.lua             # Session management
│   ├── worktree.lua           # Worktree operations
│   └── visual.lua             # Visual selection handling
│
├── ui/                         # User interface components
│   ├── pickers.lua            # Telescope pickers (simple and full)
│   └── native-sessions.lua   # Native Claude session handling
│
└── utils/                      # Utility functions
    ├── git.lua                # Git operations
    ├── terminal.lua           # Terminal management
    └── persistence.lua        # Session file I/O
```

## Usage

### Basic Usage

```lua
-- In your Neovim config
require("neotex.ai-claude").setup({
  simple_picker_max = 3,        -- Show max 3 sessions in simple picker
  auto_restore_session = true,  -- Auto-restore last session
  worktree = {
    max_sessions = 4,
    auto_switch_tab = true,
  }
})
```

### Keybindings

Default keybindings (configured in `neotex.config.keymaps`):

- `<C-c>` - Smart toggle Claude Code (all modes)
- `<leader>as` - Browse Claude sessions
- `<leader>av` - View worktrees
- `<leader>aw` - Create new worktree with Claude session
- `<leader>ar` - Restore closed worktree session

### Commands

The module creates these commands (via the worktree sub-module):

- `:ClaudeWorktree` - Create a new worktree with Claude session
- `:ClaudeSessions` - Open full session browser
- `:ClaudeSession` - Switch to a different session
- `:ClaudeRestoreWorktree` - Restore a previously closed worktree

## API Reference

### Main Module (`init.lua`)

```lua
local claude = require("neotex.ai-claude")

-- Session Management
claude.smart_toggle()              -- Smart toggle with simple picker
claude.resume_session(id)           -- Resume specific session
claude.save_session_state()         -- Save current session state
claude.load_session_state()         -- Load saved session state
claude.check_for_recent_session()   -- Check if recent session exists

-- Worktree Management
claude.create_worktree_with_claude(opts)  -- Create worktree with session
claude.telescope_sessions()               -- Show sessions in Telescope
claude.telescope_worktrees()              -- Show worktrees in Telescope

-- Visual Selection
claude.send_visual_to_claude()      -- Send visual selection to Claude

-- Setup
claude.setup(opts)                  -- Initialize with configuration
```

### Configuration Options

```lua
{
  -- Picker settings
  simple_picker_max = 3,          -- Max sessions in simple picker
  show_preview = true,             -- Show preview in pickers

  -- Session management
  auto_restore_session = true,    -- Auto-restore on startup
  auto_save_session = true,        -- Save session state automatically
  session_timeout_hours = 24,      -- Sessions older than this are stale

  -- Worktree settings
  worktree = {
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
    default_type = "feature",
  },

  -- Terminal settings
  auto_insert_mode = true,         -- Auto-enter insert mode
  terminal_height = 15,            -- Height of terminal split

  -- Visual selection
  visual = {
    include_filename = true,       -- Include filename in selection
    include_line_numbers = true,   -- Include line numbers
  },
}
```

## Smart Toggle Behavior

The `smart_toggle()` function (bound to `<C-c>`) provides intelligent session management:

1. **If Claude is already open** - Toggles the window visibility
2. **If Claude is closed but recent session exists (< 24 hours)** - Shows a menu with three options:
   - **Continue last session** - Resume your most recent conversation
   - **Browse all sessions** - Opens session picker (shows 3 recent + "Show all" if many)
   - **Start new session** - Begin a fresh Claude conversation
3. **If no recent sessions exist** - Starts a new Claude session directly

## Session Persistence

Sessions are automatically saved to `~/.local/share/nvim/claude/` with:
- Current working directory
- Git branch information
- Timestamp of last activity
- Session ID for restoration

## Worktree Integration

The worktree feature creates isolated development environments:

1. Creates a new git worktree for the feature/bug
2. Opens a new WezTerm tab (if available)
3. Starts a Claude session with context
4. Creates a `CLAUDE.md` file with task information

## Development

### Adding New Features

1. **Core logic** goes in `core/` - no UI dependencies
2. **UI components** go in `ui/` - Telescope pickers, previews
3. **Shared utilities** go in `utils/` - Git ops, file I/O
4. **Configuration** updates go in `config.lua`

### Testing

Test the module with:

```vim
:lua require("neotex.ai-claude").setup()
:lua require("neotex.ai-claude").smart_toggle()
```

## Migration from Old Structure

This module consolidates functionality previously spread across:
- `neotex.core.claude-session`
- `neotex.core.claude-worktree`
- `neotex.core.claude-visual`
- `neotex.core.claude-native-sessions`
- `neotex.core.claude-sessions-picker`

All functionality is preserved with improved organization.

## Troubleshooting

### Sessions not appearing
- Check that Claude CLI is installed and working
- Verify sessions exist with `claude --list-sessions`
- Check session files in `~/.claude/sessions/`

### Worktree creation fails
- Ensure you're in a git repository
- Check that the branch name doesn't already exist
- Verify git worktree support with `git worktree list`

### Simple picker shows all sessions
- Adjust `simple_picker_max` in configuration
- Default is 3, can be set from 1-10

## Future Enhancements

The organized structure makes these additions straightforward:

1. **Session Templates** - Add `core/templates.lua`
2. **Multi-model Support** - Add `core/models.lua`
3. **Enhanced Context** - Add `core/context.lua`
4. **Session Sharing** - Add `core/sync.lua`
5. **Analytics** - Add `utils/metrics.lua`

---

*Module created as part of Claude Session Enhancement v3*
*Maintains backward compatibility while improving organization*