-- Debug sync state module
local M = {}

local notify = require('neotex.util.notifications')

function M.debug_sync_state()
  local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  local external_sync = require('neotex.plugins.tools.himalaya.external_sync')
  
  notify.himalaya('=== DEBUG SYNC STATE ===', notify.categories.USER_ACTION)
  
  -- Get internal state
  local state = streamlined_sync.state
  local status = streamlined_sync.get_status()
  
  notify.himalaya('Internal state:', notify.categories.STATUS)
  notify.himalaya('  sync_running: ' .. tostring(state.sync_running), notify.categories.STATUS)
  notify.himalaya('  sync_pid: ' .. tostring(state.sync_pid), notify.categories.STATUS)
  notify.himalaya('  vim pid: ' .. vim.fn.getpid(), notify.categories.STATUS)
  
  -- Check global mbsync
  local global_running = streamlined_sync.is_sync_running_globally()
  notify.himalaya('  global mbsync: ' .. tostring(global_running), notify.categories.STATUS)
  
  -- Check external detection
  local has_external, sync_info = external_sync.detect_external_sync()
  notify.himalaya('External detection:', notify.categories.STATUS)
  notify.himalaya('  has_external: ' .. tostring(has_external), notify.categories.STATUS)
  notify.himalaya('  external_sync_running: ' .. tostring(status.external_sync_running), notify.categories.STATUS)
  
  if sync_info then
    notify.himalaya('  external pid: ' .. tostring(sync_info.pid), notify.categories.STATUS)
    notify.himalaya('  external cmd: ' .. tostring(sync_info.command), notify.categories.STATUS)
  end
  
  -- Check lock file
  local lock_file = '/tmp/himalaya-sync.lock'
  local handle = io.open(lock_file, 'r')
  if handle then
    local lock_pid = handle:read('*a')
    handle:close()
    notify.himalaya('Lock file:', notify.categories.STATUS)
    notify.himalaya('  lock pid: ' .. tostring(lock_pid), notify.categories.STATUS)
  else
    notify.himalaya('  No lock file', notify.categories.STATUS)
  end
  
  -- List all mbsync processes
  local ps_handle = io.popen('ps aux | grep mbsync | grep -v grep')
  if ps_handle then
    local ps_output = ps_handle:read('*a')
    ps_handle:close()
    notify.himalaya('mbsync processes:', notify.categories.STATUS)
    for line in ps_output:gmatch('[^\n]+') do
      notify.himalaya('  ' .. line:sub(1, 100), notify.categories.STATUS)
    end
  end
  
  notify.himalaya('=== END DEBUG ===', notify.categories.USER_ACTION)
end

-- Add command
vim.api.nvim_create_user_command('HimalayaDebugSync', M.debug_sync_state, {
  desc = 'Debug Himalaya sync state'
})

return M