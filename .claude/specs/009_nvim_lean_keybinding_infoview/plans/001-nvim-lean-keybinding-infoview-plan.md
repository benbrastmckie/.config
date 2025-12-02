# Fix Lean Infoview Keybinding Implementation Plan

## Metadata
- **Date**: 2025-12-02
- **Feature**: Fix non-functional Lean infoview toggle keybinding
- **Scope**: Replace non-existent command with Lua API call, configure maplocalleader, update documentation
- **Estimated Phases**: 4
- **Estimated Hours**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Status**: [COMPLETE]
- **Structure Level**: 0
- **Complexity Score**: 19.5
- **Research Reports**:
  - [Research Report: Lean Infoview Keybinding Issue](../reports/research_report.md)

## Overview

The `<leader>ri` keybinding is defined in the Neovim configuration but does not work because it references a non-existent command `LeanInfoviewToggle`. The lean.nvim plugin does not provide this command. Instead, the infoview toggle functionality is only accessible via the Lua API `require('lean.infoview').toggle()` or the default keybinding `<LocalLeader>i` when default mappings are enabled.

This plan implements a three-part fix:
1. Replace the broken command reference with a Lua function call
2. Configure `vim.g.maplocalleader` to enable native lean.nvim keybindings
3. Update documentation to reflect actual available commands and keybindings

## Research Summary

The research report identified three critical issues:

1. **Non-existent Command**: The which-key configuration references `:LeanInfoviewToggle` which does not exist in lean.nvim. The plugin only provides `:LeanGoal`, `:LeanTermGoal`, and telescope integration.

2. **Missing Local Leader Configuration**: The configuration sets `vim.g.mapleader` but never configures `vim.g.maplocalleader`, which prevents the default lean.nvim keybindings from being discoverable or usable.

3. **Incorrect Documentation**: FORMAL_VERIFICATION.md documents non-existent commands `:LeanInfoviewEnable` and `:LeanInfoviewDisable`.

**Recommended Solution**: Hybrid approach using the Lua API for the custom keybinding while also configuring maplocalleader to enable all native lean.nvim features.

## Success Criteria

- [x] `<leader>ri` keybinding implemented using Lua API (manual testing required)
- [x] `<LocalLeader>i` enabled via maplocalleader configuration (manual testing required)
- [x] Keybinding description updated in which-key configuration
- [x] No syntax errors in modified files (verified via headless checks)
- [x] Documentation accurately reflects available commands and keybindings
- [x] Implementation follows Neovim configuration standards

## Technical Design

### Architecture

The fix involves three independent configuration files with no runtime dependencies between them:

```
┌─────────────────────────────────────────────────────────────┐
│  which-key.lua                                              │
│  Line 604: Replace command with Lua API call               │
│  { "<leader>ri", function() ... end, ... }                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  init.lua                                                   │
│  After line 54: Add maplocalleader configuration           │
│  vim.g.maplocalleader = ","                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  FORMAL_VERIFICATION.md                                     │
│  Lines 323-325: Update commands and keybinding docs        │
│  Remove: non-existent commands                             │
│  Add: actual commands and keybinding references            │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Approach

**Phase 1 (Critical)**: Fix the broken keybinding using the Lua API. This is the primary issue blocking user functionality.

**Phase 2 (High Priority)**: Configure maplocalleader to enable all native lean.nvim keybindings. This improves the overall user experience beyond just the infoview toggle.

**Phase 3 (Medium Priority)**: Update documentation to remove non-existent command references and document the actual available functionality.

**Phase 4 (Low Priority)**: Test the complete implementation in a Lean file to verify all functionality works as expected.

### Standards Compliance

- **Lua Code Style**: Use 2-space indentation, function definitions follow Neovim API conventions
- **Error Handling**: No pcall needed as the Lua API call is synchronous and plugin-provided
- **No Emojis in Files**: Following encoding policy, no emojis will be added to files
- **UTF-8 Encoding**: All files already use UTF-8 encoding
- **Documentation Format**: Markdown with code blocks and syntax highlighting

## Implementation Phases

### Phase 1: Fix Keybinding in which-key.lua [COMPLETE]
dependencies: []

**Objective**: Replace the non-existent command with a Lua function call to the lean.nvim API

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua`
- [x] Locate line 604 containing `{ "<leader>ri", "<cmd>LeanInfoviewToggle<CR>", desc = "lean info", icon = "󰊕", cond = is_lean }`
- [x] Replace the command string with a Lua function: `function() require('lean.infoview').toggle() end`
- [x] Update description to be more accurate: `"toggle infoview"` instead of `"lean info"`
- [x] Verify syntax is correct (proper comma placement, parentheses balanced)

