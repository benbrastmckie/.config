# Adaptive Multi-Level Plan Structure System Implementation Plan

## Metadata
- **Date**: 2025-10-03
- **Feature**: Adaptive Multi-Level Plan Structure System
- **Scope**: Design and implement automatic complexity-based plan organization supporting single-file, phase-directory, and hierarchical structures
- **Estimated Phases**: 6
- **Standards File**: /home/benjamin/.config/CLAUDE.md
- **Plan Number**: 024

## Overview

The current specification system uses only single-file plans (`NNN_plan_name.md`), which works well for simple to medium-complexity projects but becomes unwieldy for large, complex implementations with 50+ tasks and 10+ phases. This plan implements an adaptive three-tier plan structure system that automatically selects the appropriate organizational pattern based on project complexity.

### Problem Statement

Current limitations:
1. **Large plans are difficult to navigate** - Plans with 50+ tasks in a single file are hard to scan and understand
2. **No automatic structure selection** - Manual decision required for plan organization
3. **Commands assume single-file structure** - `/implement`, `/resume-implement`, etc. only work with single files
4. **No formal complexity scoring** - "Low/Medium/High" is subjective and inconsistent
5. **Ad-hoc hierarchical organization** - Parent-child plan relationships are manually created and maintained

### Solution Approach

Implement a three-tier adaptive system:

**Tier 1: Single-File Plans** (Simple projects)
- **Criteria**: <10 tasks, <4 phases, estimated <20 hours
- **Structure**: `specs/plans/NNN_feature_name.md`
- **Use case**: Simple features, bug fixes, small enhancements

**Tier 2: Phase-Directory Plans** (Medium projects)
- **Criteria**: 10-50 tasks, 4-10 phases, estimated 20-100 hours
- **Structure**:
  ```
  specs/plans/NNN_feature_name/
  ├── NNN_feature_name.md          # Overview with problem, solution, phase summaries
  ├── phase_1_foundation.md        # Detailed phase 1 tasks
  ├── phase_2_implementation.md    # Detailed phase 2 tasks
  └── phase_N_final.md             # Detailed phase N tasks
  ```
- **Use case**: Standard features, moderate refactoring, multi-component implementations

**Tier 3: Hierarchical Tree Plans** (Complex projects)
- **Criteria**: >50 tasks, >10 phases, estimated >100 hours
- **Structure**:
  ```
  specs/plans/NNN_feature_name/
  ├── NNN_feature_name.md          # Overview with metadata, links to phase directories
  ├── phase_1_foundation/
  │   ├── phase_1_overview.md      # Phase objectives and stage summaries
  │   ├── stage_1_setup.md         # Detailed stage tasks
  │   └── stage_2_core.md
  ├── phase_2_implementation/
  │   ├── phase_2_overview.md
  │   ├── stage_1_backend.md
  │   ├── stage_2_frontend.md
  │   └── stage_3_integration.md
  └── phase_N_final/
      └── phase_N_overview.md
  ```
- **Use case**: Large architectural changes, complete system implementations, major refactors

## Success Criteria

- [x] Complexity scoring algorithm implemented and validated
- [x] Plan structure automatically selected based on complexity
- [x] All plan-related commands support all three tiers
- [x] Backward compatibility maintained with existing single-file plans
- [x] Plan parsing utility handles multi-file structures
- [x] Agents updated to create/process multi-level plans
- [x] Documentation complete for all three tiers
- [x] Migration path defined for converting between tiers

## Technical Design

### Complexity Scoring Algorithm

**Inputs**:
- Task count (estimated or actual from existing plan)
- Phase count
- Estimated hours per phase
- Dependency complexity (number of cross-phase dependencies)

**Scoring Formula**:
```
complexity_score = (task_count * 1.0) + (phase_count * 5.0) + (total_hours * 0.5) + (dependency_count * 2.0)

Thresholds:
- Simple (Tier 1): score < 50
- Medium (Tier 2): 50 ≤ score < 200
- Complex (Tier 3): score ≥ 200
```

