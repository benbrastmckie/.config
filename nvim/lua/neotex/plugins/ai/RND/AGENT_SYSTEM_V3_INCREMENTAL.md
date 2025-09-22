# Agent System v3: Incremental Build Plan

## Philosophy: Start Small, Build Solid, Extend Gradually

This plan starts with what you have working (Claude session management, MCPHub) and incrementally adds features in small, tested steps until reaching a plugin-ready alpha, then beta.

## Current Foundation (What You Have Working)

```
┌─────────────────────────────────────────────────────────────┐
│                   EXISTING FOUNDATION                       │
├─────────────────────────────────────────────────────────────┤
│ • Claude session management (restoration, smart toggle)     │
│ • MCPHub.nvim (MCP server integration)                      │
│ • Visual selection → Claude                                 │
│ • Worktree awareness                                        │
│ • Which-key mappings (<leader>a*)                          │
└─────────────────────────────────────────────────────────────┘
```

## Build Phases: Research → Foundation → Alpha → Beta → Vision

### Research Checkpoints (Before Each Major Feature)

Throughout the build process, we'll pause to research existing solutions before implementing new features. This ensures we don't reinvent wheels and can adapt proven code.

### Phase 0: Solid Core (Week 1)
**Goal**: Create minimal infrastructure that everything else builds on

```
┌─────────────────────────────────────────────────────────────┐
│                      SOLID CORE                            │
├─────────────────────────────────────────────────────────────┤
│  1. Agent Config Module (central configuration)            │
│  2. Task File (AGENT_TASKS.md with standards)              │
│  3. Context Module (basic file awareness)                  │
└─────────────────────────────────────────────────────────────┘
```

#### Step 1: Agent Config Module (Day 1)
```lua
-- lua/neotex/core/agent/init.lua
local M = {}

-- Central configuration
M.config = {
  task_file = vim.fn.expand("~/.local/share/nvim/AGENT_TASKS.md"),
  context_limit = 10, -- Max files to include
  auto_inject_tasks = true,
  debug = false
}

-- Setup function
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Initialize submodules
  require("neotex.core.agent.tasks").setup(M.config)
  require("neotex.core.agent.context").setup(M.config)
  
  -- Create commands
  vim.api.nvim_create_user_command("AgentTasks", function()
    require("neotex.core.agent.tasks").open_tasks()
  end, {})
  
  vim.api.nvim_create_user_command("AgentContext", function()
    require("neotex.core.agent.context").show_context()
  end, {})
end

return M
```

#### Step 2: Task File System (Day 2-3)
```lua
-- lua/neotex/core/agent/tasks.lua
-- (Implementation from AGENT_SYSTEM_V2.md - markdown task file)
-- Focus on:
-- • Initialize task file with standards
-- • Basic add/toggle functions
-- • Auto-inject into Claude context
```

#### Step 3: Basic Context Gatherer (Day 4-5)
```lua
-- lua/neotex/core/agent/context.lua
local M = {}

function M.gather_context()
  return {
    current_file = vim.fn.expand("%:p"),
    git_branch = vim.fn.system("git branch --show-current"):gsub("\n", ""),
    open_buffers = M.get_open_buffers(),
    task_file = M.get_task_content()
  }
end

function M.format_for_claude()
  local context = M.gather_context()
  -- Format as markdown
  return string.format([[
## Current Context

File: %s
Branch: %s

## Active Tasks
%s

## Open Files
%s
]], context.current_file, context.git_branch, context.task_file, ...)
end
```

#### Integration Points (Day 6-7)
```lua
-- Modify existing claude-session.lua
function M.smart_toggle()
  -- ... existing code ...
  
  -- NEW: Auto-inject context if agent system is loaded
  if package.loaded["neotex.core.agent"] then
    local context = require("neotex.core.agent.context").format_for_claude()
    -- Somehow pass this to Claude (implementation depends on your setup)
  end
end
```

### Phase 1: Alpha Features (Week 2)
**Goal**: Add practical enhancements that make daily use better

