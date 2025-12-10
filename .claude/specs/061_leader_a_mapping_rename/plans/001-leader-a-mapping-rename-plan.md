# Leader A Mapping Rename Implementation Plan

## Metadata
- **Date**: 2025-12-09 (Revised)
- **Feature**: Reorganize `<leader>a` AI/Assistant namespace with lowercase-only mappings and comprehensive Goose command coverage
- **Status**: [COMPLETE]
- **Estimated Hours**: 4-6 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Current Mappings Audit](/home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/reports/001-current-mappings-audit.md)
  - [Mapping Renaming Strategy](/home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/reports/002-mapping-renaming-strategy.md)
  - [Unmapped Commands Inventory](/home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/reports/003-unmapped-commands-inventory.md)
  - [Avante Mapping Removal](/home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/reports/1-the_removal_of_all_avante_mapp.md)

## Overview

This plan reorganizes the `<leader>a` AI/Assistant key mapping namespace to achieve three primary objectives:

1. **Eliminate Capital Letter Violations**: Remove 4 capital letter mappings (aP, aA, aC, aR) that violate lowercase naming convention
2. **Optimize Key Ergonomics**: Reassign Avante's prime mappings (aa, ae, am, ap, ax) to high-frequency Goose commands after Avante removal
3. **Comprehensive Command Coverage**: Map 15 currently unmapped Goose commands (60% of total commands lack mappings)

### Current State
- 22 total `<leader>a` mappings defined in which-key.lua
- 4 mappings use capital letters (18% violation rate)
- 5 Avante mappings occupy prime ergonomic positions (being removed)
- Only 10/25 Goose commands have mappings (40% coverage)
- Multiple namespace conflicts prevent adding unmapped commands

### Target State
- 100% lowercase mapping compliance (0 capital letters)
- Goose toggle on double-tap `<leader>aa` pattern (optimal ergonomics)
- All 25 Goose commands mapped with mnemonic-based keys
- Non-AI commands (TTS, Yolo) moved to appropriate namespaces
- Claude commands consolidated to free up namespace

### Research Findings Summary
- **Capital Letter Violations**: aP (Lectic provider), aA/aC (Goose modes), aR (Goose recipe)
- **Avante Prime Keys**: aa, ae, am, ap, ax all available after removal
- **Available Lowercase Keys**: h, j, k, p, u, w, x, z (8 unused keys)
- **Unmapped Command Categories**: Focus/Pane (2), Session (3), Execution (3), Config (1), Diff/Review (5)

## Success Criteria

- [ ] All 4 capital letter mappings (aP, aA, aC, aR) replaced with lowercase alternatives
- [ ] Goose toggle moved from `<leader>ag` to `<leader>aa` (double-tap pattern)
- [ ] All 15 unmapped Goose commands have key mappings in `<leader>a` namespace
- [ ] TTS toggle commented out (user preference to disable)
- [ ] Claude worktree commands moved to `<leader>g` namespace (git-related)
- [ ] No mapping conflicts remain (verified via which-key conflict detection)
- [ ] Updated which-key.lua passes validation with no errors
- [ ] All new mappings use mnemonic-friendly keys for discoverability
- [ ] Documentation updated to reflect new mapping scheme

## Implementation Phases

### Phase 0: Remove Avante Mappings [COMPLETE]
dependencies: []

**Objective**: Comment out all Avante keybindings to free up prime ergonomic keys (aa, ae, am, ap, ax) for Goose command optimization

**Complexity**: Low

**Tasks**:

1. Comment out Avante section in which-key.lua
   - [x] Open /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua
   - [x] Update section header (line 260): Add "(REMOVED: 2025-12-09 - Avante plugin no longer used)"
   - [x] Comment out `<leader>aa` mapping (line 261): `-- { "<leader>aa", "<cmd>AvanteAsk<CR>", desc = "avante ask", icon = "󰚩" },`
   - [x] Comment out `<leader>ae` mapping (line 262): `-- { "<leader>ae", "<cmd>AvanteEdit<CR>", desc = "avante edit", icon = "󱇧", mode = { "v" } },`
   - [x] Comment out `<leader>ap` mapping (line 263): `-- { "<leader>ap", "<cmd>AvanteProvider<CR>", desc = "avante provider", icon = "󰜬" },`
   - [x] Comment out `<leader>am` mapping (line 264): `-- { "<leader>am", "<cmd>AvanteModel<CR>", desc = "avante model", icon = "󰡨" },`
   - [x] Comment out `<leader>ax` mapping (line 265): `-- { "<leader>ax", "<cmd>MCPHubOpen<CR>", desc = "mcp hub", icon = "󰚩" },`

2. Verify syntax and functionality
   - [x] Save file and reload config (`:source %`)
   - [x] Execute `:checkhealth which-key` to verify no syntax errors
   - [x] Test `<leader>a` popup shows remaining AI commands (Claude, Goose, Lectic)
   - [x] Verify no errors in `:messages` log related to undefined Avante commands
   - [x] Confirm aa, ae, ap, am, ax keys are now available for reassignment

**Testing**:
```bash
# Verify which-key.lua syntax
nvim --headless -c "luafile /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua" -c "quit" 2>&1 | grep -i error

# Check that Avante mappings are commented
grep -E "^\s*--.*<leader>a[aepmx].*Avante" /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua || echo "ERROR: Avante mappings not commented"

# Verify 5 Avante keys are freed
test $(grep -c "^\s*--.*<leader>a[aepmx].*Avante\|MCP" /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua) -eq 5 || echo "WARNING: Expected 5 commented Avante mappings"
```

**Expected Outcome**: 5 prime ergonomic keys (aa, ae, am, ap, ax) freed in `<leader>a` namespace, ready for Goose command reassignment

**Expected Duration**: 0.5 hours

---

### Phase 1: Remove Capital Letter Violations [COMPLETE]
dependencies: [0]

**Objective**: Replace all uppercase letter mappings with lowercase mnemonic alternatives

**Tasks**:

1. Replace Lectic provider mapping
   - [x] Change `<leader>aP` to `<leader>ak` (konfig/config provider)
   - [x] Update which-key.lua line 271
   - [x] Verify conditional `is_lectic` preserved

2. Replace Goose mode mappings
   - [x] Change `<leader>aA` to `<leader>au` (auto/unassisted mode)
   - [x] Change `<leader>aC` to `<leader>ah` (human/chat mode)
   - [x] Update which-key.lua lines 369-370
   - [x] Verify mode command calls (`GooseModeAuto`, `GooseModeChat`)

3. Replace Goose recipe mapping
   - [x] Change `<leader>aR` to `<leader>aj` (job/recipe runner)
   - [x] Update which-key.lua line 371-373
   - [x] Verify recipe picker function call preserved

4. Validation checkpoint
   - [x] Run nvim with updated config
   - [x] Execute `:checkhealth which-key` for conflicts
   - [x] Test all 4 remapped commands functionality
   - [x] Verify which-key popup shows new lowercase mappings

**Expected Outcome**: Zero capital letter mappings in `<leader>a` namespace, all 4 commands functional with mnemonic lowercase keys

**Estimated Time**: 1 hour

---

### Phase 2: Reorganize Non-AI Commands [COMPLETE]
dependencies: [1]

**Objective**: Comment out TTS toggle and move Claude worktree commands out of `<leader>a` to free up namespace for Goose commands

**Tasks**:

1. Comment out TTS toggle
   - [x] Comment out `<leader>at` mapping in which-key.lua (line ~274)
   - [x] Add explanatory comment: "(DISABLED: 2025-12-09 - User preference)"
   - [x] Verify no syntax errors after commenting

