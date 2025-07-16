-- Test Maildir Integration
-- Comprehensive tests for the complete Maildir draft system

local M = {}

-- Dependencies
local maildir = require('neotex.plugins.tools.himalaya.core.maildir')
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
local composer = require('neotex.plugins.tools.himalaya.ui.email_composer')
local notify = require('neotex.util.notifications')
local logger = require('neotex.plugins.tools.himalaya.core.logger')

-- Test results
M.test_results = {
  foundation = {},
  draft_manager = {},
  composer = {},
  integration = {}
}

-- Run foundation tests
function M.test_foundation()
  notify.himalaya('Testing Maildir foundation...', notify.categories.STATUS)
  
  local test = require('neotex.plugins.tools.himalaya.test.features.test_maildir_foundation')
  local result = test.run()
  
  M.test_results.foundation = {
    success = result.success,
    tests = test.test_results
  }
  
  return result.success
end

-- Run draft manager tests
function M.test_draft_manager()
  notify.himalaya('Testing Draft Manager...', notify.categories.STATUS)
  
  local test = require('neotex.plugins.tools.himalaya.test.features.test_draft_manager_maildir')
  local result = test.run()
  
  M.test_results.draft_manager = {
    success = result.success,
    tests = test.test_results
  }
  
  return result.success
end

-- Run composer tests
function M.test_composer()
  notify.himalaya('Testing Email Composer...', notify.categories.STATUS)
  
  local test = require('neotex.plugins.tools.himalaya.test.features.test_email_composer')
  local result = test.run()
  
  M.test_results.composer = {
    success = result.success,
    tests = test.test_results
  }
  
  return result.success
end

