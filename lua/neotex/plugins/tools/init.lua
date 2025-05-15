-----------------------------------------------------------
-- Tool Integration Plugins
--
-- This module loads plugins that integrate various tools:
-- - gitsigns.lua: Git integration
-- - firenvim.lua: Browser integration
-- - vimtex.lua: LaTeX integration
-- - lean.lua: Lean theorem prover integration
-- - markdown-preview.lua: Markdown preview
-- - autolist.lua: Smart list handling for markdown
-- - mini.lua: Mini plugins collection (pairs, comments, etc.)
-- - surround.lua: Text surrounding functionality
-- - todo-comments.lua: Highlight and search TODO comments
-- - yanky.lua: Enhanced yank and paste functionality
--
-- Note: The following remain in other modules:
-- - toggleterm.lua: Terminal integration (editor module)
-- - telescope.lua: Fuzzy finder and navigation (editor module)
-- - treesitter.lua: Syntax highlighting and code navigation (editor module)
-- - sessions.lua: Session management (ui module)
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
local gitsigns_module = safe_require("neotex.plugins.tools.gitsigns")
local firenvim_module = safe_require("neotex.plugins.tools.firenvim")
local vimtex_module = safe_require("neotex.plugins.tools.vimtex")
local lean_module = safe_require("neotex.plugins.tools.lean")
local snacks_module = safe_require("neotex.plugins.snacks")
local markdown_preview_module = safe_require("neotex.plugins.tools.markdown-preview")
local autolist_module = safe_require("neotex.plugins.tools.autolist")
local mini_module = safe_require("neotex.plugins.tools.mini")
local surround_module = safe_require("neotex.plugins.tools.surround")
local todo_comments_module = safe_require("neotex.plugins.tools.todo-comments")
local yanky_module = safe_require("neotex.plugins.tools.yanky")

-- Return plugin specs
return {
  gitsigns_module,
  firenvim_module,
  vimtex_module,
  lean_module,
  snacks_module,
  markdown_preview_module,
  autolist_module,
  mini_module,
  surround_module,
  todo_comments_module,
  yanky_module,
}

