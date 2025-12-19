------------------------------------------------------------------------
-- MCP-Hub Integration Plugin (Cross-Platform)
------------------------------------------------------------------------
-- This module provides clean integration with MCP-Hub for AI tools
-- Uses lazy.nvim with intelligent environment detection for installation
--
-- Features:
-- 1. Cross-platform compatibility (NixOS and standard environments)
-- 2. Automatic installation method detection
-- 3. Fallback to bundled installation when needed
--
-- Installation Methods:
-- - NixOS/Nix users: Uses bundled installation (automatic)
-- - Standard users: Uses global npm installation or bundled fallback
-- - Manual: Install with `npm install -g mcp-hub@latest`
--
-- Commands:
-- - :MCPHub          - Launch the MCP-Hub interface
-- - :MCPHubStatus    - Check connection status
--
-- See: https://github.com/ravitemer/mcphub.nvim

return {
  "ravitemer/mcphub.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = true,
  cmd = { "MCPHub", "MCPHubStatus", "MCPHubOpen" },
  -- Keys removed - defined in which-key.lua as <leader>ah
  build = "bundled_build.lua", -- Use bundled installation

  config = function()
    -- Detect environment and choose appropriate installation method
    local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or
        vim.fn.getenv("NIX_STORE") ~= vim.NIL or
        vim.fn.executable("nix") == 1

    -- Check if global mcp-hub is available (for non-NixOS users)
    local has_global_mcphub = vim.fn.executable("mcp-hub") == 1

    -- Simple MCPHub configuration with environment detection
    require("mcphub").setup({
      -- Basic configuration
      port = 37373,
      config = vim.fn.expand("~/.config/mcphub/servers.json"),
      debug = false,
      -- Use bundled binary for NixOS or when global install is not available
      use_bundled_binary = is_nixos or not has_global_mcphub,

      
      -- Global auto-approval for MCP tools
      auto_approve = true,

      -- Clean UI
      ui = {
        window = {
          width = 0.8,
          height = 0.8,
          border = "rounded",
        },
      },

      -- Minimal callbacks with installation method feedback
      on_ready = function()
        vim.g.mcphub_ready = true
        local method = (is_nixos or not has_global_mcphub) and " (bundled NixOS installation)" or ""
        -- Only show MCPHub ready message in debug mode
        if vim.g.mcphub_debug_mode then
          require('neotex.util.notifications').ai('MCPHub ready', require('neotex.util.notifications').categories.STATUS, { method = method })
        end
      end,

      on_error = function(err)
        -- Skip version mismatch errors
        if err and err:match("VERSION_MISMATCH") then
          -- Fix version silently by applying our standard fix
          require("mcphub.server").fix_version()
          return
        end

        vim.g.mcphub_ready = false
        require('neotex.util.notifications').ai('MCPHub error', require('neotex.util.notifications').categories.ERROR, { error = err })
      end,

      -- Minimal logging
      log = {
        level = vim.log.levels.WARN,
        to_file = false,
      },
    })
  end,
}
