/orchestrate a refactor of the <leader>ac picker and associated commands in order to maintain all artifacts included in .claude/ (these should not include checkpoints/, docs/, learning/, logs/, metrics/, etc., just the artifacts that it makes sense to load/save between different projects)

# Progressive Adaptive Planning System Implementation Plan

## Metadata
- **Date**: 2025-10-06
- **Feature**: Progressive Adaptive Planning System
- **Scope**: Replace anticipatory tier system with progressive lazy-expansion approach where plans start simple and expand only when implementation reveals complexity
- **Estimated Phases**: 6
- **Estimated Tasks**: 48
- **Estimated Hours**: 80
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Plan Number**: 025
- **Structure Tier**: 1
- **Complexity Score**: 98.0

## Overview

The current adaptive planning system (Plan 024, completed) uses an anticipatory approach with upfront complexity scoring and tier selection during `/plan` creation. This implementation replaces it with a **progressive, lazy-expansion** system where:

1. **All plans start as single files** (simple by default)
2. **Expansion happens during implementation** when phases/stages prove complex
3. **Directory structure created on-demand** when first phase expands
4. **Parent files revised to summaries** after children created
5. **Lazy evaluation** adds detail based on actual needs, not predictions

### Problem Statement

Current limitations with anticipatory tier system:
1. **Premature optimization**: Forces upfront complexity decisions before implementation reveals true needs
2. **Structure overhead**: Creates multi-file structures that may never be needed
3. **Cognitive burden**: Users must understand and choose between tiers during planning
4. **Inflexible**: Difficult to adjust structure once tier selected
5. **Prediction errors**: Complexity estimates often wrong, leading to inappropriate tier selection

### Solution Approach

Progressive system benefits:
1. **Start simple**: Single file default reduces initial overhead
2. **Expand as needed**: Structure grows organically during implementation
3. **No upfront decisions**: System automatically creates directories when expanding
4. **Flexible**: Easy to expand or collapse phases based on actual complexity
5. **Accurate structure**: Final structure reflects actual implementation complexity

## Success Criteria

- [ ] All plans start as single files (Tier selection removed from `/plan`)
- [ ] `/expand-phase` command creates phase files and directory structure on demand
- [ ] `/expand-stage` command creates stage files within phase directories
- [ ] `/collapse-phase` and `/collapse-stage` commands merge content back
- [ ] Parent files automatically revised to summaries after expansion
- [ ] Update reminders added to leaf files
- [ ] `/implement` command detects and navigates progressive structures
- [ ] All plan commands updated for progressive structure awareness
- [ ] Parsing utilities extended with progressive detection functions
- [ ] Documentation updated to reflect progressive approach
- [ ] Migration path from tier system to progressive system
- [ ] Backward compatibility maintained with existing tier-based plans

## Technical Design

### Structure Evolution

**Level 0: Single File (Initial)**
```
specs/plans/025_feature.md
```

**Level 1: Phase Expansion**
```
specs/plans/025_feature/           # Directory created on first expansion
├── 025_feature.md                 # Main plan moved here, revised to summaries
├── phase_2_impl.md                # Expanded phase with details
└── phase_5_deploy.md              # Expanded phase with details
```

**Level 2: Stage Expansion**
```
specs/plans/025_feature/
├── 025_feature.md                 # Main plan (summary + links)
├── phase_2_impl/                  # Phase directory created on first stage expansion
│   ├── phase_2_impl.md            # Phase moved here, revised to summaries
│   ├── stage_1_backend.md         # Expanded stage with details
│   └── stage_2_frontend.md        # Expanded stage with details
└── phase_5_deploy.md              # Phase without stage expansion
```

### Metadata Requirements

**Main Plan (all levels)**:
```markdown
## Metadata
- **Structure Level**: 0 | 1 | 2
- **Expanded Phases**: [2, 5] (if any)
- **Expanded Stages**: {2: [1, 3], 5: [1]} (if any)
```

**Phase File**:
```markdown
## Metadata
- **Phase Number**: 2
- **Parent Plan**: 025_feature.md
- **Expanded Stages**: [1, 3] (if any)
```

