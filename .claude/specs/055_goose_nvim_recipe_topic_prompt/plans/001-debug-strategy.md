# Debug Strategy: Goose Nvim Recipe Topic Prompt Issue

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix recipe parameter prompting in Neovim Goose picker
- **Status**: [NOT STARTED]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001-goose-nvim-recipe-topic-prompt-analysis.md)
- **Complexity Score**: 45.0
- **Structure Level**: 0

## Overview

The Goose sidebar displays "I understand that you want to initiate the research recipe. This recipe requires a topic to proceed" when recipes are invoked via `<leader>aR` in Neovim because the picker executes `goose run --recipe` without collecting `user_prompt` parameters first. The Goose CLI does not interactively prompt for parameters, causing recipes to receive unsubstituted template variables (`{{ topic }}`).

This debug strategy focuses on fixing the parameter collection flow in the Nvim picker to collect parameters before CLI invocation, validating the fix across all affected recipes, and adding user feedback during parameter collection.

## Research Summary

Key findings from root cause analysis:

1. **Parameter Collection Gap**: The `prompt_for_parameters()` function exists but is called after sidebar opening, creating a race condition where recipes execute without parameter values
2. **CLI Behavior**: Goose CLI does not prompt for `user_prompt` parameters; unsubstituted template variables appear as literal text (`{{ parameter_name }}`)
3. **Widespread Impact**: 5 recipes use `user_prompt` requirement type (research, create-plan, implement, revise, and others)
4. **Recipe Validation Errors**: Multiple recipes contain syntax errors (research.yaml:10 uses invalid `integer` type, create-plan.yaml missing `title` field) that prevent testing
5. **Existing Infrastructure**: Parameter collection, validation, and serialization functions already implemented but not properly integrated into execution flow

Recommended approach: Implement pre-execution parameter collection by moving `prompt_for_parameters()` call before sidebar opening, fix recipe validation errors, and enhance UX with clear feedback during parameter prompts.

## Success Criteria

- [ ] All recipes with `user_prompt` parameters execute successfully via Nvim picker
- [ ] Parameter prompts appear before recipe execution (not after sidebar opens)
- [ ] Recipe validation errors are fixed (research.yaml, create-plan.yaml pass `--explain`)
- [ ] User receives clear feedback during parameter collection (count, validation, cancellation)
- [ ] Automated tests verify parameter collection, validation, and CLI argument construction

## Technical Design

### Architecture Overview

The fix involves three components:

1. **Execution Flow Refactor** (execution.lua:35-78):
   - Move `prompt_for_parameters()` call before sidebar opening
   - Collect parameters synchronously via `vim.fn.input()` prompts
   - Pass collected parameters to `goose run --params key=value,key2=value2`

