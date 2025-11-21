# Debug Report: Phase 3 Test Failures After Scripts/Tests Artifact Type Addition

## Metadata
- **Date**: 2025-11-20
- **Agent**: debug-analyst
- **Issue**: 9 test failures in picker registry and metadata modules after Phase 3 implementation
- **Hypothesis**: Test expectations not updated to reflect new artifact types (scripts, tests) and assertion type mismatches
- **Status**: Investigating

## Issue Description

Tests failed with 9 failures in picker registry and metadata modules after Phase 3 implementation (scripts/tests artifact type support). Expected total artifact types increased from 11 to 13, but tests still expect 11. Additionally, multiple tests have assertion type mismatches where string values are being compared against boolean expectations.

## Failed Tests

### registry_spec.lua (8 failures)
1. get_sync_types includes all 11 artifact types - Expected 11, got 13
2. format_heading formats command heading correctly - Expected boolean true, got string '[Commands]'
3. format_heading formats agent heading correctly - Expected boolean true, got string '[Agents]'
4. format_artifact formats artifact with local marker - Expected boolean true, got string '*'
5. format_artifact formats artifact without local marker - Expected boolean false, got nil
6. format_artifact uses 2-space indent for hook_event - Expected boolean true, got string '  ├─'
7. format_artifact uses 1-space indent for commands - Expected boolean true, got string ' ├─'
8. format_artifact strips 'Specialized in' prefix from agent descriptions - Expected boolean false, got nil

### metadata_spec.lua (1 failure)
9. parse_doc_description ignores subheadings when looking for paragraph - Expected empty string, got 'This should not be extracted'

## Investigation

### Test Reproduction
Tests were run with the plenary test framework:
```bash
nvim --headless -c "PlenaryBustedDirectory nvim/lua/neotex/plugins/ai/claude/commands/picker/ { minimal_init = 'tests/minimal_init.vim' }"
```

Exit code: 1 (failure)
Results: 50 passed, 9 failed out of 59 total tests

### Evidence Gathering

#### 1. Registry Implementation Analysis
File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry.lua`

The registry now contains **13 artifact types** (lines 8-205):
1. command
2. agent
3. hook_event
4. tts_file
5. template
6. lib
7. **script** (NEW - lines 97-113)
8. **test** (NEW - lines 115-133)
9. doc
10. agent_protocol
11. standard
12. data_doc
13. settings

The `get_sync_types()` function (lines 234-242) correctly returns all types with `sync_enabled = true`, which includes all 13 types.

#### 2. Test Assertion Analysis
File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua`

**Problem 1: Outdated count expectation** (line 112)
```lua
assert.equals(11, #sync_types)  -- Expects 11, but registry has 13
```

**Problem 2-8: Incorrect assertion type usage** (lines 120, 127, 146, 159, 173, 185, 196)
Tests are using `assert.is_true()` and `assert.is_false()` with `string:match()` which returns:
- The matched string (truthy) on success
- `nil` (falsy) on failure

The tests expect boolean `true/false` but receive `string/nil`. Example:
```lua
-- Line 120: This returns a string, not boolean
assert.is_true(heading:match("%[Commands%]"))
-- Should be: assert.is_not_nil(heading:match("%[Commands%]"))
```

#### 3. Metadata Parser Bug
File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua`

The `parse_doc_description()` function (lines 67-103) has a logic flaw at line 96:
```lua
elseif after_title and line ~= "" and not line:match("^#") then
```

This condition checks `not line:match("^#")` which catches lines NOT starting with `#`. However, when the line immediately after the title is a subheading like `## Subheading`, the condition is evaluated as:
- `after_title = true` (title was found)
- `line = "## Subheading"` (not empty)
- `not line:match("^#")` evaluates to `false` because line DOES start with `#`

