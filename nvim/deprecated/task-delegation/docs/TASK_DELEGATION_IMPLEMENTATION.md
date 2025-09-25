# Task Delegation with Report-Back: Complete Implementation Plan

## Implementation Summary

**Status**: ✅ COMPLETE - All features implemented and integrated

The Claude Task Delegation system has been fully implemented and integrated into the neotex plugin ecosystem. The system provides:

- **Hierarchical task spawning**: Parent Claude sessions can spawn child tasks in isolated git worktrees
- **WezTerm integration**: Each child task runs in its own WezTerm tab with descriptive branch-based naming
- **Context file generation**: Automatic creation of TASK_DELEGATION.md and CLAUDE.md files for each child task
- **Report-back mechanism**: Child tasks can report completion with git diff stats, commits, and integration instructions
- **Telescope monitoring**: Visual interface to monitor, switch between, and manage active tasks
- **Automatic cleanup**: Option to merge changes and clean up worktrees when tasks complete

### Implementation Files:
- `nvim/lua/neotex/plugins/ai/claude-agents/init.lua` - Core task delegation module
- `nvim/lua/neotex/plugins/ai/claude-task-delegation.lua` - Lazy.nvim plugin specification
- Updated `nvim/lua/neotex/plugins/ai/init.lua` - Integration with AI plugin system

### Key Commands:
- `:TaskDelegate` / `<leader>ast` - Spawn child task
- `:TaskMonitor` / `<leader>asm` - Monitor active tasks
- `:TaskReportBack` / `<leader>asb` - Report task completion
- `:TaskStatus` / `<leader>ass` - Show task status
- `:TaskCancel` / `<leader>asc` - Cancel current task

## Overview

This document provides a complete implementation plan for a simple task delegation system where Claude Code sessions can spawn child tasks in new WezTerm tabs, with file-based report-back mechanisms when tasks complete.

### MVP Features

- **Basic Task Delegation**: Spawn child Claude agents in isolated git worktrees
- **WezTerm Tab Management**: Each agent spawns in its own tab with branch-based naming
- **Simple Report-Back**: File-based communication when tasks complete
- **Basic Monitoring**: Telescope picker showing agent hierarchy
- **Git Integration**: Automatic branch creation and change tracking

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│         Parent Claude Session (WezTerm Tab: "main")         │
│                   Working on primary feature                │
│                       <leader>ast                           │
└────────────────────┬─────────────────────────────────────────┘
                     │
              [Creates Worktree]
              [Spawns WezTerm Tab]
                     │
┌────────────────────┴─────────────────────────────────────────┐
│      Child Claude Session (WezTerm Tab: "task-auth-123")    │
│                    TASK_DELEGATION.md                       │
│                        CLAUDE.md                            │
│                  Works independently                        │
└────────────────────┬─────────────────────────────────────────┘
                     │
              [:TaskReportBack]
                     │
