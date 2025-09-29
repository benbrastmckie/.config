-- neotex.core.claude-native-sessions
-- Native session management using Claude's actual session files

local M = {}

-- Get the project folder for the current directory
function M.get_project_folder()
  local cwd = vim.fn.getcwd()

  -- First check if we're in a git repo and use its root
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  local project_path = cwd

  if git_root ~= "" and not git_root:match("^fatal:") then
    project_path = git_root

    -- Check if this is a git worktree, and if so, use the main repository path
    local worktree_list = vim.fn.system("git worktree list 2>/dev/null")
    if not worktree_list:match("^fatal:") then
      -- Parse worktree list to find the main repository
      for line in worktree_list:gmatch("[^\r\n]+") do
        local path, branch = line:match("^([^%s]+)%s+[^%s]+%s+%[([^%]]+)%]")
        if branch == "master" or branch == "main" then
          project_path = path
          break
        end
      end
    end
  end

  -- Replace slashes with dashes and dots with double dashes
  -- Handle the specific pattern where /. becomes --
  local step1 = project_path:gsub("/", "-")
  local folder_name = step1:gsub("-%.", "--")
  return vim.fn.expand("~/.claude/projects/" .. folder_name)
end

-- Parse a JSONL session file to get metadata
function M.parse_session_file(filepath)
  local file = io.open(filepath, "r")
  if not file then return nil end
  
  local first_line = file:read("*l")
  local last_line = nil
  local line_count = 1
  
  -- Read through to get last line
  for line in file:lines() do
    last_line = line
    line_count = line_count + 1
  end
  file:close()
  
  if not first_line or not last_line then return nil end
  
  -- Parse JSON
  local ok_first, first = pcall(vim.fn.json_decode, first_line)
  local ok_last, last = pcall(vim.fn.json_decode, last_line)
  
  if not ok_first or not ok_last then return nil end
  
  -- Safely extract last message
  local last_msg = ""
  if last.message then
    if type(last.message) == "string" then
      last_msg = last.message:gsub("\n", " "):sub(1, 80)
    elseif type(last.message) == "table" then
      -- Check for different message structures
      local content = last.message.content
      if type(content) == "string" then
        -- Direct string content
        last_msg = content:gsub("\n", " "):sub(1, 80)
      elseif type(content) == "table" then
        -- Content is an array of content blocks
        if content[1] and content[1].text then
          -- Extract text from first content block
          last_msg = content[1].text:gsub("\n", " "):sub(1, 80)
        elseif content[1] and content[1].content then
          -- Sometimes nested differently
          last_msg = tostring(content[1].content):gsub("\n", " "):sub(1, 80)
        else
          -- Fallback: try to find any text field
          for _, item in ipairs(content) do
            if item.text then
              last_msg = item.text:gsub("\n", " "):sub(1, 80)
              break
            end
          end
        end
      end
    end
  end
  
  -- Try to get session ID from the JSON data first, then fallback to filename
  local session_id = first.sessionId
  if not session_id then
    -- Extract from filename (filepath is like /path/to/session-id.jsonl)
    session_id = vim.fn.fnamemodify(filepath, ":t:r")
  end

  return {
    session_id = session_id,
    created = first.timestamp,
    updated = last.timestamp,
    branch = last.gitBranch or first.gitBranch,
    cwd = first.cwd,
    message_count = line_count,
    last_message = last_msg,
    type = last.type
  }
end

-- Get all sessions for current project
function M.get_sessions()
  local project_folder = M.get_project_folder()

  if vim.fn.isdirectory(project_folder) == 0 then
    return {}
  end

  local sessions = {}
  local files = vim.fn.glob(project_folder .. "/*.jsonl", false, true)

  for _, filepath in ipairs(files) do
    local session = M.parse_session_file(filepath)
    if session then
      -- Extract session ID from filename if not present in the data
      if not session.session_id then
        local filename = vim.fn.fnamemodify(filepath, ":t:r") -- Get filename without extension
        session.session_id = filename
      end
      table.insert(sessions, session)
    end
  end
  
  -- Sort by updated timestamp (most recent first)
  -- ISO 8601 timestamps sort correctly lexicographically
  table.sort(sessions, function(a, b)
    return (a.updated or "") > (b.updated or "")
  end)
  
  return sessions
end

