# Subagent-First Long-Term Implementation Plan

## Core Principle: Incremental Feature Addition via `<leader>a` Mappings

This plan builds orchestrator functionality piece-by-piece through the existing `<leader>a` keymap structure, testing each feature thoroughly before eventually abstracting into a plugin. Every feature is added to your working config first, proven in real use, then refined.

## Implementation Philosophy

1. **Add features directly to existing config** under `<leader>a` mappings
2. **Test each feature in real development** before adding the next
3. **Keep everything working** - no breaking changes
4. **Only abstract to plugin** after all features are proven and stable
5. **Use simple approaches first**, add complexity only when needed

## Long-Term Phase Overview

```
Months 1-2: Core Features (Get subagents working)
Months 3-4: Enhanced Capabilities (Templates, monitoring, coordination)
Months 5-6: Advanced Features (Multi-level orchestration, automation)
Month 7: Plugin Abstraction (Package proven functionality)
Ongoing: Community Features (Based on real usage patterns)
```

## Month 1: Core Working Components

### Week 1: Basic Subagent Spawning (Add to `<leader>ao`)

**Goal**: Get subagents working in worktrees with WezTerm tabs

#### Step 1: Add Orchestrator Mode to Existing Config

```lua
-- ADD to existing claude-worktree.lua

-- Mark main branch as orchestrator
function M.set_as_orchestrator()
  M.orchestrator = {
    active = true,
    subagents = {},
    task_file = vim.fn.getcwd() .. "/AGENT_TASKS.md",
    started = os.time()
  }
  M.save_orchestrator_state()
  vim.notify("Orchestrator mode activated", vim.log.levels.INFO)
end

-- Quick spawn subagent with minimal setup
function M.spawn_subagent(name, role)
  if not M.orchestrator or not M.orchestrator.active then
    vim.notify("Must be in orchestrator mode", vim.log.levels.ERROR)
    return
  end
  
  -- Create worktree
  local worktree_path = "../" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. "-agent-" .. name
  local branch = "agent/" .. name
  
  vim.fn.system("git worktree add " .. worktree_path .. " -b " .. branch)
  
  -- Create CLAUDE.md with role
  local context = string.format([[
# Agent: %s

## Role
%s

## Instructions
- Update your section in AGENT_TASKS.md as you work
- Commit frequently with clear messages
- Mark tasks with [WIP], [DONE], or [BLOCKED]

## Communication
Check AGENT_TASKS.md for:
- Your assigned tasks (## %s Agent section)
- Orchestrator messages at the top
- Other agents' progress

## Working Branch
You are on branch: %s
Main orchestrator is monitoring your progress.
]], name, role, name, branch)
  
  vim.fn.writefile(vim.split(context, "\n"), worktree_path .. "/CLAUDE.md")
  
  -- Spawn WezTerm tab
  local cmd = string.format(
    "wezterm cli spawn --cwd '%s' -- nvim CLAUDE.md -c ':ClaudeCode'",
    worktree_path
  )
  
  local result = vim.fn.system(cmd)
  local pane_id = result:match("(%d+)")
  
  -- Set tab title
  if pane_id then
    vim.fn.system(string.format(
      "wezterm cli set-tab-title --pane-id %s 'Agent: %s'",
      pane_id, name
    ))
  end
  
  -- Track subagent
  M.orchestrator.subagents[name] = {
    worktree = worktree_path,
    branch = branch,
    pane_id = pane_id,
    role = role,
    spawned = os.time(),
    status = "active"
  }
  
  M.save_orchestrator_state()
  vim.notify("Spawned subagent: " .. name, vim.log.levels.INFO)
end

-- Quick dismiss subagent
function M.dismiss_subagent(name)
  local agent = M.orchestrator.subagents[name]
  if not agent then
    vim.notify("Subagent not found: " .. name, vim.log.levels.ERROR)
    return
  end
  
  -- Close WezTerm tab
  if agent.pane_id then
    vim.fn.system("wezterm cli kill-pane --pane-id " .. agent.pane_id)
  end
  
  -- Ask about the work
  local choice = vim.fn.confirm(
    "What to do with " .. name .. "'s work?",
    "&Merge\n&Keep branch\n&Delete", 2
  )
  
  if choice == 1 then
    vim.fn.system("git merge " .. agent.branch)
  elseif choice == 3 then
    vim.fn.system("git branch -D " .. agent.branch)
  end
  
  -- Remove worktree
  vim.fn.system("git worktree remove " .. agent.worktree .. " --force")
  
  M.orchestrator.subagents[name] = nil
  M.save_orchestrator_state()
  vim.notify("Dismissed subagent: " .. name, vim.log.levels.INFO)
end
```

