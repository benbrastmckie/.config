# NOTE Tag Analysis Research Report

## Metadata
- **Date**: 2025-12-09
- **Agent**: research-specialist
- **Topic**: Plan revision insights for research the NOTE tags in order to revise the plan accordingly
- **Report Type**: plan revision analysis
- **Workflow Type**: research-and-revise

## Executive Summary

The user has added 4 NOTE tags to the plan indicating they want to preserve certain existing mappings rather than moving them as the plan currently specifies. Analysis reveals that keeping `<leader>ay`, `<leader>as`, and `<leader>ac` will create namespace conflicts in Phase 4 where the plan attempts to reassign these keys to Goose commands. Additionally, commenting out `<leader>at` instead of moving it simplifies Phase 2. The validation checkpoint in Phase 2 Task 5 should be removed as it tests moved commands that will no longer be moved. Overall impact: 3 namespace conflicts, 1 simplified task, 1 unnecessary validation removed.

## Findings

### Finding 1: NOTE on Line 142 - Comment Out TTS Toggle Instead of Moving
- **Description**: User wants to comment out `<leader>at` (TTS toggle) rather than moving it to `<leader>rt` as Phase 2 Task 1 currently specifies.
- **Location**: Plan line 142, Phase 2 Task 1 (lines 144-148)
- **Current Plan Action**: Move `<leader>at` from `<leader>a` namespace to `<leader>r` namespace as `<leader>rt`
- **User Preference**: Comment out `<leader>at` mapping entirely (no relocation)
- **Evidence**:
  ```markdown
  <!-- NOTE: just comment out <leader>at instead of moving it -->

  1. Move TTS toggle to `<leader>r` namespace
     - [ ] Remove `<leader>at` mapping from which-key.lua (line ~274)
     - [ ] Add `<leader>rt` mapping in `<leader>r` (run/settings) group
  ```
- **Impact**:
  - **Phase 2 Task 1 Simplification**: Task becomes simpler - just comment out the mapping, no need to add `<leader>rt`
  - **Phase 4 Namespace**: Frees up `<leader>at` key for Goose commands (currently allocated to `GooseToggleFocus` in Phase 4 Task 1)
  - **No Conflicts**: Phase 4 already plans to use `<leader>at` for `GooseToggleFocus`, so this change aligns with Phase 4's intentions
  - **Documentation Impact**: Phase 5 documentation (lines 309-332) needs updating to reflect TTS is commented out, not moved

### Finding 2: NOTE on Line 150 - Preserve Yolo Mode Toggle
- **Description**: User wants to keep `<leader>ay` (Yolo mode toggle) unchanged rather than moving it to `<leader>ry` as Phase 2 Task 2 currently specifies.
- **Location**: Plan line 150, Phase 2 Task 2 (lines 152-156)
- **Current Plan Action**: Move `<leader>ay` from `<leader>a` namespace to `<leader>r` namespace as `<leader>ry`
- **User Preference**: Keep `<leader>ay` in its current location (no relocation)
- **Evidence**:
  ```markdown
  <!-- NOTE: don't change <leader>ay -->

  2. Move Yolo mode toggle to `<leader>r` namespace
     - [ ] Remove `<leader>ay` mapping from which-key.lua (line ~275)
     - [ ] Add `<leader>ry` mapping in `<leader>r` group
  ```
- **Current Mapping**: Line 304-360 of which-key.lua shows `<leader>ay` toggles `--dangerously-skip-permissions` flag
- **Impact**:
  - **Phase 2 Task 2 Removal**: Entire task should be removed from Phase 2
  - **No Phase 4 Conflicts**: Phase 4 does not allocate `<leader>ay` to any Goose command, so no namespace conflict
  - **Namespace Utilization**: `<leader>ay` remains occupied by Yolo toggle, unavailable for future Goose command expansion
  - **Success Criteria Impact**: Line 48 success criterion "TTS and Yolo toggles moved to `<leader>r` namespace" is no longer accurate

