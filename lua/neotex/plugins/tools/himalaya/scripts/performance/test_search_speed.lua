-- Test Search Performance for Himalaya Plugin

local framework = require('neotex.plugins.tools.himalaya.scripts.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers

-- Test suite
local tests = {}

-- Test basic search performance
table.insert(tests, framework.create_test('search_performance_basic', function()
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  -- Create large email dataset
  local emails = {}
  for i = 1, 1000 do
    table.insert(emails, helpers.create_test_email({
      subject = "Email " .. i .. (i % 10 == 0 and " important" or ""),
      body = "Body content " .. i .. " with various keywords",
      from = { 
        name = "Sender " .. (i % 5), 
        email = "sender" .. (i % 5) .. "@example.com" 
      }
    }))
  end
  
  -- Measure search time
  local start_time = vim.loop.hrtime()
  local results = search.filter_emails(emails, "subject:important")
  local duration = (vim.loop.hrtime() - start_time) / 1e6
  
  -- Verify results
  assert.equals(#results, 100, "Should find 100 emails with 'important'")
  assert.truthy(duration < 100, "Search should complete in under 100ms")
  
  -- Add performance metric to results
  if _G.himalaya_test_runner then
    _G.himalaya_test_runner.results.performance.basic_search = duration .. "ms"
  end
end))

-- Test complex search performance
table.insert(tests, framework.create_test('search_performance_complex', function()
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  -- Create dataset
  local emails = {}
  for i = 1, 500 do
    table.insert(emails, helpers.create_test_email({
      subject = "Project " .. (i % 20),
      body = "Discussion about " .. (i % 10 == 0 and "urgent" or "regular") .. " matters",
      from = { email = "user" .. (i % 30) .. "@company.com" },
      date = os.date("%Y-%m-%d", os.time() - i * 86400)
    }))
  end
  
  -- Complex search with multiple operators
  local start_time = vim.loop.hrtime()
  local results = search.filter_emails(emails, 
    "from:user1 OR from:user2 AND body:urgent NOT subject:Project 5"
  )
  local duration = (vim.loop.hrtime() - start_time) / 1e6
  
  -- Verify performance
  assert.truthy(duration < 50, "Complex search should complete in under 50ms")
  
  -- Add metric
  if _G.himalaya_test_runner then
    _G.himalaya_test_runner.results.performance.complex_search = duration .. "ms"
  end
end))

-- Test search with date ranges
table.insert(tests, framework.create_test('search_performance_date_range', function()
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  -- Create dated emails
  local emails = {}
  local now = os.time()
  for i = 1, 365 do
    table.insert(emails, helpers.create_test_email({
      subject = "Daily Report " .. i,
      date = os.date("%Y-%m-%d %H:%M:%S", now - i * 86400)
    }))
  end
  
  -- Search last 30 days
  local start_time = vim.loop.hrtime()
  local results = search.filter_emails(emails, "date:>30d")
  local duration = (vim.loop.hrtime() - start_time) / 1e6
  
  -- Verify
  assert.truthy(#results <= 30, "Should find emails from last 30 days")
  assert.truthy(duration < 20, "Date search should complete in under 20ms")
  
  -- Add metric
  if _G.himalaya_test_runner then
    _G.himalaya_test_runner.results.performance.date_search = duration .. "ms"
  end
end))

-- Test search cache performance
table.insert(tests, framework.create_test('search_cache_performance', function()
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  -- Create dataset
  local emails = {}
  for i = 1, 200 do
    table.insert(emails, helpers.create_test_email({
      subject = "Cached Email " .. i
    }))
  end
  
  -- First search (cold)
  local cold_start = vim.loop.hrtime()
  local results1 = search.filter_emails(emails, "subject:Cached")
  local cold_duration = (vim.loop.hrtime() - cold_start) / 1e6
  
  -- Second search (warm - should use cache if implemented)
  local warm_start = vim.loop.hrtime()
  local results2 = search.filter_emails(emails, "subject:Cached")
  local warm_duration = (vim.loop.hrtime() - warm_start) / 1e6
  
  -- Verify
  assert.equals(#results1, #results2, "Results should be consistent")
  
  -- Cache should make second search faster (if implemented)
  -- This is informational - not a hard requirement
  local speedup = cold_duration / warm_duration
  
  -- Add metrics
  if _G.himalaya_test_runner then
    _G.himalaya_test_runner.results.performance.cold_search = cold_duration .. "ms"
    _G.himalaya_test_runner.results.performance.warm_search = warm_duration .. "ms"
    _G.himalaya_test_runner.results.performance.cache_speedup = string.format("%.2fx", speedup)
  end
end))

-- Test memory usage
table.insert(tests, framework.create_test('search_memory_usage', function()
  local search = require('neotex.plugins.tools.himalaya.core.search')
  
  -- Get initial memory
  collectgarbage("collect")
  local initial_memory = collectgarbage("count")
  
  -- Create and search large dataset
  local emails = {}
  for i = 1, 5000 do
    table.insert(emails, helpers.create_test_email({
      subject = "Memory Test " .. i,
      body = string.rep("x", 1000) -- 1KB body
    }))
  end
  
  -- Perform search
  local results = search.filter_emails(emails, "subject:Memory Test 1")
  
  -- Force garbage collection
  emails = nil
  collectgarbage("collect")
  local final_memory = collectgarbage("count")
  
  -- Calculate memory delta
  local memory_increase = final_memory - initial_memory
  
  -- Verify reasonable memory usage
  assert.truthy(memory_increase < 10000, "Memory increase should be under 10MB")
  
  -- Add metric
  if _G.himalaya_test_runner then
    _G.himalaya_test_runner.results.performance.memory_delta = 
      string.format("%.2f KB", memory_increase)
  end
end))

-- Export test suite
_G.himalaya_test = framework.create_suite('Search Performance', tests)

return _G.himalaya_test