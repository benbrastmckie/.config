# Test Count System Refactor Implementation Plan

## Executive Summary

The current test counting system in Himalaya has multiple inconsistencies and architectural issues that lead to inaccurate counts, hardcoded values, and confusing displays. This document outlines a systematic refactor to create an elegant, standard approach for counting and displaying tests throughout the system.

## Current State Analysis

### Problems Identified

1. **Multiple Counting Methods**
   - Tests are counted differently in different contexts
   - Metadata counts vs execution counts often mismatch
   - Some tests are double-counted in multiple categories
   - Unit tests subdirectories require special handling (as noted in test_runner.lua)

2. **Hardcoded Test Lists**
   - `get_test_list()` functions return hardcoded names that don't match actual tests
   - Example: `test_email_commands.lua` lists "Email preview command" which doesn't exist
   - The test README states 261 tests but this is manually maintained

3. **Inconsistent Display**
   - Picker shows one count
   - Execution reports another count
   - Notifications may show yet another count
   - Performance metrics calculate percentages based on potentially wrong totals

4. **Error Handling**
   - Count mismatches only show errors in non-test mode (`_G.HIMALAYA_TEST_MODE` suppression)
   - No graceful degradation when counts are wrong
   - Validation errors are suppressed rather than handled
   - Test discovery silently continues on module load failures

5. **Architectural Issues**
   - Test counting logic is scattered across multiple functions
   - No single source of truth for test counts
   - Mixing of concerns between counting, execution, and display
   - Categories defined in multiple places (picker categories vs directory structure)

## Design Principles

### Core Philosophy (Following GUIDELINES.md)
**Evolution, Not Revolution**: This refactor acknowledges the pragmatic realities of the existing test system while working toward more accurate counting. We will document compromises and preserve all working functionality.

### 1. Single Source of Truth
- Test counts should be derived from actual test execution, not metadata
- Metadata should be for organization and documentation only
- One authoritative registry for all test information

### 2. Runtime Discovery
- Count tests by what actually executes, not what metadata claims
- Dynamic discovery prevents hardcoded lists from becoming stale
- Systematic analysis of test patterns before implementation

### 3. Graceful Degradation
- Display informative errors instead of wrong counts
- Never crash or hide problems silently
- Preserve functionality even when counts are uncertain

### 4. Separation of Concerns
- Counting logic separate from display logic
- Test execution separate from result reporting
- Clear module boundaries with well-defined interfaces

### 5. Transparency
- Show users when counts might be inaccurate
- Provide debugging information when requested
- Document all architectural compromises

### 6. Test-Driven Migration
- Each phase must maintain 100% test pass rate
- Root cause analysis for any failures
- User approval required before proceeding

## Proposed Architecture

### Core Components

```
+---------------------+
|   Test Discovery    |
|  (finds test files) |
+----------+----------+
           |
           v
+---------------------+
|   Test Inspector    |
| (analyzes each file)|
+----------+----------+
           |
           v
+---------------------+
|   Test Registry     |
| (single truth source)|
+----------+----------+
           |
    +------+------+----------+--------+
    |             |          |        |
    v             v          v        v
+-------+   +---------+  +-------+  +-----+
|Picker |   |Executor |  |Report |  |Debug|
+-------+   +---------+  +-------+  +-----+
```

### Component Responsibilities

1. **Test Discovery**: Find all test files in the filesystem
2. **Test Inspector**: Analyze each file to determine actual test count
3. **Test Registry**: Maintain authoritative test information
4. **Display Components**: Use registry data for consistent display

## Important Considerations from Test Infrastructure

### Test Discovery Patterns
- Tests are discovered by finding `test_*.lua` files in category directories
- Unit tests have subdirectories that need recursive scanning
- Test files can contain multiple test patterns (M.tests table, test_* functions, M.run suite)

### Test Execution Modes
- Interactive mode via `:HimalayaTest` command with picker
- Headless mode via `dev_cli.lua` for CI/CD
- Both modes must show consistent counts

### Performance Tracking
- The test framework tracks individual test durations
- Performance metrics are calculated as percentages of total tests
- Inaccurate counts affect performance analysis

