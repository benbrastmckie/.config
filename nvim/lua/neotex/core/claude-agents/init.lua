-----------------------------------------------------------
-- Claude Task Delegation System
--
-- Extends claude-worktree.lua with hierarchical task delegation
-- capabilities, allowing Claude sessions to spawn child tasks
-- in isolated worktrees with WezTerm tab management
-----------------------------------------------------------

local M = {}

-- Import existing claude-worktree module
local worktree_base = require("neotex.core.claude-worktree")

-- Inherit all base functionality
setmetatable(M, { __index = worktree_base })

-- Simple in-memory state (resets on restart)
M.active_tasks = {}

-- Task delegation specific configuration
M.config = {
  auto_start_claude = true,
  report_file_name = "REPORT_BACK.md",
  delegation_file_name = "TASK_DELEGATION.md",
  context_file_name = "CLAUDE.md",
  preferred_transport = "wezterm",

  -- Terminal settings
  terminal = {
    set_tab_title = true,
    use_branch_name = true,
    title_prefix = "",
    strip_task_prefix = true,
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

-- Initialize the module
function M.setup(opts)
  -- Initialize base worktree functionality first
  worktree_base.setup(opts)

  if opts and opts.task_delegation then
    M.config = vim.tbl_deep_extend("force", M.config, opts.task_delegation)
  end

  M._create_commands()
  M._create_keymaps()

  vim.notify("Claude Task Delegation system loaded", vim.log.levels.INFO)
end

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
  if M.config.auto_start_claude then
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

-- Create delegation files in child worktree
function M._create_delegation_files(worktree_path, config)
  -- Create TASK_DELEGATION.md
  local delegation_content = M._generate_delegation_content(config)
  local delegation_file = worktree_path .. "/" .. M.config.delegation_file_name
  vim.fn.writefile(vim.split(delegation_content, "\n"), delegation_file)

  -- Create CLAUDE.md
  local claude_content = M._generate_claude_content(config)
  local claude_file = worktree_path .. "/" .. M.config.context_file_name
  vim.fn.writefile(vim.split(claude_content, "\n"), claude_file)

  -- Copy context files if specified
  if config.context_files then
    M._copy_context_files(worktree_path, config.context_files)
  end
end

-- Generate TASK_DELEGATION.md content
function M._generate_delegation_content(config)
  local report_path = config.parent.path .. "/" .. M.config.report_file_name

  return string.format([[# Task Delegation

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
- Report should include summary, changes, and any issues]],
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
  return string.format([[# Claude Task Session

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

Remember: The parent session is waiting for your report. Work efficiently but thoroughly.]],
    config.task,
    config.child_name,
    config.parent.branch,
    config.parent.path,
    os.date("%Y-%m-%d %H:%M:%S")
  )
end

-- Copy context files to child worktree
function M._copy_context_files(worktree_path, context_files)
  for _, file in ipairs(context_files) do
    if vim.fn.filereadable(file) == 1 then
      local dest = worktree_path .. "/" .. vim.fn.fnamemodify(file, ":t")
      local copy_cmd = string.format("cp '%s' '%s'", file, dest)
      vim.fn.system(copy_cmd)
    end
  end
end

-- Track delegation in parent session
function M._track_delegation(parent_id, delegation_info)
  if not M.active_tasks[parent_id] then
    M.active_tasks[parent_id] = {}
  end
  table.insert(M.active_tasks[parent_id], delegation_info)
end

-- Update delegation with tab ID
function M._update_delegation_tab(parent_id, child_name, tab_id)
  if M.active_tasks[parent_id] then
    for _, task in ipairs(M.active_tasks[parent_id]) do
      if task.name == child_name then
        task.tab_id = tab_id
        break
      end
    end
  end
end

-- Generate and send report back to parent
function M.task_report_back()
  -- Check if we're in a delegated task
  local delegation_file = vim.fn.getcwd() .. "/" .. M.config.delegation_file_name

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

-- Parse delegation file for task information
function M._parse_delegation_file(delegation_file)
  local content = vim.fn.readfile(delegation_file)
  local info = {}

  for _, line in ipairs(content) do
    local session_id = line:match("Session ID%*%*: (.+)")
    if session_id then info.session_id = session_id end

    local working_dir = line:match("Working Directory%*%*: (.+)")
    if working_dir then info.parent_path = working_dir end

    local branch = line:match("Parent branch: `(.+)`")
    if branch then info.parent_branch = branch end

    local report_match = line:match("Report will be written to: `(.+)`")
    if report_match then info.report_path = report_match end

    local task_match = line:match("^([^#].+)")
    if task_match and not info.task and not line:match("^%-") and not line:match("^%*%*") then
      info.task = task_match
    end

    local started_match = line:match("Started: (.+)")
    if started_match then info.started_at = started_match end
  end

  return info
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
  return string.format([[================================================================================
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

================================================================================]],
    delegation_info.task or "Unknown task",
    current_branch,
    os.date("%Y-%m-%d %H:%M:%S"),
    M._calculate_duration(delegation_info.started_at),
    commits ~= "" and commits or "No commits made",
    files_changed ~= "" and files_changed or "No files changed",
    diff_stat ~= "" and diff_stat or "No changes",
    current_branch,
    delegation_info.session_id or "Unknown",
    vim.fn.getcwd(),
    delegation_info.started_at or "Unknown"
  )
end

-- Calculate duration from start time
function M._calculate_duration(started_at)
  if not started_at then return "Unknown" end

  local start_time = os.time() -- This is a simplification
  local current_time = os.time()
  local duration = current_time - start_time

  local hours = math.floor(duration / 3600)
  local minutes = math.floor((duration % 3600) / 60)

  if hours > 0 then
    return string.format("%dh %dm", hours, minutes)
  else
    return string.format("%dm", minutes)
  end
end

-- Write report to parent directory
function M._write_report(report_path, report)
  local existing_content = ""

  -- Read existing content if file exists
  if vim.fn.filereadable(report_path) == 1 then
    existing_content = table.concat(vim.fn.readfile(report_path), "\n")
  end

  -- Append new report
  local full_content = existing_content .. "\n" .. report
  vim.fn.writefile(vim.split(full_content, "\n"), report_path)
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

-- Clean up child worktree
function M._cleanup_child_worktree(delegation_info)
  local confirm = vim.fn.confirm(
    "This will delete the current worktree. Are you sure?",
    "&Yes\n&No",
    2
  )

  if confirm == 1 then
    local current_path = vim.fn.getcwd()
    local worktree_remove_cmd = string.format("git worktree remove %s --force", current_path)
    local result = vim.fn.system(worktree_remove_cmd)

    if vim.v.shell_error == 0 then
      vim.notify("Worktree cleaned up successfully", vim.log.levels.INFO)
      -- Return to parent or close tab
      M._return_to_parent_session(delegation_info)
    else
      vim.notify("Failed to clean up worktree: " .. result, vim.log.levels.ERROR)
    end
  end
end

-- Mark task as complete (placeholder for future task tracking)
function M._mark_task_complete(delegation_info)
  -- This could be extended to update task status in a more sophisticated tracking system
end

-- Create task-specific commands
function M._create_commands()
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

  -- Monitor tasks
  vim.api.nvim_create_user_command("TaskMonitor", function()
    M.telescope_task_monitor()
  end, { desc = "Monitor active tasks" })

  -- Child commands
  vim.api.nvim_create_user_command("TaskReportBack", M.task_report_back, {
    desc = "Report task completion to parent"
  })

  vim.api.nvim_create_user_command("TaskStatus", function()
    local delegation_file = vim.fn.getcwd() .. "/" .. M.config.delegation_file_name
    if vim.fn.filereadable(delegation_file) == 1 then
      vim.cmd("edit " .. delegation_file)
    else
      vim.notify("Not in a delegated task session", vim.log.levels.WARN)
    end
  end, {
    desc = "Show current task status"
  })

  vim.api.nvim_create_user_command("TaskCancel", function()
    local delegation_file = vim.fn.getcwd() .. "/" .. M.config.delegation_file_name
    if vim.fn.filereadable(delegation_file) == 1 then
      local confirm = vim.fn.confirm(
        "Cancel current task and clean up worktree?",
        "&Yes\n&No",
        2
      )
      if confirm == 1 then
        local delegation_info = M._parse_delegation_file(delegation_file)
        if delegation_info then
          M._cleanup_child_worktree(delegation_info)
        end
      end
    else
      vim.notify("Not in a delegated task session", vim.log.levels.WARN)
    end
  end, {
    desc = "Cancel current task and cleanup"
  })
end

-- Create keymaps
function M._create_keymaps()
  local keymap = vim.keymap.set

  -- Parent keymaps
  keymap("n", "<leader>ast", function()
    vim.cmd("TaskDelegate")
  end, { desc = "Spawn child task" })

  keymap("n", "<leader>asm", function()
    vim.cmd("TaskMonitor")
  end, { desc = "Monitor active tasks" })

  -- Child keymaps (context-aware)
  keymap("n", "<leader>asb", function()
    local delegation_file = vim.fn.getcwd() .. "/" .. M.config.delegation_file_name
    if vim.fn.filereadable(delegation_file) == 1 then
      vim.cmd("TaskReportBack")
    else
      vim.notify("Not in a child task session", vim.log.levels.WARN)
    end
  end, { desc = "Report back to parent" })

  keymap("n", "<leader>ass", function()
    vim.cmd("TaskStatus")
  end, { desc = "Show task status" })

  keymap("n", "<leader>asc", function()
    vim.cmd("TaskCancel")
  end, { desc = "Cancel task" })

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

-- Get visual selection
function M._get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)

  if #lines == 0 then
    return {}
  end

  -- Handle single line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
  else
    -- Handle multi-line selection
    lines[1] = string.sub(lines[1], start_pos[3])
    lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  end

  return lines
end

-- Simple telescope picker for task monitoring
function M.telescope_task_monitor()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")

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
    previewer = previewers.new_buffer_previewer({
      title = "Task Details",
      define_preview = function(self, entry, status)
        local task = entry.value
        local claude_file = task.path .. "/CLAUDE.md"

        if vim.fn.filereadable(claude_file) == 1 then
          local lines = vim.fn.readfile(claude_file)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        else
          local info = {
            "# Task: " .. task.task,
            "",
            "**Status:** " .. task.status,
            "**Worktree:** " .. task.path,
            "**Created:** " .. (task.created_at or "Unknown"),
            "",
            "No CLAUDE.md file found."
          }
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, info)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        end
      end
    }),
    attach_mappings = function(prompt_bufnr, map)
      -- Default action: Switch to agent's WezTerm tab
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection then
          M._switch_to_task(selection.value)
        end
        actions.close(prompt_bufnr)
      end)

      -- Additional mappings
      map("i", "<C-m>", function() -- Merge task's work
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          M._merge_task_work(selection.value)
        end
      end)

      map("i", "<C-r>", function() -- Read task's report
        local selection = action_state.get_selected_entry()
        if selection then
          M._open_task_report(selection.value)
        end
      end)

      map("i", "<C-d>", function() -- Dismiss/delete task
        local selection = action_state.get_selected_entry()
        if selection then
          local confirm = vim.fn.confirm(
            string.format("Dismiss task '%s'?", selection.value.name),
            "&Yes\n&No", 2
          )
          if confirm == 1 then
            M._dismiss_task(selection.value)
            -- Refresh picker
            actions.close(prompt_bufnr)
            vim.schedule(M.telescope_task_monitor)
          end
        end
      end)

      map("i", "<C-g>", function() -- Show git diff for task
        local selection = action_state.get_selected_entry()
        if selection then
          M._show_task_git_diff(selection.value)
        end
      end)

      return true
    end
  }):find()
