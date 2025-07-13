-- Test Email Composer Maildir
-- Tests for the Maildir-based email composer

local M = {}

-- Dependencies
local composer = require('neotex.plugins.tools.himalaya.ui.email_composer_maildir')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Test state
M.test_dir = nil
M.test_results = {}
M.test_buffers = {}

-- Helper to create test environment
local function setup_test_env()
  M.test_dir = vim.fn.tempname() .. '_composer_test'
  
  -- Set up test config
  local config = require('neotex.plugins.tools.himalaya.core.config')
  config.config = {
    sync = {
      maildir_root = M.test_dir
    },
    accounts = {
      { name = 'TestAccount', email = 'test@example.com' }
    }
  }
  
  -- Mock get_formatted_from
  config.get_formatted_from = function(account)
    return 'Test User <test@example.com>'
  end
  
  -- Create test maildir
  vim.fn.mkdir(M.test_dir .. '/TestAccount/.Drafts', 'p')
  
  -- Setup modules
  draft_manager.setup()
  composer.setup({
    compose = {
      auto_save_interval = 0  -- Disable autosave for tests
    }
  })
  
  return M.test_dir
end

-- Helper to cleanup test environment
local function cleanup_test_env()
  -- Delete test buffers
  for _, buf in ipairs(M.test_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  M.test_buffers = {}
  
  -- Delete test directory
  if M.test_dir and vim.fn.isdirectory(M.test_dir) == 1 then
    vim.fn.delete(M.test_dir, 'rf')
  end
  M.test_dir = nil
end

-- Helper to report test result
local function report_test(name, success, error_msg)
  table.insert(M.test_results, {
    name = name,
    success = success,
    error = error_msg
  })
  
  if success then
    logger.info('Test passed: ' .. name)
  else
    logger.error('Test failed: ' .. name, { error = error_msg })
  end
end

-- Test 1: Create compose buffer
function M.test_create_compose_buffer()
  local test_name = 'Create compose buffer'
  
  local buf = composer.create_compose_buffer({
    account = 'TestAccount',
    to = 'recipient@example.com',
    subject = 'Test Subject'
  })
  
  if not buf then
    report_test(test_name, false, 'Failed to create compose buffer')
    return false
  end
  
  table.insert(M.test_buffers, buf)
  
  -- Verify buffer content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  local has_from = content:match('From: Test User <test@example%.com>')
  local has_to = content:match('To: recipient@example%.com')
  local has_subject = content:match('Subject: Test Subject')
  
  if has_from and has_to and has_subject then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Buffer content incorrect')
    return false
  end
end

-- Test 2: Save draft
function M.test_save_draft()
  local test_name = 'Save draft from composer'
  
  local buf = composer.create_compose_buffer({
    account = 'TestAccount',
    subject = 'Save Test'
  })
  
  if not buf then
    report_test(test_name, false, 'Failed to create buffer')
    return false
  end
  
  table.insert(M.test_buffers, buf)
  
  -- Modify content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, 'Test body content')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save draft
  local ok = composer.save_draft(buf)
  
  if not ok then
    report_test(test_name, false, 'Failed to save draft')
    return false
  end
  
  -- Verify buffer is marked as unmodified
  local modified = vim.api.nvim_buf_get_option(buf, 'modified')
  
  if not modified then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Buffer still marked as modified after save')
    return false
  end
end

-- Test 3: Reply to email
function M.test_reply_to_email()
  local test_name = 'Reply to email'
  
  local original = {
    from = 'sender@example.com',
    to = 'recipient@example.com',
    cc = 'cc@example.com',
    subject = 'Original Subject',
    message_id = '<original@example.com>',
    body = 'Original message body'
  }
  
  local buf = composer.reply_to_email(original, false)
  
  if not buf then
    report_test(test_name, false, 'Failed to create reply buffer')
    return false
  end
  
  table.insert(M.test_buffers, buf)
  
  -- Verify reply content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  local has_to = content:match('To: sender@example%.com')
  local has_subject = content:match('Subject: Re: Original Subject')
  local has_quote = content:match('> Original message body')
  
  if has_to and has_subject and has_quote then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Reply content incorrect')
    return false
  end
