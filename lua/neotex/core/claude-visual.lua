--------------------------------------------------------------------------------
-- Claude Visual Selection Integration
--------------------------------------------------------------------------------
-- Improved implementation with proper state management and terminal lifecycle
-- Fixes timing issues and provides robust message delivery

local M = {}

-- State tracking
local ClaudeTerminalState = {
  CLOSED = 0,
  OPENING = 1,
  READY = 2,
  BUSY = 3
}

local terminal_state = ClaudeTerminalState.CLOSED
local pending_message = nil

-- Configuration
M.config = {
  -- Timeout waiting for terminal to be ready (ms)
  ready_timeout = 5000,

  -- Auto-retry failed sends
  auto_retry = true,
  max_retries = 3,

  -- Default prompt when none provided
  default_prompt = "Please help me with this code:",

  -- Show progress notifications
  show_progress = true,

  -- Clear terminal input before sending
  clear_before_send = true,

  -- Focus Claude window after sending
  auto_focus = true,

  -- Enter insert mode after sending
  auto_insert = true
}

-- Error types for consistent handling
local ErrorType = {
  TERMINAL_NOT_FOUND = "Terminal not found",
  CHANNEL_NOT_READY = "Channel not ready",
  TIMEOUT = "Operation timed out",
  SEND_FAILED = "Failed to send message"
}

-- Helper function to get visual selection text
local function get_visual_selection()
  -- Get the visual selection marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]

  -- Check if we have valid marks (they exist and are different from default)
  if start_line == 0 or end_line == 0 or start_line > end_line then
    return ""
  end

  -- Additional check: ensure we're not getting stale marks
  -- If start and end are the same position, likely no selection
  if start_line == end_line and start_col == end_col then
    return ""
  end

  -- Get the lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    return ""
  end

  -- Handle single line selection
  if #lines == 1 then
    -- For single line, ensure end_col is greater than start_col
    if end_col < start_col then
      return ""
    end
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    -- Handle multi-line selection
    lines[1] = string.sub(lines[1], start_col)
    if #lines > 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end

  local result = table.concat(lines, '\n')

  -- Trim empty result or whitespace-only result
  if result == "" or result:match("^%s*$") then
    return ""
  end

  return result
end

-- Function to find Claude terminal buffer
local function find_claude_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      local buftype = vim.bo[buf].buftype
      -- Look for claude in the buffer name and ensure it's a terminal
      if buftype == "terminal" and (bufname:match("claude") or bufname:match("ClaudeCode")) then
        return buf
      end
    end
  end
  return nil
end