end

-- Get active tasks (scan for worktrees with TASK_DELEGATION.md)
function M._get_active_tasks()
  local tasks = {}

  -- Simple approach: scan for worktrees with TASK_DELEGATION.md
  local worktree_output = vim.fn.system("git worktree list")
  local worktree_list = vim.split(worktree_output, "\n")

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
            created_at = task_info.started_at or "Unknown",
            name = vim.fn.fnamemodify(path, ":t")
          })
        end
      end
    end
  end

  return tasks
end

-- Get simple task status
function M._get_task_status(task_path)
  -- Check if REPORT_BACK.md exists in parent
  local parent_path = vim.fn.fnamemodify(task_path, ":h:h") -- Go up two levels to find parent
  local report_file = parent_path .. "/REPORT_BACK.md"

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

-- Switch to task's WezTerm tab or directory
function M._switch_to_task(task)
  -- Try to find the WezTerm tab for this task
  local tabs = M._find_wezterm_tabs_by_path(task.path)

  if #tabs > 0 then
    -- Activate the tab
    local activate_cmd = string.format(
      "wezterm cli activate-tab --tab-id %s",
      tabs[1]
    )
    vim.fn.system(activate_cmd)
    vim.notify("Switched to task tab: " .. task.name, vim.log.levels.INFO)
  else
    -- Fallback: change directory in current session
    vim.cmd("cd " .. task.path)
    local claude_file = task.path .. "/CLAUDE.md"
    if vim.fn.filereadable(claude_file) == 1 then
      vim.cmd("edit " .. claude_file)
    end
    vim.notify("Switched to task directory: " .. task.name, vim.log.levels.INFO)
  end
