# Picker Buffer Validation and Help Section Fix

## Metadata
- **Date**: 2025-10-08
- **Feature**: Fix picker CR keymap error and help section preview focus
- **Scope**: Add buffer validation before keymap operations and fix help section handling to allow preview focus
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: /home/benjamin/.config/nvim/nvim/specs/reports/040_debug_picker_cr_keymap_error.md

## Overview

The picker's two-stage Return key behavior has two critical bugs:

1. **Buffer Validation Error**: Pressing `<CR>` causes `E5108: Invalid buffer id: 159` error because the code validates the preview window but not the preview buffer before setting keymaps. This makes the picker unusable.

2. **Help Section Non-Response**: Pressing `<CR>` on [Keyboard Shortcuts] help section does nothing because the code returns early, preventing preview focus for scrolling the help text.

Both issues stem from the recent two-stage Return implementation (plan 038). The Tab handler has the same buffer validation issue but may work more reliably due to timing differences.

## Success Criteria
- [ ] `<CR>` in picker does not produce buffer validation errors
- [ ] First `<CR>` on help section focuses preview for scrolling
- [ ] Second `<CR>` on help section returns to picker (no action execution)
- [ ] All artifact types continue to work with two-stage Return behavior
- [ ] Tab handler also validates buffers for consistency
- [ ] Help section shows appropriate status message when preview focused
- [ ] All existing picker functionality preserved
- [ ] Code follows Neovim configuration guidelines (nvim/CLAUDE.md)

## Technical Design

### 1. Buffer Validation Fix

**Root Cause**:
- Line 2820: Code validates `preview_winid` with `vim.api.nvim_win_is_valid()`
- Line 2831: Code calls `vim.keymap.set()` with `preview_bufnr` without validation
- When buffer 159 is invalid/deleted, keymap.set() fails with E5108 error

**Current Code (Lines 2820-2831)**:
```lua
-- Only validates WINDOW, not BUFFER
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  -- Sets keymap on buffer WITHOUT validation - ERROR HERE
  vim.keymap.set("n", "<Esc>", function()
    preview_focused = false
    return_stage = "first"
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })
```

**Design**:
- Add buffer validation: `vim.api.nvim_buf_is_valid(preview_bufnr)`
- Validate BOTH window and buffer before keymap operations
- Apply same fix to Tab handler (lines 2754-2780) for consistency

**Implementation Location**: picker.lua lines 2820, 2763

### 2. Help Section Preview Focus Fix

**Root Cause**:
- Lines 2806-2808: `is_help` check returns early
- This prevents preview focus logic from running
- User cannot scroll keyboard shortcuts help text

**Current Code (Lines 2806-2808)**:
```lua
if selection.value.is_help then
  return  -- Exits before preview focus logic
end
```

**Design**:
- Only return on SECOND press (when `return_stage == "second"`)
- First press: Fall through to preview focus logic
- Second press: Reset state and return (no action to execute)
- Show different status message for help section (no action description)

**Implementation Location**: picker.lua lines 2806-2808, 2833-2835

### 3. Visual Result

**Before (Broken)**:
```
User presses <CR> → Error: E5108: Invalid buffer id: 159
User presses <CR> on [Keyboard Shortcuts] → Nothing happens
```

**After (Fixed)**:
```
User presses <CR> → Preview focuses, no error
User presses <CR> on [Keyboard Shortcuts] → Preview focuses for scrolling
User presses <CR> again on help → Returns to picker (no action)
User presses <CR> on command → Preview focuses
User presses <CR> again on command → Command inserted into Claude Code
```

## Implementation Phases

### Phase 1: Add Buffer Validation to Return and Tab Handlers [COMPLETED]
**Objective**: Prevent buffer validation errors by checking buffer validity before keymap operations
**Complexity**: Low

Tasks:
- [x] Read current Return key handler (lines 2757-2844)
- [x] Locate buffer validation check at line 2820
- [x] Add buffer validation to condition: `and preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr)`
- [x] Test with various artifact types to verify no errors
- [x] Read Tab handler (lines 2754-2780)
- [x] Locate buffer validation check at line 2763
- [x] Add same buffer validation to Tab handler condition
- [x] Test Tab key with various artifacts to verify consistency
- [x] Verify both handlers gracefully handle invalid buffers

Testing:
```bash
# Open picker and try pressing <CR> on various items
# Verify no E5108 errors occur
# Test rapid <CR> presses
# Test with entries that might not have previews
# Test Tab key for consistency
# Verify both handle edge cases gracefully
```

### Phase 2: Fix Help Section Preview Focus [COMPLETED]
**Objective**: Allow preview focus for help section while preventing action execution
**Complexity**: Low

