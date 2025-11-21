# Phase 3 Picker Test Failures - Fix Research Report

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Fix Phase 3 picker test failures (registry and metadata modules)
- **Report Type**: Codebase analysis and standards compliance
- **Debug Report**: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/debug/001_phase3_test_failures.md

## Executive Summary

Phase 3 implementation successfully added `script` and `test` artifact types to the picker registry (lines 97-133), increasing total sync types from 11 to 13. However, 9 test failures occurred due to: (1) outdated test expectation (line 112: expects 11, actual 13), (2) incorrect assertion pattern usage - 7 tests use `assert.is_true()`/`assert.is_false()` with `string:match()` which returns string/nil not boolean true/false (lines 120, 127, 146, 159, 173, 185, 196), and (3) metadata parser logic bug where `after_title` flag isn't reset when encountering subheadings (line 96), causing extraction of content after subheadings. Fixes require updating test count, replacing boolean assertions with `assert.is_not_nil()`/`assert.is_nil()` per Lua testing standards, and adding subheading detection to reset parser state.

## Findings

### 1. Root Cause Analysis - Test Count Mismatch

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua

**Issue**: Line 112 expects 11 sync types but registry now has 13 after Phase 3 added `script` and `test` types.

**Evidence**:
```lua
-- Line 108-113 (registry_spec.lua)
it("includes all 11 artifact types", function()
  local sync_types = registry.get_sync_types()
  -- Should have 11 types: command, agent, hook_event, tts_file, template,
  -- lib, doc, agent_protocol, standard, data_doc, settings
  assert.equals(11, #sync_types)  -- FAILS: actual is 13
end)
```

**Registry Implementation**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry.lua:97-133 shows two new types:
- `script` (lines 97-113): Extension `.sh`, subdirs `scripts/`, sync_enabled `true`
- `test` (lines 115-133): Extension `.sh`, subdirs `tests/`, sync_enabled `true`, pattern_filter `^test_`

**Correct Count**: 13 total sync types (original 11 + script + test)

**Fix**: Update line 112 from `assert.equals(11, #sync_types)` to `assert.equals(13, #sync_types)`

---

### 2. Root Cause Analysis - Assertion Type Mismatches (7 failures)

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua

**Issue**: Tests use `assert.is_true()` and `assert.is_false()` with `string:match()` return values, but Lua's `string:match()` returns:
- Matched substring (truthy but NOT boolean `true`) on success
- `nil` (falsy but NOT boolean `false`) on failure

**Standards Research**:

From /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md:44-198 (Agent Behavioral Compliance Testing section), proper Lua assertion patterns are documented.

From scan_spec.lua pattern analysis (lines 203-204):
```lua
assert.is_not_nil(dirs.project_dir)  -- Correct pattern for non-nil checks
assert.is_not_nil(dirs.global_dir)
```

From registry_spec.lua correct patterns (lines 36-49):
```lua
assert.is_true(registry.should_preserve_permissions("hook_event"))   -- OK: function returns boolean
assert.is_false(registry.should_preserve_permissions("command"))     -- OK: function returns boolean
```

**Incorrect Pattern Examples**:

1. **Lines 120-121** (format_heading test):
```lua
assert.is_true(heading:match("%[Commands%]"))      -- WRONG: returns string "[Commands]", not true
assert.is_true(heading:match("Slash commands"))    -- WRONG: returns string "Slash commands", not true
```

2. **Lines 159-161** (format_artifact test):
```lua
assert.is_false(result:match("^%*"))               -- WRONG: returns nil, not false
assert.is_true(result:match("global%-command"))    -- WRONG: returns string, not true
```

**Correct Pattern** (from other test files):
```lua
assert.is_not_nil(heading:match("%[Commands%]"))   -- CORRECT: tests for match success
assert.is_nil(result:match("^%*"))                 -- CORRECT: tests for match failure
```

**All 7 Failing Assertions**:
- Line 120: `assert.is_true(heading:match("%[Commands%]"))` → `assert.is_not_nil(...)`
- Line 121: `assert.is_true(heading:match("Slash commands"))` → `assert.is_not_nil(...)`
- Line 127: `assert.is_true(heading:match("%[Agents%]"))` → `assert.is_not_nil(...)`
- Line 128: `assert.is_true(heading:match("AI assistants"))` → `assert.is_not_nil(...)`
- Line 146: `assert.is_true(result:match("^%*"))` → `assert.is_not_nil(...)`
- Line 147: `assert.is_true(result:match("test%-command"))` → `assert.is_not_nil(...)`
- Line 148: `assert.is_true(result:match("Test description"))` → `assert.is_not_nil(...)`
- Line 159: `assert.is_false(result:match("^%*"))` → `assert.is_nil(...)`
- Line 160: `assert.is_true(result:match("global%-command"))` → `assert.is_not_nil(...)`
- Line 161: `assert.is_true(result:match("Global description"))` → `assert.is_not_nil(...)`
- Line 173: `assert.is_true(result:match("%s%s├─"))` → `assert.is_not_nil(...)`
- Line 185: `assert.is_true(result:match("%s├─"))` → `assert.is_not_nil(...)`
- Line 196: `assert.is_false(result:match("Specialized in"))` → `assert.is_nil(...)`
- Line 197: `assert.is_true(result:match("testing"))` → `assert.is_not_nil(...)`

