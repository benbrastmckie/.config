# Test Count System Refactor - Implementation Plan

## Executive Summary

This document provides a systematic, release-ready implementation plan to fix test count discrepancies and establish a clean test hierarchy. Following GUIDELINES.md phase-based development, this refactor eliminates cruft while preserving all functionality.

## Current State Analysis

### Critical Issues
1. **Double Counting**: `test_maildir_integration.lua` runs other test suites, inflating counts
2. **Metadata Drift**: 5 modules have incorrect counts in metadata
3. **Architectural Confusion**: No clear distinction between test files and test suites
4. **Registry Inaccuracy**: Shows 233 tests while execution finds 261

### Root Causes
1. **Mixed Patterns**: Some files are test suites, others are test files, no clear marking
2. **Manual Maintenance**: Metadata counts updated manually, prone to drift
3. **Legacy Design**: Test aggregation pattern created before registry system existed

## Design Goals

1. **Clear Hierarchy**: Test Files → Test Suites → Run All Tests
2. **Single Source of Truth**: Registry determines all counts dynamically
3. **Zero Manual Maintenance**: No hardcoded counts anywhere
4. **Release Ready**: Clean, documented, production-quality code

## Test-Driven Development Setup

```bash
# Create development alias for rapid testing
alias htest='nvim --headless -l /home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/test/dev_cli.lua'

# Usage during implementation:
htest                    # Run all tests after each change
htest test_maildir_integration  # Test specific suite
htest features           # Test category
```

## Phase-Based Implementation

### Phase 1: Test Architecture Refactor (Day 1)

#### 1. Pre-Phase Analysis
- [ ] Run baseline: `htest > baseline.txt`
- [ ] Identify all test aggregator patterns in codebase
- [ ] Document which files are suites vs individual tests
- [ ] Map test dependencies and relationships

Test categorization:
```
Test Files (contain actual tests):
- All files except test_maildir_integration.lua

Test Suites (orchestrate other tests):
- test_maildir_integration.lua (currently)
```

#### 2. Implementation

**Step 1: Create test suite infrastructure**

Create `test/utils/test_suite.lua`:
```lua
-- Test Suite Infrastructure
-- Provides clear distinction between test files and test suites

local M = {}

-- Marker for test suites
M.SUITE_MARKER = "TEST_SUITE"

-- Create a test suite definition
function M.create_suite(name, config)
  return {
    [M.SUITE_MARKER] = true,
    name = name,
    description = config.description,
    runs_tests = config.runs_tests or {},
    category = config.category or "suites",
    tags = config.tags or {"suite"}
  }
end

-- Check if a module is a test suite
function M.is_suite(module)
  return module and module[M.SUITE_MARKER] == true
end

return M
```

**Step 2: Extract integration test cases**

Create `test/features/test_maildir_integration_cases.lua`:
```lua
-- Extracted from test_maildir_integration.lua
-- These are the actual integration test cases

local M = {}

M.test_metadata = {
  name = "Maildir Integration Cases",
  description = "Actual integration test cases for maildir",
  count = 4,
  category = "features",
  tags = {"maildir", "integration", "cases"}
}

-- Move the 4 test functions here from test_maildir_integration.lua
-- (test_ui_create, test_list_drafts, test_edit_draft, test_migration)

return M
```

**Step 3: Convert test_maildir_integration to pure suite**

Update `test/features/test_maildir_integration.lua`:
```lua
local suite = require('neotex.plugins.tools.himalaya.test.utils.test_suite')

local M = suite.create_suite("Maildir Test Suite", {
  description = "Orchestrates all maildir-related tests",
  runs_tests = {
    "test_maildir_foundation",
    "test_draft_manager_maildir",
    "test_email_composer",
    "test_maildir_integration_cases"  -- New file with the 4 tests
  },
  category = "features",
  tags = {"maildir", "suite", "orchestration"}
})

-- Keep orchestration logic but remove individual tests
-- Update run() to only orchestrate, not count its own tests

return M
```

