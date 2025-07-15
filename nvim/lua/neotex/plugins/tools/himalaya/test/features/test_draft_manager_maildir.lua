-- Test Draft Manager Maildir
-- Tests for the Maildir-based draft manager

local M = {}

-- Dependencies
local draft_manager = require('neotex.plugins.tools.himalaya.core.draft_manager_maildir')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Test state
M.test_dir = nil
M.test_results = {}
M.test_buffers = {}

-- Helper to create test directory
local function setup_test_env()
  M.test_dir = vim.fn.tempname() .. '_draft_test'
  
  -- Set up test config
  local config = require('neotex.plugins.tools.himalaya.core.config')
  config.config = {
    sync = {
      maildir_root = M.test_dir
    },
    accounts = {
      { name = 'TestAccount' }
    }
  }
  
  -- Create test maildir
  vim.fn.mkdir(M.test_dir .. '/TestAccount/.Drafts', 'p')
  
  -- Setup draft manager
  draft_manager.setup()
  
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
  
  -- Results are stored in M.test_results for structured reporting
end

-- Test 1: Create draft
function M.test_create_draft()
  local test_name = 'Create draft'
  
  local metadata = {
    from = 'test@example.com',
    to = 'recipient@example.com',
    subject = 'Test Draft',
    body = 'This is a test draft body.'
  }
  
  local buffer, err = draft_manager.create('TestAccount', metadata)
  
  if not buffer then
    report_test(test_name, false, err or 'Failed to create draft')
    return false
  end
  
  table.insert(M.test_buffers, buffer)
  
  -- Verify buffer was created
  if not vim.api.nvim_buf_is_valid(buffer) then
    report_test(test_name, false, 'Invalid buffer created')
    return false
  end
  
  -- Verify content
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  if content:match('From: test@example%.com') and
     content:match('Subject: Test Draft') and
     content:match('This is a test draft body') then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Draft content incorrect')
    return false
  end
end

-- Test 2: Save draft
function M.test_save_draft()
  local test_name = 'Save draft'
  
  -- Create a draft first
  local buffer = draft_manager.create('TestAccount', {
    subject = 'Save Test',
    body = 'Original body'
  })
  
  if not buffer then
    report_test(test_name, false, 'Failed to create draft for save test')
    return false
  end
  
  table.insert(M.test_buffers, buffer)
  
  -- Modify content
  vim.api.nvim_buf_set_lines(buffer, -1, -1, false, {'Modified body'})
  
  -- Save draft
  local ok, err = draft_manager.save(buffer)
  
  if not ok then
    report_test(test_name, false, err or 'Failed to save draft')
    return false
  end
  
  -- Verify file was moved to cur/
  local draft_info = draft_manager.get_by_buffer(buffer)
  if not draft_info then
    report_test(test_name, false, 'Failed to get draft info after save')
    return false
  end
  
  if draft_info.filepath:match('/cur/') then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Draft not moved to cur/ directory')
    return false
  end
end

-- Test 3: List drafts
function M.test_list_drafts()
  local test_name = 'List drafts'
  
  -- Clear existing drafts from previous tests
  local draft_dir = M.test_dir .. '/TestAccount/.Drafts'
  if vim.fn.isdirectory(draft_dir) == 1 then
    -- Remove all files in maildir subdirectories
    for _, subdir in ipairs({'new', 'cur', 'tmp'}) do
      local path = draft_dir .. '/' .. subdir
      if vim.fn.isdirectory(path) == 1 then
        local files = vim.fn.readdir(path)
        for _, file in ipairs(files) do
          vim.fn.delete(path .. '/' .. file)
        end
      end
    end
  end
  
  -- Create multiple drafts
  local draft_count = 3
  for i = 1, draft_count do
    local buf = draft_manager.create('TestAccount', {
      subject = 'Draft ' .. i,
      body = 'Body ' .. i
    })
    if buf then
      table.insert(M.test_buffers, buf)
      draft_manager.save(buf)
    end
  end
  
  -- List drafts
  local drafts = draft_manager.list('TestAccount')
  
  if #drafts == draft_count then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, string.format(
      'Expected %d drafts, found %d',
      draft_count,
      #drafts
    ))
    return false
  end
end

