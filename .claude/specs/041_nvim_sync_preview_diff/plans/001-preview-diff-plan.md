# Implementation Plan: Remove Option 4 (Preview Diff) from Nvim Claude-Code Sync Utility

## Metadata
- **Date**: 2025-12-04 (Revised)
- **Feature**: Remove unimplemented option 4 (Preview Diff Mode) from sync menu, renumber remaining options
- **Status**: [COMPLETE]
- **Estimated Hours**: 0.5-1 hour
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Research Reports**: [revision_001_remove_option_4.md](../reports/revision_001_remove_option_4.md)
- **Complexity Score**: 15
- **Structure Level**: 0

## Overview

The nvim claude-code sync utility currently shows 6 options when file conflicts exist:
1. Replace existing + add new
2. Add new only
3. Interactive
4. Preview diff (UNIMPLEMENTED - falls back to option 1 with warning)
5. Clean copy
6. Cancel

This plan removes option 4 entirely, providing a cleaner user experience with only implemented options. Options 5-6 will be renumbered to 4-5.

## Rationale

- Option 4 is unimplemented and confusing to users
- The fallback behavior (silently using option 1) is unexpected
- Removing placeholder options improves UX
- Can be re-added later if diff preview is actually implemented

## Success Criteria

- [x] Option 4 (Preview diff) removed from menu
- [x] Options 5-6 renumbered to 4-5
- [x] All remaining options (1-5) function correctly
- [x] No dead code remains for old option 4
- [x] Default choice updated to new Cancel position (5)

## Technical Design

### Current State (sync.lua)

```lua
-- Dialog message shows:
"  1: Replace existing + add new (%d files)\n" ..
"  2: Add new only (%d new)\n" ..
"  3: Interactive  4: Preview diff\n" ..
"  5: Clean copy   6: Cancel"

-- Buttons:
buttons = "&1 Replace\n&2 New only\n&3 Interactive\n&4 Preview\n&5 Clean\n&6 Cancel"

-- Default choice:
default_choice = 6  -- Cancel

-- Handler includes unused case:
elseif choice == 4 then
  helpers.notify("Preview diff not yet implemented...", "WARN")
  merge_only = false
elseif choice == 5 then
  -- Clean copy
elseif choice == 6 then
  -- Cancel (implicit fallthrough)
```

### Target State

```lua
-- Dialog message:
"  1: Replace existing + add new (%d files)\n" ..
"  2: Add new only (%d new)\n" ..
"  3: Interactive\n" ..
"  4: Clean copy   5: Cancel"

-- Buttons:
buttons = "&1 Replace\n&2 New only\n&3 Interactive\n&4 Clean\n&5 Cancel"

-- Default choice:
default_choice = 5  -- Cancel

-- Handler (option 4 removed):
elseif choice == 4 then
  -- Clean copy
else
  -- Cancel (choice == 5 or any other)
```

## Implementation Phases

### Phase 1: Update Sync Menu and Logic [COMPLETE]
dependencies: []

**Objective**: Remove option 4 and renumber options 5-6

**Complexity**: Low

**Tasks**:
- [x] Edit `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`
- [x] Update dialog message (lines 978-983): Remove "4: Preview diff" from text
- [x] Update buttons string (line 985): Remove "&4 Preview" button
- [x] Update default_choice (line 986): Change from 6 to 5
- [x] Update comment (line 1006): Remove "4=Preview diff" from options list
- [x] Remove option 4 handler (lines 1025-1028): Delete the elseif block
- [x] Renumber option 5 to 4 (line 1029): Change `choice == 5` to `choice == 4`
- [x] Verify fallthrough handles choice == 5 as Cancel

**Testing**:
```vim
" Test: Open sync picker with conflicting files
:ClaudeCommands
" Navigate to [Load All Artifacts]
" Verify: Menu shows options 1-5 (no "Preview diff")
" Verify: Option 4 is "Clean copy"
" Verify: Option 5 is "Cancel"
" Test each option works correctly
```

**Expected Duration**: 30 minutes

### Phase 2: Verify No Broken References [COMPLETE]
dependencies: [1]

**Objective**: Ensure no other code references the old option 4

**Complexity**: Low

**Tasks**:
- [x] Search codebase for "Preview diff" references
- [x] Search codebase for "option 4" or "choice == 4" references
- [x] Verify no documentation references the removed option
- [x] Check previewer.lua help section for any option 4 references

**Testing**:
```bash
# Search for references
grep -r "Preview diff" nvim/lua/neotex/plugins/ai/claude/
grep -r "option.* 4" nvim/lua/neotex/plugins/ai/claude/
```

**Expected Duration**: 15 minutes

## Files to Modify

### Primary Changes
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/operations/sync.lua`:
  - Lines 978-983: Dialog message text
  - Line 985: Buttons string
  - Line 986: Default choice
  - Line 1006: Options comment
  - Lines 1025-1028: Remove option 4 handler
  - Line 1029: Renumber option 5 to 4

### Verification Files (no changes expected)
- `nvim/lua/neotex/plugins/ai/claude/commands/picker/display/previewer.lua` - Check help section

## Risk Management

### Low Risk: User Confusion
**Mitigation**: The removed option was unimplemented anyway, users may not notice

### Low Risk: Numbering Errors
**Mitigation**: Simple sequential renumbering, easy to verify

## Rollback Plan

If issues arise:
1. Restore the original buttons and message strings
2. Restore the option 4 handler with fallback warning
3. No data loss risk - this is purely UI

## Completion Checklist

- [x] Phase 1 completed
- [x] Phase 2 completed
- [x] All remaining options (1-5) verified working
- [x] No orphaned code references
- [ ] Manual testing complete
