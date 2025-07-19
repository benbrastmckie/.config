-- Test Registry Verification Script
-- Verifies that the registry system is working correctly

local runner = require('neotex.plugins.tools.himalaya.test.test_runner')
local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')

-- Setup and discover tests
runner.setup()

-- Get comprehensive counts
local counts = registry.get_comprehensive_counts()

print("=== Test Registry Verification ===")
print(string.format("Total modules inspected: %d", counts.by_status.inspected))
print(string.format("Modules with errors: %d", counts.by_status.error))
print("")

print("Test counts by category:")
for category, info in pairs(counts.by_category) do
  print(string.format("  %s: %d tests", category, info.total))
end
print("")

if #counts.validation_issues > 0 then
  print("Validation issues found:")
  for _, module_issues in ipairs(counts.validation_issues) do
    print(string.format("\n  Module: %s", module_issues.module))
    for _, issue in ipairs(module_issues.issues) do
      print(string.format("    - %s: %s", issue.type, issue.details))
    end
  end
else
  print("No validation issues found!")
end

-- Check specific known issues
print("\n=== Checking Known Issues ===")

-- Check test_email_commands
local email_cmd_path = "neotex.plugins.tools.himalaya.test.commands.test_email_commands"
local email_cmd_entry = registry.registry[email_cmd_path]
if email_cmd_entry then
  print("\ntest_email_commands:")
  print("  Actual tests found: " .. #email_cmd_entry.actual_tests)
  for _, test in ipairs(email_cmd_entry.actual_tests) do
    print("    - " .. test.name)
  end
  
  -- Check if get_test_list has issues
  for _, issue in ipairs(email_cmd_entry.validation_issues) do
    if issue.type == "hardcoded_list_invalid" then
      print("  ⚠️  " .. issue.details)
    end
  end
end

print("\n=== Registry Verification Complete ===")