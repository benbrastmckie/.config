# goose.nvim Split Sidebar Implementation Plan

## Metadata
- **Date**: 2025-12-05
- **Feature**: Fork goose.nvim locally and implement split window support with toggleable right sidebar
- **Status**: [NOT STARTED]
- **Scope**: Replace floating windows with configurable split-based sidebar featuring width persistence, dual-pane layout (output/input), standard Neovim navigation integration, and backward-compatible configuration
- **Estimated Hours**: 11-16 hours
- **Complexity Score**: 87.5
- **Structure Level**: 0
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Implementation Research: goose.nvim Split Window Support](../reports/001-goose-split-sidebar-persist-analysis.md)

## Overview

Convert goose.nvim from floating window architecture to split-based sidebar while maintaining full backward compatibility. Implementation involves local fork creation, modification of 3 core files (~75 lines total), creation of 1 new width persistence module (~75 lines), and comprehensive testing across navigation, persistence, and integration scenarios.

**Key Deliverables**:
1. Local fork at `~/.config/nvim/lua/custom/goose-split.nvim`
2. Split window creation system (`create_split_windows()`)
3. Width persistence module (`width_persistence.lua`)
4. Configuration options (`use_splits`, `sidebar_position`, `persist_width`)
5. Native `<C-h>`/`<C-l>` navigation integration
6. Updated lazy.nvim configuration

## Research Summary

Research identified specific implementation points in goose.nvim architecture:
- **Window creation** is modular (only 2 lines use `nvim_open_win()` for floats)
- **State management** is window-type agnostic (`state.windows` table works for splits)
- **Width persistence pattern** validated from neo-tree reference implementation
- **Dual-pane layout** achievable via split sequence: `botright vsplit` → set output buffer → `split` → set input buffer
- **Total modifications**: ~189 new lines, ~15 modified lines across 4 files
- **Risk level**: Medium (well-established patterns, robust mitigation strategies)

## Success Criteria
- [ ] Local fork created at `~/.config/nvim/lua/custom/goose-split.nvim` with Git initialization
- [ ] Split mode opens right sidebar with dual-pane layout (output top, input bottom)
- [ ] Width persists across Neovim restarts via `~/.local/share/nvim/goose_split_width`
- [ ] Native `<C-h>`/`<C-l>` navigation works between editor and goose sidebar
- [ ] `<Tab>` toggles between input/output panes within goose
- [ ] Float mode remains unchanged when `use_splits = false` (backward compatibility)
- [ ] No conflicts with neo-tree, toggleterm, or other sidebar plugins
- [ ] Configuration migration guide documented for existing users

## Technical Design

### Architecture Overview

**Split Creation Pipeline**:
```
create_windows() [routing]
    ↓
create_split_windows() [NEW]
    ↓
1. botright vsplit          → Create right vertical split
2. Set output_buf           → Top pane (output_win)
3. split (horizontal)       → Within sidebar
4. Set input_buf            → Bottom pane (input_win)
5. configure_split_dimensions() → Apply width/heights
6. apply_split_constraints()    → Lock width, track changes
```

**Width Persistence Flow**:
```
Initialization:
  load_width() → Read from ~/.local/share/nvim/goose_split_width
             → Return saved width or default (80)
             → nvim_win_set_width() applied to both windows

Runtime Tracking:
  WinResized autocmd → track_width_change()
                    → Check current width
                    → Write to persistence file if changed
```

**State Management**:
- Reuse existing `state.windows` table (no changes needed)
- Window handles stored: `input_buf`, `output_buf`, `input_win`, `output_win`
- Window type (split vs float) abstracted away from cleanup/focus logic

### Modified Files

**File 1: `lua/goose/ui/ui.lua`** (+60 lines, ~5 modified)
- Add `create_split_windows()` function (lines 81-164)
- Modify `create_windows()` to route based on `config.ui.use_splits` (line 56)
- No changes to `close_windows()`, `focus_input()`, `focus_output()` (window-type agnostic)

**File 2: `lua/goose/ui/window_config.lua`** (+50 lines, ~10 modified)
- Add `configure_split_dimensions()` function (load/apply width, calculate heights)
- Add `apply_split_constraints()` function (winfixwidth, WinResized autocmd)
- Modify `setup_resize_handler()` to route split vs float dimension logic

