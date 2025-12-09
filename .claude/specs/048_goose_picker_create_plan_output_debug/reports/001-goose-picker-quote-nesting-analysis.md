# Root Cause Analysis: Goose Picker Recipe Execution Failure

**Date**: 2025-12-09
**Issue**: Recipe execution via `<leader>aR` fails with "error: a value is required for '--recipe'"
**Affected Component**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`
**Severity**: Critical - Blocks all recipe execution via picker

## Executive Summary

The goose picker fails to execute recipes because of **nested single-quote collision** in the TermExec command string. The `shell_escape()` function wraps the recipe path in single quotes, but TermExec's `cmd='...'` parameter also uses single quotes, causing Vim's parser to terminate the string prematurely and lose the recipe path.

**Root Cause**: Quote nesting conflict between shell_escape wrapper and TermExec parameter syntax
**Impact**: Recipe path is not passed to goose CLI, causing execution failure
**Fix Complexity**: Low (single line change in execution.lua:31)

## Error Evidence

### Observed Error Output
```
error: a value is required for '--recipe <RECIPE_NAME or FULL_PATH_TO_RECIPE_FILE>' but none was supplied
```

Location: `/home/benjamin/.config/.claude/output/goose-picker-output.md`

### What This Indicates
The goose CLI received `goose run --recipe` with **no value**, meaning the recipe path was lost during command construction or transmission to ToggleTerm.

## Code Flow Analysis

### 1. User Invokes Picker
- **Keybinding**: `<leader>aR` (from which-key.lua:371-373)
- **Action**: Calls `require("neotex.plugins.ai.goose.picker").show_recipe_picker()`

### 2. Recipe Selection
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/init.lua`
- **Lines**: 61-70
- **Process**:
  1. User selects recipe from Telescope picker
  2. Selection handler extracts `recipe.path` (absolute path)
  3. Calls `metadata.parse(recipe.path)` to extract parameters
  4. If successful, calls `execution.run_recipe(recipe.path, meta)`

### 3. Parameter Prompting
- **File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`
- **Lines**: 19-39
- **Process**:
  1. `run_recipe()` calls `prompt_for_parameters(metadata.parameters)`
  2. For create-plan.yaml, prompts for:
     - `feature_description` (requirement: user_prompt)
     - `complexity` (optional, default: 3)
     - `prompt_file` (optional)
  3. Returns params table (could be empty `{}` if all defaults used)

### 4. Command Building (THE PROBLEM)
- **File**: execution.lua
- **Lines**: 138-156
- **Code**:
```lua
function M.build_command(recipe_path, params)
  -- Line 140: Wraps path in single quotes
  local cmd = string.format('goose run --recipe %s --interactive', M.shell_escape(recipe_path))

  -- Lines 143-152: Add parameters if present
  if params and vim.tbl_count(params) > 0 then
    local param_parts = {}
    for key, value in pairs(params) do
      local escaped_value = M.shell_escape(tostring(value))
      table.insert(param_parts, string.format('%s=%s', key, escaped_value))
    end
    cmd = cmd .. ' --params ' .. table.concat(param_parts, ',')
  end

  return cmd
end
```

- **shell_escape function** (lines 163-166):
```lua
function M.shell_escape(str)
  -- Wraps string in single quotes: 'path/to/file.yaml'
  return "'" .. str:gsub("'", "'\\''") .. "'"
end
```

**Result**: `cmd` becomes:
```
goose run --recipe '/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive
```

### 5. TermExec Invocation (THE FAILURE POINT)
- **File**: execution.lua
- **Line**: 31
- **Code**:
```lua
vim.cmd(string.format("TermExec cmd='%s'", cmd))
```

**Constructed Command**:
```vim
TermExec cmd='goose run --recipe '/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive'
```

## Root Cause Explanation

### The Nested Quote Problem

The TermExec command uses **single quotes** to delimit the `cmd` parameter:
```
TermExec cmd='...'
```

But the `cmd` value **also contains single quotes** from shell_escape:
```
goose run --recipe '/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive
```

When Vim parses this:
```
TermExec cmd='goose run --recipe '/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive'
             ^                      ^
             |                      |
        String starts          String ENDS (prematurely!)
```

Vim's parser sees:
1. `cmd='goose run --recipe '` - Complete string (WRONG!)
2. `/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive'` - Garbage/unparsed text

**Result**: TermExec receives `cmd="goose run --recipe "` (empty recipe value)

### Why This Happens

1. **Lua string.format**: Constructs literal string without Vim quote awareness
2. **vim.cmd()**: Passes string to Vim command parser
3. **Vim parser**: Sees single quote inside single-quoted string as terminator
4. **Quote escaping doesn't help**: shell_escape uses `'\''` which is for **shell**, not **Vim**

### Confirmation Evidence

From test analysis:
```bash
# What execution.lua creates:
TermExec cmd='goose run --recipe '/path/to/file.yaml' --interactive'

# What Vim parses:
cmd = 'goose run --recipe '
# (rest is ignored/malformed)

