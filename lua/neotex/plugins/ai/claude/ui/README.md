# AI Claude UI Components

User interface components for Claude AI integration using Telescope. Provides interactive pickers for session browsing and management with rich previews and metadata display.

## Modules

### pickers.lua
Telescope picker integration for Claude session browsing and worktree management.

**Key Features:**
- Session browsing with preview
- Worktree listing with metadata
- Fuzzy finding and filtering
- Custom previewer with session details
- Smart default selection

**Key Functions:**
- `sessions_picker(opts)` - Browse all Claude sessions
- `simple_sessions_picker(opts)` - Recent sessions only (limited count)
- `worktrees_picker(opts)` - Browse git worktrees with Claude sessions
- `create_session_previewer()` - Custom previewer for session metadata
- `create_worktree_previewer()` - Custom previewer for worktree info

**Picker Options:**
```lua
{
  prompt_title = "Claude Sessions",      -- Picker title
  show_preview = true,                   -- Show preview window
  max_sessions = 3,                      -- For simple picker
  initial_mode = "insert",               -- Start in insert mode
  layout_strategy = "horizontal",         -- Layout style
}
```

**Session Preview:**
```
Session: uuid-format-string

Project: /path/to/project
Branch: main
Last Active: 2 hours ago
Created: 2025-09-30 14:30

Recent Activity:
- Implemented feature X
- Fixed bug in module Y
```

**Worktree Preview:**
```
Branch: feature/new-api

Type: feature
Description: Implement new API endpoints

Location: /path/to/worktree
Session: uuid-format-string
Created: 3 hours ago
```

**Keybindings:**
- `<CR>` - Resume selected session or switch to worktree
- `<C-d>` - Delete session or remove worktree
- `<C-r>` - Refresh picker
- `<Esc>` - Close picker

### native-sessions.lua
Native Claude Code session handling with time formatting and metadata extraction.

**Key Features:**
- Native session list parsing via Claude CLI
- Time ago formatting (e.g., "2 hours ago")
- Session metadata extraction
- Project and branch detection
- Recent session filtering

**Key Functions:**
- `get_sessions()` - Get all Claude CLI sessions
- `parse_session_list(output)` - Parse CLI output to session objects
- `format_time_ago(timestamp)` - Human-readable time formatting
- `get_recent_sessions(hours)` - Filter by recency
- `extract_metadata(session)` - Extract project/branch info
- `is_session_active(id)` - Check if session is currently active

**Session Object:**
```lua
{
  id = "uuid-format-string",
  title = "Project Name",
  timestamp = 1727712000,
  project = "/path/to/project",
  branch = "main",
  time_ago = "2 hours ago",
  is_active = false,
}
```

**Time Formatting:**
- Under 1 minute: "just now"
- Under 1 hour: "X minutes ago"
- Under 24 hours: "X hours ago"
- Under 7 days: "X days ago"
- Over 7 days: "X weeks ago"
- Over 4 weeks: Full date

**CLI Integration:**
```bash
# Get sessions via Claude CLI
claude --list-sessions

# Resume session
claude --resume <session-id>
```

## Integration Points

### With Core Modules
```
pickers.lua
├── core/session.lua (for session operations)
├── core/session-manager.lua (for validation)
├── core/worktree.lua (for worktree data)
└── native-sessions.lua (for session metadata)

native-sessions.lua
├── plenary.job (for CLI execution)
└── core/session.lua (for persistence)
```

### With Telescope
```
All pickers use:
├── telescope.pickers
├── telescope.finders
├── telescope.actions
├── telescope.previewers
└── telescope.config
```

## Usage Examples

### Session Pickers
```lua
local ui = require('neotex.plugins.ai.claude.ui.pickers')

-- Browse all sessions
ui.sessions_picker({
  show_preview = true
})

-- Simple picker (recent only)
ui.simple_sessions_picker({
  max_sessions = 3
})

-- Worktrees picker
ui.worktrees_picker()
```

### Native Session Functions
```lua
local native = require('neotex.plugins.ai.claude.ui.native-sessions')

-- Get all sessions
local sessions = native.get_sessions()

-- Get recent sessions (last 24 hours)
local recent = native.get_recent_sessions(24)

-- Format timestamp
local time_str = native.format_time_ago(os.time() - 3600)  -- "1 hour ago"

-- Check if session active
local active = native.is_session_active("uuid-here")
```

### Custom Picker
```lua
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local ui_pickers = require('neotex.plugins.ai.claude.ui.pickers')

pickers.new({}, {
  prompt_title = "My Custom Picker",
  finder = finders.new_table({
    results = sessions,
    entry_maker = function(session)
      return {
        value = session,
        display = session.title,
        ordinal = session.id,
      }
    end
  }),
  previewer = ui_pickers.create_session_previewer(),
}):find()
```

## Picker Configuration

### Global Config
```lua
require('neotex.plugins.ai.claude').setup({
  ui = {
    simple_picker_max = 3,           -- Max sessions in simple picker
    show_preview = true,             -- Show preview by default
    layout_strategy = "horizontal",   -- Picker layout
    preview_width = 0.5,             -- Preview window width
  }
})
```

### Per-Picker Config
```lua
-- Override global settings
ui.sessions_picker({
  max_sessions = 5,
  layout_strategy = "vertical",
  initial_mode = "normal",
})
```

## Preview Customization

### Session Preview Sections
1. **Header**: Session ID and title
2. **Metadata**: Project, branch, timestamps
3. **Activity**: Recent session activity (if available)
4. **Stats**: Session duration, message count (if tracked)

### Worktree Preview Sections
1. **Header**: Branch name and type
2. **Description**: Task description
3. **Location**: Worktree path
4. **Session**: Associated Claude session
5. **Timing**: Creation and last access time

## Error Handling

### CLI Errors
- **Claude not installed**: Shows error with installation instructions
- **Session not found**: Filters out invalid sessions
- **Parse errors**: Graceful fallback with partial data

### Picker Errors
- **No sessions**: Shows "No sessions found" message
- **Telescope not available**: Falls back to simple selection
- **Preview errors**: Shows preview unavailable message

### Session Errors
- **Invalid metadata**: Uses defaults and shows warning
- **Timestamp issues**: Falls back to "unknown" time
- **Missing fields**: Gracefully handles partial data

## Performance Considerations

### Caching
- Session list cached for 5 seconds
- Metadata extracted on demand
- Preview content generated lazily

### Lazy Loading
- Telescope loaded only when picker opened
- Native sessions module loaded on first use
- Preview content loaded per selection

### Optimization
- Async session retrieval via plenary.job
- Efficient time formatting without date libraries
- Minimal string allocations in tight loops

## Testing

### Session Picker
```vim
:lua require('neotex.plugins.ai.claude.ui.pickers').sessions_picker()
```

### Simple Picker
```vim
:lua require('neotex.plugins.ai.claude.ui.pickers').simple_sessions_picker({max_sessions = 5})
```

### Worktrees Picker
```vim
:lua require('neotex.plugins.ai.claude.ui.pickers').worktrees_picker()
```

### Time Formatting
```vim
:lua print(require('neotex.plugins.ai.claude.ui.native-sessions').format_time_ago(os.time() - 7200))
```

## Navigation
- [<- Parent Directory](../README.md)
- [Pickers Module](pickers.lua)
- [Native Sessions](native-sessions.lua)
