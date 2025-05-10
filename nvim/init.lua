-- Neovim configuration entry point
-- Author: Benjamin
-- Repository: https://github.com/username/neovim-config

-- Load the core configuration first
pcall(require, "neotex.core")

-- Load configuration with improved error handling
local ok, bootstrap = pcall(require, "neotex.bootstrap")

-- If bootstrap fails, fall back to the original method
if not ok then
  vim.notify("Error loading bootstrap: " .. tostring(bootstrap) .. ". Falling back to original bootstrap.", vim.log.levels.ERROR)
  pcall(require, "neotex.bootstrap")
end