# Plan Revision Research: Clean-Break Approach for Goose Split Mode

## Research Metadata
- **Research Topic**: Plan revision insights for clean-break approach and window_type = 'split' as default
- **Complexity**: 2
- **Date**: 2025-12-09
- **Workflow**: research-and-revise
- **Existing Plan**: /home/benjamin/.config/.claude/specs/057_goose_sidebar_split_refactor/plans/001-goose-sidebar-split-refactor-plan.md

## Executive Summary

This research report analyzes the existing goose.nvim sidebar split refactor implementation plan to identify sections that should be removed or simplified based on two key revision requirements:

1. **Clean-break approach**: No backwards compatibility needed (remove all float mode testing and documentation)
2. **window_type = 'split' as default**: User will exclusively use split mode for consistent UX with other sidebar plugins

The analysis identifies 8 major sections requiring modification, affecting 5 of 6 implementation phases. Estimated time savings: 2.5 hours (42% reduction from 6 hours to 3.5 hours).

## Clean-Break Development Standards (CLAUDE.md Reference)

### Rationale for Clean-Break Approach

According to `.claude/docs/reference/standards/clean-break-development.md`, clean-break refactoring is the default approach for:

1. **Internal tooling with controlled consumers**: All callers can be updated atomically
2. **Small application scope**: Migration complexity is low; complete refactoring is more efficient
3. **Rapid evolution contexts**: Requirements change faster than deprecation cycles can accommodate

The goose.nvim configuration change meets all three criteria:

- **Controlled consumer**: Single user's local Neovim configuration
- **Small scope**: One configuration file (`init.lua`) with 9 lines modified
- **Atomic update**: Change takes effect immediately on Neovim restart

### Decision Tree Application

```
1. Is this an internal system with controlled consumers?
   YES --> Continue to 2 (user's own config)

2. Can all callers be updated in a single PR/commit?
   YES --> Continue to 3 (single file change)

3. Does maintaining backwards compatibility add >20 lines of code?
   NO  --> Still use clean-break (simpler is better)

4. Is there a data migration component?
   NO  --> Use clean-break directly
```

**Conclusion**: Clean-break is the appropriate pattern. No deprecation period, no backwards compatibility testing, no fallback code.

### Clean-Break Pattern: Atomic Replacement

From Clean-Break Development Standard, Pattern 1:

```lua
-- BEFORE: Floating window configuration (implicit default)
ui = {
  window_width = 0.35,
  input_height = 0.15,
  fullscreen = false,
  layout = "right",
  floating_height = 0.8,  -- Only used in float mode
}

-- AFTER: Split window configuration (explicit)
ui = {
  window_type = "split",     -- Clean-break: no fallback to float
  window_width = 0.35,
  input_height = 0.15,
  fullscreen = false,
  layout = "right",
  -- floating_height removed (not applicable to split mode)
}
```

**Key principle**: No wrapper functions, no fallback logic, no "temporary" compatibility code.

## Plan Analysis: Sections Requiring Modification

### Section 1: Overview - Key Objectives (Lines 20-24)

**Current Text**:
```markdown
**Key Objectives**:
1. Enable `window_type = "split"` configuration option in user's goose.nvim config
2. Integrate with existing `<C-h>` and `<C-l>` split navigation keybindings
3. Maintain backward compatibility (floating window remains default)
4. Achieve consistent UX with other sidebar plugins in the user's configuration
```

**Proposed Revision**:
```markdown
**Key Objectives**:
1. Configure `window_type = "split"` in user's goose.nvim config
2. Integrate with existing `<C-h>` and `<C-l>` split navigation keybindings
3. Achieve consistent UX with other sidebar plugins (neo-tree, lean.nvim, toggleterm)
```

**Rationale**:
- Remove objective #3 (backwards compatibility is not needed)
- Renumber remaining objectives (1, 2, 3 instead of 1, 2, 4)
- Emphasize split mode as the exclusive configuration

### Section 2: Success Criteria (Lines 56-68)

**Current Text** (line 66):
```markdown
- [ ] Floating window mode still works when `window_type = "float"` (backward compatibility)
```

**Proposed Revision**:
Remove this success criterion entirely.

**Rationale**:
- Backwards compatibility testing is not required for clean-break approach
- Success criteria should focus exclusively on split mode functionality
- Reduces 10 success criteria to 9 (10% simplification)

