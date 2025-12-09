# Goose Nvim Recipe Topic Prompt Root Cause Analysis

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Root cause analysis for recipe parameter prompting issue
- **Report Type**: debug analysis

## Executive Summary

The Goose sidebar displays "I understand that you want to initiate the research recipe. This recipe requires a topic to proceed" because the Nvim picker invokes recipes via CLI (`goose run --recipe`) without providing values for `user_prompt` parameters, and Goose CLI does not interactively prompt for parameters. The recipe receives unsubstituted template variables (`{{ topic }}`), which the agent recognizes as missing required input. The fix requires implementing parameter collection in the Nvim picker before invoking recipes.

## Findings

### Finding 1: Nvim Picker Executes Recipes Without Parameter Collection

- **Description**: The execution module constructs CLI commands with `--params` only when parameters are already collected via `prompt_for_parameters()`, but this function is called synchronously after sidebar opening, creating a race condition
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua:74-78, 106-113
- **Evidence**:
```lua
-- Line 74: Collect parameters
local params = M.prompt_for_parameters(metadata.parameters)
if not params then
  vim.notify('Recipe execution cancelled', vim.log.levels.INFO)
  return
end

-- Line 106: Build recipe CLI arguments
local args = { 'run', '--recipe', recipe_path }

-- Add parameters if present (lines 109-113)
local params_str = M._serialize_params(params)
if params_str ~= '' then
  table.insert(args, '--params')
  table.insert(args, params_str)
end
```
- **Impact**: Parameters with `requirement: user_prompt` are not prompted for, so recipes execute with missing parameter values

### Finding 2: `user_prompt` Requirement Type Does Not Trigger CLI Prompts