**File 3: `lua/goose/config.lua`** (+4 lines)
- Add configuration options: `use_splits`, `sidebar_position`, `persist_width`, `default_split_width`
- Default: `use_splits = false` (backward compatibility)

**File 4: `lua/goose/ui/width_persistence.lua`** (+75 lines, NEW)
- Module functions: `load_width()`, `save_width()`, `track_width_change()`, `get_width()`
- Persistence file: `~/.local/share/nvim/goose_split_width` (single line with width value)
- Width validation: 30-200 column range

### Configuration Schema

**User Configuration** (nvim/lua/neotex/plugins/ai/goose/init.lua):
```lua
require("goose").setup({
  ui = {
    -- Existing float mode options (unchanged)
    window_width = 0.35,      -- Float mode only
    input_height = 0.15,      -- Both modes (percentage for splits)
    fullscreen = false,
    layout = "right",         -- Float mode only
    floating_height = 0.8,    -- Float mode only
    display_model = true,
    display_goose_mode = true,

    -- NEW: Split mode options
    use_splits = true,              -- Enable split mode (default: false)
    sidebar_position = "right",     -- "left" or "right" (default: "right")
    persist_width = true,           -- Enable width persistence (default: true)
    default_split_width = 80,       -- Default width in columns (default: 80)
  },
})
```

### Dual-Pane Layout

**Visual Layout** (Right Sidebar):
```
┌─────────────────────────────┬────────────────────┐
│                             │                    │
│                             │  Output Window     │
│    Main Editor              │  (output_win)      │
│    (Code Files)             │  Markdown render   │
│                             │  ~85% height       │
│                             ├────────────────────┤
│                             │  Input Window      │
│                             │  (input_win)       │
│                             │  Prompt input      │
│                             │  ~15% height       │
└─────────────────────────────┴────────────────────┘
```

**Height Calculation**:
- Total height from `nvim_win_get_height(output_win)`
- Input: `floor(total * config.ui.input_height)` (default: 15%)
- Output: `total - input_height` (default: 85%)

### Navigation Integration

**Native Neovim Navigation** (no modifications needed):
- `<C-h>` - Move to left window (editor)
- `<C-l>` - Move to right window (goose sidebar)
- `<C-w>w` - Cycle through windows

**Existing Goose Navigation** (unchanged):
- `<Tab>` - Toggle between input/output panes (within goose)
- Mapped to `api.toggle_pane()` in both windows

### Error Handling

**Window Creation**:
- Wrap `nvim_win_set_buf()` in `pcall()` to handle invalid buffer/window scenarios
- Validate window handles with `nvim_win_is_valid()` before operations
- Fallback to default dimensions if persistence file corrupted

**Width Persistence**:
- Validate width range (30-200 columns) before saving
- Graceful fallback to `config.ui.default_split_width` if file unreadable
- Use `pcall()` around `writefile()` to prevent crashes on permission errors

**Cleanup**:
- Existing `close_windows()` already uses `pcall()` for all window/buffer operations
- No modifications needed (window-type agnostic cleanup)

## Implementation Phases

### Phase 1: Local Fork Setup [NOT STARTED]
dependencies: []

**Objective**: Create local fork of goose.nvim at `~/.config/nvim/lua/custom/goose-split.nvim` with Git initialization and remote tracking

**Complexity**: Low

**Tasks**:
- [ ] Create directory `~/.config/nvim/lua/custom/` if not exists (file: mkdir -p)
- [ ] Copy goose.nvim from lazy.nvim cache to custom directory (file: ~/.local/share/nvim/lazy/goose.nvim)
- [ ] Initialize Git repository in fork directory (file: ~/.config/nvim/lua/custom/goose-split.nvim)
- [ ] Add upstream remote: `git remote add upstream https://github.com/azorng/goose.nvim`
- [ ] Create initial commit: `git commit -m "Initial fork for split window support"`
- [ ] Update lazy.nvim configuration to use local fork via `dir` parameter (file: nvim/lua/neotex/plugins/ai/goose/init.lua)
- [ ] Reload lazy.nvim and verify fork loaded: `:Lazy reload goose-split.nvim`

