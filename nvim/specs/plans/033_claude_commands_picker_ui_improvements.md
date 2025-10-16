# Claude Commands Picker UI Improvements Implementation Plan

## ✅ IMPLEMENTATION COMPLETE

All phases completed successfully on 2025-10-08.

**Implementation Summary**: nvim/specs/summaries/033_claude_picker_ui_improvements_summary.md

## Metadata
- **Date**: 2025-10-08
- **Feature**: Claude Commands Picker (`<leader>ac`) UI Quality of Life Improvements
- **Scope**: Improve picker usability without significant refactoring
- **Estimated Phases**: 3
- **Standards File**: nvim/CLAUDE.md
- **Research Reports**: None (analysis-based improvements)

## Overview

Implement targeted UI improvements to the Claude commands picker (`<leader>ac`) based on user experience analysis. Focus on quick wins that enhance usability:

1. **Single-escape close behavior** - Currently requires `<esc><esc>` to close from insert mode, should close on first press
2. **Documentation accuracy** - Update keyboard shortcuts help text to reflect improved behavior
3. **Docs descriptions audit** - Ensure all [Docs] entries have visible descriptions in picker

These improvements address common friction points while maintaining the picker's current structure and functionality.

## Success Criteria
- [x] Picker closes immediately on single `<esc>` press from insert mode
- [x] Keyboard shortcuts help accurately describes close behavior
- [x] All docs entries display meaningful descriptions (or audit identifies which need attention)
- [x] No regressions in existing picker functionality
- [x] Changes follow project Lua coding standards

## Technical Design

### Architecture
- **Component**: Telescope picker configuration and Claude commands picker
- **Files Modified**:
  - `nvim/lua/neotex/plugins/editor/telescope.lua` - Global Telescope mappings
  - `nvim/lua/neotex/plugins/ai/claude/commands/picker.lua` - Help text update
- **Pattern**: Standard Telescope action mapping override

### Escape Behavior Fix
Current behavior:
```
Insert mode → <esc> → Normal mode → <esc> → Close
```

Desired behavior:
```
Insert mode → <esc> → Close (immediate)
```

Implementation:
```lua
-- Add to telescope.lua defaults.mappings.i:
["<esc>"] = actions.close
```

This is a standard Telescope configuration pattern used across the Neovim community to make escape behavior more intuitive.

### Description Parsing
The picker already has description parsing logic (picker.lua:160-202):
- Checks YAML frontmatter for `description:` field
- Falls back to second heading after title
- Scans first 30 lines of each .md file

Audit will identify which docs need better metadata.

## Implementation Phases

### Phase 1: Telescope Escape Mapping [COMPLETED]
**Objective**: Make escape close picker immediately from insert mode
**Complexity**: Low

Tasks:
- [x] Read current telescope.lua configuration (lines 20-62)
- [x] Add `["<esc>"] = actions.close` to insert mode mappings (after line 26)
- [x] Verify mapping doesn't conflict with existing keybinds
- [x] Test picker opens and closes with single escape

Testing:
```lua
-- Manual test:
-- 1. Open picker with <leader>ac
-- 2. Type to filter (entering insert mode)
-- 3. Press <esc> once
-- Expected: Picker closes immediately
```

Validation:
- Picker closes on first escape press
- No error messages in `:messages`
- Other telescope pickers also benefit from change

### Phase 2: Update Help Documentation [COMPLETED]
**Objective**: Update keyboard shortcuts help to reflect accurate close behavior
**Complexity**: Low

Tasks:
- [x] Read current help text in picker.lua (lines 846-896)
- [x] Update line 861 from:
  ```lua
  "  Escape      - Close picker",
  ```
  to:
  ```lua
  "  Escape      - Close picker (single press from insert mode)",
  ```
- [x] Review all help text for accuracy
- [x] Verify help displays correctly in picker preview

