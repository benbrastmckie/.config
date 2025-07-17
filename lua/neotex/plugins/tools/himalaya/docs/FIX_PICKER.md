# Test Picker Refactor Implementation Plan

## Executive Summary

The test picker currently shows inaccurate test counts (~111 vs actual 261) due to architectural inconsistencies between test structures and counting logic. This document outlines an elegant refactor that standardizes test metadata, improves counting accuracy, and maintains backward compatibility.

## Root Cause Analysis

### Current Test Architecture Problems

1. **Three Different Test Patterns**:
   - **Unit Tests**: `M.tests = { test_name = function() ... }` (works correctly)
   - **Feature/Integration Tests**: `M.run()` + internal test functions (undercounted)
   - **Command Tests**: Framework-based with `_G.himalaya_test` (special case)

2. **Counting vs Execution Mismatch**:
   - **Counting**: Static analysis of module structure
   - **Execution**: Dynamic execution with structured results
   - **Result**: Double counting, missed tests, inconsistent results

3. **Missing Test Metadata**:
   - No standard way to declare test count
   - No way to introspect complex test structures
   - No validation of counting accuracy

### Additional Context from Test Suite Analysis

4. **Test Environment Considerations**:
   - Tests run in both interactive (`:HimalayaTest`) and headless (`dev_cli.lua`) modes
   - Test isolation system requires proper cleanup and state management
   - Global test mode flags (`_G.HIMALAYA_TEST_MODE`) affect behavior

5. **Current Test Count Discrepancy**:
   - README.md states "Total Tests: 196 tests" but picker shows ~111
   - Actual execution shows 261 tests
   - This suggests multiple counting systems with different results

6. **Test Framework Integration**:
   - Existing test framework in `utils/test_framework.lua` has established patterns
   - Notification system integration requires special handling
   - CLI command mocking is essential for test isolation

## Proposed Solution: Test Metadata Standardization

### 1. Core Principle: Explicit Test Metadata

Every test module will declare its test count explicitly:

```lua
-- Standard metadata for all test modules
M.test_metadata = {
  name = "Cache System Tests",
  description = "Tests for email caching with TTL",
  count = 8,                    -- Total number of individual tests
  category = "unit",            -- unit, feature, integration, command, performance
  tags = {"cache", "storage"},  -- Optional tags for filtering
  dependencies = {"maildir"},   -- Optional dependencies
  estimated_duration_ms = 500   -- Optional performance hint
}
```

### 2. Standardized Test Interface

All test modules will implement this interface:

```lua
-- Required functions for all test modules
M.get_test_count = function()
  return M.test_metadata.count
end

M.get_test_list = function()
  -- Returns list of individual test names (for display)
  return {
    "Cache store and retrieve",
    "Cache TTL expiration",
    "Cache multiple emails",
    -- ... etc
  }
end

M.run = function()
  -- Standardized execution with consistent result format
  return {
    total = M.test_metadata.count,
    passed = passed_count,
    failed = failed_count,
    errors = error_list,
    success = failed_count == 0,
    details = test_details
  }
end
```

### 3. Backward Compatibility Strategy

The refactor will maintain full backward compatibility:

```lua
-- Adapter for existing unit tests
local function adapt_unit_test(test_module)
  if test_module.tests and not test_module.test_metadata then
    -- Auto-generate metadata for existing unit tests
    local count = 0
    local test_names = {}
    for name, _ in pairs(test_module.tests) do
      count = count + 1
      table.insert(test_names, name:gsub("^test_", ""):gsub("_", " "))
    end
    
    test_module.test_metadata = {
      name = "Legacy Unit Tests",
      count = count,
      category = "unit",
      auto_generated = true
    }
    
    test_module.get_test_count = function() return count end
    test_module.get_test_list = function() return test_names end
  end
end
```

### 4. Test Environment Compatibility

The refactor must preserve existing test infrastructure:

- **Interactive mode**: `:HimalayaTest` command and picker interface
- **Headless mode**: `dev_cli.lua` for CI/CD and TDD workflows
- **Test isolation**: Existing isolation system in `utils/test_isolation.lua`
- **Framework integration**: Compatibility with `utils/test_framework.lua`
- **Notification handling**: Respect existing notification suppression patterns
- **CLI mocking**: Preserve `_G.HIMALAYA_TEST_MODE` behavior

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1)

