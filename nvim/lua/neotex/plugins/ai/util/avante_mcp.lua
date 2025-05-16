-- lua/neotex/plugins/ai/util/avante_mcp.lua

local mcp_server = require('neotex.plugins.ai.util.mcp_server')

local M = {}

-- Track if we've already shown the "not initialized" warning
local _warning_shown = false

-- Primary function for Avante commands to ensure MCPHub is available
function M.with_mcp(avante_command)
  -- Create a variable to track if we had issues with MCPHub
  local had_mcphub_issues = false
  
  -- First trigger the AvantePreLoad event to make sure lazy.nvim has a chance to load MCPHub
  pcall(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
  end)
  
  -- Give a tiny bit of time for the event to be processed
  vim.cmd("sleep 10m")
  
  -- Step 1: Ensure MCPHub plugin is loaded (after triggering the event)
  if not mcp_server.load() then
    -- Silently continue without MCPHub
    had_mcphub_issues = true
  else
    -- Step 2: Start server if not running or ready
    if not mcp_server.state.running or not mcp_server.state.ready then
      local start_result = mcp_server.start()
      if not start_result then
        had_mcphub_issues = true
      end
    end
  end
  
  -- Step 3: Run the Avante command
  if had_mcphub_issues then
    -- If we had issues, just run Avante directly with minimal delay
    vim.defer_fn(function()
      vim.cmd(avante_command)
    end, 10)
  else
    -- If everything looks good, give the server a moment to initialize fully
    vim.defer_fn(function()
      -- Only check status if we don't already know it's ready
      if not mcp_server.state.ready then
        local status = mcp_server.check_status()
        
        -- Don't show the warning about MCPHub not being initialized
      end
      
      -- Run the Avante command
      vim.cmd(avante_command)
    end, 250) -- Give server time to start, but not too long
  end
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

-- Simpler and more direct function to open MCPHub interface
function M.open_mcphub()
  -- Set up a dedicated command that will be created once the plugin is loaded
  vim.api.nvim_create_user_command("MCPHubOpen", function()
    -- Run the startup command to ensure the server is running
    pcall(vim.cmd, "MCPHubStart")
    
    -- Give server a moment to start up if it wasn't already running
    vim.defer_fn(function()
      -- Then open the interface 
      pcall(vim.cmd, "MCPHub")
    end, 500)
  end, { desc = "Open MCPHub interface with auto-start" })
  
  -- Load the MCPHub plugin via Lazy
  vim.notify("Opening MCPHub...", vim.log.levels.INFO)
  
  -- Try to load the plugin through Lazy's API
  pcall(function()
    require("lazy").load({ plugins = { "mcphub.nvim" } })
    
    -- Wait for the plugin to initialize
    vim.defer_fn(function()
      -- Run our command
      pcall(vim.cmd, "MCPHubOpen")
    end, 200)
  end)
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
end

return M