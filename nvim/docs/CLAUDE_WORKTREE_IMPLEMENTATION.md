# Claude Code + Git Worktree: Detailed Implementation Plan

## Executive Summary

This document provides a concrete, step-by-step implementation plan for integrating git-worktree.nvim and wezterm.nvim with your existing Neovim setup (claude-code.nvim + toggleterm.nvim) to enable parallel Claude Code development across isolated git worktrees.

## Current State Analysis

### Existing Plugins (Already Working)

1. **claude-code.nvim** (`<C-c>` keybinding)
   - 40% vertical split sidebar
   - Auto-refresh on file changes
   - Git root awareness

2. **toggleterm.nvim** (`<C-t>` keybinding)
   - Vertical terminal (80 columns)
   - Fish shell configured
   - Persistent across sessions disabled

### Plugins to Add

3. **git-worktree.nvim** - Worktree management with Telescope
4. **wezterm.nvim** - Programmatic tab control

## Implementation Plan

### Phase 1: Plugin Installation (Day 1)

#### Step 1.1: Install git-worktree.nvim

Create file: `~/.config/nvim/lua/neotex/plugins/git/worktree.lua`

```lua
return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = { 
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim" 
  },
  keys = {
    { "<leader>hw", "<cmd>Telescope git_worktree<cr>", desc = "Switch worktree" },
    { "<leader>hW", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "Create worktree" },
  },
  config = function()
    local Worktree = require("git-worktree")
    
    -- Configure worktree behavior
    Worktree.setup({
      change_directory_command = "tcd",  -- Tab-local directory change
      update_on_change = true,           -- Update NvimTree/neo-tree
      update_on_change_command = "e .",  -- Refresh explorer
      clearjumps_on_change = true,       -- Clear jump list on switch
      autopush = false,                  -- Don't auto-push branches
    })
    
    -- Load Telescope extension
    require("telescope").load_extension("git_worktree")
    
    -- Hook: Auto-create CLAUDE.md on new worktree
    Worktree.on_tree_change(function(op, metadata)
      if op == Worktree.Operations.Create then
        local context_file = metadata.path .. "/CLAUDE.md"
        if vim.fn.filereadable(context_file) == 0 then
          -- Parse branch type and name
          local branch = metadata.branch
          local type = branch:match("^(%w+)/") or "feature"
          local name = branch:match("/(.+)$") or branch
          
          -- Create context content
          local content = {
            "# Task: " .. name,
            "",
            "## Metadata",
            "- **Type**: " .. type,
            "- **Branch**: " .. branch,
            "- **Created**: " .. os.date("%Y-%m-%d %H:%M"),
            "- **Worktree**: " .. metadata.path,
            "",
            "## Objective",
            "[Describe the main goal of this work]",
            "",
            "## Context",
            "- Parent project: " .. metadata.upstream,
            "- Working in isolated worktree",
            "",
            "## Acceptance Criteria",
            "- [ ] Implementation complete",
            "- [ ] Tests passing",
            "- [ ] Documentation updated",
            "",
            "## Notes",
            "[Any relevant notes or links]",
          }
          
          vim.fn.writefile(content, context_file)
          vim.notify("Created context file: CLAUDE.md", vim.log.levels.INFO)
        end
      end
    end)
  end,
}
```

#### Step 1.2: Install wezterm.nvim

Create file: `~/.config/nvim/lua/neotex/plugins/terminal/wezterm-integration.lua`

```lua
return {
  "willothy/wezterm.nvim",
  config = function()
    require("wezterm").setup({
      create_commands = false,  -- We'll create our own commands
    })
  end,
  keys = {
    { 
      "<leader>hT", 
      function() 
        local wezterm = require("wezterm")
        local count = vim.v.count
        if count > 0 then
          wezterm.switch_tab.index(count)
        else
          vim.notify("Use count to specify tab (e.g., 2<leader>hT for tab 2)")
        end
      end, 
      desc = "Switch to WezTerm tab N" 
    },
  },
}
```

