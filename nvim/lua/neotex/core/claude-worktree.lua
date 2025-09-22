-----------------------------------------------------------
-- Claude Code + Git Worktree Integration Module
--
-- Orchestrates git worktrees with Claude Code sessions,
-- managing parallel development across isolated branches
-- with WezTerm tab integration
-----------------------------------------------------------

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
  
  -- Restore sessions and sync with git
  M.restore_sessions()
  
  -- Always sync with actual git worktrees on startup
  vim.defer_fn(function()
    M.sync_with_git_worktrees()
  end, 500)
  
  -- Only notify if debug mode is enabled
  local notify = require('neotex.util.notifications')
  if notify.config.debug_mode then
    vim.notify("Claude-Worktree integration loaded", vim.log.levels.INFO)
  end
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
    
    -- Store session BEFORE spawning tab (needed by _spawn_wezterm_tab)
    M.sessions[feature] = {
      worktree_path = worktree_path,
      branch = branch,
      type = type,
      session_id = session_id,
      created = os.date("%Y-%m-%d %H:%M"),
      tab_id = nil,  -- Will be set by _spawn_wezterm_tab
    }
    
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
    
    M.current_session = feature
    M.save_sessions()
  end)
end

-- WezTerm: Spawn new tab for worktree
function M._spawn_wezterm_tab(worktree_path, feature, session_id, context_file)
  if not has_wezterm then
    return
  end
  
  -- Use WezTerm CLI to spawn tab
  local cmd = string.format(
    "wezterm cli spawn --cwd '%s' -- nvim %s",
    worktree_path,
    context_file and "CLAUDE.md" or ""
  )
  
  local result = vim.fn.system(cmd)
  
  -- Extract tab ID from output (WezTerm CLI typically outputs the pane id)
  local pane_id = result:match("(%d+)")
  
  if pane_id then
    -- Get tab ID from pane
    local tab_info = vim.fn.system("wezterm cli list --format json")
    local ok, tabs = pcall(vim.fn.json_decode, tab_info)
    
    if ok and tabs then
      for _, tab in ipairs(tabs) do
        if tostring(tab.pane_id) == pane_id then
          M.sessions[feature].tab_id = tab.tab_id
          break
        end
      end
    end
    
    if M.config.auto_switch_tab and pane_id then
      -- Activate the new pane
      vim.fn.system("wezterm cli activate-pane --pane-id " .. pane_id)
    end
    
    vim.notify(
      string.format("Created Claude session '%s' in new WezTerm tab", feature),
      vim.log.levels.INFO
    )
  else
    vim.notify("Created worktree but couldn't spawn WezTerm tab", vim.log.levels.WARN)
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
        -- Try to activate tab
        local result = vim.fn.system("wezterm cli activate-tab --tab-id " .. choice.session.tab_id)
        if vim.v.shell_error ~= 0 then
          vim.notify("Could not switch WezTerm tab", vim.log.levels.WARN)
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
  local cleaned_names = {}
  
  for name, session in pairs(M.sessions) do
    -- Check if worktree still exists
    local exists = vim.fn.system("test -d " .. session.worktree_path .. " && echo 1 || echo 0")
    if vim.trim(exists) == "0" then
      M.sessions[name] = nil
      cleaned = cleaned + 1
      table.insert(cleaned_names, string.format("%s (%s)", name, session.branch or "unknown"))
    end
  end
  
  if cleaned > 0 then
    M.save_sessions()
    -- Detailed notification following NOTIFICATIONS.md standards
    if cleaned == 1 then
      vim.notify(
        string.format("Removed stale session: %s", cleaned_names[1]), 
        vim.log.levels.INFO
      )
    else
      vim.notify(
        string.format("Removed %d stale sessions:\n%s", 
          cleaned, 
          table.concat(cleaned_names, "\n")), 
        vim.log.levels.INFO
      )
    end
  else
    -- User-initiated action should always provide feedback
    vim.notify("No stale sessions to clean up", vim.log.levels.INFO)
  end
end

