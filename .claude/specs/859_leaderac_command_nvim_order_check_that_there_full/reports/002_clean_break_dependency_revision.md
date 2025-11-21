# Clean-Break Approach: Dependency Revision Analysis

## Metadata
- **Date**: 2025-11-20
- **Agent**: research-specialist
- **Topic**: Plan revision insights for maintaining clean-break approach with unified dependency updates
- **Report Type**: codebase analysis

## Executive Summary

The current plan for refactoring the Claude artifacts picker contradicts clean-break philosophy by overemphasizing backward compatibility (lines 25, 53, 298-301, 498, 620, 641, 645-646) when project standards explicitly prioritize coherence over compatibility. The nvim codebase follows a "Systematic Migration Process" (nvim/docs/CODE_STANDARDS.md:41-47) requiring atomic updates of ALL references, complete removal of old implementations, and documentation reflecting only current patterns. The plan's facade pattern (line 275-301) is correctly designed but mispositioned as a compatibility preservation mechanism rather than a clean architectural boundary. Key conflicts: (1) Phase 5 creates migration guide (line 456) explicitly banned by writing standards, (2) backward compatibility testing (line 498) should be functional testing of new architecture, (3) rollback plan references "old implementation" (line 646) when clean-break requires complete replacement. Recommendations: Remove all backward compatibility language, reframe facade as permanent architectural pattern, eliminate migration guide, adopt atomic all-references update strategy, and ensure documentation describes only the modular architecture without historical comparisons.

## Findings

### Finding 1: Facade Pattern Mischaracterized as Compatibility Layer

**Location**: /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md:275-301

**Current Approach**: Plan describes `picker.lua` as "Facade/compatibility layer" (line 90) and "compatibility layer" (line 275) with purpose to "maintain backward compatibility" (lines 298-301).

**Clean-Break Standard**: nvim/docs/CODE_STANDARDS.md:25-47 states "Code quality and coherence take priority over backward compatibility" and "Remove deprecated patterns entirely rather than maintaining compatibility layers."

**Analysis**:
The facade pattern itself is architecturally sound - keeping `picker.lua` as a stable entry point while modularizing internals is good design. However, the plan justifies it with backward compatibility rather than architectural quality.

**Evidence from Plan**:
```markdown
# Lines 275-295
**Facade Pattern**: Keep `picker.lua` as compatibility layer

-- picker.lua (new facade)
local new_picker = require("neotex.plugins.ai.claude.commands.picker.init")

M.show_commands_picker = function(opts)
  return new_picker.show(opts)
end

-- Deprecated functions with warnings
M.load_command_locally = function(...)
  vim.notify("Deprecated: Use operations.load()", vim.log.levels.WARN)
  return new_picker.operations.load(...)
end
```

**Issue**: The "Deprecated functions with warnings" approach (lines 288-292) contradicts clean-break principle. nvim/docs/CODE_STANDARDS.md:41-47 requires:
1. Map all usages of old implementation
2. Update ALL references in single atomic change
3. Remove old implementation completely

**What It Should Be**: `picker.lua` should be a permanent architectural facade providing a stable public API, not a temporary compatibility shim. The module structure should be:
- `picker.lua` - Public API (permanent)
- `picker/` - Internal implementation (private modules)

This is the "Single Source of Truth" principle from nvim/docs/CODE_STANDARDS.md:11-15.

### Finding 2: Migration Guide Creation Violates Writing Standards

**Location**: Plan lines 456, 559-572

**Plan Statement**:
- Line 456: "Write migration guide from monolithic to modular (file: picker/MIGRATION.md)"
- Line 559-572: Documents migration guide content requirements

**Standard**: .claude/docs/concepts/writing-standards.md:56 explicitly states: "No migration guides: Do not create migration guides or compatibility documentation for refactors"

**nvim-Specific Standard**: nvim/docs/CODE_STANDARDS.md:32 states "Trust git history for historical context"

**Evidence from Writing Standards**:
```markdown
# writing-standards.md:309-347
### Migration Guides
Separate documents for version upgrades:
```

