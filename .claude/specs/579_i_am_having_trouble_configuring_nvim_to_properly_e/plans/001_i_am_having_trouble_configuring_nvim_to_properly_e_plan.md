# Fix Neovim Pair Expansion CR Behavior Implementation Plan

## Metadata
- **Date**: 2025-11-04
- **Feature**: Fix CR key behavior to properly expand pairs without always creating newlines
- **Scope**: Modify autopairs CR mapping to use autopairs_cr() API for conditional pair expansion
- **Estimated Phases**: 4
- **Estimated Hours**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Structure Level**: 0
- **Complexity Score**: 18.0
- **Research Reports**:
  - [Current Nvim Pair Expansion Configuration Research](../reports/001_current_nvim_pair_expansion_configuration_research.md)
  - [Pair Expansion Plugin Solutions Research](../reports/002_pair_expansion_plugin_solutions_research.md)
  - [CR Behavior Without Always Creating Newline Research](../reports/003_cr_behavior_without_always_creating_newline_research.md)

## Overview

The current Neovim configuration uses nvim-autopairs with blink.cmp integration, but the CR (carriage return) mapping implementation has issues:

1. **Current Problem**: Manual CR implementation using `check_break_line_char()` and `<CR><C-o>O` doesn't leverage autopairs' full logic
2. **Desired Behavior**: CR should only expand pairs when cursor is between brackets (e.g., `{|}`) and behave normally otherwise
3. **Solution**: Replace manual implementation with official `autopairs_cr()` API function

The goal is to achieve "smart" CR behavior that:
- Expands pairs with proper indentation when between brackets: `{|}` → `{\n  |\n}`
- Behaves normally in plain text contexts: `hello|` → `hello\n|`
- Accepts completion when blink.cmp menu is visible
- Respects all autopairs rules, treesitter context, and conditional logic

## Research Summary

Key findings from research reports:

**From Report 1 (Current Configuration)**:
- Configuration already has `map_cr = false` (correct for custom integration)
- Current implementation uses `check_break_line_char()` with manual `<CR><C-o>O`
- blink.cmp integration function exists but doesn't use autopairs' official API
- Treesitter integration enabled (`check_ts = true`) for context-aware pairing

**From Report 2 (Plugin Solutions)**:
- nvim-autopairs provides `autopairs_cr()` function specifically for this use case
- This function handles all context detection, indentation, rule conditions automatically
- Manual implementation with `check_break_line_char()` bypasses autopairs' sophisticated logic
- Recommended pattern: Check completion visibility first, then call `autopairs_cr()`

**From Report 3 (CR Behavior Best Practices)**:
- Primary recommendation: Replace `check_break_line_char()` with `autopairs_cr()`
- Remove redundant CR mapping from blink-cmp.lua (conflicts with autopairs mapping)
- `autopairs_cr()` respects all rules including `:with_cr()` conditions for specific pairs
- Returns empty string after accepting completion, not `<Ignore>`

**Implementation Consensus**:
All three reports recommend using the official `autopairs_cr()` API instead of manual implementation. This ensures proper integration with autopairs' treesitter context detection, rule conditions, and indentation logic.

## Success Criteria

- [ ] CR expands pairs when cursor is between matching brackets (e.g., `{|}`, `(|)`, `[|]`)
- [ ] CR behaves normally in plain text contexts (no expansion)
- [ ] CR accepts completion when blink.cmp menu is visible
- [ ] No extra newlines created after accepting completion
- [ ] Treesitter context respected (no expansion in strings/comments)
- [ ] LaTeX special rules preserved (no expansion between `$|$`)
- [ ] All existing autopairs rules continue to work
- [ ] No CR mapping conflicts between blink-cmp.lua and autopairs.lua
- [ ] Tests pass: bracket expansion, completion acceptance, normal typing

## Technical Design

### Architecture Overview

**Current Architecture**:
```
User presses CR
    ↓
autopairs.lua CR mapping (line 105)
    ├─ blink.is_visible() → Accept completion
    └─ check_break_line_char() → Manual <CR><C-o>O or <CR>
```

**Target Architecture**:
```
User presses CR
    ↓
autopairs.lua CR mapping (updated)
    ├─ blink.is_visible() → Accept completion, return ''
    └─ autopairs_cr() → Automatic smart expansion or normal CR
                         (respects rules, treesitter, indentation)
```