**Stage File**:
```markdown
## Metadata
- **Stage Number**: 1
- **Parent Phase**: phase_2_implementation.md
```

### Parent Revision Logic

**Phase Expansion - Revise Main Plan**:
```markdown
Before:
### Phase 2: Implementation
**Objective**: Build core features
Tasks:
- [ ] Task 1
- [ ] Task 2
...15 more tasks...

After:
### Phase 2: Implementation
**Objective**: Build core features
**Status**: [PENDING]

For detailed tasks and implementation, see [Phase 2 Details](phase_2_implementation.md)
```

**Stage Expansion - Revise Phase File**:
```markdown
Before:
### Stage 1: Backend Setup
Tasks:
- [ ] Task 1
...10 tasks...

After:
### Stage 1: Backend Setup
**Objective**: Backend infrastructure

For detailed tasks, see [Stage 1 Details](stage_1_backend.md)
```

### Update Reminders

**Phase file reminder**:
```markdown
## Update Reminder
When phase complete, mark Phase 2 as [COMPLETED] in main plan: `025_feature.md`
```

**Stage file reminder**:
```markdown
## Update Reminder
When stage complete, mark Stage 1 as [COMPLETED] in phase file: `phase_2_implementation.md`
```

## Implementation Phases

### Phase 1: Core Progressive Parsing [COMPLETED]
**Objective**: Extend parsing utilities with progressive structure detection
**Complexity**: Medium

Tasks:
- [x] Update `.claude/utils/parse-adaptive-plan.sh` with progressive detection functions
  - Add `detect_structure_level()` - Returns 0, 1, or 2
  - Add `is_plan_expanded()` - Check if plan has directory
  - Add `get_plan_directory()` - Get plan directory if exists
  - Add `is_phase_expanded()` - Check if phase has file
  - Add `get_phase_file()` - Get phase file path
  - Add `is_stage_expanded()` - Check if stage has file
  - Add `list_expanded_phases()` - List which phases are expanded
  - Add `list_expanded_stages()` - List which stages are expanded
- [x] Update existing functions to work with progressive structures
  - Modify `get_phase_tasks()` to read from inline or expanded phases
  - Modify `mark_task_complete()` to update correct file based on expansion
  - Modify `get_plan_status()` to aggregate status across directory structure
- [x] Create test cases for progressive structure detection
  - Test Level 0 detection (single file)
  - Test Level 1 detection (phase expansion)
  - Test Level 2 detection (stage expansion)
  - Test transition scenarios (Level 0→1, 1→2)
- [x] Validate parsing functions with example structures
  - Create test plan at Level 0
  - Manually create Level 1 structure
  - Manually create Level 2 structure
  - Test all parsing functions against each level

Testing:
```bash
# Test structure level detection
.claude/utils/parse-adaptive-plan.sh detect_structure_level specs/plans/025_test.md
# Expected: 0

# Test expansion detection
.claude/utils/parse-adaptive-plan.sh is_plan_expanded specs/plans/025_test.md
# Expected: false

# Test phase expansion
.claude/utils/parse-adaptive-plan.sh is_phase_expanded specs/plans/025_test/ 2
# Expected: true/false based on structure

# Test listing expanded phases
.claude/utils/parse-adaptive-plan.sh list_expanded_phases specs/plans/025_test/
# Expected: space-separated list of phase numbers
```

Expected Outcomes:
- Progressive structure detection working across all levels
- Parsing utilities can identify expansion status
- All functions handle progressive structures correctly
- Test coverage for all detection scenarios

### Phase 2: Expansion Commands [COMPLETED]
**Objective**: Create commands to expand phases and stages on demand
**Complexity**: High

Tasks:
- [x] Create `.claude/commands/expand-phase.md` command
  - Parse arguments: `<plan-path> <phase-num>`
  - Extract phase content from main plan
  - Detect if this is FIRST expansion (no directory exists)
  - If first: Create directory, move main plan into it
  - Create phase file with extracted content
  - Revise main plan to summary + link
  - Update metadata (Structure Level, Expanded Phases)
  - Validate directory structure after expansion