**Example Calculations**:
```
Simple: 8 tasks, 3 phases, 15 hours, 2 dependencies
  = (8 * 1.0) + (3 * 5.0) + (15 * 0.5) + (2 * 2.0)
  = 8 + 15 + 7.5 + 4
  = 34.5 → Tier 1 (single file)

Medium: 30 tasks, 6 phases, 60 hours, 8 dependencies
  = (30 * 1.0) + (6 * 5.0) + (60 * 0.5) + (8 * 2.0)
  = 30 + 30 + 30 + 16
  = 106 → Tier 2 (phase directory)

Complex: 80 tasks, 12 phases, 200 hours, 20 dependencies
  = (80 * 1.0) + (12 * 5.0) + (200 * 0.5) + (20 * 2.0)
  = 80 + 60 + 100 + 40
  = 280 → Tier 3 (hierarchical tree)
```

### Metadata Format Extensions

**All Tiers** include base metadata:
```yaml
## Metadata
- **Date**: YYYY-MM-DD
- **Feature**: Feature name
- **Scope**: Description
- **Plan Number**: NNN
- **Structure Tier**: 1|2|3
- **Complexity Score**: N.N
- **Estimated Phases**: N
- **Estimated Tasks**: N
- **Estimated Hours**: N
- **Standards File**: /path/to/CLAUDE.md
```

**Tier 2** adds:
```yaml
- **Phase Files**:
  - [Phase 1: Foundation](phase_1_foundation.md)
  - [Phase 2: Implementation](phase_2_implementation.md)
```

**Tier 3** adds:
```yaml
- **Phase Directories**:
  - [Phase 1: Foundation](phase_1_foundation/)
  - [Phase 2: Implementation](phase_2_implementation/)
```

### File Naming Conventions

**Tier 1** (single file):
```
NNN_feature_name.md
```

**Tier 2** (phase directory):
```
NNN_feature_name/
├── NNN_feature_name.md                    # Overview (required)
├── phase_1_descriptive_name.md            # Phase 1 (required)
└── phase_N_descriptive_name.md            # Phase N (required)
```

**Tier 3** (hierarchical):
```
NNN_feature_name/
├── NNN_feature_name.md                    # Overview (required)
├── phase_1_descriptive_name/              # Phase 1 directory (required)
│   ├── phase_1_overview.md                # Phase overview (required)
│   ├── stage_1_descriptive_name.md        # Stage 1 (required)
│   └── stage_N_descriptive_name.md        # Stage N (optional)
└── phase_N_descriptive_name/              # Phase N directory
    └── phase_N_overview.md
```

### Plan Discovery Protocol

Commands must locate plans using this search order:

1. **Check for directory**: `specs/plans/NNN_feature_name/`
   - If exists: Read `NNN_feature_name/NNN_feature_name.md` to determine tier
   - Check metadata field `Structure Tier: 2|3`

2. **Check for single file**: `specs/plans/NNN_feature_name.md`
   - If exists: Tier 1 (single file)

3. **List available plans**: For commands like `/list-plans`
   - Scan for both `.md` files and directories with matching `.md` inside
   - Display plan number, name, and tier

### Cross-Referencing Strategy

**Tier 1** (single file):
- Standard markdown links to other specs
- No internal structure to reference

**Tier 2** (phase directory):
- Overview file links to each phase file
- Phase files link back to overview
- Summary files link to overview (not individual phases)

**Tier 3** (hierarchical):
- Overview links to phase directories
- Phase overviews link back to main overview
- Phase overviews link to stage files
- Stage files link back to phase overview
- Summary files link to main overview

### Backward Compatibility

**Existing single-file plans**:
- Continue to work without modification
- Auto-detected as Tier 1 by absence of directory
- Can be migrated to Tier 2/3 using `/migrate-plan` command (future enhancement)