#### Step 1.3: Test Basic Functionality

After installing plugins, test:

```vim
" 1. Reload Neovim config
:Lazy sync

" 2. Test worktree creation
<leader>hW
" Enter: feature/test-worktree

" 3. Verify CLAUDE.md was created
:e ../project-feature-test-worktree/CLAUDE.md

" 4. Test switching worktrees
<leader>hw
```

### Phase 2: Core Module Development (Day 2-3)

#### Step 2.1: Create Claude-Worktree Orchestrator

Create file: `~/.config/nvim/lua/neotex/core/claude-worktree.lua`

```lua
-- Claude Code + Git Worktree Integration Module
local M = {}

-- Dependencies
local has_wezterm, wezterm = pcall(require, "wezterm")
local has_worktree, worktree = pcall(require, "git-worktree")

-- Configuration
M.config = {
  -- Worktree naming patterns
  types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
  default_type = "feature",
  
  -- Session management
  max_sessions = 4,
  auto_switch_tab = true,
  create_context_file = true,
  
  -- Context file template
  context_template = [[
# Task: %s

## Metadata
- **Type**: %s
- **Branch**: %s
- **Created**: %s
- **Worktree**: %s
- **Session ID**: %s

## Objective
[Describe the main goal]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on %s in the %s worktree. The goal is to..."

## Notes
[Add any relevant context, links, or decisions]
]],
}

-- Session state tracking
M.sessions = {}  -- { feature_name = { tab_id, worktree_path, branch, created } }
M.current_session = nil

-- Initialize module
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  
  -- Check dependencies
  if not has_wezterm then
    vim.notify("wezterm.nvim not found. Tab management disabled.", vim.log.levels.WARN)
  end
  if not has_worktree then
    vim.notify("git-worktree.nvim not found. Worktree features disabled.", vim.log.levels.ERROR)
    return
  end
  
  -- Create commands
  M._create_commands()
  
  -- Create keymaps
  M._create_keymaps()
  
  -- Restore sessions if any saved
  M.restore_sessions()
  
  vim.notify("Claude-Worktree integration loaded", vim.log.levels.INFO)
end

-- Helper: Generate worktree path
function M._generate_worktree_path(feature, type)
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return string.format("../%s-%s-%s", project, type, feature)
end

-- Helper: Generate branch name
function M._generate_branch_name(feature, type)
  return string.format("%s/%s", type, feature)
end

-- Helper: Create context file
function M._create_context_file(worktree_path, feature, type, branch, session_id)
  if not M.config.create_context_file then
    return nil
  end
  
  local context_file = worktree_path .. "/CLAUDE.md"
  local content = string.format(
    M.config.context_template,
    feature,
    type,
    branch,
    os.date("%Y-%m-%d %H:%M"),
    worktree_path,
    session_id or "N/A",
    feature,
    branch
  )
  
  vim.fn.writefile(vim.split(content, "\n"), context_file)
  return context_file
end

-- Core: Create worktree with Claude session
function M.create_worktree_with_claude()
  -- Get feature name
  local feature = vim.fn.input("Feature name: ")
  if feature == "" then 
    vim.notify("Cancelled", vim.log.levels.WARN)
    return 
  end
  
  -- Get type
  vim.ui.select(M.config.types, {
    prompt = "Select type:",
    format_item = function(item)
      return item:sub(1,1):upper() .. item:sub(2)
    end,
  }, function(type)
    if not type then 
      vim.notify("Cancelled", vim.log.levels.WARN)
      return 
    end
    
    local worktree_path = M._generate_worktree_path(feature, type)
    local branch = M._generate_branch_name(feature, type)
    
    -- Check if worktree already exists
    local existing = vim.fn.system("git worktree list | grep " .. branch)
    if existing ~= "" then
      vim.notify("Worktree already exists: " .. branch, vim.log.levels.ERROR)
      return
    end
    
    -- Create worktree
    vim.notify("Creating worktree: " .. worktree_path, vim.log.levels.INFO)
    local result = vim.fn.system("git worktree add " .. worktree_path .. " -b " .. branch)
    
    if vim.v.shell_error ~= 0 then
      vim.notify("Failed to create worktree: " .. result, vim.log.levels.ERROR)
      return
    end
    
    -- Generate session ID
    local session_id = string.format("%s-%d", feature, os.time())
    
    -- Create context file
    local context_file = M._create_context_file(
      worktree_path, feature, type, branch, session_id
    )
    
    -- Create WezTerm tab if available
    if has_wezterm then
      M._spawn_wezterm_tab(worktree_path, feature, session_id, context_file)
    else
      -- Fallback: switch to worktree in current Neovim
      vim.cmd("tcd " .. worktree_path)
      if context_file then
        vim.cmd("edit " .. context_file)
      end
      vim.notify("Switched to worktree: " .. feature, vim.log.levels.INFO)
    end
    
    -- Store session
    M.sessions[feature] = {
      worktree_path = worktree_path,
      branch = branch,
      type = type,
      session_id = session_id,
      created = os.date("%Y-%m-%d %H:%M"),
      tab_id = nil,  -- Will be set by _spawn_wezterm_tab
    }
    
    M.current_session = feature
    M.save_sessions()
  end)
end

-- WezTerm: Spawn new tab for worktree
function M._spawn_wezterm_tab(worktree_path, feature, session_id, context_file)
  if not has_wezterm then
    return
  end
  
  -- Method 1: Try wezterm.nvim spawn_tab
  local ok, result = pcall(function()
    return wezterm.spawn_tab({
      cwd = worktree_path,
      args = context_file and { "nvim", "CLAUDE.md" } or { "nvim" },
    })
  end)
  
  if not ok then
    -- Method 2: Fallback to CLI
    local cmd = string.format(
      "wezterm cli spawn --cwd '%s' -- nvim %s",
      worktree_path,
      context_file and "CLAUDE.md" or ""
    )
    
    result = vim.fn.system(cmd)
    
    -- Extract tab ID from output
    local tab_id = result:match("tab_id%s*:%s*(%d+)") or 
                   result:match("(%d+)")
    
    if tab_id then
      M.sessions[feature].tab_id = tab_id
      
      if M.config.auto_switch_tab then
        -- Switch to the new tab
        vim.fn.system("wezterm cli activate-tab --tab-id " .. tab_id)
      end
      
      vim.notify(
        string.format("Created Claude session '%s' in WezTerm tab %s", feature, tab_id),
        vim.log.levels.INFO
      )
    else
      vim.notify("Created worktree but couldn't spawn WezTerm tab", vim.log.levels.WARN)
    end
  end
end

-- Switch to existing Claude session
function M.switch_session()
  if vim.tbl_count(M.sessions) == 0 then
    vim.notify("No active Claude sessions", vim.log.levels.INFO)
    return
  end
  
  local items = {}
  for name, session in pairs(M.sessions) do
    table.insert(items, {
      name = name,
      display = string.format(
        "%s%-20s %s [%s]",
        name == M.current_session and "* " or "  ",
        name,
        session.branch,
        session.created
      ),
      session = session,
    })
  end
  
  -- Sort by creation time
  table.sort(items, function(a, b)
    return a.session.created > b.session.created
  end)
  
  vim.ui.select(items, {
    prompt = "Select Claude session:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then
      -- Switch directory
      vim.cmd("tcd " .. choice.session.worktree_path)
      
      -- Open CLAUDE.md if exists
      local context_file = choice.session.worktree_path .. "/CLAUDE.md"
      if vim.fn.filereadable(context_file) == 1 then
        vim.cmd("edit " .. context_file)
      end
      
      -- Switch WezTerm tab if available
      if has_wezterm and choice.session.tab_id then
        local ok = pcall(function()
          wezterm.switch_tab.id(choice.session.tab_id)
        end)
        
        if not ok then
          -- Fallback to CLI
          vim.fn.system("wezterm cli activate-tab --tab-id " .. choice.session.tab_id)
        end
      end
      
      M.current_session = choice.name
      vim.notify("Switched to session: " .. choice.name, vim.log.levels.INFO)
    end
  end)
end

-- List all active sessions
function M.list_sessions()
  if vim.tbl_count(M.sessions) == 0 then
    vim.notify("No active Claude sessions", vim.log.levels.INFO)
    return
  end
  
  print("\nActive Claude Sessions:")
  print(string.rep("-", 80))
  print(string.format("%-20s %-20s %-15s %-20s", "Name", "Branch", "Type", "Created"))
  print(string.rep("-", 80))
  
  for name, session in pairs(M.sessions) do
    local marker = name == M.current_session and " *" or ""
    print(string.format(
      "%-20s %-20s %-15s %-20s%s",
      name,
      session.branch,
      session.type,
      session.created,
      marker
    ))
  end
  
  print(string.rep("-", 80))
  print(string.format("Total: %d session(s)", vim.tbl_count(M.sessions)))
  
  if has_wezterm then
    local tab_count = 0
    for _, session in pairs(M.sessions) do
      if session.tab_id then tab_count = tab_count + 1 end
    end
    print(string.format("WezTerm tabs: %d", tab_count))
  end
end

-- Delete a session
function M.delete_session()
  if vim.tbl_count(M.sessions) == 0 then
    vim.notify("No sessions to delete", vim.log.levels.WARN)
    return
  end
  
  local items = {}
  for name, session in pairs(M.sessions) do
    table.insert(items, {
      name = name,
      display = string.format("%s (%s)", name, session.branch),
      session = session,
    })
  end
  
  vim.ui.select(items, {
    prompt = "Delete session:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then
      local confirm = vim.fn.confirm(
        string.format("Delete session '%s' and remove worktree?", choice.name),
        "&Yes\n&No",
        2
      )
      
      if confirm == 1 then
        -- Remove worktree
        local result = vim.fn.system("git worktree remove " .. choice.session.worktree_path .. " --force")
        
        if vim.v.shell_error == 0 then
          -- Close WezTerm tab if exists
          if has_wezterm and choice.session.tab_id then
            vim.fn.system("wezterm cli kill-pane --tab-id " .. choice.session.tab_id)
          end
          
          -- Remove from sessions
          M.sessions[choice.name] = nil
          
          if M.current_session == choice.name then
            M.current_session = nil
          end
          
          M.save_sessions()
          vim.notify("Deleted session: " .. choice.name, vim.log.levels.INFO)
        else
          vim.notify("Failed to remove worktree: " .. result, vim.log.levels.ERROR)
        end
      end
    end
  end)
end

-- Quick terminal in current worktree
function M.open_terminal()
  -- Use existing toggleterm
  vim.cmd("ToggleTerm direction=vertical")
end

-- Open Claude in current context
function M.open_claude()
  -- Use existing claude-code.nvim
  vim.cmd("ClaudeCode")
end

-- Session persistence: Save
function M.save_sessions()
  local data = vim.fn.json_encode(M.sessions)
  local file = vim.fn.stdpath("data") .. "/claude-worktree-sessions.json"
  vim.fn.writefile({data}, file)
end

-- Session persistence: Restore
function M.restore_sessions()
  local file = vim.fn.stdpath("data") .. "/claude-worktree-sessions.json"
  if vim.fn.filereadable(file) == 1 then
    local data = vim.fn.readfile(file)
    if #data > 0 then
      local ok, sessions = pcall(vim.fn.json_decode, data[1])
      if ok then
        M.sessions = sessions
        vim.notify(
          string.format("Restored %d Claude session(s)", vim.tbl_count(sessions)),
          vim.log.levels.INFO
        )
      end
    end
  end
end

-- Clean up stale sessions
function M.cleanup_sessions()
  local cleaned = 0
  for name, session in pairs(M.sessions) do
    -- Check if worktree still exists
    local exists = vim.fn.system("test -d " .. session.worktree_path .. " && echo 1 || echo 0")
    if vim.trim(exists) == "0" then
      M.sessions[name] = nil
      cleaned = cleaned + 1
    end
  end
  
  if cleaned > 0 then
    M.save_sessions()
    vim.notify(string.format("Cleaned up %d stale session(s)", cleaned), vim.log.levels.INFO)
  end
end

-- Create commands
function M._create_commands()
  vim.api.nvim_create_user_command("ClaudeWorktree", M.create_worktree_with_claude, {
    desc = "Create worktree with Claude session"
  })
  
  vim.api.nvim_create_user_command("ClaudeSession", M.switch_session, {
    desc = "Switch Claude session"
  })
  
  vim.api.nvim_create_user_command("ClaudeSessionList", M.list_sessions, {
    desc = "List Claude sessions"
  })
  
  vim.api.nvim_create_user_command("ClaudeSessionDelete", M.delete_session, {
    desc = "Delete Claude session"
  })
  
  vim.api.nvim_create_user_command("ClaudeSessionCleanup", M.cleanup_sessions, {
    desc = "Clean up stale sessions"
  })
end

-- Create keymaps
function M._create_keymaps()
  local keymap = vim.keymap.set
  
  -- Main operations
  keymap("n", "<leader>ht", M.create_worktree_with_claude, 
    { desc = "Create worktree with Claude" })
  keymap("n", "<leader>hs", M.switch_session, 
    { desc = "Switch Claude session" })
  keymap("n", "<leader>hl", M.list_sessions, 
    { desc = "List Claude sessions" })
  keymap("n", "<leader>hd", M.delete_session, 
    { desc = "Delete Claude session" })
  
  -- Quick access
  keymap("n", "<leader>hc", M.open_claude, 
    { desc = "Open Claude (current context)" })
  keymap("n", "<leader>hT", M.open_terminal, 
    { desc = "Open terminal (toggleterm)" })
end

return M
```

