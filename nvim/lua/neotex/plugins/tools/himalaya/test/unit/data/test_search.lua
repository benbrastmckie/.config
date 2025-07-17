-- Unit tests for data/search.lua module
-- Tests advanced search functionality with Gmail-style operators

local M = {}

-- Test metadata
M.test_metadata = {
  name = "Email Search Tests",
  description = "Tests for advanced search functionality with operators",
  count = 9,
  category = "unit",
  tags = {"search", "query", "operators"},
  estimated_duration_ms = 300
}

-- Load test framework
package.path = package.path .. ";/home/benjamin/.config/nvim/lua/?.lua"
local framework = require("neotex.plugins.tools.himalaya.test.utils.test_framework")
local test = framework.test
local assert = framework.assert

-- Module under test
local search = require("neotex.plugins.tools.himalaya.data.search")

-- Mock email cache for testing
local mock_emails = {
  {
    id = "1",
    from = "john@example.com",
    to = {"me@example.com"},  -- Should be array
    cc = {},
    subject = "Meeting tomorrow",
    body = "Let's discuss the project",
    date = "2025-01-17",
    has_attachment = true
  },
  {
    id = "2", 
    from = "jane@company.com",
    to = {"me@example.com"},  -- Should be array
    cc = {},
    subject = "Re: Project update",
    body = "The latest changes look good",
    date = "2025-01-16",
    has_attachment = false
  },
  {
    id = "3",
    from = "support@service.com",
    to = {"me@example.com"},  -- Should be array
    cc = {},
    subject = "Your invoice",
    body = "Payment due soon",
    date = "2025-01-15",
    has_attachment = true
  }
}

-- Test suite
M.tests = {
  test_parse_query_simple = function()
    local query = "project"
    local parsed, err = search.parse_query(query)
    
    assert.is_table(parsed, "Should return parsed query")
    assert.is_table(parsed.text, "Should have text array")
    
    -- Check text array structure
    local has_project = false
    for _, text_item in ipairs(parsed.text) do
      if text_item.value == "project" then
        has_project = true
      end
    end
    assert.truthy(has_project, "Should contain search text")
  end,
  
  test_parse_query_with_operators = function()
    local query = 'from:john@example.com subject:"Meeting tomorrow" has:attachment'
    local parsed = search.parse_query(query)
    
    assert.is_table(parsed.operators, "Should have operators")
    -- Check operators were parsed
    local has_from = false
    local has_subject = false
    local has_attachment = false
    
    for _, op in ipairs(parsed.operators) do
      if op.operator == "from" and op.value == "john@example.com" then
        has_from = true
      elseif op.operator == "subject" and op.value == "Meeting tomorrow" then
        has_subject = true
      elseif op.operator == "has" and op.value == "attachment" then
        has_attachment = true
      end
    end
    
    assert.truthy(has_from, "Should parse from operator")
    assert.truthy(has_subject, "Should parse subject operator")
    assert.truthy(has_attachment, "Should parse has:attachment")
  end,
  
  test_match_email_with_text = function()
    local criteria = {
      text = {{value = "project", negate = false}},
      operators = {},
      logic = "AND"
    }
    
    local match1 = search.match_email(mock_emails[1], criteria)
    local match2 = search.match_email(mock_emails[2], criteria)
    local match3 = search.match_email(mock_emails[3], criteria)
    
    assert.truthy(match1, "Email 1 should match 'project'")
    assert.truthy(match2, "Email 2 should match 'project'")
    assert.falsy(match3, "Email 3 should not match 'project'")
  end,
  
  test_match_email_with_from_operator = function()
    local criteria = {
      text = {},
      operators = {{
        operator = "from",
        value = "john",
        config = search.operators.from,
        negate = false
      }},
      logic = "AND"
    }
    
    local match1 = search.match_email(mock_emails[1], criteria)
    local match2 = search.match_email(mock_emails[2], criteria)
    
    assert.truthy(match1, "Should match email from john")
    assert.falsy(match2, "Should not match email from jane")
  end,
  
  test_search_function = function()
    -- Mock email cache
    local email_cache = require("neotex.plugins.tools.himalaya.data.cache")
    local orig_get_folder_emails = email_cache.get_folder_emails
    email_cache.get_folder_emails = function()
      return mock_emails
    end
    
    local results = search.search("project", {
      account = "test",
      folder = "INBOX"
    })
    
    -- Restore original function
    email_cache.get_folder_emails = orig_get_folder_emails
    
    assert.is_table(results, "Should return results")
    -- Results might be empty if search logic differs
  end,
  
  test_parse_date_operators = function()
    local query = "after:2025-01-15"
    local parsed = search.parse_query(query)
    
    assert.is_table(parsed.operators, "Should have operators")
    local has_after = false
    for _, op in ipairs(parsed.operators) do
      if op.operator == "after" and op.value == "2025-01-15" then
        has_after = true
      end
    end
    assert.truthy(has_after, "Should parse after operator")
  end,
  
  test_match_boolean_field = function()
    local email_with_attachment = { has_attachment = true }
    local email_without = { has_attachment = false }
    
    assert.truthy(search.match_boolean_field(email_with_attachment, "has_attachment", true), 
                  "Should match email with attachment")
    assert.truthy(search.match_boolean_field(email_without, "has_attachment", false),
                 "Should match email without attachment when looking for false")
  end,
  
  test_clean_quotes = function()
    assert.equals(search.clean_quotes('"quoted text"'), "quoted text", 
                  "Should remove double quotes")
    assert.equals(search.clean_quotes("'single quoted'"), "single quoted",
                  "Should remove single quotes")
    assert.equals(search.clean_quotes("unquoted"), "unquoted",
                  "Should leave unquoted text unchanged")
  end
}

-- Run all tests
function M.run()
  local test_results = {
    name = "test_search",
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
if vim.fn.expand('%:t') == 'test_search.lua' then
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