#### 1.1 Create Test Metadata Framework

**File**: `lua/neotex/plugins/tools/himalaya/test/utils/test_metadata.lua`

```lua
local M = {}

-- Validate test metadata structure
M.validate_metadata = function(metadata)
  local required_fields = {"name", "count", "category"}
  for _, field in ipairs(required_fields) do
    if not metadata[field] then
      error(string.format("Missing required field: %s", field))
    end
  end
  
  if type(metadata.count) ~= "number" or metadata.count < 0 then
    error("count must be a non-negative number")
  end
  
  local valid_categories = {"unit", "feature", "integration", "command", "performance"}
  if not vim.tbl_contains(valid_categories, metadata.category) then
    error(string.format("Invalid category: %s", metadata.category))
  end
  
  return true
end

-- Create standardized test interface
M.create_test_interface = function(metadata, test_functions)
  M.validate_metadata(metadata)
  
  return {
    test_metadata = metadata,
    get_test_count = function() return metadata.count end,
    get_test_list = function()
      local names = {}
      for name, _ in pairs(test_functions) do
        table.insert(names, name:gsub("^test_", ""):gsub("_", " "))
      end
      return names
    end,
    run = function()
      -- Execute tests and return standardized results
      local results = {
        total = metadata.count,
        passed = 0,
        failed = 0,
        errors = {},
        success = false,
        details = {}
      }
      
      for name, func in pairs(test_functions) do
        local ok, err = pcall(func)
        if ok then
          results.passed = results.passed + 1
        else
          results.failed = results.failed + 1
          table.insert(results.errors, {
            test = name,
            error = tostring(err)
          })
        end
      end
      
      results.success = results.failed == 0
      return results
    end
  }
end

return M
```

#### 1.2 Create Backward Compatibility Layer

**File**: `lua/neotex/plugins/tools/himalaya/test/utils/test_adapter.lua`

```lua
local M = {}
local metadata_utils = require('neotex.plugins.tools.himalaya.test.utils.test_metadata')

-- Adapt existing unit tests
M.adapt_unit_test = function(test_module)
  if test_module.tests and not test_module.test_metadata then
    local count = 0
    local test_names = {}
    
    for name, _ in pairs(test_module.tests) do
      count = count + 1
      table.insert(test_names, name:gsub("^test_", ""):gsub("_", " "))
    end
    
    test_module.test_metadata = {
      name = test_module.name or "Legacy Unit Tests",
      count = count,
      category = "unit",
      auto_generated = true
    }
    
    test_module.get_test_count = function() return count end
    test_module.get_test_list = function() return test_names end
    
    -- Preserve existing run function if it exists
    if not test_module.run then
      test_module.run = function()
        local results = {
          total = count,
          passed = 0,
          failed = 0,
          errors = {},
          success = false,
          details = {}
        }
        
        for name, func in pairs(test_module.tests) do
          local ok, err = pcall(func)
          if ok then
            results.passed = results.passed + 1
          else
            results.failed = results.failed + 1
            table.insert(results.errors, {
              test = name,
              error = tostring(err)
            })
          end
        end
        
        results.success = results.failed == 0
        return results
      end
    end
  end
  
  return test_module
end

-- Adapt existing feature/integration tests
M.adapt_complex_test = function(test_module, estimated_count)
  if not test_module.test_metadata then
    -- Try to determine test count from module structure
    local count = estimated_count or 1
    
    -- Look for test_ functions
    local test_functions = {}
    for name, value in pairs(test_module) do
      if type(value) == "function" and name:match("^test_") then
        table.insert(test_functions, name)
      end
    end
    
    if #test_functions > 0 then
      count = #test_functions
    end
    
    test_module.test_metadata = {
      name = test_module.name or "Legacy Complex Tests",
      count = count,
      category = "feature", -- Default category
      auto_generated = true,
      estimated = true -- Mark as estimated
    }
    
    test_module.get_test_count = function() return count end
    test_module.get_test_list = function()
      local names = {}
      for _, name in ipairs(test_functions) do
        table.insert(names, name:gsub("^test_", ""):gsub("_", " "))
      end
      return names
    end
  end
  
  return test_module
end

return M
```

