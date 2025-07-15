# Himalaya Test Suite

Comprehensive testing infrastructure for the Himalaya email plugin.

## Overview

This directory contains all tests for the Himalaya plugin, organized by test type and scope. The test suite provides reliable validation of plugin functionality with comprehensive coverage and automated test execution.

## Test Runner

The test runner (`test_runner.lua`) provides a unified interface for discovering, executing, and reporting test results.

### Running Tests

```vim
" Run all tests
:HimalayaTest

" Run specific category
:HimalayaTest commands
:HimalayaTest features
:HimalayaTest integration
:HimalayaTest performance

" Run specific test
:HimalayaTest test_maildir_foundation
```

### Test Runner Features

- **Automatic Discovery**: Finds all test files matching `test_*.lua` pattern
- **Flexible Execution**: Run all tests, by category, or individually
- **Mock Support**: Prevents real Himalaya CLI calls during testing
- **Result Reporting**: Detailed markdown reports with pass/fail statistics
- **Performance Tracking**: Duration measurements for all tests
- **Error Details**: Complete error messages and stack traces for failures

## Test Organization

### commands/
Tests for all Himalaya commands and their integration with Neovim.

**Current Tests:**
- `test_basic_commands.lua` - Core command functionality, config validation
- `test_email_commands.lua` - Email manipulation commands
- `test_sync_commands.lua` - Synchronization command tests

**Status**: ✅ Up to date and passing

### features/
Tests for specific feature implementations and modules.

**Current Tests:**
- `test_maildir_foundation.lua` - Core Maildir functionality (filename generation, parsing, atomic writes)
- `test_maildir_integration.lua` - Comprehensive Maildir integration tests
- `test_draft_manager_maildir.lua` - Draft management (create, save, list, delete)
- `test_email_composer_maildir.lua` - Email composer functionality
- `test_draft_saving.lua` - Draft saving workflows
- `test_scheduler.lua` - Scheduler functionality

**Status**: ✅ Consolidated and passing

### integration/
End-to-end tests that verify complete workflows.

**Current Tests:**
- `test_full_workflow.lua` - Complete email workflow tests

**Status**: ✅ Working

### performance/
Performance benchmarks and stress tests.

**Current Tests:**
- `test_search_speed.lua` - Email search performance

**Status**: ✅ Working

### utils/
Testing utilities and mock implementations.

**Current Utilities:**
- `test_mocks.lua` - Mock implementations for CLI calls
- `test_framework.lua` - Test helper functions and assertion library
- `mock_data.lua` - Sample data for testing
- `test_search.lua` - Search utilities for tests

**Status**: ✅ Complete and functional

## Test Status

### Overall Status: ✅ 100% Pass Rate

The test suite has been fully consolidated and optimized, achieving 100% pass rate across all categories:

- **Commands**: All tests passing
- **Features**: All tests passing  
- **Integration**: All tests passing
- **Performance**: All tests passing

### Recent Improvements (Phase 2)

1. **Test Infrastructure Enhancements**
   - Enhanced test assertions with more specific checks
   - Added better error reporting in test failures
   - Improved test setup/teardown consistency
   - Added test timing and performance metrics
   - Standardized test naming conventions

2. **Test Quality Improvements**
   - Added edge case testing for all modules
   - Enhanced error condition testing
   - Created test utilities for common patterns
   - Added test data factories and fixtures
   - Added test categorization and filtering
   - Created performance benchmarking tests

3. **Infrastructure Fixes**
   - Fixed buffer cleanup issues (test buffers now properly closed)
   - Fixed mode normalization (no longer leaves cursor in insert mode)
   - Fixed "Account configuration not found" notification during tests
   - Improved test names in :HimalayaTest picker
   - Disabled auto-sync during test execution

### Historical Issues (Resolved)

These issues were encountered and resolved during test infrastructure development:

1. **Module Path Issues** - Fixed imports from `scripts.utils.*` to `test.utils.*`
2. **Draft System Incompatibilities** - Migrated to new maildir-based draft system
3. **Config Initialization** - Ensured proper config setup in test environment
4. **Maildir Tests** - Fixed parsing, atomic writes, and filtering issues

## Test Writing Standards

### Test Structure

Each test file should follow this structure:

```lua
-- Test Description
-- Brief description of what this test file covers

local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local assert = framework.assert
local helpers = framework.helpers

-- Module under test
local module = require('neotex.plugins.tools.himalaya.module.name')

-- Test results tracking
local M = {}
M.test_results = {}

-- Helper function for reporting
local function report_test(name, success, error_info, context)
  local result = framework.create_test_result(name, success, error_info, context)
  table.insert(M.test_results, result)
  return result
end

-- Individual test functions
function M.test_feature_name()
  local test_name = 'Feature description'
  
  -- Test implementation
  local success, result = pcall(function()
    -- Test logic here
    assert.equals(actual, expected, 'Error message')
  end)
  
  report_test(test_name, success, result)
  return success
end

-- Run function
function M.run()
  M.test_results = {}
  
  -- Run all tests
  M.test_feature_name()
  
  -- Return aggregate results
  return {
    passed = passed_count,
    failed = failed_count,
    total = total_count,
    errors = errors_array
  }
end

return M
```