**Testing**:
```bash
# Verify fork directory structure
ls -la ~/.config/nvim/lua/custom/goose-split.nvim/lua/goose/

# Verify Git initialization
cd ~/.config/nvim/lua/custom/goose-split.nvim
git status
git remote -v

# Verify lazy.nvim recognizes fork
nvim
:Lazy
# Check that "goose-split.nvim" shows as "dir" source (not GitHub URL)
```

**Expected Duration**: 1 hour

### Phase 2: Split Window Creation Implementation [NOT STARTED]
dependencies: [1]

**Objective**: Implement `create_split_windows()` function and routing logic to enable basic split-based sidebar with dual-pane layout

**Complexity**: Medium

**Tasks**:
- [ ] Add `create_split_windows()` function to `lua/goose/ui/ui.lua` after line 80 (~60 lines)
- [ ] Implement split creation sequence: `botright vsplit` → set output buffer → `split` → set input buffer
- [ ] Build windows table with same structure as float mode: `input_buf`, `output_buf`, `input_win`, `output_win`
- [ ] Apply standard configurations: `setup_options()`, `setup_autocmds()`, `setup_keymaps()` (reuse existing functions)
- [ ] Return focus to origin window after split creation (file: lua/goose/ui/ui.lua:161)
- [ ] Modify `create_windows()` function to route to `create_split_windows()` when `config.ui.use_splits == true` (file: lua/goose/ui/ui.lua:56)
- [ ] Add temporary placeholder calls for `configure_split_dimensions()` and `apply_split_constraints()` (implement in Phase 3)

**Testing**:
```bash
# Test split creation with minimal config
nvim
:lua require("goose.config").get().ui.use_splits = true
:Goose
# Verify right sidebar appears with dual-pane layout
# Verify closing works: :GooseClose
# Check for orphaned windows/buffers: :ls, :windows
```

**Expected Duration**: 4-5 hours

### Phase 3: Width Persistence Module [NOT STARTED]
dependencies: [2]

**Objective**: Create `width_persistence.lua` module and implement width tracking/restoration across Neovim sessions

**Complexity**: Medium

**Tasks**:
- [ ] Create new file `lua/goose/ui/width_persistence.lua` (~75 lines)
- [ ] Implement `load_width()` function: read from `~/.local/share/nvim/goose_split_width`, validate range (30-200), return default if missing/invalid
- [ ] Implement `save_width()` function: validate width, write to persistence file with `pcall()` wrapper
- [ ] Implement `track_width_change()` function: detect changes via `nvim_win_get_width()`, save if different from `current_width`
- [ ] Implement `get_width()` function: return current width state
- [ ] Add module configuration: `width_file`, `default_width`, `current_width` state variables
- [ ] Test persistence file creation/reading in isolation before integration

**Testing**:
```bash
# Test width persistence module in isolation
nvim
:lua local wp = require("goose.ui.width_persistence")
:lua print(wp.load_width())  -- Should return 80 (default)
:lua wp.save_width(100)
:lua print(wp.load_width())  -- Should return 100

# Verify persistence file
cat ~/.local/share/nvim/goose_split_width
# Should contain: 100

# Test edge cases
:lua wp.save_width(25)  -- Below minimum (30)
:lua print(wp.load_width())  -- Should still be 100 (invalid width rejected)
```

**Expected Duration**: 2-3 hours

### Phase 4: Split Dimension and Constraint Functions [NOT STARTED]
dependencies: [3]

**Objective**: Implement `configure_split_dimensions()` and `apply_split_constraints()` functions to manage width/height and integrate persistence

**Complexity**: Medium

