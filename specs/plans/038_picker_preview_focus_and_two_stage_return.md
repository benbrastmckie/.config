# Picker Preview Focus Navigation and Two-Stage Return Enhancement

## Metadata
- **Date**: 2025-10-08
- **Feature**: Preview focus navigation with two-stage Return key behavior
- **Scope**: Enhance picker with Tab/Shift-Tab documentation, preview focus switching, and refined Return key behavior for improved navigation and control
- **Estimated Phases**: 4
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: None (inline research completed)

## Overview

The Claude command picker currently lacks documentation for Tab/Shift-Tab behavior, doesn't support preview pane navigation, and immediately executes actions on Return. This enhancement adds three key improvements:

1. **Tab/Shift-Tab Documentation**: Document the existing Telescope multi-selection behavior (Tab toggles selection and moves down, Shift-Tab toggles and moves up)

2. **Preview Focus Navigation**: Allow users to switch focus to the preview pane for scrolling long previews, with intuitive key bindings (Tab to preview, Esc to return)

3. **Two-Stage Return Behavior**: Change Return key to first focus the preview for review, then execute the action on second press:
   - First Return: Focus preview pane (all artifact types)
   - Second Return: Execute action based on artifact type:
     * **Commands only**: Insert into Claude Code terminal
     * **All other artifacts**: Open file for editing (Agents, Templates, Docs, Lib, Hooks, TTS)

This creates a more deliberate, review-before-action workflow while maintaining keyboard-driven efficiency.

## Success Criteria
- [ ] Tab/Shift-Tab behavior documented in help text
- [ ] Tab key switches focus to preview pane for scrolling
- [ ] Esc key returns focus from preview to picker
- [ ] First Return on any artifact focuses preview (with visual feedback)
- [ ] Second Return on commands inserts command into Claude Code
- [ ] Second Return on all other artifacts opens file for editing (including agents)
- [ ] Preview focus state resets when selection changes
- [ ] All existing keybindings (`<C-l>`, `<C-u>`, `<C-s>`, `<C-e>`) continue to work from picker
- [ ] Code follows Neovim configuration guidelines (nvim/CLAUDE.md)

## Technical Design

### 1. Tab/Shift-Tab Documentation

**Current State**:
- Tab and Shift-Tab use default Telescope behavior (multi-selection)
- No documentation in help text (line 846-890)

**Design**:
- Add section to help text explaining multi-selection
- Document Tab: toggle selection + move down
- Document Shift-Tab: toggle selection + move up
- Explain use case (bulk operations on multiple artifacts)

**Implementation Location**: picker.lua help text (around line 860)

### 2. Preview Focus Navigation

**Current State**:
- Telescope doesn't natively support preview focus switching
- Preview pane is display-only, not interactive
- No way to scroll long previews

**Design**:
- Override default Tab mapping to implement custom preview focus logic
- On Tab press:
  1. Get current picker instance via `action_state.get_current_picker(prompt_bufnr)`
  2. Access preview window: `picker.previewer.state.winid`
  3. Switch focus: `vim.api.nvim_set_current_win(preview_winid)` with `noautocmd`
  4. Set buffer-local Esc mapping in preview to return focus
- Track focus state with local variable in attach_mappings closure
- Provide visual feedback when preview is focused (status message or highlight)

**State Management**:
```lua
local preview_focused = false  -- Track if preview has focus

-- Tab handler
if not preview_focused then
  -- Switch to preview
  preview_focused = true
  vim.api.nvim_set_current_win(picker.previewer.state.winid)
  -- Set Esc mapping in preview buffer to return
else
  -- Already in preview, do nothing or cycle behavior
end

-- Esc in preview handler
preview_focused = false
vim.api.nvim_set_current_win(picker.prompt_win)
```

**Implementation Location**: picker.lua attach_mappings (around line 2703)

### 3. Two-Stage Return Key Behavior

**Current State** (from previous refactor):
- Return immediately closes picker and executes action
- Commands insert into terminal
- Agents insert @agent_name
- File artifacts open for editing

