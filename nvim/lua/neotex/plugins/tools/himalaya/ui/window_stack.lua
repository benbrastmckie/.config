-- Window Stack Manager for Himalaya Email Client
-- Tracks window hierarchy to ensure proper focus restoration when closing nested floating windows

local M = {}

-- Stack to track window hierarchy
M.stack = {}

-- Push a new window onto the stack
function M.push(win_id, parent_win)
  if not win_id then
    return false
  end
  
  -- Skip validation in headless mode or for testing
  local is_valid = true
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  if not is_headless then
    is_valid = vim.api.nvim_win_is_valid(win_id)
  end
  
  if not is_valid then
    return false
  end
  
  parent_win = parent_win or (not is_headless and vim.api.nvim_get_current_win() or 1000)
  
  local buffer_id = nil
  if not is_headless then
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win_id)
    buffer_id = ok and buf or nil
  end
  
  table.insert(M.stack, {
    window = win_id,
    parent = parent_win,
    buffer = buffer_id,
    timestamp = vim.loop.hrtime(),
    type = 'generic' -- Default type
  })
  
  return true
end

-- Pop window from stack and restore parent focus
function M.pop()
  if #M.stack == 0 then 
    return false 
  end
  
  local entry = table.remove(M.stack)
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  
  -- Close current window if it's still valid (skip in headless mode)
  if not is_headless and vim.api.nvim_win_is_valid(entry.window) then
    vim.api.nvim_win_close(entry.window, true)
  end
  
  -- Restore focus to parent if it's still valid (skip in headless mode)
  if not is_headless and entry.parent and vim.api.nvim_win_is_valid(entry.parent) then
    vim.api.nvim_set_current_win(entry.parent)
    return true
  end
  
  return not is_headless
end

-- Pop and close current window, restore parent focus
function M.close_current()
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  local current_win = not is_headless and vim.api.nvim_get_current_win() or nil
  
  -- Find the current window in the stack
  for i = #M.stack, 1, -1 do
    if not current_win or M.stack[i].window == current_win then
      local entry = table.remove(M.stack, i)
      
      -- Close current window (skip in headless mode)
      if not is_headless and vim.api.nvim_win_is_valid(entry.window) then
        vim.api.nvim_win_close(entry.window, true)
      end
      
      -- Restore focus to parent (skip in headless mode)
      if not is_headless and entry.parent and vim.api.nvim_win_is_valid(entry.parent) then
        vim.api.nvim_set_current_win(entry.parent)
        return true
      end
      
      return not is_headless
    end
  end
  
  -- If not found in stack, close normally (skip in headless mode)
  if not is_headless then
    vim.cmd('close')
  end
  return false
end

-- Clear the stack (useful for cleanup)
function M.clear()
  M.stack = {}
end

-- Get current stack depth
function M.depth()
  return #M.stack
end

-- Get the top window in the stack (most recently added)
function M.peek()
  if #M.stack == 0 then
    return nil
  end
  return M.stack[#M.stack]
end

-- Check if a window is in the stack
function M.contains(win_id)
  for _, entry in ipairs(M.stack) do
    if entry.window == win_id then
      return true
    end
  end
  return false
end

-- Clean up invalid windows from the stack
function M.cleanup()
  local valid_stack = {}
  for _, entry in ipairs(M.stack) do
    if vim.api.nvim_win_is_valid(entry.window) and 
       vim.api.nvim_win_is_valid(entry.parent) then
      table.insert(valid_stack, entry)
    end
  end
  M.stack = valid_stack
end

-- Push a draft window onto the stack (Phase 6)
function M.push_draft(win_id, draft_id, parent_win)
  if not win_id then
    return false
  end
  
  -- Skip validation in headless mode or for testing
  local is_valid = true
  local is_headless = vim.fn.argc(-1) == 0 and vim.fn.has('gui_running') == 0
  if not is_headless then
    is_valid = vim.api.nvim_win_is_valid(win_id)
  end
  
  if not is_valid then
    return false
  end
  
  parent_win = parent_win or (not is_headless and vim.api.nvim_get_current_win() or 1000)
  
  local buffer_id = nil
  if not is_headless then
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win_id)
    buffer_id = ok and buf or nil
  end
  
  local entry = {
    window = win_id,
    parent = parent_win,
    buffer = buffer_id,
    type = 'draft',
    draft_id = draft_id,
    timestamp = vim.loop.hrtime()
  }
  
  table.insert(M.stack, entry)
  return true
end

-- Get all draft windows in the stack (Phase 6)
function M.get_draft_windows()
  local draft_windows = {}
  for _, entry in ipairs(M.stack) do
    if entry.type == 'draft' then
      table.insert(draft_windows, entry)
    end
  end
  return draft_windows
end

-- Get draft window by draft ID (Phase 6)
function M.get_draft_window(draft_id)
  for _, entry in ipairs(M.stack) do
    if entry.type == 'draft' and entry.draft_id == draft_id then
      return entry
    end
  end
  return nil
end

-- Check if a draft window is open (Phase 6)
function M.has_draft_window(draft_id)
  return M.get_draft_window(draft_id) ~= nil
end

-- Close all draft windows (Phase 6)
function M.close_all_drafts()
  local closed = 0
  -- Iterate backwards to avoid index issues
  for i = #M.stack, 1, -1 do
    local entry = M.stack[i]
    if entry.type == 'draft' then
      if vim.api.nvim_win_is_valid(entry.window) then
        vim.api.nvim_win_close(entry.window, true)
        closed = closed + 1
      end
      table.remove(M.stack, i)
    end
  end
  return closed
end

-- Debug function to print current stack
function M.debug()
  print("Window Stack (depth: " .. #M.stack .. "):")
  for i, entry in ipairs(M.stack) do
    local win_valid = vim.api.nvim_win_is_valid(entry.window)
    local parent_valid = vim.api.nvim_win_is_valid(entry.parent)
    local type_info = entry.type or "unknown"
    if entry.type == 'draft' and entry.draft_id then
      type_info = string.format("draft[%s]", entry.draft_id)
    end
    print(string.format("  %d: win=%d(%s) parent=%d(%s) type=%s", 
      i, entry.window, win_valid and "valid" or "invalid",
      entry.parent, parent_valid and "valid" or "invalid",
      type_info))
  end
end

return M