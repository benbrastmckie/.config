-- neotex.core.claude-sessions-picker
-- Native Telescope picker for Claude sessions

local M = {}

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
          require("neotex.core.claude-session").save_session_state()
        end
      end)
      return true
    end,
  }):find()
end

return M