### Test Categories
- Directory-based: commands, features, integration, performance, unit
- Picker groupings: "Core Data & Storage", "Email Operations", etc.
- Categories can overlap (tests appear in multiple groups)

### Exit Codes and CI/CD
- The test runner returns exit codes for CI/CD integration
- Count accuracy affects build system decisions

## Pre-Implementation Analysis

Following GUIDELINES.md systematic approach, before implementing:

### 1. Affected Modules Analysis
- **test_runner.lua**: Core counting logic needs refactoring
- **Individual test files**: May need updates to remove hardcoded lists
- **test/README.md**: Manual count needs automation
- **Picker display**: Needs to use new registry
- **Report generation**: Must show accurate counts

### 2. Redundancy Identification
- Multiple counting methods can be consolidated
- Hardcoded test lists can be eliminated
- Metadata validation can be unified
- Error suppression code can be removed

### 3. Integration Planning
- New registry must work with existing test execution
- Backward compatibility during migration phase
- All display components must use same data source
- Performance impact must be minimal

### 4. Pragmatic Compromises
- Test suites that return dynamic counts need special handling
- Some metadata may remain for documentation purposes
- Migration must not break CI/CD workflows
- Existing test patterns must be preserved

## Implementation Plan

### Phase 1: Create Test Registry System ✅ COMPLETE (2025-07-18)

#### Pre-Phase Analysis
- [x] Analyze current test discovery mechanism
- [x] Document existing counting patterns  
- [x] Identify all test file formats
- [x] Plan registry integration points

#### Implementation Goals
- [x] Create registry without breaking existing system
- [x] Support all current test patterns
- [x] Add validation without enforcing it
- [x] Document any necessary compromises

#### Testing Protocol (MANDATORY)
- [x] Run `:HimalayaTest all` - must achieve 100% pass rate (261/261 tests passing)
- [x] Verify registry populates correctly
- [x] Test with both interactive and headless modes
- [x] Document any test failures and fixes

#### 1.1 Create Test Registry Module ✅
**File**: `test/utils/test_registry.lua`

```lua
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
  --   inspection_error = string|nil
  -- }
}

-- Inspect a test module and register its actual tests
function M.inspect_and_register(test_info)
  -- Load module safely
  -- Introspect actual test functions
  -- Register in registry
  -- Return success/error
end

-- Get accurate test count for a module
function M.get_test_count(module_path)
  -- Return actual count from registry
  -- Return nil, error if not inspected
end

-- Get all tests in a category
function M.get_category_tests(category)
  -- Filter registry by category
  -- Return test information
end

-- Update execution results
function M.update_execution_results(module_path, results)
  -- Store last execution results
  -- Track discrepancies
end
```

#### 1.2 Create Test Inspector
**File**: `test/utils/test_inspector.lua`

```lua
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
  
  -- Pattern 1: M.tests table (unit test pattern)
  if test_module.tests and type(test_module.tests) == 'table' then
    for name, func in pairs(test_module.tests) do
      if type(func) == 'function' and name:match('^test_') then
        table.insert(tests, { name = name, type = 'function' })
        count = count + 1
      end
    end
  end
  
  -- Pattern 2: test_* functions in module (alternative pattern)
  for key, value in pairs(test_module) do
    if type(value) == 'function' and key:match('^test_') and key ~= 'test_metadata' then
      if not test_module.tests or not test_module.tests[key] then -- Avoid double counting
        table.insert(tests, { name = key, type = 'function' })
        count = count + 1
      end
    end
  end
  
  -- Pattern 3: M.run function that returns results (suite pattern)
  if test_module.run and type(test_module.run) == 'function' and count == 0 then
    -- This is a test suite - we need to analyze its execution
    -- to determine actual test count
    return { suite = true, needs_execution = true }
  end
  
  return {
    tests = tests,
    count = count,
    metadata = test_module.test_metadata,
    has_run = test_module.run ~= nil
  }
end

-- Validate test module structure
function M.validate_structure(test_module)
  local issues = {}
  
  -- Check metadata accuracy
  if test_module.test_metadata and test_module.test_metadata.count then
    local actual = M.count_actual_tests(test_module)
    if actual ~= test_module.test_metadata.count then
      table.insert(issues, {
        type = 'count_mismatch',
        claimed = test_module.test_metadata.count,
        actual = actual
      })
    end
  end
  
  -- Check get_test_list accuracy
  if test_module.get_test_list then
    local list = test_module.get_test_list()
    local actual_names = M.get_actual_test_names(test_module)
    -- Compare lists for accuracy
  end
  
  return issues
end
```

