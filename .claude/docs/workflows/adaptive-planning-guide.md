# Adaptive Planning Guide

Comprehensive guide to adaptive plan structures and workflow checkpointing.

## Overview

The Claude Code adaptive planning system provides two complementary capabilities:

1. **Progressive Plan Organization**: Automatically organize implementation plans using three structure levels (L0, L1, L2) based on complexity
2. **Interruption Recovery**: Resume workflows from checkpoints after interruptions without losing progress

Together, these features enable:
- Plans that grow organically from simple to complex structures
- Long-running workflows that survive process interruptions
- Efficient context management for large implementation efforts
- Reduced risk of data loss during development

## When to Use Adaptive Planning

**Use progressive structures** when:
- Planning features with uncertain complexity
- Working on projects that might grow in scope
- Managing teams with varying skill levels
- Need clear phase boundaries for review

**Use checkpointing** when:
- Running multi-hour workflows (/orchestrate, /implement)
- Working in environments prone to interruptions
- Executing critical implementations
- Need to pause and resume work across sessions

## System Components

**Structure Management**:
- Complexity scoring algorithms
- Automatic expansion triggers
- Manual expansion/collapse commands (/expand, /collapse)
- Tier migration utilities

**Checkpoint Management**:
- Automatic checkpoint creation during workflow execution
- Interactive resume prompts on restart
- Checkpoint cleanup and archival
- State preservation and restoration

## Plan Structure Levels (L0, L1, L2)

### Level 0: Single File (Tier 1)

**Structure**:
```
specs/NNN_topic/plans/NNN_feature_name.md
```

**Characteristics**:
- All content in one markdown file
- Inline phase sections with `### Phase N:` headers
- Simple, linear organization
- Easy to read and edit
- No subdirectory needed (simple, non-structured plan)

**When to Use**:
- **Task count**: < 10 tasks
- **Phase count**: < 4 phases
- **Estimated hours**: < 20 hours
- **Complexity score**: < 50

**Example Use Cases**:
- Bug fixes with multiple steps
- Configuration updates
- Small feature additions
- Documentation updates

### Level 1: Phase Directory (Tier 2 - Structured Plan)

**Structure**:
```
specs/NNN_topic/plans/NNN_feature_name/    # Structured plan subdirectory
├── NNN_feature_name.md                    # Overview with phase summaries
├── phase_1_setup.md                       # Detailed tasks for phase 1
├── phase_2_implementation.md              # Detailed tasks for phase 2
└── phase_3_testing.md                     # Detailed tasks for phase 3
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
- **Complexity score**: 50-200

**Example Use Cases**:
- Multi-component features
- API integrations
- Dashboard implementations
- Refactoring modules

### Level 2: Hierarchical Tree (Tier 3)

**Structure**:
```
specs/NNN_topic/plans/NNN_feature_name/     # Structured plan subdirectory
├── NNN_feature_name.md                     # Main overview
├── phase_1_analysis/
│   ├── phase_1_overview.md                 # Phase overview
│   ├── stage_1_codebase_scan.md            # Stage details
│   └── stage_2_metrics.md                  # Stage details
└── phase_2_design/
    ├── phase_2_overview.md
    └── stage_1_architecture.md
```

**Characteristics**:
- Main overview links to phase directories
- Each phase has its own directory
- Phase overview files link to stage files
- Multi-level navigation hierarchy

**When to Use**:
- **Task count**: > 50 tasks
- **Phase count**: > 10 phases
- **Estimated hours**: > 100 hours
- **Complexity score**: ≥ 200

**Example Use Cases**:
- Full application rewrites
- Large-scale refactoring projects
- Multi-module system implementations
- Complex migration projects

## Complexity Management

### Complexity Scoring Formula

```
score = (tasks × 1.0) + (phases × 5.0) + (hours × 0.5) + (dependencies × 2.0)
```

### Tier Thresholds
- **Tier 1 (L0)**: score < 50
- **Tier 2 (L1)**: 50 ≤ score < 200
- **Tier 3 (L2)**: score ≥ 200

### Automatic Expansion

Plans automatically expand when:
- Phase complexity score > 8
- Phase has > 10 tasks
- Phase references > 10 files
- User requests expansion via /expand command

### Example Calculations

**Simple Feature** (Tier 1):
```
Tasks: 8, Phases: 3, Hours: 15, Dependencies: 2
Score = (8 × 1.0) + (3 × 5.0) + (15 × 0.5) + (2 × 2.0)
      = 8 + 15 + 7.5 + 4 = 34.5 → Tier 1
