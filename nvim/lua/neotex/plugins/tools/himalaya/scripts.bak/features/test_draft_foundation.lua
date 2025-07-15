-- Draft Foundation Test Suite
-- Tests for Phase 1: Core draft infrastructure

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert

-- Setup notification system for testing
local notify = require('neotex.util.notifications')

-- Force reinitialize notification state for testing
notify.history = notify.history or {}
notify.config = notify.config or {}
notify.stats = notify.stats or {
  total_notifications = 0,
  filtered_notifications = 0,
  batched_notifications = 0,
  by_module = {},
  by_category = {},
  performance = {
    avg_processing_time = 0,
    max_processing_time = 0,
    total_processing_time = 0
  }
}

-- Always call setup to ensure proper initialization
notify.setup({
  enabled = true,
  debug_mode = false,
  max_history = 200,
  modules = {
    himalaya = { enabled = true, debug_mode = false }
  }
})

-- Test suite
local tests = {}

-- Test 1: Draft Manager initialization
table.insert(tests, framework.create_test('draft_manager_setup', function()
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  
  -- Setup should work without errors
  local ok = pcall(draft_manager.setup)
  assert.truthy(ok, "Draft manager setup should not error")
  
  -- Check initial state
  assert.equals(type(draft_manager.drafts), 'table', "Drafts table should exist")
  assert.equals(vim.tbl_count(draft_manager.drafts), 0, "Should start with no drafts")
end))

-- Test 2: Local Storage initialization
table.insert(tests, framework.create_test('local_storage_setup', function()
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Setup should create directories
  storage.setup()
  
  -- Check directory exists
  assert.equals(vim.fn.isdirectory(storage.config.base_dir), 1, "Storage directory should exist")
  
  -- Check index is loaded
  assert.equals(type(storage.index), 'table', "Storage index should be a table")
end))

-- Test 3: Draft creation and state tracking
table.insert(tests, framework.create_test('draft_creation', function()
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Clear any existing data
  storage._clear_all()
  draft_manager.setup()
  
  -- Create a test buffer
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.eml')
  
  -- Create draft
  local draft = draft_manager.create(buf, 'test_account', {
    subject = 'Test Draft',
    to = 'test@example.com'
  })
  
  -- Verify draft structure
  assert.truthy(draft, "Draft should be created")
  assert.equals(draft.buffer, buf, "Draft should reference correct buffer")
  assert.equals(draft.state, draft_manager.states.NEW, "Draft should start in NEW state")
  assert.truthy(draft.local_id, "Draft should have local ID")
  assert.equals(draft.account, 'test_account', "Draft should have correct account")
  assert.equals(draft.metadata.subject, 'Test Draft', "Draft should have correct subject")
  assert.equals(draft.metadata.to, 'test@example.com', "Draft should have correct recipient")
  
  -- Verify buffer variable is set
  local ok, buffer_draft = pcall(vim.api.nvim_buf_get_var, buf, 'himalaya_draft')
  assert.truthy(ok, "Buffer should have himalaya_draft variable")
  assert.equals(buffer_draft.local_id, draft.local_id, "Buffer variable should match draft")
  
  -- Verify draft is tracked
  local tracked = draft_manager.get_by_buffer(buf)
  assert.truthy(tracked, "Draft should be tracked by buffer")
  assert.equals(tracked.local_id, draft.local_id, "Tracked draft should match")
  
  -- Cleanup
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end))