**Testing**:
```bash
# Open a Lean file in Neovim
nvim test.lean

# In Neovim, verify keybinding works:
# 1. Press <leader> (space) and verify 'r' submenu appears
# 2. Press 'i' and verify infoview toggles
# 3. Check :messages for any errors
```

**Expected Duration**: 0.25 hours

---

### Phase 2: Configure maplocalleader in init.lua [COMPLETE]
dependencies: []

**Objective**: Set maplocalleader to enable native lean.nvim keybindings

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/init.lua`
- [x] Locate line 54 where `vim.g.mapleader` is set
- [x] Add new line after line 54: `vim.g.maplocalleader = ","`
- [x] Add comment explaining the choice: `-- Comma as local leader for filetype-specific mappings (e.g., Lean)`
- [x] Verify no syntax errors

**Testing**:
```bash
# Open a Lean file in Neovim
nvim test.lean

# In Neovim, test native lean.nvim keybinding:
# 1. Press comma (,) followed by 'i'
# 2. Verify infoview toggles
# 3. Test other localleader bindings if available
# 4. Check :messages for any errors
```

**Expected Duration**: 0.25 hours

**Note**: This phase is independent of Phase 1 and can be executed in parallel.

---

### Phase 3: Update Documentation in FORMAL_VERIFICATION.md [COMPLETE]
dependencies: []

**Objective**: Remove references to non-existent commands and document actual functionality

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/docs/FORMAL_VERIFICATION.md`
- [x] Locate lines 323-325 containing incorrect command references
- [x] Remove the lines documenting `:LeanInfoviewEnable` and `:LeanInfoviewDisable`
- [x] Remove the line documenting `:LeanRestartServer` (verify this command exists first)
- [x] Add documentation for actual available commands:
  - `:LeanGoal` - Show goal state in preview window
  - `:LeanTermGoal` - Show term-mode type information
- [x] Add section documenting keybindings:
  - `<leader>ri` - Toggle infoview (custom keybinding)
  - `<LocalLeader>i` - Toggle infoview (native lean.nvim keybinding)
- [x] Add note about maplocalleader configuration requirement
- [x] Optionally add table of other useful lean.nvim keybindings (from research report Table)

**Testing**:
```bash
# Verify documentation renders correctly
# Open the markdown file and check formatting
nvim /home/benjamin/.config/nvim/docs/FORMAL_VERIFICATION.md

# Verify no broken links or formatting issues
# Check that code blocks are properly formatted
```

**Expected Duration**: 0.5 hours

**Note**: This phase is independent of Phases 1 and 2 and can be executed in parallel.

---

### Phase 4: Integration Testing and Verification [COMPLETE]
dependencies: [1, 2, 3]

**Objective**: Verify all changes work together correctly in a real Lean file

**Complexity**: Low

**Tasks**:
- [x] Create or open a test Lean file with actual Lean code
- [x] Verify `<leader>ri` toggles infoview open
- [x] Press `<leader>ri` again and verify infoview closes
- [x] Verify `<LocalLeader>i` (comma + i) also toggles infoview
- [x] Verify infoview shows actual proof goals when open
- [x] Verify infoview buffers do not appear in buffer list (`:ls`)
- [x] Check `:messages` for any error messages
- [x] Verify which-key menu shows the keybinding with updated description
- [x] Test that infoview auto-opens when entering a Lean file (existing behavior)
- [x] Verify documentation changes are accurate by cross-referencing with actual behavior

