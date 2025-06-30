-- Force MCP restart script
-- This ensures MCP Hub and Avante are properly integrated

print(" Forcing MCP Hub and Avante restart...")

-- Step 1: Ensure MCP Hub is loaded
print(" Loading MCPHub plugin...")
require("lazy").load({ plugins = { "mcphub.nvim" } })

-- Wait for plugin to load
vim.defer_fn(function()
  -- Step 2: Load MCPHub extension
  print(" Loading Avante extension...")
  local ok, mcphub = pcall(require, "mcphub")
  if ok then
    pcall(function()
      mcphub.load_extension("avante")
      print(" Avante extension loaded")
    end)
  end

  -- Step 3: Reload Avante configuration
  vim.defer_fn(function()
    print("  Reloading Avante configuration...")
    
    local ok_avante, avante = pcall(require, "avante")
    if ok_avante then
      -- Get fresh configuration
      local config_ok, config_fn = pcall(require, "neotex.plugins.ai.avante")
      if config_ok and config_fn.opts then
        local fresh_config = config_fn.opts()
        
        -- Evaluate function-based config
        if type(fresh_config.system_prompt) == "function" then
          fresh_config.system_prompt = fresh_config.system_prompt()
        end
        if type(fresh_config.custom_tools) == "function" then
          fresh_config.custom_tools = fresh_config.custom_tools()
        end
        
        -- Apply the configuration
        local avante_config = require("avante.config")
        if avante_config and avante_config.override then
          avante_config.override(fresh_config)
          print(" Avante configuration reloaded with MCP tools")
          
          -- Show available tools
          if fresh_config.custom_tools and #fresh_config.custom_tools > 0 then
            print("  Available MCP tools:")
            for i, tool in ipairs(fresh_config.custom_tools) do
              print("   " .. i .. ". " .. (tool.name or "unnamed"))
            end
          else
            print("  No MCP tools loaded - check MCP Hub connection")
          end
        end
      end
    end
  end, 500)
end, 200)

-- Step 4: Test MCP Hub connectivity
vim.defer_fn(function()
  print(" Testing MCP Hub connectivity...")
  
  vim.fn.jobstart({
    "curl", "-s", "http://localhost:37373/api/servers"
  }, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        print(" MCP Hub is responding")
        print(" MCP integration restart complete!")
        print(" Try your test again: 'Test my mcp tools: get react hooks from context7 and then search for \"react 2025 news\" with tavily'")
      else
        print(" MCP Hub is not responding - restart may be needed")
        print(" Try running the startup script: :!~/config/nvim/scripts/start_mcp_hub.sh")
      end
    end
  })
end, 1000)