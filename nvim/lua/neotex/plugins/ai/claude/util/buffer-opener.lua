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
  -- Split direction when opening from terminal
  split_direction = 'vsplit',  -- 'vsplit' or 'split'
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
-- In terminal buffer: opens in vertical split
-- In normal buffer: replaces current buffer
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

  -- Determine opening strategy based on current buffer context
  local open_command
  if is_terminal_buffer() then
    -- In terminal: open in split to preserve terminal
    open_command = M.config.split_direction .. ' ' .. escaped_path
  else
    -- In normal buffer: replace current buffer
    open_command = 'edit ' .. escaped_path
  end

  -- Execute the open command
  local success, err = pcall(function()
    vim.cmd(open_command)
  end)

  if not success then
    notify_error('Buffer opener: Failed to open file: ' .. tostring(err))
    return false
  end

  -- Optionally focus the new buffer (already focused by default)
  if M.config.focus_new_buffer then
    -- The vim command already focuses the new buffer
  end

  -- Extract filename for notification
  local filename = vim.fn.fnamemodify(filepath, ':t')
  notify('Opened artifact: ' .. filename)

  return true
end

-- Open artifact in a specific split direction (override config)
function M.open_artifact_split(filepath, direction)
  local original_direction = M.config.split_direction
  M.config.split_direction = direction or 'vsplit'
  local result = M.open_artifact(filepath)
  M.config.split_direction = original_direction
  return result
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
