# Picker Fixes: Escape Hanging, Help Accuracy, Template Consistency

## Metadata
- **Date**: 2025-10-08
- **Feature**: Fix three issues in `<leader>ac` picker based on research findings
- **Scope**: Escape mapping, keyboard shortcuts help accuracy, template YAML consistency
- **Estimated Phases**: 3
- **Standards File**: nvim/CLAUDE.md
- **Research Reports**: Research conducted in /orchestrate workflow (inline findings)

## Overview

Fix three distinct issues identified through systematic research:

1. **Escape Hanging**: Picker requires double-escape to close due to missing insert mode mapping
2. **Keyboard Shortcuts Inaccuracy**: Help text contains incomplete/misleading information about Ctrl-d, Ctrl-e, and file operations
3. **Template Quote Inconsistency**: One template file lacks quoted description field

All fixes are low-risk, well-researched, and improve user experience without breaking existing functionality.

## Research Findings

### Issue 1: Escape Key Hanging
**Root Cause**: Telescope configuration missing `["<esc>"] = actions.close` in insert mode mappings
- Insert mode (telescope.lua:24-39): Has `<C-c>` but no `<esc>`
- Normal mode (telescope.lua:41): Has `<esc>` → `actions.close`
- Behavior: First escape exits insert mode, waits 100ms timeout, requires second escape
- Help text (picker.lua:861): Already documents single press but not implemented

### Issue 2: Keyboard Shortcuts Inaccuracies
**Findings**:
- **Ctrl-d** (line 860): Documented as picker feature but is redundant telescope default
- **Ctrl-e** (line 853): Claims "loads locally first if needed" but only works for Commands/Hooks
  - Implementation (picker.lua:2744-2754) missing support for: Agents, Templates, Lib, Docs, TTS
- **File Operations** (line 885-888): Incomplete documentation
  - Says works for: "Commands, Agents, Hooks, TTS Files"
  - Actually Ctrl-l/u/s work for: Commands, Agents, Hooks, TTS, Templates, Lib, Docs
  - But Ctrl-e only works for: Commands, Hooks

