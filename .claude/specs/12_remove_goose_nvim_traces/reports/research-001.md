# Research Report: Task #12

**Task**: Remove all goose.nvim traces from Neovim configuration
**Date**: 2026-01-11
**Focus**: Comprehensive identification of all goose.nvim references

## Summary

The goose.nvim plugin and its associated infrastructure have extensive traces throughout the Neovim configuration. This includes the main plugin configuration, custom picker modules, health checks, keymaps, documentation, tests, and references in various README files. Additionally, there are related files in ~/.config/.goose/ and ~/.config/.goosehints that should be considered for removal.

## Findings

### 1. Core Plugin Files (DELETE)

**Main Plugin Configuration**:
- `nvim/lua/neotex/plugins/ai/goose/init.lua` - Main goose.nvim plugin spec (131 lines)

**Custom Picker System** (entire directory):
- `nvim/lua/neotex/plugins/ai/goose/picker/init.lua` - Main picker entry point
- `nvim/lua/neotex/plugins/ai/goose/picker/discovery.lua` - Recipe discovery
- `nvim/lua/neotex/plugins/ai/goose/picker/execution.lua` - Recipe execution
- `nvim/lua/neotex/plugins/ai/goose/picker/metadata.lua` - Metadata parsing
- `nvim/lua/neotex/plugins/ai/goose/picker/previewer.lua` - Telescope previewer
- `nvim/lua/neotex/plugins/ai/goose/picker/modification.lua` - Recipe modification (if exists)
- `nvim/lua/neotex/plugins/ai/goose/picker/README.md` - Picker documentation
- `nvim/lua/neotex/plugins/ai/goose/README.md` - Main goose README

**Health Check**:
- `nvim/lua/goose/health.lua` - Custom health check module (123 lines)

**Test Files**:
- `nvim/tests/picker/goose_terminal_execution_spec.lua` - Terminal execution tests
- `nvim/tests/picker/goose_execution_unit_spec.lua` - Unit tests

### 2. Plugin Registration (EDIT)

**AI Plugin Loader**:
- `nvim/lua/neotex/plugins/ai/init.lua` - Line 47: Remove "goose" from ai_plugins list

### 3. Lock File Entry (EDIT)

**lazy-lock.json**:
- Line 14: `"goose.nvim": { "branch": "main", "commit": "49d189d87af12af5c8915804d2462b20c178a6bd" }` - Will be auto-removed on next lazy sync

### 4. UI Integration (EDIT)

**Lualine Configuration** (`nvim/lua/neotex/plugins/ui/lualine.lua`):
- Lines 38-39, 42-43, 46: Remove "goose-input", "goose-output" from disabled_filetypes
- Line 46 comment mentions goose - update or remove

### 5. Keymaps (EDIT - Already Commented)

**Which-Key** (`nvim/lua/neotex/plugins/editor/which-key.lua`):
- Lines 356-421: Goose AI commands block (already commented out as of 2025-12-10)
- This commented code block should be deleted entirely

### 6. Documentation (EDIT)

**Primary Documentation**:
- `nvim/docs/AI_TOOLING.md`:
  - Lines 40-44: Goose AI Agent section header and description
  - Link to goose README

- `nvim/docs/MAPPINGS.md`:
  - Lines 136-159: Entire "Goose AI Agent" section with keymap documentation
  - References to goose throughout

**README Files**:
- `nvim/README.md`:
  - Line 52: Goose link in AI section

- `nvim/lua/neotex/README.md`:
  - Line 76: goose directory reference

- `nvim/lua/neotex/plugins/README.md`:
  - Line 78: goose directory description

- `nvim/lua/neotex/plugins/ai/README.md`:
  - Lines 49-52: goose/init.lua documentation
  - Line 70: goose directory link
  - Lines 173-174: Goose commands note

- `nvim/lua/neotex/plugins/ai/claude/README.md`:
  - Lines 16, 19, 21: Goose references and comparisons
  - Line 533: Goose link in related documentation

- `nvim/lua/neotex/util/README.md`:
  - Line 84: Example using notify.ai for goose

### 7. Related Code References (EDIT)

**Claude Sync Module** (`nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`):
- Line 1: Module path comment references goose
- Lines 415-416: .goose/settings paths
- Lines 428-429, 522-541, 641-642, 961, 1123, 1145: Multiple .goose directory references
- This appears to be a sync module that handles both .goose and .claude directories

### 8. External Files (CONSIDER)

**~/.config/.goosehints** (302 lines):
- Complete project standards file for Goose recipes
- Derived from Claude Code documentation

**~/.config/.goose/** directory:
- docs/
- mcp-servers/
- README.md
- recipes/
- scripts/

**~/.config/.old_claude/** directory:
- Multiple goose-related task artifacts in specs/ subdirectories

## Recommendations

### Phase 1: Core Plugin Removal
1. Delete entire `nvim/lua/neotex/plugins/ai/goose/` directory
2. Delete `nvim/lua/goose/health.lua`
3. Delete test files: `nvim/tests/picker/goose_*_spec.lua`
4. Remove "goose" from ai_plugins list in `nvim/lua/neotex/plugins/ai/init.lua`

### Phase 2: UI and Keymap Cleanup
1. Remove goose-input/goose-output from lualine disabled_filetypes
2. Delete commented goose keymaps from which-key.lua
3. Update lualine comment mentioning goose

### Phase 3: Documentation Updates
1. Remove Goose sections from AI_TOOLING.md and MAPPINGS.md
2. Update all README files to remove goose references
3. Update claude/README.md to remove Goose comparisons

### Phase 4: Related Code Cleanup
1. Update sync.lua to remove .goose directory handling (or keep if still useful for .claude)
2. Evaluate whether sync.lua module path comment needs fixing

### Phase 5: External Files (Optional - User Decision)
1. Consider removing ~/.config/.goosehints
2. Consider removing ~/.config/.goose/ directory
3. Old specs in .old_claude/ are already archived

## References

- goose.nvim repository: https://github.com/azorng/goose.nvim
- lazy-lock.json line 14: goose.nvim commit 49d189d

## Next Steps

1. Create implementation plan with phased approach
2. Execute deletion of core plugin files first
3. Update dependent files
4. Run lazy sync to clean lock file
5. Verify no runtime errors on Neovim startup
6. Test that remaining AI plugins (Claude, OpenCode) work correctly
