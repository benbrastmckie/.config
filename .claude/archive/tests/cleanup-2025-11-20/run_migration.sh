#!/usr/bin/env bash
#
# Test script to execute specs migration
#

set -euo pipefail

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
export CLAUDE_PROJECT_DIR="/home/benjamin/.config"

source "$LIB_DIR/base-utils.sh"
source "$LIB_DIR/migrate-specs-utils.sh"

# Execute migration steps

echo "========================================="
echo "Specs Migration Execution"
echo "========================================="
echo ""

# Step 1: Scan
echo "Step 1: Scanning specs structure..."
if scan_specs_structure; then
  echo "✓ Scan complete"
else
  echo "✗ Scan failed"
  exit 1
fi
echo ""

# Step 2: Generate plan
echo "Step 2: Generating migration plan..."
if generate_migration_plan; then
  echo "✓ Migration plan generated"
  echo ""
  echo "Migration Plan Preview:"
  head -50 migration_plan.txt
else
  echo "✗ Migration plan generation failed"
  exit 1
fi
echo ""

# Step 3: Dry-run
echo "Step 3: Executing dry-run validation..."
if execute_dry_run; then
  echo "✓ Dry-run passed"
else
  echo "✗ Dry-run failed"
  exit 1
fi
echo ""

# Step 4: Backup
echo "Step 4: Creating backup..."
BACKUP_FILE=$(backup_specs)
if [[ -n "$BACKUP_FILE" ]]; then
  echo "✓ Backup created: $BACKUP_FILE"
else
  echo "✗ Backup failed"
  exit 1
fi
echo ""

# Step 5: Execute migration
echo "Step 5: Executing migration..."
if execute_migration; then
  echo "✓ Migration complete"
else
  echo "✗ Migration failed"
  echo "Rolling back to backup..."
  rollback_migration "$BACKUP_FILE"
  exit 1
fi
echo ""

# Step 6: Verify
echo "Step 6: Verifying migration..."
if verify_migration; then
  echo "✓ Migration verified"
else
  echo "✗ Migration verification failed"
  echo "Rolling back to backup..."
  rollback_migration "$BACKUP_FILE"
  exit 1
fi
echo ""

# Step 7: Update gitignore
echo "Step 7: Updating .gitignore..."
if update_gitignore_rules; then
  echo "✓ .gitignore updated"
else
  echo "⚠ .gitignore update had issues (non-fatal)"
fi
echo ""

echo "========================================="
echo "Migration Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  - Review migrated structure: ls -la specs/"
echo "  - Check specific topics: ls -la specs/009_orchestration_enhancement_adapted/"
echo "  - Verify gitignore: git status specs/"
echo ""