-- Telescope session browser with preview
function M.telescope_sessions()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  
  -- Always sync with git worktrees to ensure we have the latest
  M.sync_with_git_worktrees()
  
  local sessions_list = {}
  
  -- Check if we have any sessions after discovery
  if vim.tbl_count(M.sessions) == 0 then
    -- No sessions found even after discovery
    vim.notify("No Claude sessions found. Press <leader>aw to create one.", vim.log.levels.INFO)
    return
  end
  
  -- Get current directory to detect which session is active
  local current_path = vim.fn.getcwd()
  
  -- Get all worktrees including main to show everything
  local worktree_output = vim.fn.system("git worktree list")
  local main_branch = nil
  
  if vim.v.shell_error == 0 then
    for line in worktree_output:gmatch("[^\n]+") do
      local path = line:match("^([^%s]+)")
      local branch = line:match("%[(.+)%]")
      
      -- Find the main/master branch
      if path and branch and not branch:match("/") then
        main_branch = {
          path = path,
          branch = branch,
          is_main = true
        }
        break
      end
    end
  end
  
  -- Add main/master branch first if found
  if main_branch then
    local is_current = main_branch.path == current_path
    table.insert(sessions_list, {
      name = "main",
      branch = main_branch.branch,
      worktree = main_branch.path,
      type = nil,
      created = nil,
      is_current = is_current,
      is_main = true,
      display = string.format(
        "%s%-40s %s",
        is_current and "* " or "  ",
        vim.fn.fnamemodify(main_branch.path, ":t"),
        main_branch.branch
      )
    })
  end
  
  -- Add Claude sessions
  for name, session in pairs(M.sessions) do
    local is_current = session.worktree_path == current_path
    table.insert(sessions_list, {
      name = name,
      branch = session.branch,
      worktree = session.worktree_path,
      type = session.type,
      created = session.created,
      is_current = is_current,
      display = string.format(
        "%s%-40s %s",
        is_current and "* " or "  ",
        vim.fn.fnamemodify(session.worktree_path, ":t"),
        session.branch or "N/A"
      )
    })
  end
  
  -- Sort by creation date (newest first), but keep main at top
  table.sort(sessions_list, function(a, b)
    if a.is_main then return false end  -- main always goes first
    if b.is_main then return true end
    return (a.created or "") > (b.created or "")
  end)
  
  -- Add keyboard shortcuts entry at the beginning (will appear at bottom with descending strategy)
  table.insert(sessions_list, 1, {
    is_help = true,
    name = "~~~help",  -- ~~~ ensures it sorts after everything
    display = string.format(
      "  %-40s %s",
      "[Keyboard Shortcuts]",
      "help"
    ),
    branch = "help",
    worktree = "help"
  })
  
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
    sorting_strategy = "descending",  -- Default strategy
    default_selection_index = 2,  -- Start on second item (first actual session)
    previewer = previewers.new_buffer_previewer({
      title = "Session Context",
      define_preview = function(self, entry, status)
        -- Show help for keyboard shortcuts entry
        if entry.value.is_help then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
            "Keyboard Shortcuts:",
            "",
            "  Enter (CR)  - Switch to selected session",
            "  Ctrl-d      - Delete selected session",
            "  Ctrl-t      - Open session in new tab",
            "  Ctrl-n      - Create new Claude worktree",
            "  Escape      - Close picker",
            "",
            "Navigation:",
            "  Ctrl-j/k    - Move selection down/up",
            "  Ctrl-u/d    - Scroll preview up/down",
            "",
            "Note: Sessions include CLAUDE.md context files"
          })
          return
        end
        
        -- Special preview for main branch
        if entry.value.is_main then
          M._generate_main_branch_preview(self, entry)
          return
        end
        
        -- Regular Claude session preview
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
        local selection = action_state.get_selected_entry()
        if selection and not selection.value.is_help then
          actions.close(prompt_bufnr)
          vim.cmd("tcd " .. selection.value.worktree)
          
          -- Only set current_session for Claude sessions, not main
          if not selection.value.is_main then
            M.current_session = selection.value.name
          end
          
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
        if selection and not selection.value.is_help then
          -- Don't allow deleting main branch
          if selection.value.is_main then
            vim.notify("Cannot delete main branch", vim.log.levels.ERROR)
            return
          end
          local confirm = vim.fn.confirm(
            "Delete session '" .. selection.value.name .. "'?",
            "&Yes\n&No", 2
          )
          if confirm == 1 then
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local current_prompt = current_picker:_get_prompt()
            
            -- Delete the session
            local success = M.delete_session_by_name(selection.value.name)
            
            if success ~= false then
              -- Close and reopen picker to refresh
              actions.close(prompt_bufnr)
              vim.schedule(function()
                M.telescope_sessions()
              end)
            end
          end
        end
      end)
      
      -- Open in new tab with Ctrl-t
      map("i", "<C-t>", function()
        local selection = action_state.get_selected_entry()
        if selection and not selection.value.is_help then
          actions.close(prompt_bufnr)
          vim.cmd("tabnew")
          vim.cmd("tcd " .. selection.value.worktree)
          local context = selection.value.worktree .. "/CLAUDE.md"
          if vim.fn.filereadable(context) == 1 then
            vim.cmd("edit " .. context)
          end
        end
      end)
      
      -- Create new session with Ctrl-n
      map("i", "<C-n>", function()
        actions.close(prompt_bufnr)
        M.create_worktree_with_claude()
      end)
      
      return true
    end,
  }):find()
end