-- Integration test: Full workflow
function M.test_integration()
  notify.himalaya('Testing full integration...', notify.categories.STATUS)
  
  local test_dir = vim.fn.tempname() .. '_integration_test'
  local results = {}
  local all_passed = true
  
  -- Setup test environment
  local config = require('neotex.plugins.tools.himalaya.core.config')
  config.config = {
    sync = {
      maildir_root = test_dir
    },
    accounts = {
      { name = 'TestAccount', email = 'test@example.com' }
    }
  }
  
  config.get_formatted_from = function(account)
    return 'Test User <test@example.com>'
  end
  
  -- Create test maildir
  vim.fn.mkdir(test_dir .. '/TestAccount/.Drafts', 'p')
  
  -- Test 1: Create draft through UI
  local function test_ui_create()
    -- Clear directory before test to ensure clean state
    local draft_dir = test_dir .. '/TestAccount/.Drafts'
    if vim.fn.isdirectory(draft_dir .. '/cur') == 1 then
      vim.fn.delete(draft_dir .. '/cur', 'rf')
      vim.fn.mkdir(draft_dir .. '/cur', 'p')
    end
    
    local buf = composer.create_compose_buffer({
      account = 'TestAccount',
      to = 'recipient@example.com',
      subject = 'Integration Test'
    })
    
    if not buf then
      return false, 'Failed to create compose buffer'
    end
    
    -- Add body content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    table.insert(lines, 'Test body content for integration test.')
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Save draft
    local ok = composer.save_draft(buf)
    if not ok then
      return false, 'Failed to save draft'
    end
    
    -- Verify draft exists in Maildir
    local drafts = maildir.list_messages(test_dir .. '/TestAccount/.Drafts', {D = true})
    if #drafts ~= 1 then
      return false, 'Draft not found in Maildir'
    end
    
    -- Cleanup
    vim.api.nvim_buf_delete(buf, { force = true })
    
    return true
  end
  
  -- Test 2: List drafts
  local function test_list_drafts()
    local drafts = draft_manager.list('TestAccount')
    
    if #drafts ~= 1 then
      return false, string.format('Expected 1 draft, found %d', #drafts)
    end
    
    local draft = drafts[1]
    if draft.subject ~= 'Integration Test' then
      return false, 'Draft subject mismatch'
    end
    
    return true
  end
  
  -- Test 3: Open and edit draft
  local function test_edit_draft()
    local drafts = draft_manager.list('TestAccount')
    if #drafts == 0 then
      return false, 'No drafts to edit'
    end
    
    local filepath = drafts[1].filepath
    local buf = composer.open_draft(filepath)
    
    if not buf then
      return false, 'Failed to open draft'
    end
    
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
    if headers.subject ~= 'Integration Test - Modified' then
      return false, 'Subject not updated'
    end
    
    -- Cleanup
    vim.api.nvim_buf_delete(buf, { force = true })
    
    return true
  end
  
  -- Test 4: Migration compatibility
  local function test_migration()
    -- Ensure config is set up with maildir_root for migration
    local config = require('neotex.plugins.tools.himalaya.core.config')
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
    
    if not result or result.migrated ~= 1 then
      local err_msg = string.format(
        'Migration failed: expected 1 migrated, got %s (total: %s, failed: %s)',
        result and result.migrated or 'nil',
        result and result.total or 'nil',
        result and result.failed or 'nil'
      )
      return false, err_msg
    end
    
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
    
    if not found then
      return false, 'Migrated draft not found'
    end
    
    -- Cleanup
    vim.fn.delete(legacy_dir, 'rf')
    
    -- Restore original config
    config.config = original_config
    
    return true
  end
  
  -- Run tests
  local tests = {
    { name = 'Create draft through UI', fn = test_ui_create },
    { name = 'List drafts', fn = test_list_drafts },
    { name = 'Open and edit draft', fn = test_edit_draft },
    { name = 'Migration compatibility', fn = test_migration }
  }
  
  for _, test in ipairs(tests) do
    local ok, err = test.fn()
    table.insert(results, {
      name = test.name,
      success = ok,
      error = err
    })
    
    if not ok then
      all_passed = false
    end
    -- Results are stored in results table for structured reporting
  end
  
  -- Cleanup
  vim.fn.delete(test_dir, 'rf')
  
  M.test_results.integration = {
    success = all_passed,
    tests = results
  }
  
  return all_passed
end

-- Run all tests
function M.run()
  notify.himalaya('Running comprehensive Maildir integration tests...', notify.categories.STATUS)
  
  local start_time = vim.loop.hrtime()
  
  -- Run test suites
  local foundation_ok = M.test_foundation()
  local manager_ok = M.test_draft_manager()
  local composer_ok = M.test_composer()
  local integration_ok = M.test_integration()
  
  local elapsed = (vim.loop.hrtime() - start_time) / 1e9
  
  -- Summary
  local total_tests = 0
  local passed_tests = 0
  
  for _, suite in pairs(M.test_results) do
    if suite.tests then
      for _, test in ipairs(suite.tests) do
        total_tests = total_tests + 1
        if test.success then
          passed_tests = passed_tests + 1
        end
      end
    end
  end
  
  -- Build detailed error list
  local error_list = {}
  
  if passed_tests < total_tests then
    for suite_name, suite in pairs(M.test_results) do
      if suite.tests then
        for _, test in ipairs(suite.tests) do
          if not test.success then
            table.insert(error_list, {
              test = string.format('[%s] %s', suite_name, test.name),
              error = test.error or 'Unknown error'
            })
          end
        end
      end
    end
  end
  
  local all_passed = foundation_ok and manager_ok and composer_ok and integration_ok
  
  -- Notification
  if all_passed then
    notify.himalaya(
      string.format('All tests passed! (%d/%d)', passed_tests, total_tests),
      notify.categories.USER_ACTION
    )
  else
    notify.himalaya(
      string.format('Some tests failed: %d/%d passed', passed_tests, total_tests),
      notify.categories.ERROR
    )
  end
  
  -- Return structured results for test runner
  return {
    total = total_tests,
    passed = passed_tests,
    failed = total_tests - passed_tests,
    errors = error_list,
    success = all_passed,
    details = {
      foundation = foundation_ok,
      draft_manager = manager_ok,
      composer = composer_ok,
      integration = integration_ok,
      duration_seconds = elapsed
    }
  }
end

-- Generate test report
function M.report()
  local report = {
    '# Maildir Integration Test Report',
    '',
    '## Summary',
    ''
  }
  
  for suite_name, suite in pairs(M.test_results) do
    local passed = 0
    local total = 0
    
    if suite.tests then
      for _, test in ipairs(suite.tests) do
        total = total + 1
        if test.success then passed = passed + 1 end
      end
    end
    
    table.insert(report, string.format('- **%s**: %d/%d passed',
      suite_name, passed, total))
  end
  
  table.insert(report, '')
  table.insert(report, '## Detailed Results')
  
  for suite_name, suite in pairs(M.test_results) do
    table.insert(report, '')
    table.insert(report, '### ' .. suite_name)
    
    if suite.tests then
      for _, test in ipairs(suite.tests) do
        local status = test.success and '✓' or '✗'
        local line = string.format('- [%s] %s', status, test.name)
        if not test.success and test.error then
          line = line .. ': ' .. test.error
        end
        table.insert(report, line)
      end
    end
  end
  
  return table.concat(report, '\n')
end

return M