```
┌─────────────────────────────────────────────────────────────┐
│                    ALPHA FEATURES                          │
├─────────────────────────────────────────────────────────────┤
│  4. Smart Context (related files, errors)                  │
│  5. Simple Templates (3-5 common prompts)                  │
│  6. Task Quick-Add (extract from Claude responses)         │
│  7. Basic Keymaps (<leader>ag*)                           │
└─────────────────────────────────────────────────────────────┘
```

#### Step 4: Smart Context Enhancement (Day 8-9)
```lua
-- Enhance context.lua
function M.find_related_files()
  -- Find imports/requires in current file
  -- Find test files (*_test.*, *.test.*, *_spec.*)
  -- Find README.md in same/parent directory
end

function M.get_recent_errors()
  -- Get diagnostics from current buffer
  -- Format for Claude
end
```

#### Step 5: Simple Templates (Day 10)
```lua
-- lua/neotex/core/agent/templates.lua
local M = {}

M.templates = {
  debug = "Help debug this error:\n{ERROR}\nFile: {FILE}\n",
  test = "Write tests for:\n{SELECTION}\n",
  refactor = "Refactor for clarity:\n{SELECTION}\n"
}

function M.apply_template(template_name)
  -- Get template
  -- Substitute variables
  -- Send to Claude
end
```

#### Step 6: Task Auto-Extract (Day 11-12)
```lua
-- Add to tasks.lua
function M.extract_from_claude_response()
  -- Parse Claude's last response
  -- Look for patterns like "TODO:", "Next:", "Should:", "Need to:"
  -- Auto-add to task file
end

-- Hook into Claude terminal close
vim.api.nvim_create_autocmd("TermClose", {
  pattern = "*claude*",
  callback = function()
    require("neotex.core.agent.tasks").extract_from_claude_response()
  end
})
```

#### Step 7: Unified Keymaps (Day 13-14)
```lua
-- Add to which-key.lua
{
  { "<leader>ag", group = "agent", icon = "" },
  { "<leader>agt", "<cmd>AgentTasks<cr>", desc = "Task dashboard" },
  { "<leader>agc", "<cmd>AgentContext<cr>", desc = "Show context" },
  { "<leader>ags", "<cmd>AgentSendContext<cr>", desc = "Send context to Claude" },
  { "<leader>agp", "<cmd>AgentTemplate<cr>", desc = "Apply template" },
}
```

### Phase 2: Plugin Package (Week 3)
**Goal**: Package as standalone plugin for testing

```
┌─────────────────────────────────────────────────────────────┐
│                  ALPHA PLUGIN STRUCTURE                    │
├─────────────────────────────────────────────────────────────┤
│  claude-agent.nvim/                                        │
│  ├── lua/claude-agent/                                     │
│  │   ├── init.lua         (main entry)                    │
│  │   ├── tasks.lua        (task management)               │
│  │   ├── context.lua      (context gathering)             │
│  │   └── templates.lua    (prompt templates)              │
│  ├── plugin/                                               │
│  │   └── claude-agent.lua (auto commands)                 │
│  └── README.md            (documentation)                 │
└─────────────────────────────────────────────────────────────┘
```

#### Packaging Steps:
1. Move code from `neotex/core/agent/` to new repo
2. Add proper module structure
3. Create minimal README with setup instructions
4. Test as external plugin
5. Tag as v0.1.0-alpha

### Phase 3: Beta Features (Week 4-5)
**Goal**: Add power-user features once core is stable

```
┌─────────────────────────────────────────────────────────────┐
│                     BETA FEATURES                          │
├─────────────────────────────────────────────────────────────┤
│  8. Telescope Integration (task/template pickers)          │
│  9. Project Context Files (.claude-context)                │
│  10. Session History (track what was discussed)            │
│  11. Quick Actions (common operations)                     │
│  12. Performance Metrics (token usage, time tracking)      │
└─────────────────────────────────────────────────────────────┘
```

#### Research Before Beta:
- **Study prompt-tower.nvim** for context file patterns
- **Review ChatGPT.nvim** for template management approaches
- **Examine todotxt.nvim** for task UI patterns

