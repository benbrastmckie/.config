# Settings.json Sync as Artifact - Implementation Plan

## Metadata
- **Date**: 2025-12-04
- **Feature**: Enable settings.json as syncable artifact in claude-code sync utility
- **Scope**: Modify the Neovim sync utility to sync settings.json (portable hook configurations) instead of settings.local.json, enabling automatic hook configuration distribution while preserving local settings exclusion
- **Status**: [COMPLETE]
- **Estimated Phases**: 5
- **Estimated Hours**: 2-3 hours
- **Complexity Score**: 28.5
- **Structure Level**: 0
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**:
  - [Settings.json Sync Research Report](../reports/001-settings-json-sync-research.md)

## Overview

This implementation modifies the claude-code sync utility to treat `settings.json` as a syncable artifact, aligning with Claude Code's official three-tier settings hierarchy. Currently, the sync utility excludes settings files from sync operations (implemented in spec 044). This plan reverses that exclusion and redirects sync operations to target `settings.json` (portable, version-controlled) instead of `settings.local.json` (local-only, machine-specific).

**Key Changes**:
- Sync `settings.json` as a regular artifact (like commands, agents, hooks)
- Keep `settings.local.json` excluded from sync (local-only)
- Preserve template initialization (settings.local.json created from settings.json)
- Update documentation to clarify which file syncs and why

## Research Summary

The research report identified that the sync infrastructure for settings files already exists from spec 044, but currently targets `settings.local.json` (which should be excluded). Key findings:

- **Infrastructure Present**: Scan, sync, preview, and initialization logic already implemented
- **Simple Target Change**: Change filename parameter from `settings.local.json` to `settings.json` in 3 files
- **Re-enable Operations**: Re-add settings scanning and sync operations that were removed in spec 044
- **Documentation Clarity**: Update README to explain settings.json IS synced, settings.local.json is NOT
- **Template Logic Preserved**: Existing initialization creates settings.local.json from settings.json (keep this)

**Recommended Approach**: Option A from research - re-enable settings sync targeting settings.json instead of settings.local.json. Uses existing infrastructure, minimal code changes, aligns perfectly with Claude Code's official design.

## Success Criteria

- [ ] settings.json scanned and synced as regular artifact across all sync modes
- [ ] settings.local.json remains excluded from sync operations
- [ ] Preview display shows accurate settings.json count (new/replace)
- [ ] Console notifications include settings count in output
- [ ] Interactive mode prompts for settings.json conflicts with all decision options
- [ ] Clean Replace mode deletes and re-syncs settings.json (not preserved)
- [ ] Template initialization still creates settings.local.json from settings.json
- [ ] Documentation clearly distinguishes settings.json (synced) from settings.local.json (not synced)
- [ ] All sync strategies work correctly (Load All, Replace, Add New, Interactive, Clean Replace)
- [ ] No regression in existing artifact sync behavior (commands, agents, hooks, etc.)

## Technical Design

### Architecture Overview

The sync utility uses a scan-sync-display pattern:
1. **Scan** (scan.lua): Discovers artifacts by scanning directories
2. **Sync** (sync.lua): Copies artifacts from global to project, applies strategies
3. **Display** (previewer.lua): Shows preview of sync actions before execution

Settings files were integrated in spec 044 but excluded from sync. This implementation re-enables sync by:
1. Changing scan target from `settings.local.json` → `settings.json`
2. Re-adding settings to sync operations (load_all, clean_replace, interactive)
3. Including settings in count calculations and notifications
4. Preserving initialization logic (creates settings.local.json from settings.json)

### Component Interactions

```
┌─────────────────────────────────────────────────────────┐
│ Sync Command Entry Points                              │
│ - load_all_globally()     [Load All Artifacts]         │
│ - clean_and_replace_all() [Clean Replace]              │
│ - load_all_with_strategy()[Interactive/Merge modes]    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ scan.scan_directory_for_sync()                         │
│ - Discovers settings.json in .claude/                  │
│ - Returns file list with action metadata               │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ sync.sync_files()                                       │
│ - Copies settings.json from global to project          │
│ - Applies merge/replace strategy                       │
│ - Calls initialize_settings_from_template()            │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│ Output                                                  │
│ - Notification with settings count                     │
│ - Preview shows settings actions                       │
│ - settings.local.json auto-initialized if missing      │
└─────────────────────────────────────────────────────────┘
```

