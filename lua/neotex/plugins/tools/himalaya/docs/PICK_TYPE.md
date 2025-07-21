# Test Picker Type Implementation Plan

## Option A: Directory-Based Categories Only

### Overview
Remove custom thematic categories from the test picker to eliminate confusion where tests appear in multiple categories. This will show only the directory-based organization that matches the actual file structure.

### Current Issue
- Tests are shown in BOTH custom categories (like "Draft System", "Email Operations") AND directory categories
- This causes the picker to show 380 total tests when there are actually only 234
- Users see confusing duplicate entries

## Implementation Plan Following GUIDELINES.md

### Pre-Implementation Analysis

#### 1. Modules Affected
- **Primary**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/himalaya/test/test_runner.lua`
- **Secondary**: None (UI-only change)
- **Dependencies**: Test picker UI (already part of test_runner.lua)

#### 2. Redundancies to Remove
- Lines 247-349 in test_runner.lua contain custom category definitions
- These duplicate tests already shown in directory categories
- No functional value, only UI confusion

#### 3. Integration Points
- Test execution logic remains unchanged
- Registry and inspector modules unaffected
- Only picker display logic changes

### Phase-Based Development

## Phase 1: Remove Custom Categories (15 minutes)

### 1. Pre-Phase Analysis
- [x] Analyzed test_runner.lua structure
- [x] Identified lines 247-349 as custom categories
- [x] Confirmed no dependencies on this code
- [x] Verified picker will still function without it

### 2. Implementation Steps
```lua
-- DELETE lines 247-349 from test_runner.lua
-- This removes:
-- - Draft System category (lines 247-259)
-- - Email Operations category (lines 262-275)
-- - Sync & State category (lines 278-289)
-- - Search & Navigation category (lines 292-300)
-- - Foundation category (lines 303-310)
-- - Integration category (lines 313-328)
-- - Performance category (lines 331-349)
```

### 3. Testing Protocol (MANDATORY)
```bash
# Step 1: Run baseline test before changes
nvim --headless -l test/dev_cli.lua > baseline.txt

# Step 2: Make the deletion

# Step 3: Run tests after deletion
nvim --headless -l test/dev_cli.lua > after_deletion.txt

# Step 4: Compare results
diff baseline.txt after_deletion.txt

# Expected: Identical test execution results
# Only picker display should change
```

### 4. Verification
```vim
" In Neovim, verify picker display
:HimalayaTest

" Should see:
" - No custom categories
" - Only directory-based categories
" - Total count of 234 in picker
```

## Phase 2: Add Hierarchical Display for Features (20 minutes)

### 1. Pre-Phase Analysis
- Features category has 215 tests (too many for flat display)
- Need to show individual test files with counts
- Must preserve test execution functionality

### 2. Implementation Steps

#### Step 1: Modify create_picker_items() function
```lua
-- Around line 360 in test_runner.lua
-- After removing custom categories, enhance directory display

function M.create_picker_items()
  local items = {}
  local registry = require('neotex.plugins.tools.himalaya.test.utils.test_registry')
  
  -- Add "Run All Tests" at the top
  local total_count = registry.get_comprehensive_counts().summary.total_tests
  table.insert(items, {
    display = string.format("> Run All Tests (%d)", total_count),
    category = "all",
    action = function() M.run_all_tests() end
  })
  
  -- Process each directory
  for category, tests in pairs(M.tests) do
    local category_count = 0
    local test_items = {}
    
    -- Count tests and prepare items
    for _, test_info in ipairs(tests) do
      local test_count = registry.get_test_count(test_info.module_path) or 1
      category_count = category_count + test_count
      
      table.insert(test_items, {
        test_info = test_info,
        count = test_count
      })
    end
    
    -- Special handling for features (many tests)
    if category == "features" and category_count > 50 then
      -- Add category header
      table.insert(items, {
        display = string.format("- %s/ (%d tests)", category, category_count),
        category = category,
        is_header = true
      })
      
      -- Add "Run All Feature Tests" sub-item
      table.insert(items, {
        display = string.format("  > Run All %s Tests (%d)", 
          category:gsub("^%l", string.upper), category_count),
        category = category,
        action = function() M.run_category_tests(category) end,
        indent = 1
      })
      
      -- Add individual test files
      for _, item in ipairs(test_items) do
        local test_name = M.format_test_display_name(item.test_info.name)
        table.insert(items, {
          display = string.format("    - %s (%d tests)", test_name, item.count),
          test_info = item.test_info,
          action = function() M.run_single_test(item.test_info) end,
          indent = 2
        })
      end
    else
      -- Regular categories (flat display)
      table.insert(items, {
        display = string.format("- %s/ (%d tests)", category, category_count),
        category = category,
        action = function() M.run_category_tests(category) end
      })
      
      -- Add test files directly
      for _, item in ipairs(test_items) do
        local test_name = M.format_test_display_name(item.test_info.name)
        table.insert(items, {
          display = string.format("  - %s", test_name),
          test_info = item.test_info,
          action = function() M.run_single_test(item.test_info) end,
          indent = 1
        })
      end
    end
  end
  
  return items
