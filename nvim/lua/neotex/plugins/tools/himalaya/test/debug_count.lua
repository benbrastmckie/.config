-- Debug script to find the 234 vs 233 discrepancy

local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')

-- Setup test runner
test_runner.setup()

-- Get comprehensive counts
local counts = registry.get_comprehensive_counts()

print("=== REGISTRY COMPREHENSIVE COUNT ANALYSIS ===")
print(string.format("Total tests in registry: %d", counts.summary.total_tests))
print("")

-- Analyze each category
for category, info in pairs(counts.by_category) do
  print(string.format("\n%s category:", category))
  print(string.format("  Total tests: %d", info.total))
  print(string.format("  Modules: %d", info.modules))
  print(string.format("  Missing metadata: %d", info.missing_metadata))
  print(string.format("  With issues: %d", info.with_issues))
end

-- Check each module in detail
print("\n=== DETAILED MODULE ANALYSIS ===")
local total_from_modules = 0
local suites_found = 0
local suites_with_nonzero_count = 0

for module_path, entry in pairs(registry.registry) do
  local test_count = registry.get_test_count(module_path)
  local module_name = module_path:match('([^.]+)$') or module_path
  
  if entry.is_suite then
    suites_found = suites_found + 1
    print(string.format("\nSUITE: %s", module_name))
    print(string.format("  is_suite: %s", tostring(entry.is_suite)))
    print(string.format("  runs_tests: %s", vim.inspect(entry.runs_tests)))
    print(string.format("  Test count: %d", test_count or 0))
    print(string.format("  Aggregated count: %d", registry.get_suite_aggregated_count(module_path)))
    
    if test_count and test_count > 0 then
      suites_with_nonzero_count = suites_with_nonzero_count + 1
    end
  elseif test_count then
    total_from_modules = total_from_modules + test_count
    if test_count == 0 then
      print(string.format("\nMODULE WITH 0 TESTS: %s", module_name))
      print(string.format("  Category: %s", entry.category))
      print(string.format("  is_suite: %s", tostring(entry.is_suite)))
      print(string.format("  needs_execution: %s", tostring(entry.needs_execution)))
    end
  end
end

print(string.format("\n=== SUMMARY ==="))
print(string.format("Total from non-suite modules: %d", total_from_modules))
print(string.format("Total suites found: %d", suites_found))
print(string.format("Suites with non-zero count: %d", suites_with_nonzero_count))

-- Check M.tests in test_runner
print("\n=== TEST RUNNER M.tests ANALYSIS ===")
local runner_total = 0
for category, tests in pairs(test_runner.tests) do
  local category_count = 0
  for _, test in ipairs(tests) do
    local count = registry.get_test_count(test.module_path) or 1
    category_count = category_count + count
  end
  runner_total = runner_total + category_count
  print(string.format("%s: %d tests from %d modules", category, category_count, #tests))
end
print(string.format("\nTotal in M.tests: %d", runner_total))

-- Look for the discrepancy
print("\n=== DISCREPANCY ANALYSIS ===")
print(string.format("Registry reports: %d", counts.summary.total_tests))
print(string.format("Runner M.tests would show: %d", runner_total))
print(string.format("Difference: %d", counts.summary.total_tests - runner_total))

-- Find modules in registry but not in M.tests
print("\n=== MODULES IN REGISTRY BUT NOT IN M.tests ===")
for module_path, entry in pairs(registry.registry) do
  local found_in_tests = false
  for category, tests in pairs(test_runner.tests) do
    for _, test in ipairs(tests) do
      if test.module_path == module_path then
        found_in_tests = true
        break
      end
    end
    if found_in_tests then break end
  end
  
  if not found_in_tests and not entry.is_suite then
    local test_count = registry.get_test_count(module_path) or 0
    print(string.format("Missing from M.tests: %s (count: %d, category: %s)", 
      module_path:match('([^.]+)$') or module_path, test_count, entry.category))
  end
end