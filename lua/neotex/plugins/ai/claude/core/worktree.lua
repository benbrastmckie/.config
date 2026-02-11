-----------------------------------------------------------
-- Claude Code + Git Worktree Integration Module
--
-- Orchestrates git worktrees with Claude Code sessions,
-- managing parallel development across isolated branches
-- with terminal tab integration (Kitty/WezTerm)
-----------------------------------------------------------

local M = {}

-- Dependencies
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

  -- Terminal preferences (optional, with sensible defaults)
  terminal = {
    -- No "prefer" option - use detected terminal
    -- Simpler is better: always fallback to current window
    fallback_mode = 'current_window',

    -- Debug mode only - follows NOTIFICATIONS.md patterns
    show_terminal_info = false
  },

  -- CLAUDE.md preservation settings
  preserve_main_claudemd = true,  -- Copy main CLAUDE.md to new worktrees
  claudemd_separator = "---",     -- Markdown separator between sections
  claudemd_inherited_heading = "# Project Configuration (Inherited from Main Worktree)",

  -- Context file template
  context_template = [[
# Worktree Task: %s

## Task Metadata
- **Type**: %s
- **Branch**: %s
- **Created**: %s
- **Worktree**: %s
- **Session ID**: %s

## Objective
[Describe the main goal for this worktree]

## Current Status
- [ ] Planning
- [ ] Implementation
- [ ] Testing
- [ ] Documentation
- [ ] Review

## Claude Context
Tell Claude: "I'm working on %s in the %s worktree. The goal is to..."

## Task Notes
[Add worktree-specific context, links, or decisions]
]],
}

-- Session state tracking
M.sessions = {}  -- { feature_name = { tab_id, worktree_path, branch, created } }
M.current_session = nil
M._initialized = false  -- Guard to prevent multiple initializations

-- Initialize module
function M.setup(opts)
  -- Prevent multiple initializations
  if M._initialized then
    return
  end
  M._initialized = true
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Check terminal support (lazy-loaded)
  local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
  if not terminal_detect.supports_tabs() then
    local terminal_name = terminal_detect.get_display_name()
    local terminal_type = terminal_detect.detect()

    -- Provide specific guidance for Kitty remote control
    if terminal_type == 'kitty' then
      local config_path = terminal_detect.get_kitty_config_path()
      local config_status = terminal_detect.check_kitty_config()

      local message
      if config_status == false then
        message = string.format(
          "Kitty remote control is disabled. Add 'allow_remote_control yes' to %s and restart Kitty.",
          config_path
        )
      elseif config_status == nil then
        message = string.format(
          "Kitty config not found. Create %s with 'allow_remote_control yes' and restart Kitty.",
          config_path
        )
      else
        message = string.format(
          "Kitty remote control configuration issue. Ensure 'allow_remote_control yes' is in %s and restart Kitty.",
          config_path
        )
      end

      vim.notify(message, vim.log.levels.WARN)
    else
      -- Generic error for non-Kitty terminals
      vim.notify(
        string.format(
          "Terminal '%s' does not support tab management. Please use Kitty (with remote control enabled) or WezTerm.",
          terminal_name
        ),
        vim.log.levels.WARN
      )
    end
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

-- Helper: Locate main worktree's CLAUDE.md file
-- @return string|nil Absolute path to main CLAUDE.md, or nil if not found
function M._get_main_claudemd_path()
  -- Get git repository root (main worktree)
  local git_root_list = vim.fn.systemlist("git rev-parse --show-toplevel")

  if vim.v.shell_error ~= 0 or #git_root_list == 0 then
    return nil
  end

  local git_root = git_root_list[1]
  local main_claude = git_root .. "/CLAUDE.md"

  -- Check if file exists and is readable
  if vim.fn.filereadable(main_claude) == 1 then
    return main_claude
  end

  return nil
end

