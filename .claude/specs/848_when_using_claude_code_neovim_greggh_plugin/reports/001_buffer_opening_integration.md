# Neovim Buffer Opening Integration for Claude Code Workflows

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Automatic buffer opening after workflow command completion
- **Report Type**: Integration design and implementation plan
- **Complexity**: 3

## Executive Summary

This report analyzes the integration between the `greggh/claude-code.nvim` plugin and the `.claude/` workflow commands (`/research`, `/plan`, `/build`, etc.) to automatically open generated artifacts (reports, plans, summaries) in Neovim buffers upon completion.

**Key Findings**:
1. The existing Neovim configuration has extensive Claude Code integration (~9,626 lines)
2. Command completion signals (e.g., `REPORT_CREATED: /path/to/file.md`) provide clear hooks for automation
3. Multiple viable approaches exist: file watchers, autocmd patterns, and post-command hooks
4. The `greggh/claude-code.nvim` plugin handles terminal management but doesn't provide workflow completion hooks

**Recommended Approach**: Implement a file watcher using Neovim's native `vim.uv.new_fs_event()` API that monitors the specs directory and automatically opens newly created artifacts based on their type and recency.

---

## Current Architecture Analysis

### 1. Neovim Claude Code Integration

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/`

The existing integration is comprehensive:
- **External Plugin**: `claudecode.lua` configures `greggh/claude-code.nvim` (110 lines)
- **Internal System**: `claude/` directory with 9,626 lines across 20 files
- **Key Components**:
  - Session management with UUID validation
  - Git worktree integration (2,275 lines)
  - Command picker system (1,114 lines)
  - Visual selection handling
  - Terminal state management

**Existing Buffer Opening Patterns**:
```lua
-- From claude/core/worktree.lua (line 313, 385, 510)
vim.cmd("edit " .. context_file)
vim.cmd("edit " .. vim.fn.fnameescape(context_file))

-- From claude/commands/picker.lua (line 1307-1318)
local function edit_artifact_file(filepath)
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    -- Error notification
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end
```

**Key Pattern**: The codebase already uses `vim.cmd("edit " .. vim.fn.fnameescape(filepath))` to open files safely.

### 2. Claude Workflow Commands

**Location**: `/home/benjamin/.config/.claude/commands/`

Analyzed commands:
- `/research` - Creates reports in `specs/{NNN_topic}/reports/`
- `/plan` - Creates plans in `specs/{NNN_topic}/plans/`
- `/build` - Creates summaries in `specs/{NNN_topic}/summaries/`
- `/debug` - Creates debug reports in `specs/{NNN_topic}/debug/`
- `/repair` - Creates error analysis and repair plans
- `/errors` - Queries error logs

**Completion Signal Protocol**:
All agents return standardized completion signals:
```bash
REPORT_CREATED: /absolute/path/to/report.md
PLAN_CREATED: /absolute/path/to/plan.md
SUMMARY_CREATED: /absolute/path/to/summary.md
DEBUG_REPORT_CREATED: /absolute/path/to/debug.md
```

**Example from research-specialist agent**:
```bash
# Step 5: Final verification and return
echo "REPORT_CREATED: $REPORT_PATH"
```

### 3. Directory Protocols

**Location**: `/home/benjamin/.config/.claude/docs/concepts/directory-protocols.md`

Topic-based structure:
```
specs/
└── {NNN_topic}/
    ├── plans/          # Implementation plans (gitignored)
    ├── reports/        # Research reports (gitignored)
    ├── summaries/      # Implementation summaries (gitignored)
    ├── debug/          # Debug reports (COMMITTED)
    └── ...
```

**Key Characteristics**:
- Sequential topic numbering (NNN format: 000-999)
- Atomic topic allocation prevents race conditions
- Each artifact type has its own subdirectory
- Main artifacts are markdown files with timestamped names

---

## Integration Approaches

### Approach 1: File System Watcher (RECOMMENDED)

**Mechanism**: Use Neovim's native `vim.uv.new_fs_event()` to watch the specs directory and automatically open new artifacts.

**Advantages**:
- Works regardless of command source (terminal, external script, etc.)
- Native Neovim API - no external dependencies
- Event-driven, minimal performance impact
- Can distinguish between artifact types
- Handles concurrent command execution

**Implementation Location**:
- New module: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/artifact-watcher.lua`
- Integration point: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua`

**Technical Design**:
```lua
-- artifact-watcher.lua
local M = {}

