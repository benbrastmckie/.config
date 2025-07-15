# Himalaya Test Suite

Comprehensive testing infrastructure for the Himalaya email plugin, providing reliable validation of plugin functionality with extensive coverage and automated test execution.

## File Structure

```
test/
├── README.md                    # This file - test suite overview
├── test_runner.lua             # Main test runner and discovery
│
├── commands/                   # Command interface tests
│   ├── README.md              # Command testing documentation
│   ├── test_basic_commands.lua
│   ├── test_email_commands.lua
│   └── test_sync_commands.lua
│
├── features/                   # Feature-specific tests
│   ├── README.md              # Feature testing documentation
│   ├── test_async_timing.lua
│   ├── test_draft_manager_maildir.lua
│   ├── test_draft_saving.lua
│   ├── test_email_composer_maildir.lua
│   ├── test_maildir_foundation.lua
│   ├── test_maildir_integration.lua
│   └── test_scheduler.lua
│
├── integration/               # End-to-end workflow tests
│   ├── README.md              # Integration testing documentation
│   ├── test_draft_simple.lua
│   ├── test_email_operations_simple.lua
│   ├── test_full_workflow.lua
│   └── test_sync_simple.lua
│
├── performance/               # Performance and benchmarking tests
│   ├── README.md              # Performance testing documentation
│   └── test_search_speed.lua
│
└── utils/                     # Testing utilities and framework
    ├── README.md              # Test utilities documentation
    ├── test_framework.lua     # Core testing framework
    ├── test_isolation.lua     # Test isolation system
    ├── test_performance.lua   # Performance monitoring
    └── test_search.lua        # Search testing utilities
```

## Test Categories

### [Commands Tests](commands/README.md)
Tests for all Himalaya commands and their integration with Neovim.

**Purpose**: Validate command interfaces, parameter handling, and user-facing functionality.

**Coverage**: 
- Plugin initialization and configuration
- Email operations (list, send, delete)
- Synchronization commands
- Command validation and error handling

**Key Tests**: Basic commands, email operations, sync management

### [Features Tests](features/README.md)
Tests for specific Himalaya features and their underlying implementations.

**Purpose**: Validate core feature functionality and business logic.

**Coverage**:
- Async operations and timing
- Draft management (maildir-based)
- Email composition and editing
- Scheduler and queue management
- Maildir system integration

**Key Tests**: Scheduler, draft manager, email composer, maildir operations

### [Integration Tests](integration/README.md)
End-to-end workflow tests that verify component interaction.

**Purpose**: Validate that components work together correctly in realistic scenarios.

**Coverage**:
- Complete email workflows
- Multi-component coordination
- State consistency across operations
- Error propagation and handling

**Key Tests**: Full workflows, simplified operations, sync coordination

### [Performance Tests](performance/README.md)
Performance and benchmarking tests for efficiency validation.

**Purpose**: Ensure plugin remains responsive under various load conditions.

**Coverage**:
- Search performance across dataset sizes
- Memory usage patterns
- Cache effectiveness
- Performance regression detection

**Key Tests**: Search speed, memory efficiency, scalability

### [Test Utils](utils/README.md)
Testing utilities and framework components.

**Purpose**: Provide common functionality and patterns for all test suites.

**Coverage**:
- Test framework and assertions
- Test environment isolation
- Performance monitoring
- Domain-specific utilities

**Key Components**: Framework, isolation, performance monitoring, search utils

## Running Tests

### Interactive Test Runner
```vim
:HimalayaTest
```
Opens an interactive picker to select and run tests by category or individual test.

### Run All Tests
```vim
:HimalayaTest all
```

### Run by Category
```vim
:HimalayaTest commands     # Run all command tests
:HimalayaTest features     # Run all feature tests
:HimalayaTest integration  # Run all integration tests
:HimalayaTest performance  # Run all performance tests
```

### Run Specific Test
```vim
:HimalayaTest test_scheduler
:HimalayaTest test_full_workflow
:HimalayaTest test_search_speed
```

## Test Runner Features

### Test Discovery
- **Automatic Detection**: Finds all `test_*.lua` files
- **Category Organization**: Groups tests by directory structure
- **Flexible Execution**: Run individual tests or entire categories

### Test Execution
- **Real Implementation Testing**: Tests actual code without mocking
- **Test Isolation**: Prevents tests from affecting each other
- **Error Handling**: Graceful handling of expected failures in test environment

### Result Reporting
- **Detailed Reports**: Comprehensive pass/fail statistics
- **Performance Metrics**: Execution time for all tests
- **Error Details**: Complete error messages and context
- **Progress Tracking**: Real-time test execution progress

## Testing Philosophy

### Real Implementation Testing
- **No Mocking**: Tests use actual implementations to catch real issues
- **Graceful Failure Handling**: Expected failures (like missing config) are handled appropriately
- **Test Mode Protection**: External CLI calls are prevented during testing

### Test Isolation
- **Clean Environment**: Each test runs in isolated environment
- **State Management**: Editor state is preserved and restored
- **Resource Cleanup**: Temporary files and buffers are cleaned up

### Quality Assurance
- **Comprehensive Coverage**: Tests cover normal and edge cases
- **Performance Monitoring**: Performance regressions are detected
- **Consistent Patterns**: Standardized test patterns across all tests

## Test Environment

### Test Mode Features
- **CLI Protection**: Prevents external Himalaya CLI calls
- **Notification Suppression**: Reduces test noise in test mode
- **State Isolation**: Tests don't affect user environment
- **Buffer Management**: Automatic cleanup of test buffers

### Performance Monitoring
- **Timing Precision**: High-resolution timing for performance tests
- **Memory Tracking**: Memory usage monitoring
- **Regression Detection**: Automatic performance regression detection

## Contributing

### Adding New Tests

1. **Choose the Right Category**:
   - **Commands**: For testing command interfaces
   - **Features**: For testing specific functionality
   - **Integration**: For testing component interaction
   - **Performance**: For testing efficiency

2. **Follow Established Patterns**:
   - Use the test framework from `utils/test_framework.lua`
   - Follow naming conventions (`test_*.lua`)
   - Include appropriate assertions and cleanup

3. **Test Real Implementation**:
   - Test actual code behavior, not mocks
   - Handle expected failures gracefully
   - Use `pcall()` for operations that might fail

4. **Update Documentation**:
   - Update relevant README.md files
   - Document test purpose and coverage
   - Include examples if needed

### Test Writing Standards

- **Descriptive Names**: Test names should clearly describe what they validate
- **Focused Tests**: Each test should have a single, clear purpose
- **Proper Cleanup**: Ensure tests clean up after themselves
- **Error Handling**: Handle both success and failure cases appropriately
- **Performance Awareness**: Consider performance implications of tests

## Current Status

- **Total Tests**: 122 tests across all categories
- **Pass Rate**: 100% (all tests passing)
- **Coverage**: Comprehensive coverage of all major functionality
- **Performance**: All tests execute efficiently with proper isolation

The test suite provides reliable validation of the Himalaya plugin functionality, ensuring stability and correctness across all components and workflows.

## Navigation

- [Commands Tests →](commands/README.md)
- [Features Tests →](features/README.md)
- [Integration Tests →](integration/README.md)
- [Performance Tests →](performance/README.md)
- [Test Utils →](utils/README.md)
- [← Himalaya Plugin](../README.md)