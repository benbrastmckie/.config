# Research Report: Task #32 (Follow-up)

**Task**: 32 - Improve Neovim sidebar panel to display Claude Code context usage
**Started**: 2026-02-03T12:00:00Z
**Completed**: 2026-02-03T12:45:00Z
**Focus**: Lualine customization for Claude Code sidebar terminal buffer
**Effort**: 2-3 hours (implementation)
**Dependencies**: lualine.nvim, greggh/claude-code.nvim, jq (for statusline parsing)
**Sources/Inputs**: Lualine source code, Claude Code docs, local config analysis
**Artifacts**: specs/032_neovim_sidebar_context_display/reports/research-002.md
**Standards**: report-format.md, artifact-formats.md

## Executive Summary

- Lualine extensions are simple Lua tables with `sections` and `filetypes` fields - no filetype is set by claude-code.nvim, so extensions must use `buftype = "terminal"` combined with buffer name pattern matching
- Claude Code terminal buffers are named `claude-code` or `claude-code-{git-root-sanitized}` with `buftype = "terminal"`, detectable via `vim.api.nvim_buf_get_name(buf):match("^claude%-code")`
- Custom lualine components can be functions returning strings; context data must be obtained by configuring Claude Code's statusline to write JSON to a known file path
- Implementation requires: (1) Claude settings.json statusline config, (2) Lua timer polling status file, (3) Custom lualine extension for claude-code buffers

## Context and Scope

This follow-up research investigates SPECIFICALLY how to customize lualine for Claude Code terminal buffers to display context usage. The previous research (research-001.md) covered the general approach; this report provides implementation-ready technical details for lualine integration.

## Findings

### 1. Lualine Extensions Architecture

**Extension Structure** (from lualine source code):

```lua
-- Minimal extension structure
local M = {}

M.sections = {
  lualine_a = { component1, component2 },
  lualine_b = {},
  lualine_c = {},
  lualine_x = {},
  lualine_y = {},
  lualine_z = {},
}

M.filetypes = { 'filetype1', 'filetype2' }

return M
```

**How Extensions Work**:
1. When lualine renders, it checks if current buffer's filetype matches any loaded extension
2. If match found, extension's `sections` replace default sections
3. Extensions are loaded via `setup({ extensions = { my_extension } })`

**Built-in Examples** (from `~/.local/share/nvim/lazy/lualine.nvim/lua/lualine/extensions/`):

```lua
-- toggleterm.lua - Terminal-specific extension
local function toggleterm_statusline()
  return 'ToggleTerm #' .. vim.b.toggle_number
end

local M = {}
M.sections = { lualine_a = { toggleterm_statusline } }
M.filetypes = { 'toggleterm' }
return M
```

**Key Insight**: Extensions match on `filetype`, but claude-code.nvim does NOT set a custom filetype. Terminal buffers have `buftype = "terminal"` but filetype is empty or "terminal".

### 2. Detecting Claude Code Terminal Buffers

**Buffer Identification** (from `~/.local/share/nvim/lazy/claude-code.nvim/lua/claude-code/terminal.lua`):

```lua
-- Buffer name generation (lines 171-177)
local function generate_buffer_name(instance_id, config)
  if config.git.multi_instance then
    return 'claude-code-' .. instance_id:gsub('[^%w%-_]', '-')
  else
    return 'claude-code'
  end
end
```

**Buffer Names**:
- Single instance mode: `claude-code`
- Multi-instance mode: `claude-code-{sanitized-git-root}` (e.g., `claude-code--home-benjamin--config-nvim`)

**Detection Patterns**:

```lua
-- Pattern 1: Buffer name prefix match
local function is_claude_code_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name:match("^claude%-code") ~= nil
end

-- Pattern 2: Combined buftype + name check (more robust)
local function is_claude_code_terminal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "terminal" then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name:match("claude%-code") ~= nil
end
```

**Alternative: Using existing local code** (from `lua/neotex/plugins/ai/claude/claude-session/terminal.lua`):

```lua
-- Local pattern already in codebase (lines 5-15)
function M.claude_buffer_exists()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("claude") then
        return true, buf
      end
    end
  end
  return false
end
```

### 3. Lualine Extension for Claude Code (Without Filetype)

Since claude-code.nvim doesn't set a filetype, a standard extension won't work. Two approaches:

**Approach A: Set filetype in autocmd**

Add to claudecode.lua configuration:

```lua
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*claude*",
  callback = function()
    vim.bo.filetype = "claude-code"  -- Set custom filetype
    -- ... existing configuration
  end,
})
```

Then create extension:

