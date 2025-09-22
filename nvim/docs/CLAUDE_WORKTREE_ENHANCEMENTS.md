# Claude Worktree Enhancements Implementation Plan

## Overview

This document outlines the remaining enhancements for the Claude Worktree integration that haven't been implemented yet. These are quality-of-life improvements that enhance the core functionality already in place.

## Enhancement 1: Telescope Session Browser

### What It Does

Provides a fuzzy-searchable interface for Claude sessions with preview and quick actions. Instead of a simple list, you get a rich Telescope picker showing session details, with the ability to switch, delete, or preview sessions.

### Benefits

- **Visual Overview**: See all sessions with branch, type, and creation date at a glance
- **Quick Actions**: Switch with `<Enter>`, delete with `<C-d>`, preview context with `<C-p>`
- **Fuzzy Search**: Find sessions by typing partial names
- **Live Preview**: See CLAUDE.md content before switching

### Implementation

```lua
-- Add to ~/.config/nvim/lua/neotex/core/claude-worktree.lua

function M.telescope_sessions()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")

  local sessions_list = {}
  for name, session in pairs(M.sessions) do
    table.insert(sessions_list, {
      name = name,
      branch = session.branch,
      worktree = session.worktree_path,
      type = session.type,
      created = session.created,
      current = name == M.current_session,
      display = string.format(
        "%s%-20s %s%-15s %s%-30s %s",
        name == M.current_session and "✓ " or "  ",
        name,
        session.type and session.type:upper() or "N/A",
        session.branch or "N/A",
        session.created or "N/A"
      )
    })
  end

  -- Sort by creation date (newest first)
  table.sort(sessions_list, function(a, b)
    return (a.created or "") > (b.created or "")
  end)

  pickers.new({}, {
    prompt_title = "Claude Sessions 🤖",
    finder = finders.new_table {
      results = sessions_list,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name .. " " .. entry.branch,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Session Context",
      define_preview = function(self, entry, status)
        local context_file = entry.value.worktree .. "/CLAUDE.md"
        if vim.fn.filereadable(context_file) == 1 then
          local lines = vim.fn.readfile(context_file)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
        else
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false,
            {"No CLAUDE.md file found", "", "Worktree: " .. entry.value.worktree})
        end
      end,
    }),
    attach_mappings = function(prompt_bufnr, map)
      -- Switch to session on Enter
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.cmd("tcd " .. selection.value.worktree)
          M.current_session = selection.value.name

          local context = selection.value.worktree .. "/CLAUDE.md"
          if vim.fn.filereadable(context) == 1 then
            vim.cmd("edit " .. context)
          end

          vim.notify("Switched to: " .. selection.value.name, vim.log.levels.INFO)
        end
      end)

      -- Delete session with Ctrl-d
      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()
        if selection then
          local confirm = vim.fn.confirm(
            "Delete session '" .. selection.value.name .. "'?",
            "&Yes\n&No", 2
          )
          if confirm == 1 then
            actions.close(prompt_bufnr)
            M.delete_session_by_name(selection.value.name)
          end
        end
      end)

      -- Open in new tab with Ctrl-t
      map("i", "<C-t>", function()
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          vim.cmd("tabnew")
          vim.cmd("tcd " .. selection.value.worktree)
          local context = selection.value.worktree .. "/CLAUDE.md"
          if vim.fn.filereadable(context) == 1 then
            vim.cmd("edit " .. context)
          end
        end
      end)

      return true
    end,
  }):find()
end

-- Helper function to delete by name
function M.delete_session_by_name(name)
  local session = M.sessions[name]
  if not session then
    vim.notify("Session not found: " .. name, vim.log.levels.WARN)
    return
  end

  -- Remove worktree
  local result = vim.fn.system("git worktree remove " .. session.worktree_path .. " --force")

  if vim.v.shell_error == 0 then
    M.sessions[name] = nil
    if M.current_session == name then
      M.current_session = nil
    end
    M.save_sessions()
    vim.notify("Deleted session: " .. name, vim.log.levels.INFO)
  else
    vim.notify("Failed to remove worktree: " .. result, vim.log.levels.ERROR)
  end
end

-- Register the command
vim.api.nvim_create_user_command("ClaudeSessions", M.telescope_sessions, {
  desc = "Browse Claude sessions with Telescope"
})
```

### Keymap Addition

```lua
-- Add to which-key.lua
{ "<leader>aS", "<cmd>ClaudeSessions<CR>", desc = "sessions telescope", icon = "🔭" },
```

## Enhancement 2: Statusline Component

### What It Does

Shows the current Claude session name and type in your statusline/lualine, giving you constant visual feedback about which worktree context you're in.

### Benefits

- **Always Visible**: Know which session you're in without running commands
- **Context Awareness**: See session type (feature/bugfix/refactor) at a glance
- **Non-Intrusive**: Small addition to existing statusline

### Implementation