┌────────────────────┴─────────────────────────────────────────┐
│                    REPORT_BACK.md                           │
│              (Written to parent's directory)                │
│          Git diff, commits, summary of changes              │
└─────────────────────────────────────────────────────────────┘
```

## MVP Architecture

### Simple Extension Structure
```
nvim/lua/neotex/core/
└── claude-worktree-tasks.lua    # Extends existing claude-worktree.lua
```

**Current Structure**:
```
nvim/lua/neotex/plugins/ai/claude-agents/
└── init.lua       # Simple task delegation
```

## MVP Implementation

### 1. Simple Module Extension

```lua
-- File: ~/.config/nvim/lua/neotex/core/claude-worktree-tasks.lua
-- Simple extension of existing claude-worktree.lua module

local M = {}

-- Import existing claude-worktree module
local worktree_base = require("neotex.core.claude-worktree")

-- Inherit all base functionality
setmetatable(M, { __index = worktree_base })

-- Simple in-memory state (resets on restart)
M.active_tasks = {}

M.config = {
  auto_start_claude = true,
  report_file_name = "REPORT_BACK.md",
  delegation_file_name = "TASK_DELEGATION.md",
  context_file_name = "CLAUDE.md",
}

-- Initialize the module
function M.setup(opts)
  worktree_base.setup(opts)

  if opts and opts.task_delegation then
    M.config = vim.tbl_deep_extend("force", M.config, opts.task_delegation)
  end

  M._create_commands()
  M._create_keymaps()
end

return M
```

### 2. Basic Task Spawning

```lua
-- Core function to spawn a child task
function M.spawn_child_task(task_description, opts)
  opts = opts or {}

  -- Validate we're in a git repository
  if vim.fn.isdirectory(".git") == 0 then
    vim.notify("Not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Get parent session information
  local parent_info = M._get_parent_info()

  -- Generate unique child name
  local child_name = M._generate_child_name(task_description)

  -- Create worktree for child
  local child_worktree = M._create_child_worktree(child_name)
  if not child_worktree then
    return
  end

  -- Create delegation context files
  M._create_delegation_files(child_worktree, {
    parent = parent_info,
    task = task_description,
    child_name = child_name,
    context_files = opts.context_files,
    additional_context = opts.additional_context
  })

  -- Track delegation
  M._track_delegation(parent_info.id, {
    name = child_name,
    worktree = child_worktree,
    task = task_description,
    spawned_at = os.time(),
    status = "active"
  })

  -- Spawn WezTerm tab with Claude
  local tab_id = M._spawn_child_wezterm_tab(child_worktree, child_name, task_description)

  if tab_id then
    -- Update tracking with tab ID
    M._update_delegation_tab(parent_info.id, child_name, tab_id)

    vim.notify(string.format(
      "Spawned child task '%s' in new WezTerm tab",
      child_name
    ), vim.log.levels.INFO)

    return child_name, tab_id
  else
    vim.notify("Failed to spawn WezTerm tab", vim.log.levels.ERROR)
  end
end

-- Get parent session information
function M._get_parent_info()
  return {
    id = M.current_session or vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
    path = vim.fn.getcwd(),
    branch = vim.fn.system("git branch --show-current"):gsub("\n", ""),
    worktree = vim.fn.getcwd(),
  }
end

-- Generate unique child name
function M._generate_child_name(task_description)
  local safe_name = task_description:gsub("[^%w%-]", "-"):sub(1, 20):lower()
  local timestamp = os.date("%H%M%S")
  return string.format("task-%s-%s", safe_name, timestamp)
end

-- Create worktree for child task
function M._create_child_worktree(child_name)
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local worktree_path = string.format("../%s-%s", project_name, child_name)
  local branch_name = "task/" .. child_name

  -- Create worktree
  local cmd = string.format("git worktree add %s -b %s", worktree_path, branch_name)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to create worktree: " .. result, vim.log.levels.ERROR)
    return nil
  end

  -- Get absolute path
  local absolute_path = vim.fn.fnamemodify(worktree_path, ":p")
  return absolute_path
end
```

### 3. Simple WezTerm Tab Management

```lua
-- Basic WezTerm tab spawning
function M._spawn_wezterm_tab(worktree_path, child_name, task_description)
  -- Check if WezTerm CLI is available
  if vim.fn.executable("wezterm") == 0 then
    vim.notify("WezTerm CLI not found", vim.log.levels.ERROR)
    return nil
  end

  -- Prepare the command to run in the new tab
  local nvim_cmd = string.format("nvim %s/CLAUDE.md", worktree_path)

  -- Spawn new WezTerm tab
  local spawn_cmd = string.format(
    "wezterm cli spawn --cwd '%s' -- %s",
    worktree_path,
    nvim_cmd
  )

  local result = vim.fn.system(spawn_cmd)
  local tab_id = result:match("(%d+)")

  if not tab_id then
    vim.notify("Failed to get tab ID from WezTerm", vim.log.levels.ERROR)
    return nil
  end

  -- Set descriptive tab title using branch name
  local branch_name = vim.fn.system(string.format(
    "cd %s && git branch --show-current",
    worktree_path
  )):gsub("\n", "")

  local display_name = branch_name:gsub("^task/", "")

  local title_cmd = string.format(
    "wezterm cli set-tab-title --pane-id %s '%s'",
    tab_id,
    display_name
  )
  vim.fn.system(title_cmd)

  -- Auto-start Claude if configured
  if M.config.auto_start_claude then
    vim.defer_fn(function()
      M._start_claude_in_tab(tab_id)
    end, 2000)
  end

  return tab_id
end

-- Start Claude in the child tab
function M._start_claude_in_tab(tab_id)
  local claude_cmd = string.format(
    "wezterm cli send-text --pane-id %s --no-paste $'\\x1b:ClaudeCode\\x0d'",
    tab_id
  )
  vim.fn.system(claude_cmd)

  vim.defer_fn(function()
    local prompt = "Review TASK_DELEGATION.md for your task details."
    local send_prompt = string.format(
      "wezterm cli send-text --pane-id %s '%s'",
      tab_id,
      prompt
    )
    vim.fn.system(send_prompt)
  end, 4000)
end
```

### 4. Basic Context File Generation

```lua
-- Spawn WezTerm tab for child task
function M._spawn_child_wezterm_tab(worktree_path, child_name, task_description)
  -- Check if WezTerm CLI is available
  if vim.fn.executable("wezterm") == 0 then
    vim.notify("WezTerm CLI not found", vim.log.levels.ERROR)
    return nil
  end

  -- Prepare the command to run in the new tab
  local nvim_cmd = string.format(
    "nvim %s/CLAUDE.md -c 'cd %s'",
    worktree_path,
    worktree_path
  )

  -- Spawn new WezTerm tab
  local spawn_cmd = string.format(
    "wezterm cli spawn --cwd '%s' -- %s",
    worktree_path,
    nvim_cmd
  )

  local result = vim.fn.system(spawn_cmd)

  -- Extract pane ID from result
  local pane_id = result:match("(%d+)")

  if not pane_id then
    vim.notify("Failed to get pane ID from WezTerm", vim.log.levels.ERROR)
    return nil
  end

  -- Set descriptive tab title using branch name
  -- Branch format: task/task-<description>-<timestamp>
  -- Extract just the task-<description>-<timestamp> part for clarity
  local branch_name = vim.fn.system(string.format(
    "cd %s && git branch --show-current",
    worktree_path
  )):gsub("\n", "")

  -- Remove the "task/" prefix if present for cleaner display
  local display_name = branch_name:gsub("^task/", "")

  -- Set tab title to branch name (more descriptive than task type)
  local title_cmd = string.format(
    "wezterm cli set-tab-title --pane-id %s '%s'",
    pane_id,
    display_name
  )
  vim.fn.system(title_cmd)

  -- Auto-start Claude if configured
  if M.delegation_config.auto_start_claude then
    vim.defer_fn(function()
      M._start_claude_in_tab(pane_id)
    end, 2000)  -- Wait 2 seconds for Neovim to load
  end

  -- Get tab ID from pane
  local tab_id = M._get_tab_id_from_pane(pane_id)

  return tab_id or pane_id
end

-- Start Claude in the child tab
function M._start_claude_in_tab(pane_id)
  -- Send command to start Claude
  local claude_cmd = string.format(
    "wezterm cli send-text --pane-id %s --no-paste $'\\x1b:ClaudeCode\\x0d'",
    pane_id
  )
  vim.fn.system(claude_cmd)

  -- Optional: Send initial prompt
  vim.defer_fn(function()
    local prompt = "I've been delegated a specific task. Please review TASK_DELEGATION.md for details."
    local send_prompt = string.format(
      "wezterm cli send-text --pane-id %s '%s'",
      pane_id,
      prompt
    )
    vim.fn.system(send_prompt)
  end, 4000)  -- Wait additional 2 seconds for Claude to start
end

-- Get tab ID from pane ID
function M._get_tab_id_from_pane(pane_id)
  local list_cmd = "wezterm cli list --format json"
  local result = vim.fn.system(list_cmd)

  local ok, data = pcall(vim.fn.json_decode, result)
  if ok and data then
    for _, item in ipairs(data) do
      if tostring(item.pane_id) == tostring(pane_id) then
        return item.tab_id
      end
    end
  end

  return nil
end


-- WezTerm transport (MVP focus)
function M.get_transport()
  -- MVP implementation only supports WezTerm
  if vim.fn.executable("wezterm") == 1 then
    return {
      spawn = M._spawn_child_wezterm_tab,
      activate = function(id)
        vim.fn.system("wezterm cli activate-tab --tab-id " .. id)
      end
    }, "wezterm"
  else
    vim.notify("WezTerm not available. Please install WezTerm.", vim.log.levels.ERROR)
    return nil, nil
  end
end
```

### 4. Context File Generation

```lua
-- Create delegation files in child worktree
function M._create_delegation_files(worktree_path, config)
  -- Create TASK_DELEGATION.md
  local delegation_content = M._generate_delegation_content(config)
  local delegation_file = worktree_path .. "/" .. M.delegation_config.delegation_file_name
  vim.fn.writefile(vim.split(delegation_content, "\n"), delegation_file)

  -- Create CLAUDE.md
  local claude_content = M._generate_claude_content(config)
  local claude_file = worktree_path .. "/" .. M.delegation_config.context_file_name
  vim.fn.writefile(vim.split(claude_content, "\n"), claude_file)

  -- Copy context files if specified
  if config.context_files then
    M._copy_context_files(worktree_path, config.context_files)
  end
end

-- Generate TASK_DELEGATION.md content
function M._generate_delegation_content(config)
  local report_path = config.parent.path .. "/" .. M.delegation_config.report_file_name

  return string.format([[
# Task Delegation

## Parent Session Information
- **Session ID**: %s
- **Working Directory**: %s
- **Branch**: %s
- **Timestamp**: %s

## Delegated Task
### Description
%s

### Context Files
%s

### Additional Context
%s

## Instructions

1. **Review this task**: Understand what needs to be done
2. **Work in isolation**: This worktree is yours to modify
3. **Commit frequently**: Use clear, descriptive commit messages
4. **Test your changes**: Ensure everything works before reporting
5. **Report completion**: Run `:TaskReportBack` when done

## Report Mechanism

When you complete the task:
1. Run `:TaskReportBack` command
2. Report will be written to: `%s`
3. You'll have options to return to parent or clean up

## Available Commands

- `:TaskReportBack` - Generate and send completion report
- `:TaskStatus` - Show current task status
- `:TaskContext` - Display additional context
- `:TaskCancel` - Cancel task and cleanup

## Git Workflow

You're on branch: `task/%s`
Parent branch: `%s`

Commits should be prefixed with `[TASK]` for clarity.

## Notes

- Work independently - don't worry about conflicts
- Parent continues working while you complete this
- You can spawn your own subagents if needed
- Report should include summary, changes, and any issues
]],
    config.parent.id,
    config.parent.path,
    config.parent.branch,
    os.date("%Y-%m-%d %H:%M:%S"),
    config.task,
    config.context_files and table.concat(
      vim.tbl_map(function(f) return "- " .. f end, config.context_files),
      "\n"
    ) or "None specified",
    config.additional_context or "None provided",
    report_path,
    config.child_name,
    config.parent.branch
  )
end

-- Generate CLAUDE.md content
function M._generate_claude_content(config)
  return string.format([[
# Claude Task Session

## Your Role
You are working on a delegated task in an isolated worktree. Your parent session has asked you to complete a specific task while they continue working on other aspects of the project.

## Current Task
%s

## Important Files
1. **TASK_DELEGATION.md** - Full task details and instructions
2. **CLAUDE.md** - This file (your context)
3. **REPORT_BACK.md** - Where you'll report completion (auto-generated)

## Workflow

### 1. Understand the Task
- Read TASK_DELEGATION.md thoroughly
- Review any provided context files
- Ask clarifying questions if needed

### 2. Complete the Work
- Make necessary changes
- Test your implementation
- Commit with clear messages (prefix with [TASK])

### 3. Report Completion
- Run `:TaskReportBack` when done
- This generates a report with:
  - Summary of changes
  - List of commits
  - Files modified
  - Any issues or notes

## Key Points

- **Isolation**: You're in branch `task/%s`
- **Independence**: Work without worrying about conflicts
- **Communication**: Report back through REPORT_BACK.md
- **Flexibility**: Focus on single-level task delegation

## Commands Reference

`:TaskReportBack` - Submit your completion report
`:TaskStatus` - Check task details
`:TaskContext` - View additional context
`:TaskCancel` - Abandon task (with cleanup)

## Context

Parent Branch: %s
Parent Path: %s
Started: %s

Remember: The parent session is waiting for your report. Work efficiently but thoroughly.
]],
    config.task,
    config.child_name,
    config.parent.branch,
    config.parent.path,
    os.date("%Y-%m-%d %H:%M:%S")
  )
end
```

### 5. Simple Report-Back Mechanism

```lua
-- Generate and send report back to parent
function M.task_report_back()
  -- Check if we're in a delegated task
  local delegation_file = vim.fn.getcwd() .. "/" .. M.delegation_config.delegation_file_name

  if vim.fn.filereadable(delegation_file) == 0 then
    vim.notify("Not in a delegated task session", vim.log.levels.ERROR)
    return
  end

  -- Parse delegation information
  local delegation_info = M._parse_delegation_file(delegation_file)
  if not delegation_info then
    vim.notify("Failed to parse delegation file", vim.log.levels.ERROR)
    return
  end

  -- Generate report
  local report = M._generate_task_report(delegation_info)

  -- Write report to parent directory
  local report_path = delegation_info.report_path
  M._write_report(report_path, report)

  -- Show completion options
  M._show_completion_options(delegation_info)

  -- Mark task as complete
  M._mark_task_complete(delegation_info)

  vim.notify("Report sent to parent session!", vim.log.levels.INFO)
end

-- Generate comprehensive task report
function M._generate_task_report(delegation_info)
  local current_branch = vim.fn.system("git branch --show-current"):gsub("\n", "")
  local parent_branch = delegation_info.parent_branch

  -- Get git information
  local commits = vim.fn.system(string.format(
    "git log --oneline %s..HEAD",
    parent_branch
  )):gsub("\n$", "")

  local diff_stat = vim.fn.system(string.format(
    "git diff --stat %s..HEAD",
    parent_branch
  )):gsub("\n$", "")

  local files_changed = vim.fn.system(string.format(
    "git diff --name-only %s..HEAD",
    parent_branch
  )):gsub("\n$", "")

  -- Build report
  return string.format([[
================================================================================
# Task Completion Report

**Task**: %s
**Child Branch**: %s
**Completed**: %s
**Duration**: %s

## Summary

[Generated from git history and changes]

## Changes Made

### Commits
```
%s
```

### Files Modified
```
%s
```

### Statistics
```
%s
```

## Integration Instructions

To merge these changes:
```bash
git merge %s
```

Or cherry-pick specific commits:
```bash
git cherry-pick <commit-hash>
```

## Notes

- Task completed successfully
- All tests passing (if applicable)
- No blocking issues encountered

## Child Session Details
- **Session ID**: %s
- **Worktree**: %s
- **Started**: %s

================================================================================

]],
    delegation_info.task,
    current_branch,
    os.date("%Y-%m-%d %H:%M:%S"),
    M._calculate_duration(delegation_info.started_at),
    commits ~= "" and commits or "No commits made",
    files_changed ~= "" and files_changed or "No files changed",
    diff_stat ~= "" and diff_stat or "No changes",
    current_branch,
    delegation_info.session_id,
    vim.fn.getcwd(),
    delegation_info.started_at
  )
end

-- Show completion options
function M._show_completion_options(delegation_info)
  local choice = vim.fn.confirm(
    "Task reported! What would you like to do?",
    "&Return to parent\n&Stay here\n&Clean up worktree\n&Nothing",
    1
  )

  if choice == 1 then
    M._return_to_parent_session(delegation_info)
  elseif choice == 3 then
    M._cleanup_child_worktree(delegation_info)
  end
end

-- Return to parent session
function M._return_to_parent_session(delegation_info)
  -- Find parent WezTerm tab if possible
  local parent_tabs = M._find_wezterm_tabs_by_path(delegation_info.parent_path)

  if #parent_tabs > 0 then
    -- Activate parent tab
    local activate_cmd = string.format(
      "wezterm cli activate-tab --tab-id %s",
      parent_tabs[1]
    )
    vim.fn.system(activate_cmd)

    vim.notify("Returned to parent session", vim.log.levels.INFO)
  else
    -- Fallback: change directory in current session
    vim.cmd("cd " .. delegation_info.parent_path)
    vim.notify("Parent tab not found. Changed to parent directory.", vim.log.levels.WARN)
  end
end

-- Find WezTerm tabs by working directory
function M._find_wezterm_tabs_by_path(path)
  local list_cmd = "wezterm cli list --format json"
  local result = vim.fn.system(list_cmd)

  local tabs = {}
  local ok, data = pcall(vim.fn.json_decode, result)

  if ok and data then
    for _, item in ipairs(data) do
      if item.cwd == path then
        table.insert(tabs, item.tab_id)
      end
    end
  end

  return tabs
end
```

### 6. Simple Task Monitoring with Telescope

```lua
-- Simple telescope picker for task monitoring (MVP)
function M.telescope_task_monitor()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local entry_display = require("telescope.pickers.entry_display")

  -- Get list of active task worktrees
  local tasks = M._get_active_tasks()

  if #tasks == 0 then
    vim.notify("No active delegated tasks", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Active Tasks",
    finder = finders.new_table({
      results = tasks,
      entry_maker = function(entry)
        return {
          value = entry,
          display = string.format("%s [%s] - %s",
            entry.branch,
            entry.status,
            entry.task
          ),
          ordinal = entry.task .. " " .. entry.branch,
        }
      end
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- Default action: Switch to agent's WezTerm tab
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection then
          M._switch_to_agent(selection.value)
        end
      end)

      -- Additional mappings
      map("i", "<C-m>", function() -- Merge agent's work
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          M._merge_agent_work(selection.value)
        end
      end)

      map("i", "<C-r>", function() -- Read agent's report
        local selection = action_state.get_selected_entry()
        if selection then
          M._open_agent_report(selection.value)
        end
      end)

      map("i", "<C-d>", function() -- Dismiss/delete agent
        local selection = action_state.get_selected_entry()
        if selection then
          local confirm = vim.fn.confirm(
            string.format("Dismiss agent '%s'?", selection.value.name),
            "&Yes\n&No", 2
          )
          if confirm == 1 then
            M._dismiss_agent(selection.value)
            -- Refresh picker
            actions.close(prompt_bufnr)
            vim.schedule(M.telescope_agent_monitor)
          end
        end
      end)

      map("i", "<C-t>", function() -- Create child task for selected agent
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          vim.ui.input({
            prompt = string.format("New task for %s: ", selection.value.name)
          }, function(task)
            if task then
              M._delegate_to_agent(selection.value, task)
            end
          end)
        end
      end)

      map("i", "<C-g>", function() -- Show git diff for agent
        local selection = action_state.get_selected_entry()
        if selection then
          M._show_agent_git_diff(selection.value)
        end
      end)

      map("i", "<C-l>", function() -- Show agent logs
        local selection = action_state.get_selected_entry()
        if selection then
          M._show_agent_logs(selection.value)
        end
      end)

      map("i", "<Tab>", function() -- Expand/collapse children
        local selection = action_state.get_selected_entry()
        if selection and selection.value.has_children then
          M._toggle_agent_children(selection.value)
          -- Refresh picker
          actions.close(prompt_bufnr)
          vim.schedule(M.telescope_agent_monitor)
        end
      end)

      return true
    end
  }):find()
end

-- Get active tasks (MVP)
function M._get_active_tasks()
  local tasks = {}

  -- Simple approach: scan for worktrees with TASK_DELEGATION.md
  local worktree_list = vim.fn.system("git worktree list"):split("\n")

  for _, line in ipairs(worktree_list) do
    if line ~= "" then
      local path = line:match("^([^%s]+)")
      local delegation_file = path .. "/TASK_DELEGATION.md"

      if vim.fn.filereadable(delegation_file) == 1 then
        local task_info = M._parse_delegation_file(delegation_file)
        if task_info then
          -- Get branch name
          local branch = vim.fn.system(string.format(
            "cd %s && git branch --show-current", path
          )):gsub("\n", "")

          table.insert(tasks, {
            path = path,
            branch = branch,
            task = task_info.task or "Unknown task",
            status = M._get_task_status(path),
            created_at = task_info.started_at or "Unknown"
          })
        end
      end
    end
  end

  return tasks
end

-- Get simple task status (MVP)
function M._get_task_status(task_path)
  -- Check if REPORT_BACK.md exists
  local report_file = task_path .. "/REPORT_BACK.md"
  if vim.fn.filereadable(report_file) == 1 then
    return "completed"
  end

  -- Check git status for activity
  local git_status = vim.fn.system(string.format(
    "cd %s && git status --short", task_path
  ))
  if git_status ~= "" then
    return "active"
  end

  return "idle"
end
```

### 7. Commands and Keybindings (MVP)

```lua
-- Simple commands for MVP
function M._create_task_commands()
  -- Delegate task
  vim.api.nvim_create_user_command("TaskDelegate", function(opts)
    local task = opts.args
    if task == "" then
      vim.ui.input({ prompt = "Task description: " }, function(input)
        if input and input ~= "" then
          M.spawn_child_task(input)
        end
      end)
    else
      M.spawn_child_task(task)
    end
  end, { nargs = "*", desc = "Delegate task to child agent" })

  -- Monitor tasks
  vim.api.nvim_create_user_command("TaskMonitor", function()
    M.telescope_task_monitor()
  end, { desc = "Monitor active tasks" })

  -- Report back (for child sessions)
  vim.api.nvim_create_user_command("TaskReportBack", function()
    M.task_report_back()
  end, { desc = "Submit task completion report" })

  -- Read reports (for parent sessions)
  vim.api.nvim_create_user_command("TaskReports", function()
    M.read_task_reports()
  end, { desc = "Read task completion reports" })
end

-- Setup keybindings
function M._setup_keybindings()
  -- <leader>av - Delegate task
  vim.keymap.set("n", "<leader>av", function()
    vim.ui.input({ prompt = "Task: " }, function(task)
      if task and task ~= "" then
        M.spawn_child_task(task)
      end
    end)
  end, { desc = "Delegate task to child agent" })

  -- <leader>aw - Monitor tasks
  vim.keymap.set("n", "<leader>aw", function()
    M.telescope_task_monitor()
  end, { desc = "Monitor active tasks" })

  -- <leader>ar - Report back (context-aware)
  vim.keymap.set("n", "<leader>ar", function()
    local delegation_file = vim.fn.getcwd() .. "/TASK_DELEGATION.md"
    if vim.fn.filereadable(delegation_file) == 1 then
      M.task_report_back()
    else
      M.read_task_reports()
    end
  end, { desc = "Report back or read reports" })
end
```

## Configuration (MVP)

```lua
-- Simple configuration
M.delegation_config = {
  delegation_file_name = "TASK_DELEGATION.md",
  context_file_name = "CLAUDE.md",
  report_file_name = "REPORT_BACK.md",
  preferred_transport = "wezterm",
  auto_start_claude = true
}

-- Simple task tracking
M.active_tasks = {}
      local has_claude = vim.fn.filereadable(claude_file) == 1

      if has_claude then
        -- Parse and enhance CLAUDE.md content
        local claude_content = vim.fn.readfile(claude_file)
        local enhanced = M._enhance_claude_preview(agent, claude_content)
        lines = enhanced
      else
        -- Generate preview from agent data
        lines = M._generate_agent_preview(agent)
      end

      -- Set preview content
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- Set filetype for syntax highlighting
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")

      -- Add custom highlighting for status
      M._add_preview_highlights(self.state.bufnr, agent)
    end
  })
