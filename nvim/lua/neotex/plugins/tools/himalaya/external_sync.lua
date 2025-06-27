-- External Sync Detection and Handoff Module
-- Provides visibility and control over sync processes across Neovim instances

local M = {}

local notify = require('neotex.util.notifications')
local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')

-- Detection functions
function M.detect_external_sync()
  local status = streamlined_sync.get_status()
  
  -- Check if external sync is running (using the new field)
  if status.external_sync_running then
    local sync_info = M.analyze_external_sync()
    return true, sync_info
  end
  return false, nil
end

function M.analyze_external_sync()
  -- Parse ps output for sync details
  local handle = io.popen('ps aux | grep mbsync | grep -v grep | head -1')
  if not handle then return nil end
  
  local ps_output = handle:read('*a'):gsub('\n$', '') -- Remove trailing newline
  handle:close()
  
  if ps_output == '' then return nil end
  
  -- Parse ps output more carefully
  -- Format: USER PID %CPU %MEM VSZ RSS TTY STAT START TIME COMMAND
  local parts = {}
  for part in ps_output:gmatch('%S+') do
    table.insert(parts, part)
  end
  
  if #parts < 11 then return nil end
  
  local pid = parts[2]
  local start_time = parts[9]
  local runtime = parts[10]
  
  -- Extract command (everything after mbsync)
  local command = ps_output:match('mbsync%s+(.+)$') or ''
  command = command:gsub('\n', '') -- Remove any newlines
  
  -- Check if sync is likely stuck (> 5 minutes)
  local stuck = false
  if runtime then
    local min = tonumber(runtime:match('(%d+):')) or 0
    stuck = min >= 5
  end
  
  return {
    pid = pid,
    runtime = runtime,
    command = command,
    likely_stuck = stuck,
    start_time = start_time
  }
end

-- Progress file functions for Phase 2 preparation
function M.get_progress_file()
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  return string.format('/tmp/himalaya-sync-%s.progress', account)
end

function M.read_external_progress()
  local progress_file = M.get_progress_file()
  local file = io.open(progress_file, 'r')
  if not file then return nil end
  
  local content = file:read('*a')
  file:close()
  
  local ok, data = pcall(vim.json.decode, content)
  if not ok then return nil end
  
  -- Check if progress is stale (> 30 seconds)
  if data.last_update and os.time() - data.last_update > 30 then
    return nil
  end
  
  return data
end

-- Takeover prompt UI
function M.show_takeover_prompt(sync_info)
  if not sync_info then return end
  
  -- Sanitize fields to remove newlines
  local pid = (sync_info.pid or 'unknown'):gsub('\n', '')
  local runtime = (sync_info.runtime or 'unknown'):gsub('\n', '')
  local command = (sync_info.command or ''):gsub('\n', '')
  
  local lines = {
    'External sync process detected:',
    '',
    '  Process ID: ' .. pid,
    '  Runtime: ' .. runtime,
    '  Command: mbsync ' .. command,
    '',
  }
  
  if sync_info.likely_stuck then
    table.insert(lines, '⚠️  This sync appears stuck (running > 5 minutes)')
    table.insert(lines, '')
  end
  
  table.insert(lines, 'What would you like to do?')
  table.insert(lines, '')
  table.insert(lines, '[Y] Take control - Kill and restart with progress')
  table.insert(lines, '[N] Keep running - Show basic status only')
  table.insert(lines, '[A] Always take control (save preference)')
  table.insert(lines, '')
  table.insert(lines, 'Press Y/N/A or Esc to cancel')
  
  -- Create floating window
  local width = 60
  local height = #lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Center the window
  local win_width = vim.api.nvim_get_option('columns')
  local win_height = vim.api.nvim_get_option('lines')
  local row = math.floor((win_height - height) / 2)
  local col = math.floor((win_width - width) / 2)
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' External Sync Detected ',
    title_pos = 'center'
  })
  
  -- Set up keymaps for the prompt
  local function close_prompt()
    vim.api.nvim_win_close(win, true)
  end
  
  local function handle_choice(choice)
    close_prompt()
    
    if choice == 'y' or choice == 'Y' then
      M.takeover_external_sync(sync_info)
    elseif choice == 'a' or choice == 'A' then
      -- Save preference
      local config = require('neotex.plugins.tools.himalaya.config')
      config.set_sync_handoff_option('auto_takeover', true)
      M.takeover_external_sync(sync_info)
    elseif choice == 'n' or choice == 'N' then
      notify.himalaya('Keeping external sync running', notify.categories.STATUS)
    end
  end
  
  -- Set up keymaps
  vim.api.nvim_buf_set_keymap(buf, 'n', 'y', '', { callback = function() handle_choice('y') end })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'Y', '', { callback = function() handle_choice('Y') end })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'n', '', { callback = function() handle_choice('n') end })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'N', '', { callback = function() handle_choice('N') end })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'a', '', { callback = function() handle_choice('a') end })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'A', '', { callback = function() handle_choice('A') end })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', { callback = close_prompt })
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', { callback = close_prompt })
end