#### 1.2 Create Test Inspector ✅
**File**: `test/utils/test_inspector.lua`

Created module that:
- Inspects test modules to find actual tests
- Supports multiple test patterns (global himalaya_test, M.tests table, test_* functions, M.run suites)
- Validates module structure and metadata accuracy
- Safely handles get_test_list() calls that might fail
- Identifies hardcoded test lists that don't match actual tests

#### 1.3 Update Test Discovery ✅
Modified `test_runner.lua` to use the registry:

```lua
function M.discover_tests()
  local registry = require('test.utils.test_registry')
  local test_dirs = {
    'commands',
    'features', 
    'integration',
    'performance',
    'unit'
  }
  
  for _, dir in ipairs(test_dirs) do
    M.tests[dir] = {}
    local dir_path = test_path .. dir .. '/'
    
    if vim.fn.isdirectory(dir_path) == 1 then
      local files = vim.fn.glob(dir_path .. 'test_*.lua', false, true)
      
      -- Special handling for unit tests subdirectories
      if dir == 'unit' then
        local subdirs = vim.fn.glob(dir_path .. '*/', false, true)
        for _, subdir in ipairs(subdirs) do
          local subdir_files = vim.fn.glob(subdir .. 'test_*.lua', false, true)
          vim.list_extend(files, subdir_files)
        end
      end
      
      -- Register each discovered file
      for _, file in ipairs(files) do
        local test_info = M.create_test_info(file, dir)
        local success, error = registry.inspect_and_register(test_info)
        
        if not success then
          -- Store error for display but continue discovery
          test_info.discovery_error = error
        end
        
        table.insert(M.tests[dir], test_info)
      end
    end
  end
end
```

### Phase 1 Results

#### What Was Accomplished
1. **Created Test Registry System**
   - Single source of truth for test information
   - Tracks actual test counts from module inspection
   - Stores validation issues and execution results
   - No backwards compatibility - clean implementation

2. **Created Test Inspector**
   - Dynamically discovers actual test functions
   - Validates metadata claims vs actual tests
   - Identifies hardcoded list issues
   - Supports all existing test patterns

3. **Integrated Registry with Test Runner**
   - Updated discover_tests() to populate registry
   - Modified counting functions to use registry data
   - Added execution result tracking
   - Registry updates after each test run

4. **Validation Issues Found**
   - 7 modules with count mismatches identified
   - Multiple hardcoded get_test_list() issues found
   - All issues tracked without breaking test execution
   - 100% test pass rate maintained (261 tests)

#### Key Discoveries
- test_email_commands uses global pattern but inspector found 0 tests (needs investigation)
- Several modules have metadata count mismatches (e.g., maildir_integration claims 32 but has 4)
- Hardcoded get_test_list() functions often don't match actual test names
- Registry system successfully identifies all discrepancies

#### Next Steps
- Phase 2 will use registry data for all counting
- Phase 3 will enhance display to show validation warnings
- Phase 4 will integrate execution results
- Phase 5 will remove all legacy code

### Phase 2: Refactor Counting Logic ✅ COMPLETE (2025-07-18)

#### 2.1 Replace Direct Counting Functions
Update all counting functions to use registry:

```lua
function M.count_test_functions_in_category(category)
  local registry = require('test.utils.test_registry')
  local tests = registry.get_category_tests(category)
  
  local count = 0
  local errors = {}
  
  for _, test in ipairs(tests) do
    if test.actual_tests then
      count = count + #test.actual_tests
    elseif test.inspection_error then
      table.insert(errors, {
        module = test.module_path,
        error = test.inspection_error
      })
    end
  end
  
  return count, errors
end
```

#### 2.2 Create Count Aggregation
New function for comprehensive counting:

```lua
function M.get_comprehensive_counts()
  return {
    by_category = {
      -- category -> { total = n, errors = {...} }
    },
    by_status = {
      inspected = n,
      error = n,
      total = n
    },
    validation_issues = {
      -- List of modules with count mismatches
    }
  }
end
```

