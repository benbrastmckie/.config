-- neotex.core.claude-session
-- Enhanced Claude Code session management with automatic restoration
-- Tracks active sessions and offers to restore them when nvim reopens

local M = {}
local Path = require("plenary.path")

-- Session state file location
local state_dir = vim.fn.stdpath("data") .. "/claude"
local state_file = state_dir .. "/last_session.json"

-- Ensure state directory exists
local function ensure_state_dir()
  local dir = Path:new(state_dir)
  if not dir:exists() then
    dir:mkdir({ parents = true })
  end
end

-- Save current working directory and timestamp
function M.save_session_state()
  -- Use session manager for robust state saving
  local session_manager = require("neotex.ai-claude.core.session-manager")

  local state = {
    cwd = vim.fn.getcwd(),
    timestamp = os.time(),
    git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", ""),
    branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", ""),
  }

  -- Use the session manager's save_state method with validation
  return session_manager.save_state(state)
end

-- Load last session state
function M.load_session_state()
  local file = io.open(state_file, "r")
  if not file then
    return nil
  end
  
  local content = file:read("*all")
  file:close()
  
  if content == "" then
    return nil
  end
  
  local ok, state = pcall(vim.fn.json_decode, content)
  if not ok then
    return nil
  end
  
  return state
end