### Key Components

1. **autopairs.lua**: `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua`
   - Lines 90-124: `setup_blink_integration()` function
   - Lines 105-120: CR keymap to be updated

2. **blink-cmp.lua**: `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/blink-cmp.lua`
   - Line 76: CR mapping to be removed/commented

3. **autopairs Rules**: Lines 44-87 in autopairs.lua
   - LaTeX space handling rules (line 53-64)
   - LaTeX dollar sign rules (line 67-81)
   - All rules use `:with_cr()` conditions that will be respected by `autopairs_cr()`

### API Functions

1. **`npairs.autopairs_cr()`**: Official autopairs CR handler
   - Returns terminal codes for bracket expansion or normal CR
   - Respects all rules, conditions, treesitter integration
   - Handles indentation automatically

2. **`blink.is_visible()`**: Check if completion menu is open
   - Returns boolean

3. **`blink.accept()`**: Accept currently selected completion
   - Returns void, triggers completion acceptance

### Integration Flow

1. **Completion Menu Visible**: Accept completion, return empty string
2. **Between Brackets**: `autopairs_cr()` returns expansion sequence
3. **Normal Context**: `autopairs_cr()` returns normal `<CR>`
4. **Special Contexts**: `autopairs_cr()` respects rule conditions (e.g., LaTeX `$|$`)

## Implementation Phases

### Phase 1: Update autopairs CR Mapping
dependencies: []

**Objective**: Replace manual CR implementation with official `autopairs_cr()` API

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua`
- [x] Locate `setup_blink_integration()` function (lines 90-124)
- [x] Replace lines 105-120 (current CR mapping) with new implementation using `autopairs_cr()`
- [x] Change return value after completion acceptance from `t('<Ignore>')` to empty string `''`
- [x] Update keymap description to reflect new behavior
- [x] Verify keymap options remain: `{ expr = true, silent = true, noremap = true, replace_keycodes = false }`

**New Implementation Pattern**:
```lua
vim.keymap.set('i', '<CR>', function()
  if blink.is_visible() then
    blink.accept()
    return ''  -- Empty string, not <Ignore>
  else
    return npairs.autopairs_cr()  -- Official API handles everything
  end
end, { expr = true, silent = true, noremap = true, replace_keycodes = false, desc = "Accept completion or smart autopairs CR" })
```

**Testing**:
```bash
# Manual testing in Neovim
# 1. Test bracket expansion: Type { then } then CR
# 2. Test completion: Trigger completion, press CR
# 3. Test normal text: Type "hello" then CR
```

**Expected Duration**: 30 minutes

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [x] Update this plan file: Mark completed tasks with [x]
- [x] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 1 Completion Requirements**:
- [x] All phase tasks marked [x]
- [x] Tests passing (manual testing shows correct behavior)
- [x] Git commit created: `feat(579): complete Phase 1 - Update autopairs CR mapping to use autopairs_cr() API`
- [x] Checkpoint saved (if complex phase)
- [x] Update this plan file with phase completion status

[COMPLETED]

### Phase 2: Remove Redundant CR Mapping from blink-cmp.lua
dependencies: [1]

**Objective**: Eliminate CR mapping conflict by removing blink-cmp's CR keymap

**Complexity**: Low

**Tasks**:
- [ ] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/blink-cmp.lua`
- [ ] Locate keymap configuration section (around line 67-84)
- [ ] Find CR mapping at line 76: `['<CR>'] = { 'accept', 'fallback' }`
- [ ] Comment out or remove the CR mapping line
- [ ] Add comment explaining CR is handled by autopairs.lua integration
- [ ] Verify no syntax errors in keymap table after removal

**Implementation**:
```lua
keymap = {
  preset = 'default',
  ['<C-k>'] = { 'select_prev', 'fallback' },
  ['<C-j>'] = { 'select_next', 'fallback' },
  -- ... other mappings
  -- CR mapping removed - handled by autopairs.lua integration
  -- ['<CR>'] = { 'accept', 'fallback' },
  ['<Tab>'] = {
    'snippet_forward',
    'select_and_accept',
    'fallback'
  },
  -- ... rest of keymap
}
```

