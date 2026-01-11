# Implementation Plan: Task #13

**Task**: Refactor leader-ac management tool
**Version**: 001
**Created**: 2026-01-11
**Language**: lua

## Overview

Refactor the `<leader>ac` Claude artifacts picker to align with the refactored .claude/ skills-based architecture. Focus on removing dead goose.nvim code, adding skills support, and simplifying the implementation. Target: net reduction of ~960 lines while adding new functionality.

## Phases

### Phase 1: Remove Dead Sync Code

**Estimated effort**: 30 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Remove deprecated goose.nvim sync infrastructure from sync.lua
2. Simplify sync operations to essential functionality only
3. Keep working: load_all_globally, update_artifact_from_global

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Major cleanup

**Steps**:
1. Remove `initialize_settings_from_template` function (deprecated, returns false)
2. Remove interactive sync state management (create_interactive_state, prompt_for_conflict, show_diff_for_file)
3. Remove run_interactive_sync function
4. Simplify load_all_globally to 2 strategies: "Add new" and "Replace all"
5. Remove clean_and_replace_all complexity (not needed for simple sync)
6. Keep sync_files, count_actions, count_by_depth utilities
7. Keep update_artifact_from_global function

**Verification**:
- `<leader>ac` opens picker without errors
- [Load All Artifacts] entry works with simplified 2-option dialog
- Ctrl-u (update from global) still works

---

### Phase 2: Remove Agent Infrastructure

**Estimated effort**: 30 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Remove agent scanning from parser.lua (agents/ directory doesn't exist)
2. Remove standalone agents section from entries.lua
3. Remove agent preview from previewer.lua
4. Remove agent-related mappings from init.lua

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Remove agent scanning
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Remove agent entries
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua` - Remove agent preview
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua` - Clean up agent references

**Steps**:
1. In parser.lua:
   - Remove scan_agents_directory function
   - Remove parse_agents_with_fallback function
   - Remove build_agent_dependencies function
   - Remove agents from get_extended_structure return
2. In entries.lua:
   - Remove format_agent function
   - Remove create_standalone_agents_entries function
   - Remove get_agents_for_command function
   - Remove agent entries from create_commands_entries
   - Remove standalone agents from create_picker_entries
3. In previewer.lua:
   - Remove preview_agent function
   - Remove agent case from create_command_previewer
4. In init.lua:
   - Remove agent-specific action handling

**Verification**:
- Picker opens without errors
- No agent-related entries appear
- Commands still display correctly

---

### Phase 3: Add Skills Support

**Estimated effort**: 45 minutes
**Status**: [COMPLETED]

**Objectives**:
1. Add skill discovery to parser.lua
2. Add skill entries to entries.lua
3. Add skill preview to previewer.lua
4. Enable skill editing via Enter/Ctrl-e

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Add skill scanning
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Add skill entries
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua` - Add skill preview
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/init.lua` - Add skill action handling

**Steps**:
1. In parser.lua, add scan_skills_directory:
   ```lua
   function M.scan_skills_directory(skills_dir)
     -- Scan for */SKILL.md pattern
     -- Parse frontmatter: name, description, allowed-tools, context
     -- Return array of skill metadata
   end
   ```
2. Add parse_skills_with_fallback for local/global merging
3. Update get_extended_structure to include skills
4. In entries.lua, add create_skills_entries:
   - Format: `* ├─ skill-name    Description`
   - Include is_local indicator
5. Add skills section to create_picker_entries (after Commands)
6. In previewer.lua, add preview_skill:
   - Show name, description, allowed-tools
   - Show context file references
   - Show file path and local/global status
7. In init.lua, add skill handling to select_default:
   - skill entry_type opens SKILL.md for editing

**Verification**:
- [Skills] section appears in picker with 8 skills
- Skills show correct metadata in preview
- Enter on skill opens SKILL.md file
- Ctrl-e on skill opens SKILL.md file

---

### Phase 4: Simplify Categories and Test

**Estimated effort**: 30 minutes
**Status**: [NOT STARTED]

**Objectives**:
1. Remove TTS Files section (integrated into hooks)
2. Update category order
3. Test all operations work correctly
4. Update README documentation

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Remove TTS, reorder
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua` - Remove TTS preview
- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Remove TTS scanning
- `nvim/lua/neotex/plugins/ai/claude/README.md` - Update documentation

**Steps**:
1. In parser.lua:
   - Remove scan_tts_files function
   - Remove parse_tts_files_with_fallback function
   - Remove tts_files from get_extended_structure
2. In entries.lua:
   - Remove format_tts_file function
   - Remove create_tts_entries function
   - Remove TTS from create_picker_entries
   - Update category order in create_picker_entries:
     ```
     1. Special entries (bottom)
     2. Docs
     3. Lib
     4. Templates
     5. Scripts
     6. Tests
     7. Skills (NEW)
     8. Hooks
     9. Commands (top)
     ```
3. In previewer.lua:
   - Remove preview_tts_file function
   - Remove tts_file case from create_command_previewer
4. Test operations:
   - Open picker with `<leader>ac`
   - Verify categories display correctly
   - Test Enter on each entry type
   - Test Ctrl-e, Ctrl-l, Ctrl-u, Ctrl-s
   - Test [Load All Artifacts]
5. Update README.md:
   - Update directory structure
   - Update category list
   - Remove agent/TTS references

**Verification**:
- Picker shows correct categories in order
- All keyboard shortcuts work
- Load All syncs commands, skills, hooks, docs, lib, scripts, tests
- README accurately describes current functionality

---

## Dependencies

- None - self-contained refactoring

## Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Break existing functionality | High | Low | Test each operation after changes |
| Miss edge cases in sync | Medium | Low | Keep core sync_files function unchanged |
| Skill discovery misses files | Low | Low | Test with existing 8 skills |

## Success Criteria

- [ ] Picker opens without errors
- [ ] [Commands] section shows all 9 commands
- [ ] [Skills] section shows all 8 skills
- [ ] [Hooks] section shows registered hooks
- [ ] [Docs], [Lib], [Scripts], [Tests] sections work
- [ ] Enter opens file for editing on all entry types
- [ ] Ctrl-e opens file for editing
- [ ] [Load All Artifacts] syncs with 2-option dialog
- [ ] Net code reduction of ~800+ lines
- [ ] No TTS or Agent references remain

## Rollback Plan

Git revert to commit before implementation started. All changes are in nvim/lua/neotex/plugins/ai/claude/commands/ directory.
