# Claude Session Management - Long-Term Architecture Solution

## Executive Summary
This report provides a comprehensive long-term solution for Claude session management that maintains the clean architecture of the refactor while restoring and enhancing the original UX features. The solution emphasizes robustness, maintainability, and extensibility following the "Evolution, Not Revolution" philosophy from GUIDELINES.md.

## Date: 2025-09-24
## Architecture Version: 2.0

---

## 1. Design Principles & Goals

Following the GUIDELINES.md philosophy of "Evolution, Not Revolution", this solution:

### Core Principles
1. **Single Source of Truth**: Each domain has one authoritative module
2. **Clean Layer Separation**: Core, Infrastructure, UI, and Facade layers remain distinct
3. **Dependency Injection**: Testable, mockable, extensible design
4. **Progressive Enhancement**: Start simple, add features incrementally
5. **Pragmatic Compromises**: Accept Claude CLI limitations, work within them

### Functional Goals
1. Restore the intuitive 3-option picker for `<C-c>` toggle
2. Properly integrate terminal operations with session management
3. Support both Claude CLI native sessions and Neovim-managed sessions
4. Maintain project/git-aware session contexts
5. Enable future extensibility for multi-modal AI tools

---

## 2. Comprehensive Architecture Design

### 2.1 Enhanced Layer Structure

```
nvim/lua/neotex/ai-claude/
├── init.lua                    # Facade (orchestration only)
├── types.lua                   # Shared type definitions
├── config.lua                  # Configuration management
│
├── core/                       # Business Logic (pure functions)
│   ├── session.lua            # Session state management
│   ├── context.lua            # Project/git context awareness
│   └── strategy.lua           # Decision logic for session selection
│
├── infra/                      # I/O Operations
│   ├── persistence.lua        # All file I/O
│   ├── claude-cli.lua         # Claude CLI integration
│   ├── terminal.lua           # Terminal management
│   └── git.lua               # Git operations
│
├── ui/                         # User Interface
│   ├── pickers.lua            # All telescope pickers
│   ├── notifications.lua      # User feedback
│   └── preview.lua           # Preview generation
│
└── adapters/                   # External Integration
    ├── native-sessions.lua     # Claude native session compatibility
    └── legacy.lua             # Backward compatibility shims
```

### 2.2 Type System Enhancement

```lua
-- types.lua - Complete type definitions
---@class ClaudeSession
---@field id string Unique session identifier
---@field project_id string Project/git repository identifier
---@field created number Unix timestamp
---@field updated number Unix timestamp
---@field branch string? Git branch name
---@field worktree_path string? Worktree path if applicable
---@field messages ClaudeMessage[]
---@field metadata SessionMetadata
---@field state SessionState

---@class SessionMetadata
---@field source "native"|"managed" Session origin
---@field version string Schema version
---@field cli_session_id string? Claude CLI session ID
---@field message_count number
---@field last_message_preview string?

---@class SessionState
---@field active boolean
---@field terminal_bufnr number? Associated terminal buffer
---@field window_id number? Associated window

---@class SessionContext
---@field project_id string
---@field git_root string?
---@field branch string?
---@field worktree boolean
---@field cwd string

---@class PickerOption
---@field id string
---@field display string
---@field icon string
---@field action function
---@field metadata table?
```

---

## 3. Concrete Implementation Details

### 3.1 Session Context Management

