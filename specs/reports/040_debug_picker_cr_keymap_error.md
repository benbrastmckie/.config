# Debug Report: Picker Enter Key Keymap Error

**Report Number**: 040
**Date**: 2025-10-08
**Issue**: Invalid buffer ID error when pressing Enter in picker, help section non-responsive
**Status**: Root cause identified

## Problem Statement

### Primary Issue: Buffer Validation Error
When pressing `<CR>` (Enter) in the `<leader>ac` picker, the following error occurs:

```
E5108: Error executing lua: vim/keymap.lua:0: Invalid buffer id: 159
stack traceback:
        [C]: in function 'nvim_buf_set_keymap'
        vim/keymap.lua: in function 'set'
        ...ig/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua:2814: in function 'run_replace_or_original'
        ...re/nvim/lazy/telescope.nvim/lua/telescope/actions/mt.lua:65: in function 'key_func'
        ...hare/nvim/lazy/telescope.nvim/lua/telescope/mappings.lua:253: in function <...hare/nvim/lazy/telescope.nvim/lua/telescope/mappings.lua:252>
```

### Secondary Issue: Help Section Non-Response
Pressing `<CR>` on the `[Keyboard Shortcuts]` help section does nothing (expected behavior: focus preview for scrolling).

## Investigation Findings

### Code Analysis

