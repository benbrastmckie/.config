-- Find modules with needs_execution but not is_suite

local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')

-- Setup
test_runner.setup()

print("=== MODULES WITH needs_execution=true AND is_suite=false ===")

for module_path, entry in pairs(registry.registry) do
  if entry.needs_execution and not entry.is_suite then
    local count = registry.get_test_count(module_path)
    local name = module_path:match('([^.]+)$') or module_path
    
    print(string.format("\nFOUND: %s", name))
    print(string.format("  Module path: %s", module_path))
    print(string.format("  Category: %s", entry.category))
    print(string.format("  Test count: %d", count or 0))
    print(string.format("  Has metadata: %s", entry.metadata ~= nil))
    print(string.format("  Metadata count: %s", entry.metadata and entry.metadata.count or "nil"))
    print(string.format("  Last execution: %s", entry.last_execution and vim.inspect(entry.last_execution) or "nil"))
    print(string.format("  Actual tests: %d", #(entry.actual_tests or {})))
    
    -- This is likely our culprit - it gets count=1 by default but might execute 0
    if not entry.last_execution and not (entry.metadata and entry.metadata.count) then
      print("  *** DEFAULT COUNT=1 APPLIED ***")
    end
  end
end

print("\n\n=== VERIFICATION: All suites should have is_suite=true ===")
-- Double-check that all suites are properly marked
for module_path, entry in pairs(registry.registry) do
  if entry.runs_tests then
    print(string.format("\nModule with runs_tests: %s", module_path:match('([^.]+)$')))
    print(string.format("  is_suite: %s", tostring(entry.is_suite)))
    print(string.format("  Test count: %d", registry.get_test_count(module_path) or 0))
  end
end