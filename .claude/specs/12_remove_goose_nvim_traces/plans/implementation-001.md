# Implementation Plan: Task #12

**Task**: Remove all goose.nvim traces from Neovim configuration
**Version**: 001
**Created**: 2026-01-11
**Language**: lua

## Overview

Systematically remove all goose.nvim plugin files, references, documentation, and related configuration from the Neovim setup. The approach uses a phased strategy: first remove core plugin files, then clean up dependent configuration, update documentation, and finally handle external files. Each phase builds on the previous to ensure no orphaned references remain.

## Phases

### Phase 1: Core Plugin File Deletion

**Estimated effort**: 15 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Delete the entire goose plugin directory and all custom modules
2. Delete the goose health check module
3. Delete goose-related test files
4. Remove goose from the AI plugin loader

**Files to delete**:
- `nvim/lua/neotex/plugins/ai/goose/` - Entire directory (init.lua, picker/, README.md)
- `nvim/lua/goose/health.lua` - Health check module
- `nvim/tests/picker/goose_terminal_execution_spec.lua` - Terminal execution tests
- `nvim/tests/picker/goose_execution_unit_spec.lua` - Unit tests

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/init.lua` - Remove "goose" from ai_plugins list (line 47)

**Steps**:
1. Delete `nvim/lua/neotex/plugins/ai/goose/` directory recursively
2. Delete `nvim/lua/goose/` directory (contains only health.lua)
3. Delete test files `nvim/tests/picker/goose_*_spec.lua`
4. Edit `nvim/lua/neotex/plugins/ai/init.lua` to remove "goose" from ai_plugins array

**Verification**:
- No goose directories exist in nvim/lua/
- No goose test files exist in nvim/tests/
- ai/init.lua no longer references goose

---

### Phase 2: UI and Keymap Cleanup

**Estimated effort**: 15 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Remove goose filetypes from lualine disabled list
2. Delete commented goose keymaps from which-key
3. Update comments that reference goose

**Files to modify**:
- `nvim/lua/neotex/plugins/ui/lualine.lua` - Remove goose-input/goose-output entries and update comment
- `nvim/lua/neotex/plugins/editor/which-key.lua` - Delete commented Goose AI commands block (lines 356-421)

**Steps**:
1. Edit lualine.lua:
   - Remove "goose-input" from disabled_filetypes.statusline (line 38)
   - Remove "goose-output" from disabled_filetypes.statusline (line 39)
   - Remove "goose-input" from disabled_filetypes.winbar (line 42)
   - Remove "goose-output" from disabled_filetypes.winbar (line 43)
   - Update comment on line 46 to remove goose reference
2. Edit which-key.lua:
   - Delete the entire commented Goose AI commands block (lines 356-421)

**Verification**:
- Grep for "goose" in lualine.lua returns no matches
- Grep for "goose" in which-key.lua returns no matches

---

### Phase 3: Documentation Updates

**Estimated effort**: 30 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Remove Goose sections from primary documentation
2. Update all README files to remove goose references

**Files to modify**:
- `nvim/docs/AI_TOOLING.md` - Remove Goose AI Agent section
- `nvim/docs/MAPPINGS.md` - Remove Goose AI Agent keymaps section
- `nvim/README.md` - Remove Goose link from AI section
- `nvim/lua/neotex/README.md` - Remove goose directory reference
- `nvim/lua/neotex/plugins/README.md` - Remove goose directory description
- `nvim/lua/neotex/plugins/ai/README.md` - Remove goose documentation and links
- `nvim/lua/neotex/plugins/ai/claude/README.md` - Remove Goose comparisons and references
- `nvim/lua/neotex/util/README.md` - Update or remove goose example

**Steps**:
1. Edit AI_TOOLING.md to remove the Goose AI Agent section (lines 40-44)
2. Edit MAPPINGS.md to remove the entire Goose AI Agent section (lines 136-159)
3. Edit nvim/README.md to remove Goose line from AI plugins list
4. Edit neotex/README.md to remove goose directory line
5. Edit plugins/README.md to remove goose directory line
6. Edit ai/README.md to remove goose/init.lua docs, goose link, and goose commands note
7. Edit claude/README.md to remove Goose references and comparisons
8. Edit util/README.md to update notify example (change goose to claude or generic)

**Verification**:
- Grep for "goose" in nvim/docs/ returns no matches
- Grep for "goose" in nvim/**/README.md returns no matches

---

### Phase 4: Sync Module Cleanup

**Estimated effort**: 20 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Evaluate sync.lua for goose directory handling
2. Remove or refactor .goose references as appropriate

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Clean up goose references

**Steps**:
1. Read sync.lua to understand the .goose directory handling
2. Fix module path comment on line 1 (currently references goose path)
3. Evaluate whether .goose directory handling should be:
   - Removed entirely (if only for goose recipes)
   - Kept as-is (if still used for project settings)
   - Refactored (if partially useful)
4. If removing, delete the following goose-related code:
   - .goose/settings paths (lines 415-416)
   - .goose directory creation (lines 428-429)
   - .goose subdirectory definitions (lines 522-541)
   - .goose directory handling (lines 641-642, 961, 1123, 1145)
5. Test that sync functionality still works for .claude directories

**Verification**:
- Module path comment is correct
- Sync functionality works for Claude artifacts
- No orphaned .goose references remain

---

### Phase 5: External Files and Final Cleanup

**Estimated effort**: 10 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Remove external goose configuration files
2. Clean up lazy-lock.json via lazy sync
3. Verify complete removal

**Files to delete**:
- `~/.config/.goosehints` - Goose project standards file
- `~/.config/.goose/` - Goose recipes and MCP servers directory

**Steps**:
1. Delete ~/.config/.goosehints file
2. Delete ~/.config/.goose/ directory recursively
3. Run `nvim --headless -c "Lazy sync" -c "qa"` to update lazy-lock.json
4. Verify goose.nvim entry is removed from lazy-lock.json
5. Start Neovim and verify no errors on startup
6. Verify :checkhealth shows no goose-related entries

**Verification**:
- .goosehints file does not exist
- .goose directory does not exist
- lazy-lock.json has no goose.nvim entry
- Neovim starts without errors
- Remaining AI plugins (Claude, OpenCode) work correctly

---

## Dependencies

- None (self-contained cleanup task)

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| sync.lua breaks after goose removal | Medium | Low | Test sync functionality after Phase 4 |
| Other plugins depend on goose | Medium | Very Low | Research phase identified no dependencies |
| Missed goose references | Low | Low | Final grep verification in Phase 5 |

## Success Criteria

- [ ] No files/directories containing "goose" in name under nvim/lua/
- [ ] No test files containing "goose" in name under nvim/tests/
- [ ] Grep for "goose" in nvim/ returns 0 matches
- [ ] lazy-lock.json does not contain goose.nvim
- [ ] Neovim starts without errors
- [ ] :ClaudeCode and OpenCode commands work correctly
- [ ] External .goose files removed from ~/.config/

## Rollback Plan

1. Git revert the implementation commits
2. Run `git checkout HEAD~N -- nvim/` to restore deleted files
3. Run `Lazy sync` to restore goose.nvim to lazy-lock.json
4. Restore .goosehints and .goose/ from backup if needed