**Tasks**:
- [ ] Implement `configure_split_dimensions()` in `lua/goose/ui/window_config.lua` after line 177 (~25 lines)
- [ ] Integrate width_persistence.load_width() to get saved width (file: lua/goose/ui/window_config.lua)
- [ ] Apply width to both windows via `nvim_win_set_width()` with `pcall()` wrapper
- [ ] Calculate input/output heights: `input_height = floor(total * config.ui.input_height)`, `output_height = total - input_height`
- [ ] Apply heights via `nvim_win_set_height()` with `pcall()` wrapper
- [ ] Implement `apply_split_constraints()` in `lua/goose/ui/window_config.lua` (~25 lines)
- [ ] Set `winfixwidth = true` on both windows to prevent unwanted resizing
- [ ] Create `WinResized` autocmd with `GooseSplitResize` augroup to track width changes
- [ ] Call `width_persistence.track_width_change()` in autocmd callback
- [ ] Modify `setup_resize_handler()` to route split vs float dimension logic based on `config.ui.use_splits` (file: lua/goose/ui/window_config.lua:179)

**Testing**:
```bash
# Test split dimensions with saved width
nvim
:Goose
# Verify sidebar width matches saved value (or default 80)
# Measure with :lua print(vim.api.nvim_win_get_width(0)) when in goose window

# Test height calculation
# Verify input pane ~15% of total, output pane ~85%
# Measure with :lua print(vim.api.nvim_win_get_height(0))

# Test width constraints
# Try resizing editor windows - goose width should remain fixed
<C-w>> (increase width) - should NOT affect goose sidebar

# Test width tracking
# Manually resize goose sidebar: <C-w>|, then adjust with <C-w><
# Close and reopen goose - verify new width persisted
```

**Expected Duration**: 2-3 hours

### Phase 5: Configuration Integration [NOT STARTED]
dependencies: [4]

**Objective**: Add configuration options to `config.lua` and validate split/float mode switching with backward compatibility

**Complexity**: Low

**Tasks**:
- [ ] Add `use_splits = false` to `ui` defaults in `lua/goose/config.lua` line 44
- [ ] Add `sidebar_position = "right"` to `ui` defaults
- [ ] Add `persist_width = true` to `ui` defaults
- [ ] Add `default_split_width = 80` to `ui` defaults
- [ ] Update user configuration file to enable split mode (file: nvim/lua/neotex/plugins/ai/goose/init.lua)
- [ ] Test with `use_splits = true` and `sidebar_position = "left"` to verify left sidebar positioning
- [ ] Test with `use_splits = false` to verify float mode still works (backward compatibility)
- [ ] Test with `persist_width = false` to verify width persistence can be disabled
- [ ] Test with various `default_split_width` values (30, 60, 100, 150)

**Testing**:
```bash
# Test split mode (right sidebar)
nvim
:Goose
# Verify right sidebar appears

# Test left sidebar positioning
# Update config: sidebar_position = "left"
nvim
:Goose
# Verify sidebar appears on left

# Test backward compatibility (float mode)
# Update config: use_splits = false
nvim
:Goose
# Verify floating windows appear (original behavior)

# Test width persistence disabled
# Update config: persist_width = false
nvim
:Goose
# Resize sidebar, close, reopen
# Verify width resets to default (not persisted)

# Test default width variations
# Update config: default_split_width = 120
nvim
# Delete persistence file: rm ~/.local/share/nvim/goose_split_width
:Goose
# Verify sidebar width is 120 columns
```

**Expected Duration**: 1-2 hours

### Phase 6: Testing, Integration, and Documentation [NOT STARTED]
dependencies: [5]

**Objective**: Comprehensive testing across navigation, integration with other plugins, edge cases, and documentation updates

**Complexity**: Medium

**Tasks**:
- [ ] Test native navigation: `<C-h>` to editor, `<C-l>` to goose, `<C-w>w` cycle (verify focus tracking)
- [ ] Test internal navigation: `<Tab>` toggle between input/output panes (verify existing keymap works)
- [ ] Test with neo-tree open simultaneously (verify no conflicts, both sidebars coexist)
- [ ] Test with toggleterm open (verify split positioning and width constraints)
- [ ] Test window handle invalidation: close goose, create new tabs, reopen goose (verify no stale handles)
- [ ] Test VimResized event: resize terminal, verify goose dimensions recalculate correctly
- [ ] Test persistence file corruption: write invalid data to `goose_split_width`, verify graceful fallback
- [ ] Test across multiple Neovim sessions: save width in session 1, verify restored in session 2
- [ ] Document configuration options in fork README.md (use_splits, sidebar_position, persist_width, default_split_width)
- [ ] Create migration guide for existing goose.nvim users switching to fork
- [ ] Add inline code comments documenting split creation sequence and persistence flow
- [ ] Create changelog documenting all modifications to upstream goose.nvim

