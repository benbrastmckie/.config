-----------------------------------------------------------
-- AI Tooling Plugins
-- 
-- This module loads AI-related plugins:
-- - avante.lua: Avante AI integration with MCP Hub support
-- - mcp-hub.lua: MCP Hub integration
-- - lectic.lua: Lectic AI integration for interactive markdown files (with util/lectic_extras.lua)
-- - util/avante-highlights.lua: Enhanced visual indicators for Avante
-- - util/system-prompts.lua: System prompts manager for Avante
-- - util/avante-support.lua: Support functions for Avante configuration
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

-- Load the AI plugin modules
local avante_plugin = safe_require("neotex.plugins.ai.avante")
local lectic_plugin = safe_require("neotex.plugins.ai.lectic")

-- Load the optional MCPHub loader (completely isolated)
-- This runs in a completely separate loading context
local mcphub_loader_plugin = safe_require("neotex.plugins.ai.mcphub-loader")

-- Return plugin specs with MCPHub completely isolated
return {
  -- Core plugins
  avante_plugin,
  lectic_plugin,
  
  -- Add MCPHub loader as a completely separate plugin
  -- This will be loaded ONLY when specifically triggered
  mcphub_loader_plugin,
}