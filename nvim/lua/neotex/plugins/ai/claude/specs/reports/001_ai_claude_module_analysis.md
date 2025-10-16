# AI-Claude Module Architecture and Features Research Report

## Metadata
- **Date**: 2025-09-29
- **Scope**: Complete analysis of the ai-claude module structure, features, and integration patterns
- **Primary Directory**: `/home/benjamin/.config/nvim/lua/neotex/ai-claude/`
- **Files Analyzed**: 13 Lua modules, 2 README files, 3 spec documents

## Executive Summary

The ai-claude module is a comprehensive Neovim integration for Claude Code that provides sophisticated session management, git worktree integration, and intelligent UI components. The module follows a clean architectural pattern with separation between core logic, UI components, and utilities. It offers advanced features like smart session toggling, project-aware contexts, and terminal emulator integration.

## Module Architecture

### Directory Structure
```
nvim/lua/neotex/ai-claude/
├── init.lua                    # Main entry point and public API
├── config.lua                  # Configuration management
├── README.md                   # Module documentation
│
├── core/                       # Core business logic
│   ├── session.lua            # Session management & persistence
│   ├── worktree.lua          # Git worktree orchestration
│   └── visual.lua            # Visual selection handling
│
├── ui/                        # User interface components
│   ├── pickers.lua           # Telescope pickers
│   └── native-sessions.lua  # Native Claude session handling
│
├── utils/                     # Utility functions
│   ├── claude-code.lua       # Claude Code plugin integration
│   ├── git.lua              # Git operations
│   ├── persistence.lua      # Session file I/O
│   ├── terminal.lua         # Terminal buffer management
│   ├── terminal-detection.lua # Terminal emulator detection
│   └── terminal-commands.lua # Terminal-agnostic commands
│
└── specs/                     # Documentation and planning
    ├── plans/                # Implementation plans
    ├── reports/              # Research reports
    └── summaries/            # Implementation summaries
```

### Architectural Principles

1. **Separation of Concerns**: Clear boundaries between core logic, UI, and utilities
2. **Module Independence**: Each module has specific responsibilities with minimal coupling
3. **Extensibility**: Design allows for easy addition of new features
4. **Backward Compatibility**: Maintains compatibility while improving organization

## Core Features

### 1. Smart Session Management

**Location**: `core/session.lua`

The session management system provides intelligent context-aware session handling:

- **Auto-save/restore**: Tracks sessions per directory/project
- **24-hour session timeout**: Considers sessions stale after 24 hours
- **Git awareness**: Tracks branch information with sessions
- **State persistence**: Saves to `~/.local/share/nvim/claude/`
- **Smart toggle behavior**:
  - If Claude open → Toggle visibility
  - If recent session exists → Show menu (Continue/Browse/New)
  - If no recent sessions → Start new session

### 2. Git Worktree Integration

**Location**: `core/worktree.lua`

Advanced git worktree orchestration for isolated development:

- **Automated worktree creation**: Creates feature branches with Claude sessions
- **Terminal tab management**: Integrates with Kitty/WezTerm for tab creation
- **Context files**: Generates `CLAUDE.md` with task information
- **Session tracking**: Maps worktrees to Claude sessions
- **Maximum 4 concurrent sessions**: Configurable limit
- **Worktree types**: feature, bugfix, refactor, experiment, hotfix

### 3. Visual Selection Handling

**Location**: `core/visual.lua`

Sophisticated code selection and context sending:

- **Smart selection**: Captures visual selections with context
- **Metadata inclusion**: Optional filename and line numbers
- **Buffer sending**: Can send entire buffers
- **Prompt integration**: Supports custom prompts with selections
- **User commands**: `ClaudeSendVisual`, `ClaudeSendBuffer`

### 4. Telescope Integration

**Location**: `ui/pickers.lua`

Rich UI for session browsing:

- **Simple picker**: Shows 3 most recent sessions (configurable)
- **Full picker**: Browse all available sessions
- **Preview panes**: Shows session details
- **Smart filtering**: Project-aware session listing
- **Hierarchical display**: Shows session relationships

### 5. Claude Code Plugin Integration

**Location**: `utils/claude-code.lua`

Clean interface for Claude Code plugin interaction:

- **Command abstraction**: Opens Claude with custom commands
- **Session resumption**: Direct session ID resumption
- **Continue mode**: Quick continuation support
- **Config preservation**: Doesn't modify global plugin config
- **Error handling**: Graceful fallback on failures

## Configuration System

The module uses a hierarchical configuration with sensible defaults:

```lua
{
  -- Picker settings
  simple_picker_max = 3,
  show_preview = true,

  -- Session management
  auto_restore_session = true,
  auto_save_session = true,
  session_timeout_hours = 24,

  -- Worktree settings
  worktree = {
    max_sessions = 4,
    auto_switch_tab = true,
    create_context_file = true,
    types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
    default_type = "feature",
  },

  -- Visual selection
  visual = {
    include_filename = true,
    include_line_numbers = true,
  }
}
```

## Integration Patterns

### 1. Terminal Emulator Detection

The module intelligently detects and adapts to different terminal emulators:

- **Supported terminals**: Kitty, WezTerm
- **Capability detection**: Checks for tab management support
- **Command abstraction**: Terminal-agnostic command generation
- **Graceful degradation**: Works without tab support

### 2. Notification System

Uses `neotex.util.notifications` for consistent user feedback:

- **Category-based**: ERROR, WARNING, INFO, USER_ACTION
- **Debug mode support**: Conditional verbose logging
- **Module tagging**: Tracks notification source

### 3. Public API Design

Clean, consistent API exposed through `init.lua`:

```lua
-- Session Management
M.smart_toggle()
M.resume_session(id)
M.save_session_state()
M.load_session_state()

-- Worktree Management
M.create_worktree_with_claude(opts)
M.telescope_sessions()
M.telescope_worktrees()

-- Visual Selection
M.send_visual_to_claude()
```

## User Commands

The module registers numerous commands for user interaction:

- `:ClaudeWorktree` - Create worktree with Claude session
- `:ClaudeSessions` - Browse all sessions
- `:ClaudeSession` - Switch sessions
- `:ClaudeSessionList` - List active sessions
- `:ClaudeSessionDelete` - Remove sessions
- `:ClaudeSessionCleanup` - Clean stale sessions
- `:ClaudeRestoreWorktree` - Restore closed worktree
- `:ClaudeSendVisual` - Send visual selection
- `:ClaudeSendBuffer` - Send entire buffer

## Advanced Features

### 1. Session Persistence

- JSON-based state files
- Per-project session tracking
- Git branch awareness
- Timestamp tracking for staleness

### 2. Context File Generation

Automated creation of `CLAUDE.md` files with:
- Task metadata
- Objectives and status tracking
- Claude-specific context
- Worktree information

### 3. Multi-Instance Support

- Tracks multiple Claude instances
- Per-worktree session isolation
- Tab-based instance management
- Concurrent session limits

## Technical Insights

### Strengths

1. **Modular Design**: Clean separation enables easy maintenance
2. **Feature-Rich**: Comprehensive session and worktree management
3. **Terminal Integration**: Advanced tab management capabilities
4. **User Experience**: Smart defaults and intuitive workflows
5. **Extensibility**: Clear patterns for adding new features

### Areas for Enhancement

1. **Command Discovery**: No built-in way to browse Claude commands
2. **Template System**: Limited template support (only context files)
3. **Session Analytics**: No metrics or usage tracking
4. **Multi-Model Support**: Claude-specific, not model-agnostic
5. **Documentation**: Could benefit from more inline examples

## Recommendations

### Immediate Improvements

1. **Add Command Picker**: Implement telescope picker for `.claude/commands/`
2. **Session Templates**: Add template system for common workflows
3. **Better Error Messages**: More descriptive error handling
4. **Command Completion**: Add command-line completion support

### Future Enhancements

1. **Analytics Module**: Track session metrics and usage patterns
2. **Model Abstraction**: Support multiple AI models
3. **Session Sharing**: Collaborative session support
4. **Context Enhancement**: Richer context gathering
5. **Plugin Integration**: Broader plugin ecosystem support

## Migration Path

The module successfully migrated from scattered implementations:

**Previous Structure**:
- `neotex.core.claude-session`
- `neotex.core.claude-worktree`
- `neotex.core.claude-visual`
- `neotex.core.claude-native-sessions`
- `neotex.core.claude-sessions-picker`

**Current Structure**: Unified under `neotex.ai-claude` with improved organization

## Usage Patterns

### Common Workflows

1. **Quick Session Toggle**: `<C-c>` for smart session management
2. **Feature Development**: `:ClaudeWorktree` for isolated work
3. **Code Review**: Visual selection + `ClaudeSendVisual`
4. **Session Recovery**: Auto-restore on directory entry

### Configuration Examples

```lua
require("neotex.ai-claude").setup({
  simple_picker_max = 5,        -- Show more recent sessions
  worktree = {
    max_sessions = 6,           -- Allow more concurrent sessions
    auto_switch_tab = false,    -- Manual tab switching
  },
  visual = {
    include_line_numbers = false, -- Cleaner code snippets
  }
})
```

## Conclusion

The ai-claude module represents a sophisticated integration between Neovim and Claude Code, providing advanced session management, git worktree orchestration, and intelligent UI components. Its modular architecture and clear separation of concerns make it maintainable and extensible. The recommended enhancements, particularly the command picker implementation planned in `001_claude_commands_telescope_picker.md`, would address current gaps and further improve the user experience.

## References

### Primary Files
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/init.lua` - Main module entry
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/core/worktree.lua` - Worktree orchestration
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/core/session.lua` - Session management
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/utils/claude-code.lua` - Plugin integration

### Documentation
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/README.md` - Module documentation
- `/home/benjamin/.config/nvim/lua/neotex/ai-claude/utils/README.md` - Utilities documentation
- `/home/benjamin/.config/nvim/specs/plans/001_claude_commands_telescope_picker.md` - Command picker plan

### Related Components
- `claude-code.nvim` - Base Claude Code plugin
- `telescope.nvim` - Fuzzy finder framework
- `git-worktree.nvim` - Git worktree management
- `.claude/commands/` - Claude command definitions