-- Parse ISO 8601 timestamp to Unix time
local function parse_iso_timestamp(iso_str)
  if not iso_str then return nil end
  
  -- Parse ISO 8601 format: "2025-09-16T07:46:57.569Z"
  -- The Z means UTC time
  local year, month, day, hour, min, sec = iso_str:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not year then return nil end
  
  -- os.time() assumes the input is local time
  -- Since we have UTC, we need to use os.time with UTC values
  -- and then adjust for the local timezone
  
  -- First, get the current timezone offset
  local current_time = os.time()
  local utc_date = os.date("!*t", current_time)
  local local_date = os.date("*t", current_time)
  
  -- Calculate timezone offset in seconds
  local utc_now = os.time(utc_date)
  local local_now = os.time(local_date)
  local tz_offset = utc_now - local_now
  
  -- Create the timestamp as if it were local time
  local timestamp = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec)
  })
  
  -- Adjust for timezone difference
  return timestamp - tz_offset
end

-- Format time difference
function M.format_time_ago(timestamp)
  if not timestamp then return "unknown" end
  
  local ts
  -- Check if it's already a number (milliseconds)
  if type(timestamp) == "number" then
    ts = timestamp / 1000  -- Convert to seconds
  else
    -- Parse ISO 8601 string
    ts = parse_iso_timestamp(timestamp)
  end
  
  if not ts then return "unknown" end
  
  local now = os.time()
  local diff = now - ts
  
  -- Handle negative differences (future timestamps)
  if diff < 0 then
    return "future"  -- Shouldn't happen with proper timezone handling
  end
  
  local minutes = math.floor(diff / 60)
  local hours = math.floor(minutes / 60)
  local days = math.floor(hours / 24)
  
  if days >= 7 then
    local weeks = math.floor(days / 7)
    return string.format("%d week%s ago", weeks, weeks == 1 and "" or "s")
  elseif days >= 2 then
    return string.format("%d days ago", days)
  elseif days == 1 then
    return "1 day ago"
  elseif hours >= 2 then
    return string.format("%d hours ago", hours)
  elseif hours == 1 then
    return "1 hour ago"
  elseif minutes >= 2 then
    return string.format("%d mins ago", minutes)
  elseif minutes == 1 then
    return "1 min ago"
  elseif diff >= 30 then
    return string.format("%d secs ago", diff)
  else
    return "just now"
  end
end

