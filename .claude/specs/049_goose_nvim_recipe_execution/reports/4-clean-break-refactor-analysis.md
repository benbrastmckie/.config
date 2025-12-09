# Clean-Break Refactoring Analysis

## Research Context

**Topic**: Clean-break approach for goose.nvim recipe execution integration
**Date**: 2025-12-09
**Requested By**: User preference for eliminating backward compatibility concerns

## User Requirements

The user explicitly stated:
- "I don't care about backwards compatibility"
- "prefer a clean-break approach"

This aligns with the project's Clean-Break Development Standard documented in CLAUDE.md.

## Clean-Break Development Standard (from CLAUDE.md)

The project follows a clean-break development philosophy:

> **Internal tooling changes**: ALWAYS use clean-break (no deprecation periods)
> **Interface changes**: Unified implementation, no compatibility wrappers

Key principles:
1. Internal tooling changes require NO deprecation periods
2. Direct replacement of default behavior (old code removed, not preserved)
3. No backwards-compatibility hacks or fallback options
4. Remove unused code completely rather than marking it deprecated

## Analysis of Current Plan

The current plan (001-goose-nvim-recipe-execution-plan.md) includes several backward compatibility provisions that should be removed:

### Items to Remove

1. **Goal 4**: "Maintain backward compatibility via optional keybindings"
   - REMOVE: The `<C-t>` keybinding for ToggleTerm fallback
   - RATIONALE: User explicitly doesn't need backward compatibility

2. **Success Criteria - item 6**: "optional `<C-t>` keybinding preserves ToggleTerm execution"
   - REMOVE: No fallback keybindings needed
   - RATIONALE: Clean-break means ToggleTerm integration is fully replaced

3. **Phase 2 Tasks**: Multiple tasks related to `<C-t>` keybinding
   - REMOVE: All tasks referencing ToggleTerm fallback
   - KEEP: Core sidebar execution keybinding tasks

4. **Dependencies Section**: ToggleTerm listed as optional dependency
   - REMOVE: "ToggleTerm plugin: Optional (only if fallback keybinding used)"
   - RATIONALE: No ToggleTerm integration needed

5. **Notes Section - "Why Preserve ToggleTerm Option?"**
   - REMOVE: Entire rationale section
   - RATIONALE: User explicitly rejected this approach

6. **Technical Design references to fallback**
   - UPDATE: Remove references to optional keybindings and fallback paths
   - SIMPLIFY: Architecture diagrams to show only sidebar execution path

## Recommended Revisions

### Metadata Changes
- Update Date to include "(Revised)"
- Reduce Estimated Hours (fewer tasks without fallback implementation)
- Reduce Estimated Phases (Phase 2 simplified significantly)

### Goal Changes
- Remove Goal 4 (backward compatibility)
- Renumber remaining goals

### Success Criteria Changes
- Remove item 6 (optional `<C-t>` keybinding)
- Remove item 7 (notification of output destination) - only one destination now
- Renumber remaining items

### Phase Changes

**Phase 2 (Picker Keybinding Updates)**:
- Remove all `<C-t>` keybinding tasks
- Simplify to just updating `<CR>` action
- Estimated duration: Reduce from 1 hour to 0.5 hours

**Phase 3 (which-key Integration)**:
- Remove references to `<C-t>` alternative
- Simplify description updates

**Phase 4 (Error Handling)**:
- Remove fallback notification ("use <C-t> for terminal")
- Keep goose.nvim-not-installed error, but no fallback suggestion

**Phase 5 (Documentation and Testing)**:
- Remove ToggleTerm comparison tests
- Remove fallback keybinding documentation

### Dependencies Changes
- Remove ToggleTerm from dependencies section entirely

### Notes Changes
- Remove "Why Preserve ToggleTerm Option?" section
- Update "Clean-Break Development" note to emphasize this approach

## Impact Assessment

### Reduced Complexity
- Fewer keybindings to implement and document
- Simpler error handling (no fallback logic)
- Cleaner architecture (single execution path)
- Estimated time reduction: ~2-3 hours

### Simplified Testing
- No need to test ToggleTerm execution path
- No need to verify fallback behavior
- No need to document two different workflows

### Cleaner Codebase
- No dead code for ToggleTerm integration
- No conditional logic for execution method selection
- Single responsibility: sidebar execution only

## Conclusion

The clean-break approach is well-aligned with project standards and user preference. The plan should be revised to remove all backward compatibility provisions, resulting in a simpler, more focused implementation.
