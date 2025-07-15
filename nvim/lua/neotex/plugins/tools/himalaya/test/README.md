# Himalaya Test Suite

Comprehensive testing infrastructure for the Himalaya email plugin.

## Overview

This directory contains all tests for the Himalaya plugin, organized by test type and scope. The test suite is designed to ensure reliability, performance, and maintainability of the plugin while following the development guidelines in [docs/GUIDELINES.md](../docs/GUIDELINES.md).

## Test Runner

The test runner (`test_runner.lua`) provides a unified interface for discovering, executing, and reporting test results. It supports both Telescope-based and simple picker interfaces for test selection.

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
- `test_basic_commands.lua` - Core command functionality
- `test_email_commands.lua` - Email manipulation commands
- `test_sync_commands.lua` - Synchronization command tests

**Status**: † Need updates for current command structure

### features/
Tests for specific feature implementations and modules.

**Current Tests:**
- `test_maildir_foundation.lua` - Core Maildir functionality 
- `test_maildir_integration.lua` - Maildir integration tests 
- `test_draft_manager_maildir.lua` - Draft management tests 
- `test_email_composer_maildir.lua` - Email composer tests 
- `test_scheduler.lua` - Scheduler functionality
- Various draft-related tests (need consolidation)

**Status**: = Partially updated, draft tests need consolidation

### integration/
End-to-end tests that verify complete workflows.

**Current Tests:**
- `test_full_workflow.lua` - Complete email workflow tests

**Status**: † Needs update for current architecture

### performance/
Performance benchmarks and stress tests.

**Current Tests:**
- `test_search_speed.lua` - Email search performance

**Status**: † Needs implementation with current search

### utils/
Testing utilities and mock implementations.

**Current Utilities:**
- `test_mocks.lua` - Mock implementations for CLI calls 
- `test_framework.lua` - Test helper functions
- `mock_data.lua` - Sample data for testing

## Test Status

### Working Tests
-  Maildir foundation tests
-  Maildir integration tests
-  Draft manager tests
-  Email composer tests

### Tests Needing Updates
- † Command tests (need to match current command structure)
- † Integration tests (need to use current APIs)
- † Performance tests (need implementation)
- † Draft tests (need consolidation and cleanup)

### Missing Tests
- L UI component tests (sidebar, float, preview)
- L State management tests
- L Event system tests
- L OAuth/sync tests
- L Setup wizard tests

## Writing Tests

### Test Structure

Each test file should follow this pattern:

```lua
-- Test Description
-- What this test validates

local M = {}

-- Dependencies
local module_under_test = require('neotex.plugins.tools.himalaya.module')
local test_utils = require('neotex.plugins.tools.himalaya.test.utils.test_framework')

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

function M.test_feature_two()
  -- Another test
end

-- Main run function (optional, for aggregate results)
function M.run()
  local results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
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

## Current Issues

### Known Problems

1. **Path Updates**: Many tests reference old module paths
2. **API Changes**: Tests use deprecated APIs that need updating
3. **Mock Coverage**: Not all external calls are properly mocked
4. **Test Duplication**: Multiple tests for same functionality
5. **Missing Coverage**: Major features lack test coverage

### Priority Fixes

1. Update all module paths to current structure
2. Fix mock implementations for current utils
3. Consolidate duplicate draft tests
4. Add tests for UI components
5. Create integration tests for new architecture

## Future Improvements

### Phase 1: Stabilization
- [ ] Fix all path references
- [ ] Update mocks for current implementation
- [ ] Ensure all existing tests pass
- [ ] Remove duplicate/obsolete tests

### Phase 2: Coverage
- [ ] Add UI component tests
- [ ] Add state management tests
- [ ] Add event system tests
- [ ] Achieve 80% code coverage

### Phase 3: Integration
- [ ] Create comprehensive workflow tests
- [ ] Add multi-account tests
- [ ] Add error recovery tests
- [ ] Performance benchmarks

### Phase 4: Automation
- [ ] CI/CD integration
- [ ] Automated test runs
- [ ] Coverage reporting
- [ ] Performance tracking

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

## Navigation

- [ê Himalaya Plugin](../README.md)
- [í Commands Tests](commands/README.md)
- [í Features Tests](features/README.md)
- [í Integration Tests](integration/README.md)
- [í Performance Tests](performance/README.md)
- [í Test Utilities](utils/README.md)