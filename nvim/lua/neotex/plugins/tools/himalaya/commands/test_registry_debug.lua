-- Test Registry Debug Commands
-- Commands for inspecting and debugging the test registry system

local M = {}

local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
local float = require('neotex.plugins.tools.himalaya.ui.float')

-- Show registry validation report
function M.show_validation_report()
  local counts = registry.get_comprehensive_counts()
  local lines = {}
  
  -- Header
  table.insert(lines, '# Test Registry Validation Report')
  table.insert(lines, '')
  table.insert(lines, string.format('Generated: %s', os.date('%Y-%m-%d %H:%M:%S')))
  table.insert(lines, '')
  
  -- Summary
  table.insert(lines, '## Overall Summary')
  table.insert(lines, string.format('**Total tests found: %d**', counts.summary.total_tests))
  table.insert(lines, '')
  table.insert(lines, string.format('Total modules: %d', counts.by_status.total))
  table.insert(lines, string.format('Successfully inspected: %d', counts.by_status.inspected))
  table.insert(lines, string.format('Inspection errors: %d', counts.by_status.error))
  table.insert(lines, '')
  table.insert(lines, '### Metadata Status')
  table.insert(lines, string.format('With metadata: %d', counts.summary.total_with_metadata))
  table.insert(lines, string.format('Missing metadata: %d', counts.summary.total_missing_metadata))
  table.insert(lines, '')
  table.insert(lines, '### Validation Issues')
  table.insert(lines, string.format('Count mismatches: %d modules', counts.summary.total_with_mismatches))
  table.insert(lines, string.format('Hardcoded list issues: %d modules', counts.summary.total_with_hardcoded_lists))
  table.insert(lines, '')
  
  -- Category breakdown
  table.insert(lines, '## Test Counts by Category')
  local categories = {}
  for cat, _ in pairs(counts.by_category) do
    table.insert(categories, cat)
  end
  table.sort(categories)
  
  for _, category in ipairs(categories) do
    local info = counts.by_category[category]
    table.insert(lines, string.format('\n### %s', category:upper()))
    table.insert(lines, string.format('- Tests: %d', info.total))
    table.insert(lines, string.format('- Modules: %d', info.modules))
    if info.missing_metadata > 0 then
      table.insert(lines, string.format('- Missing metadata: %d', info.missing_metadata))
    end
    if info.with_issues > 0 then
      table.insert(lines, string.format('- With validation issues: %d', info.with_issues))
    end
    if #info.errors > 0 then
      table.insert(lines, '- Errors:')
      for _, err in ipairs(info.errors) do
        table.insert(lines, string.format('  ⚠️  %s', err.module))
      end
    end
  end
  table.insert(lines, '')
  
  -- Validation issues
  if #counts.validation_issues > 0 then
    table.insert(lines, '## Validation Issues')
    for _, module_issues in ipairs(counts.validation_issues) do
      table.insert(lines, string.format('\n### %s', module_issues.module))
      for _, issue in ipairs(module_issues.issues) do
        table.insert(lines, string.format('- **%s**: %s', issue.type, issue.details))
      end
    end
  else
    table.insert(lines, '## ✅ No Validation Issues Found')
  end
  
  -- Show in floating window
  float.show('Test Registry Validation', lines)
end

-- Debug print registry state
function M.debug_registry()
  registry.debug_print()
end

-- Show test details for a specific module
function M.show_module_details(module_name)
  local lines = {}
  local found = false
  
  -- Search for module
  for module_path, entry in pairs(registry.registry) do
    if module_path:match(module_name) then
      found = true
      table.insert(lines, string.format('# Module: %s', module_path))
      table.insert(lines, '')
      table.insert(lines, string.format('Category: %s', entry.category))
      table.insert(lines, string.format('File: %s', entry.file_path))
      table.insert(lines, '')
      
      if entry.metadata then
        table.insert(lines, '## Metadata')
        table.insert(lines, string.format('Name: %s', entry.metadata.name or 'N/A'))
        table.insert(lines, string.format('Count: %d', entry.metadata.count or 0))
        table.insert(lines, string.format('Description: %s', entry.metadata.description or 'N/A'))
        table.insert(lines, '')
      end
      
      table.insert(lines, '## Actual Tests')
      if #entry.actual_tests > 0 then
        for _, test in ipairs(entry.actual_tests) do
          table.insert(lines, string.format('- %s (%s)', test.name, test.type))
        end
      else
        table.insert(lines, 'No individual tests found (may be a test suite)')
      end
      table.insert(lines, '')
      
      if entry.last_execution then
        table.insert(lines, '## Last Execution')
        table.insert(lines, string.format('Total: %d', entry.last_execution.total))
        table.insert(lines, string.format('Passed: %d', entry.last_execution.passed))
        table.insert(lines, string.format('Failed: %d', entry.last_execution.failed))
        table.insert(lines, '')
      end
      
      if #entry.validation_issues > 0 then
        table.insert(lines, '## Validation Issues')
        for _, issue in ipairs(entry.validation_issues) do
          table.insert(lines, string.format('- %s: %s', issue.type, issue.details))
        end
      end
      
      break
    end
  end
  
  if not found then
    table.insert(lines, string.format('No module found matching: %s', module_name))
  end
  
  float.show('Module Details', lines)
end

return M