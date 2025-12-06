# Research Report: Nvim Sync Clean Copy Bug

## Summary

The clean replace option (option 4/5) in the nvim sync utility successfully removes local artifact directories but fails to copy new artifacts from the global `~/.config/.claude/` directory. The error is caused by a **Lua function definition order issue** where `clean_and_replace_all()` calls `load_all_with_strategy()` before the latter function is defined.

## Error Analysis

### Error Message
```
E5108: Error executing lua: ...ex/plugins/ai/claude/commands/picker/operations/sync.lua:687: attempt to call global 'load_all_with_strategy' (a nil value)
stack traceback:
  ...ex/plugins/ai/claude/commands/picker/operations/sync.lua:687: in function 'load_all_globally'
```

### Root Cause

In Lua, local function definitions are executed **linearly** - a function must be defined before it can be called. The current file structure has:

1. `clean_and_replace_all()` defined at line 560-688
2. `sync_files()` defined at line 695-737
3. `load_all_with_strategy()` defined at line 757-815

When `clean_and_replace_all()` calls `load_all_with_strategy()` on line 684-687:
```lua
return load_all_with_strategy(
  project_dir, commands, agents, hooks, all_tts, templates, lib_utils, docs,
  all_agent_protocols, standards, all_data_docs, settings, scripts, tests, all_skills, false
)
```

The function `load_all_with_strategy` has not yet been defined in Lua's execution context, resulting in `nil`.

### Why It Worked for Option 1/2

Options 1 and 2 call `load_all_with_strategy()` from `load_all_globally()` (line 1046-1049), which is defined **after** `load_all_with_strategy()`, so the function is already available in the scope.

### Code Structure Analysis

Current function order in sync.lua:
```
Line 31:   create_interactive_state()
Line 45:   show_diff_for_file()
Line 160:  prompt_for_conflict()
Line 261:  apply_interactive_decisions()
Line 356:  run_interactive_sync()
Line 414:  count_by_depth()
Line 431:  count_actions()
Line 447:  confirm_clean_replace()        -- NEW (Phase 1)
Line 487:  remove_artifact_directories()  -- NEW (Phase 2)
Line 560:  clean_and_replace_all()        -- NEW (Phase 3) - PROBLEM: calls load_all_with_strategy
Line 695:  sync_files()
Line 757:  load_all_with_strategy()       -- PROBLEM: defined AFTER clean_and_replace_all
Line 821:  M.load_all_globally()
Line 1057: M.update_artifact_from_global()
```

## Solution Options

### Option 1: Move `load_all_with_strategy()` Before `clean_and_replace_all()` (Recommended)

Move the `load_all_with_strategy()` function definition to appear before `clean_and_replace_all()`. This requires also moving `sync_files()` since `load_all_with_strategy()` depends on it.

**New order:**
```
Line ~450: confirm_clean_replace()
Line ~490: remove_artifact_directories()
Line ~555: sync_files()              -- MOVED UP
Line ~620: load_all_with_strategy()  -- MOVED UP
Line ~700: clean_and_replace_all()   -- Now can call load_all_with_strategy
```

**Pros:**
- Clean, straightforward fix
- Maintains readability with logical grouping
- No behavioral changes

**Cons:**
- Requires moving ~150 lines of code

### Option 2: Use Forward Declaration

Declare all functions as locals at the top of the file, then define them later:

```lua
-- Forward declarations at top of file
local sync_files
local load_all_with_strategy
local clean_and_replace_all

-- ... later in file ...
sync_files = function(files, preserve_perms, merge_only)
  -- implementation
end

load_all_with_strategy = function(project_dir, ...)
  -- implementation
end

clean_and_replace_all = function(project_dir, global_dir)
  -- implementation (can now call load_all_with_strategy)
end
```

**Pros:**
- No need to move large blocks of code
- Common Lua pattern for mutual recursion

**Cons:**
- Adds complexity with forward declarations
- Changes coding style from rest of file

### Option 3: Inline Sync Logic in `clean_and_replace_all()`

Instead of calling `load_all_with_strategy()`, inline the sync logic directly in `clean_and_replace_all()`.

**Pros:**
- No function reordering needed

**Cons:**
- Code duplication (~60 lines)
- Harder to maintain
- Violates DRY principle

## Recommendation

**Option 1: Move functions** is the recommended fix because:
1. It's the simplest conceptual fix
2. It maintains code clarity
3. It doesn't introduce new patterns
4. It groups related functions logically (all sync helpers together)

## Implementation Details

### Files Affected
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

### Functions to Move

1. **`sync_files()`** (lines 695-737, ~42 lines)
   - Must move before `load_all_with_strategy()` since it's called by that function

2. **`load_all_with_strategy()`** (lines 757-815, ~58 lines)
   - Must move before `clean_and_replace_all()`

### Total Lines to Move
~100 lines of code

### Risk Assessment
- **Low risk**: Pure code reordering, no logic changes
- **Testing**: Verify all sync options (1-5) still work
- **Regression**: Check interactive mode and no-conflicts path

## Verification Steps

After fix:
1. Test Option 1 (Replace + add new) - should still work
2. Test Option 2 (Add new only) - should still work
3. Test Option 3 (Interactive) - should still work
4. Test Option 4 (Clean copy with conflicts) - NOW should work
5. Test Option 5 (Clean copy no conflicts) - NOW should work (was Option 2 in no-conflicts dialog)

## References

- Error output: `/home/benjamin/.config/.claude/specs/038_nvim_sync_clean_replace/output.md`
- Implementation plan: `/home/benjamin/.config/.claude/specs/038_nvim_sync_clean_replace/plans/001-nvim-sync-clean-replace-plan.md`
- Source file: `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
