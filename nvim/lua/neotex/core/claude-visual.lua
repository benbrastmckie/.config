--------------------------------------------------------------------------------
-- Claude Visual Selection Integration
--------------------------------------------------------------------------------
-- This module provides a way to send visual selections to Claude Code
-- similar to how Avante handles visual selections with AvanteEdit

local M = {}

-- Helper function to get visual selection text
local function get_visual_selection()
  -- Get the visual selection marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  local start_line = start_pos[2]
  local start_col = start_pos[3]
  local end_line = end_pos[2]
  local end_col = end_pos[3]
  
  -- Get the lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  
  if #lines == 0 then
    return ""
  end
  
  -- Handle single line selection
  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    -- Handle multi-line selection
    lines[1] = string.sub(lines[1], start_col)
    if #lines > 1 then
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end
  
  return table.concat(lines, '\n')
end

-- Function to find Claude terminal buffer
local function find_claude_terminal()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname:match("claude") and vim.bo[buf].buftype == "terminal" then
        return buf
      end
    end
  end
  return nil
end

-- Function to send text to Claude with optional prompt
function M.send_to_claude(text, prompt)
  -- First ensure Claude Code is open
  vim.cmd('ClaudeCode')
  
  -- Wait for terminal to be ready
  vim.defer_fn(function()
    local claude_buf = find_claude_terminal()
    if not claude_buf then
      vim.notify("Claude Code terminal not found", vim.log.levels.WARN)
      return
    end
    
    -- Get the terminal channel
    local chan = vim.bo[claude_buf].channel
    if not chan or chan <= 0 then
      vim.notify("Claude Code terminal channel not found", vim.log.levels.WARN)
      return
    end
    
    -- Prepare the message
    local message = ""
    
    -- Add prompt if provided
    if prompt and prompt ~= "" then
      message = prompt .. "\n\n"
    end
    
    -- Add context about the selection
    local filetype = vim.bo.filetype
    local filename = vim.fn.expand("%:t")
    
    if filename ~= "" then
      message = message .. "From file: " .. filename
      if filetype ~= "" then
        message = message .. " (" .. filetype .. ")"
      end
      message = message .. "\n\n"
    end
    
    -- Add the selected text in code block
    if filetype ~= "" then
      message = message .. "```" .. filetype .. "\n"
    else
      message = message .. "```\n"
    end
    message = message .. text
    message = message .. "\n```\n"
    
    -- Send to Claude terminal
    vim.api.nvim_chan_send(chan, message)
    
    -- Focus the Claude window
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == claude_buf then
        vim.api.nvim_set_current_win(win)
        -- Enter insert mode for immediate interaction
        vim.cmd('startinsert')
        break
      end
    end
    
    vim.notify("Sent selection to Claude Code", vim.log.levels.INFO)
  end, 200)
end

-- Function to send visual selection to Claude
function M.send_visual_to_claude(prompt)
  local selection = get_visual_selection()
  
  if selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end
  
  M.send_to_claude(selection, prompt)
end

-- Interactive function with prompt input
function M.send_visual_with_prompt()
  local selection = get_visual_selection()
  
  if selection == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end
  
  -- Get prompt from user
  vim.ui.input({
    prompt = "Claude prompt: ",
    default = "Please help me with this code:",
  }, function(prompt)
    if prompt then
      M.send_to_claude(selection, prompt)
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