# /migrate-specs: Specs Directory Migration

## Purpose
Migrate specs/ directory from flat structure (`specs/plans/`, `specs/reports/`, `specs/summaries/`) to topic-based structure (`specs/{NNN_topic}/`) with comprehensive subdirectories for all workflow artifacts.

## Synopsis
```bash
/migrate-specs [OPTIONS]
```

## Options
- `--dry-run` - Preview migration without modifying files
- `--backup` - Create backup before migration (default: yes)
- `--no-backup` - Skip backup creation (use with caution)
- `--rollback [BACKUP_FILE]` - Restore from backup (uses latest if not specified)
- `--verify` - Verify migration completed successfully
- `--help` - Show this help message

## Description
This command migrates the specs directory from a flat structure to a topic-based organization where all workflow artifacts are co-located under `specs/{NNN_topic}/` directories.

### Migration Process

**Phase 1: Pre-Migration Analysis**
1. Scan existing artifacts (plans, reports, summaries)
2. Parse plan metadata for report associations
3. Generate migration plan
4. Execute dry-run validation

**Phase 2: Backup Creation**
1. Create timestamped backup archive
2. Verify backup integrity with checksums
3. Save backup to `specs/backups/`

**Phase 3: Migration Execution**
1. Create topic directories with subdirectories
2. Move main plans to `specs/{NNN_topic}/{NNN_topic}.md`
3. Move associated reports to `specs/{NNN_topic}/reports/`
4. Move summaries to `specs/{NNN_topic}/summaries/`
5. Update cross-references in all markdown files
6. Clean up empty old directories

**Phase 4: Post-Migration Verification**
1. Verify directory structure created
2. Verify artifact counts match
3. Verify no broken cross-references
4. Verify gitignore rules applied correctly

### Topic Directory Structure

Each topic directory contains:
```
specs/{NNN_topic}/
├── {NNN_topic}.md              # Main plan
├── reports/                     # Research reports
├── plans/                       # Sub-plans (nested)
├── summaries/                   # Implementation summaries
├── debug/                       # Debug reports (committed)
├── scripts/                     # Investigation scripts (gitignored)
├── outputs/                     # Test outputs (gitignored)
├── artifacts/                   # Operation artifacts (gitignored)
├── backups/                     # Backups (gitignored)
└── [data/, logs/, notes/]      # Optional subdirectories
```

## Usage Examples

### Preview Migration (Dry-Run)
```bash
/migrate-specs --dry-run
```

Shows:
- Topics to create
- Artifacts to move
- Cross-references to update
- Estimated duration and size
- Warnings and errors

### Execute Migration
```bash
/migrate-specs
```

Creates backup automatically, executes migration, verifies success.

### Execute Without Backup (Not Recommended)
```bash
/migrate-specs --no-backup
```

Skips backup creation. Only use if you have manual backup.

### Verify Migration
```bash
/migrate-specs --verify
```

Runs post-migration tests:
- Directory structure validation
- Artifact count verification
- Cross-reference validation
- Gitignore rules verification

### Rollback to Backup
```bash
/migrate-specs --rollback
```

Restores from latest backup. Optionally specify backup file:
```bash
/migrate-specs --rollback specs/backups/specs_backup_20251015_143022.tar.gz
```

## Success Criteria

Migration succeeds when:
- All topic directories created
- All artifacts moved (no files in old structure)
- Cross-references updated (no old-style paths)
- Gitignore rules applied (debug/ tracked, others ignored)
- Verification tests pass

## Rollback Conditions

Automatic rollback triggers:
- Artifact count mismatch
- Directory creation failure
- Cross-reference update failure
- Verification test failure

## Related Documents

- [Migration Strategy](specs/plans/009_orchestration_enhancement_adapted/design/migration_strategy.md) - Complete migration strategy
- [Artifact Taxonomy](specs/plans/009_orchestration_enhancement_adapted/design/artifact_taxonomy.md) - Artifact organization design

## Task Definition

Source the migration utilities library and execute the requested operation:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
source "$LIB_DIR/base-utils.sh"
source "$LIB_DIR/migrate-specs-utils.sh"

# Parse arguments
DRY_RUN=false
BACKUP=true
ROLLBACK=false
VERIFY=false
BACKUP_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --backup)
      BACKUP=true
      shift
      ;;
    --no-backup)
      BACKUP=false
      shift
      ;;
    --rollback)
      ROLLBACK=true
      shift
      if [[ $# -gt 0 && ! $1 =~ ^-- ]]; then
        BACKUP_FILE="$1"
        shift
      fi
      ;;
    --verify)
      VERIFY=true
      shift
      ;;
    --help)
      cat "$SCRIPT_DIR/../commands/migrate-specs.md"
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Execute operations
if [[ "$ROLLBACK" == "true" ]]; then
  info "Rolling back specs migration..."
  rollback_migration "$BACKUP_FILE"
  exit 0
fi

if [[ "$VERIFY" == "true" ]]; then
  info "Verifying specs migration..."
  verify_migration
  exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
  info "Executing dry-run (no files will be modified)..."
  execute_dry_run
  exit 0
fi

# Execute full migration
info "Starting specs migration..."

# Backup phase
if [[ "$BACKUP" == "true" ]]; then
  info "Creating backup..."
  BACKUP_FILE=$(backup_specs)
  info "Backup created: $BACKUP_FILE"
fi

# Scan phase
info "Scanning existing specs structure..."
scan_specs_structure

# Generate migration plan
info "Generating migration plan..."
generate_migration_plan

# Execute migration
info "Executing migration..."
execute_migration

# Verification phase
info "Verifying migration..."
if verify_migration; then
  info "Migration completed successfully!"
  info "Run '/migrate-specs --verify' anytime to re-verify"
else
  error "Migration verification failed"
  if [[ -n "$BACKUP_FILE" ]]; then
    warn "Rolling back to backup..."
    rollback_migration "$BACKUP_FILE"
  fi
  exit 1
fi

# Update .gitignore
info "Updating .gitignore..."
update_gitignore_rules

info "Specs migration complete!"
```