#### Step 2: Add Keymaps to `<leader>a` Structure

```lua
-- ADD to which-key.lua under <leader>a group
{ "<leader>ao", group = "orchestrator" },
{ "<leader>aoo", desc = "Activate orchestrator mode" },
{ "<leader>aos", desc = "Spawn subagent" },
{ "<leader>aod", desc = "Dismiss subagent" },
{ "<leader>aol", desc = "List subagents" },
{ "<leader>aof", desc = "Focus subagent (switch tab)" },
```

### Week 2: Task Coordination System

```lua
-- Initialize AGENT_TASKS.md with sections
function M.init_agent_tasks()
  local task_file = M.orchestrator.task_file
  
  if vim.fn.filereadable(task_file) == 0 then
    local content = [[
# Agent Task Coordination

## Orchestrator Messages
_Messages from the main orchestrator to all agents_

## Active Agents

]]
    
    -- Add section for each agent
    for name, agent in pairs(M.orchestrator.subagents) do
      content = content .. string.format([[
## %s Agent
_Role: %s_
_Branch: %s_

### Tasks
- [ ] Awaiting task assignment

]], name, agent.role, agent.branch)
    end
    
    vim.fn.writefile(vim.split(content, "\n"), task_file)
  end
end

-- Quick task assignment
function M.assign_task(agent_name, task)
  local task_file = M.orchestrator.task_file
  local lines = vim.fn.readfile(task_file)
  
  -- Find agent section and add task
  local in_section = false
  for i, line in ipairs(lines) do
    if line:match("^## " .. agent_name .. " Agent") then
      in_section = true
    elseif in_section and line:match("^### Tasks") then
      -- Insert task after the Tasks header
      table.insert(lines, i + 1, "- [ ] " .. task)
      break
    end
  end
  
  vim.fn.writefile(lines, task_file)
  
  -- Commit the change
  vim.fn.system(string.format(
    "git add %s && git commit -m 'Assigned task to %s: %s'",
    task_file, agent_name, task
  ))
end
```

### Week 3: Progress Monitoring (`<leader>aop`)

**Goal**: Add visibility into agent progress

```lua
-- Add progress tracking functions
function M.get_agent_progress(agent_name)
  -- Parse AGENT_TASKS.md for task status
  local stats = { total = 0, done = 0, wip = 0, blocked = 0 }
  -- Implementation from Day 9 code above
  return stats
end

-- Keymap: <leader>aop - Show progress
{ "<leader>aop", desc = "Show agent progress" },
```

### Week 4: Quick Actions (`<leader>aoa`)

**Goal**: Telescope picker for common orchestrator actions

```lua
-- Add to which-key.lua
{ "<leader>aoa", desc = "Agent actions menu" },
{ "<leader>aob", desc = "Broadcast to all agents" },
```

## Month 2: Enhanced Control

### Week 5-6: Prompt Templates (`<leader>aot`)