**New Design**:
- Add local state variable `return_stage` (values: "first" | "second")
- First Return:
  1. Set `return_stage = "second"`
  2. Focus preview pane (same logic as Tab)
  3. Display status message: "Preview focused - Press Return again to [action]"
  4. Do NOT close picker or execute action
- Second Return (from preview):
  1. Check `return_stage == "second"`
  2. Execute artifact-specific action:
     * **Commands**: Insert into Claude Code terminal
     * **All others**: Open file for editing (Agents, Templates, Docs, Lib, Hooks, TTS)
  3. Close picker
  4. Reset `return_stage = "first"`
- Reset `return_stage = "first"` when selection changes (intercept movement actions)

**Important Behavior Change**:
- Agents no longer insert `@agent_name` reference
- Agents open their file for editing like other file artifacts
- Only commands insert into Claude Code

**State Management**:
```lua
local return_stage = "first"  -- Track Return press stage
local preview_focused = false -- Track preview focus

-- Return handler
if return_stage == "first" then
  -- First press: focus preview
  return_stage = "second"
  preview_focused = true
  vim.api.nvim_set_current_win(picker.previewer.state.winid)
  -- Show status message
  print("Preview focused - Press Return to " .. get_action_description(entry))
else
  -- Second press: execute action
  if entry_type == "command" then
    actions.close(prompt_bufnr)
    send_command_to_terminal(command)
  else
    -- All other artifacts open file for editing
    actions.close(prompt_bufnr)
    edit_artifact_file(filepath)
  end
  return_stage = "first"
  preview_focused = false
end

-- Selection change handler (reset state)
-- Intercept move_selection_next, move_selection_previous, etc.
local original_move_next = actions.move_selection_next
actions.move_selection_next:enhance({
  post = function()
    return_stage = "first"
    preview_focused = false
  end
})
```

**Implementation Location**: picker.lua actions.select_default handler (around line 2705)

### 4. Data Structures

No schema changes needed. State tracked with local variables in attach_mappings closure:
- `preview_focused` (boolean): Whether preview pane has focus
- `return_stage` ("first" | "second"): Which Return press stage we're in

### 5. Edge Cases and Considerations

**Selection Changes**:
- Reset both `return_stage` and `preview_focused` when user moves selection
- Hook into all movement actions: move_selection_next, move_selection_previous, move_selection_better, move_selection_worse

**Special Entries**:
- Headings: Skip two-stage behavior (return immediately)
- Help entry: Skip two-stage behavior
- Load All entry: Execute immediately (no preview focus)

**Rapid Key Presses**:
- State transitions should handle rapid Return presses correctly
- First Return sets stage to "second", immediate second Return executes

**Closing Picker**:
- Esc from picker: Close picker (existing behavior)
- Esc from preview: Return focus to picker (new behavior)
- Ctrl-C: Close picker and reset all state

**Other Action Keys**:
- `<C-l>`, `<C-u>`, `<C-s>`, `<C-e>` should work from picker regardless of return_stage
- These keys should reset return_stage to "first" after execution

## Implementation Phases

### Phase 1: Document Tab/Shift-Tab Multi-Selection
**Objective**: Add documentation for existing Tab/Shift-Tab multi-selection behavior
**Complexity**: Low

Tasks:
- [ ] Read current help text in picker.lua (lines 846-890)
- [ ] Add new section "Multi-Selection:" in help text
- [ ] Document Tab: "Toggle selection and move down (for batch operations)"
- [ ] Document Shift-Tab: "Toggle selection and move up"
- [ ] Explain use case: selecting multiple artifacts for batch operations
- [ ] Position after "Navigation:" section, before "Artifact Types:"

Testing:
```bash
# Open picker and view help
# Verify Tab/Shift-Tab section appears in help text
# Test Tab to verify multi-selection behavior works as documented
# Test Shift-Tab to verify behavior
```

### Phase 2: Implement Preview Focus Switching (Tab/Esc)
**Objective**: Allow Tab to focus preview, Esc to return to picker
**Complexity**: Medium