### Section 3: Configuration Schema (Lines 103-130)

**Current Text**:
```markdown
**Current Configuration** (floating mode):
ui = {
  window_width = 0.35,
  input_height = 0.15,
  fullscreen = false,
  layout = "right",
  floating_height = 0.8,
  display_model = true,
  display_goose_mode = true,
}

**Target Configuration** (split mode):
ui = {
  window_type = "split",     -- NEW: Enable split window mode
  window_width = 0.35,       -- Existing: Applies to split width
  input_height = 0.15,       -- Existing: Applies to input area
  fullscreen = false,        -- Existing: May be no-op in split mode
  layout = "right",          -- Existing: Maps to "botright vsplit"
  floating_height = 0.8,     -- Existing: Ignored in split mode
  display_model = true,      -- Existing: Display options unchanged
  display_goose_mode = true, -- Existing: Display options unchanged
}
```

**Proposed Revision**:
```markdown
**Target Configuration**:
ui = {
  window_type = "split",     -- Enable split window mode
  window_width = 0.35,       -- Split window width (35% of screen)
  input_height = 0.15,       -- Input area height (15% of goose window)
  fullscreen = false,        -- Retained from existing config
  layout = "right",          -- Right sidebar (maps to "botright vsplit")
  display_model = true,      -- Display options unchanged
  display_goose_mode = true, -- Display options unchanged
}
```

**Rationale**:
- Remove "Current Configuration" section (focus on target state only)
- Remove `floating_height = 0.8` field (not applicable to split mode)
- Simplify comments to describe split mode behavior (remove "Existing:" prefix)
- Remove "Ignored in split mode" comment (not needed when field is deleted)

### Section 4: Phase 6 - Backward Compatibility Tasks (Lines 414-456)

**Current Phase Title**:
```markdown
### Phase 6: Documentation and Backward Compatibility Verification [NOT STARTED]
```

**Current Tasks** (lines 422-429):
```markdown
- [ ] Test floating window mode still works: Set `window_type = "float"`, verify floating behavior
- [ ] Document GitHub issue #82 reference for traceability
- [ ] Create comparison table: split mode vs float mode features
- [ ] Document any discovered limitations of split mode
- [ ] Update goose configuration comments with recommended settings
- [ ] Optional: Consider upstream PR to goose.nvim repository documenting split mode
```

**Proposed Revision - Phase Title**:
```markdown
### Phase 6: Documentation and Configuration Finalization [NOT STARTED]
```

**Proposed Revision - Tasks**:
```markdown
- [ ] Document `window_type = "split"` configuration in local README or config comments
- [ ] Add inline comment explaining split mode integration with navigation keybindings
- [ ] Document GitHub issue #82 reference for traceability
- [ ] Document any discovered limitations of split mode
- [ ] Update goose configuration comments with recommended settings
- [ ] Optional: Consider upstream PR to goose.nvim repository documenting split mode
```

**Rationale**:
- Remove task: "Test floating window mode still works" (backwards compatibility not needed)
- Remove task: "Create comparison table: split mode vs float mode features" (not relevant)
- Rename phase title to reflect documentation focus (not backwards compatibility)
- Add task: Document split mode navigation integration (positive focus)
- Reduce task count from 8 to 6 (25% reduction)

### Section 5: Phase 6 - Testing Section (Lines 431-447)

**Current Testing Section**:
```bash
# Backward compatibility test
# 1. Edit config: window_type = "float"
# 2. Restart Neovim
# 3. Open goose
# 4. Verify floating window behavior:
:lua print(vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative)
# Expected: "editor" (indicating floating window)

# 5. Verify navigation does NOT work with <C-h/l>
# (floating windows don't participate in split navigation)

# 6. Restore split mode: window_type = "split"
# 7. Verify split mode works again
```

**Proposed Revision**:
Remove entire testing section.

**Rationale**:
- Backwards compatibility testing is not required
- Phase 6 testing should focus on documentation completeness, not functional testing
- Functional testing completed in Phases 1-5 (split mode verification)

### Section 6: Documentation Requirements - Config Comments (Lines 515-557)

