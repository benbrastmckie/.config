-- Test validation and debugging commands
local M = {}

local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
local float = require('neotex.plugins.tools.himalaya.ui.float')
local notify = require('neotex.util.notifications')

-- Command to validate test counts
M.validate_test_counts = function()
  -- Use registry for comprehensive validation
  local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
  local counts = registry.get_comprehensive_counts()
  
  local lines = {
    "# Test Count Validation Report",
    "",
    string.format("Generated: %s", os.date('%Y-%m-%d %H:%M:%S')),
    "",
    "## Summary",
    ""
  }
  
  -- Overall counts
  table.insert(lines, string.format("Total Tests: %d", counts.summary.total_tests))
  table.insert(lines, string.format("Total Modules: %d", counts.by_status.total))
  table.insert(lines, string.format("Successfully Inspected: %d", counts.by_status.inspected))
  table.insert(lines, string.format("Inspection Errors: %d", counts.by_status.error))
  table.insert(lines, "")
  
  -- Architecture Summary
  table.insert(lines, "## Test Architecture")
  local suite_count = 0
  local test_file_count = 0
  
  for module_path, entry in pairs(registry.registry) do
    if entry.is_suite then
      suite_count = suite_count + 1
    else
      test_file_count = test_file_count + 1
    end
  end
  
  table.insert(lines, string.format("Test Files: %d (contribute to count)", test_file_count))
  table.insert(lines, string.format("Test Suites: %d (orchestrate other tests, count=0)", suite_count))
  table.insert(lines, "")
  
  -- List suites
  if suite_count > 0 then
    table.insert(lines, "### Test Suites")
    for module_path, entry in pairs(registry.registry) do
      if entry.is_suite then
        local name = module_path:match("([^.]+)$") or module_path
        local aggregated = registry.get_suite_aggregated_count(module_path)
        table.insert(lines, string.format("- %s (aggregates %d tests)", name, aggregated))
        if entry.runs_tests and #entry.runs_tests > 0 then
          for _, test_name in ipairs(entry.runs_tests) do
            table.insert(lines, string.format("  - %s", test_name))
          end
        end
      end
    end
    table.insert(lines, "")
  end
  
  -- Validation Issues
  if #counts.validation_issues > 0 then
    table.insert(lines, "## ⚠️  Validation Issues")
    table.insert(lines, "")
    
    for _, issue in ipairs(counts.validation_issues) do
      local module_name = issue.module:match("([^.]+)$") or issue.module
      table.insert(lines, string.format("### %s", module_name))
      
      for _, detail in ipairs(issue.issues) do
        if detail.type == 'count_mismatch' then
          table.insert(lines, string.format("- ❌ %s", detail.details))
        elseif detail.type == 'missing_metadata' then
          table.insert(lines, string.format("- ⚠️  %s", detail.details))
        else
          table.insert(lines, string.format("- ⚠  %s", detail.details))
        end
      end
      table.insert(lines, "")
    end
  else
    table.insert(lines, "## ✅ No Validation Issues")
    table.insert(lines, "")
  end
  
  -- Category breakdown
  table.insert(lines, "## Category Breakdown")
  table.insert(lines, "")
  
  for category, info in pairs(counts.by_category) do
    table.insert(lines, string.format("### %s", category:upper()))
    table.insert(lines, string.format("- Modules: %d", info.modules))
    table.insert(lines, string.format("- Total Tests: %d", info.total))
    if info.missing_metadata > 0 then
      table.insert(lines, string.format("- Missing Metadata: %d ⚠️", info.missing_metadata))
    end
    if info.with_issues > 0 then
      table.insert(lines, string.format("- Modules with Issues: %d ⚠️", info.with_issues))
    end
    table.insert(lines, "")
  end
  
  -- Final status
  if counts.summary.total_missing_metadata == 0 and 
     counts.summary.total_with_mismatches == 0 and
     counts.by_status.error == 0 then
    table.insert(lines, "## ✅ All Validations Passed!")
    table.insert(lines, "")
    table.insert(lines, "The test system is in perfect health:")
    table.insert(lines, "- All modules have metadata")
    table.insert(lines, "- No count mismatches")
    table.insert(lines, "- Clear test/suite architecture")
    table.insert(lines, "- Registry and execution counts match")
  else
    table.insert(lines, "## ⚠️  Action Required")
    table.insert(lines, "")
    if counts.summary.total_missing_metadata > 0 then
      table.insert(lines, string.format("- Add metadata to %d modules", counts.summary.total_missing_metadata))
    end
    if counts.summary.total_with_mismatches > 0 then
      table.insert(lines, string.format("- Fix count mismatches in %d modules", counts.summary.total_with_mismatches))
    end
    if counts.by_status.error > 0 then
      table.insert(lines, string.format("- Fix load errors in %d modules", counts.by_status.error))
    end
  end
  
  -- Show in floating window
  float.show('Test Count Validation', lines)
end

