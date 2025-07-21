-- Find the extra test that causes 234 vs 233

local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')

-- Setup
test_runner.setup()

-- Theory: A test file exists that:
-- 1. Is counted in the registry total (contributes 1)
-- 2. But when executed, it either:
--    a) Returns 0 tests
--    b) Fails to load
--    c) Is skipped somehow

print("=== LOOKING FOR TESTS WITH COUNT=1 ===")

-- Find all tests that report exactly 1 test
local single_test_modules = {}

for module_path, entry in pairs(registry.registry) do
  local count = registry.get_test_count(module_path)
  if count == 1 and not entry.is_suite then
    table.insert(single_test_modules, {
      module_path = module_path,
      name = module_path:match('([^.]+)$') or module_path,
      category = entry.category,
      needs_execution = entry.needs_execution,
      has_metadata = entry.metadata ~= nil,
      metadata_count = entry.metadata and entry.metadata.count
    })
  end
end

print(string.format("Found %d modules with exactly 1 test", #single_test_modules))

-- Check each one
for _, module in ipairs(single_test_modules) do
  -- Check if this module has special properties
  if module.needs_execution then
    print(string.format("\nSUSPECT: %s", module.name))
    print(string.format("  Category: %s", module.category))
    print(string.format("  needs_execution: true"))
    print(string.format("  metadata_count: %s", module.metadata_count or "nil"))
    
    -- Try to load and check
    local ok, test_module = pcall(require, module.module_path)
    if ok and test_module then
      -- Count actual test functions
      local actual_count = 0
      for name, func in pairs(test_module) do
        if type(func) == 'function' and name:match('^test_') then
          actual_count = actual_count + 1
        end
      end
      
      -- Check if it has a run function that might return different results
      if test_module.run then
        print(string.format("  Has run() function"))
        print(string.format("  Actual test functions: %d", actual_count))
        
        -- This could be the culprit if run() returns 0 tests
        if actual_count == 0 then
          print("  *** LIKELY CULPRIT: Has run() but no test_ functions ***")
        end
      end
    end
  end
end

-- Alternative theory: Check for default count = 1 logic
print("\n\n=== CHECKING DEFAULT COUNT LOGIC ===")

local registry_86_line = [[
  -- Default to 1 for suite
  return 1
]]

print("In test_registry.lua, line 86 returns 1 as default for suites that need execution.")
print("This could add 1 to the count if a suite's execution results aren't available.")

-- Check if any suite has this condition
for module_path, entry in pairs(registry.registry) do
  if entry.is_suite and entry.needs_execution and not entry.last_execution then
    local count = registry.get_test_count(module_path)
    print(string.format("\nSUITE WITH DEFAULT COUNT: %s", module_path:match('([^.]+)$')))
    print(string.format("  Count: %d", count or 0))
    print(string.format("  Has metadata.count: %s", entry.metadata and entry.metadata.count or "no"))
  end
end