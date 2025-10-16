# Replace Preview Focus with Native Telescope Scrolling

## Metadata
- **Date**: 2025-10-08
- **Feature**: Replace broken preview focus feature with Telescope native scrolling actions
- **Scope**: Remove ~200 lines of problematic preview focus code and replace with Telescope's built-in preview scrolling
- **Estimated Phases**: 3
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**:
  - /tmp/picker_research_report.md
  - /tmp/telescope_buffer_lifecycle_report.md
  - /home/benjamin/.config/nvim/specs/reports/042_preview_focus_keymap_strategies.md

## Overview

Based on comprehensive research, the preview focus feature added in commit bdf1e5d has an **unfixable architectural incompatibility** with Telescope's buffer management system. The feature attempts to set buffer-local keymaps on Telescope-managed preview buffers, which causes a TOCTOU (Time-of-Check to Time-of-Use) race condition where buffers become invalid between validation and keymap.set.

**Root Cause**: Telescope uses `vim.schedule()` to attach buffers to windows asynchronously. Between the time you validate a buffer and try to set a keymap on it, Telescope may delete/recreate that buffer, causing E5108 "Invalid buffer id" errors.

**Historical Context**: Commit 9ab0020 (Oct 7) worked perfectly. The problematic preview focus feature was added the next day (Oct 8, commit bdf1e5d) and has been fundamentally broken since inception.

**Solution**: Replace the broken preview focus feature with Telescope's native preview scrolling actions. This removes ~200 lines of problematic code and provides 100% reliable preview scrolling without any buffer management issues.

## Success Criteria
- [ ] All preview focus code removed (Tab handler, Return two-stage, state management)
- [ ] Telescope native scrolling actions added (`<C-u>`, `<C-d>`, `<C-f>`, `<C-b>`)
- [ ] Keyboard shortcuts help updated with scrolling commands
- [ ] No E5108 buffer validation errors
- [ ] Preview scrolling works reliably for all artifact types
- [ ] Code is simpler and more maintainable (~200 lines removed)
- [ ] All existing picker functionality preserved (search, filtering, selection, etc.)
- [ ] Code follows Neovim configuration guidelines (nvim/CLAUDE.md)

## Technical Design

### 1. Code to Remove

**State Management Variables** (lines ~2708-2710):
```lua
-- REMOVE: These managed preview focus state
local preview_focused = false
local return_stage = "first"

local function reset_state()
  return_stage = "first"
  preview_focused = false
end

local function get_action_description(entry)
  if entry.value.command then
    return "insert command"
  else
    return "edit file"
  end
end
```

**Tab Handler** (lines ~2754-2781):
```lua
-- REMOVE: Entire Tab handler for preview focus
map("i", "<Tab>", function()
  local picker = action_state.get_current_picker(prompt_bufnr)
  if not picker or not picker.previewer or not picker.previewer.state then
    return
  end

  local preview_winid = picker.previewer.state.winid
  local preview_bufnr = picker.previewer.state.bufnr

  if not preview_winid or not vim.api.nvim_win_is_valid(preview_winid) or
     not preview_bufnr or not vim.api.nvim_buf_is_valid(preview_bufnr) then
    return
  end

  preview_focused = true
  vim.api.nvim_set_current_win(preview_winid)

  pcall(vim.keymap.set, "n", "<Esc>", function()
    preview_focused = false
    if vim.api.nvim_win_is_valid(picker.prompt_win) then
      vim.api.nvim_set_current_win(picker.prompt_win)
    end
  end, { buffer = preview_bufnr, nowait = true })

  vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
end)
```