Migration guides are permitted only for versioned product releases, not internal refactoring.

**Contradiction**: The picker refactor is an internal code reorganization, not a user-facing API version change. Creating MIGRATION.md violates both:
1. Clean-break documentation policy (no historical context in functional docs)
2. nvim code standards (git history provides migration context)

**Correct Approach**:
- Phase 5 should create only functional documentation (README.md files)
- Architecture documentation should describe current modular structure
- No temporal language ("migrating from", "old approach", "new approach")

### Finding 3: Backward Compatibility Language Throughout Plan

**Location**: Multiple sections (lines 25, 53, 298-301, 498, 620, 641, 645-646)

**Violations Found**:

1. **Line 25**: "Maintain 100% backward compatibility with existing workflows"
2. **Line 53**: "Progressive modularization preserving backward compatibility"
3. **Lines 298-301**: "API Stability", "backward compatible", "Gradual migration path"
4. **Line 498**: "Backward compatibility with existing API" as integration test
5. **Line 620**: "Breaking backward compatibility" as technical risk
6. **Line 641**: "100% backward compatibility" as success metric
7. **Lines 645-646**: "Facade layer continues delegating to old implementation"

**Standard Violation**: .claude/docs/concepts/writing-standards.md:25-26 states "Prioritize coherence over compatibility: Clean, well-designed refactors are preferred over maintaining backward compatibility"

**nvim Standard Violation**: nvim/docs/CODE_STANDARDS.md:27-28 states "Code quality and coherence take priority over backward compatibility"

**Analysis**:
The plan frames the refactor as a compatibility preservation exercise when standards require it to be a clean quality improvement. This mindset leads to:
- Keeping deprecated functions (line 288-292)
- Planning gradual migration (line 301)
- Testing old API instead of new architecture (line 498)

**Correct Framing**:
- **Goal**: Create a modular, maintainable picker architecture
- **Constraint**: Preserve user-facing functionality (keybindings, features)
- **Non-goal**: Preserve internal implementation details or function signatures

The difference is subtle but critical: Users should see no change in behavior, but the implementation can and should be completely rewritten.

### Finding 4: Systematic Migration Process Not Followed

**Location**: nvim/docs/CODE_STANDARDS.md:41-47

**Standard Process**:
```markdown
**Systematic Migration Process**:
1. **Map all usages** of the old implementation
2. **Design new architecture** without legacy constraints
3. **Update ALL references** in a single, atomic change
4. **Remove old implementation** completely
5. **Test thoroughly** to ensure functionality preserved
6. **Update documentation** to reflect only current patterns
```

**Plan Approach**: Phases 1-4 incrementally build new modules while keeping old `picker.lua` functional, then Phase 5 documents both old and new.

**Gap Analysis**:

**Step 1 (Map usages)**: ✓ Implicitly done - picker.lua is only called from keybinding
**Step 2 (Design new)**: ✓ Phase 1 correctly designs modular architecture
**Step 3 (Update ALL)**: ✗ Plan doesn't identify all callers and update atomically
**Step 4 (Remove old)**: ✗ Plan keeps old implementation in facade with deprecation warnings
**Step 5 (Test thoroughly)**: ✓ Comprehensive testing strategy
**Step 6 (Update docs)**: ✗ Creates migration guide instead of current-state docs

**What's Missing**:
The plan needs a task in Phase 1:
- [ ] Identify all callers of picker.lua functions (grep codebase)
- [ ] Update all callers to use new module structure in single commit
- [ ] Remove all old function implementations from picker.lua
- [ ] Verify no references to old patterns remain

**Current References to Find**:
```lua
-- nvim configuration likely has:
require('neotex.plugins.ai.claude.commands.picker').show_commands_picker()
-- Or direct vim.keymap.set calls
```

These should be updated to:
```lua
require('neotex.plugins.ai.claude.commands.picker').show()
```

And old function names deleted entirely.

### Finding 5: Rollback Plan References "Old Implementation"

**Location**: Plan lines 643-648

