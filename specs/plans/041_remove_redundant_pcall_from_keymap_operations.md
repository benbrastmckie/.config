# Remove Redundant pcall from Keymap Operations

## Metadata
- **Date**: 2025-10-08
- **Feature**: Simplify keymap operations to match Telescope best practices
- **Scope**: Remove pcall wrappers from vim.keymap.set calls while keeping buffer validation
- **Estimated Phases**: 1
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/nvim/specs/reports/041_telescope_picker_buffer_validation_best_practices.md

## Overview

Based on comprehensive research of Telescope.nvim source code, the current implementation uses redundant error handling. Telescope NEVER wraps `vim.keymap.set()` calls in pcall - out of 84 pcall usages in Telescope source, zero are for keymap operations.

**Current State**: Using both buffer validation AND pcall for keymap.set
**Telescope Pattern**: Buffer validation only, no pcall for keymap.set
**Conclusion**: pcall wrapper is unnecessary and doesn't match idiomatic Telescope code

The buffer validation checks (added in commit 79728f2) are correct and should be kept. The pcall wrappers (added in commit 5850108) should be removed.

## Success Criteria
- [ ] pcall wrapper removed from Tab handler keymap.set (line 2773)
- [ ] pcall wrapper removed from Return handler keymap.set (line 2832)
- [ ] Buffer validation checks preserved (lines 2764, 2827)
- [ ] Code matches Telescope.nvim patterns
- [ ] No E5108 errors when using picker
- [ ] All existing picker functionality preserved
- [ ] Code follows Neovim configuration guidelines (nvim/CLAUDE.md)

## Technical Design

### 1. Current Implementation (Over-Engineered)

**Tab Handler (Line 2773)**:
```lua
-- Buffer validation check (KEEP THIS)
if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) or
   not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
  return
end

-- Switch focus
preview_focused = true
vim.api.nvim_set_current_win(preview_winid)

-- pcall wrapper (REMOVE THIS)
pcall(vim.keymap.set, "n", "<Esc>", function()
  preview_focused = false
  if vim.api.nvim_win_is_valid(picker.prompt_win) then
    vim.api.nvim_set_current_win(picker.prompt_win)
  end
end, { buffer = preview_bufnr, nowait = true })
```

**Return Handler (Line 2832)**:
```lua
-- Buffer validation check (KEEP THIS)
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) and
   preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  -- pcall wrapper (REMOVE THIS)
  pcall(vim.keymap.set, "n", "<Esc>", function()
    preview_focused = false
    return_stage = "first"
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })
```

### 2. Telescope Pattern (Idiomatic)

From research report findings, Telescope uses this pattern:

```lua
-- Validate buffer BEFORE operations
if buf and vim.api.nvim_buf_is_valid(buf) then
  -- Direct keymap.set call, NO pcall
  vim.keymap.set("n", "key", function() ... end, { buffer = buf })
end
```

**Evidence**:
- `telescope/mappings.lua:202`: `vim.keymap.set(mode, key_bind, mode_func, opts)`
- `telescope/actions/init.lua:156`: Buffer validation before operations
- `builtin/lsp.lua:183`: Direct keymap.set with buffer option
- ZERO pcall wrappers for keymap.set in entire Telescope codebase

### 3. Why pcall is Unnecessary

**From Research Report Section 4.2**:

1. **Buffer validation prevents the error condition** - If buffer is valid at validation, keymap.set succeeds
2. **Race condition window is tiny** - Buffer rarely invalidates between check and set
3. **API behavior** - vim.keymap.set with invalid buffer fails silently (no error throw)
4. **Telescope evidence** - 84 pcall usages, ZERO for keymap.set
5. **Historical commits** - Telescope fixed buffer issues with validation, not pcall

### 4. Recommended Implementation

**Tab Handler**:
```lua
if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) or
   not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
  return
end

preview_focused = true
vim.api.nvim_set_current_win(preview_winid)

-- Direct keymap.set (matches Telescope pattern)
vim.keymap.set("n", "<Esc>", function()
  preview_focused = false
  if vim.api.nvim_win_is_valid(picker.prompt_win) then
    vim.api.nvim_set_current_win(picker.prompt_win)
  end
end, { buffer = preview_bufnr, nowait = true })
```

**Return Handler**:
```lua
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) and
   preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  -- Direct keymap.set (matches Telescope pattern)
  vim.keymap.set("n", "<Esc>", function()
    preview_focused = false
    return_stage = "first"
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })
```

## Implementation Phases

### Phase 1: Remove pcall Wrappers from Keymap Operations [COMPLETED]
**Objective**: Simplify code to match Telescope's idiomatic pattern
**Complexity**: Low