Tasks:
- [ ] Add local state variable `preview_focused = false` in attach_mappings
- [ ] Create Tab key handler using `map("i", "<Tab>", function() ... end)`
- [ ] In Tab handler: Get current picker via `action_state.get_current_picker(prompt_bufnr)`
- [ ] Access preview window ID: `picker.previewer.state.winid`
- [ ] Access prompt window ID: `picker.prompt_win`
- [ ] Implement focus switch: `vim.api.nvim_set_current_win(preview_winid, {noautocmd = true})`
- [ ] Set `preview_focused = true` after switching
- [ ] Get preview buffer ID: `picker.previewer.state.bufnr`
- [ ] Set buffer-local Esc mapping in preview: `vim.keymap.set("n", "<Esc>", ..., {buffer = preview_bufnr})`
- [ ] Esc handler: Switch back to prompt window, set `preview_focused = false`
- [ ] Add visual feedback when preview is focused (status message)
- [ ] Handle case where preview doesn't exist (no-op)

Testing:
```bash
# Open picker and select any item with preview
# Press Tab - verify focus switches to preview pane
# Verify you can scroll preview with j/k
# Press Esc - verify focus returns to picker
# Verify selection movement works after returning to picker
# Test with entries that have no preview (headings)
```

### Phase 3: Implement Two-Stage Return Key Behavior
**Objective**: Refactor Return to focus preview first, execute action second
**Complexity**: High

Tasks:
- [ ] Add local state variable `return_stage = "first"` in attach_mappings
- [ ] Refactor existing `actions.select_default:replace()` handler
- [ ] Add conditional: if `return_stage == "first"` then focus preview
- [ ] First Return: Set `return_stage = "second"`, `preview_focused = true`
- [ ] First Return: Switch to preview window (same logic as Tab handler)
- [ ] First Return: Display action hint: "Press Return to [insert command|edit file]"
- [ ] Create helper function `get_action_description(entry)` returning action text
- [ ] Add conditional: else if `return_stage == "second"` then execute action
- [ ] Second Return for commands: Close picker, `send_command_to_terminal(command)`
- [ ] Second Return for all other artifacts: Close picker, `edit_artifact_file(filepath)`
- [ ] Remove agent @name insertion logic (agents now open files for editing)
- [ ] Reset both state variables after action execution
- [ ] Preserve existing special entry handling (headings, Load All, help)
- [ ] Test with all artifact types

Testing:
```bash
# Open picker, select a command
# Press Return once - verify preview focuses, message shows
# Press Return again - verify command inserted into Claude Code

# Select an agent
# Press Return once - verify preview focuses
# Press Return again - verify agent file opens for editing (NOT @agent_name insertion)

# Select doc/lib/template/hook/TTS file
# Press Return once - verify preview focuses
# Press Return again - verify file opens for editing

# Select heading or Load All
# Press Return - verify immediate action (no two-stage)
```

### Phase 4: Implement State Reset on Selection Change
**Objective**: Reset return_stage and preview_focused when user moves selection
**Complexity**: Medium

Tasks:
- [ ] Create state reset function: `local function reset_state() return_stage = "first"; preview_focused = false end`
- [ ] Hook into movement actions using enhance method
- [ ] Enhance `actions.move_selection_next` with post callback calling reset_state()
- [ ] Enhance `actions.move_selection_previous` with post callback
- [ ] Enhance `actions.move_selection_better` with post callback
- [ ] Enhance `actions.move_selection_worse` with post callback
- [ ] Also reset state after `<C-l>`, `<C-u>`, `<C-s>`, `<C-e>` actions
- [ ] Test that state resets work correctly
- [ ] Verify first Return after selection change focuses preview (not executing action)

Testing:
```bash
# Open picker, select item, press Return once (preview focused)
# Press j or k to change selection
# Press Return - verify it focuses preview (stage reset to first)
# Not executing action from previous selection

# Select item, press Return once
# Press Ctrl-l to load locally
# Verify return_stage reset to first

# Test all movement and action keys for proper state reset
```

## Testing Strategy