**Plan Text**:
```markdown
1. **Phase 1 Rollback**: Revert to monolithic picker.lua (git reset)
2. **Phase 2-5 Rollback**: Facade layer continues delegating to old implementation
3. **Feature Flags**: Add `use_legacy_picker` config option for gradual migration
```

**Standard Violation**: This approach contradicts clean-break by planning to keep "old implementation" accessible.

**nvim Standard**: CODE_STANDARDS.md:27-39 states "Remove deprecated patterns entirely" and "Delete rather than comment out or deprecate."

**Issue**: Line 647 "use_legacy_picker config option" represents exactly the kind of compatibility layer that clean-break forbids.

**Correct Rollback Plan**:
```markdown
If critical issues arise during implementation:

1. **Before Commit**: Revert changes via git (standard development practice)
2. **After Commit**: Fix forward - debug and patch the new implementation
3. **No Fallback**: No legacy picker option - the new implementation IS the picker

Risk Mitigation:
- Comprehensive testing before merge (Phases 1-4)
- Thorough manual verification (Phase 1 task)
- Test coverage requirement (80%+)
```

The presence of a rollback plan that preserves old code suggests insufficient confidence in the new design. Clean-break approach builds confidence through:
- Comprehensive design (Phase 1 architecture)
- Thorough testing (80%+ coverage requirement)
- Atomic replacement (all references updated together)

### Finding 6: Success Criteria Emphasizes Compatibility Over Quality

**Location**: Plan lines 59-71

**Current Success Criteria**:
- Line 64: "100% backward compatibility maintained (all existing keybindings work)"
- Line 65: "Load All syncs 15+ artifact types successfully"

**Analysis**:
- "100% backward compatibility" (line 64) should be "All features work correctly"
- The emphasis on "backward" implies preserving old behavior, but the goal is correct behavior

**nvim Quality Goals**: CODE_STANDARDS.md:17-23 defines success as:
- **Simplicity**: Reduce complexity without losing functionality
- **Unity**: Ensure components work together harmoniously
- **Maintainability**: Code that is easy to understand and modify
- **Reliability**: Preserve working functionality through changes
- **Performance**: Optimize startup time and runtime efficiency

**Revised Success Criteria**:
```markdown
- [ ] All picker features work correctly (keybindings, preview, edit, Load All)
- [ ] Modular architecture improves maintainability (<250 lines per module)
- [ ] Registry system simplifies adding new artifact types
- [ ] Test coverage ensures reliability (80%+)
- [ ] Performance matches or exceeds baseline (±5%)
- [ ] Documentation describes current architecture clearly
```

Note the shift from "backward compatibility" to "working functionality" - semantically similar but philosophically different.

### Finding 7: Phase Dependencies Enable Clean-Break Atomic Update

**Location**: Plan lines 306, 340, 376, 412, 444

**Current Dependencies**:
- Phase 1: [] (foundation)
- Phase 2: [1] (depends on Phase 1)
- Phase 3: [1] (depends on Phase 1)
- Phase 4: [1, 2, 3] (depends on all previous)
- Phase 5: [1, 2, 3, 4] (depends on all)

**Observation**: This dependency structure enables parallel work (Phases 2 and 3) while ensuring Phase 4 integrates everything.

**Clean-Break Opportunity**: Phase 4 is the natural point for atomic replacement. Tasks should include:
- [ ] Integrate all modules from Phases 1-3 into unified picker
- [ ] Update all external callers to use new API
- [ ] Remove all deprecated functions from picker.lua
- [ ] Verify complete removal of old patterns (grep validation)
- [ ] Single atomic commit: "refactor: modularize picker architecture"

This transforms Phase 4 from "Enhanced Operations" to "Integration and Clean Cutover" - the step where old implementation is completely replaced.

### Finding 8: Documentation Standards Conflicts

**Location**: Plan Phase 5 (lines 443-476)

**Plan Documentation Tasks**:
- Line 451: "Create comprehensive README.md for commands/ directory update"
- Line 456: "Write migration guide from monolithic to modular"
- Line 458: "Create user guide with usage examples"
- Line 459: "Add architecture documentation"
- Line 465: "Update CHANGELOG with all changes"

**Analysis**:

**Correct** (aligns with standards):
- Line 451-455: README.md files (required by nvim/CLAUDE.md:33-61)
- Line 458: User guide (functional documentation)
- Line 459: Architecture documentation (technical design)
- Line 465: CHANGELOG update (historical record - correct place for changes)

**Incorrect** (violates clean-break):
- Line 456: Migration guide (prohibited by writing-standards.md:56)

**Correct Approach**:
```markdown
**Phase 5 Documentation Tasks**:
- [ ] Update commands/README.md with picker architecture overview
- [ ] Create picker/README.md describing modular structure
- [ ] Create picker/artifacts/README.md documenting registry system
- [ ] Create picker/display/README.md explaining entry and preview logic
- [ ] Create picker/operations/README.md detailing sync operations
- [ ] Create picker/utils/README.md for utility modules
- [ ] Create picker/ARCHITECTURE.md with module design and data flow
- [ ] Create picker/USER_GUIDE.md with usage examples
- [ ] Update nvim CHANGELOG.md with refactor entry
```

Note: No MIGRATION.md, no "old vs new" comparisons, all documentation describes current state.

## Recommendations

### Recommendation 1: Reframe Facade as Permanent Architecture Pattern

**Action**: Update Technical Design section (lines 273-302) to describe facade as architectural choice, not compatibility mechanism.

**Rationale**: The facade pattern is good design - it provides a stable public API while allowing internal modularization. The issue is the justification, not the pattern itself.

**Revised Section**:
```markdown
### Public API Boundary

**Architectural Pattern**: `picker.lua` serves as the public API boundary, providing a stable interface while allowing internal implementation to be modularized.

**Structure**:
```lua
-- picker.lua (public API - permanent)
local internal = require("neotex.plugins.ai.claude.commands.picker.init")

local M = {}

-- Primary public function
M.show = function(opts)
  return internal.show(opts)
end

return M
```

**Benefits**:
- Stable import path for external code
- Internal modules can be reorganized without breaking callers
- Clear separation between public API and implementation details
- Follows "Single Source of Truth" principle (CODE_STANDARDS.md:11-15)

**Note**: This is the permanent architecture, not a temporary compatibility layer.
```

**Changes**:
- Remove "compatibility layer" language
- Remove "deprecated functions with warnings"
- Remove "gradual migration path"
- Add "permanent architecture" framing
- Reference nvim code standards

### Recommendation 2: Remove All Backward Compatibility Language

**Action**: Remove or rewrite all references to backward compatibility throughout the plan.

**Specific Changes**:

**Line 25**:
- Old: "Maintain 100% backward compatibility with existing workflows"
- New: "Preserve all user-facing functionality"

**Line 53**:
- Old: "Progressive modularization preserving backward compatibility"
- New: "Progressive modularization with atomic cutover"

**Lines 298-301** (API Stability section):
- Delete entire section (covered by Recommendation 1)

**Line 498**:
- Old: "Backward compatibility with existing API"
- New: "Public API functionality preserved"

**Line 620**:
- Old: Risk "Breaking backward compatibility"
- New: Risk "Breaking user workflows" (with same mitigation)

**Line 641**:
- Old: "Backward compatibility 100%"
- New: "All features work correctly"

**Lines 645-647**:
- Delete "Feature Flags" rollback option entirely
- Revise per Recommendation 5

**Rationale**: Clean-break philosophy requires focusing on quality of current implementation, not preservation of past patterns.

### Recommendation 3: Replace Migration Guide with Architecture Documentation

**Action**: Replace Phase 5 task "Write migration guide" (line 456) with expanded architecture documentation.

**New Tasks**:
```markdown
### Phase 5: Polish and Documentation [NOT STARTED]

**Tasks**:
- [ ] Create picker/ARCHITECTURE.md with:
  - Module responsibility matrix
  - Data flow diagrams (using Unicode box-drawing per nvim/CLAUDE.md:70-99)
  - Registry system design
  - Extension points for new artifact types
- [ ] Document public API in picker/README.md:
  - show() function with options
  - Keybinding integration
  - Configuration options
- [ ] Create picker/DEVELOPMENT.md for contributors:
  - How to add new artifact types
  - Testing requirements
  - Module organization principles
```