#### 1.3 Update Test Runner Discovery

**File**: `lua/neotex/plugins/tools/himalaya/test/test_runner.lua` (lines 846-907)

```lua
-- Enhanced test counting with metadata support
function M.count_test_functions_in_category(category)
  local count = 0
  local adapter = require('neotex.plugins.tools.himalaya.test.utils.test_adapter')
  
  if not M.tests[category] then
    return 0
  end
  
  for _, test_info in ipairs(M.tests[category]) do
    local success, test_module = pcall(require, test_info.module_path)
    if success then
      -- Ensure module has standardized interface
      if test_module.tests and not test_module.test_metadata then
        test_module = adapter.adapt_unit_test(test_module)
      elseif test_module.run and not test_module.test_metadata then
        test_module = adapter.adapt_complex_test(test_module)
      end
      
      -- Use standardized interface
      if test_module.get_test_count then
        count = count + test_module.get_test_count()
      else
        -- Final fallback
        count = count + 1
      end
    else
      -- Module loading failed
      count = count + 1
    end
  end
  
  return count
end

-- Remove the estimate_test_count function (no longer needed)
-- The adapter layer handles all estimation

-- Enhanced count_all_test_functions with validation
function M.count_all_test_functions()
  local total = 0
  local validation_errors = {}
  
  for category, _ in pairs(M.tests) do
    local category_count = M.count_test_functions_in_category(category)
    total = total + category_count
    
    -- Optional: Add validation to catch discrepancies
    if M.config.validate_counts then
      local actual_count = M.validate_category_count(category)
      if actual_count ~= category_count then
        table.insert(validation_errors, {
          category = category,
          expected = category_count,
          actual = actual_count
        })
      end
    end
  end
  
  -- Report validation errors if any
  if #validation_errors > 0 and not _G.HIMALAYA_TEST_MODE then
    local notify = require('neotex.util.notifications')
    notify.himalaya("Test count validation failed", notify.categories.ERROR)
  end
  
  return total
end
```

### Phase 2: Gradual Migration (Week 2-3)

#### 2.1 Migrate Unit Tests

For each unit test file, add metadata at the top:

```lua
-- Example: test_cache.lua
local M = {}

-- Add test metadata
M.test_metadata = {
  name = "Email Cache Tests",
  description = "Tests for email caching with TTL and normalization",
  count = 8,
  category = "unit",
  tags = {"cache", "storage", "ttl"},
  estimated_duration_ms = 500
}

-- Existing tests table remains unchanged
M.tests = {
  test_cache_store_and_retrieve_email = function() ... end,
  test_cache_ttl_expiration = function() ... end,
  -- ... (existing tests)
}

-- Add standardized interface
M.get_test_count = function() return M.test_metadata.count end
M.get_test_list = function()
  local names = {}
  for name, _ in pairs(M.tests) do
    table.insert(names, name:gsub("^test_", ""):gsub("_", " "))
  end
  return names
end

-- Existing run function can be preserved or updated
```

#### 2.2 Migrate Feature/Integration Tests

```lua
-- Example: test_maildir_integration.lua
local M = {}

-- Add explicit metadata
M.test_metadata = {
  name = "Maildir Integration Tests",
  description = "Comprehensive tests for complete Maildir draft system",
  count = 32, -- Explicitly declare the 32 tests this actually runs
  category = "integration",
  tags = {"maildir", "integration", "drafts"},
  estimated_duration_ms = 2000
}

-- Existing test functions remain unchanged
function M.test_foundation() ... end
function M.test_draft_manager() ... end
function M.test_composer() ... end
function M.test_integration() ... end

-- Add standardized interface
M.get_test_count = function() return M.test_metadata.count end
M.get_test_list = function()
  return {
    "Foundation Tests (8 tests)",
    "Draft Manager Tests (8 tests)",
    "Composer Tests (8 tests)",
    "Integration Tests (8 tests)"
  }
end

-- Existing run function remains unchanged
function M.run() ... end
```

