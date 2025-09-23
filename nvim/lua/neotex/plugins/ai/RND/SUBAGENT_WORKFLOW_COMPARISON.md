# Subagent Workflow Comparison for Neovim Integration

## Executive Summary

This document compares different approaches for implementing multi-agent workflows in Neovim, evaluating three primary strategies plus alternatives based on the existing spec files and research into available solutions.

## Context & Requirements

Based on your existing infrastructure:
- **Current Assets**: Working Claude Code integration, worktree management (`claude-worktree.lua`), MCPHub.nvim, visual selection integration
- **Design Specs**: AGENT_SYSTEM_V3_INCREMENTAL.md, ORCHESTRATOR_SUBAGENT_DESIGN.md, SUBAGENT_FIRST_IMPLEMENTATION.md
- **Goals**: Elegant workflow for managing subagents in Neovim with worktree isolation

## Approach Comparison

### Approach 1: Claude Code Delegation (Your Proposed Method)
**Concept**: Use `<leader>av` and `<leader>aw` to manage worktrees, then let Claude Code manage subagents internally

```
┌─────────────────────────────────────────────────────────────┐
│                   User in Main Worktree                     │
│                  <leader>aw → Switch/Create                 │
└───────────────────┬─────────────────────────────────────────┘
                    │
┌───────────────────┴─────────────────────────────────────────┐
│                Claude Code (Orchestrator)                   │
│         Uses Task tool to spawn multiple subagents          │
│              Manages coordination internally                │
└───────────────────┬─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┬──────────────┐
        │           │           │              │
    [Worktree 1] [Worktree 2] [Worktree 3] [Worktree 4]
     Frontend     Backend      Testing       Docs
```

**Pros:**
- Minimal Neovim-side implementation required
- Leverages Claude Code's existing Task tool and agent capabilities
- Simple user interface through existing keymaps
- Claude handles complex orchestration logic
- Works with current `claude-worktree.lua` infrastructure

**Cons:**
- Less direct control over individual agents from Neovim
- Harder to monitor agent progress from editor
- Dependency on Claude Code's internal agent management
- Limited visibility into agent state without Claude interface

**Implementation Effort:** Low (1-2 weeks)

---

### Approach 2: Magenta.nvim-Style Sub-Agents
**Concept**: Implement Magenta.nvim's spawn/wait pattern with dedicated worktrees

```
┌─────────────────────────────────────────────────────────────┐
│              Neovim Orchestrator (Main Branch)              │
│                   spawn_subagent() functions                │
└────────┬───────────┬───────────┬────────────┬───────────────┘
         │           │           │            │
    [Spawn]     [Spawn]     [Spawn]      [Spawn]
         │           │           │            │
┌────────┴────┐ ┌────┴──────┐ ┌──┴────────┐ ┌─┴─────────┐
│  Frontend   │ │ Backend   │ │  Tests    │ │   Docs    │
│   Agent     │ │  Agent    │ │  Agent    │ │  Agent    │
│ (Worktree)  │ │(Worktree) │ │(Worktree) │ │(Worktree) │
│  + Claude   │ │ + Claude  │ │ + Claude  │ │ + Claude  │
└─────────────┘ └───────────┘ └───────────┘ └───────────┘
```

**Key Features from Magenta.nvim to Adopt:**
- `spawn_subagent(config)` - Creates specialized agent with context
- `wait_for_subagents()` - Synchronization points
- `spawn_foreach()` - Parallel batch operations
- Message passing through shared files
- Progress tracking and result yielding

**Pros:**
- Fine-grained control from Neovim
- Can leverage Magenta's proven patterns
- Better progress visibility through editor UI
- Supports parallel and hierarchical workflows
- Direct integration with git worktrees

**Cons:**
- Significant implementation complexity
- Need to port/adapt TypeScript code to Lua
- Requires extensive testing for edge cases
- More maintenance overhead

**Implementation Effort:** High (4-6 weeks)

---

### Approach 3: Individual Agent Management
**Concept**: Create subagents individually from Neovim, each in its own WezTerm tab

