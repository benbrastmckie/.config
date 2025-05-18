-----------------------------------------------------------
-- NeoVim Configuration Entry Point
-- Author: Benjamin Brast-McKie
-- 
-- This is the main entry point for NeoVim configuration.
-- It sets the leader key and loads the configuration modules.
-- The loading process includes fallbacks to ensure NeoVim 
-- starts properly even if there are errors in the configuration.
--
-- Structure:
-- - neotex/bootstrap.lua: Handles plugin and feature initialization
-- - neotex/config/: Core configuration modules
-- - neotex/utils/: Utility functions
-- - neotex/plugins/: Plugin specification and configuration
-----------------------------------------------------------

-- Disable matchit.vim and matchparen right at the start to prevent loading
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1

-- Set notification level to show only important messages
vim.notify_level = vim.log.levels.INFO

-- Set leader key BEFORE loading lazy or any other plugins
-- This is critical and must happen first
vim.g.mapleader = " " -- Space as leader key

-- Use the Nix-installed MCP-Hub binary if available
local mcp_hub_path = os.getenv("MCP_HUB_PATH")
if mcp_hub_path then
  vim.g.mcp_hub_path = mcp_hub_path
end

-- Load configuration with improved error handling
local config_ok, config = pcall(require, "neotex.config")
local bootstrap_ok, bootstrap = pcall(require, "neotex.bootstrap")

-- Make sure bootstrap exists before trying to use it
if bootstrap_ok and type(bootstrap) == "table" and type(bootstrap.init) == "function" then
  bootstrap.init()
end

-- If the new config structure fails, set up minimal fallback
if not config_ok then
  vim.notify("Error loading config structure: " .. tostring(config) .. ". Using minimal fallback.", vim.log.levels.WARN)
  -- Minimal fallback options without depending on deprecated modules
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.wrap = true
  vim.opt.breakindent = true
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
  vim.opt.mouse = "a"
else
  -- Load the new configuration
  pcall(config.setup)
end

-- Global function to ensure MCPHub is loaded and available
_G.ensure_mcphub_loaded = function()
  -- First trigger the event to lazy-load MCPHub
  vim.api.nvim_exec_autocmds("User", { pattern = "AvantePreLoad" })
  
  -- Check if the MCPHub command exists
  if vim.fn.exists(":MCPHub") == 0 then
    -- MCPHub command doesn't exist yet, try to load it directly
    
    -- First, check if Lazy has the plugin loaded
    local stats = require("lazy").stats()
    if not stats.loaded["mcphub.nvim"] then
      -- Try to explicitly load the plugin via Lazy
      pcall(function() vim.cmd("Lazy load mcphub.nvim") end)
      
      -- Wait a bit for the load to complete
      vim.defer_fn(function()
        -- Check again if the command exists
        if vim.fn.exists(":MCPHub") == 0 then
          -- Still doesn't exist, try to register it manually
          vim.api.nvim_create_user_command("MCPHub", function()
            -- Ensure the module is loaded when the command is called
            local ensure_mcphub = require("neotex.util.ensure_mcphub")
            
            -- Start the server directly using our helper function
            ensure_mcphub.start_mcphub_server()
          end, {})
          
          vim.notify("Manually registered MCPHub command", vim.log.levels.INFO)
        end
      end, 100)
    end
  end
  
  return true
end

-- Track MCPHub server state to prevent multiple startups
_G.mcphub_server_started = false

-- Create command for loading MCPHub
vim.api.nvim_create_user_command("MCPHubLoad", function()
  -- Ensure the module is loaded first
  local ensure_mcphub = require("neotex.util.ensure_mcphub")
  
  -- Load the plugin
  _G.ensure_mcphub_loaded()
  
  -- Start the server directly using our helper function
  ensure_mcphub.start_mcphub_server()
end, { desc = "Force load MCPHub plugin and start server" })


-- If bootstrap fails, set up minimal fallback
if not bootstrap_ok then
  vim.notify("Error loading bootstrap: " .. tostring(bootstrap) .. ". Using minimal fallback.", vim.log.levels.WARN)
  -- Ensure minimal plugin management functionality
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if vim.loop.fs_stat(lazypath) then
    vim.opt.rtp:prepend(lazypath)
    pcall(require, "lazy")
  end
end
