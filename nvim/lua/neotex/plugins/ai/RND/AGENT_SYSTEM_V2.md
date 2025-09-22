# Agent System v2: Practical Implementation

## Philosophy: Useful, Robust, Not Complicated

Based on research and your existing setup, this refined design focuses on **practical value** over complexity. We'll leverage MCPHub (which you have), skip unnecessary abstractions, and build only what delivers immediate workflow improvements.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  AGENT ORCHESTRATOR                         │
│            (Simplified Central Controller)                  │
└────┬──────────────┬──────────────┬──────────────┬──────────┘
     │              │              │              │
┌────┴────┐    ┌────┴────┐    ┌────┴────┐    ┌────┴────┐
│ Prompts │    │  Tasks  │    │ Context │    │ Agents  │
│ (Simple)│    │ (Light) │    │ (Smart) │    │ (Basic) │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │
     └──────────────┴──────────────┴──────────────┘
                         │
              ┌──────────┴──────────┐
              │   Claude Code        │
              │   + MCPHub (existing)│
              └─────────────────────┘
```

## Core Components (Prioritized by Value)

### 1. Smart Context Manager (HIGH VALUE, LOW COMPLEXITY)

**Purpose**: Automatically gather and format context for Claude

**Implementation**:
```lua
-- neotex/core/agent-context.lua
local M = {}

-- Auto-detect context based on current buffer/project
function M.gather_context()
  local context = {
    file = vim.fn.expand("%:p"),
    filetype = vim.bo.filetype,
    git_branch = vim.fn.system("git branch --show-current"):gsub("\n", ""),
    related_files = M.find_related_files(),
    recent_errors = M.get_recent_diagnostics(),
    test_files = M.find_test_files()
  }
  return context
end

-- Smart file detection (imports, tests, configs)
function M.find_related_files()
  -- Find imports in current file
  -- Find test files
  -- Find config files
  return files
end

-- Format context for Claude
function M.format_for_claude(context)
  local prompt = string.format([[
Current file: %s
Branch: %s
Related files: %s
Recent errors: %s

Context files attached:
%s
]], context.file, context.git_branch, ...)
  return prompt
end
```

**Usage**: Press `<leader>agc` to send smart context to Claude

### 2. Lightweight Task Tracker (HIGH VALUE, MEDIUM COMPLEXITY)

**Purpose**: Track tasks in a human-readable markdown file with agent update standards

**Implementation**:
```lua
-- neotex/core/agent-tasks.lua
local M = {}

-- Task file location
M.task_file = vim.fn.expand("~/.local/share/nvim/AGENT_TASKS.md")

-- Initialize task file with standards if it doesn't exist
function M.init_task_file()
  if vim.fn.filereadable(M.task_file) == 0 then
    local content = M.get_task_template()
    vim.fn.writefile(vim.split(content, "\n"), M.task_file)
  end
end

-- Get task file template with agent instructions
function M.get_task_template()
  return [[
# Agent Task Tracker

## AGENT INSTRUCTIONS (MUST FOLLOW)

When updating this file, you MUST follow these standards:

1. **Task Format**: Each task MUST use this exact format:
   ```
   - [ ] Task description here (YYYY-MM-DD HH:MM)
   - [x] Completed task example (2024-01-15 14:30) [DONE: 2024-01-15 15:45]
   - [~] In progress task example (2024-01-15 14:00) [WIP]
   - [-] Blocked task example (2024-01-15 13:00) [BLOCKED: waiting for API access]
   ```

2. **Status Markers**:
   - `[ ]` = Pending/Not started
   - `[~]` = Work in progress
   - `[x]` = Completed
   - `[-]` = Blocked/On hold

3. **Metadata Requirements**:
   - Creation timestamp: Required in parentheses after description
   - Completion: Add `[DONE: YYYY-MM-DD HH:MM]` when marking complete
   - Progress: Add `[WIP]` when starting work
   - Blockers: Add `[BLOCKED: reason]` when blocked

4. **Section Organization**:
   - Keep sections in order: Current Sprint → Backlog → Completed → Archive
   - Move completed tasks to Completed section
   - Archive old completed tasks weekly

5. **Update Rules**:
   - NEVER delete tasks, only move them between sections
   - ALWAYS preserve timestamps and history
   - Add context in parentheses for complex tasks
   - Use nested lists for subtasks with 2-space indent

## Current Sprint

_Tasks actively being worked on this session_

- [ ] Example: Implement context gathering (2024-01-15 14:30)

## Backlog

_Tasks identified but not yet started_

## Completed

_Recently completed tasks (move to Archive after 1 week)_

## Archive

_Historical record of completed tasks_

---
*Last Updated: Never*
*Total Tasks: 0 | Completed: 0 | In Progress: 0 | Blocked: 0*
]]
end

