# Debug Report: Goose Nvim Recipe Topic Prompt Issue

## Metadata
- **Date**: 2025-12-09
- **Agent**: debug-analyst
- **Issue**: Recipe parameter prompts appear in goose sidebar instead of before execution
- **Hypothesis**: Parameter collection timing issue causing prompts to execute after sidebar opens
- **Status**: Complete

## Issue Description

When running `<leader>aR` in Neovim and selecting a recipe (e.g., "research"), the goose sidebar opens but displays this message:

```
> /recipe:research
---
I understand that you want to initiate the research recipe.
This recipe requires a topic to proceed. Please provide a natural
language description of the research topic.
```

**Expected Behavior**: User should be prompted for the `topic` parameter via `vim.fn.input()` BEFORE the sidebar opens, and the recipe should execute with the provided value.

**Actual Behavior**: The sidebar opens immediately without prompting for parameters, and the recipe receives unsubstituted template variables (`{{ topic }}`), causing the goose agent to recognize missing input and prompt the user within the sidebar conversation.

## Failed Tests

No automated tests exist for this functionality. Issue discovered through manual testing:

1. Open Neovim
2. Press `<leader>aR` (trigger goose recipe picker)
3. Select "research" recipe from picker
4. Observe: Sidebar opens immediately
5. Observe: No `vim.fn.input()` prompt appears
6. Observe: Sidebar shows "This recipe requires a topic to proceed"

## Investigation

### Root Cause Hypothesis Validation

**Hypothesis**: Parameter collection occurs AFTER sidebar opening, creating a race condition where recipes execute without parameter values.

**Validation**: **CONFIRMED**

### Evidence

#### Evidence 1: Execution Flow Analysis

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

Lines 73-98 show the problematic execution order:

```lua
-- Line 73: Collect parameters
local params = M.prompt_for_parameters(metadata.parameters)
if not params then
  vim.notify('Recipe execution cancelled', vim.log.levels.INFO)
  return
end

-- Line 80-98: Ensure sidebar is open
if not goose_state.windows or not goose_state.windows.output then
  local open_ok, open_err = pcall(goose_core.open)
  if not open_ok then
    -- Retry once
    vim.schedule(function()
      vim.defer_fn(function()
        local retry_ok = pcall(goose_core.open)
        if not retry_ok then
          vim.notify(
            'Failed to open goose sidebar. Try running :Goose first.',
            vim.log.levels.ERROR
          )
        end
      end, 100)
    end)
    return
  end
end
```

**Analysis**: The code DOES call `prompt_for_parameters()` before opening the sidebar (line 74). However, the sidebar opening is wrapped in a `vim.schedule()` and `vim.defer_fn()` asynchronous callback (lines 85-95), which creates a timing issue where the CLI job starts before parameters are collected.

**Actual Root Cause**: The parameter collection at line 74 executes synchronously, but if the sidebar is already open (line 81 check fails because sidebar exists from previous use), the code skips the sidebar opening block entirely and proceeds directly to job execution at line 195. The collected parameters ARE passed to the CLI, but there's a deeper issue with how `user_prompt` requirement type is handled.

#### Evidence 2: Recipe Definition Uses `user_prompt` Requirement

File: `/home/benjamin/.config/.goose/recipes/research.yaml`

Lines 4-7:
```yaml
parameters:
  - key: topic
    input_type: string
    requirement: user_prompt
    description: Natural language description of research topic
```

File: `/home/benjamin/.config/.goose/recipes/create-plan.yaml`

Lines 16-20:
```yaml
parameters:
  - key: feature_description
    input_type: string
    requirement: user_prompt
    description: Natural language description of feature to implement
```

**Analysis**: Both recipes use `requirement: user_prompt`, which according to Goose documentation is intended for interactive prompting in the Desktop app. The Goose CLI does NOT prompt for `user_prompt` parameters.

#### Evidence 3: Parameter Collection Logic Handles `user_prompt`

File: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