#### Location of Error
File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
Line: 2831 (in the Enter key handler's first-stage logic)

#### Problematic Code (Lines 2806-2837)

```lua
if selection.value.is_help then
  return
end

-- Two-stage selection logic
if return_stage == "first" then
  -- First Return: Focus preview
  return_stage = "second"

  local picker = action_state.get_current_picker(prompt_bufnr)
  if picker and picker.previewer and picker.previewer.state then
    local preview_winid = picker.previewer.state.winid
    local preview_bufnr = picker.previewer.state.bufnr

    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
      preview_focused = true
      vim.api.nvim_set_current_win(preview_winid)

      -- Set Esc mapping to return to picker
      vim.keymap.set("n", "<Esc>", function()
        preview_focused = false
        return_stage = "first"
        if vim.api.nvim_win_is_valid(picker.prompt_win) then
          vim.api.nvim_set_current_win(picker.prompt_win)
        end
      end, { buffer = preview_bufnr, nowait = true })  -- LINE 2831: ERROR HERE

      -- Show action hint
      local action_desc = get_action_description(selection)
      vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})
    end
  end
```

#### Working Code for Comparison: Tab Handler (Lines 2754-2780)

```lua
-- Tab handler: Focus preview pane for scrolling
map("i", "<Tab>", function()
  local picker = action_state.get_current_picker(prompt_bufnr)
  if not picker or not picker.previewer or not picker.previewer.state then
    return
  end

  local preview_winid = picker.previewer.state.winid
  local preview_bufnr = picker.previewer.state.bufnr

  if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) then
    return
  end

  -- Switch focus to preview window
  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  -- Set buffer-local Esc mapping to return to picker
  vim.keymap.set("n", "<Esc>", function()
    preview_focused = false
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })

  vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
end)
```

### Root Cause Analysis

#### Issue 1: Missing Buffer Validation

**Problem**: The Enter handler validates the preview window but **not the preview buffer** before setting a keymap on it.

**Line 2820**: `if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then`
- Only validates window validity
- Does NOT validate buffer validity

**Line 2831**: `vim.keymap.set("n", "<Esc>", ..., { buffer = preview_bufnr, nowait = true })`
- Attempts to set keymap on `preview_bufnr` without validation
- Fails if buffer is invalid (deleted, unloaded, etc.)

**Comparison with Tab Handler**:
- Tab handler has identical pattern (also missing buffer validation)
- Tab handler may work more reliably due to different timing/lifecycle

#### Issue 2: Help Section Early Return

**Problem**: The help section check at line 2806-2808 returns early, preventing preview focus.

```lua
if selection.value.is_help then
  return  -- Exits before preview focus logic
end
```

**Why this exists**:
- Help entries are marked with `is_help = true` (line 237)
- Early return prevents execution of action logic
- However, it also prevents first-stage preview focus

**Help Entry Definition (Lines 236-246)**:
```lua
table.insert(entries, {
  is_help = true,
  name = "~~~help",
  display = string.format(
    "%-40s %s",
    "[Keyboard Shortcuts]",
    "Help"
  ),
  command = nil,
  entry_type = "special"
})
```

**Help Preview (Lines 869-925)**:
- The help entry DOES have a preview (keyboard shortcuts documentation)
- The preview is generated in `define_preview` function (lines 869-925)
- Users should be able to focus this preview to scroll through help

## Buffer Lifecycle Context

### When Preview Buffers Are Created
Telescope's `define_preview` function is called when:
1. Picker opens and displays initial selection
2. Selection changes (cursor moves)
3. Entries are refreshed

### When Preview Buffers May Be Invalid
1. **Rapid selection changes**: Buffer from previous selection destroyed
2. **Entry without preview**: Some entries might not create preview buffers
3. **Telescope buffer recycling**: Internal buffer management may reuse/destroy buffers
4. **Async timing**: Preview creation and keymap setting may race

### Why Error Occurs
The error `Invalid buffer id: 159` suggests:
1. `preview_bufnr` was valid when captured from `picker.previewer.state.bufnr`
2. Buffer was deleted/invalidated before `vim.keymap.set()` executed
3. No validation caught the invalid state

## Proposed Solutions

### Solution 1: Add Buffer Validation (Recommended)

Add buffer validation check before setting keymap:

```lua
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  -- ADDED: Validate buffer before setting keymap
  if preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
    -- Set Esc mapping to return to picker
    vim.keymap.set("n", "<Esc>", function()
      preview_focused = false
      return_stage = "first"
      if vim.api.nvim_win_is_valid(picker.prompt_win) then
        vim.api.nvim_set_current_win(picker.prompt_win)
      end
    end, { buffer = preview_bufnr, nowait = true })
  end

  -- Show action hint
  local action_desc = get_action_description(selection)
  vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})
end
```

**Benefits**:
- Prevents invalid buffer errors
- Graceful degradation (preview still focuses, just no Esc mapping)
- Consistent with window validation pattern

**Trade-offs**:
- If buffer invalid, Esc mapping won't be set (user must close picker another way)
- Silent failure (could add warning message)

### Solution 2: Use pcall Wrapper

Wrap keymap setting in pcall for error handling:

```lua
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then
  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  -- Set Esc mapping with error handling
  local ok, err = pcall(vim.keymap.set, "n", "<Esc>", function()
    preview_focused = false
    return_stage = "first"
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })

  if not ok then
    -- Log error or silently continue
    vim.notify("Warning: Could not set Esc mapping in preview", vim.log.levels.WARN)
  end

  -- Show action hint
  local action_desc = get_action_description(selection)
  vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})
end
```

**Benefits**:
- Catches and handles errors gracefully
- Provides visibility into failures (via notification)
- Preview still works even if keymap fails

**Trade-offs**:
- More verbose
- Notification might be noisy
- Still doesn't solve root cause (buffer lifecycle)

### Solution 3: Allow Help Section Preview Focus

Modify help section handling to allow preview focus:

```lua
-- Check for help section - allow first-stage preview focus
if selection.value.is_help then
  if return_stage == "first" then
    -- Allow preview focus for help section
    -- (fall through to preview focus logic)
  else
    -- Second Return: Do nothing for help (no action to execute)
    reset_state()
    return
  end
end
```

OR remove the early return entirely and rely on second-stage logic:

```lua
-- Remove lines 2806-2808 entirely
-- Let help section go through normal two-stage flow
-- Second-stage logic already handles lack of command/filepath
```

**Benefits**:
- Help section becomes navigable (first Enter focuses preview)
- Users can scroll through keyboard shortcuts help
- Consistent two-stage behavior

**Trade-offs**:
- Second Return must handle help section (no action to execute)
- Need to ensure second-stage doesn't try to execute non-existent command

### Solution 4: Combined Approach (Best)

Combine all three solutions:

```lua
-- Allow help section preview focus (first stage only)
if selection.value.is_help then
  if return_stage == "second" then
    -- Second Return on help: Just reset and return
    reset_state()
    return
  end
  -- First Return: Fall through to preview focus logic
end

-- Two-stage selection logic
if return_stage == "first" then
  -- First Return: Focus preview
  return_stage = "second"

  local picker = action_state.get_current_picker(prompt_bufnr)
  if picker and picker.previewer and picker.previewer.state then
    local preview_winid = picker.previewer.state.winid
    local preview_bufnr = picker.previewer.state.bufnr

    -- Validate both window AND buffer
    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) and
       preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
      preview_focused = true
      vim.api.nvim_set_current_win(preview_winid)

      -- Set Esc mapping to return to picker
      vim.keymap.set("n", "<Esc>", function()
        preview_focused = false
        return_stage = "first"
        if vim.api.nvim_win_is_valid(picker.prompt_win) then
          vim.api.nvim_set_current_win(picker.prompt_win)
        end
      end, { buffer = preview_bufnr, nowait = true })

      -- Show action hint (skip for help section)
      if not selection.value.is_help then
        local action_desc = get_action_description(selection)
        vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})
      else
        vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
      end
    end
  end
else
  -- Second Return: Execute action based on artifact type
  -- (existing logic handles lack of command/filepath gracefully)
  reset_state()
  -- ... rest of second-stage logic
end
```

**Benefits**:
- Fixes buffer validation error (primary issue)
- Enables help section preview focus (secondary issue)
- Maintains two-stage behavior consistently
- Provides appropriate status messages

## Implementation Steps

### Step 1: Add Buffer Validation
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Line**: 2820

**Change**:
```lua
-- BEFORE:
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) then

-- AFTER:
if preview_winid and vim.api.nvim_win_is_valid(preview_winid) and
   preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
```

### Step 2: Fix Help Section Handling
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Lines**: 2806-2808

**Change**:
```lua
-- BEFORE:
if selection.value.is_help then
  return
end

-- AFTER:
if selection.value.is_help then
  if return_stage == "second" then
    -- Second Return on help: Just reset and return
    reset_state()
    return
  end
  -- First Return: Fall through to preview focus logic
end
```

### Step 3: Update Status Message for Help
**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Lines**: 2833-2835

**Change**:
```lua
-- BEFORE:
-- Show action hint
local action_desc = get_action_description(selection)
vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})

-- AFTER:
-- Show action hint (different message for help section)
if not selection.value.is_help then
  local action_desc = get_action_description(selection)
  vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})
else
  vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
end
```

### Step 4: Consider Updating Tab Handler (Optional)
The Tab handler has the same missing buffer validation. While it hasn't caused errors yet, it should be fixed for consistency:

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua`
**Line**: 2763

**Change**:
```lua
-- BEFORE:
if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) then
  return