local watchers = {}
local recent_artifacts = {}

-- Configuration
local config = {
  watch_dirs = {
    reports = true,
    plans = true,
    summaries = true,
    debug = false,  -- Debug artifacts usually not opened automatically
  },
  debounce_ms = 500,  -- Prevent multiple opens for same file
  auto_open = true,
}

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})

  -- Find specs directory
  local specs_dir = M.find_specs_directory()
  if not specs_dir then
    return
  end

  M.start_watching(specs_dir)
end

function M.find_specs_directory()
  -- Detect project root (git or .claude directory)
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error == 0 then
    git_root = vim.fn.trim(git_root)
    local specs_path = git_root .. "/.claude/specs"
    if vim.fn.isdirectory(specs_path) == 1 then
      return specs_path
    end
  end

  -- Fallback: search upwards for .claude directory
  local current = vim.fn.getcwd()
  while current ~= "/" do
    local specs_path = current .. "/.claude/specs"
    if vim.fn.isdirectory(specs_path) == 1 then
      return specs_path
    end
    current = vim.fn.fnamemodify(current, ":h")
  end

  return nil
end

function M.start_watching(specs_dir)
  -- Watch for new topic directories
  local w = vim.uv.new_fs_event()

  local function on_change(err, filename, events)
    if err then
      vim.notify("Artifact watcher error: " .. err, vim.log.levels.WARN)
      return
    end

    -- Check if it's a new directory
    if events.rename and filename then
      local topic_path = specs_dir .. "/" .. filename
      if vim.fn.isdirectory(topic_path) == 1 then
        -- Start watching artifact subdirectories
        M.watch_topic_directory(topic_path)
      end
    end
  end

  -- Use vim.schedule_wrap to safely call vim.api functions
  w:start(specs_dir, {}, vim.schedule_wrap(function(...)
    on_change(...)
  end))

  table.insert(watchers, w)

  -- Watch existing topic directories
  local topics = vim.fn.glob(specs_dir .. "/*", false, true)
  for _, topic_path in ipairs(topics) do
    if vim.fn.isdirectory(topic_path) == 1 then
      M.watch_topic_directory(topic_path)
    end
  end
end

function M.watch_topic_directory(topic_path)
  -- Watch each artifact type subdirectory
  for artifact_type, should_watch in pairs(config.watch_dirs) do
    if should_watch then
      local artifact_dir = topic_path .. "/" .. artifact_type
      if vim.fn.isdirectory(artifact_dir) == 1 then
        M.watch_artifact_directory(artifact_dir, artifact_type)
      end
    end
  end
end

function M.watch_artifact_directory(artifact_dir, artifact_type)
  local w = vim.uv.new_fs_event()

  local function on_artifact_change(err, filename, events)
    if err then return end

    -- Only process markdown files
    if not filename or not filename:match("%.md$") then
      return
    end

    local filepath = artifact_dir .. "/" .. filename

    -- Check if file was created (not just modified)
    if events.rename or events.change then
      -- Debounce: check if we've recently seen this file
      local now = vim.uv.now()
      if recent_artifacts[filepath] and (now - recent_artifacts[filepath]) < config.debounce_ms then
        return
      end
      recent_artifacts[filepath] = now

      -- Verify file exists and is readable
      if vim.fn.filereadable(filepath) ~= 1 then
        return
      end

      -- Open the file
      if config.auto_open then
        M.open_artifact(filepath, artifact_type)
      end
    end
  end

  w:start(artifact_dir, {}, vim.schedule_wrap(function(...)
    on_artifact_change(...)
  end))

  table.insert(watchers, w)
end

