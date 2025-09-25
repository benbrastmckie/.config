-- neotex.ai-claude.ui.pickers
-- Telescope pickers for Claude sessions

local M = {}

-- Configuration
M.config = {
  simple_picker_max = 3,  -- Maximum sessions to show in simple picker
}

-- Parse Claude session list output
function M.parse_sessions(output)
  local sessions = {}
  local lines = vim.split(output, "\n")
  
  -- Skip header and parse session lines
  for i, line in ipairs(lines) do
    if i > 1 and line ~= "" and line:match("%d+%.") then
      -- Parse session line format: "1. 26s ago      29s ago           3 master                   delete /home/benjamin/..."
      local num, modified, created, msgs, branch, summary = line:match("(%d+)%.%s+([%w%s]+ago)%s+([%w%s]+ago)%s+(%d+)%s+([%w%-%./_]+)%s+(.*)")
      
      if num then
        -- Extract session ID from the full output if available
        -- We'll need to run claude --resume and parse the selection
        table.insert(sessions, {
          number = tonumber(num),
          modified = modified,
          created = created,
          messages = msgs,
          branch = branch,
          summary = vim.trim(summary or ""),
          line = line
        })
      end
    end
  end
  
  return sessions
end

-- Get session ID by number selection
function M.get_session_id_by_number(number)
  -- Run claude --resume in non-interactive mode to get session list with IDs
  local output = vim.fn.system("claude --resume --non-interactive 2>&1 || true")
  
  -- Try to extract session ID for the selected number
  -- This is a workaround since Claude CLI doesn't provide direct session ID listing
  -- We simulate the selection
  local simulate_cmd = string.format("echo '%d' | claude --resume 2>&1 | head -1", number)
  local result = vim.fn.system(simulate_cmd)
  
  -- Extract session ID from the output if possible
  local session_id = result:match("([a-f0-9%-]+)")
  return session_id
end