**Step 4: Fix metadata counts**

```lua
-- test_maildir_foundation.lua
M.test_metadata.count = 12  -- was 14

-- test_cache.lua
M.test_metadata.count = 7   -- was 8

-- test_scheduler.lua
M.test_metadata.count = 9   -- was 10

-- test_search.lua
M.test_metadata.count = 8   -- was 9
```

#### 3. Testing Protocol

After each implementation step:
```bash
# Run tests and check output
htest > test_results.txt
diff baseline.txt test_results.txt

# Verify specific changes
htest test_maildir_integration
htest features
```

Expected outcomes:
- [ ] All tests still pass (100% rate)
- [ ] Registry shows 237 tests (233 + 4 new integration cases)
- [ ] Execution finds 237 tests (no double counting)
- [ ] No validation warnings in output

#### 4. Documentation

Update `test/utils/README.md`:
```markdown
## Test Suite Infrastructure

### test_suite.lua
Provides clear distinction between test files and test suites.

**Usage:**
```lua
-- Creating a test suite
local suite = require('...test_suite')
local M = suite.create_suite("Name", {
  runs_tests = {"test_foo", "test_bar"}
})
```

**Key Functions:**
- `create_suite()` - Creates a suite definition
- `is_suite()` - Checks if module is a suite
```

#### 5. Commit & Review

```bash
git add -A
git commit -m "Phase 1: Test Architecture Refactor

- Created test suite infrastructure for clear test/suite distinction
- Extracted integration cases from test_maildir_integration
- Fixed metadata counts in 4 modules  
- Registry and execution counts now match (237 tests)

No backwards compatibility issues - all tests passing."
```

#### 6. User Approval
- [ ] Request testing: "Please run :HimalayaTest all"
- [ ] Verify no regressions reported
- [ ] Proceed to Phase 2

### Phase 2: Registry Enhancement for Suites (Day 2)

#### 1. Pre-Phase Analysis
- [ ] Verify Phase 1 changes are stable
- [ ] Run `htest` to ensure clean baseline
- [ ] Review test_inspector.lua current implementation

#### 2. Implementation

**Step 1: Update Test Inspector**

Modify `test/utils/test_inspector.lua`:
```lua
function M.inspect_module(module_path)
  -- ... existing code ...
  
  -- Add suite detection
  local suite_util = require('neotex.plugins.tools.himalaya.test.utils.test_suite')
  if suite_util.is_suite(test_module) then
    return {
      is_suite = true,
      suite_info = test_module,
      runs_tests = test_module.runs_tests or {},
      count = 0  -- Suites contribute 0 to count
    }
  end
  
  -- ... rest of existing logic
end
```

**Step 2: Update Test Registry**

Enhance `test/utils/test_registry.lua`:
```lua
-- Add to registry entry structure
M.registry = {
  -- [module_path] = {
  --   ... existing fields ...
  --   is_suite = boolean,
  --   runs_tests = string[],  -- modules this suite runs
  --   aggregated_count = number  -- calculated from children
  -- }
}

-- New function: Calculate suite's aggregated count
function M.get_suite_count(module_path)
  local entry = M.registry[module_path]
  if not entry or not entry.is_suite then
    return 0
  end
  
  local total = 0
  for _, test_module in ipairs(entry.runs_tests or {}) do
    -- Find the full module path
    for path, reg_entry in pairs(M.registry) do
      if path:match(test_module .. "$") then
        total = total + (M.get_test_count(path) or 0)
        break
      end
    end
  end
  
  entry.aggregated_count = total
  return total
end
```

**Step 3: Update Test Runner Display**

