-- buffer-opener.lua
-- Purpose: Context-aware buffer opening for Claude Code workflow artifacts
-- Integrates with the post-buffer-opener.sh hook to open artifacts in Neovim
--
-- Zero Undo Impact: Opening a new buffer does not affect existing buffers' undo trees
--
-- Usage:
--   local opener = require('neotex.plugins.ai.claude.util.buffer-opener')
--   opener.open_artifact('/path/to/artifact.md')

local M = {}

-- Attempt to load notification system (graceful fallback)
local notifications
local ok, notify_module = pcall(require, 'neotex.util.notifications')
if ok then
  notifications = notify_module
end

-- Configuration
M.config = {
  -- Focus the new buffer after opening
  focus_new_buffer = true,
  -- Show notification on artifact open
  show_notifications = true,
}

-- Setup function to configure the module
function M.setup(user_config)
  if user_config then
    M.config = vim.tbl_deep_extend('force', M.config, user_config)
  end
end

-- Detect if current buffer is a terminal buffer
local function is_terminal_buffer()
  local buftype = vim.bo.buftype
  return buftype == 'terminal'
end

-- Find a non-terminal window in the current tabpage to open buffers in
-- Returns window handle or nil if no suitable window found
local function find_editor_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
    -- Look for normal buffers (not terminal, not special buffers)
    if buftype == '' or buftype == 'acwrite' then
      return win
    end
  end
  return nil
end

-- Show notification using the unified notification system
local function notify(message, level)
  if not M.config.show_notifications then
    return
  end

  level = level or vim.log.levels.INFO

  if notifications then
    -- Use the AI module context for notifications
    notifications.ai(message, notifications.categories.USER_ACTION, {
      file = vim.fn.fnamemodify(message, ':t')
    })
  else
    -- Fallback to basic vim.notify
    vim.notify(message, level)
  end
end

-- Show error notification
local function notify_error(message)
  if notifications then
    notifications.error(message, {}, 'ai')
  else
    vim.notify(message, vim.log.levels.ERROR)
  end
end

-- Open artifact file with context-aware behavior
-- In terminal buffer: opens as new tab in editor pane (not splitting terminal)
-- In normal buffer: opens as new tab
function M.open_artifact(filepath)
  -- Validate filepath
  if not filepath or filepath == '' then
    notify_error('Buffer opener: No file path provided')
    return false
  end

  -- Check if file exists
  if vim.fn.filereadable(filepath) == 0 then
    notify_error('Buffer opener: File not found: ' .. filepath)
    return false
  end

  -- Escape the filepath for vim commands
  local escaped_path = vim.fn.fnameescape(filepath)

  -- Execute the open command with context-aware strategy
  local success, err = pcall(function()
    if is_terminal_buffer() then
      -- When called from terminal context, find editor window first
      local editor_win = find_editor_window()
      if editor_win then
        -- Switch to editor window, then open as new tab
        vim.api.nvim_set_current_win(editor_win)
        vim.cmd('tabedit ' .. escaped_path)
      else
        -- Fallback: create new tab (tab will be in editor area)
        vim.cmd('tabnew ' .. escaped_path)
      end
    else
      -- In normal buffer: open as new tab
      vim.cmd('tabedit ' .. escaped_path)
    end
  end)

  if not success then
    notify_error('Buffer opener: Failed to open file: ' .. tostring(err))
    return false
  end

  -- Extract filename for notification
  local filename = vim.fn.fnamemodify(filepath, ':t')
  notify('Opened artifact: ' .. filename)

  return true
end

-- Open artifact in a specific split direction (for explicit split requests)
function M.open_artifact_split(filepath, direction)
  if not filepath or filepath == '' then
    notify_error('Buffer opener: No file path provided')
    return false
  end

  if vim.fn.filereadable(filepath) == 0 then
    notify_error('Buffer opener: File not found: ' .. filepath)
    return false
  end

  local escaped_path = vim.fn.fnameescape(filepath)
  local split_cmd = (direction or 'vsplit') .. ' ' .. escaped_path

  local success, err = pcall(function()
    vim.cmd(split_cmd)
  end)

  if not success then
    notify_error('Buffer opener: Failed to open file: ' .. tostring(err))
    return false
  end

  local filename = vim.fn.fnamemodify(filepath, ':t')
  notify('Opened artifact: ' .. filename)

  return true
end

-- Open artifact in vertical split (convenience function)
function M.open_artifact_vsplit(filepath)
  return M.open_artifact_split(filepath, 'vsplit')
end

-- Open artifact in horizontal split (convenience function)
function M.open_artifact_hsplit(filepath)
  return M.open_artifact_split(filepath, 'split')
end

-- Open artifact replacing current buffer (convenience function)
function M.open_artifact_edit(filepath)
  if not filepath or filepath == '' then
    notify_error('Buffer opener: No file path provided')
    return false
  end

  if vim.fn.filereadable(filepath) == 0 then
    notify_error('Buffer opener: File not found: ' .. filepath)
    return false
  end

  local escaped_path = vim.fn.fnameescape(filepath)

  local success, err = pcall(function()
    vim.cmd('edit ' .. escaped_path)
  end)

  if not success then
    notify_error('Buffer opener: Failed to open file: ' .. tostring(err))
    return false
  end

  local filename = vim.fn.fnamemodify(filepath, ':t')
  notify('Opened artifact: ' .. filename)

  return true
end

return M