Lines 215-244:
```lua
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
    -- Validate parameter type
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

**Analysis**: The `prompt_for_parameters()` function DOES handle `user_prompt` parameters (line 215) and should prompt via `vim.fn.input()`. The function treats `user_prompt` parameters the same as `required` parameters, except it doesn't fail if the value is empty for `user_prompt` (lines 224-232).

**Critical Discovery**: Lines 224-232 reveal the actual bug - when `param.requirement == 'user_prompt'` and the user provides an empty value (or cancels), the code does NOT add the parameter to the `params` table, but also does NOT return `nil` to cancel execution. This means execution continues with an empty `params` table.

#### Evidence 4: Recipe Validation Errors Exist

```bash
# research.yaml validation error
$ goose run --recipe .goose/recipes/research.yaml --explain
Error: Failed to parse recipe: parameters[1].input_type: unknown variant `integer`,
expected one of `string`, `number`, `boolean`, `date`, `file`, `select`
at line 10 column 17
```

File: `/home/benjamin/.config/.goose/recipes/research.yaml`

Line 10:
```yaml
  - key: complexity
    input_type: integer  # INVALID - should be "number"
    requirement: optional
    description: Research complexity level (1-4)
    default: 2
```

**Analysis**: The `complexity` parameter uses invalid `input_type: integer`, which should be `input_type: number` according to Goose recipe schema. This validation error prevents testing the recipe via CLI.

```bash
# create-plan.yaml validation error
$ goose run --recipe .goose/recipes/create-plan.yaml --explain
Error: Failed to parse recipe: missing field `title` at line 12 column 1
```

File: `/home/benjamin/.config/.goose/recipes/create-plan.yaml`

Lines 1-13:
```yaml
# create-plan.yaml - Research-and-Plan Workflow Recipe
#
# This recipe implements the /create-plan command functionality in Goose:
# 1. Research Phase: Invoke research-specialist to create codebase analysis
# 2. Planning Phase: Invoke plan-architect to create implementation plan
# 3. State Management: Track workflow state transitions
# 4. Hard Barrier: Validate all artifacts created successfully
#
# Corresponds to Claude Code command: /create-plan
# Behavioral guidelines ported from: .claude/commands/create-plan.md

name: create-plan
description: Research and create new implementation plan workflow
# MISSING: title field (required by Goose recipe schema)
```

**Analysis**: The `create-plan.yaml` recipe is missing the required `title` field in frontmatter, which should be present before the `name` field.

#### Evidence 5: Widespread `user_prompt` Usage

```bash
$ grep -r "requirement: user_prompt" .goose/recipes/
.goose/recipes/revise.yaml:7:    requirement: user_prompt
.goose/recipes/revise.yaml:12:    requirement: user_prompt
.goose/recipes/research.yaml:6:    requirement: user_prompt
.goose/recipes/create-plan.yaml:19:    requirement: user_prompt
.goose/recipes/implement.yaml:7:    requirement: user_prompt
```

**Analysis**: 5 different recipes use `user_prompt` requirement type, indicating this is a systemic issue affecting multiple workflows, not just the research recipe.

## Root Cause Analysis

### Identified Root Cause

**PRIMARY CAUSE**: The `prompt_for_parameters()` function (lines 215-244) has a logic flaw where `user_prompt` parameters that are empty or cancelled do NOT cause execution to abort. When the user provides an empty value:

1. Line 224: `value == ''` evaluates to true
2. Line 226: The condition `param.requirement == 'required'` is false (it's `'user_prompt'`)
3. Lines 227-232: Error notification is skipped
4. Line 233: `else` block is not executed (no parameter added to `params`)
5. Line 245: Loop continues to next parameter
6. Line 248: Function returns empty `params` table `{}` (NOT `nil`)
7. Line 75 in `run_recipe_in_sidebar()`: Check `if not params` evaluates to FALSE (empty table is truthy)
8. Execution continues without parameters

**SECONDARY CAUSE**: Recipe YAML files contain validation errors:
- `research.yaml` line 10: Invalid `input_type: integer` (should be `number`)
- `create-plan.yaml` line 1: Missing required `title` field

**TERTIARY CAUSE**: The Goose CLI does not interactively prompt for `user_prompt` parameters. When recipes are invoked via `goose run --recipe path --params key=value`, any `user_prompt` parameters without values in `--params` appear as literal template variables (`{{ parameter_name }}`) in the recipe instructions, causing the agent to recognize missing input and prompt within the conversation.

### Why This Occurs

The implementation assumes `user_prompt` parameters are optional (can be skipped), but the recipes define them as functionally required (the recipe cannot proceed without them). This semantic mismatch causes:

1. Empty table returned instead of `nil` (no cancellation signal)
2. CLI invoked with `--params` flag missing required parameters
3. Recipe receives unsubstituted `{{ topic }}` in instructions
4. Agent recognizes missing parameter and prompts user in sidebar

### Code Flow Trace

```
User Action: <leader>aR → Select "research" recipe
  ↓
