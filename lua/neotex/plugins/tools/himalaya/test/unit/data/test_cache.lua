-- Unit tests for data/cache.lua module
-- Tests email caching functionality with TTL and normalization

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Email Cache Tests",
  description = "Tests for email caching with TTL and normalization",
  count = 7,
  category = "unit",
  tags = {"cache", "storage", "ttl"},
  estimated_duration_ms = 500
}

-- Load test framework
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"
local framework = require("neotex.plugins.tools.himalaya.test.utils.test_framework")
local test = framework.test
local assert = framework.assert

-- Module under test
local cache = require("neotex.plugins.tools.himalaya.data.cache")

-- Test suite
M.tests = {
  test_cache_store_and_retrieve_email = function()
    -- Clear cache first
    cache.clear_all()
    
    -- Test data
    local account = "test@example.com"
    local folder = "INBOX"
    local email = {
      id = "123",
      from = "sender@example.com",
      to = "recipient@example.com",
      subject = "Test Email",
      date = "2025-01-17"
    }
    
    -- Store email
    cache.store_email(account, folder, email)
    
    -- Retrieve email
    local retrieved = cache.get_email(account, folder, "123")
    assert.is_table(retrieved, "Retrieved email should be a table")
    assert.equals(retrieved.id, "123", "Email ID should match")
    assert.equals(retrieved.from, "sender@example.com", "From should match")
    assert.equals(retrieved.subject, "Test Email", "Subject should match")
  end,
  
  test_cache_ttl_expiration = function()
    -- Clear cache
    cache.clear_all()
    
    -- Store email with short TTL (for testing)
    local old_ttl = cache.config.ttl
    cache.config.ttl = 0 -- 0 seconds TTL (immediate expiration)
    
    local email = { id = "456", subject = "Expiring Email" }
    cache.store_email("test", "INBOX", email)
    
    -- Manually adjust cached_at to simulate expiration
    if cache._get_cache then
      -- Access internal cache if possible
      local internal_cache = cache._get_cache()
      if internal_cache["test"] and internal_cache["test"]["INBOX"] and internal_cache["test"]["INBOX"]["456"] then
        internal_cache["test"]["INBOX"]["456"].cached_at = os.time() - 10 -- 10 seconds ago
      end
    else
      -- Just wait a second to ensure expiration
      vim.wait(1100) -- Wait 1.1 seconds
    end
    
    -- Should be expired
    local retrieved = cache.get_email("test", "INBOX", "456")
    assert.is_nil(retrieved, "Expired email should return nil")
    
    -- Restore TTL
    cache.config.ttl = old_ttl
  end,
  
  test_cache_store_multiple_emails = function()
    cache.clear_all()
    
    local emails = {
      { id = "1", subject = "Email 1" },
      { id = "2", subject = "Email 2" },
      { id = "3", subject = "Email 3" }
    }
    
    -- Store multiple emails
    cache.store_emails("test", "INBOX", emails)
    
    -- Retrieve each
    for _, email in ipairs(emails) do
      local retrieved = cache.get_email("test", "INBOX", email.id)
      assert.is_table(retrieved, "Email should be retrieved")
      assert.equals(retrieved.subject, email.subject, "Subject should match")
    end
  end,
  
  test_cache_body_storage = function()
    cache.clear_all()
    
    local email_id = "789"
    local body_content = "This is the email body\nWith multiple lines\nAnd special chars: @#$%"
    
    -- Store body
    cache.store_email_body("test", "INBOX", email_id, body_content)
    
    -- Retrieve body
    local retrieved = cache.get_email_body("test", "INBOX", email_id)
    assert.equals(retrieved, body_content, "Body content should match exactly")
  end,
  
  test_cache_folder_emails = function()
    cache.clear_all()
    
    local emails = {
      { id = "10", subject = "First" },
      { id = "11", subject = "Second" },
      { id = "12", subject = "Third" }
    }
    
    cache.store_emails("test", "INBOX", emails)
    
    -- Get all emails in folder
    local folder_emails = cache.get_folder_emails("test", "INBOX")
    assert.is_table(folder_emails, "Should return table of emails")
    assert.equals(#folder_emails, 3, "Should have 3 emails")
  end,
  
  test_cache_clear_folder = function()
    cache.clear_all()
    
    -- Store emails in multiple folders
    cache.store_email("test", "INBOX", { id = "1", subject = "Inbox Email" })
    cache.store_email("test", "Sent", { id = "2", subject = "Sent Email" })
    
    -- Clear one folder
    cache.clear_folder("test", "INBOX")
    
    -- INBOX should be empty
    local inbox = cache.get_folder_emails("test", "INBOX")
    assert.equals(#inbox, 0, "INBOX should be empty")
    
    -- Sent should still have email
    local sent = cache.get_email("test", "Sent", "2")
    assert.is_table(sent, "Sent email should still exist")
  end,
  
  test_safe_tostring_handles_userdata = function()
    -- Test internal safe_tostring function by storing userdata
    cache.clear_all()
    
    -- Create a mock email with userdata (vim.NIL)
    local email = {
      id = "999",
      from = vim.NIL,
      to = "test@example.com",
      subject = vim.NIL
    }
    
    -- Should not error when storing
    cache.store_email("test", "INBOX", email)
    
    -- Retrieved email should have normalized string values
    local retrieved = cache.get_email("test", "INBOX", "999")
    assert.is_table(retrieved, "Should retrieve email")
    -- The cache stores the string "vim.NIL" not the default "Unknown"
    assert.equals(retrieved.from, "vim.NIL", "Should store vim.NIL as string")
    assert.equals(retrieved.subject, "vim.NIL", "Should store vim.NIL as string")
  end
}

-- Run all tests
function M.run()
  local test_results = {
    name = "test_cache",
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
if vim.fn.expand('%:t') == 'test_cache.lua' then
  M.run()
end

-- Add standardized interface

return M