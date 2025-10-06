# Adaptive Plan Structures Guide

Comprehensive guide to the three-tier adaptive plan structure system for .claude/ workflow.

## Overview

The adaptive plan structure system automatically organizes implementation plans based on project complexity, using three tiers of organization:

- **Tier 1**: Single file for simple features
- **Tier 2**: Phase directory for medium features
- **Tier 3**: Hierarchical tree for complex features

This guide explains when to use each tier, how to work with them, and how to migrate between tiers as your project evolves.

## The Three Tiers

### Tier 1: Single File

**Structure**:
```
specs/plans/NNN_feature_name.md
```

**Characteristics**:
- All content in one markdown file
- Inline phase sections with `### Phase N:` headers
- Simple, linear organization
- Easy to read and edit

**When to Use**:
- **Task count**: < 10 tasks
- **Phase count**: < 4 phases
- **Estimated hours**: < 20 hours
- **Dependencies**: Minimal inter-phase dependencies
- **Complexity score**: < 50

**Example Use Cases**:
- Bug fixes with multiple steps
- Configuration updates
- Small feature additions
- UI tweaks and styling changes
- Documentation updates

**Example**:
```markdown
# Implementation Plan: Fix Button Alignment

## Metadata
- **Plan Number**: 007
- **Structure Tier**: 1
- **Complexity Score**: 34.5

## Problem Statement
Button alignment inconsistent across settings panel.

## Solution Approach
Update CSS and add responsive layout.

### Phase 1: Update CSS
**Objective**: Fix button alignment in settings.css

Tasks:
- [ ] Task 1: Audit current button styles
- [ ] Task 2: Update flexbox properties
- [ ] Task 3: Test on mobile breakpoints

### Phase 2: Testing
**Objective**: Verify fixes across browsers

Tasks:
- [ ] Task 1: Test Chrome, Firefox, Safari
- [ ] Task 2: Verify mobile responsive
```

### Tier 2: Phase Directory

**Structure**:
```
specs/plans/NNN_feature_name/
├── NNN_feature_name.md       # Overview with phase summaries
├── phase_1_setup.md          # Detailed tasks for phase 1
├── phase_2_implementation.md # Detailed tasks for phase 2
├── phase_3_testing.md        # Detailed tasks for phase 3
└── phase_4_deployment.md     # Detailed tasks for phase 4
```

**Characteristics**:
- Overview file with problem, solution, and phase summaries
- Each phase in separate file
- Cross-references between overview and phases
- Better navigation for medium complexity

**When to Use**:
- **Task count**: 10-50 tasks
- **Phase count**: 4-10 phases
- **Estimated hours**: 20-100 hours
- **Dependencies**: Moderate inter-phase dependencies
- **Complexity score**: 50-200

**Example Use Cases**:
- Multi-component features
- API integrations
- Dashboard implementations
- Plugin systems
- Refactoring modules

**Overview File Example**:
```markdown
# Implementation Plan: User Dashboard

## Metadata
- **Plan Number**: 015
- **Structure Tier**: 2
- **Complexity Score**: 106.0

## Problem Statement
Users need a centralized dashboard to view profile, settings, and activity.

## Solution Approach
Build dashboard with tabbed interface using React components.

## Phase Summaries

### Phase 1: Project Setup [PENDING]
- Set up project structure
- Install dependencies
- Configure build tools
- [Details →](phase_1_setup.md)

### Phase 2: Core Components [PENDING]
- Create dashboard layout
- Build tab navigation
- Implement routing
- [Details →](phase_2_implementation.md)

### Phase 3: Data Integration [PENDING]
- Connect to API
- Implement state management
- Add loading states
- [Details →](phase_3_integration.md)
```

