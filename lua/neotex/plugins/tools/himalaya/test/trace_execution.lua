-- Trace actual test execution to find the 234 vs 233 discrepancy

local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
local original_run_test = test_runner.run_test

-- Counter
local execution_trace = {
  total_executed = 0,
  tests_by_module = {},
  skipped_modules = {}
}

-- Override run_test to trace execution
test_runner.run_test = function(test_info)
  print(string.format("\n=== EXECUTING: %s ===", test_info.name))
  
  -- Store original results
  local original_total = test_runner.results.total
  
  -- Call original function
  original_run_test(test_info)
  
  -- Calculate tests added by this module
  local tests_added = test_runner.results.total - original_total
  execution_trace.total_executed = execution_trace.total_executed + tests_added
  
  execution_trace.tests_by_module[test_info.name] = {
    count = tests_added,
    category = test_info.category,
    module_path = test_info.module_path
  }
  
  print(string.format("  Tests executed: %d", tests_added))
  print(string.format("  Running total: %d", execution_trace.total_executed))
  
  -- Check if this was skipped as a suite
  if tests_added == 0 then
    -- Load module to check if it's a suite
    local ok, test_module = pcall(require, test_info.module_path)
    if ok and test_module then
      local suite_util = require('neotex.plugins.tools.himalaya.test.utils.test_suite')
      if suite_util.is_suite(test_module) then
        print("  SKIPPED: This is a test suite")
        table.insert(execution_trace.skipped_modules, test_info.name)
      end
    end
  end
end

-- Setup and run
print("=== STARTING TEST EXECUTION TRACE ===")
test_runner.setup()

-- Get picker count
local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local counts = registry.get_comprehensive_counts()
print(string.format("Picker would show: %d tests", counts.summary.total_tests))

-- Run all tests
test_runner.run_all_tests()

-- Summary
print("\n\n=== EXECUTION SUMMARY ===")
print(string.format("Total tests executed: %d", execution_trace.total_executed))
print(string.format("Picker shows: %d", counts.summary.total_tests))
print(string.format("DISCREPANCY: %d", counts.summary.total_tests - execution_trace.total_executed))

if #execution_trace.skipped_modules > 0 then
  print("\nSkipped modules (suites):")
  for _, name in ipairs(execution_trace.skipped_modules) do
    print(string.format("  - %s", name))
  end
end

-- Find the module causing the discrepancy
if counts.summary.total_tests - execution_trace.total_executed == 1 then
  print("\n=== LOOKING FOR THE MODULE WITH OFF-BY-ONE ===")
  
  -- Compare registry count vs execution count for each module
  for name, exec_info in pairs(execution_trace.tests_by_module) do
    local registry_count = registry.get_test_count(exec_info.module_path)
    if registry_count and registry_count ~= exec_info.count then
      print(string.format("\nMISMATCH FOUND: %s", name))
      print(string.format("  Registry count: %d", registry_count))
      print(string.format("  Execution count: %d", exec_info.count))
      print(string.format("  Difference: %d", registry_count - exec_info.count))
    end
  end
end