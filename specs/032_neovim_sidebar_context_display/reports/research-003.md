# Research Report: Task #32 (Third Follow-up)

**Task**: 32 - Improve Neovim sidebar panel to display Claude Code context usage
**Started**: 2026-02-03T14:30:00Z
**Completed**: 2026-02-03T15:15:00Z
**Focus**: Push-based architecture via Claude Code Stop hooks
**Effort**: 2-3 hours (implementation)
**Dependencies**: Claude Code hooks system, vim.uv (libuv), lualine.nvim
**Sources/Inputs**: Claude Code hooks documentation, Neovim libuv docs, lualine source
**Artifacts**: specs/032_neovim_sidebar_context_display/reports/research-003.md
**Standards**: report-format.md, artifact-formats.md

## Executive Summary

- **Stop hooks are the recommended push mechanism**: Claude Code's `Stop` hook fires when Claude finishes responding and receives the full JSON payload including `context_window` data with `used_percentage`, token counts, and model info
- **Statusline hooks also viable**: The `statusLine` configuration updates every 300ms during conversation changes and provides identical JSON data - could serve as an alternative or complement to Stop hooks
- **vim.uv.new_fs_event() enables efficient file watching**: Neovim's libuv bindings provide native filesystem event monitoring with minimal overhead, eliminating the need for timer-based polling
- **Recommended architecture**: Stop hook writes JSON to `/tmp/claude-context.json`, Neovim watches the file with `vim.uv.new_fs_event()`, lualine component reads and caches the data

## Context and Scope

This follow-up research investigates a PUSH-BASED approach where Claude Code actively writes context data via hooks, rather than Neovim polling for updates. Building on research-002.md's lualine integration findings, this report focuses on:

1. Claude Code hook mechanisms for pushing context data
2. Neovim's file watching capabilities via vim.uv
3. Integration architecture for minimal overhead

## Findings

### 1. Claude Code Stop Hooks

**Event Timing**: The `Stop` hook fires when Claude finishes responding. It does NOT fire on user interrupts.

**Hook Configuration** (in `~/.claude/settings.json`):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/context-push.sh"
          }
        ]
      }
    ]
  }
}
```

**Key Characteristics**:
- Fires once per Claude response (not per tool call)
- Receives JSON via stdin with full session context
- Cannot be filtered by matcher (always fires on every Stop)
- Has `stop_hook_active` field to detect continuation scenarios

**JSON Input Available to Stop Hooks**:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": false
}
```

**Limitation**: The Stop hook input does NOT include `context_window` or `model` data directly. These fields are only available in the **statusLine** hook.

### 2. Claude Code Statusline Configuration (Better Option)

**Key Discovery**: The `statusLine` configuration provides richer data than Stop hooks and updates more frequently.

**Configuration** (in `~/.claude/settings.json`):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/statusline-push.sh",
    "padding": 0
  }
}
```

**Update Frequency**: Every 300ms when conversation messages update (not continuously).

**Complete JSON Input**:

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

**Advantages over Stop hooks**:
1. Includes `context_window` data with `used_percentage`
2. Includes `model` information
3. Includes `cost` data
4. Updates during Claude's work, not just at completion
5. Simpler configuration (single field vs hooks array)

### 3. Shell Script for Context Push

**Recommended Script** (`~/.claude/hooks/statusline-push.sh`):

```bash
#!/bin/bash
# Read JSON from stdin, write to file for Neovim, output for Claude display
input=$(cat)

# Atomic write to temp file to prevent partial reads
TEMP_FILE="/tmp/claude-context.json.tmp"
TARGET_FILE="/tmp/claude-context.json"

echo "$input" > "$TEMP_FILE"
mv "$TEMP_FILE" "$TARGET_FILE"

# Output for Claude's own statusline display
MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
PERCENT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

printf "%s | %d%% | \$%.2f" "$MODEL" "$PERCENT" "$COST"
```

**Key Implementation Details**:
- **Atomic write**: Write to `.tmp` file then `mv` to prevent partial reads
- **Fixed location**: `/tmp/claude-context.json` is predictable
- **Dual output**: Writes file AND outputs text for Claude's display
- **No external dependencies**: Only uses jq (already required by Claude Code)

### 4. Neovim File Watching with vim.uv

**vim.uv.new_fs_event() Pattern** (from Neovim docs):

```lua
local uv = vim.uv
local w = uv.new_fs_event()

local function on_change(err, fname, status)
  if err then return end

  -- Schedule Neovim API calls (required for callbacks)
  vim.schedule(function()
    -- Invalidate cache and trigger lualine refresh
    require("neotex.util.claude-context").invalidate_cache()
    vim.cmd("redrawstatus")
  end)

  -- Debounce: stop and restart watcher
  w:stop()
  watch_file(fname)
end