```
┌─────────────────────────────────────────────────────────────┐
│                    Neovim Control Center                    │
│              <leader>aos → Spawn Individual Agent           │
└────────┬───────────┬───────────┬────────────┬───────────────┘
         │           │           │            │
    [Manual]    [Manual]    [Manual]     [Manual]
         │           │           │            │
┌────────┴────┐ ┌────┴──────┐ ┌──┴────────┐ ┌─┴─────────┐
│ WezTerm Tab │ │WezTerm Tab│ │WezTerm Tab│ │WezTerm Tab│
│  Frontend   │ │  Backend  │ │   Tests   │ │   Docs    │
│  Worktree   │ │ Worktree  │ │ Worktree  │ │ Worktree  │
│   Claude    │ │  Claude   │ │  Claude   │ │  Claude   │
└─────────────┘ └───────────┘ └───────────┘ └───────────┘
```

**Implementation Details:**
- Each agent spawned via `<leader>aos` (orchestrator spawn)
- Individual CLAUDE.md context files per worktree
- Manual coordination through AGENT_TASKS.md
- WezTerm tab management for each agent

**Pros:**
- Complete control over each agent
- Easy to debug individual agents
- Can manually intervene at any point
- Simpler implementation than full orchestration
- Natural integration with existing workflow

**Cons:**
- More manual coordination required
- No automatic synchronization
- User must manage multiple tabs/windows
- Less efficient for complex multi-agent tasks

**Implementation Effort:** Medium (2-3 weeks)

---

## Alternative Approaches Discovered

### 4. Hybrid Telescope-Based Coordination

**Concept**: Use Telescope as the primary interface for agent management

```lua
-- Telescope picker for all agent operations
<leader>aot → Telescope agent picker
  - Spawn new agent
  - Monitor progress
  - Switch between agents
  - Coordinate tasks
```

**Pros:**
- Familiar Neovim interface
- Easy to extend and customize
- Good for visual feedback

**Cons:**
- Limited for complex orchestration
- Primarily UI-focused

---

### 5. Task File-Driven Orchestration

**Concept**: Use AGENT_TASKS.md as the primary coordination mechanism

```markdown
## Orchestrator Commands
!spawn frontend ui-specialist
!spawn backend api-specialist
!sync-point all
!wait backend.api_complete
!dismiss frontend
```

**Pros:**
- Git-trackable coordination
- Easy to understand and modify
- Works with any editor

**Cons:**
- Requires custom parser
- Less real-time feedback

---

### 6. MCP Server-Based Coordination

**Concept**: Implement coordination as an MCP server that agents connect to

**Pros:**
- Standard protocol
- Could work with multiple AI providers
- Clean separation of concerns

**Cons:**
- Complex to implement
- Overhead of running separate server
- Less integrated with Neovim

---

## Recommendation Based on Your Context

Given your existing infrastructure and goals, I recommend **Approach 7: Task Delegation with Report-Back** as the primary implementation strategy:

### Why This Approach Wins

1. **Natural Mental Model**: Developers already think in terms of "delegate this task and get back to me"
2. **Leverages Existing Infrastructure**: Builds directly on your `claude-worktree.lua`
3. **Immediate Value**: Can implement basic version in days, not weeks
4. **Scalable Complexity**: Children can spawn their own subagents when needed
5. **Git-Native**: All coordination through branches and markdown files
6. **Clear Accountability**: Report-back mechanism ensures nothing gets lost

### Implementation Roadmap

#### Phase 1: Core Task Delegation (Week 1)
**Start Here - Immediate Value**

Extend your existing `claude-worktree.lua` with:
```lua
function M.spawn_child_task(task_description, context_files)
  -- Create task worktree
  -- Generate TASK_DELEGATION.md
  -- Create child CLAUDE.md
  -- Spawn WezTerm tab
  -- Track delegation
end

function M.task_report_back()
  -- Generate report from git history
  -- Write to parent's REPORT_BACK.md
  -- Offer to return to parent
end

-- Add to which-key
{ "<leader>ast", desc = "Spawn child task" }
{ "<leader>asb", desc = "Report back (in child)" }
{ "<leader>asr", desc = "Read task reports" }
```

