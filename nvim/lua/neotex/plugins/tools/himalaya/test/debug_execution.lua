-- Debug script to trace execution count vs picker count

local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
local suite_util = require('neotex.plugins.tools.himalaya.test.utils.test_suite')

-- Setup test runner
test_runner.setup()

-- Simulate what happens during "Run All Tests"
local total_that_would_execute = 0
local total_in_picker = 0
local skipped_tests = {}

print("=== EXECUTION SIMULATION ===")

-- Count what the picker shows
local counts = registry.get_comprehensive_counts()
total_in_picker = counts.summary.total_tests
print(string.format("Picker shows: %d tests", total_in_picker))

-- Simulate execution
for category, tests in pairs(test_runner.tests) do
  print(string.format("\n%s category:", category))
  
  for _, test_info in ipairs(tests) do
    -- Load the module
    local ok, test_module = pcall(require, test_info.module_path)
    
    if ok and test_module then
      -- Check if it's a suite
      if suite_util.is_suite(test_module) then
        -- This would be skipped during execution!
        local test_count = registry.get_test_count(test_info.module_path) or 0
        print(string.format("  SKIP SUITE: %s (would skip %d tests)", test_info.name, test_count))
        table.insert(skipped_tests, {
          name = test_info.name,
          module_path = test_info.module_path,
          count = test_count,
          reason = "is_suite"
        })
      else
        -- This would execute
        local test_count = registry.get_test_count(test_info.module_path) or 1
        total_that_would_execute = total_that_would_execute + test_count
        print(string.format("  EXECUTE: %s (%d tests)", test_info.name, test_count))
      end
    else
      -- Module failed to load
      print(string.format("  ERROR: %s (would count as 1)", test_info.name))
      total_that_would_execute = total_that_would_execute + 1
    end
  end
end

print(string.format("\n=== SUMMARY ==="))
print(string.format("Picker shows: %d", total_in_picker))
print(string.format("Would execute: %d", total_that_would_execute))
print(string.format("Difference: %d", total_in_picker - total_that_would_execute))

if #skipped_tests > 0 then
  print("\n=== SKIPPED TESTS ===")
  for _, skip in ipairs(skipped_tests) do
    print(string.format("- %s: %d tests (reason: %s)", skip.name, skip.count, skip.reason))
  end
end

-- Find the exact source of any remaining discrepancy
if total_in_picker - total_that_would_execute == 1 then
  print("\n=== LOOKING FOR THE EXTRA 1 ===")
  
  -- Check if any test has a mismatch between registry count and actual count
  for module_path, entry in pairs(registry.registry) do
    if not entry.is_suite then
      local registry_count = registry.get_test_count(module_path) or 0
      local actual_tests = #(entry.actual_tests or {})
      
      -- Check for off-by-one errors
      if registry_count ~= actual_tests and math.abs(registry_count - actual_tests) == 1 then
        print(string.format("FOUND MISMATCH: %s", module_path:match('([^.]+)$') or module_path))
        print(string.format("  Registry count: %d", registry_count))
        print(string.format("  Actual tests: %d", actual_tests))
        print(string.format("  needs_execution: %s", tostring(entry.needs_execution)))
        print(string.format("  metadata.count: %s", entry.metadata and entry.metadata.count or "nil"))
      end
    end
  end
end