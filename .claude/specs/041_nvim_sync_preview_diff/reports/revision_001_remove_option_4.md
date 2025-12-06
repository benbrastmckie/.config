# Research Report: Remove Option 4 from Sync Utility

## Date
2025-12-04

## Summary
Analysis of changes required to remove option 4 (Preview diff) from the nvim claude-code sync utility while preserving all other options.

## Current State

The sync utility in `sync.lua` currently has 6 options when conflicts exist:
1. Replace existing + add new
2. Add new only
3. Interactive (per-file prompts)
4. Preview diff (UNIMPLEMENTED - currently falls back to option 1)
5. Clean copy
6. Cancel

## Required Changes

### Files to Modify
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`

### Code Changes Required

#### 1. Update Dialog Message (lines 978-983)
**Current:**
```lua
"  1: Replace existing + add new (%d files)\n" ..
"  2: Add new only (%d new)\n" ..
"  3: Interactive  4: Preview diff\n" ..
"  5: Clean copy   6: Cancel"
```

**After:**
```lua
"  1: Replace existing + add new (%d files)\n" ..
"  2: Add new only (%d new)\n" ..
"  3: Interactive\n" ..
"  4: Clean copy   5: Cancel"
```

#### 2. Update Button String (line 985)
**Current:**
```lua
buttons = "&1 Replace\n&2 New only\n&3 Interactive\n&4 Preview\n&5 Clean\n&6 Cancel"
```

**After:**
```lua
buttons = "&1 Replace\n&2 New only\n&3 Interactive\n&4 Clean\n&5 Cancel"
```

#### 3. Update Default Choice (line 986)
**Current:**
```lua
default_choice = 6  -- Default to Cancel for safety
```

**After:**
```lua
default_choice = 5  -- Default to Cancel for safety
```

#### 4. Update Options Comment (line 1006)
**Current:**
```lua
-- Options: 1=Replace existing + add new, 2=Add new only, 3=Interactive, 4=Preview diff, 5=Clean copy, 6=Cancel
```

**After:**
```lua
-- Options: 1=Replace existing + add new, 2=Add new only, 3=Interactive, 4=Clean copy, 5=Cancel
```

#### 5. Remove Option 4 Handler (lines 1025-1028)
**Remove entirely:**
```lua
elseif choice == 4 then
  -- Preview diff (not implemented yet, fallback to Replace all for now)
  helpers.notify("Preview diff not yet implemented, using Replace existing + add new", "WARN")
  merge_only = false
```

#### 6. Renumber Option 5 to 4 (lines 1029-1030)
**Current:**
```lua
elseif choice == 5 then
  -- Clean copy - remove all local artifacts and replace with global versions
```

**After:**
```lua
elseif choice == 4 then
  -- Clean copy - remove all local artifacts and replace with global versions
```

#### 7. Update Cancel Check (implicit choice == 6 becomes choice == 5)
The fallthrough `else` clause handles cancel, which now triggers on choice >= 5 instead of >= 6.

## Impact Analysis

- **Backward Compatibility**: No external API changes
- **User Impact**: Cleaner menu with only implemented options
- **Risk**: Low - removing unimplemented feature
- **Testing**: Manual verification of all remaining options

## Estimated Effort
- 0.5-1 hour for code changes and testing