**Phase File Example** (`phase_2_implementation.md`):
```markdown
# Phase 2: Core Components

**Objective**: Build dashboard layout and tab navigation
**Complexity**: Medium
**Dependencies**: Phase 1 complete

## Tasks

- [ ] Task 1: Create Dashboard.jsx component
  - Implement layout grid
  - Add responsive breakpoints
  - Style with Tailwind CSS

- [ ] Task 2: Build TabNavigation component
  - Create tab buttons
  - Implement active state
  - Add keyboard navigation

- [ ] Task 3: Set up React Router
  - Define routes for tabs
  - Implement navigation handlers
  - Add URL state synchronization

## Testing

- Unit tests for components
- Integration tests for routing
- Accessibility tests for keyboard navigation

## Success Criteria

- Dashboard renders on all screen sizes
- Tabs navigate correctly
- URL reflects current tab
- Keyboard navigation works

[← Back to Overview](015_user_dashboard.md)
```

### Tier 3: Hierarchical Tree

**Structure**:
```
specs/plans/NNN_feature_name/
├── NNN_feature_name.md           # Main overview
├── phase_1_analysis/
│   ├── phase_1_overview.md       # Phase overview
│   ├── stage_1_codebase_scan.md  # Stage details
│   ├── stage_2_metrics.md        # Stage details
│   └── stage_3_report.md         # Stage details
├── phase_2_design/
│   ├── phase_2_overview.md
│   ├── stage_1_architecture.md
│   └── stage_2_api_design.md
└── phase_3_implementation/
    ├── phase_3_overview.md
    ├── stage_1_backend.md
    ├── stage_2_frontend.md
    └── stage_3_integration.md
```

**Characteristics**:
- Main overview links to phase directories
- Each phase has its own directory
- Phase overview files link to stage files
- Multi-level navigation hierarchy
- Best for very large, complex projects

**When to Use**:
- **Task count**: > 50 tasks
- **Phase count**: > 10 phases
- **Estimated hours**: > 100 hours
- **Dependencies**: Complex inter-phase and inter-stage dependencies
- **Complexity score**: ≥ 200

**Example Use Cases**:
- Full application rewrites
- Large-scale refactoring projects
- Multi-module system implementations
- Complex migration projects
- Platform integrations

**Main Overview Example**:
```markdown
# Implementation Plan: Complete Neovim Refactor

## Metadata
- **Plan Number**: 020
- **Structure Tier**: 3
- **Complexity Score**: 280.0

## Problem Statement
Neovim configuration has grown organically and needs systematic refactoring.

## Solution Approach
Phased refactor with analysis, design, implementation, and migration phases.

## Phase Summaries

### Phase 1: Analysis [IN PROGRESS]
Analyze current codebase and identify refactoring targets.
- **Stages**: 3
- **Tasks**: 15
- [Details →](phase_1_analysis/phase_1_overview.md)

### Phase 2: Design [PENDING]
Design new architecture and module structure.
- **Stages**: 2
- **Tasks**: 8
- [Details →](phase_2_design/phase_2_overview.md)

### Phase 3: Implementation [PENDING]
Implement new structure module by module.
- **Stages**: 3
- **Tasks**: 22
- [Details →](phase_3_implementation/phase_3_overview.md)
```

**Phase Overview Example** (`phase_1_analysis/phase_1_overview.md`):
```markdown
# Phase 1: Analysis

## Objective
Analyze current codebase to identify refactoring opportunities.

## Stages

### Stage 1: Codebase Scan [IN PROGRESS]
Scan all Lua files and catalog modules.
- **Tasks**: 5
- [Details →](stage_1_codebase_scan.md)

### Stage 2: Metrics Collection [PENDING]
Collect code metrics (complexity, coupling, cohesion).
- **Tasks**: 6
- [Details →](stage_2_metrics.md)

### Stage 3: Report Generation [PENDING]
Generate comprehensive refactoring report.
- **Tasks**: 4
- [Details →](stage_3_report.md)

## Dependencies
- None (first phase)

## Success Criteria
- All modules cataloged
- Metrics collected for each module
- Refactoring priorities identified

[← Back to Main Plan](../020_neovim_refactor.md)
```

## Complexity Scoring