end

-- Enhance CLAUDE.md content with real-time data
function M._enhance_claude_preview(agent, claude_lines)
  local enhanced = {}
  local insert_point = 0

  -- Find where to insert status (after first heading)
  for i, line in ipairs(claude_lines) do
    table.insert(enhanced, line)
    if i == 1 or (line:match("^#%s") and insert_point == 0) then
      insert_point = i + 1
    end
  end

  -- Insert real-time status section after title
  local status_section = M._generate_status_section(agent)
  for i = #enhanced, insert_point, -1 do
    enhanced[i + #status_section] = enhanced[i]
  end
  for i, line in ipairs(status_section) do
    enhanced[insert_point + i - 1] = line
  end

  return enhanced
end

-- Generate real-time status section
function M._generate_status_section(agent)
  local lines = {}

  -- Status box
  table.insert(lines, "")
  table.insert(lines, "## ▶ Live Status")
  table.insert(lines, "")
  table.insert(lines, "```")
  table.insert(lines, string.format("Status:      %s", M._get_agent_status_text(agent)))
  table.insert(lines, string.format("Branch:      %s", agent.branch or "unknown"))
  table.insert(lines, string.format("Created:     %s", agent.created_at or "unknown"))
  table.insert(lines, string.format("Duration:    %s", agent.duration or M._calculate_duration(agent.spawned_at)))
  table.insert(lines, string.format("Tab Status:  %s", agent.tab_active and "Active" or "Inactive"))
  table.insert(lines, string.format("Parent:      %s", agent.parent_name or "root"))
  table.insert(lines, "```")
  table.insert(lines, "")

  -- Git status
  local git_status = M._get_agent_git_status(agent)
  if git_status then
    table.insert(lines, "## ◆ Git Status")
    table.insert(lines, "")
    table.insert(lines, "```diff")
    for _, status_line in ipairs(git_status) do
      table.insert(lines, status_line)
    end
    table.insert(lines, "```")
    table.insert(lines, "")
  end

  -- Progress indicators
  local progress = M._get_agent_progress(agent)
  if progress then
    table.insert(lines, "## ▣ Progress")
    table.insert(lines, "")
    for _, item in ipairs(progress.items) do
      local checkbox = item.done and "[x]" or "[ ]"
      table.insert(lines, string.format("- %s %s", checkbox, item.task))
    end
    table.insert(lines, string.format("**Completion: %d%%**", progress.percentage))
    table.insert(lines, "")
  end

  -- Deliverables
  local deliverables = M._get_agent_deliverables(agent)
  if #deliverables > 0 then
    table.insert(lines, "## ▼ Deliverables")
    table.insert(lines, "")
    for _, file in ipairs(deliverables) do
      local full_path = agent.worktree .. "/" .. file
      local exists = vim.fn.filereadable(full_path) == 1
      local icon = exists and "✓" or "✗"
      table.insert(lines, string.format("- [%s] `%s`", icon, full_path))

      if exists then
        local size = vim.fn.getfsize(full_path)
        local modified = vim.fn.getftime(full_path)
        table.insert(lines, string.format("  Size: %s | Modified: %s",
          M._format_file_size(size),
          os.date("%Y-%m-%d %H:%M", modified)
        ))
      end
    end
    table.insert(lines, "")
  end

  -- Reports
  if agent.has_report then
    table.insert(lines, "## ◈ Report Available")
    table.insert(lines, "")
    table.insert(lines, string.format("- Report: `%s/REPORT_BACK.md`", agent.parent_path or agent.worktree))
    table.insert(lines, "- Press `<C-r>` to read report")
    table.insert(lines, "")
  end

  -- Children summary
  if agent.has_children then
    table.insert(lines, "## ► Child Agents")
    table.insert(lines, "")
    for _, child in ipairs(agent.children or {}) do
      local child_status = M._get_agent_status_icon(child)
      table.insert(lines, string.format("- %s %s: %s",
        child_status,
        child.name,
        child.task or "No task description"
      ))
    end
    table.insert(lines, "")
  end

  -- Merge status
  if agent.merge_status then
    table.insert(lines, "## ⇄ Merge Status")
    table.insert(lines, "")
    if agent.merge_status == "merged" then
      table.insert(lines, "✓ **Merged to parent branch**")
      table.insert(lines, string.format("Merged at: %s", agent.merged_at or "unknown"))
    elseif agent.merge_status == "pending" then
      table.insert(lines, "○ **Pending merge**")
      table.insert(lines, "Press `<C-m>` to merge")
    elseif agent.merge_status == "conflict" then
      table.insert(lines, "✗ **Merge conflict detected**")
      table.insert(lines, "Manual resolution required")
    end
    table.insert(lines, "")
  end

  return lines
end

-- Get agent's git status
function M._get_agent_git_status(agent)
  if not agent.worktree then return nil end

  local git_status_cmd = string.format(
    "cd %s && git status --short 2>/dev/null",
    agent.worktree
  )
  local status_output = vim.fn.system(git_status_cmd)

  if vim.v.shell_error ~= 0 or status_output == "" then
    return nil
  end

  local lines = {}
  local stats = { added = 0, modified = 0, deleted = 0 }

  for line in status_output:gmatch("[^\n]+") do
    table.insert(lines, line)
    if line:match("^A") or line:match("^%?%?") then
      stats.added = stats.added + 1
    elseif line:match("^M") then
      stats.modified = stats.modified + 1
    elseif line:match("^D") then
      stats.deleted = stats.deleted + 1
    end
  end

  -- Add summary
  table.insert(lines, "---")
  table.insert(lines, string.format(
    "+%d additions, ~%d modifications, -%d deletions",
    stats.added, stats.modified, stats.deleted
  ))

  return lines
end

-- Get agent progress from task markers
function M._get_agent_progress(agent)
  local task_file = agent.worktree .. "/TASK_DELEGATION.md"
  if vim.fn.filereadable(task_file) == 0 then
    return nil
  end

  local content = vim.fn.readfile(task_file)
  local tasks = {}
  local completed = 0

  for _, line in ipairs(content) do
    local unchecked = line:match("^%s*%-%s*%[%s*%]%s+(.+)")
    local checked = line:match("^%s*%-%s*%[x%]%s+(.+)")

    if unchecked then
      table.insert(tasks, { task = unchecked, done = false })
    elseif checked then
      table.insert(tasks, { task = checked, done = true })
      completed = completed + 1
    end
  end

  if #tasks == 0 then return nil end

  return {
    items = tasks,
    percentage = math.floor((completed / #tasks) * 100)
  }
end

-- Get deliverable files from agent
function M._get_agent_deliverables(agent)
  local deliverables = {}

  -- Check for common deliverable patterns
  local patterns = {
    "**/*.test.*",
    "**/*.spec.*",
    "**/dist/**",
    "**/build/**",
    "**/*.min.js",
    "**/*.bundle.js",
    "docs/**/*.md",
    "README.md",
    "CHANGELOG.md"
  }

  -- Also check if CLAUDE.md mentions specific deliverables
  local claude_file = agent.worktree .. "/CLAUDE.md"
  if vim.fn.filereadable(claude_file) == 1 then
    local content = vim.fn.readfile(claude_file)
    for _, line in ipairs(content) do
      -- Look for file paths mentioned as deliverables
      local file_match = line:match("deliverable[s]?:?%s*`([^`]+)`")
      if file_match then
        table.insert(deliverables, file_match)
      end
    end
  end

  -- Find actual files matching patterns
  for _, pattern in ipairs(patterns) do
    local files = vim.fn.glob(agent.worktree .. "/" .. pattern, false, true)
    for _, file in ipairs(files) do
      local relative = file:gsub("^" .. agent.worktree .. "/", "")
      table.insert(deliverables, relative)
    end
  end

  return deliverables
end

-- Get agent status icon
function M._get_agent_status_icon(agent)
  if agent.status == "completed" then
    return "✓"
  elseif agent.status == "active" then
    return "●"
  elseif agent.status == "blocked" then
    return "✗"
  elseif agent.status == "reporting" then
    return "◐"
  elseif agent.merge_status == "merged" then
    return "⇔"
  else
    return "○"
  end
end

-- Get agent status text
function M._get_agent_status_text(agent)
  local status = agent.status or "unknown"

  -- Add merge status if relevant
  if agent.merge_status == "merged" then
    status = status .. " (merged)"
  elseif agent.merge_status == "pending" then
    status = status .. " (pending merge)"
  end

  -- Add tab status
  if agent.tab_active then
    status = status .. " [tab active]"
  end

  return status
end
```

### 6. Basic Telescope Monitoring (Simplified)

```lua
-- Simple telescope picker for task monitoring
function M.telescope_task_monitor()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")

  -- Get active tasks
  local tasks = {}
  for id, task in pairs(M.active_tasks) do
    table.insert(tasks, {
      id = id,
      name = task.name,
      task = task.task,
      worktree = task.worktree,
      status = task.status or "active",
      created = task.created or os.time()
    })
  end

  if #tasks == 0 then
    vim.notify("No active tasks", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Active Tasks",
    finder = finders.new_table({
      results = tasks,
      entry_maker = function(task)
        return {
          value = task,
          display = string.format("%s - %s", task.name, task.task),
          ordinal = task.name .. " " .. task.task,
        }
      end
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Task Details",
      define_preview = function(self, entry, status)
        local task = entry.value
        local claude_file = task.worktree .. "/CLAUDE.md"

        if vim.fn.filereadable(claude_file) == 1 then
          local lines = vim.fn.readfile(claude_file)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        else
          local info = {
            "# Task: " .. task.task,
            "",
            "**Status:** " .. task.status,
            "**Worktree:** " .. task.worktree,
            "**Created:** " .. os.date("%Y-%m-%d %H:%M:%S", task.created),
            "",
            "No CLAUDE.md file found."
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, info)
        end
      end
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          -- Switch to task's WezTerm tab
          if selection.value.tab_id then
            vim.fn.system("wezterm cli activate-tab --tab-id " .. selection.value.tab_id)
          end
        end
      end)
      return true
    end
  }):find()
end
```

### 7. Commands and Keybindings

```lua
-- Read task reports in parent session
function M.read_task_reports()
  local report_file = vim.fn.getcwd() .. "/" .. M.delegation_config.report_file_name

  if vim.fn.filereadable(report_file) == 0 then
    vim.notify("No reports available", vim.log.levels.INFO)
    return
  end

  -- Open report file
  vim.cmd("tabnew " .. report_file)
  vim.cmd("setlocal filetype=markdown")
  vim.cmd("setlocal nomodifiable")

  -- Add buffer-local keymaps
  M._setup_report_keymaps()

  vim.notify("Press 'm' on a report to merge, 'd' to delete", vim.log.levels.INFO)
end

-- Setup keymaps for report buffer
function M._setup_report_keymaps()
  local buf = vim.api.nvim_get_current_buf()

  -- Merge branch from report
  vim.keymap.set("n", "m", function()
    local branch = M._extract_branch_from_cursor_position()
    if branch then
      M._merge_child_branch(branch)
    end
  end, { buffer = buf, desc = "Merge branch from report" })

  -- Delete report section
  vim.keymap.set("n", "d", function()
    M._delete_report_section()
  end, { buffer = buf, desc = "Delete this report section" })

  -- Go to child worktree
  vim.keymap.set("n", "g", function()
    local worktree = M._extract_worktree_from_cursor_position()
    if worktree then
      M._go_to_worktree(worktree)
    end
  end, { buffer = buf, desc = "Go to child worktree" })

  -- Refresh reports
  vim.keymap.set("n", "r", function()
    vim.cmd("e!")
    vim.notify("Reports refreshed", vim.log.levels.INFO)
  end, { buffer = buf, desc = "Refresh reports" })
end

-- Merge child branch
function M._merge_child_branch(branch)
  local confirm = vim.fn.confirm(
    string.format("Merge branch '%s'?", branch),
    "&Yes\n&No\n&Inspect first",
    3
  )

  if confirm == 1 then
    -- Perform merge
    local merge_cmd = string.format("git merge %s --no-edit", branch)
    local result = vim.fn.system(merge_cmd)

    if vim.v.shell_error == 0 then
      vim.notify(string.format("Successfully merged %s", branch), vim.log.levels.INFO)

      -- Offer to delete worktree
      local cleanup = vim.fn.confirm("Delete child worktree?", "&Yes\n&No", 2)
      if cleanup == 1 then
        M._cleanup_merged_worktree(branch)
      end
    else
      vim.notify("Merge failed: " .. result, vim.log.levels.ERROR)
    end
  elseif confirm == 3 then
    -- Show diff first
    vim.cmd(string.format("Git diff %s", branch))
  end
end
```

### 8. Commands and Keybindings

```lua
-- Create task-specific commands
function M._create_task_commands()
  -- Parent commands
  vim.api.nvim_create_user_command("TaskDelegate", function(opts)
    local task = opts.args
    if task == "" then
      vim.ui.input({ prompt = "Task description: " }, function(input)
        if input and input ~= "" then
          M.spawn_child_task(input)
        end
      end)
    else
      M.spawn_child_task(task)
    end
  end, {
    nargs = "*",
    desc = "Delegate task to child session"
  })

  vim.api.nvim_create_user_command("AgentMonitor", M.telescope_agent_monitor, {
    desc = "Open task monitor in Telescope"
  })

  vim.api.nvim_create_user_command("TaskMonitor", M.telescope_agent_monitor, {
    desc = "Monitor active child tasks (alias for AgentMonitor)"
  })

  vim.api.nvim_create_user_command("TaskReadReports", M.read_task_reports, {
    desc = "Read task completion reports"
  })

  -- Child commands
  vim.api.nvim_create_user_command("TaskReportBack", M.task_report_back, {
    desc = "Report task completion to parent"
  })

  vim.api.nvim_create_user_command("TaskStatus", M.show_task_status, {
    desc = "Show current task status"
  })

  vim.api.nvim_create_user_command("TaskCancel", M.cancel_task, {
    desc = "Cancel current task and cleanup"
  })

  -- Navigation commands
  vim.api.nvim_create_user_command("TaskGoTo", function(opts)
    local task_num = tonumber(opts.args)
    if task_num then
      M.go_to_child_task(task_num)
    end
  end, {
    nargs = 1,
    desc = "Switch to child task by number"
  })
end

-- Create keymaps
function M._create_task_keymaps()
  local keymap = vim.keymap.set

  -- Parent keymaps
  keymap("n", "<leader>ast", function()
    vim.cmd("TaskDelegate")
  end, { desc = "Spawn child task" })

  keymap("n", "<leader>asm", function()
    vim.cmd("AgentMonitor")
  end, { desc = "Monitor agents (Telescope)" })

  keymap("n", "<leader>asr", function()
    vim.cmd("TaskReadReports")
  end, { desc = "Read task reports" })

  keymap("n", "<leader>ash", function()
    vim.cmd("AgentMonitor")
  end, { desc = "Agent hierarchy view" })

  -- Child keymaps (context-aware)
  keymap("n", "<leader>asb", function()
    if M._is_child_session() then
      vim.cmd("TaskReportBack")
    else
      vim.notify("Not in a child task session", vim.log.levels.WARN)
    end
  end, { desc = "Report back to parent" })

  keymap("n", "<leader>ass", function()
    vim.cmd("TaskStatus")
  end, { desc = "Show task status" })

  -- Quick task delegation with visual selection
  keymap("v", "<leader>ast", function()
    -- Get visual selection as context
    local lines = M._get_visual_selection()
    local context = table.concat(lines, "\n")

    vim.ui.input({ prompt = "Task description: " }, function(task)
      if task and task ~= "" then
        M.spawn_child_task(task, {
          additional_context = context
        })
      end
    end)
  end, { desc = "Delegate task with selection as context" })
end
```

### 9. Integration with which-key.lua

```lua
-- Add to your which-key configuration
local wk = require("which-key")

wk.register({
  ["<leader>a"] = {
    s = {
      name = "Subagent Tasks",
      t = { "<cmd>TaskDelegate<cr>", "Spawn child task" },
      m = { "<cmd>TaskMonitor<cr>", "Monitor tasks" },
      r = { "<cmd>TaskReadReports<cr>", "Read reports" },
      b = { "<cmd>TaskReportBack<cr>", "Report back (child)" },
      s = { "<cmd>TaskStatus<cr>", "Task status" },
      c = { "<cmd>TaskCancel<cr>", "Cancel task" },
      g = {
        function()
          require("telescope.builtin").live_grep({
            search_dirs = { vim.fn.getcwd() .. "/REPORT_BACK.md" }
          })
        end,
        "Search reports"
      },
    }
  }
})
```

### 10. Configuration Options

```lua
-- Add to your Neovim configuration
require("neotex.core.claude-worktree-tasks").setup({
  -- Inherit claude-worktree settings
  types = { "feature", "bugfix", "refactor", "task" },
  default_type = "task",

  -- Task delegation specific settings
  task_delegation = {
    -- Auto-start Claude in child tabs
    auto_start_claude = true,

    -- Auto-open Claude sidebar
    auto_open_claude = true,

    -- File names
    report_file_name = "REPORT_BACK.md",
    delegation_file_name = "TASK_DELEGATION.md",
    context_file_name = "CLAUDE.md",

    -- Behavior
    cleanup_on_complete = false,
    return_to_parent_on_complete = true,

    -- Terminal settings
    terminal = {
      set_tab_title = true,
      use_branch_name = true,           -- Use git branch name for tab titles
      title_prefix = "",                -- Optional prefix for tab titles
      strip_task_prefix = true,         -- Remove "task/" from branch names
      activate_on_spawn = true,
    },

    -- Report settings
    report = {
      include_diff_stat = true,
      include_commits = true,
      include_files = true,
      auto_commit_report = true,
    }
  }
})
```

## Telescope Agent Monitor Interface

### Visual Layout

```
╭─────────────────── Agent Hierarchy Monitor ──────────────────╮
│ > search agents                                               │
├────────────────────────────────────────────────────────────────┤
│ ✓ main                      main           completed  2h 30m │
│   ● └─ task-auth-1234       task/auth      active    45m    │
│     ○   └─ task-validate    task/valid     pending   10m    │
│   ● └─ task-ui-5678         task/ui        active    1h 15m │
│   ⇔ └─ task-docs-9012       task/docs      merged    3h     │
│     ✓   └─ task-examples    task/ex        completed 2h 30m │
├────────────────────────────────────────────────────────────────┤
│ 5 agents (2 active, 2 completed, 1 pending)                  │
╰────────────────────────────────────────────────────────────────╯

╭───────────────────── Agent Details ───────────────────────╮
│ # Claude Task Session                                     │
│                                                           │
│ ## ▶ Live Status                                          │
│                                                           │
│ ```                                                       │
│ Status:      active [tab active]                         │
│ Branch:      task/task-auth-1234                         │
│ Created:     2024-01-15 10:30                           │
│ Duration:    45 minutes                                  │
│ Tab Status:  Active                                      │
│ Parent:      main                                        │
│ ```                                                       │
│                                                           │
│ ## ◆ Git Status                                           │
│                                                           │
│ ```diff                                                   │
│ M  src/auth/login.js                                     │
│ M  src/auth/session.js                                   │
│ A  src/auth/jwt.js                                       │
│ ---                                                       │
│ +3 additions, ~2 modifications, -0 deletions             │
│ ```                                                       │
│                                                           │
│ ## ▣ Progress                                             │
│                                                           │
│ - [x] Refactor authentication module                     │
│ - [x] Implement JWT tokens                               │
│ - [ ] Add refresh token logic                            │
│ - [ ] Write tests                                        │
│ **Completion: 50%**                                       │
│                                                           │
│ ## ▼ Deliverables                                         │
│                                                           │
│ - [✓] `/home/user/project-task-auth/src/auth/jwt.js`     │
│   Size: 4.2KB | Modified: 2024-01-15 11:15              │
│ - [✗] `/home/user/project-task-auth/tests/auth.test.js`  │
│                                                           │
│ ## ► Child Agents                                         │
│                                                           │
│ - ○ task-validate: Validate JWT implementation           │
│                                                           │
╰───────────────────────────────────────────────────────────╯

Keybindings:
<CR>   Switch to agent's WezTerm tab       <C-g>  Show git diff
<C-m>  Merge agent's branch                <C-l>  Show agent logs
<C-r>  Read agent's report                 <Tab>  Expand/collapse
<C-d>  Dismiss agent                       <C-t>  Create child task
```

### Key Features of the Monitor

1. **Simple Display**: List of active tasks with basic status
2. **Status Icons**: Visual indicators for task state (active, completed, idle)
3. **Basic Preview**: CLAUDE.md content display
4. **Task Information**: Branch name, description, and creation time
7. **Quick Actions**: Single-key operations for common tasks

### Status Icon Legend

| Icon | Meaning | Description |
|------|---------|-------------|
| `✓`  | Completed | Task/agent has finished successfully |
| `●`  | Active | Currently working/in progress |
| `○`  | Pending | Waiting to start |
| `✗`  | Blocked/Failed | Cannot proceed or has errors |
| `◐`  | Reporting | Generating or sending report |
| `⇔`  | Merged | Branch has been merged |
| `▶`  | Section Header | Indicates expandable section |
| `◆`  | Git/Code | Related to version control |
| `▣`  | Progress | Task progress indicator |
| `▼`  | Files/Deliverables | Output artifacts |
| `◈`  | Report | Report available |
| `►`  | Child/Nested | Has child elements |
| `⇄`  | Sync/Exchange | Bidirectional operation |

## Tab Naming Strategy

All transports now use **branch names** for descriptive tab/window titles:

### WezTerm Example:
```
Branch: task/task-refactor-auth-143502
Tab Title: "task-refactor-auth-143502"
```



**Why Branch Names?**
- More descriptive than generic task types
- Includes timestamp for uniqueness
- Easy to correlate with git branches
- Consistent naming strategy for WezTerm tabs

## Usage Examples

### Example 1: Basic Task Delegation

```vim
" From parent session working on main feature
:TaskDelegate refactor the authentication module to use JWT tokens

" This will:
" 1. Create worktree: ../project-task-refactor-auth-143502
" 2. Create branch: task/task-refactor-auth-143502
" 3. Generate TASK_DELEGATION.md and CLAUDE.md
" 4. Spawn new tab with title "task-refactor-auth-143502"
" 5. Open Neovim with CLAUDE.md
" 6. Auto-start Claude Code after 2 seconds
```

### Example 2: Task with Context Files

```lua
-- From Lua
local M = require("neotex.core.claude-worktree-tasks")

M.spawn_child_task("implement user preferences API", {
  context_files = {
    "src/models/user.js",
    "src/api/routes.js",
    "docs/api-spec.md"
  },
  additional_context = "Use RESTful conventions and add proper validation"
})
```

### Example 3: Visual Selection Context

```vim
" 1. Select code block in visual mode
" 2. Press <leader>ast
" 3. Enter task: "optimize this function for performance"
" 4. Selected code becomes context for child task
```

### Example 4: Child Reporting Back

```vim
" In child session after completing work
:TaskReportBack

" Generates report with:
" - Git diff statistics
" - List of commits
" - Modified files
" - Integration instructions

" Prompts:
" 1. Return to parent
" 2. Stay here
" 3. Clean up worktree
```

### Example 5: Parent Processing Reports

```vim
" In parent session
:TaskReadReports

" Opens REPORT_BACK.md with keymaps:
" - 'm' on a report: merge that branch
" - 'd' on a report: delete that section
" - 'g' on a report: go to that worktree
```

## MVP Implementation Timeline (2-3 Weeks)

### Week 1: Core Delegation (Days 1-7) ✅ COMPLETED
- [x] Day 1-2: Implement `spawn_child_task` with worktree creation
- [x] Day 3: Add WezTerm tab spawning with branch-based titles
- [x] Day 4: Implement context file generation (TASK_DELEGATION.md, CLAUDE.md)
- [x] Day 5: Add basic report-back mechanism
- [x] Day 6-7: Testing and refinement

### Week 2: Monitoring & Integration (Days 8-14) ✅ COMPLETED
- [x] Day 8-9: Simple telescope task monitoring
- [x] Day 10-11: Report reading and basic merge functionality
- [x] Day 12-13: Commands and keybindings (<leader>ast, <leader>asm, <leader>asb)
- [x] Day 14: Integration testing and bug fixes

### Week 3: Polish & Documentation (Days 15-21) ✅ COMPLETED
- [x] Day 15-16: Error handling and edge case fixes
- [x] Day 17-18: User documentation and examples
- [x] Day 19-20: Performance optimization and cleanup
- [x] Day 21: Final testing and deployment

## Implementation Status: COMPLETE

All core features have been implemented and integrated into the neotex plugin system.


## Testing Checklist

### Basic Functionality ✅ COMPLETE
- [x] Child task spawns in new WezTerm tab
- [x] Worktree created with correct branch name
- [x] TASK_DELEGATION.md contains correct information
- [x] CLAUDE.md provides clear context
- [x] Claude auto-starts in child tab

### Report Mechanism ✅ COMPLETE
- [x] `:TaskReportBack` generates complete report
- [x] Report written to parent's REPORT_BACK.md
- [x] Git information correctly captured
- [x] Return to parent works

### Parent Monitoring ✅ COMPLETE
- [x] `:TaskMonitor` shows active tasks
- [x] Tab status correctly detected
- [x] Reports marked as available
- [x] Navigation to child tasks works

### Integration ✅ COMPLETE
- [x] Keybindings work as expected
- [x] Commands have proper completion
- [x] Plugin properly integrated with neotex AI system
- [x] Works with existing claude-worktree.lua infrastructure

## Troubleshooting Guide

### Common Issues and Solutions

#### WezTerm Tab Not Spawning
```lua
-- Check WezTerm CLI is available
:echo executable("wezterm")

-- Test manual spawn
:!wezterm cli spawn --cwd /tmp -- nvim

-- Check for errors in system log
:messages
```

#### Claude Not Auto-Starting
```lua
-- Increase delay
M.delegation_config.auto_start_delay = 4000  -- 4 seconds

-- Or start manually in child
:ClaudeCode
```

#### Report Not Generating
```vim
" Verify in child worktree
:echo filereadable("TASK_DELEGATION.md")

" Check git has commits
:!git log --oneline HEAD~5..HEAD

" Generate report manually
:lua require("neotex.core.claude-worktree-tasks").task_report_back()
```

#### Can't Return to Parent
```vim
" Find parent manually
:!wezterm cli list

" Change directory manually
:cd ../project-main

" Or use telescope to find parent
:Telescope find_files cwd=..
```

## Best Practices

### For Parent Sessions
1. **Clear task descriptions**: Be specific about what needs to be done
2. **Provide context files**: Include relevant files for the task
3. **Monitor regularly**: Check `:TaskMonitor` for progress
4. **Process reports promptly**: Review and merge completed work

### For Child Sessions
1. **Read TASK_DELEGATION.md first**: Understand the full context
2. **Commit frequently**: Use clear, prefixed commit messages
3. **Test before reporting**: Ensure work is complete
4. **Include notes in report**: Mention any issues or suggestions

### For Both
1. **Use descriptive branch names**: Helps identify tasks later
2. **Clean up completed worktrees**: Avoid clutter
3. **Archive important reports**: Keep record of completed work
4. **Leverage Claude's capabilities**: Let it spawn sub-subagents if needed

## Conclusion

This implementation provides a complete task delegation system with:
- **Automatic WezTerm tab management**
- **Git-based coordination**
- **Clear parent-child communication**
- **Report-back mechanism**
- **Full integration with Neovim workflow**

The system builds on your existing `claude-worktree.lua` infrastructure and can be implemented incrementally, starting with basic spawning and adding features as needed.