#!/usr/bin/env lua

-- Test script for draft field synchronization
-- Tests that all email fields are properly synced between buffer and remote

local test_framework = require('neotex.test.framework')
local test = test_framework.new('Draft Field Sync')

-- Test dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_v2')
local email_composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local utils = require('neotex.plugins.tools.himalaya.utils')
local state = require('neotex.plugins.tools.himalaya.core.state')

-- Test data
local test_account = 'test_account'
local test_email = {
  from = 'test@example.com',
  to = 'recipient@example.com',
  cc = 'cc@example.com',
  bcc = 'bcc@example.com',
  subject = 'Test Draft Field Sync',
  body = 'This is a test email body.\nWith multiple lines.'
}

-- Helper function to create a test draft
local function create_test_draft()
  -- Create compose buffer
  local buf = email_composer.create_compose_buffer({
    account = test_account,
    from = test_email.from,
    to = test_email.to,
    cc = test_email.cc,
    bcc = test_email.bcc,
    subject = test_email.subject,
    body = test_email.body
  })
  
  -- Wait for initial save
  vim.wait(200)
  
  return buf
end

-- Test 1: Initial draft creation captures all fields
test:test('Initial draft creation captures all fields', function()
  local buf = create_test_draft()
  
  -- Get draft from manager
  local draft = draft_manager.get_by_buffer(buf)
  test:assert_not_nil(draft, 'Draft should be created')
  
  -- Check all metadata fields
  test:assert_equals(draft.metadata.from, test_email.from, 'From field should match')
  test:assert_equals(draft.metadata.to, test_email.to, 'To field should match')
  test:assert_equals(draft.metadata.cc, test_email.cc, 'Cc field should match')
  test:assert_equals(draft.metadata.bcc, test_email.bcc, 'Bcc field should match')
  test:assert_equals(draft.metadata.subject, test_email.subject, 'Subject field should match')
  
  -- Check body content
  test:assert_not_nil(draft.content, 'Body content should be saved')
  test:assert_true(draft.content:find('test email body'), 'Body should contain test content')
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end)

-- Test 2: Field updates are synced
test:test('Field updates are synced on save', function()
  local buf = create_test_draft()
  
  -- Update fields in buffer
  local new_data = {
    to = 'new-recipient@example.com',
    subject = 'Updated Subject',
    cc = 'new-cc@example.com'
  }
  
  -- Get current lines and update
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match('^To:') then
      lines[i] = 'To: ' .. new_data.to
    elseif line:match('^Subject:') then
      lines[i] = 'Subject: ' .. new_data.subject
    elseif line:match('^Cc:') then
      lines[i] = 'Cc: ' .. new_data.cc
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save draft
  email_composer.save_draft(buf, 'test')
  vim.wait(100)
  
  -- Get updated draft
  local draft = draft_manager.get_by_buffer(buf)
  
  -- Check updated fields
  test:assert_equals(draft.metadata.to, new_data.to, 'To field should be updated')
  test:assert_equals(draft.metadata.subject, new_data.subject, 'Subject should be updated')
  test:assert_equals(draft.metadata.cc, new_data.cc, 'Cc field should be updated')
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end)

-- Test 3: Empty fields are handled correctly
test:test('Empty fields are handled correctly', function()
  -- Create draft with minimal fields
  local buf = email_composer.create_compose_buffer({
    account = test_account,
    from = test_email.from
  })
  
  vim.wait(200)
  
  local draft = draft_manager.get_by_buffer(buf)
  test:assert_not_nil(draft, 'Draft should be created')
  
  -- Check empty fields are stored as empty strings
  test:assert_equals(draft.metadata.to, '', 'Empty To field should be empty string')
  test:assert_equals(draft.metadata.cc, '', 'Empty Cc field should be empty string')
  test:assert_equals(draft.metadata.bcc, '', 'Empty Bcc field should be empty string')
  test:assert_equals(draft.metadata.subject, '', 'Empty Subject should be empty string')
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end)

-- Test 4: Multi-line headers are handled
test:test('Multi-line headers are handled correctly', function()
  local buf = create_test_draft()
  
  -- Add multi-line subject
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match('^Subject:') then
      lines[i] = 'Subject: This is a very long subject that'
      table.insert(lines, i + 1, '  continues on the next line')
      break
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save and check
  email_composer.save_draft(buf, 'test')
  vim.wait(100)
  
  local draft = draft_manager.get_by_buffer(buf)
  test:assert_true(
    draft.metadata.subject:find('continues on the next line'),
    'Multi-line subject should be concatenated'
  )
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end)

-- Test 5: Body content is separated from headers
test:test('Body content is separated from headers', function()
  local buf = create_test_draft()
  
  -- Add more body content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, 'Additional body line 1')
  table.insert(lines, 'Additional body line 2')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save
  email_composer.save_draft(buf, 'test')
  vim.wait(100)
  
  local draft = draft_manager.get_by_buffer(buf)
  
  -- Check body doesn't contain headers
  test:assert_false(
    draft.content:find('^From:'),
    'Body should not contain From header'
  )
  test:assert_false(
    draft.content:find('^Subject:'),
    'Body should not contain Subject header'
  )
  
  -- Check body contains added content
  test:assert_true(
    draft.content:find('Additional body line 1'),
    'Body should contain added lines'
  )
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end)

-- Run tests
test:run()

-- Print summary
print('\nDraft Field Sync Test Summary:')
print(string.format('  Total tests: %d', test.total))
print(string.format('  Passed: %d', test.passed))
print(string.format('  Failed: %d', test.failed))

-- Exit with appropriate code
os.exit(test.failed > 0 and 1 or 0)