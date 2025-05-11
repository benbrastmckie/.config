-----------------------------------------------------------
-- Buffer Management Utilities
-- 
-- This module provides functions for working with buffers, including:
-- - Buffer navigation (goto_buffer)
-- - Buffer cleanup (close_other_buffers, close_unused_buffers)
-- - Buffer operations (display_messages, save_all_buffers)
-- - Configuration management (reload_config)
--
-- The utilities are exposed both as module functions and vim commands.
-----------------------------------------------------------

local M = {}

-- Go to next/previous most recent buffer, excluding buffers where winfixbuf = true
function M.goto_buffer(count, direction)
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
      table.insert(fixed_buffers, buf)
    else
      table.insert(normal_buffers, buf)
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

-- Display vim messages in quickfix window
function M.display_messages()
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

-- Find all instances of a word in a project with telescope
function M.search_word_under_cursor()
  local word = vim.fn.expand('<cword>')
  require('telescope.builtin').live_grep({ default_text = word })
end

-- Reload neovim config
function M.reload_config()
  for name, _ in pairs(package.loaded) do
    if name:match('^neotex') then
      package.loaded[name] = nil
    end
  end

  dofile(vim.env.MYVIMRC)
  vim.notify('Nvim configuration reloaded!', vim.log.levels.INFO)
end

-- Close all buffers except current one
function M.close_other_buffers()
  local current = vim.fn.bufnr('%')
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and bufnr ~= current then
      vim.cmd(string.format('silent! bdelete %d', bufnr))
    end
  end
  vim.notify("Closed all other buffers", vim.log.levels.INFO)
end

-- Close buffers that haven't been used for specified time
function M.close_unused_buffers(minutes)
  minutes = minutes or 30
  local threshold_time = os.time() - (minutes * 60)
  local current = vim.fn.bufnr('%')
  local closed_count = 0
  
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and bufnr ~= current then
      local bufinfo = vim.fn.getbufinfo(bufnr)[1]
      -- Check last used time and whether it's modified
      if not bufinfo.changed and bufinfo.lastused < threshold_time then
        vim.cmd(string.format('silent! bdelete %d', bufnr))
        closed_count = closed_count + 1
      end
    end
  end
  
  vim.notify(string.format("Closed %d unused buffers (inactive for >%d minutes)", closed_count, minutes), vim.log.levels.INFO)
end

-- Save all modified buffers
function M.save_all_buffers()
  vim.cmd('wall')
  vim.notify("Saved all modified buffers", vim.log.levels.INFO)
end

-- Jump to alternate buffer with optional fallback to most recent
function M.jump_to_alternate()
  local alt_bufnr = vim.fn.bufnr('#')
  if alt_bufnr ~= -1 then
    vim.cmd('buffer ' .. alt_bufnr)
  else
    -- Fallback to most recent buffer
    M.goto_buffer(1, 1)
  end
end

-- Set up global buffer-related commands
function M.setup()
  -- Set up the reload command
  vim.api.nvim_create_user_command('ReloadConfig', function()
    M.reload_config()
  end, {})
  
  -- Add more buffer-related commands
  vim.api.nvim_create_user_command('BufCloseOthers', function()
    M.close_other_buffers()
  end, {})
  
  vim.api.nvim_create_user_command('BufCloseUnused', function(opts)
    local minutes = tonumber(opts.args) or 30
    M.close_unused_buffers(minutes)
  end, { nargs = '?' })
  
  vim.api.nvim_create_user_command('BufSaveAll', function()
    M.save_all_buffers()
  end, {})
  
  -- Set up global function aliases for backward compatibility
  _G.GotoBuffer = function(count, direction)
    M.goto_buffer(count, direction)
  end
  
  _G.DisplayMessages = function()
    M.display_messages()
  end
  
  _G.SearchWordUnderCursor = function()
    M.search_word_under_cursor()
  end
  
  return true
end

return M