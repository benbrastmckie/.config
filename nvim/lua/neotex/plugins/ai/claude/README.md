# Claude AI Integration Module

This module provides a comprehensive internal Claude AI integration system for Neovim, containing 9,626 lines of code across 20 files. It works in conjunction with the external `claude-code.nvim` plugin (configured in `../claudecode.lua`) to provide advanced Claude AI functionality.

## Architectural Overview

This module represents the **internal system** for Claude AI integration, while `../claudecode.lua` serves as the **external plugin configuration layer**. This separation follows clean architecture principles:

- **External dependencies** are isolated in plugin configs
- **Internal business logic** is organized in domain modules
- **Clear boundary** between "what we use" vs "what we built"

## Core Features

### 1. Session Management System
- **Smart session detection and restoration** with UUID validation
- **Session state persistence** to `~/.local/share/nvim/claude/`
- **Automatic cleanup** of stale sessions (24+ hours)
- **Context-aware session switching** with project scoping
- **Robust error handling** and session validation

### 2. Git Worktree Integration
- **Isolated development environments** with dedicated Claude sessions
- **Automatic worktree creation** with Claude context
- **Branch-specific session management** and restoration
- **WezTerm tab integration** for seamless workflow
- **Context file generation** (`CLAUDE.md`) with task information

### 3. Visual Selection Processing
- **Send selected code to Claude** with full context
- **Filename and line number inclusion** for precise references
- **Smart formatting** optimized for AI consumption
- **Multi-mode support** (visual, line, block)

### 4. Terminal Detection and Management
- **Universal terminal support** (Kitty, WezTerm, Alacritty, etc.)
- **Automatic capability detection** and optimization
- **Context-aware command generation** per terminal type
- **Terminal-specific integrations** (e.g., Kitty remote control)

### 5. Advanced UI Components
- **Telescope integration** with rich session browsing
- **Simple and full session pickers** with intelligent defaults
- **Command hierarchy browser** with extensible framework
- **Preview functionality** with session metadata
- **Native session handling** with time formatting

### 6. Command System
- **Hierarchical command organization** with parsing
- **Custom command execution** framework
- **Extensible command framework** for future expansion
- **Command picker UI** with 1,114 lines of interface code

### 7. Project Integration
- **Project-aware session scoping** based on git repositories
- **Automatic context file generation** for development tasks
- **Git branch awareness** and worktree coordination
- **Session restoration** across project switches

### 8. Advanced Integrations
- **Avante plugin support** with highlights and MCP protocol
- **MCP server implementation** (715 lines) for tool communication
- **System prompt management** (670 lines) for AI optimization
- **Tool registry system** (401 lines) for extensible functionality

## Directory Structure

**Total: 9,626 lines across 20 files**

```
ai/claude/
├── init.lua                      # Main entry point and public API (162 lines)
├── config.lua                    # Configuration management
├── README.md                     # This documentation file
│
├── core/                         # 3,800+ lines - Core business logic
│   ├── session.lua              # Core session management (461 lines)
│   ├── session-manager.lua      # Robust session validation (476 lines)
│   ├── visual.lua               # Visual selection handling (588 lines)
│   └── worktree.lua             # Git worktree integration (2,275 lines)
│
├── ui/                          # 870+ lines - User interface components
│   ├── pickers.lua              # Telescope pickers (272 lines)
│   └── native-sessions.lua      # Native session handling (598 lines)
│
├── utils/                       # 3,400+ lines - Core utilities
│   ├── claude-code.lua          # Claude Code integration (145 lines)
│   ├── git.lua                  # Git operations (46 lines)
│   ├── persistence.lua          # Session file I/O (72 lines)
│   ├── terminal.lua             # Terminal management (61 lines)
│   ├── terminal-detection.lua   # Terminal type detection (168 lines)
│   └── terminal-commands.lua    # Command generation (96 lines)
│
├── util/                        # 2,300+ lines - Advanced utilities
│   ├── avante-highlights.lua    # Syntax highlighting (193 lines)
│   ├── avante-support.lua       # Avante integration (560 lines)
│   ├── avante_mcp.lua           # MCP protocol support (416 lines)
│   ├── mcp_server.lua           # MCP server implementation (715 lines)
│   ├── system-prompts.lua       # System prompt management (670 lines)
│   └── tool_registry.lua        # Tool registration system (401 lines)
│
├── commands/                    # 1,400+ lines - Command system
│   ├── parser.lua               # Command parsing (299 lines)
│   └── picker.lua               # Command picker UI (1,114 lines)
│
└── specs/                       # Documentation and planning
    ├── plans/                   # Implementation plans (5 plans)
    ├── reports/                 # Research reports (7 reports)
    └── summaries/               # Implementation summaries (4 summaries)
```