---

### 3. Root Cause Analysis - Metadata Parser Logic Bug

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua

**Issue**: The `parse_doc_description()` function (lines 67-103) doesn't reset the `after_title` flag when encountering subheadings.

**Current Logic** (lines 93-99):
```lua
elseif line:match("^#%s+[^#]") then
  -- Found a title heading (# Title, not ## Subheading)
  after_title = true
elseif after_title and line ~= "" and not line:match("^#") then
  -- Plain text after title, before any subheading
  return line:sub(1, 40)
end
```

**Problem Flow**:
1. Line "# Main Title" matches `^#%s+[^#]` → `after_title = true`
2. Line "## Subheading" has `^##` which DOESN'T match `^#%s+[^#]` (has two `#`), so `after_title` stays `true`
3. Line "This should not be extracted" matches `after_title and line ~= "" and not line:match("^#")` → extracted incorrectly

**Test Expectation** (metadata_spec.lua:210-222):
```lua
it("ignores subheadings when looking for paragraph", function()
  local test_file = temp_dir .. "/test.md"
  local content = {
    "# Main Title",
    "",
    "## Subheading",
    "This should not be extracted",
  }
  vim.fn.writefile(content, test_file)

  local result = metadata.parse_doc_description(test_file)
  assert.equals("", result)  -- FAILS: gets "This should not be extracted"
end)
```

**Fix**: Add explicit subheading detection to reset `after_title`:
```lua
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

**Rationale**: When parser encounters `##` (subheading), it should stop looking for descriptions because content under subheadings is not the main document description. Resetting `after_title = false` prevents extraction of content that appears after subheadings.

---

### 4. Standards Compliance Analysis

**Lua Code Standards** (from /home/benjamin/.config/nvim/CLAUDE.md:11-23):
- Indentation: 2 spaces ✓ (tests use correct indentation)
- Error handling: Use pcall for operations that might fail ✓ (metadata.lua uses pcall)
- Naming: Descriptive lowercase names with underscores ✓ (test names are descriptive)

**Testing Standards** (from /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md:1-324):
- All public APIs must have tests ✓ (registry and metadata modules fully tested)
- Test location: `*_spec.lua` files adjacent to source ✓ (tests in same directory)
- Test framework: Busted/plenary.nvim ✓ (uses busted `describe`/`it` syntax)

**Assertion Best Practices** (derived from codebase analysis):
1. **Use `assert.is_not_nil()` for match success**: Tests that pattern exists in string
2. **Use `assert.is_nil()` for match failure**: Tests that pattern does NOT exist in string
3. **Use `assert.is_true()` ONLY with boolean-returning functions**: Not with `string:match()`
4. **Use `assert.is_false()` ONLY with boolean-returning functions**: Not with `string:match()`

**Examples from Working Tests**:
```lua
-- scan_spec.lua:203-204 (CORRECT)
assert.is_not_nil(dirs.project_dir)
assert.is_not_nil(dirs.global_dir)

-- registry_spec.lua:36-38 (CORRECT - function returns boolean)
assert.is_true(registry.should_preserve_permissions("hook_event"))
assert.is_true(registry.should_preserve_permissions("lib"))

-- registry_spec.lua:120 (INCORRECT - string:match returns string)
assert.is_true(heading:match("%[Commands%]"))  -- Should be assert.is_not_nil
```

---

### 5. Impact Assessment

**Affected Components**:
- Picker test suite: 9/59 tests failing (15% failure rate)
- Registry module: Implementation correct, tests need update
- Metadata module: Implementation has bug, needs logic fix

**Severity**: Medium
- Tests blocking but functionality works for most cases
- Parser bug affects markdown files with subheadings (edge case but important)
- No production code crashes, only test failures

**Risk Level**: Low
- Fixes are straightforward and well-understood
- All failures have clear root causes
- Changes isolated to test files and one parser function
- No breaking changes to public APIs