2. **Recipe YAML Fixes** (recipes/*.yaml):
   - Fix research.yaml:10: Change `input_type: integer` to `input_type: number`
   - Fix create-plan.yaml: Add required `title` field to frontmatter

3. **User Feedback Enhancement** (execution.lua:203-249):
   - Add parameter count notification before first prompt
   - Show parameter index during prompts: "[1/2] Enter topic (string): "
   - Display validation hints in error messages
   - Support Ctrl-C cancellation with confirmation

### Component Interactions

```
User Trigger (<leader>aR)
    ↓
Picker (picker.lua:select_recipe)
    ↓
Execution (execution.lua:run_recipe_in_sidebar)
    ├─ Parse metadata (metadata.lua:parse_recipe)
    ├─ Collect parameters (prompt_for_parameters) ← MOVED HERE
    ├─ Validate parameters (validate_param)
    ├─ Serialize parameters (_serialize_params)
    ├─ Open sidebar (sidebar.lua:open)
    └─ Execute CLI (plenary.job: goose run --recipe X --params Y)
```

### Key Changes

1. **Parameter Collection Timing**: Move from asynchronous (after sidebar open) to synchronous (before sidebar open)
2. **Validation Integration**: Use existing `validate_param()` for type checking during collection
3. **Error Handling**: Cancel execution if required parameters missing or invalid (before sidebar opens)
4. **User Feedback**: Add progress notifications at each collection step

## Implementation Phases

### Phase 1: Fix Recipe Validation Errors [NOT STARTED]
dependencies: []

**Objective**: Correct recipe YAML syntax errors to enable `--explain` testing and parameter validation.

**Complexity**: Low

**Tasks**:
- [ ] Fix research.yaml:10: Change `input_type: integer` to `input_type: number`
- [ ] Add validation: `goose run --recipe .goose/recipes/research.yaml --explain` succeeds
- [ ] Fix create-plan.yaml:1-12: Add required `title:` field
- [ ] Add validation: `goose run --recipe .goose/recipes/create-plan.yaml --explain` succeeds
- [ ] Test all recipes: Run `goose run --recipe .goose/recipes/*.yaml --explain` for each recipe

**Testing**:
```bash
# Validate all recipes pass --explain check
cd /home/benjamin/.config
for recipe in .goose/recipes/*.yaml; do
  echo "Validating $recipe..."
  goose run --recipe "$recipe" --explain || exit 1
done
echo "All recipes validated successfully"
```

**Expected Duration**: 0.5-1 hours

### Phase 2: Refactor Parameter Collection Flow [NOT STARTED]
dependencies: [1]

**Objective**: Move parameter collection to occur before sidebar opening, ensuring all `user_prompt` parameters are collected and validated.

**Complexity**: Medium

**Tasks**:
- [ ] Modify `run_recipe_in_sidebar()` in execution.lua:35-78 to collect parameters before sidebar call
- [ ] Update execution flow: metadata parse → parameter collection → validation → sidebar open → CLI execution
- [ ] Ensure `prompt_for_parameters()` blocks until all parameters collected or user cancels
- [ ] Pass collected parameters to CLI via `--params` flag (execution.lua:109-113)
- [ ] Add cancellation handling: Show notification and return early if user cancels any prompt

**Code Changes**:
```lua
-- execution.lua:35-78 (BEFORE)
function M.run_recipe_in_sidebar(recipe_path, recipe_name)
  -- Parse metadata
  local metadata = metadata_parser.parse_recipe(recipe_path)

  -- Open sidebar FIRST (race condition)
  sidebar.open(recipe_name)

  -- Collect parameters AFTER (too late)
  local params = M.prompt_for_parameters(metadata.parameters)

  -- Execute CLI
  plenary.job:new({ ... }):start()
end

-- execution.lua:35-78 (AFTER)
function M.run_recipe_in_sidebar(recipe_path, recipe_name)
  -- Parse metadata
  local metadata = metadata_parser.parse_recipe(recipe_path)

  -- Collect parameters BEFORE opening sidebar
  local params = M.prompt_for_parameters(metadata.parameters)
  if not params then
    vim.notify('Recipe execution cancelled', vim.log.levels.INFO)
    return
  end

  -- Open sidebar AFTER parameters collected
  sidebar.open(recipe_name)

  -- Execute CLI with parameters
  local args = M._build_cli_args(recipe_path, params)
  plenary.job:new({ command = 'goose', args = args }):start()
end
```

**Testing**:
```bash
# Manual test: Trigger picker and verify parameter prompt appears BEFORE sidebar
# 1. Open nvim
# 2. Press <leader>aR
# 3. Select "research" recipe
# 4. Verify: Parameter prompt appears in command line BEFORE sidebar opens
# 5. Enter "Lua async patterns"
# 6. Verify: Sidebar opens with research content (not parameter prompt message)
```

**Expected Duration**: 2-3 hours

### Phase 3: Enhance User Feedback During Parameter Collection [NOT STARTED]
dependencies: [2]

**Objective**: Improve parameter prompting UX with clear instructions, validation feedback, and cancellation handling.

**Complexity**: Low

**Tasks**:
- [ ] Add parameter count notification before first prompt: "Recipe requires N parameters"
- [ ] Show parameter index during prompts: "[1/3] Enter topic (string): "
- [ ] Enhance validation error messages: "Expected number, got 'abc' for parameter 'count'"
- [ ] Add cancellation confirmation: "Cancel recipe execution? Press Ctrl-C again to confirm"
- [ ] Show summary after collection: "3 parameters collected successfully"

**Code Changes**:
```lua
-- execution.lua:203-249 (enhance prompt_for_parameters)
function M.prompt_for_parameters(parameters)
  if not parameters or #parameters == 0 then
    return {}
  end

  -- Count parameters that need prompting
  local prompt_count = 0
  for _, param in ipairs(parameters) do
    if param.requirement == 'required' or param.requirement == 'user_prompt' then
      prompt_count = prompt_count + 1
    end
  end

  -- Show count notification
  if prompt_count > 0 then
    vim.notify(
      string.format('Recipe requires %d parameter%s', prompt_count, prompt_count > 1 and 's' or ''),
      vim.log.levels.INFO
    )
  end

  local params = {}
  local current_index = 1

  for _, param in ipairs(parameters) do
    if param.requirement == 'required' or param.requirement == 'user_prompt' then
      -- Enhanced prompt with index
      local prompt_text = string.format(
        '[%d/%d] Enter %s (%s)%s: ',
        current_index,
        prompt_count,
        param.key,
        param.input_type,
        param.description ~= '' and ' - ' .. param.description or ''
      )

      local ok, value = pcall(vim.fn.input, prompt_text)
      if not ok or value == '' then
        if param.requirement == 'required' then
          vim.notify(
            string.format('Required parameter "%s" not provided', param.key),
            vim.log.levels.ERROR
          )
          return nil
        end
      else
        -- Enhanced validation feedback
        local valid, converted = M.validate_param(value, param.input_type)
        if not valid then
          vim.notify(
            string.format(
              'Invalid %s value for parameter "%s": expected %s, got "%s"',
              param.input_type,
              param.key,
              param.input_type,
              value
            ),
            vim.log.levels.ERROR
          )
          return nil
        end
        params[param.key] = converted
      end

      current_index = current_index + 1
    end
  end

  -- Show success summary
  vim.notify(
    string.format('%d parameter%s collected successfully', prompt_count, prompt_count > 1 and 's' or ''),
    vim.log.levels.INFO
  )

  return params
end
```

**Testing**:
```bash
# Manual test: Verify enhanced feedback
# 1. Open nvim
# 2. Press <leader>aR
# 3. Select "create-plan" recipe (has 3 user_prompt parameters)
# 4. Verify: Notification shows "Recipe requires 3 parameters"
# 5. Enter first parameter
# 6. Verify: Prompt shows "[1/3] Enter topic (string): "
# 7. Enter invalid number (e.g., "abc" for numeric parameter)
# 8. Verify: Error shows "Expected number, got 'abc' for parameter 'complexity'"
# 9. Press Ctrl-C during second parameter
# 10. Verify: Notification shows "Recipe execution cancelled"
```

**Expected Duration**: 1-1.5 hours

### Phase 4: Automated Testing and Validation [NOT STARTED]
dependencies: [3]

**Objective**: Create automated tests to verify parameter collection, validation, and CLI argument construction.

**Complexity**: Medium

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-results.txt", "validation-report.txt"]

**Tasks**:
- [ ] Create test module: `nvim/lua/neotex/plugins/ai/goose/picker/tests/test_parameter_collection.lua`
- [ ] Test case: Verify `prompt_for_parameters()` collects all `user_prompt` parameters
- [ ] Test case: Verify parameter validation rejects invalid types (string as number, etc.)
- [ ] Test case: Verify CLI argument construction includes `--params key=value` format
- [ ] Test case: Verify cancellation handling returns nil and shows notification
- [ ] Run tests: Execute test suite and verify all tests pass

**Test Structure**:
```lua
-- nvim/lua/neotex/plugins/ai/goose/picker/tests/test_parameter_collection.lua
local execution = require('neotex.plugins.ai.goose.picker.execution')

describe('Parameter Collection', function()
  it('collects all user_prompt parameters', function()
    local params = {
      { key = 'topic', requirement = 'user_prompt', input_type = 'string' },
      { key = 'complexity', requirement = 'user_prompt', input_type = 'number' }
    }

    -- Mock vim.fn.input to return test values
    _G.vim.fn.input = function(prompt)
      if prompt:match('topic') then return 'Test Topic' end
      if prompt:match('complexity') then return '3' end
    end

    local result = execution.prompt_for_parameters(params)
    assert.are.equal('Test Topic', result.topic)
    assert.are.equal(3, result.complexity)
  end)

  it('validates parameter types', function()
    local valid, converted = execution.validate_param('abc', 'number')
    assert.is_false(valid)
    assert.is_nil(converted)

    valid, converted = execution.validate_param('42', 'number')
    assert.is_true(valid)
    assert.are.equal(42, converted)
  end)

  it('constructs CLI arguments with parameters', function()
    local params = { topic = 'Test', complexity = 3 }
    local params_str = execution._serialize_params(params)
    assert.are.equal('topic=Test,complexity=3', params_str)
  end)

  it('handles cancellation gracefully', function()
    local params = {
      { key = 'topic', requirement = 'required', input_type = 'string' }
    }

    -- Mock vim.fn.input to simulate Ctrl-C (returns empty string)
    _G.vim.fn.input = function() return '' end

    local result = execution.prompt_for_parameters(params)
    assert.is_nil(result)
  end)
end)
```

**Testing**:
```bash
# Run automated test suite
cd /home/benjamin/.config/nvim
nvim --headless -c "PlenaryBustedDirectory lua/neotex/plugins/ai/goose/picker/tests" -c "qa"

# Verify all tests pass
if [ $? -eq 0 ]; then
  echo "All parameter collection tests passed"
else
  echo "Test failures detected"
  exit 1
fi
```

**Expected Duration**: 1-2 hours

## Testing Strategy

### Unit Testing
- Test parameter collection function in isolation with mocked input
- Test parameter validation for all input types (string, number, boolean, file, select)
- Test CLI argument serialization with various parameter combinations
- Test cancellation handling and error messages

### Integration Testing
- Test full execution flow: picker selection → parameter prompts → sidebar opening → CLI execution
- Test all affected recipes (research, create-plan, implement, revise) via picker
- Test parameter validation with invalid inputs (wrong types, empty values)
- Test cancellation at different prompt stages

### Manual Testing
- Trigger picker with `<leader>aR` and verify parameter prompts appear before sidebar
- Test parameter collection with valid inputs and verify recipes execute correctly
- Test cancellation during parameter prompts and verify clean abort
- Test validation errors with invalid inputs and verify clear error messages

### Validation Commands
```bash
# Recipe validation
for recipe in .goose/recipes/*.yaml; do
  goose run --recipe "$recipe" --explain || exit 1
done

# Unit tests
nvim --headless -c "PlenaryBustedDirectory lua/neotex/plugins/ai/goose/picker/tests" -c "qa"

# Integration test (manual)
nvim -c "lua require('neotex.plugins.ai.goose.picker').select_recipe()"
```

## Documentation Requirements

### Update Picker README
- Document parameter collection behavior for CLI execution
- Explain `user_prompt` vs `required` distinction in CLI context
- Add troubleshooting section for parameter validation errors

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md`

**Sections to Add**:
```markdown
## Parameter Collection

The Nvim picker collects recipe parameters via `vim.fn.input()` prompts before CLI execution:
- **required**: Must be provided; execution fails if missing
- **optional**: Uses default value if not provided
- **user_prompt**: Always prompts user for input (same behavior as `required` in CLI context)

**Important**: The Goose CLI does not interactively prompt for `user_prompt` parameters. The Nvim picker bridges this gap by collecting parameters before CLI invocation.

## Troubleshooting

### Parameter Prompts Not Appearing
- Verify recipe YAML syntax: `goose run --recipe <path> --explain`
- Check parameter definitions have `requirement: user_prompt` or `requirement: required`

### Invalid Parameter Type Error
- Verify input matches `input_type` in recipe definition
- Use `goose run --recipe <path> --explain` to see expected parameter types
```

### Update Execution Module Comments
- Add inline documentation for `prompt_for_parameters()` function
- Document parameter validation and serialization logic
- Add examples of CLI argument construction with parameters

## Dependencies

### External Dependencies
- Goose CLI installed and available in PATH
- plenary.nvim plugin for job control
- Nvim 0.10+ for `vim.fn.input()` support

### Internal Dependencies
- metadata.lua: Recipe YAML parsing
- sidebar.lua: Sidebar opening after parameter collection
- execution.lua: Parameter collection, validation, CLI invocation

### Recipe Files
- .goose/recipes/research.yaml (requires fix: line 10)
- .goose/recipes/create-plan.yaml (requires fix: missing title field)
- All recipes using `user_prompt` parameters must be tested

## Risk Analysis

### Low Risk
- Recipe YAML syntax fixes (straightforward corrections)
- User feedback enhancements (additive changes)

### Medium Risk
- Execution flow refactor (changes parameter collection timing)
  - **Mitigation**: Test all affected recipes before/after change
  - **Rollback**: Git revert execution.lua if issues arise

### High Risk
- None identified (parameter collection infrastructure already exists)

## Rollback Plan

If parameter collection changes cause issues:

1. **Immediate Rollback**: `git checkout HEAD~1 nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`
2. **Verify Rollback**: Test picker with `<leader>aR` to confirm previous behavior restored
3. **Document Issues**: Create new debug report with failure details
4. **Alternative Approach**: Consider parameter collection in sidebar after opening (async pattern)

## Success Metrics

- All 5 recipes with `user_prompt` parameters execute successfully via picker
- Parameter prompts complete in <10 seconds for typical inputs
- Zero recipe validation errors after YAML fixes
- Automated test suite passes with 100% success rate
- User feedback shows clear progress during parameter collection
