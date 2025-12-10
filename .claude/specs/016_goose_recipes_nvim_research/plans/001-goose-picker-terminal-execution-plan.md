# Implementation Plan: Goose Recipe Picker Terminal Execution

## Metadata
- **Date**: 2025-12-10
- **Feature**: Refactor `<leader>aj` picker to run recipe commands in neovim terminal for interactive goose CLI usage
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-goose-nvim-recipes-research.md](../reports/001-goose-nvim-recipes-research.md)

## Problem Statement

The current `<leader>aj` goose recipe picker executes recipes using `plenary.job` which:
1. Runs recipes in the background with output streamed to goose.nvim sidebar
2. Does NOT provide an interactive terminal session
3. Cannot handle interactive goose CLI features (prompts, real-time input)
4. User cannot interact with the goose session as they would in a terminal

**User Goal**: Run recipe commands in the neovim terminal (via toggleterm or similar) so that:
- Full interactive goose CLI experience is available
- Real-time streaming output is visible
- User can interrupt/interact with long-running recipes
- Recipe management remains via the `<leader>aj` picker UI

## Architecture Overview

### Current Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                 Recipe Picker (init.lua)                    │
│           <leader>aj opens Telescope picker                 │
└────────────────────┬────────────────────────────────────────┘
                     │ <CR> selection
                     v
┌─────────────────────────────────────────────────────────────┐
│               Execution (execution.lua)                     │
│        plenary.job -> goose.nvim sidebar output             │
└─────────────────────────────────────────────────────────────┘
```

### Target Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                 Recipe Picker (init.lua)                    │
│           <leader>aj opens Telescope picker                 │
└────────────────────┬────────────────────────────────────────┘
                     │ <CR> selection
                     v
┌─────────────────────────────────────────────────────────────┐
│               Execution (execution.lua)                     │
│    TermExec -> toggleterm terminal (interactive session)    │
└─────────────────────────────────────────────────────────────┘
```

## Phase Overview

| Phase | Description | Dependencies |
|-------|-------------|--------------|
| 1 | Add terminal execution function | None |
| 2 | Refactor picker to use terminal execution | Phase 1 |
| 3 | Add execution mode configuration | Phase 2 |
| 4 | Testing and validation | Phase 3 |

## Detailed Phases

### Phase 1: Add Terminal Execution Function [COMPLETE]

**Objective**: Create a new execution function that runs recipes in neovim terminal

**Files to Modify**:
- `nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

**Implementation Details**:

1. Add new function `run_recipe_in_terminal(recipe_path, metadata)`
   - Build goose CLI command: `goose run --recipe <path>`
   - Handle parameter prompting (existing logic)
   - Build `--params key=value` flags
   - Execute via `TermExec cmd='<command>'`

2. Command construction pattern:
   ```lua
   local cmd = string.format(
     "goose run --recipe '%s'%s",
     recipe_path,
     params_string -- --params key=value --params key2=value2
   )
   vim.cmd(string.format("TermExec cmd='%s'", cmd))
   ```

3. Shell escaping requirements:
   - Recipe paths with spaces: wrap in single quotes
   - Parameter values with special chars: escape single quotes
   - Use existing `_serialize_params` logic as reference

**Success Criteria**:
- [x] `run_recipe_in_terminal` function implemented
- [x] Function handles recipes with no parameters
- [x] Function handles recipes with required parameters
- [x] Function handles recipes with user_prompt parameters
- [x] Shell escaping prevents injection vulnerabilities

**Estimated Effort**: 1-2 hours

---

### Phase 2: Refactor Picker to Use Terminal Execution [COMPLETE]

**Objective**: Change default `<CR>` action to use terminal execution

**Files to Modify**:
- `nvim/lua/neotex/plugins/ai/goose/picker/init.lua`

**Implementation Details**:

1. Modify `actions.select_default:replace` callback:
   - Replace `execution.run_recipe_in_sidebar` with `execution.run_recipe_in_terminal`
   - Replace `execution.prompt_in_sidebar` with parameter prompting + terminal execution

2. Update parameter flow:
   - For `user_prompt` parameters: prompt via `vim.ui.input` then execute in terminal
   - For `required` parameters: prompt via `vim.fn.input` (existing pattern)
   - For `optional` parameters with defaults: use default values

3. Remove sidebar-specific code from default action:
   - Keep `<C-p>` preview mode as-is (already uses TermExec)
   - Consider adding new keymap for sidebar execution if backward compatibility needed

**Success Criteria**:
- [x] `<CR>` executes recipe in neovim terminal
- [x] Parameter prompting works before terminal execution
- [x] Terminal opens and shows goose CLI output
- [x] User can interact with goose session in terminal

**Estimated Effort**: 1-2 hours

---

### Phase 3: Add Execution Mode Configuration [COMPLETE]

**Objective**: Allow user to choose between terminal and sidebar execution modes

**Files to Modify**:
- `nvim/lua/neotex/plugins/ai/goose/picker/init.lua`
- `nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