#### 2.3 Update Test Runner Execution

**File**: `lua/neotex/plugins/tools/himalaya/test/test_runner.lua` (lines 465-620)

```lua
-- Enhanced test execution with metadata validation
function M.run_test(test_info)
  local adapter = require('neotex.plugins.tools.himalaya.test.utils.test_adapter')
  
  -- Clear module cache
  package.loaded[test_info.module_path] = nil
  
  -- Load test module
  local ok, test_module = pcall(require, test_info.module_path)
  if not ok then
    ok, test_module = pcall(dofile, test_info.path)
  end
  
  if not ok or not test_module then
    M.results.total = M.results.total + 1
    M.results.failed = M.results.failed + 1
    table.insert(M.results.errors, {
      test = test_info.name,
      category = test_info.category,
      type = 'error',
      message = 'Failed to load test module: ' .. tostring(test_module)
    })
    return
  end
  
  -- Ensure standardized interface
  if test_module.tests and not test_module.test_metadata then
    test_module = adapter.adapt_unit_test(test_module)
  elseif test_module.run and not test_module.test_metadata then
    test_module = adapter.adapt_complex_test(test_module)
  end
  
  -- Setup test environment
  if test_module.setup then
    pcall(test_module.setup)
  end
  
  -- Execute tests using standardized interface
  local expected_count = test_module.get_test_count and test_module.get_test_count() or 1
  
  if test_module.run then
    local success, result = pcall(test_module.run)
    
    if success and type(result) == 'table' then
      -- Validate result structure
      local total = result.total or expected_count
      local passed = result.passed or 0
      local failed = result.failed or 0
      
      -- Validate counts match expectations
      if total ~= expected_count then
        if not _G.HIMALAYA_TEST_MODE then
          local notify = require('neotex.util.notifications')
          notify.himalaya(
            string.format("Test count mismatch in %s: expected %d, got %d",
              test_info.name, expected_count, total),
            notify.categories.ERROR
          )
        end
      end
      
      -- Update results
      M.results.total = M.results.total + total
      M.results.passed = M.results.passed + passed
      M.results.failed = M.results.failed + failed
      
      -- Add errors
      if result.errors then
        for _, error in ipairs(result.errors) do
          table.insert(M.results.errors, {
            test = test_info.name .. ':' .. error.test,
            category = test_info.category,
            type = 'failed',
            message = error.error or error.message
          })
        end
      end
    else
      -- Legacy handling for simple pass/fail
      M.results.total = M.results.total + 1
      if success and result ~= false then
        M.results.passed = M.results.passed + 1
      else
        M.results.failed = M.results.failed + 1
        table.insert(M.results.errors, {
          test = test_info.name,
          category = test_info.category,
          type = 'failed',
          message = success and 'Test returned false' or tostring(result)
        })
      end
    end
  else
    -- No run function - this should not happen with adapted modules
    M.results.total = M.results.total + 1
    M.results.failed = M.results.failed + 1
    table.insert(M.results.errors, {
      test = test_info.name,
      category = test_info.category,
      type = 'error',
      message = 'No run function found'
    })
  end
  
  -- Teardown
  if test_module.teardown then
    pcall(test_module.teardown)
  end
end
```

### Phase 3: Enhanced Picker Interface (Week 4)

#### 3.1 Improved Picker Display

**File**: `lua/neotex/plugins/tools/himalaya/test/test_runner.lua` (lines 159-312)