### Standards Alignment

**Code Standards**:
- Lua coding conventions (2-space indent, snake_case)
- Use existing sync infrastructure (no new patterns)
- pcall for error handling in sync operations

**Documentation Standards**:
- Update README with clear settings file distinction
- Use CommonMark format with code examples
- No historical commentary (clean-break standard)

**Directory Organization**:
- settings.json in `.claude/` root (not subdirectory)
- Follows existing artifact placement pattern

### Design Decisions

**Why Sync settings.json Instead of settings.local.json**:
- settings.json contains portable hooks using `$CLAUDE_PROJECT_DIR` variable
- Should be version-controlled and shared across projects
- Enables automatic hook configuration in new projects
- Aligns with Claude Code's official three-tier hierarchy

**Why Keep settings.local.json Excluded**:
- Contains machine-specific permissions and overrides
- Should NOT be version-controlled or shared
- Accumulates session-specific preferences
- Highest precedence (overrides settings.json)

**Why Preserve Template Initialization**:
- New projects need default hook configurations
- settings.local.json auto-created from settings.json template
- Gives users working hooks immediately after sync
- Doesn't interfere with sync operations

## Implementation Phases

### Phase 1: Update Scan Target [COMPLETE]
dependencies: []

**Objective**: Change scan.lua to target settings.json instead of settings.local.json

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua`
- [x] Locate line 192: `settings = M.scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")`
- [x] Replace "settings.local.json" with "settings.json" in scan call
- [x] Verify no other references to settings.local.json in scan.lua (should only be this one)

**Testing**:
```bash
# Verify scan.lua contains settings.json target
grep -n "settings.json" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua

# Verify settings.local.json removed from scan calls
! grep "settings.local.json" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua
```

**Expected Duration**: 0.25 hours

---

### Phase 2: Re-enable Settings Sync in load_all_globally() [COMPLETE]
dependencies: [1]

**Objective**: Re-add settings scanning and sync operations in the Load All Artifacts function

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
- [x] Locate `load_all_globally()` function (~line 853)
- [x] Add settings scan after data documentation scans: `local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.json")`
- [x] Locate `load_all_with_strategy()` function signature (~line 638)
- [x] Add `settings` parameter to function signature (after `skills` parameter)
- [x] Locate sync operations block (~line 657)
- [x] Add settings sync call: `local set_count = sync_files(settings, false, merge_only)`
- [x] Add `set_count` to total calculation (~line 660)
- [x] Add settings to notification string (~line 686): `"Settings: %d"` and `set_count` parameter
- [x] Update `load_all_globally()` return statement to pass settings to `load_all_with_strategy()`

**Testing**:
```bash
# Verify load_all_globally scans settings
grep -A 5 "data_templates_readme.*scan_directory_for_sync" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua | grep "settings"

# Verify settings parameter in function signature
grep "function.*load_all_with_strategy.*settings" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua

# Verify settings sync call
grep "set_count.*sync_files.*settings" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua

# Verify notification includes settings
grep "Settings:.*%d" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua
```

**Expected Duration**: 0.5 hours

---

### Phase 3: Re-enable Settings Sync in clean_and_replace_all() [COMPLETE]
dependencies: [2]

**Objective**: Re-add settings scanning and sync operations in Clean Replace function

**Complexity**: Low

**Tasks**:
- [x] Locate `clean_and_replace_all()` function (~line 725)
- [x] Add settings scan after data documentation scans: `local settings = scan.scan_directory_for_sync(global_dir, project_dir, "", "settings.json")`
- [x] Locate function return statement (~line 830)
- [x] Add `settings` parameter to `load_all_with_strategy()` call
- [x] Verify settings.json NOT in "PRESERVED" list in confirmation dialog (~line 499-506)

**Testing**:
```bash
# Verify clean_and_replace_all scans settings
grep -A 5 "function.*clean_and_replace_all" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua | grep -A 50 "scan_directory_for_sync" | grep "settings"

# Verify settings passed to load_all_with_strategy in return
grep -A 20 "clean_and_replace_all.*load_all_with_strategy" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua | grep "settings"

# Verify settings.json not in preserved list
! grep -A 10 "PRESERVED files" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua | grep "settings.json"
```