**Command behavior**:
- All commands check for directory first, then file
- Plan parsing utility abstracts tier differences
- `/implement` processes phases regardless of tier structure

## Implementation Phases

### Phase 1: Complexity Scoring and Tier Selection [COMPLETED]
**Objective**: Create utility to evaluate plan complexity and select appropriate tier
**Complexity**: Medium

Tasks:
- [x] Create `.claude/utils/calculate-plan-complexity.sh` utility
  - Input: task count, phase count, estimated hours, dependency count
  - Output: complexity score and recommended tier (1/2/3)
  - Implement scoring formula as documented in Technical Design
  - Validate thresholds with existing plans
- [x] Create `.claude/utils/analyze-plan-requirements.sh` utility
  - Parse feature description to estimate task/phase counts
  - Use heuristics: keywords, sentence count, scope indicators
  - Output: estimated complexity metrics for scoring
- [x] Test complexity scoring with 10 existing plans
  - Verify Tier 1 recommendations for simple plans (001, 007, test files)
  - Verify Tier 2 recommendations for medium plans (013, 014)
  - Verify Tier 3 recommendations for complex plans (019, 023)
  - Adjust thresholds if needed based on validation

Testing:
```bash
# Test complexity calculation
.claude/utils/calculate-plan-complexity.sh 8 3 15 2
# Expected: score=34.5, tier=1

.claude/utils/calculate-plan-complexity.sh 30 6 60 8
# Expected: score=106, tier=2

.claude/utils/calculate-plan-complexity.sh 80 12 200 20
# Expected: score=280, tier=3

# Test requirement analysis
.claude/utils/analyze-plan-requirements.sh "Add user authentication with email and password"
# Expected: tasks~12, phases~4, hours~40, tier=2
```

Expected Outcomes:
- Complexity scoring algorithm implemented and validated
- Requirements analysis provides reasonable estimates
- Thresholds correctly categorize existing plans into tiers

### Phase 2: Adaptive Plan Parsing Utility [COMPLETED]
**Objective**: Create unified plan parsing interface that works across all three tiers
**Complexity**: High

Tasks:
- [x] Create `.claude/utils/parse-adaptive-plan.sh` utility
  - Function: `detect_plan_tier(plan_path)` → 1|2|3
  - Function: `get_plan_overview(plan_path)` → path to overview file
  - Function: `list_plan_phases(plan_path)` → array of phase file/directory paths
  - Function: `get_phase_tasks(plan_path, phase_num)` → list of tasks with checkboxes
  - Function: `mark_task_complete(plan_path, phase_num, task_num)` → update task checkbox
  - Function: `get_phase_status(plan_path, phase_num)` → complete|incomplete|not_started
- [x] Implement Tier 1 (single file) parsing
  - Read single file
  - Extract phases by `### Phase N:` headers
  - Extract tasks by `- [ ]` pattern
  - Mark completion by replacing `- [ ]` with `- [x]`
- [x] Implement Tier 2 (phase directory) parsing
  - Detect directory structure
  - Read overview file for phase list
  - Read individual phase files for tasks
  - Update phase files for task completion
- [x] Implement Tier 3 (hierarchical) parsing
  - Detect multi-level directory structure
  - Read overview → phase overviews → stage files
  - Navigate hierarchy to locate tasks
  - Update appropriate stage files for completion
- [x] Create comprehensive test suite
  - Test all functions with Tier 1, 2, 3 sample plans
  - Test edge cases: missing files, malformed structure
  - Test concurrent access (multiple tasks being marked)