### External Plugin Configuration

This internal system is initialized by the external plugin configuration:
- **`../claudecode.lua`** (107 lines) - External `claude-code.nvim` plugin wrapper
- **Purpose**: Bridges external plugin with this internal system
- **Responsibilities**: Plugin management, terminal behavior, deferred initialization
- **Integration**: Sets up session manager and coordinates with internal modules

## Usage

### Initialization

This module is automatically initialized through the external plugin configuration in `../claudecode.lua`. Direct setup is also possible:

```lua
-- Direct initialization (usually handled automatically)
require("neotex.plugins.ai.claude").setup({
  simple_picker_max = 3,        -- Show max 3 sessions in simple picker
  auto_restore_session = true,  -- Auto-restore last session
  session_timeout_hours = 24,   -- Session staleness threshold
  worktree = {
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
  }
})
```

### Keybindings

Default keybindings (configured in `which-key.lua`):

- `<C-c>` - Smart toggle Claude Code (all modes)
- `<leader>ac` - Context-sensitive Claude commands:
  - **Normal mode**: Browse Claude commands
  - **Visual mode**: Send selection to Claude with prompt
- `<leader>as` - Browse Claude sessions
- `<leader>av` - View worktrees
- `<leader>aw` - Create new worktree with Claude session
- `<leader>ar` - Restore closed worktree session

### Commands

The module creates these user commands:

- `:ClaudeCommands` - Browse Claude commands in hierarchical picker
- `:ClaudeWorktree` - Create a new worktree with Claude session
- `:ClaudeSessions` - Open full session browser
- `:ClaudeSession` - Switch to a different session
- `:ClaudeRestoreWorktree` - Restore a previously closed worktree

### Visual Selection Commands

- `:ClaudeSendVisual [prompt]` - Send visual selection with optional prompt
- `:ClaudeSendVisualPrompt` - Send visual selection with interactive prompt input

### Additional Commands (via command system)

The extensible command framework provides additional functionality accessible through the command picker (`:ClaudeCommands`).

## API Reference

### Main Module (`init.lua`)

```lua
local ai = require("neotex.plugins.ai.claude")

-- Session Management
ai.smart_toggle()              -- Smart toggle with simple picker
ai.resume_session(id)           -- Resume specific session
ai.save_session_state()         -- Save current session state
ai.load_session_state()         -- Load saved session state
ai.check_for_recent_session()   -- Check if recent session exists

-- Worktree Management
ai.create_worktree_with_claude(opts)  -- Create worktree with session
ai.telescope_sessions()               -- Show sessions in Telescope
ai.telescope_worktrees()              -- Show worktrees in Telescope

-- Visual Selection
ai.send_visual_to_claude()                  -- Send visual selection to Claude
ai.send_visual_to_claude_with_prompt()      -- Send with interactive prompt

-- Setup
ai.setup(opts)                  -- Initialize with configuration

-- Additional APIs
ai.show_commands_picker()        -- Show command hierarchy browser
ai.get_native_sessions()         -- Get native Claude sessions
ai.format_time_ago(timestamp)    -- Format timestamps for display
```

### Configuration Options