**Expected Duration**: 0.25 hours

---

### Phase 4: Re-enable Settings in Interactive Mode and Preview [COMPLETE]
dependencies: [3]

**Objective**: Include settings in interactive mode, preview display, and count calculations

**Complexity**: Medium

**Tasks**:
- [x] In sync.lua, locate `load_all_globally()` where it scans for interactive mode (~line 957)
- [x] Add settings to `total_files` calculation (~line 957)
- [x] Add settings action count variables (~line 976): `local set_copy, set_replace = count_actions(settings)`
- [x] Add `set_copy` to `total_copy` calculation (~line 978)
- [x] Add `set_replace` to `total_replace` calculation (~line 980)
- [x] Add settings to `run_interactive_sync()` artifact list (~line 1036-1039)
- [x] Add settings parameter to final `load_all_with_strategy()` call (~line 1066)
- [x] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua`
- [x] Locate line 198: `local settings = scan_directory_for_sync(global_dir, project_dir, "", "settings.local.json")`
- [x] Change "settings.local.json" to "settings.json"
- [x] Verify settings already included in count calculations (lines 227, 230-232, 253) - no changes needed

**Testing**:
```bash
# Verify settings in total_files calculation
grep "total_files.*settings" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua

# Verify settings action counts
grep "set_copy.*count_actions.*settings" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua

# Verify settings in interactive sync artifact list
grep -A 10 "run_interactive_sync" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua | grep "settings"

# Verify previewer targets settings.json
grep "settings.*scan_directory_for_sync.*settings.json" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua
```

**Expected Duration**: 0.5 hours

---

### Phase 5: Update Documentation [COMPLETE]
dependencies: [4]

**Objective**: Update README to clarify settings.json IS synced, settings.local.json is NOT

**Complexity**: Low

**Tasks**:
- [x] Open `/home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md`
- [x] Update artifact count from 449 to 450 (~line 162)
- [x] Add settings.json to artifact categories list (~lines 150-159): `"Settings (settings.json from .claude/) - portable hook configurations"`
- [x] Locate Settings File Handling section (~lines 225-245)
- [x] Replace entire section with updated content explaining settings.json IS synced (see research report lines 399-430 for exact text)
- [x] Ensure table shows settings.json as "Yes (as artifact)" and settings.local.json as "Never"
- [x] Add example showing settings count in sync notification

**Testing**:
```bash
# Verify artifact count updated to 450
grep "450" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md

# Verify settings.json added to artifact list
grep "Settings.*settings.json.*portable" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md

# Verify updated settings file handling section
grep -A 30 "Settings File Handling" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md | grep "settings.json IS synced"

# Verify table shows correct sync status
grep -A 10 "File.*Purpose.*Synced" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md | grep "settings.json.*Yes"
grep -A 10 "File.*Purpose.*Synced" /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/README.md | grep "settings.local.json.*Never"
```

**Expected Duration**: 0.5 hours

---

## Testing Strategy

### Unit Testing

**Scan Operation**:
```bash
# Test settings.json discovered by scan
cd /home/benjamin/.config
nvim --headless -c "lua print(require('neotex.plugins.ai.claude.commands.picker.utils.scan').scan_directory_for_sync('/home/benjamin/.config', '/tmp/test-project', '', 'settings.json'))" -c "quit"
```

**Sync Operation**:
```bash
# Test settings.json copied during sync
mkdir -p /tmp/test-project/.claude
rm -f /tmp/test-project/.claude/settings.json
# Run sync via Neovim picker (Load All Artifacts)
# Verify settings.json appears in /tmp/test-project/.claude/
test -f /tmp/test-project/.claude/settings.json && echo "PASS: settings.json synced"
```

### Integration Testing

**Test 1: Load All Artifacts (New)**
```bash
# Setup: Clean test project without settings.json
mkdir -p /tmp/test-project/.claude
rm -f /tmp/test-project/.claude/settings.json
rm -f /tmp/test-project/.claude/settings.local.json

# Execute: Run [Load All Artifacts] from picker
# Expected:
# - settings.json copied from global
# - settings.local.json auto-initialized from settings.json
# - Notification shows "Settings: 1"