#### Beta Additions:
```lua
-- Telescope picker for tasks
function M.telescope_tasks()
  -- Show tasks in Telescope
  -- Allow filtering by status
  -- Quick toggle with <CR>
end

-- Project-specific context
function M.load_project_context()
  -- Look for .claude-context file
  -- Include project-specific instructions
end

-- Session history
function M.save_session_summary()
  -- After each session, save:
  -- • Topics discussed
  -- • Tasks created/completed
  -- • Files modified
end
```

### Phase 4: Advanced Features Research (Week 6)
**Goal**: Research and prototype advanced features from original vision

```
┌─────────────────────────────────────────────────────────────┐
│                  RESEARCH TARGETS                          │
├─────────────────────────────────────────────────────────────┤
│  Plugin             │ What to Study/Fork                │
├─────────────────────┼───────────────────────────────────┤
│  Magenta.nvim       │ • spawn_subagent pattern          │
│                     │ • wait_for_subagents logic        │
│                     │ • Message passing protocol        │
├─────────────────────┼───────────────────────────────────┤
│  prompt-tower.nvim  │ • Project tree generation         │
│                     │ • File selection UI               │
│                     │ • Smart ignore patterns           │
├─────────────────────┼───────────────────────────────────┤
│  MCPHub.nvim        │ Already integrated                │
│  (existing)         │ Study server management UI        │
├─────────────────────┼───────────────────────────────────┤
│  ChatGPT.nvim       │ • Custom template system          │
│                     │ • Inline command patterns         │
│                     │ • Response parsing                │
├─────────────────────┼───────────────────────────────────┤
│  neowiki.nvim       │ • Note organization               │
│                     │ • GTD workflow patterns           │
└─────────────────────┴───────────────────────────────────────┘
```

#### Research Tasks:
1. **Fork Magenta.nvim's agent spawning** (2 days)
   - Extract spawn_subagent function
   - Adapt to use worktrees instead of contexts
   - Test with simple two-agent setup

2. **Study prompt-tower.nvim** (1 day)
   - Understand file selection algorithm
   - Adapt ignore patterns for context gathering
   - Consider forking the UI picker

3. **Analyze ChatGPT.nvim templates** (1 day)
   - Extract template variable system
   - Study inline command detection
   - Adapt for Claude-specific needs

### Phase 5: Vision Features (Week 7-8)
**Goal**: Implement advanced features approaching original AGENT_SYSTEM_DESIGN.md vision

```
┌─────────────────────────────────────────────────────────────┐
│                    VISION FEATURES                         │
├─────────────────────────────────────────────────────────────┤
│  13. Subagent Orchestration (simplified Magenta approach)  │
│  14. Prompt Component Library (based on research)          │
│  15. Standards Enforcement (lightweight version)           │
│  16. Advanced Context (prompt-tower inspired)              │
│  17. Worktree Integration (git-worktree.nvim)             │
└─────────────────────────────────────────────────────────────┘
```

#### Implementation Strategy:

**Subagent Orchestration** (adapted from Magenta.nvim):
```lua
-- Simplified version of Magenta's pattern
local M = {}

-- Fork/adapt from Magenta.nvim
function M.spawn_subagent(config)
  -- Instead of Magenta's complex context isolation:
  -- 1. Create/switch to worktree
  -- 2. Open new Claude session
  -- 3. Pass specific context
  
  local worktree = require("git-worktree")
  worktree.create_worktree(config.branch)
  
  -- Open Claude in new tab/terminal
  vim.cmd("tabnew")
  vim.cmd("ClaudeCode")
  
  -- Inject agent-specific prompt
  M.inject_agent_context(config)
end

-- Simplified coordination (no complex message passing)
function M.coordinate_agents(agents)
  -- Use task file as coordination point
  -- Each agent updates their section
end
```

**Prompt Components** (inspired by prompt-tower.nvim + ChatGPT.nvim):
```lua
-- Combine best of both approaches
local M = {}

-- From prompt-tower: file selection
M.select_context_files = function()
  -- Fork their file picker
  -- Add to context
end

-- From ChatGPT.nvim: template variables
M.components = {
  personas = {
    architect = "You are a senior software architect...",
    tester = "You are a QA engineer focused on edge cases..."
  },
  contexts = {
    -- Adapted from prompt-tower's project tree
    project = M.generate_project_tree,
    recent_changes = M.get_git_diff
  }
}

-- Simple builder (not complex API)
function M.build_prompt(components)
  local parts = {}
  for _, component in ipairs(components) do
    table.insert(parts, M.components[component.type][component.name])
  end
  return table.concat(parts, "\n\n")
end
```