```lua
-- NEW FILE: lua/neotex/core/agent-templates.lua
local M = {}

M.templates = {}

-- Built-in templates
M.templates.frontend = {
  role = "You are a frontend specialist focusing on UI/UX implementation",
  context = [[
Focus on:
- Component architecture
- User interactions
- Responsive design
- Accessibility
- Performance optimization
]],
  initial_tasks = {
    "Review UI requirements",
    "Set up component structure",
    "Implement core features",
    "Add styling and animations",
    "Test across browsers"
  }
}

M.templates.backend = {
  role = "You are a backend specialist focusing on API and data layer",
  context = [[
Focus on:
- API design and implementation
- Database operations
- Authentication/Authorization
- Performance and caching
- Error handling
]],
  initial_tasks = {
    "Design data models",
    "Implement API endpoints",
    "Add validation",
    "Write tests",
    "Document API"
  }
}

M.templates.tester = {
  role = "You are a QA specialist focusing on comprehensive testing",
  context = [[
Focus on:
- Unit test coverage
- Integration testing
- Edge cases
- Performance testing
- Bug reproduction
]],
  initial_tasks = {
    "Review requirements",
    "Create test plan",
    "Write unit tests",
    "Perform integration testing",
    "Document findings"
  }
}

-- Use template to spawn agent
function M.spawn_from_template(name, template_name, custom_tasks)
  local template = M.templates[template_name]
  if not template then
    vim.notify("Template not found: " .. template_name, vim.log.levels.ERROR)
    return
  end
  
  local worktree = require("neotex.core.claude-worktree")
  
  -- Spawn with template role
  worktree.spawn_subagent(name, template.role)
  
  -- Add template context to CLAUDE.md
  local agent = worktree.orchestrator.subagents[name]
  if agent then
    local claude_file = agent.worktree .. "/CLAUDE.md"
    local current = vim.fn.readfile(claude_file)
    
    -- Insert template context
    table.insert(current, "")
    table.insert(current, "## Specialized Context")
    table.insert(current, template.context)
    
    vim.fn.writefile(current, claude_file)
    
    -- Assign initial tasks
    local tasks = custom_tasks or template.initial_tasks
    for _, task in ipairs(tasks) do
      worktree.assign_task(name, task)
    end
  end
end

-- Create custom template
function M.create_template(name, template)
  M.templates[name] = template
  M.save_templates()
  vim.notify("Created template: " .. name, vim.log.levels.INFO)
end

return M
```

**Keymaps to add:**
```lua
-- Add to which-key.lua
{ "<leader>aot", desc = "Spawn from template" },
{ "<leader>aote", desc = "Edit templates" },
{ "<leader>aotn", desc = "New template" },
```

### Week 7: Dashboard & Status (`<leader>aoh`)

```lua
-- ADD to claude-worktree.lua
function M.spawn_with_template()
  local templates = require("neotex.core.agent-templates")
  
  -- Select template
  local template_names = vim.tbl_keys(templates.templates)
  
  vim.ui.select(template_names, {
    prompt = "Select agent template:",
    format_item = function(name)
      local t = templates.templates[name]
      return string.format("%s - %s", name, vim.split(t.role, "\n")[1]:sub(1, 40))
    end
  }, function(template_name)
    if not template_name then return end
    
    -- Get agent name
    vim.ui.input({
      prompt = "Agent name: "
    }, function(name)
      if not name then return end
      
      -- Optional: customize tasks
      local customize = vim.fn.confirm("Customize tasks?", "&Yes\n&No", 2)
      
      if customize == 1 then
        -- Open buffer to edit tasks
        local buf = vim.api.nvim_create_buf(false, true)
        local template = templates.templates[template_name]
        local lines = { "# Edit tasks for " .. name, "" }
        
        for _, task in ipairs(template.initial_tasks) do
          table.insert(lines, "- " .. task)
        end
        
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_name(buf, "agent-tasks")
        vim.api.nvim_set_current_buf(buf)
        
        -- Save and spawn on write
        vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
          callback = function()
            local tasks = {}
            local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            for _, line in ipairs(buf_lines) do
              local task = line:match("^%- (.+)")
              if task then
                table.insert(tasks, task)
              end
            end
            
            templates.spawn_from_template(name, template_name, tasks)
            vim.api.nvim_buf_delete(buf, { force = true })
          end,
          desc = "Spawn agent with tasks"
        })
      else
        -- Use default tasks
        templates.spawn_from_template(name, template_name)
      end
    end)
  end)
end

-- Command
vim.api.nvim_create_user_command("AgentSpawnTemplate", M.spawn_with_template, {
  desc = "Spawn agent from template"
})
```

### Week 8: Context Management (`<leader>aoc`)

