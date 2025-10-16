# AI Integration Overview

This document provides a comprehensive overview of all AI-related functionality in the Neovim configuration, focusing on Claude Code integration and session management features that have been added.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         KEYMAPS                              │
│                    (<leader>a mappings)                      │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────┼────────────────────────────────────────┐
│                 PLUGINS                                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Claude Code  │ │    Avante    │ │    Lectic    │        │
│  │ (greggh/)    │ │ (yetone/)    │ │   (local)    │        │
│  └──────┬───────┘ └──────────────┘ └──────────────┘        │
└─────────┼────────────────────────────────────────────────────┘
          │
┌─────────┼────────────────────────────────────────────────────┐
│      CORE MODULES                                            │
│  ┌──────────────────────┐  ┌──────────────────────┐         │
│  │ claude-session.lua   │  │ claude-worktree.lua  │         │
│  │ • Smart toggle       │  │ • Git worktree mgmt  │         │
│  │ • Session restore    │  │ • Parallel sessions  │         │
│  │ • State persistence  │  │ • WezTerm integration│         │
│  └──────────┬───────────┘  └──────────────────────┘         │
│             │                                                │
│  ┌──────────┴───────────┐  ┌──────────────────────┐         │
│  │ claude-native-       │  │ claude-visual.lua    │         │
│  │ sessions.lua         │  │ • Visual selection   │         │
│  │ • Parse JSONL files  │  │ • Send to Claude     │         │
│  │ • Telescope picker   │  └──────────────────────┘         │
│  └──────────────────────┘                                   │
└─────────────────────────────────────────────────────────────┘
```

## Key Mappings (<leader>a)

### Claude Code Mappings
- `<C-c>` - Smart toggle Claude Code with session restoration
- `<leader>ac` - Continue last Claude session
- `<leader>ar` - Resume Claude session (native Telescope picker)
- `<leader>as` - Send visual selection to Claude
- `<leader>av` - View Claude worktree sessions
- `<leader>aw` - Create new Claude worktree
- `<leader>ak` - Kill/cleanup stale Claude sessions
- `<leader>ao` - Open/restore Claude session
- `<leader>ah` - Check Claude session health

### Avante.nvim Mappings
- `<leader>aa` - Avante ask
- `<leader>ae` - Avante edit (visual mode)
- `<leader>ap` - Select Avante provider
- `<leader>am` - Select Avante model
- `<leader>at` - Toggle Avante
- `<leader>ax` - Open MCP Hub

### Lectic Mappings (context-sensitive)
- `<leader>al` - Run Lectic
- `<leader>al` - Submit selection to Lectic (visual mode)
- `<leader>an` - Create new Lectic file
- `<leader>aP` - Select Lectic provider

## Core Modules

### 1. claude-session.lua
**Purpose**: Enhanced session management with automatic restoration

**Key Features**:
- Tracks session state in `~/.local/share/nvim/claude/last_session.json`
- Smart toggle with session restoration prompts
- Telescope picker with three options:
  - Continue last session
  - Browse all sessions
  - Start new session
- Auto-detects recent sessions in same directory/git repo
- Saves git branch and timestamp metadata

**Functions**:
- `M.smart_toggle()` - Main entry point for `<C-c>`
- `M.save_session_state()` - Persists current session info
- `M.check_for_recent_session()` - Validates if restoration is appropriate
- `M.show_session_picker()` - Displays Telescope UI with previews
- `M.continue_session()` - Direct continue without UI
- `M.resume_session()` - Opens native session browser

### 2. claude-native-sessions.lua
**Purpose**: Parse and display Claude's actual session files

**Key Features**:
- Reads from `~/.claude/projects/[project-folder]/*.jsonl`
- Parses JSONL session files with message history
- Extracts message content from complex nested structures
- Handles timezone conversion for timestamps
- Dynamic text wrapping based on preview width

**Functions**:
- `M.get_project_folder()` - Maps CWD to Claude's project folder format
- `M.parse_session_file()` - Extracts metadata from JSONL files
- `M.get_sessions()` - Returns sorted list of sessions
- `M.format_time_ago()` - Human-readable time differences
- `M.show_session_picker()` - Native Telescope picker with real session IDs

### 3. claude-worktree.lua
**Purpose**: Manages parallel Claude sessions with git worktrees

**Key Features**:
- Creates isolated Claude sessions per git worktree
- WezTerm tab integration
- Session state persistence
- Automatic context file generation

**Commands**:
- `:ClaudeWorktree` - Create new worktree with Claude session
- `:ClaudeSessions` - View all worktree sessions
- `:ClaudeSessionCleanup` - Remove stale sessions

### 4. claude-visual.lua
**Purpose**: Send visual selections to Claude

**Features**:
- Captures visual selection
- Formats and sends to Claude
- Maintains conversation context

### 5. claude-sessions-picker.lua (helper)
**Purpose**: Alternative session picker implementation (partially implemented)

## Plugin Configurations

### claudecode.lua (/lua/neotex/plugins/ai/)
**Plugin**: greggh/claude-code.nvim

**Configuration**:
```lua
{
  window = {
    split_ratio = 0.40,
    position = "vertical",
    enter_insert = true,
  },
  refresh = {
    enable = true,
    show_notifications = true,
  },
  git = {
    use_git_root = true,
  },
  command_variants = {
    continue = "--continue",
    resume = "--resume",
    verbose = "--verbose",
  },
}
```

**Customizations**:
- Terminal buffer management (unlisted, hidden)
- Auto-insert mode for better UX
- Session management integration via setup()

### avante.lua (/lua/neotex/plugins/ai/)
**Plugin**: yetone/avante.nvim

**Features**:
- Inline AI editing
- Multiple provider support
- MCP server integration

### lectic.lua (/lua/neotex/plugins/ai/)
**Purpose**: Local Markdown-based AI interactions

## Session Data Structure

### Claude Session Files Location
```
~/.claude/projects/
├── -home-benjamin--config/
│   ├── [session-uuid].jsonl
│   └── ...
└── -home-benjamin-Documents-Philosophy-TODO/
    ├── [session-uuid].jsonl
    └── ...
```

### Session State File
```json
{
  "cwd": "/home/benjamin/.config",
  "timestamp": 1234567890,
  "git_root": "/home/benjamin/.config",
  "branch": "master"
}
```

### JSONL Message Format
```json
{
  "sessionId": "uuid",
  "timestamp": "2025-09-16T07:46:57.569Z",
  "gitBranch": "master",
  "message": {
    "role": "assistant",
    "content": [{
      "type": "text",
      "text": "Actual message content"
    }]
  }
}
```

## Recent Enhancements (Session Restoration Feature)

### What Was Added
1. **Smart Session Detection**: Automatically detects if there's a recent Claude session when pressing `<C-a>`
2. **Native Session Browser**: Custom Telescope picker that reads actual Claude session files
3. **Dynamic Preview Formatting**: Text wrapping adjusts to preview window width
4. **Project Isolation**: Sessions are filtered by git repository root
5. **Rich Previews**: Shows session age, message count, and last message content

### Technical Implementation
- **State Persistence**: Uses `~/.local/share/nvim/claude/last_session.json`
- **JSONL Parsing**: Directly reads Claude's session files
- **Timezone Handling**: Converts UTC timestamps to local time
- **Git Integration**: Uses git root to determine project context
- **Dynamic UI**: Preview width detection for responsive text wrapping

## Future Plugin Architecture

Based on the current implementation, a standalone plugin could provide:

### Core Features
1. Session management (continue, resume, restore)
2. Project-based session isolation
3. Visual selection integration
4. Worktree support

### Proposed API
```lua
require("claude-enhanced").setup({
  session = {
    auto_restore = true,
    max_age_hours = 24,
  },
  ui = {
    picker = "telescope",  -- or "fzf-lua"
    preview_width = "dynamic",
  },
  worktree = {
    enabled = true,
    auto_context = true,
  }
})
```

### Module Structure
```
claude-enhanced.nvim/
├── lua/
│   └── claude-enhanced/
│       ├── init.lua
│       ├── session.lua
│       ├── picker.lua
│       ├── worktree.lua
│       ├── visual.lua
│       └── utils.lua
└── plugin/
    └── claude-enhanced.lua
```

## Dependencies

### Required
- `nvim-lua/plenary.nvim` - Path utilities, async
- `greggh/claude-code.nvim` - Base Claude integration
- `nvim-telescope/telescope.nvim` - UI picker

### Optional
- `ThePrimeagen/git-worktree.nvim` - Worktree management
- `willothy/wezterm.nvim` - Terminal tab integration

## Configuration Files

### Key Files Modified
1. `/lua/neotex/plugins/ai/claudecode.lua` - Plugin config
2. `/lua/neotex/plugins/editor/which-key.lua` - Keymaps
3. `/lua/neotex/core/claude-*.lua` - Core functionality

### Data Files
- `~/.local/share/nvim/claude/last_session.json` - Session state
- `~/.claude/projects/*/` - Claude's native session storage

## Notes for Plugin Development

1. **Session ID Format**: UUIDs like `ff49bd37-6741-4966-bda2-d0e592471d7b`
2. **Project Folder Naming**: Slashes → dashes, dots → double dashes
3. **Message Extraction**: Handle nested content arrays with type checking
4. **Timestamp Parsing**: ISO 8601 with UTC timezone considerations
5. **UI Responsiveness**: Use `vim.api.nvim_win_get_width()` for dynamic sizing

This overview should help you understand the current architecture and plan for the standalone plugin development.