end

-- Merge task's work into current branch
function M._merge_task_work(task)
  local confirm = vim.fn.confirm(
    string.format("Merge branch '%s'?", task.branch),
    "&Yes\n&No\n&Show diff first",
    3
  )

  if confirm == 1 then
    -- Perform merge
    local merge_cmd = string.format("git merge %s --no-edit", task.branch)
    local result = vim.fn.system(merge_cmd)

    if vim.v.shell_error == 0 then
      vim.notify(string.format("Successfully merged %s", task.branch), vim.log.levels.INFO)

      -- Offer to delete worktree
      local cleanup = vim.fn.confirm("Delete task worktree?", "&Yes\n&No", 2)
      if cleanup == 1 then
        M._cleanup_task_worktree(task)
      end
    else
      vim.notify("Merge failed: " .. result, vim.log.levels.ERROR)
    end
  elseif confirm == 3 then
    -- Show diff first
    vim.cmd(string.format("!git diff %s", task.branch))
  end
end

-- Open task's report
function M._open_task_report(task)
  local report_path = vim.fn.getcwd() .. "/" .. M.config.report_file_name

  if vim.fn.filereadable(report_path) == 1 then
    vim.cmd("tabnew " .. report_path)
    vim.cmd("setlocal filetype=markdown")
    vim.cmd("setlocal nomodifiable")
    vim.notify("Opened task reports", vim.log.levels.INFO)
  else
    vim.notify("No reports available", vim.log.levels.WARN)
  end
end

-- Dismiss/delete a task
function M._dismiss_task(task)
  local result = vim.fn.system("git worktree remove " .. task.path .. " --force")

  if vim.v.shell_error == 0 then
    vim.notify("Dismissed task: " .. task.name, vim.log.levels.INFO)
  else
    vim.notify("Failed to dismiss task: " .. result, vim.log.levels.ERROR)
  end
end

-- Show git diff for task
function M._show_task_git_diff(task)
  local parent_branch = "main" -- Could be made configurable
  vim.cmd(string.format("!cd %s && git diff %s..%s", task.path, parent_branch, task.branch))
end

-- Clean up task worktree after merge
function M._cleanup_task_worktree(task)
  local result = vim.fn.system("git worktree remove " .. task.path .. " --force")

  if vim.v.shell_error == 0 then
    vim.notify("Cleaned up worktree: " .. task.name, vim.log.levels.INFO)
  else
    vim.notify("Failed to clean up worktree: " .. result, vim.log.levels.ERROR)
  end
end

return M