```lua
-- Enhanced picker with metadata support
function M.run_with_picker(filter)
  -- ... existing filter logic ...
  
  -- Create enhanced menu structure with metadata
  local items = {}
  
  -- Count total tests with validation
  local total_tests, validation_info = M.count_all_tests_with_validation()
  
  -- Add main options with validation indicators
  local all_tests_text = string.format('Run All Tests (%d tests)', total_tests)
  if validation_info.has_estimates then
    all_tests_text = all_tests_text .. ' ~'
  end
  
  table.insert(items, { 
    text = all_tests_text, 
    value = 'all', 
    icon = '=�',
    metadata = validation_info
  })
  
  table.insert(items, { text = '                         ', value = nil, icon = '' })
  
  -- Create enhanced categories with metadata
  local categories = M.build_enhanced_categories()
  
  for _, cat in ipairs(categories) do
    local count_info = M.get_category_count_info(cat)
    local display_text = string.format('%s (%d tests)', cat.name, count_info.total)
    
    -- Add indicators for estimation vs explicit counts
    if count_info.estimated > 0 then
      display_text = display_text .. string.format(' [%d estimated]', count_info.estimated)
    end
    
    table.insert(items, {
      text = display_text,
      value = cat,
      icon = cat.icon,
      metadata = count_info
    })
  end
  
  -- ... rest of picker logic ...
end

-- Enhanced category building with metadata
function M.build_enhanced_categories()
  local categories = {
    {
      name = 'Core Data & Storage',
      icon = '=�',
      desc = 'Cache, drafts, maildir, search, templates',
      tests = {
        { category = 'unit', pattern = 'test_cache' },
        { category = 'unit', pattern = 'test_drafts' },
        { category = 'unit', pattern = 'test_maildir' },
        { category = 'unit', pattern = 'test_search' },
        { category = 'unit', pattern = 'test_templates' },
        { category = 'features', pattern = 'test_maildir_foundation' },
        { category = 'features', pattern = 'test_maildir_integration' },
      }
    },
    -- ... other categories ...
  }
  
  return categories
end

-- Get detailed count information for a category
function M.get_category_count_info(category)
  local total = 0
  local explicit = 0
  local estimated = 0
  local auto_generated = 0
  
  for _, test_spec in ipairs(category.tests) do
    if M.tests[test_spec.category] then
      for _, test_info in ipairs(M.tests[test_spec.category]) do
        if test_info.name:match(test_spec.pattern) then
          local success, test_module = pcall(require, test_info.module_path)
          if success and test_module.test_metadata then
            total = total + test_module.test_metadata.count
            
            if test_module.test_metadata.estimated then
              estimated = estimated + test_module.test_metadata.count
            else
              explicit = explicit + test_module.test_metadata.count
            end
            
            if test_module.test_metadata.auto_generated then
              auto_generated = auto_generated + 1
            end
          else
            total = total + 1
            estimated = estimated + 1
          end
        end
      end
    end
  end
  
  return {
    total = total,
    explicit = explicit,
    estimated = estimated,
    auto_generated = auto_generated
  }
end

-- Enhanced count validation
function M.count_all_tests_with_validation()
  local total = 0
  local validation_info = {
    has_estimates = false,
    auto_generated = 0,
    validation_errors = {}
  }
  
  for category, _ in pairs(M.tests) do
    local category_info = M.get_category_detailed_info(category)
    total = total + category_info.total
    
    if category_info.estimated > 0 then
      validation_info.has_estimates = true
    end
    
    validation_info.auto_generated = validation_info.auto_generated + category_info.auto_generated
    
    for _, error in ipairs(category_info.validation_errors) do
      table.insert(validation_info.validation_errors, error)
    end
  end
  
  return total, validation_info
end
```

#### 3.2 Validation and Debugging Tools

**File**: `lua/neotex/plugins/tools/himalaya/test/utils/test_validation.lua`