```lua
{
  -- Picker settings
  simple_picker_max = 3,          -- Max sessions in simple picker
  show_preview = true,            -- Show preview in pickers

  -- Session management
  auto_restore_session = true,    -- Auto-restore on startup
  auto_save_session = true,       -- Save session state automatically
  session_timeout_hours = 24,     -- Sessions older than this are stale

  -- Worktree settings
  worktree = {
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
    default_type = "feature",
  },

  -- Terminal settings
  auto_insert_mode = true,        -- Auto-enter insert mode
  terminal_height = 15,           -- Height of terminal split

  -- Visual selection
  visual = {
    include_filename = true,      -- Include filename in selection
    include_line_numbers = true,  -- Include line numbers
  },

  -- Advanced features (configured automatically)
  mcp_server = {
    enable = true,                -- Enable MCP server functionality
    tool_registry = true,         -- Enable tool registration
  },
  avante_integration = {
    enable = true,                -- Enable Avante plugin support
    highlights = true,            -- Enable syntax highlighting
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

## Session Persistence and Management

### Storage Location
Sessions are automatically saved to `~/.local/share/nvim/claude/` with comprehensive metadata:
- **Current working directory** for project context
- **Git branch information** for development context
- **Timestamp of last activity** for staleness detection
- **Session ID with UUID validation** for reliable restoration
- **Project-specific scoping** for organized session management

### Session Validation
The session manager (`core/session-manager.lua`) provides robust validation:
- **UUID pattern matching** for session ID validation
- **Session existence verification** before restoration attempts
- **Automatic cleanup** of invalid or corrupted sessions
- **Error handling** with user-friendly notifications

### Session Lifecycle
1. **Creation**: Automatic session creation with metadata
2. **Validation**: Real-time session ID and state validation
3. **Persistence**: Automatic saving of session state
4. **Restoration**: Smart session restoration with context
5. **Cleanup**: Automatic removal of stale sessions (24+ hours)

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

### Usage Examples

#### Visual Selection with Prompt
1. **Select text** in visual mode (`v`, `V`, or `Ctrl-v`)
2. **Press `<leader>ac`** to trigger the interactive prompt
3. **Enter your question** (e.g., "Please explain this function")
4. **Claude opens** with your selection and custom prompt

Example workflow:
```vim
" Select a function in visual mode
v}
" Press <leader>ac (same key as normal mode, but context-aware)
" Enter prompt: "What does this function do and how can I optimize it?"
" Claude receives the selection with your question
```

#### Claude Commands Browser
1. **In normal mode**, press `<leader>ac` to browse available Claude commands
2. **Navigate** through the hierarchical command picker
3. **Select** a command to execute

#### Command Usage
```vim
" With visual selection active:
:ClaudeSendVisual Please review this code for bugs
:ClaudeSendVisualPrompt  " Interactive prompt input
```

### Testing

Test the module with:

```vim
:lua require("neotex.plugins.ai.claude").setup()
:lua require("neotex.plugins.ai.claude").smart_toggle()

" Test visual selection feature:
" 1. Select some text in visual mode
" 2. Press <leader>ac
" 3. Enter a prompt when prompted
```

### Code Quality
Run linting and formatting:
```vim
<leader>l     " Run linter
<leader>mp    " Format code
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

### Session Issues

**Sessions not appearing:**
- Check that Claude CLI is installed: `claude --version`
- Verify sessions exist: `claude --list-sessions`
- Check session files in `~/.local/share/nvim/claude/`
- Verify session ID format (UUID validation)

**Session restoration fails:**
- Check session manager logs for validation errors
- Verify session metadata integrity
- Clear stale sessions: automatic cleanup after 24 hours

**Simple picker shows all sessions:**
- Adjust `simple_picker_max` in configuration (default: 3, range: 1-10)
- Check session staleness threshold (`session_timeout_hours`)

### Worktree Issues

**Worktree creation fails:**
- Ensure you're in a git repository: `git status`
- Check branch name availability: `git branch -a`
- Verify git worktree support: `git worktree list`
- Check terminal integration (WezTerm/Kitty)

**Terminal integration problems:**
- Verify terminal detection: check `utils/terminal-detection.lua`
- Test terminal commands: see `utils/terminal-commands.lua`
- Check terminal-specific features (e.g., Kitty remote control)

### UI and Integration Issues

**Telescope pickers not working:**
- Verify Telescope installation and configuration
- Check picker initialization in `ui/pickers.lua`
- Test with `:ClaudeCommands` command

