# Research Report: Task #32

**Task**: 32 - Improve Neovim sidebar panel to display Claude Code context usage
**Started**: 2026-02-03T12:00:00Z
**Completed**: 2026-02-03T12:30:00Z
**Effort**: 2-4 hours (implementation)
**Dependencies**: claude-code.nvim plugin, jq (for status line parsing)
**Sources/Inputs**: Plugin docs, Claude Code CLI docs, local config analysis, community examples
**Artifacts**: specs/032_neovim_sidebar_context_display/reports/research-001.md
**Standards**: report-format.md

## Executive Summary

- Claude Code CLI provides comprehensive context usage data via JSON statusline API including `used_percentage`, `remaining_percentage`, and detailed token breakdowns
- The VS Code extension displays context indicator only at 50%+ usage; no native Neovim sidebar implementation exists
- Three feasible implementation approaches identified: (1) Custom sidebar panel with Lua, (2) Enhanced terminal titlebar/statusline, (3) Floating window overlay
- Existing local patterns (himalaya/sidebar.lua, claude-status.lua) provide reusable infrastructure for sidebar implementation

## Context and Scope

This research investigates how to add context usage display to Neovim's Claude Code integration, similar to the VS Code extension's prompt box footer. The scope includes:

1. Understanding Claude Code's context data API
2. Analyzing VS Code extension implementation
3. Evaluating Neovim sidebar patterns from existing plugins
4. Identifying feasible approaches for the local codebase

## Findings

### Claude Code Statusline JSON API

Claude Code CLI exposes rich context data via the statusline configuration. When configured, it passes JSON to a custom command via stdin every 300ms when conversation updates.

