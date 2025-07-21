-- Unit tests for data/maildir.lua module
-- Tests Maildir format operations and utilities

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Maildir Format Tests",
  description = "Tests for Maildir format operations and utilities",
  count = 8,
  category = "unit",
  tags = {"maildir", "filesystem", "email-format"},
  estimated_duration_ms = 600
}

-- Load test framework
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"
local framework = require("neotex.plugins.tools.himalaya.test.utils.test_framework")
local test = framework.test
local assert = framework.assert

-- Module under test
local maildir = require("neotex.plugins.tools.himalaya.data.maildir")

-- Test setup
local test_dir = "/tmp/himalaya_test_maildir"

local function setup()
  -- Create test directory
  vim.fn.mkdir(test_dir, "p")
end

local function teardown()
  -- Clean up test directory
  vim.fn.delete(test_dir, "rf")
end

-- Test suite
M.tests = {
  test_create_maildir = function()
    setup()
    
    local maildir_path = test_dir .. "/test_maildir"
    local ok, err = maildir.create_maildir(maildir_path)
    
    assert.truthy(ok, "Should create maildir: " .. (err or ""))
    
    -- Check subdirectories exist
    assert.equals(vim.fn.isdirectory(maildir_path .. "/new"), 1, "Should have new/ directory")
    assert.equals(vim.fn.isdirectory(maildir_path .. "/cur"), 1, "Should have cur/ directory")
    assert.equals(vim.fn.isdirectory(maildir_path .. "/tmp"), 1, "Should have tmp/ directory")
    
    teardown()
  end,
  
  test_is_maildir = function()
    setup()
    
    local maildir_path = test_dir .. "/valid_maildir"
    maildir.create_maildir(maildir_path)
    
    assert.truthy(maildir.is_maildir(maildir_path), "Should recognize valid maildir")
    assert.falsy(maildir.is_maildir(test_dir), "Should reject non-maildir directory")
    assert.falsy(maildir.is_maildir("/nonexistent"), "Should reject nonexistent path")
    
    teardown()
  end,
  
  test_generate_filename = function()
    -- Test basic filename generation
    local filename = maildir.generate_filename()
    assert.equals(type(filename), "string", "Should generate filename")
    
    -- Should match Maildir format
    assert.truthy(filename:match("^%d+%."), "Should start with timestamp")
    
    -- Test with flags
    local flagged = maildir.generate_filename({'S', 'F'})
    assert.truthy(flagged:match(":2,"), "Should have :2, prefix for flags")
    assert.truthy(flagged:match("F"), "Should have F flag")
    assert.truthy(flagged:match("S"), "Should have S flag")
  end,
  
  test_parse_filename = function()
    -- Test with a simple filename
    local filename = "1234567890.M123P456.hostname"
    local parsed = maildir.parse_filename(filename)
    
    assert.is_table(parsed, "Should parse filename")
    assert.equals(parsed.timestamp, 1234567890, "Should extract timestamp")
    
    -- Test with flags
    local filename_with_flags = "1234567890.M123P456.hostname:2,FS"
    local parsed_flags = maildir.parse_filename(filename_with_flags)
    
    assert.is_table(parsed_flags, "Should parse filename with flags")
    assert.is_table(parsed_flags.flags, "Should extract flags")
    assert.truthy(vim.tbl_contains(parsed_flags.flags, 'F'), "Should have F flag")
    assert.truthy(vim.tbl_contains(parsed_flags.flags, 'S'), "Should have S flag")
  end,
  
  test_atomic_write = function()
    setup()
    
    local maildir_path = test_dir .. "/write_test"
    maildir.create_maildir(maildir_path)
    
    local content = "Test email content\nWith multiple lines"
    local target = maildir_path .. "/cur/test_email"
    
    local ok, err = maildir.atomic_write(maildir_path .. "/tmp", target, content)
    assert.truthy(ok, "Should write atomically: " .. (err or ""))
    
    -- Check file exists and has correct content
    assert.equals(vim.fn.filereadable(target), 1, "Target file should exist")
    
    local read_content = table.concat(vim.fn.readfile(target), "\n")
    assert.equals(read_content, content, "Content should match")
    
    teardown()
  end,
  
  test_list_messages = function()
    setup()
    
    local maildir_path = test_dir .. "/list_test"
    maildir.create_maildir(maildir_path)
    
    -- Create test messages
    local files = {
      maildir_path .. "/cur/1234567890.test:2,S",
      maildir_path .. "/cur/1234567891.test:2,",
      maildir_path .. "/new/1234567892.test"
    }
    
    for _, file in ipairs(files) do
      vim.fn.writefile({"Test content"}, file)
    end
    
    local messages = maildir.list_messages(maildir_path)
    assert.truthy(#messages > 0, "Should find messages")
    
    -- Check message properties
    for _, msg in ipairs(messages) do
      assert.equals(type(msg.filename), "string", "Should have filename")
      assert.equals(type(msg.path), "string", "Should have path")
      assert.is_number(msg.timestamp, "Should have timestamp")
    end
    
    teardown()
  end,
  
  test_read_headers = function()
    setup()
    
    local test_file = test_dir .. "/test_email.eml"
    local content = [[From: sender@example.com
To: recipient@example.com
Subject: Test Email
Date: Fri, 17 Jan 2025 10:00:00 +0000
Message-ID: <123@example.com>

This is the body.]]
    
    vim.fn.writefile(vim.split(content, "\n"), test_file)
    
    local headers = maildir.read_headers(test_file)
    assert.is_table(headers, "Should return headers")
    assert.equals(headers.from, "sender@example.com", "Should parse From header")
    assert.equals(headers.to, "recipient@example.com", "Should parse To header")
    assert.equals(headers.subject, "Test Email", "Should parse Subject header")
    assert.equals(headers["message-id"], "<123@example.com>", "Should parse Message-ID")
    
    teardown()
  end,
  
  test_update_size = function()
    setup()
    
    local test_file = test_dir .. "/test.eml"
    local content = "Test content with known size"
    vim.fn.writefile({content}, test_file)
    
    -- Create a filename with size placeholder
    local filename = "1234567890.test,S=0:2,S"
    local new_path = test_dir .. "/" .. filename
    vim.fn.rename(test_file, new_path)
    
    local updated_path = maildir.update_size(new_path)
    
    -- Check that the function returns something
    assert.equals(type(updated_path), "string", "Should return updated path")
    
    teardown()
  end
}

-- Run all tests
function M.run()
  local test_results = {
    name = "test_maildir",
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
  }
  
  for test_name, test_fn in pairs(M.tests) do
    test_results.total = test_results.total + 1
    
    -- Set test mode
    _G.HIMALAYA_TEST_MODE = true
    
    local ok, err = pcall(test_fn)
    
    if ok then
      test_results.passed = test_results.passed + 1
      -- Suppress print output when run from test runner
      if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
        print("✓ " .. test_name)
      end
    else
      test_results.failed = test_results.failed + 1
      table.insert(test_results.errors, {
        test = test_name,
        error = tostring(err)
      })
      -- Suppress print output when run from test runner
      if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
        print("✗ " .. test_name .. ": " .. tostring(err))
      end
    end
  end
  
  -- Print summary only when not run from test runner
  if not _G.HIMALAYA_TEST_RUNNER_ACTIVE then
    print(string.format("\n%s: %d/%d tests passed (%.1f%%)",
      test_results.name,
      test_results.passed,
      test_results.total,
      (test_results.passed / test_results.total) * 100
    ))
  end
  
  return test_results
end

-- Execute if running directly
if vim.fn.expand('%:t') == 'test_maildir.lua' then
  M.run()
end

-- Add standardized interface

return M