```

**Medium Feature** (Tier 2):
```
Tasks: 25, Phases: 6, Hours: 45, Dependencies: 8
Score = (25 × 1.0) + (6 × 5.0) + (45 × 0.5) + (8 × 2.0)
      = 25 + 30 + 22.5 + 16 = 93.5 → Tier 2
```

## Checkpoint System

### How Checkpointing Works

Checkpoints are automatically created during workflow execution to enable recovery after interruptions.

**Automatic Checkpoint Creation**:

In `/orchestrate`:
- After research phase completes
- After planning phase completes
- After implementation phase completes
- After debugging phase (if needed)

In `/implement`:
- After each phase completion (after git commit)
- Before moving to next phase
- On workflow pause or interruption

### Checkpoint Storage

Checkpoints are stored in `.claude/data/checkpoints/`:

```
checkpoints/
├── README.md
├── orchestrate_auth_system_20251003_184530.json
├── implement_dark_mode_20251003_192230.json
└── failed/
    └── orchestrate_broken_feature_20251003_150000.json
```

**Checkpoint Filename Format**: `{workflow_type}_{project_name}_{timestamp}.json`

### Checkpoint Contents

```json
{
  "checkpoint_id": "orchestrate_auth_system_20251003_184530",
  "workflow_type": "orchestrate",
  "project_name": "auth_system",
  "workflow_description": "Implement authentication system",
  "created_at": "2025-10-03T18:45:30Z",
  "updated_at": "2025-10-03T18:52:15Z",
  "status": "in_progress",
  "current_phase": 2,
  "total_phases": 5,
  "completed_phases": [1],
  "workflow_state": {
    "project_name": "auth_system",
    "artifact_registry": {...},
    "research_results": [...],
    "plan_path": "specs/plans/022_auth_implementation.md"
  },
  "last_error": null
}
```

### Resume Workflow

When you restart a workflow command, it automatically detects existing checkpoints:

```
Found existing checkpoint for "Implement authentication system"
Created: 2025-10-03 18:45:30 (12 minutes ago)
Progress: Phase 2 of 5 completed

Options:
  (r)esume - Continue from Phase 3
  (s)tart fresh - Delete checkpoint and restart
  (v)iew details - Show checkpoint contents
  (d)elete - Remove checkpoint without starting

Choice [r/s/v/d]:
```

**Resume Options**:

- **r) Resume**: Loads workflow state, restores progress, continues from next incomplete phase
- **s) Start Fresh**: Deletes checkpoint, starts from beginning (use when requirements changed)
- **v) View Details**: Shows checkpoint contents, helps decide whether to resume
- **d) Delete**: Removes checkpoint, exits without starting workflow

### Checkpoint Management

**List Active Checkpoints**:
```bash
.claude/lib/# list-checkpoints.sh (removed)
.claude/lib/# list-checkpoints.sh (removed) orchestrate  # Filter by type
```

**Manual Deletion**:
```bash
rm .claude/data/checkpoints/orchestrate_auth_system_*.json
```

**Automatic Cleanup**:
- Checkpoint deleted when workflow completes successfully
- Failed checkpoints moved to `checkpoints/failed/` (kept 30 days)
- Checkpoints older than 7 days automatically deleted
- Run cleanup: `.claude/lib/# cleanup-checkpoints.sh (removed) [days]`

## Integrating Structures and Checkpoints

### Planning Complex Features

1. Use /plan to create initial plan (automatic tier selection)
2. Review complexity score and tier assignment
3. Begin /implement execution
4. Checkpoints created automatically after each phase
5. If complexity increases, use /expand to extract phases
6. Resume from checkpoint after interruptions

### Recovery Workflow

If interrupted during implementation:

1. Restart /implement (auto-detects checkpoint)
2. Review progress in resume prompt
3. Choose (r)esume to continue
4. Implementation resumes from next phase
5. All plan structure changes preserved

### Best Practices

**Plan Early**: Use /plan to establish structure before implementation

**Monitor Complexity**: Check if phases grow beyond ~10 tasks

**Checkpoint Hygiene**: Let workflows complete for auto-cleanup

**Migrate Proactively**: Upgrade tier before plans become unwieldy

**Trust Resume**: Checkpoint system preserves all state accurately

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

### Migration Commands

