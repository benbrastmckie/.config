# Implementation Plan: Add Root Files to Leader-ac Picker

- **Task**: 24 - add_root_files_to_leader_ac_picker
- **Status**: [COMPLETE]
- **Effort**: 1-2 hours
- **Dependencies**: Task 23 (agents support) completed
- **Research Inputs**: None (follow-up task, patterns established in codebase)
- **Artifacts**: plans/implementation-001.md (this file)
- **Standards**: plan-format.md, status-markers.md, artifact-management.md, tasks.md
- **Type**: neovim
- **Lean Intent**: false

## Overview

Add support for root-level `.claude/` configuration files to the `<leader>ac` telescope picker. This includes `.gitignore`, `README.md`, `CLAUDE.md`, and `settings.local.json`. These files are critical for configuration portability and should be accessible alongside commands, hooks, skills, and agents in the picker interface.

## Goals & Non-Goals

**Goals**:
- Add a new [Root Files] section to the picker displaying root-level configuration files
- Support view and edit operations for these files
- Support sync operation to copy global root files to local project
- Handle both project-local and global versions with local override priority
- Maintain consistent display format with existing sections (prefix for local, tree characters)

**Non-Goals**:
- Adding all root-level files (only the four specified files)
- Modifying the sync behavior for other artifact types
- Adding new keyboard shortcuts (use existing view/edit/sync bindings)

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| File type mismatch | L | L | Use appropriate metadata parsers for each file type |
| Sync conflicts with settings.local.json | M | M | Handle JSON files like other artifacts - use replace/copy logic |
| Display ordering issues | L | L | Follow established insertion order pattern (reverse for descending sort) |

## Implementation Phases

### Phase 1: Add Root Files Scanner Function [COMPLETED]

**Goal**: Create scanning function in parser.lua to discover root-level configuration files

**Tasks**:
- [ ] Add `scan_root_files` function to parser.lua that checks for existence of specific files:
  - `.gitignore`
  - `README.md`
  - `CLAUDE.md`
  - `settings.local.json`
- [ ] Implement local/global fallback logic (project first, then ~/.config/.claude/)
- [ ] Return array of file metadata with `name`, `filepath`, `is_local`, `description` fields
- [ ] Add `root_files` to the return structure of `get_extended_structure()`

**Timing**: 30 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua`

**Verification**:
- Function returns expected file list when called
- Local files override global files correctly
- Files that don't exist are not included

---

### Phase 2: Add Root Files Entry Creator [COMPLETED]

**Goal**: Create entry generation function in entries.lua for root files section

**Tasks**:
- [ ] Add `create_root_files_entries` function to entries.lua
- [ ] Generate entries with appropriate entry_type ("root_file")
- [ ] Use consistent display formatting (prefix for local, tree character for hierarchy)
- [ ] Add descriptions based on file type:
  - `.gitignore` - "Git ignore patterns"
  - `README.md` - "Documentation"
  - `CLAUDE.md` - "Claude configuration"
  - `settings.local.json` - "Local settings"
- [ ] Add [Root Files] heading entry
- [ ] Insert entries into `create_picker_entries` function in correct order (after Commands, before Agents)

**Timing**: 30 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua`

**Verification**:
- Root files section appears in picker
- Entries display with correct formatting
- Local files show asterisk prefix

---

### Phase 3: Add Sync Support for Root Files [COMPLETED]

**Goal**: Enable sync operation to copy global root files to local project

**Tasks**:
- [ ] Add `root_files` scanning to `scan_all_artifacts` function in sync.lua
- [ ] Add `root_files` sync execution in `execute_sync` function
- [ ] Update `subdir_map` in `update_artifact_from_global` to include `root_file` type
- [ ] Handle root files as direct children of `.claude/` (empty subdir path)
- [ ] Test sync includes root files in count and report

**Timing**: 30 minutes

**Files to modify**:
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua` (if needed for root file patterns)

**Verification**:
- Load All Artifacts includes root files
- Individual root file sync works via update_artifact_from_global
- Sync report shows root files count

---

### Phase 4: Integration Testing [COMPLETED]

**Goal**: Verify end-to-end functionality of root files in picker

**Tasks**:
- [ ] Test picker displays [Root Files] section with correct files
- [ ] Test view operation opens file in buffer
- [ ] Test edit operation opens file for editing
- [ ] Test sync operation copies global to local
- [ ] Test local/global display indicator works correctly
- [ ] Verify no regressions in other picker sections

**Timing**: 20 minutes

**Files to modify**: None (testing only)

**Verification**:
- All operations work as expected
- No visual regressions in picker display

## Testing & Validation

- [ ] Run `:lua require("neotex.plugins.ai.claude.commands.parser").get_extended_structure()` and verify `root_files` field
- [ ] Open `<leader>ac` picker and verify [Root Files] section appears
- [ ] Select a root file and press Enter to view
- [ ] Select a root file and press `<C-e>` to edit
- [ ] Run Load All Artifacts and verify root files are included
- [ ] Test from both global directory (~/.config) and a project directory

## Artifacts & Outputs

- `nvim/lua/neotex/plugins/ai/claude/commands/parser.lua` - Updated with root files scanner
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/entries.lua` - Updated with root files entries
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua` - Updated with root files sync
- `specs/24_add_root_files_to_leader_ac_picker/plans/implementation-001.md` - This plan
- `specs/24_add_root_files_to_leader_ac_picker/summaries/implementation-summary-YYYYMMDD.md` - Summary after completion

## Rollback/Contingency

If implementation causes issues:
1. Revert changes to the three Lua files
2. Root files section will not appear in picker
3. Other picker functionality remains unaffected
4. No data loss risk - this is additive functionality only