end

-- Test 4: Reply all
function M.test_reply_all()
  local test_name = 'Reply all to email'
  
  local original = {
    from = 'sender@example.com',
    to = 'recipient@example.com, other@example.com',
    cc = 'cc@example.com',
    subject = 'Original Subject',
    message_id = '<original@example.com>',
    body = 'Original message'
  }
  
  local buf = composer.reply_to_email(original, true)
  
  if not buf then
    report_test(test_name, false, 'Failed to create reply all buffer')
    return false
  end
  
  table.insert(M.test_buffers, buf)
  
  -- Verify reply all content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  local has_to = content:match('To: sender@example%.com')
  local has_cc = content:match('Cc:.*recipient@example%.com')
  
  if has_to and has_cc then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Reply all recipients incorrect')
    return false
  end
end

-- Test 5: Forward email
function M.test_forward_email()
  local test_name = 'Forward email'
  
  local original = {
    from = 'sender@example.com',
    to = 'recipient@example.com',
    subject = 'Original Subject',
    date = 'Mon, 13 Jan 2025 10:00:00 +0000',
    body = 'Original message to forward'
  }
  
  local buf = composer.forward_email(original)
  
  if not buf then
    report_test(test_name, false, 'Failed to create forward buffer')
    return false
  end
  
  table.insert(M.test_buffers, buf)
  
  -- Verify forward content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  local has_subject = content:match('Subject: Fwd: Original Subject')
  local has_separator = content:match('---------- Forwarded message')
  local has_original = content:match('Original message to forward')
  
  if has_subject and has_separator and has_original then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Forward content incorrect')
    return false
  end
end

-- Test 6: Open existing draft
function M.test_open_existing_draft()
  local test_name = 'Open existing draft'
  
  -- Create and save a draft first
  local buf1 = composer.create_compose_buffer({
    account = 'TestAccount',
    subject = 'Existing Draft',
    body = 'Draft to reopen'
  })
  
  if not buf1 then
    report_test(test_name, false, 'Failed to create initial draft')
    return false
  end
  
  table.insert(M.test_buffers, buf1)
  composer.save_draft(buf1)
  
  -- Get draft filepath
  local draft_info = draft_manager.get_by_buffer(buf1)
  if not draft_info then
    report_test(test_name, false, 'Failed to get draft info')
    return false
  end
  
  local filepath = draft_info.filepath
  
  -- Close buffer
  vim.api.nvim_buf_delete(buf1, { force = true })
  
  -- Open draft again
  local buf2 = composer.open_draft(filepath)
  
  if not buf2 then
    report_test(test_name, false, 'Failed to open existing draft')
    return false
  end
  
  table.insert(M.test_buffers, buf2)
  
  -- Verify content
  local lines = vim.api.nvim_buf_get_lines(buf2, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  if content:match('Subject: Existing Draft') and content:match('Draft to reopen') then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Reopened draft content incorrect')
    return false
  end
end

-- Run all tests
function M.run()
  M.test_results = {}
  
  notify.himalaya('Running Email Composer Maildir tests...', notify.categories.STATUS)
  
  -- Setup test environment
  setup_test_env()
  
  -- Run each test
  M.test_create_compose_buffer()
  M.test_save_draft()
  M.test_reply_to_email()
  M.test_reply_all()
  M.test_forward_email()
  M.test_open_existing_draft()
  
  -- Cleanup
  cleanup_test_env()
  
  -- Summary
  local passed = 0
  local failed = 0
  
  for _, result in ipairs(M.test_results) do
    if result.success then
      passed = passed + 1
    else
      failed = failed + 1
    end
  end
  
  -- Display results
  local msg = string.format(
    'Email Composer tests complete: %d/%d passed',
    passed,
    passed + failed
  )
  
  if failed > 0 then
    notify.himalaya(msg, notify.categories.ERROR)
    
    -- Show failures
    for _, result in ipairs(M.test_results) do
      if not result.success then
        print(string.format('FAILED: %s - %s', result.name, result.error or 'Unknown error'))
      end
    end
  else
    notify.himalaya(msg, notify.categories.USER_ACTION)
  end
  
  return failed == 0
end

return M