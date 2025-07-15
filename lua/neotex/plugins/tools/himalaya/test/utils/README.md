# Test Utils

This directory contains testing utilities and framework components that support all Himalaya tests.

## Purpose

Test utilities provide common functionality, frameworks, and patterns used across all test suites. These utilities ensure consistency, reduce code duplication, and provide powerful testing capabilities.

## Test Files

### test_framework.lua
Core testing framework with assertions, helpers, and test infrastructure.

**What it provides:**
- **Assertion Library**: Comprehensive assertion functions for validation
- **Test Helpers**: Common utilities for test setup and execution
- **Test Environment**: Standardized test environment creation and cleanup
- **Test Runners**: Test execution and result reporting infrastructure

**Key components:**
- `assert.equals()`, `assert.truthy()`, `assert.falsy()` - Basic assertions
- `assert.email_headers()`, `assert.maildir_structure()` - Domain-specific assertions
- `helpers.create_test_env()` - Test environment setup
- `helpers.create_test_email()` - Test data creation
- `create_test()`, `create_suite()` - Test structure creation

### test_isolation.lua
Test isolation system to prevent side effects and ensure clean test execution.

**What it provides:**
- **Editor State Management**: Save and restore editor state
- **Test Mode Management**: Global test mode flag handling
- **Event Isolation**: Prevent test events from affecting user environment
- **State Cleanup**: Ensure tests don't interfere with each other

**Key functions:**
- `save_state()` - Capture current editor state
- `restore_state()` - Restore previous editor state
- `run_isolated()` - Execute tests in isolated environment

### test_performance.lua
Performance monitoring and benchmarking utilities.

**What it provides:**
- **Timing Utilities**: Precise performance measurement
- **Memory Monitoring**: Memory usage tracking
- **Performance Assertions**: Performance-based test validation
- **Benchmarking**: Performance comparison and regression detection

**Key functions:**
- `start_monitoring()` - Begin performance measurement
- `end_monitoring()` - Complete performance measurement
- `performance_test()` - Execute performance-aware tests
- Performance reporting and analysis

### test_search.lua
Search-specific testing utilities and helpers.

**What it provides:**
- **Search Test Data**: Generate test datasets for search operations
- **Search Validation**: Verify search results and performance
- **Search Patterns**: Common search test patterns and scenarios

**Key functions:**
- `filter_emails()` - Email filtering for search tests
- `create_search_dataset()` - Generate test data for search
- Search result validation and verification

## Testing Architecture

### Framework Design
```
test_framework.lua (Core)
├── Assertions (validation)
├── Helpers (utilities)
├── Test Environment (setup/cleanup)
└── Test Runners (execution)

test_isolation.lua (Isolation)
├── State Management
├── Event Isolation
└── Test Mode Control

test_performance.lua (Performance)
├── Timing Utilities
├── Memory Monitoring
└── Performance Assertions

test_search.lua (Domain-specific)
├── Search Test Data
├── Search Validation
└── Search Patterns
```

### Test Environment Lifecycle
1. **Setup**: Create isolated test environment
2. **Execute**: Run test with real implementations
3. **Validate**: Check results with assertions
4. **Cleanup**: Restore original state

## Common Patterns

### Basic Test Structure
```lua
local framework = require('test_framework')
local assert = framework.assert
local helpers = framework.helpers

local test = framework.create_test('test_name', function()
  -- Test environment is automatically managed
  local result = actual_function()
  assert.truthy(result, "Function should return result")
end)
```

### Test Environment Usage
```lua
local env = helpers.create_test_env()
-- Test operations with isolated environment
helpers.cleanup_test_env(env)
```

### Performance Testing
```lua
local performance = require('test_performance')
local monitor = performance.start_monitoring('test_name')
-- Perform operations
local result = performance.end_monitoring(monitor)
assert.performance(result.duration_ms, 100, "Should complete within 100ms")
```

### Assertion Patterns
```lua
-- Basic assertions
assert.equals(actual, expected, "Values should match")
assert.truthy(value, "Value should be truthy")
assert.falsy(value, "Value should be falsy")

-- Domain-specific assertions
assert.email_headers(content, expected_headers)
assert.maildir_structure(path)
assert.file_exists(path)
```

## Test Utilities API

### Core Assertions
- `assert.equals(actual, expected, message)` - Value equality
- `assert.truthy(value, message)` - Truthiness check
- `assert.falsy(value, message)` - Falsiness check
- `assert.contains(table, value, message)` - Table containment
- `assert.matches(string, pattern, message)` - Pattern matching
- `assert.no_error(fn, message)` - Error-free execution
- `assert.error(fn, expected_error, message)` - Expected error

### Helper Functions
- `helpers.create_test_env(config)` - Create test environment
- `helpers.cleanup_test_env(env)` - Cleanup test environment
- `helpers.create_test_email(overrides)` - Generate test email
- `helpers.create_temp_dir()` - Create temporary directory
- `helpers.wait_for(condition, timeout)` - Wait for condition

### Test Structure
- `create_test(name, fn)` - Create single test
- `create_suite(name, tests)` - Create test suite
- `create_managed_test(name, fn, config)` - Create test with environment
- `create_performance_test(name, fn, options)` - Create performance test

## Running Utilities

The test utilities are automatically loaded and available in all tests:

```lua
local framework = require('neotex.plugins.tools.himalaya.test.utils.test_framework')
local isolation = require('neotex.plugins.tools.himalaya.test.utils.test_isolation')
local performance = require('neotex.plugins.tools.himalaya.test.utils.test_performance')
local search = require('neotex.plugins.tools.himalaya.test.utils.test_search')
```

## Test Environment Features

### Isolation Features
- **No external CLI calls**: Tests run without hitting external services
- **State restoration**: Editor state is preserved and restored
- **Event isolation**: Test events don't affect user environment
- **Buffer cleanup**: Test buffers are automatically cleaned up

### Performance Features
- **Precise timing**: High-resolution timing for performance tests
- **Memory monitoring**: Track memory usage during operations
- **Regression detection**: Identify performance regressions
- **Benchmarking**: Compare performance across different implementations

## Contributing

When adding new test utilities:

1. **Make it reusable**: Ensure utilities can be used across different test types
2. **Follow patterns**: Use consistent APIs and naming conventions
3. **Document thoroughly**: Provide clear documentation and examples
4. **Test the utilities**: Ensure test utilities themselves are reliable
5. **Keep it simple**: Avoid over-engineering utility functions

## Navigation

- [← Test Overview](../README.md)
- [← Performance Tests](../performance/README.md)
- [Commands Tests →](../commands/README.md)