-- Test 4: Delete draft
function M.test_delete_draft()
  local test_name = 'Delete draft'
  
  -- Create a draft
  local buffer = draft_manager.create('TestAccount', {
    subject = 'Delete Test',
    body = 'To be deleted'
  })
  
  if not buffer then
    report_test(test_name, false, 'Failed to create draft for delete test')
    return false
  end
  
  draft_manager.save(buffer)
  
  -- Get filepath before deletion
  local draft_info = draft_manager.get_by_buffer(buffer)
  local filepath = draft_info and draft_info.filepath
  
  -- Delete draft
  local ok, err = draft_manager.delete(buffer)
  
  if not ok then
    report_test(test_name, false, err or 'Failed to delete draft')
    return false
  end
  
  -- Verify file is deleted
  if filepath and vim.fn.filereadable(filepath) == 0 then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Draft file still exists after deletion')
    return false
  end
end

-- Test 5: Get draft by buffer
function M.test_get_by_buffer()
  local test_name = 'Get draft by buffer'
  
  local metadata = {
    from = 'sender@example.com',
    to = 'recipient@example.com',
    subject = 'Get By Buffer Test',
    cc = 'cc@example.com',
    bcc = 'bcc@example.com'
  }
  
  local buffer = draft_manager.create('TestAccount', metadata)
  
  if not buffer then
    report_test(test_name, false, 'Failed to create draft')
    return false
  end
  
  table.insert(M.test_buffers, buffer)
  
  -- Get draft info
  local draft = draft_manager.get_by_buffer(buffer)
  
  if not draft then
    report_test(test_name, false, 'Failed to get draft by buffer')
    return false
  end
  
  -- Verify fields
  local valid = draft.buffer == buffer and
                draft.account == 'TestAccount' and
                draft.subject == 'Get By Buffer Test' and
                draft.from == 'sender@example.com' and
                draft.to == 'recipient@example.com' and
                draft.cc == 'cc@example.com' and
                draft.bcc == 'bcc@example.com'
  
  if valid then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Draft info incorrect: ' .. vim.inspect(draft))
    return false
  end
end

-- Test 6: Open existing draft
function M.test_open_draft()
  local test_name = 'Open existing draft'
  
  -- Create and save a draft
  local buffer1 = draft_manager.create('TestAccount', {
    subject = 'Open Test',
    body = 'Test opening'
  })
  
  if not buffer1 then
    report_test(test_name, false, 'Failed to create draft')
    return false
  end
  
  table.insert(M.test_buffers, buffer1)
  draft_manager.save(buffer1)
  
  -- Get filepath
  local draft_info = draft_manager.get_by_buffer(buffer1)
  if not draft_info then
    report_test(test_name, false, 'Failed to get draft info')
    return false
  end
  
  local filepath = draft_info.filepath
  
  -- Close buffer
  vim.api.nvim_buf_delete(buffer1, { force = true })
  
  -- Open draft again
  local buffer2, err = draft_manager.open(filepath)
  
  if not buffer2 then
    report_test(test_name, false, err or 'Failed to open draft')
    return false
  end
  
  table.insert(M.test_buffers, buffer2)
  
  -- Verify content
  local lines = vim.api.nvim_buf_get_lines(buffer2, 0, -1, false)
  local content = table.concat(lines, '\n')
  
  if content:match('Subject: Open Test') and content:match('Test opening') then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Opened draft has incorrect content')
    return false
  end
end

-- Run all tests
function M.run()
  M.test_results = {}
  
  notify.himalaya('Running Draft Manager Maildir tests...', notify.categories.STATUS)
  
  -- Setup test environment
  setup_test_env()
  
  -- Run each test
  M.test_create_draft()
  M.test_save_draft()
  M.test_list_drafts()
  M.test_delete_draft()
  M.test_get_by_buffer()
  M.test_open_draft()
  
  -- Cleanup
  cleanup_test_env()
  
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
  
  -- Display summary notification
  local msg = string.format(
    'Draft Manager tests complete: %d/%d passed',
    passed,
    passed + failed
  )
  
  if failed > 0 then
    notify.himalaya(msg, notify.categories.ERROR)
  else
    notify.himalaya(msg, notify.categories.USER_ACTION)
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