### Best Practices

1. **Use Test Environment**: Always use `framework.helpers.create_test_env()` for tests that need configuration
2. **Clean Up Resources**: Always clean up test environments and buffers
3. **Mock External Calls**: Never make real Himalaya CLI calls in tests
4. **Descriptive Names**: Use clear, descriptive test names that explain what is being tested
5. **Edge Cases**: Include tests for error conditions and edge cases
6. **Performance**: Add timing assertions for performance-critical code

### Common Patterns

#### Testing with Environment
```lua
local env = helpers.create_test_env()
-- Test code here
helpers.cleanup_test_env(env)
```

#### Mocking CLI Calls
```lua
local original = utils.execute_himalaya
utils.execute_himalaya = mock.himalaya_cli({ 
  list = { success = true, data = test_emails }
})
-- Test code
utils.execute_himalaya = original
```

#### Testing Async Operations
```lua
helpers.wait_for(function()
  return condition_met
end, timeout_ms)
```

### Test Coverage

- ✅ **Maildir Operations**: Complete coverage of file operations, parsing, and structure
- ✅ **Draft Management**: Full lifecycle testing (create, save, list, delete, migration)
- ✅ **Email Composition**: Complete composer functionality testing
- ✅ **Command Interface**: All user-facing commands tested
- ✅ **Configuration**: Config validation and setup testing
- ✅ **Integration**: End-to-end workflow validation

## Writing Tests

### Test Structure

Each test file should follow this pattern:

```lua
-- Test Description
-- What this test validates

local M = {}

-- Dependencies
local module_under_test = require('neotex.plugins.tools.himalaya.module')
local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')

-- Test setup (optional)
function M.setup()
  -- Initialize test environment
end

-- Test teardown (optional)
function M.teardown()
  -- Clean up test environment
end

-- Individual test functions (prefix with test_)
function M.test_feature_one()
  -- Test implementation
  -- Return true for pass, false for fail
  -- Or throw error with details
end

-- Main run function (returns structured results)
function M.run()
  local results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {},
    success = false
  }
  
  -- Run all test_ functions
  -- Update results
  
  return results
end

return M
```

### Best Practices

1. **Isolation**: Tests should not depend on external state
2. **Mocking**: Use test_mocks to prevent real CLI calls
3. **Cleanup**: Always clean up temporary files/state
4. **Clear Names**: Test names should describe what they validate
5. **Fast Execution**: Keep individual tests under 100ms
6. **Deterministic**: Tests should produce consistent results
7. **Structured Results**: Return proper result objects, don't print to console

## Command Integration

The following commands have been updated to use the consolidated test suite:

- `HimalayaTest` - Main test runner (recommended)
- `HimalayaTestMaildir` - Maildir foundation tests
- `HimalayaTestDraftManager` - Draft manager tests
- `HimalayaTestEmailComposer` - Email composer tests
- `HimalayaTestMaildirIntegration` - Integration tests

**Deprecated Commands**: The following commands now redirect to `:HimalayaTest`:
- `HimalayaTestCommands`
- `HimalayaTestPhase8`
- `HimalayaTestPhase9`
- `HimalayaDemoPhase8`
- `HimalayaDemoPhase9`

## Debugging Tests

### Running Individual Tests

```lua
-- In Neovim
:lua require('neotex.plugins.tools.himalaya.test.features.test_maildir_foundation').run()
```

### Verbose Output

```lua
-- Enable debug notifications
:lua require('neotex.plugins.tools.himalaya.test.test_runner').config.debug_notifications = true
```

### Manual Test Execution

```lua
-- Load and run specific test
:lua dofile(vim.fn.stdpath('config') .. '/lua/neotex/plugins/tools/himalaya/test/features/test_maildir_foundation.lua')
```

## Contributing

When adding new tests:

1. Follow the established structure
2. Update this README with test descriptions
3. Ensure tests are fast and deterministic
4. Add appropriate mocks for external calls
5. Document any special requirements
6. Return structured results instead of printing to console

## Navigation

- [🏠 Himalaya Plugin](../README.md)
- [📝 Commands Tests](commands/README.md)
- [✨ Features Tests](features/README.md)
- [🔗 Integration Tests](integration/README.md)
- [⚡ Performance Tests](performance/README.md)
- [🛠️ Test Utilities](utils/README.md)