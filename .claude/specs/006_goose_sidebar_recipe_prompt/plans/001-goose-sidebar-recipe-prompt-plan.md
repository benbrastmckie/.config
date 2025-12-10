# Implementation Plan: Goose Sidebar Recipe Prompt

## Metadata

- **Date**: 2024-12-09
- **Feature**: Enable recipe parameter input through goose sidebar instead of vim.fn.input()
- **Status**: [COMPLETE]
- **Estimated Hours**: 2-4 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-goose-sidebar-recipe-prompt-research.md](../reports/001-goose-sidebar-recipe-prompt-research.md)

## Overview

When selecting a recipe from the `<leader>aj` picker that has `user_prompt` parameters, instead of prompting with vim.fn.input() at the command line, the goose sidebar will open and display a prompt message asking for the user's description. When the user types their response and submits, the recipe executes with that description as the parameter value.

## Research Summary

- Recipe picker uses Telescope and calls `execution.run_recipe_in_sidebar()` on selection
- Current `prompt_for_parameters()` uses `vim.fn.input()` for `user_prompt` parameters
- goose.nvim's `handle_submit()` is local but keymaps can be overridden on buffer level
- Need pending recipe state to intercept submit and route to recipe execution
- No modifications to goose.nvim plugin required

## Success Criteria

- [x] Selecting a recipe with `user_prompt` parameters opens goose sidebar
- [x] Sidebar displays prompt message asking for description
- [x] User can type description in sidebar input area
- [x] Submitting runs the recipe with user's input as parameter value
- [x] Normal submit behavior preserved when no pending recipe
- [x] Sidebar cleanup works correctly (close without submit clears state)

## Implementation Phases

### Phase 1: Add Pending Recipe State and Prompt Function [COMPLETE]

**Objective**: Create the state management and sidebar prompt function in execution.lua

**Tasks**:
- [x] Add `M._pending_recipe` module state variable (nil or table with path, metadata, param_key)
- [x] Create `M.prompt_in_sidebar(recipe_path, metadata, param_key)` function that:
  - Stores recipe info in `M._pending_recipe`
  - Opens sidebar with `goose_core.open({ focus = 'input', new_session = true })`
  - Writes prompt message to output buffer using goose.nvim's render functions
  - Sets up submit keymap override on input buffer
- [x] Create `M._create_recipe_submit_handler(windows)` that returns a function to:
  - Read input buffer content
  - Check `M._pending_recipe` state
  - If set: call existing recipe execution with user input as param value
  - Clear `M._pending_recipe` after execution
  - If not set: fall through to normal `core.run()` behavior

**Testing**:
- Manually test `prompt_in_sidebar()` by adding temporary keymap
- Verify sidebar opens with prompt message
- Verify submit handler correctly detects pending recipe state

**Dependencies**: None (first phase)

### Phase 2: Integrate with Picker Selection Flow [COMPLETE]

**Objective**: Route recipes with `user_prompt` parameters through the new sidebar flow

**Tasks**:
- [x] Modify `<CR>` action in `init.lua` to detect `user_prompt` parameters in metadata
- [x] If `user_prompt` parameter exists, call `execution.prompt_in_sidebar()` instead of `run_recipe_in_sidebar()`
- [x] If no `user_prompt` parameters, preserve existing direct execution behavior
- [x] Handle case where recipe has multiple `user_prompt` parameters (prompt for first, then next)

**Testing**:
- Select recipe with `user_prompt` param (e.g., create-plan.yaml)
- Verify sidebar opens with prompt instead of vim.fn.input()
- Type description and submit
- Verify recipe executes correctly with provided parameter
- Select recipe without `user_prompt` params
- Verify existing behavior preserved (direct execution)

**Dependencies**: Phase 1

### Phase 3: Polish and Edge Cases [COMPLETE]

**Objective**: Handle edge cases and improve user experience

**Tasks**:
- [x] Clear `_pending_recipe` state when sidebar is closed without submit (WinClosed autocmd)
- [x] Add visual indicator in output area showing which recipe is pending (recipe name, parameter being requested)
- [x] Handle escape/cancel gracefully (clear state, no error messages)
- [x] Ensure keymap override is properly cleaned up after use
- [x] Add recipe parameter description to prompt message if available from metadata

**Testing**:
- Open sidebar for recipe, then close without submitting - verify clean state
- Open sidebar for recipe, press escape - verify no error messages
- Submit with empty input - verify appropriate handling (error or default behavior)
- Rapid open/close cycles - verify no state leaks

**Dependencies**: Phase 2

## Technical Notes

### Key Files

| File | Purpose |
|------|---------|
| `nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` | Recipe execution, new prompt_in_sidebar function |
| `nvim/lua/neotex/plugins/ai/goose/picker/init.lua` | Picker entry point, selection routing |
| `nvim/lua/neotex/plugins/ai/goose/picker/metadata.lua` | Recipe metadata parsing (read-only reference) |

### State Flow

```
User selects recipe
    |
    v
Check for user_prompt params
    |
    +-- No params --> run_recipe_in_sidebar() (existing)
    |
    +-- Has params --> prompt_in_sidebar()
                          |
                          v
                       Store M._pending_recipe
                          |
                          v
                       Open sidebar + write prompt
                          |
                          v
                       Override submit keymap
                          |
                          v
                       User submits
                          |
                          v
                       Custom handler runs recipe
                          |
                          v
                       Clear M._pending_recipe
```

### Keymap Override Pattern

```lua
-- After sidebar opens, override submit keymap
local submit_key = config.keymap.window.submit  -- typically '<CR>'
vim.keymap.set('n', submit_key, function()
  M._handle_recipe_submit(state.windows)
end, { buffer = state.windows.input_buf, silent = false })
```

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| goose.nvim update breaks assumptions | Medium | Pin to known version, test after updates |
| State leak if sidebar closed unexpectedly | Low | WinClosed autocmd to clear state |
| Keymap conflict with other plugins | Low | Use buffer-local keymaps only |

## Out of Scope

- Modifying goose.nvim plugin code
- Supporting multiple simultaneous pending recipes
- Recipe parameter validation beyond what goose CLI provides
- Changing recipe YAML format or adding new parameter types
