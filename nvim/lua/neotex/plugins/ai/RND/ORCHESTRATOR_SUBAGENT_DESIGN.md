# Orchestrator-Subagent System Design

## Executive Summary

This document details how to implement a primary agent (orchestrator) that manages multiple subagents across git worktrees, with each subagent getting its own WezTerm tab and Claude instance. This builds on the existing `claude-worktree.lua` foundation.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│              PRIMARY ORCHESTRATOR (Main Branch)             │
│                     Claude Instance #1                      │
│                  Coordinates & Monitors                     │
└────────┬───────────┬───────────┬────────────┬───────────────┘
         │           │           │            │
    [Git Worktree] [Git Worktree] [Git Worktree] [Git Worktree]
         │           │           │            │
┌────────┴────┐ ┌────┴──────┐ ┌──┴────────┐ ┌─┴─────────┐
│  Frontend   │ │ Backend   │ │  Tests    │ │   Docs    │
│   Agent     │ │  Agent    │ │  Agent    │ │  Agent    │
│ feature-ui  │ │feature-api│ │test-suite │ │docs-update│
│ WezTerm Tab │ │WezTerm Tab│ │WezTerm Tab│ │WezTerm Tab│
│   Claude    │ │  Claude   │ │  Claude   │ │  Claude   │
└─────────────┘ └───────────┘ └───────────┘ └───────────┘
```

## Implementation Approaches

### Approach 1: Centralized Orchestrator (Recommended)

#### How It Works

1. **Primary Agent Setup**
   - Runs in main branch as orchestrator
   - Has overview of entire project
   - Maintains coordination state

2. **Subagent Spawning**
   - Each subagent gets dedicated worktree
   - Naming: `agent/frontend`, `agent/backend`, etc.
   - Each spawns in new WezTerm tab

3. **Communication Flow**
   ```
   Orchestrator → AGENT_TASKS.md → Subagents
                ↓                ↑
           Assigns tasks    Report progress
                ↓                ↑
           Git commits      Read updates
   ```

4. **Lifecycle Management**
   - Orchestrator spawns subagents with specific context
   - Monitors progress via task file updates
   - Merges completed work back to main
   - Dismisses agents when done

#### Code Implementation

```lua
-- Extension to claude-worktree.lua
local M = require("neotex.core.claude-worktree")

-- Spawn a specialized subagent
function M.spawn_subagent(config)
  -- Validate orchestrator is running
  if not M.is_orchestrator() then
    vim.notify("Only orchestrator can spawn subagents", vim.log.levels.ERROR)
    return
  end
  
  -- Generate agent-specific worktree
  local agent_name = "agent-" .. config.name
  local worktree_path = M._generate_worktree_path(agent_name, "agent")
  local branch = "agent/" .. config.name
  
  -- Create worktree
  local result = vim.fn.system("git worktree add " .. worktree_path .. " -b " .. branch)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to create agent worktree: " .. result, vim.log.levels.ERROR)
    return
  end
  
  -- Create agent context file with instructions
  local context = M._create_agent_context({
    name = config.name,
    role = config.role,
    tasks = config.tasks,
    files_to_focus = config.files,
    orchestrator_branch = "main",
    communication_protocol = "AGENT_TASKS.md"
  })
  
  vim.fn.writefile(vim.split(context, "\n"), worktree_path .. "/CLAUDE.md")
  
  -- Spawn WezTerm tab with Claude
  local tab_id = M._spawn_agent_tab(worktree_path, agent_name)
  
  -- Track subagent in orchestrator state
  M.orchestrator_state.subagents[config.name] = {
    worktree = worktree_path,
    branch = branch,
    tab_id = tab_id,
    status = "active",
    spawned = os.time(),
    tasks_assigned = #config.tasks
  }
  
  return tab_id
end

-- Create agent-specific context
function M._create_agent_context(config)
  return string.format([[
# Subagent: %s

## Your Role
%s

## Assigned Tasks
%s

## Focus Areas
- Files: %s
- Branch: Working in isolated branch '%s'

## Communication Protocol

### Task Updates
Update your section in AGENT_TASKS.md:
```markdown
## %s Agent Tasks
- [x] Completed task [DONE: timestamp]
- [~] Current task [WIP]
- [ ] Pending task
```

### Progress Reporting
- Commit frequently with descriptive messages
- Update task status as you work
- Add [BLOCKED: reason] if you encounter issues

### Coordination
- Check "## Orchestrator Messages" section for updates
- Don't modify other agents' sections
- Use git commits to signal completion

## Context Sync
The orchestrator is monitoring from branch '%s'
Your completed work will be merged when ready.
]],
    config.name,
    config.role,
    table.concat(config.tasks, "\n"),
    table.concat(config.files_to_focus, ", "),
    config.branch,
    config.name,
    config.orchestrator_branch
  )
