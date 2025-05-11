-----------------------------------------------------------
-- Tool Integration Plugins
-- 
-- This module loads plugins that integrate various tools:
-- - toggleterm.lua: Terminal integration
-- - gitsigns.lua: Git integration
-- - telescope.lua: Fuzzy finder
-- - sessions.lua: Session management
-- - treesitter.lua: Syntax highlighting and code navigation
-- - firenvim.lua: Browser integration
-- - vimtex.lua: LaTeX integration
-- - lean.lua: Lean theorem prover integration
-- - avante.lua: AI integration
-- - (moved to neotex.plugins.snacks)
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
local toggleterm_module = safe_require("neotex.plugins.tools.toggleterm")
local gitsigns_module = safe_require("neotex.plugins.tools.gitsigns")
local telescope_module = safe_require("neotex.plugins.tools.telescope")
local sessions_module = safe_require("neotex.plugins.tools.sessions")
local treesitter_module = safe_require("neotex.plugins.tools.treesitter")
local firenvim_module = safe_require("neotex.plugins.tools.firenvim")
local vimtex_module = safe_require("neotex.plugins.tools.vimtex")
local lean_module = safe_require("neotex.plugins.tools.lean")
local avante_module = safe_require("neotex.plugins.tools.avante")
local snacks_module = safe_require("neotex.plugins.snacks")
local markdown_preview_module = safe_require("neotex.plugins.tools.markdown-preview")
local autolist_module = safe_require("neotex.plugins.tools.autolist")

-- Return plugin specs
return {
  toggleterm_module,
  gitsigns_module,
  telescope_module,
  sessions_module,
  treesitter_module,
  firenvim_module,
  vimtex_module,
  lean_module,
  avante_module,
  snacks_module,
  markdown_preview_module,
  autolist_module,
}