-- Show Telescope picker for native Claude sessions
function M.show_session_picker(override_sessions, on_select_callback)
  local project_folder = M.get_project_folder()
  local sessions = override_sessions or M.get_sessions()
  
  if #sessions == 0 then
    -- Debug info
    local cwd = vim.fn.getcwd()
    vim.notify(string.format("No sessions found in: %s\nCWD: %s", project_folder, cwd), vim.log.levels.INFO)
    return
  end
  
  -- Debug: Show which folder we're reading from (only in debug mode)
  -- vim.notify("Loading sessions from: " .. project_folder, vim.log.levels.INFO)
  
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
      local lines = {}

      -- Get preview window width for text wrapping
      local preview_width = vim.api.nvim_win_get_width(self.state.winid) or 80

      -- Helper function to wrap text
      local function wrap_text(text, width)
        if not text or text == "" then return {} end
        if #text <= width then return { text } end

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

      -- Compact header
      table.insert(lines, " SESSION DETAILS")
      table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
      table.insert(lines, "")
      table.insert(lines, string.format("Session ID: %s", session.session_id and session.session_id:sub(1, 36) or "unknown"))
      table.insert(lines, string.format("Branch: %s", session.branch or "master"))
      table.insert(lines, string.format("Messages: %d", session.message_count or 0))
      table.insert(lines, string.format("Created: %s", M.format_time_ago(session.created)))
      table.insert(lines, string.format("Updated: %s", M.format_time_ago(session.updated)))
      table.insert(lines, "")
      table.insert(lines, "Last Message:")
      table.insert(lines, "────────────────────────────────────")

      -- Show the full last message with proper wrapping
      if session.last_message and session.last_message ~= "" then
        -- The last_message is already truncated in parse_session_file, let's get the full one
        -- Check if session_id exists before trying to build path
        if session.session_id then
          local session_file = project_folder .. "/" .. session.session_id .. ".jsonl"
          if vim.fn.filereadable(session_file) == 1 then
          -- Read the actual conversation file for full content
          local conversation_lines = vim.fn.readfile(session_file)
          if #conversation_lines > 0 then
            -- Get the last several messages for context
            local messages = {}
            local start_idx = math.max(1, #conversation_lines - 20)

            for i = start_idx, #conversation_lines do
              local line = conversation_lines[i]
              if line and line ~= "" then
                -- Try proper JSON decode
                local ok, decoded = pcall(vim.fn.json_decode, line)
                if ok and decoded then
                  local content = ""
                  local role = decoded.role or "unknown"

                  -- Extract content from various message formats
                  if decoded.message then
                    if type(decoded.message) == "string" then
                      content = decoded.message
                    elseif type(decoded.message) == "table" then
                      if decoded.message.content then
                        if type(decoded.message.content) == "string" then
                          content = decoded.message.content
                        elseif type(decoded.message.content) == "table" then
                          -- Handle content blocks
                          for _, block in ipairs(decoded.message.content) do
                            if block.text then
                              content = content .. (content ~= "" and "\n" or "") .. block.text
                            elseif block.content then
                              content = content .. (content ~= "" and "\n" or "") .. tostring(block.content)
                            end
                          end
                        end
                      end
                    end
                  elseif decoded.content then
                    -- Direct content field
                    if type(decoded.content) == "string" then
                      content = decoded.content
                    elseif type(decoded.content) == "table" then
                      content = vim.inspect(decoded.content)
                    end
                  end

                  if content ~= "" then
                    table.insert(messages, { role = role, content = content })
                  end
                end
              end
            end

            -- Display messages with full width wrapping
            for _, msg in ipairs(messages) do
              if msg.role == "user" or msg.role == "human" then
                table.insert(lines, "")
                table.insert(lines, "👤 USER:")
              elseif msg.role == "assistant" or msg.role == "claude" then
                table.insert(lines, "")
                table.insert(lines, "🤖 CLAUDE:")
              else
                table.insert(lines, "")
                table.insert(lines, msg.role .. ":")
              end

              -- Handle newlines and wrap each line to full width
              local content_lines = vim.split(msg.content, "\n", { plain = true })
              for _, content_line in ipairs(content_lines) do
                if #content_line > preview_width then
                  -- Wrap long lines to full preview width
                  local wrapped = wrap_text(content_line, preview_width)
                  for _, wrapped_line in ipairs(wrapped) do
                    table.insert(lines, wrapped_line)
                  end
                else
                  table.insert(lines, content_line)
                end
              end
            end
          end
          else
            -- Session file not readable, fallback to truncated message
            local message_lines = vim.split(session.last_message, "\n", { plain = true })
            for _, msg_line in ipairs(message_lines) do
              if #msg_line > preview_width then
                local wrapped = wrap_text(msg_line, preview_width)
                for _, wrapped_line in ipairs(wrapped) do
                  table.insert(lines, wrapped_line)
                end
              else
                table.insert(lines, msg_line)
              end
            end
          end
        else
          -- No session_id, just show the truncated last_message
          local message_lines = vim.split(session.last_message, "\n", { plain = true })
          for _, msg_line in ipairs(message_lines) do
            if #msg_line > preview_width then
              local wrapped = wrap_text(msg_line, preview_width)
              for _, wrapped_line in ipairs(wrapped) do
                table.insert(lines, wrapped_line)
              end
            else
              table.insert(lines, msg_line)
            end
          end
        end
      else
        table.insert(lines, "(no message)")
      end

      table.insert(lines, "")
      table.insert(lines, "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
      table.insert(lines, "")
      table.insert(lines, "Press <Enter> to resume this session")

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_call(self.state.bufnr, function()
        vim.opt_local.filetype = "markdown"
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = false  -- No indent for full width
        vim.opt_local.conceallevel = 0
      end)
    end,
  })
  
  pickers.new({}, {
    prompt_title = "Claude Sessions (Native)",
    finder = finders.new_table({
      results = sessions,
      entry_maker = function(session)
        local msg_preview = "(no message)"
        if session.last_message and session.last_message ~= "" then
          msg_preview = session.last_message:sub(1, 50)
        end
        
        local display = string.format(
          "%-15s │ %3d msgs │ %-10s │ %s",
          M.format_time_ago(session.updated),
          session.message_count,
          session.branch or "no-branch",
          msg_preview
        )
        return {
          value = session,
          display = display,
          ordinal = (session.last_message or "") .. " " .. (session.branch or ""),
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewer,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.value.session_id then
          local session = selection.value

          -- If a custom callback was provided, use it
          if on_select_callback then
            on_select_callback(session)
          else
            -- Default resume behavior
            -- Resume with specific session ID
            local notify = require("neotex.util.notifications")

            notify.notify(
              string.format("Resuming session: %s...", session.session_id:sub(1, 8)),
              notify.categories.USER_ACTION,
              { module = "ai-claude", action = "resume_session" }
            )

            -- The claude-code.nvim plugin doesn't support direct session ID resuming
            -- We need to use the interactive flow: open ClaudeCode and then send the session ID

            -- First check if ClaudeCode command exists
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

            -- Use session manager for validated resumption
            local session_manager = require("neotex.ai-claude.core.session-manager")
            local success, error_msg = session_manager.resume_session(session.session_id)

            if not success and error_msg then
              notify.notify(
                "Failed to resume session: " .. error_msg,
                notify.categories.ERROR,
                { module = "ai-claude" }
              )
            elseif success then
              -- Enter insert mode after a short delay
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

return M