- [x] Implement phase content extraction logic
  - Parse phase section from main plan
  - Extract objective, tasks, testing, expected outcomes
  - Generate phase file with proper format
  - Preserve all checkboxes and completion markers
- [x] Implement main plan revision logic
  - Replace phase content with summary
  - Add link to phase file
  - Update metadata fields
  - Preserve other phases unchanged
- [x] Create `.claude/commands/expand-stage.md` command
  - Parse arguments: `<phase-path> <stage-num>`
  - Extract stage content from phase file
  - Detect if this is FIRST stage expansion in phase
  - If first: Create phase directory, move phase file into it
  - Create stage file with extracted content
  - Revise phase file to summary + link
  - Update metadata in phase and main plan
  - Add update reminder to stage file
- [x] Implement stage content extraction logic
  - Parse stage section from phase file
  - Generate stage file with tasks
  - Add metadata and update reminder
- [x] Implement phase file revision logic
  - Replace stage content with summary
  - Add link to stage file
  - Update metadata
- [x] Add validation checks to both commands
  - Verify plan/phase exists before expansion
  - Prevent duplicate expansions
  - Validate file writes succeeded
  - Check metadata consistency
- [x] Create comprehensive test suite
  - Test expand-phase on Level 0 plan
  - Test expand-phase on already-Level-1 plan
  - Test expand-stage on phase file
  - Test expand-stage on already-expanded phase
  - Test error cases (missing files, invalid phase numbers)

Testing:
```bash
# Test first phase expansion (Level 0 → 1)
/expand-phase specs/plans/025_test.md 2
# Expected: Directory created, main plan moved, phase 2 extracted

# Test subsequent phase expansion (Level 1 → 1 with more phases)
/expand-phase specs/plans/025_test/ 5
# Expected: Phase 5 extracted to new file, no directory changes

# Test first stage expansion (Level 1 → 2)
/expand-stage specs/plans/025_test/phase_2_impl.md 1
# Expected: Phase directory created, stage 1 extracted

# Test subsequent stage expansion
/expand-stage specs/plans/025_test/phase_2_impl/ 2
# Expected: Stage 2 added to existing phase directory

# Verify metadata updates
grep "Structure Level" specs/plans/025_test/025_test.md
grep "Expanded Phases" specs/plans/025_test/025_test.md
```

Expected Outcomes:
- `/expand-phase` correctly creates phase files and directories
- `/expand-stage` correctly creates stage files and directories
- Main plans revised to summaries after expansion
- Metadata accurately reflects expansion status
- All content preserved during extraction

### Phase 3: Collapse Commands [COMPLETED]
**Objective**: Create commands to merge expanded content back into parent files
**Complexity**: Medium

Tasks:
- [x] Create `.claude/commands/collapse-phase.md` command
  - Parse arguments: `<plan-path> <phase-num>`
  - Read phase file content
  - Merge content back into main plan
  - Delete phase file
  - Check if this was LAST expanded phase
  - If last: Move main plan back to root, delete directory
  - Update metadata (Structure Level, Expanded Phases)
- [x] Implement phase content merging logic
  - Read phase file tasks and content
  - Find phase section in main plan
  - Replace summary with full content
  - Remove link to phase file
  - Preserve task completion status
- [x] Implement directory cleanup logic
  - Check if directory has other phase files
  - If empty: Move main plan to parent directory
  - Delete empty directory
  - Update file paths in metadata
- [x] Create `.claude/commands/collapse-stage.md` command
  - Parse arguments: `<phase-path> <stage-num>`
  - Read stage file content
  - Merge content back into phase file
  - Delete stage file
  - Check if this was LAST expanded stage
  - If last: Move phase file back to parent, delete phase directory
  - Update metadata in phase and main plan
- [x] Implement stage content merging logic
  - Read stage file tasks
  - Find stage section in phase file
  - Replace summary with full content
  - Remove link to stage file
- [x] Implement phase directory cleanup logic
  - Check if directory has other stage files
  - If empty: Move phase file to parent directory
  - Delete empty phase directory
  - Update paths and metadata
- [x] Add validation checks
  - Verify files exist before collapse
  - Prevent data loss during merge
  - Validate metadata consistency after collapse
  - Check for orphaned files
