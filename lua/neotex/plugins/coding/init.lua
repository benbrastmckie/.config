-----------------------------------------------------------
-- Coding Enhancement Plugins
-- 
-- This module loads plugins that enhance the coding experience:
-- - mini.pairs: Auto-close pairs of characters (replacing nvim-autopairs)
-- - mini.surround: Surround text with characters (planned replacement for surround.lua)
-- - mini.comment: Comment toggling (planned replacement for comment.lua)
-- - mini.cursorword: Highlight word occurrences (planned replacement for local-highlight)
--
-- The module uses a consistent error handling approach to ensure
-- NeoVim starts properly even if some plugin specifications fail.
-----------------------------------------------------------

-- Helper function to require a module with error handling
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    vim.notify("Failed to load plugin module: " .. module, vim.log.levels.WARN)
    return {}
  end
  return result
end

-- Load all mini modules
local mini_module = safe_require("neotex.plugins.coding.mini")

-- Return plugin specs
return {
  mini_module,
  -- Additional coding plugins will be added here
}