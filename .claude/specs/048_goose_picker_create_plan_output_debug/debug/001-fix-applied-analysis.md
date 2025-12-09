# Debug Analysis: Goose Picker Quote Nesting Fix

**Date**: 2025-12-09
**Status**: Root Cause Identified, Fix Ready

## Issue Summary

The goose picker fails to execute recipes via `<leader>aR` with error:
```
error: a value is required for '--recipe <RECIPE_NAME or FULL_PATH_TO_RECIPE_FILE>' but none was supplied
```

## Root Cause

**Nested single-quote collision** in execution.lua line 31.

The `shell_escape()` function wraps paths in single quotes:
```
goose run --recipe '/path/to/recipe.yaml' --interactive
```

The TermExec command also uses single quotes:
```lua
vim.cmd(string.format("TermExec cmd='%s'", cmd))
```

Combined result that Vim parses incorrectly:
```vim
TermExec cmd='goose run --recipe '/path/to/recipe.yaml' --interactive'
             ^                      ^
             |                      |
        String starts          String ENDS (prematurely!)
```

Vim's parser terminates at the inner single quote, losing the recipe path.

## Fix

Change line 31 in `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`:

**From**:
```lua
vim.cmd(string.format("TermExec cmd='%s'", cmd))
```

**To**:
```lua
vim.cmd(string.format("TermExec cmd=\"%s\"", cmd))
```

## Why This Works

Double quotes delimit the `cmd` parameter for Vim's parser. Single quotes inside double-quoted strings are treated as literal characters. No escaping collision occurs.

**Corrected result**:
```vim
TermExec cmd="goose run --recipe '/path/to/recipe.yaml' --interactive"
```

## Verification Steps

1. Apply the one-line fix to execution.lua
2. Test via `<leader>aR` picker
3. Select create-plan recipe
4. Verify goose run executes successfully

## Files Involved

- **Bug Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua:31`
- **Test Recipe**: `/home/benjamin/.config/.goose/recipes/create-plan.yaml`
- **Related**: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:371-373` (keybinding)

## Risk Assessment

**Very Low** - Single line change using well-understood Vim/Lua quote escaping pattern.