-- Test 4: Local save functionality
table.insert(tests, framework.create_test('local_save', function()
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Setup
  storage._clear_all()
  draft_manager.setup()
  storage.setup()
  
  -- Create buffer with content
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.eml')
  
  -- Add email content
  local content = {
    'Subject: Test Email',
    'To: recipient@example.com',
    'From: sender@example.com',
    '',
    'This is the email body.',
    'Multiple lines of content.'
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  
  -- Create and save draft
  local draft = draft_manager.create(buf, 'test_account')
  local save_ok, save_err = draft_manager.save_local(buf)
  
  assert.truthy(save_ok, "Local save should succeed: " .. tostring(save_err))
  assert.truthy(draft.content_hash, "Draft should have content hash after save")
  assert.truthy(draft.modified_at, "Draft should have modified timestamp")
  
  -- Verify storage
  local stored = storage.load(draft.local_id)
  assert.truthy(stored, "Draft should be stored locally")
  assert.equals(stored.account, 'test_account', "Stored draft should have correct account")
  assert.truthy(stored.content:match('This is the email body'), "Stored content should match")
  
  -- Verify metadata was updated from content
  assert.equals(draft.metadata.subject, 'Test Email', "Subject should be parsed from content")
  assert.equals(draft.metadata.to, 'recipient@example.com', "To should be parsed from content")
  
  -- Cleanup
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end))

-- Test 5: Storage operations
table.insert(tests, framework.create_test('storage_operations', function()
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Clear and setup
  storage._clear_all()
  storage.setup()
  
  -- Test save
  local test_data = {
    metadata = { subject = 'Storage Test', to = 'test@example.com' },
    content = 'Test content for storage',
    account = 'test_account',
    remote_id = '12345'
  }
  
  local save_ok = storage.save('test_id_1', test_data)
  assert.truthy(save_ok, "Storage save should succeed")
  
  -- Test load
  local loaded = storage.load('test_id_1')
  assert.truthy(loaded, "Should load saved data")
  assert.equals(loaded.metadata.subject, 'Storage Test', "Loaded data should match")
  assert.equals(loaded.remote_id, '12345', "Remote ID should be preserved")
  
  -- Test list
  local list = storage.list()
  assert.equals(#list, 1, "Should list one draft")
  assert.equals(list[1].local_id, 'test_id_1', "Listed draft should have correct ID")
  
  -- Test find by remote ID
  local found = storage.find_by_remote_id('12345', 'test_account')
  assert.truthy(found, "Should find draft by remote ID")
  assert.equals(found.metadata.subject, 'Storage Test', "Found draft should match")
  
  -- Test delete
  local delete_ok = storage.delete('test_id_1')
  assert.truthy(delete_ok, "Delete should succeed")
  
  -- Verify deletion
  local deleted = storage.load('test_id_1')
  assert.falsy(deleted, "Deleted draft should not load")
  
  local list_after = storage.list()
  assert.equals(#list_after, 0, "Should have no drafts after deletion")
end))

-- Test 6: Notification categorization
table.insert(tests, framework.create_test('notification_categories', function()
  local notifications = require('neotex.plugins.tools.himalaya.core.draft_notifications')
  local notify = require('neotex.util.notifications')
  
  -- Store original notify function
  local original_notify = notify.himalaya
  local captured_notifications = {}
  
  -- Mock notify to capture calls
  notify.himalaya = function(message, category, context)
    table.insert(captured_notifications, {
      message = message,
      category = category,
      context = context
    })
  end
  
  -- Test user action notifications
  notifications.draft_saved('123', 'Test Subject')
  local saved_notif = captured_notifications[#captured_notifications]
  assert.equals(saved_notif.category, notify.categories.USER_ACTION, 
    "Draft saved should be USER_ACTION")
  
  notifications.draft_deleted('123')
  local deleted_notif = captured_notifications[#captured_notifications]
  assert.equals(deleted_notif.category, notify.categories.USER_ACTION,
    "Draft deleted should be USER_ACTION")
  
  -- Test error notifications
  notifications.draft_save_failed('123', 'Test error')
  local error_notif = captured_notifications[#captured_notifications]
  assert.equals(error_notif.category, notify.categories.ERROR,
    "Draft save failed should be ERROR")
  
  -- Test debug notifications (should check debug mode)
  local debug_count_before = #captured_notifications
  
  -- Mock debug mode off
  notify.config = { modules = { himalaya = { debug_mode = false } } }
  notifications.draft_syncing('123')
  assert.equals(#captured_notifications, debug_count_before,
    "Debug notifications should not show when debug mode is off")
  
  -- Mock debug mode on
  notify.config = { modules = { himalaya = { debug_mode = true } } }
  notifications.draft_syncing('123')
  assert.equals(#captured_notifications, debug_count_before + 1,
    "Debug notifications should show when debug mode is on")
  
  local sync_notif = captured_notifications[#captured_notifications]
  assert.equals(sync_notif.category, notify.categories.STATUS,
    "Draft syncing should be STATUS")
  
  -- Restore original function
  notify.himalaya = original_notify
end))

-- Test 7: Draft manager cleanup
table.insert(tests, framework.create_test('draft_cleanup', function()
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Setup
  storage._clear_all()
  draft_manager.setup()
  
  -- Create buffer and draft
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.eml')
  
  local draft = draft_manager.create(buf, 'test_account')
  assert.truthy(draft_manager.has_draft(buf), "Should have draft for buffer")
  
  -- Delete buffer (simulating user action)
  vim.api.nvim_buf_delete(buf, { force = true })
  
  -- Wait for autocmd to fire
  vim.wait(100, function() return false end)
  
  -- Check draft is cleaned up from memory but not from storage
  assert.falsy(draft_manager.get_by_buffer(buf), "Draft should be removed from memory")
  
  -- Storage should still have the draft
  local stored = storage.load(draft.local_id)
  assert.truthy(stored, "Draft should still exist in storage after buffer cleanup")
end))

-- Test 8: Multiple draft management
table.insert(tests, framework.create_test('multiple_drafts', function()
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Setup
  storage._clear_all()
  draft_manager.setup()
  
  -- Create multiple drafts
  local buffers = {}
  local drafts = {}
  
  for i = 1, 3 do
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. '.eml')
    table.insert(buffers, buf)
    
    local draft = draft_manager.create(buf, 'test_account', {
      subject = 'Draft ' .. i,
      to = 'recipient' .. i .. '@example.com'
    })
    table.insert(drafts, draft)
  end
  
  -- Verify all drafts are tracked
  local all_drafts = draft_manager.get_all()
  assert.equals(#all_drafts, 3, "Should have 3 drafts")
  
  -- Verify each can be retrieved
  for i, buf in ipairs(buffers) do
    local draft = draft_manager.get_by_buffer(buf)
    assert.truthy(draft, "Should find draft for buffer " .. i)
    assert.equals(draft.metadata.subject, 'Draft ' .. i, "Draft should have correct subject")
  end
  
  -- Cleanup
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Draft Foundation', tests)

return _G.himalaya_test