```lua
-- Create ~/.config/nvim/lua/neotex/util/claude-status.lua

local M = {}

function M.get_session_status()
  local ok, claude = pcall(require, "neotex.core.claude-worktree")
  if not ok or not claude.current_session then
    return ""
  end

  local session = claude.sessions[claude.current_session]
  if not session then
    return ""
  end

  -- Format: 🤖 feature:auth or 🐛 bugfix:login
  local icon = ({
    feature = "🚀",
    bugfix = "🐛",
    refactor = "🔧",
    experiment = "🧪",
    hotfix = "🔥"
  })[session.type] or "🤖"

  return string.format("%s %s:%s",
    icon,
    session.type and session.type:sub(1,3) or "ses",
    claude.current_session
  )
end

-- For lualine users
function M.lualine_component()
  return {
    M.get_session_status,
    cond = function()
      local ok, claude = pcall(require, "neotex.core.claude-worktree")
      return ok and claude.current_session ~= nil
    end,
    color = { fg = "#61afef", gui = "bold" },
  }
end

return M
```

### Lualine Integration

```lua
-- Add to your lualine config
local claude_status = require("neotex.util.claude-status")

require('lualine').setup({
  sections = {
    lualine_c = {
      'filename',
      claude_status.lualine_component(),  -- Add this
    },
    -- or in lualine_x for right side
    lualine_x = {
      claude_status.lualine_component(),
      'encoding',
      'fileformat',
      'filetype'
    },
  }
})
```

## Enhancement 3: Session Health Check & Auto-Recovery

### What It Does

Automatically validates sessions on startup, removes stale entries, and can recover sessions from existing worktrees that weren't properly tracked.

### Benefits

- **Self-Healing**: Automatically fixes broken session references
- **Discovery**: Finds existing worktrees and creates sessions for them
- **Validation**: Ensures all sessions point to valid worktrees

### Implementation

```lua
-- Add to ~/.config/nvim/lua/neotex/core/claude-worktree.lua

function M.health_check()
  local issues = {}
  local fixed = 0

  -- Check each session
  for name, session in pairs(M.sessions) do
    if not session.worktree_path or
       vim.fn.isdirectory(session.worktree_path) == 0 then
      table.insert(issues, {
        session = name,
        issue = "Worktree missing",
        action = "removed"
      })
      M.sessions[name] = nil
      fixed = fixed + 1
    end
  end

  -- Discover untracked worktrees
  local worktrees = vim.fn.systemlist("git worktree list --porcelain")
  local tracked_paths = {}
  for _, session in pairs(M.sessions) do
    tracked_paths[session.worktree_path] = true
  end

  local discovered = 0
  for i = 1, #worktrees, 3 do
    local path = worktrees[i]:match("^worktree (.+)")
    local branch = worktrees[i + 2]:match("^branch (.+)")

    if path and branch and not tracked_paths[path] then
      -- Skip the main worktree
      if not branch:match("^refs/heads/main$") and
         not branch:match("^refs/heads/master$") then

        -- Extract feature name from branch
        local feature = branch:match("/([^/]+)$") or branch
        local type = branch:match("^refs/heads/(%w+)/") or "feature"

        -- Create session for discovered worktree
        M.sessions[feature] = {
          worktree_path = path,
          branch = branch:gsub("^refs/heads/", ""),
          type = type,
          created = "recovered",
          discovered = true
        }
        discovered = discovered + 1

        table.insert(issues, {
          session = feature,
          issue = "Untracked worktree",
          action = "recovered"
        })
      end
    end
  end

  -- Save if changes were made
  if fixed > 0 or discovered > 0 then
    M.save_sessions()
  end

  -- Report results
  if #issues > 0 then
    vim.notify(string.format(
      "Session Health Check:\n" ..
      "- Fixed: %d stale sessions\n" ..
      "- Discovered: %d worktrees\n" ..
      "Run :ClaudeSessionHealth for details",
      fixed, discovered
    ), vim.log.levels.INFO)
  end

  return issues
end

-- Detailed health report
function M.health_report()
  local issues = M.health_check()

  if #issues == 0 then
    vim.notify("All Claude sessions are healthy!", vim.log.levels.INFO)
    return
  end

  local lines = {"Claude Session Health Report", "=" .. string.rep("=", 40), ""}

  for _, issue in ipairs(issues) do
    table.insert(lines, string.format(
      "• %s: %s → %s",
      issue.session,
      issue.issue,
      issue.action
    ))
  end

  -- Create a floating window with the report
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 50
  local height = math.min(#lines + 2, 20)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " Health Check ",
    title_pos = "center",
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { silent = true })
end

-- Auto-run health check on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      if vim.fn.isdirectory(".git") == 1 then
        M.health_check()
      end
    end, 2000)  -- Run after 2 seconds
  end,
})

-- Register command
vim.api.nvim_create_user_command("ClaudeSessionHealth", M.health_report, {
  desc = "Show Claude session health report"
})
```