- [x] Create test suite for collapse commands
  - Test collapse-phase on multi-phase Level 1
  - Test collapse-phase on single-phase (last one)
  - Test collapse-stage on multi-stage phase
  - Test collapse-stage on single-stage (last one)
  - Test error cases

Testing:
```bash
# Test collapsing a phase (not last one)
/collapse-phase specs/plans/025_test/ 2
# Expected: Phase 2 merged back, phase file deleted, directory remains

# Test collapsing last phase (Level 1 → 0)
/collapse-phase specs/plans/025_test/ 5
# Expected: Phase 5 merged, main plan moved to root, directory deleted

# Test collapsing a stage (not last one)
/collapse-stage specs/plans/025_test/phase_2_impl/ 1
# Expected: Stage 1 merged, stage file deleted, phase dir remains

# Test collapsing last stage (Level 2 → 1)
/collapse-stage specs/plans/025_test/phase_2_impl/ 2
# Expected: Stage 2 merged, phase file moved to parent, phase dir deleted

# Verify content preservation
diff <(grep "\- \[" original_plan.md) <(grep "\- \[" collapsed_plan.md)
# Expected: All tasks preserved with completion status
```

Expected Outcomes:
- `/collapse-phase` correctly merges phase content back
- `/collapse-stage` correctly merges stage content back
- Directory cleanup happens when last child removed
- Metadata accurately reflects collapsed structure
- No data loss during collapse operations

### Phase 4: Update Existing Commands [COMPLETED]
**Objective**: Modify all plan-related commands to support progressive structures
**Complexity**: High

Tasks:
- [x] Update `.claude/commands/plan.md` command
  - Remove tier selection logic
  - Always create single file at `specs/plans/NNN_feature.md`
  - Remove calls to `calculate-plan-complexity.sh` for tier selection
  - Keep complexity calculation for informational purposes only
  - Show hint if complexity high: "Consider expansion during implementation"
  - Update metadata to use Structure Level: 0
  - Remove tier-specific file creation logic
- [x] Update `.claude/commands/implement.md` command (via parsing utilities)
  - Add structure level detection at start
  - Navigate progressive directory structure
  - Read from phase/stage files when expanded
  - Suggest `/expand-phase` during implementation if phase complex
  - Update completion in correct files (Level 0/1/2)
  - Handle task marking across expanded structures
  - Update partial summaries with structure level info
- [x] Update `.claude/commands/resume-implement.md` command (via parsing utilities)
  - Detect structure level when resuming
  - Find incomplete phases across all levels
  - Navigate to correct files for resume
  - Support resuming from expanded phase/stage
- [x] Update `.claude/commands/list-plans.md` command
  - Show structure level (L0, L1, L2) instead of tier
  - Display expanded phases/stages
  - Format: `[L1] 025_feature (P:2,5) - 25/40 tasks`
  - Group by structure level in output
  - Show expansion hints for incomplete plans
- [x] Update `.claude/commands/update-plan.md` command (via parsing utilities)
  - Detect structure level before update
  - Target correct file based on expansion status
  - Support updating main plan, phase files, or stage files
  - Maintain cross-reference integrity
  - Update metadata when structure changes
- [x] Update `.claude/commands/revise.md` command (via parsing utilities)
  - Analyze revision scope (main/phase/stage)
  - Navigate to appropriate file
  - Handle directory-based structure
  - Preserve expansion status
  - Update cross-references if needed
- [x] Test all updated commands with progressive structures
  - Test /plan creates Level 0 plans
  - Test /implement with Level 0, 1, 2 plans
  - Test /resume-implement across all levels
  - Test /list-plans displays structure correctly
  - Test /update-plan targets correct files
  - Test /revise navigates to correct files

Testing:
```bash
# Test /plan creates simple plans
/plan "Add user profile page"
ls specs/plans/026_*.md
# Expected: Single file created, no directory

# Test /implement suggests expansion
/implement specs/plans/026_user_profile.md
# Expected: If phase complex, suggests /expand-phase

# Test /list-plans shows structure levels
/list-plans
# Expected: Shows [L0], [L1], [L2] indicators

# Test /update-plan with expanded structure
/update-plan specs/plans/025_test/ "Add Phase 6"
# Expected: Updates main plan in directory

# Test /revise with progressive structure
/revise "Update Phase 2 objective" specs/plans/025_test/
# Expected: Navigates to phase_2_impl.md if expanded
```

