-- Test Registry: Single Source of Truth for Test Information
-- Central registry that maintains accurate test counts and metadata

local M = {}

-- Single source of truth for all test information
M.registry = {
  -- Structure:
  -- [module_path] = {
  --   file_path = string,
  --   category = string,
  --   actual_tests = { name = string, type = 'function'|'suite' }[],
  --   metadata = table|nil,
  --   last_execution = { total = number, passed = number, failed = number }|nil,
  --   inspection_error = string|nil,
  --   validation_issues = { type = string, details = string }[]
  -- }
}

-- Inspect a test module and register its actual tests
function M.inspect_and_register(test_info)
  local inspector = require('neotex.plugins.tools.himalaya.test.utils.test_inspector')
  
  -- Inspect the module
  local inspection_result, error = inspector.inspect_module(test_info.module_path)
  
  if not inspection_result then
    -- Store the error but continue
    M.registry[test_info.module_path] = {
      file_path = test_info.path,
      category = test_info.category,
      actual_tests = {},
      metadata = nil,
      inspection_error = error,
      validation_issues = { { type = 'load_error', details = error } }
    }
    return false, error
  end
  
  -- Validate the module structure
  local validation_issues = inspector.validate_structure(inspection_result)
  
  -- Register the module
  M.registry[test_info.module_path] = {
    file_path = test_info.path,
    category = test_info.category,
    actual_tests = inspection_result.tests or {},
    metadata = inspection_result.metadata,
    has_run_function = inspection_result.has_run,
    needs_execution = inspection_result.needs_execution,
    validation_issues = validation_issues
  }
  
  return true, nil
end

-- Get accurate test count for a module
function M.get_test_count(module_path)
  local entry = M.registry[module_path]
  if not entry then
    return nil, "Module not inspected"
  end
  
  if entry.inspection_error then
    return nil, entry.inspection_error
  end
  
  -- If this is a test suite that needs execution to determine count
  if entry.needs_execution then
    -- Use last execution results if available
    if entry.last_execution then
      return entry.last_execution.total
    end
    -- Otherwise use metadata count if available
    if entry.metadata and entry.metadata.count then
      return entry.metadata.count
    end
    -- Default to 1 for suite
    return 1
  end
  
  -- Return actual test count
  return #entry.actual_tests
end

-- Get all tests in a category
function M.get_category_tests(category)
  local tests = {}
  
  for module_path, entry in pairs(M.registry) do
    if entry.category == category then
      table.insert(tests, {
        module_path = module_path,
        file_path = entry.file_path,
        actual_tests = entry.actual_tests,
        metadata = entry.metadata,
        inspection_error = entry.inspection_error,
        validation_issues = entry.validation_issues
      })
    end
  end
  
  return tests
end

-- Update execution results
function M.update_execution_results(module_path, results)
  local entry = M.registry[module_path]
  if not entry then
    return
  end
  
  -- Store last execution results
  entry.last_execution = {
    total = results.total or 0,
    passed = results.passed or 0,
    failed = results.failed or 0,
    timestamp = os.time()
  }
  
  -- Track discrepancies
  if entry.metadata and entry.metadata.count and results.total then
    if results.total ~= entry.metadata.count then
      table.insert(entry.validation_issues, {
        type = 'count_mismatch',
        details = string.format("Metadata claims %d tests, execution found %d", 
          entry.metadata.count, results.total)
      })
    end
  end
end

-- Get comprehensive count information
function M.get_comprehensive_counts()
  local counts = {
    by_category = {},
    by_status = {
      inspected = 0,
      error = 0,
      total = 0
    },
    validation_issues = {}
  }
  
  -- Process each registered module
  for module_path, entry in pairs(M.registry) do
    counts.by_status.total = counts.by_status.total + 1
    
    if entry.inspection_error then
      counts.by_status.error = counts.by_status.error + 1
    else
      counts.by_status.inspected = counts.by_status.inspected + 1
    end
    
    -- Category counts
    if not counts.by_category[entry.category] then
      counts.by_category[entry.category] = {
        total = 0,
        errors = {}
      }
    end
    
    local test_count = M.get_test_count(module_path)
    if test_count then
      counts.by_category[entry.category].total = counts.by_category[entry.category].total + test_count
    else
      table.insert(counts.by_category[entry.category].errors, {
        module = module_path,
        error = entry.inspection_error
      })
    end
    
    -- Collect validation issues
    if #entry.validation_issues > 0 then
      table.insert(counts.validation_issues, {
        module = module_path,
        issues = entry.validation_issues
      })
    end
  end
  
  return counts
end

-- Clear the registry (useful for testing)
function M.clear()
  M.registry = {}
end

-- Debug function to print registry state
function M.debug_print()
  print("=== Test Registry State ===")
  for module_path, entry in pairs(M.registry) do
    print(string.format("\nModule: %s", module_path))
    print(string.format("  Category: %s", entry.category))
    print(string.format("  Test Count: %d", #entry.actual_tests))
    if entry.metadata then
      print(string.format("  Metadata Count: %d", entry.metadata.count or 0))
    end
    if entry.inspection_error then
      print(string.format("  ERROR: %s", entry.inspection_error))
    end
    if #entry.validation_issues > 0 then
      print("  Validation Issues:")
      for _, issue in ipairs(entry.validation_issues) do
        print(string.format("    - %s: %s", issue.type, issue.details))
      end
    end
  end
  print("===========================")
end

return M