**Rationale**:
- Architecture docs describe current design (standards-compliant)
- Development guide helps future contributors (forward-looking)
- No historical "old vs new" comparisons (clean-break)

**Reference**: Similar to existing .claude/docs/architecture/state-based-orchestration-overview.md which documents architecture without migration context.

### Recommendation 4: Add Atomic Cutover Task to Phase 4

**Action**: Add explicit atomic replacement task to Phase 4.

**New Phase 4 Tasks** (insert after line 420):
```markdown
### Phase 4: Integration and Atomic Cutover [NOT STARTED]
dependencies: [1, 2, 3]

**Objective**: Integrate all modules and perform atomic replacement of old implementation

**Complexity**: Medium

**Tasks**:
- [ ] Map all external callers of picker functions (grep codebase)
- [ ] Implement registry-driven sync in operations/sync.lua
- [ ] Add interactive conflict resolution UI
- [ ] Implement diff preview before sync
- [ ] Add file integrity validation (checksum)
- [ ] Add executable permissions verification
- [ ] Implement sync result reporting with success/failure counts
- [ ] Add selective sync UI (choose artifact types)
- [ ] Create enhanced Load All preview showing changes
- [ ] Add retry logic for failed syncs
- [ ] Update help text with new sync options
- [ ] **ATOMIC CUTOVER**:
  - [ ] Update all external callers to use new API (single commit)
  - [ ] Remove all old function implementations from picker.lua
  - [ ] Verify no references to old patterns (grep validation)
  - [ ] Update keybindings if function names changed
- [ ] Write tests for sync operations (80%+ coverage)
- [ ] Write tests for conflict resolution (80%+ coverage)
- [ ] Write tests for public API (80%+ coverage)
```

**Rationale**: Follows nvim/docs/CODE_STANDARDS.md:41-47 "Systematic Migration Process" which requires:
- Step 3: "Update ALL references in a single, atomic change"
- Step 4: "Remove old implementation completely"

### Recommendation 5: Revise Rollback Plan to Clean-Break Standard

**Action**: Replace rollback plan (lines 643-648) with forward-fix approach.

**Revised Rollback Plan**:
```markdown
## Risk Mitigation Strategy

### Pre-Merge Quality Gates

**Before committing to main branch**:
1. All tests passing (80%+ coverage requirement)
2. Manual verification checklist complete (Phase 1 task)
3. Performance benchmarks within ±5% baseline
4. Code review approval

### Post-Merge Issue Resolution

**If issues discovered after merge**:
1. **Fix Forward**: Debug and patch the modular implementation
2. **No Rollback to Old Code**: The modular architecture IS the picker
3. **Rapid Response**: High-priority fixes for user-facing issues

**Rationale**:
- Clean-break approach requires confidence in new implementation
- Comprehensive testing (Phases 1-4) builds that confidence
- Forward fixes are faster than maintaining dual implementations
- Git revert available for catastrophic failures (standard practice)

### Risk Reduction Through Design

**Architectural Safeguards**:
- Facade pattern isolates API changes
- Comprehensive test coverage catches regressions
- Phased implementation allows incremental validation
- Performance benchmarks prevent degradation
```

**Rationale**: Aligns with nvim/docs/CODE_STANDARDS.md:27 "Remove deprecated patterns entirely" - no fallback to old implementation.

### Recommendation 6: Revise Success Criteria to Focus on Quality

**Action**: Rewrite success criteria (lines 59-71) to emphasize quality over compatibility.