### Finding 3: NOTE on Line 167 - Preserve Claude Session and Command Mappings
- **Description**: User wants to keep both `<leader>as` (Claude sessions) and `<leader>ac` (Claude commands) unchanged rather than moving them to `<leader>cs` and `<leader>cc` as Phase 2 Task 4 currently specifies.
- **Location**: Plan line 167, Phase 2 Task 4 (lines 169-173)
- **Current Plan Action**: Move `<leader>as` to `<leader>cs` and `<leader>ac` to `<leader>cc`
- **User Preference**: Keep both mappings at their current locations
- **Evidence**:
  ```markdown
  <!-- NOTE: I don't want to change <leader>as or <leader>ac -->

  4. Consolidate Claude session/commands
     - [ ] Move `<leader>as` (claude sessions) to `<leader>cs`
     - [ ] Move `<leader>ac` (claude commands) to `<leader>cc`
  ```
- **Current Mappings**:
  - Line 255: `<leader>as` - `resume_session()` function - "claude sessions"
  - Lines 248-254: `<leader>ac` - `ClaudeCommands` command / send visual selection - "claude commands"
- **Impact**:
  - **Phase 2 Task 4 Removal**: Entire task should be removed from Phase 2
  - **CRITICAL Phase 4 Conflicts**: Creates 2 namespace conflicts:
    1. **Conflict 1**: Phase 4 Task 2 (line 253) plans to add `<leader>as` for `GooseSelectSession` - BLOCKED by existing Claude sessions mapping
    2. **Conflict 2**: Phase 4 Task 4 (line 264) plans to add `<leader>ac` for `GooseOpenConfig` - BLOCKED by existing Claude commands mapping
  - **Namespace Starvation**: Keeping both Claude mappings prevents 2 planned Goose commands from being mapped
  - **Mnemonic Collision**: Both `<leader>as` and `<leader>ac` have semantic meaning for Claude ("sessions", "commands") but also make sense for Goose ("select session", "config")

### Finding 4: NOTE on Line 175 - Validation Checkpoint No Longer Necessary
- **Description**: User notes that Phase 2 Task 5 validation checkpoint is not necessary given that TTS, Yolo, and Claude commands are no longer being moved.
- **Location**: Plan line 175, Phase 2 Task 5 (lines 177-183)
- **Current Plan Action**: Validate moved commands at `<leader>rt`, `<leader>ry`, `<leader>gv/gw/gr`, `<leader>cs/cc`
- **User Preference**: Remove or simplify validation checkpoint since most moves are cancelled
- **Evidence**:
  ```markdown
  <!-- NOTE: the following should not be necessary -->

  5. Validation checkpoint
     - [ ] Test TTS toggle at `<leader>rt`
     - [ ] Test Yolo mode at `<leader>ry`
     - [ ] Test Claude worktree commands at `<leader>gv`, `<leader>gw`, `<leader>gr`
     - [ ] Test Claude session/commands at `<leader>cs`, `<leader>cc`
  ```
- **Impact**:
  - **Phase 2 Task 5 Simplification**: Only need to validate Claude worktree moves (gv/gw/gr), not TTS/Yolo/Claude sessions/commands
  - **Phase 2 Expected Outcome Update**: Line 186 says "7 mappings moved out" - should be reduced to "3 mappings moved out" (only av, aw, ar for worktrees)
  - **Testing Efficiency**: Reduces validation overhead by eliminating tests for commands that aren't being moved

## Namespace Conflict Analysis

### Critical Conflict Table

| Key | Current Owner | Current Purpose | Phase 4 Planned Assignment | Conflict Status |
|-----|---------------|-----------------|----------------------------|-----------------|
| `<leader>at` | TTS toggle | Toggle text-to-speech | `GooseToggleFocus` | **RESOLVED** - User wants TTS commented out, freeing the key |
| `<leader>ay` | Yolo toggle | Toggle dangerous permissions | (not allocated) | **NO CONFLICT** - No Phase 4 plan for this key |
| `<leader>as` | Claude sessions | Resume Claude session | `GooseSelectSession` | **CONFLICT** - User keeps Claude, blocks Goose session picker |
| `<leader>ac` | Claude commands | Open Claude commands picker | `GooseOpenConfig` | **CONFLICT** - User keeps Claude, blocks Goose config |

### Conflict Resolution Options

