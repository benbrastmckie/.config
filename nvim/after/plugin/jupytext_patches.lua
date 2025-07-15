-- Patches for jupytext.nvim to work with Neovim 0.10+
-- This file patches the jupytext plugin to use the updated health check API
-- and fix the file reading error handling

-- Only apply patches if jupytext is loaded
local ok, _ = pcall(require, "jupytext")
if not ok then
  return
end

-- Patch the health check to use the new API
local health_path = vim.fn.stdpath("data") .. "/lazy/jupytext.nvim/lua/jupytext/health.lua"
if vim.fn.filereadable(health_path) == 1 then
  -- Override the health check module
  package.loaded["jupytext.health"] = nil
  local M = {}
  
  M.check = function()
    -- Use the new health check API for Neovim 0.10+
    local health = vim.health or require("health")
    health.start("jupytext.nvim")
    
    local result = vim.fn.system("jupytext --version")
    
    if vim.v.shell_error == 0 then
      health.ok("Jupytext is available: " .. vim.trim(result))
    else
      health.error("Jupytext is not available", { "Install jupytext via `pip install jupytext`" })
    end
  end
  
  -- Replace the module
  package.preload["jupytext.health"] = function()
    return M
  end
end

-- Patch the utils module to handle file reading errors
local utils_path = vim.fn.stdpath("data") .. "/lazy/jupytext.nvim/lua/jupytext/utils.lua"
if vim.fn.filereadable(utils_path) == 1 then
  -- Override the utils module
  package.loaded["jupytext.utils"] = nil
  local M = {}
  
  local language_extensions = {
    python = "py",
    julia = "jl",
    r = "r",
    R = "r",
    bash = "sh",
  }
  
  local language_names = {
    python3 = "python",
  }
  
  M.get_ipynb_metadata = function(filename)
    -- Safely read and parse the notebook file
    local file = io.open(filename, "r")
    if not file then
      vim.notify("Could not open notebook file: " .. filename, vim.log.levels.ERROR)
      return { language = "python", extension = "py" } -- Default fallback
    end
    
    local content = file:read("a")
    file:close()
    
    if not content or content == "" then
      vim.notify("Notebook file is empty: " .. filename, vim.log.levels.ERROR)
      return { language = "python", extension = "py" } -- Default fallback
    end
    
    local ok, data = pcall(vim.json.decode, content)
    if not ok then
      vim.notify("Could not parse notebook JSON: " .. filename, vim.log.levels.ERROR)
      return { language = "python", extension = "py" } -- Default fallback
    end
    
    -- Safely navigate the metadata structure
    local metadata = data and data.metadata
    if not metadata then
      return { language = "python", extension = "py" } -- Default fallback
    end
    
    local language = nil
    if metadata.kernelspec then
      language = metadata.kernelspec.language
      if not language and metadata.kernelspec.name then
        language = language_names[metadata.kernelspec.name]
      end
    end
    
    -- Default to python if no language found
    language = language or "python"
    local extension = language_extensions[language] or "txt"
    
    return { language = language, extension = extension }
  end
  
  M.get_jupytext_file = function(filename, extension)
    local fileroot = vim.fn.fnamemodify(filename, ":r")
    return fileroot .. "." .. extension
  end
  
  M.check_key = function(tbl, key)
    for tbl_key, _ in pairs(tbl) do
      if tbl_key == key then
        return true
      end
    end
    return false
  end
  
  -- Replace the module
  package.preload["jupytext.utils"] = function()
    return M
  end
end

-- Only show notification in debug mode
if vim.g.debug_mode then
  vim.notify("Jupytext patches applied for Neovim 0.10+ compatibility", vim.log.levels.INFO)
end