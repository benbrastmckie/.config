-- neotex.config module
-- Main configuration loader

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