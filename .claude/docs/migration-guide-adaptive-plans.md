# Migration Guide: Adopting Adaptive Plan Structures

Guide for migrating existing single-file plans to the adaptive three-tier system.

## Overview

If you have existing implementation plans in the traditional single-file format (`NNN_plan_name.md`), this guide helps you assess which plans would benefit from migration to Tier 2 or Tier 3 structures.

## Should You Migrate?

### Benefits of Migration

**Better Organization**:
- Easier navigation in large plans
- Clear separation of phases
- Reduced cognitive load

**Improved Collaboration**:
- Team members can work on different phase files
- Easier to review specific phases
- Better git diff readability

**Scalability**:
- Plans can grow without becoming unwieldy
- Adding phases doesn't clutter single file
- Hierarchical organization for complex projects

### When NOT to Migrate

Keep Tier 1 (single file) if:
- Plan is complete and archived
- Plan is simple (< 10 tasks, < 4 phases)
- Plan won't grow significantly
- Team prefers single-file format
- Migration effort exceeds benefit

## Assessment Process

### Step 1: Inventory Existing Plans

List all your current plans:
```bash
/list-plans
```

Identify candidates for migration:
- Plans with > 4 phases
- Plans with > 10 tasks
- Plans that are difficult to navigate
- Active plans that may grow

### Step 2: Calculate Complexity

For each candidate plan, estimate complexity:

```bash
# Count tasks
grep -c '^\- \[ \]' specs/plans/NNN_plan_name.md

# Count phases
grep -c '^### Phase' specs/plans/NNN_plan_name.md

# Estimate hours (manual review)
# Count dependencies (manual review)

# Calculate score
.claude/utils/calculate-plan-complexity.sh <tasks> <phases> <hours> <deps>
```

**Example**:
```bash
# Plan has 18 tasks, 5 phases, estimated 40 hours, 6 dependencies
.claude/utils/calculate-plan-complexity.sh 18 5 40 6

# Output:
# Complexity Score: 75.0
# Recommended Tier: 2
```

### Step 3: Prioritize Migrations

Create a migration priority list based on:

1. **High Priority** (Migrate first):
   - Active plans in progress
   - Plans with complexity score > 100
   - Plans that are hard to navigate
   - Plans team requests improvement for

2. **Medium Priority** (Migrate when convenient):
   - Completed plans with score 50-100
   - Plans that may be referenced frequently
   - Plans with moderate complexity

3. **Low Priority** (Keep as-is):
   - Archived plans not actively used
   - Simple plans (score < 50)
   - Plans unlikely to change

### Step 4: Create Migration Plan

Document your migration plan:

```markdown
# Migration Plan for Adaptive Structure Adoption

## High Priority (Migrate this week)
- [ ] Plan 015: Dashboard Implementation (score: 93.5 → Tier 2)
- [ ] Plan 020: Refactoring Project (score: 220.0 → Tier 3)

## Medium Priority (Migrate this month)
- [ ] Plan 012: API Integration (score: 68.0 → Tier 2)
- [ ] Plan 018: Plugin System (score: 115.0 → Tier 2)

## Low Priority (Keep as Tier 1)
- Plan 007: Button Fix (score: 34.5)
- Plan 009: Config Update (score: 28.0)
```

## Migration Procedure

### Migrating to Tier 2

**For each plan to migrate**:

1. **Backup Original**:
```bash
cp specs/plans/NNN_plan_name.md specs/plans/backups/NNN_plan_name_$(date +%Y%m%d).bak
```

2. **Run Migration**:
```bash
/migrate-plan specs/plans/NNN_plan_name.md --to-tier=2
```

3. **Verify Migration**:
```bash
# Check tier detection
.claude/utils/parse-adaptive-plan.sh detect_tier specs/plans/NNN_plan_name/
# Expected: 2

# List phases
.claude/utils/parse-adaptive-plan.sh list_phases specs/plans/NNN_plan_name/
# Expected: All phases listed

# Check file structure
ls -la specs/plans/NNN_plan_name/
# Expected: overview + phase files
```

4. **Test Implementation**:
```bash
/implement specs/plans/NNN_plan_name/
# Should work identically to before migration
```

5. **Update References**:
- If plan has summary, update plan path
- Update any documentation referencing the plan
- Notify team of new structure

6. **Delete Backup** (after verification):
```bash
rm specs/plans/backups/NNN_plan_name_*.bak
```

### Migrating to Tier 3

**For very complex plans**:

1. **First migrate to Tier 2** (if not already):
```bash
/migrate-plan specs/plans/NNN_plan_name.md --to-tier=2
```

2. **Then migrate to Tier 3**:
```bash
/migrate-plan specs/plans/NNN_plan_name/ --to-tier=3
```

3. **Verify Hierarchical Structure**:
```bash
# Check tier
.claude/utils/parse-adaptive-plan.sh detect_tier specs/plans/NNN_plan_name/
# Expected: 3

# Verify structure
find specs/plans/NNN_plan_name/ -type f -name "*.md"
# Expected: overview, phase overviews, stage files
```

