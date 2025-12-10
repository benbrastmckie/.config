# Goose Sidebar Recipe Command Error - Debug Strategy Plan

## Metadata
- **Date**: 2025-12-09
- **Feature**: Fix Goose sidebar recipe execution to use proper CLI --recipe flag instead of invalid /recipe: text syntax
- **Status**: [NOT STARTED]
- **Estimated Hours**: 3-5 hours
- **Complexity Score**: 32.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Root Cause Analysis](../reports/001-goose-sidebar-gemini-recipe-cmd-error-analysis.md)

## Overview

The Goose sidebar recipe picker executes recipes using invalid `/recipe:<name>` syntax sent as text to the Goose CLI (`goose run --text "/recipe:create-plan"`), which causes Gemini (and other providers) to receive the recipe command as literal user text instead of executing the recipe file. Recipe execution requires the `--recipe` CLI flag with a file path (`goose run --recipe <path>`), not in-session slash command syntax.

This debug plan addresses the architectural mismatch between the picker's execution model and the Goose CLI's actual recipe invocation API.

## Research Summary

Key findings from root cause analysis:
- The picker uses `/recipe:<name>` syntax that is NOT a valid Goose CLI command for recipe execution
- `goose run --text "/recipe:create-plan"` sends the slash command as literal user text to the LLM
- Gemini (via gemini-cli provider) receives `/recipe:create-plan` as conversational text, causing "I'm not familiar with..." response
- Recipe execution requires `goose run --recipe /path/to/recipe.yaml` CLI syntax
- The `/recipe` slash command exists ONLY for saving conversations to recipe files, not executing existing recipes
- goose.nvim's `job.lua:build_args()` only supports `--text` parameter, not `--recipe` flag

Recommended fix approach: Modify `execution.lua` to use proper `--recipe` flag, either by enhancing `job.lua` or by creating local execution bypass.

## Success Criteria
- [ ] Recipe picker executes recipes using `goose run --recipe <path>` instead of `goose run --text "/recipe:<name>"`
- [ ] Recipes execute successfully with Gemini provider in Neovim sidebar
- [ ] Recipe parameters are handled correctly (either pre-prompted in Neovim or allowed to prompt via CLI)
- [ ] All documentation updated to reflect correct recipe execution model
- [ ] No regressions in existing sidebar functionality (manual text prompts, file context, etc.)

## Technical Design

### Root Cause
The picker's `execution.lua:run_recipe_in_sidebar()` function builds recipe invocations as:
```lua
local prompt = string.format('/recipe:%s', recipe_name)
goose.core.run(prompt, {...})  -- Translates to: goose run --text "/recipe:create-plan"
```

This sends `/recipe:<name>` as user text to the LLM, which has no knowledge of recipe syntax.

### Solution Architecture
**Option A: Modify job.lua in goose.nvim Fork (Recommended)**
- Fork goose.nvim and enhance `job.lua:build_args()` to support `--recipe` parameter
- Modify `execution.lua` to pass recipe path via new parameter
- Benefits: Clean integration with existing sidebar workflow, maintains goose.nvim architecture
- Drawback: Requires maintaining a fork

**Option B: Local Execution Bypass in execution.lua**
- Create direct CLI command execution in `execution.lua` without using goose.nvim's job builder
- Execute `goose run --recipe <path>` directly via vim.fn.jobstart() or plenary.job
- Capture output and send to sidebar
- Benefits: No fork required, isolated change in local config
- Drawback: Bypasses goose.nvim's context formatting and session management

**Selected Approach**: Start with Option B for immediate fix, then evaluate Option A for upstreaming to goose.nvim.

### Implementation Strategy
1. **Phase 1**: Modify `execution.lua` to detect recipe execution and build proper CLI command
2. **Phase 2**: Implement direct job execution with output capture and sidebar integration
3. **Phase 3**: Test with Gemini provider using multiple recipes (create-plan, research, implement)
4. **Phase 4**: Update documentation to remove invalid `/recipe:` syntax references

## Implementation Phases

### Phase 1: Modify Recipe Execution Command Builder [NOT STARTED]
dependencies: []

**Objective**: Change `execution.lua:run_recipe_in_sidebar()` to build `goose run --recipe <path>` command instead of `/recipe:<name>` text.

**Complexity**: Medium

**Tasks**:
- [ ] Backup current execution.lua: `cp ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua.backup.$(date +%Y%m%d_%H%M%S)`
- [ ] Read current `execution.lua` to understand `run_recipe_in_sidebar()` function (lines 33-87)
- [ ] Modify recipe invocation logic to construct CLI command array: `{"goose", "run", "--recipe", recipe_path}`
- [ ] Remove `/recipe:<name>` string formatting (lines 60-62)
- [ ] Add recipe path resolution from picker metadata (use `metadata.recipe_path` or construct from recipe name)
- [ ] Verify recipe file exists before execution with error handling