# Verify:
test -f /tmp/test-project/.claude/settings.json || echo "FAIL: settings.json not synced"
test -f /tmp/test-project/.claude/settings.local.json || echo "FAIL: settings.local.json not initialized"
diff /tmp/test-project/.claude/settings.json /home/benjamin/.config/.claude/settings.json || echo "FAIL: settings.json content differs"
```

**Test 2: Replace Strategy**
```bash
# Setup: Modify local settings.json
mkdir -p /tmp/test-project/.claude
echo '{"hooks": {"Custom": []}}' > /tmp/test-project/.claude/settings.json

# Execute: Run [Load All Artifacts] with "Replace all + add new" strategy
# Expected: Local settings.json overwritten with global version

# Verify:
diff /tmp/test-project/.claude/settings.json /home/benjamin/.config/.claude/settings.json || echo "FAIL: settings.json not replaced"
```

**Test 3: Add New Only Strategy**
```bash
# Setup: Modify local settings.json
mkdir -p /tmp/test-project/.claude
echo '{"hooks": {"Custom": []}}' > /tmp/test-project/.claude/settings.json

# Execute: Run [Load All Artifacts] with "Add new only" strategy
# Expected: Local settings.json preserved (not overwritten)

# Verify:
grep "Custom" /tmp/test-project/.claude/settings.json || echo "FAIL: settings.json was replaced (should be preserved)"
```

**Test 4: Interactive Mode**
```bash
# Setup: Modify local settings.json
mkdir -p /tmp/test-project/.claude
echo '{"hooks": {"Custom": []}}' > /tmp/test-project/.claude/settings.json

# Execute: Run [Load All Artifacts] with "Interactive" mode
# Expected:
# - Prompt appears for settings.json with options (Keep, Replace, View diff, etc.)
# - Each decision option works correctly

# Manual verification: Test each decision option
# - Keep: Preserves local changes
# - Replace: Overwrites with global version
# - View diff: Shows differences
# - Skip: Continues without action
```

**Test 5: Clean Replace**
```bash
# Setup: Create local settings.json with custom content
mkdir -p /tmp/test-project/.claude
echo '{"hooks": {"Custom": []}}' > /tmp/test-project/.claude/settings.json

# Execute: Run [Clean Replace All Artifacts]
# Expected:
# - Local .claude/ directory wiped
# - settings.json re-synced from global (not custom content)
# - settings.local.json re-initialized from new settings.json

# Verify:
! grep "Custom" /tmp/test-project/.claude/settings.json || echo "FAIL: settings.json not replaced in clean replace"
diff /tmp/test-project/.claude/settings.json /home/benjamin/.config/.claude/settings.json || echo "FAIL: settings.json content differs after clean replace"
```

**Test 6: Preview Accuracy**
```bash
# Setup: Delete local settings.json
mkdir -p /tmp/test-project/.claude
rm -f /tmp/test-project/.claude/settings.json

# Execute: Open picker preview (before sync)
# Expected: Preview shows "Settings: 1 new, 0 replace"

# Verify: Manual inspection of preview display

# Setup 2: Modify local settings.json
echo '{"hooks": {}}' > /tmp/test-project/.claude/settings.json

# Execute: Open picker preview again
# Expected: Preview shows "Settings: 0 new, 1 replace"

# Verify: Manual inspection of preview display
```

### Manual End-to-End Verification

1. Create test project in `/tmp/test-project`
2. Run sync via Neovim picker: `<leader>as` (Load All Artifacts)
3. Verify settings.json appears with correct content
4. Verify settings.local.json auto-initialized
5. Verify notification shows settings count
6. Test hooks work correctly (run `/test` or `/implement` command)
7. Modify local settings.json and test each sync strategy
8. Test Clean Replace deletes and re-syncs settings.json

### Regression Testing

Verify existing artifact sync behavior unchanged:
```bash
# Test commands still sync correctly
diff /tmp/test-project/.claude/commands/test.md /home/benjamin/.config/.claude/commands/test.md

# Test agents still sync correctly
diff /tmp/test-project/.claude/agents/plan-architect.md /home/benjamin/.config/.claude/agents/plan-architect.md