**Complete JSON Structure** ([source](https://code.claude.com/docs/en/statusline)):

```json
{
  "hook_event_name": "Status",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.json",
  "cwd": "/current/working/directory",
  "model": {
    "id": "claude-opus-4-1",
    "display_name": "Opus"
  },
  "workspace": {
    "current_dir": "/current/working/directory",
    "project_dir": "/original/project/directory"
  },
  "version": "1.0.80",
  "cost": {
    "total_cost_usd": 0.01234,
    "total_duration_ms": 45000,
    "total_api_duration_ms": 2300,
    "total_lines_added": 156,
    "total_lines_removed": 23
  },
  "context_window": {
    "total_input_tokens": 15234,
    "total_output_tokens": 4521,
    "context_window_size": 200000,
    "used_percentage": 42.5,
    "remaining_percentage": 57.5,
    "current_usage": {
      "input_tokens": 8500,
      "output_tokens": 1200,
      "cache_creation_input_tokens": 5000,
      "cache_read_input_tokens": 2000
    }
  }
}
```

**Key Fields for Context Display**:
- `context_window.used_percentage` - Pre-calculated percentage (0-100)
- `context_window.remaining_percentage` - Pre-calculated remaining
- `context_window.context_window_size` - Total context limit (200k for most models, 1M for Sonnet 4.5)
- `context_window.current_usage.*` - Detailed token breakdown

**Configuration** (in `~/.claude/settings.json`):
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

### VS Code Extension Context Display

The VS Code extension's graphical panel shows context percentage only at 50%+ usage ([Issue #21781](https://github.com/anthropics/claude-code/issues/21781)). There are active feature requests for:

- Always-visible context indicator ([Issue #16526](https://github.com/anthropics/claude-code/issues/16526))
- Configurable threshold
- Breakdown of what consumes context

Third-party VS Code extensions exist for enhanced monitoring:
- [Claude Token Monitor](https://marketplace.visualstudio.com/items?itemName=Wilendar.claude-usage-monitor) - Real-time dashboard
- [Claude Code Usage Tracker](https://marketplace.visualstudio.com/items?itemName=YahyaShareef.claude-code-usage-tracker) - Session tracking
- [Claude Code Status Bar Monitor](https://marketplace.visualstudio.com/items?itemName=bartosz-warzocha.claude-statusbar) - Status bar display

### Neovim Plugin Landscape

**Current Claude Code Neovim Plugins**:

1. **[greggh/claude-code.nvim](https://github.com/greggh/claude-code.nvim)** (currently used in local config)
   - Terminal-based integration
   - No context display feature
   - Provides toggle/window management

2. **[coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)**
   - WebSocket MCP server approach (same protocol as VS Code extension)
   - Real-time editor context
   - No token/context display documented

3. **Community statusline tools** ([ccstatusline](https://github.com/sirmalloc/ccstatusline), [ccusage](https://ccusage.com/guide/statusline))
   - Parse statusline JSON for display
   - Show context percentage with color-coded thresholds
   - Green < 50%, Yellow 50-80%, Red > 80%

**AI Sidebar Patterns in Other Plugins**:

1. **avante.nvim** ([sidebar.lua](https://github.com/yetone/avante.nvim/blob/main/lua/avante/sidebar.lua))
   - Token counting via `token_count` field
   - Displays in input hint area
   - Container-based layout (result, selected_code, input)

2. **codecompanion.nvim** ([docs](https://codecompanion.olimorris.dev/configuration/chat-buffer))
   - `show_token_count = true` option
   - Global metadata: `_G.codecompanion_chat_metadata[bufnr].tokens`
   - Lualine integration available

### Local Codebase Analysis

**Existing Infrastructure**:

1. **`lua/neotex/util/claude-status.lua`**
   - Session status display (worktree integration)
   - Lualine component patterns
   - Color-coded by session type

2. **`lua/neotex/plugins/tools/himalaya/ui/sidebar.lua`**
   - Complete sidebar implementation
   - Buffer/window management
   - Content update with metadata
   - Highlight application patterns

3. **`lua/neotex/plugins/ai/claude/core/session-manager.lua`**
   - Session validation and state management
   - Buffer detection patterns
   - Periodic synchronization (every 5s)

4. **`lua/neotex/plugins/ai/claudecode.lua`**
   - Plugin configuration
   - Terminal autocmds
   - Window settings (40% width vertical split)

### Implementation Approaches

#### Approach 1: Custom Sidebar Panel (Recommended)

Create a dedicated sidebar panel similar to himalaya/sidebar.lua that displays context usage.

**Architecture**:
```
┌─────────────────────────────────────────────────────────────┐
│ Claude Code Terminal (40% width)                            │
├─────────────────────────────────────────────────────────────┤
│ Context: 42.5% [████████░░░░░░░░░░░░] 85K/200K             │
│ Model: Opus | Cost: $0.31 | Session: abc123                 │
└─────────────────────────────────────────────────────────────┘
```

**Data Flow**:
1. Configure Claude CLI to output statusline JSON to a file or named pipe
2. Lua timer (300ms) reads and parses the JSON
3. Update sidebar buffer with formatted display
4. Apply color highlighting based on thresholds

**Implementation Steps**:
1. Create `lua/neotex/plugins/ai/claude/ui/context-panel.lua`
2. Configure statusline in `~/.claude/settings.json` to write to known path
3. Create parser for statusline JSON
4. Add virtual text or dedicated buffer line for display
5. Integrate with existing terminal toggle workflow

**Pros**:
- Rich display with full context data
- Independent of terminal content
- Consistent with local codebase patterns

**Cons**:
- Requires external statusline configuration
- File-based IPC adds complexity

#### Approach 2: Terminal Titlebar Enhancement

Modify the terminal window title or add virtual text at the top of the Claude terminal buffer.

**Architecture**:
```lua
-- In terminal autocmd
vim.api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
  virt_lines = {{{"Context: 42.5%", "DiagnosticInfo"}}},
  virt_lines_above = true,
})
```

**Data Flow**:
1. Parse Claude CLI statusline output from terminal buffer content
2. Extract context percentage from terminal text patterns
3. Display as virtual text above terminal

**Pros**:
- No external configuration needed
- Integrated with existing terminal

**Cons**:
- Parsing terminal output is fragile
- Limited display space

#### Approach 3: Statusline Component Integration

Add context display to lualine or existing statusline.

**Architecture**:
```lua
-- lualine component
{
  function()
    local data = read_claude_status()
    if data then
      return string.format(" %d%%", data.context_window.used_percentage)
    end
    return ""
  end,
  cond = function() return claude_is_active() end,
}
```

**Pros**:
- Minimal visual footprint
- Uses existing statusline infrastructure

**Cons**:
- Limited display detail
- Only visible in statusline area

### Technical Considerations

#### Data Acquisition Methods

1. **File-based polling** (Recommended)
   - Statusline command writes to `~/.claude/status.json`
   - Lua timer reads file every 300-500ms
   - Simple, reliable, cross-platform

2. **Named pipe (FIFO)**
   - More responsive than file polling
   - Requires platform-specific handling

3. **Terminal output parsing**
   - Parse `used_percentage` from terminal content
   - Fragile, depends on statusline format

4. **WebSocket integration** (via coder/claudecode.nvim)
   - Direct MCP protocol access
   - Would require plugin switch or major refactoring

#### Color-Coded Thresholds

Standard community convention:
- **Green** (< 50%): Safe zone, plenty of context remaining
- **Yellow** (50-80%): Warning zone, consider compacting
- **Red** (> 80%): Danger zone, context nearly full

### Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Statusline JSON format changes | Low | Version check, graceful degradation |
| File polling performance impact | Low | Use vim.loop timers, 300ms interval |
| Terminal buffer complexity | Medium | Separate display from terminal buffer |
| Multiple instance conflicts | Low | Per-instance status files |

### Recommendations

1. **Primary Implementation**: Custom sidebar panel approach
   - Create `lua/neotex/plugins/ai/claude/ui/context-panel.lua`
   - Reuse patterns from himalaya sidebar
   - File-based status polling

2. **Configuration Requirements**:
   - Add statusline configuration to Claude settings
   - Create status writer script at `~/.claude/statusline.sh`

3. **Display Features**:
   - Context percentage with progress bar
   - Color-coded thresholds
   - Model name and session info
   - Cost tracking (optional)

4. **Integration Points**:
   - Hook into existing Claude terminal toggle
   - Add to lualine as optional component
   - Support multiple display modes (panel, statusline, floating)

## Decisions

1. **Use file-based polling** over WebSocket - simpler implementation, no plugin switch required
2. **Implement as sidebar panel** - consistent with existing codebase patterns
3. **Follow community threshold standards** - Green/Yellow/Red at 50%/80%
4. **Make display modular** - Support sidebar, statusline, and floating window options

## Appendix

### Search Queries Used
- "claude-code.nvim plugin github neovim sidebar terminal integration"
- "Claude Code VS Code extension context usage display prompt box footer token usage"
- "Claude Code CLI statusline JSON output context percentage terminal status format"
- "Claude Code --output-format status-json API context token usage programmatic"
- "avante.nvim sidebar panel token usage display neovim lua"
- "codecompanion.nvim chat buffer status token count display neovim"

### References
- [Claude Code Statusline Documentation](https://code.claude.com/docs/en/statusline)
- [Context Window Progress Bar Gist](https://gist.github.com/davidamo9/764415aff29959de21f044dbbfd00cd9)
- [Feature Request: Real-time context display (Issue #16526)](https://github.com/anthropics/claude-code/issues/16526)
- [Option to always show context (Issue #21781)](https://github.com/anthropics/claude-code/issues/21781)
- [greggh/claude-code.nvim](https://github.com/greggh/claude-code.nvim)
- [coder/claudecode.nvim](https://github.com/coder/claudecode.nvim)
- [yetone/avante.nvim](https://github.com/yetone/avante.nvim)
- [olimorris/codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim)
- [sirmalloc/ccstatusline](https://github.com/sirmalloc/ccstatusline)
