-- Test Email Composer Maildir
-- Tests for the Maildir-based email composer

local M = {}

-- Dependencies
local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')
local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')

-- Test state
M.test_results = {}
M.test_env = nil

-- Helper to report test result with enhanced context
local function report_test(name, success, error_info, context)
  local result = framework.create_test_result(name, success, error_info, context)
  table.insert(M.test_results, result)
  return result
end

-- Test 1: Create compose buffer
function M.test_create_compose_buffer()
  local test_name = 'Create compose buffer'
  
  -- Use managed test environment
  local env = framework.helpers.create_test_env()
  
  local success, result = pcall(function()
    -- Set up test environment
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    -- Validate config setup
    local config = require('neotex.plugins.tools.himalaya.core.config')
    local from_test = config.get_formatted_from('TestAccount')
    framework.assert.truthy(from_test, 'config.get_formatted_from should return valid value')
    
    -- Create compose buffer
    local buf = composer.create_compose_buffer({
      account = 'TestAccount',
      to = 'recipient@example.com',
      subject = 'Test Subject'
    })
    
    framework.assert.buffer_valid(buf, 'create_compose_buffer should return valid buffer')
    framework.helpers.register_buffer(env, buf)
    
    -- Verify buffer content with enhanced assertions
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    framework.assert.email_headers(content, {
      from = 'Test User <test@example.com>',
      to = 'recipient@example.com',
      subject = 'Test Subject'
    }, 'Email headers should match expected values')
    
    return {
      buffer_id = buf,
      content_length = #content,
      account = 'TestAccount'
    }
  end)
  
  -- Always cleanup
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 2: Save draft
function M.test_save_draft()
  local test_name = 'Save draft from composer'
  
  local env = framework.helpers.create_test_env()
  
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    local buf = composer.create_compose_buffer({
      account = 'TestAccount',
      subject = 'Save Test'
    })
    
    framework.assert.buffer_valid(buf, 'Should create compose buffer')
    framework.helpers.register_buffer(env, buf)
    
    -- Modify content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(lines, 'Test body content')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Save draft
    local ok = composer.save_draft(buf)
    framework.assert.truthy(ok, 'Should save draft successfully')
    
    -- Verify buffer is marked as unmodified
    local modified = vim.api.nvim_buf_get_option(buf, 'modified')
    framework.assert.falsy(modified, 'Buffer should not be modified after save')
    
    return { buffer_id = buf, content_added = true }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 3: Reply to email
function M.test_reply_to_email()
  local test_name = 'Reply to email'
  
  local env = framework.helpers.create_test_env()
  
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    local original = {
      from = 'sender@example.com',
      to = 'recipient@example.com',
      cc = 'cc@example.com',
      subject = 'Original Subject',
      message_id = '<original@example.com>',
      body = 'Original message body'
    }
    
    local buf = composer.reply_to_email(original, false)
    framework.assert.buffer_valid(buf, 'Should create reply buffer')
    framework.helpers.register_buffer(env, buf)
    
    -- Verify reply content with enhanced assertions
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    framework.assert.matches(content, 'To: sender@example%.com', 'Should reply to sender')
    framework.assert.matches(content, 'Subject: Re: Original Subject', 'Should add Re: prefix')
    framework.assert.matches(content, '> Original message body', 'Should quote original message')
    
    return { buffer_id = buf, reply_type = 'simple' }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 4: Reply all
function M.test_reply_all()
  local test_name = 'Reply all to email'
  
  local env = framework.helpers.create_test_env()
  
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    local original = {
      from = 'sender@example.com',
      to = 'recipient@example.com, other@example.com',
      cc = 'cc@example.com',
      subject = 'Original Subject',
      message_id = '<original@example.com>',
      body = 'Original message'
    }
    
    local buf = composer.reply_to_email(original, true)
    framework.assert.buffer_valid(buf, 'Should create reply all buffer')
    framework.helpers.register_buffer(env, buf)
    
    -- Verify reply all content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    framework.assert.matches(content, 'To: sender@example%.com', 'Should reply to sender')
    framework.assert.matches(content, 'Cc:.*recipient@example%.com', 'Should CC original recipients')
    
    return { buffer_id = buf, reply_type = 'all' }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 5: Forward email
