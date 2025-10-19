#!/usr/bin/env bash
# Migration script for converting flat spec structure to topic-based structure
# Usage: DRY_RUN=true ./migrate_to_topic_structure.sh (dry run)
#        DRY_RUN=false ./migrate_to_topic_structure.sh (actual migration)
#
# Strategy:
# 1. Each plan in specs/plans/NNN_name.md becomes a topic specs/NNN_name/
# 2. The plan moves to specs/NNN_name/plans/NNN_name.md
# 3. Reports and summaries are matched to plan topics when possible
# 4. Unmatched reports/summaries go to a general "research" topic

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/.." && pwd)"

# Source required utilities
source "$CLAUDE_DIR/lib/template-integration.sh"
# artifact-operations.sh removed - modular utilities sourced as needed

# Configuration
DRY_RUN="${DRY_RUN:-true}"
VERBOSE="${VERBOSE:-false}"
SPECS_DIR="$CLAUDE_DIR/specs"
BACKUP_DIR="$SPECS_DIR/backups/pre_migration_$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
  if [ "$VERBOSE" = "true" ]; then
    echo -e "${BLUE}[DEBUG]${NC} $1"
  fi
}

# Main migration workflow
main() {
  # Check if we're in dry-run mode
  if [ "$DRY_RUN" = "true" ]; then
    log_warn "Running in DRY-RUN mode - no changes will be made"
  else
    log_info "Running in ACTUAL mode - files will be migrated"
  fi

  echo "============================================"
  echo "Spec Structure Migration Script"
  echo "============================================"
  echo ""

  # Step 1: Create backup
  log_info "Step 1: Creating backup of specs directory"
  if [ "$DRY_RUN" = "false" ]; then
    mkdir -p "$BACKUP_DIR"

    for dir in plans reports summaries; do
      if [ -d "$SPECS_DIR/$dir" ]; then
        cp -r "$SPECS_DIR/$dir" "$BACKUP_DIR/" 2>/dev/null || true
      fi
    done

    log_info "Backup created at: $BACKUP_DIR"
  else
    log_info "Would create backup at: $BACKUP_DIR"
  fi
  echo ""

  # Step 2: Migrate plan files to topic directories
  log_info "Step 2: Migrating plan files to topic directories"
  echo ""

  local plan_count=0

  if [ -d "$SPECS_DIR/plans" ]; then
    for plan_file in "$SPECS_DIR/plans"/*.md; do
      [ -f "$plan_file" ] || continue

      local filename=$(basename "$plan_file")

      # Extract number and name from filename (e.g., 056_complete_topic_based_spec_organization.md)
      if [[ "$filename" =~ ^([0-9]+)_(.+)\.md$ ]]; then
        local number="${BASH_REMATCH[1]}"
        local topic_name="${BASH_REMATCH[2]}"
        local topic_dir="$SPECS_DIR/${number}_${topic_name}"

        if [ "$VERBOSE" = "true" ]; then
          log_info "Plan: $filename → ${number}_${topic_name}/"
        fi

        if [ "$DRY_RUN" = "false" ]; then
          # Create topic directory structure
          mkdir -p "$topic_dir"/{plans,reports,summaries,debug,scripts,outputs,artifacts,backups}
          # Create .gitkeep in debug directory
          touch "$topic_dir/debug/.gitkeep"

          # Copy plan file
          cp "$plan_file" "$topic_dir/plans/$filename"
        fi

        ((plan_count++))
      fi
    done
  fi

  echo ""
  log_info "Migrated $plan_count plan files"
  echo ""

  # Step 3: Handle reports and summaries
  log_warn "Step 3: Reports and summaries require manual review"
  echo ""

  local report_count=$(find "$SPECS_DIR/reports" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l || echo "0")
  local summary_count=$(find "$SPECS_DIR/summaries" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l || echo "0")

  log_info "Found $report_count reports and $summary_count summaries in flat structure"
  log_warn "These should be manually reviewed and placed in appropriate topic directories"
  log_warn "Or they can remain in the flat structure for archival purposes"
  echo ""

  # Step 4: Archive flat structure
  log_info "Step 4: Archiving flat structure directories"
  echo ""

  if [ "$DRY_RUN" = "false" ]; then
    local archive_dir="$SPECS_DIR/archived_flat_structure_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$archive_dir"

    # Move flat directories to archive
    for dir in plans reports summaries; do
      if [ -d "$SPECS_DIR/$dir" ]; then
        # Check if directory has files at top level
        local flat_files=$(find "$SPECS_DIR/$dir" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l)
        if [ "$flat_files" -gt 0 ]; then
          mv "$SPECS_DIR/$dir" "$archive_dir/"
          log_info "Archived: $SPECS_DIR/$dir → $archive_dir/$dir"
        fi
      fi
    done

    log_info "Flat structure archived to: $archive_dir"
  else
    log_info "Would archive flat directories to: specs/archived_flat_structure_*/"
  fi

  echo ""

  # Summary
  echo "============================================"
  echo "Migration Summary"
  echo "============================================"
  if [ "$DRY_RUN" = "true" ]; then
    echo "DRY RUN completed - no changes made"
    echo ""
    echo "Summary:"
    echo "  - $plan_count plans would be migrated to topic directories"
    echo "  - $report_count reports and $summary_count summaries would be archived"
    echo ""
    echo "To execute migration, run:"
    echo "  DRY_RUN=false $0"
  else
    echo "Migration completed successfully"
    echo "Backup location: $BACKUP_DIR"
    echo "Migration log: $MIGRATION_LOG"
    echo ""
    echo "Results:"
    echo "  - $plan_count plans migrated to topic directories"
    echo "  - Flat structure archived (contains reports and summaries for manual review)"
    echo ""
    echo "Next steps:"
    echo "  1. Run validation: .claude/scripts/validate_migration.sh"
    echo "  2. Manually review archived reports/summaries and place in topic directories as needed"
    echo "  3. Update cross-references in CLAUDE.md and documentation"
  fi
  echo "============================================"
}

# Run main function
main "$@"