### Issue 3: Template Quote Inconsistency
**Findings**:
- Total templates: 4 (.claude/templates/*.yaml)
- Quoted descriptions: 3 (crud-feature, api-endpoint, refactoring)
- Unquoted description: 1 (example-feature.yaml line 2)
- Standard: Quoted strings for consistency and YAML best practices

## Success Criteria
- [ ] Escape closes picker immediately from insert mode (single press)
- [ ] Help text accurately reflects actual keyboard shortcut behavior
- [ ] All template descriptions use consistent quoted format
- [ ] No regressions in existing picker functionality
- [ ] Changes follow Lua and YAML standards

## Technical Design

### Architecture
**Components Affected**:
1. Telescope global configuration (nvim/lua/neotex/plugins/editor/telescope.lua)
2. Picker help text (nvim/lua/neotex/plugins/ai/claude/commands/picker.lua)
3. Template file (.claude/templates/example-feature.yaml)

**Pattern**: Configuration fix + documentation accuracy + format consistency

### Escape Fix Design
Add escape mapping to telescope insert mode (line ~27):
```lua
i = {
  ["<C-j>"] = actions.move_selection_next,
  ["<C-k>"] = actions.move_selection_previous,
  ["<C-c>"] = actions.close,
  ["<esc>"] = actions.close,  -- ADD THIS
  ["<Down>"] = actions.move_selection_next,
  -- ... rest of mappings
},
```

**Impact**: All telescope pickers benefit (intentional, beneficial consistency)

### Help Text Corrections
Three specific updates needed:

1. **Remove Ctrl-d entry** (redundant telescope default):
   ```diff
   - "  Ctrl-d      - Scroll preview down",
   ```

2. **Clarify Ctrl-e limitations**:
   ```diff
   - "  Ctrl-e      - Edit artifact file (loads locally first if needed)",
   + "  Ctrl-e      - Edit artifact file (Commands and Hooks only)",
   ```

3. **Expand file operations description**:
   ```diff
   - "File Operations (Ctrl-l/u/s/e):",
   - "  Work for: Commands, Agents, Hooks, TTS Files",
   + "File Operations:",
   + "  Ctrl-l/u/s  - Work for: Commands, Agents, Hooks, TTS, Templates, Lib, Docs",
   + "  Ctrl-e      - Edit file (Commands and Hooks only)",
   ```

### Template Fix Design
Add quotes to description in example-feature.yaml:
```diff
- description: Template for creating a new feature with tests and documentation
+ description: "Template for creating a new feature with tests and documentation"
```

## Implementation Phases

### Phase 1: Fix Telescope Escape Mapping
**Objective**: Add escape mapping to telescope insert mode to eliminate hanging
**Complexity**: Low

Tasks:
- [ ] Read telescope.lua insert mode mappings section (lines 24-39)
- [ ] Add `["<esc>"] = actions.close` after `["<C-c>"]` line (around line 27)
- [ ] Verify no conflicts with existing mappings
- [ ] Add inline comment: `-- Close picker immediately (no mode switch)`

Testing:
```lua
-- Manual test in Neovim:
-- 1. Open any telescope picker (e.g., :Telescope find_files)
-- 2. Start typing to enter insert mode
-- 3. Press <esc> once
-- Expected: Picker closes immediately without delay
```

Validation:
- Picker closes on first escape press
- No 100ms timeout delay observed
- Works across all telescope pickers (find_files, live_grep, etc.)
- Help text in picker.lua:861 now matches actual behavior

### Phase 2: Update Keyboard Shortcuts Help Text
**Objective**: Correct inaccuracies and incomplete information in help text
**Complexity**: Low

Tasks:
- [ ] Read current help text in picker.lua (lines 848-894)
- [ ] Remove line 860: `"  Ctrl-d      - Scroll preview down",`
- [ ] Update line 856 (Ctrl-e) to: `"  Ctrl-e      - Edit artifact file (Commands and Hooks only)",`
- [ ] Update lines 885-888 (File Operations section):
  ```lua
  "File Operations:",
  "  Ctrl-l/u/s  - Work for: Commands, Agents, Hooks, TTS, Templates, Lib, Docs",
  "  Ctrl-e      - Edit file (Commands and Hooks only)",
  "  Preserves executable permissions for .sh files",
  ```
- [ ] Verify formatting and line length consistency

Testing:
```bash
# Manual verification:
# 1. Open picker with <leader>ac
# 2. Navigate to [Keyboard Shortcuts] entry
# 3. Verify preview shows:
#    - No Ctrl-d entry (removed)
#    - Ctrl-e clarifies Commands/Hooks limitation
#    - File operations section clearly separates Ctrl-l/u/s vs Ctrl-e
# 4. Test actual shortcuts to confirm accuracy:
#    - Try Ctrl-e on a Template → should NOT work
#    - Try Ctrl-l on a Template → should work
```

Validation:
- Help text accurately reflects implementation
- No misleading or incomplete information
- Formatting consistent with other help entries
- Line length within 80-100 character guideline

### Phase 3: Fix Template Quote Consistency
**Objective**: Apply consistent quoted format to all template descriptions
**Complexity**: Low

Tasks:
- [ ] Read .claude/templates/example-feature.yaml
- [ ] Locate description field (line 2)
- [ ] Add quotes around description value
- [ ] Verify YAML remains valid after change

Testing:
```bash
# Validate YAML syntax:
# (If yamllint available)
yamllint .claude/templates/example-feature.yaml

# Or test in picker:
# 1. Open picker with <leader>ac
# 2. Navigate to [Templates] section
# 3. Verify example-feature displays correctly
# 4. Try Ctrl-l to load it (should work without YAML errors)
```

Validation:
- Description field properly quoted
- YAML file remains valid
- Template displays correctly in picker
- Consistent with other templates (crud-feature, api-endpoint, refactoring)

## Testing Strategy

### Manual Integration Testing
After all phases:
1. **Escape behavior**:
   - Open `<leader>ac` picker
   - Type to filter (enter insert mode)
   - Press escape once → picker closes immediately

2. **Help text accuracy**:
   - Open picker, navigate to [Keyboard Shortcuts]
   - Verify all documented shortcuts match actual behavior
   - Test Ctrl-e on different artifact types (should only work for Commands/Hooks)

3. **Template consistency**:
   - Navigate to [Templates] section
   - Verify all templates display descriptions
   - Load example-feature template to test YAML validity

### Regression Testing
Verify existing functionality:
- All keyboard shortcuts still work (Ctrl-l, Ctrl-u, Ctrl-s, Ctrl-n)
- Navigation with Ctrl-j/k still functions
- Preview scrolling with Ctrl-u/d still works (telescope default)
- All artifact types display correctly

## Documentation Requirements

### Inline Comments
- **telescope.lua**: Add comment explaining escape mapping purpose
- **picker.lua**: Help text is self-documenting

### No README Updates Needed
These are internal fixes; no user-facing documentation changes required beyond the help text itself.

## Dependencies

### External Dependencies
None - uses existing Telescope actions API and standard YAML format.

### Prerequisites
- Telescope.nvim installed (already present)
- Claude commands picker functional (already present)
- Template system operational (already present)

## Risk Assessment

### Low Risk Changes
1. **Escape mapping**: Standard telescope pattern, affects all pickers beneficially
2. **Help text**: Documentation only, no functional changes
3. **Template quotes**: YAML syntax improvement, backward compatible

### Potential Issues
1. **User muscle memory**: Users accustomed to double-escape
   - Mitigation: Single-escape is universally preferred; this is an improvement

2. **Ctrl-e expectations**: Users may expect Ctrl-e to work on all artifacts
   - Mitigation: Help text now clearly documents limitations; implementation unchanged

3. **YAML parsing**: Quoting might affect template parsing
   - Mitigation: Quoted strings are standard YAML; other templates already use this format

## Notes

### Design Decisions

**Why not implement Ctrl-e for all artifact types?**
- Out of scope for this fix (accuracy vs feature expansion)
- Each artifact type needs custom editor integration
- Current help text claims broader support than implemented
- Better to accurately document than promise unsupported features

**Why remove Ctrl-d from help?**
- It's a telescope default, not picker-specific
- Documenting defaults creates maintenance burden
- Help should focus on picker-specific shortcuts
- Users can still use Ctrl-d (telescope provides it)

**Why quoted strings in YAML?**
- Consistency across all templates
- Prevents parsing issues with special characters
- YAML best practice for string values
- Already the majority pattern (3/4 templates)

### Research Validation
All fixes directly address research findings:
- ✅ Issue 1: Escape hanging → Add insert mode mapping
- ✅ Issue 2: Help inaccuracies → Correct Ctrl-d/e/file ops
- ✅ Issue 3: Template quotes → Standardize to quoted format

### Command Integration
This plan is designed for `/implement` compatibility with:
- Clear phase boundaries
- Specific file references and line numbers
- Manual testing instructions
- Checkbox-based task tracking

## Related Work

### Previous Picker Improvements
- Plan 033: Parser fix for docs descriptions (completed)
- This plan (034): Escape, help text, template consistency
- Future: Consider implementing Ctrl-e for all artifact types

### Escape Mapping History
- Initial issue: Required double-escape (mode switch + close)
- Plan 033 attempted fix but missed insert mode mapping
- This plan completes the escape behavior fix
