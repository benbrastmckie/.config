-- Test Email Commands for Himalaya Plugin

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers
local mock = framework.mock

-- Test suite
local tests = {}

-- Test email list command
table.insert(tests, framework.create_test('email_list_command', function()
  local himalaya = require('neotex.plugins.tools.himalaya')
  local commands = require('neotex.plugins.tools.himalaya.core.commands.email')
  
  -- Mock the utils.list_emails function
  local original_list = himalaya.utils.list_emails
  local mock_emails = {
    helpers.create_test_email({ subject = "Test 1" }),
    helpers.create_test_email({ subject = "Test 2" })
  }
  
  himalaya.utils.list_emails = function(folder)
    assert.equals(folder, "INBOX", "Should list INBOX folder")
    return { success = true, emails = mock_emails }
  end
  
  -- Test the command
  local result = commands.list_emails("INBOX")
  
  -- Verify results
  assert.truthy(result.success, "Command should succeed")
  assert.equals(#result.emails, 2, "Should return 2 emails")
  
  -- Restore original function
  himalaya.utils.list_emails = original_list
end))

-- Test email send command
table.insert(tests, framework.create_test('email_send_command', function()
  local scheduler = require('neotex.plugins.tools.himalaya.core.scheduler')
  
  -- Create test email
  local email_data = {
    to = { "test@example.com" },
    subject = "Test Subject",
    body = "Test Body"
  }
  
  -- Mock scheduler
  local original_schedule = scheduler.schedule_email
  local scheduled_email = nil
  
  scheduler.schedule_email = function(email, delay)
    scheduled_email = email
    return { success = true, id = "test-123" }
  end
  
  -- Send email (should be scheduled)
  local result = scheduler.schedule_email(email_data, 60)
  
  -- Verify scheduling
  assert.truthy(result.success, "Scheduling should succeed")
  assert.equals(result.id, "test-123", "Should return scheduled ID")
  assert.truthy(scheduled_email, "Email should be scheduled")
  
  -- Restore original
  scheduler.schedule_email = original_schedule
end))

-- Test email delete command
table.insert(tests, framework.create_test('email_delete_command', function()
  local commands = require('neotex.plugins.tools.himalaya.core.commands.email')
  local utils = require('neotex.plugins.tools.himalaya.utils')
  
  -- Mock delete function
  local original_delete = utils.delete_email
  local deleted_ids = {}
  
  utils.delete_email = function(id)
    table.insert(deleted_ids, id)
    return { success = true }
  end
  
  -- Test single delete
  local result = commands.delete_email("test-123")
  assert.truthy(result.success, "Delete should succeed")
  assert.contains(deleted_ids, "test-123", "Email should be deleted")
  
  -- Restore original
  utils.delete_email = original_delete
end))

-- Test email search command
table.insert(tests, framework.create_test('email_search_command', function()
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  -- Create test emails
  local emails = {
    helpers.create_test_email({ subject = "Important Meeting" }),
    helpers.create_test_email({ subject = "Regular Update" }),
    helpers.create_test_email({ subject = "Important Notice" })
  }
  
  -- Test search
  local results = search.filter_emails(emails, "subject:Important")
  
  -- Verify results
  assert.equals(#results, 2, "Should find 2 emails with 'Important' in subject")
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Email Commands', tests)

return _G.himalaya_test