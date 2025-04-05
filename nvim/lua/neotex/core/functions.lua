-- Display vim messages in quickfix window
function DisplayMessages()
  -- Get all messages and split them into lines
  local messages = vim.fn.execute('messages')
  local lines = vim.split(messages, '\n')

  -- Create quickfix items from messages
  local qf_items = vim.tbl_map(function(line)
    return { text = line }
  end, lines)

  -- Set the quickfix list and open it
  vim.fn.setqflist(qf_items)
  vim.cmd('copen')
end

-- Fine all instances of a word in a project with telescope
function SearchWordUnderCursor()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({ default_text = word })
end

-- Reload neovim config
vim.api.nvim_create_user_command('ReloadConfig', function()
  for name, _ in pairs(package.loaded) do
    if name:match('^plugins') then
      package.loaded[name] = nil
    end
  end

  dofile(vim.env.MYVIMRC)
  vim.notify('Nvim configuration reloaded!', vim.log.levels.INFO)
end, {})

-- Go to next/previous most recent buffer, excluding buffers where winfixbuf = true
function GotoBuffer(count, direction)
  -- Check if a buffer is in a fixed window
  local function is_buffer_fixed(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if vim.wo[win].winfixbuf then
        return true
      end
    end
    return false
  end

  -- Check if current window is fixed
  local current_buf = vim.api.nvim_get_current_buf()
  if is_buffer_fixed(current_buf) then
    return
  end

  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  -- Filter and sort buffers into two groups
  local normal_buffers = {}
  local fixed_buffers = {}

  for _, buf in ipairs(buffers) do
    if is_buffer_fixed(buf.bufnr) then
      table.insert(normal_buffers, buf)
    else
      table.insert(fixed_buffers, buf)
    end
  end

  -- Sort both lists by modification time
  local sort_by_mtime = function(a, b)
    return vim.fn.getftime(a.name) > vim.fn.getftime(b.name)
  end
  table.sort(normal_buffers, sort_by_mtime)
  table.sort(fixed_buffers, sort_by_mtime)

  -- Choose which buffer list to use
  local target_buffers = #normal_buffers > 0 and normal_buffers or fixed_buffers
  if #target_buffers == 0 then
    return
  end

  -- Find current buffer index
  local current = vim.fn.bufnr('%')
  local current_index = 1
  for i, buf in ipairs(target_buffers) do
    if buf.bufnr == current then
      current_index = i
      break
    end
  end

  -- Calculate target buffer index
  local target_index = current_index + (direction * count)
  if target_index < 1 then
    target_index = #target_buffers
  elseif target_index > #target_buffers then
    target_index = 1
  end

  -- Switch to target buffer
  vim.cmd('buffer ' .. target_buffers[target_index].bufnr)
end

-- Note: Avante functionality has been moved to lua/neotex/plugins/ai/avante-support.lua

-- Function to toggle between fully open and fully closed folds
function _G.ToggleAllFolds()
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
    vim.notify("All folds closed", vim.log.levels.INFO)
  else
    -- Some folds are closed, so open them all
    vim.cmd('normal! zR')
    vim.notify("All folds opened", vim.log.levels.INFO)
  end
end

-- Create a functions table for requiring from other modules
local M = {}

-- Custom Markdown header-based folding function
-- This creates folds at each heading level (# Header)
function _G.MarkdownFoldLevel()
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
function M.ToggleFoldEnable()
  -- Toggle the foldenable option
  vim.wo.foldenable = not vim.wo.foldenable
  
  -- Show notification about the new state
  if vim.wo.foldenable then
    vim.notify("Folding enabled", vim.log.levels.INFO)
  else
    vim.notify("Folding disabled", vim.log.levels.INFO)
  end
end

-- Function to toggle between manual and expr folding method
-- The state is persisted between sessions for all filetypes
function _G.ToggleFoldingMethod()
  local cache_dir = vim.fn.stdpath("cache")
  local fold_state_file = cache_dir .. "/folding_state"
  
  -- Ensure the cache directory exists
  vim.fn.mkdir(cache_dir, "p")
  
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
      vim.notify("Folding enabled (expr with markdown support)", vim.log.levels.INFO)
    else
      -- For other filetypes, use indent folding which is generally useful
      new_method = "indent"
      vim.wo.foldmethod = "indent"
      vim.notify("Folding enabled (indent)", vim.log.levels.INFO)
    end
    
    -- Save the state to file
    local file = io.open(fold_state_file, "w")
    if file then
      file:write(new_method)
      file:close()
    end
  else
    new_method = "manual"
    vim.wo.foldmethod = "manual"
    vim.notify("Folding set to manual", vim.log.levels.INFO)
    
    -- Save the state to file
    local file = io.open(fold_state_file, "w")
    if file then
      file:write("manual")
      file:close()
    end
  end
  
  -- Ensure folds are visible (whether open or closed)
  vim.wo.foldenable = true
end

-- Function to load the saved folding state
function M.LoadFoldingState()
  local cache_dir = vim.fn.stdpath("cache")
  local fold_state_file = cache_dir .. "/folding_state"
  
  -- Check if the state file exists
  if vim.fn.filereadable(fold_state_file) == 1 then
    local file = io.open(fold_state_file, "r")
    if file then
      local state = file:read("*all")
      file:close()
      
      -- Apply the saved state
      if state == "expr" and (vim.bo.filetype == "markdown" or vim.bo.filetype == "lectic.markdown") then
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.MarkdownFoldLevel()"
      elseif state == "indent" then
        vim.wo.foldmethod = "indent"
      else
        vim.wo.foldmethod = "manual"
      end
    end
  end
  
  -- Ensure foldenable is always set to true
  vim.wo.foldenable = true
  -- Start with all folds open for better usability
  vim.wo.foldlevel = 99
end

-- Return the module
return M