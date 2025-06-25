-----------------------------------------------------------
-- Editor Enhancement Plugins
-- 
-- This module loads plugins that enhance the editing experience:
-- - which-key.nvim: Displays keybinding help popup
-- - formatting.lua: Code formatting with conform.nvim
-- - linting.lua: Code linting with nvim-lint
-- - telescope.lua: Fuzzy finder and navigation
-- - toggleterm.lua: Terminal integration
-- - treesitter.lua: Syntax highlighting and code navigation
--
-- Note: The following have been moved to the tools module:
-- - yanky.nvim: Enhanced yank and paste functionality (moved to tools)
-- - todo-comments.lua: Highlight and search TODO comments (moved to tools)
-- - autolist.lua: Smart list handling for markdown (moved to tools)
-- - mini.lua: Mini plugins collection (moved to tools)
-- - surround.lua: Text surrounding with quotes, brackets, etc. (moved to tools)
--
-- Note: The following has been moved to the ui module:
-- - sessions.lua: Session management (moved to ui)
--
-- The module uses a consistent error handling approach to ensure
-- NeoVim starts properly even if some plugin specifications fail.
-----------------------------------------------------------

-- Helper function to require a module with error handling
local function safe_require(module)
  local ok, result = pcall(require, module)
  if not ok then
    require('neotex.util.notifications').editor('Failed to load plugin module', require('neotex.util.notifications').categories.WARNING, { module = module })
    return {}
  end
  return result
end

-- Load modules
local which_key_module = safe_require("neotex.plugins.editor.which-key")
local formatting_module = safe_require("neotex.plugins.editor.formatting")
local linting_module = safe_require("neotex.plugins.editor.linting")
local telescope_module = safe_require("neotex.plugins.editor.telescope")
local toggleterm_module = safe_require("neotex.plugins.editor.toggleterm")
local treesitter_module = safe_require("neotex.plugins.editor.treesitter")

-- Return plugin specs
return {
  which_key_module,
  formatting_module,
  linting_module,
  telescope_module,
  toggleterm_module,
  treesitter_module,
}