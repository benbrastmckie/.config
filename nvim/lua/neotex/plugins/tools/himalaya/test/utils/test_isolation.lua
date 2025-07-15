-- Test Isolation Module
-- Ensures tests don't affect user's editing state

local M = {}

-- Save complete editor state
function M.save_state()
  local state = {
    -- Current window and buffer
    window = vim.api.nvim_get_current_win(),
    buffer = vim.api.nvim_get_current_buf(),
    
    -- Mode information
    mode = vim.api.nvim_get_mode().mode,
    
    -- Cursor position
    cursor = vim.api.nvim_win_get_cursor(0),
    
    -- All open windows
    windows = vim.api.nvim_list_wins(),
    
    -- Event ignore state
    eventignore = vim.o.eventignore,
    
    -- Save test mode
    test_mode = _G.HIMALAYA_TEST_MODE,
  }
  
  return state
end

-- Restore editor state
function M.restore_state(state)
  if not state then return end
  
  -- Temporarily ignore all events during restoration
  local old_eventignore = vim.o.eventignore
  vim.o.eventignore = "all"
  
  -- Force exit insert mode first
  vim.cmd('stopinsert')
  vim.cmd('stopinsert!')
  
  -- Clear any pending input
  vim.api.nvim_feedkeys('', 'n', true)
  
  -- Restore window if valid
  if state.window and vim.api.nvim_win_is_valid(state.window) then
    pcall(vim.api.nvim_set_current_win, state.window)
  end
  
  -- Restore buffer if valid
  if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then
    local current_buf = vim.api.nvim_get_current_buf()
    if current_buf ~= state.buffer then
      pcall(vim.api.nvim_set_current_buf, state.buffer)
    end
  end
  
  -- Restore cursor position
  if state.cursor then
    pcall(vim.api.nvim_win_set_cursor, 0, state.cursor)
  end
  
  -- Ensure we're in normal mode
  if vim.api.nvim_get_mode().mode ~= 'n' then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
  end
  
  -- Restore test mode flag
  _G.HIMALAYA_TEST_MODE = state.test_mode
  
  -- Restore eventignore
  vim.o.eventignore = old_eventignore
end

-- Run function with complete isolation
function M.run_isolated(fn)
  -- Save current state
  local state = M.save_state()
  
  -- Set test mode flag
  _G.HIMALAYA_TEST_MODE = true
  
  -- Ignore events during test execution
  vim.o.eventignore = "BufEnter,BufLeave,BufWinEnter,BufWinLeave,WinEnter,WinLeave"
  
  -- Run the function
  local ok, result = pcall(fn)
  
  -- Always restore state, even if test failed
  M.restore_state(state)
  
  -- Return result
  if ok then
    return result
  else
    error(result)
  end
end

return M