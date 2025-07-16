# Unit Tests

Focused tests for individual modules ensuring correct behavior in isolation.

## Subdirectories

### [config/](config/)
Unit tests for the configuration system modules including accounts, folders, OAuth, UI settings, and validation.

### [utils/](utils/)
Unit tests for utility modules including string manipulation, email formatting, file operations, and async utilities.

## Purpose

Unit tests verify that individual modules work correctly in isolation. They test:
- Module initialization and setup
- Individual function behavior
- Edge cases and error handling
- State management within modules
- API contracts and interfaces

## Test Structure

Each test file follows the pattern `test_[module_name].lua` and contains:
- Setup/teardown functions when needed
- Focused tests for each public function
- Tests for error conditions
- Tests for edge cases

## Running Unit Tests

```vim
:HimalayaTest unit           " Run all unit tests
:HimalayaTest unit/config    " Run config unit tests
:HimalayaTest unit/utils     " Run utils unit tests
```

## Navigation
- [← Test Suite](../README.md)