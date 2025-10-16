# Picker Hook Event Indicators and Tree Indentation Fix

## Metadata
- **Date**: 2025-10-08
- **Feature**: Fix hook event local indicators and standardize tree character indentation
- **Scope**: Correct hook event '*' indicator display and add consistent tree character spacing for non-command/agent artifacts
- **Estimated Phases**: 2
- **Standards File**: /home/benjamin/.config/nvim/CLAUDE.md
- **Research Reports**: Inline research completed

## Overview

Two formatting issues in the Claude command picker require correction:

1. **Hook Events Missing '*' Indicator**: Hook events don't show the '*' local indicator even when the user is in .config/ directory (which provides the global source). The root cause is that `format_hook_event()` doesn't receive the hook data containing `is_local` flags.

2. **Inconsistent Tree Character Indentation**: Tree characters (├─, └─) need one additional space of indentation for all artifact types EXCEPT commands and agents. Currently:
   - Commands/Agents: 1 space between prefix and tree char (correct)
   - Other artifacts (Docs, Lib, Templates, TTS, Hooks): 0 spaces (incorrect, need +1)

## Success Criteria
- [ ] Hook events show '*' when any associated hook is local
- [ ] Hook events in .config/ directory display '*' indicator correctly
- [ ] Tree characters for Docs, Lib, Templates, TTS Files, and Hook Events have one additional space of indentation
- [ ] Tree characters for Commands and Agents remain unchanged (1 space indentation)
- [ ] Preview pane agent cross-references have correct indentation (3 spaces before tree char)
- [ ] All existing picker functionality preserved
- [ ] Code follows Neovim configuration guidelines (nvim/CLAUDE.md)

## Technical Design

### 1. Hook Event Local Indicator Fix

**Root Cause**:
- `format_hook_event()` function (lines 67-86) only receives `event_name` and `indent_char` parameters
- Hook data with `is_local` flags exists in `event_hooks` array (created at lines 562-570) but isn't passed to formatter
- Parser.lua correctly sets `is_local` flags on hooks; issue is purely display-layer

**Design**:
- Add `event_hooks` parameter to `format_hook_event()` function signature
- Check if ANY hook in the array has `is_local = true`
- Add prefix logic: `local prefix = has_local_hook and "*" or " "`
- Update format string from `" %s %-38s %s"` to `"%s %s %-38s %s"` (add prefix parameter)
- Update call site at line 578 to pass `event_hooks` array

**Logic for Local Status**:
```lua
-- A hook event is local if ANY of its hooks are local
local has_local_hook = false
for _, hook in ipairs(event_hooks) do
  if hook.is_local then
    has_local_hook = true
    break
  end
end
```

**Implementation Location**: picker.lua lines 67-86 (function definition), line 578 (call site)

### 2. Tree Character Indentation Standardization

**Current State**:
- Commands/Agents: `"%s %s"` format (1 space between prefix and tree char) - KEEP AS-IS
- Docs/Lib/Templates: `"%s%s"` format (0 spaces) - ADD 1 SPACE
- TTS Files: `"%s%s"` format (0 spaces) - ADD 1 SPACE
- Hook Events: `" %s"` format (1 space but no prefix) - CHANGE TO 2 SPACES WITH PREFIX
- Preview cross-refs: `"  "` prefix (2 spaces) - CHANGE TO 3 SPACES

**Design**:
Change format strings to add consistent spacing:

| Location | Current Format | New Format | Line |
|----------|---------------|------------|------|
| `format_hook_event()` | `" %s %-38s %s"` | `"%s  %s %-38s %s"` | 81 |
| `format_tts_file()` | `"%s%s %-38s %s"` | `"%s %s %-38s %s"` | 97 |
| Docs inline | `"%s%s %-38s %s"` | `"%s %s %-38s %s"` | 292 |
| Lib inline | `"%s%s %-38s %s"` | `"%s %s %-38s %s"` | 351 |
| Templates inline | `"%s%s %-38s %s"` | `"%s %s %-38s %s"` | 410 |
| Preview (multi) | `"  " .. tree_char` | `"   " .. tree_char` | 1031 |
| Preview (single) | `"  └─ "` | `"   └─ "` | 1037 |

**Implementation Locations**:
- Format functions: lines 81, 97
- Inline display strings: lines 292, 351, 410
- Preview cross-references: lines 1031, 1037

### 3. Visual Result

**Before**:
```
 [Hook Events]
 ├─ SessionStart        When session begins
 └─ Stop                After command completion

 *├─ local_doc.md       Documentation
  ├─ global_lib.sh      Utility script
```

**After**:
```
 [Hook Events]
* ├─ SessionStart       When session begins (if local)
* └─ Stop               After command completion (if local)

*  ├─ local_doc.md      Documentation
   ├─ global_lib.sh     Utility script
```

Note the additional space before tree characters for non-command/agent artifacts.

## Implementation Phases

### Phase 1: Fix Hook Event Local Indicator [COMPLETED]
**Objective**: Update `format_hook_event()` to display '*' for local hooks
**Complexity**: Low

