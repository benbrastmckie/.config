# goose.nvim Recipe Execution Integration Plan

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Integrate recipe picker with goose.nvim sidebar for unified output display
- **Scope**: Refactor recipe execution from ToggleTerm to goose.nvim sidebar UI with real-time streaming output, eliminating terminal buffer output and leveraging existing session management
- **Status**: [COMPLETE]
- **Estimated Hours**: 6-9 hours
- **Estimated Phases**: 5
- **Complexity Score**: 42.5
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [goose.nvim Plugin Architecture and APIs](../reports/001-goose-nvim-architecture.md)
  - [Neovim Sidebar Recipe Execution Methods](../reports/002-sidebar-recipe-execution.md)
  - [Recipe Output Handling and File Redirection](../reports/003-recipe-output-redirection.md)
  - [Clean-Break Refactoring Analysis](../reports/4-clean-break-refactor-analysis.md)

## Overview

The current recipe picker (`<leader>aR`) executes goose recipes via ToggleTerm, which outputs to an external terminal buffer instead of the goose.nvim sidebar UI. This creates a disjointed user experience where recipe execution is separated from the main goose chat interface. This plan implements sidebar integration using a hybrid approach that leverages plenary.job directly without modifying goose.nvim core, enabling real-time streaming output, markdown rendering, and session management integration.

**Goals**:
1. Execute recipes in goose sidebar with real-time output streaming
2. Eliminate ToggleTerm dependency for recipe execution
3. Integrate recipe sessions with goose session management
4. Improve UX with markdown rendering and auto-scrolling

## Research Summary

Analysis of goose.nvim architecture and recipe execution patterns reveals:

**From goose.nvim Architecture Report**:
- Plugin uses plenary.job for process management with on_stdout callbacks
- Sidebar provides real-time streaming output via ui.render_output()
- goose.api.run() and goose.core.run() are available integration points
- Current picker bypasses sidebar infrastructure entirely

**From Sidebar Execution Methods Report**:
- Three integration strategies identified (text-based, native args, hybrid)
- Hybrid approach (Strategy 3) recommended: no goose.nvim core changes required
- Recipe execution can use same plenary.job pattern as core plugin
- Session management automatically handles recipe runs

**From Output Handling Report**:
- goose-picker-output.md is NOT created by picker code (debugging artifact)
- ToggleTerm outputs to buffer (not files) - no file redirection issue exists
- Sidebar integration will eliminate terminal buffers entirely
- Session files (~/.config/goose/sessions/) are legitimate output (not unwanted)

**Recommended Approach**: Implement hybrid adapter layer (Strategy 3) with run_recipe_in_sidebar() function in execution.lua, using plenary.job directly to execute recipes with sidebar output handling.

## Success Criteria

- [ ] Recipes executed via `<leader>aR` display output in goose sidebar (not terminal)
- [ ] Real-time streaming output visible during recipe execution
- [ ] Markdown rendering applied to recipe output (code blocks, headers, etc.)
- [ ] Recipe sessions integrated with goose session picker (`:GooseSelectSession`)
- [ ] No ToggleTerm terminal buffers created during recipe execution
- [ ] Recipe execution cancellation works via `:GooseStop`

## Technical Design

### Architecture Overview

The integration follows a hybrid adapter pattern that interfaces between the recipe picker and goose.nvim without modifying core plugin code:

```
┌─────────────────────────────────────────────────────────────────┐
│                    User Interface Layer                         │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Recipe Picker (Telescope)                              │    │
│  │  - discovery.lua: Find recipes                          │    │
│  │  - metadata.lua: Parse YAML                             │    │
│  │  - execution.lua: NEW run_recipe_in_sidebar()          │    │
│  └────────────┬───────────────────────────────────────────┘    │
└───────────────┼──────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Adapter Layer (NEW)                            │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  execution.lua: run_recipe_in_sidebar()                │    │
│  │  - Validate sidebar state (goose_state.windows)        │    │
│  │  - Build recipe CLI args (--recipe, --params)          │    │
│  │  - Create plenary.job with callbacks                   │    │
│  │  - Register job in goose_state                         │    │
│  └────────────┬───────────────────────────────────────────┘    │
└───────────────┼──────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  goose.nvim Integration                         │
│  ┌────────────────────┬──────────────────────────────────┐    │
│  │  goose.core        │  goose.ui                        │    │
│  │  - open()          │  - render_output()               │    │
│  │  - stop()          │  - scroll_to_bottom()            │    │
│  └────────────────────┴──────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Process Execution Layer                        │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  plenary.job                                            │    │
│  │  - Job:new({ command, args, on_stdout, on_exit })     │    │
│  │  - Spawns: goose run --recipe PATH --params KEY=VAL   │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

**1. execution.lua (Modified)**:
- NEW: `run_recipe_in_sidebar(recipe_path, metadata)` - Primary integration function
- Ensures sidebar is open (calls goose.core.open if needed)
- Builds goose CLI arguments for recipe execution
- Creates plenary.job with callbacks mimicking goose.job pattern
- Registers job in goose_state for lifecycle management
- REMOVED: `run_recipe()` - ToggleTerm execution removed (clean-break)

**2. init.lua (Modified)**:
- Update default `<CR>` action to call run_recipe_in_sidebar()
- Update which-key descriptions for sidebar execution

**3. goose.nvim Core (Unchanged)**:
- Leverage existing sidebar UI, session management, and job tracking
- No modifications to goose.nvim plugin code required
- Adapter pattern ensures compatibility with future goose.nvim updates

### Data Flow

**Recipe Execution Flow**:
1. User presses `<leader>aR` → Telescope picker opens
2. User selects recipe → Parameter prompts appear
3. User confirms parameters → `run_recipe_in_sidebar()` called
4. Function validates sidebar state → Opens if needed
5. Function builds CLI args → `{ "run", "--recipe", PATH, "--params", "..." }`
6. Function creates plenary.job → Registers callbacks
7. Job starts → on_start triggers UI update
8. Output streams → on_stdout triggers render_output() + scroll
9. Job completes → on_exit clears job state

**Output Streaming**:
```
goose CLI stdout (line-buffered)
      ↓
plenary.job on_stdout callback
      ↓
vim.schedule() for async safety
      ↓
vim.cmd('checktime') - Reload session changes
      ↓
goose.ui.render_output() - Update sidebar buffer
      ↓
render-markdown.nvim - Apply formatting
      ↓
goose.ui.scroll_to_bottom() - Auto-scroll
```

### Standards Compliance

**Code Standards** (from CLAUDE.md):
- Lua indentation: 2 spaces (preserved from existing picker code)
- Error handling: Use pcall for external module loading
- Module structure: M.function_name pattern
- File paths: Use absolute paths from vim.fn.stdpath()

**Testing Protocols**:
- Unit tests: Validate recipe arg building logic
- Integration tests: Execute recipes with mock goose CLI
- Manual tests: Real recipe execution with various parameter types

**Clean-Break Development**:
- No deprecation period for ToggleTerm execution
- Direct replacement of default behavior (old ToggleTerm code removed)
- Clean migration: sidebar execution is the only execution method

**Error Logging**:
- Integrate error-handling.sh for recipe execution failures
- Log errors with error_type: "recipe_execution_error"
- Include recipe path and parameters in error details

### Divergence Analysis

**No Standards Divergence Detected**:
- Implementation aligns with existing Lua coding standards
- No CLAUDE.md modifications required
- Testing approach follows testing_protocols standards
- Documentation follows documentation_policy standards

## Implementation Phases

### Phase 1: Sidebar Integration Function [COMPLETE]
dependencies: []

**Objective**: Implement run_recipe_in_sidebar() function in execution.lua with plenary.job integration.

**Complexity**: Medium

**Tasks**:
- [x] Create run_recipe_in_sidebar(recipe_path, metadata) function in execution.lua
- [x] Add pcall wrapper for goose module imports (goose.core, goose.ui, goose.state)
- [x] Implement sidebar validation: Check if goose_state.windows exists
- [x] Implement sidebar opening: Call goose.core.open() if sidebar closed
- [x] Implement job stopping: Call goose.core.stop() to clear existing jobs
- [x] Build recipe CLI args array: { "run", "--recipe", recipe_path, "--params", "..." }
- [x] Implement parameter serialization: Convert params table to "key=value,key2=value2"
- [x] Create plenary.job with command "goose" and args array
- [x] Implement on_start callback: Call goose.ui.render_output() in vim.schedule()
- [x] Implement on_stdout callback: Call vim.cmd('checktime') + render_output() in vim.schedule()
- [x] Implement on_stderr callback: Display error notification with vim.notify()
- [x] Implement on_exit callback: Clear goose_state.goose_run_job in vim.schedule()
- [x] Register job in goose_state.goose_run_job = job
- [x] Start job with job:start()
- [x] Add user notification: "Executing recipe: {name} | Output: Goose sidebar"

**Testing**:
```bash
# Manual integration test
# 1. Open neovim with goose.nvim installed
# 2. Press <leader>aR to open recipe picker
# 3. Select recipe with parameters
# 4. Verify output appears in goose sidebar (right panel)
# 5. Verify markdown rendering applied (code blocks visible)
# 6. Verify auto-scroll to bottom during output
# 7. Test :GooseStop cancellation during execution

