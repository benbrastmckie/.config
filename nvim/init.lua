-- Neovim configuration entry point
-- Author: Benjamin
-- Repository: https://github.com/username/neovim-config

-- Load configuration with improved error handling
local config_ok, config = pcall(require, "neotex.config")
local bootstrap_ok, bootstrap = pcall(require, "neotex.bootstrap")

-- If the new config structure fails, fall back to the original
if not config_ok then
  vim.notify("Error loading new config structure: " .. tostring(config) .. ". Falling back to original core.", vim.log.levels.WARN)
  pcall(require, "neotex.core")
else
  -- Load the new configuration
  pcall(config.setup)
end

-- If bootstrap fails, fall back to the original method
if not bootstrap_ok then
  vim.notify("Error loading bootstrap: " .. tostring(bootstrap) .. ". Falling back to original bootstrap.", vim.log.levels.WARN)
  pcall(require, "neotex.bootstrap")
end