#### Step 2.2: Initialize the Module

Add to your Neovim init file or create: `~/.config/nvim/lua/neotex/config/claude-init.lua`

```lua
return {
  setup = function()
    -- Load claude-worktree module
    local claude_worktree = require("neotex.core.claude-worktree")
    
    claude_worktree.setup({
      -- Customize options
      max_sessions = 4,
      auto_switch_tab = true,
      create_context_file = true,
      
      -- Customize types if needed
      types = { "feature", "bugfix", "refactor", "experiment", "hotfix" },
      default_type = "feature",
    })
    
    -- Optional: Clean up on startup
    vim.defer_fn(function()
      claude_worktree.cleanup_sessions()
    end, 1000)
  end
}
```

### Phase 3: Integration & Testing (Day 4)

#### Step 3.1: Add Telescope Integration

Enhance the worktree picker with session info:

```lua
-- Add to claude-worktree.lua

function M.telescope_sessions()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  
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
        "%s%-20s %s%-30s %s",
        name == M.current_session and "> " or "  ",
        name,
        session.type:upper(),
        session.branch,
        session.created
      )
    })
  end
  
  pickers.new({}, {
    prompt_title = "Claude Sessions",
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
    attach_mappings = function(prompt_bufnr, map)
      -- Select action: switch to session
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.cmd("tcd " .. selection.value.worktree)
          M.current_session = selection.value.name
          
          -- Open CLAUDE.md
          local context = selection.value.worktree .. "/CLAUDE.md"
          if vim.fn.filereadable(context) == 1 then
            vim.cmd("edit " .. context)
          end
          
          vim.notify("Switched to: " .. selection.value.name)
        end
      end)
      
      -- Delete action
      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()
        if selection then
          actions.close(prompt_bufnr)
          M.delete_session_by_name(selection.value.name)
        end
      end)
      
      return true
    end,
  }):find()
end

-- Add command
vim.api.nvim_create_user_command("ClaudeSessions", M.telescope_sessions, {
  desc = "Browse Claude sessions with Telescope"
})
```

