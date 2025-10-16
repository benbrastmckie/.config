# Visual Claude Prompt Mapping Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases completed successfully. The `<leader>ac` mapping now works in visual mode to send selected text to Claude with a user-provided prompt.

## Metadata
- **Date**: 2025-09-29
- **Feature**: Add `<leader>ac` mapping for visual select mode to send selected text to Claude with user prompt
- **Scope**: Keymap modification and visual selection integration
- **Estimated Phases**: 3
- **Standards File**: `/home/benjamin/.config/nvim/CLAUDE.md`
- **Research Reports**: None

## Overview

Implement a new `<leader>ac` mapping that works specifically in visual select mode to send the currently selected text to Claude Code along with a user-provided prompt. This will replace the current `<leader>ac` mapping (claude commands) and provide an intuitive way to quickly send code selections to Claude with custom prompts.

The implementation will leverage the existing visual selection infrastructure in `ai/claude/core/visual.lua` while adding an interactive prompt collection mechanism.

## Success Criteria

- [x] `<leader>ac` works only in visual select mode
- [x] User is prompted to enter a custom prompt/question
- [x] Selected text is sent to Claude Code with the user's prompt
- [x] Current `<leader>ac` functionality is preserved under a different mapping
- [x] Integration works with all visual modes (v, V, Ctrl-v)
- [x] Error handling for empty selections and cancelled prompts
- [x] Follows project coding standards and conventions

## Technical Design

### Architecture Overview
```
Visual Selection ──→ Prompt Input ──→ Claude Integration
     │                    │                  │
     ├─ get_visual_selection()     ├─ vim.ui.input()    ├─ send_visual_to_claude()
     ├─ Mode validation            ├─ Prompt validation └─ Existing infrastructure
     └─ Error handling             └─ Cancellation handling
```

### Component Integration
- **Which-key mapping**: Visual mode specific mapping for `<leader>ac`
- **Prompt collection**: Use `vim.ui.input()` for user prompt input
- **Visual module**: Extend existing `core/visual.lua` functionality
- **Error handling**: Validate selection and prompt before sending

### Key Design Decisions
1. **Mode restriction**: Only activate in visual modes to prevent accidental triggers
2. **Prompt validation**: Handle empty prompts and user cancellation gracefully
3. **Existing functionality**: Move current `<leader>ac` to `<leader>aC` or similar
4. **User experience**: Clear prompts and helpful error messages

## Implementation Phases

### Phase 1: Update Which-Key Mapping Configuration [COMPLETED]
**Objective**: Modify the which-key configuration to support visual mode mapping
**Complexity**: Low

Tasks:
- [x] Update `lua/neotex/plugins/editor/which-key.lua` to change `<leader>ac` mapping
- [x] Move current "claude commands" functionality to `<leader>aC` (capital C)
- [x] Add new visual mode specific mapping for `<leader>ac`
- [x] Update mapping description and icon appropriately
- [x] Ensure mapping only activates in visual modes (`v`, `V`, `Ctrl-v`)

Testing:
```bash
# Test that old mapping still works with new key
# Test that new mapping only appears in visual mode
# Verify which-key displays correctly
```

Expected outcome: New mapping appears only in visual mode, old functionality preserved

### Phase 2: Implement Interactive Prompt Function [COMPLETED]
**Objective**: Create function to collect user prompt and integrate with visual selection
**Complexity**: Medium

Tasks:
- [x] Create new function `send_visual_to_claude_with_prompt()` in `core/visual.lua`
- [x] Implement `vim.ui.input()` for prompt collection with appropriate options
- [x] Add validation for empty or cancelled prompts
- [x] Integrate with existing `send_visual_to_claude(prompt)` function
- [x] Add configuration option for default prompt placeholder text
- [x] Handle user cancellation gracefully (ESC or empty input)
- [x] Add progress notifications for user feedback

Testing:
```bash
# Test visual selection with prompt input
# Test cancellation behavior (ESC, empty input)
# Test with different visual selection types
# Verify integration with Claude Code terminal
```