This gives you a working delegation system in days.

#### Phase 2: Enhanced Monitoring (Week 2)
**Add Visibility**

- Task monitoring dashboard
- Report processing UI
- Automatic merge suggestions
- WezTerm notifications

#### Phase 3: Advanced Orchestration (Week 3+)
**Scale Up Complexity**

- Parallel child tasks
- Dependency chains
- Automatic report summarization
- Integration with Claude Code's Task tool

## Implementation Priorities

### Immediate (Week 1):
1. Extend `claude-worktree.lua` with basic `spawn_subagent()`
2. Add AGENT_TASKS.md sectioned coordination
3. Create WezTerm tab management functions
4. Add progress monitoring via task file parsing

### Short Term (Week 2-3):
1. Template system for common agent roles
2. Telescope picker for agent management
3. Basic progress dashboard
4. Git-based synchronization points

### Medium Term (Month 2):
1. Test Claude Code's Task tool with worktrees
2. Implement message passing between agents
3. Add automated triggers and dependencies
4. Create hierarchical agent structures

### Long Term (Month 3+):
1. Study and adapt Magenta.nvim patterns
2. Implement parallel batch operations
3. Build sophisticated orchestration
4. Package as reusable plugin

## Decision Matrix

| Criteria | Approach 1 (Claude) | Approach 2 (Magenta) | Approach 3 (Individual) | Recommended Hybrid |
|----------|-------------------|---------------------|----------------------|-------------------|
| Implementation Effort | Low | High | Medium | Medium |
| Control Granularity | Low | High | High | High |
| Automation Level | High | High | Low | Medium→High |
| Maintenance Burden | Low | High | Medium | Medium |
| Learning Curve | Low | High | Low | Low→Medium |
| Flexibility | Medium | High | High | High |
| Integration with Existing | High | Low | High | High |
| Time to First Value | 1 week | 4-6 weeks | 2 weeks | 2 weeks |

## Conclusion

The **phased hybrid approach** offers the best balance:

1. **Quick wins** with individual agent management (Week 1-2)
2. **Leverage Claude Code** for complex orchestration (Week 3)
3. **Gradual sophistication** based on actual needs (Month 2+)

This approach:
- Builds on your existing `claude-worktree.lua` foundation
- Provides immediate practical value
- Allows organic growth based on real usage
- Avoids over-engineering before understanding actual needs
- Maintains flexibility to adopt Magenta.nvim patterns later

Start with `M.spawn_subagent()` in your existing module and expand from there. The infrastructure you've already built (worktree management, WezTerm integration, session tracking) provides 80% of what you need.

## Approach 7: Task Delegation with Report-Back (NEW RECOMMENDATION)

### Concept: Hierarchical Task Delegation with Return Channel

This approach implements a parent-child relationship where a Claude session in one WezTerm tab can spawn child sessions that complete tasks and report back. The parent maintains context while children handle specific subtasks.

```
┌─────────────────────────────────────────────────────────────┐
│            Parent Claude Session (WezTerm Tab 1)            │
│                    "I need to refactor X"                   │
│                  <leader>ast → Spawn Subtask                │
└────────────────────┬─────────────────────────────────────────┘
                     │
                [Delegates Task]
                     │
┌────────────────────┴─────────────────────────────────────────┐
│            Child Claude Session (WezTerm Tab 2)             │
│                  Receives: Task + Context                    │
│              Can spawn own subagents if needed              │
│                  Completes work in isolation                │
└────────────────────┬─────────────────────────────────────────┘
                     │
                [Reports Back]
                     │
┌────────────────────┴─────────────────────────────────────────┐
│                      REPORT_BACK.md                         │
│          Summary of changes + Git commits + Results         │
└──────────────────────────────────────────────────────────────┘
                     ↓
            [Parent reads report]
```