#### Step 3.2: Add Status Line Component

```lua
-- Add to your lualine config or statusline

local function claude_session_status()
  local ok, claude = pcall(require, "neotex.core.claude-worktree")
  if not ok or not claude.current_session then
    return ""
  end
  
  local session = claude.sessions[claude.current_session]
  if session then
    return string.format(" Claude: %s (%s)", 
      claude.current_session, 
      session.type:sub(1,3):upper()
    )
  end
  
  return ""
end

-- Add to lualine sections
sections = {
  lualine_c = { claude_session_status },
}
```

### Phase 4: Workflow Optimization (Day 5)

#### Step 4.1: Quick Actions

Add these helper functions to `claude-worktree.lua`:

```lua
-- Quick create feature
function M.quick_feature()
  local name = vim.fn.input("Feature name: ")
  if name ~= "" then
    M._quick_create(name, "feature")
  end
end

-- Quick create bugfix
function M.quick_bugfix()
  local name = vim.fn.input("Bugfix name: ")
  if name ~= "" then
    M._quick_create(name, "bugfix")
  end
end

-- Helper for quick creates
function M._quick_create(name, type)
  local worktree_path = M._generate_worktree_path(name, type)
  local branch = M._generate_branch_name(name, type)
  
  -- Create worktree
  local result = vim.fn.system("git worktree add " .. worktree_path .. " -b " .. branch)
  
  if vim.v.shell_error == 0 then
    -- Create context
    M._create_context_file(worktree_path, name, type, branch, name .. "-" .. os.time())
    
    -- Spawn tab
    if has_wezterm then
      M._spawn_wezterm_tab(worktree_path, name, name .. "-" .. os.time(), 
        worktree_path .. "/CLAUDE.md")
    end
    
    -- Store session
    M.sessions[name] = {
      worktree_path = worktree_path,
      branch = branch,
      type = type,
      created = os.date("%Y-%m-%d %H:%M"),
    }
    
    M.current_session = name
    M.save_sessions()
    
    vim.notify("Created " .. type .. ": " .. name, vim.log.levels.INFO)
  end
end

-- Add keymaps
vim.keymap.set("n", "<leader>hf", M.quick_feature, { desc = "Quick feature worktree" })
vim.keymap.set("n", "<leader>hb", M.quick_bugfix, { desc = "Quick bugfix worktree" })
```