### Manual Testing (All Phases)
All features require manual testing in Neovim:
1. Open picker with keymap (e.g., `<leader>ac`)
2. Test Tab/Shift-Tab multi-selection
3. Test Tab to focus preview, Esc to return
4. Test two-stage Return on all artifact types
5. Test state reset on selection changes
6. Test all existing keybindings still work

### Test Cases by Artifact Type
- **Commands**: Two-stage Return inserts into Claude Code
- **Agents**: Two-stage Return opens file for editing (behavioral change)
- **Templates**: Two-stage Return opens file
- **Docs**: Two-stage Return opens file
- **Lib**: Two-stage Return opens file
- **Hooks**: Two-stage Return opens file
- **TTS Files**: Two-stage Return opens file

### Edge Case Testing
- Preview focus when no preview exists (headings)
- Rapid Return presses (first→second transition)
- Return after selection change (state reset)
- Tab when already in preview (no-op or cycle?)
- Esc from preview when preview_focused = false
- Close picker with Ctrl-C (state cleanup)

### Regression Testing
- All existing keybindings: `<C-l>`, `<C-u>`, `<C-s>`, `<C-e>`, `<C-n>`
- Help section display
- Load All functionality
- Search and filtering
- Command hierarchies and agent nesting

## Documentation Requirements

### Files to Update
- `nvim/lua/neotex/plugins/ai/claude/commands/README.md` - Document new preview navigation and two-stage Return
- `nvim/lua/neotex/plugins/ai/claude/README.md` - Update picker behavior summary
- Inline code comments in `picker.lua` - Document state management and focus switching logic

### Documentation Content
- Explain Tab/Shift-Tab multi-selection
- Describe preview focus navigation (Tab to preview, Esc to return)
- Clarify two-stage Return behavior (focus, then execute)
- Note behavioral change: Agents no longer insert @name, now open files
- Update keybinding reference table with new behaviors
- Add usage examples for preview navigation workflow

## Dependencies

### Existing Code Dependencies
- Telescope.nvim API: `action_state.get_current_picker()`, window/buffer access
- Existing picker infrastructure: state management, action handlers
- `send_command_to_terminal()` function for command insertion
- `edit_artifact_file()` function for file editing

### No External Dependencies
All functionality uses existing Telescope API and Neovim window management. No new dependencies required.

## Notes

### Design Decisions

1. **Two-Stage Return for All Artifacts**: Provides consistent, deliberate interaction model. Users review before executing, reducing accidental actions.

2. **Agents Open Files**: More consistent with other non-command artifacts. Editing agent definitions is more useful than inserting @name references. Users can manually type @agent_name if needed.

3. **Tab for Preview Focus**: Intuitive mapping that overrides multi-selection (which is rarely used). Esc to return matches Vim conventions for exiting modes.

4. **State Reset on Selection Change**: Prevents confusing behavior where Return executes instead of focusing preview after user browses selections.

5. **Visual Feedback**: Status messages provide clear feedback about current state and next action, especially during two-stage Return flow.

### Implementation Complexity

This refactor is moderate complexity because:
- Telescope doesn't natively support preview focus (requires custom window navigation)
- State management across multiple keybindings requires careful coordination
- Two-stage Return changes fundamental interaction model (requires user retraining)
- Many edge cases to handle (selection changes, special entries, state cleanup)

### User Impact

**Benefits**:
- Ability to scroll long previews (agent descriptions, command help, file content)
- More deliberate, review-before-action workflow reduces mistakes
- Consistent file editing for all non-command artifacts
- Clear visual feedback during interaction

**Learning Curve**:
- Users must adapt to two-stage Return (may initially try single Return)
- Agent behavior change (@name insertion → file editing) affects workflows
- Tab behavior change (multi-select → preview focus) for users who used multi-select

### Future Enhancements

Potential improvements (out of scope):
- Status line indicator showing focus state (preview vs picker)
- Configurable single vs two-stage Return (user preference)
- Preview focus persistent across selections (stay in preview mode)
- Advanced preview navigation (search in preview, jump to sections)
