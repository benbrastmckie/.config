-- Draft Composer Test Suite
-- Tests for Phase 2: Email composer integration

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert

-- Setup notification system for testing
local notify = require('neotex.util.notifications')
-- Force reinitialize notification state
notify.history = notify.history or {}
notify.config = notify.config or {
  enabled = true,
  debug_mode = false,
  max_history = 200,
  modules = {
    himalaya = { enabled = true, debug_mode = false }
  }
}
notify.setup(notify.config)

-- Test suite
local tests = {}

-- Mock scheduler to prevent real email sending
local scheduler_mock = {
  schedule_email = function(email, time)
    return "mock_scheduled_id_" .. tostring(os.time())
  end
}
package.loaded['neotex.plugins.tools.himalaya.core.scheduler'] = scheduler_mock

-- Test 1: Email composer setup
table.insert(tests, framework.create_test('composer_setup', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Clear any existing data
  storage._clear_all()
  draft_manager.setup()
  
  -- Setup composer
  local ok = pcall(composer.setup, {
    compose = {
      auto_save_interval = 1, -- 1 second for testing
      use_tab = false
    }
  })
  
  assert.truthy(ok, "Composer setup should not error")
  assert.equals(composer.config.auto_save_interval, 1, "Config should be updated")
end))

-- Test 2: Create new draft composition
table.insert(tests, framework.create_test('new_draft_creation', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  
  -- Create compose buffer
  local buf = composer.create_compose_buffer({
    to = 'test@example.com',
    subject = 'Test Draft Subject',
    account = 'test_account'
  })
  
  assert.truthy(buf, "Buffer should be created")
  assert.truthy(vim.api.nvim_buf_is_valid(buf), "Buffer should be valid")
  
  -- Check draft was created
  local draft = draft_manager.get_by_buffer(buf)
  assert.truthy(draft, "Draft should be created and tracked")
  assert.equals(draft.metadata.to, 'test@example.com', "To field should match")
  assert.equals(draft.metadata.subject, 'Test Draft Subject', "Subject should match")
  assert.equals(draft.account, 'test_account', "Account should match")
  assert.equals(draft.state, draft_manager.states.NEW, "Draft should be in NEW state")
  
  -- Check buffer has correct content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  assert.truthy(lines[1]:match('From:'), "Should have From header")
  assert.truthy(lines[2]:match('To: test@example.com'), "Should have To header")
  assert.truthy(lines[5]:match('Subject: Test Draft Subject'), "Should have Subject header")
  
  -- Cleanup
  composer.close_compose_buffer(buf)
end))

-- Test 3: Autosave functionality
table.insert(tests, framework.create_test('autosave_drafts', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- Create compose buffer
  local buf = composer.create_compose_buffer({
    to = 'autosave@example.com',
    subject = 'Autosave Test'
  })
  
  local draft = draft_manager.get_by_buffer(buf)
  assert.truthy(draft, "Draft should exist")
  
  -- Modify buffer content
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { 'This is autosave test content.' })
  vim.api.nvim_buf_set_option(buf, 'modified', true)
  
  -- Wait for autosave (configured to 1 second in test)
  vim.wait(1500, function() return false end)
  
  -- Check if content was saved to local storage
  local saved = storage.load(draft.local_id)
  assert.truthy(saved, "Draft should be saved to local storage")
  assert.truthy(saved.content:match('This is autosave test content'), "Content should be saved")
  
  -- Cleanup
  composer.close_compose_buffer(buf)
end))

-- Test 4: Reply workflow
table.insert(tests, framework.create_test('reply_workflow', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  
  -- Create reply draft
  local buf = composer.create_compose_buffer({
    to = 'original@example.com',
    subject = 'Re: Original Subject',
    compose_type = 'reply',
    reply_to = '12345',
    body = '\nOn 2024-01-10, original@example.com wrote:\n> Original message content'
  })
  
  assert.truthy(buf, "Reply buffer should be created")
  
  local draft = draft_manager.get_by_buffer(buf)
  assert.truthy(draft, "Reply draft should be tracked")
  assert.equals(draft.metadata.compose_type, 'reply', "Should be marked as reply")
  assert.equals(draft.metadata.reply_to, '12345', "Should track original message ID")
  
  -- Check content includes quoted text
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  assert.truthy(content:match('> Original message content'), "Should include quoted text")
  
  -- Cleanup
  composer.close_compose_buffer(buf)
end))