Expected Outcomes:
- All commands work seamlessly with progressive structures
- `/plan` creates simple single-file plans by default
- `/implement` navigates and updates all structure levels
- `/list-plans` clearly shows structure level and expansion status
- `/update-plan` and `/revise` target correct files
- User experience smooth across all structure levels

### Phase 5: Remove Old Tier System
**Objective**: Completely remove the tier system in favor of the progressive level system
**Complexity**: Medium

Tasks:
- [ ] Remove tier system utilities
  - Delete `.claude/utils/calculate-plan-complexity.sh` (tier selection logic)
  - Remove `detect_tier()` function from `parse-adaptive-plan.sh`
  - Remove tier-related helper functions
  - Keep complexity calculation for informational scoring only
- [ ] Clean up tier references in parsing utilities
  - Remove all tier compatibility code from `parse-adaptive-plan.sh`
  - Remove tier mapping logic
  - Simplify to only support Structure Level 0/1/2
  - Remove legacy tier metadata support
- [ ] Update or remove tier-dependent commands
  - Check `.claude/commands/migrate-plan.md` - update for progressive or remove
  - Remove any tier-specific documentation from command files
  - Update help text to remove tier references
  - Ensure all commands use Structure Level terminology
- [ ] Remove tier system documentation
  - Delete old tier selection documentation if exists
  - Remove tier complexity formulas and thresholds
  - Clean up any tier-specific examples
  - Remove tier comparison tables
- [ ] Update CLAUDE.md specifications
  - Remove tier references from plan structure section
  - Update to only document Structure Level 0/1/2
  - Remove tier selection and complexity threshold documentation
  - Update examples to show progressive workflow only
- [ ] Clean up agent prompts
  - Remove tier selection logic from plan-architect agent
  - Update agent prompts to always create Level 0
  - Remove tier-aware language from agent descriptions
  - Simplify planning agent workflow
- [ ] Audit codebase for tier references
  - Search for "Tier 1", "Tier 2", "Tier 3" strings
  - Search for "Structure Tier" metadata references
  - Replace or remove all tier terminology
  - Ensure consistent use of "Structure Level"

Testing:
```bash
# Verify tier utilities removed
test ! -f .claude/utils/calculate-plan-complexity.sh
# Expected: File does not exist

# Verify tier function removed from parsing
! grep -q "detect_tier" .claude/utils/parse-adaptive-plan.sh
# Expected: No matches

# Verify no tier references in commands
! grep -r "Structure Tier\|Tier [123]" .claude/commands/
# Expected: No matches (or only in migration notes)

# Verify CLAUDE.md updated
! grep -q "Tier 1\|Tier 2\|Tier 3" CLAUDE.md
# Expected: No tier references

# Verify only Level references exist
grep -q "Structure Level" .claude/commands/plan.md
# Expected: Match found
```

Expected Outcomes:
- Complete removal of tier system code and utilities
- All commands use Structure Level terminology exclusively
- Documentation reflects progressive system only
- Simpler, more consistent codebase
- No backwards compatibility - clean break from tier system

### Phase 6: Documentation and Integration
**Objective**: Update all documentation to reflect progressive planning approach
**Complexity**: Medium

Tasks:
- [ ] Revise `.claude/docs/adaptive-plan-structures.md`
  - Change title to "Progressive Plan Structures"
  - Remove anticipatory tier selection content
  - Document progressive lazy-expansion approach
  - Explain Structure Levels 0, 1, 2
  - Show expansion workflow examples
  - Document when and how to expand
- [ ] Create `.claude/docs/progressive-planning-guide.md`
  - Comprehensive guide to progressive planning
  - Start simple philosophy
  - When to use expansion commands
  - Best practices for progressive planning
  - Examples of expansion scenarios
  - Troubleshooting guide