**Goal**: Better context injection for agents

```lua
-- Dynamic context builder
function M.build_agent_context(config)
  local prompt_parts = {}
  
  -- Role
  table.insert(prompt_parts, "# Role")
  table.insert(prompt_parts, config.role)
  table.insert(prompt_parts, "")
  
  -- Context
  if config.context_files then
    table.insert(prompt_parts, "# Context Files")
    for _, file in ipairs(config.context_files) do
      table.insert(prompt_parts, "- " .. file)
    end
    table.insert(prompt_parts, "")
  end
  
  -- Standards
  if config.standards then
    table.insert(prompt_parts, "# Standards to Follow")
    table.insert(prompt_parts, config.standards)
    table.insert(prompt_parts, "")
  end
  
  -- Dependencies
  if config.dependencies then
    table.insert(prompt_parts, "# Dependencies")
    for dep, version in pairs(config.dependencies) do
      table.insert(prompt_parts, string.format("- %s: %s", dep, version))
    end
    table.insert(prompt_parts, "")
  end
  
  -- Communication
  table.insert(prompt_parts, "# Communication Protocol")
  table.insert(prompt_parts, [[
1. Update AGENT_TASKS.md with your progress
2. Commit with prefix: [AGENT] message
3. Check for updates from orchestrator
4. Report blockers immediately
]])
  
  return table.concat(prompt_parts, "\n")
end

-- Spawn with complex configuration
function M.spawn_complex_agent(config)
  local name = config.name
  local prompt = M.build_agent_prompt(config)
  
  -- Spawn base agent
  M.spawn_subagent(name, config.role)
  
  -- Write full prompt
  local agent = M.orchestrator.subagents[name]
  if agent then
    local prompt_file = agent.worktree .. "/AGENT_CONTEXT.md"
    vim.fn.writefile(vim.split(prompt, "\n"), prompt_file)
    
    -- Update CLAUDE.md to reference it
    local claude_file = agent.worktree .. "/CLAUDE.md"
    local claude_content = vim.fn.readfile(claude_file)
    table.insert(claude_content, "")
    table.insert(claude_content, "See AGENT_CONTEXT.md for detailed instructions")
    vim.fn.writefile(claude_content, claude_file)
  end
end
```

```lua
-- Keymaps
{ "<leader>aoc", desc = "Set agent context" },
{ "<leader>aocf", desc = "Add context files" },
{ "<leader>aocs", desc = "Set standards" },
```

## Month 3-4: Advanced Coordination

### Week 9-10: Multi-Agent Coordination

```lua
-- ADD to claude-worktree.lua
function M.show_orchestrator_dashboard()
  if not M.orchestrator or not M.orchestrator.active then
    vim.notify("Not in orchestrator mode", vim.log.levels.WARN)
    return
  end
  
  local lines = {
    "# Orchestrator Dashboard",
    string.format("Started: %s", os.date("%Y-%m-%d %H:%M", M.orchestrator.started)),
    "",
    "## Active Subagents"
  }
  
  -- Check each agent
  for name, agent in pairs(M.orchestrator.subagents) do
    table.insert(lines, "")
    table.insert(lines, string.format("### %s", name))
    table.insert(lines, string.format("- Role: %s", agent.role:sub(1, 50)))
    table.insert(lines, string.format("- Branch: %s", agent.branch))
    table.insert(lines, string.format("- Spawned: %s", os.date("%H:%M", agent.spawned)))
    
    -- Check if WezTerm tab is still active
    local tab_check = vim.fn.system(string.format(
      "wezterm cli list | grep %s",
      agent.pane_id or "none"
    ))
    
    local status = tab_check ~= "" and "Active" or "Inactive"
    table.insert(lines, string.format("- Status: %s", status))
    
    -- Get last commit
    local last_commit = vim.fn.system(string.format(
      "git log -1 --oneline %s 2>/dev/null",
      agent.branch
    )):gsub("\n", "")
    
    if last_commit ~= "" then
      table.insert(lines, string.format("- Last commit: %s", last_commit))
    end
  end
  
  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  
  local width = 80
  local height = math.min(#lines + 2, 30)
  
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Orchestrator Dashboard ",
    title_pos = "center"
  })
  
  -- Keymaps
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { silent = true })
  
  -- Refresh every 5 seconds if still open
  local timer = vim.loop.new_timer()
  timer:start(5000, 5000, vim.schedule_wrap(function()
    if vim.api.nvim_buf_is_valid(buf) then
      -- Refresh content
      M.show_orchestrator_dashboard()
    else
      timer:close()
    end
  end))
end
```

