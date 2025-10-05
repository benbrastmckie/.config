---
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
argument-hint: <plan-path> [--to-tier=N]
description: Convert an implementation plan from one tier structure to another
command-type: dependent
parent-commands: plan, update-plan
---

# Migrate Plan Structure

I'll convert an implementation plan from one tier structure to another, preserving all content, completion status, and metadata.

## Arguments
- **plan-path**: Path to plan (file or directory)
- **--to-tier=N** (optional): Target tier (1, 2, or 3). If omitted, automatically recommends based on complexity.

## Migration Paths

### Tier 1 → Tier 2 (Single File → Phase Directory)
**When to migrate**:
- Plan has grown to 10+ tasks or 4+ phases
- Complexity score reaches 50-200 range
- Navigation becoming difficult in single file

**Migration process**:
1. Create directory: `specs/plans/NNN_feature_name/`
2. Create overview: `NNN_feature_name.md` (metadata, problem, solution, phase summaries)
3. Extract each phase to separate file: `phase_N_name.md`
4. Add cross-references between overview and phase files
5. Update metadata: `Structure Tier: 2`
6. Preserve all completion markers and task status

### Tier 2 → Tier 3 (Phase Directory → Hierarchical Tree)
**When to migrate**:
- Plan exceeds 50+ tasks or 10+ phases
- Complexity score reaches 200+
- Individual phases are too large (>10 tasks each)

**Migration process**:
1. Keep directory: `specs/plans/NNN_feature_name/`
2. Update overview: Links to phase directories (not files)
3. For each phase:
   - Create phase directory: `phase_N_name/`
   - Create phase overview: `phase_N_overview.md`
   - Break phase tasks into stages: `stage_M_name.md`
   - Add cross-references
4. Update metadata: `Structure Tier: 3`
5. Preserve all completion markers across stage files

### Tier 3 → Tier 2 (Hierarchical Tree → Phase Directory)
**When to migrate** (downgrade):
- Plan complexity has been reduced
- Hierarchical structure no longer needed
- Simplification desired

**Migration process**:
1. Collapse each phase directory to single phase file
2. Combine all stage tasks into phase file
3. Update overview to link to phase files
4. Update metadata: `Structure Tier: 2`
5. Preserve completion markers

### Tier 2 → Tier 1 (Phase Directory → Single File)
**When to migrate** (downgrade):
- Plan has been simplified significantly
- Phase count reduced below 4
- Total tasks below 10

**Migration process**:
1. Combine all phase files into single `.md` file
2. Merge overview content into file header
3. Inline all phases with `### Phase N:` headers
4. Delete directory structure
5. Update metadata: `Structure Tier: 1`
6. Preserve completion markers

## Process

### 1. Analyze Current Plan
```bash
# Detect current tier
CURRENT_TIER=$(.claude/utils/parse-adaptive-plan.sh detect_tier "$PLAN_PATH")

# Calculate current complexity
# Extract metrics from metadata or count tasks/phases
COMPLEXITY_SCORE=$(.claude/utils/calculate-plan-complexity.sh $TASKS $PHASES $HOURS $DEPS)
```

### 2. Determine Target Tier
**If --to-tier specified**: Use provided tier
**If auto-recommend**:
- Use complexity score to recommend tier
- Display recommendation to user
- Confirm before proceeding

### 3. Validate Migration
- **Cannot skip tiers**: Must migrate T1→T2→T3 incrementally
- **Preserve content**: All tasks, phases, metadata must transfer
- **Completion status**: All `[x]` and `[COMPLETED]` markers preserved
- **Cross-references**: Update all links to reflect new structure

### 4. Execute Migration
Based on migration path (see above), perform:
- File/directory creation
- Content extraction and reorganization
- Cross-reference updates
- Metadata updates

### 5. Verify Migration
```bash
# Verify new tier
NEW_TIER=$(.claude/utils/parse-adaptive-plan.sh detect_tier "$NEW_PLAN_PATH")

# Verify all phases present
OLD_PHASES=$(.claude/utils/parse-adaptive-plan.sh list_phases "$OLD_PATH")
NEW_PHASES=$(.claude/utils/parse-adaptive-plan.sh list_phases "$NEW_PATH")
# Should match

# Verify all tasks preserved
# Count tasks before and after migration
```

### 6. Backup and Cleanup
- Create backup of original structure
- Keep backup for 1 commit cycle
- Delete after successful verification
- Update any summaries or reports linking to plan

## Migration Safety

### Automatic Backups
- Original plan backed up to: `specs/plans/backups/NNN_feature_name_YYYYMMDD.bak`
- Backup includes timestamp
- Restoration instructions provided

### Rollback Procedure
If migration fails or is unsatisfactory:
```bash
# Restore from backup
mv specs/plans/backups/NNN_feature_name_YYYYMMDD.bak specs/plans/NNN_feature_name.md
```

### Verification Checklist
After migration, verify:
- [ ] All phases present in new structure
- [ ] All tasks accounted for (count matches)
- [ ] Completion markers preserved correctly
- [ ] Metadata updated (Structure Tier field)
- [ ] Cross-references all valid
- [ ] /implement command works with new structure
- [ ] Plan opens and displays correctly

## Examples

```bash
# Auto-recommend tier based on complexity
/migrate-plan specs/plans/015_feature.md

# Explicitly migrate to Tier 2
/migrate-plan specs/plans/015_feature.md --to-tier=2

# Migrate Tier 2 to Tier 3
/migrate-plan specs/plans/016_complex/ --to-tier=3

# Downgrade from Tier 3 to Tier 2
/migrate-plan specs/plans/017_hierarchy/ --to-tier=2
```

## Integration with Other Commands

- **After migration**: Use `/implement` with new plan path
- **Before migration**: Consider `/update-plan` if only minor changes needed
- **Review results**: Use `/list-plans` to see tier indicator
- **Verify structure**: Use parsing utility to test new structure

## Migration History

Each migration adds to plan metadata:
```markdown
## Migration History

### [YYYY-MM-DD] - Tier Migration
- **From**: Tier N
- **To**: Tier M
- **Reason**: [Complexity increase/simplification/reorganization]
- **Backup**: specs/plans/backups/NNN_feature_name_YYYYMMDD.bak
```

## Best Practices

1. **Migrate incrementally**: Don't skip tiers (T1→T2→T3)
2. **Verify before deleting**: Keep backups until migration confirmed
3. **Update summaries**: If plan has summary, update plan path reference
4. **Test implementation**: Run `/implement` on migrated plan to ensure compatibility
5. **Migrate early**: Better to migrate before plan becomes too unwieldy
6. **Document reason**: Note why migration was needed in history

## Notes

- **Preserves all content**: No information loss during migration
- **Completion-safe**: Maintains all task checkmarks and phase completion markers
- **Cross-reference update**: Automatically updates all internal links
- **Backward compatible**: Migrated plans work with all commands
- **Auto-backup**: Original plan always preserved
- **Tier detection**: Uses parse-adaptive-plan.sh for accurate detection

Let me analyze your plan and determine the optimal migration path.