The system calculates a complexity score to recommend the appropriate tier:

### Formula
```
score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
```

### Tier Thresholds
- **Tier 1**: score < 50
- **Tier 2**: 50 ≤ score < 200
- **Tier 3**: score ≥ 200

### Complexity Factors

**Tasks (weight: 1.0)**
- Each task adds 1 point
- Granular tasks increase score moderately
- Most direct measure of implementation work

**Phases (weight: 5.0)**
- Each phase adds 5 points
- Heavy weight reflects organizational overhead
- More phases = more complexity management

**Estimated Hours (weight: 0.5)**
- Each hour adds 0.5 points
- Reflects time investment
- Long duration indicates complexity

**Dependencies (weight: 2.0)**
- Each inter-phase dependency adds 2 points
- Dependencies increase coordination complexity
- More dependencies = more careful sequencing

### Example Calculations

**Simple Feature** (Tier 1):
```
Tasks: 8
Phases: 3
Hours: 15
Dependencies: 2

Score = (8 × 1.0) + (3 × 5.0) + (15 × 0.5) + (2 × 2.0)
      = 8 + 15 + 7.5 + 4
      = 34.5 → Tier 1
```

**Medium Feature** (Tier 2):
```
Tasks: 25
Phases: 6
Hours: 45
Dependencies: 8

Score = (25 × 1.0) + (6 × 5.0) + (45 × 0.5) + (8 × 2.0)
      = 25 + 30 + 22.5 + 16
      = 93.5 → Tier 2
```

**Complex Feature** (Tier 3):
```
Tasks: 60
Phases: 12
Hours: 120
Dependencies: 20

Score = (60 × 1.0) + (12 × 5.0) + (120 × 0.5) + (20 × 2.0)
      = 60 + 60 + 60 + 40
      = 220.0 → Tier 3
```

## Tier Migration

Plans can migrate between tiers as complexity changes.

### When to Migrate

**Migrate Up (T1→T2 or T2→T3)**:
- Plan grows beyond current tier's thresholds
- Navigation becoming difficult
- Phases getting too large (>10 tasks per phase)
- Team requests better organization

**Migrate Down (T3→T2 or T2→T1)**:
- Plan simplified through refactoring
- Phases collapsed or removed
- Complexity reduced significantly
- Simpler structure preferred

### Migration Paths

#### Tier 1 → Tier 2

**Process**:
1. Create directory: `specs/plans/NNN_feature_name/`
2. Create overview: `NNN_feature_name.md` with metadata and summaries
3. Extract each phase to file: `phase_N_name.md`
4. Add cross-references between files
5. Update metadata: `Structure Tier: 2`

**Command**:
```bash
/migrate-plan specs/plans/007_feature.md --to-tier=2
```

**Before**:
```
specs/plans/007_feature.md (all content)
```

**After**:
```
specs/plans/007_feature/
├── 007_feature.md (overview)
├── phase_1_setup.md
├── phase_2_implementation.md
└── phase_3_testing.md
```

#### Tier 2 → Tier 3

**Process**:
1. Keep directory structure
2. Update overview to link to phase directories
3. Create phase directories: `phase_N_name/`
4. Create phase overviews: `phase_N_overview.md`
5. Break phase tasks into stages: `stage_M_name.md`
6. Update metadata: `Structure Tier: 3`

**Command**:
```bash
/migrate-plan specs/plans/015_feature/ --to-tier=3
```

**Before**:
```
specs/plans/015_feature/
├── 015_feature.md
├── phase_1_setup.md
└── phase_2_implementation.md
```

**After**:
```
specs/plans/015_feature/
├── 015_feature.md
├── phase_1_setup/
│   ├── phase_1_overview.md
│   ├── stage_1_environment.md
│   └── stage_2_dependencies.md
└── phase_2_implementation/
    ├── phase_2_overview.md
    ├── stage_1_backend.md
    └── stage_2_frontend.md
```

#### Tier 3 → Tier 2 (Downgrade)