**Revised Success Criteria**:
```markdown
## Success Criteria

### Functional Requirements
- [ ] All picker features work correctly:
  - Keybindings (<leader>ac)
  - Navigation and selection
  - Preview for all artifact types
  - Edit operations
  - Load All Artifacts sync
- [ ] Artifact type coverage increased from 11 to 16+ types
- [ ] Scripts, tests, plans, reports, summaries visible with preview/edit

### Quality Improvements
- [ ] Modular architecture improves maintainability:
  - Module count increased from 1 to 15-20 modules
  - Average module size reduced from 3,385 lines to <250 lines
  - Clear separation of concerns (artifacts, display, operations, utils)
- [ ] Registry system simplifies extensibility:
  - Adding new artifact types requires only registry entry
  - No modifications to core picker logic needed
- [ ] Test coverage ensures reliability:
  - 80%+ coverage for all new modules
  - Integration tests for end-to-end flows
  - Performance tests validate no degradation

### Documentation Quality
- [ ] Architecture clearly documented (ARCHITECTURE.md)
- [ ] All modules have README.md files
- [ ] Public API documented with examples
- [ ] Development guide for contributors

### Performance Requirements
- [ ] Performance within ±5% of baseline:
  - Picker open time <105ms
  - Preview render time <210ms
  - Load All sync time ~2-5.25s
- [ ] Memory footprint ~2.5-3.5MB (±15%)

### Production Readiness
- [ ] Zero critical bugs
- [ ] <3 minor bugs
- [ ] All features thoroughly tested
- [ ] Clean git history (atomic commits per phase)
```

**Changes**:
- Removed "100% backward compatibility" (line 64)
- Added quality metrics (maintainability, extensibility, reliability)
- Reframed compatibility as "features work correctly"
- Added documentation quality requirements
- Emphasized clean-break values (modularity, clarity, testability)

### Recommendation 7: Update Phase 1 to Include Reference Mapping

**Action**: Add task to Phase 1 for mapping all usages of picker functions.

**New Phase 1 Task** (insert after line 313):
```markdown
### Phase 1: Foundation - Modular Architecture [NOT STARTED]

**Tasks**:
- [ ] **Map Current Usage** (required for atomic cutover):
  - Grep codebase for all picker.lua imports
  - Identify all functions called externally
  - Document current keybinding implementations
  - List all external dependencies on picker
- [ ] Create `picker/` directory structure with subdirectories
- [ ] Create artifact registry module with 11 existing types
...
```

**Rationale**: Follows nvim/docs/CODE_STANDARDS.md:42 "Step 1: Map all usages of the old implementation" before proceeding with refactor.

## References

### Standards Documentation
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:23-46 - Clean-Break Refactors philosophy
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:47-57 - Documentation Standards (no migration guides)
- /home/benjamin/.config/.claude/docs/concepts/writing-standards.md:141-151 - Banned migration language
- /home/benjamin/.config/nvim/docs/CODE_STANDARDS.md:25-47 - Clean-Break Refactoring process
- /home/benjamin/.config/nvim/docs/CODE_STANDARDS.md:11-15 - Single Source of Truth principle
- /home/benjamin/.config/nvim/docs/CODE_STANDARDS.md:41-47 - Systematic Migration Process
- /home/benjamin/.config/nvim/CLAUDE.md:33-61 - README requirements for all subdirectories
- /home/benjamin/.config/nvim/CLAUDE.md:70-99 - Unicode box-drawing for diagrams

### Plan References
- /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md:25 - "100% backward compatibility" claim
- /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md:275-301 - Facade pattern as compatibility layer
- /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md:456 - Migration guide creation task
- /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/plans/001_leaderac_command_nvim_order_check_that_t_plan.md:643-648 - Rollback plan with legacy fallback

### Research References
- /home/benjamin/.config/.claude/specs/859_leaderac_command_nvim_order_check_that_there_full/reports/001_artifact_management_comprehensive_analysis.md:14 - Original research recommending "maintaining backward compatibility"
- /home/benjamin/.config/.claude/specs/854_001_setup_command_comprehensive_analysismd_in/reports/003_revision_research.md:12-61 - Example of clean-break revision identifying compatibility contradictions
- /home/benjamin/.config/.claude/specs/847_updating_the_standard_for_error_logging_to_claude/reports/002_clean_break_revision_insights.md:12-23 - Example analyzing backward compatibility vs clean-break approach

### Related Architecture
- /home/benjamin/.config/.claude/docs/architecture/state-based-orchestration-overview.md - Example of architecture documentation without migration context
