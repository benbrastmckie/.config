-- Unit tests for data/drafts.lua module
-- Tests Maildir-based draft management

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Draft Management Tests",
  description = "Tests for draft creation, storage, and recovery",
  count = 6,
  category = "unit",
  tags = {"drafts", "storage", "recovery"},
  estimated_duration_ms = 400
}

-- Load test framework
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"
local framework = require("neotex.plugins.tools.himalaya.test.utils.test_framework")
local test = framework.test
local assert = framework.assert

-- Module under test
local drafts = require("neotex.plugins.tools.himalaya.data.drafts")

-- Test setup/teardown
local test_dir = "/tmp/himalaya_test_drafts"

local function setup()
  -- Enable test mode
  _G.HIMALAYA_TEST_MODE = true
  
  -- Create test directory
  vim.fn.mkdir(test_dir, "p")
  
  -- Mock config
  local config = require("neotex.plugins.tools.himalaya.core.config")
  config.config = {
    sync = {
      maildir_root = test_dir
    },
    accounts = {
      { name = "TestAccount" }
    }
  }
  
  -- Initialize draft manager
  drafts.setup()
end

local function teardown()
  -- Clean up test directory
  vim.fn.delete(test_dir, "rf")
  
  -- Clear draft tracking
  drafts.buffer_drafts = {}
  
  -- Disable test mode
  _G.HIMALAYA_TEST_MODE = false
end

-- Test suite
M.tests = {
  test_create_draft = function()
    setup()
    
    local metadata = {
      from = "test@example.com",
      to = "recipient@example.com",
      subject = "Test Draft",
      body = "This is a test draft."
    }
    
    local buf = drafts.create("TestAccount", metadata)
    assert.is_number(buf, "Should return buffer number")
    assert.truthy(vim.api.nvim_buf_is_valid(buf), "Buffer should be valid")
    
    -- Check buffer content
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert.truthy(#lines > 0, "Buffer should have content")
    
    -- Check that file was created
    local filepath = drafts.buffer_drafts[buf]
    assert.equals(type(filepath), "string", "Should track buffer to filepath")
    assert.truthy(vim.fn.filereadable(filepath) == 1, "Draft file should exist")
    
    teardown()
  end,
  
  test_save_draft = function()
    setup()
    
    local metadata = {
      from = "test@example.com",
      to = "recipient@example.com",
      subject = "Save Test",
      body = "Original body"
    }
    
    local buf = drafts.create("TestAccount", metadata)
    
    -- Modify buffer content
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"Modified content"})
    
    -- Save draft
    local success, err = drafts.save(buf, true) -- silent save
    assert.truthy(success, "Save should succeed: " .. (err or ""))
    
    -- Check file was updated
    local filepath = drafts.buffer_drafts[buf]
    local content = vim.fn.readfile(filepath)
    local full_content = table.concat(content, "\n")
    assert.truthy(full_content:match("Modified content"), "File should contain modified content")
    
    teardown()
  end,
  
  test_list_drafts = function()
    setup()
    
    -- Create multiple drafts
    local draft1 = drafts.create("TestAccount", {
      subject = "Draft 1",
      from = "test@example.com",
      to = "user1@example.com"
    })
    
    local draft2 = drafts.create("TestAccount", {
      subject = "Draft 2", 
      from = "test@example.com",
      to = "user2@example.com"
    })
    
    -- List drafts
    local draft_list = drafts.list("TestAccount")
    assert.is_table(draft_list, "Should return table")
    assert.equals(#draft_list, 2, "Should have 2 drafts")
    
    -- Check draft properties
    local subjects = {}
    for _, draft in ipairs(draft_list) do
      table.insert(subjects, draft.subject)
    end
    
    assert.truthy(vim.tbl_contains(subjects, "Draft 1"), "Should find Draft 1")
    assert.truthy(vim.tbl_contains(subjects, "Draft 2"), "Should find Draft 2")
    
    teardown()
  end,
  
  test_delete_draft = function()
    setup()
    
    local buf = drafts.create("TestAccount", {
      subject = "To Delete",
      from = "test@example.com"
    })
    
    local filepath = drafts.buffer_drafts[buf]
    assert.truthy(vim.fn.filereadable(filepath) == 1, "Draft file should exist")
    
    -- Delete draft
    local success = drafts.delete(buf)
    assert.truthy(success, "Delete should succeed")
    
    -- Check file removed
    assert.truthy(vim.fn.filereadable(filepath) == 0, "Draft file should be deleted")
    
    -- Check buffer tracking removed
    assert.is_nil(drafts.buffer_drafts[buf], "Buffer tracking should be removed")
    
    teardown()
  end,
  
  test_is_draft = function()
    setup()
    
    local draft_buf = drafts.create("TestAccount", { subject = "Test" })
    local normal_buf = vim.api.nvim_create_buf(false, true)
    
    assert.truthy(drafts.is_draft(draft_buf), "Should identify draft buffer")
    assert.falsy(drafts.is_draft(normal_buf), "Should not identify normal buffer as draft")
    
    teardown()
  end,
  
  test_get_by_buffer = function()
    setup()
    
    local metadata = {
      from = "sender@example.com",
      to = "recipient@example.com",
      subject = "Get by buffer test",
      cc = "cc@example.com"
    }
    
    local buf = drafts.create("TestAccount", metadata)
    
    local draft_info = drafts.get_by_buffer(buf)
    assert.is_table(draft_info, "Should return draft info")
    assert.equals(draft_info.subject, "Get by buffer test", "Subject should match")
    assert.equals(draft_info.from, "sender@example.com", "From should match")
    assert.equals(draft_info.to, "recipient@example.com", "To should match")
    assert.equals(draft_info.cc, "cc@example.com", "Cc should match")
    
    teardown()
  end
}

-- Run all tests
function M.run()
  local test_results = {
    name = "test_drafts",
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
if vim.fn.expand('%:t') == 'test_drafts.lua' then
  M.run()
end

-- Add standardized interface
M.get_test_count = function() return M.test_metadata.count end
M.get_test_list = function()
  local names = {}
  for name, _ in pairs(M.tests) do
    table.insert(names, name:gsub("^test_", ""):gsub("_", " "))
  end
  return names
end

return M