### Implementation Design

#### 1. Core Task Delegation System

```lua
-- Extension to claude-worktree.lua
local M = require("neotex.core.claude-worktree")

-- Task delegation state
M.task_delegations = {}  -- { parent_id = { children = {...} } }

-- Spawn a child task from current session
function M.spawn_child_task(task_description, context_files)
  -- Get parent session info
  local parent_id = M.get_current_session_id()
  local parent_path = vim.fn.getcwd()
  local parent_branch = vim.fn.system("git branch --show-current"):gsub("\n", "")

  -- Generate child session name
  local child_name = string.format("task-%s-%d",
    task_description:gsub("%s+", "-"):sub(1, 20),
    os.time()
  )

  -- Create task worktree
  local child_worktree = M._generate_worktree_path(child_name, "task")
  local child_branch = "task/" .. child_name

  vim.fn.system(string.format(
    "git worktree add %s -b %s",
    child_worktree, child_branch
  ))

  -- Create task delegation file
  local delegation_file = child_worktree .. "/TASK_DELEGATION.md"
  local delegation_content = M._create_delegation_context({
    parent_id = parent_id,
    parent_path = parent_path,
    parent_branch = parent_branch,
    task = task_description,
    context_files = context_files,
    report_back_file = parent_path .. "/REPORT_BACK.md"
  })

  vim.fn.writefile(vim.split(delegation_content, "\n"), delegation_file)

  -- Create CLAUDE.md with instructions
  local claude_md = M._create_child_claude_context({
    task = task_description,
    parent_branch = parent_branch,
    delegation_file = delegation_file
  })

  vim.fn.writefile(vim.split(claude_md, "\n"), child_worktree .. "/CLAUDE.md")

  -- Track delegation
  if not M.task_delegations[parent_id] then
    M.task_delegations[parent_id] = { children = {} }
  end

  table.insert(M.task_delegations[parent_id].children, {
    name = child_name,
    worktree = child_worktree,
    branch = child_branch,
    task = task_description,
    status = "active",
    spawned = os.time()
  })

  -- Spawn WezTerm tab with Claude
  M._spawn_child_claude_tab(child_worktree, child_name)

  vim.notify(string.format("Spawned child task: %s", child_name), vim.log.levels.INFO)

  return child_name
end
```

#### 2. Task Context Templates

```lua
-- Create delegation context for child
function M._create_delegation_context(config)
  return string.format([[
# Task Delegation

## Parent Session
- **ID**: %s
- **Path**: %s
- **Branch**: %s

## Assigned Task
%s

## Context Files
%s

## Instructions for Completion

1. Complete the assigned task in this isolated worktree
2. Commit your changes with clear messages
3. When complete, run `:TaskReportBack` to generate report
4. The report will be sent to: `%s`

## Report Format

Your report should include:
- Summary of changes made
- List of files modified/created
- Git commit references
- Any issues encountered
- Suggestions for parent session

## Available Commands

- `:TaskReportBack` - Generate and send report to parent
- `:TaskStatus` - Show current task status
- `:TaskCancel` - Cancel task and cleanup
]],
    config.parent_id,
    config.parent_path,
    config.parent_branch,
    config.task,
    table.concat(vim.tbl_map(function(f) return "- " .. f end,
      config.context_files or {}), "\n"),
    config.report_back_file
  )
end

-- Create CLAUDE.md for child session
function M._create_child_claude_context(config)
  return string.format([[
# Child Task Session

## Your Assignment
%s

## Context
You are working in a child session spawned from branch `%s`.
Your work is isolated in this worktree and will be reported back to the parent session.

## Workflow

1. **Understand the task**: Read TASK_DELEGATION.md for full context
2. **Complete the work**: Make changes, test, and commit
3. **Report completion**: Use `:TaskReportBack` when done

## Important Notes

- Work in isolation - don't worry about conflicts with parent
- Commit frequently with clear messages
- If you need to spawn your own subagents, you can do so
- Parent session is waiting for your report

## Task Delegation Details
See: TASK_DELEGATION.md
]],
    config.task,
    config.parent_branch
  )
end
```

