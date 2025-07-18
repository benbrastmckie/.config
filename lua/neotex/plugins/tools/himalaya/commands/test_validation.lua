-- Test validation and debugging commands
local M = {}

local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
local float = require('neotex.plugins.tools.himalaya.ui.float')
local notify = require('neotex.util.notifications')

-- Command to validate test counts
M.validate_test_counts = function()
  -- Ensure tests are discovered
  test_runner.discover_tests()
  
  local lines = {
    "# Test Count Validation Report",
    "",
    string.format("Generated: %s", os.date('%Y-%m-%d %H:%M:%S')),
    "",
    "## Summary",
    ""
  }
  
  local total_tests = 0
  local total_with_metadata = 0
  local total_missing_metadata = 0
  
  -- Check each category
  for category, tests in pairs(test_runner.tests) do
    local category_info = test_runner.get_category_count_info(category)
    
    table.insert(lines, string.format("### %s Tests", category:upper()))
    table.insert(lines, string.format("- Total: %d tests", category_info.total))
    table.insert(lines, string.format("- With metadata: %d tests", category_info.explicit))
    table.insert(lines, string.format("- Missing metadata: %d files", category_info.missing_metadata))
    table.insert(lines, "")
    
    -- List files missing metadata
    if category_info.missing_metadata > 0 then
      table.insert(lines, "Files missing metadata:")
      for _, test_info in ipairs(tests) do
        local success, test_module = pcall(require, test_info.module_path)
        if success then
          if not test_module.test_metadata then
            table.insert(lines, string.format("  - %s", test_info.name))
          end
        else
          table.insert(lines, string.format("  - %s (failed to load)", test_info.name))
        end
      end
      table.insert(lines, "")
    end
    
    total_tests = total_tests + category_info.total
    total_with_metadata = total_with_metadata + category_info.explicit
    total_missing_metadata = total_missing_metadata + category_info.missing_metadata
  end
  
  -- Overall summary
  table.insert(lines, "## Overall Summary")
  table.insert(lines, string.format("- Total tests: %d", total_tests))
  table.insert(lines, string.format("- Tests with metadata: %d", total_with_metadata))
  table.insert(lines, string.format("- Files missing metadata: %d", total_missing_metadata))
  
  if total_missing_metadata == 0 then
    table.insert(lines, "")
    table.insert(lines, "✅ All test files have metadata!")
  else
    table.insert(lines, "")
    table.insert(lines, "⚠️  Some test files are missing metadata")
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