# Test hooks still sync correctly
diff /tmp/test-project/.claude/hooks/pre-commit /home/benjamin/.config/.claude/hooks/pre-commit
```

### Coverage Requirements

- All sync modes tested: Load All, Clean Replace, Interactive
- All strategies tested: Replace, Add New, Merge
- Preview accuracy verified for new and replace scenarios
- Template initialization verified (settings.local.json created)
- Notification output verified (settings count included)
- Regression testing passed (existing artifacts unaffected)

## Documentation Requirements

### Files to Update

1. **README.md** (primary user documentation)
   - Update artifact count from 449 to 450
   - Add settings.json to artifact categories list
   - Replace Settings File Handling section with clarified content
   - Update examples to show settings count in notifications

2. **CLAUDE.md** (optional, if settings mentioned)
   - Check if sync utility settings behavior documented
   - Add clarification about settings.json sync if needed
   - No changes if sync utility already documented elsewhere

### Documentation Standards

- Use CommonMark format with clear code examples
- Include bash code blocks with syntax highlighting
- Provide table showing settings file comparison
- Explain WHY settings.json syncs but settings.local.json doesn't
- Show example notification output with settings count

## Dependencies

### External Dependencies
- Neovim (already installed)
- Lua language server (for syntax validation, optional)
- Claude Code sync utility (already exists)

### Internal Dependencies
- `scan.lua` (scan infrastructure) - existing
- `sync.lua` (sync operations) - existing
- `previewer.lua` (preview display) - existing
- `settings.json` (portable hook configurations) - existing in global config
- `initialize_settings_from_template()` function - existing, no changes needed

### Prerequisite Verification
```bash
# Verify global settings.json exists
test -f /home/benjamin/.config/.claude/settings.json || echo "ERROR: Global settings.json missing"

# Verify sync utility exists
test -f /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua || echo "ERROR: Sync utility missing"

# Verify scan utility exists
test -f /home/benjamin/.config/nvim/lua/neotex/plugins/ai/claude/commands/picker/utils/scan.lua || echo "ERROR: Scan utility missing"
```

## Risk Analysis

### Low Risk
- **Infrastructure Reuse**: Using existing scan/sync infrastructure (already tested)
- **Simple Target Change**: Changing filename parameter is low-risk modification
- **Template Logic Preserved**: No changes to initialization (already working)

### Medium Risk
- **Backwards Compatibility**: Projects without settings.json will show "Settings: 0" (acceptable)
- **User Confusion**: Must clearly document which file syncs (settings.json) vs which doesn't (settings.local.json)
- **Clean Replace Behavior**: Must ensure settings.json deleted (not preserved) during clean replace

### Mitigation Strategies

**Documentation Clarity**:
- Explicitly state "settings.json IS synced" in multiple places
- Provide table comparing settings.json vs settings.local.json
- Include examples showing settings count in notifications
- Explain WHY settings.json should be synced (portable hooks)

**Preserve Initialization**:
- Keep `initialize_settings_from_template()` function unchanged
- Ensures settings.local.json auto-created from settings.json
- New projects get default hook configurations immediately

**Test All Strategies**:
- Verify Replace, Add New, Interactive, and Clean Replace modes
- Test each strategy with modified local settings.json
- Ensure preview shows correct counts (new vs replace)

**Regression Prevention**:
- Test existing artifact sync behavior unchanged
- Verify commands, agents, hooks still sync correctly
- Ensure no side effects on other sync operations

## Notes

### Previous Work Context

This implementation reverses part of spec 044, which excluded settings.local.json from sync. The reversal is intentional and well-motivated:

**Spec 044 Goal**: Exclude machine-specific settings.local.json from sync
**This Spec Goal**: Include portable settings.json in sync

Both goals are correct and non-conflicting. The confusion arose from which file should be synced:
- settings.local.json = local-only (spec 044 correctly excluded this)
- settings.json = shared config (this spec correctly includes this)

### Implementation Estimate Rationale

**Total: 2-3 hours**
- Phase 1: 0.25 hours (simple filename change in scan.lua)
- Phase 2: 0.5 hours (re-add settings to load_all_globally)
- Phase 3: 0.25 hours (re-add settings to clean_and_replace_all)
- Phase 4: 0.5 hours (re-add settings to interactive mode and preview)
- Phase 5: 0.5 hours (update documentation)
- Buffer: 0.5 hours (testing, verification, unexpected issues)

### Progressive Planning Hint

Complexity score of 28.5 is well below the expansion threshold (50). This plan uses Level 0 structure (single file) which is appropriate for the scope. No phase expansion needed.