```lua
-- core/context.lua
local Context = {}
Context.__index = Context

function Context:new(git)
  return setmetatable({ git = git }, self)
end

function Context:get_current()
  local cwd = vim.fn.getcwd()
  local git_root = self.git:get_root()
  local branch = self.git:current_branch()

  -- Generate unique project ID
  local project_id = self:generate_project_id(git_root or cwd)

  return {
    project_id = project_id,
    git_root = git_root,
    branch = branch,
    worktree = self.git:is_worktree(),
    cwd = cwd,
  }
end

function Context:generate_project_id(path)
  -- Convert path to stable ID (handles worktrees)
  local normalized = path:gsub("%-feature%-[^/]+$", "")
                          :gsub("%-bugfix%-[^/]+$", "")
                          :gsub("/", "-")
  return normalized
end

function Context:matches(session, current)
  -- Smart matching logic
  if session.project_id == current.project_id then
    -- Same project, check branch preference
    if session.branch == current.branch then
      return 3  -- Exact match
    end
    return 2    -- Project match
  elseif session.git_root and current.git_root then
    -- Check if related repositories
    if self:are_related_repos(session.git_root, current.git_root) then
      return 1  -- Related match
    end
  end
  return 0      -- No match
end

return Context
```

### 3.2 Session Selection Strategy

```lua
-- core/strategy.lua
local Strategy = {}
Strategy.__index = Strategy

function Strategy:new(config)
  return setmetatable({ config = config }, self)
end

function Strategy:select_best_session(sessions, context)
  local scored = {}

  for _, session in ipairs(sessions) do
    local score = self:score_session(session, context)
    if score > 0 then
      table.insert(scored, { session = session, score = score })
    end
  end

  -- Sort by score and recency
  table.sort(scored, function(a, b)
    if a.score == b.score then
      return a.session.updated > b.session.updated
    end
    return a.score > b.score
  end)

  -- Return top candidates
  local candidates = {}
  for i = 1, math.min(3, #scored) do
    table.insert(candidates, scored[i].session)
  end

  return candidates
end

function Strategy:score_session(session, context)
  local score = 0

  -- Age penalty
  local age_hours = (os.time() - session.updated) / 3600
  if age_hours > self.config.max_age_hours then
    return 0
  end

  -- Context matching
  if session.project_id == context.project_id then
    score = score + 100
    if session.branch == context.branch then
      score = score + 50
    end
  end

  -- Recency bonus
  if age_hours < 1 then
    score = score + 20
  elseif age_hours < 8 then
    score = score + 10
  end

  return score
end

return Strategy
```

### 3.3 Enhanced UI Pickers

```lua
-- ui/pickers.lua
local Pickers = {}
Pickers.__index = Pickers

function Pickers:new()
  return setmetatable({}, self)
end

function Pickers:simple_session_picker(recent_session, callbacks)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  -- Build options based on context
  local options = self:build_simple_options(recent_session)

  pickers.new(require("telescope.themes").get_dropdown({
    winblend = 10,
    previewer = false,
    layout_config = {
      width = 0.5,
      height = 12,
    },
  }), {
    prompt_title = "Claude Session",
    finder = finders.new_table({
      results = options,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%s  %s", entry.icon, entry.display),
          ordinal = entry.display,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          selection.value.action()
        end
      end)

      -- Add info keybinding
      map("i", "<C-i>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.metadata then
          self:show_session_info(selection.value.metadata)
        end
      end)

      return true
    end,
  }):find()
end

function Pickers:build_simple_options(recent_session)
  local options = {}

  if recent_session then
    local age = self:format_age(recent_session.updated)
    table.insert(options, {
      id = "continue",
      display = string.format("Continue last session (%s)", age),
      icon = "󰊢",
      action = function()
        require("neotex.ai-claude").resume_session(recent_session.id)
      end,
      metadata = recent_session,
    })
  end

  table.insert(options, {
    id = "new",
    display = "Start new session",
    icon = "󰈔",
    action = function()
      require("neotex.ai-claude").new_session()
    end,
  })

  table.insert(options, {
    id = "browse",
    display = "Browse all sessions",
    icon = "󰑐",
    action = function()
      require("neotex.ai-claude").show_all_sessions()
    end,
  })

  -- Add project switcher if multiple projects detected
  local projects = self:get_recent_projects()
  if #projects > 1 then
    table.insert(options, {
      id = "projects",
      display = "Switch project context",
      icon = "󰉋",
      action = function()
        self:project_picker(projects)
      end,
    })
  end

  return options
end

function Pickers:full_session_picker(sessions, on_select)
  -- Implementation with full preview
  local previewers = require("telescope.previewers")

  local previewer = previewers.new_buffer_previewer({
    title = "Session Details",
    define_preview = function(self, entry, status)
      local session = entry.value
      local lines = self:generate_preview(session)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end,
  })

  -- Full picker implementation...
end

return Pickers
```

