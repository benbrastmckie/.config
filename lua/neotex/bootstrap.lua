-- Enhanced bootstrap.lua with improved error handling and organization
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
    require("lazy").setup({
      -- Current active imports
      { import = "neotex.plugins" },    -- main plugins directory
      { import = "neotex.plugins.lsp" }, -- lsp plugins directory
      
      -- Phase 2 imports (commented until implementation)
      -- { import = "neotex.plugins.coding" },  -- coding enhancement plugins
      -- { import = "neotex.plugins.editor" },  -- editor enhancement plugins
      -- { import = "neotex.plugins.tools" },   -- tool integration plugins
      -- { import = "neotex.plugins.ui" },      -- UI enhancement plugins
      -- { import = "neotex.plugins.extras" },  -- optional plugins
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
    })
  end, "setup of lazy.nvim plugins")
end

-- Setup Jupyter notebook styling with proper error handling
local function setup_jupyter_styling()
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(function()
        with_error_handling(function()
          local styling = require("neotex.plugins.jupyter.styling")
          if type(styling) == "table" and styling.setup then
            styling.setup()
          end
        end, "setup of Jupyter notebook styling")
      end, 1000)
    end,
    once = true
  })
end

-- Main initialization function
function M.init()
  local steps = {
    { func = cleanup_tmp_dirs, name = "Cleanup temporary directories" },
    { func = ensure_lazy, name = "Ensure lazy.nvim is installed" },
    { func = validate_lockfile, name = "Validate lazy-lock.json" },
    { func = setup_lazy, name = "Set up plugins with lazy.nvim" },
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
  
  if success then
    vim.notify("Neovim configuration loaded successfully", vim.log.levels.INFO)
  else
    vim.notify("Neovim configuration loaded with errors", vim.log.levels.WARN)
  end
  
  return success
end

-- Initialize the configuration
return M.init()