But on the NEXT line after the subheading:
- `after_title = true` (still true, never reset)
- `line = "This should not be extracted"` (not empty)
- `not line:match("^#")` evaluates to `true` (doesn't start with #)

The function extracts this content line after the subheading, which violates the test expectation. The function should reset `after_title` or check if we've hit a subheading.

## Root Cause Analysis

### Root Cause #1: Outdated Test Count (8 failures in registry_spec.lua)

**Hypothesis: CONFIRMED**

1. **Count Mismatch** (1 failure): Test expects 11 sync types but registry has 13 after Phase 3 added `script` and `test` artifact types.

2. **Assertion Type Mismatches** (7 failures): Tests use `assert.is_true()` and `assert.is_false()` with `string:match()` return values, but `string:match()` returns:
   - Matched string (truthy but not boolean `true`) on success
   - `nil` (falsy but not boolean `false`) on no match

   This causes type comparison failures in the test assertions.

**Evidence:**
- Line 112: `assert.equals(11, #sync_types)` expects 11, registry has 13
- Lines 120, 127, 146, 159, 173, 185, 196: All use `assert.is_true()` or `assert.is_false()` expecting boolean but receiving string/nil from `string:match()`

### Root Cause #2: Logic Bug in parse_doc_description (1 failure in metadata_spec.lua)

**Hypothesis: CONFIRMED**

The `parse_doc_description()` function doesn't properly handle subheadings after the title. The `after_title` flag remains true even after encountering a subheading, causing the function to extract content after subheadings.

**Evidence:**
- Line 96 in metadata.lua: `elseif after_title and line ~= "" and not line:match("^#")` doesn't reset `after_title` when hitting subheadings
- Test failure: Expected empty string but got "This should not be extracted" (content after subheading)

## Proposed Fix

### Fix #1: Update registry_spec.lua (8 test fixes)

**File:** `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua`

**Change 1 - Line 112:** Update count expectation
```lua
-- OLD:
assert.equals(11, #sync_types)

-- NEW:
assert.equals(13, #sync_types)  -- Now includes script and test types
```

**Change 2 - Lines 120-121:** Fix assertion type
```lua
-- OLD:
assert.is_true(heading:match("%[Commands%]"))
assert.is_true(heading:match("Slash commands"))

-- NEW:
assert.is_not_nil(heading:match("%[Commands%]"))
assert.is_not_nil(heading:match("Slash commands"))
```

**Change 3 - Lines 127-128:** Fix assertion type
```lua
-- OLD:
assert.is_true(heading:match("%[Agents%]"))
assert.is_true(heading:match("AI assistants"))

-- NEW:
assert.is_not_nil(heading:match("%[Agents%]"))
assert.is_not_nil(heading:match("AI assistants"))
```

**Change 4 - Lines 146-148:** Fix assertion type
```lua
-- OLD:
assert.is_true(result:match("^%*"))  -- Starts with * for local
assert.is_true(result:match("test%-command"))
assert.is_true(result:match("Test description"))

-- NEW:
assert.is_not_nil(result:match("^%*"))  -- Starts with * for local
assert.is_not_nil(result:match("test%-command"))
assert.is_not_nil(result:match("Test description"))
```

**Change 5 - Lines 159-161:** Fix assertion type
```lua
-- OLD:
assert.is_false(result:match("^%*"))  -- Does not start with *
assert.is_true(result:match("global%-command"))
assert.is_true(result:match("Global description"))

-- NEW:
assert.is_nil(result:match("^%*"))  -- Does not start with *
assert.is_not_nil(result:match("global%-command"))
assert.is_not_nil(result:match("Global description"))
```

**Change 6 - Line 173:** Fix assertion type
```lua
-- OLD:
assert.is_true(result:match("%s%s├─"))  -- Two spaces before tree char

-- NEW:
assert.is_not_nil(result:match("%s%s├─"))  -- Two spaces before tree char
```

**Change 7 - Line 185:** Fix assertion type
```lua
-- OLD:
assert.is_true(result:match("%s├─"))  -- One space before tree char

-- NEW:
assert.is_not_nil(result:match("%s├─"))  -- One space before tree char
```

**Change 8 - Lines 196-197:** Fix assertion type
```lua
-- OLD:
assert.is_false(result:match("Specialized in"))
assert.is_true(result:match("testing"))

-- NEW:
assert.is_nil(result:match("Specialized in"))
assert.is_not_nil(result:match("testing"))
```

### Fix #2: Fix parse_doc_description logic bug (1 test fix)

**File:** `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua`

**Change - Lines 93-99:** Add subheading detection
```lua
-- OLD:
elseif line:match("^#%s+[^#]") then
  -- Found a title heading (# Title, not ## Subheading)
  after_title = true
elseif after_title and line ~= "" and not line:match("^#") then
  -- Plain text after title, before any subheading
  return line:sub(1, 40)
end

-- NEW:
elseif line:match("^#%s+[^#]") then
  -- Found a title heading (# Title, not ## Subheading)
  after_title = true
elseif line:match("^##") then
  -- Found subheading - stop looking for description
  after_title = false
elseif after_title and line ~= "" and not line:match("^#") then
  -- Plain text after title, before any subheading
  return line:sub(1, 40)
end
```

### Fix Rationale

**Fix #1 Rationale:**
The test expectations were written before Phase 3 added the `script` and `test` artifact types. The assertions used incorrect Lua testing patterns - `string:match()` returns the matched string (not boolean true) or nil (not boolean false). Using `assert.is_not_nil()` and `assert.is_nil()` properly tests for match success/failure.

**Fix #2 Rationale:**
The parser's `after_title` flag was never reset after encountering subheadings, causing it to extract content from under subheadings. Adding explicit subheading detection (`^##`) to reset the flag ensures only the first paragraph immediately after the main title is extracted, not content after subheadings.

### Fix Complexity
- **Estimated time:** 15 minutes
- **Risk level:** Low
- **Testing required:** Run full test suite after fixes
- **Files affected:** 2 files (registry_spec.lua, metadata.lua)
- **Lines changed:** ~20 lines total

## Impact Assessment

### Scope
**Affected files:**
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua` (test file)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua` (implementation)

**Affected components:**
- Picker test suite (registry and metadata modules)
- Documentation description parser

**Severity:** Medium
- Tests are failing but functionality appears correct
- Parser bug could cause incorrect descriptions in picker UI

### Related Issues
- No other test failures or related issues identified
- The implementation added in Phase 3 (script/test types) is correct
- Only test expectations and parser logic need updating

### Verification Steps
1. Apply all fixes to both files
2. Run full picker test suite: `:TestFile` on both spec files
3. Verify all 59 tests pass
4. Manually test picker UI to confirm description parsing works correctly
5. Check that script and test artifact types appear in picker

## Recommendations

### Immediate Actions
1. Apply Fix #1 to update test expectations and assertion types
2. Apply Fix #2 to fix parse_doc_description logic
3. Run full test suite to verify all tests pass
4. Document the string:match() assertion pattern to prevent future occurrences

### Future Improvements
1. **Testing Standards**: Document the correct Lua assertion patterns in nvim/CLAUDE.md:
   - Use `assert.is_not_nil(string:match(...))` for match success
   - Use `assert.is_nil(string:match(...))` for match failure
   - Never use `assert.is_true()` with `string:match()` results

2. **Parser Robustness**: Consider adding more test cases for edge cases:
   - Multiple subheadings after title
   - Empty lines between title and subheading
   - Documents with only title and subheadings (no paragraphs)

3. **Type Safety**: Consider adding type annotations or assertions to catch these issues earlier

4. **Test Coverage**: Add tests for the new script and test artifact types to ensure they work correctly in the picker