### 3.4 Claude CLI Integration

```lua
-- infra/claude-cli.lua
local ClaudeCLI = {}
ClaudeCLI.__index = ClaudeCLI

function ClaudeCLI:new()
  return setmetatable({
    cache = {},
    cache_ttl = 300,  -- 5 minutes
  }, self)
end

function ClaudeCLI:open_session(opts)
  opts = opts or {}

  -- Check if Claude CLI exists
  if not self:is_available() then
    return false, "Claude CLI not installed"
  end

  -- Build command based on options
  local cmd = "claude"
  if opts.session_id then
    -- Attempt to resume specific session
    cmd = cmd .. " --continue " .. opts.session_id
  elseif opts.continue then
    cmd = cmd .. " --continue"
  end

  -- Open in split
  vim.cmd("vsplit")
  vim.cmd("terminal " .. cmd)

  local bufnr = vim.api.nvim_get_current_buf()

  -- Set up buffer
  vim.bo[bufnr].buflisted = false
  vim.bo[bufnr].bufhidden = "hide"

  -- Store session info
  vim.b[bufnr].claude_session = {
    id = opts.session_id,
    started = os.time(),
  }

  -- Auto-enter insert mode
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.cmd("startinsert")
    end
  end, 100)

  return true, bufnr
end

function ClaudeCLI:list_native_sessions()
  -- Cache results
  local cache_key = "native_sessions"
  if self:is_cache_valid(cache_key) then
    return self.cache[cache_key].data
  end

  -- Parse native session files
  local sessions = {}
  local project_folder = self:get_project_folder()

  if vim.fn.isdirectory(project_folder) == 1 then
    local files = vim.fn.glob(project_folder .. "/*.jsonl", false, true)
    for _, file in ipairs(files) do
      local session = self:parse_session_file(file)
      if session then
        table.insert(sessions, session)
      end
    end
  end

  -- Update cache
  self.cache[cache_key] = {
    data = sessions,
    timestamp = os.time(),
  }

  return sessions
end

function ClaudeCLI:get_project_folder()
  -- Implementation matching Claude's folder naming
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if git_root == "" then
    git_root = vim.fn.getcwd()
  end

  -- Handle worktrees
  local main_repo = git_root:gsub("%-feature%-[^/]+$", "")
                            :gsub("%-bugfix%-[^/]+$", "")

  local folder_name = main_repo:gsub("/", "-"):gsub("^%-", "")
  return vim.fn.expand("~/.claude/projects/" .. folder_name)
end

return ClaudeCLI
```

### 3.5 Enhanced Facade Implementation

