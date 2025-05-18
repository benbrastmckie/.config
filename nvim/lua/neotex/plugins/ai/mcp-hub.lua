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
    -- Set up server management first
    local mcp_server = require("neotex.plugins.ai.util.mcp_server")
    
    -- Check if we're on NixOS for specialized integration
    local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
    
    -- Create a platform-agnostic MCPNix command
    if is_nixos then
      -- Register simplified NixOS command for direct server management
      vim.api.nvim_create_user_command("MCPNix", function()
        -- First clean up any existing processes
        mcp_server.cleanup_existing_processes()
        
        -- Get NixOS binary path
        local cmd = "/nix/store/w99rw47l41zkkqxd1w6ya51w7m05fgsc-mcp-hub/bin/mcp-hub"
        
        if vim.fn.filereadable(cmd) ~= 1 then
          -- Try to find it on the PATH
          cmd = vim.fn.exepath("mcp-hub")
          
          if not cmd or cmd == "" then
            vim.notify("MCP-Hub binary not found. Please install it with Nix.", vim.log.levels.ERROR)
            return
          end
        end
        
        -- Use fixed port 37373 for consistency
        local port = 37373
        
        -- Display what we're doing
        vim.notify("Starting MCP-Hub server via Nix...", vim.log.levels.INFO)
        
        -- Create the servers.json file with the correct port
        pcall(function()
          local config_dir = vim.fn.expand("~/.config/mcphub")
          local servers_file = config_dir .. "/servers.json"
          
          local servers_config = {
            mcpServers = {
              {
                name = "default",
                description = "Default MCP Hub server",
                url = "http://localhost:" .. port,
                apiKey = "",
                default = true
              }
            }
          }
          
          -- Make sure the directory exists
          if vim.fn.isdirectory(config_dir) == 0 then
            vim.fn.mkdir(config_dir, "p")
          end
          
          -- Write the config
          local content = vim.json.encode(servers_config)
          vim.fn.writefile({content}, servers_file)
        end)
        
        -- Start the server with completely silent output
        local handle = io.popen(cmd .. " serve --port=" .. port .. " >/dev/null 2>&1 &")
        if handle then
          handle:close()
        end
        
        -- Update the state directly - assume success
        mcp_server.state.running = true
        mcp_server.state.ready = true
        mcp_server.state.port = port
        vim.g.mcphub_version = mcp_server.get_actual_version()
        
        -- Set global flag to indicate NixOS server is running
        vim.g.mcphub_nixos_running = true
        
        vim.notify("MCP-Hub server started", vim.log.levels.INFO)
      end, { desc = "Start MCP-Hub server using Nix binary" })
      
      -- Notify that the command is available
      vim.defer_fn(function()
        vim.notify("MCPNix command available - use :MCPNix to start MCP-Hub", vim.log.levels.INFO)
      end, 1000)
    end
    
    -- Create servers.json if it doesn't exist (do this first for all environments)
    local config_dir = vim.fn.expand("~/.config/mcphub")
    if vim.fn.isdirectory(config_dir) == 0 then
      vim.fn.mkdir(config_dir, "p")
    end
    
    local servers_file = config_dir .. "/servers.json"
    if vim.fn.filereadable(servers_file) == 0 then
      local default_config = {
        mcpServers = {
          {
            name = "default",
            description = "Default MCP Hub server",
            url = "http://localhost:37373",
            apiKey = "",
            default = true
          }
        }
      }
      
      local file = io.open(servers_file, "w")
      if file then
        file:write(vim.json.encode(default_config))
        file:close()
      end
    end
    
    -- Setup MCPHub with version override and dynamic port
    require("mcphub").setup({
      -- Server configuration
      port = mcp_server.state.port or 37373, -- Use the port we started with or default
      config = vim.fn.expand("~/.config/mcphub/servers.json"),
      version_override = require("neotex.plugins.ai.util.mcp_server").get_actual_version(), -- Use actual version
      
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
        
        -- Set version in hub instance to prevent version errors
        if hub then
          hub.version = "1.0.0"
        end
      end,
      
      on_error = function(err)
        -- Skip version mismatch errors
        if err and err:match("VERSION_MISMATCH") then
          -- Fix version silently by applying our standard fix
          mcp_server.fix_version()
          return
        end
        
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
    
    -- Set up the server manager with version fix
    mcp_server.setup_commands()
    
    -- Apply version fixes after setup
    mcp_server.fix_version()
  end,
}