-- Add a new task via Lua
function M.add_task(description, section)
  section = section or "Backlog"
  local timestamp = os.date("%Y-%m-%d %H:%M")
  local task_line = string.format("- [ ] %s (%s)", description, timestamp)
  
  -- Read current file
  local lines = vim.fn.readfile(M.task_file)
  
  -- Find section and insert
  for i, line in ipairs(lines) do
    if line:match("^## " .. section) then
      -- Insert after section header and blank line
      table.insert(lines, i + 3, task_line)
      break
    end
  end
  
  -- Update statistics
  M.update_stats(lines)
  
  -- Write back
  vim.fn.writefile(lines, M.task_file)
end

-- Update statistics footer
function M.update_stats(lines)
  local stats = {total = 0, completed = 0, in_progress = 0, blocked = 0}
  
  for _, line in ipairs(lines) do
    if line:match("^%s*- %[[ ~x-]%]") then
      stats.total = stats.total + 1
      if line:match("- %[x%]") then
        stats.completed = stats.completed + 1
      elseif line:match("- %[~%]") then
        stats.in_progress = stats.in_progress + 1
      elseif line:match("- %[-%]") then
        stats.blocked = stats.blocked + 1
      end
    end
  end
  
  -- Update footer
  for i = #lines, 1, -1 do
    if lines[i]:match("^%*Total Tasks:") then
      lines[i] = string.format("*Total Tasks: %d | Completed: %d | In Progress: %d | Blocked: %d*",
        stats.total, stats.completed, stats.in_progress, stats.blocked)
      break
    end
  end
  
  -- Update last modified
  for i = #lines, 1, -1 do
    if lines[i]:match("^%*Last Updated:") then
      lines[i] = "*Last Updated: " .. os.date("%Y-%m-%d %H:%M") .. "*"
      break
    end
  end
end

-- Quick task viewer/editor
function M.open_tasks()
  M.init_task_file()
  vim.cmd("edit " .. M.task_file)
  vim.cmd("setlocal autoread")
  
  -- Set up keymaps for task management
  vim.keymap.set("n", "<CR>", function()
    M.toggle_task_status()
  end, { buffer = true, desc = "Toggle task status" })
  
  vim.keymap.set("n", "<leader>ta", function()
    vim.ui.input({ prompt = "New task: " }, function(input)
      if input then M.add_task(input) end
      vim.cmd("edit!") -- Reload
    end)
  end, { buffer = true, desc = "Add new task" })
end

-- Toggle task status on current line
function M.toggle_task_status()
  local line = vim.api.nvim_get_current_line()
  local new_line = line
  
  if line:match("- %[ %]") then
    -- Start task
    new_line = line:gsub("- %[ %]", "- [~]") .. " [WIP]"
  elseif line:match("- %[~%]") then
    -- Complete task
    local timestamp = " [DONE: " .. os.date("%Y-%m-%d %H:%M") .. "]"
    new_line = line:gsub("- %[~%]", "- [x]"):gsub(" %[WIP%]", "") .. timestamp
  elseif line:match("- %[x%]") then
    -- Reopen task
    new_line = line:gsub("- %[x%]", "- [ ]"):gsub(" %[DONE:.-]", "")
  end
  
  vim.api.nvim_set_current_line(new_line)
  
  -- Update stats
  local lines = vim.fn.readfile(M.task_file)
  M.update_stats(lines)
  vim.fn.writefile(lines, M.task_file)
end

-- Auto-inject task file into Claude context
function M.inject_into_context()
  M.init_task_file()
  return "## Current Tasks\n\n" .. table.concat(vim.fn.readfile(M.task_file), "\n")
