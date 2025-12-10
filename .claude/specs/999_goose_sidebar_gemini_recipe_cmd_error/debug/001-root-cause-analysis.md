# Debug Analysis: Goose Sidebar Recipe Command Execution Failure

## Metadata
- **Date**: 2025-12-09
- **Agent**: debug-analyst
- **Issue**: Goose sidebar recipe commands not recognized by Gemini provider
- **Hypothesis**: Recipe picker uses invalid `/recipe:` slash command syntax sent as text instead of proper CLI `--recipe` flag
- **Status**: Complete

## Issue Description

When executing recipes through the goose.nvim sidebar recipe picker with the Gemini provider, the LLM responds with "I'm not familiar with the /recipe:create-plan command" instead of executing the recipe. This occurs consistently across all recipes (create-plan, research, implement) and prevents any recipe execution in the sidebar.

The user invokes a recipe through the Telescope picker UI, expecting the recipe to execute, but instead receives an error message indicating the LLM doesn't recognize the slash command syntax.

## Failed Operation

**User Action**: Select "create-plan" recipe from Telescope picker (`<leader>agr`)
**Expected Behavior**: Recipe executes with Gemini, prompting for parameters and generating plan
**Actual Behavior**: Gemini responds with "I'm not familiar with the /recipe:create-plan command. Could you please provide more information about what you'd like to do?"

**CLI Command Generated**: `goose run --text "/recipe:create-plan"`
**Correct CLI Command**: `goose run --recipe /home/benjamin/.config/.goose/recipes/create-plan.yaml`

## Investigation

### Code Execution Flow Analysis

The recipe execution flow follows this path:

1. **Telescope Picker Selection** → User selects recipe from picker UI
2. **execution.lua:run_recipe_in_sidebar()** → Builds `/recipe:<name>` text command (lines 60-71)
3. **goose.core.run()** → Delegates to job executor with prompt text
4. **job.lua:build_args()** → Constructs CLI arguments with `--text` flag (lines 11-28)
5. **CLI Execution** → Runs `goose run --text "/recipe:create-plan"`
6. **Gemini Provider** → Receives literal text "/recipe:create-plan" as user prompt
7. **LLM Response** → "I'm not familiar with..." error

### Root Cause Identified

The root cause is located in **execution.lua:60-71**:

```lua
-- File: /home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua
-- Lines: 60-71

-- Build /recipe:<name> command - Goose will prompt for parameters conversationally
local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
local prompt = string.format('/recipe:%s', recipe_name)

-- Notify user
vim.notify(
  string.format('Starting recipe: %s', recipe_name),
  vim.log.levels.INFO
)

-- Use goose.core.run() which handles sidebar opening and job management
goose_core.run(prompt)
```

**Why This Fails**:

1. **Invalid Syntax**: The code constructs `/recipe:create-plan` as a text string, treating it as if it were a slash command that Goose recognizes. However, `/recipe:` is NOT a valid Goose CLI command for recipe execution.

2. **Text Transmission**: The `goose_core.run(prompt)` call passes this string through job.lua's build_args():

```lua
-- File: /home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/job.lua
-- Lines: 11-14

function M.build_args(prompt)
  if not prompt then return nil end
  local message = context.format_message(prompt)
  local args = { "run", "--text", message }
```

This creates CLI arguments: `["run", "--text", "/recipe:create-plan"]`

3. **Literal User Text**: The `--text` flag sends the slash command as literal user text to the LLM. The Goose CLI forwards this verbatim to Gemini as a conversational prompt.

4. **No LLM Context**: The gemini-cli provider filters out Goose's extension information and slash command documentation from system prompts (as per CLI provider design). Gemini has no knowledge that `/recipe:` means anything special.

5. **Conversational Response**: Gemini interprets `/recipe:create-plan` as a user asking about a command they heard about, and responds conversationally that it's not familiar with that command.

### Evidence

**From goose.nvim job.lua**:
- Line 14: `local args = { "run", "--text", message }` - ALWAYS uses `--text` flag
- No support for `--recipe` flag in build_args() function
- All prompts are sent as user text, never as CLI commands