**Testing**:
```bash
# Navigation tests
nvim
:Goose
<C-l>  # Move to goose sidebar - verify cursor in sidebar
<C-h>  # Move back to editor - verify cursor in editor
<C-l><Tab>  # Move to sidebar, toggle pane - verify toggle works
<Tab>  # Toggle again - verify returns to original pane

# Integration tests with neo-tree
nvim
:Neotree
:Goose
# Verify both sidebars visible, no layout conflicts
<C-h>  # Editor
<C-l>  # Goose
:Neotree close
:Goose
# Verify goose still works after neo-tree closed

# Integration tests with toggleterm
nvim
:ToggleTerm direction=vertical
:Goose
# Verify both terminals coexist
# Resize windows - verify winfixwidth prevents goose resize

# Edge case: window handle invalidation
nvim
:Goose
:tabnew  # Create new tab
:tabprevious  # Return to tab 1
:GooseClose
:Goose  # Reopen - should create fresh windows
# Verify no errors, clean creation

# Edge case: persistence file corruption
echo "invalid" > ~/.local/share/nvim/goose_split_width
nvim
:Goose
# Verify fallback to default width (80), no crashes
# Check logs for graceful error handling

# Persistence across sessions
nvim
:Goose
<C-w>|  # Maximize goose width
<C-w>50<  # Set to ~50 columns
:GooseClose
:q  # Exit Neovim
nvim
:Goose
# Verify width restored to ~50 columns

# VimResized event
nvim
:Goose
# Resize terminal window (via terminal emulator)
# Verify goose dimensions recalculate (heights adjust, width persists)
```

**Expected Duration**: 3-4 hours

## Testing Strategy

### Unit Testing Approach

**Module Isolation Tests** (Phase 3):
- Test `width_persistence.lua` functions independently
- Validate load/save/track functions with mock data
- Test edge cases: missing file, invalid content, permission errors

**Function Integration Tests** (Phase 4):
- Test `configure_split_dimensions()` with various saved widths
- Test `apply_split_constraints()` with manual resizing
- Verify autocmd triggering and width tracking

### Integration Testing Approach

**Plugin Compatibility** (Phase 6):
- Test with neo-tree (both open simultaneously)
- Test with toggleterm (both vertical splits)
- Test with nvim-tree (if still in deprecated config)
- Test with other sidebar plugins (if present)

**Navigation Testing** (Phase 6):
- Native Neovim navigation (`<C-h>`, `<C-l>`, `<C-w>w`)
- Goose internal navigation (`<Tab>` toggle)
- Focus tracking across window transitions
- State preservation when switching tabs

### Regression Testing Approach

**Float Mode Validation** (Phase 5):
- Set `use_splits = false`
- Verify all float mode behavior unchanged
- Test existing user configurations
- Validate no breaking changes to API

**State Management** (Phase 6):
- Verify `state.windows` table structure unchanged
- Test toggle behavior (open/close cycles)
- Test session persistence (last_focused_goose_window)
- Validate cleanup (no orphaned windows/buffers)

### Performance Testing

**Width Persistence** (Phase 3-4):
- Measure file I/O overhead (should be <5ms)
- Test autocmd frequency (ensure not triggered excessively)
- Validate no lag during window resizing

**Window Creation** (Phase 2):
- Measure split creation time (should be <50ms)
- Compare to float creation time (ensure comparable)
- Test with large buffers (ensure no slowdown)

### Test Success Criteria

- All phases pass respective testing sections without errors
- No orphaned windows or buffers after :GooseClose
- Width persists accurately across 10+ Neovim restarts
- No conflicts when 3+ sidebars open simultaneously
- Float mode behavior identical to upstream goose.nvim
- Zero regressions in existing focus/toggle/cleanup logic

## Documentation Requirements

### Code Documentation