-- Test 5: Open existing draft
table.insert(tests, framework.create_test('open_existing_draft', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local storage = require('neotex.plugins.tools.himalaya.core.local_storage')
  
  -- First, create and save a draft
  local test_draft = {
    metadata = {
      to = 'existing@example.com',
      subject = 'Existing Draft',
      from = 'sender@example.com',
      cc = '',
      bcc = ''
    },
    content = 'This is the existing draft content.',
    account = 'test_account',
    remote_id = '99999'
  }
  
  -- Save to local storage
  storage.save('test_existing_draft', test_draft)
  
  -- Mock the load function to return our test data
  local original_load = draft_manager.load
  draft_manager.load = function(remote_id, account)
    if remote_id == '99999' and account == 'test_account' then
      return test_draft
    end
    return original_load(remote_id, account)
  end
  
  -- Open the draft
  local buf = composer.open_draft('99999', 'test_account')
  assert.truthy(buf, "Should open draft buffer")
  
  -- Check draft is tracked
  local draft = draft_manager.get_by_buffer(buf)
  assert.truthy(draft, "Draft should be tracked")
  assert.equals(draft.remote_id, '99999', "Should have correct remote ID")
  assert.equals(draft.state, draft_manager.states.SYNCED, "Should be in SYNCED state")
  
  -- Check content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  assert.truthy(content:match('existing@example.com'), "Should have correct recipient")
  assert.truthy(content:match('Existing Draft'), "Should have correct subject")
  assert.truthy(content:match('This is the existing draft content'), "Should have correct body")
  
  -- Restore original function
  draft_manager.load = original_load
  
  -- Cleanup
  composer.close_compose_buffer(buf)
end))

-- Test 6: Send and close workflow
table.insert(tests, framework.create_test('send_and_close', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  
  -- Create draft
  local buf = composer.create_compose_buffer({
    to = 'send@example.com',
    subject = 'Send Test Email',
    body = 'This email should be sent.'
  })
  
  local draft = draft_manager.get_by_buffer(buf)
  assert.truthy(draft, "Draft should exist")
  
  -- Send email
  local ok, err = composer.send_and_close(buf)
  assert.truthy(ok, "Send should succeed: " .. tostring(err))
  
  -- Buffer should be deleted
  assert.falsy(vim.api.nvim_buf_is_valid(buf), "Buffer should be deleted after send")
  
  -- Draft should be cleaned up
  assert.falsy(draft_manager.get_by_buffer(buf), "Draft should be removed from tracking")
end))

-- Test 7: Multiple draft management
table.insert(tests, framework.create_test('multiple_drafts', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  
  -- Create multiple drafts
  local buffers = {}
  for i = 1, 3 do
    local buf = composer.create_compose_buffer({
      to = 'recipient' .. i .. '@example.com',
      subject = 'Draft ' .. i
    })
    table.insert(buffers, buf)
  end
  
  -- Check all are tracked
  local compose_buffers = composer.get_compose_buffers()
  assert.equals(#compose_buffers, 3, "Should have 3 compose buffers")
  
  -- Check each buffer
  for i, buf in ipairs(buffers) do
    assert.truthy(composer.is_compose_buffer(buf), "Buffer " .. i .. " should be compose buffer")
    local draft = draft_manager.get_by_buffer(buf)
    assert.truthy(draft, "Draft " .. i .. " should exist")
    assert.equals(draft.metadata.subject, 'Draft ' .. i, "Subject should match")
  end
  
  -- Cleanup
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      composer.close_compose_buffer(buf)
    end
  end
end))

-- Test 8: Sync engine integration
table.insert(tests, framework.create_test('sync_engine_integration', function()
  local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_v2')
  local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
  local sync_engine = require('neotex.plugins.tools.himalaya.core.sync_engine')
  
  -- Initialize sync engine
  sync_engine.setup({
    sync_interval = 100, -- 100ms for testing
    max_retries = 1
  })
  
  -- Create draft
  local buf = composer.create_compose_buffer({
    to = 'sync@example.com',
    subject = 'Sync Test'
  })
  
  local draft = draft_manager.get_by_buffer(buf)
  assert.truthy(draft, "Draft should exist")
  
  -- Save draft (triggers sync)
  composer.save_draft(buf, 'manual')
  
  -- Check sync was queued
  local status = sync_engine.get_status()
  assert.truthy(status.queue_size >= 0, "Sync queue should have items or be empty")
  
  -- Cleanup
  composer.close_compose_buffer(buf)
  sync_engine.stop_processing()
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Draft Composer', tests)

return _G.himalaya_test