**Testing**:
```bash
# Verify execution.lua modified correctly
grep -n "goose run --recipe" ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua

# Verify /recipe: syntax removed
! grep -n "/recipe:" ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua

# Check syntax validity
nvim --headless -c "luafile ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua" -c "quit" 2>&1
```

**Expected Duration**: 1 hour

---

### Phase 2: Implement Direct CLI Execution with Sidebar Integration [NOT STARTED]
dependencies: [1]

**Objective**: Execute the `goose run --recipe` command directly using Neovim job API and integrate output into sidebar window.

**Complexity**: High

**Tasks**:
- [ ] Create job execution function using `vim.fn.jobstart()` or plenary.job API
- [ ] Build command array with recipe path: `{"goose", "run", "--recipe", recipe_path}`
- [ ] Add provider configuration flag: `--provider gemini-cli` (read from goose config)
- [ ] Capture stdout/stderr output from job execution
- [ ] Implement output streaming to sidebar buffer (append lines as they arrive)
- [ ] Add error handling for job failures (exit code ≠ 0, stderr output)
- [ ] Preserve sidebar window state and scrolling behavior
- [ ] Add recipe execution status indicator in sidebar (loading, complete, error)

**Testing**:
```bash
# Automated validation script
cat > /tmp/test_recipe_execution.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Test 1: Verify CLI command construction
nvim --headless -c "lua require('neotex.plugins.ai.goose.picker.execution')" -c "quit" 2>&1
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo "FAIL: execution.lua syntax error"
  exit 1
fi
echo "PASS: execution.lua loads without errors"

# Test 2: Verify goose CLI is accessible
which goose > /dev/null || { echo "FAIL: goose CLI not found in PATH"; exit 1; }
echo "PASS: goose CLI found"

# Test 3: Test recipe file exists
RECIPE_PATH="$HOME/.config/.goose/recipes/create-plan.yaml"
if [ ! -f "$RECIPE_PATH" ]; then
  echo "FAIL: Recipe file not found: $RECIPE_PATH"
  exit 1
fi
echo "PASS: Recipe file exists"

echo "✓ All validation checks passed"
EOF

chmod +x /tmp/test_recipe_execution.sh
bash /tmp/test_recipe_execution.sh
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test_recipe_execution.sh"]

**Expected Duration**: 2-3 hours

---

### Phase 3: End-to-End Recipe Execution Testing [NOT STARTED]
dependencies: [2]

**Objective**: Test recipe execution with Gemini provider in Neovim sidebar using multiple recipes to verify functionality and parameter handling.

**Complexity**: Medium

**Tasks**:
- [ ] Launch Neovim with goose.nvim plugin loaded
- [ ] Open recipe picker with `:Telescope goose_recipes` or custom keymap
- [ ] Execute `create-plan` recipe from picker
- [ ] Verify Gemini receives recipe instructions (not "/recipe:create-plan" text)
- [ ] Confirm recipe prompt appears correctly in sidebar
- [ ] Test recipe parameter prompting (if recipe has parameters)
- [ ] Execute `research` recipe to test different recipe structure
- [ ] Execute `implement` recipe to test complex multi-step workflow
- [ ] Test error handling: execute non-existent recipe, verify error message in sidebar
- [ ] Verify sidebar output formatting matches expected recipe output

**Testing**:
```bash
# Manual verification checklist (saved to file for reference)
cat > /tmp/recipe_testing_checklist.md << 'EOF'
# Recipe Execution Testing Checklist

## Test Case 1: create-plan Recipe
- [ ] Open recipe picker
- [ ] Select create-plan recipe
- [ ] Verify sidebar shows "Loading recipe..." indicator
- [ ] Confirm recipe execution begins (not "/recipe:create-plan" error)
- [ ] Check if recipe parameters prompt correctly
- [ ] Verify output appears in sidebar incrementally
- [ ] Confirm final output matches expected format

## Test Case 2: research Recipe
- [ ] Execute research recipe from picker
- [ ] Verify different recipe structure executes correctly
- [ ] Check research-specific prompts work

## Test Case 3: Error Handling
- [ ] Execute non-existent recipe
- [ ] Verify error message displayed in sidebar
- [ ] Confirm sidebar doesn't crash or freeze

## Test Case 4: Provider Compatibility
- [ ] Verify execution works with gemini-cli provider
- [ ] Optional: Test with claude-code provider if available
EOF

echo "Created testing checklist: /tmp/recipe_testing_checklist.md"

# Automated test: Verify recipe execution doesn't produce "/recipe:" error
cat > /tmp/test_no_slash_recipe_error.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# This test requires Neovim to be running with goose.nvim loaded
# We'll create a verification script that can be sourced during manual testing

echo "Verification: Check goose CLI can execute recipe with --recipe flag"

