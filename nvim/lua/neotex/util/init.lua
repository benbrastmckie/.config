-----------------------------------------------------------
-- NeoVim Utility Functions
-- 
-- This module provides utility functions used throughout the
-- configuration. It also serves as a loader for specialized
-- utility modules:
--
-- - buffer.lua: Functions for buffer management
-- - fold.lua: Functions for managing folds
-- - url.lua: URL detection and handling
-- - diagnostics.lua: LSP diagnostic utilities
-- - misc.lua: Miscellaneous helper functions
-- - optimize.lua: Performance optimization utilities
-- - lectic.lua: Functions for Lectic AI integration
--
-- Each module follows a consistent pattern with a setup()
-- function that initializes the module's functionality.
-----------------------------------------------------------

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

-- Load all utility modules with proper error handling
function M._load_submodules()
  local modules = {
    "buffer",
    "fold",
    "url",
    "diagnostics",
    "misc",
    "optimize",
    "lectic_extras",
    "notifications"
  }
  
  local loaded = {}
  
  for _, module_name in ipairs(modules) do
    local ok, module = pcall(require, "neotex.util." .. module_name)
    if ok and type(module) == "table" then
      loaded[module_name] = module
      -- Call setup function if it exists
      if type(module.setup) == "function" then
        pcall(module.setup)
      end
    else
      vim.notify("Failed to load utility module: " .. module_name, vim.log.levels.WARN)
    end
  end
  
  return loaded
end

-- Setup module - called during initialization
function M.setup()
  -- Removed notification to reduce startup messages
  
  -- Load all submodules
  local submodules = M._load_submodules()
  
  -- Create aliases for commonly used functions for easier access
  for module_name, module in pairs(submodules) do
    for func_name, func in pairs(module) do
      if type(func) == "function" and not func_name:match("^_") then
        -- Don't overwrite existing functions
        if not M[func_name] then
          M[func_name] = func
        end
      end
    end
  end
  
  -- Set up backward compatibility for core.functions
  if not _G.LoadFoldingState and submodules.fold then
    _G.LoadFoldingState = submodules.fold.load_folding_state
  end
  
  if not _G.SetupUrlMappings and submodules.url then
    _G.SetupUrlMappings = submodules.url.setup_url_mappings
  end
  
  return true
end

return M