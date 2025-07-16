-- Development CLI for Himalaya Test Suite
-- This provides command-line access to the test runner for development workflows
-- Usage: nvim --headless -l test/dev_cli.lua [test_arg]
--
-- Arguments:
--   all          - Run all tests (default)
--   commands     - Run command tests
--   features     - Run feature tests
--   integration  - Run integration tests
--   performance  - Run performance tests
--   <test_name>  - Run specific test by name
--
-- This file:
-- - Sets up the test environment for headless mode
-- - Overrides UI output to print to stdout
-- - Handles exit codes for shell integration
--
-- The actual test logic is in test_runner.lua

-- Set test mode
_G.HIMALAYA_TEST_MODE = true

-- Initialize Himalaya
local ok, himalaya = pcall(require, 'neotex.plugins.tools.himalaya.init')
if ok then
  himalaya.setup({})
end

-- Setup and run tests
local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
test_runner.setup()

-- Override show_results for headless mode
test_runner.show_results = function()
  local results = test_runner.results
  print("\n# Himalaya Test Results\n")
  print(string.format("Date: %s", os.date("%Y-%m-%d %H:%M:%S")))
  print(string.format("Duration: %.2f ms\n", results.duration or 0))
  print("## Summary")
  print(string.format("Total Tests: %d", results.total))
  print(string.format("✅ Passed: %d", results.passed))
  print(string.format("❌ Failed: %d", results.failed))
  print(string.format("⏭️  Skipped: %d", results.skipped or 0))
  print(string.format("\nSuccess Rate: %.1f%%\n", 
    results.total > 0 and (results.passed / results.total * 100) or 0))
  
  if results.failed > 0 and results.errors then
    print("## Failed Tests\n")
    for _, error in ipairs(results.errors) do
      -- Print the test category and name
      local test_name = error.test or "Unknown test"
      if error.test_name and error.test_name ~= "" then
        test_name = test_name .. ":" .. error.test_name
      end
      print(string.format("❌ [%s] %s", 
        error.category or "UNKNOWN",
        test_name))
      
      -- Print the full error message with proper indentation
      local message = error.message or error.error or "No error message"
      -- Split multiline messages and indent each line
      for line in message:gmatch("[^\n]+") do
        print("  " .. line)
      end
      print("") -- Empty line between errors
    end
  else
    print("All tests passed! 🎉")
  end
end

-- Get test argument from command line
local test_arg = arg and arg[1] or 'all'

-- Execute tests
test_runner.execute_test_selection(test_arg)

-- Exit with appropriate code
os.exit(test_runner.results.failed == 0 and 0 or 1)