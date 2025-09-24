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
  
  return {
    session_id = first.sessionId,
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
function M.show_session_picker()
  local project_folder = M.get_project_folder()
  local sessions = M.get_sessions()
  
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
      local lines = {
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        " SESSION DETAILS",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "",
        "Session ID: " .. (session.session_id or "unknown"),
        "Branch: " .. (session.branch or "none"),
        "Messages: " .. tostring(session.message_count),
        "Created: " .. M.format_time_ago(session.created),
        "Updated: " .. M.format_time_ago(session.updated),
        "",
        "Last Message:",
        "────────────────────────────────────",
        session.last_message or "(empty)",
        "",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
        "",
        "Press <Enter> to resume this session",
      }
      
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_buf_call(self.state.bufnr, function()
        vim.cmd("setlocal filetype=markdown")
        vim.cmd("setlocal wrap")
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
          
          -- Resume with specific session ID
          vim.notify("Resuming session: " .. session.session_id:sub(1, 8) .. "...", vim.log.levels.INFO)

          -- Store the session ID so we can use it
          vim.g.claude_resume_session_id = session.session_id

          -- Use ClaudeCodeResume which should handle resuming
          vim.cmd("ClaudeCodeResume")

          -- After a short delay, send the session ID to the terminal
          vim.defer_fn(function()
            -- Find the Claude terminal buffer
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              if vim.api.nvim_buf_is_valid(buf) then
                local bufname = vim.api.nvim_buf_get_name(buf)
                if bufname:match("claude") or bufname:match("ClaudeCode") then
                  -- Get the terminal channel
                  local chan = vim.api.nvim_buf_get_option(buf, "channel")
                  if chan and chan > 0 then
                    -- Send the session ID
                    vim.api.nvim_chan_send(chan, session.session_id .. "\n")
                    break
                  end
                end
              end
            end

            -- Save state and enter insert mode
            require("neotex.core.claude-session").save_session_state()
            vim.cmd("startinsert")
          end, 500)
        end
      end)
      return true
    end,
  }):find()
end

return M