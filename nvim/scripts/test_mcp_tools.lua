-- Test script for MCP tools integration
print("🧪 Testing MCP tools integration...")

-- Load the modules
local ok, mcphub = pcall(require, "mcphub")
if not ok then
  print("❌ MCPHub not available")
  return
end

local hub = mcphub.get_hub_instance()
if not hub then
  print("❌ MCP Hub not initialized")
  return
end

print("✅ MCP Hub is available and initialized")

-- Test Context7 tool
print("\n📚 Testing Context7 (resolve React library)...")
hub:call_tool("github.com/upstash/context7-mcp", "resolve-library-id", {
  libraryName = "react"
}, {
  parse_response = true,
  callback = function(result, err)
    if err then
      print("❌ Context7 error: " .. err)
    elseif result and result.error then
      print("❌ Context7 tool error: " .. result.error)
    else
      print("✅ Context7 working! Result:")
      print(result.text or vim.inspect(result))
    end
  end,
})

-- Test Tavily tool
print("\n🔍 Testing Tavily (search 'react 2025 news')...")
hub:call_tool("tavily", "tavily-search", {
  query = "react 2025 news",
  max_results = 3,
  topic = "news"
}, {
  parse_response = true,
  callback = function(result, err)
    if err then
      print("❌ Tavily error: " .. err)
    elseif result and result.error then
      print("❌ Tavily tool error: " .. result.error)
    else
      print("✅ Tavily working! Result:")
      print(result.text or vim.inspect(result))
    end
  end,
})

print("\n🎉 MCP tools test complete!")