# goose.nvim Sidebar Split Refactor Implementation Plan

## Metadata
- **Date**: 2025-12-09
- **Feature**: Refactor goose.nvim configuration to use split windows instead of floating windows for sidebar navigation integration
- **Status**: [NOT STARTED]
- **Estimated Hours**: 4-6 hours
- **Complexity Score**: 35.0
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Split Window UI Implementation in Neovim](../reports/001-split-window-ui-implementation.md)
  - [Window Configuration and Type Selection](../reports/002-window-config-schema.md)
  - [Split Navigation Keybinding Integration](../reports/003-split-navigation-integration.md)

## Overview

This plan implements split window support for goose.nvim as an alternative to the current floating window implementation. The feature request (GitHub issue #82) seeks to integrate goose.nvim with standard Neovim split navigation workflows, making it consistent with other sidebar plugins like nvim-tree, toggleterm, and lean.nvim infoview.

**Key Objectives**:
1. Enable `window_type = "split"` configuration option in user's goose.nvim config
2. Integrate with existing `<C-h>` and `<C-l>` split navigation keybindings
3. Maintain backward compatibility (floating window remains default)
4. Achieve consistent UX with other sidebar plugins in the user's configuration

**Important Discovery**: Research reveals that goose.nvim upstream source code **already implements** split window support via the `window_type` configuration option. This refactor primarily involves enabling and testing the existing split mode in the user's local configuration, with potential minor adjustments if needed.

## Research Summary

### Key Findings from Research Reports

**From Split Window UI Implementation Report**:
- Neovim 0.10+ supports split window creation via `nvim_open_win()` with `split` parameter
- goose.nvim already contains split window implementation logic in `ui.lua` and `window_config.lua`
- Two windows created: `input_win` (prompt) and `output_win` (conversation)
- Current implementation uses `relative = 'editor'` for floating windows
- Split mode uses vim commands: `"topleft vsplit"` or `"botright vsplit"`

**From Window Configuration Report**:
- The `window_type` configuration option may already exist upstream but is not exposed in user config
- Proposed schema: `window_type = "split"` with `layout = "right"` or `layout = "left"`
- Width controlled by existing `window_width = 0.35` (35% of screen)
- Input/output split ratio controlled by existing `input_height = 0.15` (15%)
- Backward compatibility achieved by defaulting `window_type = "float"`

**From Split Navigation Integration Report**:
- User's keybindings already configured: `<C-h/j/k/l>` map to `<C-w>h/j/k/l>`
- Split windows automatically participate in Neovim's window navigation system
- Terminal mode keybindings use `wincmd h/j/k/l` (compatible with split windows)
- Other sidebar plugins (neo-tree, lean.nvim, toggleterm) all use split windows
- No keybinding changes required for split navigation to work

**Recommended Approach**:
Based on research findings, the implementation should focus on configuration changes to enable the existing split window functionality, followed by comprehensive testing to verify integration with the user's navigation workflow.

## Success Criteria

- [ ] goose.nvim opens as a split window (not floating) when `window_type = "split"` is set
- [ ] Split window appears on right side of screen (respecting `layout = "right"`)
- [ ] Window width is 35% of screen width (respecting `window_width = 0.35`)
- [ ] Input/output windows maintain vertical split relationship (15%/85% ratio)
- [ ] Navigation with `<C-h>` moves focus from goose to left window
- [ ] Navigation with `<C-l>` moves focus to goose from left window
- [ ] Terminal mode navigation works within goose terminal buffers
- [ ] No conflicts with existing sidebar plugins (neo-tree, lean.nvim, toggleterm)
- [ ] Floating window mode still works when `window_type = "float"` (backward compatibility)
- [ ] goose buffers excluded from buffer navigation (`<Tab>`, `<S-Tab>`)

## Technical Design

### Architecture Overview

The refactor leverages goose.nvim's existing split window implementation by modifying the user's local configuration file. The implementation follows this architecture:

**Configuration Layer** (`/home/benjamin/.config/nvim/lua/neotex/plugins/ai/goose/init.lua`):
- Add `window_type = "split"` to `ui` configuration table
- Retain existing layout, width, and height configurations
- goose.nvim plugin reads configuration and activates split window code path

**Window Creation Layer** (goose.nvim plugin, read-only analysis):
- `ui.lua`: Detects `config.ui.window_type == "split"` and uses vim split commands
- `window_config.lua`: Applies split-specific dimension configuration
- Windows created with `vsplit` and `split` commands (not `nvim_open_win` with `relative`)

**Navigation Integration** (existing, no changes required):
- User's keybindings (`<C-h/j/k/l>`) already map to `<C-w>h/j/k/l>`
- Split windows automatically participate in `wincmd` navigation system
- Terminal mode keybindings use `wincmd` (compatible with goose terminal buffers)

### Component Interactions

```
User Config (init.lua)
  └─> window_type = "split"
      └─> goose.nvim reads config
          └─> ui.lua detects split mode
              └─> Uses "botright vsplit" (layout="right")
                  └─> window_config.lua sets width/height
                      └─> Split window participates in wincmd navigation
                          └─> User's <C-h/l> keybindings work automatically
```

### Configuration Schema

**Current Configuration** (floating mode):
```lua
ui = {
  window_width = 0.35,
  input_height = 0.15,
  fullscreen = false,
  layout = "right",
  floating_height = 0.8,
  display_model = true,
  display_goose_mode = true,
}
```

**Target Configuration** (split mode):
```lua
ui = {
  window_type = "split",     -- NEW: Enable split window mode
  window_width = 0.35,       -- Existing: Applies to split width
  input_height = 0.15,       -- Existing: Applies to input area
  fullscreen = false,        -- Existing: May be no-op in split mode
  layout = "right",          -- Existing: Maps to "botright vsplit"
  floating_height = 0.8,     -- Existing: Ignored in split mode
  display_model = true,      -- Existing: Display options unchanged
  display_goose_mode = true, -- Existing: Display options unchanged
}
```

### Buffer Settings Recommendations

To prevent goose buffers from appearing in buffer navigation (matching behavior of other sidebar plugins), consider applying these buffer settings:

```lua
vim.bo.buflisted = false   -- Exclude from buffer lists
vim.bo.bufhidden = "hide"  -- Hide when not displayed
vim.bo.buftype = "nofile"  -- Not associated with a file
```

**Implementation Note**: These settings are likely already implemented in goose.nvim's buffer setup. Verification required during testing phase.

### Standards Alignment

**Code Standards Compliance**:
- Configuration changes follow Lua table syntax from nvim CLAUDE.md
- No bash sourcing required (Lua configuration only)
- No custom scripts needed (using existing plugin functionality)

**Documentation Standards**:
- Update local README documenting configuration change
- Reference GitHub issue #82 for traceability
- Document testing results and any discovered edge cases

**Directory Organization**:
- Configuration file located in standard plugin directory: `nvim/lua/neotex/plugins/ai/goose/`
- No new files created (modification of existing init.lua)

## Implementation Phases

### Phase 1: Configuration Update and Basic Testing [NOT STARTED]
dependencies: []

**Objective**: Update goose.nvim configuration to enable split window mode and verify basic window creation.

**Complexity**: Low

**Tasks**:
- [ ] Backup current goose configuration: `cp nvim/lua/neotex/plugins/ai/goose/init.lua nvim/lua/neotex/plugins/ai/goose/init.lua.backup.$(date +%Y%m%d)`
- [ ] Add `window_type = "split"` to `ui` configuration table in `nvim/lua/neotex/plugins/ai/goose/init.lua`
- [ ] Restart Neovim to reload plugin configuration
- [ ] Open goose.nvim using existing toggle keybinding
- [ ] Verify split window created (not floating window)
- [ ] Verify window appears on right side of screen
- [ ] Verify window width approximately 35% of screen width
- [ ] Verify input and output windows present as vertical split

**Testing**:
```bash
# Manual verification steps
# 1. Open Neovim
nvim

# 2. Inside Neovim, check window configuration type
# In Neovim command mode, after opening goose:
:lua print(vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative)
# Expected output: empty string (indicating split window, not floating)

# 3. Check window count
:lua print(vim.fn.winnr('$'))
# Expected: At least 3 windows (main + goose output + goose input)

# 4. Check window width ratio
:lua local total_width = vim.o.columns; local goose_width = vim.api.nvim_win_get_width(0); print(string.format("%.2f", goose_width / total_width))
# Expected: ~0.35 (35% of screen)
```

**Automation Metadata**:
- automation_type: manual (visual verification required for window positioning)
- validation_method: programmatic (Lua command validation)
- skip_allowed: false
- artifact_outputs: ["init.lua.backup.*"]

**Expected Duration**: 1 hour

---

### Phase 2: Split Navigation Integration Testing [NOT STARTED]
dependencies: [1]

**Objective**: Verify that split navigation keybindings (`<C-h>`, `<C-l>`) work correctly with goose.nvim split windows.

**Complexity**: Low

**Tasks**:
- [ ] Open goose.nvim in split mode (right sidebar)
- [ ] Open neo-tree or other left sidebar plugin
- [ ] Test navigation from main window to goose using `<C-l>`
- [ ] Test navigation from goose to main window using `<C-h>`
- [ ] Test navigation from goose to neo-tree (if open) using `<C-h>` repeatedly
- [ ] Verify focus changes between windows as expected
- [ ] Test all four directional keybindings: `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`
- [ ] Document any navigation issues or unexpected behavior

**Testing**:
```bash
# Manual navigation test protocol
# 1. Open Neovim with multiple windows
nvim test_file.txt

# 2. In Neovim, open neo-tree (left sidebar)
# :Neotree toggle

# 3. Open goose.nvim (right sidebar)
# Use configured goose toggle keybinding

# 4. Navigate through windows using <C-h/j/k/l>
# Verify focus moves correctly between:
# - neo-tree (left)
# - main window (center)
# - goose output (right top)
# - goose input (right bottom)

# 5. Check current window number changes
:lua print(vim.fn.winnr())
# Execute after each navigation, verify number changes
```

**Automation Metadata**:
- automation_type: manual (interactive navigation testing)
- validation_method: visual (focus changes visible)
- skip_allowed: false
- artifact_outputs: []

**Expected Duration**: 1 hour

---

### Phase 3: Terminal Mode Navigation Testing [NOT STARTED]
dependencies: [2]

**Objective**: Verify terminal mode navigation keybindings work within goose.nvim when executing recipes (terminal buffers).

**Complexity**: Low

**Tasks**:
- [ ] Start a goose recipe that creates a terminal buffer
- [ ] Verify terminal buffer opens in goose window
- [ ] Enter terminal mode in goose window (should be automatic)
- [ ] Test `<C-h>` navigation from terminal mode to adjacent window
- [ ] Test `<C-l>` navigation back to terminal window
- [ ] Verify terminal mode keybindings use `wincmd` (from user config)
- [ ] Test all four directional terminal mode keybindings
- [ ] Document any terminal-specific navigation issues

**Testing**:
```bash
# Manual terminal mode test protocol
# 1. Open goose.nvim in split mode
# 2. Start a goose recipe (creates terminal buffer)
# 3. In terminal mode, press <C-h>
# Expected: Focus moves to window on the left
# 4. Press <C-l> to return to goose terminal
# Expected: Focus returns to goose window

# Verify keybinding configuration
# Check that terminal mode keybindings use wincmd:
nvim -c ':verbose map <C-h>'
# Expected output should show: buf_map(0, "t", "<C-h>", "<Cmd>wincmd h<CR>", ...)
```

**Automation Metadata**:
- automation_type: manual (terminal interaction required)
- validation_method: visual (focus changes in terminal mode)
- skip_allowed: false
- artifact_outputs: []

**Expected Duration**: 0.5 hours

---

### Phase 4: Multi-Sidebar Layout Testing [NOT STARTED]
dependencies: [3]

**Objective**: Test goose.nvim split mode integration with other sidebar plugins (neo-tree, lean.nvim, toggleterm).

**Complexity**: Medium

**Tasks**:
- [ ] Test scenario: neo-tree (left) + goose (right) + main window (center)
- [ ] Test scenario: toggleterm (vertical) + goose (right) navigation
- [ ] Test scenario: lean.nvim infoview (bottom-right) + goose (right) layout
- [ ] Test scenario: All sidebar plugins open simultaneously
- [ ] Verify no layout conflicts or unexpected window positioning
- [ ] Verify navigation works correctly in all multi-sidebar scenarios
- [ ] Test window resizing with multiple sidebars open
- [ ] Document any plugin interaction issues or edge cases

**Testing**:
```bash
# Multi-sidebar layout test scenarios
# Scenario 1: neo-tree + goose
# 1. Open neo-tree on left
# 2. Open goose on right
# 3. Navigate between all windows
# 4. Verify layout: [neo-tree | main | goose]

# Scenario 2: toggleterm + goose
# 1. Open toggleterm (vertical split)
# 2. Open goose (right split)
# 3. Verify no layout conflicts

# Scenario 3: lean.nvim + goose
# 1. Open Lean file (triggers infoview)
# 2. Open goose (right split)
# 3. Verify layout: [main | goose (top) / lean-infoview (bottom-right)]

# Scenario 4: All plugins
# 1. Open neo-tree + toggleterm + goose + lean infoview
# 2. Navigate between all windows
# 3. Verify all plugins coexist without conflicts
```

**Automation Metadata**:
- automation_type: manual (complex layout scenarios)
- validation_method: visual (multi-window layout verification)
- skip_allowed: false
- artifact_outputs: []

**Expected Duration**: 1 hour

---

### Phase 5: Edge Cases and Configuration Tuning [NOT STARTED]
dependencies: [4]

**Objective**: Test edge cases, configure buffer settings, and ensure robust split window behavior.

**Complexity**: Medium

**Tasks**:
- [ ] Test window resize behavior (`:VimResized` autocmd triggers)
- [ ] Verify goose toggle command opens/closes split correctly
- [ ] Test behavior when goose split is only open window
- [ ] Verify goose buffers excluded from buffer list (check `buflisted` setting)
- [ ] Test focus restoration when closing goose window
- [ ] Verify window dimensions persist across toggle cycles
- [ ] Test fullscreen mode behavior (may be no-op in split mode)
- [ ] Test alternative layout: `layout = "left"` (left sidebar instead of right)
- [ ] Document any discovered edge cases requiring configuration tuning

**Testing**:
```bash
# Edge case test protocol
# 1. Window resize test
# - Open goose split
# - Resize terminal window
# - Verify goose width adjusts proportionally

# 2. Toggle persistence test
# - Open goose split
# - Note window width
# - Close goose
# - Reopen goose
# - Verify width matches previous state

# 3. Buffer list pollution test
nvim
# :buffers
# Expected: goose buffers should NOT appear in list

# Check buffer settings
:lua local buf = vim.fn.bufnr('goose'); print(vim.bo[buf].buflisted)
# Expected: false

# 4. Left sidebar test
# Change config: layout = "left"
# Restart Neovim
# Open goose
# Verify split appears on left side
```

**Automation Metadata**:
- automation_type: semi-automated (resize triggers, buffer checks)
- validation_method: programmatic (buffer settings validation)
- skip_allowed: false
- artifact_outputs: []

**Expected Duration**: 1.5 hours

---

### Phase 6: Documentation and Backward Compatibility Verification [NOT STARTED]
dependencies: [5]

**Objective**: Document configuration changes, verify backward compatibility with floating mode, and create usage guide.

**Complexity**: Low

**Tasks**:
- [ ] Document `window_type = "split"` configuration in local README or config comments
- [ ] Add inline comment explaining split vs float mode trade-offs
- [ ] Test floating window mode still works: Set `window_type = "float"`, verify floating behavior
- [ ] Document GitHub issue #82 reference for traceability
- [ ] Create comparison table: split mode vs float mode features
- [ ] Document any discovered limitations of split mode
- [ ] Update goose configuration comments with recommended settings
- [ ] Optional: Consider upstream PR to goose.nvim repository documenting split mode

**Testing**:
```bash
# Backward compatibility test
# 1. Edit config: window_type = "float"
# 2. Restart Neovim
# 3. Open goose
# 4. Verify floating window behavior:
:lua print(vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative)
# Expected: "editor" (indicating floating window)

# 5. Verify navigation does NOT work with <C-h/l>
# (floating windows don't participate in split navigation)

# 6. Restore split mode: window_type = "split"
# 7. Verify split mode works again
```

**Automation Metadata**:
- automation_type: manual (documentation and verification)
- validation_method: visual (floating window verification)
- skip_allowed: false
- artifact_outputs: ["README.md updates", "config comments"]

**Expected Duration**: 1 hour

---

## Testing Strategy

### Overall Test Approach

The testing strategy uses manual verification with programmatic validation where possible. Since this refactor focuses on UI/UX changes (window positioning, navigation integration), visual confirmation is required for most test scenarios.

**Test Levels**:
1. **Unit Testing**: Configuration changes (Phase 1)
2. **Integration Testing**: Navigation integration (Phases 2-4)
3. **System Testing**: Multi-plugin scenarios (Phase 4)
4. **Regression Testing**: Backward compatibility (Phase 6)

**Test Environment**:
- Neovim version: User's current version (0.10+)
- Operating system: User's current OS (Linux)
- Plugin manager: lazy.nvim (user's current setup)
- Test plugins: neo-tree, lean.nvim, toggleterm (already installed)

**Test Execution Pattern**:
- Each phase includes explicit testing section with validation commands
- Manual test protocols documented for reproducibility
- Programmatic checks using Lua API where applicable
- All tests must pass before proceeding to next phase

**Success Metrics**:
- All 10 success criteria met (100% pass rate)
- Zero navigation conflicts with existing plugins
- Zero layout issues in multi-sidebar scenarios
- Backward compatibility verified (floating mode still works)

### Test Automation Considerations

While this refactor primarily requires manual testing due to UI/UX nature, the following components can be validated programmatically:

**Programmatic Validation**:
- Window configuration type: `nvim_win_get_config().relative == ''` (split window)
- Window count: `vim.fn.winnr('$') >= 3` (main + goose output + input)
- Window width ratio: `win_width / total_width ≈ 0.35`
- Buffer settings: `vim.bo.buflisted == false`, `vim.bo.buftype == "nofile"`

**Manual Validation**:
- Visual window positioning (left vs right sidebar)
- Navigation flow between windows
- Focus changes during `<C-h/j/k/l>` navigation
- Terminal mode interaction
- Multi-plugin layout verification

### Non-Interactive Testing Compliance

**Note**: This implementation plan involves primarily manual UI/UX testing due to the nature of window positioning and navigation verification. However, programmatic validation is included wherever feasible (window configuration checks, buffer settings validation).

Future enhancement opportunity: Create automated Neovim test suite using testing framework (e.g., plenary.nvim) to programmatically verify window states, navigation paths, and configuration loading.

## Documentation Requirements

### Files to Update

1. **Configuration File Comments** (`nvim/lua/neotex/plugins/ai/goose/init.lua`):
   - Add inline documentation explaining `window_type` option
   - Document split vs float mode trade-offs
   - Reference GitHub issue #82

2. **Local README** (if exists):
   - Document split mode configuration
   - Add usage examples
   - List any discovered limitations

3. **Testing Notes**:
   - Create test results summary
   - Document any edge cases discovered
   - Record multi-plugin compatibility findings

### Documentation Standards Compliance

**Follows nvim CLAUDE.md standards**:
- Clear, concise language
- Code examples with syntax highlighting
- No emojis in file content
- Follow CommonMark specification
- Update documentation with code changes

**Format**:
```lua
-- goose.nvim configuration
-- Reference: https://github.com/azorng/goose.nvim/issues/82
--
-- window_type options:
--   "float" - Floating window (default, original behavior)
--   "split" - Split window (integrates with <C-h/l> navigation)
--
-- Split mode benefits:
--   - Works with standard split navigation keybindings
--   - Consistent UX with neo-tree, toggleterm, lean.nvim
--   - No separate focus keybindings needed
--
-- Float mode benefits:
--   - Overlays main window (preserves screen space)
--   - Centered layout option available
--   - Traditional floating panel UX
```

## Dependencies

### External Dependencies

**Neovim Version**:
- Minimum: Neovim 0.10+ (for `nvim_open_win` split parameter support)
- User's current version: Verify compatibility

**goose.nvim Plugin**:
- Current version must include split window implementation
- Research indicates split mode exists in upstream source
- Verify user's installed version includes split window code path

**Plugin Manager**:
- lazy.nvim (user's current setup)
- Configuration changes require Neovim restart to reload plugin

### Internal Dependencies

**Existing Keybindings** (`nvim/lua/neotex/config/keymaps.lua`):
- Window navigation: `<C-h/j/k/l>` → `<C-w>h/j/k/l>`
- Terminal navigation: `<C-h/j/k/l>` → `wincmd h/j/k/l`
- No changes required (already compatible)

**Existing Sidebar Plugins**:
- neo-tree (left sidebar, split window)
- lean.nvim (infoview, split window)
- toggleterm (vertical split)
- All use split windows, no conflicts expected

**User Configuration**:
- `nvim/lua/neotex/config/options.lua`: `splitright = true` setting
- Ensures goose split opens on right side as expected

### Prerequisites Checklist

Before starting implementation:
- [ ] Verify Neovim version ≥ 0.10
- [ ] Verify goose.nvim plugin installed and up-to-date
- [ ] Backup current goose configuration
- [ ] Review existing keybinding configuration
- [ ] Document current goose.nvim version for reference

### Risk Assessment

**Low Risk**:
- Configuration change is non-destructive (can revert to `window_type = "float"`)
- Backup created before modification
- No plugin source code modifications required
- Research confirms split mode already implemented upstream

**Medium Risk**:
- Potential version compatibility issues if user's goose.nvim is outdated
- Possible layout conflicts with unusual window arrangements
- Terminal mode navigation behavior may vary across Neovim versions

**Mitigation Strategies**:
- Create configuration backup before changes
- Test each phase incrementally
- Document rollback procedure
- Verify goose.nvim version before starting
- Test backward compatibility in final phase

---

## Implementation Notes

### Complexity Calculation
```
Score = Base(refactor=5) + Tasks/2 + Files*3 + Integrations*5
Score = 5 + (34/2) + (1*3) + (3*5)
Score = 5 + 17 + 3 + 10
Score = 35.0
```

**Tier Selection**: Tier 1 (single file structure)
- Complexity score: 35.0 (< 50 threshold)
- Phases: 6 (manageable in single file)
- Files modified: 1 (init.lua configuration only)

### Progressive Planning Hint

This plan is created as **Level 0** (single file structure). The complexity score of 35.0 is below the threshold for phase expansion (50). All phases are contained in this single plan file for straightforward execution.

If implementation reveals additional complexity (e.g., custom buffer settings required, upstream patch needed), use `/expand phase <N>` to create detailed stage-level breakdowns for specific phases.

---

## Upstream Contribution Consideration

**Optional Post-Implementation**:
If split mode works well and testing reveals opportunities for improvement, consider contributing upstream to goose.nvim:

**Potential PR Scope**:
- Enhanced documentation of `window_type` configuration option
- Additional examples in goose.nvim README
- Configuration validation improvements
- Buffer settings recommendations for split mode

**Prerequisites for PR**:
- Thorough testing completed (all phases)
- Edge cases documented
- Split mode verified working on user's system
- Clear benefit demonstrated vs floating mode

**Not in Scope for Current Plan**:
- Upstream contributions are optional enhancement
- Current plan focuses on local configuration only
- No plugin source code modifications required

---

**Plan Status**: [NOT STARTED]
**Next Step**: Begin Phase 1 - Configuration Update and Basic Testing