### Keymap Addition

```lua
-- Add to which-key.lua
{ "<leader>aH", "<cmd>ClaudeSessionHealth<CR>", desc = "health check", icon = "🏥" },
```

## Enhancement 4: Quick Session Switcher (Numbered)

### What It Does

Allows instant switching between sessions using number keys, similar to buffer/tab switching. Your 3 most recent sessions get numbers 1-3.

### Benefits

- **Speed**: Switch sessions with `<leader>1`, `<leader>2`, `<leader>3`
- **Muscle Memory**: Similar to existing buffer switching patterns
- **Visual Feedback**: Shows numbers in session list

### Implementation

```lua
-- Add to ~/.config/nvim/lua/neotex/core/claude-worktree.lua

function M.get_recent_sessions(limit)
  limit = limit or 3
  local sorted = {}

  for name, session in pairs(M.sessions) do
    table.insert(sorted, {
      name = name,
      session = session,
      created = session.created or "0"
    })
  end

  table.sort(sorted, function(a, b)
    return a.created > b.created
  end)

  -- Take only the first 'limit' sessions
  local recent = {}
  for i = 1, math.min(limit, #sorted) do
    recent[i] = sorted[i]
  end

  return recent
end

function M.quick_switch(number)
  local recent = M.get_recent_sessions()
  local target = recent[number]

  if not target then
    vim.notify("No session #" .. number, vim.log.levels.WARN)
    return
  end

  -- Switch to the session
  vim.cmd("tcd " .. target.session.worktree_path)
  M.current_session = target.name

  local context = target.session.worktree_path .. "/CLAUDE.md"
  if vim.fn.filereadable(context) == 1 then
    vim.cmd("edit " .. context)
  end

  vim.notify(string.format(
    "Switched to #%d: %s",
    number,
    target.name
  ), vim.log.levels.INFO)
end

-- Override list_sessions to show numbers
local original_list_sessions = M.list_sessions
function M.list_sessions()
  if vim.tbl_count(M.sessions) == 0 then
    vim.notify("No active Claude sessions", vim.log.levels.INFO)
    return
  end

  local recent = M.get_recent_sessions()
  local recent_names = {}
  for i, r in ipairs(recent) do
    recent_names[r.name] = i
  end

  print("\nActive Claude Sessions:")
  print(string.rep("-", 80))
  print(string.format("%-3s %-20s %-20s %-15s %-20s", "#", "Name", "Branch", "Type", "Created"))
  print(string.rep("-", 80))

  for name, session in pairs(M.sessions) do
    local number = recent_names[name] and string.format("%d", recent_names[name]) or " "
    local marker = name == M.current_session and " ←" or ""

    print(string.format(
      "%-3s %-20s %-20s %-15s %-20s%s",
      number,
      name,
      session.branch or "N/A",
      session.type or "N/A",
      session.created or "N/A",
      marker
    ))
  end

  print(string.rep("-", 80))
  print(string.format("Total: %d session(s)", vim.tbl_count(M.sessions)))
  print("\nQuick switch: <leader>1-3 for recent sessions")
end
```

### Keymap Addition

```lua
-- Add to which-key.lua (in the main mappings section, not in groups)
{ "<leader>1", function() require("neotex.core.claude-worktree").quick_switch(1) end, desc = "session #1" },
{ "<leader>2", function() require("neotex.core.claude-worktree").quick_switch(2) end, desc = "session #2" },
{ "<leader>3", function() require("neotex.core.claude-worktree").quick_switch(3) end, desc = "session #3" },
```

## Implementation Priority

1. **High Priority** (Do First):
   - Enhancement 3: Health Check & Auto-Recovery - Prevents data loss and confusion
   - Enhancement 1: Telescope Session Browser - Most useful daily feature

2. **Medium Priority**:
   - Enhancement 2: Statusline Component - Nice visual feedback

3. **Low Priority**:
   - Enhancement 4: Quick Session Switcher - Convenience feature

## Testing Each Enhancement

### Test Telescope Browser

```vim
:ClaudeSessions
" Should show rich picker with preview
" Try: Search, switch, delete operations
```

### Test Statusline

```vim
:ClaudeSession
" Check statusline shows current session
" Switch sessions and verify update
```

### Test Health Check

```vim
" Create a worktree manually
git worktree add ../test-worktree -b test/branch

" Restart Neovim
" Should auto-discover the worktree

:ClaudeSessionHealth
" Should show health report
```

### Test Quick Switcher

```vim
:ClaudeSessionList
" Note the numbers

<leader>1
" Should switch to session #1

<leader>2
" Should switch to session #2
```

## Summary

These enhancements transform the basic Claude Worktree system into a polished, production-ready workflow. The Telescope browser and health check are essential for daily use, while the statusline and quick switcher add professional polish.

Total implementation time: ~2-3 hours for all enhancements.
