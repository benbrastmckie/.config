-----------------------------------------------------------
-- NeoVim Configuration Bootstrapping
-- Author: Benjamin Brast-McKie
-- 
-- This module handles the initialization of the NeoVim configuration.
-- It provides a robust sequence of steps to set up the environment,
-- load plugins, and initialize core functionality with proper error
-- handling at each step.
-----------------------------------------------------------

local M = {}

-- Utility function for error handling
local function with_error_handling(func, msg)
  local ok, err = pcall(func)
  if not ok then
    vim.notify("Error in " .. msg .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Clean up any tree-sitter tmp directories that might cause conflicts
local function cleanup_tmp_dirs()
  return with_error_handling(function()
    local tmp_dirs = vim.fn.glob(vim.fn.expand("~") .. "/tree-sitter-*-tmp", true, true)
    for _, dir in ipairs(tmp_dirs) do
      vim.fn.delete(dir, "rf")
    end
  end, "cleanup of temporary tree-sitter directories")
end

-- Ensure lazy.nvim is installed
local function ensure_lazy()
  return with_error_handling(function()
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
      vim.notify("Installing lazy.nvim...", vim.log.levels.INFO)
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
      })
    end
    vim.opt.rtp:prepend(lazypath)
  end, "installation of lazy.nvim")
end

-- Validate and fix lockfile if needed
local function validate_lockfile()
  return with_error_handling(function()
    local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
    if vim.fn.filereadable(lockfile) == 1 then
      -- Read the file content
      local content = table.concat(vim.fn.readfile(lockfile), "\n")
      -- Check if it's valid JSON
      local success, _ = pcall(vim.fn.json_decode, content)
      if not success then
        -- If not valid JSON, create a valid but empty JSON object
        local valid_json = [[{
  "_comments": "This is a temporary placeholder lock file that will be replaced when plugins are installed"
}]]
        vim.fn.writefile(vim.split(valid_json, "\n"), lockfile)
        vim.notify("Fixed invalid lazy-lock.json file", vim.log.levels.INFO)
      end
    end
  end, "validation of lazy-lock.json")
end

-- Initialize lazy.nvim with plugin specs
local function setup_lazy()
  return with_error_handling(function()
    -- Try to load the new plugin system first
    local ok, plugins = pcall(require, "neotex.plugins")
    
    -- If the new plugin system fails, fall back to the old import-based method
    if not ok then
      vim.notify("Using legacy plugin import system", vim.log.levels.DEBUG)
      
      require("lazy").setup({
        -- Legacy imports
        { import = "neotex.plugins" },    -- main plugins directory
        { import = "neotex.plugins.lsp" }, -- lsp plugins directory
      }, {
        install = {
          colorscheme = { "gruvbox" },
        },
        checker = {
          enabled = true,
          notify = false,
        },
        change_detection = {
          notify = false,
        },
        performance = {
          reset_packpath = true,
          rtp = {
            reset = true,
          },
        },
        rocks = {
          enabled = false,  -- Disable luarocks support completely
        },
      })
    else
      -- New plugin system - organize specs by category
      
      -- Set up with direct plugin specs AND the lsp imports
      -- This ensures backward compatibility during the transition
      require("lazy").setup({
        -- Direct plugin specs
        plugins,
        
        -- Legacy LSP import for backward compatibility
        { import = "neotex.plugins.lsp" },
        
        -- Phase 2 imports
        -- coding plugins have been moved to editor directory
        { import = "neotex.plugins.editor" },  -- editor enhancement plugins (includes former coding plugins)
        { import = "neotex.plugins.tools" },   -- tool integration plugins
        { import = "neotex.plugins.text" },    -- text format-specific plugins
        { import = "neotex.plugins.ui" },      -- UI enhancement plugins
        
        -- Phase 4 imports
        { import = "neotex.plugins.ai" },      -- AI tooling plugins
      }, {
        install = {
          colorscheme = { "gruvbox" },
        },
        checker = {
          enabled = true,
          notify = false,
        },
        change_detection = {
          notify = false,
        },
        performance = {
          reset_packpath = true,
          rtp = {
            reset = true,
          },
        },
        rocks = {
          enabled = false,  -- Disable luarocks support completely
        },
      })
    end
  end, "setup of lazy.nvim plugins")
end

-- Setup Jupyter notebook styling with proper error handling
local function setup_jupyter_styling()
  -- Create a VimEnter autocmd for deferred Jupyter styling setup
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function()
        -- Safely attempt to load the styling module
        with_error_handling(function()
          local ok, styling
          
          -- First, check if any ipynb files are open before loading the styling
          local any_ipynb = false
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local bufname = vim.api.nvim_buf_get_name(buf)
            if bufname:match("%.ipynb$") then
              any_ipynb = true
              break
            end
          end
          
          -- Only load styling if needed
          if any_ipynb then
            ok, styling = pcall(require, "neotex.plugins.text.jupyter.styling")
            if ok and type(styling) == "table" and styling.setup then
              styling.setup()
            end
          end
        end, "setup of Jupyter notebook styling")
      end, 1500) -- Increased delay to ensure all plugins are loaded
    end,
    once = true
  })
  
  -- Always return true since the actual setup is deferred
  return true
end

-- Initialize utilities with error handling
local function setup_utils()
  return with_error_handling(function()
    local utils = require("neotex.util")
    if type(utils) == "table" and utils.setup then
      utils.setup()
    end
  end, "setup of utilities")
end

-- Main initialization function
function M.init()
  local steps = {
    { func = cleanup_tmp_dirs, name = "Cleanup temporary directories" },
    { func = ensure_lazy, name = "Ensure lazy.nvim is installed" },
    { func = validate_lockfile, name = "Validate lazy-lock.json" },
    { func = setup_lazy, name = "Set up plugins with lazy.nvim" },
    { func = setup_utils, name = "Initialize utility functions" },
    { func = setup_jupyter_styling, name = "Configure Jupyter styling" },
  }
  
  local success = true
  for _, step in ipairs(steps) do
    if not step.func() then
      vim.notify("Failed at step: " .. step.name, vim.log.levels.ERROR)
      success = false
      break
    end
  end
  
  if not success then
    -- Only notify on errors
    vim.notify("Neovim configuration loaded with errors", vim.log.levels.WARN)
  end
  
  return success
end

-- Return the module, let init.lua call M.init()
return M