function M.open_artifact(filepath, artifact_type)
  -- Defer to next tick to ensure we're in main loop
  vim.schedule(function()
    -- Check if we're in Claude Code terminal
    local current_buf = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_buf_get_option(current_buf, 'buftype')

    if buftype == 'terminal' then
      -- Open in new split
      vim.cmd("vsplit " .. vim.fn.fnameescape(filepath))
    else
      -- Open in current window
      vim.cmd("edit " .. vim.fn.fnameescape(filepath))
    end

    -- Optional: Show notification
    local notify = require('neotex.util.notifications')
    notify.editor(
      "Opened " .. artifact_type .. ": " .. vim.fn.fnamemodify(filepath, ":t"),
      notify.categories.INFO,
      { filepath = filepath, artifact_type = artifact_type }
    )
  end)
end

function M.stop_watching()
  for _, w in ipairs(watchers) do
    w:stop()
  end
  watchers = {}
end

return M
```

**Integration**:
```lua
-- In nvim/lua/neotex/plugins/ai/claude/init.lua
local artifact_watcher = require("neotex.plugins.ai.claude.util.artifact-watcher")

function M.setup(config)
  -- ... existing setup ...

  -- Start artifact watcher
  if config.watch_artifacts ~= false then
    artifact_watcher.setup({
      auto_open = config.auto_open_artifacts,
      watch_dirs = config.watch_artifact_types or {
        reports = true,
        plans = true,
        summaries = true,
        debug = false,
      },
    })
  end
end
```

**Configuration in claudecode.lua**:
```lua
-- nvim/lua/neotex/plugins/ai/claudecode.lua
config = function(_, opts)
  require("claude-code").setup(opts)

  vim.defer_fn(function()
    local session_manager = require("neotex.plugins.ai.claude.core.session-manager")
    session_manager.setup()

    local ok, claude_module = pcall(require, "neotex.plugins.ai.claude")
    if ok and claude_module and claude_module.setup then
      claude_module.setup({
        -- Enable artifact watching
        watch_artifacts = true,
        auto_open_artifacts = true,
        watch_artifact_types = {
          reports = true,
          plans = true,
          summaries = true,
          debug = false,  -- Don't auto-open debug reports
        },
      })
    end
  end, 100)
