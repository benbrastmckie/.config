-- Test Maildir Foundation
-- Tests for the core Maildir module functionality

local M = {}

-- Dependencies
local maildir = require('neotex.plugins.tools.himalaya.core.maildir')
local logger = require('neotex.plugins.tools.himalaya.core.logger')
local notify = require('neotex.util.notifications')

-- Test state
M.test_dir = nil
M.test_results = {}

-- Helper to create test directory
local function setup_test_dir()
  M.test_dir = vim.fn.tempname() .. '_maildir_test'
  vim.fn.mkdir(M.test_dir, 'p')
  return M.test_dir
end

-- Helper to cleanup test directory
local function cleanup_test_dir()
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

-- Test 1: Generate Maildir filename
function M.test_generate_filename()
  local test_name = 'Generate Maildir filename'
  
  -- Test with draft flag
  local filename = maildir.generate_filename({'D'})
  
  -- Validate format
  local pattern = "^%d+%.%d+_[^%.]+%.[^,]+,S=%d+:2,D$"
  if filename:match(pattern) then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Invalid filename format: ' .. filename)
    return false
  end
end

-- Test 2: Parse Maildir filename
function M.test_parse_filename()
  local test_name = 'Parse Maildir filename'
  
  -- Generate a filename first
  local filename = maildir.generate_filename({'D', 'F'})
  
  -- Parse it
  local metadata = maildir.parse_filename(filename)
  
  if not metadata then
    report_test(test_name, false, 'Failed to parse filename')
    return false
  end
  
  -- Validate parsed data
  local valid = metadata.timestamp and
                metadata.hrtime and
                metadata.unique and
                metadata.hostname and
                metadata.flags.D and
                metadata.flags.F
  
  if valid then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Incomplete metadata: ' .. vim.inspect(metadata))
    return false
  end
end

-- Test 3: Create Maildir structure
function M.test_create_maildir()
  local test_name = 'Create Maildir structure'
  
  local test_path = setup_test_dir() .. '/test_maildir'
  
  -- Create Maildir
  local ok, err = maildir.create_maildir(test_path)
  
  if not ok then
    report_test(test_name, false, err)
    cleanup_test_dir()
    return false
  end
  
  -- Verify structure
  local valid = maildir.is_maildir(test_path)
  
  cleanup_test_dir()
  
  if valid then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Invalid Maildir structure created')
    return false
  end
end

-- Test 4: Atomic write
function M.test_atomic_write()
  local test_name = 'Atomic write to Maildir'
  
  local test_path = setup_test_dir() .. '/test_maildir'
  maildir.create_maildir(test_path)
  
  -- Test content
  local content = [[From: test@example.com
To: recipient@example.com
Subject: Test Email
Date: Mon, 13 Jan 2025 10:00:00 +0000

This is a test email body.
]]
  
  -- Generate filename
  local filename = maildir.generate_filename({'D'})
  local target_path = test_path .. '/cur/' .. filename
  local tmp_path = test_path .. '/tmp'
  
  -- Perform atomic write
  local ok, err = maildir.atomic_write(tmp_path, target_path, content)
  
  if not ok then
    report_test(test_name, false, err)
    cleanup_test_dir()
    return false
  end
  
  -- Verify file exists and content matches
  if vim.fn.filereadable(target_path) == 1 then
    local lines = vim.fn.readfile(target_path)
    local read_content = table.concat(lines, '\n')
    -- Add final newline if original content ends with one
    if content:sub(-1) == '\n' and read_content:sub(-1) ~= '\n' then
      read_content = read_content .. '\n'
    end
    if read_content == content then
      report_test(test_name, true)
      cleanup_test_dir()
      return true
    else
      report_test(test_name, false, 'Content mismatch')
    end
  else
    report_test(test_name, false, 'File not created')
  end
  
  cleanup_test_dir()
  return false
end