Testing:
```bash
# Manual test:
# 1. Open picker with <leader>ac
# 2. Navigate to [Keyboard Shortcuts] entry
# 3. Verify preview shows updated escape description
# 4. Verify formatting is consistent
```

Validation:
- Help text accurately describes behavior
- No formatting issues in preview
- Text remains within preview width

### Phase 3: Docs Description Audit [COMPLETED]
**Objective**: Identify docs entries without descriptions and document findings
**Complexity**: Low

Tasks:
- [x] Open picker and navigate to [Docs] section
- [x] Document which docs have empty/missing descriptions
- [x] For each missing description, check doc file structure:
  - Has YAML frontmatter with `description:` field?
  - Has clear second heading that could serve as description?
  - Needs manual description addition?
- [x] Create summary of findings
- [x] (Optional) Add descriptions to high-priority docs if needed

Testing:
```bash
# Manual verification:
# 1. Open picker with <leader>ac
# 2. Scroll through [Docs] entries
# 3. Check each entry has visible description
# 4. Empty descriptions should show empty space (expected if not in metadata)
```

Validation:
- All docs checked and status documented
- High-priority docs have descriptions added (if applicable)
- Description parsing logic confirmed working

## Testing Strategy

### Unit Testing
Not applicable - configuration changes don't require unit tests.

### Integration Testing
Manual verification that:
1. Telescope escape mapping works across all pickers (not just Claude commands)
2. Claude commands picker displays correct help text
3. Docs entries show descriptions where metadata exists

### Regression Testing
Verify existing functionality still works:
- All picker keyboard shortcuts (Ctrl-l, Ctrl-e, Ctrl-u, etc.)
- Command insertion on Enter
- Navigation with Ctrl-j/k
- Preview display for all entry types

## Documentation Requirements

### Files to Update
- **nvim/lua/neotex/plugins/editor/telescope.lua** - Inline comment explaining escape mapping
- **nvim/lua/neotex/plugins/ai/claude/commands/picker.lua** - Help text already self-documenting

### Documentation Changes
- Comment in telescope.lua:
  ```lua
  -- Close picker immediately on escape (no mode switch)
  ["<esc>"] = actions.close,
  ```

## Dependencies

### External Dependencies
None - uses existing Telescope actions API.

### Prerequisites
- Telescope.nvim installed and configured (already present)
- Claude commands picker functional (already present)

## Risk Assessment

### Low Risk Changes
- **Escape mapping**: Standard Telescope pattern, widely used, very low chance of issues
- **Help text update**: Documentation only, no functional changes
- **Docs audit**: Read-only analysis, no code changes

### Potential Issues
1. **User muscle memory**: Users accustomed to double-escape may accidentally close picker
   - Mitigation: This is universally considered an improvement; single-escape is more intuitive

2. **Other pickers affected**: Escape mapping is global for all Telescope pickers
   - Mitigation: This is intentional and beneficial; consistent behavior across all pickers

## Notes

### Design Decisions
- **Global vs. picker-specific mapping**: Chose global telescope.lua mapping for consistency across all pickers
- **Help text wording**: Included "(single press from insert mode)" for clarity without verbosity
- **Description audit only**: Phase 3 audits rather than fixes to avoid scope creep; actual fixes can be separate effort

### Future Enhancements (Out of Scope)
These were identified during research but deferred:
1. Dynamic keyboard shortcuts help generation (currently hardcoded)
2. Visual indicators for commands with/without children
3. Improved tree character consistency
4. YAML frontmatter templates for new docs

### Command Children Verification
Research confirmed that command children display **is** working correctly:
- `document` command shows `list-summaries` and `validate-setup` as dependents
- Logic in picker.lua:607-683 properly reads `dependent-commands:` metadata
- Tree characters (├─, └─) display hierarchy correctly

### References
- Telescope actions API: nvim-telescope/telescope.nvim
- Current picker implementation: nvim/lua/neotex/plugins/ai/claude/commands/picker.lua
- Current telescope config: nvim/lua/neotex/plugins/editor/telescope.lua
