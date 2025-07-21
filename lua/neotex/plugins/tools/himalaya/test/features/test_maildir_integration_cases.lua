-- Test Maildir Integration Cases
-- Actual integration test cases extracted from test_maildir_integration.lua

local M = {}

local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers

-- Test metadata
M.test_metadata = {
  name = "Maildir Integration Cases",
  description = "Actual integration test cases for maildir functionality",
  count = 4,
  category = "features",
  tags = {"maildir", "integration", "cases"}
}

-- Dependencies
local maildir = require("neotex.plugins.tools.himalaya.data.maildir")
local draft_manager = require("neotex.plugins.tools.himalaya.data.drafts")
local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local config = require('neotex.plugins.tools.himalaya.core.config')
local notify = require('neotex.util.notifications')

-- Test directory (will be set in setup for each test run)
local test_dir = nil

-- Setup function
function M.setup()
  -- Create unique test directory for this test run
  test_dir = '/tmp/himalaya_test_maildir_integration_' .. vim.loop.hrtime()
  
  -- Create test configuration
  config.config.accounts = {
    {
      name = 'TestAccount',
      default = true,
      from = 'test@example.com'
    }
  }
  
  -- Set the maildir root in sync config (where draft_manager looks for it)
  config.config.sync = {
    maildir_root = test_dir
  }
  
  config.get_formatted_from = function(account)
    return 'Test User <test@example.com>'
  end
  
  -- Create test maildir with proper structure
  local drafts_dir = test_dir .. '/TestAccount/.Drafts'
  vim.fn.mkdir(drafts_dir .. '/new', 'p')
  vim.fn.mkdir(drafts_dir .. '/cur', 'p')
  vim.fn.mkdir(drafts_dir .. '/tmp', 'p')
end

-- Teardown function
function M.teardown()
  -- Cleanup
  if test_dir and vim.fn.isdirectory(test_dir) == 1 then
    vim.fn.delete(test_dir, 'rf')
  end
  test_dir = nil
end

