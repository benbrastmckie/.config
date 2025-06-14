-----------------------------------------------------------
-- UI Enhancement Plugins
-- 
-- This module loads plugins that enhance the UI experience:
-- - colorscheme.lua: Gruvbox theme configuration
-- - lualine.lua: Status line configuration
-- - bufferline.lua: Buffer line configuration
-- - neo-tree.lua: File explorer configuration
-- - nvim-web-devicons.lua: File icons
-- - sessions.lua: Session management
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
local colorscheme_module = safe_require("neotex.plugins.ui.colorscheme")
local lualine_module = safe_require("neotex.plugins.ui.lualine")
local bufferline_module = safe_require("neotex.plugins.ui.bufferline")
local neo_tree_module = safe_require("neotex.plugins.ui.neo-tree")
local web_devicons_module = safe_require("neotex.plugins.ui.nvim-web-devicons")
local sessions_module = safe_require("neotex.plugins.ui.sessions")

-- Return plugin specs
return {
  colorscheme_module,
  lualine_module,
  bufferline_module,
  neo_tree_module,
  web_devicons_module,
  sessions_module,
}