#### Option 1: Remap Goose Commands to Alternative Keys
**Approach**: Keep Claude mappings as user requested, reassign affected Goose commands to unused keys

**Changes Required**:
- `GooseSelectSession`: Move from planned `<leader>as` to alternative (e.g., `<leader>az` - "session with Z pattern")
- `GooseOpenConfig`: Move from planned `<leader>ac` to alternative (e.g., `<leader>ak` - "konfig", reusing Phase 1's mnemonic)

**Conflicts**:
- `<leader>ak` already planned for `GooseStop` ("kill") in Phase 4 Task 3 (line 260)
- `<leader>az` not currently allocated, appears available

**Pros**:
- Honors user preference to keep Claude mappings
- Minimal disruption to existing muscle memory
- Only requires reassigning 2 Goose commands to alternative keys

**Cons**:
- Creates weaker mnemonics (e.g., "z" for session is non-intuitive)
- May require cascading reassignments if alternative keys already allocated

#### Option 2: Keep Goose Mappings as Planned, Override User Preference
**Approach**: Proceed with Phase 2 Task 4 as originally planned, explaining the namespace conflict to user

**Pros**:
- Maintains stronger mnemonics (`as` = sessions, `ac` = commands/config)
- Follows original research-backed strategy from report 002-mapping-renaming-strategy.md
- Provides cleaner namespace organization with all Claude commands in `<leader>c`

**Cons**:
- Violates user's explicit NOTE preference
- Disrupts existing muscle memory for Claude commands
- Requires user to relearn 2 frequently-used mappings

#### Option 3: Hybrid Approach - Move Only `<leader>ac`, Keep `<leader>as`
**Approach**: Compromise by keeping Claude sessions but moving Claude commands to `<leader>cc`

**Changes Required**:
- Keep `<leader>as` for Claude sessions (honors user preference)
- Move `<leader>ac` to `<leader>cc` (frees key for `GooseOpenConfig`)
- Reassign `GooseSelectSession` from `<leader>as` to `<leader>az` or other available key

**Pros**:
- Partially honors user preference (keeps most-used Claude sessions)
- Allows `GooseOpenConfig` to use semantic `<leader>ac` mapping
- Only disrupts 1 existing Claude mapping instead of 2

**Cons**:
- Still violates part of user's NOTE (moving `<leader>ac`)
- Creates inconsistent Claude namespace (sessions in `<leader>a`, commands in `<leader>c`)
- Requires reassigning `GooseSelectSession` to weaker mnemonic

**RECOMMENDED**: Option 1 - Remap Goose Commands to Alternative Keys

## Revised Task Recommendations

### Phase 2 Task Revisions

**Task 1 (Line 144-148): Comment Out TTS Toggle** - SIMPLIFY
```markdown
1. Comment out TTS toggle
   - [ ] Comment out `<leader>at` mapping in which-key.lua (line ~274)
   - [ ] Add explanatory comment: "TTS toggle removed, use alternative TTS management"
   - [ ] Verify which-key popup no longer shows `<leader>at`
```

**Task 2 (Line 152-156): Move Yolo Mode Toggle** - REMOVE ENTIRELY
- Rationale: User NOTE explicitly requests no change to `<leader>ay`
- No replacement task needed

**Task 3 (Line 158-165): Move Claude Worktree Commands** - KEEP AS-IS
- Rationale: No user NOTE conflicts with this task
- Continue as planned with gv/gw/gr mappings

**Task 4 (Line 169-173): Consolidate Claude Session/Commands** - REMOVE ENTIRELY
- Rationale: User NOTE explicitly requests no change to `<leader>as` or `<leader>ac`
- No replacement task needed

**Task 5 (Line 177-183): Validation Checkpoint** - SIMPLIFY
```markdown
5. Validation checkpoint
   - [ ] Test Claude worktree commands at `<leader>gv`, `<leader>gw`, `<leader>gr`
   - [ ] Verify old mappings removed (av, aw, ar no longer exist)
   - [ ] Check which-key popup shows correct grouping for `<leader>g`
```

### Phase 4 Task Revisions

**Task 1 (Line 247-250): Map Focus/Pane Management** - KEEP AS-IS
- `<leader>at` will be freed by commenting out TTS, allowing `GooseToggleFocus` as planned
- `<leader>an` has no conflicts

**Task 2 (Line 252-255): Map Session Management** - REVISE FOR CONFLICT
```markdown
2. Map Session Management commands
   - [ ] Add `<leader>az` for `GooseSelectSession` - "goose session (z-pattern)"
   - [ ] Add `<leader>aj` for `GooseInspectSession` - "goose inspect session (json)"
   - [ ] Verify session picker and JSON inspection
```
- **Change**: Move `GooseSelectSession` from `<leader>as` (conflicts with Claude sessions) to `<leader>az` (available)
- **Impact**: Weakens mnemonic (z has no semantic meaning for sessions), but avoids user preference conflict

**Task 3 (Line 257-261): Map Execution Commands** - KEEP AS-IS
- No conflicts with user NOTEs
- All three keys (ar, au, ak) available or will be available after Phase 2

**Task 4 (Line 263-265): Map Configuration Commands** - REVISE FOR CONFLICT
```markdown
4. Map Configuration commands
   - [ ] Add `<leader>aw` for `GooseOpenConfig` - "goose write config"
   - [ ] Verify config file opens in editor
```
- **Change**: Move `GooseOpenConfig` from `<leader>ac` (conflicts with Claude commands) to `<leader>aw` (freed by moving Claude worktree in Phase 2 Task 3)
- **Alternative Consideration**: Could use `<leader>ak` ("konfig" mnemonic from Phase 1), but that's already allocated to `GooseStop` in Task 3
- **Impact**: Weakens mnemonic slightly ("write" is less intuitive than "config"), but maintains some semantic meaning

**Task 5-7 (Lines 267-288): Remaining Mappings** - KEEP AS-IS
- No conflicts with user NOTEs
- Diff navigation, output, fullscreen, quit, and recipe mappings unaffected

### Phase 5 Documentation Revisions

**Task 2 (Line 308-313): Create Migration Guide** - UPDATE SCOPE
```markdown
2. Create migration guide
   - [ ] Document all mapping changes in CHANGELOG or KEYBINDINGS.md
   - [ ] Create before/after mapping table for reference
   - [ ] List deprecated mappings (old capital letter keys)
   - [ ] Highlight breaking changes:
     - TTS toggle commented out (no replacement)
     - Claude worktree commands moved to `<leader>g`
     - Goose commands expanded with new mappings
```

**Task 3 (Line 315-320): Update Keybinding Documentation** - REMOVE `<leader>r` SECTION
```markdown
3. Update keybinding documentation
   - [ ] Update nvim/docs/KEYBINDINGS.md with new `<leader>a` mappings
   - [ ] Update `<leader>g` section for Claude worktree commands
   - [ ] Document that `<leader>as` and `<leader>ac` remain for Claude (not moved)
   - [ ] Document that `<leader>ay` remains for Yolo toggle (not moved)
   - [ ] Document that `<leader>at` is commented out (no TTS mapping)
   - [ ] Document mnemonic naming convention
```

## Expected Outcome Revisions

### Phase 2 Expected Outcome (Line 186)
**Current**: "7 mappings moved out of `<leader>a` namespace, freeing up: at, ay, av, aw, ar, as, ac"

**Revised**: "3 mappings moved out of `<leader>a` namespace (Claude worktrees to `<leader>g`), 1 mapping commented out (TTS toggle). Freed keys: av, aw, ar (moved), at (commented). Preserved keys: ay (Yolo), as (Claude sessions), ac (Claude commands)."

### Success Criteria Revisions (Lines 43-54)

**Criterion 4 (Line 48)**: "TTS and Yolo toggles moved to `<leader>r` namespace (run/settings)"
- **Revised**: "TTS toggle commented out (no replacement mapping)"

**Criterion 5 (Line 49)**: "Claude worktree commands moved to `<leader>g` namespace (git-related)"
- **Keep as-is** - This is still accurate

**New Criterion**: "Claude session and command mappings preserved at `<leader>as` and `<leader>ac` per user preference"

## Alternative Key Availability Analysis

### Currently Unused Lowercase Keys in `<leader>a` Namespace

Based on the plan and current mappings, available keys after Phase 0-3 completion:

| Key | Status After Phase 3 | Available for Phase 4 |
|-----|----------------------|----------------------|
| `<leader>at` | Freed (TTS commented out) | YES - Allocated to `GooseToggleFocus` |
| `<leader>av` | Freed (worktree moved to gv) | YES - Unallocated |
| `<leader>aw` | Freed (worktree moved to gw) | YES - Can use for `GooseOpenConfig` |
| `<leader>ar` | Freed (worktree moved to gr) | NO - Allocated to `GooseRun` |
| `<leader>ak` | Newly available (was aP) | NO - Allocated to `GooseStop` |
| `<leader>ah` | Newly available (was aC) | YES - Unallocated |
| `<leader>au` | Newly available (was aA) | NO - Allocated to `GooseRunNewSession` |
| `<leader>az` | Never allocated | YES - Can use for `GooseSelectSession` |

### Recommended Key Reassignments for Conflict Resolution

1. **`GooseSelectSession`**: Use `<leader>az` (available, no prior allocation)
   - Mnemonic weakness: "z" has no semantic connection to "session"
   - Alternative: `<leader>ah` ("history" mnemonic) - but also weak

2. **`GooseOpenConfig`**: Use `<leader>aw` (freed by worktree move)
   - Mnemonic: "write config" (weak but plausible)
   - Alternative: `<leader>av` (freed by worktree move) - "view config" mnemonic

## Risk Assessment

### Risk 1: Weaker Mnemonics for Goose Commands
- **Impact**: Medium - Users may find `<leader>az` (session) and `<leader>aw` (config) less intuitive than `<leader>as` and `<leader>ac`
- **Mitigation**: Document the mappings clearly, consider adding which-key descriptions that emphasize the command purpose
- **Likelihood**: High - Mnemonic weakness is inherent to the compromise

### Risk 2: User Expects All NOTEs to Be Honored
- **Impact**: Low - Analysis shows all 4 NOTEs can be honored with alternative key assignments
- **Mitigation**: Present Option 1 (Remap Goose Commands) as the plan revision that honors all user preferences
- **Likelihood**: Low - Conflicts are resolvable without overriding user preferences

### Risk 3: Namespace Exhaustion for Future Goose Commands
- **Impact**: Low - Even after preserving Claude mappings, 8+ keys remain available (or will become available) in `<leader>a` namespace
- **Mitigation**: Plan already maps all 25 Goose commands, so no immediate expansion needed
- **Likelihood**: Very Low - Current plan achieves 100% Goose coverage even with preserved Claude mappings

## Recommendations

1. **Honor All User NOTEs**: Revise Phase 2 to comment out TTS (`<leader>at`), remove Yolo move task (keep `<leader>ay`), remove Claude consolidation task (keep `<leader>as` and `<leader>ac`), and simplify validation checkpoint to only test Claude worktree moves.

2. **Implement Option 1 for Conflict Resolution**: Reassign `GooseSelectSession` to `<leader>az` and `GooseOpenConfig` to `<leader>aw`, accepting weaker mnemonics to honor user's preference for preserving Claude mappings.

3. **Update Success Criteria and Expected Outcomes**: Revise plan metadata (lines 43-54) and phase expected outcomes (line 186) to reflect reduced scope - only 3 mappings moved (Claude worktrees), not 7.

4. **Document Mnemonic Trade-offs in Migration Guide**: Phase 5 Task 2 should explicitly note that `<leader>az` (Goose session) and `<leader>aw` (Goose config) use weaker mnemonics due to namespace constraints from preserving Claude mappings.

5. **Consider Future Namespace Strategy**: If additional Goose commands are added in future versions, revisit the decision to preserve Claude mappings at `<leader>as` and `<leader>ac`, potentially proposing `<leader>c` consolidation as a separate migration effort.

## References

- Plan file: /home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/plans/001-leader-a-mapping-rename-plan.md
- Current mappings: /home/benjamin/.config/nvim/lua/neotex/plugins/editor/which-key.lua (lines 244-417)
- Research report: /home/benjamin/.config/.claude/specs/061_leader_a_mapping_rename/reports/001-current-mappings-audit.md