end

-- AFTER:
if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) or
   not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
  return
end
```

## Testing Plan

### Test Case 1: Normal Entry Selection
1. Open picker with `<leader>ac`
2. Select a normal command entry (not help)
3. Press `<CR>` (should focus preview, no error)
4. Press `<CR>` again (should execute action)

**Expected**: No buffer validation errors, normal two-stage behavior

### Test Case 2: Help Section Selection
1. Open picker with `<leader>ac`
2. Navigate to `[Keyboard Shortcuts]` entry
3. Press `<CR>` (should focus preview with help text)
4. Scroll through help with j/k
5. Press `<Esc>` (should return to picker)

**Expected**: Preview focuses, help is scrollable, Esc returns

### Test Case 3: Rapid Selection Changes
1. Open picker with `<leader>ac`
2. Rapidly move cursor between entries
3. Press `<CR>` while moving (stress test buffer lifecycle)

**Expected**: No errors, graceful handling of buffer state

### Test Case 4: Tab Key Behavior
1. Open picker with `<leader>ac`
2. Press `<Tab>` to focus preview
3. Scroll through preview
4. Press `<Esc>` to return

**Expected**: No errors with updated buffer validation

## Summary

### Root Causes Identified

1. **Missing Buffer Validation**: Enter handler validates preview window but not buffer before setting keymap
2. **Help Section Early Return**: Help entries exit before preview focus logic, preventing scrollable help

### Recommended Fix

Implement Solution 4 (Combined Approach):
1. Add buffer validation check: `vim.api.nvim_buf_is_valid(preview_bufnr)`
2. Modify help section to allow first-stage preview focus
3. Update status messages to differentiate help section
4. Optionally fix Tab handler with same buffer validation

### Impact

- **Primary Issue**: Fixed with buffer validation
- **Secondary Issue**: Fixed with help section logic update
- **Consistency**: Same pattern should be applied to Tab handler
- **User Experience**: Help section becomes navigable, no more buffer errors

## Files Affected

- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` (lines 2763, 2806-2808, 2820, 2833-2835)

## References

- Error stack trace: Line 2831 in Enter key handler
- Help entry definition: Lines 236-246
- Help preview generation: Lines 869-925
- Tab handler (working reference): Lines 2754-2780
- Enter handler (broken code): Lines 2806-2837