**From Goose CLI documentation**:
- `goose run --help` shows `--recipe <RECIPE_NAME or FULL_PATH_TO_RECIPE_FILE>` flag
- `/recipe [filepath]` slash command is ONLY for saving conversations to recipe files (not executing)
- Recipe execution requires CLI flag, not in-session slash commands

**From research analysis**:
- gemini-cli provider filters extension information from system prompts
- LLM receives only the text message with role prefixes (Human:/Assistant:)
- No slash command documentation is passed to Gemini API

## Root Cause Analysis

### Hypothesis Validation
**Hypothesis**: Recipe picker uses invalid `/recipe:` slash command syntax sent as text instead of proper CLI `--recipe` flag

**Status**: **CONFIRMED**

### Evidence Summary

1. **Architectural Mismatch**: The picker assumes `/recipe:<name>` is a valid command syntax when it's actually only valid as an in-session slash command for saving conversations (not executing recipes).

2. **Missing CLI Flag Support**: goose.nvim's job.lua only supports `--text` parameter in build_args(), with no pathway to use `--recipe` flag.

3. **Text-Based Transmission**: All recipe invocations go through `--text` flag, making them literal user prompts rather than recipe execution commands.

4. **Provider Filtering**: gemini-cli provider intentionally filters out extension documentation, ensuring the LLM never sees slash command definitions even if they were valid.

5. **Documentation Propagation**: Multiple documentation files (picker/README.md, goose/README.md, execution.lua comments) document `/recipe:<name>` syntax as correct, perpetuating the architectural error.

### Technical Root Cause

The code conflates two distinct Goose CLI mechanisms:

- **In-Session Slash Commands**: Commands like `/recipe [filepath]` used during interactive sessions (`goose session`) to perform session operations (save conversation as recipe)
- **CLI Recipe Execution**: The `--recipe` flag used with `goose run` to execute recipe files from the command line

The picker tries to use in-session slash command syntax (`/recipe:create-plan`) via the CLI execution mechanism (`goose run --text`), which sends it as user text to the LLM instead of executing a recipe.

## Impact Assessment

### Scope
**Affected Files**:
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` (lines 60-71) - PRIMARY
- `/home/benjamin/.local/share/nvim/lazy/goose.nvim/lua/goose/job.lua` (lines 11-28) - Secondary (missing --recipe support)
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md` - Documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` - Documentation

**Affected Components**:
- Recipe picker execution module (primary failure point)
- goose.nvim job builder (missing feature)
- Sidebar recipe execution workflow (complete failure)
- Recipe documentation and user guidance (incorrect model)

**Severity**: **HIGH**
- Complete failure of recipe execution in sidebar
- Affects all recipes across all CLI providers (Gemini, Claude Code, etc.)
- User-facing feature is entirely non-functional
- Incorrect architectural model documented and implemented

### Related Issues

1. **Parameter Prompting**: Even if recipe execution were fixed, recipe parameter prompting would need special handling in the Neovim sidebar context (CLI's native parameter prompts may not work properly).

2. **Documentation Drift**: The documented `/recipe:` syntax is used throughout picker and goose plugin READMEs, requiring comprehensive documentation updates.

3. **Upstream goose.nvim Limitation**: The plugin's job.lua doesn't support `--recipe` flag, limiting recipe execution capabilities without local modifications or forking.

## Proposed Fix

### Fix Description

Replace the invalid `/recipe:<name>` text command with proper CLI `--recipe` flag invocation. Since goose.nvim's job.lua doesn't support the `--recipe` flag, implement direct CLI execution in execution.lua that bypasses the job builder.

### Implementation Strategy

**Phase 1: Modify execution.lua Command Builder**
1. Remove `/recipe:<name>` string construction (lines 60-62)
2. Add recipe path resolution from metadata or construct from recipe name
3. Build CLI command array: `{"goose", "run", "--recipe", recipe_path}`
4. Add provider configuration: `--provider` flag from goose config

**Phase 2: Implement Direct Job Execution**
1. Replace `goose_core.run(prompt)` call with direct vim.fn.jobstart() or plenary.job
2. Capture stdout/stderr output streams
3. Stream output to sidebar buffer (append lines as they arrive)
4. Handle job exit codes and error conditions
5. Preserve sidebar window state and scrolling

**Phase 3: Update Documentation**
1. Remove all `/recipe:` execution syntax references
2. Document correct CLI `--recipe` flag model
3. Clarify `/recipe` is only for saving conversations
4. Add troubleshooting guidance for recipe execution

### Code Changes

**File**: `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua`
**Lines**: 60-71 (complete replacement)

**Current Code** (INCORRECT):
```lua
-- Build /recipe:<name> command - Goose will prompt for parameters conversationally
local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')
local prompt = string.format('/recipe:%s', recipe_name)