end
```

### Approach 2: Message-Passing Coordination

#### How It Works

1. **Message Files Structure**
   ```
   .agent-coordination/
   ├── orchestrator/
   │   ├── assignments.md
   │   └── status.md
   ├── frontend/
   │   ├── progress.md
   │   └── blockers.md
   └── backend/
       ├── progress.md
       └── api-spec.md
   ```

2. **Communication Protocol**
   - Agents write to their own directories
   - Orchestrator reads all, writes to orchestrator/
   - Git commits trigger notifications

3. **Synchronization Points**
   - Orchestrator defines sync points
   - Agents wait at boundaries
   - Coordinated integration phases

#### Implementation

```lua
-- Message passing system
function M.send_agent_message(from, to, message)
  local msg_dir = ".agent-coordination/" .. to
  vim.fn.mkdir(msg_dir, "p")
  
  local msg_file = msg_dir .. "/" .. from .. "-" .. os.time() .. ".md"
  local content = string.format([[
From: %s
To: %s
Timestamp: %s

%s
]], from, to, os.date("%Y-%m-%d %H:%M"), message)
  
  vim.fn.writefile(vim.split(content, "\n"), msg_file)
  
  -- Commit the message
  vim.fn.system(string.format(
    "git add %s && git commit -m 'Message from %s to %s'",
    msg_file, from, to
  ))
end

-- Orchestrator monitoring
function M.monitor_subagents()
  local status = {}
  
  for name, agent in pairs(M.orchestrator_state.subagents) do
    -- Check git log for recent commits
    local commits = vim.fn.system(string.format(
      "git log --oneline -5 %s",
      agent.branch
    ))
    
    -- Parse task file for progress
    local task_file = agent.worktree .. "/AGENT_TASKS.md"
    if vim.fn.filereadable(task_file) == 1 then
      local tasks = M.parse_agent_section(task_file, name)
      status[name] = {
        completed = tasks.completed,
        in_progress = tasks.in_progress,
        blocked = tasks.blocked,
        last_commit = commits:match("^(%S+)"),
        active = M.is_tab_active(agent.tab_id)
      }
    end
  end
  
  return status
end
```

### Approach 3: Hierarchical Coordination

#### Structure
```
Main Orchestrator
├── Frontend Lead (coordinates UI agents)
│   ├── Component Agent
│   ├── Styling Agent
│   └── Testing Agent
└── Backend Lead (coordinates API agents)
    ├── Database Agent
    ├── API Agent
    └── Integration Agent
```

#### When to Use
- Large projects with 5+ parallel tasks
- Clear subsystem boundaries
- Need for specialized coordination

## Task File Structure

### Centralized AGENT_TASKS.md

```markdown
# Agent Task Coordination

## Orchestrator Messages
- All agents: API spec updated, see `.agent-coordination/api-v2.yaml`
- Frontend: New endpoints available for testing
- Backend: Database schema approved, proceed with implementation

## Frontend Agent Tasks (worktree: feature-ui)
_Assigned: 2024-01-15 10:00_

- [x] Set up component structure [DONE: 2024-01-15 11:30]
- [~] Implement dashboard view [WIP]
  - [x] Layout complete
  - [ ] Data binding
  - [ ] Event handlers
- [ ] Add responsive design
- [ ] Write component tests
- [-] Integrate with API [BLOCKED: waiting for endpoints]

## Backend Agent Tasks (worktree: feature-api)
_Assigned: 2024-01-15 10:00_

- [x] Design database schema [DONE: 2024-01-15 11:00]
- [x] Create user model [DONE: 2024-01-15 12:00]
- [~] Implement CRUD endpoints [WIP]
  - [x] POST /users
  - [x] GET /users/:id
  - [ ] PUT /users/:id
  - [ ] DELETE /users/:id
- [ ] Add authentication
- [ ] Write API tests

## Test Agent Tasks (worktree: test-suite)
_Assigned: 2024-01-15 14:00_

- [ ] Wait for Frontend component completion
- [ ] Wait for Backend API completion
- [ ] Integration test suite
- [ ] E2E test scenarios

## Coordination Log
- 2024-01-15 10:00: Spawned Frontend and Backend agents
- 2024-01-15 12:00: Backend published API spec
- 2024-01-15 14:00: Spawned Test agent
- 2024-01-15 15:00: Frontend blocked on API integration
```

## WezTerm Tab Management

### Tab Naming Convention
```
Main:        "Orchestrator (main)"
Subagents:   "Agent: Frontend (feature-ui)"
             "Agent: Backend (feature-api)"
             "Agent: Tests (test-suite)"