- [ ] Update `.claude/commands/README.md`
  - Remove tier selection documentation
  - Add expansion/collapse command docs
  - Update /plan to reflect single-file default
  - Document structure level indicators
  - Update examples to show progressive workflow
- [ ] Update `/home/benjamin/.config/CLAUDE.md` specifications section
  - Document Structure Level metadata field
  - Update plan format to show progressive approach
  - Add expansion/collapse command reference
  - Update cross-referencing guidelines for progressive structures
  - Document migration from tier system
- [ ] Update all command documentation
  - Update /plan.md (already done in Phase 4)
  - Update /implement.md (already done in Phase 4)
  - Update /list-plans.md (already done in Phase 4)
  - Add /expand-phase.md documentation
  - Add /expand-stage.md documentation
  - Add /collapse-phase.md documentation
  - Add /collapse-stage.md documentation
  - Add /migrate-to-progressive.md documentation
- [ ] Create migration guide from tier system
  - Document differences between tier and progressive
  - Step-by-step migration instructions
  - Backward compatibility notes
  - When to migrate vs. keep tier format
  - Troubleshooting migration issues
- [ ] Update agent documentation
  - Update plan-architect agent to create Level 0 plans
  - Remove tier selection from agent prompts
  - Document progressive structure awareness
  - Update code-writer agent for expansion suggestions
- [ ] Create examples and tutorials
  - Example: Expanding a phase during implementation
  - Example: Collapsing unnecessary expansion
  - Example: Migrating a tier-based plan
  - Tutorial: Progressive planning workflow
- [ ] Validate documentation completeness
  - Check all commands documented
  - Verify all examples work
  - Test migration guide steps
  - Review for consistency

Testing:
```bash
# Verify documentation references
grep -r "Structure Level\|Progressive" .claude/docs/
# Expected: Multiple references across docs

# Test example commands from documentation
# Execute each example and verify it works as documented

# Follow migration guide
# Complete guide step-by-step and verify success

# Verify agent documentation
grep -r "progressive\|expand-phase" .claude/agents/
# Expected: Agents aware of progressive structures
```

Expected Outcomes:
- Complete documentation for progressive planning system
- Clear migration guide from tier system
- All command documentation updated
- Agent documentation reflects progressive approach
- Examples and tutorials provide clear guidance

## Testing Strategy

### Unit Testing
- Progressive structure detection functions
- Expansion content extraction logic
- Collapse content merging logic
- Metadata update operations
- Directory creation and cleanup

### Integration Testing
- End-to-end expansion workflow (Level 0 → 1 → 2)
- End-to-end collapse workflow (Level 2 → 1 → 0)
- Plan creation → expansion → implementation flow
- Migration from tier system → progressive system
- Cross-command interaction (/expand → /implement → /collapse)

### Compatibility Testing
- Existing tier-based plans still work
- Mixed environment (tier + progressive plans)
- Backward compatibility with old metadata
- Migration preserves all content

### Edge Case Testing
- Expanding already-expanded phases
- Collapsing non-existent phases
- Concurrent expansions
- Partial expansions (some phases expanded, others not)
- Empty phases/stages

### Performance Testing
- Large plan parsing with progressive structure
- Expansion/collapse with many phases/stages
- Navigation performance in deeply nested structures

## Documentation Requirements

### User-Facing Documentation
- Progressive planning system guide
- Expansion/collapse command documentation
- Migration guide from tier system
- Troubleshooting guide
- Best practices for progressive planning

### Developer Documentation
- Progressive structure specification
- Parsing utility API extensions
- Expansion/collapse algorithm details
- Directory structure conventions
- Metadata format for progressive structures

### Example Plans
- Example Level 0 plan (simple feature)
- Example Level 1 plan (phase expansion)
- Example Level 2 plan (stage expansion)
- Migration examples (tier → progressive)

## Dependencies

### Internal Dependencies
- Existing `parse-adaptive-plan.sh` utility
- Plan numbering system
- `/plan`, `/implement` command implementations
- Specification directory structure (specs/plans/)
- CLAUDE.md standards

### External Dependencies
- Bash scripting utilities (grep, sed, awk, find)
- File system operations (mkdir, mv, rm)
- Git for version control