```lua
-- init.lua - Complete facade
local M = {}

-- State
M.is_initialized = false
local modules = {}

-- Lazy initialization
local function ensure_initialized()
  if not M.is_initialized then
    error("Claude not initialized. Call setup() first.")
  end
end

function M.setup(opts)
  if M.is_initialized then
    return M
  end

  -- Initialize configuration
  local config = require("neotex.ai-claude.config").setup(opts)

  -- Create infrastructure layers
  modules.persistence = require("neotex.ai-claude.infra.persistence"):new(config.paths)
  modules.git = require("neotex.ai-claude.infra.git"):new()
  modules.terminal = require("neotex.ai-claude.infra.terminal"):new()
  modules.claude_cli = require("neotex.ai-claude.infra.claude-cli"):new()

  -- Create core domain models
  modules.context = require("neotex.ai-claude.core.context"):new(modules.git)
  modules.strategy = require("neotex.ai-claude.core.strategy"):new(config.session)
  modules.session_manager = require("neotex.ai-claude.core.session"):new(
    modules.persistence,
    modules.git,
    modules.terminal,
    modules.claude_cli
  )

  -- Create UI components
  modules.pickers = require("neotex.ai-claude.ui.pickers"):new()
  modules.notifications = require("neotex.ai-claude.ui.notifications"):new()

  -- Create adapters
  modules.native_adapter = require("neotex.ai-claude.adapters.native-sessions"):new(
    modules.claude_cli,
    modules.persistence
  )

  M.is_initialized = true
  return M
end

function M.smart_toggle()
  ensure_initialized()

  -- Check if Claude is already open
  local claude_buf = modules.terminal:find_claude_buffer()
  if claude_buf then
    -- Close it
    return modules.terminal:close_claude(claude_buf)
  end

  -- Get current context
  local context = modules.context:get_current()

  -- Find best matching sessions
  local all_sessions = modules.session_manager:list_sessions()
  local candidates = modules.strategy:select_best_session(all_sessions, context)

  if #candidates == 0 then
    -- No sessions, start new
    return M.new_session()
  elseif #candidates == 1 and modules.strategy:is_obvious_choice(candidates[1], context) then
    -- Single obvious choice, auto-resume
    return M.resume_session(candidates[1].id)
  else
    -- Show simple picker
    modules.pickers:simple_session_picker(candidates[1], {
      on_continue = function() M.resume_session(candidates[1].id) end,
      on_new = function() M.new_session() end,
      on_browse = function() M.show_all_sessions() end,
    })
    return true
  end
end

function M.new_session()
  ensure_initialized()
  return modules.session_manager:create_and_open()
end

function M.resume_session(session_id)
  ensure_initialized()

  if not session_id then
    -- Show full picker
    return M.show_all_sessions()
  end

  return modules.session_manager:resume(session_id)
end

function M.show_all_sessions()
  ensure_initialized()

  local sessions = modules.session_manager:list_all_sessions()
  modules.pickers:full_session_picker(sessions, function(session)
    M.resume_session(session.id)
  end)

  return true
end

-- Additional public APIs...

return M
```

---

## 4. Migration Path

### Phase 1: Core Implementation (Week 1)
1. Implement enhanced type system
2. Create context and strategy modules
3. Update session manager with new dependencies
4. Implement Claude CLI integration

### Phase 2: UI Enhancement (Week 2)
1. Implement simple and full pickers
2. Add preview generation
3. Create notification system
4. Test picker interactions

### Phase 3: Integration (Week 3)
1. Wire everything through facade
2. Update keybindings
3. Add native session compatibility
4. Test end-to-end workflows

### Phase 4: Polish (Week 4)
1. Performance optimization
2. Error handling improvements
3. Documentation
4. User testing

---

## 5. Extensibility Points

This architecture enables future enhancements:

1. **Multi-Provider Support**: Add Anthropic API, OpenAI, etc.
2. **Session Sync**: Cloud backup/restore
3. **Team Collaboration**: Shared sessions
4. **Advanced Context**: File awareness, project understanding
5. **Smart Suggestions**: ML-based session recommendations
6. **Workflow Automation**: Task-based session management

---

## 6. Testing Strategy

### Unit Tests (Per Module)
```lua
-- Example test for strategy module
describe("Strategy", function()
  it("scores exact branch matches highest", function()
    local strategy = Strategy:new({ max_age_hours = 48 })
    local session = { project_id = "test", branch = "main", updated = os.time() }
    local context = { project_id = "test", branch = "main" }

    local score = strategy:score_session(session, context)
    assert.is_true(score > 150)
  end)
end)
```

### Integration Tests
- Test complete flow from keypress to terminal open
- Verify session persistence and restoration
- Test picker interactions
- Validate git/worktree awareness

### User Acceptance Criteria
- `<C-c>` feels instant and intuitive
- Session selection is predictable
- No data loss on crashes
- Works across different project structures

---

*Report generated: 2025-09-24*
*Analyzed by: Claude Assistant*