**Testing**:
```bash
# Restart Neovim and verify:
# 1. No CR mapping conflicts
# 2. Completion still works correctly
# 3. Which-key shows correct CR mapping from autopairs.lua
```

**Expected Duration**: 15 minutes

**Phase 2 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(579): complete Phase 2 - Remove redundant CR mapping from blink-cmp.lua`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 3: Comprehensive Testing and Validation
dependencies: [1, 2]

**Objective**: Verify all CR behaviors work correctly in various contexts

**Complexity**: Medium

**Tasks**:
- [ ] Create test file `/tmp/test_autopairs_cr.lua` for manual testing
- [ ] Test bracket expansion: `{|}`, `(|)`, `[|]`
- [ ] Test nested brackets: `{[|]}`
- [ ] Test completion acceptance with CR (trigger LSP completion)
- [ ] Test normal text CR behavior (no expansion)
- [ ] Test string context (should NOT expand, treesitter check)
- [ ] Test comment context (should NOT expand, treesitter check)
- [ ] Test LaTeX math mode: `$|$` (should NOT expand per rules)
- [ ] Test LaTeX braces: `{|}` (should expand normally)
- [ ] Test Lean unicode pairs: `⟨|⟩`, `«|»`
- [ ] Verify no extra newlines after completion acceptance
- [ ] Test with Tab completion as alternative (should still work)

**Test Scenarios**:
```lua
-- Scenario 1: Bracket expansion
-- Type: {}<CR> (when cursor between {|})
-- Expected:
-- {
--   |
-- }

-- Scenario 2: Normal text
-- Type: hello<CR>
-- Expected:
-- hello
-- |

-- Scenario 3: Completion acceptance
-- Type: req<trigger-completion><CR>
-- Expected: "require" inserted, no extra newline

-- Scenario 4: String context (treesitter check)
-- Type: "hello|"<CR>
-- Expected: Normal newline (no bracket expansion logic)

-- Scenario 5: LaTeX math (rule condition)
-- In .tex file: $x + y|$<CR>
-- Expected: Normal newline (with_cr(cond.none()) rule)
```

**Testing**:
```bash
# Open Neovim with test file
nvim /tmp/test_autopairs_cr.lua

# Run through all test scenarios above
# Document any failures or unexpected behavior
```

**Expected Duration**: 1 hour

<!-- PROGRESS CHECKPOINT -->
After completing the above tasks:
- [ ] Update this plan file: Mark completed tasks with [x]
- [ ] Verify changes with git diff
<!-- END PROGRESS CHECKPOINT -->

**Phase 3 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(579): complete Phase 3 - Comprehensive testing and validation`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

### Phase 4: Documentation and Cleanup
dependencies: [1, 2, 3]

**Objective**: Document changes and finalize implementation

**Complexity**: Low

**Tasks**:
- [ ] Update autopairs.lua comments to reflect new `autopairs_cr()` usage
- [ ] Document the integration pattern in code comments (lines 89-93)
- [ ] Add inline comment explaining why blink-cmp.lua doesn't map CR
- [ ] Update research report implementation status sections (3 reports)
- [ ] Mark all reports as "Implementation Complete" with plan reference
- [ ] Verify all LaTeX/Lean special rules still documented
- [ ] Clean up any commented-out code from previous implementation
- [ ] Run final smoke test of all scenarios

**Documentation Updates**:
```lua
-- In autopairs.lua (around line 89):
-- blink.cmp integration for Enter key with autopairs
-- Uses autopairs_cr() API for proper bracket expansion that respects:
-- - All autopairs rules and :with_cr() conditions
-- - Treesitter context (no expansion in strings/comments)
-- - Custom rules (LaTeX $$ pairs, Lean unicode, etc.)
-- Strategy: Check completion menu first, then delegate to autopairs_cr()
```

**Testing**:
```bash
# Final smoke test
nvim /tmp/test_autopairs_cr.lua

# Quick verification of:
# 1. Bracket expansion works
# 2. Normal CR works
# 3. Completion works
# 4. No errors in :messages
```

**Expected Duration**: 45 minutes

**Phase 4 Completion Requirements**:
- [ ] All phase tasks marked [x]
- [ ] Tests passing (run test suite per Testing Protocols in CLAUDE.md)
- [ ] Git commit created: `feat(579): complete Phase 4 - Documentation and cleanup`
- [ ] Checkpoint saved (if complex phase)
- [ ] Update this plan file with phase completion status