**Avante integration problems:**
- Check Avante plugin installation
- Verify MCP server functionality
- Test tool registry system

**Visual selection not working:**
- Verify mode detection (visual/line/block)
- Check selection formatting in `core/visual.lua`
- Test filename and line number inclusion

**`<leader>ac` mapping issues:**
- **Visual mode**: Ensure text is selected before pressing `<leader>ac`
- **Normal mode**: `<leader>ac` should open Claude commands browser
- **Mode detection**: Function validates visual mode automatically
- **Alternative**: Use `:ClaudeSendVisualPrompt` command if mapping fails
- **Which-key**: Verify with `:lua print(require('which-key'))`

**Prompt input problems:**
- If prompt dialog doesn't appear, check `vim.ui.input()` availability
- Empty prompts are rejected by default (see `allow_empty_prompt` config)
- Prompt timeout: dialog auto-cancels after extended inactivity
- Test with different UI implementations if dialog doesn't show

## Architecture and Implementation Details

### Code Organization Principles

**Core Business Logic** (`core/`): 3,800+ lines
- No UI dependencies
- Pure business logic and domain models
- Session management, worktree operations, visual processing

**User Interface** (`ui/`): 870+ lines
- Telescope integration and pickers
- Native session handling and formatting
- Preview functionality and user interactions

**Utilities** (`utils/` + `util/`): 5,700+ lines
- Shared utilities and helper functions
- Terminal detection and command generation
- Advanced integrations (Avante, MCP, tool registry)

**Command System** (`commands/`): 1,400+ lines
- Hierarchical command organization
- Extensible parsing and execution framework
- Rich command picker interface

### External Dependencies

- **`claude-code.nvim`** - External plugin (configured in `../claudecode.lua`)
- **`plenary.nvim`** - Lua utilities and async operations
- **`telescope.nvim`** - UI pickers and preview functionality
- **Terminal applications** - Kitty, WezTerm, Alacritty support
- **Git** - Worktree operations and branch management

### Integration Points

**With external plugin** (`../claudecode.lua`):
- Session manager initialization (deferred setup)
- Configuration bridging and option passing
- Terminal behavior coordination

**With Neovim ecosystem**:
- Autocmd integration for buffer management
- User command registration
- Keymap coordination (via `neotex.config.keymaps`)

## Future Enhancements

The organized structure enables straightforward additions:

### Core Enhancements
1. **Session Templates** - Add `core/templates.lua` for reusable session configurations
2. **Multi-model Support** - Add `core/models.lua` for different AI model support
3. **Enhanced Context** - Add `core/context.lua` for advanced context management
4. **Session Sharing** - Add `core/sync.lua` for session synchronization

### Utility Expansions
5. **Analytics** - Add `utils/metrics.lua` for usage tracking
6. **Backup System** - Add `utils/backup.lua` for session backup/restore
7. **Plugin Integrations** - Extend `util/` for more plugin support

### UI Improvements
8. **Advanced Previews** - Enhanced session preview functionality
9. **Custom Pickers** - Specialized pickers for different use cases
10. **Dashboard** - Session overview and management interface

## Documentation and Specifications

Comprehensive documentation is maintained in `specs/`:
- **Implementation Plans** (5 plans) - Detailed feature implementation guides
- **Research Reports** (7 reports) - Technical analysis and investigation results
- **Implementation Summaries** (4 summaries) - Post-implementation documentation

## Navigation

- [← Parent Directory](../README.md) - AI plugins overview
- [External Plugin Config](../claudecode.lua) - `claude-code.nvim` configuration
- [Core Modules](core/README.md) - Core business logic documentation
- [UI Components](ui/README.md) - User interface documentation
- [Utilities](utils/README.md) - Utility functions documentation
- [Specifications](specs/README.md) - Implementation plans and reports

---

**Architecture Summary**: This comprehensive internal system (9,626 lines) works with the external plugin configuration (`../claudecode.lua`, 107 lines) to provide advanced Claude AI integration. The clear separation between external plugin management and internal system implementation follows clean architecture principles and enables maintainable, extensible code organization.

*Module developed through iterative implementation phases with comprehensive testing and documentation.*