Testing:
```bash
# Create test plans in .claude/specs/plans/test_adaptive/
mkdir -p .claude/specs/plans/test_adaptive/{tier1,tier2,tier3}

# Test Tier 1 detection and parsing
.claude/utils/parse-adaptive-plan.sh detect_tier .claude/specs/plans/test_adaptive/tier1/001_simple.md
# Expected: 1

# Test Tier 2 phase extraction
.claude/utils/parse-adaptive-plan.sh list_phases .claude/specs/plans/test_adaptive/tier2/002_medium/
# Expected: phase_1_foundation.md phase_2_implementation.md

# Test Tier 3 hierarchical navigation
.claude/utils/parse-adaptive-plan.sh get_tasks .claude/specs/plans/test_adaptive/tier3/003_complex/ 1
# Expected: list of tasks from phase 1 stages

# Test task completion marking
.claude/utils/parse-adaptive-plan.sh mark_complete .claude/specs/plans/test_adaptive/tier2/002_medium/ 1 3
# Expected: Task 3 in phase 1 marked with [x]
```

Expected Outcomes:
- Unified parsing interface abstracts tier complexity
- All three tiers can be queried and updated consistently
- Test suite validates all parsing functions
- Edge cases handled gracefully with error messages

### Phase 3: Update /plan Command for Adaptive Structure [COMPLETED]
**Objective**: Modify `/plan` command to evaluate complexity and create appropriate tier structure
**Complexity**: High

Tasks:
- [x] Update `.claude/commands/plan.md` command logic
  - Parse feature description to estimate complexity
  - Call `analyze-plan-requirements.sh` to get metrics
  - Call `calculate-plan-complexity.sh` to determine tier
  - Display tier selection to user for confirmation
  - Create directory structure based on selected tier
- [x] Implement Tier 1 plan creation (existing behavior)
  - Generate single `NNN_feature_name.md` file
  - Include all metadata, phases, and tasks
- [x] Implement Tier 2 plan creation
  - Create `specs/plans/NNN_feature_name/` directory
  - Generate `NNN_feature_name.md` overview with metadata and phase summaries
  - Generate `phase_N_name.md` files for each phase with detailed tasks
  - Add cross-reference links between overview and phase files
- [x] Implement Tier 3 plan creation
  - Create hierarchical directory structure
  - Generate main overview file with links to phase directories
  - Generate phase overview files with links to stages
  - Generate stage files with detailed task lists
  - Implement complete cross-referencing system
- [x] Update `plan-architect` agent with tier-aware planning
  - Agent receives complexity metrics and tier recommendation
  - Agent generates appropriate structure (single file vs. multi-file)
  - Agent creates cross-reference links automatically
  - Agent follows consistent naming conventions

Testing:
```bash
# Test Tier 1 creation
/plan "Fix button alignment in settings panel"
# Expected: Single file created, Tier 1 detected

# Test Tier 2 creation
/plan "Implement user dashboard with profile, settings, and activity feed components"
# Expected: Directory with overview + 4-6 phase files

# Test Tier 3 creation
/plan "Complete redesign of authentication system with OAuth, 2FA, session management, and audit logging across backend, frontend, and database layers"
# Expected: Hierarchical directory with phase subdirectories and stage files

# Verify metadata in each tier
grep "Structure Tier" .claude/specs/plans/025_*/025_*.md
# Expected: Correct tier number in each plan
```

Expected Outcomes:
- `/plan` command automatically selects and creates appropriate tier
- All three tiers generate valid, well-structured plans
- Cross-references work correctly in all tiers
- User can override tier selection if needed

### Phase 4: Update /implement and /resume-implement Commands [COMPLETED]
**Objective**: Modify implementation commands to work with all three plan tiers
**Complexity**: High

Tasks:
- [x] Update `.claude/commands/implement.md` command logic
  - Use `parse-adaptive-plan.sh` to detect plan tier
  - Load phases from appropriate structure (file vs. directory)
  - Process phases sequentially regardless of tier
  - Mark task completion in correct file(s)
  - Update phase status across multi-file structures
- [x] Implement Tier 1 execution (existing behavior)
  - Read single file
  - Process phases in order
  - Mark tasks with `[x]` as completed
  - Add `[COMPLETED]` marker to completed phases
- [x] Implement Tier 2 execution
  - Read overview to get phase list
  - Read phase files for task details
  - Execute tasks and update phase files
  - Mark phase as complete in both phase file and overview