Tasks:
- [x] Read current help section handling (lines 2806-2808)
- [x] Modify `is_help` check to only return on second press
- [x] Add condition: `if return_stage == "second"` then reset and return
- [x] First press: Remove return statement, fall through to preview focus
- [x] Read status message code (lines 2833-2835)
- [x] Add conditional status message for help section
- [x] Help section message: "Preview focused - Press Esc to return to picker"
- [x] Non-help message: "Preview focused - Press Return to [action]"
- [x] Test pressing <CR> on [Keyboard Shortcuts] - verify preview focuses
- [x] Test pressing <CR> again on help - verify returns to picker
- [x] Test scrolling in help preview with j/k, <C-u>, <C-d>
- [x] Verify help section doesn't execute any actions on second press

Testing:
```bash
# Open picker and navigate to [Keyboard Shortcuts]
# Press <CR> - verify preview focuses with appropriate message
# Use j/k to scroll help text
# Use <C-u> and <C-d> to scroll by half-page
# Press <CR> again - verify returns to picker
# Verify no action is executed (no terminal insertion)
# Test with other artifact types to ensure no regression
```

## Testing Strategy

### Manual Testing
All changes require testing in Neovim:
1. Open picker with `<leader>ac`
2. Test Return key on all artifact types (Commands, Agents, Docs, Lib, Templates, Hooks, TTS)
3. Test rapid Return presses
4. Test Return on [Keyboard Shortcuts] help section
5. Test Tab key for consistency
6. Verify no E5108 errors occur
7. Test edge cases (headings, special entries)

### Test Cases
- **Buffer Validation**:
  - Return key on all artifact types (no errors)
  - Tab key on all artifact types (no errors)
  - Rapid key presses (no race conditions)
  - Entries without previews (graceful handling)

- **Help Section**:
  - First Return on [Keyboard Shortcuts] (preview focuses)
  - Second Return on help (returns to picker, no action)
  - Scrolling in help preview (j/k, <C-u>, <C-d> work)
  - Status message shows correct text

- **Two-Stage Behavior**:
  - Commands: First Return focuses preview, second inserts command
  - All other artifacts: First Return focuses, second opens file
  - Help section: First Return focuses, second returns (no action)
  - Selection change: Resets return_stage correctly

### Regression Testing
- All existing keybindings work (`<C-e>`, `<C-l>`, `<C-u>`, `<C-s>`)
- Preview focus navigation preserved
- Search and filtering work correctly
- All artifact types selectable and functional
- State management works across selection changes

## Documentation Requirements

### Files to Update
- `nvim/lua/neotex/plugins/ai/claude/commands/README.md` - Document buffer validation and help section behavior
- Inline code comments in `picker.lua` - Document buffer validation logic

### Documentation Content
- Explain buffer validation prevents keymap errors
- Clarify help section allows preview focus for scrolling
- Note that help section doesn't execute actions on second Return
- Document status message differences for help vs other artifacts

## Dependencies

### Existing Code Dependencies
- Telescope.nvim API: `vim.api.nvim_buf_is_valid()`, `vim.api.nvim_win_is_valid()`
- Existing two-stage Return behavior (plan 038)
- Preview buffer lifecycle in Telescope

### No External Dependencies
All changes use existing Neovim and Telescope APIs.

## Notes

### Design Decisions

1. **Buffer Validation**: Add explicit buffer validity check before keymap operations to prevent E5108 errors. This is defensive programming for robustness.

2. **Help Section Preview Focus**: Allow preview focus for help section so users can scroll long keyboard shortcuts list. Second press returns without action since help has no executable action.

3. **Status Message Differentiation**: Show different status messages for help section (no action description) vs other artifacts (action description) for clarity.

4. **Tab Handler Consistency**: Apply same buffer validation to Tab handler even though it may not currently exhibit errors, for consistency and future-proofing.

5. **Minimal Changes**: Only add validation checks and modify help section logic. No changes to state management or two-stage behavior.

### Implementation Simplicity

This fix is straightforward because:
- Only adds buffer validation checks (one conditional)
- Only modifies help section early return logic (one conditional)
- Only updates status message (one conditional)
- No new logic or algorithms required
- No changes to state management
- Buffer validation is standard Neovim API usage

### User Impact

**Benefits**:
- Picker no longer crashes with buffer validation errors
- Help section preview is now accessible for scrolling
- More robust buffer handling prevents future issues
- Consistent behavior between Tab and Return handlers

**Learning Curve**: None - purely bug fixes that enhance existing behavior without changing interaction patterns.

### Root Cause Summary

From debug report 040:
- **Primary Cause**: Missing `vim.api.nvim_buf_is_valid(preview_bufnr)` check before `vim.keymap.set()`
- **Secondary Cause**: Help section early return preventing preview focus
- **Impact**: Picker unusable due to errors, help section inaccessible
- **Solution**: Add buffer validation, modify help section logic