2. Move Claude worktree commands to `<leader>g` namespace
   - [x] Remove `<leader>av` (view worktrees) from which-key.lua (line ~258)
   - [x] Remove `<leader>aw` (create worktree) from which-key.lua (line ~259)
   - [x] Remove `<leader>ar` (restore worktree) from which-key.lua (line ~260)
   - [x] Add `<leader>gv` mapping in `<leader>g` (git) group - "view claude worktrees"
   - [x] Add `<leader>gw` mapping in `<leader>g` group - "create claude worktree"
   - [x] Add `<leader>gr` mapping in `<leader>g` group - "restore claude worktree"
   - [x] Verify worktree commands functional in new namespace

3. Validation checkpoint
   - [x] Test Claude worktree commands at `<leader>gv`, `<leader>gw`, `<leader>gr`
   - [x] Verify old mappings removed (av, aw, ar)
   - [x] Verify TTS mapping commented out (at)
   - [x] Check which-key popups show correct grouping

**Expected Outcome**: 3 mappings moved (Claude worktrees), 1 commented out (TTS), freeing up: at, av, aw, ar

**Estimated Time**: 1 hour

---

### Phase 3: Optimize Goose Ergonomics with Avante Keys [COMPLETE]
dependencies: [2]

**Objective**: Reassign high-frequency Goose commands to Avante's prime ergonomic positions (aa, ae, am, ap, ax)

**Tasks**:

1. Move Goose toggle to double-tap pattern
   - [x] Remove existing `<leader>ag` mapping (goose toggle)
   - [x] Add `<leader>aa` mapping for `Goose` command (toggle)
   - [x] Update description to "goose toggle"
   - [x] Test double-tap ergonomics in practice

2. Assign Goose input to prime position
   - [x] Move `<leader>ai` (goose input) to `<leader>ae` (edit/entry mnemonic)
   - [x] Update which-key.lua mapping
   - [x] Verify `GooseOpenInput` command call

3. Assign mode selector to unified key
   - [x] Create mode picker function (similar to provider picker)
   - [x] Add `<leader>am` mapping for mode picker (auto/chat selection)
   - [x] Remove old `<leader>au` and `<leader>ah` mode mappings (from Phase 1)
   - [x] Implement which-key picker UI for mode selection
   - [x] Test mode switching via picker

4. Assign provider/backend to consistent key
   - [x] Move existing `<leader>ab` (provider status) to `<leader>ap` (provider mnemonic)
   - [x] Update which-key.lua mapping
   - [x] Verify provider picker functionality

5. Assign new session command to available key
   - [x] Add `<leader>ax` mapping for `GooseOpenInputNewSession`
   - [x] Update description to "goose new session"
   - [x] Test new session creation workflow

6. Validation checkpoint
   - [x] Test Goose toggle at `<leader>aa` (verify double-tap feel)
   - [x] Test Goose input at `<leader>ae`
   - [x] Test mode picker at `<leader>am` (both auto and chat modes)
   - [x] Test provider picker at `<leader>ap`
   - [x] Test new session at `<leader>ax`
   - [x] Verify old mappings removed (ag, ai, ab, au, ah)

**Expected Outcome**: 5 most-used Goose commands on optimal ergonomic keys (aa, ae, am, ap, ax)

**Estimated Time**: 2 hours

---

### Phase 4: Map All Unmapped Goose Commands [COMPLETE]
dependencies: [3]

**Objective**: Add key mappings for 15 currently unmapped Goose commands using freed namespace and mnemonic keys

**Tasks**:

<!-- NOTE: I don't need these task 1 changes -->

1. Map Focus/Pane Management commands
   - [x] Add `<leader>at` for `GooseToggleFocus` - "goose toggle focus"
   - [x] Add `<leader>an` for `GooseTogglePane` - "goose toggle pane"
   - [x] Verify focus and pane toggle functionality

2. Map Session Management commands
   - [x] Add `<leader>az` for `GooseSelectSession` - "goose select session"
   - [x] Add `<leader>aj` for `GooseInspectSession` - "goose inspect session (json)"
   - [x] Verify session picker and JSON inspection

