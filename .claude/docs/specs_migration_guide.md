# Specs Migration Guide

## Overview

This guide documents the migration from flat specs structure to topic-based organization, integrating topic-scoped artifact subdirectories (debug/, scripts/, outputs/, etc.).

## Purpose

The migration provides:
- **Topic-based organization**: All artifacts co-located under `specs/{NNN_topic}/`
- **Artifact lifecycle management**: Separate subdirectories for different artifact types
- **Gitignore compliance**: Debug reports committed, other artifacts gitignored
- **Cross-reference maintenance**: Automated link updates during migration
- **Progressive plan support**: Handles Level 0/1/2 plan structures

## Migration Command

```bash
/migrate-specs [--dry-run] [--backup]
```

### Options
- `--dry-run`: Preview changes without executing migration
- `--backup`: Create backup before migration (recommended)

## Migration Process

### Phase 1: Discovery and Analysis

```bash
# Discover existing specs structure
find specs/ -name "*.md" -type f

# Categorize artifacts
- plans/ → {NNN_topic}/{NNN_topic}.md
- reports/{topic}/ → {NNN_topic}/reports/
- summaries/ → {NNN_topic}/summaries/
```

### Phase 2: Topic Directory Creation

For each plan:
```bash
TOPIC_DIR="specs/{NNN_topic}"
mkdir -p "$TOPIC_DIR"/{reports,plans,summaries,debug,scripts,outputs,artifacts,backups}
```

Standard subdirectories created:
- `reports/` - Research reports (gitignored)
- `plans/` - Sub-plans (gitignored)
- `summaries/` - Implementation summaries (gitignored)
- `debug/` - Debug reports (COMMITTED)
- `scripts/` - Investigation scripts (gitignored)
- `outputs/` - Test outputs (gitignored)
- `artifacts/` - Operation artifacts (gitignored)
- `backups/` - Backups (gitignored)

### Phase 3: Artifact Movement

```bash
# Main plan
mv specs/plans/009_topic.md → specs/009_topic/009_topic.md

# Reports
mv specs/reports/topic/001_report.md → specs/009_topic/reports/001_report.md

# Summaries
mv specs/summaries/009_summary.md → specs/009_topic/summaries/001_summary.md
```

### Phase 4: Cross-Reference Updates

Update all markdown links:
```bash
# Plan → Report
[Report](../reports/topic/001_report.md) → [Report](reports/001_report.md)

# Report → Plan
**Main Plan**: ../../plans/009_topic.md → **Main Plan**: ../009_topic.md

# Summary → Plan
**Plan**: ../plans/009_topic.md → **Plan**: ../009_topic.md
```

### Phase 5: Gitignore Updates

Add topic-scoped patterns to `.gitignore`:
```gitignore
# Topic-scoped artifacts (gitignored)
specs/*/reports/
specs/*/plans/
specs/*/summaries/
specs/*/scripts/
specs/*/outputs/
specs/*/artifacts/
specs/*/backups/
specs/*/data/
specs/*/logs/
specs/*/notes/

# Debug reports are COMMITTED (exception)
!specs/*/debug/
```

### Phase 6: Verification

```bash
# Verify topic structure
ls specs/009_topic/

# Expected output:
009_topic.md
reports/
plans/
summaries/
debug/
scripts/
outputs/
artifacts/
backups/

# Verify gitignore
git status specs/009_topic/scripts/  # Should show nothing (gitignored)
git status specs/009_topic/debug/    # Should show files (tracked)

# Verify cross-references
grep -r "specs/plans" specs/  # Should return no results
```

## Progressive Plan Migration

### Level 0 (Single File)
```bash
# Before
specs/plans/009_topic.md

# After
specs/009_topic/009_topic.md
```

### Level 1 (Phase-Expanded)
```bash
# Before
specs/plans/009_topic/
  009_topic.md
  phase_2_implementation.md
  phase_5_validation.md

# After
specs/009_topic/
  009_topic.md
  phase_2_implementation.md
  phase_5_validation.md
  reports/
  summaries/
  debug/
  scripts/
  ...
```

### Level 2 (Stage-Expanded)
```bash
# Before
specs/plans/009_topic/
  009_topic.md
  phase_2_implementation/
    phase_2_implementation.md
    stage_1_setup.md
    stage_3_testing.md

# After
specs/009_topic/
  009_topic.md
  phase_2_implementation/
    phase_2_implementation.md
    stage_1_setup.md
    stage_3_testing.md
  reports/
  summaries/
  debug/
  ...
```

## Rollback Procedure

If migration fails or needs reversal:

```bash
# Restore from backup
tar -xzf .backup_specs_YYYYMMDD_HHMMSS.tar.gz

# Or use /migrate-specs rollback
/migrate-specs --rollback .backup_specs_YYYYMMDD_HHMMSS.tar.gz
```

## Post-Migration Tasks

1. **Update CLAUDE.md**: Ensure specs organization documented
2. **Verify all links**: Run link checker on all markdown files
3. **Test commands**: Verify /plan, /implement, /orchestrate work with new structure
4. **Clean old structure**: Remove empty specs/plans/, specs/reports/ directories

## Common Issues

### Issue: Broken cross-references
**Solution**: Use spec-updater agent to fix references
```bash
# Find broken references
grep -r "specs/plans" specs/
grep -r "specs/reports" specs/

# Update manually or invoke spec-updater
```

### Issue: Gitignore not working for scripts/
**Solution**: Check gitignore rules
```bash
# Test gitignore
git check-ignore specs/009_topic/scripts/test.sh  # Should be ignored
git check-ignore specs/009_topic/debug/test.md    # Should NOT be ignored
```

### Issue: Progressive plan structure lost
**Solution**: Verify directory structure preserved
```bash
# Check if phase files exist
ls specs/009_topic/phase_*.md

# Check if stage directories exist
ls -d specs/009_topic/phase_*/
```

## Integration with Existing Workflows

### /plan Command
- Creates plans in topic directory: `specs/{NNN_topic}/{NNN_topic}.md`
- Includes spec updater checklist
- Creates standard subdirectories automatically

### /implement Command
- Reads plans from topic directory
- Creates debug reports in `debug/` during failures
- Uses spec updater for artifact management

### /orchestrate Command
- Creates topic directory for workflow
- Organizes research reports in `reports/`
- Creates debug reports in `debug/` during debugging phase
- Generates summaries in `summaries/`

## Standards Compliance

Follows CLAUDE.md standards:
- **Clean-Break Refactor**: No backward compatibility with flat structure
- **Present-Focused Documentation**: No historical markers in migrated files
- **Gitignore Compliance**: Enforced via artifact-operations.sh
- **Progressive Planning**: Full support for Level 0/1/2 structures

## References

- **Artifact Taxonomy**: `specs/009_orchestration_enhancement_adapted/design/artifact_taxonomy.md`
- **Migration Strategy**: `specs/009_orchestration_enhancement_adapted/design/migration_strategy.md`
- **Spec Updater Agent**: `.claude/agents/spec-updater.md`
- **CLAUDE.md**: Project-level standards for specs organization