**Two-Stage Return Logic** (lines ~2807-2849):
```lua
-- REMOVE: Help section special handling for preview focus
if selection.value.is_help then
  if return_stage == "second" then
    reset_state()
    return
  end
  -- First press: fall through to preview focus logic
end

-- REMOVE: Two-stage Return logic
if return_stage == "first" then
  -- First Return: Focus preview
  return_stage = "second"

  local picker = action_state.get_current_picker(prompt_bufnr)
  if picker and picker.previewer and picker.previewer.state then
    local preview_winid = picker.previewer.state.winid
    local preview_bufnr = picker.previewer.state.bufnr

    if preview_winid and vim.api.nvim_win_is_valid(preview_winid) and
       preview_bufnr and vim.api.nvim_buf_is_valid(preview_bufnr) then
      preview_focused = true
      vim.api.nvim_set_current_win(preview_winid)

      pcall(vim.keymap.set, "n", "<Esc>", function()
        preview_focused = false
        return_stage = "first"
        if vim.api.nvim_win_is_valid(picker.prompt_win) then
          vim.api.nvim_set_current_win(picker.prompt_win)
        end
      end, { buffer = preview_bufnr, nowait = true })

      if selection.value.is_help then
        vim.api.nvim_echo({{" Preview focused - Press Esc to return to picker ", "Normal"}}, false, {})
      else
        local action_desc = get_action_description(selection)
        vim.api.nvim_echo({{" Preview focused - Press Return to " .. action_desc .. " ", "Normal"}}, false, {})
      end
    end
  end
else
  -- Keep this part - direct action execution
  reset_state()
  -- ... command/file opening logic ...
end
```

**Movement Action Enhancements** (lines ~3066-3089):
```lua
-- REMOVE: State reset on selection change
actions.move_selection_next:enhance({
  post = function()
    reset_state()
  end
})

actions.move_selection_previous:enhance({
  post = function()
    reset_state()
  end
})

actions.move_selection_worse:enhance({
  post = function()
    reset_state()
  end
})

actions.move_selection_better:enhance({
  post = function()
    reset_state()
  end
})
```

### 2. Code to Add

**Native Scrolling Actions** (replace Tab handler and state management):
```lua
-- Preview scrolling using Telescope's native actions (no buffer issues)
map("i", "<C-u>", actions.preview_scrolling_up)
map("i", "<C-d>", actions.preview_scrolling_down)
map("i", "<C-f>", actions.preview_scrolling_down)  -- Alternative (full page)
map("i", "<C-b>", actions.preview_scrolling_up)    -- Alternative (full page)
```

**Simplified Return Handler** (one-stage, no preview focus):
```lua
-- Direct action on Enter (no two-stage preview focus)
actions.select_default:replace(function()
  local selection = action_state.get_selected_entry()
  if not selection then
    return
  end

  -- Skip heading entries
  if selection.value.is_heading then
    return
  end

  -- Special entries
  if selection.value.is_load_all then
    local loaded = load_all_globally()
    if loaded > 0 then
      actions.close(prompt_bufnr)
      vim.defer_fn(function()
        M.show_commands_picker(opts)
      end, 50)
    end
    return
  end

  if selection.value.is_help then
    return
  end

  -- Execute action based on artifact type
  if selection.value.command then
    -- Commands: Insert into Claude Code terminal
    actions.close(prompt_bufnr)
    send_command_to_terminal(selection.value.command)
  elseif selection.value.entry_type == "agent" and selection.value.filepath then
    -- Agents: Open file for editing
    actions.close(prompt_bufnr)
    edit_artifact_file(selection.value.filepath)
  elseif selection.value.entry_type == "doc" and selection.value.filepath then
    actions.close(prompt_bufnr)
    edit_artifact_file(selection.value.filepath)
  elseif selection.value.entry_type == "lib" and selection.value.filepath then
    actions.close(prompt_bufnr)
    edit_artifact_file(selection.value.filepath)
  elseif selection.value.entry_type == "template" and selection.value.filepath then
    actions.close(prompt_bufnr)
    edit_artifact_file(selection.value.filepath)
  elseif selection.value.entry_type == "hook_event" and selection.value.hooks then
    actions.close(prompt_bufnr)
    if #selection.value.hooks > 0 then
      edit_artifact_file(selection.value.hooks[1].filepath)
    end
  elseif selection.value.entry_type == "tts_file" and selection.value.filepath then
    actions.close(prompt_bufnr)
    edit_artifact_file(selection.value.filepath)
  end
end)
```

**Updated Help Text** (lines ~846-890):
```lua
-- Update keyboard shortcuts section
Commands:
  Enter (CR)     - Execute action for selected item
                   Commands: Insert into Claude Code
                   All others: Open file for editing

Preview Navigation:
  Ctrl-u         - Scroll preview up (half page)
  Ctrl-d         - Scroll preview down (half page)
  Ctrl-b         - Scroll preview up (full page)
  Ctrl-f         - Scroll preview down (full page)
```