```lua
-- lua/neotex/plugins/ui/lualine/extensions/claude-code.lua
local M = {}

M.sections = {
  lualine_a = { "mode" },
  lualine_c = { claude_context_component },  -- Custom component
  lualine_z = { "location" },
}

M.filetypes = { "claude-code" }

return M
```

**Approach B: Conditional component in main sections**

Add context display as conditional component in main lualine config:

```lua
sections = {
  lualine_c = {
    {
      function()
        local context = get_claude_context()
        if context then
          return string.format("Context: %d%% [%s]",
            context.used_percentage,
            make_progress_bar(context.used_percentage, 10))
        end
        return ""
      end,
      cond = function()
        local name = vim.api.nvim_buf_get_name(0)
        return vim.bo.buftype == "terminal" and name:match("claude%-code")
      end,
    },
  },
}
```

### 4. Creating Custom Lualine Components

**Function-Based Components**:

```lua
-- Simple function component
local function my_component()
  return "some text"
end

-- Component with options
{
  function() return "text" end,
  cond = function() return true end,  -- Condition to show
  color = { fg = "#ff0000", gui = "bold" },  -- Styling
  on_click = function() vim.cmd("SomeCommand") end,  -- Click handler
}
```

**Progress Bar Implementation**:

```lua
local function make_progress_bar(percentage, width)
  width = width or 10
  local filled = math.floor(percentage / 100 * width)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

-- With color thresholds
local function get_context_color(percentage)
  if percentage < 50 then
    return { fg = "#98c379" }  -- Green
  elseif percentage < 80 then
    return { fg = "#e5c07b" }  -- Yellow
  else
    return { fg = "#e06c75" }  -- Red
  end
end
```

**Complete Context Component**:

```lua
local function claude_context_component()
  local context = get_claude_context()
  if not context then return "" end

  local pct = context.used_percentage or 0
  local bar = make_progress_bar(pct, 10)
  local tokens = context.current_usage
    and (context.current_usage.input_tokens or 0)
    or 0
  local size = context.context_window_size or 200000

  return string.format("%d%% [%s] %dk/%dk",
    pct, bar,
    math.floor(tokens / 1000),
    math.floor(size / 1000))
end
```

### 5. Fetching Context Data from Claude Code

