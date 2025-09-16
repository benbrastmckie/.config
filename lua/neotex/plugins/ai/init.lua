-----------------------------------------------------------
-- AI Tooling Plugins
--
-- This module loads AI-related plugins:
-- - avante.lua: Avante AI integration with MCP Hub support
-- - claude-code.lua: Claude Code terminal integration for seamless AI workflow
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
    require('neotex.util.notifications').ai('Failed to load plugin module', require('neotex.util.notifications').categories.WARNING, { module = module })
    return {}
  end
  return result
end

-- Load the Avante+MCP integration during setup
local function setup_integrations()
  local avante_mcp = require("neotex.plugins.ai.util.avante_mcp")
  avante_mcp.setup()
end

-- Initialize once plugins are loaded
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    -- Set up integrations with a slight delay to ensure other plugins are loaded
    vim.defer_fn(setup_integrations, 100)

    -- Register a global MCPHubOpen command that will be available at startup
    pcall(vim.api.nvim_del_user_command, "MCPHubOpen")
    vim.api.nvim_create_user_command("MCPHubOpen", function()
      -- Try to load MCPHub through Lazy
      pcall(function()
        require("lazy").load({ plugins = { "mcphub.nvim" } })
      end)

      -- Give a moment for the plugin to load
      vim.defer_fn(function()
        -- Ensure the open_mcphub function is called safely
        pcall(function()
          require("neotex.plugins.ai.util.avante_mcp").open_mcphub()
        end)
      end, 100)
    end, { desc = "Open MCPHub interface with auto-load and start" })

    -- Register a handler for our custom event
    vim.api.nvim_create_autocmd("User", {
      pattern = "AvantePreLoad",
      callback = function()
        -- Try to load MCPHub through Lazy instead of packadd
        pcall(function()
          require("lazy").load({ plugins = { "mcphub.nvim" } })
        end)

        -- Verify that we can now require MCPHub
        vim.defer_fn(function()
          pcall(function()
            require("mcphub")
          end)
        end, 50)
      end,
      once = true
    })
  end
})

-- Load the AI plugin modules
local avante_plugin = safe_require("neotex.plugins.ai.avante")
local claude_code_plugin = safe_require("neotex.plugins.ai.claude-code")
local lectic_plugin = safe_require("neotex.plugins.ai.lectic")
local mcphub_plugin = safe_require("neotex.plugins.ai.mcp-hub")

-- Return plugin specs
return {
  -- Core plugins
  avante_plugin,
  claude_code_plugin,
  lectic_plugin,

  -- MCPHub plugin (completely isolated)
  mcphub_plugin,
}

