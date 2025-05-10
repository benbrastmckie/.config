-----------------------------------------------------------
-- NeoVim Configuration Module Loader
-- 
-- This module coordinates the loading of core configuration components:
--
-- - options.lua: Core Vim/NeoVim options
-- - keymaps.lua: Key mappings for various modes
-- - autocmds.lua: Autocommands for different events
--
-- Each component has a setup() function that initializes its
-- specific configuration. This module ensures proper loading
-- sequence and error handling.
-----------------------------------------------------------

local M = {}

-- Safe require function for local use
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to load config module: " .. module, vim.log.levels.ERROR)
    return false
  end
  
  if type(result) == "table" and type(result.setup) == "function" then
    local setup_ok, _ = pcall(result.setup)
    if not setup_ok then
      vim.notify("Failed to setup config module: " .. module, vim.log.levels.ERROR)
      return false
    end
  end
  
  return true
end

-- Load all configuration components
function M.setup()
  -- Load configuration modules
  -- Each returns true/false based on successful loading
  local modules = {
    "neotex.config.options",
    "neotex.config.keymaps",
    "neotex.config.autocmds",
  }
  
  local all_success = true
  for _, module in ipairs(modules) do
    if not safe_require(module) then
      all_success = false
    end
  end
  
  return all_success
end

return M