**Claude Code Statusline Configuration** (from official docs):

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0
  }
}
```

**Statusline Script to Write JSON File** (`~/.claude/statusline.sh`):

```bash
#!/bin/bash
# Read JSON from stdin, write to file for Neovim to read
input=$(cat)
echo "$input" > ~/.claude/status.json
# Also output something for Claude's own display
echo "$(echo "$input" | jq -r '.model.display_name') | $(echo "$input" | jq -r '.context_window.used_percentage // 0')%"
```

**JSON Structure** (from Claude Code docs):

```json
{
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

**Lua Reader with Caching**:

```lua
-- lua/neotex/util/claude-context.lua
local M = {}

local cache = {
  data = nil,
  mtime = 0,
  last_check = 0,
}

local STATUS_FILE = vim.fn.expand("~/.claude/status.json")
local CACHE_TTL = 500  -- ms

function M.get_context()
  local now = vim.loop.hrtime() / 1e6  -- ms

  -- Check cache TTL
  if cache.data and (now - cache.last_check) < CACHE_TTL then
    return cache.data
  end

  -- Check file modification time
  local stat = vim.loop.fs_stat(STATUS_FILE)
  if not stat then return cache.data end

  if stat.mtime.sec == cache.mtime then
    cache.last_check = now
    return cache.data
  end

  -- Read and parse file
  local file = io.open(STATUS_FILE, "r")
  if not file then return nil end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if ok and data and data.context_window then
    cache.data = data.context_window
    cache.mtime = stat.mtime.sec
    cache.last_check = now
  end

  return cache.data
end

return M
```

### 6. Current Lualine Configuration Analysis

From `lua/neotex/plugins/ui/lualine.lua`:

```lua
-- Current config disables lualine for terminal buffers (line 42-44)
disabled_buftypes = {
  statusline = { "terminal", "nofile" },
  winbar = { "terminal", "nofile" },
},
```

**Problem**: This completely disables lualine for ALL terminal buffers including Claude Code.

**Solution**: Remove "terminal" from `disabled_buftypes` and use extension to customize Claude Code specifically:

```lua
disabled_buftypes = {
  statusline = { "nofile" },  -- Remove "terminal"
  winbar = { "nofile" },
},
```

Then add claude-code extension to show context for that specific terminal.

### 7. Complete Implementation Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Claude Code Terminal Window                     │
│                                                                  │
│  [TERMINAL content...]                                          │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ TERMINAL | 42% [████░░░░░░] 85k/200k | Opus | $0.31 | 1234:1    │
└─────────────────────────────────────────────────────────────────┘
     │             │                      │        │
     │             └─ Context component   │        └─ location
     │                                    └─ Model + cost
     └─ Mode (lualine_a)
```

**File Structure**:

```
lua/neotex/
├── util/
│   └── claude-context.lua          # Context data reader (new)
└── plugins/ui/
    ├── lualine.lua                 # Main config (modify)
    └── lualine/
        └── extensions/
            └── claude-code.lua     # Custom extension (new)
```

## Recommendations

### Implementation Steps

1. **Create statusline script** (`~/.claude/statusline.sh`)
   - Write JSON to `~/.claude/status.json`
   - Output simple text for Claude's own display

2. **Configure Claude settings** (`~/.claude/settings.json`)
   - Add statusLine configuration pointing to script

3. **Create context reader** (`lua/neotex/util/claude-context.lua`)
   - File-based polling with mtime caching
   - Return parsed context_window data

4. **Set filetype for Claude buffers** (in `claudecode.lua`)
   - Add `vim.bo.filetype = "claude-code"` in TermOpen autocmd

5. **Create lualine extension** (`lua/neotex/plugins/ui/lualine/extensions/claude-code.lua`)
   - Custom sections with context component
   - Progress bar with color thresholds

6. **Update lualine config** (`lua/neotex/plugins/ui/lualine.lua`)
   - Remove "terminal" from disabled_buftypes
   - Add claude-code extension to extensions list

### Component Specifications

| Section | Content | Example |
|---------|---------|---------|
| lualine_a | Mode | `TERMINAL` |
| lualine_b | (empty or branch) | `master` |
| lualine_c | Context percentage + bar | `42% [████░░░░░░] 85k/200k` |
| lualine_x | Model + Cost | `Opus | $0.31` |
| lualine_y | (empty) | |
| lualine_z | Location | `1234:1` |

### Color Thresholds

| Usage | Color | Hex Code |
|-------|-------|----------|
| < 50% | Green | `#98c379` |
| 50-80% | Yellow | `#e5c07b` |
| > 80% | Red | `#e06c75` |

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Status file not created (Claude not running) | Medium | Graceful fallback to empty display |
| JSON parse errors | Low | pcall wrapper, return cached data |
| Lualine refresh performance | Low | Use mtime-based caching, 500ms TTL |
| Filetype change breaks other plugins | Low | Use unique filetype "claude-code" |
| Multi-instance status file conflicts | Medium | Consider per-instance status files |

## Decisions

1. **Use filetype-based extension** over conditional components - cleaner separation, follows lualine patterns
2. **Set filetype in TermOpen autocmd** - minimal change to existing code
3. **Use file-based status passing** - simple, reliable, no plugin dependencies
4. **mtime-based cache** - efficient file access, responsive updates
5. **Progress bar style**: Block characters (`█░`) - widely supported in terminals

## Appendix

### Search Queries Used
- "lualine.nvim extensions terminal buffer custom statusline 2025"
- "lualine nvim extension custom filetype terminal buftype condition"
- "Claude Code CLI statusline JSON file output context window percentage"
- "neovim terminal buffer detect bufname job_id pattern matching lua"
- "lualine nvim progress bar component percentage bar custom visual"
- "greggh/claude-code.nvim filetype buffer terminal statusline"

### References

- [Lualine.nvim GitHub](https://github.com/nvim-lualine/lualine.nvim)
- [Lualine Built-in Extensions (DeepWiki)](https://deepwiki.com/nvim-lualine/lualine.nvim/7.1-built-in-extensions)
- [Claude Code Statusline Documentation](https://code.claude.com/docs/en/statusline)
- [ccstatusline (GitHub)](https://github.com/sirmalloc/ccstatusline)
- [greggh/claude-code.nvim](https://github.com/greggh/claude-code.nvim)
- [Neovim Lua Guide](https://neovim.io/doc/user/lua-guide.html)
- [Neovim API Documentation](https://neovim.io/doc/user/api.html)

### Local Files Referenced

- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/lualine.lua` - Current lualine config
- `/home/benjamin/.config/nvim/lua/neotex/util/claude-status.lua` - Existing status component pattern
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua` - Claude Code plugin config
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/claude-session/terminal.lua` - Terminal utilities
- `/home/benjamin/.local/share/nvim/lazy/claude-code.nvim/lua/claude-code/terminal.lua` - Plugin source
- `/home/benjamin/.local/share/nvim/lazy/lualine.nvim/lua/lualine/extensions/toggleterm.lua` - Extension example
