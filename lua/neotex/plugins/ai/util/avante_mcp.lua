-- lua/neotex/plugins/ai/util/avante_mcp.lua

local mcp_server = require('neotex.plugins.ai.util.mcp_server')
local tool_registry = require('neotex.plugins.ai.util.tool_registry')

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

-- Helper function to integrate Avante with MCP using hybrid tool registry
function M._integrate_avante_with_mcp()
  local ok, mcphub = pcall(require, "mcphub")
  if not ok then return end
  
  -- Try to load the Avante extension
  pcall(function()
    mcphub.load_extension("avante")
  end)
  
  -- Try to update Avante's system prompt with hybrid tool registry
  pcall(function()
    local hub = mcphub.get_hub_instance()
    if hub then
      -- Get current avante config to determine persona and context
      local avante_ok, avante = pcall(require, "avante")
      if avante_ok and avante.config then
        -- Default to expert persona if not specified
        local current_persona = "expert"
        
        -- Try to get conversation context (this would need to be implemented
        -- based on how Avante stores conversation history)
        local conversation_context = ""
        
        -- Generate context-aware MCP tools prompt using tool registry
        local hybrid_prompt = tool_registry.generate_context_aware_prompt(current_persona, conversation_context)
        
        -- Update system prompt with hybrid approach
        if avante.config.override then
          -- Get existing system prompt from system-prompts.json
          local system_prompts = M._load_system_prompts()
          if system_prompts and system_prompts.prompts and system_prompts.prompts[current_persona] then
            local base_prompt = system_prompts.prompts[current_persona].prompt
            -- Replace placeholder with actual tool instructions
            local enhanced_prompt = base_prompt:gsub("{MCP_TOOLS_PLACEHOLDER}", hybrid_prompt)
            avante.config.override({ system_prompt = enhanced_prompt })
          end
        end
      end
    end
  end)
end

-- Load system prompts from JSON file
function M._load_system_prompts()
  local prompts_file = vim.fn.stdpath("config") .. "/lua/neotex/plugins/ai/util/system-prompts.json"
  local file = io.open(prompts_file, "r")
  if not file then
    return nil
  end
  
  local content = file:read("*all")
  file:close()
  
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end
  
  return decoded
end

