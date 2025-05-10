-- neotex.utils module
-- Provides core utility functions for the entire configuration

local M = {}

-- Safe require function that handles errors gracefully
function M.safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to require module: " .. module, vim.log.levels.ERROR)
    return nil
  end
  return result
end

-- Check if a value is empty (nil, empty string, empty table)
function M.is_empty(value)
  if value == nil then
    return true
  elseif type(value) == "string" then
    return value == ""
  elseif type(value) == "table" then
    return vim.tbl_isempty(value)
  end
  return false
end

-- Merge two tables, with values from the second table taking precedence
function M.tbl_extend(t1, t2)
  if not t2 then
    return t1
  end
  
  local result = {}
  for k, v in pairs(t1 or {}) do
    result[k] = v
  end
  
  for k, v in pairs(t2 or {}) do
    result[k] = v
  end
  
  return result
end

-- Check if a file or directory exists
function M.exists(path)
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

-- Get OS-specific information
function M.get_os()
  if vim.fn.has("win32") == 1 then
    return "windows"
  elseif vim.fn.has("macunix") == 1 then
    return "mac"
  else
    return "linux"
  end
end

-- Execute a function safely with error handling
function M.try(func, ...)
  local args = {...}
  return pcall(function() return func(unpack(args)) end)
end

-- Schedule a function to run asynchronously
function M.schedule(func)
  vim.schedule(function()
    local ok, err = pcall(func)
    if not ok then
      vim.notify("Error in scheduled function: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)
end

-- Defer a function to run after a delay (in ms)
function M.defer(func, delay)
  vim.defer_fn(function()
    local ok, err = pcall(func)
    if not ok then
      vim.notify("Error in deferred function: " .. tostring(err), vim.log.levels.ERROR)
    end
  end, delay or 10)
end

-- Setup module - called during initialization
function M.setup()
  -- Place any initialization logic here
  return true
end

return M