end
```

**File Storage**: `~/.local/share/nvim/AGENT_TASKS.md` (structured markdown)

### 3. Prompt Templates (MEDIUM VALUE, LOW COMPLEXITY)

**Purpose**: Quick access to common prompts, no complex library

**Implementation**:
```lua
-- neotex/core/agent-prompts.lua
local M = {}

-- Simple prompt templates
M.templates = {
  refactor = [[
Please refactor this code with the following goals:
- Improve readability
- Reduce complexity
- Maintain functionality
- Add appropriate error handling

{SELECTION}
]],
  
  test = [[
Generate comprehensive tests for:
{SELECTION}

Include:
- Unit tests
- Edge cases
- Error conditions
- Mock any external dependencies
]],
  
  debug = [[
Help debug this issue:
Error: {ERROR}
File: {FILE}
Line: {LINE}

Recent changes:
{GIT_DIFF}

Suggest fixes and explain the root cause.
]]
}

-- Quick template picker with variable substitution
function M.use_template()
  -- Telescope picker for templates
  -- Auto-substitute variables
  -- Send to Claude
end
```

**Usage**: `<leader>apt` - Pick and apply template

### 4. Agent Sessions (Use Existing + Light Extensions)

**What we have**:
- Claude session restoration (your existing work)
- MCPHub for MCP servers

**What to add**:
```lua
-- neotex/core/agent-sessions.lua
local M = {}

-- Link sessions to git worktrees (if using)
function M.get_worktree_session()
  local worktree = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  return worktree .. "/.claude-session"
end

-- Auto-save session context
function M.save_context()
  local session_file = M.get_worktree_session()
  -- Save current buffers, last commands, task list
end

-- Quick session switcher
function M.switch_session()
  -- List worktrees
  -- Show which have active Claude sessions
  -- Switch with one keypress
end
```

### 5. MCP Integration (Already Have - Just Configure)

**Your existing MCPHub setup is good!** Just add useful servers:

```json
// ~/.config/mcphub/servers.json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/home/benjamin"],
      "description": "File system access"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${env:GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "CONNECTION_STRING": "${env:PG_CONNECTION}"
      }
    }
  }
}
```

## What We're NOT Building (Complexity Avoided)

### 1. ~~Complex Subagent Orchestration~~
**Why skip**: Magenta.nvim exists but adds complexity. Your current Claude + worktrees is simpler.

### 2. ~~Bidirectional TODO Sync~~
**Why skip**: Complex to implement, prone to sync issues. Simple task list is enough.

### 3. ~~Comprehensive Hooks System~~
**Why skip**: Over-engineering. Use simple autocmds where needed.

### 4. ~~Standards Auto-Injection~~
**Why skip**: Just keep a STANDARDS.md file and reference it. Claude respects CLAUDE.md already.

### 5. ~~Component Library Architecture~~
**Why skip**: Simple template strings are more maintainable than complex APIs.

## Practical Workflow Integration

### Task File Integration with Claude

The task file (`AGENT_TASKS.md`) will be automatically included in Claude's context. Claude will be instructed to:

1. **Read the AGENT INSTRUCTIONS section** at the start of each session
2. **Update task status** as work progresses:
   - Mark `[~]` when starting a task
   - Mark `[x]` when completing with timestamp
   - Mark `[-]` if blocked with reason
3. **Add new tasks** discovered during work to the Backlog
4. **Move tasks between sections** as appropriate
5. **Never delete tasks**, only move to Archive when old

**Auto-Context Injection**:
```lua
-- When starting Claude, automatically include:
-- 1. Current task file content
-- 2. Instruction to follow the task format
-- 3. Request to update tasks as work progresses

function M.prepare_claude_context()
  local context = {
    "Please read and follow the task tracking standards in AGENT_TASKS.md",
    "Update task status as you work (mark WIP, DONE, BLOCKED)",
    "Add any new tasks you identify to the Backlog section",
    "",
    require("agent-tasks").inject_into_context()
  }
  return table.concat(context, "\n")
end
```

### Daily Workflow

```lua
-- Morning: Start with context
<leader>agc  -- Gather context (includes task file)
<leader>ac   -- Continue yesterday's session

