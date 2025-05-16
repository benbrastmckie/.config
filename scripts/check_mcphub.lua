-- Check MCPHub installation and configuration status
local M = {}

-- Utility function to print status messages
local function log(message, success)
  local prefix = success and "✓" or "✗"
  local color = success and "Green" or "Red"
  vim.api.nvim_echo({{prefix .. " " .. message, color}}, true, {})
end

-- Check if mcphub.nvim plugin directory exists
function M.check_installation()
  local plugin_path = vim.fn.stdpath("data") .. "/lazy/mcphub.nvim"
  local exists = vim.fn.isdirectory(plugin_path) == 1
  log("MCPHub plugin directory: " .. plugin_path, exists)
  return exists
end

-- Check if MCPHub is registered with Lazy
function M.check_lazy_registration()
  local success, lazy_plugin_specs = pcall(require, "lazy.core.config")
  if not success then
    log("Lazy plugin manager not found", false)
    return false
  end
  
  for _, plugin in pairs(lazy_plugin_specs.specs) do
    if type(plugin) == "table" and plugin[1] == "mcphub/mcphub.nvim" then
      log("MCPHub is registered with Lazy", true)
      return true
    end
  end
  
  log("MCPHub is not registered with Lazy", false)
  return false
end

-- Check if MCPHub commands are registered
function M.check_commands()
  local commands = vim.api.nvim_get_commands({})
  local mcp_commands = {
    "MCPLast",
    "MCPTogglePanel",
    "MCPSelectModel",
    "MCPSend",
    "MCPContext"
  }
  
  local all_commands_exist = true
  for _, cmd in ipairs(mcp_commands) do
    local exists = commands[cmd] ~= nil
    log("Command " .. cmd .. " is registered", exists)
    all_commands_exist = all_commands_exist and exists
  end
  
  return all_commands_exist
end

-- Check if MCPHub is loaded in Lazy
function M.check_plugin_load_status()
  local success, lazy_plugin_state = pcall(require, "lazy.core.cache")
  if not success then
    log("Could not check plugin load status", false)
    return false
  end
  
  -- Try to get the loaded state
  local plugin_loaded = false
  pcall(function()
    for name, status in pairs(lazy_plugin_state.get().loader) do
      if name:match("mcphub") then
        plugin_loaded = status.loaded ~= nil
        log("MCPHub load status: " .. (plugin_loaded and "Loaded" or "Not loaded"), plugin_loaded)
      end
    end
  end)
  
  -- If we couldn't determine loaded state, try another method
  if not plugin_loaded then
    success, _ = pcall(require, "mcphub")
    log("MCPHub module can be required", success)
    return success
  end
  
  return plugin_loaded
end

-- Check if lua modules are available
function M.check_modules()
  local modules = {
    "mcphub",
    "mcphub.config",
    "mcphub.ui",
    "mcphub.api"
  }
  
  local all_modules_loadable = true
  for _, module in ipairs(modules) do
    local success = pcall(require, module)
    log("Module " .. module .. " is loadable", success)
    all_modules_loadable = all_modules_loadable and success
  end
  
  return all_modules_loadable
end

-- Check if MCPHub configuration is valid
function M.check_config()
  local success, config = pcall(function()
    local mcphub = require("mcphub")
    return mcphub.config
  end)
  
  if not success then
    log("Could not access MCPHub configuration", false)
    return false
  end
  
  log("MCPHub configuration is accessible", true)
  
  -- Check important configuration values
  if config then
    log("API Key configured: " .. (config.api_key ~= nil and "Yes" or "No"), config.api_key ~= nil)
    log("Default model: " .. (config.default_model or "Not set"), config.default_model ~= nil)
  end
  
  return success and config ~= nil
end

-- Run all checks
function M.run_diagnostics()
  print("\n=== MCPHub Diagnostics ===\n")
  
  local installation = M.check_installation()
  local registration = M.check_lazy_registration()
  local commands = M.check_commands()
  local loaded = M.check_plugin_load_status()
  local modules = M.check_modules()
  local config = M.check_config()
  
  print("\n=== Diagnostic Summary ===")
  log("Installation: " .. (installation and "Found" or "Not found"), installation)
  log("Lazy registration: " .. (registration and "Registered" or "Not registered"), registration)
  log("Commands: " .. (commands and "Available" or "Missing"), commands)
  log("Plugin loaded: " .. (loaded and "Yes" or "No"), loaded)
  log("Modules: " .. (modules and "Available" or "Missing"), modules)
  log("Configuration: " .. (config and "Valid" or "Invalid"), config)
  
  if not installation then
    print("\nSuggestion: Run :Lazy install mcphub/mcphub.nvim")
  elseif not registration then
    print("\nSuggestion: Check your init.lua to ensure MCPHub is properly configured with Lazy")
  elseif not loaded then
    print("\nSuggestion: Try :Lazy load mcphub.nvim or restart Neovim")
  elseif not commands or not modules then
    print("\nSuggestion: Check for plugin load errors with :messages")
  elseif not config then
    print("\nSuggestion: Check your MCPHub configuration in init.lua or plugin config file")
  end
end

-- Run diagnostics when the script is executed directly
if not pcall(debug.getlocal, 4, 1) then
  M.run_diagnostics()
end

return M