```

### Tab Lifecycle

```lua
-- Spawn agent in new WezTerm tab
function M._spawn_agent_tab(worktree_path, agent_name)
  -- Create new tab with proper working directory
  local cmd = string.format(
    "wezterm cli spawn --cwd '%s' -- nvim CLAUDE.md",
    worktree_path
  )
  
  local result = vim.fn.system(cmd)
  local pane_id = result:match("(%d+)")
  
  if pane_id then
    -- Set descriptive tab title
    vim.fn.system(string.format(
      "wezterm cli set-tab-title --pane-id %s 'Agent: %s'",
      pane_id, agent_name
    ))
    
    -- Auto-start Claude after nvim loads
    vim.defer_fn(function()
      vim.fn.system(string.format(
        "wezterm cli send-text --pane-id %s ':ClaudeCode\\n'",
        pane_id
      ))
    end, 2000)
    
    return pane_id
  end
end

-- Dismiss agent and cleanup
function M.dismiss_agent(agent_name)
  local agent = M.orchestrator_state.subagents[agent_name]
  if not agent then return end
  
  -- Close WezTerm tab
  if agent.tab_id then
    vim.fn.system("wezterm cli kill-pane --pane-id " .. agent.tab_id)
  end
  
  -- Merge or archive work
  local merge = vim.fn.confirm(
    string.format("Merge %s work to main?", agent_name),
    "&Yes\n&No\n&Archive", 1
  )
  
  if merge == 1 then
    -- Merge branch
    vim.fn.system(string.format(
      "git checkout main && git merge %s",
      agent.branch
    ))
  elseif merge == 3 then
    -- Archive branch
    vim.fn.system(string.format(
      "git tag archive/%s %s",
      agent_name, agent.branch
    ))
  end
  
  -- Remove worktree
  vim.fn.system("git worktree remove " .. agent.worktree .. " --force")
  
  -- Update orchestrator state
  M.orchestrator_state.subagents[agent_name] = nil
  vim.notify("Dismissed agent: " .. agent_name, vim.log.levels.INFO)
end
```

## Orchestrator Dashboard

### Visual Status Display

```lua
function M.show_orchestrator_dashboard()
  local lines = {
    "# Orchestrator Dashboard",
    "",
    "## Active Subagents",
    ""
  }
  
  local status = M.monitor_subagents()
  
  for name, info in pairs(status) do
    local agent = M.orchestrator_state.subagents[name]
    local progress = (info.completed / (info.completed + info.in_progress + #info.blocked)) * 100
    
    table.insert(lines, string.format(
      "### %s (Tab: %s)",
      name,
      info.active and "Active" or "Idle"
    ))
    table.insert(lines, string.format(
      "- Progress: %d%% [%d/%d tasks]",
      progress,
      info.completed,
      agent.tasks_assigned
    ))
    
    if info.in_progress > 0 then
      table.insert(lines, string.format(
        "- Working on: %d task(s)",
        info.in_progress
      ))
    end
    
    if #info.blocked > 0 then
      table.insert(lines, string.format(
        "- BLOCKED: %d task(s)",
        #info.blocked
      ))
    end
    
    table.insert(lines, "")
  end
  
  -- Create floating window with dashboard
  M.create_floating_dashboard(lines)
end
```

## Implementation Timeline

### Phase 1: Basic Orchestrator (Days 1-2)
1. Extend `claude-worktree.lua` with orchestrator role
2. Implement `spawn_subagent()` function
3. Create agent context templates
4. Test with single subagent

### Phase 2: Task Coordination (Days 3-4)
1. Implement sectioned AGENT_TASKS.md
2. Add task parsing and monitoring
3. Create progress tracking
4. Test with two parallel agents

### Phase 3: Communication (Days 5-6)
1. Implement message-passing system
2. Add git-based notifications
3. Create sync point management
4. Test complex coordination scenarios

### Phase 4: Polish (Days 7-8)
1. Orchestrator dashboard UI
2. Tab management improvements
3. Error recovery
4. Performance optimization

## Success Metrics

1. **Isolation**: Agents work without conflicts
2. **Parallelism**: True concurrent development
3. **Visibility**: Clear progress tracking
4. **Reliability**: Survives crashes/restarts
5. **Efficiency**: Reduced context switching

## Configuration

```lua
-- In your config
require("neotex.core.claude-worktree").setup({
  orchestrator = {
    enabled = true,
    max_subagents = 4,
    auto_dismiss_on_complete = false,
    task_file = "AGENT_TASKS.md",
    message_dir = ".agent-coordination"
  },
  subagent = {
    auto_start_claude = true,
    commit_frequency = "frequent",  -- or "on_complete"
    report_interval = 300,  -- seconds
  }
})
```

## Next Steps

1. Start with Centralized Orchestrator approach
2. Implement basic spawn/dismiss functionality
3. Add task file coordination
4. Test with real development scenario
5. Iterate based on usage patterns
