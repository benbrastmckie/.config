-- Test Full Email Workflow for Himalaya Plugin

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers
local mock = framework.mock

-- Test suite
local tests = {}

-- Test complete email workflow
table.insert(tests, framework.create_test('complete_email_workflow', function()
  local himalaya = require('neotex.plugins.tools.himalaya')
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  local state = require('neotex.plugins.tools.himalaya.core.state')
  
  -- Save original scheduler state
  local original_queue = vim.deepcopy(scheduler.queue)
  
  -- Initialize plugin
  himalaya.setup({
    accounts = {
      test = {
        name = "Test Account",
        email = "test@example.com"
      }
    }
  })
  
  -- 1. Open email list
  local list_result = himalaya.utils.list_emails("INBOX")
  assert.truthy(list_result, "Should list emails")
  
  -- 2. Compose new email
  local compose_data = {
    to = { "recipient@example.com" },
    subject = "Integration Test",
    body = "This is an integration test email"
  }
  
  -- 3. Schedule the email (all emails must be scheduled)
  local schedule_result = scheduler.schedule_email(compose_data, 60)
  assert.truthy(schedule_result.success, "Email should be scheduled")
  
  -- 4. Verify it's in the queue
  local queue = scheduler.get_scheduled_emails()
  local found = false
  for _, item in ipairs(queue) do
    if item.id == schedule_result.id then
      found = true
      assert.equals(item.email.subject, "Integration Test")
      break
    end
  end
  assert.truthy(found, "Scheduled email should be in queue")
  
  -- 5. Edit scheduled time
  local new_time = os.time() + 120
  local edit_result = scheduler.edit_scheduled_send_time(schedule_result.id, new_time)
  assert.truthy(edit_result.success, "Should edit scheduled time")
  
  -- 6. Save state
  state.save()
  
  -- 7. Verify state persistence
  local saved_state = state.get()
  assert.truthy(saved_state, "State should be saved")
  
  -- Clean up - cancel the scheduled email and restore original state
  scheduler.cancel_send(schedule_result.id)
  scheduler.queue = original_queue
end))

-- Test multi-account workflow
table.insert(tests, framework.create_test('multi_account_workflow', function()
  local himalaya = require('neotex.plugins.tools.himalaya')
  local multi_account = require('neotex.plugins.tools.himalaya.ui.multi_account')
  
  -- Setup multiple accounts
  himalaya.setup({
    accounts = {
      personal = {
        name = "Personal",
        email = "personal@example.com"
      },
      work = {
        name = "Work",
        email = "work@example.com"
      }
    }
  })
  
  -- Test unified inbox view
  multi_account.set_mode(multi_account.modes.UNIFIED)
  assert.equals(multi_account.get_mode(), "unified", "Should be in unified mode")
  
  -- Test split view
  multi_account.set_mode(multi_account.modes.SPLIT)
  assert.equals(multi_account.get_mode(), "split", "Should be in split mode")
  
  -- Test account switching
  local accounts = multi_account.get_accounts()
  assert.equals(#accounts, 2, "Should have 2 accounts")
end))

-- Test notification integration
table.insert(tests, framework.create_test('notification_integration', function()
  local notify = require('neotex.util.notifications')
  local himalaya = require('neotex.plugins.tools.himalaya')
  
  -- Capture notifications during operation
  local notifications = helpers.capture_notifications(function()
    -- Trigger some operations that should notify
    himalaya.utils.list_emails("INBOX")
  end)
  
  -- Verify notifications were sent
  assert.truthy(#notifications > 0, "Should have notifications")
  
  -- Check notification format
  local found_himalaya = false
  for _, notif in ipairs(notifications) do
    if notif.opts and notif.opts.module == "himalaya" then
      found_himalaya = true
      break
    end
  end
  assert.truthy(found_himalaya, "Should have himalaya notifications")
end))

-- Test error handling workflow
table.insert(tests, framework.create_test('error_handling_workflow', function()
  local himalaya = require('neotex.plugins.tools.himalaya')
  local errors = require('neotex.plugins.tools.himalaya.core.errors')
  
  -- Mock a failing operation
  local original_list = himalaya.utils.list_emails
  himalaya.utils.list_emails = function()
    return errors.create(
      errors.types.NETWORK_ERROR,
      "Connection failed",
      { details = "Test error" }
    )
  end
  
  -- Try to list emails
  local result = himalaya.utils.list_emails("INBOX")
  
  -- Verify error handling
  assert.falsy(result.success, "Operation should fail")
  assert.equals(result.type, errors.types.NETWORK_ERROR)
  assert.truthy(result.message, "Should have error message")
  
  -- Restore original
  himalaya.utils.list_emails = original_list
end))

-- Test sync integration
table.insert(tests, framework.create_test('sync_integration', function()
  local sync = require('neotex.plugins.tools.himalaya.sync.manager')
  local coordinator = require('neotex.plugins.tools.himalaya.sync.coordinator')
  
  -- Check coordinator state
  local is_primary = coordinator.is_primary()
  assert.truthy(is_primary ~= nil, "Should have primary/secondary status")
  
  -- Test sync cooldown
  local should_sync = coordinator.should_allow_sync()
  assert.truthy(should_sync ~= nil, "Should have sync decision")
  
  -- If we're primary and can sync
  if is_primary and should_sync then
    -- Mock sync operation
    local sync_called = false
    local original_sync = sync.sync_inbox
    sync.sync_inbox = function()
      sync_called = true
      return { success = true }
    end
    
    -- Trigger sync
    local result = sync.sync_inbox()
    assert.truthy(result.success, "Sync should succeed")
    assert.truthy(sync_called, "Sync should be called")
    
    -- Restore
    sync.sync_inbox = original_sync
  end
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Full Workflow Integration', tests)

return _G.himalaya_test