-- Trash Browser UI
-- Simple interface for viewing and managing trash contents

local M = {}

local trash_manager = require('neotex.plugins.tools.himalaya.trash_manager')
local trash_operations = require('neotex.plugins.tools.himalaya.trash_operations')

-- Show trash browser
function M.show_trash_browser()
  local items = trash_manager.list_trash_items()
  
  if #items == 0 then
    vim.notify('Trash is empty', vim.log.levels.INFO)
    return
  end
  
  -- Create buffer for trash browser
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'himalaya-trash')
  
  -- Format trash contents
  local lines = M.format_trash_list(items)
  
  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Store items in buffer variable for keymap access
  vim.api.nvim_buf_set_var(buf, 'trash_items', items)
  
  -- Open in floating window
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' Trash Browser ',
    title_pos = 'center'
  })
  
  -- Set up keymaps for trash browser
  M.setup_trash_keymaps(buf)
  
  -- Set cursor to first email line (skip header)
  if #items > 0 then
    vim.api.nvim_win_set_cursor(win, {4, 0}) -- Skip 3 header lines
  end
end

-- Format trash list for display
function M.format_trash_list(items)
  local lines = {
    '# Himalaya Local Trash Browser',
    '# ' .. #items .. ' items in trash',
    '',
    'ID                   | From Folder    | Deleted Date         | Size',
    string.rep('-', 80)
  }
  
  for i, item in ipairs(items) do
    local size_str = M.format_file_size(item.size_bytes or 0)
    local date_str = M.format_date(item.deleted_date)
    local folder_str = M.truncate_string(item.original_folder, 14)
    local id_str = M.truncate_string(item.email_id, 20)
    
    local line = string.format('%-20s | %-14s | %-19s | %s',
      id_str, folder_str, date_str, size_str
    )
    
    table.insert(lines, line)
  end
  
  if #items == 0 then
    table.insert(lines, '')
    table.insert(lines, 'No items in trash')
  else
    table.insert(lines, '')
    table.insert(lines, 'Keymaps: <CR>=View details, gR=Restore, gD=Permanent delete, q=Close')
  end
  
  return lines
end

-- Setup keymaps for trash browser
function M.setup_trash_keymaps(buf)
  local opts = { buffer = buf, silent = true }
  
  -- Close trash browser
  vim.keymap.set('n', 'q', function()
    vim.api.nvim_win_close(0, true)
  end, opts)
  
  -- View email details
  vim.keymap.set('n', '<CR>', function()
    M.view_trash_item_details(buf)
  end, opts)
  
  -- Restore email
  vim.keymap.set('n', 'gR', function()
    M.restore_current_item(buf)
  end, opts)
  
  -- Permanent delete
  vim.keymap.set('n', 'gD', function()
    M.permanent_delete_current_item(buf)
  end, opts)
  
  -- Refresh trash view
  vim.keymap.set('n', 'r', function()
    M.refresh_trash_browser(buf)
  end, opts)
end

-- Get current trash item from cursor position
function M.get_current_trash_item(buf)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local items = vim.api.nvim_buf_get_var(buf, 'trash_items')
  
  -- Account for header lines (items start at line 6)
  local item_index = cursor_line - 5
  
  if item_index >= 1 and item_index <= #items then
    return items[item_index]
  end
  
  return nil
end

-- View detailed information about trash item
function M.view_trash_item_details(buf)
  local item = M.get_current_trash_item(buf)
  if not item then
    vim.notify('No trash item selected', vim.log.levels.WARN)
    return
  end
  
  local details = {
    'Email ID: ' .. item.email_id,
    'Original Folder: ' .. item.original_folder,
    'Deleted Date: ' .. item.deleted_date,
    'File Path: ' .. item.file_path,
    'Size: ' .. M.format_file_size(item.size_bytes or 0),
    '',
    'Actions:',
    '  gR - Restore to original folder',
    '  gD - Permanently delete'
  }
  
  -- Show in a small popup
  local detail_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(detail_buf, 0, -1, false, details)
  vim.api.nvim_buf_set_option(detail_buf, 'modifiable', false)
  
  local popup_win = vim.api.nvim_open_win(detail_buf, false, {
    relative = 'cursor',
    width = 50,
    height = #details,
    row = 1,
    col = 0,
    style = 'minimal',
    border = 'rounded',
    title = ' Email Details ',
    title_pos = 'center'
  })
  
  -- Auto-close popup after 5 seconds or on any key
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(popup_win) then
      vim.api.nvim_win_close(popup_win, true)
    end
  end, 5000)
end

-- Restore current trash item
function M.restore_current_item(buf)
  local item = M.get_current_trash_item(buf)
  if not item then
    vim.notify('No trash item selected', vim.log.levels.WARN)
    return
  end
  
  local success = trash_operations.restore_from_trash(item.email_id)
  if success then
    M.refresh_trash_browser(buf)
  end
end

-- Permanently delete current trash item
function M.permanent_delete_current_item(buf)
  local item = M.get_current_trash_item(buf)
  if not item then
    vim.notify('No trash item selected', vim.log.levels.WARN)
    return
  end
  
  local success = trash_operations.permanent_delete(item.email_id)
  if success then
    M.refresh_trash_browser(buf)
  end
end

-- Refresh trash browser content
function M.refresh_trash_browser(buf)
  local items = trash_manager.list_trash_items()
  local lines = M.format_trash_list(items)
  
  -- Update buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Update stored items
  vim.api.nvim_buf_set_var(buf, 'trash_items', items)
  
  vim.notify('Trash browser refreshed', vim.log.levels.INFO)
end

-- Utility functions
function M.format_file_size(bytes)
  if bytes < 1024 then
    return bytes .. 'B'
  elseif bytes < 1024 * 1024 then
    return math.floor(bytes / 1024) .. 'KB'
  else
    return math.floor(bytes / 1024 / 1024 * 10) / 10 .. 'MB'
  end
end

function M.format_date(iso_date)
  -- Convert from ISO format to readable format
  local year, month, day, hour, min = iso_date:match('(%d+)-(%d+)-(%d+)T(%d+):(%d+)')
  if year then
    return string.format('%s/%s/%s %s:%s', month, day, year, hour, min)
  end
  return iso_date
end

function M.truncate_string(str, max_len)
  if #str <= max_len then
    return str
  end
  return str:sub(1, max_len - 3) .. '...'
end

-- Setup commands for trash UI
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaTrash', M.show_trash_browser, {
    desc = 'Open trash browser interface'
  })
end

return M