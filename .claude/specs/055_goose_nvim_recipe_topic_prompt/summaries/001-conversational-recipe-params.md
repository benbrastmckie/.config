# Summary: Conversational Recipe Parameter Prompting

**Date**: 2025-12-09
**Status**: IMPLEMENTED
**Files Changed**: 1

## Problem

When selecting a recipe via `<leader>aR` picker (e.g., "research"), the goose sidebar would open but display a message asking for the topic parameter. This happened because:

1. `user_prompt` parameters with empty values didn't abort execution
2. Recipe was sent to Goose with unsubstituted template variables (`{{ topic }}`)
3. Goose recognized the missing parameter and prompted inside the sidebar conversation

## Solution

Replaced the complex pre-prompt flow with native goose.nvim integration:

**Before**: Prompt for params via `vim.fn.input()` -> Build CLI args -> Spawn `plenary.job`

**After**: Send `/recipe:<name>` command via `goose_core.run()` -> Goose handles prompting conversationally

## Changes

### `nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

Simplified `run_recipe_in_sidebar()` from ~160 lines to ~40 lines:

```lua
-- Before: Complex parameter collection and job spawning
local params = M.prompt_for_parameters(metadata.parameters)
-- ... 100+ lines of job management

-- After: Native goose.core integration
local prompt = string.format('/recipe:%s', recipe_name)
goose_core.run(prompt)
```

## Benefits

1. **Natural UX**: Select recipe -> Sidebar opens -> Goose asks for parameters conversationally
2. **Simpler code**: Removed ~120 lines of parameter prompting and job management
3. **Better integration**: Uses goose.nvim's native session/job handling
4. **Consistent experience**: Parameters collected in same chat interface as recipe output

## Testing

1. Restart Neovim
2. Press `<leader>aR` to open recipe picker
3. Select "research"
4. Sidebar opens, Goose asks "Please provide a natural language description of the research topic"
5. Type topic in chat, recipe executes