**Inline Comments** (All Phases):
- Document `create_split_windows()` function with split sequence explanation
- Comment height calculation formula in `configure_split_dimensions()`
- Explain width persistence flow in `width_persistence.lua` module header
- Document routing logic in modified `create_windows()` function

**Module Headers**:
- Add header to `width_persistence.lua`: "Width persistence for goose.nvim split windows - Pattern adapted from neo-tree"
- Reference neo-tree implementation: `/home/benjamin/.config/nvim/lua/neotex/util/neotree-width.lua`

### User Documentation

**README Updates** (Phase 6):
- Add "Split Window Support" section to fork README.md
- Document all configuration options: `use_splits`, `sidebar_position`, `persist_width`, `default_split_width`
- Provide example configurations for common use cases (right sidebar, left sidebar, float mode)
- Add troubleshooting section for persistence file issues

**Migration Guide** (Phase 6):
- Create `MIGRATION.md` for existing goose.nvim users
- Document steps to switch from upstream to fork
- Explain configuration changes needed to enable split mode
- Provide rollback instructions (switch back to upstream)

**Changelog**:
- Create `CHANGELOG_FORK.md` documenting all modifications
- List files modified with line counts
- Document new features added beyond upstream
- Track upstream version fork was based on (for future merging)

### Architecture Documentation

**Technical Design Document** (Phase 6):
- Document split creation pipeline (routing → creation → dimensions → constraints)
- Explain width persistence architecture (load → apply → track → save)
- Diagram dual-pane layout with ASCII art (already in research report)
- Reference research report for detailed implementation rationale

### Standards Compliance

**Coding Standards** (from CLAUDE.md):
- Follow 2-space indentation (already goose.nvim convention)
- Use `pcall()` for all window/buffer API calls (error handling standard)
- Snake_case for function names (already goose.nvim convention)
- No global variables (use module-local `M` table)

**Testing Standards** (from CLAUDE.md):
- Manual testing via `:Goose` command (no automated test suite in upstream)
- Document test commands in each phase's Testing section
- Validate success criteria before marking phase complete

## Dependencies

### External Dependencies

**Neovim Version**:
- Minimum: 0.8.0 (goose.nvim requirement)
- Recommended: 0.9.0+ (for better window API support)

**Existing Plugins**:
- plenary.nvim (goose.nvim dependency)
- render-markdown.nvim (goose.nvim dependency)

**Optional (for testing)**:
- neo-tree.nvim (integration testing)
- toggleterm.nvim (integration testing)

### Internal Dependencies

**Phase Dependencies**:
- Phase 2 depends on Phase 1 (fork must exist before modifications)
- Phase 3 depends on Phase 2 (persistence module used by split dimensions)
- Phase 4 depends on Phase 3 (dimensions function calls persistence functions)
- Phase 5 depends on Phase 4 (config options control dimension behavior)
- Phase 6 depends on Phase 5 (testing requires complete implementation)

**File Dependencies**:
- `window_config.lua` depends on `width_persistence.lua` (module require)
- `ui.lua` depends on `window_config.lua` (configurator require)
- `ui.lua` depends on `config.lua` (config.get() calls)

**Reference Implementations**:
- Width persistence pattern: `/home/benjamin/.config/nvim/lua/neotex/util/neotree-width.lua`
- Split positioning pattern: `/home/benjamin/.config/nvim/lua/neotex/plugins/ui/neo-tree.lua`
- Toggle pattern: `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/toggleterm.lua`

### Filesystem Dependencies

**Required Directories**:
- `~/.config/nvim/lua/custom/` (for local fork)
- `~/.local/share/nvim/` (for persistence file)

**Created Files**:
- `~/.config/nvim/lua/custom/goose-split.nvim/` (fork directory)
- `~/.local/share/nvim/goose_split_width` (persistence file)

**Modified Files**:
- `nvim/lua/neotex/plugins/ai/goose/init.lua` (lazy.nvim config)

### Git Dependencies

**Remote Tracking**:
- Upstream remote: `https://github.com/azorng/goose.nvim`
- Purpose: Track upstream changes for future merging
- Branch: `main` (track upstream main branch)

**Commit Strategy**:
- Initial commit: "Initial fork for split window support"
- Feature commits: One per phase (e.g., "Add split window creation", "Add width persistence")
- Final commit: "Complete split window implementation with documentation"