#### 3. Report-Back Mechanism

```lua
-- Generate report and notify parent
function M.task_report_back()
  -- Get current task info
  local delegation_file = vim.fn.getcwd() .. "/TASK_DELEGATION.md"
  if vim.fn.filereadable(delegation_file) == 0 then
    vim.notify("Not in a delegated task session", vim.log.levels.ERROR)
    return
  end

  -- Parse delegation info
  local delegation = M._parse_delegation_file(delegation_file)

  -- Generate report content
  local report = M._generate_task_report(delegation)

  -- Write report to parent's directory
  local report_file = delegation.report_back_file
  local existing = vim.fn.filereadable(report_file) == 1 and
                   vim.fn.readfile(report_file) or {}

  -- Append new report
  vim.list_extend(existing, vim.split(report, "\n"))
  vim.fn.writefile(existing, report_file)

  -- Notify parent via WezTerm (if possible)
  M._notify_parent_session(delegation.parent_id, delegation.task)

  -- Show completion dialog
  local choice = vim.fn.confirm(
    "Report sent! What would you like to do?",
    "&Return to parent\n&Stay here\n&Clean up", 1
  )

  if choice == 1 then
    M._return_to_parent(delegation)
  elseif choice == 3 then
    M._cleanup_child_session(delegation)
  end
end

-- Generate comprehensive task report
function M._generate_task_report(delegation)
  local git_log = vim.fn.system("git log --oneline " .. delegation.parent_branch .. "..HEAD")
  local git_diff = vim.fn.system("git diff --stat " .. delegation.parent_branch .. "..HEAD")
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")

  return string.format([[

---

## Task Report: %s
**Generated**: %s
**Child Branch**: %s

### Summary
[Auto-generated from git commits and changes]

### Changes Made
```
%s
```

### Commits
```
%s
```

### Files Modified
%s

### Status
- [x] Task completed
- [ ] Requires review
- [ ] Has blockers

### Notes for Parent Session
- Changes are ready to merge from branch: %s
- Run `git merge %s` to integrate changes

---

]],
    delegation.task,
    timestamp,
    vim.fn.system("git branch --show-current"):gsub("\n", ""),
    git_diff,
    git_log,
    M._list_modified_files(),
    vim.fn.system("git branch --show-current"):gsub("\n", ""),
    vim.fn.system("git branch --show-current"):gsub("\n", "")
  )
end
```

#### 4. Parent Session Integration

```lua
-- Monitor child tasks from parent session
function M.monitor_child_tasks()
  local parent_id = M.get_current_session_id()
  local children = M.task_delegations[parent_id]

  if not children or #children.children == 0 then
    vim.notify("No child tasks active", vim.log.levels.INFO)
    return
  end

  -- Create monitoring dashboard
  local lines = {
    "# Active Child Tasks",
    "",
    string.format("Parent Session: %s", parent_id),
    "",
    "## Delegated Tasks"
  }

  for _, child in ipairs(children.children) do
    local status = M._check_child_status(child)
    table.insert(lines, string.format(
      "- [%s] %s (%s)",
      status.complete and "x" or status.active and "~" or " ",
      child.task,
      child.name
    ))

    if status.has_report then
      table.insert(lines, "  └─ Report available!")
    end
  end

  -- Check for reports
  local report_file = vim.fn.getcwd() .. "/REPORT_BACK.md"
  if vim.fn.filereadable(report_file) == 1 then
    table.insert(lines, "")
    table.insert(lines, "## Reports Available")
    table.insert(lines, "Run `:TaskReadReports` to view")
  end

  -- Display in floating window
  M._show_dashboard(lines)
end

-- Read and process reports from children
function M.read_task_reports()
  local report_file = vim.fn.getcwd() .. "/REPORT_BACK.md"

  if vim.fn.filereadable(report_file) == 0 then
    vim.notify("No reports available", vim.log.levels.INFO)
    return
  end

  -- Open report file in new buffer
  vim.cmd("split " .. report_file)
  vim.cmd("setlocal filetype=markdown")

  -- Add keymaps for report actions
  vim.keymap.set("n", "<leader>tm", function()
    -- Merge child branch
    local branch = M._extract_branch_from_report()
    if branch then
      local confirm = vim.fn.confirm(
        string.format("Merge branch %s?", branch),
        "&Yes\n&No", 2
      )
      if confirm == 1 then
        vim.fn.system("git merge " .. branch)
        vim.notify("Merged: " .. branch, vim.log.levels.INFO)
      end
    end
  end, { buffer = true, desc = "Merge reported branch" })

  vim.keymap.set("n", "<leader>tc", function()
    -- Clear processed report
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local keep_lines = M._filter_unprocessed_reports(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, keep_lines)
    vim.cmd("write")
  end, { buffer = true, desc = "Clear processed reports" })
end
```