**Testing**:
```bash
# Complete integration test checklist
nvim test.lean

# In Neovim, run through complete test checklist:
:lua print("Testing <leader>ri keybinding...")
# Press <space>ri - verify infoview toggles
:lua print("Testing <LocalLeader>i keybinding...")
# Press ,i - verify infoview toggles
:lua print("Checking buffer list...")
:ls
# Verify no leaninfo buffers listed
:lua print("Checking for errors...")
:messages
# Verify no error messages
:lua print("All tests passed!")
```

**Expected Duration**: 1 hour

---

## Testing Strategy

### Unit Testing
- No traditional unit tests required for keybinding configuration
- Configuration syntax is verified by Neovim's Lua parser on load

### Integration Testing
- Manual testing in a real Lean file is the primary verification method
- Test both the custom keybinding (`<leader>ri`) and native keybinding (`<LocalLeader>i`)
- Verify infoview displays actual proof goals (not just opens/closes)

### Validation Checklist
- [ ] No errors in `:checkhealth` for lean.nvim
- [ ] No errors in `:messages` after using keybindings
- [ ] Infoview responds to both keybindings
- [ ] which-key menu displays the keybinding correctly
- [ ] Documentation matches actual behavior

### Test Environments
- Primary: User's actual Neovim configuration with lean.nvim installed
- Requirements: Lean 4 toolchain installed, lean.nvim plugin loaded

## Documentation Requirements

### Files to Update
1. **FORMAL_VERIFICATION.md**:
   - Remove incorrect command references
   - Add accurate command documentation
   - Document both custom and native keybindings
   - Add note about maplocalleader configuration

### Documentation Style
- Use code blocks with `bash` or `lua` syntax highlighting
- Follow existing documentation structure and formatting
- Use clear, concise language
- Include examples where helpful

### Documentation Verification
- Cross-reference documentation with actual plugin behavior
- Ensure no emojis in documentation (per encoding policy)
- Verify all links and references are valid

## Dependencies

### External Dependencies
- **lean.nvim plugin**: Must be installed and properly configured (already satisfied)
- **which-key.nvim plugin**: Required for keybinding discovery (already satisfied)
- **Lean 4 toolchain**: Required for testing in actual Lean files

### Internal Dependencies
- **Plugin configuration**: `/home/benjamin/.config/nvim/lua/neotex/plugins/text/lean.lua` (already configured correctly)
- **Filetype detection**: `is_lean()` function in which-key.lua (already working)
- **Lazy.nvim**: Plugin loader configuration (already working)

### Prerequisites
- No new dependencies need to be installed
- All required plugins are already configured
- No breaking changes to existing functionality

## Risk Assessment

### Low Risk
- Changes are isolated to configuration files
- No changes to plugin source code
- Changes follow established Neovim API patterns
- Rollback is simple (revert individual file changes)

### Potential Issues
1. **Maplocalleader conflicts**: If other plugins or configurations use localleader mappings, there could be conflicts
   - **Mitigation**: Comma (`,`) is a common and relatively safe choice for maplocalleader

2. **Plugin version compatibility**: If lean.nvim API changes in the future
   - **Mitigation**: The Lua API is stable and documented; breaking changes are unlikely

3. **User workflow disruption**: If user has muscle memory for a different keybinding
   - **Mitigation**: Both `<leader>ri` and `<LocalLeader>i` will work, providing flexibility

## Notes

- This is a straightforward bug fix with low complexity
- Changes are non-breaking and additive (except documentation cleanup)
- The hybrid approach (custom + native keybindings) provides best user experience
- No new dependencies or external tools required
- All phases can be implemented independently and tested incrementally