-- Function to focus Claude window
local function focus_claude_window(claude_buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == claude_buf then
      vim.api.nvim_set_current_win(win)
      return true
    end
  end
  return false
end

-- Enhanced message formatting
function M.format_message(text, prompt)
  local parts = {}

  -- Add prompt if provided
  if prompt and prompt ~= "" then
    table.insert(parts, prompt)
  else
    table.insert(parts, M.config.default_prompt)
  end

  -- Add file context
  local filename = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  if filename ~= "" then
    -- Use relative path from git root if possible
    local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
    if git_root ~= "" and vim.v.shell_error == 0 then
      -- Get relative path from git root
      local relative = vim.fn.fnamemodify(filename, ":s?" .. git_root .. "/??")
      filename = relative
    else
      -- Fall back to just the filename
      filename = vim.fn.fnamemodify(filename, ":t")
    end

    table.insert(parts, "")
    table.insert(parts, "From file: " .. filename)
  end

  -- Add code block with syntax highlighting
  table.insert(parts, "")
  if filetype ~= "" then
    table.insert(parts, "```" .. filetype)
  else
    table.insert(parts, "```")
  end

  -- Add the actual code
  for line in text:gmatch("[^\n]+") do
    table.insert(parts, line)
  end

  table.insert(parts, "```")

  -- Join with newlines but don't add trailing newline
  -- (that's added during submission)
  return table.concat(parts, "\n")
end

-- Ensure Claude is open (not toggle)
function M.ensure_claude_open()
  local claude_buf = find_claude_terminal()

  if claude_buf then
    -- Already open, just ensure it's visible
    focus_claude_window(claude_buf)
    return claude_buf, true  -- buf, was_already_open
  else
    -- Need to open
    terminal_state = ClaudeTerminalState.OPENING
    vim.cmd('ClaudeCode')
    return nil, false
  end
end

-- Wait for Claude to be ready for input
function M.wait_for_ready(callback, timeout)
  timeout = timeout or M.config.ready_timeout
  local start_time = vim.loop.now()

  local timer = vim.loop.new_timer()
  timer:start(100, 100, vim.schedule_wrap(function()
    local claude_buf = find_claude_terminal()

    if not claude_buf then
      if vim.loop.now() - start_time > timeout then
        timer:stop()
        M.handle_error(ErrorType.TERMINAL_NOT_FOUND, {timeout = true})
        return
      end
      return
    end

    -- Check if terminal is ready by looking for prompt
    local lines = vim.api.nvim_buf_get_lines(claude_buf, -10, -1, false)
    local is_ready = false

    -- Look for the characteristic Claude Code prompt pattern
    for _, line in ipairs(lines) do
      -- Look for Claude's main prompt or welcome message completion
      if line:match("^>") or                           -- Main prompt
         line:match("────────") or                      -- Separator line (longer pattern)
         line:match("Welcome to Claude Code!") or      -- Welcome completed
         line:match("? for shortcuts") then            -- Ready for input
        is_ready = true
        break
      end
    end

    -- Also check if we see the combination that indicates readiness
    local text = table.concat(lines, "\n")
    if text:match("Try.*%s*────.*%s*%?.*shortcuts") then
      is_ready = true
    end

    if is_ready then
      timer:stop()
      terminal_state = ClaudeTerminalState.READY
      callback(claude_buf)
    elseif vim.loop.now() - start_time > timeout then
      timer:stop()
      M.handle_error(ErrorType.TIMEOUT, {buf = claude_buf})
      callback(claude_buf)  -- Try anyway
    end
  end))
end

-- Submit message to Claude terminal
function M.submit_message(claude_buf, text, prompt)
  -- Get the terminal job ID (standard approach)
  -- Access via buffer variable, not buffer option
  local ok, job_id = pcall(vim.api.nvim_buf_get_var, claude_buf, 'terminal_job_id')
  if not ok or not job_id then
    M.handle_error(ErrorType.CHANNEL_NOT_READY, {buf = claude_buf})
    return false
  end

  -- Build formatted message
  local message = M.format_message(text, prompt)

  -- Focus Claude window first
  if M.config.auto_focus then
    focus_claude_window(claude_buf)
  end

  -- Use the standard chansend approach to send input to terminal
  -- This is the recommended method in Neovim documentation
  vim.fn.chansend(job_id, message .. "\n")

  -- Clear pending message
  pending_message = nil
  terminal_state = ClaudeTerminalState.BUSY

  if M.config.show_progress then
    vim.notify("Selection sent to Claude", vim.log.levels.INFO)
  end

  return true
end

-- Main function to send text to Claude
function M.send_to_claude(text, prompt)
  -- Store message in case we need to retry
  pending_message = {
    text = text,
    prompt = prompt,
    timestamp = os.time()
  }

  -- Ensure Claude is open
  local claude_buf, was_open = M.ensure_claude_open()

  if was_open and claude_buf then
    -- Already open and ready
    return M.submit_message(claude_buf, text, prompt)
  else
    -- Wait for ready state
    M.wait_for_ready(function(buf)
      if buf then
        M.submit_message(buf, text, prompt)
      end
    end)
    return true  -- Async operation started
  end
end

-- Error handling
function M.handle_error(error_type, context)
  context = context or {}

  local handlers = {
    [ErrorType.TERMINAL_NOT_FOUND] = function()
      -- Try to reopen Claude
      if M.config.auto_retry then
        vim.notify("Claude not found, reopening...", vim.log.levels.WARN)
        vim.cmd('ClaudeCode')
      else
        vim.notify("Claude Code terminal not found", vim.log.levels.ERROR)
      end
    end,

    [ErrorType.TIMEOUT] = function()
      -- Offer to retry
      vim.notify("Claude is not responding. Press <leader>as to retry.", vim.log.levels.WARN)
    end,

    [ErrorType.SEND_FAILED] = function()
      -- Store for later retry
      M.store_failed_message(context)
      vim.notify("Message saved. Will retry when Claude is ready.", vim.log.levels.INFO)
    end,

    [ErrorType.CHANNEL_NOT_READY] = function()
      vim.notify("Claude terminal channel not ready", vim.log.levels.ERROR)
    end
  }

  local handler = handlers[error_type]
  if handler then
    handler()
  else
    vim.notify("Unknown error: " .. tostring(error_type), vim.log.levels.ERROR)
  end
end

-- Store failed message for retry
function M.store_failed_message(context)
  if pending_message then
    -- Could store in a persistent location for recovery
    vim.g.claude_failed_message = pending_message
  end
end

-- Send visual selection with retry
function M.send_with_retry(text, prompt, attempts)
  attempts = attempts or M.config.max_retries
  local attempt = 1

  local function try_send()
    local success = M.send_to_claude(text, prompt)

    if not success and attempt < attempts then
      attempt = attempt + 1
      if M.config.show_progress then
        vim.notify(
          string.format("Retrying... (attempt %d/%d)", attempt, attempts),
          vim.log.levels.WARN
        )
      end
      vim.defer_fn(try_send, 1000)  -- Retry after 1 second
    elseif not success then
      vim.notify("Failed to send to Claude after " .. attempts .. " attempts",
                 vim.log.levels.ERROR)
    end
  end

  try_send()
end

-- Function to send visual selection to Claude
function M.send_visual_to_claude(prompt)
  local selection = get_visual_selection()

  -- Debug: log selection details
  if M.config.show_progress then
    vim.notify(string.format("Selection length: %d chars", #selection), vim.log.levels.DEBUG)
  end

  if selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  if M.config.auto_retry then
    M.send_with_retry(selection, prompt)
  else
    M.send_to_claude(selection, prompt)
  end
end

-- Interactive function with prompt input
function M.send_visual_with_prompt()
  local selection = get_visual_selection()

  -- Debug: log selection details
  if M.config.show_progress then
    vim.notify(string.format("Prompt function - Selection length: %d chars", #selection), vim.log.levels.DEBUG)
  end

  if selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end

  -- Show progress indicator
  local progress_handle = nil
  if M.config.show_progress then
    progress_handle = vim.notify("Preparing to send to Claude...", vim.log.levels.INFO, {
      title = "Claude Code",
      timeout = false
    })
  end

  -- Get prompt from user
  vim.ui.input({
    prompt = "Claude prompt: ",
    default = M.config.default_prompt,
  }, function(prompt)
    if not prompt then
      if progress_handle then
        vim.notify("Cancelled", vim.log.levels.INFO, {
          title = "Claude Code",
          replace = progress_handle
        })
      end
      return
    end

    -- Send the selection
    if M.config.auto_retry then
      M.send_with_retry(selection, prompt)
    else
      M.send_to_claude(selection, prompt)
    end

    -- Update progress
    if progress_handle then
      vim.notify("Selection sent to Claude", vim.log.levels.INFO, {
        title = "Claude Code",
        replace = progress_handle
      })
    end
  end)
end

-- Function to send current buffer to Claude
function M.send_buffer_to_claude(prompt)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local content = table.concat(lines, '\n')

  if content == "" then
    vim.notify("Buffer is empty", vim.log.levels.WARN)
    return
  end

  if M.config.auto_retry then
    M.send_with_retry(content, prompt or "Please review this code:")
  else
    M.send_to_claude(content, prompt or "Please review this code:")
  end
end

-- Setup terminal monitoring
function M.setup_terminal_monitor()
  -- Monitor Claude terminal for state changes
  vim.api.nvim_create_autocmd("TermOpen", {
    pattern = "*claude*",
    callback = function(args)
      local buf = args.buf
      terminal_state = ClaudeTerminalState.OPENING

      -- Monitor for ready state
      vim.api.nvim_create_autocmd("TextChanged", {
        buffer = buf,
        callback = function()
          if terminal_state == ClaudeTerminalState.OPENING then
            local lines = vim.api.nvim_buf_get_lines(buf, -3, -1, false)
            for _, line in ipairs(lines) do
              if line:match("Welcome to Claude Code") or
                 line:match("^>") or
                 line:match("──────") then
                terminal_state = ClaudeTerminalState.READY

                -- If we have a pending message, send it now
                if pending_message and
                   (os.time() - pending_message.timestamp < 30) then
                  vim.defer_fn(function()
                    M.submit_message(buf, pending_message.text, pending_message.prompt)
                  end, 500)  -- Small delay to ensure terminal is settled
                end
                break
              end
            end
          end
        end
      })
    end
  })

  -- Monitor for terminal close
  vim.api.nvim_create_autocmd("TermClose", {
    pattern = "*claude*",
    callback = function()
      terminal_state = ClaudeTerminalState.CLOSED
      pending_message = nil
    end
  })
end

-- Initialize the module
function M.setup()
  M.setup_terminal_monitor()
  -- Debug: confirm setup is called
  if M.config.show_progress then
    vim.notify("Claude Visual initialized", vim.log.levels.DEBUG)
  end
end

-- Create user commands
vim.api.nvim_create_user_command('ClaudeSendVisual', function(opts)
  M.send_visual_to_claude(opts.args)
end, {
  range = true,
  nargs = '?',
  desc = 'Send visual selection to Claude Code with optional prompt'
})

vim.api.nvim_create_user_command('ClaudeSendVisualPrompt', function()
  M.send_visual_with_prompt()
end, {
  range = true,
  desc = 'Send visual selection to Claude Code with interactive prompt'
})

vim.api.nvim_create_user_command('ClaudeSendBuffer', function(opts)
  M.send_buffer_to_claude(opts.args)
end, {
  nargs = '?',
  desc = 'Send entire buffer to Claude Code'
})

return M