-- Working: Quick actions
<leader>apt  -- Apply prompt template
<leader>agt  -- Open task file in buffer
v<leader>as  -- Send selection to Claude

-- Task Management (in task buffer)
<CR>         -- Toggle task status (pending→WIP→done)
<leader>ta   -- Add new task

-- Debugging: Smart assistance
<leader>agd  -- Debug with context (errors + recent changes)

-- Review: Check progress
<leader>agt  -- Review task file with statistics
<leader>agh  -- Check session health
```

### Implementation Phases (2 Weeks Total)

#### Week 1: Core Features
1. **Day 1-2**: Smart Context Manager
   - Auto-gather related files
   - Format context for Claude
   - Test with real workflows

2. **Day 3-4**: Lightweight Task Tracker
   - Simple JSON storage
   - Telescope picker UI
   - Auto-extract from Claude responses

3. **Day 5-6**: Prompt Templates
   - Create 5-10 useful templates
   - Variable substitution
   - Quick picker interface

#### Week 2: Polish & Integration
1. **Day 7-8**: Session Enhancements
   - Link to worktrees
   - Context persistence
   - Quick switcher

2. **Day 9-10**: Testing & Refinement
   - Real workflow testing
   - Performance optimization
   - Documentation

## Configuration Structure

```lua
-- neotex/plugins/ai/agent-system.lua
return {
  "local/agent-system",
  dir = "~/.config/nvim/lua/neotex/core/agent-system",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "greggh/claude-code.nvim",
    "ravitemer/mcphub.nvim", -- Already have
  },
  config = function()
    require("agent-system").setup({
      -- Minimal config
      auto_context = true,
      task_file = vim.fn.expand("~/.local/share/nvim/agent-tasks.json"),
      templates_dir = vim.fn.expand("~/.config/nvim/agent-templates"),
    })
  end,
  keys = {
    { "<leader>agc", desc = "Gather context" },
    { "<leader>agt", desc = "Task dashboard" },
    { "<leader>apt", desc = "Prompt templates" },
    { "<leader>agd", desc = "Debug with context" },
  }
}
```

## Why This Design is Better

### 1. **Practical Over Theoretical**
- Each feature solves a real, daily problem
- No abstract "might be useful" features
- Everything can be built in days, not months

### 2. **Leverages Existing Tools**
- MCPHub: Already configured, just needs servers
- Claude Code: Your session work is excellent, keep it
- Telescope: Perfect for all pickers, no custom UI needed

### 3. **Simple Data Structures**
- Tasks: JSON file, no database
- Context: Runtime only, no persistence complexity
- Templates: Plain strings with variables

### 4. **Maintainable**
- ~500 lines of Lua total
- No external dependencies beyond what you have
- Clear, single-purpose functions

### 5. **Immediately Useful**
- Smart context gathering saves 5 minutes per session
- Task tracking prevents lost TODOs
- Templates standardize common requests

## Migration Path from v1 Design

### Keep These Ideas
- ✓ Smart context awareness
- ✓ Task tracking (simplified)
- ✓ Prompt templates (simplified)
- ✓ Session management (existing work)
- ✓ MCP integration (MCPHub)

### Drop These Complexities
- ✗ Subagent orchestration → Use multiple Claude tabs if needed
- ✗ Component library → Simple template strings
- ✗ Hooks system → Simple autocmds only
- ✗ Standards manager → CLAUDE.md file is enough
- ✗ Complex TODO sync → One-way extraction only

## Success Metrics

After 2 weeks, you should have:
1. **Context gathering that captures 90% of what you manually copy**
2. **Task list that catches all Claude-suggested TODOs**
3. **5-10 templates you actually use daily**
4. **Zero maintenance overhead**
5. **Under 1 second response time for all operations**

## Next Step

Start with the Smart Context Manager - it's the highest value, lowest complexity feature that will immediately improve every Claude interaction.

```bash
# Create the structure
mkdir -p ~/.config/nvim/lua/neotex/core/agent-system
touch ~/.config/nvim/lua/neotex/core/agent-system/{init,context,tasks,prompts}.lua
```

Then implement `context.lua` first - 50 lines of code for massive workflow improvement.