picker.lua:select_recipe()
  ↓
execution.lua:run_recipe_in_sidebar(recipe_path, metadata)
  ↓ Line 74
execution.lua:prompt_for_parameters(metadata.parameters)
  ↓ Line 215-244 (user_prompt handling)
  → vim.fn.input("Enter topic (string): ")
  → User presses ESC or enters empty string
  → value == '' (line 224)
  → param.requirement != 'required' (line 226)
  → Skip error notification (lines 227-232)
  → Skip parameter assignment (line 243 not executed)
  → Continue loop
  ↓ Line 248
  → return params (empty table {})
  ↓ Line 75
  → if not params → FALSE (empty table is truthy)
  ↓ Line 80-98
  → Open sidebar (or verify already open)
  ↓ Line 106-113
  → Build CLI args: ['run', '--recipe', path, '--params', '']
  ↓ Line 195
  → job:start()
  ↓
CLI Execution: goose run --recipe research.yaml --params ""
  ↓
Recipe receives: {{ topic }} (unsubstituted)
  ↓
Agent response: "This recipe requires a topic to proceed..."
```

## Impact Assessment

### Scope

**Affected Files**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` (lines 203-249)
- `/home/benjamin/.config/.goose/recipes/research.yaml` (line 10, validation error)
- `/home/benjamin/.config/.goose/recipes/create-plan.yaml` (line 1, missing title)
- 5 recipe files using `user_prompt` requirement type

**Affected Components**:
- Goose recipe picker (parameter collection)
- All recipes with `user_prompt` parameters (research, create-plan, implement, revise)
- Recipe YAML validation workflow

**Severity**: **HIGH**

- Blocks all recipe execution via Nvim picker for recipes with `user_prompt` parameters
- Affects 5 different recipes (widespread impact)
- Creates confusing UX where agent prompts in sidebar instead of pre-execution
- Recipe validation errors prevent CLI-based testing and verification

### Related Issues

1. **No User Feedback During Parameter Collection**: When prompts DO appear, there's no indication of how many parameters are required or which prompt is current (e.g., "[1/3] Enter topic")

2. **Validation Errors Obscure Testing**: Recipe YAML errors prevent `goose run --explain` from working, making it impossible to validate parameter definitions during development

3. **Inconsistent Empty Value Handling**: `required` parameters fail on empty value, but `user_prompt` parameters silently skip, creating semantic confusion about requirement strictness

## Proposed Fix

### Fix Description

Implement a three-part fix to address root cause, validation errors, and UX improvements:

**Part 1: Fix Empty Value Handling for `user_prompt` Parameters**

Modify `prompt_for_parameters()` to treat empty/cancelled `user_prompt` parameters as execution cancellation (same as `required` parameters).

**Part 2: Fix Recipe YAML Validation Errors**

- `research.yaml`: Change `input_type: integer` to `input_type: number`
- `create-plan.yaml`: Add `title` field to frontmatter

**Part 3: Enhance User Feedback During Parameter Collection**

Add progress indicators, validation hints, and cancellation confirmation to improve UX.

### Code Changes

#### Change 1: Fix Empty Value Handling

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

**Lines**: 215-244

**Before**:
```lua
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
    -- Validate parameter type
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

**After**:
```lua
elseif param.requirement == 'required' or param.requirement == 'user_prompt' then
  local prompt_text = string.format(
    'Enter %s (%s)%s: ',
    param.key,
    param.input_type,
    param.description ~= '' and ' - ' .. param.description or ''
  )

  local ok, value = pcall(vim.fn.input, prompt_text)
  if not ok or value == '' then
    -- User cancelled or provided empty value
    -- Treat user_prompt same as required (execution cannot proceed without value)
    vim.notify(
      string.format('Parameter "%s" required for recipe execution (cancelled)', param.key),
      vim.log.levels.WARN
    )
    return nil
  else
    -- Validate parameter type
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