- **Description**: Goose CLI does not interactively prompt for `user_prompt` parameters; unsubstituted template variables appear as literal text (`{{ parameter_name }}`) when values are not provided
- **Location**: Goose CLI behavior (https://block.github.io/goose/docs/guides/recipes/recipe-reference/)
- **Evidence**: From Recipe Reference Guide:
> "If a value isn't provided for a `user_prompt` parameter, the parameter won't be substituted and may appear as literal `{{ parameter_name }}` text in the recipe output."
- **Impact**: All recipes using `requirement: user_prompt` fail silently when invoked via Nvim picker, requiring Desktop app or manual parameter passing

### Finding 3: Research Recipe Defines Topic as `user_prompt` Parameter

- **Description**: The research.yaml recipe defines `topic` parameter with `requirement: user_prompt`, expecting interactive prompting that never occurs in CLI execution
- **Location**: /home/benjamin/.config/.goose/recipes/research.yaml:4-7
- **Evidence**:
```yaml
parameters:
  - key: topic
    input_type: string
    requirement: user_prompt
    description: Natural language description of research topic
```
- **Impact**: When picker invokes `goose run --recipe research.yaml` without `--params topic=...`, the recipe instructions contain literal `{{ topic }}`, causing agent confusion

### Finding 4: Parameter Prompting Function Exists But Skips `user_prompt` Requirements

- **Description**: The `prompt_for_parameters()` function in execution.lua handles `required` and `user_prompt` parameters identically (lines 215-244), but is never invoked before recipe execution in the current flow
- **Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua:203-249
- **Evidence**:
```lua
-- Line 215: Prompt for required and user_prompt parameters
elseif param.requirement == 'required' or param.requirement == 'user_prompt' then
  local prompt_text = string.format(
    'Enter %s (%s)%s: ',
    param.key,
    param.input_type,
    param.description ~= '' and ' - ' .. param.description or ''
  )

  local ok, value = pcall(vim.fn.input, prompt_text)
  if not ok or value == '' then
    -- User cancelled or provided empty value for required parameter
    if param.requirement == 'required' then
      vim.notify(
        string.format('Required parameter "%s" not provided', param.key),
        vim.log.levels.ERROR
      )
      return nil
    end
  else
    -- Validate parameter type (lines 235-243)
    local valid, converted = M.validate_param(value, param.input_type)
    if not valid then
      vim.notify(
        string.format('Invalid %s value for parameter "%s"', param.input_type, param.key),
        vim.log.levels.ERROR
      )
      return nil
    end
    params[param.key] = converted
  end
end
```
- **Impact**: Parameter collection infrastructure exists but requires integration into the execution flow to work correctly

### Finding 5: Multiple Recipes Use `user_prompt` Requirement Type

- **Description**: The pattern of using `requirement: user_prompt` is widespread across recipes, indicating systemic design mismatch between recipe definitions and CLI execution model
- **Location**: Multiple recipe files in /home/benjamin/.config/.goose/recipes/
- **Evidence**:
```bash
# Grep results showing user_prompt usage
.goose/recipes/revise.yaml:7:    requirement: user_prompt
.goose/recipes/revise.yaml:12:    requirement: user_prompt
.goose/recipes/research.yaml:6:    requirement: user_prompt
.goose/recipes/create-plan.yaml:19:    requirement: user_prompt
.goose/recipes/implement.yaml:7:    requirement: user_prompt
```
- **Impact**: All affected recipes will fail when invoked via Nvim picker without parameter collection implementation

### Finding 6: Recipe Validation Errors Exist in Current Recipe Files

- **Description**: Multiple recipes contain syntax errors that prevent `goose run --explain` from working, masking the parameter prompting issue during development
- **Location**: /home/benjamin/.config/.goose/recipes/research.yaml:10, /home/benjamin/.config/.goose/recipes/create-plan.yaml:1-12
- **Evidence**:
```bash
# research.yaml validation error
$ goose run --recipe .goose/recipes/research.yaml --explain
Error: Failed to parse recipe: parameters[1].input_type: unknown variant `integer`, expected one of `string`, `number`, `boolean`, `date`, `file`, `select` at line 10 column 17

# create-plan.yaml validation error
$ goose run --recipe .goose/recipes/create-plan.yaml --explain
Error: Failed to parse recipe: missing field `title` at line 12 column 1
```
- **Impact**: Recipe validation errors prevent testing of parameter prompting behavior via CLI, obscuring the root cause during development iterations

## Recommendations

### 1. Implement Pre-Execution Parameter Collection in Nvim Picker

**Priority**: CRITICAL

**Description**: Modify `run_recipe_in_sidebar()` to collect parameters via `prompt_for_parameters()` BEFORE constructing the plenary.job, ensuring all `user_prompt` parameters are collected and passed via `--params` flag.

**Implementation Steps**:
1. Move parameter collection to occur immediately after metadata parsing (before sidebar opening)
2. Show parameter prompts sequentially using `vim.fn.input()` for each `user_prompt` parameter
3. Validate parameter types using existing `validate_param()` function
4. Cancel execution if required parameters are missing or invalid
5. Pass collected parameters to `goose run --recipe --params key=value,key2=value2`

**Rationale**: This aligns Nvim picker behavior with Goose Desktop parameter dialog, enabling CLI-based recipe execution with proper parameter substitution.

### 2. Fix Recipe Validation Errors

**Priority**: HIGH

**Description**: Correct recipe YAML syntax errors to enable `goose run --explain` testing and parameter validation during development.

**Fixes Required**:
- **research.yaml:10**: Change `input_type: integer` to `input_type: number` (valid Goose type)
- **create-plan.yaml:1-12**: Add required `title:` field to recipe frontmatter

**Validation Command**: `goose run --recipe <path> --explain` should succeed for all recipes

### 3. Add User Feedback During Parameter Collection

**Priority**: MEDIUM

**Description**: Enhance parameter prompting UX with clear instructions, validation feedback, and cancellation handling to match Goose Desktop experience.

**Improvements**:
1. Display parameter count notification before first prompt: "Recipe requires 2 parameters"
2. Show parameter index during prompts: "[1/2] Enter topic (string): "
3. Provide validation hints in error messages: "Expected number, got 'abc'"
4. Support Ctrl-C cancellation with confirmation prompt: "Cancel recipe execution? (y/n)"
5. Show summary after collection: "2 parameters collected successfully"

### 4. Consider Parameter Pre-Filling from Context

**Priority**: LOW

**Description**: Extract parameter values from editor context (current file, selection, buffer content) to reduce manual input for common use cases.

**Context Sources**:
- **Current file path**: Pre-fill `file` type parameters with `vim.fn.expand('%:p')`
- **Visual selection**: Pre-fill `string` parameters with selected text
- **Git branch**: Pre-fill `topic` parameters with current branch name
- **Last command**: Pre-fill parameters from most recent picker invocation (session cache)

**Example**:
```lua
-- If user has text selected, offer as default for "topic" parameter
local visual_selection = vim.fn.getregion(...)
if visual_selection and param.key == 'topic' then
  prompt_text = prompt_text .. ' [' .. visual_selection .. ']: '
end
```

### 5. Document `user_prompt` vs `required` Distinction

**Priority**: LOW

**Description**: Add documentation explaining that `user_prompt` is intended for Desktop app usage, while CLI-based tools should use `required` for mandatory parameters that must be provided via `--params`.

**Documentation Location**: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md

**Content to Add**:
```markdown
## Parameter Requirement Types

### CLI Execution Considerations

When recipes are invoked via Nvim picker, parameters are collected through `vim.fn.input()` prompts:
- `required`: Must be provided; execution fails if missing
- `optional`: Uses default value if not provided; prompts if default missing
- `user_prompt`: Always prompts user for input (same behavior as `required` in CLI context)

**Important**: The Goose CLI does not interactively prompt for `user_prompt` parameters. The Nvim picker bridges this gap by collecting parameters before CLI invocation.
```

## References

- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua (lines 35-196, parameter collection and CLI invocation)
- /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/metadata.lua (lines 74-126, YAML parameter parsing)
- /home/benjamin/.config/.goose/recipes/research.yaml (lines 4-12, user_prompt parameter definition)
- /home/benjamin/.config/.goose/recipes/create-plan.yaml (lines 16-31, recipe parameter structure)
- [Goose Recipe Reference Guide](https://block.github.io/goose/docs/guides/recipes/recipe-reference/) - user_prompt behavior documentation
- [Goose CLI Commands](https://block.github.io/goose/docs/guides/goose-cli-commands/) - `goose run --params` syntax