**Standards Enforcement** (lightweight):
```lua
-- Instead of complex auto-injection, use simple approach
local M = {}

M.standards_file = vim.fn.expand("~/.config/nvim/STANDARDS.md")

-- Simple: just prepend to context
function M.inject_standards()
  if vim.fn.filereadable(M.standards_file) == 1 then
    return vim.fn.readfile(M.standards_file)
  end
  return ""
end

-- Hook into context gathering
local original_gather = require("claude-agent.context").gather
require("claude-agent.context").gather = function()
  local context = original_gather()
  context.standards = M.inject_standards()
  return context
end
```

### Phase 6: Integration & Polish (Week 9-10)
**Goal**: Integrate researched/forked components into cohesive system

#### Integration Tasks:
1. **Merge forked code** into plugin structure
2. **Resolve conflicts** between different approaches
3. **Create unified API** that feels consistent
4. **Performance optimization** (lazy loading, caching)
5. **Comprehensive testing** with real workflows

## Research Strategy

### Before You Build, Research:

1. **Quick Plugin Evaluation** (30 minutes max per plugin)
   - Clone the repo
   - Find the relevant module/function
   - Copy interesting code to a `research/` folder
   - Note complexity and dependencies

2. **Fork Decision Matrix**
   ```
   Should I fork this code?
   ├─ Is it <100 lines? → YES, adapt it
   ├─ Is it well-isolated? → YES, extract module
   ├─ Does it have heavy dependencies? → NO, reimplement
   └─ Is it tightly coupled? → NO, just study patterns
   ```

3. **Research Notes Template**
   ```markdown
   # Plugin: [name]
   ## Useful Code: [file:line]
   ## Pattern: [what it does]
   ## Adaptation: [how to simplify]
   ## Time to implement: [hours]
   ```

## Implementation Timeline

### Week 1: Solid Core
- **Mon**: Research existing task/TODO plugins (2 hrs) + Config module
- **Tue-Wed**: Task file system (adapt from todotxt patterns)
- **Thu**: Research context gathering approaches (2 hrs)
- **Fri-Sun**: Basic context + integration

### Week 2: Alpha Features  
- **Mon**: Research prompt-tower.nvim file selection (2 hrs)
- **Tue**: Smart context implementation
- **Wed**: Study ChatGPT.nvim templates (1 hr) + implement
- **Thu-Fri**: Task extraction
- **Weekend**: Keymaps + testing

### Week 3: Package & Release
- **Mon-Wed**: Create plugin structure
- **Thu-Fri**: Documentation
- **Weekend**: Alpha release (v0.1.0)

### Week 4: Beta Development
- **Mon**: Research Telescope plugin patterns
- **Tue-Wed**: Telescope integration
- **Thu-Fri**: Project files + history

### Week 5: Advanced Research
- **Mon-Tue**: Deep dive into Magenta.nvim spawning
- **Wed-Thu**: Extract and adapt agent patterns
- **Fri**: Test multi-agent setup

### Week 6-8: Vision Implementation
- Build features discovered through research
- Integrate forked/adapted code
- Polish and optimize

### Week 9-10: Final Integration
- Merge all components
- Create unified experience
- Prepare for release

## Success Criteria

### Core Success (End of Week 1)
- [ ] Task file creates and updates properly
- [ ] Context includes current file + tasks
- [ ] Works with existing Claude setup

### Alpha Success (End of Week 2)
- [ ] Can gather smart context (5+ related files)
- [ ] Templates work for common cases
- [ ] Tasks auto-extract from Claude
- [ ] All keymaps functional

### Plugin Success (End of Week 3)
- [ ] Installs via lazy.nvim
- [ ] No conflicts with existing config
- [ ] Documentation covers setup
- [ ] Tagged v0.1.0-alpha