-- Notify user
vim.notify(
  string.format('Starting recipe: %s', recipe_name),
  vim.log.levels.INFO
)

-- Use goose.core.run() which handles sidebar opening and job management
goose_core.run(prompt)
```

**Proposed Code** (CORRECT):
```lua
-- Build CLI command with --recipe flag for proper recipe execution
local recipe_name = metadata.name or vim.fn.fnamemodify(recipe_path, ':t:r')

-- Verify recipe file exists
if vim.fn.filereadable(recipe_path) == 0 then
  vim.notify(
    string.format('Recipe file not found: %s', recipe_path),
    vim.log.levels.ERROR
  )
  return
end

-- Notify user
vim.notify(
  string.format('Executing recipe: %s', recipe_name),
  vim.log.levels.INFO
)

-- Build goose CLI command array
-- Note: We bypass goose.core.run() because job.lua doesn't support --recipe flag
local cmd = {'goose', 'run', '--recipe', recipe_path}

-- Add provider flag if configured (read from goose config or plugin settings)
local provider = config.get('provider') or 'gemini-cli'
table.insert(cmd, '--provider')
table.insert(cmd, provider)

-- Execute recipe via direct job invocation with sidebar output
local job_id = vim.fn.jobstart(cmd, {
  on_stdout = function(_, data, _)
    -- Append output to sidebar buffer
    local goose_api = require('goose.api')
    local buf = goose_api.get_goose_buffer()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
    end
  end,
  on_stderr = function(_, data, _)
    -- Handle errors in sidebar
    local goose_api = require('goose.api')
    local buf = goose_api.get_goose_buffer()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
    end
  end,
  on_exit = function(_, exit_code, _)
    if exit_code ~= 0 then
      vim.notify(
        string.format('Recipe failed with exit code: %d', exit_code),
        vim.log.levels.ERROR
      )
    else
      vim.notify(
        string.format('Recipe completed: %s', recipe_name),
        vim.log.levels.INFO
      )
    end
  end,
  stdout_buffered = false,
  stderr_buffered = false,
})

if job_id <= 0 then
  vim.notify('Failed to start recipe job', vim.log.levels.ERROR)