local function watch_file(fname)
  local fullpath = vim.fn.expand(fname)
  w:start(fullpath, {}, vim.schedule_wrap(on_change))
end

-- Start watching
watch_file("/tmp/claude-context.json")
```

**Critical Requirements**:
1. **vim.schedule_wrap()**: All Neovim API calls in libuv callbacks MUST be wrapped
2. **Debounce pattern**: Stop and restart watcher after each event (Linux inotify quirk)
3. **Error handling**: Check for err before processing

**Alternative: FocusGained + checktime**:

```lua
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    require("neotex.util.claude-context").invalidate_cache()
    vim.cmd("redrawstatus")
  end,
})
```

This is simpler but only updates when Neovim regains focus, not in real-time.

### 5. Lualine Component with File-Based Cache

**Complete Implementation** (`lua/neotex/util/claude-context.lua`):

```lua
local M = {}

local cache = {
  data = nil,
  valid = false,
}

local STATUS_FILE = "/tmp/claude-context.json"

-- Called by file watcher or FocusGained
function M.invalidate_cache()
  cache.valid = false
end

-- Called by lualine component
function M.get_context()
  -- Return cached data if valid
  if cache.valid and cache.data then
    return cache.data
  end

  -- Check if file exists
  local stat = vim.uv.fs_stat(STATUS_FILE)
  if not stat then
    cache.data = nil
    cache.valid = true
    return nil
  end

  -- Read and parse file
  local file = io.open(STATUS_FILE, "r")
  if not file then
    cache.data = nil
    cache.valid = true
    return nil
  end

  local content = file:read("*a")
  file:close()

  local ok, data = pcall(vim.json.decode, content)
  if ok and data and data.context_window then
    cache.data = {
      used_percentage = data.context_window.used_percentage or 0,
      context_window_size = data.context_window.context_window_size or 200000,
      current_tokens = data.context_window.current_usage and
        (data.context_window.current_usage.input_tokens or 0) or 0,
      model = data.model and data.model.display_name or "Claude",
      cost = data.cost and data.cost.total_cost_usd or 0,
    }
  else
    cache.data = nil
  end

  cache.valid = true
  return cache.data
end

-- Setup file watcher
function M.setup()
  local w = vim.uv.new_fs_event()
  if not w then return end

  local function on_change(err, fname, status)
    if err then return end
    vim.schedule(function()
      M.invalidate_cache()
      vim.cmd("redrawstatus")
    end)
    w:stop()
    M._start_watch(w)
  end

  M._start_watch = function(watcher)
    -- Only watch if file exists (will be created by Claude Code)
    local stat = vim.uv.fs_stat(STATUS_FILE)
    if stat then
      watcher:start(STATUS_FILE, {}, vim.schedule_wrap(on_change))
    else
      -- Retry in 5 seconds if file doesn't exist yet
      vim.defer_fn(function() M._start_watch(watcher) end, 5000)
    end
  end

  M._start_watch(w)
end

return M
```

### 6. Architecture Comparison

| Approach | Update Trigger | Overhead | Complexity | Recommended |
|----------|----------------|----------|------------|-------------|
| **Statusline hook + fs_event** | On Claude activity | Minimal | Medium | **Yes** |
| Stop hook + fs_event | On response complete | Low | Medium | Viable |
| Timer-based polling | Every N ms | Higher | Low | No |
| FocusGained only | On window focus | None | Very Low | Fallback |

**Recommended Architecture**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Claude Code CLI                              │
│                                                                      │
│  [Conversation activity]                                             │
│         │                                                            │
│         ▼ (every 300ms when active)                                  │
│  ┌─────────────────────┐                                             │
│  │ statusLine hook     │                                             │
│  │ statusline-push.sh  │                                             │
│  └─────────┬───────────┘                                             │
│            │                                                         │
│            ▼                                                         │
│  ┌─────────────────────┐      ┌─────────────────────┐               │
│  │ /tmp/claude-context │ ───▶ │ vim.uv.new_fs_event │               │
│  │ .json (atomic write)│      │ (Neovim watcher)    │               │
│  └─────────────────────┘      └─────────┬───────────┘               │
│                                         │                            │
│                                         ▼                            │
│                               ┌─────────────────────┐               │
│                               │ invalidate_cache()  │               │
│                               │ redrawstatus        │               │
│                               └─────────┬───────────┘               │
│                                         │                            │
│                                         ▼                            │
│                               ┌─────────────────────┐               │
│                               │ lualine component   │               │
│                               │ read cached data    │               │
│                               └─────────────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
```

### 7. Complete Implementation Files

