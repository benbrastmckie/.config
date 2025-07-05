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

local notify = require('neotex.util.notifications')

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
  notify.editor('Nvim configuration reloaded!', notify.categories.USER_ACTION)
end

-- Close all buffers except current one
function M.close_other_buffers()
  local current = vim.fn.bufnr('%')
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and bufnr ~= current then
      vim.cmd(string.format('silent! bdelete %d', bufnr))
    end
  end
  notify.editor("Closed all other buffers", notify.categories.USER_ACTION)
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

  notify.editor(string.format("Closed %d unused buffers (inactive for >%d minutes)", closed_count, minutes), notify.categories.USER_ACTION)
end

-- Save all modified buffers
function M.save_all_buffers()
  vim.cmd('wall')
  notify.editor("Saved all modified buffers", notify.categories.USER_ACTION)
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

-- Delete the file associated with the current buffer
function M.delete_file_and_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()

  -- Get the file path
  local filepath = vim.api.nvim_buf_get_name(buf)
  if not filepath or filepath == '' then
    notify.editor('No file associated with this buffer', notify.categories.WARNING)
    return
  end

  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    notify.editor('File does not exist: ' .. filepath, notify.categories.WARNING)
    return
  end

  -- Use async confirmation prompt
  local filename = vim.fn.fnamemodify(filepath, ':t')
  local prompt = string.format(" Delete file \"%s\"?", filename)

  vim.ui.select({"Yes", "No"}, {
    prompt = prompt,
    kind = "file_deletion",
    format_item = function(item)
      if item == "Yes" then
        return " " .. item  -- Check mark
      else
        return " " .. item  -- X mark
      end
    end,
  }, function(choice)
    if choice ~= "Yes" then
      return
    end

    -- Proceed with deletion
    local current_win = vim.api.nvim_get_current_win()
    local buffers = vim.api.nvim_list_bufs()
    local alternate_buf = nil

    -- Find a suitable buffer to switch to
    for _, b in ipairs(buffers) do
      if b ~= buf and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
        local buftype = vim.api.nvim_buf_get_option(b, 'buftype')
        local bufname = vim.api.nvim_buf_get_name(b)
        -- Skip special buffers and ensure it has a real file
        if buftype == '' and bufname ~= '' then
          alternate_buf = b
          break
        end
      end
    end

    -- If no alternate buffer found, create a new empty one
    if not alternate_buf then
      alternate_buf = vim.api.nvim_create_buf(true, false)
    end

    -- Delete the file first
    local ok = vim.fn.delete(filepath)
    if ok == 0 then
      -- Switch to alternate buffer in all windows showing this buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == buf then
          vim.api.nvim_win_set_buf(win, alternate_buf)
        end
      end

      -- Now delete the buffer
      vim.api.nvim_buf_delete(buf, { force = true })
      notify.editor('Deleted: ' .. filename, notify.categories.USER_ACTION)
    else
      notify.editor('Failed to delete file: ' .. filepath, notify.categories.ERROR)
    end
  end)
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

  vim.api.nvim_create_user_command('BufDeleteFile', function()
    M.delete_file_and_buffer()
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