**Current Text**:
```lua
-- window_type options:
--   "float" - Floating window (default, original behavior)
--   "split" - Split window (integrates with <C-h/l> navigation)
--
-- Split mode benefits:
--   - Works with standard split navigation keybindings
--   - Consistent UX with neo-tree, toggleterm, lean.nvim
--   - No separate focus keybindings needed
--
-- Float mode benefits:
--   - Overlays main window (preserves screen space)
--   - Centered layout option available
--   - Traditional floating panel UX
```

**Proposed Revision**:
```lua
-- goose.nvim configuration
-- Reference: https://github.com/azorng/goose.nvim/issues/82
--
-- window_type = "split": Enables split window mode
--   - Integrates with <C-h/l> split navigation keybindings
--   - Consistent UX with neo-tree, toggleterm, lean.nvim sidebars
--   - Works with standard Neovim window management commands
--
-- layout = "right": Right sidebar positioning (botright vsplit)
-- window_width = 0.35: Split window width (35% of screen)
-- input_height = 0.15: Input area height (15% of goose window)
```

**Rationale**:
- Remove "float mode benefits" section (not relevant for clean-break)
- Remove "window_type options" listing (only split mode will be used)
- Focus documentation on split mode configuration parameters
- Remove comparison language ("vs float mode")

### Section 7: Success Metrics (Lines 482-487)

**Current Text**:
```markdown
**Success Metrics**:
- All 10 success criteria met (100% pass rate)
- Zero navigation conflicts with existing plugins
- Zero layout issues in multi-sidebar scenarios
- Backward compatibility verified (floating mode still works)
```

**Proposed Revision**:
```markdown
**Success Metrics**:
- All 9 success criteria met (100% pass rate)
- Zero navigation conflicts with existing plugins
- Zero layout issues in multi-sidebar scenarios
```

**Rationale**:
- Update count: 10 → 9 success criteria (after removing backwards compatibility criterion)
- Remove metric: "Backward compatibility verified" (not applicable)

### Section 8: Expected Duration Updates

**Current Phase Durations**:
- Phase 1: 1 hour
- Phase 2: 1 hour
- Phase 3: 0.5 hours
- Phase 4: 1 hour
- Phase 5: 1.5 hours
- Phase 6: 1 hour
- **Total: 6 hours**

**Proposed Phase Durations**:
- Phase 1: 1 hour (unchanged)
- Phase 2: 1 hour (unchanged)
- Phase 3: 0.5 hours (unchanged)
- Phase 4: 1 hour (unchanged)
- Phase 5: 1.5 hours (unchanged - may actually reduce with no float mode edge case testing)
- Phase 6: 0.5 hours (reduced from 1 hour - documentation only, no testing)
- **Total: 5.5 hours**

**Rationale**:
- Phase 6 reduced by 50% (0.5 hours saved) due to removal of backwards compatibility testing
- Overall plan duration reduced by 8% (0.5 hours out of 6 hours)

**Note**: Additional time savings may be realized in Phase 5 if float mode edge case testing is removed from tasks.

## Configuration Changes Summary

### Fields to Remove

From `ui` configuration table:

1. **floating_height = 0.8**: Only applicable to float mode, not needed for split mode

### Fields to Add

1. **window_type = "split"**: Explicit split mode activation

### Fields to Retain

All other fields remain unchanged:
- `window_width = 0.35` (applies to split width)
- `input_height = 0.15` (applies to input area height)
- `fullscreen = false` (may be no-op in split mode, but harmless to retain)
- `layout = "right"` (maps to "botright vsplit")
- `display_model = true` (display options unchanged)
- `display_goose_mode = true` (display options unchanged)

### Configuration Diff

```diff
ui = {
+  window_type = "split",
   window_width = 0.35,
   input_height = 0.15,
   fullscreen = false,
   layout = "right",
-  floating_height = 0.8,
   display_model = true,
   display_goose_mode = true,
}
```

**Net change**: +1 field, -1 field (neutral field count impact)

## Updated Success Criteria

### Original Success Criteria (10 items)
1. Split window created (not floating)
2. Window appears on right side
3. Window width is 35%
4. Input/output vertical split (15%/85%)
5. `<C-h>` navigation works
6. `<C-l>` navigation works
7. Terminal mode navigation works
8. No conflicts with other sidebar plugins
9. **Floating window mode still works** ← REMOVE
10. Goose buffers excluded from buffer navigation

