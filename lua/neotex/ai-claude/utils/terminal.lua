-- Terminal management utilities for Claude AI integration
local M = {}

-- Check if a Claude buffer exists
function M.claude_buffer_exists()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match("claude") then
        return true, buf
      end
    end
  end
  return false
end

-- Find Claude terminal window
function M.find_claude_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("claude") then
      return win
    end
  end
  return nil
end

-- Open Claude in a terminal
function M.open_claude(cmd, continue)
  cmd = cmd or "claude"
  if continue then
    cmd = "ClaudeCodeContinue"
  end

  vim.cmd(cmd)

  -- Auto-enter insert mode
  vim.defer_fn(function()
    vim.cmd("startinsert")
  end, 100)
end

-- Toggle Claude terminal visibility
function M.toggle_claude_window()
  local win = M.find_claude_window()
  if win then
    vim.api.nvim_win_close(win, false)
    return false
  else
    -- Try to restore if buffer exists
    local exists, buf = M.claude_buffer_exists()
    if exists then
      vim.cmd("split")
      vim.api.nvim_set_current_buf(buf)
      return true
    end
  end
  return false
end

return M