#### Step 4.2: Which-Key Integration

If using which-key.nvim:

```lua
local which_key = require("which-key")

which_key.register({
  ["<leader>h"] = {
    name = "+AI/Claude",
    
    -- Core Claude operations
    c = { "<cmd>ClaudeCode<cr>", "Claude sidebar" },
    C = { "<cmd>ClaudeCodeContinue<cr>", "Continue Claude" },
    r = { "<cmd>ClaudeCodeResume<cr>", "Resume Claude" },
    
    -- Worktree operations
    w = { "<cmd>Telescope git_worktree<cr>", "Switch worktree" },
    W = { "<cmd>Telescope git_worktree create_git_worktree<cr>", "Create worktree" },
    
    -- Session management
    t = { "<cmd>ClaudeWorktree<cr>", "Create worktree + Claude" },
    s = { "<cmd>ClaudeSession<cr>", "Switch Claude session" },
    l = { "<cmd>ClaudeSessionList<cr>", "List sessions" },
    d = { "<cmd>ClaudeSessionDelete<cr>", "Delete session" },
    
    -- Quick creates
    f = { "<cmd>lua require('neotex.core.claude-worktree').quick_feature()<cr>", "Quick feature" },
    b = { "<cmd>lua require('neotex.core.claude-worktree').quick_bugfix()<cr>", "Quick bugfix" },
    
    -- Terminal
    T = { "<cmd>ToggleTerm direction=vertical<cr>", "Terminal" },
  },
})
```