end
```

**Key Changes**:
1. Replaces `/recipe:<name>` text with `--recipe <path>` CLI flag
2. Adds recipe file existence validation
3. Builds proper CLI command array for jobstart()
4. Implements direct job execution with output streaming
5. Handles stdout/stderr output to sidebar buffer
6. Adds exit code handling and user notifications
7. Bypasses goose.nvim's job.lua limitation

### Fix Rationale

This fix addresses the root cause by:

1. **Correct CLI Invocation**: Uses `--recipe` flag as documented in Goose CLI help
2. **Proper Execution Model**: Executes recipe files instead of sending slash commands as text
3. **Provider Compatibility**: Works with all CLI providers (Gemini, Claude Code, etc.)
4. **Sidebar Integration**: Maintains sidebar output display via direct buffer manipulation
5. **Minimal Disruption**: Changes only execution.lua, no modifications to goose.nvim plugin
6. **Error Handling**: Validates recipe existence and handles job failures gracefully

**Why Not Use goose.core.run()**:
- goose.nvim's job.lua doesn't support `--recipe` flag (only `--text`)
- Would require forking and modifying upstream plugin
- Direct jobstart() achieves same result with local code only

**Why This Fix Works**:
- Sends `goose run --recipe <path>` to CLI, which executes the recipe file
- Recipe YAML defines the prompt/instructions sent to LLM
- LLM receives recipe content, not slash command syntax
- Gemini executes recipe instructions as intended

### Fix Complexity

- **Estimated Time**: 2-3 hours
- **Risk Level**: Low-Medium
  - Low risk of breaking existing functionality (only affects recipe execution path)
  - Medium risk in sidebar output handling (needs testing with streaming output)
- **Testing Required**:
  - Manual testing: Execute multiple recipes (create-plan, research, implement) from picker
  - Verify sidebar output appears correctly and streams incrementally
  - Test error handling (non-existent recipe, invalid YAML, job failures)
  - Confirm no regression in non-recipe sidebar functionality (manual prompts, file context)

## Recommendations

### Immediate Actions (Critical)

1. **Implement Fix in execution.lua**: Replace lines 60-71 with proposed code above to use `--recipe` CLI flag instead of `/recipe:` text syntax.

2. **Test Recipe Execution**: Verify recipes execute correctly with Gemini provider using the picker interface. Test multiple recipes to ensure consistency.

3. **Update Documentation**: Remove all references to `/recipe:<name>` syntax in picker/README.md and goose/README.md. Document correct `--recipe` flag model.

### Short-Term Actions (High Priority)

4. **Handle Recipe Parameters**: Determine strategy for recipe parameter prompting (pre-prompt in Neovim vs allow CLI prompts). Current fix allows CLI prompts, but may need enhancement for better UX.

5. **Add Parameter Input UI**: If CLI parameter prompts don't work well in sidebar, implement Neovim input prompts before recipe execution.

6. **Test Cross-Provider**: Verify recipe execution works with claude-code provider in addition to gemini-cli.

### Long-Term Actions (Consider)

7. **Contribute to goose.nvim**: Consider submitting PR to upstream goose.nvim to add `--recipe` flag support in job.lua, enabling cleaner integration.

8. **Enhance Recipe Picker**: Add recipe parameter preview in picker UI, showing what inputs the recipe requires before execution.

9. **Add Recipe Validation**: Validate recipe YAML syntax before execution to provide better error messages for malformed recipes.

## Validation Checklist

Before marking this issue as resolved, verify:

- [ ] Recipe picker uses `goose run --recipe <path>` instead of `goose run --text "/recipe:<name>"`
- [ ] Recipes execute successfully with Gemini provider (test create-plan, research, implement)
- [ ] Sidebar displays recipe output correctly with streaming updates
- [ ] Error handling works (non-existent recipe, job failures, invalid YAML)
- [ ] No regressions in existing sidebar functionality (manual prompts, file context)
- [ ] Documentation updated to remove `/recipe:` syntax references
- [ ] Recipe parameter prompting works (either CLI prompts or Neovim input)
- [ ] Cross-provider compatibility tested (Gemini and Claude Code if available)

## Conclusion

The issue is caused by a fundamental architectural misunderstanding in the recipe picker implementation. The code treats `/recipe:<name>` as a valid Goose command that can be sent as user text, when in reality:

1. Recipe execution requires the `--recipe` CLI flag with a file path
2. The `/recipe` slash command is only for saving conversations, not executing recipes
3. Sending `/recipe:<name>` as text makes it a literal user prompt to the LLM
4. The LLM has no context about slash command syntax and responds conversationally

The fix is straightforward but requires replacing the execution model in execution.lua to use proper CLI invocation with the `--recipe` flag. This bypasses goose.nvim's job builder limitation and executes recipes correctly via direct jobstart() calls.

**Confidence Level**: **HIGH** - Root cause is clearly identified, fix is well-understood, and validation path is clear.
