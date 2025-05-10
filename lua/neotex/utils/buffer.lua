-- neotex.utils.buffer
-- Utilities for buffer management

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

-- Set up global buffer-related commands
function M.setup()
  -- Set up the reload command
  vim.api.nvim_create_user_command('ReloadConfig', function()
    M.reload_config()
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