3. Map Execution commands
   - [x] Add `<leader>ar` for `GooseRun` - "goose run (continue session)"
   - [x] Add `<leader>au` for `GooseRunNewSession` - "goose run (new session)"
   - [x] Add `<leader>ak` for `GooseStop` - "goose stop/kill"
   - [x] Verify prompt execution and stop functionality

4. Map Configuration commands
   - [x] Add `<leader>aw` for `GooseOpenConfig` - "goose config file"
   - [x] Verify config file opens in editor

5. Map Diff/Review Navigation commands
   - [x] Keep existing `<leader>ad` for `GooseDiff` - "goose diff"
   - [x] Add `<leader>dn` for `GooseDiffNext` - "goose diff next"
   - [x] Add `<leader>dp` for `GooseDiffPrev` - "goose diff prev"
   - [x] Add `<leader>dx` for `GooseDiffClose` - "goose diff close"
   - [x] Add `<leader>dz` for `GooseRevertAll` - "goose revert all"
   - [x] Add `<leader>dh` for `GooseRevertThis` - "goose revert this file"
   - [x] Add `<leader>dw` for `GooseSetReviewBreakpoint` - "goose set breakpoint"
   - [x] Verify all diff navigation and revert commands

6. Map remaining commands
   - [x] Add `<leader>ao` for `GooseOpenOutput` - "goose output"
   - [x] Add `<leader>af` for `GooseToggleFullscreen` - "goose fullscreen"
   - [x] Add `<leader>aq` for `GooseClose` - "goose quit"
   - [x] Keep `<leader>aj` for recipe picker (moved from aR in Phase 1)

7. Validation checkpoint
   - [x] Create comprehensive test checklist of all 25 Goose commands
   - [x] Test each command mapping individually
   - [x] Verify which-key popup shows all new mappings
   - [x] Check for any mapping conflicts (`:verbose map <leader>a`)
   - [x] Verify mnemonic consistency across all mappings

**Expected Outcome**: 100% Goose command coverage (25/25 commands mapped), organized by function category

**Estimated Time**: 2 hours

---

### Phase 5: Documentation and Validation [COMPLETE]
dependencies: [4]

**Objective**: Document new mapping scheme and verify no regressions

**Tasks**:

1. Update which-key.lua inline documentation
   - [x] Add section header comment for `<leader>a` AI/Assistant group
   - [x] Document mapping organization principles (lowercase only, mnemonic-based)
   - [x] Add category comments (Core, Focus, Session, Execution, Config, Diff)

2. Create migration guide
   - [x] Document all mapping changes in CHANGELOG or KEYBINDINGS.md
   - [x] Create before/after mapping table for reference
   - [x] List deprecated mappings (old capital letter keys)
   - [x] Highlight breaking changes (commented out TTS, moved Claude worktree commands)

3. Update keybinding documentation
   - [x] Update nvim/docs/KEYBINDINGS.md with new `<leader>a` mappings
   - [x] Update `<leader>g` section for Claude worktree commands
   - [x] Document mnemonic naming convention
   - [x] Note TTS toggle disabled (commented out)

4. Add mapping convention rule to CLAUDE.md
   - [x] Add explicit rule: "All `<leader>` mappings MUST use lowercase letters"
   - [x] Document rationale (consistency, ergonomics, muscle memory)
   - [x] Add enforcement recommendation (linting or code review)

5. Comprehensive validation
   - [x] Run `:checkhealth which-key` for conflicts
   - [x] Test all 25 Goose commands with new mappings
   - [x] Test moved Claude worktree commands
   - [x] Test conditional Lectic mappings (verify no conflicts)
   - [x] Verify which-key popup accuracy for all groups
   - [x] Check for any vim errors during startup

6. Create test script for mapping validation
   - [x] Write Lua test that verifies all expected mappings exist
   - [x] Test that old mappings are removed (capital letters, moved commands)
   - [x] Add to nvim test suite for regression prevention

**Expected Outcome**: Complete documentation of new mapping scheme, validated 100% functional with no conflicts

