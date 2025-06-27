-- Test simplified external sync detection
local M = {}

local notify = require('neotex.util.notifications')

function M.test_external_sync()
  notify.himalaya('=== Testing Simplified External Sync ===', notify.categories.USER_ACTION)
  
  -- Test 1: Check if external sync is detected
  local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  local status = streamlined_sync.get_status()
  
  notify.himalaya('Current status:', notify.categories.STATUS)
  notify.himalaya('  Local sync running: ' .. tostring(status.sync_running), notify.categories.STATUS)
  notify.himalaya('  External sync detected: ' .. tostring(status.external_sync_running), notify.categories.STATUS)
  
  -- Test 2: Check sync status line
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local status_line = ui.get_sync_status_line()
  
  if status_line then
    notify.himalaya('Status line: ' .. status_line, notify.categories.STATUS)
  else
    notify.himalaya('No sync status to display', notify.categories.STATUS)
  end
  
  -- Test 3: Check if mbsync is running
  local is_global = streamlined_sync.is_sync_running_globally()
  notify.himalaya('mbsync processes running: ' .. tostring(is_global), notify.categories.STATUS)
  
  notify.himalaya('=== Test Complete ===', notify.categories.USER_ACTION)
end

-- Test starting a sync
function M.test_sync_prevention()
  notify.himalaya('=== Testing Sync Prevention ===', notify.categories.USER_ACTION)
  
  -- Try to start a sync
  local streamlined_sync = require('neotex.plugins.tools.himalaya.streamlined_sync')
  local result = streamlined_sync.sync_inbox(true)
  
  if result then
    notify.himalaya('Sync started successfully', notify.categories.STATUS)
  else
    notify.himalaya('Sync prevented (as expected if external sync running)', notify.categories.STATUS)
  end
  
  notify.himalaya('=== Test Complete ===', notify.categories.USER_ACTION)
end

vim.api.nvim_create_user_command('HimalayaTestSimple', M.test_external_sync, {
  desc = 'Test simplified external sync detection'
})

vim.api.nvim_create_user_command('HimalayaTestPrevention', M.test_sync_prevention, {
  desc = 'Test sync prevention when external sync running'
})

return M