Tasks:
- [x] Read current `format_hook_event()` function (lines 67-86)
- [x] Add `event_hooks` parameter to function signature
- [x] Add loop to check if any hook in `event_hooks` has `is_local = true`
- [x] Add prefix variable: `local prefix = has_local_hook and "*" or " "`
- [x] Update format string from `" %s %-38s %s"` to `"%s  %s %-38s %s"` (adds prefix and extra space)
- [x] Update function call at line 578 to pass `event_hooks`: `format_hook_event(event_name, indent_char, event_hooks)`
- [x] Test with local hooks in .config/ directory - verify '*' appears
- [x] Test with global hooks - verify no '*' appears

Testing:
```bash
# Open picker from .config/ directory
# Navigate to [Hook Events] section
# Verify hook events show '*' indicator
# Navigate to different directory and verify global hooks don't show '*'
```

### Phase 2: Standardize Tree Character Indentation [COMPLETED]
**Objective**: Add one space of indentation for tree characters in non-command/agent artifacts
**Complexity**: Low

Tasks:
- [x] Update `format_hook_event()` line 81 format string (already updated in Phase 1 with prefix)
- [x] Update `format_tts_file()` line 97: change `"%s%s %-38s %s"` to `"%s %s %-38s %s"`
- [x] Update Docs inline line 292: change `"%s%s %-38s %s"` to `"%s %s %-38s %s"`
- [x] Update Lib inline line 351: change `"%s%s %-38s %s"` to `"%s %s %-38s %s"`
- [x] Update Templates inline line 410: change `"%s%s %-38s %s"` to `"%s %s %-38s %s"`
- [x] Update Preview cross-ref line 1031: change `"  " .. tree_char` to `"   " .. tree_char`
- [x] Update Preview cross-ref line 1037: change `"  └─ "` to `"   └─ "`
- [x] Verify Commands and Agents still use 1-space indentation (no changes to these)
- [x] Test visual alignment of all artifact types in picker
- [x] Test preview pane agent cross-references for correct indentation

Testing:
```bash
# Open picker and navigate through all sections
# Verify tree characters for Docs, Lib, Templates, TTS Files, Hook Events have extra space
# Verify Commands and Agents tree characters remain unchanged (1 space)
# Select an agent and view preview
# Verify "Commands that use this agent" section has correct 3-space indentation
# Check visual alignment is consistent and clean
```

## Testing Strategy

### Manual Testing
All changes require visual verification in Neovim:
1. Open picker from .config/ directory (local source)
2. Navigate to [Hook Events] - verify '*' indicators
3. Navigate to all other sections - verify tree character spacing
4. Open picker from different directory (global source)
5. Verify global hooks don't show '*'
6. Select various artifacts and check visual alignment
7. View agent previews and check cross-reference indentation

### Test Cases
- **Hook Events**:
  - Local hooks in .config/ directory (should show '*')
  - Global hooks from ~/.config/.claude/ (should not show '*')
  - Mixed local/global hooks in same event (should show '*' if ANY hook is local)

- **Tree Indentation**:
  - Commands: 1 space (no change)
  - Agents: 1 space (no change)
  - Docs: 1 space (changed from 0)
  - Lib: 1 space (changed from 0)
  - Templates: 1 space (changed from 0)
  - TTS Files: 1 space (changed from 0)
  - Hook Events: 2 spaces with prefix (changed from 1 without prefix)
  - Preview cross-refs: 3 spaces (changed from 2)

### Regression Testing
- All existing keybindings work (`<CR>`, `<C-e>`, `<C-l>`, `<C-u>`, `<C-s>`)
- Two-stage Return behavior preserved
- Preview focus navigation preserved
- Search and filtering work correctly
- Help section displays correctly
- All artifact types selectable and functional

## Documentation Requirements

### Files to Update
- `nvim/lua/neotex/plugins/ai/claude/commands/README.md` - Document hook indicator behavior
- Inline code comments in `picker.lua` - Document local indicator logic for hooks

### Documentation Content
- Explain hook events show '*' when any associated hook is local
- Clarify tree character indentation pattern (commands/agents vs others)
- Note that indentation provides visual hierarchy consistency

## Dependencies

### Existing Code Dependencies
- Hook data with `is_local` flags (already correctly set by parser.lua)
- Existing format functions and inline display strings
- Tree character constants (├─, └─)

### No External Dependencies
All changes are cosmetic display updates using existing data structures.

## Notes

### Design Decisions

1. **Hook Event Local Status**: Event is local if ANY hook is local (logical OR). This matches user expectation that being in .config/ makes hooks local.

2. **Indentation Consistency**: Adding one space for non-command/agent artifacts creates visual distinction between hierarchical levels without disrupting existing command/agent formatting.

3. **Preview Cross-Reference Spacing**: Increasing to 3 spaces maintains visual hierarchy - preview content is indented more than main picker display.

4. **Minimal Changes**: Only modifying format strings, no logic changes to parsing or data structures.

### Implementation Simplicity

This refactor is straightforward because:
- Hook `is_local` flags already exist in data
- Only format strings need updating
- No new logic or algorithms required
- Changes are purely cosmetic display adjustments
- All artifact types already have tree character formatting in place

### User Impact

**Benefits**:
- Hook events correctly show local indicators
- Consistent visual hierarchy across all artifact types
- Clearer distinction between local and global artifacts
- Better visual alignment in picker display

**Learning Curve**: None - purely cosmetic improvements that enhance existing behavior without changing interaction patterns.