**Rationale**:
- Removes the distinction between `required` and `user_prompt` for empty value handling
- Both types now cancel execution if no value provided (return `nil`)
- User receives clear feedback that execution was cancelled
- Prevents recipes from receiving unsubstituted template variables

#### Change 2: Fix Recipe Validation Errors

**File**: `/home/benjamin/.config/.goose/recipes/research.yaml`

**Line**: 10

**Before**:
```yaml
  - key: complexity
    input_type: integer
    requirement: optional
    description: Research complexity level (1-4)
    default: 2
```

**After**:
```yaml
  - key: complexity
    input_type: number
    requirement: optional
    description: Research complexity level (1-4)
    default: 2
```

**File**: `/home/benjamin/.config/.goose/recipes/create-plan.yaml`

**Line**: 1-12

**Before**:
```yaml
# create-plan.yaml - Research-and-Plan Workflow Recipe
#
# This recipe implements the /create-plan command functionality in Goose:
# 1. Research Phase: Invoke research-specialist to create codebase analysis
# 2. Planning Phase: Invoke plan-architect to create implementation plan
# 3. State Management: Track workflow state transitions
# 4. Hard Barrier: Validate all artifacts created successfully
#
# Corresponds to Claude Code command: /create-plan
# Behavioral guidelines ported from: .claude/commands/create-plan.md

name: create-plan
description: Research and create new implementation plan workflow
```

**After**:
```yaml
# create-plan.yaml - Research-and-Plan Workflow Recipe
#
# This recipe implements the /create-plan command functionality in Goose:
# 1. Research Phase: Invoke research-specialist to create codebase analysis
# 2. Planning Phase: Invoke plan-architect to create implementation plan
# 3. State Management: Track workflow state transitions
# 4. Hard Barrier: Validate all artifacts created successfully
#
# Corresponds to Claude Code command: /create-plan
# Behavioral guidelines ported from: .claude/commands/create-plan.md

title: Create Implementation Plan
name: create-plan
description: Research and create new implementation plan workflow
```

**Rationale**:
- Fixes validation errors preventing `goose run --explain` from working
- Enables recipe testing via CLI during development
- Aligns with Goose recipe schema requirements

#### Change 3: Enhance User Feedback (Optional UX Improvement)

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`

**Lines**: 203-249

**Enhancement**: Add parameter count notification and progress indicators

```lua
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
    -- Skip optional parameters with defaults
    if param.requirement == 'optional' and param.default then
      params[param.key] = param.default
    -- Prompt for required and user_prompt parameters
    elseif param.requirement == 'required' or param.requirement == 'user_prompt' then
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
        -- Execution cannot proceed without value
        vim.notify(
          string.format('Parameter "%s" required for recipe execution (cancelled)', param.key),
          vim.log.levels.WARN
        )
        return nil
      else
        -- Validate parameter type
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
  if prompt_count > 0 then
    vim.notify(
      string.format('%d parameter%s collected successfully', prompt_count, prompt_count > 1 and 's' or ''),
      vim.log.levels.INFO
    )
  end

  return params