-- Test 5: Read headers
function M.test_read_headers()
  local test_name = 'Read email headers'
  
  local test_path = setup_test_dir() .. '/test_maildir'
  maildir.create_maildir(test_path)
  
  -- Create test email
  local content = [[From: sender@example.com
To: recipient@example.com
Subject: Test Subject
Date: Mon, 13 Jan 2025 10:00:00 +0000
X-Custom-Header: Custom Value
Content-Type: text/plain; charset=utf-8

This is the body.
]]
  
  local filename = maildir.generate_filename({})
  local filepath = test_path .. '/cur/' .. filename
  maildir.atomic_write(test_path .. '/tmp', filepath, content)
  
  -- Read headers
  local headers = maildir.read_headers(filepath)
  
  cleanup_test_dir()
  
  if headers and 
     headers.from == 'sender@example.com' and
     headers.to == 'recipient@example.com' and
     headers.subject == 'Test Subject' and
     headers['x-custom-header'] == 'Custom Value' then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Headers not parsed correctly: ' .. vim.inspect(headers))
    return false
  end
end

-- Test 6: List messages with filter
function M.test_list_messages()
  local test_name = 'List messages with filter'
  
  local test_path = setup_test_dir() .. '/test_maildir'
  maildir.create_maildir(test_path)
  
  -- Create test emails
  local drafts = 0
  local regular = 0
  
  -- Ensure cur directory exists
  vim.fn.mkdir(test_path .. '/cur', 'p')
  
  local created = 0
  for i = 1, 5 do
    local content = string.format("Subject: Test %d\n\nBody %d", i, i)
    local flags = i <= 3 and {'D'} or {}
    if i <= 3 then drafts = drafts + 1 else regular = regular + 1 end
    
    -- Add a small delay to ensure unique filenames
    vim.wait(10)
    
    local filename = maildir.generate_filename(flags)
    local filepath = test_path .. '/cur/' .. filename
    local ok, err = maildir.atomic_write(test_path .. '/tmp', filepath, content)
    if ok then
      created = created + 1
    else
      report_test(test_name, false, 'Failed to create message ' .. i .. ': ' .. (err or 'unknown error'))
      cleanup_test_dir()
      return false
    end
  end
  
  -- Verify files were created
  local cur_files = vim.fn.readdir(test_path .. '/cur')
  if #cur_files ~= 5 then
    report_test(test_name, false, string.format(
      'Expected 5 files in cur/, found %d',
      #cur_files
    ))
    cleanup_test_dir()
    return false
  end
  
  -- List all messages
  local all_messages = maildir.list_messages(test_path)
  
  -- List only drafts
  local draft_messages = maildir.list_messages(test_path, {D = true})
  
  cleanup_test_dir()
  
  if #all_messages == 5 and #draft_messages == 3 then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, string.format(
      'Expected 5 total, 3 drafts. Got %d total, %d drafts',
      #all_messages, #draft_messages
    ))
    return false
  end
end

-- Test 7: Update size in filename
function M.test_update_size()
  local test_name = 'Update size in filename'
  
  local test_path = setup_test_dir() .. '/test_maildir'
  maildir.create_maildir(test_path)
  
  -- Create email with incorrect size
  local content = "Subject: Test\n\nThis is a test with some content to measure size."
  local filename = maildir.generate_filename({'D'})
  local filepath = test_path .. '/cur/' .. filename
  maildir.atomic_write(test_path .. '/tmp', filepath, content)
  
  -- Update size
  local size = maildir.update_size(filepath)
  
  -- Check if filename was updated
  local files = vim.fn.readdir(test_path .. '/cur')
  local updated = false
  
  for _, file in ipairs(files) do
    if file:match('S=' .. size) then
      updated = true
      break
    end
  end
  
  cleanup_test_dir()
  
  if updated and size == #content then
    report_test(test_name, true)
    return true
  else
    report_test(test_name, false, 'Size not updated correctly')
    return false
  end
end

-- Run all tests
function M.run()
  M.test_results = {}
  
  -- Run each test
  M.test_generate_filename()
  M.test_parse_filename()
  M.test_create_maildir()
  M.test_atomic_write()
  M.test_read_headers()
  M.test_list_messages()
  M.test_update_size()
  
  -- Return results for test runner to handle
  local passed = 0
  local failed = 0
  local details = {}
  
  for _, result in ipairs(M.test_results) do
    if result.success then
      passed = passed + 1
    else
      failed = failed + 1
      table.insert(details, string.format('%s: %s', result.name, result.error or 'Unknown error'))
    end
  end
  
  return {
    passed = passed,
    failed = failed,
    total = passed + failed,
    details = details,
    success = failed == 0
  }
end

return M