```lua
local M = {}

-- Validate test count accuracy by running a quick test
M.validate_test_count = function(test_module, expected_count)
  if not test_module.run then
    return false, "No run function"
  end
  
  -- Run test in validation mode
  local old_mode = _G.HIMALAYA_TEST_MODE
  _G.HIMALAYA_TEST_MODE = true
  _G.HIMALAYA_TEST_VALIDATION = true
  
  local success, result = pcall(test_module.run)
  
  _G.HIMALAYA_TEST_MODE = old_mode
  _G.HIMALAYA_TEST_VALIDATION = false
  
  if not success then
    return false, "Test execution failed: " .. tostring(result)
  end
  
  if not result or type(result) ~= 'table' then
    return false, "Invalid result structure"
  end
  
  local actual_count = result.total or 0
  if actual_count ~= expected_count then
    return false, string.format("Count mismatch: expected %d, got %d", expected_count, actual_count)
  end
  
  return true, "Validation passed"
end

-- Generate count validation report
M.generate_validation_report = function()
  local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
  test_runner.discover_tests()
  
  local report = {
    "# Test Count Validation Report",
    "",
    string.format("Generated: %s", os.date('%Y-%m-%d %H:%M:%S')),
    ""
  }
  
  local total_tests = 0
  local total_validated = 0
  local total_errors = 0
  
  for category, tests in pairs(test_runner.tests) do
    table.insert(report, string.format("## %s Tests", category:upper()))
    table.insert(report, "")
    
    for _, test_info in ipairs(tests) do
      local success, test_module = pcall(require, test_info.module_path)
      if success and test_module.test_metadata then
        local expected = test_module.test_metadata.count
        local valid, message = M.validate_test_count(test_module, expected)
        
        total_tests = total_tests + 1
        
        if valid then
          total_validated = total_validated + 1
          table.insert(report, string.format("-  %s: %d tests", test_info.name, expected))
        else
          total_errors = total_errors + 1
          table.insert(report, string.format("- L %s: %d tests - %s", test_info.name, expected, message))
        end
      else
        total_errors = total_errors + 1
        table.insert(report, string.format("- �  %s: No metadata", test_info.name))
      end
    end
    
    table.insert(report, "")
  end
  
  -- Summary
  table.insert(report, "## Summary")
  table.insert(report, "")
  table.insert(report, string.format("- Total test modules: %d", total_tests))
  table.insert(report, string.format("- Validated: %d", total_validated))
  table.insert(report, string.format("- Errors: %d", total_errors))
  table.insert(report, string.format("- Success rate: %.1f%%", (total_validated / total_tests) * 100))
  
  return table.concat(report, '\n')
end

return M
```

### Phase 4: Migration Verification (Week 5)

#### 4.1 Add Validation Commands

**File**: `lua/neotex/plugins/tools/himalaya/commands/test_validation.lua`

```lua
local M = {}

-- Command to validate test counts
M.validate_test_counts = function()
  local validation = require('neotex.plugins.tools.himalaya.test.utils.test_validation')
  local report = validation.generate_validation_report()
  
  -- Show in floating window
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  float.show('Test Count Validation', vim.split(report, '\n'))
end

-- Command to run count validation and show discrepancies
M.debug_test_counts = function()
  local test_runner = require('neotex.plugins.tools.himalaya.test.test_runner')
  test_runner.discover_tests()
  
  local discrepancies = {}
  local total_picker_count = 0
  local total_execution_count = 0
  
  for category, tests in pairs(test_runner.tests) do
    local picker_count = test_runner.count_test_functions_in_category(category)
    local execution_count = 0
    
    -- Run tests to get actual count
    for _, test_info in ipairs(tests) do
      local success, test_module = pcall(require, test_info.module_path)
      if success and test_module.run then
        local test_result = test_module.run()
        execution_count = execution_count + (test_result.total or 1)
      else
        execution_count = execution_count + 1
      end
    end
    
    total_picker_count = total_picker_count + picker_count
    total_execution_count = total_execution_count + execution_count
    
    if picker_count ~= execution_count then
      table.insert(discrepancies, {
        category = category,
        picker = picker_count,
        execution = execution_count,
        diff = execution_count - picker_count
      })
    end
  end
  
  -- Generate report
  local lines = {
    "# Test Count Discrepancy Report",
    "",
    string.format("Total Picker Count: %d", total_picker_count),
    string.format("Total Execution Count: %d", total_execution_count),
    string.format("Overall Discrepancy: %d", total_execution_count - total_picker_count),
    ""
  }
  
  if #discrepancies > 0 then
    table.insert(lines, "## Discrepancies by Category")
    table.insert(lines, "")
    
    for _, disc in ipairs(discrepancies) do
      table.insert(lines, string.format("- %s: Picker=%d, Execution=%d, Diff=%+d",
        disc.category, disc.picker, disc.execution, disc.diff))
    end
  else
    table.insert(lines, "## No discrepancies found! <�")
  end
  
  local float = require('neotex.plugins.tools.himalaya.ui.float')
  float.show('Test Count Debug', lines)
end

return M
```