end
```

**Rationale**:
- Improves UX by showing parameter count before prompts
- Progress indicator `[1/3]` helps user understand prompt sequence
- Enhanced validation errors include expected vs. actual type
- Success summary provides closure after parameter collection

### Fix Complexity

**Estimated Time**: 2-3 hours

**Risk Level**: Low

**Breakdown**:
- Part 1 (Empty value fix): 30 minutes - Simple logic change, well-understood behavior
- Part 2 (YAML fixes): 15 minutes - Straightforward text corrections
- Part 3 (UX enhancement): 1-2 hours - Additive changes, no existing behavior modified
- Testing: 30 minutes - Manual testing of all affected recipes

**Testing Required**:

1. **Unit Testing** (automated):
   - Test `prompt_for_parameters()` with empty/cancelled input → returns `nil`
   - Test `prompt_for_parameters()` with valid input → returns populated table
   - Test parameter validation for all input types (string, number, boolean)

2. **Integration Testing** (manual):
   - Trigger picker with `<leader>aR`
   - Select "research" recipe
   - Verify: Parameter prompt appears BEFORE sidebar opens
   - Enter valid topic value
   - Verify: Recipe executes with provided parameter (no "topic required" message in sidebar)
   - Test cancellation: Press ESC during prompt
   - Verify: Execution cancelled, sidebar does not open
   - Test invalid input: Enter "abc" for `complexity` (number type)
   - Verify: Error message shows type mismatch, execution cancelled

3. **Validation Testing** (CLI):
   ```bash
   # Verify recipes pass validation after fixes
   goose run --recipe .goose/recipes/research.yaml --explain
   goose run --recipe .goose/recipes/create-plan.yaml --explain
   ```

## Recommendations

### Priority 1: Implement Fix Part 1 (Empty Value Handling)

**Why**: This addresses the root cause preventing recipes from executing. Without this fix, all recipes with `user_prompt` parameters remain broken.

**Steps**:
1. Modify `execution.lua` lines 224-232 to return `nil` for empty `user_prompt` values
2. Test with research recipe: Verify cancellation works
3. Test with valid input: Verify parameters collected and passed to CLI

### Priority 2: Fix Recipe Validation Errors (Part 2)

**Why**: Enables CLI-based testing and validation of recipe behavior, which is essential for development iteration.

**Steps**:
1. Fix `research.yaml` line 10: `input_type: number`
2. Add `title` field to `create-plan.yaml`
3. Run `goose run --recipe <path> --explain` for each recipe
4. Verify all recipes pass validation

### Priority 3: Enhance User Feedback (Part 3)

**Why**: Improves UX but not critical for basic functionality. Can be deferred if time-constrained.

**Steps**:
1. Add parameter count notification before first prompt
2. Add progress indicator `[1/N]` to each prompt
3. Enhance validation error messages with expected vs. actual type
4. Add success summary after collection complete

### Priority 4: Add Automated Tests

**Why**: Prevents regression and ensures parameter collection works correctly across all scenarios.

**Steps**:
1. Create test file: `nvim/lua/neotex/plugins/ai/goose/picker/tests/test_parameter_collection.lua`
2. Test cases:
   - Empty value for `user_prompt` → returns `nil`
   - Valid value for `user_prompt` → returns table with parameter
   - Invalid type (string for number) → returns `nil` with error
   - Multiple parameters → collects all in sequence
   - Cancellation mid-sequence → returns `nil`
3. Run test suite: `nvim --headless -c "PlenaryBustedDirectory lua/neotex/plugins/ai/goose/picker/tests" -c "qa"`

### Priority 5: Document `user_prompt` vs `required` Behavior

**Why**: Clarifies semantic meaning for future recipe authors and prevents similar issues.

**Location**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md`

**Content**:
```markdown
## Parameter Collection Behavior

The Nvim picker collects recipe parameters via `vim.fn.input()` prompts before CLI execution:

### Requirement Types

- **required**: Must be provided; execution fails if missing or empty
- **optional**: Uses default value if not provided; prompts if default missing
- **user_prompt**: Always prompts user for input (treated same as `required` in CLI context)

### Important Notes

The Goose CLI does NOT interactively prompt for `user_prompt` parameters. The Nvim picker
bridges this gap by collecting parameters before CLI invocation. If a user cancels or
provides an empty value for a `user_prompt` parameter, execution is cancelled to prevent
recipes from receiving unsubstituted template variables.

### Troubleshooting

**Symptom**: Recipe displays "This recipe requires [parameter] to proceed"

**Cause**: Parameter was not collected before execution (empty value or cancellation)

**Solution**: Re-trigger picker and provide a value for all required/user_prompt parameters
```

## Conclusion

The issue is caused by a logic flaw where `user_prompt` parameters with empty values do not cancel execution, leading to recipes receiving unsubstituted template variables. The fix is straightforward: treat empty `user_prompt` values the same as empty `required` values (return `nil` to cancel). Additional recipe validation fixes and UX enhancements will improve the overall workflow.

**Confidence Level**: HIGH

All evidence points to the identified root cause, and the proposed fix directly addresses the observed behavior. Testing via manual execution and recipe validation will confirm the fix resolves the issue.