-- Helper: Create context file
function M._create_context_file(worktree_path, feature, type, branch, session_id)
  if not M.config.create_context_file then
    return nil
  end

  local context_file = worktree_path .. "/CLAUDE.md"

  -- Build task metadata section
  local task_section = string.format(
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

  local content
  local preserved = false

  -- Try to preserve main CLAUDE.md if enabled
  if M.config.preserve_main_claudemd then
    local main_claude_path = M._get_main_claudemd_path()

    if main_claude_path then
      -- Read main CLAUDE.md content
      local ok, main_lines = pcall(vim.fn.readfile, main_claude_path)

      if ok and #main_lines > 0 then
        local main_content = table.concat(main_lines, "\n")

        -- Combine: task metadata + separator + inherited content
        content = task_section .. "\n\n" ..
          M.config.claudemd_separator .. "\n\n" ..
          M.config.claudemd_inherited_heading .. "\n\n" ..
          main_content

        preserved = true
      end
    end
  end

  -- Fallback: use template-only
  if not preserved then
    content = task_section
  end

  -- Write to worktree
  vim.fn.writefile(vim.split(content, "\n"), context_file)

  -- Notify user
  if preserved then
    vim.notify(
      "Created worktree CLAUDE.md (preserved main configuration)",
      vim.log.levels.INFO
    )
  end

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

    -- Create terminal tab if available
    local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
    if terminal_detect.supports_tabs() then
      M._spawn_terminal_tab(worktree_path, feature, session_id, context_file)
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

-- Terminal: Spawn new tab for worktree (supports Kitty and WezTerm)
function M._spawn_terminal_tab(worktree_path, feature, session_id, context_file)
  -- Lazy-load dependencies for performance
  local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
  local terminal_cmds = require('neotex.plugins.ai.claude.claude-session.terminal-commands')
  local notify = require('neotex.util.notifications')

  -- Check terminal support
  if not terminal_detect.supports_tabs() then
    local terminal_name = terminal_detect.get_display_name()
    local terminal_type = terminal_detect.detect()

    -- Provide specific guidance for Kitty remote control
    if terminal_type == 'kitty' then
      local config_path = terminal_detect.get_kitty_config_path()
      local config_status = terminal_detect.check_kitty_config()

      local message
      local solution_data = {
        terminal = terminal_name,
        config_file = config_path,
        required_setting = "allow_remote_control yes",
        fallback = "opening in current window"
      }

      if config_status == false then
        message = string.format(
          "Kitty remote control is disabled. Add 'allow_remote_control yes' to %s and restart Kitty.",
          config_path
        )
      elseif config_status == nil then
        message = string.format(
          "Kitty config not found. Create %s with 'allow_remote_control yes' and restart Kitty.",
          config_path
        )
      else
        message = string.format(
          "Kitty remote control configuration issue. Ensure 'allow_remote_control yes' is in %s and restart Kitty.",
          config_path
        )
      end

      notify.editor(message, notify.categories.ERROR, solution_data)
    else
      -- Generic error for non-Kitty terminals
      notify.editor(
        string.format(
          "Terminal '%s' does not support tab management. Please use Kitty (with remote control enabled) or WezTerm.",
          terminal_name
        ),
        notify.categories.ERROR,
        {
          terminal = terminal_name,
          required = "kitty or wezterm",
          fallback = "opening in current window"
        }
      )
    end

    -- Fallback to current window (pragmatic compromise)
    vim.cmd("tcd " .. vim.fn.fnameescape(worktree_path))
    if context_file then
      vim.cmd("edit " .. vim.fn.fnameescape(context_file))
    end

    -- USER_ACTION notification for fallback action
    notify.editor(
      string.format("Opened worktree '%s' in current window", feature),
      notify.categories.USER_ACTION,
      { worktree = feature, path = worktree_path }
    )
    return
  end

  -- Generate terminal-specific command
  -- Convert relative path to absolute path for terminal commands
  local abs_worktree_path = vim.fn.fnamemodify(worktree_path, ":p")
  local cmd = terminal_cmds.spawn_tab(
    abs_worktree_path,
    context_file and "nvim CLAUDE.md" or nil
  )

  if not cmd then
    notify.editor(
      "Failed to generate terminal command",
      notify.categories.ERROR,
      { worktree = feature }
    )
    return
  end

  -- Execute spawn command
  local result = vim.fn.system(cmd)

  -- Check for command execution errors
  if vim.v.shell_error ~= 0 then
    notify.editor(
      string.format("Failed to spawn terminal tab: %s", vim.trim(result)),
      notify.categories.ERROR,
      { worktree = feature, error = result }
    )
    return
  end

  -- Parse result to get tab/pane ID
  local tab_id = terminal_cmds.parse_spawn_result(result)

  if tab_id then
    -- Store tab ID in session
    M.sessions[feature].tab_id = tab_id

    -- Auto-activate if configured
    if M.config.auto_switch_tab then
      local activate_cmd = terminal_cmds.activate_tab(tab_id)
      if activate_cmd then
        vim.fn.system(activate_cmd)
      end
    end

    -- Set tab title if supported
    local title_cmd = terminal_cmds.set_tab_title(tab_id, feature)
    if title_cmd then
      vim.fn.system(title_cmd)
    end

    -- Success notification (USER_ACTION category)
    notify.editor(
      string.format(
        "Created Claude session '%s' in new %s tab",
        feature,
        terminal_detect.get_display_name()
      ),
      notify.categories.USER_ACTION,
      {
        session = feature,
        terminal = terminal_detect.detect(),
        tab_id = tab_id
      }
    )
  else
    -- WARNING for partial success
    notify.editor(
      "Created worktree but couldn't track tab ID",
      notify.categories.WARNING,
      { worktree = feature }
    )
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
      
      -- Switch terminal tab if available
      local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
      local terminal_cmds = require('neotex.plugins.ai.claude.claude-session.terminal-commands')
      if terminal_detect.supports_tabs() and choice.session.tab_id then
        -- Try to activate tab
        local activate_cmd = terminal_cmds.activate_tab(choice.session.tab_id)
        if activate_cmd then
          local result = vim.fn.system(activate_cmd)
          if vim.v.shell_error ~= 0 then
            vim.notify("Could not switch terminal tab", vim.log.levels.WARN)
          end
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
  
  local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
  if terminal_detect.supports_tabs() then
    local tab_count = 0
    for _, session in pairs(M.sessions) do
      if session.tab_id then tab_count = tab_count + 1 end
    end
    print(string.format("%s tabs: %d", terminal_detect.get_display_name(), tab_count))
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
          -- Close terminal tab if exists
          local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
          if terminal_detect.supports_tabs() and choice.session.tab_id then
            -- Note: Tab closing is terminal-specific and may not be supported
            if terminal_detect.detect() == 'wezterm' then
              vim.fn.system("wezterm cli kill-pane --tab-id " .. choice.session.tab_id)
            end
            -- Kitty doesn't support remote tab closing
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
        -- Only notify if there are actually sessions to restore
        local session_count = vim.tbl_count(sessions)
        if session_count > 0 then
          vim.notify(
            string.format("Restored %d Claude worktree session(s)", session_count),
            vim.log.levels.INFO
          )
        end
      end
    end
  end
end

-- Clean up stale sessions
-- @param silent boolean If true, only show notifications when sessions are cleaned (not when none found)
function M.cleanup_sessions(silent)
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
  elseif not silent then
    -- Only show "no sessions" message when explicitly called by user (not silent)
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
            "  Ctrl-o      - Open worktree in new terminal tab",
            "  Ctrl-n      - Create new Claude worktree",
            "  Ctrl-x      - Cleanup stale worktrees",
            "  Ctrl-h      - Show worktree health report",
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
      
      -- Open worktree in new terminal tab with Ctrl-o
      map("i", "<C-o>", function()
        local selection = action_state.get_selected_entry()
        if selection and not selection.value.is_help then
          -- Don't allow opening help entry
          if selection.value.is_help then
            return
          end

          actions.close(prompt_bufnr)

          -- Get the worktree path
          local worktree_path = selection.value.worktree
          local name = selection.value.name

          -- Check if CLAUDE.md exists to determine what to open
          local claude_md_path = worktree_path .. "/CLAUDE.md"
          local open_file = vim.fn.filereadable(claude_md_path) == 1 and "CLAUDE.md" or ""

          -- Use terminal abstraction for spawning
          local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
          local terminal_cmds = require('neotex.plugins.ai.claude.claude-session.terminal-commands')

          if not terminal_detect.supports_tabs() then
            local terminal_name = terminal_detect.get_display_name()
            local terminal_type = terminal_detect.detect()

            -- Provide specific guidance for Kitty remote control
            if terminal_type == 'kitty' then
              local config_path = terminal_detect.get_kitty_config_path()
              local config_status = terminal_detect.check_kitty_config()

              local message
              if config_status == false then
                message = string.format(
                  "Kitty remote control is disabled. Add 'allow_remote_control yes' to %s and restart Kitty.",
                  config_path
                )
              elseif config_status == nil then
                message = string.format(
                  "Kitty config not found. Create %s with 'allow_remote_control yes' and restart Kitty.",
                  config_path
                )
              else
                message = string.format(
                  "Kitty remote control configuration issue. Ensure 'allow_remote_control yes' is in %s and restart Kitty.",
                  config_path
                )
              end

              vim.notify(message, vim.log.levels.ERROR)
            else
              -- Generic error for non-Kitty terminals
              vim.notify(
                string.format(
                  "Terminal '%s' does not support tab management. Please use Kitty (with remote control enabled) or WezTerm.",
                  terminal_name
                ),
                vim.log.levels.ERROR
              )
            end
            return
          end

          -- Spawn new terminal tab with the worktree
          local cmd
          if open_file ~= "" then
            -- Open with nvim and CLAUDE.md
            cmd = terminal_cmds.spawn_tab(worktree_path, "nvim CLAUDE.md")
          else
            -- Just open the directory
            cmd = terminal_cmds.spawn_tab(worktree_path)
          end

          if not cmd then
            vim.notify("Failed to generate terminal command", vim.log.levels.ERROR)
            return
          end

          local result = vim.fn.system(cmd)

          if vim.v.shell_error ~= 0 then
            vim.notify("Failed to create new terminal tab: " .. vim.trim(result), vim.log.levels.ERROR)
            return
          end

          local pane_id = terminal_cmds.parse_spawn_result(result)

          if pane_id then
            -- Set the tab title if supported
            local title_cmd = terminal_cmds.set_tab_title(pane_id, name)
            if title_cmd then
              vim.fn.system(title_cmd)
            end

            -- Activate the new tab
            local activate_cmd = terminal_cmds.activate_tab(pane_id)
            if activate_cmd then
              vim.fn.system(activate_cmd)
            end

            vim.notify(
              string.format(
                "Opened worktree '%s' in new %s tab",
                name,
                terminal_detect.get_display_name()
              ),
              vim.log.levels.INFO
            )
          else
            vim.notify("Failed to parse terminal tab ID", vim.log.levels.ERROR)
          end
        end
      end)

      -- Cleanup sessions with Ctrl-x
      map("i", "<C-x>", function()
        actions.close(prompt_bufnr)
        vim.schedule(function()
          M.cleanup_sessions()
          -- Reopen picker after cleanup
          vim.defer_fn(function()
            M.telescope_sessions()
          end, 500)
        end)
      end)

      -- Show health report with Ctrl-h
      map("i", "<C-h>", function()
        actions.close(prompt_bufnr)
        vim.schedule(function()
          M.health_report()
        end)
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

  -- Get the main repository path to exclude it
  local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")

  local found_worktrees = {}
  local new_count = 0

  -- Parse all worktrees from git
  for line in worktree_output:gmatch("[^\n]+") do
    local path = line:match("^([^%s]+)")
    local branch = line:match("%[(.+)%]")

    if path and branch then
      -- Skip the main repository
      if path ~= git_root then
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
  end
  
  -- Remove sessions whose worktree directories no longer exist
  -- Note: We check the actual path, not pattern matching, to support
  -- sessions created with non-standard branch names (e.g., "himalaya" vs "feature/himalaya")
  local removed_count = 0
  local removed_names = {}
  for name, session in pairs(M.sessions) do
    -- Verify the worktree path actually exists on disk
    local worktree_exists = session.worktree_path and
                            vim.fn.isdirectory(session.worktree_path) == 1
    if not worktree_exists then
      M.sessions[name] = nil
      removed_count = removed_count + 1
      table.insert(removed_names, name)
    else
      -- Mark as found so it won't be re-added as new
      found_worktrees[name] = true
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
    local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
    if terminal_detect.supports_tabs() then
      M._spawn_terminal_tab(worktree_path, name, name .. "-" .. os.time(), 
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

  vim.api.nvim_create_user_command("ClaudeRestoreWorktree", M.restore_worktree_session, {
    desc = "Restore a closed Claude worktree session"
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

-- ============================================================================
-- SESSION RESTORATION FEATURES
-- ============================================================================

-- Check if a worktree session can be restored
function M.is_restorable(worktree_name)
  local session = M.sessions[worktree_name]
  if not session then return false, "No session found" end
  
  -- Check worktree exists
  local worktree_exists = vim.fn.isdirectory(session.worktree_path) == 1
  if not worktree_exists then
    return false, "Worktree directory missing"
  end
  
  -- Check CLAUDE.md exists
  local claude_md = session.worktree_path .. "/CLAUDE.md"
  local has_context = vim.fn.filereadable(claude_md) == 1
  
  return true, has_context and "Ready to restore" or "No CLAUDE.md file"
end

-- Spawn new terminal tab for restoration
function M._spawn_restoration_tab(worktree_path, name)
  local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
  local terminal_cmds = require('neotex.plugins.ai.claude.claude-session.terminal-commands')

  if not terminal_detect.supports_tabs() then
    local terminal_name = terminal_detect.get_display_name()
    local terminal_type = terminal_detect.detect()

    -- Provide specific guidance for Kitty remote control
    if terminal_type == 'kitty' then
      local config_path = terminal_detect.get_kitty_config_path()
      local config_status = terminal_detect.check_kitty_config()

      local message
      if config_status == false then
        message = string.format(
          "Kitty remote control is disabled. Add 'allow_remote_control yes' to %s and restart Kitty.",
          config_path
        )
      elseif config_status == nil then
        message = string.format(
          "Kitty config not found. Create %s with 'allow_remote_control yes' and restart Kitty.",
          config_path
        )
      else
        message = string.format(
          "Kitty remote control configuration issue. Ensure 'allow_remote_control yes' is in %s and restart Kitty.",
          config_path
        )
      end

      return nil, nil, message
    else
      -- Generic error for non-Kitty terminals
      return nil, nil, string.format(
        "Terminal '%s' does not support tab management. Please use Kitty (with remote control enabled) or WezTerm.",
        terminal_name
      )
    end
  end

  -- Use terminal abstraction to create new tab with CLAUDE.md open
  -- Convert relative path to absolute path for terminal commands
  local abs_worktree_path = vim.fn.fnamemodify(worktree_path, ":p")
  local cmd = terminal_cmds.spawn_tab(abs_worktree_path, "nvim CLAUDE.md")

  if not cmd then
    return nil, nil, "Failed to generate terminal command"
  end

  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return nil, nil, "Failed to spawn terminal tab: " .. vim.trim(result)
  end

  local pane_id = terminal_cmds.parse_spawn_result(result)

  if pane_id then
    -- Activate the new tab
    local activate_cmd = terminal_cmds.activate_tab(pane_id)
    if activate_cmd then
      vim.fn.system(activate_cmd)
    end

    -- Set tab title if supported
    local title_cmd = terminal_cmds.set_tab_title(pane_id, name)
    if title_cmd then
      vim.fn.system(title_cmd)
    end

    -- For compatibility, return both tab_id and pane_id as the same value
    return pane_id, pane_id, nil
  end

  return nil, nil, "Failed to spawn terminal tab"
end

-- Restore Claude session in the new tab
function M._restore_claude_session(pane_id, session_id)
  if not pane_id then return end

  local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
  local terminal = terminal_detect.detect()

  -- Terminal-specific text sending (not all terminals support this)
  if terminal == 'wezterm' then
    -- Wait for Neovim to load, then send ClaudeCodeResume command
    vim.defer_fn(function()
      local resume_cmd = string.format(
        "wezterm cli send-text --pane-id %s ':ClaudeCodeResume\\n'",
        pane_id
      )
      vim.fn.system(resume_cmd)

      -- Open Claude sidebar after a delay
      vim.defer_fn(function()
        -- Send Ctrl-A to open Claude sidebar
        local sidebar_cmd = string.format(
          "wezterm cli send-text --no-paste --pane-id %s '\\x01'",
          pane_id
        )
        vim.fn.system(sidebar_cmd)
      end, 2000)
    end, 1500)
  elseif terminal == 'kitty' then
    -- Kitty has different remote control commands
    -- Note: Kitty remote control requires --allow-remote-control flag
    vim.notify(
      "Claude session restoration in Kitty tabs requires manual :ClaudeCodeResume",
      vim.log.levels.INFO
    )
  end
end

-- Perform complete restoration
function M._perform_restoration(entry)
  local name = entry.name
  local session = entry.session
  local worktree_path = session and session.worktree_path or entry.worktree_path
  
  -- Verify worktree exists
  if vim.fn.isdirectory(worktree_path) == 0 then
    vim.notify("Worktree no longer exists: " .. worktree_path, vim.log.levels.ERROR)
    return
  end
  
  -- Try to spawn terminal tab
  local tab_id, pane_id, err = M._spawn_restoration_tab(worktree_path, name)

  if not tab_id then
    -- Fallback: open in current Neovim
    vim.notify("Terminal tab restoration failed: " .. (err or "unknown error"), vim.log.levels.WARN)
    vim.notify("Opening in current window...", vim.log.levels.INFO)
    
    vim.cmd("cd " .. vim.fn.fnameescape(worktree_path))
    vim.cmd("edit CLAUDE.md")
    
    -- Try to resume Claude session locally
    if session and session.session_id then
      vim.defer_fn(function()
        vim.cmd("ClaudeCodeResume")
      end, 100)
    end
    return
  end
  
  -- Update session with new tab ID
  if session then
    M.sessions[name].tab_id = tab_id
    M.save_sessions()
  end
  
  -- Restore Claude session
  if session and session.session_id then
    M._restore_claude_session(pane_id, session.session_id)
  end
  
  vim.notify(string.format("Restored worktree session: %s", name), vim.log.levels.INFO)
end

-- Main restoration function with telescope picker
function M.restore_worktree_session()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  
  local restorable = {}
  
  -- Find all restorable sessions
  for name, session in pairs(M.sessions) do
    local can_restore, status = M.is_restorable(name)
    table.insert(restorable, {
      name = name,
      session = session,
      worktree_path = session.worktree_path,
      branch = session.branch,
      can_restore = can_restore,
      status = status,
      display = string.format(
        "%-30s %-30s %s",
        name,
        session.branch or "unknown",
        can_restore and "[Restorable]" or "[" .. status .. "]"
      )
    })
  end
  
  -- Check for orphaned worktrees without sessions
  local worktree_output = vim.fn.system("git worktree list")
  if vim.v.shell_error == 0 then
    for line in worktree_output:gmatch("[^\n]+") do
      local path = line:match("^([^%s]+)")
      local branch = line:match("%[(.+)%]")
      
      if path and branch then
        -- Check if it's a Claude-style worktree
        local type, name = branch:match("^(%w+)/(.+)$")
        if type and name and vim.tbl_contains(M.config.types, type) then
          -- Check if we already have this session
          if not M.sessions[name] then
            table.insert(restorable, {
              name = name,
              worktree_path = path,
              branch = branch,
              orphaned = true,
              can_restore = true,
              status = "Orphaned worktree",
              display = string.format(
                "%-30s %-30s %s",
                name,
                branch,
                "[Orphaned - No session]"
              )
            })
          end
        end
      end
    end
  end
  
  if #restorable == 0 then
    vim.notify("No restorable worktree sessions found", vim.log.levels.INFO)
    return
  end
  
  -- Sort by name
  table.sort(restorable, function(a, b) return a.name < b.name end)
  
  pickers.new({}, {
    prompt_title = "Restore Worktree Session",
    finder = finders.new_table {
      results = restorable,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name .. " " .. (entry.branch or "")
        }
      end
    },
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Session Info",
      define_preview = function(self, entry, status)
        local lines = {}
        local item = entry.value

        -- Get preview window width for text wrapping
        local preview_width = vim.api.nvim_win_get_width(self.state.winid) or 80

        -- Helper function to wrap text
        local function wrap_text(text, width)
          if #text <= width then
            return { text }
          end

          local wrapped = {}
          local current_line = ""
          for word in text:gmatch("%S+") do
            if #current_line + #word + 1 > width then
              if #current_line > 0 then
                table.insert(wrapped, current_line)
              end
              current_line = word
            else
              current_line = current_line .. (current_line == "" and "" or " ") .. word
            end
          end
          if #current_line > 0 then
            table.insert(wrapped, current_line)
          end
          return wrapped
        end

        -- Basic info header
        table.insert(lines, string.format("━━━ %s ━━━", item.name))
        table.insert(lines, string.format("Branch: %s | Status: %s", item.branch or "unknown", item.status))
        table.insert(lines, "")

        -- Try to show recent conversation if session exists
        if item.session and item.session.session_id then
          -- Try to find conversation file
          local project_path = vim.fn.expand("~/.claude/projects/" .. item.worktree_path:gsub("/", "-"))
          local session_file = project_path .. "/" .. item.session.session_id .. ".jsonl"

          if vim.fn.filereadable(session_file) == 1 then
            table.insert(lines, "═══ Recent Conversation ═══")
            table.insert(lines, "")

            local conversation_lines = vim.fn.readfile(session_file)
            local messages = {}

            -- Parse JSONL to extract messages (last 20 entries for more context)
            local start_idx = math.max(1, #conversation_lines - 20)
            for i = start_idx, #conversation_lines do
              local line = conversation_lines[i]
              if line and line ~= "" then
                -- Try to decode JSON properly
                local ok, decoded = pcall(vim.fn.json_decode, line)
                if ok and decoded then
                  local role = decoded.role or "unknown"
                  local content = decoded.content or ""

                  -- Handle content that might be a table (for complex messages)
                  if type(content) == "table" then
                    content = vim.inspect(content)
                  end

                  -- Clean up the content
                  content = tostring(content):gsub("\\n", "\n"):gsub("\\t", "  ")

                  if content and content ~= "" then
                    table.insert(messages, { role = role, content = content })
                  end
                else
                  -- Fallback: try to extract content between quotes more carefully
                  local role = line:match('"role"%s*:%s*"([^"]+)"')
                  -- Match content more carefully - find the content field and extract everything between quotes
                  local content_start = line:find('"content"%s*:%s*"')
                  if content_start then
                    local content = ""
                    local in_string = false
                    local escaped = false
                    local start_found = false

                    for j = content_start + 10, #line do
                      local char = line:sub(j, j)

                      if not start_found and char == '"' then
                        start_found = true
                        in_string = true
                      elseif start_found then
                        if escaped then
                          content = content .. char
                          escaped = false
                        elseif char == "\\" then
                          escaped = true
                        elseif char == '"' and in_string then
                          break
                        else
                          content = content .. char
                        end
                      end
                    end

                    if content ~= "" then
                      -- Unescape basic sequences
                      content = content:gsub("\\n", "\n"):gsub("\\t", "  "):gsub('\\"', '"'):gsub("\\\\", "\\")
                      table.insert(messages, { role = role or "unknown", content = content })
                    end
                  end
                end
              end
            end

            -- Display messages with wrapping
            for _, msg in ipairs(messages) do
              if msg.role == "user" or msg.role == "human" then
                table.insert(lines, "👤 USER:")
              else
                table.insert(lines, "🤖 CLAUDE:")
              end

              -- Split content by newlines first, then wrap each line
              local content_lines = vim.split(msg.content, "\n", { plain = true })
              for _, content_line in ipairs(content_lines) do
                if #content_line > preview_width - 4 then
                  -- Wrap long lines
                  local wrapped = wrap_text(content_line, preview_width - 4)
                  for _, wrapped_line in ipairs(wrapped) do
                    table.insert(lines, "  " .. wrapped_line)
                  end
                else
                  -- Short lines just get indented
                  table.insert(lines, "  " .. content_line)
                end
              end
              table.insert(lines, "")
            end

            if #messages == 0 then
              table.insert(lines, "(No messages found in session)")
            end
          else
            table.insert(lines, "═══ Session Details ═══")
            table.insert(lines, string.format("Type: %s", item.session.type or "unknown"))
            table.insert(lines, string.format("Created: %s", item.session.created or "unknown"))
            table.insert(lines, string.format("Session ID: %s", item.session.session_id or "none"))
            table.insert(lines, "")
            table.insert(lines, "(Conversation file not found)")
          end
        end

        -- Only show brief CLAUDE.md info to leave more space for conversation
        local claude_file = item.worktree_path .. "/CLAUDE.md"
        if vim.fn.filereadable(claude_file) == 1 then
          local content = vim.fn.readfile(claude_file)
          table.insert(lines, "")
          table.insert(lines, string.format("═══ CLAUDE.md (%d lines) ═══", #content))

          -- Just show first few lines as context
          for i = 1, math.min(5, #content) do
            if #content[i] > preview_width then
              local truncated = content[i]:sub(1, preview_width - 3) .. "..."
              table.insert(lines, truncated)
            else
              table.insert(lines, content[i])
            end
          end

          if #content > 5 then
            table.insert(lines, string.format("... (+%d more lines)", #content - 5))
          end
        end

        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

        -- Enable proper text display in preview
        vim.api.nvim_buf_call(self.state.bufnr, function()
          vim.opt_local.filetype = "markdown"
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.breakindent = true
          vim.opt_local.conceallevel = 2
        end)
      end
    }),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.can_restore then
          actions.close(prompt_bufnr)
          M._perform_restoration(selection.value)
        elseif selection then
          vim.notify("Cannot restore: " .. selection.value.status, vim.log.levels.ERROR)
        end
      end)
      
      -- Add delete mapping
      map("i", "<C-d>", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value.session then
          local confirm = vim.fn.confirm(
            "Remove session metadata for '" .. selection.value.name .. "'?",
            "&Yes\n&No", 2
          )
          if confirm == 1 then
            M.sessions[selection.value.name] = nil
            M.save_sessions()
            vim.notify("Removed session: " .. selection.value.name, vim.log.levels.INFO)
            actions.close(prompt_bufnr)
            vim.schedule(function()
              M.restore_worktree_session()
            end)
          end
        end
      end)
      
      return true
    end
  }):find()
end

-- Claude Code Session Resume Picker
-- This provides a telescope picker for browsing and resuming Claude Code sessions

-- Helper function to get Claude sessions from the CLI
function M._get_claude_sessions()
  -- Run claude --resume to get the session list
  -- We'll parse the output to extract session information
  local cmd = "claude --resume --list 2>/dev/null || echo ''"
  local result = vim.fn.system(cmd)
  
  -- If the command doesn't support --list, try interactive mode with a timeout
  if result == "" or result:match("unknown option") then
    -- Try to get sessions using expect or similar approach
    -- For now, we'll try a different approach: look for session history
    cmd = "claude --resume < /dev/null 2>&1 | head -50"
    result = vim.fn.system(cmd)
  end
  
  local sessions = {}
  
  -- Parse the output to extract session information
  -- The format typically includes session ID, directory, and timestamp
  for line in result:gmatch("[^\r\n]+") do
    -- Look for patterns that indicate session entries
    -- Format might be like: "abc123def  /home/user/project  2024-01-15 10:30"
    local session_id, path, rest = line:match("^%s*(%S+)%s+(/[^%s]+)%s*(.*)")
    if session_id and path then
      -- Extract additional info from the rest
      local timestamp = rest:match("(%d%d%d%d%-%d%d%-%d%d%s+%d%d:%d%d)")
      local title = rest:gsub(timestamp or "", ""):gsub("^%s+", ""):gsub("%s+$", "")
      
      table.insert(sessions, {
        id = session_id,
        path = path,
        timestamp = timestamp or "Unknown",
        title = title ~= "" and title or nil,
        display = string.format("%s  %s  %s", 
          session_id:sub(1, 8), 
          vim.fn.fnamemodify(path, ":~:."),
          timestamp or "")
      })
    end
  end
  
  -- If we couldn't parse sessions from claude --resume, 
  -- try to find them from the cache directory
  if #sessions == 0 then
    local cache_base = vim.fn.expand("~/.cache/claude-cli-nodejs")
    if vim.fn.isdirectory(cache_base) == 1 then
      -- Get all project directories
      local projects = vim.fn.glob(cache_base .. "/*", false, true)
      
      for _, project_dir in ipairs(projects) do
        -- Convert the escaped project path back to normal path
        local escaped_name = vim.fn.fnamemodify(project_dir, ":t")
        local real_path = escaped_name:gsub("%-", "/")
        
        if real_path:sub(1, 1) ~= "/" then
          real_path = "/" .. real_path
        end
        
        -- Check if this directory exists
        if vim.fn.isdirectory(real_path) == 1 then
          -- Get modification time as a proxy for last session
          local stat = vim.loop.fs_stat(project_dir)
          local timestamp = stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "Unknown"
          
          table.insert(sessions, {
            id = vim.fn.fnamemodify(project_dir, ":t"),
            path = real_path,
            timestamp = timestamp,
            display = string.format("%-30s  %s", 
              vim.fn.fnamemodify(real_path, ":~:."),
              timestamp)
          })
        end
      end
    end
  end
  
  -- Sort sessions by timestamp (most recent first)
  table.sort(sessions, function(a, b)
    return (a.timestamp or "") > (b.timestamp or "")
  end)
  
  return sessions
end

-- Create previewer for Claude sessions
function M._create_claude_session_previewer()
  local previewers = require("telescope.previewers")
  
  return previewers.new_buffer_previewer({
    title = "Session Details",
    get_buffer_by_name = function(_, entry)
      return entry.value.id
    end,
    define_preview = function(self, entry)
      local session = entry.value
      local lines = {}
      
      -- Add session information
      table.insert(lines, "Session Information")
      table.insert(lines, "==================")
      table.insert(lines, "")
      table.insert(lines, "Session ID: " .. (session.id or "Unknown"))
      table.insert(lines, "Directory:  " .. (session.path or "Unknown"))
      table.insert(lines, "Last Used:  " .. (session.timestamp or "Unknown"))
      
      if session.title then
        table.insert(lines, "Title:      " .. session.title)
      end
      
      table.insert(lines, "")
      table.insert(lines, "Context Files")
      table.insert(lines, "=============")
      
      -- Check for CLAUDE.md in the directory
      local claude_md_path = session.path .. "/CLAUDE.md"
      if vim.fn.filereadable(claude_md_path) == 1 then
        table.insert(lines, "")
        table.insert(lines, "CLAUDE.md found:")
        table.insert(lines, "----------------")
        
        -- Read first 30 lines of CLAUDE.md
        local claude_content = vim.fn.readfile(claude_md_path, "", 30)
        for _, line in ipairs(claude_content) do
          table.insert(lines, line)
        end
        
        if #claude_content >= 30 then
          table.insert(lines, "...")
          table.insert(lines, "(truncated)")
        end
      else
        table.insert(lines, "No CLAUDE.md file found in directory")
      end
      
      -- Check for .claude directory
      local claude_dir = session.path .. "/.claude"
      if vim.fn.isdirectory(claude_dir) == 1 then
        table.insert(lines, "")
        table.insert(lines, ".claude directory found")
      end
      
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
    end,
  })
end

-- Resume a Claude session
function M._resume_claude_session(session)
  -- Check if we're in a terminal buffer with Claude
  local current_buf = vim.api.nvim_get_current_buf()
  local is_terminal = vim.api.nvim_buf_get_option(current_buf, "buftype") == "terminal"
  
  -- First, change to the session directory
  vim.cmd("cd " .. vim.fn.fnameescape(session.path))
  
  -- Check if claude-code.nvim is available
  local has_claude_code = pcall(require, "claude-code")
  
  if has_claude_code then
    -- If we have the claude-code plugin, use it to resume
    -- The plugin will handle the terminal creation and session resumption
    vim.cmd("ClaudeCodeResume")
    
    -- After a short delay, send the session ID to the prompt
    vim.defer_fn(function()
      -- Find the Claude terminal buffer
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and 
           vim.api.nvim_buf_get_option(buf, "buftype") == "terminal" then
          local buf_name = vim.api.nvim_buf_get_name(buf)
          if buf_name:match("claude") then
            -- Send the session ID to the terminal
            vim.api.nvim_chan_send(vim.api.nvim_buf_get_option(buf, "channel"), session.id .. "\n")
            break
          end
        end
      end
    end, 500)
  else
    -- Fallback: open a new terminal with claude --resume
    if is_terminal then
      -- If we're in a terminal, send the command directly
      vim.api.nvim_feedkeys("claude --resume " .. session.id .. "\n", "n", false)
    else
      -- Otherwise, open a new terminal
      vim.cmd("terminal claude --resume " .. session.id)
      vim.cmd("startinsert")
    end
  end
  
  vim.notify(string.format("Resuming Claude session in %s", 
    vim.fn.fnamemodify(session.path, ":~:.")), vim.log.levels.INFO)
end

-- Main telescope picker for Claude sessions
function M.claude_session_picker()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local conf = require("telescope.config").values
  
  -- Get available Claude sessions
  local sessions = M._get_claude_sessions()
  
  if #sessions == 0 then
    vim.notify("No Claude sessions found. Start a new session with 'claude' command.", 
      vim.log.levels.WARN)
    return
  end
  
  pickers.new({}, {
    prompt_title = "Claude Code Sessions",
    finder = finders.new_table({
      results = sessions,
      entry_maker = function(session)
        return {
          value = session,
          display = session.display,
          ordinal = session.path .. " " .. (session.timestamp or ""),
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = M._create_claude_session_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          M._resume_claude_session(selection.value)
        end
      end)
      
      -- Add mapping to open in new terminal tab
      map("i", "<C-t>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          local terminal_detect = require('neotex.plugins.ai.claude.claude-session.terminal-detection')
          local terminal_cmds = require('neotex.plugins.ai.claude.claude-session.terminal-commands')

          if not terminal_detect.supports_tabs() then
            local terminal_name = terminal_detect.get_display_name()
            local terminal_type = terminal_detect.detect()

            -- Provide specific guidance for Kitty remote control
            if terminal_type == 'kitty' then
              local config_path = terminal_detect.get_kitty_config_path()
              local config_status = terminal_detect.check_kitty_config()

              local message
              if config_status == false then
                message = string.format(
                  "Kitty remote control is disabled. Add 'allow_remote_control yes' to %s and restart Kitty.",
                  config_path
                )
              elseif config_status == nil then
                message = string.format(
                  "Kitty config not found. Create %s with 'allow_remote_control yes' and restart Kitty.",
                  config_path
                )
              else
                message = string.format(
                  "Kitty remote control configuration issue. Ensure 'allow_remote_control yes' is in %s and restart Kitty.",
                  config_path
                )
              end

              vim.notify(message, vim.log.levels.ERROR)
            else
              -- Generic error for non-Kitty terminals
              vim.notify(
                string.format(
                  "Terminal '%s' does not support tab management. Please use Kitty (with remote control enabled) or WezTerm.",
                  terminal_name
                ),
                vim.log.levels.ERROR
              )
            end
            return
          end

          -- Open in new terminal tab
          local session = selection.value
          local cmd = terminal_cmds.spawn_tab(
            session.path,
            string.format("bash -c 'claude --resume %s'", session.id)
          )

          if cmd then
            vim.fn.system(cmd)
            vim.notify(
              string.format(
                "Opened session in new %s tab",
                terminal_detect.get_display_name()
              ),
              vim.log.levels.INFO
            )
          else
            vim.notify("Failed to generate terminal command", vim.log.levels.ERROR)
          end
        end
      end)
      
      return true
    end,
  }):find()
end

-- Register the Claude session picker command
vim.api.nvim_create_user_command("ClaudeSessionPicker", M.claude_session_picker, {
  desc = "Pick and resume a Claude Code session"
})

-- Session Health Check & Auto-Recovery
-- Validates sessions, removes stale entries, and discovers untracked worktrees

-- Perform health check on all sessions
function M.health_check()
  local issues = {}
  local fixed = 0

  -- Check each session for validity
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

  -- Get list of actual git worktrees
  local worktrees = vim.fn.systemlist("git worktree list --porcelain")

  -- Get the main repository path to exclude it
  local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")

  -- Track which paths we already have sessions for
  local tracked_paths = {}
  for _, session in pairs(M.sessions) do
    tracked_paths[session.worktree_path] = true
  end

  -- Discover untracked worktrees
  local discovered = 0
  for i = 1, #worktrees, 3 do
    local path = worktrees[i] and worktrees[i]:match("^worktree (.+)")
    local branch_line = worktrees[i + 2]
    local branch = branch_line and branch_line:match("^branch (.+)")

    if path and branch and not tracked_paths[path] then
      -- Skip the main repository (compare path to git root)
      -- and skip main/master branches
      local is_main_repo = (path == git_root)
      local is_main_branch = branch:match("^refs/heads/main$") or
                             branch:match("^refs/heads/master$") or
                             branch:match("^refs/heads/main%s") or
                             branch:match("^refs/heads/master%s")

      if not is_main_repo and not is_main_branch then
        -- Extract feature name from branch
        local feature = branch:match("/([^/]+)$") or branch:gsub("^refs/heads/", "")
        local type = branch:match("^refs/heads/(%w+)/") or "feature"

        -- Create session for discovered worktree
        M.sessions[feature] = {
          worktree_path = path,
          branch = branch:gsub("^refs/heads/", ""),
          type = type,
          created = os.date("%Y-%m-%d %H:%M"),
          discovered = true,
          session_id = feature .. "-" .. os.time()
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

  -- Report results if issues were found
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

-- Generate detailed health report
function M.health_report()
  local issues = M.health_check()

  if #issues == 0 then
    vim.notify("All Claude sessions are healthy!", vim.log.levels.INFO)
    return
  end

  local lines = {
    "Claude Session Health Report",
    string.rep("=", 42),
    "",
    string.format("Timestamp: %s", os.date("%Y-%m-%d %H:%M:%S")),
    "",
    "Issues Found:",
    string.rep("-", 42),
    ""
  }

  -- Group issues by action
  local grouped = {
    removed = {},
    recovered = {}
  }
  
  for _, issue in ipairs(issues) do
    if grouped[issue.action] then
      table.insert(grouped[issue.action], issue)
    end
  end

  -- Add removed sessions
  if #grouped.removed > 0 then
    table.insert(lines, "Removed Stale Sessions:")
    for _, issue in ipairs(grouped.removed) do
      table.insert(lines, string.format("  • %s: %s", issue.session, issue.issue))
    end
    table.insert(lines, "")
  end

  -- Add recovered sessions
  if #grouped.recovered > 0 then
    table.insert(lines, "Recovered Worktrees:")
    for _, issue in ipairs(grouped.recovered) do
      table.insert(lines, string.format("  • %s: %s", issue.session, issue.issue))
    end
    table.insert(lines, "")
  end

  -- Add summary
  table.insert(lines, string.rep("-", 42))
  table.insert(lines, string.format("Total: %d issues processed", #issues))
  table.insert(lines, "")
  table.insert(lines, "Press 'q' or <Esc> to close")

  -- Create a floating window with the report
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

  local width = 50
  local height = math.min(#lines + 2, 25)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " 󰓙 Health Check ",
    title_pos = "center",
  })

  -- Add keymaps to close the window
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { silent = true })
  
  -- Set window options
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "wrap", false)
end

-- Register the health check command
vim.api.nvim_create_user_command("ClaudeSessionHealth", M.health_report, {
  desc = "Show Claude session health report"
})

-- Auto-run health check on startup (after a delay)
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("ClaudeWorktreeHealth", { clear = true }),
  callback = function()
    vim.defer_fn(function()
      -- Only run if we're in a git repository
      if vim.fn.isdirectory(".git") == 1 then
        -- Run health check silently (issues will be notified if found)
        local issues = M.health_check()
        
        -- Only show notification if we fixed or discovered something
        if #issues > 0 then
          local fixed = 0
          local discovered = 0
          for _, issue in ipairs(issues) do
            if issue.action == "removed" then
              fixed = fixed + 1
            elseif issue.action == "recovered" then
              discovered = discovered + 1
            end
          end
          
          if fixed > 0 or discovered > 0 then
            vim.notify(string.format(
              "Claude Worktree: %s%s",
              fixed > 0 and string.format("Fixed %d stale session(s)", fixed) or "",
              discovered > 0 and string.format("%sDiscovered %d worktree(s)", 
                fixed > 0 and ", " or "", discovered) or ""
            ), vim.log.levels.INFO)
          end
        end
      end
    end, 2000)  -- Run after 2 seconds to let Neovim fully initialize
  end,
})

return M