Tasks:
- [x] Read current Tab handler keymap operation (line 2773)
- [x] Remove pcall wrapper, keep direct vim.keymap.set call
- [x] Update inline comment to reflect Telescope pattern
- [x] Read current Return handler keymap operation (line 2832)
- [x] Remove pcall wrapper, keep direct vim.keymap.set call
- [x] Update inline comment to reflect Telescope pattern
- [x] Verify buffer validation checks are still in place (lines 2764, 2827)
- [x] Test picker with various artifact types
- [x] Test rapid key presses to verify no errors
- [x] Test help section preview focus
- [x] Verify Tab and Return handlers work correctly

Testing:
```bash
# Open picker with <leader>ac
# Test Tab key on various items - verify preview focuses
# Test Return key on various items - verify two-stage behavior works
# Test help section - verify preview focus and scrolling
# Test rapid key presses - verify no errors
# Verify all existing functionality preserved
```

## Testing Strategy

### Manual Testing
All changes require testing in Neovim:
1. Open picker with `<leader>ac`
2. Test Tab key on commands, agents, docs, templates, etc.
3. Test Return key on all artifact types
4. Test help section preview focus with Return
5. Test rapid Tab/Return presses
6. Verify no E5108 errors occur
7. Confirm all existing functionality works

### Test Cases
- **Tab Handler**:
  - Tab on command (preview focuses)
  - Tab on agent (preview focuses)
  - Tab on help section (preview focuses)
  - Esc from preview (returns to picker)

- **Return Handler**:
  - First Return on command (preview focuses)
  - Second Return on command (inserts into Claude Code)
  - First Return on help (preview focuses)
  - Second Return on help (returns to picker)
  - Selection change resets return_stage

### Regression Testing
- All existing keybindings work (`<C-e>`, `<C-l>`, `<C-u>`, `<C-s>`)
- Two-stage Return behavior preserved
- Preview focus navigation works
- Search and filtering work correctly
- State management across selection changes

## Documentation Requirements

### Files to Update
- Inline code comments in `picker.lua` - Update comments to reflect Telescope pattern

### Documentation Content
- Remove mention of pcall for buffer lifecycle safety
- Note that buffer validation alone matches Telescope best practices
- Reference research report if needed for future maintainers

## Dependencies

### Existing Code Dependencies
- Buffer validation checks (must be preserved)
- Telescope.nvim API patterns
- Existing two-stage Return behavior

### No External Dependencies
All changes are simplifications using existing APIs.

## Notes

### Design Decisions

1. **Keep Buffer Validation**: Essential for preventing errors in async contexts. Matches Telescope pattern from commit f15af58 (2021).

2. **Remove pcall Wrapper**: Unnecessary based on Telescope's codebase. No instances of pcall for keymap.set in 84 total pcall usages.

3. **Match Telescope Pattern**: Using idiomatic code makes the picker easier to maintain and understand for developers familiar with Telescope.

4. **No Functionality Loss**: Buffer validation prevents the error condition that pcall was meant to catch. The pcall adds no additional safety.

5. **Simpler Code**: Removing pcall wrapper makes code more readable and reduces cognitive overhead.

### Research Summary

From report 041 findings:

**Buffer Lifecycle** (Section 2):
- Buffers can become invalid when picker closes, selection changes, or Telescope internals recreate buffers
- Validation checks catch 99%+ of these cases
- Race condition window between validation and keymap.set is negligible

**Telescope Patterns** (Section 3):
- 12 examples of buffer validation before operations
- Zero examples of pcall for keymap.set
- Pattern: Validate → Operate, no pcall wrapper

**Error Handling Strategy** (Section 4):
- Use pcall for: file I/O, external commands, API calls that throw
- Don't use pcall for: keymap operations, buffer operations with validation
- vim.keymap.set with invalid buffer fails gracefully (no error throw)

### Implementation Simplicity

This refactor is straightforward because:
- Only removes pcall wrappers (reduces code)
- Keeps all validation checks (no logic changes)
- No new functionality or behavior changes
- Direct replacement: `pcall(vim.keymap.set, ...)` → `vim.keymap.set(...)`

### User Impact

**Benefits**:
- Simpler, more maintainable code
- Matches Telescope conventions (easier for contributors)
- No performance difference (negligible pcall overhead)
- Same safety guarantees with buffer validation

**Learning Curve**: None - no user-facing changes, purely internal code simplification

### Code Quality Improvement

This change improves code quality by:
- **Following established patterns** from Telescope.nvim
- **Reducing complexity** without sacrificing safety
- **Improving readability** by removing unnecessary wrapping
- **Demonstrating best practices** for future Telescope picker development