# Unit test for parameter serialization
lua << EOF
local exec = require('neotex.plugins.ai.goose.picker.execution')
local params = { feature = "auth", complexity = 2 }
local result = exec._serialize_params(params) -- Helper function
assert(result == "feature=auth,complexity=2", "Parameter serialization failed")
print("✓ Parameter serialization test passed")
EOF
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["test-output.log"]

**Expected Duration**: 4 hours

### Phase 2: Picker Keybinding Updates [COMPLETE]
dependencies: [1]

**Objective**: Update recipe picker init.lua to use sidebar execution and remove ToggleTerm code.

**Complexity**: Low

**Tasks**:
- [x] Update init.lua attach_mappings section
- [x] Replace default `<CR>` action: Call execution.run_recipe_in_sidebar() instead of run_recipe()
- [x] Remove run_recipe() function from execution.lua (clean-break)
- [x] Update action notification: "Executing recipe in sidebar..."
- [x] Update picker help text: Document sidebar execution

**Testing**:
```bash
# Manual keybinding test
# 1. Open recipe picker with <leader>aR
# 2. Press <CR> on a recipe → Verify sidebar execution
# 3. Test with recipes requiring no parameters
# 4. Test with recipes requiring multiple parameters

# Automated keybinding validation
lua << EOF
local picker = require('neotex.plugins.ai.goose.picker')
local mappings = picker._get_mappings() -- Helper function
assert(mappings['<CR>'].action == 'sidebar', "Default action incorrect")
print("✓ Keybinding configuration test passed")
EOF
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["keybinding-test.log"]

**Expected Duration**: 0.5 hours

### Phase 3: which-key Integration [COMPLETE]
dependencies: [2]

**Objective**: Update which-key.lua to document sidebar recipe execution.

**Complexity**: Low

**Tasks**:
- [x] Update `<leader>aR` description in which-key.lua
- [x] Change description from "Run Goose Recipe" to "Run Goose Recipe (Sidebar)"
- [x] Verify which-key menu displays updated description
- [x] Test which-key popup shows correct keybinding hint

**Testing**:
```bash
# Manual which-key validation
# 1. Press <leader> in normal mode
# 2. Navigate to 'a' (AI tools) section
# 3. Verify 'R' shows "Run Goose Recipe (Sidebar)"

# Automated which-key config test
lua << EOF
local wk = require('which-key')
local mappings = wk.get_mappings()
local recipe_mapping = mappings['<leader>aR']
assert(recipe_mapping.desc:match("Sidebar"), "which-key description not updated")
print("✓ which-key integration test passed")
EOF
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["which-key-test.log"]

**Expected Duration**: 0.25 hours

### Phase 4: Error Handling and Edge Cases [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Implement robust error handling for sidebar unavailable, goose CLI errors, and parameter validation failures.

**Complexity**: Medium

**Tasks**:
- [x] Add error handling for goose module load failures (pcall wrapper)
- [x] Add error notification if goose.nvim not installed: "goose.nvim required for recipe execution. Install plugin."
- [x] Handle sidebar open failures: Retry once, then display error notification
- [x] Validate recipe_path existence before execution
- [x] Handle empty parameters gracefully (skip --params flag if no params)
- [x] Implement goose CLI error parsing from stderr
- [x] Display structured error notifications: Show recipe name + error message
- [x] Handle job cancellation cleanly: Clear job state on :GooseStop
- [x] Test long-running recipe cancellation
- [x] Test recipe with invalid YAML (template errors)
- [x] Test recipe with missing required parameters
- [x] Integrate with error-handling.sh library for error logging

