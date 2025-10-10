# AI Claude Core Modules

Core business logic modules for Claude AI integration. These modules handle session management, worktree operations, and visual selection processing without UI dependencies.

## Modules

### session.lua
Core session state management for Claude Code. Handles session creation, restoration, persistence, and cleanup with automatic staleness detection.

**Key Features:**
- Session state persistence to `~/.local/share/nvim/claude/`
- Automatic cleanup of stale sessions (24+ hours old)
- Project-scoped session management
- Session validation and error handling
- Simple picker with recent session limits

**Key Functions:**
- `save_session_state()` - Persist current session with metadata
- `load_session_state()` - Restore saved session state
- `check_for_recent_session()` - Check if recent session exists
- `get_session_metadata()` - Extract session information
- `cleanup_old_sessions()` - Remove stale sessions automatically
- `restore_session(id)` - Resume specific session by ID

**Session Metadata:**
```lua
{
  cwd = "/path/to/project",
  branch = "main",
  timestamp = os.time(),
  session_id = "uuid-format-string"
}
```

### session-manager.lua
Robust session validation and management with UUID validation and existence checks.

**Key Features:**
- UUID pattern matching for session ID validation
- Session existence verification via Claude CLI
- Automatic recovery from invalid sessions
- User-friendly error notifications
- Safe session restoration with validation

**Key Functions:**
- `validate_session_id(id)` - Validate UUID format
- `session_exists(id)` - Check if session exists in Claude CLI
- `resume_session(id)` - Safely restore session with validation
- `get_native_sessions()` - Get all Claude CLI sessions
- `safe_restore(id)` - Resume with comprehensive error handling

**Validation:**
- UUID format: `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`
- Existence check: `claude --resume <id> --dry-run`
- Fallback to new session on validation failure

### visual.lua
Visual selection processing for sending code to Claude with context.

**Key Features:**
- Multi-mode support (visual, line, block)
- Filename and line number inclusion
- Interactive prompt input
- Smart formatting for AI consumption
- Context-aware `<leader>ac` behavior

**Key Functions:**
- `send_to_claude()` - Send visual selection to Claude
- `send_to_claude_with_prompt()` - Send with interactive prompt
- `format_selection(lines, filename, start_line)` - Format code with context
- `validate_visual_mode()` - Ensure text is selected

**Usage:**
```lua
-- In visual mode
require('neotex.plugins.ai.claude.core.visual').send_to_claude()

-- With prompt
require('neotex.plugins.ai.claude.core.visual').send_to_claude_with_prompt()
```

**Output Format:**
```
File: path/to/file.lua (lines 10-25)

-- Selected code here
```

### worktree.lua
Git worktree integration with Claude session management and terminal coordination.

**Key Features:**
- Isolated development environments per branch
- Automatic worktree creation with Claude sessions
- WezTerm/Kitty tab integration
- Context file generation (CLAUDE.md)
- Session restoration across worktrees
- Automatic cleanup of completed worktrees

**Key Functions:**
- `create_worktree_with_claude(opts)` - Create worktree with session
- `restore_worktree_session()` - Restore closed worktree
- `cleanup_worktree(branch)` - Remove worktree and session
- `get_worktree_sessions()` - List all worktree sessions
- `telescope_worktrees()` - Browse worktrees in Telescope

**Options:**
```lua
{
  branch = "feature/new-api",          -- Branch name
  type = "feature",                    -- Type: feature, bugfix, refactor, etc.
  description = "Implement new API",   -- Task description
  path = "/path/to/worktree",         -- Worktree location (auto-generated)
  create_context = true,               -- Create CLAUDE.md file
  switch_tab = true,                   -- Open new terminal tab
}
```

**Worktree Types:**
- `feature` - New features
- `bugfix` - Bug fixes
- `refactor` - Code refactoring
- `experiment` - Experimental changes
- `hotfix` - Urgent fixes

**CLAUDE.md Template:**
```markdown
# Task: [Branch Name]

## Description
[Task description]

## Type
[feature|bugfix|refactor|experiment|hotfix]

## Context
- Branch: [branch-name]
- Created: [timestamp]
- Session: [session-id]
```

## Architecture

### Separation of Concerns
- **session.lua**: Low-level session I/O and persistence
- **session-manager.lua**: High-level validation and safety
- **visual.lua**: Visual mode handling (no terminal dependencies)
- **worktree.lua**: Git operations and workflow orchestration

### Dependencies
```
worktree.lua
├── session.lua (for session management)
├── session-manager.lua (for validation)
├── utils/git.lua (for git operations)
├── utils/terminal-detection.lua (for terminal type)
└── utils/terminal-commands.lua (for tab management)

session-manager.lua
├── session.lua (for basic operations)
└── plenary.job (for CLI validation)

visual.lua
├── utils/terminal-state.lua (for command queueing)
└── vim.ui.input (for prompt dialogs)

session.lua
└── plenary.path (for file I/O)
```

### State Management
- **Session State**: Stored in `~/.local/share/nvim/claude/`
- **Worktree State**: Tracked via git worktree list + session metadata
- **Visual State**: Ephemeral, extracted from visual mode selection

## Usage Examples

### Session Management
```lua
local session = require('neotex.plugins.ai.claude.core.session')

-- Save current session
session.save_session_state()

-- Check for recent session
local has_recent = session.check_for_recent_session()

-- Restore specific session
local manager = require('neotex.plugins.ai.claude.core.session-manager')
manager.resume_session("uuid-here")
```

### Visual Selection
```lua
local visual = require('neotex.plugins.ai.claude.core.visual')

-- Send selection (in visual mode)
visual.send_to_claude()

-- Send with prompt
visual.send_to_claude_with_prompt()
```

### Worktree Operations
```lua
local worktree = require('neotex.plugins.ai.claude.core.worktree')

-- Create new worktree with Claude
worktree.create_worktree_with_claude({
  branch = "feature/api-v2",
  type = "feature",
  description = "Implement API v2"
})

-- Restore closed worktree
worktree.restore_worktree_session()

-- Browse worktrees
worktree.telescope_worktrees()
```

## Error Handling

### Session Errors
- **Invalid UUID**: Shows error, offers new session
- **Session not found**: Auto-cleanup, starts fresh
- **File I/O errors**: Graceful fallback with notifications

### Worktree Errors
- **Git errors**: Clear error messages with git output
- **Terminal not supported**: Falls back to current window
- **Branch conflicts**: Validates before creation

### Visual Mode Errors
- **No selection**: Validates before sending
- **Empty prompt**: Configurable allow/reject
- **Terminal errors**: Queues command for retry

## Testing

### Session Testing
```vim
:lua require('neotex.plugins.ai.claude.core.session').save_session_state()
:lua print(vim.inspect(require('neotex.plugins.ai.claude.core.session').load_session_state()))
```

### Visual Testing
```vim
" Select some code in visual mode
v}
" Send to Claude
:lua require('neotex.plugins.ai.claude.core.visual').send_to_claude()
```

### Worktree Testing
```vim
:lua require('neotex.plugins.ai.claude.core.worktree').create_worktree_with_claude({branch = "test/feature", type = "experiment", description = "Testing worktree"})
```

## Navigation
- [<- Parent Directory](../README.md)
- [Session Manager](session-manager.lua)
- [Worktree Integration](worktree.lua)
- [Visual Selection](visual.lua)