- [x] Implement Tier 3 execution
  - Navigate hierarchical structure
  - Read stage files for tasks
  - Execute tasks and update stage files
  - Mark stages complete in phase overview
  - Mark phases complete in main overview
- [x] Update `.claude/commands/resume-implement.md` command logic
  - Use `parse-adaptive-plan.sh` to find incomplete phases
  - Detect last completed phase across all tiers
  - Resume from first incomplete task in next phase
  - Handle partially completed phases in multi-file structures
- [x] Update `code-writer` agent for tier-aware execution
  - Agent receives plan path (file or directory)
  - Agent uses parsing utility to navigate structure
  - Agent updates completion status in appropriate files
  - Agent reports progress consistently across tiers

Testing:
```bash
# Test Tier 1 implementation
/implement .claude/specs/plans/test_adaptive/tier1/001_simple.md
# Expected: Phases executed, tasks marked [x], [COMPLETED] added

# Test Tier 2 implementation
/implement .claude/specs/plans/test_adaptive/tier2/002_medium/
# Expected: Phase files updated, overview shows completion

# Test Tier 3 implementation
/implement .claude/specs/plans/test_adaptive/tier3/003_complex/
# Expected: Stage files → phase overviews → main overview all updated

# Test resume functionality
/resume-implement
# Expected: Finds last incomplete phase in multi-file plan and resumes

# Test phase dependency handling across tiers
# (Create test plan with dependencies: [1,2] in phase 3)
/implement .claude/specs/plans/test_adaptive/tier2/004_dependencies/
# Expected: Phases execute in correct order respecting dependencies
```

Expected Outcomes:
- `/implement` works seamlessly with all three tiers
- Task completion properly tracked across multi-file structures
- `/resume-implement` correctly identifies resume point
- Phase dependencies respected in all tiers
- Git commits created appropriately for each tier

### Phase 5: Update Plan Management Commands [COMPLETED]
**Objective**: Update `/list-plans`, `/update-plan`, and `/revise` to support all tiers
**Complexity**: Medium

Tasks:
- [x] Update `.claude/commands/list-plans.md`
  - Scan for both `.md` files and matching directories
  - Display plan number, name, tier, and status
  - Show phase count and completion percentage
  - Format output clearly distinguishing tiers
  - Add filter option by tier (e.g., `--tier=2`)
- [x] Update `.claude/commands/update-plan.md`
  - Detect plan tier using parsing utility
  - Allow updates to metadata in overview file
  - Allow adding/removing/reordering phases
  - For Tier 2/3: Create/delete phase files/directories as needed
  - Maintain cross-reference integrity when restructuring
  - Support tier migration (promote Tier 1→2→3 or demote 3→2→1)
- [x] Update `.claude/commands/revise.md`
  - Detect plan tier and locate correct file to revise
  - For Tier 1: Revise single file
  - For Tier 2: Revise overview or specific phase file based on scope
  - For Tier 3: Navigate hierarchy to find correct stage file
  - Maintain consistent formatting and cross-references
- [x] Create `.claude/commands/migrate-plan.md` (new command)
  - Analyze plan and recommend tier based on current complexity
  - Allow manual tier selection
  - Convert plan structure to target tier
  - Preserve all content, tasks, and metadata
  - Update all cross-references
  - Validate migration success

Testing:
```bash
# Test plan listing
/list-plans
# Expected: Shows all plans with tier indicators (T1/T2/T3)

/list-plans --tier=2
# Expected: Shows only Tier 2 plans

# Test plan updating
/update-plan .claude/specs/plans/test_adaptive/tier2/002_medium/ "Add Phase 5: Documentation"
# Expected: New phase_5_documentation.md created, overview updated

# Test plan revision
/revise "Change Phase 2 complexity from Medium to High" .claude/specs/plans/test_adaptive/tier2/002_medium/
# Expected: Complexity field updated in phase_2_implementation.md

# Test plan migration
/migrate-plan .claude/specs/plans/001_subagents_command.md --to-tier=2
# Expected: Directory created, phases split into files, content preserved

# Verify migration integrity
diff -r <(cat original_plan.md) <(cat migrated_plan/*/*)
# Expected: All content present, just restructured
```