## Migration Validation Checklist

After migrating each plan, verify:

### Content Preservation
- [ ] All phases present in new structure
- [ ] All tasks accounted for (count matches original)
- [ ] Metadata preserved (plan number, dates, etc.)
- [ ] Problem statement intact
- [ ] Solution approach preserved
- [ ] Success criteria maintained

### Completion Status
- [ ] Completed phases marked correctly
- [ ] In-progress phases marked correctly
- [ ] Task checkmarks preserved ([x] markers)
- [ ] Phase dependencies intact
- [ ] Testing requirements preserved

### Structure Integrity
- [ ] Tier detected correctly
- [ ] Overview file exists and is correct
- [ ] Phase files created properly (Tier 2)
- [ ] Phase directories created (Tier 3)
- [ ] Stage files created (Tier 3)
- [ ] Cross-references valid

### Functionality
- [ ] `/implement` command works
- [ ] `/list-plans` shows correct tier indicator
- [ ] Phase navigation works
- [ ] Task marking works
- [ ] Resume from checkpoint works

### Documentation
- [ ] Migration history added to plan
- [ ] Summaries updated (if any)
- [ ] Team notified of new structure
- [ ] Backup preserved until verified

## Rollback Procedure

If migration causes issues:

### Immediate Rollback
```bash
# Restore from backup
mv specs/plans/backups/NNN_plan_name_YYYYMMDD.bak specs/plans/NNN_plan_name.md

# Remove migrated directory
rm -rf specs/plans/NNN_plan_name/

# Verify restoration
.claude/utils/parse-adaptive-plan.sh detect_tier specs/plans/NNN_plan_name.md
# Expected: 1
```

### Downgrade Tier
```bash
# If Tier 3 is too complex, downgrade to Tier 2
/migrate-plan specs/plans/NNN_plan_name/ --to-tier=2

# If Tier 2 is problematic, downgrade to Tier 1
/migrate-plan specs/plans/NNN_plan_name/ --to-tier=1
```

## Common Migration Scenarios

### Scenario 1: Active Plan with Incomplete Phases

**Situation**: Plan is in progress, some phases complete, others pending.

**Migration Steps**:
1. Complete current phase before migrating
2. Run migration: `/migrate-plan <plan> --to-tier=2`
3. Verify completion markers preserved
4. Resume implementation: `/resume-implement <plan-dir>/`

**Validation**:
- Completed phases still marked [COMPLETED]
- In-progress phase shows correct task checkmarks
- Resume picks up at right location

### Scenario 2: Complex Plan Needs Better Organization

**Situation**: Plan has become too large for single file (>15 phases, >50 tasks).

**Migration Steps**:
1. Calculate complexity score
2. If score > 200, migrate directly to Tier 3
3. If score 100-200, migrate to Tier 2
4. Organize stages logically within phases (Tier 3)

**Validation**:
- Navigation much easier
- Phases and stages clearly separated
- Cross-references all work

### Scenario 3: Multiple Related Plans

**Situation**: Several plans that are related to same feature.

**Migration Steps**:
1. Consider whether plans should be merged
2. If merging: combine into single Tier 3 plan
3. If keeping separate: migrate each to appropriate tier
4. Add cross-references between related plans

**Validation**:
- Related plans linked appropriately
- No duplicate content
- Clear separation of concerns

### Scenario 4: Completed Plan for Reference

**Situation**: Plan is complete, kept for reference/documentation.

**Recommendation**:
- **Keep as Tier 1** unless frequently referenced
- If used often: migrate to Tier 2 for easier navigation
- Add to documentation index

## Batch Migration

For migrating multiple plans:

### Create Migration Script

```bash
#!/bin/bash
# migrate-all.sh

# Array of plans to migrate
declare -a plans=(
  "specs/plans/015_dashboard.md:2"
  "specs/plans/018_plugin_system.md:2"
  "specs/plans/020_refactor.md:3"
)

# Migrate each plan
for plan_spec in "${plans[@]}"; do
  IFS=':' read -r plan_path target_tier <<< "$plan_spec"

  echo "Migrating $plan_path to Tier $target_tier..."

  # Backup
  backup_path="${plan_path%.md}_$(date +%Y%m%d).bak"
  cp "$plan_path" "specs/plans/backups/$(basename $backup_path)"

  # Migrate
  /migrate-plan "$plan_path" --to-tier="$target_tier"

  # Verify
  new_path="${plan_path%.md}/"
  tier=$(.claude/utils/parse-adaptive-plan.sh detect_tier "$new_path")

  if [[ "$tier" == "$target_tier" ]]; then
    echo "✓ Migration successful: $new_path is Tier $tier"
  else
    echo "✗ Migration failed: expected Tier $target_tier, got Tier $tier"
  fi

  echo ""
done
```

### Run Batch Migration

```bash
chmod +x migrate-all.sh
./migrate-all.sh
```

## Post-Migration Tasks

After completing migrations:

### Update Documentation