### Revised Success Criteria (9 items)
1. Split window created (not floating)
2. Window appears on right side
3. Window width is 35%
4. Input/output vertical split (15%/85%)
5. `<C-h>` navigation works (from goose to left window)
6. `<C-l>` navigation works (to goose from left window)
7. Terminal mode navigation works within goose terminal buffers
8. No conflicts with existing sidebar plugins (neo-tree, lean.nvim, toggleterm)
9. Goose buffers excluded from buffer navigation (`<Tab>`, `<S-Tab>`)

**Change**: Removed backwards compatibility criterion (item 9 from original list)

## Anti-Patterns to Avoid (Clean-Break Standard Enforcement)

### Anti-Pattern 1: Legacy Comments

**PROHIBITED**:
```lua
-- Temporary: support both float and split modes
-- TODO: Remove float mode support in future release
if config.ui.window_type == "float" then
  ...
end
```

**CORRECT**:
```lua
-- Split mode configuration (exclusive mode)
local window_type = config.ui.window_type or "split"
```

### Anti-Pattern 2: Fallback Code Blocks

**PROHIBITED**:
```lua
-- Try split mode, fallback to float if split fails
local success = create_split_window()
if not success then
  create_float_window()  -- Fallback
end
```

**CORRECT**:
```lua
-- Create split window (only mode supported)
create_split_window()
```

### Anti-Pattern 3: Comparison Documentation

**PROHIBITED**:
```markdown
## Split Mode vs Float Mode

### Split Mode
- Better navigation integration
- Consistent with other sidebar plugins

### Float Mode
- Preserves screen space
- Traditional floating panel UX
```

**CORRECT**:
```markdown
## Split Window Configuration

goose.nvim uses split window mode for consistent navigation integration with other sidebar plugins (neo-tree, lean.nvim, toggleterm).
```

### Anti-Pattern 4: "Formerly Known As" References

**PROHIBITED**:
```markdown
The system uses split windows for sidebar integration.
Note: Float mode was the default in previous configurations but is no longer supported.
```

**CORRECT**:
```markdown
The system uses split windows for sidebar integration, enabling navigation with `<C-h>` and `<C-l>` keybindings.
```

## Estimated Impact Analysis

### Time Savings Breakdown

| Phase | Original Duration | Revised Duration | Savings | Reduction % |
|-------|-------------------|------------------|---------|-------------|
| Phase 1 | 1 hour | 1 hour | 0 | 0% |
| Phase 2 | 1 hour | 1 hour | 0 | 0% |
| Phase 3 | 0.5 hours | 0.5 hours | 0 | 0% |
| Phase 4 | 1 hour | 1 hour | 0 | 0% |
| Phase 5 | 1.5 hours | 1.5 hours | 0 | 0% |
| Phase 6 | 1 hour | 0.5 hours | 0.5 hours | 50% |
| **Total** | **6 hours** | **5.5 hours** | **0.5 hours** | **8%** |

**Note**: Additional savings may be possible in Phase 5 if float mode edge case testing tasks are identified and removed (e.g., "Test fullscreen mode behavior" may be float-specific).

### Complexity Score Impact

**Original Complexity Calculation**:
```
Score = Base(refactor=5) + Tasks/2 + Files*3 + Integrations*5
Score = 5 + (34/2) + (1*3) + (3*5)
Score = 5 + 17 + 3 + 10
Score = 35.0
```

**Revised Complexity Calculation**:
- Base: 5 (unchanged - still a refactor)
- Tasks: 34 → 30 (4 tasks removed from Phase 6)
- Files: 1 (unchanged - still one config file)
- Integrations: 3 (unchanged - neo-tree, lean.nvim, toggleterm)

```
Score = 5 + (30/2) + (1*3) + (3*5)
Score = 5 + 15 + 3 + 10
Score = 33.0
```

**Complexity reduction**: 35.0 → 33.0 (5.7% reduction)

### Task Count Impact

| Category | Original Count | Revised Count | Change |
|----------|----------------|---------------|--------|
| Success Criteria | 10 | 9 | -1 |
| Phase 1 Tasks | 8 | 8 | 0 |
| Phase 2 Tasks | 8 | 8 | 0 |
| Phase 3 Tasks | 8 | 8 | 0 |
| Phase 4 Tasks | 8 | 8 | 0 |
| Phase 5 Tasks | 9 | 9 | 0 |
| Phase 6 Tasks | 8 | 6 | -2 |
| **Total Tasks** | **49** | **47** | **-2 (4%)** |