-- Sync sessions with actual git worktrees (always keep in sync)
function M.sync_with_git_worktrees()
  local worktree_output = vim.fn.system("git worktree list")
  
  if vim.v.shell_error ~= 0 then
    return
  end
  
  local found_worktrees = {}
  local new_count = 0
  
  -- Parse all worktrees from git
  for line in worktree_output:gmatch("[^\n]+") do
    local path = line:match("^([^%s]+)")
    local branch = line:match("%[(.+)%]")
    
    if path and branch then
      -- Check if this is a Claude worktree (type/name pattern)
      local type, name = branch:match("^(%w+)/(.+)$")
      if type and name and vim.tbl_contains(M.config.types, type) then
        found_worktrees[name] = true
        
        -- Add or update session
        if not M.sessions[name] then
          M.sessions[name] = {
            worktree_path = path,
            branch = branch,
            type = type,
            created = M.sessions[name] and M.sessions[name].created or os.date("%Y-%m-%d %H:%M"),
            session_id = M.sessions[name] and M.sessions[name].session_id or (name .. "-" .. os.time()),
          }
          new_count = new_count + 1
        else
          -- Update path in case it changed
          M.sessions[name].worktree_path = path
        end
      end
    end
  end
  
  -- Remove sessions that no longer have worktrees
  local removed_count = 0
  local removed_names = {}
  for name, _ in pairs(M.sessions) do
    if not found_worktrees[name] then
      M.sessions[name] = nil
      removed_count = removed_count + 1
      table.insert(removed_names, name)
    end
  end
  
  -- Save if anything changed
  if new_count > 0 or removed_count > 0 then
    M.save_sessions()
    local notify = require('neotex.util.notifications')
    
    -- Always show when sessions are cleaned up (brief message)
    if removed_count > 0 then
      if removed_count == 1 then
        vim.notify(string.format("Cleaned up stale session: %s", removed_names[1]), vim.log.levels.INFO)
      else
        vim.notify(string.format("Cleaned up %d stale sessions: %s", removed_count, table.concat(removed_names, ", ")), vim.log.levels.INFO)
      end
    end
    
    -- Only show new worktree messages in debug mode
    if notify.config.debug_mode and new_count > 0 then
      vim.notify(string.format("Found %d new worktree(s)", new_count), vim.log.levels.INFO)
    end
  end
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
    
    -- Store session BEFORE spawning tab (needed by _spawn_wezterm_tab)
    M.sessions[name] = {
      worktree_path = worktree_path,
      branch = branch,
      type = type,
      created = os.date("%Y-%m-%d %H:%M"),
      tab_id = nil,  -- Will be set by _spawn_wezterm_tab
    }
    
    -- Spawn tab (needs session to exist)
    if has_wezterm then
      M._spawn_wezterm_tab(worktree_path, name, name .. "-" .. os.time(), 
        worktree_path .. "/CLAUDE.md")
    end
    
    M.current_session = name
    M.save_sessions()
    
    vim.notify("Created " .. type .. ": " .. name, vim.log.levels.INFO)
  else
    vim.notify("Failed to create worktree: " .. result, vim.log.levels.ERROR)
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
  
  vim.api.nvim_create_user_command("ClaudeSessions", M.telescope_sessions, {
    desc = "Browse Claude sessions with Telescope"
  })
end

-- Generate preview for main branch
function M._generate_main_branch_preview(previewer, entry)
  local git_info = require('neotex.core.git-info')
  local lines = {}
  
  -- Clear cache to get fresh data
  git_info.clear_cache()
  
  -- Determine which view to show
  if git_info.is_repository_dirty() then
    -- Show git status view for dirty repository
    local status_data = git_info.get_git_status()
    local status_lines = git_info.format_status_preview(status_data)
    vim.list_extend(lines, status_lines)
  else
    -- Show branch comparison for clean repository
    local branch_data = git_info.get_branch_comparison("main")
    local branch_lines = git_info.format_branch_preview(branch_data)
    vim.list_extend(lines, branch_lines)
  end
  
  -- Add statistics section
  local stats_data = git_info.get_repository_stats()
  local stats_lines = git_info.format_stats_section(stats_data, M.sessions)
  vim.list_extend(lines, stats_lines)
  
  -- Set the preview content
  vim.api.nvim_buf_set_lines(previewer.state.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(previewer.state.bufnr, 'filetype', 'markdown')
end

-- Create keymaps
function M._create_keymaps()
  local keymap = vim.keymap.set
  
  -- Main operations now under <leader>a for AI/Claude
  -- These duplicate the mappings in which-key.lua but are kept for direct module usage
  -- Note: The which-key.lua file should be the primary source of keymaps
  
  -- Commented out to avoid conflicts with which-key.lua mappings
  -- keymap("n", "<leader>aW", M.create_worktree_with_claude, 
  --   { desc = "Create worktree with Claude" })
  -- keymap("n", "<leader>aw", M.switch_session, 
  --   { desc = "Switch Claude session" })
  -- keymap("n", "<leader>ai", M.list_sessions, 
  --   { desc = "List Claude sessions" })
  -- keymap("n", "<leader>ad", M.delete_session, 
  --   { desc = "Delete Claude session" })
  
  -- Quick feature/bugfix are now under <leader>g in which-key.lua
  -- keymap("n", "<leader>gf", M.quick_feature, 
  --   { desc = "Quick feature worktree" })
  -- keymap("n", "<leader>gx", M.quick_bugfix, 
  --   { desc = "Quick bugfix worktree" })
end

return M