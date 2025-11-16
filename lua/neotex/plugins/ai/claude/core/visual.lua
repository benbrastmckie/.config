--------------------------------------------------------------------------------
-- Claude Visual Selection Integration
--------------------------------------------------------------------------------
-- Event-driven implementation using shared terminal-state module
-- Eliminates race conditions with autocommand-based readiness detection

local M = {}

-- Use shared terminal state module (event-driven, no timers)
local terminal_state = require('neotex.plugins.ai.claude.claude-session.terminal-state')

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
  auto_insert = true,

  -- Interactive prompt configuration
  prompt_placeholder = "Ask Claude about this code...",
  prompt_title = "Claude Prompt",
  allow_empty_prompt = false,
}

-- Helper function to get visual selection text
local function get_visual_selection()
  -- First try to get the current visual selection if we're in visual mode
  if vim.fn.mode():match("^[vV\22]") then
    -- We're in visual mode, get the current selection
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")

    -- Ensure start comes before end
    if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
      start_pos, end_pos = end_pos, start_pos
    end

    local start_line = start_pos[2]
    local start_col = start_pos[3]
    local end_line = end_pos[2]
    local end_col = end_pos[3]

    -- Get the lines and extract selection
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

    if #lines == 0 then
      return ""
    end

    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      if #lines > 1 then
        lines[#lines] = string.sub(lines[#lines], 1, end_col)
      end
    end

    local result = table.concat(lines, '\n')
    if result ~= "" and not result:match("^%s*$") then
      return result
    end
  end

  -- Fall back to previous visual selection marks
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

-- Enhanced message formatting
function M.format_message(text, prompt)
  local parts = {}

  -- Add user prompt if provided (don't add default prompt)
  if prompt and prompt ~= "" then
    table.insert(parts, prompt)
    table.insert(parts, "")  -- Add spacing after user prompt
  end

  -- Add file context prominently at the top
  local filename = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype

  if filename ~= "" then
    -- Use relative path from git root if possible, otherwise show full path
    local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
    if git_root ~= "" and vim.v.shell_error == 0 then
      -- Get relative path from git root
      local relative = vim.fn.fnamemodify(filename, ":s?" .. git_root .. "/??")
      filename = relative
    end

    -- Make file path prominent
    table.insert(parts, "**File:** `" .. filename .. "`")
    table.insert(parts, "")
  end

  -- Add code block with syntax highlighting
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

-- Main function to send text to Claude (event-driven, no timers)
function M.send_to_claude(text, prompt)
  -- Build formatted message
  local message = M.format_message(text, prompt) .. "\n"

  -- Check if terminal exists, if not open it
  local claude_buf = terminal_state.find_claude_terminal()
  if not claude_buf then
    vim.cmd('ClaudeCode')  -- Opens terminal, triggers TermOpen autocommand
  end

  -- Queue command - will auto-send when ready via autocommand
  terminal_state.queue_command(message, {
    auto_focus = M.config.auto_focus,
    notification = function()
      if M.config.show_progress then
        vim.notify("Selection sent to Claude", vim.log.levels.INFO)
      end
    end
  })

  return true
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

  M.send_to_claude(selection, prompt)
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
    M.send_to_claude(selection, prompt)

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

  M.send_to_claude(content, prompt or "Please review this code:")
end

-- Initialize the module
function M.setup()
  -- Setup event-driven terminal state monitoring
  terminal_state.setup()

  -- Use unified notification system with proper BACKGROUND category (debug only)
  local notify = require("neotex.util.notifications")
  notify.ai("Claude Visual initialized", notify.categories.BACKGROUND)
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

-- Interactive function to send visual selection with user-provided prompt
-- This function is called by the <leader>ac keymap in visual mode
function M.send_visual_to_claude_with_prompt()
  -- Validate we're in visual mode
  local mode = vim.fn.mode()
  if not mode:match("^[vV\22]") then
    vim.notify("This function only works in visual mode. Please select text first.", vim.log.levels.WARN)
    return
  end

  -- Get the visual selection first
  local selection = get_visual_selection()
  if selection == "" or selection:match("^%s*$") then
    vim.notify("No text selected. Please select some text and try again.", vim.log.levels.WARN)
    return
  end

  -- Show progress notification
  if M.config.show_progress then
    vim.notify(string.format("Selected %d characters. Opening prompt...", #selection), vim.log.levels.INFO)
  end

  -- Collect user prompt with vim.ui.input
  vim.ui.input({
    prompt = M.config.prompt_title .. ": ",
    default = "",
    completion = nil,
  }, function(user_prompt)
    -- Handle cancellation (nil input)
    if user_prompt == nil then
      if M.config.show_progress then
        vim.notify("Claude prompt cancelled.", vim.log.levels.INFO)
      end
      return
    end

    -- Handle empty prompt
    if user_prompt == "" or user_prompt:match("^%s*$") then
      if not M.config.allow_empty_prompt then
        vim.notify("Empty prompt not allowed. Please provide a question or request.", vim.log.levels.WARN)
        return
      else
        -- Use default prompt if empty is allowed
        user_prompt = M.config.default_prompt
      end
    end

    -- Validate prompt length (reasonable limit)
    if #user_prompt > 1000 then
      vim.notify("Prompt too long (max 1000 characters). Please shorten your request.", vim.log.levels.WARN)
      return
    end

    -- Show progress
    if M.config.show_progress then
      vim.notify("Sending selection to Claude with your prompt...", vim.log.levels.INFO)
    end

    -- Send to Claude using existing infrastructure
    M.send_to_claude(selection, user_prompt)
  end)
end

return M