-- Takeover implementation
function M.takeover_external_sync(sync_info)
  if not sync_info or not sync_info.pid then
    notify.himalaya('No external sync to take over', notify.categories.WARNING)
    return
  end
  
  notify.himalaya('Taking control of external sync...', notify.categories.USER_ACTION)
  
  -- Kill external process gracefully
  os.execute('kill -TERM ' .. sync_info.pid .. ' 2>/dev/null')
  vim.wait(1000)
  
  -- Force kill if still running
  if os.execute('kill -0 ' .. sync_info.pid .. ' 2>/dev/null') == 0 then
    os.execute('kill -KILL ' .. sync_info.pid .. ' 2>/dev/null')
    vim.wait(500)
  end
  
  -- Clean up lock file
  streamlined_sync.release_lock()
  
  -- Determine sync type from command
  local force_full = false
  if sync_info.command then
    force_full = sync_info.command:match('%-a') or sync_info.command:match('gmail$')
  end
  
  -- Start new sync with progress
  notify.himalaya('Starting controlled sync with progress tracking...', notify.categories.STATUS)
  return streamlined_sync.sync_mail(force_full, true)
end

-- Auto-takeover check
function M.should_auto_takeover(sync_info)
  local config = require('neotex.plugins.tools.himalaya.config')
  local handoff_config = config.get_sync_handoff_config()
  
  if not handoff_config.enabled then
    return false
  end
  
  if handoff_config.auto_takeover then
    return true
  end
  
  -- Check if sync is running too long
  if handoff_config.auto_takeover_timeout and sync_info.runtime then
    local minutes = tonumber(sync_info.runtime:match('(%d+):')) or 0
    local seconds = tonumber(sync_info.runtime:match(':(%d+)')) or 0
    local total_seconds = minutes * 60 + seconds
    
    if total_seconds >= handoff_config.auto_takeover_timeout then
      return true
    end
  end
  
  return false
end

-- Check and handle external sync
function M.check_and_handle_external_sync()
  local has_external, sync_info = M.detect_external_sync()
  
  if not has_external then
    return false
  end
  
  -- Check for auto-takeover
  if M.should_auto_takeover(sync_info) then
    notify.himalaya('Auto-taking control of external sync', notify.categories.STATUS)
    M.takeover_external_sync(sync_info)
    return true
  end
  
  -- Show prompt
  M.show_takeover_prompt(sync_info)
  return true
end

-- User commands
function M.setup_commands()
  vim.api.nvim_create_user_command('HimalayaTakeoverSync', function()
    local has_external, sync_info = M.detect_external_sync()
    if has_external then
      M.takeover_external_sync(sync_info)
    else
      notify.himalaya('No external sync process found', notify.categories.STATUS)
    end
  end, { desc = 'Take control of external sync process' })
  
  vim.api.nvim_create_user_command('HimalayaExternalSyncInfo', function()
    local has_external, sync_info = M.detect_external_sync()
    if has_external then
      vim.notify(vim.inspect(sync_info), vim.log.levels.INFO)
    else
      notify.himalaya('No external sync process found', notify.categories.STATUS)
    end
  end, { desc = 'Show external sync information' })
  
  vim.api.nvim_create_user_command('HimalayaToggleAutoTakeover', function()
    local config = require('neotex.plugins.tools.himalaya.config')
    local current = config.get_sync_handoff_option('auto_takeover')
    config.set_sync_handoff_option('auto_takeover', not current)
    notify.himalaya('Auto-takeover ' .. (not current and 'enabled' or 'disabled'), notify.categories.STATUS)
  end, { desc = 'Toggle automatic sync takeover' })
end

-- Setup
function M.setup()
  M.setup_commands()
end

return M