1. **Update CLAUDE.md** (if plan paths referenced):
```markdown
## Implementation Plans

See adaptive plan structures:
- Dashboard (specs/plans/015_dashboard/) - example - Tier 2
- Refactor (specs/plans/020_refactor/) - example - Tier 3
```

2. **Update README files** (if plans linked):
```markdown
Current plans:
- 015_dashboard.md (example) [T2]
- 020_refactor.md (example) [T3]
```

### Update Team

Notify team members:
- Which plans have been migrated
- New directory locations
- How to work with new structure
- Where to find migration guide

### Clean Up Backups

After verification period (1-2 weeks):
```bash
# Remove verified backups
rm specs/plans/backups/*.bak

# Keep backup directory for future migrations
```

## Best Practices

### During Migration

1. **One plan at a time**: Don't migrate everything at once
2. **Test thoroughly**: Verify each migration before proceeding
3. **Keep backups**: Don't delete backups until fully verified
4. **Update immediately**: Update references right after migration
5. **Communicate**: Keep team informed of changes

### After Migration

1. **Use consistently**: Stick with tier system for new plans
2. **Monitor complexity**: Watch for plans that need tier upgrades
3. **Document structure**: Update plan metadata with tier info
4. **Leverage tools**: Use `/list-plans` to see tier indicators
5. **Migrate proactively**: Upgrade tiers before plans get unwieldy

### Ongoing Maintenance

1. **Regular reviews**: Quarterly review of plan complexity
2. **Proactive migration**: Migrate plans as complexity grows
3. **Team feedback**: Adjust based on team preferences
4. **Tool updates**: Keep parsing utilities up to date
5. **Documentation current**: Update guides as needed

## Troubleshooting

### Issue: Migration command not found

**Solution**: Ensure you're using latest version:
```bash
ls .claude/commands/migrate-plan.md
# If not found, update your .claude/ directory
```

### Issue: Complexity score seems wrong

**Solution**: Manually review and adjust:
```bash
# Manually count tasks and phases
# Recalculate with accurate numbers
.claude/utils/calculate-plan-complexity.sh <correct-tasks> <correct-phases> <hours> <deps>
```

### Issue: Cross-references broken after migration

**Solution**: Verify structure and repair:
```bash
# Check structure
.claude/utils/parse-adaptive-plan.sh list_phases <plan-dir>/

# Manually review and fix links in:
# - Overview file
# - Phase files (Tier 2)
# - Phase overviews (Tier 3)
```

### Issue: /implement doesn't work after migration

**Solution**: Verify tier detection:
```bash
.claude/utils/parse-adaptive-plan.sh detect_tier <plan-path>

# If tier wrong, check metadata in overview file:
# Should have: - **Structure Tier**: 2 (or 3)
```

### Issue: Completion status lost

**Solution**: Restore from backup and retry:
```bash
# Restore backup
mv specs/plans/backups/NNN_plan_YYYYMMDD.bak specs/plans/NNN_plan.md

# Manually migrate with careful validation
# Or report issue for investigation
```

## Support and Resources

### Documentation
- [Adaptive Plan Structures Guide](adaptive-planning-guide.md)
- [Commands README](../commands/README.md)
- [Specs README](../specs/README.md)

### Commands
- `/migrate-plan` - Tier migration
- `/list-plans` - View tier indicators
- `/implement` - Execute any tier
- `/update-plan` - Modify plans (tier-aware)

### Utilities
- `parse-adaptive-plan.sh` - Parse any tier
- `calculate-plan-complexity.sh` - Score complexity
- `analyze-plan-requirements.sh` - Estimate metrics

### Getting Help

If you encounter issues during migration:

1. Check this guide's troubleshooting section
2. Review validation checklist
3. Verify with parsing utility
4. Restore from backup if needed
5. Create issue with specific error details

## Examples

### Successful Migration Example

```bash
# Original plan
specs/plans/015_dashboard.md (18 tasks, 5 phases, score: 75.0)

# Backup
cp specs/plans/015_dashboard.md specs/plans/backups/015_dashboard_20251005.bak

# Migrate
/migrate-plan specs/plans/015_dashboard.md --to-tier=2

# Result
specs/plans/015_dashboard/
├── 015_dashboard.md (overview)
├── phase_1_setup.md
├── phase_2_components.md
├── phase_3_integration.md
├── phase_4_testing.md
└── phase_5_deployment.md

# Verify
.claude/utils/parse-adaptive-plan.sh detect_tier specs/plans/015_dashboard/
# Output: 2

# Test
/implement specs/plans/015_dashboard/
# Works perfectly

# Clean up
rm specs/plans/backups/015_dashboard_20251005.bak
```

## Conclusion

Migrating to adaptive plan structures improves organization and scalability. Follow this guide to assess, prioritize, and execute migrations smoothly. Remember:

- Migrate proactively before plans become unwieldy
- Validate thoroughly after each migration
- Keep backups until verified
- Update team and documentation
- Use tier system consistently going forward

The adaptive structure system will grow with your projects, providing the right level of organization for any complexity.