-- Command to debug test count discrepancies
M.debug_test_counts = function()
  test_runner.discover_tests()
  
  local lines = {
    "# Test Count Debug Report",
    "",
    string.format("Generated: %s", os.date('%Y-%m-%d %H:%M:%S')),
    "",
    "## Test Count Comparison",
    ""
  }
  
  -- Get counts from different methods
  local picker_count = test_runner.count_all_test_functions()
  local metadata_count, validation_info = test_runner.count_all_tests_with_validation()
  
  table.insert(lines, string.format("Picker count (legacy): %d", picker_count))
  table.insert(lines, string.format("Metadata count: %d", metadata_count))
  table.insert(lines, "")
  
  if validation_info.has_missing_metadata then
    table.insert(lines, "## Missing Metadata")
    table.insert(lines, string.format("Files without metadata: %d", validation_info.missing_metadata_count))
    table.insert(lines, "Categories affected:")
    for _, cat in ipairs(validation_info.categories_with_issues) do
      table.insert(lines, string.format("  - %s", cat))
    end
    table.insert(lines, "")
  end
  
  -- Check for test count mismatches
  table.insert(lines, "## Test Execution vs Metadata Mismatches")
  table.insert(lines, "")
  table.insert(lines, "These tests report different counts in metadata vs actual execution:")
  table.insert(lines, "(This requires running the tests to check)")
  table.insert(lines, "")
  
  -- List known mismatches from recent test run
  local known_mismatches = {
    { file = "test_email_operations_simple", metadata = 5, actual = 4 },
    { file = "test_async_timing", metadata = 9, actual = 8 },
    { file = "test_maildir_foundation", metadata = 14, actual = 12 }
  }
  
  for _, mismatch in ipairs(known_mismatches) do
    table.insert(lines, string.format("- %s: metadata says %d, execution says %d",
      mismatch.file, mismatch.metadata, mismatch.actual))
  end
  
  -- Show in floating window
  float.show('Test Count Debug', lines)
end

-- Command to show detailed test information
M.show_test_details = function(test_name)
  test_runner.discover_tests()
  
  local found = false
  local lines = {
    "# Test Details",
    "",
    string.format("Test: %s", test_name or "All"),
    ""
  }
  
  -- If no specific test, show all
  if not test_name then
    for category, tests in pairs(test_runner.tests) do
      table.insert(lines, string.format("## %s", category:upper()))
      table.insert(lines, "")
      
      for _, test_info in ipairs(tests) do
        local success, test_module = pcall(require, test_info.module_path)
        if success and test_module.test_metadata then
          table.insert(lines, string.format("### %s", test_info.display_name))
          table.insert(lines, string.format("- Module: %s", test_info.module_path))
          table.insert(lines, string.format("- Count: %d tests", test_module.test_metadata.count))
          table.insert(lines, string.format("- Category: %s", test_module.test_metadata.category))
          if test_module.test_metadata.tags then
            table.insert(lines, string.format("- Tags: %s", table.concat(test_module.test_metadata.tags, ", ")))
          end
          table.insert(lines, "")
        end
      end
    end
  else
    -- Find specific test
    for category, tests in pairs(test_runner.tests) do
      for _, test_info in ipairs(tests) do
        if test_info.name == test_name or test_info.display_name == test_name then
          found = true
          local success, test_module = pcall(require, test_info.module_path)
          if success then
            table.insert(lines, string.format("## %s", test_info.display_name))
            table.insert(lines, string.format("- Module: %s", test_info.module_path))
            table.insert(lines, string.format("- Category: %s", category))
            
            if test_module.test_metadata then
              table.insert(lines, "")
              table.insert(lines, "### Metadata")
              table.insert(lines, string.format("- Name: %s", test_module.test_metadata.name))
              table.insert(lines, string.format("- Count: %d tests", test_module.test_metadata.count))
              table.insert(lines, string.format("- Category: %s", test_module.test_metadata.category))
              if test_module.test_metadata.description then
                table.insert(lines, string.format("- Description: %s", test_module.test_metadata.description))
              end
              if test_module.test_metadata.tags then
                table.insert(lines, string.format("- Tags: %s", table.concat(test_module.test_metadata.tags, ", ")))
              end
              if test_module.test_metadata.estimated_duration_ms then
                table.insert(lines, string.format("- Estimated duration: %d ms", test_module.test_metadata.estimated_duration_ms))
              end
              
              if test_module.get_test_list then
                table.insert(lines, "")
                table.insert(lines, "### Individual Tests")
                local test_list = test_module.get_test_list()
                for i, test in ipairs(test_list) do
                  table.insert(lines, string.format("%d. %s", i, test))
                end
              end
            else
              table.insert(lines, "")
              table.insert(lines, "⚠️  No metadata found for this test")
            end
          else
            table.insert(lines, "")
            table.insert(lines, "❌ Failed to load test module")
          end
          break
        end
      end
      if found then break end
    end
    
    if not found then
      table.insert(lines, "")
      table.insert(lines, "❌ Test not found: " .. test_name)
    end
  end
  
  -- Show in floating window
  float.show('Test Details', lines)
end

return M