**File 1: `~/.claude/settings.json`** (merge with existing):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/statusline-push.sh",
    "padding": 0
  }
}
```

**File 2: `~/.claude/hooks/statusline-push.sh`**:
(See Section 3 above)

**File 3: `lua/neotex/util/claude-context.lua`**:
(See Section 5 above)

**File 4: Lualine component** (in claudecode.lua autocmd or separate extension):

```lua
-- Add to lualine config for claude-code buffers
local function claude_context_component()
  local ctx = require("neotex.util.claude-context").get_context()
  if not ctx then return "" end

  local pct = math.floor(ctx.used_percentage)
  local bar = make_progress_bar(pct, 10)

  return string.format("%d%% [%s] %s | $%.2f",
    pct, bar, ctx.model, ctx.cost)
end

local function make_progress_bar(percentage, width)
  width = width or 10
  local filled = math.floor(percentage / 100 * width)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

-- Color function based on percentage
local function get_context_color()
  local ctx = require("neotex.util.claude-context").get_context()
  if not ctx then return { fg = "#98c379" } end

  local pct = ctx.used_percentage
  if pct < 50 then
    return { fg = "#98c379" }  -- Green
  elseif pct < 80 then
    return { fg = "#e5c07b" }  -- Yellow
  else
    return { fg = "#e06c75" }  -- Red
  end
end
```

**File 5: Setup call** (in claudecode.lua config):

```lua
-- In the config function after claude-code setup
vim.defer_fn(function()
  local ok, claude_context = pcall(require, "neotex.util.claude-context")
  if ok then
    claude_context.setup()
  end
end, 100)
```

## Recommendations

### Implementation Order

1. **Create statusline-push.sh** and make executable
2. **Update ~/.claude/settings.json** with statusLine configuration
3. **Create claude-context.lua** with file watcher and cache
4. **Update lualine** to include context component for Claude terminal buffers
5. **Test** by running Claude and checking lualine updates

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Hook type | statusLine (not Stop) | Provides context_window data, updates during activity |
| File location | /tmp/claude-context.json | Standard temp location, auto-cleaned |
| Watcher | vim.uv.new_fs_event | Native, low overhead, event-driven |
| Cache strategy | Invalidate on file change | Minimal reads, always current |
| Fallback | FocusGained autocommand | Works if fs_event unavailable |

### Color Thresholds

| Usage | Color | Hex Code | Meaning |
|-------|-------|----------|---------|
| < 50% | Green | `#98c379` | Healthy, plenty of room |
| 50-80% | Yellow | `#e5c07b` | Caution, consider compacting |
| > 80% | Red | `#e06c75` | Critical, context nearly full |

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| File not created initially | High on first run | Retry loop in setup(), graceful nil return |
| Partial file read | Low (atomic mv) | Atomic write pattern in shell script |
| fs_event not firing (platform) | Low on Linux | Add FocusGained fallback |
| Multiple Claude instances | Medium | Per-project status files (future enhancement) |
| JSON parse error | Low | pcall wrapper, return cached data |
| statusLine known bug (cumulative tokens) | Medium | Use `used_percentage` directly (pre-calculated) |

## Decisions

1. **Use statusLine over Stop hook** - Provides richer data including context_window
2. **Use vim.uv.new_fs_event() over polling** - Event-driven, minimal overhead
3. **Atomic file writes** - Write to .tmp, then mv for consistency
4. **Cache invalidation pattern** - Only read file when change detected
5. **Fixed file path** - /tmp/claude-context.json for simplicity
6. **Include FocusGained fallback** - Insurance if fs_event fails

## Appendix

### Search Queries Used
- "Claude Code stop hooks post-response hooks settings.json configuration 2026"
- "Claude Code CLI hooks notification after tool call response hook configuration"
- "Neovim vim.uv fs_event file watch libuv lua callback FocusGained checktime autoread"
- "Claude Code statusline hook context_window write file JSON /tmp status file push notification"

### References

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) - Complete hook event documentation
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) - Practical examples and use cases
- [Claude Code Statusline Configuration](https://code.claude.com/docs/en/statusline) - Statusline JSON structure
- [Get Notified When Claude Code Finishes](https://alexop.dev/posts/claude-code-notification-hooks/) - Community implementation
- [Neovim Lua Documentation](https://neovim.io/doc/user/lua.html) - vim.uv bindings
- [Neovim Luvref Documentation](https://neovim.io/doc/user/luvref.html) - libuv reference
- [Watch file for changes using vim.uv.new_fs_event()](https://github.com/neovim/neovim/discussions/26900) - Community discussion
- [Using libuv inside Neovim](https://teukka.tech/vimloop.html) - Tutorial

### Local Files Referenced

- `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/lualine.lua` - Current lualine config
- `/home/benjamin/.config/nvim/lua/neotex/util/claude-status.lua` - Existing status component pattern
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua` - Claude Code plugin config
- `/home/benjamin/.claude/settings.json` - Current Claude settings (minimal)
- `/home/benjamin/.config/nvim/specs/032_neovim_sidebar_context_display/reports/research-002.md` - Previous research