Modify `test_runner.lua` picker display:
```lua
-- In category count calculation
for _, test_info in ipairs(M.tests[test_spec.category]) do
  if test_info.name:match(test_spec.pattern) then
    local entry = registry.registry[test_info.module_path]
    
    if entry and entry.is_suite then
      -- For suites, show aggregated count but don't add to total
      -- This is just for display
      local suite_count = registry.get_suite_count(test_info.module_path)
      -- Don't add to total_count
    else
      -- Regular test file
      local test_count = registry.get_test_count(test_info.module_path)
      if test_count then
        total_count = total_count + test_count
      end
    end
  end
end
```

#### 3. Testing Protocol

```bash
# Test registry changes
htest > phase2_results.txt

# Verify suite handling
htest test_maildir_integration  # Should run 4 suites

# Check registry output in Neovim
:HimalayaTestRegistry  # Should show suite relationships
```

Expected outcomes:
- [ ] Test suites marked with is_suite = true
- [ ] Suite aggregated counts shown correctly
- [ ] Total count remains 237 (no double counting)
- [ ] All tests pass

#### 4. Documentation

Create `docs/TEST_ARCHITECTURE.md`:
```markdown
# Test Architecture

## Test Hierarchy

```
Individual Test Files (237 tests)
         ↓
Test Suites (0 count, orchestrate tests)
         ↓
"Run All Tests" (237 total)
```

## Test Files
- Contain actual test functions
- Have metadata with accurate count
- Contribute to total test count

## Test Suites  
- Orchestrate other test files
- Marked with TEST_SUITE marker
- Do NOT contribute to count
- Show aggregated count in UI
```

#### 5. Commit & Review

```bash
git commit -m "Phase 2: Registry Enhancement for Test Suites

- Enhanced inspector to detect test suites
- Added suite count aggregation to registry
- Updated display to show suite relationships
- No double counting - total remains 237

Test suites now clearly distinguished from test files."
```

#### 6. User Approval
- [ ] Request testing with new registry commands
- [ ] Verify suite counts display correctly
- [ ] Proceed to Phase 3

### Phase 3: Clean Up and Release Prep (Day 3)

#### 1. Pre-Phase Analysis
- [ ] Review all test files for consistency
- [ ] Check for any remaining manual counts
- [ ] Verify documentation accuracy

#### 2. Implementation

**Step 1: Remove manual count maintenance**

Update all test files to remove count from metadata (optional):
```lua
-- Option A: Keep count for documentation
M.test_metadata = {
  name = "Test Name",
  description = "...",
  count = 12,  -- Keep but note it's for reference only
}

-- Option B: Remove count entirely (cleaner)
M.test_metadata = {
  name = "Test Name", 
  description = "...",
  -- count removed - registry determines dynamically
}
```

**Step 2: Add validation command**

Create `:HimalayaTestValidateAll`:
```lua
-- Checks all test files have proper structure
-- Verifies no double counting
-- Reports any inconsistencies
```

**Step 3: Update test/README.md**

```markdown
## Test Organization

### Test Architecture
The test system uses a clear hierarchy:

1. **Test Files** (237 total)
   - Contain actual test functions
   - Located in commands/, features/, integration/, performance/
   - Each contributes to total count

2. **Test Suites** (1 currently: test_maildir_integration)
   - Orchestrate related test files
   - Do NOT add to test count
   - Show aggregated counts in picker

3. **Categories**
   - Logical groupings for the picker
   - May include both files and suites

### Running Tests
[existing content updated with suite info]
```

#### 3. Testing Protocol

Final validation:
```bash
# Full test run
htest > final_results.txt

# Validate counts
:HimalayaTestValidateAll

# Check all commands
:HimalayaTest
:HimalayaTestRegistry  
:HimalayaTestExecution
```

#### 4. Documentation

Update all affected READMEs:
- test/README.md - Updated with suite information
- test/utils/README.md - Added test_suite.lua docs
- docs/TEST_ARCHITECTURE.md - New file
- docs/TEST_COUNT.md - Mark as complete

#### 5. Commit & Review