**Files Requiring Changes**:
1. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua` (8 fixes)
2. `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua` (1 fix)

**Lines Changed**: ~20 total lines across 2 files

**Estimated Time**: 15-20 minutes for implementation and verification

---

### 6. Verification Strategy

**Test Execution** (from /home/benjamin/.config/nvim/CLAUDE.md:4-8):
```vim
:TestFile    " Run all tests in current file
:TestSuite   " Run entire test suite
```

**Verification Steps**:
1. Apply all 9 fixes to both files
2. Run `:TestFile` on `registry_spec.lua` → expect 0 failures (currently 8)
3. Run `:TestFile` on `metadata_spec.lua` → expect 0 failures (currently 1)
4. Run full picker test suite → expect 59 passed, 0 failed
5. Manual verification: Open picker UI and verify script/test types appear
6. Manual verification: Test markdown files with subheadings parse correctly

**Success Criteria**:
- All 59 tests pass (currently 50 pass, 9 fail)
- Exit code 0 from test runner
- No regression in existing functionality
- Script and test artifact types visible in picker
- Markdown description parsing ignores content after subheadings

## Recommendations

### Recommendation 1: Update Test Count Expectation

**Action**: Update registry_spec.lua line 112 to expect 13 sync types instead of 11

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua:112

**Change**:
```lua
-- OLD:
assert.equals(11, #sync_types)

-- NEW:
assert.equals(13, #sync_types)  -- Now includes script and test types
```

**Rationale**: Registry now has 13 sync-enabled types after Phase 3 implementation. Test expectation must match implementation.

**Impact**: Fixes 1 test failure

---

### Recommendation 2: Fix Assertion Type Mismatches

**Action**: Replace all `assert.is_true(string:match(...))` with `assert.is_not_nil(...)` and `assert.is_false(string:match(...))` with `assert.is_nil(...)`

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua

**Changes** (14 assertion fixes across 7 tests):

Lines 120-121:
```lua
-- OLD:
assert.is_true(heading:match("%[Commands%]"))
assert.is_true(heading:match("Slash commands"))

-- NEW:
assert.is_not_nil(heading:match("%[Commands%]"))
assert.is_not_nil(heading:match("Slash commands"))
```

Lines 127-128:
```lua
-- OLD:
assert.is_true(heading:match("%[Agents%]"))
assert.is_true(heading:match("AI assistants"))

-- NEW:
assert.is_not_nil(heading:match("%[Agents%]"))
assert.is_not_nil(heading:match("AI assistants"))
```

Lines 146-148:
```lua
-- OLD:
assert.is_true(result:match("^%*"))
assert.is_true(result:match("test%-command"))
assert.is_true(result:match("Test description"))

-- NEW:
assert.is_not_nil(result:match("^%*"))
assert.is_not_nil(result:match("test%-command"))
assert.is_not_nil(result:match("Test description"))
```

Lines 159-161:
```lua
-- OLD:
assert.is_false(result:match("^%*"))
assert.is_true(result:match("global%-command"))
assert.is_true(result:match("Global description"))

-- NEW:
assert.is_nil(result:match("^%*"))
assert.is_not_nil(result:match("global%-command"))
assert.is_not_nil(result:match("Global description"))
```

Line 173:
```lua
-- OLD:
assert.is_true(result:match("%s%s├─"))

-- NEW:
assert.is_not_nil(result:match("%s%s├─"))
```

Line 185:
```lua
-- OLD:
assert.is_true(result:match("%s├─"))

-- NEW:
assert.is_not_nil(result:match("%s├─"))
```

Lines 196-197:
```lua
-- OLD:
assert.is_false(result:match("Specialized in"))
assert.is_true(result:match("testing"))

-- NEW:
assert.is_nil(result:match("Specialized in"))
assert.is_not_nil(result:match("testing"))
```

**Rationale**: Lua's `string:match()` returns matched substring (string) or `nil`, not boolean `true`/`false`. Using `assert.is_not_nil()` and `assert.is_nil()` tests for match success/failure correctly. This pattern is consistent with other test files in the codebase (scan_spec.lua:203-204).

**Impact**: Fixes 7 test failures (14 individual assertions)

---

### Recommendation 3: Fix Metadata Parser Subheading Bug

**Action**: Add explicit subheading detection to reset `after_title` flag

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua:93-99

**Change**:
```lua
-- OLD (lines 93-99):
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

**Rationale**: Document descriptions should come from the first paragraph immediately after the main title (# Title), not from content under subheadings (## Section). When parser encounters a subheading, it should stop looking for descriptions. This matches the documented behavior and test expectations.

**Impact**: Fixes 1 test failure, improves description extraction accuracy for markdown files

---

### Recommendation 4: Document Lua Testing Assertion Patterns

**Action**: Add assertion pattern guide to nvim/CLAUDE.md testing section

**File**: /home/benjamin/.config/nvim/CLAUDE.md (Testing Protocols section)

**Addition** (after line 173):
```markdown
### Lua Testing Assertion Patterns

When testing string matching with Busted/plenary.nvim:

**CORRECT Patterns**:
- `assert.is_not_nil(str:match("pattern"))` - Test that pattern exists
- `assert.is_nil(str:match("pattern"))` - Test that pattern does NOT exist
- `assert.is_true(func())` - ONLY when function returns boolean true
- `assert.is_false(func())` - ONLY when function returns boolean false

**INCORRECT Patterns** (common mistakes):
- `assert.is_true(str:match("pattern"))` - WRONG: match returns string, not true
- `assert.is_false(str:match("pattern"))` - WRONG: match returns nil, not false

**Rationale**: Lua's `string:match()` returns the matched substring (truthy but not boolean `true`) on success, or `nil` (falsy but not boolean `false`) on failure. Boolean assertions fail type checks.

**Examples**:
```lua
-- Correct
local result = "test string"
assert.is_not_nil(result:match("test"))     -- Checks for match success
assert.is_nil(result:match("missing"))      // Checks for match failure

-- Incorrect
assert.is_true(result:match("test"))        -- Type error: string ≠ true
assert.is_false(result:match("missing"))    -- Type error: nil ≠ false
```
```

**Rationale**: Prevents future test failures from incorrect assertion usage. Documents the pattern discovered during this fix. Provides examples for developers.

**Impact**: Prevents regression, improves developer experience

---

### Recommendation 5: Add Test Coverage for New Artifact Types

**Action**: Add dedicated tests for `script` and `test` artifact types in registry_spec.lua

**File**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua

**Addition** (after line 93, before `describe("get_sync_types")` section):
```lua
it("includes script and test types added in Phase 3", function()
  local visible = registry.get_visible_types()
  local names = {}
  for _, config in ipairs(visible) do
    names[config.name] = true
  end

  -- Phase 3 additions should be visible
  assert.is_true(names["script"])
  assert.is_true(names["test"])
end)

it("configures script type correctly", function()
  local config = registry.get_type("script")
  assert.is_not_nil(config)
  assert.equals("script", config.name)
  assert.equals(".sh", config.extension)
  assert.equals("Scripts", config.plural)
  assert.is_true(config.sync_enabled)
  assert.is_true(config.picker_visible)
  assert.is_true(config.preserve_permissions)
end)

it("configures test type correctly", function()
  local config = registry.get_type("test")
  assert.is_not_nil(config)
  assert.equals("test", config.name)
  assert.equals(".sh", config.extension)
  assert.equals("Tests", config.plural)
  assert.is_true(config.sync_enabled)
  assert.is_true(config.picker_visible)
  assert.is_true(config.preserve_permissions)
  assert.equals("^test_", config.pattern_filter)
end)
```

**Rationale**: Explicit test coverage for new features ensures they work correctly and prevents regression. Tests verify configuration matches implementation (registry.lua:97-133).

**Impact**: Increases test coverage from 59 to 62 tests, documents Phase 3 additions

## References

### Source Files Analyzed

**Implementation Files**:
- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry.lua:1-250
  - Lines 8-205: ARTIFACT_TYPES configuration (13 types total)
  - Lines 97-113: `script` artifact type (Phase 3 addition)
  - Lines 115-133: `test` artifact type (Phase 3 addition)
  - Lines 234-242: `get_sync_types()` function

- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua:1-120
  - Lines 67-103: `parse_doc_description()` function
  - Lines 93-99: Subheading detection logic (bug location)

**Test Files**:
- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua:1-223
  - Line 112: Count expectation failure
  - Lines 120, 127, 146, 159, 173, 185, 196: Assertion type mismatches

- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata_spec.lua:1-262
  - Lines 210-222: Subheading test that exposes parser bug

- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan_spec.lua:203-204
  - Correct assertion pattern examples (`assert.is_not_nil()`)

**Standards Documentation**:
- /home/benjamin/.config/.claude/docs/reference/standards/testing-protocols.md:1-324
  - Lines 1-43: Test discovery and patterns
  - Lines 44-198: Agent behavioral compliance testing (assertion patterns)
  - Lines 200-262: Test isolation standards

- /home/benjamin/.config/.claude/docs/reference/standards/code-standards.md:1-199
  - Lines 1-16: General coding principles
  - Lines 17-29: Command/agent architecture standards

- /home/benjamin/.config/nvim/CLAUDE.md:1-185
  - Lines 4-8: Test commands (`:TestFile`, `:TestSuite`)
  - Lines 11-23: Lua code style standards
  - Lines 156-169: Testing protocols

**Debug Report**:
- /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/debug/001_phase3_test_failures.md:1-314
  - Complete analysis of all 9 test failures
  - Detailed root cause analysis
  - Proposed fixes with code examples

## Implementation Status
- **Status**: Planning Complete
- **Plan**: [../plans/001_fix_phase3_picker_test_failures_plan.md](../plans/001_fix_phase3_picker_test_failures_plan.md)
- **Implementation**: [Will be updated by /build command]
- **Date**: 2025-11-20