Expected Outcomes:
- `/list-plans` displays all tiers correctly
- `/update-plan` modifies structure while maintaining integrity
- `/revise` navigates to correct file in any tier
- `/migrate-plan` successfully converts between tiers
- All cross-references remain valid after updates

### Phase 6: Documentation and Integration [COMPLETED]
**Objective**: Document the adaptive plan system and update all relevant documentation
**Complexity**: Medium

Tasks:
- [x] Create `.claude/specs/README.md` enhancement
  - Document all three plan structure tiers
  - Provide examples of each tier
  - Explain complexity scoring algorithm
  - Show file structure diagrams for each tier
  - Document cross-referencing conventions
- [x] Update `.claude/commands/README.md`
  - Document tier-aware behavior of all plan commands
  - Add `/migrate-plan` command documentation
  - Update examples to show multi-tier usage
  - Document parsing utility for advanced users
- [x] Create `.claude/docs/adaptive-plan-structures.md` guide
  - Comprehensive guide to the three-tier system
  - When to use each tier (with examples)
  - How complexity is calculated
  - How to manually create each tier structure
  - Migration strategies and best practices
  - Troubleshooting common issues
- [x] Update CLAUDE.md specifications section
  - Update plan format description to mention tiers
  - Document new metadata fields (Structure Tier, Complexity Score)
  - Update cross-referencing guidelines
  - Add tier selection guidelines for manual plan creation
- [x] Create migration guide for existing projects
  - Assess existing plans and recommend tier upgrades
  - Step-by-step migration instructions
  - Validation checklist
  - Rollback procedures if needed
- [x] Update all agent documentation
  - Document tier-aware behavior in `plan-architect.md`
  - Document parsing utility usage in `code-writer.md`
  - Add examples of multi-tier plan processing

Testing:
```bash
# Verify documentation completeness
grep -r "Tier 1\|Tier 2\|Tier 3" .claude/docs/
# Expected: Multiple references in docs and guides

# Validate examples in documentation
# Extract example commands from docs and execute them
# Expected: All examples work as documented

# Test migration guide steps
# Follow migration guide to upgrade a test plan
# Expected: Plan successfully migrated, all steps clear
```

Expected Outcomes:
- Complete documentation for three-tier system
- Clear guidelines for tier selection
- Migration guide enables smooth transitions
- All examples validated and working
- Agent documentation updated

## Testing Strategy

### Unit Testing
- Complexity scoring algorithm with edge cases
- Plan parsing utility functions for all tiers
- Tier detection logic
- File creation and naming conventions

### Integration Testing
- End-to-end plan creation (feature description → tier selection → plan creation)
- End-to-end plan execution (plan → implement → completion tracking)
- Plan migration (Tier 1 → Tier 2 → Tier 3 and reverse)
- Cross-command interaction (/plan → /implement → /update-plan)

### Compatibility Testing
- Existing single-file plans still work with all commands
- Backward compatibility with old plan format
- Mixed environment (some Tier 1, some Tier 2/3 plans)

### Performance Testing
- Large plan parsing performance (Tier 3 with many stages)
- Plan listing with hundreds of plans (mixed tiers)
- Concurrent plan execution (multiple /implement commands)

### User Acceptance Testing
- Create test plans of varying complexity
- Verify tier selection makes sense
- Confirm navigation is intuitive in multi-file structures
- Validate cross-references are helpful

## Documentation Requirements

### User-Facing Documentation
- Adaptive plan structures guide (comprehensive)
- Command usage updates for tier-aware commands
- Migration guide for existing projects
- Troubleshooting guide for common issues