## Testing Protocol

### Test 1: Basic Worktree Creation
```vim
:ClaudeWorktree
" Enter: test-feature
" Select: feature
" Verify: CLAUDE.md created
" Verify: WezTerm tab opened (if available)
```

### Test 2: Session Management
```vim
:ClaudeSessionList
" Should show test-feature

:ClaudeSession
" Select test-feature
" Should switch to worktree
```

### Test 3: Multiple Sessions
```vim
" Create 3 different worktrees
:ClaudeWorktree  " feature1
:ClaudeWorktree  " feature2
:ClaudeWorktree  " bugfix1

:ClaudeSessionList
" Should show all 3 sessions
```

### Test 4: Persistence
```vim
" Create sessions
" Restart Neovim
:ClaudeSessionList
" Sessions should persist
```

## Troubleshooting Guide

### Issue: WezTerm tab creation fails

```lua
-- Check WezTerm is running
:!pgrep wezterm

-- Check CLI is available
:!wezterm cli list

-- Try manual tab creation
:!wezterm cli spawn --cwd /tmp -- nvim
```

### Issue: Worktree creation fails

```bash
# Check git version (needs 2.5+)
git --version

# Check current worktrees
git worktree list

# Clean up locked worktrees
git worktree prune
```

### Issue: Sessions not persisting