**Testing**:
```bash
# Automated error handling tests
lua << EOF
local exec = require('neotex.plugins.ai.goose.picker.execution')

-- Test 1: goose.nvim not loaded
package.loaded['goose.core'] = nil
local ok, err = pcall(exec.run_recipe_in_sidebar, "/fake/recipe.yaml", {})
assert(not ok, "Should fail when goose.nvim unavailable")
print("✓ Test 1 passed: goose.nvim unavailable")

-- Test 2: Invalid recipe path
local ok, err = pcall(exec.run_recipe_in_sidebar, "/nonexistent/recipe.yaml", {})
assert(not ok, "Should fail with invalid recipe path")
print("✓ Test 2 passed: Invalid recipe path")

-- Test 3: Empty parameters
local ok = pcall(exec.run_recipe_in_sidebar, "/valid/recipe.yaml", {})
assert(ok, "Should handle empty parameters")
print("✓ Test 3 passed: Empty parameters")

print("✓ All error handling tests passed")
EOF

# Integration test: Recipe execution with goose CLI error
# 1. Create recipe with syntax error (invalid YAML)
# 2. Execute via picker
# 3. Verify error message displayed in notification
# 4. Verify sidebar shows goose error output
# 5. Verify no job left in goose_state after error
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["error-handling-test.log"]

**Expected Duration**: 2.5 hours

### Phase 5: Documentation and Testing [COMPLETE]
dependencies: [1, 2, 3, 4]

**Objective**: Update picker README, add comprehensive test suite, and validate integration with existing recipes.

**Complexity**: Medium

**Tasks**:
- [x] Update picker/README.md with sidebar execution documentation
- [x] Document run_recipe_in_sidebar() function signature and behavior
- [x] Document keybinding: `<CR>` for sidebar execution
- [x] Add architecture diagram showing adapter layer integration
- [x] Document troubleshooting section: Common errors and solutions
- [x] Add session management notes: How recipe sessions integrate with goose
- [x] Create test suite for recipe execution module
- [x] Test with project recipes (.goose/recipes/)
- [x] Test with global recipes (~/.config/goose/recipes/)
- [x] Test with recipes requiring user_prompt parameters
- [x] Test with recipes using --interactive mode
- [x] Verify session picker shows recipe sessions
- [x] Test recipe output with markdown (code blocks, headers, lists)
- [x] Test with long-running recipes (streaming output)
- [x] Validate no ToggleTerm buffers created during execution
- [x] Verify goose-picker-output.md not created (confirm file redirection resolved)

**Testing**:
```bash
# Comprehensive integration test suite
# Test 1: Project recipe execution
nvim -c "lua require('neotex.plugins.ai.goose.picker').show_recipe_picker()" \
     -c "norm /create-plan\r\r" \
     -c "sleep 5" \
     -c "q"

# Test 2: Global recipe execution
nvim -c "lua require('neotex.plugins.ai.goose.picker').show_recipe_picker()" \
     -c "norm /analyze\r\r" \
     -c "sleep 5" \
     -c "q"

# Test 3: Verify no output files created
test ! -f .claude/output/goose-picker-output.md && echo "✓ No unwanted output files"