### Developer Documentation
- Parsing utility API reference
- Complexity scoring algorithm specification
- File structure conventions for each tier
- Cross-referencing patterns

### Example Plans
- Example Tier 1 plan (simple feature)
- Example Tier 2 plan (medium feature)
- Example Tier 3 plan (complex feature)
- Migration examples showing before/after

## Dependencies

### Internal Dependencies
- Existing plan structure and numbering system
- Current `/plan`, `/implement` command implementations
- `plan-architect` and `code-writer` agents
- Specification directory structure (specs/plans/)

### External Dependencies
- Bash scripting utilities (grep, sed, awk for parsing)
- File system operations (mkdir, mv, cp for structure creation)
- Git for version control of multi-file plans

## Risks and Mitigation

### Risk: Complexity threshold miscalibration
**Impact**: Plans assigned to wrong tier, causing confusion or inefficiency
**Mitigation**:
- Validate thresholds against 20+ existing plans
- Allow manual tier override in `/plan` command
- Provide `/migrate-plan` for easy tier changes
- Monitor usage and adjust thresholds based on feedback

### Risk: Parsing utility edge cases
**Impact**: Commands fail on unusual plan structures
**Mitigation**:
- Comprehensive test suite with edge cases
- Graceful error handling with clear messages
- Validation checks on plan structure during creation
- Documentation of supported structure patterns

### Risk: Cross-reference maintenance burden
**Impact**: Links break when plans are updated or migrated
**Mitigation**:
- Automated cross-reference creation during plan generation
- Validation checks in `/update-plan` to detect broken links
- Clear conventions for relative path references
- Migration tool handles cross-reference updates automatically

### Risk: User confusion with three tiers
**Impact**: Users unsure which tier to use or how to navigate
**Mitigation**:
- Clear documentation with examples
- Automatic tier selection removes decision burden
- Consistent navigation patterns across tiers
- Visual indicators in `/list-plans` output

### Risk: Backward compatibility breaks
**Impact**: Existing single-file plans stop working
**Mitigation**:
- Extensive compatibility testing
- Parsing utility defaults to Tier 1 for non-directory plans
- All commands check for directory first, then file
- No changes to existing plan files without explicit migration

## Notes

### Design Principles

1. **Progressive Enhancement**: Simple plans stay simple (Tier 1), complexity triggers structure only when needed
2. **Automatic Adaptation**: System selects tier automatically, user can override if desired
3. **Backward Compatibility**: All existing plans continue to work without modification
4. **Consistent Interface**: Commands work the same way regardless of plan tier
5. **Clear Navigation**: Cross-references and directory structure make navigation intuitive

### Implementation Order Rationale

1. **Complexity scoring first**: Foundation for all tier selection decisions
2. **Parsing utility second**: Abstraction layer enables all subsequent command updates
3. **Plan creation third**: Enables testing with real multi-tier plans
4. **Plan execution fourth**: Core workflow must work with new structures
5. **Management commands fifth**: Additional functionality builds on core workflow
6. **Documentation last**: Complete implementation enables accurate documentation

### Future Enhancements

- **Visual plan navigator**: Web-based UI for browsing multi-tier plans
- **Plan templates by tier**: Pre-structured templates for common patterns
- **Automated complexity re-evaluation**: Periodic checks to recommend tier upgrades
- **Plan merging**: Combine multiple Tier 1 plans into a Tier 2 plan
- **Plan splitting**: Break large Tier 1 plans into Tier 2 automatically
- **Cross-plan dependencies**: Link related plans with dependency tracking

### Success Metrics

- **Adoption rate**: % of new plans using Tier 2/3 (target: >30% for Tier 2, >10% for Tier 3)
- **Navigation efficiency**: Time to find specific task in Tier 3 vs. single file (target: <50% time)
- **Error rate**: Parsing/execution errors in multi-tier plans (target: <5%)
- **Migration success**: Plans migrated without data loss (target: 100%)
- **User satisfaction**: Feedback on ease of use and navigation (target: >80% positive)
