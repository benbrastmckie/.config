-----------------------------------------------------------
-- Editor Enhancement Plugins
-- 
-- This module loads plugins that enhance the editing experience:
-- - yanky.nvim: Enhanced yank and paste functionality
-- - which-key.nvim: Displays keybinding help popup
-- - formatting.lua: Code formatting with conform.nvim
-- - linting.lua: Code linting with nvim-lint
-- - todo-comments.lua: Highlight and search TODO comments
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
local yanky_module = safe_require("neotex.plugins.editor.yanky")
local which_key_module = safe_require("neotex.plugins.editor.which-key")
local formatting_module = safe_require("neotex.plugins.editor.formatting")
local linting_module = safe_require("neotex.plugins.editor.linting")
local todo_comments_module = safe_require("neotex.plugins.editor.todo-comments")

-- Return plugin specs
return {
  yanky_module,
  which_key_module,
  formatting_module,
  linting_module,
  todo_comments_module,
}