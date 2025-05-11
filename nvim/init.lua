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
