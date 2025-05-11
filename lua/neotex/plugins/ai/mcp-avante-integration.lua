------------------------------------------------------------------------
-- MCP-Hub and Avante Integration Module
------------------------------------------------------------------------
-- This module provides the integration between MCP-Hub and Avante
-- allowing Avante to use MCP tools and resources
--
-- Features:
-- 1. MCP tools support in Avante
-- 2. Shared configuration between MCP and Avante
-- 3. Automatic tool registration
-- 4. Event handling and status monitoring
--
-- Usage:
-- This module is loaded by both MCP-Hub and Avante configuration
-- It hooks into both systems to ensure proper integration

local M = {}

-- Store integration state
local integration_state = {
  enabled = false,
  initialized = false,
  error = nil
}

-- Create MCP tool for Avante
function M.create_mcp_tool()
  -- Return a properly formatted tool configuration that Avante can use
  return {
    name = "mcp",
    description = "Execute MCP tools and access AI providers",
    execute = function(args)
      -- Check if MCP-Hub is running
      if not _G.mcp_hub_state or not _G.mcp_hub_state.running then
        return {
          error = "MCP-Hub is not running. Please run :MCPHub first."
        }
      end
      
      -- Try to get the mcphub module
      local ok, mcphub = pcall(require, "mcphub")
      if not ok then
        return {
          error = "Failed to load MCP-Hub module."
        }
      end
      
      -- Execute the MCP tool
      local result = {}
      local has_error = false
      
      -- Use pcall to handle potential errors
      local exec_ok, exec_result = pcall(function()
        -- Extract arguments
        local tool = args.tool or args[1]
        local input = args.input or args[2] or {}
        
        -- If no tool specified, return error
        if not tool then
          return {
            error = "No MCP tool specified. Required format: {tool: 'toolname', input: {...}}"
          }
        end
        
        -- Call MCP Hub's execute_tool method
        return mcphub.execute_tool(tool, input)
      end)
      
      -- Handle execution results
      if not exec_ok then
        result = {
          error = "MCP tool execution failed: " .. tostring(exec_result)
        }
        has_error = true
      else
        result = exec_result
        
        -- Check if MCP returned an error
        if result and result.error then
          has_error = true
        end
      end
      
      -- Update global state
      if has_error and result.error then
        _G.mcp_hub_state.last_error = result.error
      end
      
      return result
    end
  }
end

-- Register MCP tool with Avante
function M.register_with_avante()
  -- Try to get Avante config
  local ok, avante_config = pcall(require, "avante.config")
  
  -- Update integration state
  integration_state.initialized = true
  
  if not ok then
    integration_state.error = "Failed to load Avante config module."
    integration_state.enabled = false
    return false
  end
  
  -- Try to register the MCP tool
  local register_ok, _ = pcall(function()
    -- Create MCP tool instance
    local mcp_tool = M.create_mcp_tool()
    
    -- Update Avante configuration to include the MCP tool
    if avante_config and avante_config.override then
      avante_config.override({
        custom_tools = {
          mcp_tool
        }
      })
    end
  end)
  
  -- Update integration state
  integration_state.enabled = register_ok
  
  if not register_ok then
    integration_state.error = "Failed to register MCP tool with Avante."
    return false
  end
  
  -- Update MCPHub global state
  if _G.mcp_hub_state then
    _G.mcp_hub_state.avante_integrated = true
  end
  
  return true
end

-- Setup integration when both plugins are available
function M.setup()
  -- Check if autocmd group exists, if not create it
  local group_exists = pcall(vim.api.nvim_get_autocmds, {group = "MCPAvanteIntegration"})
  if not group_exists then
    vim.api.nvim_create_augroup("MCPAvanteIntegration", { clear = true })
  end
  
  -- Add VimEnter hook to finalize integration after everything is loaded
  vim.api.nvim_create_autocmd("VimEnter", {
    group = "MCPAvanteIntegration",
    pattern = "*",
    callback = function()
      -- Defer execution to ensure both plugins are fully loaded
      vim.defer_fn(function()
        -- Only try to register if not already done
        if not integration_state.initialized then
          M.register_with_avante()
        end
      end, 1500) -- Delay to ensure plugins are loaded
    end,
    once = true
  })
  
  -- Add LspAttach hook to potentially integrate with LSP-powered tools
  vim.api.nvim_create_autocmd("LspAttach", {
    group = "MCPAvanteIntegration",
    callback = function()
      -- Only register if not already done
      if not integration_state.initialized then
        vim.defer_fn(function()
          M.register_with_avante()
        end, 500)
      end
    end,
    once = true
  })
  
  -- Return integration state
  return integration_state
end

-- Get the current integration state
function M.get_state()
  return integration_state
end

return M