-- Generate enhanced system prompt for a specific persona with conversation context
function M.generate_enhanced_prompt(persona, conversation_context)
  persona = persona or "expert"
  conversation_context = conversation_context or ""
  
  -- First try system-prompts.json, then fall back to system-prompts.lua
  local base_prompt = nil
  
  -- Try JSON file first
  local system_prompts = M._load_system_prompts()
  if system_prompts and system_prompts.prompts and system_prompts.prompts[persona] then
    base_prompt = system_prompts.prompts[persona].prompt
  end
  
  -- Fallback to Lua prompts if JSON doesn't have placeholder
  if not base_prompt or not string.find(base_prompt, "{MCP_TOOLS_PLACEHOLDER}") then
    local ok, prompts_module = pcall(require, "neotex.plugins.ai.util.system-prompts")
    if ok then
      local prompt_data, _ = prompts_module.get_default()
      if prompt_data and prompt_data.prompt and string.find(prompt_data.prompt, "{MCP_TOOLS_PLACEHOLDER}") then
        base_prompt = prompt_data.prompt
      end
    end
  end
  
  -- If still no placeholder, create a basic prompt with placeholder
  if not base_prompt or not string.find(base_prompt, "{MCP_TOOLS_PLACEHOLDER}") then
    base_prompt = "You are an expert AI assistant.\n\n{MCP_TOOLS_PLACEHOLDER}"
  end
  
  -- Generate context-aware tool instructions
  local tool_instructions = tool_registry.generate_context_aware_prompt(persona, conversation_context)
  
  -- Replace placeholder with actual tool instructions
  local enhanced_prompt = base_prompt:gsub("{MCP_TOOLS_PLACEHOLDER}", tool_instructions)
  
  return enhanced_prompt
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
  
  -- Commands for testing tool registry
  vim.api.nvim_create_user_command("MCPToolsShow", function(opts)
    local persona = opts.args or "expert"
    local tools = tool_registry.select_tools(persona, "")
    vim.notify("Tools for " .. persona .. ": " .. table.concat(tools, ", "), vim.log.levels.INFO)
  end, { nargs = "?", desc = "Show selected tools for persona" })
  
  vim.api.nvim_create_user_command("MCPPromptTest", function(opts)
    local args = vim.split(opts.args or "expert", " ", { plain = true })
    local persona = args[1] or "expert"
    local context = table.concat(args, " ", 2) or ""
    local prompt = M.generate_enhanced_prompt(persona, context)
    if prompt then
      print("Enhanced prompt for " .. persona .. ":")
      print(prompt:sub(1, 500) .. (prompt:len() > 500 and "..." or ""))
    else
      vim.notify("Failed to generate prompt", vim.log.levels.ERROR)
    end
  end, { nargs = "*", desc = "Test enhanced prompt generation" })
  
  vim.api.nvim_create_user_command("MCPSystemPromptTest", function()
    -- Test what Avante's actual system prompt function returns
    local ok, avante = pcall(require, "avante")
    if ok and avante.config and avante.config.system_prompt then
      local system_prompt
      if type(avante.config.system_prompt) == "function" then
        system_prompt = avante.config.system_prompt()
      else
        system_prompt = avante.config.system_prompt
      end
      
      if system_prompt then
        print("=== CURRENT AVANTE SYSTEM PROMPT ===")
        print("Length: " .. string.len(system_prompt) .. " characters")
        print("Contains MANDATORY:", string.find(system_prompt, "MANDATORY") ~= nil)
        print("Contains Context7:", string.find(system_prompt, "Context7") ~= nil)
        print("Contains warning rules:", string.find(system_prompt, "") ~= nil)
        print("")
        print("First 800 characters:")
        print(system_prompt:sub(1, 800))
      else
        print("No system prompt found")
      end
    else
      vim.notify("Could not access Avante config", vim.log.levels.ERROR)
    end
  end, { desc = "Test current Avante system prompt" })
  
  vim.api.nvim_create_user_command("MCPAvanteConfigTest", function()
    -- Test Avante configuration
    local ok, avante = pcall(require, "avante")
    if ok and avante.config then
      print("=== AVANTE CONFIG TEST ===")
      
      -- Check web search engine
      if avante.config.web_search_engine then
        print("Web search engine config:", vim.inspect(avante.config.web_search_engine))
      else
        print("No web search engine config found")
      end
      
      -- Check providers and disabled tools
      if avante.config.providers then
        for name, provider in pairs(avante.config.providers) do
          if provider.disable_tools then
            print("Provider " .. name .. " disabled tools:", table.concat(provider.disable_tools, ", "))
          end
          if provider.web_search_engine then
            print("Provider " .. name .. " web search:", vim.inspect(provider.web_search_engine))
          end
        end
      end
      
      -- Check custom tools
      if avante.config.custom_tools then
        if type(avante.config.custom_tools) == "function" then
          local tools = avante.config.custom_tools()
          print("Custom tools count:", #tools)
          for i, tool in ipairs(tools) do
            print("  Tool " .. i .. ":", tool.name or "unnamed")
          end
        else
          print("Custom tools:", vim.inspect(avante.config.custom_tools))
        end
      end
    else
      vim.notify("Could not access Avante config", vim.log.levels.ERROR)
    end
  end, { desc = "Test Avante configuration settings" })
  
  vim.api.nvim_create_user_command("MCPDebugToggle", function()
    -- Toggle MCPHub debug mode
    vim.g.mcphub_debug_mode = not vim.g.mcphub_debug_mode
    local status = vim.g.mcphub_debug_mode and "enabled" or "disabled"
    vim.notify("MCPHub debug mode " .. status, vim.log.levels.INFO)
  end, { desc = "Toggle MCPHub debug mode for verbose logging" })
  
  vim.api.nvim_create_user_command("MCPForceReload", function()
    -- Force reload Avante configuration
    vim.notify("Reloading Avante configuration...", vim.log.levels.INFO)
    
    -- Clear package cache for our modules
    package.loaded["neotex.plugins.ai.util.avante_mcp"] = nil
    package.loaded["neotex.plugins.ai.util.tool_registry"] = nil
    package.loaded["neotex.plugins.ai.util.system-prompts"] = nil
    
    -- Try to reload Avante config
    local ok, avante = pcall(require, "avante")
    if ok then
      -- Force reload the configuration
      if avante.config and avante.config.override then
        local avante_config = require("neotex.plugins.ai.avante")
        if avante_config.opts then
          local new_config = type(avante_config.opts) == "function" and avante_config.opts() or avante_config.opts
          avante.config.override(new_config)
          vim.notify(" Avante configuration reloaded", vim.log.levels.INFO)
        end
      end
    else
      vim.notify(" Failed to reload Avante", vim.log.levels.ERROR)
    end
  end, { desc = "Force reload Avante configuration with MCP fixes" })
  
  vim.api.nvim_create_user_command("MCPHubDiagnose", function()
    -- Comprehensive MCP Hub diagnosis
    print("=== MCP HUB DIAGNOSIS ===")
    
    -- Check if MCPHub module is available
    local ok, mcphub = pcall(require, "mcphub")
    if not ok then
      print("❌ MCPHub module not available")
      return
    end
    print("✅ MCPHub module loaded")
    
    -- Check if hub instance exists
    local hub = mcphub.get_hub_instance()
    if not hub then
      print("❌ MCP Hub instance not found")
      print("💡 Try running: :MCPHub or :MCPHubStart")
      return
    end
    print("✅ MCP Hub instance exists")
    
    -- Check server status
    if hub.get_servers then
      local servers = hub:get_servers()
      print("📊 Active servers:", vim.inspect(servers))
    end
    
    -- Test Context7 specifically
    print("\n=== Testing Context7 Connection ===")
    local success = pcall(function()
      hub:call_tool("github.com/upstash/context7-mcp", "resolve-library-id", {libraryName = "react"}, {
        callback = function(result, err)
          if err then
            print("❌ Context7 test failed:", err)
          else
            print("✅ Context7 test successful:", vim.inspect(result))
          end
        end
      })
    end)
    
    if not success then
      print("❌ Failed to call Context7 test")
    end
    
    print("\n💡 If errors persist, try:")
    print("   :MCPHubStart")
    print("   :MCPHub")
    print("   Restart Neovim")
  end, { desc = "Diagnose MCP Hub connection issues" })
end

return M