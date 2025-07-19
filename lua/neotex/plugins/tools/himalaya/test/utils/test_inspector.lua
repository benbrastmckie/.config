-- Test Inspector: Analyzes test modules to determine actual test counts
-- Supports multiple test patterns and validates module structure

local M = {}

-- Inspect a test module to find actual tests
function M.inspect_module(module_path)
  -- Safely load module
  local ok, test_module = pcall(require, module_path)
  if not ok then
    return nil, "Failed to load module: " .. tostring(test_module)
  end
  
  local tests = {}
  local count = 0
  
  -- Pattern 1: Global himalaya_test with suite
  if _G.himalaya_test and type(_G.himalaya_test) == 'table' then
    -- Check if this module set the global
    if _G.himalaya_test.test_metadata and test_module.test_metadata and 
       _G.himalaya_test.test_metadata == test_module.test_metadata then
      -- This is a test suite
      if _G.himalaya_test.tests and type(_G.himalaya_test.tests) == 'table' then
        for i, test in ipairs(_G.himalaya_test.tests) do
          if test.name then
            table.insert(tests, { name = test.name, type = 'suite_test' })
            count = count + 1
          end
        end
      end
      -- Clean up global after inspection
      _G.himalaya_test = nil
    end
  end
  
  -- Pattern 2: M.tests table (unit test pattern)
  if test_module.tests and type(test_module.tests) == 'table' then
    for name, func in pairs(test_module.tests) do
      if type(func) == 'function' and name:match('^test_') then
        -- Avoid double counting if already found in global
        local already_found = false
        for _, test in ipairs(tests) do
          if test.name == name then
            already_found = true
            break
          end
        end
        if not already_found then
          table.insert(tests, { name = name, type = 'function' })
          count = count + 1
        end
      end
    end
  end
  
  -- Pattern 3: Direct test_* functions in module
  for key, value in pairs(test_module) do
    if type(value) == 'function' and key:match('^test_') and key ~= 'test_metadata' then
      -- Avoid double counting
      local already_found = false
      for _, test in ipairs(tests) do
        if test.name == key then
          already_found = true
          break
        end
      end
      if not already_found and (not test_module.tests or not test_module.tests[key]) then
        table.insert(tests, { name = key, type = 'function' })
        count = count + 1
      end
    end
  end
  
  -- Pattern 4: M.run function that returns results (suite pattern)
  if test_module.run and type(test_module.run) == 'function' and count == 0 then
    -- This is a test suite that needs execution to determine count
    return {
      suite = true,
      needs_execution = true,
      metadata = test_module.test_metadata,
      has_run = true
    }
  end
  
  return {
    tests = tests,
    count = count,
    metadata = test_module.test_metadata,
    has_run = test_module.run ~= nil,
    module = test_module
  }
end

-- Validate test module structure
function M.validate_structure(inspection_result)
  local issues = {}
  
  if not inspection_result then
    return issues
  end
  
  local test_module = inspection_result.module
  if not test_module then
    return issues
  end
  
  -- Check metadata accuracy
  if inspection_result.metadata and inspection_result.metadata.count then
    local actual = inspection_result.count or #inspection_result.tests
    if actual ~= inspection_result.metadata.count then
      table.insert(issues, {
        type = 'count_mismatch',
        details = string.format("Metadata claims %d tests, found %d actual tests",
          inspection_result.metadata.count, actual)
      })
    end
  end
  
  -- Check for missing metadata
  if not inspection_result.metadata then
    table.insert(issues, {
      type = 'missing_metadata',
      details = "Test module missing metadata"
    })
  end
  
  -- Check get_test_list accuracy (if it exists)
  if test_module.get_test_list and type(test_module.get_test_list) == 'function' then
    local ok, test_list = pcall(test_module.get_test_list)
    if ok and type(test_list) == 'table' then
      -- Get actual test names
      local actual_names = {}
      for _, test in ipairs(inspection_result.tests or {}) do
        actual_names[test.name] = true
      end
      
      -- Check for mismatches
      local list_count = #test_list
      local actual_count = inspection_result.count or #inspection_result.tests
      
      if list_count ~= actual_count then
        table.insert(issues, {
          type = 'hardcoded_list_mismatch',
          details = string.format("get_test_list() returns %d names but found %d actual tests",
            list_count, actual_count)
        })
      end
      
      -- Check for non-existent tests in the list
      local non_existent = {}
      for _, name in ipairs(test_list) do
        -- The list might have display names, not actual function names
        -- This is a known issue we're fixing
        if #actual_names > 0 and not actual_names[name] then
          table.insert(non_existent, name)
        end
      end
      
      if #non_existent > 0 then
        table.insert(issues, {
          type = 'hardcoded_list_invalid',
          details = string.format("get_test_list() contains non-existent tests: %s",
            table.concat(non_existent, ", "))
        })
      end
    end
  end
  
  return issues
end

-- Count actual tests in a module (helper function)
function M.count_actual_tests(test_module)
  if not test_module then
    return 0
  end
  
  local count = 0
  
  -- Count test functions
  for key, value in pairs(test_module) do
    if type(value) == 'function' and key:match('^test_') and key ~= 'test_metadata' then
      count = count + 1
    end
  end
  
  -- Count tests in M.tests table
  if test_module.tests and type(test_module.tests) == 'table' then
    for name, func in pairs(test_module.tests) do
      if type(func) == 'function' and name:match('^test_') then
        count = count + 1
      end
    end
  end
  
  return count
end

-- Get actual test names from a module
function M.get_actual_test_names(test_module)
  local names = {}
  
  if not test_module then
    return names
  end
  
  -- Get test function names
  for key, value in pairs(test_module) do
    if type(value) == 'function' and key:match('^test_') and key ~= 'test_metadata' then
      table.insert(names, key)
    end
  end
  
  -- Get test names from M.tests table
  if test_module.tests and type(test_module.tests) == 'table' then
    for name, func in pairs(test_module.tests) do
      if type(func) == 'function' and name:match('^test_') then
        -- Avoid duplicates
        local found = false
        for _, existing in ipairs(names) do
          if existing == name then
            found = true
            break
          end
        end
        if not found then
          table.insert(names, name)
        end
      end
    end
  end
  
  return names
end

return M