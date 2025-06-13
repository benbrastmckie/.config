-- Test script to verify MCP integration with Avante
-- Run this with :luafile scripts/test_mcp_integration.lua

print("=== MCP Integration Test ===")

-- Test 1: Check if MCPHub is loaded
local ok, mcphub = pcall(require, "mcphub")
if ok then
  print("✅ MCPHub plugin loaded successfully")
  
  -- Test 2: Check if hub instance exists
  local hub = mcphub.get_hub_instance()
  if hub then
    print("✅ MCPHub instance available")
  else
    print("❌ MCPHub instance not available")
  end
  
  -- Test 3: Try to load the Avante extension
  local ext_ok = pcall(function()
    mcphub.load_extension("avante")
  end)
  
  if ext_ok then
    print("✅ Avante extension loaded successfully")
    
    -- Test 4: Check if MCP tools are available
    local ok_ext, mcphub_ext = pcall(require, "mcphub.extensions.avante")
    if ok_ext and mcphub_ext then
      print("✅ Avante extension module available")
      
      if mcphub_ext.mcp_tool then
        local tools = mcphub_ext.mcp_tool()
        if tools then
          print("✅ MCP tools function available")
          print("   Tools:", vim.inspect(tools, { depth = 1 }))
        else
          print("❌ MCP tools function returned nil")
        end
      else
        print("❌ mcp_tool function not found in extension")
      end
    else
      print("❌ Failed to load Avante extension module")
    end
  else
    print("❌ Failed to load Avante extension")
  end
else
  print("❌ MCPHub plugin not loaded")
end

-- Test 5: Check Avante configuration
local ok_avante, avante = pcall(require, "avante")
if ok_avante then
  print("✅ Avante plugin loaded")
  
  -- Check if custom_tools are configured
  local ok_config, avante_config = pcall(require, "avante.config")
  if ok_config and avante_config._options then
    print("✅ Avante config available")
    
    if avante_config._options.custom_tools then
      print("✅ Custom tools configured in Avante")
      
      -- Try to evaluate custom_tools if it's a function
      local tools = avante_config._options.custom_tools
      if type(tools) == "function" then
        local eval_ok, result = pcall(tools)
        if eval_ok then
          print("✅ Custom tools function executed successfully")
          print("   Result:", vim.inspect(result, { depth = 2 }))
        else
          print("❌ Custom tools function failed:", result)
        end
      else
        print("   Custom tools type:", type(tools))
      end
    else
      print("❌ Custom tools not configured in Avante")
    end
  else
    print("❌ Avante config not available")
  end
else
  print("❌ Avante plugin not loaded")
end

-- Test 6: Check MCP server status
print("\n=== MCP Server Status ===")
local curl_ok = os.execute("curl -s http://localhost:37373/api/servers > /dev/null 2>&1")
if curl_ok == 0 then
  print("✅ MCP Hub responding on port 37373")
else
  print("❌ MCP Hub not responding on port 37373")
end

print("\n=== Test Complete ===")
print("If all tests pass, try running :AvanteRestartMCP in Neovim")