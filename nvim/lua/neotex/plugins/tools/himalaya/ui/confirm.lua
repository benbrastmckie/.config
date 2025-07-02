-- Modern confirmation dialog system
local M = {}

-- Dependencies
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Show a confirmation dialog with Return/Escape handling
function M.show(opts)
  opts = vim.tbl_extend('force', {
    title = 'Confirm',
    message = 'Are you sure?',
    options = { 'Yes', 'No' },
    default = 2,
    keys = { confirm = '<CR>', cancel = '<Esc>' },
  }, opts or {})
  
  -- Calculate dimensions
  local width = math.max(#opts.title + 4, #opts.message + 4, 20)
  for _, option in ipairs(opts.options) do
    width = math.max(width, #option + 6)
  end
  local height = 5 + #opts.options
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Create centered floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. opts.title .. ' ',
    title_pos = 'center',
  })
  
  -- Render content
  local lines = {
    '',
    opts.message,
    '',
  }
  
  for i, option in ipairs(opts.options) do
    local prefix = i == opts.default and '> ' or '  '
    table.insert(lines, prefix .. option)
  end
  
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Set cursor to default option
  vim.api.nvim_win_set_cursor(win, { 3 + opts.default, 0 })
  
  -- Result handling
  local result = nil
  local selected = opts.default
  
  -- Update selection display
  local function update_selection(new_selected)
    selected = new_selected
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    
    local updated_lines = {}
    for i, option in ipairs(opts.options) do
      local prefix = i == selected and '> ' or '  '
      updated_lines[i] = prefix .. option
    end
    
    vim.api.nvim_buf_set_lines(buf, 3, 3 + #opts.options, false, updated_lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_win_set_cursor(win, { 3 + selected, 0 })
  end
  
  -- Close window and return result
  local function close_with_result(res)
    result = res
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  
  -- Setup keymaps
  local keymap_opts = { buffer = buf, nowait = true, noremap = true, silent = true }
  
  -- Navigation
  vim.keymap.set('n', 'j', function()
    if selected < #opts.options then
      update_selection(selected + 1)
    end
  end, keymap_opts)
  
  vim.keymap.set('n', 'k', function()
    if selected > 1 then
      update_selection(selected - 1)
    end
  end, keymap_opts)
  
  vim.keymap.set('n', '<Down>', function()
    if selected < #opts.options then
      update_selection(selected + 1)
    end
  end, keymap_opts)
  
  vim.keymap.set('n', '<Up>', function()
    if selected > 1 then
      update_selection(selected - 1)
    end
  end, keymap_opts)
  
  -- Number selection
  for i = 1, math.min(#opts.options, 9) do
    vim.keymap.set('n', tostring(i), function()
      update_selection(i)
      close_with_result(i)
    end, keymap_opts)
  end
  
  -- Confirm with Enter
  vim.keymap.set('n', opts.keys.confirm, function()
    close_with_result(selected)
  end, keymap_opts)
  
  -- Cancel with Escape
  vim.keymap.set('n', opts.keys.cancel, function()
    close_with_result(nil)
  end, keymap_opts)
  
  -- Also support q for cancel
  vim.keymap.set('n', 'q', function()
    close_with_result(nil)
  end, keymap_opts)
  
  -- Support y/n for yes/no dialogs
  if #opts.options == 2 then
    local opt1_lower = opts.options[1]:lower()
    local opt2_lower = opts.options[2]:lower()
    
    if (opt1_lower:match('yes') or opt1_lower:match('confirm') or opt1_lower:match('ok')) then
      vim.keymap.set('n', 'y', function()
        close_with_result(1)
      end, keymap_opts)
      
      vim.keymap.set('n', 'n', function()
        close_with_result(2)
      end, keymap_opts)
    elseif (opt2_lower:match('yes') or opt2_lower:match('confirm') or opt2_lower:match('ok')) then
      vim.keymap.set('n', 'y', function()
        close_with_result(2)
      end, keymap_opts)
      
      vim.keymap.set('n', 'n', function()
        close_with_result(1)
      end, keymap_opts)
    end
  end
  
  -- Focus the window
  vim.api.nvim_set_current_win(win)
  
  -- Wait for result (blocking)
  vim.cmd('redraw')
  while vim.api.nvim_win_is_valid(win) do
    vim.cmd('sleep 10m')
  end
  
  logger.debug('Confirmation dialog result', { 
    title = opts.title, 
    result = result,
    selected_option = result and opts.options[result] or 'cancelled'
  })
  
  return result
end

-- Convenience method for yes/no confirmations
function M.yes_no(title, message, default_to_no)
  return M.show({
    title = title,
    message = message,
    options = { 'Yes', 'No' },
    default = default_to_no and 2 or 1,
  }) == 1
end

-- Convenience method for ok/cancel confirmations
function M.ok_cancel(title, message)
  return M.show({
    title = title,
    message = message,
    options = { 'OK', 'Cancel' },
    default = 2,
  }) == 1
end

-- Convenience method for delete confirmations
function M.delete_confirm(item_description)
  return M.show({
    title = 'Delete ' .. item_description,
    message = 'Are you sure you want to delete this ' .. item_description .. '?',
    options = { 'Delete', 'Cancel' },
    default = 2,
  }) == 1
end

return M