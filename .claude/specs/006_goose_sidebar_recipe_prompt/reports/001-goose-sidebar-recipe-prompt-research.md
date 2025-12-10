# Research Report: Goose Sidebar Recipe Prompt Implementation

## Executive Summary

This report analyzes the implementation requirements for enabling recipe parameter input through the goose.nvim sidebar instead of vim.fn.input(). The user wants to select a recipe from the `<leader>aj` picker and have the goose sidebar open with a prompt asking for their description, which then gets used as the recipe parameter.

## Current Architecture

### Recipe Picker Flow (`nvim/lua/neotex/plugins/ai/goose/picker/`)

1. **init.lua** - Main entry point with `show_recipe_picker()` function
   - Uses Telescope for recipe selection
   - On `<CR>` action: calls `execution.run_recipe_in_sidebar(recipe.path, meta)`
   - Existing `<C-d>` mapping for `modification.add_description()` (writes to YAML file)

2. **execution.lua** - Recipe execution logic
   - `run_recipe_in_sidebar(recipe_path, metadata)` - Main execution function
   - `prompt_for_parameters(parameters)` - Uses `vim.fn.input()` for `user_prompt` parameters
   - Builds CLI: `goose run --recipe <path> --params key=value`
   - Uses `plenary.job` for async execution with output streaming to sidebar

3. **metadata.lua** - YAML parsing for recipe metadata
   - Extracts parameters with `requirement: user_prompt` designation

### goose.nvim Plugin Architecture (`~/.local/share/nvim/lazy/goose.nvim/lua/goose/`)

1. **core.lua** - Main API
   - `core.run(prompt)` - Sends text to goose via sidebar
   - `core.open({focus, new_session})` - Opens sidebar windows

2. **ui/ui.lua** - UI management
   - `ui.write_to_input(text)` - Writes text to input buffer
   - `ui.create_windows()` - Creates input/output windows

3. **ui/window_config.lua** - Window configuration and keymaps
   - `handle_submit(windows)` - Local function that reads input buffer and calls `core.run()`
   - Submit keymaps configured at lines 250-256

4. **job.lua** - Goose CLI execution
   - `build_args(prompt)` - Creates `goose run --text <message>` args
   - Uses `--name` and `--resume` for session management

## Key Findings

### Finding 1: Submit Handler is Local
The `handle_submit()` function in `window_config.lua` is local and calls `core.run(input_content)`. This means we cannot directly intercept it without modifying goose.nvim.

### Finding 2: Keymap Override is Possible
After `goose_core.open()` creates windows, we have access to `state.windows.input_buf`. We can override the submit keymap on this buffer with our custom handler.

### Finding 3: Recipe Parameters Use Separate CLI Path
Recipes use `goose run --recipe <path> --params` while normal chat uses `goose run --text`. These are distinct execution paths.

### Finding 4: State Management Required
Need to track "pending recipe" state so our custom submit handler knows to run the recipe instead of normal chat.

## Recommendations

### Recommendation 1: Pending Recipe State Pattern
Store pending recipe information in execution.lua module state:
```lua
M._pending_recipe = nil  -- { path, metadata, param_key }
```

### Recommendation 2: Custom Submit Handler with Keymap Override
After opening sidebar for recipe prompt:
1. Store pending recipe info
2. Write prompt message to output buffer
3. Override submit keymap with recipe-aware handler
4. Handler checks _pending_recipe, executes recipe if set, else calls original core.run()

### Recommendation 3: Pre-fill Input Buffer (Optional Enhancement)
Optionally pre-fill input buffer with contextual hint text that user can replace.

### Recommendation 4: Graceful Cleanup
Clear _pending_recipe state after execution or if user closes sidebar without submitting.

## Technical Approach

```
User selects recipe with user_prompt param
    |
    v
execution.prompt_in_sidebar(recipe_path, metadata, param_key)
    |
    +-- Store recipe info in M._pending_recipe
    |
    +-- Open sidebar: goose_core.open({ focus = 'input', new_session = true })
    |
    +-- Write prompt to output: ui.write_to_output("Enter description for recipe...")
    |
    +-- Override submit keymap on input_buf
    |
    v
User types description and presses submit
    |
    v
Custom submit handler:
    +-- Read input buffer content
    +-- Check M._pending_recipe
    +-- If set: run_recipe_with_param(recipe, param_key, input_content)
    +-- Clear M._pending_recipe
    +-- Restore original keymap (or leave custom handler to check nil state)
```

## Files to Modify

1. **nvim/lua/neotex/plugins/ai/goose/picker/execution.lua**
   - Add `M._pending_recipe` state
   - Add `M.prompt_in_sidebar()` function
   - Add `M._handle_recipe_submit()` function

2. **nvim/lua/neotex/plugins/ai/goose/picker/init.lua**
   - Modify `<CR>` action to detect `user_prompt` params
   - Route to `prompt_in_sidebar()` instead of `prompt_for_parameters()`

## Risk Assessment

- **Low Risk**: Changes are isolated to picker module, no goose.nvim modifications
- **Keymap Override**: Standard Neovim pattern, well-documented
- **State Management**: Simple nil/table toggle, easy to debug

## Conclusion

The implementation is feasible with minimal code changes. The keymap override pattern is the cleanest approach as it requires no modifications to the goose.nvim plugin and keeps all logic within the picker module.
