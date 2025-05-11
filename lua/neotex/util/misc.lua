-----------------------------------------------------------
-- Miscellaneous Utility Functions
-- 
-- This module contains utility functions that don't fit neatly
-- into other categories. It provides:
-- - Environment detection (get_os, exists)
-- - Function execution helpers (safe_execute, defer)
-- - Notification utilities (log)
-- - Editor enhancements (toggle_line_numbers, trim_whitespace)
-- - Text generation (random_string)
-- - Selection analysis (get_visual_selection_info)
--
-- The utilities are exposed both as module functions and commands.
-----------------------------------------------------------

local M = {}

-- Get OS information
function M.get_os()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return "windows"
  elseif vim.fn.has("mac") == 1 or vim.fn.has("macunix") == 1 then
    return "mac"
  else
    return "linux"
  end
end

-- Check if a file or directory exists
function M.exists(path)
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

-- Safely execute a function with error handling
function M.safe_execute(func, ...)
  local args = { ... }
  local ok, result = pcall(function()
    return func(unpack(args))
  end)
  
  if not ok then
    vim.notify("Error executing function: " .. tostring(result), vim.log.levels.ERROR)
    return nil
  end
  
  return result
end

-- Schedule a task to run asynchronously
function M.defer(func, delay)
  vim.defer_fn(function()
    local ok, err = pcall(func)
    if not ok then
      vim.notify("Error in deferred function: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, delay or 100)
end

-- Safely log a message
function M.log(msg, level)
  level = level or vim.log.levels.INFO
  if type(msg) ~= "string" then
    msg = vim.inspect(msg)
  end
  
  vim.notify(msg, level)
end

-- Toggle between relative and absolute line numbers
function M.toggle_line_numbers()
  local current = vim.wo.relativenumber
  vim.wo.relativenumber = not current
  
  -- Ensure number is always enabled when toggling
  vim.wo.number = true
  
  if vim.wo.relativenumber then
    vim.notify("Using relative line numbers", vim.log.levels.INFO)
  else
    vim.notify("Using absolute line numbers", vim.log.levels.INFO)
  end
end

-- Remove trailing whitespace in the current buffer
function M.trim_whitespace()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  vim.api.nvim_win_set_cursor(0, cursor_pos)
  vim.notify("Trailing whitespace removed", vim.log.levels.INFO)
end

-- Generate a random string of specified length
function M.random_string(length)
  length = length or 8
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local result = {}
  
  -- Set the random seed based on current time
  math.randomseed(os.time())
  
  for i = 1, length do
    local rand = math.random(1, #chars)
    result[i] = chars:sub(rand, rand)
  end
  
  return table.concat(result)
end

-- Calculate visual selection size (rows, cols, chars)
function M.get_visual_selection_info()
  -- Save selection marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  -- Get line contents
  local lines = vim.api.nvim_buf_get_lines(
    0, 
    start_pos[2] - 1, 
    end_pos[2], 
    false
  )
  
  if #lines == 0 then
    return { lines = 0, columns = 0, characters = 0 }
  end
  
  -- Adjust first and last line for column positions
  local start_col = start_pos[3]
  local end_col = end_pos[3]
  
  local char_count = 0
  
  if #lines == 1 then
    -- Only one line selected
    char_count = end_col - start_col + 1
    lines[1] = lines[1]:sub(start_col, end_col)
  else
    -- Multiple lines selected
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
    
    -- Count all characters
    for _, line in ipairs(lines) do
      char_count = char_count + #line
    end
    
    -- Add newlines for all but the last line
    char_count = char_count + #lines - 1
  end
  
  -- Calculate column count (maximum line length)
  local max_cols = 0
  for _, line in ipairs(lines) do
    max_cols = math.max(max_cols, #line)
  end
  
  return {
    lines = #lines,
    columns = max_cols,
    characters = char_count
  }
end

-- Display visual selection info
function M.show_selection_info()
  local info = M.get_visual_selection_info()
  local msg = string.format(
    "Selection: %d lines, %d columns, %d characters",
    info.lines, info.columns, info.characters
  )
  vim.notify(msg, vim.log.levels.INFO)
end

-- Set up misc utilities
function M.setup()
  -- Create user commands
  vim.api.nvim_create_user_command('ToggleLineNumbers', function()
    M.toggle_line_numbers()
  end, {})
  
  vim.api.nvim_create_user_command('TrimWhitespace', function()
    M.trim_whitespace()
  end, {})
  
  vim.api.nvim_create_user_command('SelectionInfo', function()
    M.show_selection_info()
  end, { range = true })
  
  -- Global function aliases for backward compatibility
  _G.ToggleLineNumbers = function()
    M.toggle_line_numbers()
  end
  
  _G.TrimWhitespace = function()
    M.trim_whitespace()
  end
  
  return true
end

return M