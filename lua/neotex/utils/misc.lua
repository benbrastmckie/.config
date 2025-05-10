-- neotex.utils.misc
-- Miscellaneous utility functions that don't fit elsewhere

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

-- Set up misc utilities
function M.setup()
  -- No global functions to set up for misc utilities
  return true
end

return M