## Testing Strategy

### Unit Tests
- No formal unit tests (manual testing only for keymap behavior)
- Verify keymap registration: `:verbose imap <CR>` should show autopairs.lua mapping

### Integration Tests
- Test blink.cmp + autopairs integration in real editing scenarios
- Test multiple filetypes: Lua, TeX, Lean, Markdown, Python
- Verify treesitter integration prevents unwanted expansions

### Manual Test Suite
1. **Bracket Expansion Tests**: All pair types (`()`, `[]`, `{}`, unicode pairs)
2. **Context Tests**: Strings, comments, math mode, normal text
3. **Completion Tests**: LSP completion with CR acceptance
4. **Filetype Tests**: LaTeX special rules, Lean unicode, general Lua
5. **Edge Cases**: Nested brackets, cursor at different positions

### Regression Tests
- Ensure existing autopairs rules continue to work
- Verify LaTeX space handling rules still functional
- Confirm Lean unicode pairs still expand correctly
- Check treesitter disable for Java/Lean still respected

### Success Metrics
- All 12 test scenarios in Phase 3 pass
- No error messages in `:messages` after testing
- Subjective "feel" matches expected behavior
- No conflicts or duplicate mappings shown in `:verbose imap <CR>`

## Documentation Requirements

### Code Comments
- Update autopairs.lua function documentation (setup_blink_integration)
- Inline comments explaining autopairs_cr() usage
- Comment in blink-cmp.lua explaining CR removal

### Research Reports
- Update implementation status in all 3 research reports
- Add plan reference to each report
- Mark status as "Implementation Complete"

### Configuration Documentation
- No user-facing documentation needed (internal config change)
- Code comments serve as internal documentation

## Dependencies

### Internal Dependencies
- nvim-autopairs plugin (already installed)
- blink.cmp plugin (already installed)
- Treesitter integration (already configured)

### External Dependencies
- None (all dependencies already satisfied)

### Prerequisite Knowledge
- Understanding of Lua keymap functions
- Familiarity with nvim-autopairs API
- Knowledge of blink.cmp completion system

### Configuration Files
- `/home/benjamin/.config/nvim/lua/neotex/plugins/tools/autopairs.lua` (modify)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/lsp/blink-cmp.lua` (modify)

## Risk Assessment

### Low Risk
- **Change scope**: Minimal changes to two files only
- **Fallback**: Can easily revert to previous implementation
- **Testing**: Manual testing covers all scenarios

### Potential Issues
1. **Return value**: Changed from `t('<Ignore>')` to `''` - may affect completion
   - Mitigation: Research reports confirm `''` is correct
2. **Timing**: blink.cmp may not be loaded when autopairs initializes
   - Mitigation: Already handled with `pcall` and API check
3. **Keymap conflict**: Multiple CR mappings could interfere
   - Mitigation: Phase 2 removes redundant mapping

### Rollback Plan
If implementation fails:
1. Revert Phase 1 changes (git checkout autopairs.lua)
2. Revert Phase 2 changes (git checkout blink-cmp.lua)
3. Restart Neovim
4. Diagnose issue from error messages

## Implementation Notes

### Why autopairs_cr() vs. Manual Implementation

**Current Manual Approach**:
- Uses `check_break_line_char()` for detection only
- Manually constructs `<CR><C-o>O` terminal codes
- Bypasses autopairs' rule conditions and treesitter logic

**Official autopairs_cr() Approach**:
- Handles detection AND execution
- Respects all autopairs rules including `:with_cr()` conditions
- Integrates with treesitter context checking
- Properly handles indentation
- Maintained by autopairs plugin (future-proof)

### Integration Pattern

The pattern used here (check completion → delegate to autopairs) is the recommended approach from nvim-autopairs documentation and community best practices. This ensures:
1. Single source of truth for CR behavior (autopairs)
2. No duplication of logic
3. Automatic benefit from autopairs improvements
4. Cleaner, more maintainable code

### Configuration Philosophy

This implementation follows the principle: "Use official APIs when available". The manual implementation with `check_break_line_char()` worked but was essentially reimplementing functionality that autopairs already provides through `autopairs_cr()`.