```vim
" Check data directory
:echo stdpath("data")

" Check session file
:!cat ~/.local/share/nvim/claude-worktree-sessions.json

" Manually save
:lua require("neotex.core.claude-worktree").save_sessions()
```

## Performance Optimization

### Lazy Loading

```lua
-- Only load module when needed
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(function()
      if vim.fn.isdirectory(".git") == 1 then
        require("neotex.config.claude-init").setup()
      end
    end, 100)
  end,
})
```

### Resource Management

```lua
-- Limit concurrent sessions
if vim.tbl_count(M.sessions) >= M.config.max_sessions then
  vim.notify("Maximum sessions reached. Please close one first.", vim.log.levels.WARN)
  return
end
```

## Complete Workflow Example

```vim
" 1. Start your day - check existing sessions
:ClaudeSessionList

" 2. Create new feature worktree
<leader>hf
> user-authentication

" 3. WezTerm opens new tab with CLAUDE.md
" Edit CLAUDE.md to add context

" 4. Start Claude
<C-c>  " Opens Claude sidebar
"Implement JWT authentication as described in CLAUDE.md"

" 5. Quick terminal for tests
<C-t>  " Opens toggleterm
npm test

" 6. Create another worktree for parallel work
<leader>hf
> payment-integration

" 7. Switch between sessions
<leader>hs  " Pick from list
" or
2<leader>hT  " Jump to WezTerm tab 2

" 8. End of day - review all sessions
:ClaudeSessionList

" 9. Clean up completed work
<leader>hd
> Select finished feature
```

## Success Metrics

- [ ] Can create worktree with single command
- [ ] CLAUDE.md files auto-generated with context
- [ ] Sessions persist across Neovim restarts
- [ ] Can switch between 3+ sessions seamlessly
- [ ] WezTerm tabs properly associated with worktrees
- [ ] No performance impact on startup
- [ ] Clean up removes both worktree and tab

## Next Steps

1. **Immediate**: Install plugins and test basic functionality
2. **Day 1-2**: Implement core module
3. **Day 3-4**: Add Telescope and status line integration
4. **Week 1**: Refine workflow based on actual usage
5. **Ongoing**: Add custom features as needed

This implementation provides a complete, production-ready solution for managing multiple Claude Code sessions across git worktrees, fully integrated with your existing Neovim setup.