#### 4.2 Add Vim Commands

**File**: `lua/neotex/plugins/tools/himalaya/init.lua` (add to existing commands)

```lua
-- Add validation commands
vim.api.nvim_create_user_command('HimalayaTestValidate', function()
  local validation = require('neotex.plugins.tools.himalaya.commands.test_validation')
  validation.validate_test_counts()
end, {
  desc = 'Validate test count accuracy'
})

vim.api.nvim_create_user_command('HimalayaTestDebug', function()
  local validation = require('neotex.plugins.tools.himalaya.commands.test_validation')
  validation.debug_test_counts()
end, {
  desc = 'Debug test count discrepancies'
})
```

## Migration Timeline

### Week 1: Core Infrastructure
- [ ] Create test metadata framework
- [ ] Create backward compatibility layer
- [ ] Update test runner discovery logic
- [ ] Add validation utilities

### Week 2: Unit Test Migration
- [ ] Migrate all unit tests (17 files)
- [ ] Add metadata to each unit test
- [ ] Validate count accuracy
- [ ] Fix any discrepancies

### Week 3: Feature/Integration Test Migration
- [ ] Migrate all feature tests (8 files)
- [ ] Migrate all integration tests (4 files)
- [ ] Add explicit count metadata
- [ ] Validate complex test structures

### Week 4: Picker Enhancement
- [ ] Update picker interface
- [ ] Add validation indicators
- [ ] Improve error handling
- [ ] Add debugging tools

### Week 5: Validation and Cleanup
- [ ] Run comprehensive validation
- [ ] Fix any remaining issues
- [ ] Add documentation
- [ ] Remove legacy code

## Success Metrics

1. **Count Accuracy**: Picker shows exactly 261 tests matching execution (resolving 196 vs 111 vs 261 discrepancy)
2. **No Regressions**: All tests still pass after migration in both interactive and headless modes
3. **Improved UX**: Picker shows detailed, accurate information with validation indicators
4. **Maintainability**: Consistent pattern across all test types
5. **Backward Compatibility**: No breaking changes to existing tests, dev_cli.lua, or :HimalayaTest
6. **Test Environment Integrity**: Preserves test isolation, CLI mocking, and notification handling
7. **Documentation Consistency**: Updates README.md to reflect accurate test counts

## Benefits

1. **Immediate**: Accurate test counts in picker
2. **Short-term**: Better test organization and debugging
3. **Long-term**: Consistent test architecture for future development
4. **Maintenance**: Clear validation tools to prevent regressions

## Risk Mitigation

1. **Backward Compatibility**: Adapter layer ensures no breaking changes to existing test files, CLI, or interactive modes
2. **Gradual Migration**: Phased approach allows for incremental validation without disrupting current workflows
3. **Validation Tools**: Built-in validation prevents count drift and catches discrepancies early
4. **Test Environment Preservation**: Maintains existing test isolation, CLI mocking, and notification patterns
5. **Documentation**: Clear migration guide for future tests and updated README.md files
6. **Rollback Strategy**: Adapter layer allows reverting to original behavior if issues arise
7. **CI/CD Compatibility**: Ensures headless mode (`dev_cli.lua`) continues working with exit codes

## Additional Considerations from Test Suite Analysis

### Test Mode Flag Timing
The refactor must preserve the critical timing of `_G.HIMALAYA_TEST_MODE` flag setting:
- Set before any config initialization
- Passed through all validation calls
- Respected by CLI mocking and notification systems

### Notification System Integration
The metadata system must work with existing notification categories:
- ERROR/WARNING: Always shown (unless test_validation = true)
- STATUS/BACKGROUND: Suppressed in test mode
- Validation indicators should use appropriate categories

### Multi-Mode Compatibility
The refactor must work seamlessly in:
- Interactive mode (`:HimalayaTest` with floating windows)
- Headless mode (`dev_cli.lua` with stdout output)
- Direct file execution (individual test files)

### Performance Test Considerations
Performance tests require special handling:
- Timing-sensitive operations
- Resource usage monitoring
- Regression detection

This refactor elegantly solves the counting problem while improving the overall test architecture and maintaining full backward compatibility with all existing test infrastructure.