```bash
# Tier 1 → Tier 2
/migrate-plan specs/plans/007_feature.md --to-tier=2

# Tier 2 → Tier 3
/migrate-plan specs/plans/015_feature/ --to-tier=3

# Downgrade Tier 2 → Tier 1
/migrate-plan specs/plans/015_feature/ --to-tier=1
```

## Command Reference

### Structure Commands
- `/expand <path>` or `/expand phase <path> <phase-num>` - Extract complex phases
- `/collapse <path>` or `/collapse phase <path> <phase-num>` - Merge phases back
- `/plan <description>` - Create plan with automatic tier selection

### Implementation Commands
- `/implement [plan-path]` - Execute plan (creates checkpoints automatically)
- `/implement` - Auto-resume from most recent checkpoint
- `/resume-implement [plan-path]` - Explicit resume from checkpoint

### Utilities
- `.claude/lib/workflow/checkpoint-utils.sh` - Checkpoint management functions
- `.claude/lib/plan/complexity-utils.sh` - Complexity calculation
- `.claude/lib/plan-core-bundle.sh` - Parse any tier structure
- `.claude/lib/# list-checkpoints.sh (removed)` - List active checkpoints
- `.claude/lib/# cleanup-checkpoints.sh (removed) [days]` - Clean old checkpoints

## Troubleshooting

### Checkpoint Not Detected

**Problem**: Restarted workflow but no resume prompt appeared

**Solutions**:
1. Check checkpoint exists: `ls .claude/data/checkpoints/*.json`
2. Verify filename format matches `{type}_{project}_{timestamp}.json`
3. Check file permissions: `ls -la .claude/data/checkpoints/`
4. Ensure workflow description matches (for orchestrate)

### Corrupted Checkpoint

**Problem**: Error loading checkpoint, invalid JSON

**Solutions**:
```bash
# Validate checkpoint
cat .claude/data/checkpoints/checkpoint.json | jq empty

# If corrupted, delete and restart
rm .claude/data/checkpoints/checkpoint.json
/orchestrate "Description"  # Start fresh
```

### Plan Feels Too Large

**Solution**: Migrate to higher tier
```bash
/migrate-plan specs/plans/015_feature/ --to-tier=3
```

### Tier 3 Over-Engineered

**Solution**: Downgrade to Tier 2
```bash
/migrate-plan specs/plans/020_feature/ --to-tier=2
```

## Advanced Operations

### Parsing Utility Functions

**Detect Tier**:
```bash
.claude/lib/plan-core-bundle.sh detect_tier <plan-path>
# Output: 1, 2, or 3
```

**List All Phases**:
```bash
.claude/lib/plan-core-bundle.sh list_phases <plan-path>
# Output: Phase 1: Name
#         Phase 2: Name
```

**Get Tasks for Phase**:
```bash
.claude/lib/plan-core-bundle.sh get_tasks <plan-path> 2
# Output: all tasks for phase 2
```

**Mark Task Complete**:
```bash
.claude/lib/plan-core-bundle.sh mark_complete <plan-path> 2 3
# Marks task 3 in phase 2 as [x]
```

### Force Resume

To always resume without prompting (automation):
```bash
export CLAUDE_AUTO_RESUME=1
/orchestrate "Feature description"
# Will auto-resume if checkpoint exists
```

### View Checkpoint Contents

```bash
# Pretty-print checkpoint JSON
cat .claude/data/checkpoints/orchestrate_*.json | jq

# Check specific field
cat .claude/data/checkpoints/orchestrate_*.json | jq '.current_phase'
```

## Integration with Other Features

### With Artifact System
- Checkpoints preserve `artifact_registry` state
- Artifact references restored on resume
- No need to re-read artifacts

### With Error Analysis
- Last error captured in checkpoint
- Error context available after resume
- Failed checkpoints archived for debugging

### With Agent Tracking
- Agent metrics continue across resume
- No duplicate invocation counts
- Performance tracking preserved

## Limitations

- Checkpoints are local (not synced across machines)
- Long-running agent executions not interruptible mid-execution
- Checkpoint format may change (version field for migration)
- Very large workflow states may take time to save/load

## References

- [Command Reference](../reference/standards/command-reference.md) - Full command documentation
- [Implementation Command](../../commands/implement.md) - Implementation details
- [Orchestration Guide](orchestration-guide.md) - Multi-agent workflows
- [Plan Command](../../commands/plan.md) - Plan creation details
- [Phase Dependencies](../reference/workflows/phase-dependencies.md) - Wave-based parallel execution
