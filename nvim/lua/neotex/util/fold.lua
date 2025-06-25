-----------------------------------------------------------
-- Fold Management Utilities
-- 
-- This module provides functions for working with code folding:
-- - Toggling folds (toggle_all_folds, toggle_fold_enable)
-- - Customizing fold behavior (toggle_folding_method)
-- - Specific fold implementations (markdown_fold_level)
-- - Persistence of fold settings (load_folding_state)
--
-- The module includes state persistence between sessions and
-- file-specific folding methods.
-----------------------------------------------------------

local notify = require('neotex.util.notifications')

local M = {}

-- Function to toggle between fully open and fully closed folds
function M.toggle_all_folds()
  -- Get current state by checking if any folds are closed
  local all_open = true
  local line_count = vim.fn.line('$')

  for i = 1, line_count do
    if vim.fn.foldclosed(i) ~= -1 then
      -- Found a closed fold, so not all are open
      all_open = false
      break
    end
  end

  if all_open then
    -- All folds are open, so close them all
    vim.cmd('normal! zM')
    notify.editor("All folds closed", notify.categories.USER_ACTION)
  else
    -- Some folds are closed, so open them all
    vim.cmd('normal! zR')
    notify.editor("All folds opened", notify.categories.USER_ACTION)
  end
end

-- Custom Markdown header-based folding function
-- This creates folds at each heading level (# Header)
function M.markdown_fold_level()
  local line = vim.fn.getline(vim.v.lnum)
  local next_line = vim.fn.getline(vim.v.lnum + 1)

  -- Check for markdown headings (### style)
  local level = line:match("^(#+)%s")
  if level then
    return ">" .. string.len(level)
  end

  -- Check for markdown headings (underline style)
  if next_line and next_line:match("^=+$") then
    return ">1"
  end
  if next_line and next_line:match("^-+$") then
    return ">2"
  end

  -- Keep current level for indented content
  return "="
end

-- Function to toggle foldenable with notification
function M.toggle_fold_enable()
  -- Toggle the foldenable option
  vim.wo.foldenable = not vim.wo.foldenable

  -- Show notification about the new state
  if vim.wo.foldenable then
    notify.editor("Folding enabled", notify.categories.USER_ACTION)
  else
    notify.editor("Folding disabled", notify.categories.USER_ACTION)
  end
end

-- Function to toggle between manual and expr folding method
-- The state is persisted between sessions for all filetypes
function M.toggle_folding_method()
  local cache_dir = vim.fn.stdpath("cache")
  local fold_state_file = cache_dir .. "/folding_state"

  -- Ensure the cache directory exists
  vim.fn.mkdir(cache_dir, 'p')

  -- The current folding method
  local current_method = vim.wo.foldmethod
  local new_method = ""

  -- Toggle the folding method
  if current_method == "manual" then
    -- For markdown files, we use our custom expression
    if vim.bo.filetype == "markdown" or vim.bo.filetype == "lectic.markdown" then
      new_method = "expr"
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
      notify.editor("Folding enabled (expr with markdown support)", notify.categories.USER_ACTION)
    else
      -- For other filetypes, use indent folding which is generally useful
      new_method = "indent"
      vim.wo.foldmethod = "indent"
      notify.editor("Folding enabled (indent)", notify.categories.USER_ACTION)
    end

    -- Save the state to file with error handling
    local ok, err = pcall(function()
      local file = io.open(fold_state_file, "w")
      if not file then
        error("Could not open fold state file for writing")
      end
      file:write(new_method)
      file:close()
    end)

    if not ok then
      notify.editor("Error saving fold state: " .. err, notify.categories.WARNING)
    end
  else
    new_method = "manual"
    vim.wo.foldmethod = "manual"
    notify.editor("Folding set to manual", notify.categories.USER_ACTION)

    -- Save the state to file with error handling
    local ok, err = pcall(function()
      local file = io.open(fold_state_file, "w")
      if not file then
        error("Could not open fold state file for writing")
      end
      file:write("manual")
      file:close()
    end)

    if not ok then
      notify.editor("Error saving fold state: " .. err, notify.categories.WARNING)
    end
  end

  -- Ensure folds are visible (whether open or closed)
  vim.wo.foldenable = true
end

-- Function to load the saved folding state
function M.load_folding_state()
  local cache_dir = vim.fn.stdpath("cache")
  local fold_state_file = cache_dir .. "/folding_state"

  -- Check if the state file exists
  if vim.fn.filereadable(fold_state_file) == 1 then
    local ok, result = pcall(function()
      local file = io.open(fold_state_file, "r")
      if not file then
        error("Could not open fold state file for reading")
      end

      local state = file:read("*all")
      file:close()
      return state
    end)

    if ok then
      local state = result

      -- Apply the saved state
      if state == "expr" and (vim.bo.filetype == "markdown" or vim.bo.filetype == "lectic.markdown") then
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
      elseif state == "indent" then
        vim.wo.foldmethod = "indent"
      else
        vim.wo.foldmethod = "manual"
      end
    else
      notify.editor("Error loading fold state: " .. result, notify.categories.WARNING)
      -- Fall back to manual folding
      vim.wo.foldmethod = "manual"
    end
  else
    -- No state file exists, default to manual folding
    vim.wo.foldmethod = "manual"
  end

  -- Ensure foldenable is always set to true
  vim.wo.foldenable = true
  -- Start with all folds open for better usability
  vim.wo.foldlevel = 99
end

-- Set up global fold-related utilities
function M.setup()
  -- Set up global function aliases for backward compatibility
  _G.ToggleAllFolds = function()
    M.toggle_all_folds()
  end
  
  _G.MarkdownFoldLevel = function()
    return M.markdown_fold_level()
  end
  
  _G.ToggleFoldingMethod = function()
    M.toggle_folding_method()
  end
  
  return true
end

return M