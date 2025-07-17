# Test Picker Counting Problems

## Overview

The test picker is showing incorrect counts because of fundamental mismatches between how tests are structured and how the counting logic works. The picker shows only ~111 tests while the actual test runner executes 261 tests.

## Current File Structure

Based on file system analysis:
- **Commands**: 3 test files 
- **Performance**: 1 test file
- **Unit**: 17 test files (in subdirectories)
- **Features**: 8 test files
- **Integration**: 4 test files
- **Total**: 33 test files

## Test Structure Problems

### 1. **Unit Tests** (Working Correctly)
- **Structure**: Have `.tests` table with individual test functions
- **Example**: `test_cache.lua` has `M.tests = { test_cache_store_and_retrieve_email = function() ... }`
- **Counting**: Works correctly - counts each function in `.tests` table
- **Actual count**: `test_cache.lua` has 11 test functions, but only 7 are being counted

### 2. **Feature Tests** (Major Problems)
- **Structure**: Have `run()` function that calls multiple internal test functions
- **Example**: `test_maildir_integration.lua` has `M.run()` that calls `M.test_foundation()`, `M.test_draft_manager()`, etc.
- **Counting**: Falls back to 1 test per file (incorrect)
- **Actual count**: `test_maildir_integration.lua` actually runs 32 tests internally

### 3. **Integration Tests** (Problems)
- **Structure**: Similar to feature tests, have `run()` function
- **Counting**: Falls back to 1 test per file (incorrect)
- **Actual count**: Unknown without running

### 4. **Command Tests** (Problems)
- **Structure**: Have `run()` function
- **Counting**: Falls back to 1 test per file (incorrect)
- **Actual count**: Unknown without running

## Specific Counting Issues

### Issue 1: Unit Test Miscounting
- **Problem**: Even unit tests aren't being counted correctly
- **Example**: `test_cache.lua` has 11 functions but shows 7 in results
- **Cause**: Some functions might not match the expected pattern or have syntax issues

### Issue 2: Feature Test Structure Mismatch
- **Problem**: Feature tests don't have `test_` prefixed functions at module level
- **Example**: `test_maildir_integration.lua` has functions like `M.test_foundation()` but these aren't detected
- **Cause**: Counting logic looks for `test_` prefixed functions but feature tests use different patterns

### Issue 3: Complex Test Execution
- **Problem**: Tests like `test_maildir_integration.lua` run multiple sub-tests internally
- **Example**: One file runs 32 tests, but picker only counts 1
- **Cause**: No way to determine internal test count without running the tests

### Issue 4: Inconsistent Test Patterns
- **Problem**: No standard pattern across all test types
- **Examples**:
  - Unit: `M.tests = { test_name = function() ... }`
  - Feature: `function M.run() ... end` with internal calls
  - Integration: Similar to feature but different internal structure

## Why 261 vs ~111 Discrepancy

The test runner shows 261 tests because:
1. **Unit tests**: Each function in `.tests` table is counted individually
2. **Feature tests**: Internal test functions are executed and counted
3. **Integration tests**: Complex workflows with multiple test steps
4. **Command tests**: Potentially multiple test scenarios per file

The picker shows ~111 because:
1. **Unit tests**: Partially counted (some functions missed)
2. **Feature tests**: Only 1 per file (should be many more)
3. **Integration tests**: Only 1 per file (should be more)
4. **Command tests**: Only 1 per file (unknown actual count)

## Root Cause Analysis

### 1. **No Standard Test Structure**
- Different test types use completely different patterns
- Unit tests use `.tests` table
- Feature/integration tests use `.run()` function
- No consistent way to introspect test count

### 2. **Complex Internal Test Logic**
- Many tests have internal sub-tests that aren't exposed
- Example: `test_maildir_integration.lua` has 4 test suites with 8 tests each = 32 total
- No metadata to indicate internal structure

### 3. **Counting Logic Limitations**
- Current logic only handles simple patterns
- Falls back to 1 per file for complex tests
- No way to introspect internal test structure without running

## Potential Solutions

### Option 1: Standardize Test Structure
- Modify all tests to use consistent `.tests` table structure
- Pro: Accurate counting, consistent patterns
- Con: Major refactoring required

### Option 2: Add Test Metadata
- Add metadata to each test file indicating test count
- Example: `M.test_count = 32` in each file
- Pro: Accurate counts, minimal changes
- Con: Manual maintenance required

### Option 3: Smart Introspection
- Enhance counting logic to understand complex patterns
- Parse test files to find internal test functions
- Pro: No test changes required
- Con: Complex implementation, fragile

### Option 4: Accept Approximation
- Show approximate counts with `~` prefix
- Focus on test execution rather than perfect counting
- Pro: Simple, works with current structure
- Con: Inaccurate user information

## Current Status

The test picker is functional but shows incorrect counts. The actual test execution works correctly (261 tests run and pass), but the picker display is misleading. The fundamental issue is architectural - we have inconsistent test structures that don't lend themselves to easy counting.

## Recommendations

1. **Short-term**: Use Option 4 (approximation) with clear indicators
2. **Long-term**: Consider Option 2 (metadata) for accurate counts
3. **Alternative**: Standardize test structure across all test types (Option 1)

The core issue is that we're trying to count tests without a consistent structure to count against. The solution requires either changing the tests or accepting the limitations of the current approach.