**Estimated Time**: 1 hour

---

## Dependencies

- **Phase 1 depends on Phase 0**: Avante mappings must be removed before reassigning capital letter violations
- **Phase 2 depends on Phase 1**: Capital letter violations must be resolved before reorganizing namespace
- **Phase 3 depends on Phase 2**: Non-AI commands must be moved to free up prime keys for Goose
- **Phase 4 depends on Phase 3**: Ergonomic optimization must complete before mapping remaining commands
- **Phase 5 depends on Phase 4**: All mappings must exist before documentation and validation

## Risk Assessment

### Risk 1: Muscle Memory Disruption
- **Impact**: High - Users have existing muscle memory for current mappings
- **Mitigation**: Create comprehensive migration guide, consider adding temporary alias mappings for transition period
- **Likelihood**: Certain

### Risk 2: Mapping Conflicts in Edge Cases
- **Impact**: Medium - Filetype-conditional mappings (Lectic) may create unexpected conflicts
- **Mitigation**: Thorough testing in different filetypes, use which-key conflict detection
- **Likelihood**: Low

### Risk 3: Mode Picker Implementation Complexity
- **Impact**: Medium - Creating unified mode picker (Phase 3, Task 3) may be more complex than individual mappings
- **Mitigation**: Reuse existing provider picker implementation pattern, fallback to individual mappings if needed
- **Likelihood**: Medium

### Risk 4: Documentation Drift
- **Impact**: Low - Documentation may not reflect actual mappings over time
- **Mitigation**: Add automated test to verify documentation matches actual mappings
- **Likelihood**: Low

## Testing Strategy

### Unit Testing
- Test each remapped command individually after changes
- Verify command execution produces expected behavior
- Check which-key popup displays correct descriptions

### Integration Testing
- Test command sequences (e.g., open Goose → run recipe → view diff)
- Verify no conflicts between `<leader>a` and other leader groups
- Test conditional mappings in different filetypes

### Regression Testing
- Verify all non-remapped commands still function
- Check global toggles (Ctrl-c for Claude, Ctrl-g for Avante) unaffected
- Test which-key group navigation

### Validation Testing
- Run `:checkhealth which-key` for conflict detection
- Use `:verbose map <leader>a` to verify no duplicate bindings
- Test startup performance (ensure no degradation from additional mappings)

## Rollback Plan

If critical issues discovered during implementation:

1. **Git Revert**: Revert which-key.lua changes to previous commit
2. **Partial Rollback**: Keep Phase 1 changes (capital letter fixes), revert Phases 2-4
3. **Staged Rollout**: Implement only Phases 1-2 initially, defer Phases 3-4 for future iteration
4. **Alias Bridge**: Add temporary alias mappings for old keys during transition period

## Notes

- **Avante Removal**: This plan assumes Avante mappings are already removed or being removed concurrently
- **Lectic Preservation**: Conditional Lectic mappings (`<leader>al`, `<leader>an`, `<leader>ak`) are preserved with filetype conditions
- **Mnemonic Strength**: Some proposed mnemonics are weak (e.g., "k" for konfig, "j" for job), but limited by available lowercase keys
- **User Preferences**: TTS toggle (`<leader>at`) commented out per user request; Yolo mode (`<leader>ay`) unchanged
- **Session/Config Mappings**: GooseSelectSession mapped to `<leader>az`, GooseOpenConfig mapped to `<leader>aw` to avoid conflicts with Claude commands

## Completion Criteria

This plan is complete when:

1. All 4 capital letter violations eliminated (100% lowercase compliance)
2. All 25 Goose commands have key mappings (100% coverage, up from 40%)
3. Goose toggle uses ergonomic `<leader>aa` double-tap pattern
4. TTS toggle commented out and Claude worktree commands moved to `<leader>g` namespace
5. No mapping conflicts detected by which-key
6. All documentation updated to reflect new mapping scheme
7. Comprehensive test suite validates all mappings functional
8. Migration guide created for users with existing muscle memory