-- Show Telescope picker for Claude sessions
function M.show_picker()
  -- Get session list
  local output = vim.fn.system("claude --resume --list 2>/dev/null || claude --resume 2>&1 | head -20")
  
  if vim.v.shell_error ~= 0 or output == "" then
    vim.notify("No Claude sessions available", vim.log.levels.WARN)
    return
  end
  
  local sessions = M.parse_sessions(output)
  
  if #sessions == 0 then
    vim.notify("No Claude sessions found", vim.log.levels.INFO)
    return
  end
  
  -- Create Telescope picker
  local telescope = require("telescope")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  
  -- Create previewer
  local previewer = previewers.new_buffer_previewer({
    title = "Session Details",
    define_preview = function(self, entry, status)
      local session = entry.value
      local lines = {
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        " SESSION DETAILS",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "",
        "Summary: " .. session.summary,
        "Branch: " .. session.branch,
        "Messages: " .. session.messages,
        "Modified: " .. session.modified,
        "Created: " .. session.created,
        "",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "",
        "Press <Enter> to resume this session",
        "Press <Esc> to cancel",
      }
      
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_call(self.state.bufnr, function()
        vim.cmd("setlocal filetype=markdown")
        vim.cmd("setlocal wrap")
      end)
    end,
  })
  
  pickers.new({}, {
    prompt_title = "Claude Sessions",
    finder = finders.new_table({
      results = sessions,
      entry_maker = function(session)
        local display = string.format(
          "%2d. %-12s │ %-8s msgs │ %-15s │ %s",
          session.number,
          session.modified,
          session.messages,
          session.branch,
          session.summary:sub(1, 40)
        )
        return {
          value = session,
          display = display,
          ordinal = session.summary .. " " .. session.branch,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local session = selection.value
          -- Try to resume by simulating selection
          vim.notify("Resuming session " .. session.number .. "...", vim.log.levels.INFO)
          
          -- Use a trick: write the selection number to a temp file and pipe it
          local temp_file = vim.fn.tempname()
          local file = io.open(temp_file, "w")
          file:write(tostring(session.number) .. "\n")
          file:close()
          
          -- Run claude resume with the selection
          vim.cmd(string.format("ClaudeCode < %s --resume", temp_file))
          
          -- Clean up
          vim.defer_fn(function()
            os.remove(temp_file)
            -- Enter insert mode
            vim.cmd("startinsert")
          end, 200)
          
          -- Save session state
          require("neotex.ai-claude.core.session").save_session_state()
        end
      end)
      return true
    end,
  }):find()
end

-- Simple session picker (shows limited options)
function M.simple_session_picker(on_select)
  local native_sessions = require("neotex.ai-claude.ui.native-sessions")
  local sessions = native_sessions.get_sessions()

  if #sessions == 0 then
    -- No sessions, just start a new one
    vim.cmd("ClaudeCode")
    require("neotex.ai-claude.core.session").save_session_state()
    return
  end

  local display_sessions = sessions

  -- Filter to top N sessions if many exist
  if #sessions > M.config.simple_picker_max then
    display_sessions = {}

    -- Add the first N sessions
    for i = 1, M.config.simple_picker_max do
      table.insert(display_sessions, sessions[i])
    end

    -- Add "Show all" option
    table.insert(display_sessions, {
      session_id = "show_all",  -- Changed from 'id' to 'session_id' for consistency
      name = string.format("Show all %d sessions...", #sessions),
      is_special = true,
      updated = os.time(),
      message_count = 0,
      last_message = "Opens the full session browser",
    })
  end

  -- If no callback provided, let native sessions handle the resume
  if not on_select then
    -- Only pass callback if we need to handle "show_all"
    if #sessions > M.config.simple_picker_max then
      -- We have "show_all" option, need custom callback
      native_sessions.show_session_picker(display_sessions, function(selected)
        if selected and selected.is_special and selected.session_id == "show_all" then
          -- Show full picker with all sessions, no callback = use default resume
          native_sessions.show_session_picker(nil)  -- nil = get all sessions, no callback = default behavior
        else
          -- Not "show_all", trigger default resume behavior manually
          local notify = require("neotex.util.notifications")

          notify.notify(
            string.format("Resuming session: %s...", selected.session_id:sub(1, 8)),
            notify.categories.USER_ACTION,
            { module = "ai-claude", action = "resume_session" }
          )

          -- Check if ClaudeCode command exists
          local has_claude_code = vim.fn.exists(":ClaudeCode") == 2

          if not has_claude_code then
            notify.notify(
              "ClaudeCode command not found. Is claude-code.nvim plugin installed?",
              notify.categories.ERROR,
              {
                module = "ai-claude",
                details = "The :ClaudeCode command is not available. Check that the claude-code.nvim plugin is installed and loaded correctly."
              }
            )
            return
          end

          -- Use our cleaner utility function to resume the session
          local claude_util = require("neotex.ai-claude.utils.claude-code")
          local success = claude_util.resume_session(selected.session_id)

          if success then
            -- Save state and enter insert mode after a short delay
            vim.defer_fn(function()
              require("neotex.ai-claude.core.session").save_session_state()
              vim.cmd("startinsert")
            end, 100)
          end
        end
      end)
    else
      -- No "show_all" option, just show the picker with default behavior
      native_sessions.show_session_picker(display_sessions)
    end
  else
    -- Custom callback provided, use it
    native_sessions.show_session_picker(display_sessions, function(selected)
      if selected and selected.is_special and selected.session_id == "show_all" then
        -- Show full picker with custom callback
        native_sessions.show_session_picker(sessions, on_select)
      else
        on_select(selected)
      end
    end)
  end
end

-- Full session picker (shows all sessions)
function M.full_session_picker(on_select)
  local native_sessions = require("neotex.ai-claude.ui.native-sessions")
  native_sessions.show_session_picker(nil, on_select)
end

return M