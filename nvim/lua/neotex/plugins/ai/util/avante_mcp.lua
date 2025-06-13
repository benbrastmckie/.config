-- lua/neotex/plugins/ai/util/avante_mcp.lua

local mcp_server = require('neotex.plugins.ai.util.mcp_server')

local M = {}

-- Track if we've already shown the "not initialized" warning
local _warning_shown = false

-- Primary function for Avante commands to ensure MCPHub is available
function M.with_mcp(avante_command)
  -- First, ensure no conflicting MCP-Hub processes are running
  mcp_server.cleanup_existing_processes()
  
  -- First, directly trigger AvantePreLoad to ensure the plugin is loaded
  vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
  
  -- Directly load the plugin
  pcall(function() require("lazy").load({ plugins = { "mcphub.nvim" } }) end)
  
  -- Then simply run the Avante command directly
  -- We'll let Avante handle its own interaction with MCP-Hub
  vim.cmd(avante_command)
end

-- Register custom Avante commands that ensure MCPHub is available
function M.register_commands()
  -- Define all the Avante commands that should have MCPHub integration
  local commands = {
    { name = "AvanteAskWithMCP", target = "AvanteAsk" },
    { name = "AvanteChatWithMCP", target = "AvanteChat" },
    { name = "AvanteToggleWithMCP", target = "AvanteToggle" },
    { name = "AvanteEditWithMCP", target = "AvanteEdit" }
  }
  
  -- Register each command
  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd.name, function(opts)
      local args = opts.args or ""
      M.with_mcp(cmd.target .. " " .. args)
    end, { nargs = "*", desc = "Run " .. cmd.target .. " with MCPHub" })
  end
end

-- Set up auto-commands to integrate with Avante
function M.setup_autocmds()
  -- When Avante buffer is created, try to integrate MCPHub
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "Avante", "AvanteInput" },
    callback = function()
      -- Only run once per buffer
      if vim.b.mcphub_integrated then
        return
      end
      vim.b.mcphub_integrated = true
      
      -- Check if MCPHub is already running
      if mcp_server.check_status() then
        -- Server is already running, we can integrate immediately
        M._integrate_avante_with_mcp()
        return
      end
      
      -- Try to load MCPHub
      if not mcp_server.load() then
        return
      end
      
      -- Start server if not running
      if not mcp_server.state.running then
        local start_result = mcp_server.start()
        if not start_result then
          return
        end
      end
      
      -- Set up MCP integration after server is ready
      vim.defer_fn(function()
        M._integrate_avante_with_mcp()
      end, 1000)
    end
  })
end

-- Helper function to integrate Avante with MCP
function M._integrate_avante_with_mcp()
  local ok, mcphub = pcall(require, "mcphub")
  if not ok then return end
  
  -- Try to load the Avante extension
  pcall(function()
    mcphub.load_extension("avante")
  end)
  
  -- Try to update Avante's system prompt with MCPHub's prompt
  pcall(function()
    local hub = mcphub.get_hub_instance()
    if hub then
      local mcp_prompt = hub:get_active_servers_prompt()
      if mcp_prompt then
        local avante_ok, avante = pcall(require, "avante")
        if avante_ok and avante.config and avante.config.override then
          avante.config.override({ system_prompt = mcp_prompt })
        end
      end
    end
  end)
end

-- Direct function to open MCPHub interface without delays
function M.open_mcphub()
  -- Get the mcp_server module
  local mcp_server = require("neotex.plugins.ai.util.mcp_server")
  
  -- First make sure any existing processes are cleaned up
  mcp_server.cleanup_existing_processes()
  
  -- Load the MCPHub plugin via Lazy
  vim.notify("Opening MCPHub...", vim.log.levels.INFO)
  
  -- Load the plugin directly
  require("lazy").load({ plugins = { "mcphub.nvim" } })
  
  -- Check if we're on NixOS
  local is_nixos = vim.fn.filereadable("/etc/NIXOS") == 1 or vim.fn.executable("nix-env") == 1
  
  -- Start server with appropriate command
  if is_nixos then
    -- Use the NixOS command which has improved error handling
    vim.cmd("MCPNix")
  else
    -- Use standard start command for non-NixOS
    vim.cmd("MCPHubStart")
  end
  
  -- Open MCPHub UI directly
  vim.cmd("MCPHub")
end

-- Initialize the integration
function M.setup()
  M.register_commands()
  M.setup_autocmds()
  
  -- Set up shortcut command
  vim.api.nvim_create_user_command("MCPAvante", function(opts)
    M.with_mcp("AvanteAsk " .. (opts.args or ""))
  end, { nargs = "*", desc = "Open Avante with MCPHub integration" })
  
  -- Set up command to open MCPHub directly
  vim.api.nvim_create_user_command("MCPHubOpen", function()
    M.open_mcphub()
  end, { desc = "Open MCPHub interface with auto-start" })
  
  -- Command to restart Avante with MCP integration
  vim.api.nvim_create_user_command("AvanteRestartMCP", function()
    dofile(vim.fn.stdpath("config") .. "/scripts/force_mcp_restart.lua")
  end, { desc = "Restart Avante with MCP integration" })
  
  -- Command to test MCP integration
  vim.api.nvim_create_user_command("MCPTest", function()
    dofile(vim.fn.stdpath("config") .. "/scripts/test_mcp_integration.lua")
  end, { desc = "Test MCP integration status" })
end

return M