-- Test 1: Create draft through UI
function M.test_ui_create()
  local buf = composer.create_compose_buffer({
    account = 'TestAccount',
    to = 'recipient@example.com',
    subject = 'Integration Test'
  })
  
  assert.truthy(buf, 'Failed to create compose buffer')
  
  -- Add body content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, 'Test body content for integration test.')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save draft
  local ok = composer.save_draft(buf)
  assert.truthy(ok, 'Failed to save draft')
  
  -- Verify draft exists in Maildir
  local drafts = maildir.list_messages(test_dir .. '/TestAccount/.Drafts', {D = true})
  assert.equals(#drafts, 1, 'Draft not found in Maildir')
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end

-- Test 2: List drafts
function M.test_list_drafts()
  -- This test depends on test_ui_create, so we need to create the draft first
  -- Create a draft to ensure we have exactly one
  local buf = composer.create_compose_buffer({
    account = 'TestAccount',
    to = 'recipient@example.com',
    subject = 'Integration Test'
  })
  
  assert.truthy(buf, 'Failed to create compose buffer')
  
  -- Add body content
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, 'Test body content for integration test.')
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  
  -- Save draft
  local ok = composer.save_draft(buf)
  assert.truthy(ok, 'Failed to save draft')
  
  -- Cleanup buffer
  vim.api.nvim_buf_delete(buf, { force = true })
  
  -- Now list drafts
  local drafts = draft_manager.list('TestAccount')
  
  assert.equals(#drafts, 1, string.format('Expected 1 draft, found %d', #drafts))
  
  local draft = drafts[1]
  assert.equals(draft.subject, 'Integration Test', 'Draft subject mismatch')
end

-- Test 3: Open and edit draft
function M.test_edit_draft()
  -- First create a draft to edit
  local create_buf = composer.create_compose_buffer({
    account = 'TestAccount',
    to = 'recipient@example.com',
    subject = 'Integration Test'
  })
  
  assert.truthy(create_buf, 'Failed to create compose buffer')
  
  -- Add body content
  local lines = vim.api.nvim_buf_get_lines(create_buf, 0, -1, false)
  table.insert(lines, 'Test body content for integration test.')
  vim.api.nvim_buf_set_lines(create_buf, 0, -1, false, lines)
  
  -- Save draft
  local ok = composer.save_draft(create_buf)
  assert.truthy(ok, 'Failed to save draft')
  
  -- Cleanup buffer
  vim.api.nvim_buf_delete(create_buf, { force = true })
  
  -- Now get the draft we just created
  local drafts = draft_manager.list('TestAccount')
  assert.truthy(#drafts > 0, 'No drafts to edit')
  
  local filepath = drafts[1].filepath
  local buf = composer.open_draft(filepath)
  
  assert.truthy(buf, 'Failed to open draft')
  
  -- Modify subject
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 10, false)
  for i, line in ipairs(lines) do
    if line:match('^Subject:') then
      lines[i] = 'Subject: Integration Test - Modified'
      break
    end
  end
  vim.api.nvim_buf_set_lines(buf, 0, 10, false, lines)
  
  -- Save changes
  composer.save_draft(buf)
  
  -- Verify changes
  local headers = maildir.read_headers(filepath)
  assert.equals(headers.subject, 'Integration Test - Modified', 'Subject not updated')
  
  -- Cleanup
  vim.api.nvim_buf_delete(buf, { force = true })
end

-- Test 4: Migration compatibility
function M.test_migration()
  -- Ensure config is set up with maildir_root for migration
  local original_config = vim.deepcopy(config.config)
  config.config.sync.maildir_root = test_dir
  
  -- Create legacy draft structure
  local legacy_dir = vim.fn.stdpath('data') .. '/himalaya/drafts'
  vim.fn.mkdir(legacy_dir, 'p')
  
  -- Create test EML file
  local eml_content = [[From: legacy@example.com
To: recipient@example.com
Subject: Legacy Draft

This is a legacy draft for migration testing.]]
  
  local draft_id = 'test_legacy_' .. os.time()
  vim.fn.writefile(vim.split(eml_content, '\n'), legacy_dir .. '/' .. draft_id .. '.eml')
  
  -- Create index
  local index = {
    {
      local_id = draft_id,
      account = 'TestAccount',
      metadata = { subject = 'Legacy Draft' }
    }
  }
  vim.fn.writefile({vim.json.encode(index)}, legacy_dir .. '/.index.json')
  
  -- Run migration
  local migration = require('neotex.plugins.tools.himalaya.migrations.draft_to_maildir')
  local result = migration.migrate({ dry_run = false })
  
  assert.truthy(result, 'Migration returned nil')
  assert.equals(result.migrated, 1, string.format(
    'Migration failed: expected 1 migrated, got %s (total: %s, failed: %s)',
    result.migrated or 'nil',
    result.total or 'nil',
    result.failed or 'nil'
  ))
  
  -- Verify migrated draft
  local drafts = maildir.list_messages(test_dir .. '/TestAccount/.Drafts', {D = true})
  local found = false
  for _, draft in ipairs(drafts) do
    local headers = maildir.read_headers(draft.path)
    if headers and headers.subject == 'Legacy Draft' then
      found = true
      break
    end
  end
  
  assert.truthy(found, 'Migrated draft not found')
  
  -- Cleanup
  vim.fn.delete(legacy_dir, 'rf')
  
  -- Restore original config
  config.config = original_config
end

-- Create test suite with proper setup/teardown
local tests = {}
table.insert(tests, framework.create_test('ui_create', function()
  M.setup()
  local success, err = pcall(M.test_ui_create)
  M.teardown()
  if not success then error(err) end
end))

table.insert(tests, framework.create_test('list_drafts', function()
  M.setup()
  local success, err = pcall(M.test_list_drafts)
  M.teardown()
  if not success then error(err) end
end))

table.insert(tests, framework.create_test('edit_draft', function()
  M.setup()
  local success, err = pcall(M.test_edit_draft)
  M.teardown()
  if not success then error(err) end
end))

table.insert(tests, framework.create_test('migration', function()
  M.setup()
  local success, err = pcall(M.test_migration)
  M.teardown()
  if not success then error(err) end
end))

-- Create and assign run function
local suite = framework.create_suite('Maildir Integration Cases', tests)
M.run = suite.run

-- Export
return M