### Beta Success (End of Week 5)
- [ ] Telescope integration smooth
- [ ] Project contexts load automatically
- [ ] Session history tracking works
- [ ] Ready for community testing

## Migration Strategy

### From Current Setup to Core
```lua
-- In your config, add:
require("neotex.core.agent").setup({
  -- Minimal config
})

-- Existing Claude mappings continue working
-- New agent features available via <leader>ag*
```

### From Core to Alpha Plugin
```lua
-- lazy.nvim spec:
{
  "yourusername/claude-agent.nvim",
  dependencies = {
    "greggh/claude-code.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("claude-agent").setup({
      -- Your config
    })
  end
}
```

### Gradual Feature Adoption
Users can:
1. Start with just task tracking
2. Add context gathering when comfortable
3. Enable templates as needed
4. Adopt beta features selectively

## Plugin Research Mapping to Vision

### From AGENT_SYSTEM_DESIGN.md to Existing Plugins:

| Your Vision Component | Research These Plugins | What to Extract |
|----------------------|------------------------|-----------------|
| **Prompt Component Library** | prompt-tower.nvim, ChatGPT.nvim | File selection UI, template variables |
| **Agent TODO Management** | todotxt.nvim, neowiki.nvim | Task formats, GTD patterns |
| **Standards Manager** | None found - build simple | Use CLAUDE.md pattern |
| **Agent Hooks** | mini.nvim (mini.hooks) | Event system patterns |
| **MCP Servers** | MCPHub.nvim ✓ | Already have! |
| **Subagent Spawning** | Magenta.nvim | spawn_subagent, coordination |
| **Worktree Integration** | git-worktree.nvim | Worktree creation API |
| **WezTerm Tabs** | wezterm.nvim | Tab management functions |
| **Context Gathering** | prompt-tower.nvim | Project tree, ignore patterns |
| **Session Management** | Your existing work ✓ | Keep and enhance |

### Specific Code to Research:

1. **Magenta.nvim** (`dlants/magenta.nvim`)
   ```lua
   -- File: lua/magenta/subagents.lua (hypothetical)
   -- Look for: spawn_subagent(), wait_for_subagents()
   -- Complexity: High - may need significant adaptation
   ```

2. **prompt-tower.nvim** (`kylesnowschwartz/prompt-tower.nvim`)
   ```lua
   -- File: lua/prompt-tower/files.lua
   -- Look for: file selection algorithm, ignore patterns
   -- Complexity: Medium - good candidate for forking
   ```

3. **ChatGPT.nvim** (`jackMort/ChatGPT.nvim`)
   ```lua
   -- File: lua/chatgpt/flows.lua
   -- Look for: template system, variable substitution
   -- Complexity: Low - easy to adapt
   ```

4. **git-worktree.nvim** (`ThePrimeagen/git-worktree.nvim`)
   ```lua
   -- File: lua/git-worktree/init.lua
   -- Look for: create_worktree(), switch_worktree()
   -- Complexity: Low - use as dependency
   ```

## Key Decisions

### What to Build First
1. **Task tracking** - Immediate value, simple implementation
2. **Context gathering** - Saves time every session
3. **Templates** - Standardizes common requests

### What to Research Then Adapt
1. **File selection** - Fork from prompt-tower.nvim
2. **Template system** - Adapt from ChatGPT.nvim
3. **Task formats** - Study todotxt.nvim patterns

### What to Use As-Is
1. **MCPHub.nvim** - Already integrated
2. **git-worktree.nvim** - Use as dependency
3. **Telescope** - Use for all UI

### What to Defer Until Research
1. **Subagent spawning** - Study Magenta first
2. **Complex hooks** - See if autocmds suffice
3. **Component library** - Start with simple templates

## Next Immediate Steps

1. **Today**: Create directory structure
```bash
mkdir -p ~/.config/nvim/lua/neotex/core/agent
touch ~/.config/nvim/lua/neotex/core/agent/{init,tasks,context}.lua
```

2. **Tomorrow**: Implement task file system
- Copy task implementation from V2
- Test with real Claude session

3. **This Week**: Get core working
- Basic context gathering
- Integration with existing Claude setup

This incremental approach ensures you always have working software, with each phase adding clear value before moving to the next.