#### 5. Keybindings and Commands

```lua
-- Add to which-key.lua
{ "<leader>ast", desc = "Spawn child task" },
{ "<leader>asm", desc = "Monitor child tasks" },
{ "<leader>asr", desc = "Read task reports" },
{ "<leader>asb", desc = "Report back (in child)" },

-- Create commands
vim.api.nvim_create_user_command("TaskDelegate", function(opts)
  local task = opts.args
  if task == "" then
    task = vim.fn.input("Task description: ")
  end

  -- Get context files
  local context_files = {}
  local current_file = vim.fn.expand("%:p")
  if current_file ~= "" then
    table.insert(context_files, current_file)
  end

  M.spawn_child_task(task, context_files)
end, { nargs = "*", desc = "Delegate task to child session" })

vim.api.nvim_create_user_command("TaskReportBack", M.task_report_back, {
  desc = "Report task completion to parent"
})

vim.api.nvim_create_user_command("TaskMonitor", M.monitor_child_tasks, {
  desc = "Monitor child tasks"
})

vim.api.nvim_create_user_command("TaskReadReports", M.read_task_reports, {
  desc = "Read reports from child tasks"
})
```

### Workflow Example

1. **Parent Session** (working on main feature):
   ```
   "I need to refactor the auth module while continuing here"
   :TaskDelegate refactor authentication module
   ```

2. **Child Session** (spawned automatically):
   - New WezTerm tab opens
   - Claude sees TASK_DELEGATION.md with context
   - Works on refactoring in isolation
   - Can spawn its own subagents if needed
   - Commits changes

3. **Child Completes**:
   ```
   :TaskReportBack
   ```
   - Generates report with changes
   - Writes to parent's REPORT_BACK.md
   - Optionally returns to parent tab

4. **Parent Reviews**:
   ```
   :TaskReadReports
   ```
   - Sees summary of changes
   - Can merge with `<leader>tm`
   - Continues with main work

### Advantages of This Approach

1. **Natural Workflow**: Matches how developers think about delegating tasks
2. **Context Preservation**: Parent maintains context while child focuses
3. **Flexible Depth**: Children can spawn their own subagents
4. **Git-Native**: All coordination through git branches and files
5. **Report Trail**: Clear documentation of what was done
6. **Non-Blocking**: Parent can continue working while child completes task

### Implementation Timeline

**Week 1**: Basic delegation and report-back
- `spawn_child_task()` function
- TASK_DELEGATION.md generation
- Simple report-back mechanism

**Week 2**: Enhanced monitoring and integration
- Parent dashboard for child tasks
- Report processing and merging
- WezTerm notification system

**Week 3**: Advanced features
- Parallel child tasks
- Dependency management
- Automatic report summarization

## Next Steps

1. Review this comparison and choose your preferred approach
2. Start with the simple `spawn_subagent()` implementation
3. Test with a real multi-agent project
4. Iterate based on actual usage patterns
5. Consider packaging as a plugin once patterns stabilize

The key insight: **Start simple, stay flexible, and let complexity emerge from actual use rather than anticipated needs.**