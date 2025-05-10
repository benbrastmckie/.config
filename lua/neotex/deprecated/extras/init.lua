-----------------------------------------------------------
-- Extras Plugins
-- 
-- This module loads plugins that provide additional functionality:
-- - todo-comments.nvim: Enhanced TODO comment highlighting and navigation
-- - conform.nvim: Code formatting with support for multiple languages
-- - nvim-lint: Code linting with support for multiple languages
-- - (more plugins will be added in future batches)
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

-- Load modules
local todo_comments_module = safe_require("neotex.plugins.extras.todo-comments")
local formatting_module = safe_require("neotex.plugins.extras.formatting")
local linting_module = safe_require("neotex.plugins.extras.linting")

-- Return plugin specs
return {
  todo_comments_module,
  formatting_module,
  linting_module,
  -- Additional extras plugins will be added here
}