end
```

---

### Approach 2: BufWritePost Autocmd Pattern

**Mechanism**: Use Neovim's autocmd system to detect when markdown files are written to specs directories.

**Advantages**:
- Simple implementation
- Low overhead
- Built into Neovim

**Disadvantages**:
- Only triggers when files are written, not created externally
- Requires pattern matching on every buffer write
- Won't catch files created by external processes

**Implementation**:
```lua
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*/.claude/specs/*/reports/*.md,*/.claude/specs/*/plans/*.md,*/.claude/specs/*/summaries/*.md",
  callback = function(args)
    -- Open the newly written file
    local filepath = args.file

    -- Check if it's a new file (file size is recent)
    local stat = vim.loop.fs_stat(filepath)
    if stat and (os.time() - stat.mtime.sec) < 5 then
      -- Recently created, auto-open
      vim.schedule(function()
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
      end)
    end
  end,
  group = vim.api.nvim_create_augroup("ClaudeArtifactAutoOpen", { clear = true }),
})
```

**Assessment**: This approach is simpler but less robust than the file watcher approach, as it only works for files created within Neovim, not by external bash commands.

---

### Approach 3: Post-Command Hook Integration

**Mechanism**: Add post-execution hooks to the workflow commands that send notifications to Neovim.

**Advantages**:
- Precise control over when to open files
- Can include metadata about the command
- No polling or watching required

**Disadvantages**:
- Requires modifying all workflow commands
- Tight coupling between bash and Neovim
- Complex IPC mechanism needed (sockets, RPC, or temp files)

**Implementation Sketch**:
```bash
# In .claude/commands/research.md (Block 2, after research complete)

# Notify Neovim to open the report
if command -v nvim >/dev/null 2>&1 && [ -n "$NVIM" ]; then
  # Running inside Neovim terminal
  nvim --server "$NVIM" --remote-send "<Cmd>call OpenClaudeArtifact('$REPORT_PATH', 'report')<CR>"
fi
```

**Neovim side**:
```lua
function _G.OpenClaudeArtifact(filepath, artifact_type)
  if vim.fn.filereadable(filepath) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  end
end
```

**Assessment**: This approach is invasive and requires changes to multiple commands. The file watcher approach is cleaner.

---

## Recommended Implementation Plan

### Phase 1: Core Artifact Watcher Module

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/artifact-watcher.lua`

1. Implement `find_specs_directory()` - Locate .claude/specs directory
2. Implement `start_watching()` - Initialize top-level specs directory watcher
3. Implement `watch_topic_directory()` - Watch individual topic directories
4. Implement `watch_artifact_directory()` - Watch artifact subdirectories (reports/, plans/, etc.)
5. Implement `open_artifact()` - Open file in appropriate window/split
6. Implement `stop_watching()` - Cleanup on exit

**Key Features**:
- Uses `vim.uv.new_fs_event()` for native file system watching
- Debouncing to prevent duplicate opens (500ms threshold)
- Smart window detection (split if in terminal, otherwise current window)
- Configurable artifact types to watch
- Error handling and graceful degradation

### Phase 2: Integration with Existing System

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/init.lua`

1. Add artifact watcher initialization to `setup()` function
2. Expose configuration options for user customization
3. Add cleanup in module teardown (if exists)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claudecode.lua`

1. Add default configuration for artifact watching
2. Enable by default with sensible defaults
3. Document configuration options

### Phase 3: User Configuration and Documentation

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`

1. Document artifact watcher feature
2. Provide configuration examples
3. Add troubleshooting section

**Configuration Options**:
```lua
{
  -- Artifact watching
  watch_artifacts = true,              -- Enable/disable feature
  auto_open_artifacts = true,          -- Automatically open new artifacts
  watch_artifact_types = {
    reports = true,                    -- Watch research reports
    plans = true,                      -- Watch implementation plans
    summaries = true,                  -- Watch implementation summaries
    debug = false,                     -- Don't auto-open debug reports
  },
  debounce_ms = 500,                   -- Debounce interval for file events
  open_in_split = nil,                 -- nil = auto-detect, true = always split, false = never split
}
```

### Phase 4: Testing and Refinement

1. **Test Case 1**: Run `/research "test topic"` and verify report auto-opens
2. **Test Case 2**: Run `/plan "test feature"` and verify plan auto-opens
3. **Test Case 3**: Multiple commands in sequence - verify debouncing works
4. **Test Case 4**: Disable feature and verify no auto-opening occurs
5. **Test Case 5**: Terminal vs. normal buffer - verify correct split behavior

### Phase 5: Advanced Features (Optional)

1. **Artifact Type Icons**: Add different icons for reports, plans, summaries in notifications
2. **Smart Window Management**: Remember user preferences for split direction
3. **History Tracking**: Keep a list of recently opened artifacts for quick re-access
4. **Telescope Integration**: Add picker for recent artifacts
5. **Custom Actions**: Allow user to define custom actions per artifact type

---

## Technical Considerations

### 1. Performance Impact

**File System Watchers**:
- Native `vim.uv.new_fs_event()` uses efficient OS-level mechanisms (inotify on Linux)
- Minimal CPU overhead when idle
- Event-driven architecture prevents polling

**Scaling**:
- Each topic directory creates 3-4 watchers (reports, plans, summaries, debug)
- With 100 topic directories: ~300-400 active watchers
- Linux default inotify limit: 8192 watches
- Well within safe limits for typical usage

**Optimization**:
- Lazy watcher creation (only watch existing directories)
- Cleanup stale watchers for deleted topics
- Debouncing prevents duplicate processing

### 2. Race Conditions

**Scenario**: File created before watcher is established

**Mitigation**:
- Watchers are created immediately on Neovim startup
- Existing topic directories are scanned and watched
- New topic directories are detected via parent watcher

**Scenario**: Multiple files created simultaneously

**Mitigation**:
- Debouncing with 500ms threshold
- Recent artifacts tracking prevents duplicates
- Each file gets individual timestamp check

### 3. Buffer Management

**Terminal Buffers**:
- Detection: `vim.api.nvim_buf_get_option(bufnr, 'buftype') == 'terminal'`
- Behavior: Open in vertical split to preserve terminal visibility
- Alternative: Use `botright vsplit` for consistent placement

**Normal Buffers**:
- Behavior: Open in current window (replace buffer)
- Alternative: Check if current buffer is modified, prompt if needed

**User Control**:
- Configuration option: `open_in_split` (nil/true/false)
- Keybinding: Toggle auto-open feature on/off

### 4. Cross-Platform Compatibility

**File System Events**:
- Linux: Uses inotify via libuv
- macOS: Uses FSEvents via libuv
- Windows: Uses ReadDirectoryChangesW via libuv

**Path Handling**:
- Always use `vim.fn.fnameescape()` for safety
- Handle spaces and special characters correctly
- Use absolute paths internally

**Neovim Version**:
- Requires Neovim 0.9+ (for stable `vim.uv` API)
- Graceful degradation: Check API availability before setup

### 5. Error Handling

**File System Errors**:
- Watcher initialization failure: Log warning, continue without watching
- File read errors: Silent skip, don't open
- Permission errors: Notify user, provide manual open option

**Notification Strategy**:
- Success: INFO level, concise message with filename
- Errors: WARN level, include error details
- Use existing `neotex.util.notifications` system

### 6. Configuration Management

**Precedence**:
1. User explicit configuration in `claudecode.lua`
2. Default configuration in artifact-watcher module
3. Runtime toggling via commands

**Persistence**:
- Configuration is in-memory, not persisted
- User preferences in Lua config files
- No state file needed

---

## Integration with Existing Features

### 1. Command Picker Integration

The existing command picker (`claude/commands/picker.lua`) already has file opening functionality:

```lua
-- Line 1307-1318
local function edit_artifact_file(filepath)
  if not filepath or vim.fn.filereadable(filepath) ~= 1 then
    -- Notification on error
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end
```

**Synergy**: The artifact watcher complements this by providing automatic opening, while the picker allows manual browsing and opening of artifacts.

### 2. Session Management Integration

The session manager tracks Claude Code sessions and their associated files. The artifact watcher can enhance this:

**Potential Enhancement**:
- Link opened artifacts to the active Claude Code session
- Track which session created which artifacts
- Provide session-scoped artifact history

### 3. Worktree Integration

The worktree system (`claude/core/worktree.lua`) creates isolated development environments. The artifact watcher should respect worktree boundaries:

**Implementation**:
- Detect if current buffer is in a worktree
- Only watch specs directory within the active worktree
- Multiple watchers for multiple active worktrees

### 4. Visual Selection Integration

The visual selection feature sends code to Claude Code. When Claude generates reports about that code, the artifact watcher can automatically open them:

**User Flow**:
1. Select code in visual mode
2. Send to Claude with prompt: "Analyze this function"
3. Claude creates a research report
4. Report automatically opens in split
5. User reviews analysis alongside original code

---

## Alternative Implementations

### Alternative 1: Plugin-Based Approach

Use existing Neovim plugins for file watching:
- `rktjmp/fwatch.nvim` - Dedicated file watching plugin
- `Makaze/watch.nvim` - Scrollable watch alternative

**Pros**:
- Battle-tested implementations
- Additional features (recursive watching, glob patterns)

**Cons**:
- External dependency
- May be overkill for this specific use case
- Less control over behavior

**Recommendation**: Stick with native `vim.uv` API for better integration and fewer dependencies.

### Alternative 2: Polling-Based Approach

Periodically check specs directory for new files:

```lua
local function poll_specs_directory()
  local specs_dir = find_specs_directory()
  if not specs_dir then return end

  -- Get list of .md files with mtime
  local current_files = get_md_files_with_mtime(specs_dir)

  -- Compare with previous scan
  for filepath, mtime in pairs(current_files) do
    if not previous_files[filepath] or previous_files[filepath] < mtime then
      -- New or modified file
      open_artifact(filepath)
    end
  end

  previous_files = current_files
end

-- Poll every 2 seconds
vim.fn.timer_start(2000, poll_specs_directory, { ['repeat'] = -1 })
```

**Pros**:
- Simple implementation
- No platform-specific code

**Cons**:
- Continuous CPU usage (even when idle)
- Delay between file creation and opening (up to polling interval)
- Not scalable (performance degrades with many files)

**Recommendation**: Polling is inferior to event-driven watching. Don't use this approach.

### Alternative 3: LSP-Style Approach

Implement a Language Server Protocol (LSP) style interface:

```lua
-- Claude workflow LSP server
local server = {
  on_artifact_created = function(artifact_type, filepath)
    open_artifact(filepath, artifact_type)
  end,
}
```

**Pros**:
- Standardized protocol
- Extensible architecture
- Could support other editors (VSCode, Emacs)

**Cons**:
- Massive over-engineering for this use case
- Requires server process management
- Complex implementation and debugging

**Recommendation**: Overkill for single-editor integration. File watching is simpler and sufficient.

---

## Security Considerations

### 1. Path Validation

**Risk**: Malicious file paths in completion signals

**Mitigation**:
- Always use `vim.fn.fnameescape()` when opening files
- Verify file is within expected specs directory
- Check file exists and is readable before opening

### 2. File Content Safety

**Risk**: Opening files with malicious content

**Mitigation**:
- Files are markdown, not executable
- Neovim sandboxes content by default
- No automatic execution of code in markdown files

### 3. File System Permission Issues

**Risk**: Attempting to open files user doesn't have permission to read

**Mitigation**:
- Check `vim.fn.filereadable()` before opening
- Graceful error handling with notifications
- Log errors for debugging

### 4. Resource Exhaustion

**Risk**: Too many watchers consuming system resources

**Mitigation**:
- Limit number of active watchers (practical limit: ~1000)
- Implement watcher cleanup for deleted directories
- Provide configuration to disable feature if needed

---

## Migration and Rollout Strategy

### Phase 1: Development (Week 1)
1. Create artifact-watcher module with core functionality
2. Unit tests for key functions
3. Integration with claude module

### Phase 2: Internal Testing (Week 2)
1. Test with real workflow commands
2. Verify performance with multiple topic directories
3. Test edge cases (rapid file creation, concurrent commands)

### Phase 3: Documentation (Week 2-3)
1. Update README with configuration examples
2. Add troubleshooting guide
3. Document common use cases

### Phase 4: User Rollout (Week 3)
1. Enable by default with conservative settings
2. Provide clear opt-out mechanism
3. Monitor for issues and feedback

### Rollback Plan
If issues arise:
1. Disable by default: Set `watch_artifacts = false` in configuration
2. Keep module in codebase for opt-in usage
3. Fix issues and re-enable in future release

---

## Testing Strategy

### Unit Tests

**File**: `/home/benjamin/.config/nvim/tests/neotex/plugins/ai/claude/util/artifact-watcher_spec.lua`

```lua
describe("artifact-watcher", function()
  local watcher = require("neotex.plugins.ai.claude.util.artifact-watcher")

  it("finds specs directory", function()
    local specs_dir = watcher.find_specs_directory()
    assert.is_not_nil(specs_dir)
    assert.truthy(vim.fn.isdirectory(specs_dir) == 1)
  end)

  it("watches existing topic directories", function()
    -- Create test topic directory
    local test_topic = specs_dir .. "/999_test_topic"
    vim.fn.mkdir(test_topic .. "/reports", "p")

    -- Start watching
    watcher.setup({ auto_open = false })

    -- Create test file
    vim.fn.writefile({"# Test"}, test_topic .. "/reports/001_test.md")

    -- Verify watcher detected file (implementation-specific)
  end)

  it("debounces rapid file creation", function()
    -- Test debouncing logic
  end)

  it("handles missing directories gracefully", function()
    local result = watcher.find_specs_directory()
    -- Should not throw error if directory doesn't exist
  end)
end)
```

### Integration Tests

**Manual Test Cases**:

1. **Basic Functionality**
   - Run: `/research "test topic"`
   - Expected: Report opens automatically in buffer
   - Verify: File path matches completion signal

2. **Multiple Artifacts**
   - Run: `/plan "test feature"` (creates research + plan)
   - Expected: Both report and plan open
   - Verify: Order is predictable (reports before plans)

3. **Terminal Context**
   - Open Claude Code terminal
   - Run: `/research "terminal test"`
   - Expected: Report opens in vertical split
   - Verify: Terminal remains visible

4. **Disabled Feature**
   - Set: `watch_artifacts = false`
   - Run: `/research "disabled test"`
   - Expected: No automatic opening
   - Verify: File is created but not opened

5. **Concurrent Commands**
   - Run multiple commands rapidly
   - Expected: All artifacts open without errors
   - Verify: Debouncing prevents duplicates

### Performance Tests

1. **Many Topic Directories**
   - Create 100 topic directories with artifacts
   - Start Neovim
   - Measure: Startup time impact
   - Expected: < 100ms overhead

2. **Rapid File Creation**
   - Create 10 files in 1 second
   - Measure: CPU usage during event processing
   - Expected: < 5% CPU spike

3. **Long-Running Session**
   - Run Neovim for 8 hours with watcher active
   - Measure: Memory usage over time
   - Expected: No memory leaks (stable memory)

---

## Documentation Requirements

### User-Facing Documentation

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/README.md`

Add section:
```markdown
## Automatic Artifact Opening

The Claude integration automatically opens newly created artifacts (research reports, implementation plans, summaries) in Neovim buffers as they are generated by workflow commands.

### Configuration

```lua
require("neotex.plugins.ai.claude").setup({
  -- Enable artifact watching (default: true)
  watch_artifacts = true,

  -- Automatically open new artifacts (default: true)
  auto_open_artifacts = true,

  -- Which artifact types to watch
  watch_artifact_types = {
    reports = true,    -- Research reports
    plans = true,      -- Implementation plans
    summaries = true,  -- Implementation summaries
    debug = false,     -- Debug reports (usually not auto-opened)
  },

  -- Debounce interval in milliseconds (default: 500)
  debounce_ms = 500,

  -- Split behavior (nil = auto, true = always, false = never)
  open_in_split = nil,
})
```

### Behavior

- **In Terminal**: Opens in vertical split (preserves terminal visibility)
- **In Normal Buffer**: Opens in current window
- **Debouncing**: Prevents duplicate opens within 500ms

### Troubleshooting

**Artifacts not opening automatically**:
1. Check configuration: `:lua print(vim.inspect(require('neotex.plugins.ai.claude').config))`
2. Verify specs directory exists: `:lua print(require('neotex.plugins.ai.claude.util.artifact-watcher').find_specs_directory())`
3. Check for errors: `:messages`

**Too many files opening**:
- Increase debounce interval: `debounce_ms = 1000`
- Disable specific artifact types: `watch_artifact_types = { reports = true, plans = false }`

**Performance issues**:
- Disable feature temporarily: `watch_artifacts = false`
- Check inotify limits (Linux): `cat /proc/sys/fs/inotify/max_user_watches`
```

### Developer Documentation

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/util/artifact-watcher.lua` (inline comments)

```lua
--- Artifact Watcher Module
---
--- Automatically opens newly created workflow artifacts (reports, plans, summaries)
--- in Neovim buffers using native file system event watchers.
---
--- Architecture:
---   1. Watches .claude/specs directory for new topic directories
---   2. For each topic, watches artifact subdirectories (reports/, plans/, etc.)
---   3. When new .md file detected, opens in appropriate window/split
---
--- Performance:
---   - Uses vim.uv.new_fs_event() (native libuv watcher)
---   - O(1) event processing per file
---   - ~300-400 active watchers for 100 topics (well within OS limits)
---
--- @module artifact-watcher
```

---

## Future Enhancements

### 1. Smart Window Management

Track user preferences for window layout:
- Remember last split direction per artifact type
- Implement window size preferences
- Support custom window creation callbacks

### 2. Artifact History and Navigation

Maintain history of opened artifacts:
```lua
-- :ClaudeArtifactHistory command
-- Shows list of recently auto-opened artifacts
-- Supports re-opening and jumping to artifacts
```

### 3. Telescope Integration

Add picker for Claude artifacts:
```lua
-- :Telescope claude_artifacts
-- Browse all artifacts across all topics
-- Preview and open with fuzzy finding
```

### 4. Conditional Opening Rules

Allow users to define rules for when to auto-open:
```lua
watch_rules = {
  reports = function(filepath, topic)
    -- Only auto-open reports for current worktree
    return is_current_worktree(topic)
  end,
  plans = function(filepath, topic)
    -- Only auto-open if plan is under 500 lines
    return vim.fn.system("wc -l < " .. filepath) < 500
  end,
}
```

### 5. Integration with Other Editors

Extend mechanism to support other editors:
- VSCode: Use extension with file watcher
- Emacs: Use file-notify with auto-revert-mode
- Shared protocol: Standardize completion signal format

---

## Conclusion

Implementing automatic buffer opening for Claude Code workflow artifacts is highly feasible using Neovim's native file system event watching API. The recommended approach (file watcher using `vim.uv.new_fs_event()`) provides:

1. **Seamless Integration**: Works with existing command structure without modifications
2. **Excellent Performance**: Event-driven, minimal overhead
3. **Reliability**: Handles concurrent commands, race conditions, and edge cases
4. **User Control**: Fully configurable with sensible defaults
5. **Future-Proof**: Architecture supports extensions and enhancements

The implementation can be completed in 3-4 weeks with proper testing and documentation, providing significant quality-of-life improvement for users who frequently use the workflow commands.

**Next Steps**:
1. Review and approve this implementation plan
2. Create artifact-watcher module with core functionality
3. Integrate with existing Claude Code system
4. Test with real workflow commands
5. Document configuration and usage
6. Deploy with opt-out capability for cautious rollout

---

## Appendix: Code Examples

### Example 1: Complete artifact-watcher.lua Implementation

See "Approach 1: File System Watcher" section above for full implementation.

### Example 2: Integration in init.lua

```lua
-- nvim/lua/neotex/plugins/ai/claude/init.lua

local M = {}

-- ... existing code ...

function M.setup(config)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", {
    simple_picker_max = 3,
    auto_restore_session = true,
    session_timeout_hours = 24,

    -- Artifact watcher configuration
    watch_artifacts = true,
    auto_open_artifacts = true,
    watch_artifact_types = {
      reports = true,
      plans = true,
      summaries = true,
      debug = false,
    },
    debounce_ms = 500,
    open_in_split = nil,

    -- ... other config ...
  }, config or {})

  -- Initialize artifact watcher if enabled
  if M.config.watch_artifacts then
    local ok, watcher = pcall(require, "neotex.plugins.ai.claude.util.artifact-watcher")
    if ok then
      watcher.setup({
        auto_open = M.config.auto_open_artifacts,
        watch_dirs = M.config.watch_artifact_types,
        debounce_ms = M.config.debounce_ms,
        open_in_split = M.config.open_in_split,
      })
    else
      vim.notify(
        "Claude artifact watcher could not be loaded",
        vim.log.levels.WARN
      )
    end
  end

  -- ... existing initialization ...
end

return M
```

### Example 3: User Configuration

```lua
-- nvim/lua/neotex/plugins/ai/claudecode.lua

return {
  "greggh/claude-code.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    -- ... existing opts ...
  },
  config = function(_, opts)
    require("claude-code").setup(opts)

    vim.defer_fn(function()
      local session_manager = require("neotex.plugins.ai.claude.core.session-manager")
      session_manager.setup()

      local ok, claude_module = pcall(require, "neotex.plugins.ai.claude")
      if ok and claude_module and claude_module.setup then
        claude_module.setup({
          -- Artifact watcher configuration
          watch_artifacts = true,        -- Enable feature
          auto_open_artifacts = true,    -- Auto-open new artifacts
          watch_artifact_types = {
            reports = true,              -- Watch research reports
            plans = true,                -- Watch implementation plans
            summaries = true,            -- Watch summaries
            debug = false,               -- Don't auto-open debug reports
          },
          debounce_ms = 500,            -- 500ms debounce
          open_in_split = nil,          -- Auto-detect (split in terminal, replace otherwise)
        })
      end
    end, 100)

    -- ... existing autocmds ...
  end,
}
```

---

## Implementation Status

- **Status**: Planning Complete
- **Plan**: [../plans/001_buffer_opening_integration_plan.md](../plans/001_buffer_opening_integration_plan.md)
- **Implementation**: [Will be updated when implementation begins]
- **Date**: 2025-11-20

---

**END OF REPORT**
