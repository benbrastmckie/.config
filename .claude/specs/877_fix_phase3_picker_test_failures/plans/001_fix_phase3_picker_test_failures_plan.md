# Fix Phase 3 Picker Test Failures Implementation Plan

## Metadata
- **Date**: 2025-11-20
- **Feature**: Fix 9 test failures in picker registry and metadata modules after Phase 3 implementation
- **Scope**: Update test expectations for new artifact types and fix assertion patterns
- **Estimated Phases**: 4
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 24.5
- **Research Reports**:
  - [Test Failure Fix Research](/home/benjamin/.config/.claude/specs/877_fix_phase3_picker_test_failures/reports/001_test_failure_fix_research.md)

## Overview

Phase 3 implementation successfully added `script` and `test` artifact types to the picker registry, increasing total sync types from 11 to 13. This caused 9 test failures across registry and metadata modules due to: (1) outdated test count expectation, (2) incorrect assertion pattern usage with `string:match()`, and (3) a metadata parser logic bug. This plan addresses all failures through systematic test updates and parser fixes while documenting Lua testing best practices to prevent future regressions.

## Research Summary

Research identified three distinct root causes from analyzing test output, implementation code, and codebase standards:

1. **Count Mismatch** (1 failure): Registry test expects 11 sync types but implementation has 13 after adding script/test types in lines 97-133 of registry.lua
2. **Assertion Type Mismatches** (7 failures): Tests use `assert.is_true()`/`assert.is_false()` with `string:match()` which returns string/nil, not boolean true/false - violates Lua testing patterns found in scan_spec.lua:203-204
3. **Parser Logic Bug** (1 failure): metadata.lua:93-99 doesn't reset `after_title` flag when encountering subheadings, causing incorrect extraction of content after subheadings

All fixes are straightforward with clear implementation paths and low risk. Test patterns align with existing codebase standards (scan_spec.lua) and nvim/CLAUDE.md testing protocols.

## Success Criteria

- [ ] All 59 picker tests pass (currently 50 pass, 9 fail)
- [ ] Test runner exits with code 0
- [ ] Script and test artifact types visible in picker UI
- [ ] Markdown description parsing correctly ignores content after subheadings
- [ ] Lua testing assertion patterns documented in nvim/CLAUDE.md
- [ ] No regression in existing functionality

## Technical Design

### Architecture Overview

This is a test maintenance and bug fix effort targeting two files:
1. **registry_spec.lua**: Update test expectations and fix assertion patterns (8 fixes)
2. **metadata.lua**: Fix parser logic to handle subheadings correctly (1 fix)

### Component Interactions

- **registry_spec.lua** → **registry.lua**: Tests verify registry configuration matches implementation
- **metadata_spec.lua** → **metadata.lua**: Tests verify parser behavior matches documented expectations
- **nvim/CLAUDE.md**: Documentation update provides testing guidance for future development

### Key Decisions

1. **Assertion Pattern Standard**: Use `assert.is_not_nil()` for match success and `assert.is_nil()` for match failure - aligns with scan_spec.lua:203-204 pattern
2. **Parser Fix Approach**: Add explicit subheading detection (`^##`) to reset `after_title` flag rather than complex state management
3. **Documentation Location**: Add Lua testing patterns to nvim/CLAUDE.md testing section (after line 173) for discoverability

## Implementation Phases

### Phase 1: Fix Registry Test Count Expectation [COMPLETE]
dependencies: []

**Objective**: Update registry_spec.lua test to expect 13 sync types instead of 11

**Complexity**: Low

**Tasks**:
- [x] Read `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua` to locate line 112
- [x] Update line 112 from `assert.equals(11, #sync_types)` to `assert.equals(13, #sync_types)`
- [x] Add inline comment: `-- Now includes script and test types (Phase 3)`
- [x] Verify change with Read tool

**Testing**:
```bash
# Run registry test file
nvim --headless -c "PlenaryBustedFile nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua { minimal_init = 'tests/minimal_init.vim' }" -c "qa!"
```

**Expected Duration**: 0.25 hours

---

### Phase 2: Fix Registry Assertion Type Mismatches [COMPLETE]
dependencies: [1]

**Objective**: Replace incorrect boolean assertions with proper nil-checking assertions for string:match() return values

**Complexity**: Medium

**Tasks**:
- [x] Fix lines 120-121: Replace `assert.is_true()` with `assert.is_not_nil()` for format_heading test
- [x] Fix lines 127-128: Replace `assert.is_true()` with `assert.is_not_nil()` for agent heading test
- [x] Fix lines 146-148: Replace `assert.is_true()` with `assert.is_not_nil()` for local marker test
- [x] Fix line 159: Replace `assert.is_false()` with `assert.is_nil()` for missing local marker test
- [x] Fix lines 160-161: Replace `assert.is_true()` with `assert.is_not_nil()` for global command test
- [x] Fix line 173: Replace `assert.is_true()` with `assert.is_not_nil()` for hook_event indent test
- [x] Fix line 185: Replace `assert.is_true()` with `assert.is_not_nil()` for command indent test
- [x] Fix line 196: Replace `assert.is_false()` with `assert.is_nil()` for agent description prefix test
- [x] Fix line 197: Replace `assert.is_true()` with `assert.is_not_nil()` for agent description test
- [x] Verify all changes with Read tool

