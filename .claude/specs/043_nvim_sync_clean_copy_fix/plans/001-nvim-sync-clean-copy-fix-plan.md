# Implementation Plan: Fix Nvim Sync Clean Copy Option

## Metadata
- **Date**: 2025-12-04
- **Feature**: Fix clean copy option failing to copy artifacts due to Lua function definition order issue
- **Status**: [COMPLETE]
- **Estimated Hours**: 0.5-1 hours
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [001-sync-clean-copy-research.md](../reports/001-sync-clean-copy-research.md)

## Overview

The clean replace option (option 4 with conflicts, option 2 without conflicts) in the nvim sync utility successfully removes local artifact directories but fails to copy new artifacts. The root cause is a Lua function definition order issue where `clean_and_replace_all()` calls `load_all_with_strategy()` before the latter function is defined.

## Problem Statement

Error:
```
E5108: Error executing lua: ...sync.lua:687: attempt to call global 'load_all_with_strategy' (a nil value)
```

In Lua, local functions must be defined before they can be called. The current file structure has `clean_and_replace_all()` defined before `load_all_with_strategy()`, causing the call to fail.

## Success Criteria
- [x] Clean copy option (with conflicts) successfully removes artifacts AND copies new ones
- [x] Clean copy option (no conflicts) successfully removes artifacts AND copies new ones
- [x] Existing sync options (Replace, Add new only, Interactive) continue to work
- [x] No Lua errors during any sync operation
- [x] Sync report shows accurate file counts after clean copy

## Technical Solution

Reorder function definitions in sync.lua to ensure `sync_files()` and `load_all_with_strategy()` are defined before `clean_and_replace_all()` calls them.

### Current Order (Problematic)
```
Line 447:  confirm_clean_replace()
Line 487:  remove_artifact_directories()
Line 560:  clean_and_replace_all()        -- Calls load_all_with_strategy (not yet defined)
Line 695:  sync_files()
Line 757:  load_all_with_strategy()       -- Defined TOO LATE
```

### New Order (Fixed)
```
Line 447:  confirm_clean_replace()
Line 487:  remove_artifact_directories()
Line 555:  sync_files()                   -- MOVED UP
Line 600:  load_all_with_strategy()       -- MOVED UP
Line 720:  clean_and_replace_all()        -- Now can call both functions
```

## Implementation Phases

### Phase 1: Move sync_files() Function [COMPLETE]
dependencies: []

**Objective**: Move `sync_files()` to appear after `remove_artifact_directories()` and before `load_all_with_strategy()`

**Tasks**:
- [x] Cut `sync_files()` function (lines 695-737 in current file)
- [x] Paste after `remove_artifact_directories()` function (after line 553)
- [x] Verify no syntax errors after move

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Expected Duration**: 10 minutes

### Phase 2: Move load_all_with_strategy() Function [COMPLETE]
dependencies: [1]

**Objective**: Move `load_all_with_strategy()` to appear after `sync_files()` and before `clean_and_replace_all()`

**Tasks**:
- [x] Cut `load_all_with_strategy()` function (lines 757-815 in current file, will be different after Phase 1)
- [x] Paste after `sync_files()` function (which was just moved)
- [x] Verify no syntax errors after move
- [x] Note: `clean_and_replace_all()` will now be after both functions it calls

**File**: `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

**Expected Duration**: 10 minutes

### Phase 3: Verify and Test [COMPLETE]
dependencies: [2]

**Objective**: Verify all sync operations work correctly after reordering

**Tasks**:
- [x] Open Neovim in a test project directory (not ~/.config)
- [x] Run `:ClaudeCommands` and navigate to `[Load All Artifacts]`
- [x] Test Option 1 (Replace + add new): Verify files sync correctly
- [x] Test Option 2 (Add new only): Verify only new files added
- [x] Test Option 4 (Clean copy with conflicts): Verify removal AND copy works
- [x] Test no-conflicts scenario: Run in clean project, verify Option 2 (Clean copy) works
- [x] Verify sync report shows accurate file counts

**Expected Duration**: 15 minutes

## Testing Strategy

### Manual Testing
1. **Clean copy with conflicts**:
   ```bash
   cd /tmp/test-sync
   mkdir -p .claude/commands
   echo "local" > .claude/commands/test.md
   # Run :ClaudeCommands -> Load All -> Option 4 (Clean)
   # Verify: commands/test.md removed, global artifacts copied
   ```

2. **Clean copy no conflicts**:
   ```bash
   cd /tmp/test-clean
   mkdir -p .claude
   # Run :ClaudeCommands -> Load All -> Option 2 (Clean copy)
   # Verify: global artifacts copied
   ```

3. **Preserved directories**:
   ```bash
   cd /tmp/test-preserve
   mkdir -p .claude/{specs,commands}
   echo "plan" > .claude/specs/my-plan.md
   echo "local" > .claude/commands/local.md
   # Run clean copy
   # Verify: specs/my-plan.md preserved, commands/ replaced
   ```

## Risk Assessment

### Low Risk
- **Code change type**: Pure function reordering, no logic changes
- **Scope**: Single file, single module
- **Rollback**: Easy to revert if issues arise

### Potential Issues
- **Line number changes**: After moving functions, line numbers in error messages will change
- **IDE navigation**: Some code navigation tools cache file structure

## Documentation Updates

No documentation updates required - this is a bug fix, not a feature change.

## Completion Checklist

- [x] Phase 1 completed (sync_files moved)
- [x] Phase 2 completed (load_all_with_strategy moved)
- [x] Phase 3 completed (all tests pass)
- [x] Clean copy with conflicts works
- [x] Clean copy without conflicts works
- [x] Existing options (1, 2, 3) still work
- [x] No Lua errors during sync operations