# What goose CLI receives:
goose run --recipe
# Error: no value provided!
```

## Component Analysis

### execution.lua (PRIMARY BUG LOCATION)
- **Function**: `run_recipe()` (line 19)
- **Issue**: Line 31 uses single quotes for TermExec cmd parameter
- **Current**: `vim.cmd(string.format("TermExec cmd='%s'", cmd))`
- **Problem**: Conflicts with single quotes from shell_escape

### shell_escape() (SECONDARY ISSUE)
- **Function**: `shell_escape()` (line 163)
- **Purpose**: Escape shell special characters for safe execution
- **Current Implementation**: Wraps in single quotes with `'\''` escaping
- **Problem**: Not compatible with Vim's command parsing (only shell parsing)

### Other Functions (WORKING CORRECTLY)
- **discovery.lua**: Returns absolute paths correctly
- **metadata.parse()**: Extracts parameters successfully
- **prompt_for_parameters()**: Collects user input properly
- **build_command()**: Constructs valid shell command (but wrong for Vim context)

## Recommended Fix

### Solution: Use Double Quotes for TermExec Parameter

**Change execution.lua line 31 from**:
```lua
vim.cmd(string.format("TermExec cmd='%s'", cmd))
```

**To**:
```lua
vim.cmd(string.format("TermExec cmd=\"%s\"", cmd))
```

**Result**:
```vim
TermExec cmd="goose run --recipe '/home/benjamin/.config/.goose/recipes/create-plan.yaml' --interactive"
```

Now Vim parses:
- `cmd="..."` - Double-quoted string
- Single quotes inside are preserved as literal characters
- Full command passes to TermExec correctly

### Alternative Solution: Remove shell_escape and Use Double Quotes Throughout

**Modify build_command() to**:
```lua
function M.build_command(recipe_path, params)
  -- Use double quotes for paths (no shell_escape needed)
  local cmd = string.format('goose run --recipe "%s" --interactive', recipe_path)

  if params and vim.tbl_count(params) > 0 then
    local param_parts = {}
    for key, value in pairs(params) do
      -- Use double quotes for parameter values
      table.insert(param_parts, string.format('%s="%s"', key, tostring(value)))
    end
    cmd = cmd .. ' --params ' .. table.concat(param_parts, ',')
  end

  return cmd
end
```

**And modify run_recipe() line 31**:
```lua
vim.cmd(string.format("TermExec cmd=\"%s\"", cmd))
```

**Result**:
```vim
TermExec cmd="goose run --recipe "/home/benjamin/.config/.goose/recipes/create-plan.yaml" --interactive"
```

## Recommended Approach

**OPTION 1** (Minimal Change - RECOMMENDED):
- Change only line 31 in execution.lua
- Keep shell_escape as-is (single quotes work inside double-quoted TermExec cmd)
- Low risk, minimal code change

**OPTION 2** (Consistent Quoting):
- Change build_command() to use double quotes
- Change run_recipe() line 31 to use double quotes for TermExec
- Remove shell_escape dependency (simpler, but more changes)
- Higher test surface area

## Testing Verification

### Test Case 1: Basic Recipe Execution
```
1. Open Neovim
2. Press <leader>aR
3. Select create-plan recipe
4. Enter feature_description when prompted
5. Verify: goose run executes with correct recipe path
```

### Test Case 2: Recipe with Spaces in Path (edge case)
```
1. Create test recipe at: ~/.config/goose/recipes/test recipe.yaml
2. Select via picker
3. Verify: path correctly quoted and executed
```

### Test Case 3: Recipe with Parameters
```
1. Select create-plan recipe
2. Provide complexity=2
3. Verify: --params complexity=2 passed correctly
```

### Test Case 4: Recipe with Single Quote in Path (edge case)
```
1. Create test recipe at: ~/.config/goose/recipes/test's-recipe.yaml
2. Select via picker
3. Verify: shell_escape handles single quote correctly
```

## Additional Files Referenced

### Working Files (No Changes Needed)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/init.lua` - Entry point, working correctly
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/discovery.lua` - Returns absolute paths correctly
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/metadata.lua` - YAML parsing works
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/previewer.lua` - Not involved in execution

### Test Recipe
- `/home/benjamin/.config/.goose/recipes/create-plan.yaml` - Valid recipe with 3 parameters (1 user_prompt, 2 optional)

### Related Configuration
- `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua:371-373` - Keybinding definition

## Summary

**Root Cause**: Nested single-quote collision between shell_escape wrapper (`'...'`) and TermExec parameter syntax (`cmd='...'`)

**Failure Mechanism**: Vim's parser terminates the `cmd` string prematurely when encountering the single quote from shell_escape, causing the recipe path to be lost

**Impact**: All recipe executions via picker fail with "no value for --recipe"

**Fix**: Change execution.lua line 31 to use double quotes for TermExec cmd parameter, allowing single-quoted paths inside

**Risk Level**: Low (one-line change, well-understood quote escaping)

**Testing Priority**: High (validates basic picker functionality)