## Risk Mitigation

### Risk 1: Window Handle Invalidation

**Scenario**: Window handles become invalid when switching tabs, creating/closing windows, or during plugin conflicts.

**Mitigation**:
- Always validate handles with `nvim_win_is_valid()` before operations (Phase 2)
- Use `pcall()` wrappers around all `nvim_win_*` and `nvim_buf_*` calls (Phase 2, 4)
- Test tab switching extensively in Phase 6
- Implement robust cleanup in `close_windows()` (already exists, no changes needed)

**Validation**: Phase 6 testing includes tab creation/switching edge cases.

### Risk 2: Width Persistence File Corruption

**Scenario**: Persistence file contains invalid data (non-numeric, out of range, corrupted).

**Mitigation**:
- Validate width range (30-200) in `load_width()` (Phase 3)
- Graceful fallback to `config.ui.default_split_width` on read failure (Phase 3)
- Use `pcall()` around `writefile()` to prevent crashes (Phase 3)
- Test corruption scenarios in Phase 6 (write invalid data, delete file, permission errors)

**Validation**: Phase 3 unit tests verify graceful degradation with corrupted input.

### Risk 3: Dual-Pane Split Complexity

**Scenario**: Split creation sequence fails midway, leaving orphaned windows or incorrect layout.

**Mitigation**:
- Test split sequence in isolation before integration (Phase 2)
- Wrap all split creation steps in `pcall()` (Phase 2)
- Save origin window handle and restore focus regardless of success/failure (Phase 2)
- Verify no orphaned windows in cleanup testing (Phase 6)

**Validation**: Phase 2 testing verifies clean creation/cleanup, Phase 6 tests edge cases.

### Risk 4: Integration Conflicts with Other Sidebars

**Scenario**: goose sidebar conflicts with neo-tree, toggleterm, or other sidebar plugins (layout issues, focus stealing, width conflicts).

**Mitigation**:
- Set `winfixwidth = true` to prevent goose from being resized by other plugins (Phase 4)
- Use explicit positioning: `botright`/`topleft` to avoid ambiguous placement (Phase 2)
- Test with neo-tree and toggleterm simultaneously in Phase 6
- Document known integration issues in README (Phase 6)

**Validation**: Phase 6 integration testing verifies coexistence with multiple sidebars.

### Risk 5: Upstream Divergence

**Scenario**: Upstream goose.nvim releases breaking changes, making fork difficult to maintain or merge.

**Mitigation**:
- Keep modifications minimal (~200 lines total, focused in 4 files) (All Phases)
- Track upstream via Git remote (Phase 1)
- Document all changes in `CHANGELOG_FORK.md` (Phase 6)
- Consider submitting PR to upstream after validation (Post-Phase 6)
- Monitor upstream releases for conflicts (ongoing maintenance)

**Validation**: Fork structure allows easy diff against upstream for future merging.

### Risk 6: Backward Compatibility Breaking

**Scenario**: Existing goose.nvim users experience breaking changes when switching to fork.

**Mitigation**:
- Default `use_splits = false` maintains float mode behavior (Phase 5)
- All existing configuration options work unchanged (Phase 5)
- Test float mode extensively to verify no regressions (Phase 5, 6)
- Provide migration guide with explicit opt-in instructions (Phase 6)

**Validation**: Phase 5 regression testing verifies float mode identical to upstream.

## Notes

**Confidence Level**: High
- Well-established patterns from neo-tree, toggleterm references
- Modular goose.nvim architecture minimizes modification scope
- Comprehensive research identified exact implementation points
- Clear mitigation strategies for all identified risks

**Future Enhancements** (out of scope for this plan):
- Horizontal split support (top/bottom sidebar)
- Multi-pane layouts (>2 panes within sidebar)
- Sidebar on both sides simultaneously
- Integration with session management plugins
- Upstream PR contribution

**Related Work**:
- Prior research (994_sidebar_toggle_research_nvim) established feasibility
- This plan builds on detailed implementation research (995_goose_split_sidebar_persist)
- No conflicts with existing Neovim configuration standards