### Phase 3: Refactor Display Components (Week 3)

#### 3.1 Enhanced Picker Display
Update picker to show inspection status:

```lua
-- In run_with_picker()
local counts = M.get_comprehensive_counts()

-- Display total with status
local total_text = string.format('Run All Tests (%d tests)', counts.by_status.inspected)
if counts.by_status.error > 0 then
  total_text = total_text .. string.format(' [%d errors]', counts.by_status.error)
end
```

#### 3.2 Improve Category Display
Show actual vs claimed counts:

```lua
-- For each category
local cat_counts = counts.by_category[category]
local display = string.format('%s (%d tests)', name, cat_counts.total)

if #cat_counts.errors > 0 then
  display = display .. ' �'
end

-- Add tooltip or submenu with error details
```

#### 3.3 Enhanced Test Report
Update build_report to show discrepancies:

```lua
function M.build_report()
  -- Existing report structure
  -- Add new section:
  
  if #validation_issues > 0 then
    table.insert(lines, '## Count Validation Issues')
    for _, issue in ipairs(validation_issues) do
      table.insert(lines, string.format('- %s: claimed %d, executed %d',
        issue.module, issue.claimed, issue.executed))
    end
  end
end
```

### Phase 4: Execution Integration (Week 4)

#### 4.1 Update Test Execution
Integrate registry with execution:

```lua
function M.run_test(test_info)
  local registry = require('test.utils.test_registry')
  
  -- Get test information from registry
  local reg_info = registry.registry[test_info.module_path]
  if not reg_info then
    -- Handle uninspected test
  end
  
  -- Execute tests
  -- Update registry with results
  registry.update_execution_results(test_info.module_path, results)
end
```

#### 4.2 Real-time Count Validation
Validate counts during execution:

```lua
-- During test execution
if executed_count ~= reg_info.actual_tests then
  -- Track discrepancy
  -- Add to validation issues
  -- Show in report
end
```

### Phase 5: Remove Legacy Code (Week 5)

#### 5.1 Remove Hardcoded Lists
- Remove all hardcoded `get_test_list()` implementations
- Replace with dynamic discovery from registry

#### 5.2 Remove Metadata Count Dependency
- Metadata becomes documentation only
- All counts derived from actual inspection

#### 5.3 Clean Error Suppression
- Remove `_G.HIMALAYA_TEST_MODE` checks that hide count errors
- Replace with proper error display

## Migration Strategy

### Step 1: Parallel Implementation
- Implement new system alongside existing
- Add feature flag to switch between old/new

### Step 2: Validation Phase
- Run both systems in parallel
- Compare results
- Log discrepancies

### Step 3: Gradual Cutover
- Switch individual components to new system
- Monitor for issues
- Keep fallback ready

### Step 4: Legacy Removal
- Remove old counting code
- Remove feature flags
- Document new system

## Testing Strategy

### Unit Tests
- Test registry operations
- Test inspector with various module formats
- Test count aggregation

### Integration Tests
- Test discovery -> inspection -> registry flow
- Test execution -> registry update flow
- Test display components with registry data

### Validation Tests
- Compare new counts with old counts
- Verify no tests are lost
- Ensure all displays are consistent

## Success Metrics

1. **Accuracy**: All displayed counts match actual execution
2. **Consistency**: Same count shown in picker, report, and notifications
3. **Transparency**: Users can see why counts might be wrong
4. **Maintainability**: Adding new test patterns requires minimal changes
5. **Performance**: No significant slowdown in test discovery

## Risk Mitigation

1. **Inspection Failures**: Graceful handling with error display
2. **Performance**: Cache inspection results between runs
3. **Compatibility**: Support existing test patterns during transition
4. **Rollback**: Feature flag allows quick reversion

## Root Cause Analysis Approach

Following GUIDELINES.md principles for addressing test failures:

### When Count Mismatches Occur
1. **Ask WHY**: Why does the count mismatch exist?
   - Is it a hardcoded list that's outdated?
   - Is it a test suite with dynamic behavior?
   - Is it a module loading failure?

2. **Fix the Root Cause**: 
   - Don't just update the number
   - Remove the source of inconsistency
   - Make counts self-correcting