-- Get Claude CLI session list
function M.get_claude_sessions()
  local result = vim.fn.system("claude --list-sessions 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    -- Try alternative command format
    result = vim.fn.system("claude list 2>/dev/null")
    if vim.v.shell_error ~= 0 then
      return nil
    end
  end
  return result
end

-- Check if there's a recent session to restore
function M.check_for_recent_session()
  -- First validate the state file
  local session_manager = require("neotex.ai-claude.core.session-manager")
  local valid, state = session_manager.validate_state_file()

  if not valid or not state then
    state = M.load_session_state()
    if not state then
      return false
    end
  end

  -- Enhanced directory and git repo validation for worktrees
  local current_cwd = vim.fn.getcwd()
  local current_git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")

  -- Check if we're in a worktree
  local is_worktree = false
  local main_repo_path = current_git_root

  if current_git_root ~= "" then
    local worktree_list = vim.fn.system("git worktree list --porcelain 2>/dev/null")
    if not worktree_list:match("^fatal:") then
      -- Parse to find the main worktree
      for line in worktree_list:gmatch("[^\r\n]+") do
        if line:match("^worktree ") then
          local path = line:match("^worktree (.+)$")
          if path and path ~= current_cwd then
            is_worktree = true
          end
        elseif line:match("^bare$") then
          -- This is a bare repository, find the actual main worktree
          is_worktree = true
        end
      end
    end
  end

  -- More flexible directory matching for worktrees
  local dir_match = false
  if state.cwd == current_cwd then
    dir_match = true
  elseif state.git_root ~= "" and current_git_root ~= "" then
    -- If both are in git repos, check if they're the same or related (worktrees)
    if state.git_root == current_git_root then
      dir_match = true
    elseif is_worktree then
      -- For worktrees, check if they share the same base repository
      local state_is_worktree = state.cwd:match("%-feature%-") or state.cwd:match("%-bugfix%-") or state.cwd:match("%-refactor%-")
      if state_is_worktree then
        -- Extract base repo name from both paths
        local current_base = current_cwd:match(".*/([^/]+)%-[^/]+%-[^/]+$") or current_cwd:match(".*/([^/]+)$")
        local state_base = state.cwd:match(".*/([^/]+)%-[^/]+%-[^/]+$") or state.cwd:match(".*/([^/]+)$")
        if current_base and state_base and current_base == state_base then
          dir_match = true
        end
      end
    end
  end

  if not dir_match then
    return false
  end
  
  -- Check if session is recent (within last 24 hours)
  local age_hours = (os.time() - state.timestamp) / 3600
  if age_hours > 24 then
    return false
  end
  
  return true, age_hours
end

-- Create preview content for session options
function M.create_preview_content(option_type, state_data, preview_width)
  local lines = {}
  -- Use preview width if provided, otherwise default to 80
  local max_width = math.max(40, (preview_width or 80) - 5)  -- Leave some padding
  
  if option_type == "continue" then
    if state_data then
      table.insert(lines, string.rep("━", max_width))
      table.insert(lines, " CONTINUE LAST SESSION")
      table.insert(lines, string.rep("━", max_width))
      table.insert(lines, "")
      table.insert(lines, "Directory: " .. (state_data.cwd or "Unknown"))
      table.insert(lines, "Git Branch: " .. (state_data.branch ~= "" and state_data.branch or "Not in git repo"))
      
      local timestamp = state_data.timestamp
      if timestamp then
        local age_hours = (os.time() - timestamp) / 3600
        local age_text
        if age_hours < 1 then
          age_text = string.format("%d minutes ago", math.floor(age_hours * 60))
        elseif age_hours < 24 then
          age_text = string.format("%.1f hours ago", age_hours)
        else
          age_text = string.format("%.0f days ago", age_hours / 24)
        end
        table.insert(lines, "Last Active: " .. age_text)
        table.insert(lines, "Date: " .. os.date("%Y-%m-%d %H:%M:%S", timestamp))
      end
      
      table.insert(lines, "")
      table.insert(lines, "Action: Resume your conversation from")
      table.insert(lines, "        where you left off")
    else
      table.insert(lines, "No recent session information available")
    end
    
  elseif option_type == "resume" then
    table.insert(lines, string.rep("━", max_width))
    table.insert(lines, " BROWSE ALL SESSIONS")
    table.insert(lines, string.rep("━", max_width))
    table.insert(lines, "")
    
    -- Try to get actual sessions from the native module
    local ok, native_sessions = pcall(require, "neotex.core.claude-native-sessions")
    if ok then
      local sessions = native_sessions.get_sessions()
      if #sessions > 0 then
        table.insert(lines, "Recent Sessions in this project:")
        table.insert(lines, string.rep("━", max_width))
        table.insert(lines, "")
        
        for i, session in ipairs(sessions) do
          if i <= 3 then  -- Show first 3 sessions with detail
            local time_ago = native_sessions.format_time_ago(session.updated)
            
            -- Session header
            table.insert(lines, string.format("▸ %s • %d messages", 
              time_ago, session.message_count or 0))
            
            -- Message preview with word wrapping
            if session.last_message and session.last_message ~= "" then
              local msg = session.last_message:gsub("\n", " ")
              -- Wrap text dynamically based on available width, show up to 3 lines
              local wrap_width = max_width - 2  -- Account for indentation
              local wrapped_lines = {}
              local current_line = ""
              
              for word in msg:gmatch("%S+") do
                if #current_line + #word + 1 <= wrap_width then
                  current_line = current_line == "" and word or current_line .. " " .. word
                else
                  if #wrapped_lines < 3 then
                    table.insert(wrapped_lines, current_line)
                    current_line = word
                  else
                    break
                  end
                end
              end
              
              -- Add the last line if there's room
              if current_line ~= "" and #wrapped_lines < 3 then
                table.insert(wrapped_lines, current_line)
              end
              
              -- Add wrapped lines with indentation
              for _, line in ipairs(wrapped_lines) do
                table.insert(lines, "  " .. line)
              end
              
              -- Add ellipsis if message was truncated
              if #msg > (wrap_width * 3) then  -- 3 lines * wrap_width chars
                table.insert(lines, "  ...")
              end
            else
              table.insert(lines, "  (no message content)")
            end
            
            -- Separator between sessions (dynamic width)
            if i < math.min(3, #sessions) then
              table.insert(lines, string.rep("─", max_width))
            end
          end
        end
        
        if #sessions > 3 then
          table.insert(lines, string.rep("─", max_width))
          table.insert(lines, string.format("... and %d more sessions", #sessions - 3))
        end
        
        table.insert(lines, "")
        table.insert(lines, "Action: Opens Telescope picker to")
        table.insert(lines, "        browse and select sessions")
      else
        table.insert(lines, "No sessions found in current project")
        table.insert(lines, "")
        table.insert(lines, "This will open an empty picker.")
        table.insert(lines, "Start a new session first to create")
        table.insert(lines, "session history.")
      end
    else
      table.insert(lines, "Session browser will open when selected")
    end
    
  elseif option_type == "new" then
    table.insert(lines, string.rep("━", max_width))
    table.insert(lines, " START NEW SESSION")
    table.insert(lines, string.rep("━", max_width))
    table.insert(lines, "")
    table.insert(lines, "Begin a fresh Claude conversation")
    table.insert(lines, "")
    table.insert(lines, "Current Context:")
    table.insert(lines, "  Directory: " .. vim.fn.getcwd())
    
    local git_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
    if git_branch ~= "" then
      table.insert(lines, "  Git Branch: " .. git_branch)
    end
    
    table.insert(lines, "")
    table.insert(lines, "This will start Claude Code with a")
    table.insert(lines, "clean slate - no previous context")
  end
  
  return lines
end

-- Show Telescope picker for session restoration
function M.show_session_picker()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values

  local has_session, age_hours = M.check_for_recent_session()
  
  local age_text = ""
  if has_session then
    if age_hours < 1 then
      age_text = string.format("%d minutes ago", math.floor(age_hours * 60))
    else
      age_text = string.format("%.1f hours ago", age_hours)
    end
  end
  
  local options = {
    {
      display = "Restore previous session" .. (age_text ~= "" and " (" .. age_text .. ")" or ""),
      value = "continue",
      icon = "󰊢",
      desc = "Resume your most recent Claude conversation"
    },
    {
      display = "Create new session",
      value = "new",
      icon = "󰈔",
      desc = "Begin a fresh Claude conversation"
    },
    {
      display = "Browse all sessions",
      value = "browse",
      icon = "󰑐",
      desc = "Open the full session browser"
    },
  }
  
  pickers.new(require("telescope.themes").get_dropdown({
    winblend = 10,
    width = 0.5,
    previewer = false,
    layout_config = {
      width = 60,
      height = 10,
    },
  }), {
    prompt_title = "Claude Session",
    finder = finders.new_table({
      results = options,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.icon .. "  " .. entry.display,
          ordinal = entry.display,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local choice = selection.value.value
          if choice == "continue" then
            local claude_util = require("neotex.ai-claude.utils.claude-code")
            if claude_util.continue() then
              M.save_session_state()
              -- Auto-enter insert mode
              vim.defer_fn(function()
                vim.cmd("startinsert")
              end, 100)
            end
          elseif choice == "browse" then
            -- Show all sessions directly using native picker
            require("neotex.ai-claude.ui.native-sessions").show_session_picker()
          elseif choice == "new" then
            local claude_util = require("neotex.ai-claude.utils.claude-code")
            if claude_util.open() then
              M.save_session_state()
              -- Auto-enter insert mode
              vim.defer_fn(function()
                vim.cmd("startinsert")
              end, 100)
            end
          end
        end
      end)
      return true
    end,
  }):find()
end

-- Quick continue last session
function M.continue_session()
  vim.cmd("ClaudeCodeContinue")
  M.save_session_state()
  -- Auto-enter insert mode
  vim.defer_fn(function()
    vim.cmd("startinsert")
  end, 100)
end

-- Quick resume with picker
function M.resume_session()
  -- Use our native session picker with actual session IDs
  require("neotex.ai-claude.ui.native-sessions").show_session_picker()
end

-- Toggle Claude Code with smart session handling
function M.smart_toggle()
  -- Use session manager for precise buffer detection
  local session_manager = require("neotex.ai-claude.core.session-manager")
  local claude_buffers = session_manager.detect_claude_buffers()
  local claude_buf_exists = #claude_buffers > 0

  if claude_buf_exists then
    -- Just toggle the existing session
    vim.cmd("ClaudeCode")
  else
    -- No active session, check for recent one and show picker
    local has_session = M.check_for_recent_session()
    if has_session then
      -- Show the 3-option menu when there's a previous session
      M.show_session_picker()
    else
      -- No recent session, just start new
      vim.cmd("ClaudeCode")
      M.save_session_state()
    end
  end
end

-- Setup autocmds and keymaps
function M.setup()
  -- Create autocmd group
  local group = vim.api.nvim_create_augroup("ClaudeSession", { clear = true })
  
  -- Save session state when opening Claude terminal
  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    pattern = "*claude*",
    callback = function()
      M.save_session_state()
    end,
  })
  
  -- Save session state periodically while Claude is active
  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      -- Check if any Claude buffer exists
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if name:match("claude") then
          M.save_session_state()
          break
        end
      end
    end,
  })
  
end

return M