### 3. Visual Result

**Before (Broken)**:
```
User presses <CR> → E5108: Invalid buffer id error
User presses Tab → Sometimes focuses preview, Esc doesn't work
User wants to scroll long preview → Must use two-stage Return (broken)
```

**After (Fixed)**:
```
User presses <CR> → Action executes immediately (insert command or open file)
User presses <C-u> → Preview scrolls up reliably (no errors)
User presses <C-d> → Preview scrolls down reliably (no errors)
User wants to scroll preview → <C-u>/<C-d> works 100% of the time
```

## Implementation Phases

### Phase 1: Remove Broken Preview Focus Infrastructure
**Objective**: Remove all code related to preview focus and two-stage Return behavior
**Complexity**: Medium

Tasks:
- [ ] Remove state management variables (preview_focused, return_stage, reset_state, get_action_description)
- [ ] Remove entire Tab handler for preview focus (lines ~2754-2781)
- [ ] Remove help section preview focus special handling (lines ~2807-2814)
- [ ] Remove two-stage Return logic (first press preview focus)
- [ ] Keep direct action execution logic (second press → now first press)
- [ ] Remove movement action enhancements (reset_state calls)
- [ ] Verify picker still functions with basic selection
- [ ] Test that Return executes actions directly

Testing:
```bash
# Open picker and verify basic functionality works
# Press Return on command - should insert immediately (no two-stage)
# Press Return on file artifact - should open immediately
# Verify no preview focus code remains
# Check for any lingering references to preview_focused or return_stage
```

### Phase 2: Add Native Telescope Scrolling Actions
**Objective**: Replace broken preview focus with Telescope's reliable native scrolling
**Complexity**: Low

Tasks:
- [ ] Add <C-u> mapping to actions.preview_scrolling_up
- [ ] Add <C-d> mapping to actions.preview_scrolling_down
- [ ] Add <C-f> mapping to actions.preview_scrolling_down (alternative)
- [ ] Add <C-b> mapping to actions.preview_scrolling_up (alternative)
- [ ] Test scrolling on command previews (help text)
- [ ] Test scrolling on agent previews (descriptions)
- [ ] Test scrolling on file previews (content)
- [ ] Test scrolling on help section preview
- [ ] Verify no E5108 errors occur
- [ ] Verify scrolling works for all artifact types

Testing:
```bash
# Open picker and select various items
# Press <C-u> - verify preview scrolls up smoothly
# Press <C-d> - verify preview scrolls down smoothly
# Press <C-f>/<C-b> - verify full page scrolling works
# Test with long command descriptions
# Test with long agent descriptions
# Test with keyboard shortcuts help section
# Verify no buffer errors occur
```

### Phase 3: Update Help Text and Documentation
**Objective**: Update keyboard shortcuts help and documentation to reflect new scrolling commands
**Complexity**: Low

Tasks:
- [ ] Read current help text (lines ~846-890)
- [ ] Remove two-stage Return documentation
- [ ] Update Return description to single-stage behavior
- [ ] Add "Preview Navigation:" section
- [ ] Document <C-u> - Scroll preview up (half page)
- [ ] Document <C-d> - Scroll preview down (half page)
- [ ] Document <C-f> - Scroll preview down (full page)
- [ ] Document <C-b> - Scroll preview up (full page)
- [ ] Update commands/README.md with scrolling commands
- [ ] Remove preview focus feature documentation
- [ ] Note that Tab is now free for other uses (or Telescope default)
- [ ] Test help display to verify formatting

Testing:
```bash
# Open picker
# Navigate to [Keyboard Shortcuts] help section
# Press Return to view help
# Verify preview navigation section is present
# Verify <C-u>, <C-d>, <C-f>, <C-b> are documented
# Verify two-stage Return language removed
# Check README for updated feature list
```

## Testing Strategy

### Manual Testing
All changes require testing in Neovim:
1. Open picker with `<leader>ac`
2. Test Return key on all artifact types (should execute immediately)
3. Test preview scrolling with <C-u>, <C-d>, <C-f>, <C-b>
4. Verify no E5108 errors occur under any circumstance
5. Test all artifact types (Commands, Agents, Docs, Lib, Templates, Hooks, TTS)
6. Test help section scrolling
7. Verify all existing functionality preserved