RECIPE_PATH="$HOME/.config/.goose/recipes/create-plan.yaml"
if goose run --recipe "$RECIPE_PATH" --text "test plan" 2>&1 | grep -i "not familiar"; then
  echo "FAIL: Recipe still producing error"
  exit 1
fi

echo "PASS: Recipe executes without slash command error"
EOF

chmod +x /tmp/test_no_slash_recipe_error.sh
echo "Created verification script: /tmp/test_no_slash_recipe_error.sh"
echo "Note: Run this script after implementing CLI integration"
```

**Automation Metadata**:
- automation_type: semi-automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["recipe_testing_checklist.md", "test_no_slash_recipe_error.sh"]

**Expected Duration**: 1 hour

---

### Phase 4: Documentation Updates [NOT STARTED]
dependencies: [3]

**Objective**: Update all documentation to remove references to invalid `/recipe:<name>` syntax and document correct recipe execution model.

**Complexity**: Low

**Tasks**:
- [ ] Update `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md` to remove `/recipe:` syntax references
- [ ] Update `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` to document `--recipe` flag usage
- [ ] Update `execution.lua` comments (lines 60-62) to reflect correct implementation
- [ ] Add note clarifying `/recipe` is ONLY for saving conversations, not executing recipes
- [ ] Document recipe execution flow: picker → CLI command → sidebar output
- [ ] Add troubleshooting section for recipe execution errors
- [ ] Update recipe picker documentation with correct execution model

**Testing**:
```bash
# Verify documentation updated correctly
grep -n "\-\-recipe" ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md || \
  { echo "FAIL: README doesn't mention --recipe flag"; exit 1; }

# Verify /recipe: syntax removed from docs
if grep -n "/recipe:" ~/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md | grep -v "not for executing"; then
  echo "FAIL: README still references /recipe: execution syntax"
  exit 1
fi

echo "PASS: Documentation updated correctly"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: []

**Expected Duration**: 0.5 hours

---

## Testing Strategy

### Unit Testing Approach
- Test recipe path resolution logic independently
- Verify CLI command builder produces correct argument array
- Test job execution error handling (non-existent recipe, invalid YAML)

### Integration Testing Approach
- End-to-end recipe execution with Gemini provider
- Sidebar output streaming verification
- Parameter prompting flow testing

### Validation Contracts
All test phases include automation metadata with:
- `automation_type: automated` - No manual intervention required
- `validation_method: programmatic` - Exit code and output validation
- `skip_allowed: false` - All tests are mandatory
- `artifact_outputs` - Test scripts and checklists for reproducibility

### Success Validation
Recipe execution will be considered successful when:
1. Picker executes `goose run --recipe <path>` instead of `goose run --text "/recipe:<name>"`
2. Gemini receives recipe instructions and executes them correctly
3. Sidebar displays recipe output without errors
4. No regressions in existing sidebar functionality

## Documentation Requirements

### Files to Update
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/README.md` - Recipe execution model
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/README.md` - CLI integration documentation
- `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` - Code comments

### Documentation Standards
- Follow Neovim configuration documentation standards from `/home/benjamin/.config/nvim/CLAUDE.md`
- Use clear code examples with syntax highlighting
- Document error cases and troubleshooting steps
- Cross-reference Goose CLI documentation for recipe syntax

## Dependencies

### External Dependencies
- goose CLI (installed and accessible in PATH)
- gemini-cli provider configured in goose config
- Recipe files in `~/.config/.goose/recipes/` directory

### Internal Dependencies
- goose.nvim plugin (azorng/goose.nvim)
- Telescope.nvim (for picker UI)
- plenary.nvim (for job execution utilities)

### Prerequisite Validation
```bash
# Verify goose CLI is installed
which goose || { echo "ERROR: goose CLI not found"; exit 1; }

# Verify recipe directory exists
ls ~/.config/.goose/recipes/*.yaml || { echo "ERROR: No recipes found"; exit 1; }

# Verify goose.nvim plugin loaded
nvim --headless -c "lua require('goose')" -c "quit" 2>&1
```

## Risk Assessment

### High Risks
- **Sidebar integration complexity**: Direct job execution may break existing sidebar context management
  - Mitigation: Start with isolated testing, preserve existing goose.core.run() for non-recipe prompts

### Medium Risks
- **Recipe parameter prompting**: CLI's native parameter prompts may not work in sidebar context
  - Mitigation: Pre-prompt parameters in Neovim before CLI execution, or allow CLI prompts to appear in sidebar

### Low Risks
- **Documentation drift**: Updated docs may conflict with upstream goose.nvim documentation
  - Mitigation: Clearly mark local modifications, consider contributing fix upstream

## Notes

This is a debug-only workflow focused on fixing the recipe execution error. The plan prioritizes immediate fix (local execution bypass) while documenting path to upstream contribution (forking goose.nvim to enhance job.lua).

The root cause is well-understood from research analysis, so phases focus on implementation and verification rather than additional investigation.