**Goal**: Coordinate multiple agents working together

```lua
-- Sync points between agents
function M.create_sync_point(agents, description)
  -- Add sync requirement to task file
  for _, agent in ipairs(agents) do
    M.assign_task(agent, "[SYNC] " .. description)
  end
end

-- Agent dependencies
function M.set_dependency(agent, depends_on, task)
  -- Mark task as blocked until dependency completes
end
```

**Keymaps:**
```lua
{ "<leader>aosy", desc = "Create sync point" },
{ "<leader>aosd", desc = "Set dependency" },
```

### Week 11-12: Automation & Triggers

```lua
-- Telescope picker for agent actions
function M.agent_action_picker()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  
  local agent_actions = {}
  
  -- Build action list
  for name, agent in pairs(M.orchestrator.subagents) do
    table.insert(agent_actions, {
      display = string.format("Focus: %s", name),
      action = function() M.focus_agent(name) end
    })
    
    table.insert(agent_actions, {
      display = string.format("Dismiss: %s", name),
      action = function() M.dismiss_subagent(name) end
    })
    
    table.insert(agent_actions, {
      display = string.format("View commits: %s", name),
      action = function() 
        vim.cmd("Git log " .. agent.branch)
      end
    })
  end
  
  -- Add orchestrator actions
  table.insert(agent_actions, {
    display = "Spawn new agent",
    action = M.spawn_with_template
  })
  
  table.insert(agent_actions, {
    display = "Show dashboard",
    action = M.show_orchestrator_dashboard
  })
  
  pickers.new({}, {
    prompt_title = "Agent Actions",
    finder = finders.new_table({
      results = agent_actions,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.display
        }
      end
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          selection.value.action()
        end
      end)
      return true
    end
  }):find()
end

-- Focus agent (switch to its WezTerm tab)
function M.focus_agent(name)
  local agent = M.orchestrator.subagents[name]
  if agent and agent.pane_id then
    vim.fn.system("wezterm cli activate-pane --pane-id " .. agent.pane_id)
    vim.notify("Switched to agent: " .. name, vim.log.levels.INFO)
  end
end

-- Broadcast message to all agents
function M.broadcast_to_agents(message)
  local task_file = M.orchestrator.task_file
  local lines = vim.fn.readfile(task_file)
  
  -- Find orchestrator messages section
  for i, line in ipairs(lines) do
    if line:match("^## Orchestrator Messages") then
      -- Insert message with timestamp
      local msg = string.format("- [%s] %s", os.date("%H:%M"), message)
      table.insert(lines, i + 2, msg)
      break
    end
  end
  
  vim.fn.writefile(lines, task_file)
  
  -- Commit
  vim.fn.system(string.format(
    "git add %s && git commit -m '[ORCHESTRATOR] %s'",
    task_file, message
  ))
  
  vim.notify("Broadcast sent: " .. message, vim.log.levels.INFO)
end
```

**Goal**: Auto-spawn agents based on triggers