### Test Cases
- **Immediate Action Execution**:
  - Return on command → inserts immediately
  - Return on agent → opens file immediately
  - Return on doc/lib/template → opens file immediately
  - Return on help section → does nothing (as before)

- **Preview Scrolling**:
  - <C-u> on long preview → scrolls up smoothly
  - <C-d> on long preview → scrolls down smoothly
  - <C-f>/<C-b> on long preview → full page scrolling
  - Scrolling on short preview → no errors
  - Scrolling on all artifact types → works consistently

- **Error Elimination**:
  - No E5108 errors with any key combination
  - No buffer validation errors
  - No timing-related failures
  - Reliable operation across all use cases

### Regression Testing
- All existing keybindings work (`<C-e>`, `<C-l>`, `<C-u>`, `<C-s>`)
- Search and filtering work correctly
- Multi-selection works (if using Tab for default)
- All artifact types selectable and functional
- Command insertion still works
- File editing still works

## Documentation Requirements

### Files to Update
- `nvim/lua/neotex/plugins/ai/claude/commands/README.md` - Remove preview focus, add scrolling
- `nvim/lua/neotex/plugins/ai/claude/README.md` - Update picker features
- Inline code comments in `picker.lua` - Document scrolling actions

### Documentation Content
- Remove all mention of preview focus feature
- Remove two-stage Return behavior documentation
- Add preview scrolling section
- Document <C-u>, <C-d>, <C-f>, <C-b> scrolling commands
- Note that this uses Telescope's native preview scrolling
- Explain single-stage Return behavior (immediate action)

## Dependencies

### Existing Code Dependencies
- Telescope.nvim actions: `actions.preview_scrolling_up`, `actions.preview_scrolling_down`
- Existing action execution logic (command insertion, file editing)
- Help text display infrastructure

### No External Dependencies
All functionality uses existing Telescope APIs.

## Notes

### Design Decisions

1. **Remove Rather Than Fix**: The preview focus feature is architecturally incompatible with Telescope. Removing it is the only reliable solution.

2. **Native Scrolling**: Telescope's `preview_scrolling_up/down` actions operate from the prompt buffer, avoiding all buffer management issues.

3. **Single-Stage Return**: Simplifies user experience. Users can scroll preview with <C-u>/<C-d> while keeping focus in picker, then press Return to execute action.

4. **Standard Telescope UX**: <C-u>/<C-d> for preview scrolling is standard across Telescope pickers, making it familiar to users.

5. **Code Simplification**: Removing ~200 lines of problematic code improves maintainability and reliability.

### Research Summary

From comprehensive research (3 parallel agents):
- **Root Cause**: TOCTOU race condition where Telescope's `vim.schedule()` invalidates buffers between validation and keymap.set
- **Historical Analysis**: Feature was added Oct 8 (commit bdf1e5d) and broken since inception. Previous version (commit 9ab0020, Oct 7) worked perfectly.
- **Alternative Approaches**: Evaluated 5 alternatives, all have drawbacks compared to native scrolling
- **Telescope Evidence**: Telescope's own code uses `vim.schedule()` for buffer management, creating unavoidable async issues

### Implementation Simplicity

This refactor is straightforward because:
- Removing code is simpler than adding
- Native actions are well-tested and reliable
- No buffer management needed
- No state tracking needed
- Standard Telescope pattern

### User Impact

**Benefits**:
- 100% reliable preview scrolling (no errors)
- Simpler, more predictable behavior
- Standard Telescope UX (familiar to users)
- No buffer validation issues
- More maintainable code

**Changes**:
- Tab key free for other uses (or default Telescope multi-select)
- Return executes immediately (no two-stage)
- Preview scrolling via <C-u>/<C-d> instead of focus switching
- Cannot use vim motions in preview (j/k) - use <C-u>/<C-d> instead

**Learning Curve**: Minimal - <C-u>/<C-d> is standard Telescope pattern

### Code Quality Improvement

This change improves code quality by:
- **Removing complexity**: ~200 lines of problematic code deleted
- **Following standards**: Uses Telescope's official APIs
- **Improving reliability**: Eliminates all buffer validation errors
- **Simplifying logic**: Single-stage Return instead of two-stage
- **Reducing maintenance**: Less code to maintain and debug