**Testing**:
```bash
# Run registry test file to verify assertion fixes
nvim --headless -c "PlenaryBustedFile nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/registry_spec.lua { minimal_init = 'tests/minimal_init.vim' }" -c "qa!"
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Fix Metadata Parser Subheading Bug [COMPLETE]
dependencies: [2]

**Objective**: Fix parse_doc_description() to properly handle subheadings by resetting after_title flag

**Complexity**: Low

**Tasks**:
- [x] Read `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata.lua` lines 93-99
- [x] Add new elseif clause after line 95: `elseif line:match("^##") then`
- [x] Add logic: `after_title = false` with comment `-- Found subheading - stop looking for description`
- [x] Verify existing logic at lines 96-99 remains unchanged
- [x] Test edge cases: title only, title with subheading, title with paragraph then subheading

**Testing**:
```bash
# Run metadata test file
nvim --headless -c "PlenaryBustedFile nvim/lua/neotex/plugins/ai/claude/commands/picker/artifacts/metadata_spec.lua { minimal_init = 'tests/minimal_init.vim' }" -c "qa!"
```

**Expected Duration**: 0.5 hours

---

### Phase 4: Document Lua Testing Patterns and Verify [COMPLETE]
dependencies: [3]

**Objective**: Document correct Lua assertion patterns and verify all tests pass

**Complexity**: Medium

**Tasks**:
- [x] Read `/home/benjamin/.config/nvim/CLAUDE.md` to locate testing section (after line 173)
- [x] Add new section "### Lua Testing Assertion Patterns" with:
  - Correct patterns: `assert.is_not_nil(str:match())` and `assert.is_nil(str:match())`
  - Incorrect patterns: `assert.is_true(str:match())` and `assert.is_false(str:match())`
  - Rationale: string:match() returns string/nil, not boolean true/false
  - Code examples showing correct and incorrect usage
- [x] Run full picker test suite to verify all 59 tests pass
- [x] Verify script and test artifact types appear in picker UI (manual test)
- [x] Verify markdown files with subheadings parse correctly (manual test)

**Testing**:
```bash
# Run full picker test suite
nvim --headless -c "PlenaryBustedDirectory nvim/lua/neotex/plugins/ai/claude/commands/picker/ { minimal_init = 'tests/minimal_init.vim' }" -c "qa!"

# Expected output: 59 passed, 0 failed, exit code 0
```

**Expected Duration**: 0.75 hours

---

## Testing Strategy

### Unit Testing
- Use plenary.nvim test framework with busted-style assertions
- Run individual test files with `:TestFile` command
- Verify each phase's changes before proceeding to next phase

### Integration Testing
- Run full picker test suite after all fixes applied
- Verify total test count: 59 passed, 0 failed
- Check exit code is 0 for CI/CD compatibility

### Manual Testing
1. Open Neovim picker UI
2. Verify "Scripts" section appears with script artifact types
3. Verify "Tests" section appears with test artifact types
4. Test markdown file with subheading structure:
   ```markdown
   # Main Title

   ## Subheading
   This should not be extracted
   ```
5. Verify picker shows no description (empty string) for above file

### Regression Testing
- Ensure all 50 previously passing tests still pass
- Verify no changes to registry.lua implementation (only test updates)
- Confirm metadata parser handles existing edge cases (title only, paragraph after title)

## Documentation Requirements

### Update nvim/CLAUDE.md
Add new section "Lua Testing Assertion Patterns" after line 173 in testing protocols section:
- Document correct assertion patterns for string:match()
- Explain rationale (string/nil vs boolean true/false)
- Provide code examples
- Reference this fix as motivation for documentation

### No Additional Documentation
No other documentation updates required:
- registry.lua already has inline documentation for script/test types
- metadata.lua change is internal logic fix (no API change)
- Test files are self-documenting with descriptive test names

## Dependencies

### External Dependencies
- plenary.nvim: Test framework (already installed)
- nvim-lua/busted: Assertion library (via plenary.nvim)

### Internal Dependencies
- registry.lua: Implementation is correct, no changes needed
- metadata.lua: Requires logic fix in Phase 3
- scan_spec.lua: Reference for correct assertion patterns (no changes)

### Prerequisites
- Neovim installed and configured
- Test environment accessible via `:TestFile` command
- minimal_init.vim present in tests/ directory

## Risk Assessment

### Low Risk Areas
- Test count update (Phase 1): Simple numeric change
- Parser logic fix (Phase 3): Isolated change with clear test coverage
- Documentation addition (Phase 4): No code impact

### Medium Risk Areas
- Assertion pattern changes (Phase 2): 14 individual assertion updates across 7 tests
  - Mitigation: Change is mechanical, pattern is proven in scan_spec.lua
  - Verification: Run tests after each file is modified

### No High Risk Areas
All changes are test-only or isolated bug fixes with comprehensive test coverage

## Notes

### Phase 3 Background [COMPLETE]
Phase 3 implementation (not part of this plan) successfully added script and test artifact types to registry.lua lines 97-133. Implementation is correct - only test expectations need updating.

### Assertion Pattern Discovery
The correct assertion pattern (`assert.is_not_nil` for string:match()) was discovered by analyzing scan_spec.lua:203-204, which uses this pattern consistently. This is the established codebase standard.

### Parser Bug Impact
The metadata parser bug affects markdown files with subheadings after the main title. Without the fix, content under subheadings is incorrectly extracted as the document description, violating the documented behavior of extracting only the first paragraph immediately after the title.