```bash
git commit -m "Phase 3: Test System Release Preparation

- Finalized test suite architecture
- Updated all documentation
- Added validation tooling
- System ready for production use

Test counts: 237 individual tests, 1 test suite
No double counting, clean architecture."
```

#### 6. User Approval
- [ ] Final testing of all test commands
- [ ] Verify documentation accuracy
- [ ] Mark refactor complete

## Success Metrics

1. **Accurate Counts**: Registry = Execution = 237 tests
2. **Clean Architecture**: Clear file vs suite distinction  
3. **Zero Warnings**: No validation issues in any view
4. **100% Pass Rate**: All tests continue to work
5. **Production Ready**: Clean, documented, maintainable

## Timeline

- **Phase 1**: 2-3 hours (architecture refactor)
- **Phase 2**: 1-2 hours (registry enhancement)
- **Phase 3**: 1 hour (cleanup and docs)

**Total**: 4-6 hours of focused work

## Long-term Benefits

1. **Self-Maintaining**: Counts derived dynamically
2. **Scalable**: Easy to add new tests/suites
3. **Clear Mental Model**: Developers understand the hierarchy
4. **Release Ready**: Professional quality implementation

-- test_cache.lua  
M.test_metadata = {
  count = 7,   -- was 8
  -- rest unchanged
}

-- test_scheduler.lua
M.test_metadata = {
  count = 9,   -- was 10
  -- rest unchanged
}

-- test_search.lua
M.test_metadata = {
  count = 8,   -- was 9
  -- rest unchanged
}
```

#### 2.2 Testing Protocol
- [ ] Run `:HimalayaTest all` - verify 4 warnings resolved
- [ ] Check `:HimalayaTestRegistry` - confirm metadata matches
- [ ] Document any new issues discovered

### Phase 3: Refactor Test Suite Pattern

#### 3.1 Extract Integration Tests
Create new file for the 4 actual integration tests:

```lua
-- test/features/test_maildir_integration_cases.lua
local M = {}

M.test_metadata = {
  name = "Maildir Integration Cases",
  description = "Integration test cases for maildir functionality",
  count = 4,
  category = "features",
  tags = {"maildir", "integration", "cases"}
}

-- Move these 4 functions from test_maildir_integration.lua:
-- - test_ui_create()
-- - test_list_drafts()  
-- - test_edit_draft()
-- - test_migration()

return M
```

#### 3.2 Convert to Pure Suite Aggregator
Update `test_maildir_integration.lua`:

```lua
-- Mark as suite aggregator
M.test_metadata = {
  name = "Maildir Test Suite",
  description = "Orchestrates all maildir-related tests",
  is_suite = true,  -- New flag
  aggregates = {
    "test_maildir_foundation",
    "test_draft_manager_maildir", 
    "test_email_composer",
    "test_maildir_integration_cases"  -- New file
  }
}

-- Remove individual test functions
-- Keep only orchestration logic
```

#### 3.3 Testing Protocol
- [ ] Run `:HimalayaTest all` - verify no tests lost
- [ ] Check specific: `:HimalayaTest test_maildir_integration_cases`
- [ ] Verify suite still orchestrates properly

### Phase 4: Enhance Test Infrastructure

#### 4.1 Update Test Inspector
Enhance `test_inspector.lua` to recognize suites:

```lua
function M.inspect_module(module_path)
  -- ... existing code ...
  
  -- Check for suite aggregator
  if inspection_result.metadata and inspection_result.metadata.is_suite then
    return {
      suite = true,
      is_aggregator = true,
      aggregates = inspection_result.metadata.aggregates,
      metadata = inspection_result.metadata,
      count = 0  -- Suites don't contribute to count
    }
  end
  
  -- ... rest of function
end
```

#### 4.2 Update Test Registry
Enhance registry to handle suite relationships:

```lua
-- Add to registry structure
M.registry = {
  -- [module_path] = {
  --   ...existing fields...
  --   is_aggregator = boolean,
  --   aggregates = string[]  -- modules this suite runs
  -- }
}