Expected outcome: Interactive prompt collection with proper error handling

### Phase 3: Integration Testing and Documentation [COMPLETED]
**Objective**: Ensure complete integration and update documentation
**Complexity**: Low

Tasks:
- [x] Test complete workflow: visual select → `<leader>ac` → prompt → Claude
- [x] Verify behavior with different visual selection modes (v, V, Ctrl-v)
- [x] Test edge cases: empty selection, very large selection, special characters
- [x] Update `ai/claude/README.md` with new functionality documentation
- [x] Add usage examples and troubleshooting information
- [x] Update keybinding documentation in `docs/MAPPINGS.md` if it exists
- [x] Test interaction with existing Claude features (session management, etc.)

Testing:
```bash
# Run comprehensive integration tests
# Test with various file types and selection sizes
# Verify documentation accuracy
:TestNearest  # If tests exist for visual module
```

Expected outcome: Fully functional feature with complete documentation

## Testing Strategy

### Unit Testing
- Function-level testing for prompt collection
- Visual selection validation testing
- Error handling verification

### Integration Testing
- End-to-end workflow testing
- Claude Code terminal integration
- Which-key mapping behavior verification

### User Experience Testing
- Visual mode detection accuracy
- Prompt input user experience
- Error message clarity and helpfulness

## Documentation Requirements

### Code Documentation
- Function docstrings for new functionality
- Inline comments explaining complex logic
- Configuration option documentation

### User Documentation
- Update `ai/claude/README.md` with new mapping
- Add usage examples and common workflows
- Document troubleshooting steps

### Mapping Documentation
- Update which-key descriptions
- Document mode restrictions and behavior
- Update any existing keybinding reference docs

## Dependencies

### Internal Dependencies
- Existing `ai/claude/core/visual.lua` module
- Which-key configuration system
- Claude Code terminal integration

### External Dependencies
- `vim.ui.input()` (built-in Neovim UI)
- Which-key.nvim plugin
- Claude Code terminal functionality

## Implementation Details

### Function Signature
```lua
-- New function in core/visual.lua
function M.send_visual_to_claude_with_prompt()
  -- Get visual selection
  -- Prompt user for input
  -- Validate both selection and prompt
  -- Send to Claude with prompt
end
```

### Which-Key Configuration
```lua
-- In which-key.lua
{ "<leader>ac",
  function() require("neotex.plugins.ai.claude.core.visual").send_visual_to_claude_with_prompt() end,
  desc = "send selection to claude with prompt",
  mode = { "v" },  -- Visual mode only
  icon = "󰘳"
},
{ "<leader>aC", "<cmd>ClaudeCommands<CR>", desc = "claude commands", icon = "󰘳" },
```

### Prompt Configuration
```lua
-- Add to visual.lua config
M.config = {
  -- ... existing config ...
  prompt_placeholder = "Ask Claude about this code...",
  prompt_title = "Claude Prompt",
  allow_empty_prompt = false,
}
```

## Error Handling

### Selection Validation
- Empty selection detection
- Mode validation (visual modes only)
- Buffer accessibility checks

### Prompt Validation
- Handle user cancellation (ESC, Ctrl-C)
- Empty prompt handling
- Prompt length validation

### Claude Integration
- Terminal availability verification
- Claude Code session state checking
- Network/communication error handling

## Notes

### Current Mapping Conflict
The current `<leader>ac` mapping is used for "claude commands" which needs to be preserved. Moving it to `<leader>aC` (capital C) maintains accessibility while freeing up the lowercase version for this more common use case.

### Visual Mode Specificity
The mapping should only be active in visual modes to prevent accidental activation when no text is selected. This provides a better user experience and clearer intent.

### User Experience Considerations
- Clear, descriptive prompts for user input
- Helpful error messages for common issues
- Progress feedback during Claude integration
- Consistent behavior across different visual selection types

### Future Enhancements
- Template prompts for common use cases
- History of previous prompts
- Integration with Claude session context
- Customizable prompt shortcuts