```lua
-- Auto-spawn when certain conditions met
function M.setup_auto_spawn(rules)
  -- Example: spawn test agent when code agent completes
  vim.api.nvim_create_autocmd("User", {
    pattern = "AgentTaskComplete",
    callback = function(ev)
      if ev.data.agent == "backend" and ev.data.task:match("API complete") then
        M.spawn_subagent("tester", "Test the completed API")
      end
    end
  })
end

-- Progress-based triggers
function M.check_progress_triggers()
  local task_file = M.orchestrator.task_file
  if vim.fn.filereadable(task_file) == 0 then
    return { total = 0, done = 0, wip = 0, blocked = 0 }
  end
  
  local lines = vim.fn.readfile(task_file)
  local in_section = false
  local stats = { total = 0, done = 0, wip = 0, blocked = 0 }
  
  for _, line in ipairs(lines) do
    if line:match("^## " .. agent_name .. " Agent") then
      in_section = true
    elseif in_section and line:match("^## ") then
      break  -- Next section
    elseif in_section then
      if line:match("^%- %[[ x~%-]%]") then
        stats.total = stats.total + 1
        if line:match("^%- %[x%]") then
          stats.done = stats.done + 1
        elseif line:match("^%- %[~%]") then
          stats.wip = stats.wip + 1
        elseif line:match("^%- %[%-%]") then
          stats.blocked = stats.blocked + 1
        end
      end
    end
  end
  
  return stats
end

  -- Check all agents progress
  for name, _ in pairs(M.orchestrator.subagents) do
    local progress = M.get_agent_progress(name)
    if progress.total > 0 and progress.done == progress.total then
      -- Agent completed all tasks
      vim.api.nvim_exec_autocmds("User", {
        pattern = "AgentComplete",
        data = { agent = name }
      })
    end
  end
end
```

## Month 5-6: Advanced Features

### Week 13-16: Hierarchical Orchestration

**Goal**: Support multi-level agent coordination

```lua
-- Subagent can spawn its own agents
function M.enable_hierarchical_mode()
  M.orchestrator.hierarchical = true
  M.orchestrator.tree = {
    main = {
      frontend_lead = {
        "ui_agent",
        "style_agent",
        "test_agent"
      },
      backend_lead = {
        "api_agent",
        "db_agent"
      }
    }
  }
end
```

### Week 17-20: Integration Features

**Goal**: Integrate with other tools and workflows

```lua
-- GitHub integration
function M.create_pr_from_agent(agent_name)
  -- Create PR from agent's branch
end

-- CI/CD triggers
function M.trigger_ci_on_complete(agent_name)
  -- Run tests when agent completes
end

-- Documentation generation
function M.generate_agent_report()
  -- Create summary of all agent work
end
```

**Keymaps:**
```lua
{ "<leader>aog", group = "git/github" },
{ "<leader>aogp", desc = "Create PR from agent" },
{ "<leader>aogm", desc = "Merge agent work" },
{ "<leader>aor", desc = "Generate report" },
```

## Month 7: Plugin Abstraction

### Only After All Features Are Proven

At this point, you have ~6 months of real usage with:
- All features tested in production
- Patterns proven and refined
- Edge cases discovered and handled
- Workflow optimized for your needs

### Week 21-24: Extract and Package

```lua
-- NEW: lua/claude-orchestrator/init.lua
local M = {}

-- Move all orchestrator functions from claude-worktree.lua
M.spawn_subagent = ... -- moved function
M.dismiss_subagent = ... -- moved function
M.set_as_orchestrator = ... -- moved function
-- etc.

-- Clean API
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", {
    templates_dir = vim.fn.stdpath("config") .. "/agent-templates",
    task_file = "AGENT_TASKS.md",
    auto_init_orchestrator = false,
    wezterm = {
      use_tabs = true,
      auto_start_claude = true
    }
  }, opts or {})
  
  -- Set up commands
  M._create_commands()
  
  -- Load saved state
  M._restore_state()
end

return M
```

### Plugin Structure (Based on Proven Features)

```
claude-orchestrator.nvim/
├── lua/
│   └── claude-orchestrator/
│       ├── init.lua           # Core orchestrator
│       ├── spawn.lua          # Agent spawning
│       ├── templates.lua      # Template system
│       ├── tasks.lua          # Task coordination
│       ├── progress.lua       # Progress tracking
│       ├── triggers.lua       # Automation
│       ├── hierarchy.lua      # Multi-level orchestration
│       └── ui.lua             # All UI components
├── templates/                 # Proven templates
├── doc/                       # Generated from 6 months of use
└── README.md                  # Real usage examples
```

### Configuration (Refined Through Use)

