-- neotex.config module
-- Main configuration loader

local M = {}

-- Safe require function for local use
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to require config module: " .. module, vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Load all configuration components
function M.setup()
  -- Load configuration modules (will be implemented in batch 2)
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

-- During refactoring, we're still using the original core modules
-- This stub ensures we can switch to the new configuration later
return {
  setup = function()
    -- In batch 1, we don't actually replace the core yet,
    -- we just prepare the structure for the next batches
    return true
  end
}