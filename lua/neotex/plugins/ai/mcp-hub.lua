------------------------------------------------------------------------
-- MCP-Hub Integration Plugin
------------------------------------------------------------------------
-- This module provides integration with MCP-Hub for AI tools and extensions
-- It serves as a bridge between various AI services and NeoVim
--
-- Features:
-- 1. MCP-Hub connection management
-- 2. Extension configuration for Avante and other AI tools
-- 3. Cross-platform compatibility with NixOS (including version fixes)
-- 4. Persistent settings between sessions
--
-- Commands:
-- - :MCPHub          - Launch the MCP-Hub interface
-- - :MCPHubStatus    - Check connection status
-- - :MCPHubStart     - Manually start the MCP-Hub server
-- - :MCPNix          - Start MCP-Hub using NixOS system binary
--
-- See: https://github.com/ravitemer/mcphub.nvim

return {
  "ravitemer/mcphub.nvim",
  name = "mcphub.nvim", -- Ensure name matches directory
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = true,
  -- Include only explicit commands to prevent auto-loading on MCPHub command
  cmd = { "MCPHubStatus", "MCPHubStart" },
  event = { "User AvantePreLoad" }, -- Only load on this custom event
  keys = { 
    -- Use a simpler command to open MCPHub that handles its own loading
    { "<leader>hx", "<cmd>MCPHubOpen<CR>", desc = "Open MCPHub" } 
  },
  module = false, -- Prevent module-based loading
  version = false, -- Explicitly disable version validation
  
  -- Build function with NixOS compatibility
  build = function()
    -- Check if we're on NixOS
    local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
    
    if is_nixos then
      -- NixOS-specific approach
      vim.notify("NixOS detected - using bundled binary approach for MCPHub", vim.log.levels.INFO)
      
      -- Directory for bundled installation
      local bundled_dir = vim.fn.expand("~/.local/share/nvim/lazy/mcphub.nvim/bundled/mcp-hub")
      vim.fn.mkdir(bundled_dir, "p")
      
      -- Create package.json for npm install
      local pkg_json = [[
{
  "name": "mcp-hub-bundled",
  "version": "1.0.0",
  "description": "Bundled MCP-Hub for NeoVim",
  "private": true,
  "dependencies": {
    "mcp-hub": "latest"
  }
}
]]
      local pkg_path = bundled_dir .. "/package.json"
      local pkg_file = io.open(pkg_path, "w")
      if pkg_file then
        pkg_file:write(pkg_json)
        pkg_file:close()
      end
      
      -- Create wrapper script
      local wrapper_content = [[
#!/bin/bash
# MCP-Hub wrapper script for NixOS
MCPHUB_BINARY="]] .. bundled_dir .. [[/node_modules/.bin/mcp-hub"
MCPHUB_JS="]] .. bundled_dir .. [[/node_modules/mcp-hub/dist/cli.js"

# Environment setup
export NODE_PATH="]] .. bundled_dir .. [[/node_modules:]] .. bundled_dir .. [["
export PATH="$PATH:]] .. bundled_dir .. [[/node_modules/.bin"

# Execute with node if available
if command -v node &> /dev/null; then
  if [ -f "$MCPHUB_JS" ]; then
    exec node "$MCPHUB_JS" "$@"
  elif [ -x "$MCPHUB_BINARY" ]; then
    exec "$MCPHUB_BINARY" "$@"
  else
    echo "Error: MCP-Hub not found"
    exit 1
  fi
else
  echo "Error: Node.js not found"
  exit 127
fi
]]
      local wrapper_path = bundled_dir .. "/mcp-hub-wrapper"
      local wrapper_file = io.open(wrapper_path, "w")
      if wrapper_file then
        wrapper_file:write(wrapper_content)
        wrapper_file:close()
        vim.fn.system("chmod +x " .. wrapper_path)
      end
      
      -- Install mcp-hub in the bundled directory
      local install_cmd = "cd " .. bundled_dir .. " && npm install --no-global"
      vim.fn.system(install_cmd)
    else
      -- Standard approach for non-NixOS
      vim.fn.system("npm install -g mcp-hub@latest")
    end
  end,
  
  -- Configuration
  config = function()
    require("mcphub").setup({
      -- Server configuration
      port = 37373,
      config = vim.fn.expand("~/.config/mcphub/servers.json"),
      
      -- Extensions configuration
      extensions = {
        avante = {
          make_slash_commands = true,
          auto_approve = true,
          make_vars = true,
          show_result_in_chat = true,
          system_prompt = "You have access to MCP tools and resources, which extend your capabilities."
        }
      },
      
      -- UI configuration
      ui = {
        window = {
          width = 0.8,
          height = 0.8,
          relative = "editor",
          border = "rounded",
        },
      },
      
      -- Event callbacks
      on_ready = function(hub)
        vim.g.mcphub_ready = true
        vim.notify("MCPHub server ready", vim.log.levels.INFO)
      end,
      
      on_error = function(err)
        vim.g.mcphub_ready = false
        vim.notify("MCPHub error: " .. err, vim.log.levels.ERROR)
      end,
      
      -- Logging
      log = {
        level = vim.log.levels.WARN,
        to_file = false,
      },
      
      debug = false, -- Set to true for more detailed logging
    })
    
    -- Set up the server manager
    require("neotex.plugins.ai.util.mcp_server").setup_commands()
  end,
}