```lua
-- Clean configuration
{
  "your-username/claude-orchestrator.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "greggh/claude-code.nvim",
  },
  config = function()
    require("claude-orchestrator").setup({
      -- Simple, working defaults
      auto_init = true,
      default_role = "You are a specialized development agent",
      templates = {
        -- Your custom templates
      }
    })
  end,
  keys = {
    { "<leader>aos", "<cmd>AgentSpawn<cr>", desc = "Spawn agent" },
    { "<leader>aod", "<cmd>AgentDismiss<cr>", desc = "Dismiss agent" },
    { "<leader>aot", "<cmd>AgentTemplate<cr>", desc = "Spawn from template" },
    { "<leader>aob", "<cmd>AgentBroadcast<cr>", desc = "Broadcast message" },
    { "<leader>aop", "<cmd>AgentProgress<cr>", desc = "Show progress" },
    { "<leader>aoa", "<cmd>AgentActions<cr>", desc = "Agent actions" },
  }
}
```

## Implementation Timeline

### Month 1: Core Working Components
- **Week 1**: Basic subagent spawning (`<leader>aos`, `<leader>aod`)
- **Week 2**: Task coordination via AGENT_TASKS.md
- **Week 3**: Progress monitoring (`<leader>aop`)
- **Week 4**: Quick actions menu (`<leader>aoa`)
- **Result**: Can orchestrate multiple agents effectively

### Month 2: Enhanced Control
- **Week 5-6**: Template system (`<leader>aot`)
- **Week 7**: Dashboard (`<leader>aoh`)
- **Week 8**: Context management (`<leader>aoc`)
- **Result**: Sophisticated agent control and monitoring

### Months 3-4: Advanced Coordination
- **Week 9-10**: Multi-agent sync points
- **Week 11-12**: Automation and triggers
- **Result**: Complex orchestration patterns working

### Months 5-6: Advanced Features
- **Week 13-16**: Hierarchical orchestration
- **Week 17-20**: External integrations (GitHub, CI/CD)
- **Result**: Enterprise-level orchestration capabilities

### Month 7: Plugin Abstraction
- **Week 21-24**: Extract, package, and document
- **Result**: Production-ready plugin based on 6 months of real use

## Keymap Evolution

The `<leader>a` structure grows organically:

```
Month 1:
<leader>ao[o/s/d/l/f]  - Basic orchestrator controls

Month 2:
<leader>ao[t/h/c/p/a]  - Templates, dashboard, context

Month 3-4:
<leader>aos[y/d]       - Sync and dependencies
<leader>aob            - Broadcasting

Month 5-6:
<leader>aog[p/m]       - Git/GitHub integration
<leader>aor            - Reporting
```

## Key Principles

1. **Every feature added to `<leader>a` first** - No separate development
2. **Test in real projects** - Each feature must solve real problems
3. **Keep everything working** - Never break existing functionality
4. **Simple first, complex later** - Start with markdown/git, add complexity only when needed
5. **Document as you go** - Each feature gets a keymap and description

## Success Criteria

### Month 1 Success
- Can spawn 3+ agents for a real project
- Agents complete actual development tasks
- Task coordination works smoothly

### Month 3 Success
- Templates speed up agent creation
- Dashboard provides clear visibility
- Automation reduces manual coordination

### Month 6 Success
- Complex multi-agent projects run smoothly
- Integration with existing workflow complete
- Ready to share with others

### Plugin Success (Month 7+)
- Clean extraction of proven features
- Well-documented from real usage
- Community-ready with examples

## Why This Approach Works

1. **No Wasted Effort**: Only build what you'll actually use
2. **Real Testing**: 6 months of production use before plugin
3. **Organic Growth**: Features emerge from actual needs
4. **Incremental Value**: Each week adds usable functionality
5. **Proven Patterns**: Plugin based on battle-tested code

## First Action

Add to your `claude-worktree.lua` TODAY:

```lua
function M.spawn_subagent(name, role)
  -- 20 lines of code
  -- Creates worktree
  -- Spawns WezTerm tab
  -- Ready to work
end
```

Then spawn your first agent for a real task. Everything else follows from actual use.