-- Test Progress File System
-- Verifies progress sharing works correctly across instances

local M = {}

local notify = require('neotex.util.notifications')

-- Test progress file writing and reading
function M.test_progress_sharing()
  notify.himalaya('=== Testing Progress File Sharing ===', notify.categories.USER_ACTION)
  
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  
  -- Test 1: Write a test progress file
  notify.himalaya('Test 1: Writing test progress file...', notify.categories.STATUS)
  
  local test_data = {
    pid = vim.fn.getpid(),
    start_time = os.time() - 30,
    command = 'mbsync gmail-inbox',
    progress = {
      current_operation = "Testing progress",
      current_message = 45,
      total_messages = 98,
      messages_added = 12,
      messages_added_total = 20,
      far_total = 98,
      near_total = 86
    },
    last_update = os.time()
  }
  
  local file = io.open(progress_file, 'w')
  if file then
    file:write(vim.json.encode(test_data))
    file:close()
    notify.himalaya('✓ Test progress file written', notify.categories.STATUS)
  else
    notify.himalaya('✗ Failed to write test file', notify.categories.ERROR)
    return
  end
  
  -- Test 2: Read and validate the progress file
  notify.himalaya('Test 2: Reading and validating progress file...', notify.categories.STATUS)
  
  local validator = require('neotex.plugins.tools.himalaya.progress_validator')
  local read_data, err = validator.read_validated_progress(account)
  
  if not read_data then
    notify.himalaya('✗ Failed to read progress: ' .. (err or 'unknown error'), notify.categories.ERROR)
    return
  end
  
  -- Test 3: Verify data integrity
  notify.himalaya('Test 3: Verifying data integrity...', notify.categories.STATUS)
  
  local tests_passed = 0
  local tests_total = 0
  
  local function test(name, expected, actual)
    tests_total = tests_total + 1
    if expected == actual then
      tests_passed = tests_passed + 1
      notify.himalaya('  ✓ ' .. name, notify.categories.STATUS)
    else
      notify.himalaya(string.format('  ✗ %s: expected %s, got %s', 
        name, tostring(expected), tostring(actual)), notify.categories.ERROR)
    end
  end
  
  test('PID matches', test_data.pid, read_data.pid)
  test('Command matches', test_data.command, read_data.command)
  test('Current message', test_data.progress.current_message, read_data.progress.current_message)
  test('Total messages', test_data.progress.total_messages, read_data.progress.total_messages)
  test('Operation', test_data.progress.current_operation, read_data.progress.current_operation)
  
  -- Test 4: Test UI display
  notify.himalaya('Test 4: Testing UI display...', notify.categories.STATUS)
  
  local ui = require('neotex.plugins.tools.himalaya.ui')
  local status_line = ui.get_sync_status_line()
  
  if status_line then
    notify.himalaya('  Status line: ' .. status_line, notify.categories.STATUS)
  else
    notify.himalaya('  No status line (might need external sync running)', notify.categories.WARNING)
  end
  
  -- Test 5: Cleanup
  notify.himalaya('Test 5: Cleaning up test file...', notify.categories.STATUS)
  os.remove(progress_file)
  notify.himalaya('✓ Test file removed', notify.categories.STATUS)
  
  -- Summary
  notify.himalaya(string.format('\n=== Test Summary: %d/%d passed ===', 
    tests_passed, tests_total), notify.categories.USER_ACTION)
end

-- Test stale progress detection
function M.test_stale_detection()
  notify.himalaya('=== Testing Stale Progress Detection ===', notify.categories.USER_ACTION)
  
  local config = require('neotex.plugins.tools.himalaya.config')
  local account = config.get_current_account_name() or 'gmail'
  local progress_file = string.format('/tmp/himalaya-sync-%s.progress', account)
  
  -- Write a stale progress file
  local stale_data = {
    pid = 99999,
    last_update = os.time() - 120, -- 2 minutes old
    progress = {
      current_operation = "Old sync"
    }
  }
  
  local file = io.open(progress_file, 'w')
  if file then
    file:write(vim.json.encode(stale_data))
    file:close()
  end
  
  -- Try to read it
  local validator = require('neotex.plugins.tools.himalaya.progress_validator')
  local data, err = validator.read_validated_progress(account)
  
  if data then
    notify.himalaya('✗ Stale data was not rejected!', notify.categories.ERROR)
  else
    notify.himalaya('✓ Stale data correctly rejected: ' .. (err or ''), notify.categories.STATUS)
  end
  
  -- Cleanup
  os.remove(progress_file)
end

-- Test progress monitoring
function M.test_progress_monitor()
  notify.himalaya('=== Testing Progress Monitor ===', notify.categories.USER_ACTION)
  notify.himalaya('Starting 10-second monitor test...', notify.categories.STATUS)
  
  local validator = require('neotex.plugins.tools.himalaya.progress_validator')
  local update_count = 0
  
  -- Start monitoring
  local timer = validator.monitor_progress_file('gmail', function(data)
    update_count = update_count + 1
    notify.himalaya(string.format('Progress update %d: %s', 
      update_count, data.progress.current_operation or 'unknown'), notify.categories.STATUS)
  end)
  
  -- Stop after 10 seconds
  vim.defer_fn(function()
    vim.fn.timer_stop(timer)
    notify.himalaya(string.format('Monitor test complete: %d updates detected', update_count), notify.categories.USER_ACTION)
  end, 10000)
end

-- Setup commands
vim.api.nvim_create_user_command('HimalayaTestProgress', M.test_progress_sharing, {
  desc = 'Test Himalaya progress file sharing'
})

vim.api.nvim_create_user_command('HimalayaTestStale', M.test_stale_detection, {
  desc = 'Test stale progress detection'
})

vim.api.nvim_create_user_command('HimalayaTestMonitor', M.test_progress_monitor, {
  desc = 'Test progress file monitoring'
})

return M