function M.test_forward_email()
  local test_name = 'Forward email'
  
  local env = framework.helpers.create_test_env()
  
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    local original = {
      from = 'sender@example.com',
      to = 'recipient@example.com',
      subject = 'Original Subject',
      date = 'Mon, 13 Jan 2025 10:00:00 +0000',
      body = 'Original message to forward'
    }
    
    local buf = composer.forward_email(original)
    framework.assert.buffer_valid(buf, 'Should create forward buffer')
    framework.helpers.register_buffer(env, buf)
    
    -- Verify forward content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    framework.assert.matches(content, 'Subject: Fwd: Original Subject', 'Should add Fwd: prefix')
    framework.assert.matches(content, '---------- Forwarded message', 'Should have forward separator')
    framework.assert.matches(content, 'Original message to forward', 'Should include original message')
    
    return { buffer_id = buf, forward_type = 'standard' }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 6: Open existing draft
function M.test_open_existing_draft()
  local test_name = 'Open existing draft'
  
  local env = framework.helpers.create_test_env()
  
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    -- Create and save a draft first
    local buf1 = composer.create_compose_buffer({
      account = 'TestAccount',
      subject = 'Existing Draft',
      body = 'Draft to reopen'
    })
    
    framework.assert.buffer_valid(buf1, 'Should create initial draft')
    framework.helpers.register_buffer(env, buf1)
    composer.save_draft(buf1)
    
    -- Get draft filepath
    local draft_info = draft_manager.get_by_buffer(buf1)
    framework.assert.truthy(draft_info, 'Should get draft info')
    
    local filepath = draft_info.filepath
    
    -- Close buffer
    vim.api.nvim_buf_delete(buf1, { force = true })
    
    -- Open draft again
    local buf2 = composer.open_draft(filepath)
    framework.assert.buffer_valid(buf2, 'Should open existing draft')
    framework.helpers.register_buffer(env, buf2)
    
    -- Verify content
    local lines = vim.api.nvim_buf_get_lines(buf2, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    framework.assert.matches(content, 'Subject: Existing Draft', 'Should have correct subject')
    framework.assert.matches(content, 'Draft to reopen', 'Should have correct body')
    
    return { buffer_id = buf2, filepath = filepath }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 7: Edge case - Empty email headers
function M.test_edge_case_empty_headers()
  local test_name = 'Edge case: Empty email headers'
  
  local env = framework.helpers.create_test_env()
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    -- Test with empty/nil values
    local buf = composer.create_compose_buffer({
      account = 'TestAccount',
      to = '',
      subject = '',
      body = ''
    })
    
    framework.assert.buffer_valid(buf, 'Should create buffer even with empty headers')
    framework.helpers.register_buffer(env, buf)
    
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    -- Should still have From header (even if empty due to empty fields)
    framework.assert.matches(content, 'From:', 'Should always have From header field')
    
    return { buffer_id = buf, content_length = #content }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 8: Edge case - Invalid account
function M.test_edge_case_invalid_account()
  local test_name = 'Edge case: Invalid account'
  
  local env = framework.helpers.create_test_env()
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    -- Test with non-existent account
    local buf = composer.create_compose_buffer({
      account = 'NonExistentAccount',
      to = 'test@example.com',
      subject = 'Test'
    })
    
    -- The composer may create a buffer but with empty/default headers
    -- This is acceptable behavior - the test is to ensure it doesn't crash
    if buf then
      framework.helpers.register_buffer(env, buf)
      
      -- Check that the buffer content indicates the account issue
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local content = table.concat(lines, '\n')
      
      -- Should have empty or default From header since account doesn't exist
      framework.assert.matches(content, 'From:', 'Should have From header even for invalid account')
    end
    
    return { account_handled = true, buffer_created = buf ~= nil }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 9: Edge case - Malformed email addresses
function M.test_edge_case_malformed_email()
  local test_name = 'Edge case: Malformed email addresses'
  
  local env = framework.helpers.create_test_env()
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    -- Test with malformed email
    local buf = composer.create_compose_buffer({
      account = 'TestAccount',
      to = 'invalid-email-address',
      subject = 'Test Malformed'
    })
    
    framework.assert.buffer_valid(buf, 'Should create buffer with malformed email')
    framework.helpers.register_buffer(env, buf)
    
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    -- Should still contain the invalid email (validation happens later)
    framework.assert.matches(content, 'To: invalid%-email%-address', 'Should preserve original email format')
    
    return { buffer_id = buf, malformed_email = 'invalid-email-address' }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Test 10: Performance test - Create multiple buffers
function M.test_performance_multiple_buffers()
  local test_name = 'Performance: Create multiple buffers'
  
  local env = framework.helpers.create_test_env()
  local success, result = pcall(function()
    framework.helpers.create_maildir(env.temp_dir, 'TestAccount')
    
    local state = require('neotex.plugins.tools.himalaya.core.state')
    state.set_current_account('TestAccount')
    
    -- Performance test: create 10 buffers quickly
    local start_time = vim.loop.hrtime()
    local buffers = {}
    
    for i = 1, 10 do
      local buf = composer.create_compose_buffer({
        account = 'TestAccount',
        to = 'test' .. i .. '@example.com',
        subject = 'Performance Test ' .. i
      })
      
      framework.assert.buffer_valid(buf, 'Buffer ' .. i .. ' should be valid')
      table.insert(buffers, buf)
      framework.helpers.register_buffer(env, buf)
    end
    
    local duration = (vim.loop.hrtime() - start_time) / 1e6
    
    -- Should complete within reasonable time (500ms for 10 buffers)
    if duration > 500 then
      error(string.format('Performance test failed: %.2fms (expected < 500ms)', duration))
    end
    
    return { 
      buffer_count = #buffers,
      duration_ms = duration,
      avg_per_buffer = duration / #buffers
    }
  end)
  
  framework.helpers.cleanup_test_env(env)
  
  if success then
    report_test(test_name, true, nil, result)
    return true
  else
    report_test(test_name, false, result)
    return false
  end
end

-- Run all tests
function M.run()
  M.test_results = {}
  
  -- Create captured notifications to avoid console spam
  local captured_notifications = framework.helpers.capture_notifications(function()
    notify.himalaya('Running Email Composer Maildir tests...', notify.categories.STATUS)
  end)
  
  -- Setup modules (no environment setup needed - each test manages its own)
  draft_manager.setup()
  composer.setup({
    compose = {
      auto_save_interval = 0  -- Disable autosave for tests
    }
  })
  
  -- Run each test (core functionality)
  M.test_create_compose_buffer()
  M.test_save_draft()
  M.test_reply_to_email()
  M.test_reply_all()
  M.test_forward_email()
  M.test_open_existing_draft()
  
  -- Run edge case tests
  M.test_edge_case_empty_headers()
  M.test_edge_case_invalid_account()
  M.test_edge_case_malformed_email()
  M.test_performance_multiple_buffers()
  
  -- Calculate results
  local passed = 0
  local failed = 0
  local errors = {}
  
  for _, result in ipairs(M.test_results) do
    if result.success then
      passed = passed + 1
    else
      failed = failed + 1
      table.insert(errors, {
        test = result.name,
        error = result.error or 'Unknown error'
      })
    end
  end
  
  -- Display summary notification (suppress in test mode)
  if not _G.HIMALAYA_TEST_MODE then
    local msg = string.format(
      'Email Composer tests complete: %d/%d passed',
      passed,
      passed + failed
    )
    
    if failed > 0 then
      notify.himalaya(msg, notify.categories.ERROR)
    else
      notify.himalaya(msg, notify.categories.USER_ACTION)
    end
  end
  
  -- Return structured results for test runner
  return {
    total = passed + failed,
    passed = passed,
    failed = failed,
    errors = errors,
    success = failed == 0
  }
end

return M