# Test 4: Verify session file created
SESSION_COUNT=$(ls ~/.config/goose/sessions/*.jsonl 2>/dev/null | wc -l)
[ "$SESSION_COUNT" -gt 0 ] && echo "✓ Recipe session created"

# Test 5: Verify no ToggleTerm buffers
TERM_COUNT=$(nvim --headless -c "lua print(#vim.fn.getbufinfo({buflisted=1, buftype='terminal'}))" -c "q" 2>&1 | grep -E "^[0-9]+$")
[ "$TERM_COUNT" -eq 0 ] && echo "✓ No terminal buffers created"

# Documentation validation
grep -q "run_recipe_in_sidebar" nvim/lua/neotex/plugins/ai/goose/picker/README.md || exit 1
grep -q "Sidebar Execution" nvim/lua/neotex/plugins/ai/goose/picker/README.md || exit 1
echo "✓ Documentation updated"
```

**Automation Metadata**:
- automation_type: automated
- validation_method: programmatic
- skip_allowed: false
- artifact_outputs: ["integration-test.log", "README.md"]

**Expected Duration**: 2 hours

## Testing Strategy

### Unit Testing
- **Scope**: Individual functions (parameter serialization, arg building, error handling)
- **Tools**: Lua assertions, pcall wrappers
- **Coverage**: All helper functions in execution.lua

### Integration Testing
- **Scope**: Full recipe execution flow from picker to sidebar output
- **Tools**: Manual neovim sessions, automated lua scripts
- **Coverage**: Default keybinding, error scenarios

### Manual Testing Checklist
- [ ] Recipe with no parameters executes in sidebar
- [ ] Recipe with multiple parameters prompts correctly
- [ ] Markdown rendering applies to output (code blocks, headers)
- [ ] Real-time streaming visible during long-running recipe
- [ ] Recipe cancellation works via :GooseStop
- [ ] Session picker shows recipe sessions with correct descriptions
- [ ] Error notifications display for invalid recipes
- [ ] Sidebar auto-opens if closed before execution
- [ ] No ToggleTerm buffers created during execution

### Performance Testing
- **Metrics**: Output latency (on_stdout to render), memory usage, job cleanup
- **Baseline**: Compare with ToggleTerm execution performance
- **Acceptance**: Sidebar execution should have <100ms latency for output updates

## Documentation Requirements

### Files to Update
1. **nvim/lua/neotex/plugins/ai/goose/picker/README.md**:
   - Add "Sidebar Execution" section describing integration
   - Document run_recipe_in_sidebar() function
   - Update keybinding reference: `<CR>` for sidebar execution
   - Add troubleshooting section for common errors

2. **nvim/lua/neotex/plugins/ai/goose/README.md** (if exists):
   - Update recipe execution section
   - Note sidebar integration feature

3. **Function Documentation** (execution.lua):
   - Add docstrings for run_recipe_in_sidebar()
   - Document parameters: recipe_path (string), metadata (table)
   - Document return values: nil (async execution)
   - Document side effects: Opens sidebar, creates job, displays notifications

### Documentation Standards (from CLAUDE.md)
- Use clear, concise language
- Include code examples with syntax highlighting
- No emojis in file content (UTF-8 encoding issues)
- Follow CommonMark specification
- Remove historical commentary (focus on current implementation)

## Dependencies

### External Dependencies
- **goose.nvim plugin**: Must be installed and loaded (azorng/goose.nvim)
- **plenary.nvim**: Required by goose.nvim (transitive dependency)
- **goose CLI**: Must be available in PATH
- **render-markdown.nvim**: Used by goose.nvim for output rendering (optional but recommended)

### Internal Dependencies
- **Existing picker modules**: discovery.lua, metadata.lua, previewer.lua (unchanged)
- **which-key.lua**: Requires update for keybinding descriptions

### Configuration Dependencies
- **goose config.yaml**: Must be properly configured (~/.config/goose/config.yaml)
- **Recipe directory**: Project (.goose/recipes/) or global (~/.config/goose/recipes/)
- **goose.nvim configuration**: UI settings in neotex/plugins/ai/goose/init.lua

### Risk Mitigation
- **goose.nvim not installed**: Graceful error with actionable message
- **goose CLI not in PATH**: Error message with installation instructions
- **Sidebar open failure**: Retry once, then display error notification
- **Recipe YAML errors**: goose CLI error captured and displayed in sidebar

## Notes

### Implementation Decisions

**Why Hybrid Approach (Strategy 3)?**
- No dependency on upstream goose.nvim changes (faster implementation)
- Clean separation between picker and plugin (maintainable)
- Can be implemented immediately (no PR review delays)
- Proven pattern from goose.job.lua (low risk)

**Clean-Break Approach (Revised 2025-12-09)**:
- ToggleTerm integration completely removed (no fallback keybinding)
- No deprecation period: sidebar execution is the only method
- Simplifies implementation and testing
- Aligns with project Clean-Break Development Standard

**Why Not Modify goose.nvim Core?**
- Adapter pattern is sufficient for requirements
- Avoids plugin maintenance burden
- Future goose.nvim updates won't break integration
- Upstream PR could be submitted later if desired

### Session Management Notes

Recipe executions create or resume goose sessions:
- Session ID auto-generated by goose CLI (timestamp-based)
- Session files stored in ~/.config/goose/sessions/
- Session picker (`:GooseSelectSession`) shows recipe sessions
- Follow-up prompts in same session maintain context
- Recipe name could be included in session description (future enhancement)

### File Redirection Resolution

Research confirmed that goose-picker-output.md is NOT created by picker code:
- File is a debugging artifact from external workflow
- ToggleTerm outputs to buffer (not file)
- Sidebar integration eliminates terminal buffers entirely
- Session files are legitimate output (not unwanted)

### Future Enhancements

Potential improvements beyond this plan:
1. **Native Recipe Support in goose.nvim**: Submit PR to upstream for `--recipe` arg support in job.lua
2. **Recipe Session Tagging**: Add [picker:YYYYMMDD] tags to session descriptions for filtering
3. **Output Destination Prompt**: vim.ui.select() to choose sidebar vs terminal per execution
4. **Recipe Execution History**: Track recipe runs in separate metadata file
5. **Session Cleanup Utility**: Automated cleanup of old recipe sessions (>7 days)