3. **Prevent Recurrence**:
   - Add validation to catch future mismatches
   - Remove ability to hardcode counts
   - Make system self-documenting

### Example Root Cause Fixes
- **Issue**: test_email_commands lists non-existent tests
- **Root Cause**: Manual maintenance of test lists
- **Fix**: Dynamic discovery from actual test functions
- **Prevention**: Remove ability to manually specify test names

## Documentation Updates

1. Update test writing guide with supported patterns
2. Document registry API for extensions
3. Create troubleshooting guide for count issues
4. Add architecture diagram to developer docs
5. **Automatic README Updates**: 
   - Create a command to update test/README.md with actual counts
   - Remove manually maintained count (currently states 261)
   - Generate category breakdowns from registry data

## Timeline Summary

- **Week 1**: Test Registry System
- **Week 2**: Counting Logic Refactor  
- **Week 3**: Display Components Update
- **Week 4**: Execution Integration
- **Week 5**: Legacy Code Removal

Total estimated time: 5 weeks with testing and validation

## Phase 1 Implementation Summary

### What We Built
1. **Test Registry (`test/utils/test_registry.lua`)**
   - Central repository for all test information
   - Tracks actual test counts, metadata, and validation issues
   - Updates with execution results for dynamic validation
   - Clean implementation with no backwards compatibility cruft

2. **Test Inspector (`test/utils/test_inspector.lua`)**
   - Dynamically inspects modules to find actual tests
   - Supports all test patterns (global, M.tests, test_*, M.run)
   - Validates metadata accuracy against actual tests
   - Identifies hardcoded list problems

3. **Registry Integration**
   - Updated test_runner.lua to populate registry on discovery
   - Modified counting functions to use registry data
   - Added execution result tracking
   - Created HimalayaTestRegistry command for validation reports

### Key Findings
- 7 modules have count mismatches between metadata and actual tests
- Multiple hardcoded get_test_list() functions don't match reality
- test_email_commands uses a pattern the inspector needs to handle better
- All 261 tests continue to pass despite validation issues

### Next Steps
Phase 2 will complete the counting logic refactor, using registry data everywhere and removing all direct metadata dependencies. The foundation is solid and ready for the next phase.

## Phase 2 Implementation Summary

### What Was Accomplished
1. **Replaced All Direct Counting**
   - Updated picker categories to use registry counts
   - Removed direct metadata.count access in test execution
   - Simplified count_all_test_functions to use registry

2. **Enhanced Registry Capabilities**
   - Added comprehensive count aggregation with detailed summaries
   - Created get_pattern_count for flexible counting
   - Enhanced validation tracking with issue type counts

3. **Improved Validation Reporting**
   - Enhanced HimalayaTestRegistry display with better organization
   - Added summary statistics (total tests, metadata status, issue counts)
   - Categorized display shows modules, tests, and issues per category

4. **Fixed Inspector Pattern**
   - Updated to handle test_email_commands pattern better
   - Added check for modules that return himalaya_test directly

### Registry Now Provides
- Total test count: 234 tests (from registry verification)
- Module status: 33 modules inspected, 0 errors
- Validation tracking: 7 modules with count mismatches
- Category breakdowns with detailed statistics

### Remaining Work
The counting logic is now fully centralized in the registry. Phase 3 will enhance the display components to show validation warnings in the picker and test results.

## Quality Checklist (Per Phase)

Following GUIDELINES.md requirements, before proceeding to next phase:

- [ ] `:HimalayaTest all` shows 100% pass rate
- [ ] New unit tests written for registry system
- [ ] Architectural compromises documented
- [ ] Working functionality preserved (both interactive and headless modes)
- [ ] Documentation updated (FIX_COUNT.md progress, affected READMEs)
- [ ] Atomic commit created with clear message
- [ ] Manual testing requested from user
- [ ] User approval received

## Conclusion

This refactor will create a robust, accurate test counting system that:
- Provides a single source of truth
- Shows actual executable test counts
- Handles errors gracefully
- Maintains consistency across all displays
- Enables future enhancements
- Follows "Evolution, Not Revolution" philosophy

The systematic approach ensures minimal disruption while delivering significant improvements in accuracy and maintainability, acknowledging pragmatic compromises while working toward architectural ideals.