-- New function to get aggregated counts
function M.get_suite_count(suite_path)
  local entry = M.registry[suite_path]
  if not entry or not entry.is_aggregator then
    return 0
  end
  
  local total = 0
  for _, module in ipairs(entry.aggregates or {}) do
    total = total + (M.get_test_count(module) or 0)
  end
  
  return total
end
```

#### 4.3 Update Test Runner Display
Enhance picker to show suite relationships:

```lua
-- In build_picker_items()
if cat_info.is_aggregator then
  -- Show aggregated count, not own count
  local suite_count = registry.get_suite_count(test_info.module_path)
  display_text = string.format('%s (suite: %d tests)', name, suite_count)
else
  -- Regular test file
  display_text = string.format('%s (%d tests)', name, test_count)
end
```

#### 4.4 Testing Protocol
- [ ] Run `:HimalayaTest all` - verify counts accurate
- [ ] Check `:HimalayaTestRegistry` - no validation warnings
- [ ] Verify suite shows aggregated count in picker
- [ ] Confirm "Run All Tests" shows correct total

### Phase 5: Documentation and Cleanup

#### 5.1 Update test/README.md
Add section on test organization:

```markdown
## Test Organization

### Test Files vs Test Suites

The test system distinguishes between:

1. **Test Files**: Contain actual test functions
   - Located in any test directory
   - Have test_metadata with accurate count
   - Contribute to total test count

2. **Test Suites**: Orchestrate other test files
   - Have `is_suite = true` in metadata
   - List aggregated modules in metadata
   - Do NOT contribute to test count (avoid double counting)

Example suite:
```lua
M.test_metadata = {
  name = "Integration Test Suite",
  is_suite = true,
  aggregates = {"test_foo", "test_bar", "test_baz"}
}
```
```

#### 5.2 Create Migration Guide
Document for future test authors:

```markdown
## Adding Tests

### Creating a Test File
1. Add test functions to appropriate category
2. Set accurate metadata.count
3. Follow existing patterns

### Creating a Test Suite
1. Set `is_suite = true` in metadata
2. List aggregated modules
3. Don't include own test functions
4. Use for orchestration only
```

#### 5.3 Testing Protocol
- [ ] Final run: `:HimalayaTest all` - 100% pass rate
- [ ] No validation warnings in picker
- [ ] Registry count matches execution count
- [ ] Documentation is accurate

## Success Criteria

1. **Test Counts**: Registry and execution counts match exactly
2. **No Warnings**: Picker shows no validation indicators
3. **Clear Hierarchy**: Test files → Suites → "Run All"
4. **100% Pass Rate**: All tests continue to pass
5. **Documentation**: README accurately describes system

## Rollback Plan

If issues arise:
1. Git stash changes
2. Revert to previous commit
3. Document specific failures
4. Adjust plan based on findings

## Timeline

- **Phase 1**: 15 minutes (analysis)
- **Phase 2**: 5 minutes (metadata fixes)
- **Phase 3**: 30 minutes (suite refactor)
- **Phase 4**: 45 minutes (infrastructure)
- **Phase 5**: 15 minutes (documentation)

**Total**: ~2 hours

## Long-term Benefits

1. **Clarity**: Clear distinction between tests and suites
2. **Accuracy**: Reliable test counts at all levels
3. **Maintainability**: Easy to add new tests/suites
4. **Scalability**: Pattern works as test suite grows

## Commands for Validation

```vim
" Before starting
:HimalayaTest all
:HimalayaTestRegistry

" After each phase
:HimalayaTest all
:HimalayaTestExecution

" Final validation
:HimalayaTestValidate
```

## Notes on Pragmatic Compromises

Following GUIDELINES.md philosophy:
- Test suites are useful for organizing related tests
- Accept the pattern but fix the counting issue
- Document the distinction clearly
- Provide tooling to handle both patterns

This evolution preserves the useful test suite pattern while fixing the count accuracy issue.