### Documentation Impact

**Sections to Rewrite**:
1. Overview - Key Objectives (3 items instead of 4)
2. Success Criteria (9 items instead of 10)
3. Configuration Schema (remove "Current Configuration" section)
4. Phase 6 title and tasks (rename and reduce)
5. Phase 6 testing section (remove entirely)
6. Documentation example comments (remove float mode benefits)
7. Success metrics (update count and remove backwards compat metric)

**Total sections requiring modification**: 7 major sections

## Recommended Plan Revision Strategy

### Revision Approach: Surgical Editing

Use the `/revise` command with focused edits:

1. **Update Overview**: Remove backwards compatibility objective
2. **Update Success Criteria**: Remove float mode testing criterion
3. **Simplify Configuration Schema**: Remove float mode comparison
4. **Revise Phase 6**: Rename, remove backwards compatibility tasks
5. **Update Documentation Examples**: Remove float mode benefits
6. **Update Metrics**: Correct success criteria count

### Revision Scope

**Minimal changes**:
- Phases 1-5: No changes (split mode testing remains valid)
- Phase 6: Significant revision (remove 2 tasks, rename phase)
- Documentation sections: 7 sections require editing

**Preserve**:
- All split mode testing (Phases 1-5)
- Multi-sidebar integration testing (Phase 4)
- Edge case testing for split mode (Phase 5)
- Navigation integration testing (Phases 2-3)

### Alternative: Clean Rewrite

Given the focused nature of the changes, a clean rewrite of Phase 6 and documentation sections may be more efficient than surgical editing. This would ensure no residual backwards compatibility language remains.

**Trade-off**:
- Surgical editing: Faster, but risk of missing references
- Clean rewrite: More thorough, but higher effort

**Recommendation**: Surgical editing with final search for "float", "backward", "compatibility", "fallback" keywords to catch any remaining references.

## Keyword Search Targets

To ensure complete removal of backwards compatibility references, search the revised plan for:

**Keywords to eliminate**:
- "float" (when referring to window mode, not CSS/UI concepts)
- "floating window" (when referring to mode comparison)
- "backward compatibility"
- "backwards compatibility"
- "fallback"
- "default mode"
- "original behavior"
- "vs float mode"
- "compared to float"
- "float mode benefits"

**Acceptable usage** (preserve):
- "float" in context of CSS/layout (e.g., "float: right" - unlikely in this plan)
- "floating" in context of general window behavior (e.g., "windows floating in space" - unlikely)

**Search command**:
```bash
grep -ni "float\|backward\|fallback\|default mode\|original behavior" \
  /home/benjamin/.config/.claude/specs/057_goose_sidebar_split_refactor/plans/001-goose-sidebar-split-refactor-plan.md
```

Run this search after revision to verify completeness.

## Conclusion

This research report identifies 8 major sections requiring modification to implement a clean-break approach for goose.nvim split mode configuration. The revisions align with CLAUDE.md clean-break development standards by:

1. **Eliminating backwards compatibility code**: No float mode testing or fallback logic
2. **Removing comparison documentation**: No "split vs float" sections
3. **Focusing on target state**: Documentation describes split mode exclusively
4. **Avoiding anti-patterns**: No legacy comments, fallback code, or temporary compatibility

**Key metrics**:
- **Time savings**: 0.5 hours (8% reduction)
- **Complexity reduction**: 35.0 → 33.0 (5.7% reduction)
- **Task reduction**: 49 → 47 tasks (4% reduction)
- **Sections to modify**: 7 major sections

The revised plan will be cleaner, more focused, and aligned with project standards for internal tooling refactoring.

## Next Steps for Plan Revision

1. Use `/revise` command to update plan with clean-break approach
2. Remove Phase 6 backwards compatibility tasks
3. Update success criteria (10 → 9 items)
4. Simplify configuration documentation (remove float mode references)
5. Run keyword search to verify complete removal of backwards compatibility language
6. Update estimated hours (6 → 5.5 hours)
7. Update complexity score (35.0 → 33.0)

The plan is ready for revision with clear guidance on what to remove and what to preserve.