**Process**:
1. Collapse each phase directory to single file
2. Combine all stages into phase file
3. Update overview to link to phase files
4. Update metadata: `Structure Tier: 2`

**Command**:
```bash
/migrate-plan specs/plans/020_feature/ --to-tier=2
```

#### Tier 2 → Tier 1 (Downgrade)

**Process**:
1. Combine all phase files into single `.md`
2. Merge overview content into file header
3. Inline phases with `### Phase N:` headers
4. Delete directory structure
5. Update metadata: `Structure Tier: 1`

**Command**:
```bash
/migrate-plan specs/plans/015_feature/ --to-tier=1
```

### Migration Safety

**Automatic Backups**:
- Original plan backed up to `specs/plans/backups/`
- Timestamp included in backup name
- Restoration instructions provided

**Verification**:
- All phases preserved
- All tasks accounted for
- Completion markers intact
- Cross-references valid

**Rollback**:
```bash
# Restore from backup if migration fails
mv specs/plans/backups/NNN_feature_YYYYMMDD.bak specs/plans/NNN_feature.md
```

## Working with Tiers

### Creating Plans

**Automatic Tier Selection**:
```bash
/plan "Feature description"
# System evaluates complexity and selects tier automatically
```

**Manual Review**:
The `/plan` command shows the recommended tier before creation:
```
Complexity Analysis:
- Tasks: 25
- Phases: 6
- Estimated Hours: 45
- Dependencies: 8
- Complexity Score: 93.5
- Recommended Tier: 2 (Phase Directory)

Proceed with Tier 2 structure? [yes/no]
```

### Implementing Plans

**All tiers work identically**:
```bash
# Tier 1 (single file)
/implement specs/plans/007_feature.md

# Tier 2 (directory)
/implement specs/plans/015_feature/

# Tier 3 (hierarchy)
/implement specs/plans/020_feature/

# Auto-resume (detects tier automatically)
/implement
```

### Updating Plans

**Tier-aware updates**:
```bash
# Update Tier 1: modifies single file
/update-plan specs/plans/007_feature.md "Add Phase 4"

# Update Tier 2: creates new phase file
/update-plan specs/plans/015_feature/ "Add Phase 7"

# Update Tier 3: adds new stage file
/update-plan specs/plans/020_feature/ "Add Stage to Phase 2"
```

### Revising Plans

**Scope-aware revisions**:
```bash
# High-level revision (affects overview)
/revise "Update problem statement and success criteria" specs/plans/015_feature/

# Phase-specific revision (affects phase file)
/revise "Change Phase 2 testing approach" specs/plans/015_feature/

# Stage-specific revision (affects stage file in Tier 3)
/revise "Add error handling to Stage 1" specs/plans/020_feature/
```

## Best Practices

### Planning

1. **Start with automatic tier selection**: Let the system recommend based on complexity
2. **Be realistic about estimates**: Accurate task/phase/hour estimates improve tier selection
3. **Plan for growth**: If a plan might expand, consider starting with Tier 2
4. **Review tier periodically**: As implementation progresses, check if migration is needed

### Organization

1. **Tier 1**: Keep phases focused and concise
2. **Tier 2**: Give phases clear, descriptive names (becomes filename)
3. **Tier 3**: Organize stages logically within each phase
4. **Cross-references**: Maintain navigation links in all tiers

### Migration

1. **Migrate incrementally**: Don't skip tiers (T1→T2→T3, not T1→T3)
2. **Migrate early**: Better to migrate before plan becomes unwieldy
3. **Keep backups**: Always verify migration before deleting backups
4. **Test after migration**: Run `/implement` to ensure structure works
5. **Update summaries**: If plan has summary, update with new path

### Completion Tracking

1. **Mark tasks promptly**: Update completion status as you work
2. **Use phase completion markers**: Mark phases [COMPLETED] when done
3. **Preserve history**: Don't remove completion markers when revising
4. **Migration preserves status**: All checkmarks survive tier migration

