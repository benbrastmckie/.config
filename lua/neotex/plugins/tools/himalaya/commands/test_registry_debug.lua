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

-- Show execution summary
function M.show_execution_summary()
  local exec_summary = registry.get_execution_summary()
  local lines = {}
  
  -- Header
  table.insert(lines, '# Test Execution Summary')
  table.insert(lines, '')
  table.insert(lines, string.format('Generated: %s', os.date('%Y-%m-%d %H:%M:%S')))
  table.insert(lines, '')
  
  -- Summary stats
  table.insert(lines, '## Execution Statistics')
  table.insert(lines, string.format('Total modules: %d', exec_summary.total_modules))
  table.insert(lines, string.format('Modules executed: %d', exec_summary.modules_executed))
  table.insert(lines, string.format('Total tests executed: %d', exec_summary.total_executed))
  table.insert(lines, string.format('Execution mismatches: %d', exec_summary.execution_mismatches))
  table.insert(lines, '')
  
  -- Execution mismatches
  if exec_summary.execution_mismatches > 0 and #exec_summary.details > 0 then
    table.insert(lines, '## Execution Mismatches')
    table.insert(lines, '')
    table.insert(lines, 'These modules show different test counts between registry and execution:')
    table.insert(lines, '')
    
    for _, detail in ipairs(exec_summary.details) do
      local module_name = detail.module:match('([^.]+)$') or detail.module
      table.insert(lines, string.format('### %s', module_name))
      table.insert(lines, string.format('- Registry count: %d', detail.registered))
      table.insert(lines, string.format('- Execution count: %d', detail.executed))
      table.insert(lines, string.format('- Difference: %d', detail.executed - detail.registered))
      table.insert(lines, '')
    end
  else
    table.insert(lines, '## ✅ No Execution Mismatches')
    table.insert(lines, '')
    table.insert(lines, 'All executed modules match their registered test counts.')
  end
  
  -- Unexecuted modules
  local unexecuted = {}
  for module_path, entry in pairs(registry.registry) do
    if not entry.last_execution then
      table.insert(unexecuted, {
        module = module_path,
        category = entry.category,
        count = #entry.actual_tests
      })
    end
  end
  
  if #unexecuted > 0 then
    table.insert(lines, '')
    table.insert(lines, '## Unexecuted Modules')
    table.insert(lines, '')
    table.insert(lines, string.format('%d modules have not been executed:', #unexecuted))
    table.insert(lines, '')
    
    -- Sort by category
    table.sort(unexecuted, function(a, b) 
      if a.category == b.category then
        return a.module < b.module
      end
      return a.category < b.category
    end)
    
    local current_category = nil
    for _, info in ipairs(unexecuted) do
      if info.category ~= current_category then
        current_category = info.category
        table.insert(lines, string.format('### %s', current_category:upper()))
      end
      local module_name = info.module:match('([^.]+)$') or info.module
      table.insert(lines, string.format('- %s (%d tests)', module_name, info.count))
    end
  end
  
  -- Show in floating window
  float.show('Execution Summary', lines)
end

return M