**Implementation Details**:

1. Add configuration option:
   ```lua
   M.config = {
     execution_mode = 'terminal', -- 'terminal' or 'sidebar'
   }
   ```

2. Add keymaps for both modes:
   - `<CR>`: Execute with configured default mode
   - `<C-t>`: Force terminal execution
   - `<C-s>`: Force sidebar execution

3. Update `show_recipe_picker` to respect config:
   ```lua
   if M.config.execution_mode == 'terminal' then
     execution.run_recipe_in_terminal(recipe.path, meta)
   else
     execution.run_recipe_in_sidebar(recipe.path, meta)
   end
   ```

4. Add setup function parameter:
   ```lua
   function M.setup(opts)
     M.config = vim.tbl_deep_extend('force', M.config, opts or {})
   end
   ```

**Success Criteria**:
- [x] Configuration option for execution_mode
- [x] `<CR>` respects configured mode
- [x] `<C-t>` always uses terminal
- [x] `<C-s>` always uses sidebar
- [x] Setup function accepts configuration

**Estimated Effort**: 1 hour

---

### Phase 4: Testing and Validation [COMPLETE]

**Objective**: Verify all execution paths work correctly

**Test Cases**:

1. **Terminal Execution - No Parameters**:
   - Select recipe with no parameters
   - Press `<CR>`
   - Verify terminal opens with `goose run --recipe <path>`
   - Verify goose CLI starts and shows output

2. **Terminal Execution - Required Parameters**:
   - Select recipe with required parameters
   - Press `<CR>`
   - Verify parameter prompt appears
   - Enter values and confirm
   - Verify terminal command includes `--params key=value`

3. **Terminal Execution - User Prompt Parameters**:
   - Select recipe with user_prompt parameter
   - Press `<CR>`
   - Verify prompt for user input
   - Enter input and confirm
   - Verify terminal command includes user input as parameter

4. **Mode Switching**:
   - Test `<C-t>` forces terminal mode
   - Test `<C-s>` forces sidebar mode
   - Test configuration change affects default behavior

5. **Edge Cases**:
   - Recipe path with spaces
   - Parameter values with special characters (quotes, ampersands)
   - Canceling parameter prompt
   - Empty parameter values

**Validation Commands**:
```bash
# Test terminal execution manually
goose run --recipe /path/to/recipe.yaml

# Test with parameters
goose run --recipe /path/to/recipe.yaml --params key="value"

# Verify toggleterm integration
:TermExec cmd='goose run --recipe /path/to/test.yaml'
```

**Success Criteria**:
- [ ] All test cases pass
- [ ] No shell injection vulnerabilities
- [ ] Error handling for missing recipes
- [ ] Notifications for execution status

**Estimated Effort**: 1 hour

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| toggleterm not installed | Low | High | Check for toggleterm, fallback to vim.cmd('terminal') |
| Shell escaping issues | Medium | High | Use vim.fn.shellescape for all user inputs |
| Parameter prompt UX | Low | Medium | Keep existing vim.fn.input pattern |
| Backward compatibility | Low | Low | Add config option to preserve sidebar behavior |

## Dependencies

**Required Plugins**:
- toggleterm.nvim (for TermExec command)
- telescope.nvim (existing dependency)
- plenary.nvim (existing dependency)

**Fallback**: If toggleterm not available, use native `:terminal` command:
```lua
local has_toggleterm = pcall(require, 'toggleterm')
if has_toggleterm then
  vim.cmd(string.format("TermExec cmd='%s'", cmd))
else
  vim.cmd('terminal ' .. cmd)
end
```

## Implementation Notes

1. **Preserve existing functionality**: The sidebar execution code should remain available for users who prefer it

2. **Command escaping**: Use `vim.fn.shellescape()` for recipe paths and parameter values to prevent shell injection

3. **Terminal naming**: Consider setting terminal title to recipe name for identification:
   ```lua
   vim.cmd(string.format("TermExec cmd='%s' name='goose:%s'", cmd, recipe_name))
   ```

4. **Session handling**: Terminal execution creates new goose session each time (unlike sidebar which can resume). Document this behavior difference.

## Success Metrics

1. User can select recipe from picker and execute in terminal
2. Interactive goose session available in terminal
3. Parameter prompting works correctly
4. Configuration allows switching between terminal and sidebar modes
5. No regression in existing sidebar functionality