## Command Reference

### Creating and Planning
- `/plan <description>` - Create plan with automatic tier selection
- `/plan-wizard` - Interactive plan creation with tier guidance

### Implementation
- `/implement [plan-path]` - Execute plan (any tier)
- `/resume-implement [plan-path]` - Resume from checkpoint (any tier)

### Management
- `/list-plans` - List all plans with tier indicators [T1]/[T2]/[T3]
- `/update-plan <plan-path> [reason]` - Add/modify phases (tier-aware)
- `/revise <changes> [plan-path]` - Revise plan content (scope-aware)
- `/migrate-plan <plan-path> [--to-tier=N]` - Convert between tiers

### Utilities
- `.claude/utils/parse-adaptive-plan.sh` - Parse any tier structure
- `.claude/utils/calculate-plan-complexity.sh` - Calculate complexity score
- `.claude/utils/analyze-plan-requirements.sh` - Estimate metrics from description

## Troubleshooting

### Issue: Plan feels too large for current tier

**Solution**: Migrate to higher tier
```bash
/migrate-plan specs/plans/015_feature/ --to-tier=3
```

### Issue: Navigation is difficult in Tier 1

**Solution**: Consider migrating to Tier 2
```bash
/migrate-plan specs/plans/007_feature.md --to-tier=2
```

### Issue: Tier 3 feels over-engineered

**Solution**: Downgrade to Tier 2 or simplify plan
```bash
/migrate-plan specs/plans/020_feature/ --to-tier=2
```

### Issue: Cross-references broken after migration

**Solution**: Use parsing utility to verify structure
```bash
.claude/utils/parse-adaptive-plan.sh detect_tier specs/plans/015_feature/
.claude/utils/parse-adaptive-plan.sh list_phases specs/plans/015_feature/
```

### Issue: Completion status lost

**Solution**: Check backup and restore if needed
```bash
# Backups are in specs/plans/backups/
ls -lt specs/plans/backups/
# Restore if necessary
```

## Advanced Usage

### Parsing Utility Functions

**Detect Tier**:
```bash
.claude/utils/parse-adaptive-plan.sh detect_tier <plan-path>
# Output: 1, 2, or 3
```

**Get Overview File**:
```bash
.claude/utils/parse-adaptive-plan.sh get_overview <plan-path>
# Output: path to overview file
```

**List All Phases**:
```bash
.claude/utils/parse-adaptive-plan.sh list_phases <plan-path>
# Output: Phase 1: Name
#         Phase 2: Name
```

**Get Tasks for Phase**:
```bash
.claude/utils/parse-adaptive-plan.sh get_tasks <plan-path> 2
# Output: all tasks for phase 2
```

**Mark Task Complete**:
```bash
.claude/utils/parse-adaptive-plan.sh mark_complete <plan-path> 2 3
# Marks task 3 in phase 2 as [x]
```

**Get Plan Status**:
```bash
.claude/utils/parse-adaptive-plan.sh get_status <plan-path>
# Output: COMPLETED, IN_PROGRESS, or PENDING
```

### Custom Complexity Scoring

Override automatic tier selection by specifying complexity in plan metadata:

```markdown
## Metadata
- **Complexity Score**: 150.0 (manually set)
- **Structure Tier**: 2 (override auto-selection)
```

## Examples

See test plans for complete examples:
- **Tier 1**: `.claude/specs/plans/test_adaptive/tier1/001_simple.md`
- **Tier 2**: `.claude/specs/plans/test_adaptive/tier2/002_medium/`
- **Tier 3**: `.claude/specs/plans/test_adaptive/tier3/003_complex/`

## References

- [Specs Directory README](../specs/README.md) - Overview of specs structure
- [Commands README](../commands/README.md) - Command documentation
- [Plan Command](../commands/plan.md) - Plan creation details
- [Implement Command](../commands/implement.md) - Implementation process
- [Migrate Plan Command](../commands/migrate-plan.md) - Migration details