end
```

### 3. Testing Protocol
```bash
# Test the hierarchical display
nvim --headless -l test/dev_cli.lua features > features_test.txt

# Verify correct execution
grep "Total Tests:" features_test.txt
# Should show: Total Tests: 215

# Test individual feature files
nvim --headless -l test/dev_cli.lua test_cache > cache_test.txt
grep "Total Tests:" cache_test.txt
# Should show: Total Tests: 25
```

### 4. Manual Testing
```vim
:HimalayaTest
" Navigate to features section
" Verify hierarchical display
" Test "Run All Feature Tests"
" Test individual feature files
```

## Phase 3: Final Cleanup and Validation (10 minutes)

### 1. Code Cleanup
- Remove any dead code references to custom categories
- Ensure consistent indentation in picker display
- Verify all test counts are accurate

### 2. Update Documentation
```markdown
# In test/README.md, update the picker section:

## Running Tests

### Interactive Testing (Within Neovim)

The `:HimalayaTest` command opens an interactive picker showing:
- Run All Tests (total count)
- Directory-based categories:
  - commands/ - Command interface tests
  - features/ - Feature-specific tests (with sub-items)
  - integration/ - End-to-end workflow tests
  - performance/ - Performance tests

For the features category with many tests, a hierarchical view is provided:
- features/ (215 tests)
  > Run All Feature Tests (215)
    - Individual test files with their counts
```

### 3. Final Testing Protocol
```bash
# Complete test suite validation
echo "=== FINAL VALIDATION ==="

# 1. Run all tests
nvim --headless -l test/dev_cli.lua > final_all.txt
tail -20 final_all.txt

# 2. Test each category
for cat in commands features integration performance; do
  echo "Testing $cat..."
  nvim --headless -l test/dev_cli.lua $cat > final_$cat.txt
  grep "Total Tests:" final_$cat.txt
done

# 3. Verify counts
echo "=== COUNT VERIFICATION ==="
echo "Commands: $(grep -o 'Total Tests: [0-9]*' final_commands.txt)"
echo "Features: $(grep -o 'Total Tests: [0-9]*' final_features.txt)"
echo "Integration: $(grep -o 'Total Tests: [0-9]*' final_integration.txt)"
echo "Performance: $(grep -o 'Total Tests: [0-9]*' final_performance.txt)"
echo "All: $(grep -o 'Total Tests: [0-9]*' final_all.txt)"

# Expected:
# Commands: Total Tests: 10
# Features: Total Tests: 215
# Integration: Total Tests: 3
# Performance: Total Tests: 5
# All: Total Tests: 233
```

### 4. Commit Strategy
```bash
git add test/test_runner.lua
git add test/README.md
git add docs/PICK_TYPE.md

git commit -m "refactor(test-picker): Remove custom categories for clarity

- Remove duplicate test categories (lines 247-349)
- Add hierarchical display for features/ category
- Maintain 100% backward compatibility for test execution
- Improve picker clarity: 380 → 234 displayed tests
- All 233 tests still pass (100% pass rate maintained)

This change only affects the picker UI display. Test execution,
registry, and all other functionality remain unchanged."
```

## Post-Implementation Verification

### Success Criteria
1. ✓ All tests pass (233/233) - functionality preserved
2. ✓ Picker shows only directory categories
3. ✓ Features category has hierarchical display
4. ✓ No duplicate test entries
5. ✓ Clean, maintainable code

### Root Cause Analysis
**Issue**: Custom categories created confusion by duplicating tests
**Root Cause**: Well-intentioned thematic grouping conflicted with directory structure
**Fix**: Single source of truth - directory-based organization only
**Prevention**: Document decision to avoid future re-introduction

## Architecture Notes

### Why This is the Right Solution
1. **Simplicity**: Removes 100+ lines of redundant code
2. **Clarity**: 1:1 mapping between files and picker entries
3. **Maintainability**: No need to maintain two category systems
4. **User Experience**: Clear, predictable test organization

### Future-Proofing
- If thematic organization is needed, implement as filters/tags
- Keep picker display tied to actual file structure
- Maintain single source of truth principle

## Summary

This implementation removes confusion while preserving all functionality. The change is purely cosmetic (UI display only) with zero impact on test execution, making it a safe, high-value improvement.

Total implementation time: ~45 minutes including thorough testing.