## Risks and Mitigation

### Risk: User confusion with progressive approach
**Impact**: Users unsure when to expand or how system works
**Mitigation**:
- Clear documentation with examples
- Helpful hints during `/implement` suggesting expansion
- Simple default (single file) reduces initial complexity
- Easy collapse if expansion not needed

### Risk: Data loss during expansion/collapse
**Impact**: Tasks or content lost during file operations
**Mitigation**:
- Comprehensive validation checks
- Atomic file operations with temp files
- Test suite covering all scenarios
- Backup main plan before expansion

### Risk: Metadata inconsistency
**Impact**: Structure level doesn't match actual structure
**Mitigation**:
- Validation checks in all commands
- Metadata updated atomically with structure
- Parsing utilities verify consistency
- Migration script validates metadata

### Risk: Backward compatibility breaks
**Impact**: Old tier-based plans stop working
**Mitigation**:
- Compatibility layer in parsing utilities
- Support both old and new metadata formats
- Migration command for explicit conversion
- Extensive compatibility testing

### Risk: Complexity of nested structures
**Impact**: Users lost in deeply nested phase/stage hierarchies
**Mitigation**:
- Update reminders in leaf files guide users back
- Cross-references at every level
- `/list-plans` shows clear structure overview
- Collapse commands simplify when not needed

## Notes

### Design Principles

1. **Start Simple**: Default to simplest structure, expand only when needed
2. **Lazy Evaluation**: Create complexity only when implementation reveals it
3. **Progressive Enhancement**: Structure grows organically with actual needs
4. **Reversible Decisions**: Easy to collapse back if expansion not needed
5. **Clear Navigation**: Update reminders and links guide users through structure

### Implementation Order Rationale

1. **Parsing utilities first**: Foundation for all progressive operations
2. **Expansion commands second**: Enable structure creation
3. **Collapse commands third**: Enable structure simplification
4. **Command updates fourth**: Integrate with existing workflows
5. **Migration fifth**: Handle transition from tier system
6. **Documentation last**: Accurate docs based on complete implementation

### Differences from Tier System (Plan 024)

| Aspect | Tier System (024) | Progressive System (025) |
|--------|------------------|-------------------------|
| Default | Tier selected upfront | Always single file |
| Timing | Structure created during /plan | Structure created during /implement |
| Decision | User/system chooses tier | System expands as needed |
| Flexibility | Tier migration difficult | Easy expand/collapse |
| Complexity | Upfront prediction | Revealed during work |
| Overhead | May create unused structure | Only creates what's needed |
| Philosophy | Anticipatory | Reactive/Progressive |

### Future Enhancements

- **Auto-expand suggestions**: AI detects when phase should be expanded based on task count
- **Auto-collapse cleanup**: Remove unnecessary expansions after plan completion
- **Smart expansion**: Suggest which phases to expand based on complexity analysis
- **Visual navigator**: Web UI for browsing progressive plan structures
- **Template expansion**: Expand from templates for common phase patterns
- **Partial expansion**: Expand only stages, not full phase

### Success Metrics

- **Adoption rate**: % of new plans that use expansion (target: >20% for complex features)
- **Structure accuracy**: Final structure matches actual complexity (target: >90% appropriate)
- **User satisfaction**: Feedback on ease of use vs. tier system (target: >80% prefer progressive)
- **Data integrity**: No data loss during expand/collapse (target: 100%)
- **System consistency**: Clean removal of tier system (target: 100% tier references removed)

## Revision History

### 2025-10-06 - Revision 1
**Changes**: Phase 5 completely rewritten
**Reason**: Shift from backwards compatibility to complete tier system removal
**Modified Phases**: Phase 5
**Details**:
- Changed Phase 5 from "Migration and Compatibility" to "Remove Old Tier System"
- Removed all backwards compatibility tasks
- Added tasks to completely remove tier utilities, functions, and documentation
- Changed focus from supporting both systems to clean migration to progressive-only
- Removed migration command creation in favor of direct tier system removal
- Updated testing to verify complete removal rather than compatibility
- Simplified approach: clean break from tier system instead of compatibility layer
