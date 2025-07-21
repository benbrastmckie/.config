-- Find why test_scheduler causes 234 vs 233

local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')

-- Setup
test_runner.setup()

print("=== LOOKING FOR test_scheduler MODULES ===")

-- Find all scheduler modules in registry
local scheduler_modules = {}
for module_path, entry in pairs(registry.registry) do
  if module_path:match("test_scheduler") then
    table.insert(scheduler_modules, {
      module_path = module_path,
      entry = entry
    })
  end
end

print(string.format("Found %d test_scheduler modules in registry", #scheduler_modules))

for _, mod in ipairs(scheduler_modules) do
  local count = registry.get_test_count(mod.module_path)
  print(string.format("\n%s", mod.module_path))
  print(string.format("  Category: %s", mod.entry.category))
  print(string.format("  Test count: %d", count or 0))
  print(string.format("  is_suite: %s", tostring(mod.entry.is_suite)))
end

-- Check M.tests
print("\n=== test_scheduler IN M.tests ===")
local found_in_tests = {}
for category, tests in pairs(test_runner.tests) do
  for _, test in ipairs(tests) do
    if test.name == "test_scheduler" then
      table.insert(found_in_tests, {
        category = category,
        test = test
      })
    end
  end
end

print(string.format("Found %d test_scheduler entries in M.tests", #found_in_tests))
for _, entry in ipairs(found_in_tests) do
  print(string.format("\nCategory: %s", entry.category))
  print(string.format("  Module path: %s", entry.test.module_path))
  print(string.format("  File path: %s", entry.test.path))
end

-- Theory: Both schedulers are in registry (contributing to 234)
-- But during execution, they're deduplicated somehow (resulting in 233)

print("\n=== THEORY CHECK ===")
local total_scheduler_count = 0
for _, mod in ipairs(scheduler_modules) do
  local count = registry.get_test_count(mod.module_path) or 0
  total_scheduler_count = total_scheduler_count + count
  print(string.format("%s contributes %d tests", mod.module_path:match("([^.]+)$"), count))
end

print(string.format("\nTotal from schedulers: %d", total_scheduler_count))
print("\nIf one scheduler is counted twice in picker but executed once, that would explain 234 vs 233")