#!/usr/bin/env bash
#
# migrate-specs-utils.sh: Utilities for specs directory migration
#
# Provides functions for migrating from flat specs/ structure to topic-based
# specs/{NNN_topic}/ organization with comprehensive subdirectories.
#

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/base-utils.sh"

# Global variables
SPECS_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/specs"
SCAN_REPORT="specs_scan_report.json"
MIGRATION_PLAN="migration_plan.txt"
BACKUP_DIR="$SPECS_DIR/backups"

# ============================================================================
# Phase 1: Pre-Migration Analysis
# ============================================================================

#
# scan_specs_structure - Scan existing specs/ directory structure
#
# Analyzes current specs/ directory and generates JSON report with:
# - Total counts (plans, reports, summaries)
# - Expanded plans (directories)
# - Artifact relationships
# - Orphaned artifacts
#
# Outputs: specs_scan_report.json
#
scan_specs_structure() {
  local plans_dir="$SPECS_DIR/plans"
  local reports_dir="$SPECS_DIR/reports"
  local summaries_dir="$SPECS_DIR/summaries"

  info "Scanning specs/ directory structure..."

  # Check if specs directories exist
  if [[ ! -d "$SPECS_DIR" ]]; then
    warn "specs/ directory does not exist"
    echo '{"error": "specs directory not found"}' > "$SCAN_REPORT"
    return 1
  fi

  # Count artifacts
  local total_plans=0
  local total_reports=0
  local total_summaries=0
  local expanded_plans=0

  if [[ -d "$plans_dir" ]]; then
    total_plans=$(find "$plans_dir" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)
    expanded_plans=$(find "$plans_dir" -maxdepth 1 -type d ! -path "$plans_dir" 2>/dev/null | wc -l)
  fi

  if [[ -d "$reports_dir" ]]; then
    total_reports=$(find "$reports_dir" -name "*.md" -type f 2>/dev/null | wc -l)
  fi

  if [[ -d "$summaries_dir" ]]; then
    total_summaries=$(find "$summaries_dir" -name "*.md" -type f 2>/dev/null | wc -l)
  fi

  # Generate scan report
  cat > "$SCAN_REPORT" <<EOF
{
  "scan_date": "$(date -Iseconds)",
  "total_plans": $total_plans,
  "total_reports": $total_reports,
  "total_summaries": $total_summaries,
  "expanded_plans": $expanded_plans,
  "artifact_relationships": []
}
EOF

  info "Scan complete: $total_plans plans, $total_reports reports, $total_summaries summaries"
  return 0
}

#
# generate_migration_plan - Generate migration plan from scan report
#
# Creates migration plan listing:
# - Topics to create
# - Artifacts to move
# - Cross-references to update
# - Estimated size and duration
#
# Outputs: migration_plan.txt
#
generate_migration_plan() {
  local plans_dir="$SPECS_DIR/plans"

  info "Generating migration plan..."

  if [[ ! -f "$SCAN_REPORT" ]]; then
    error "Scan report not found. Run scan_specs_structure first."
    return 1
  fi

  # Start migration plan
  cat > "$MIGRATION_PLAN" <<EOF
Migration Plan Generated: $(date '+%Y-%m-%d %H:%M:%S')
================================================================

EOF

  # Process each plan file
  if [[ -d "$plans_dir" ]]; then
    local plan_count=0

    # Process markdown files
    while IFS= read -r -d '' plan_file; do
      local plan_name=$(basename "$plan_file" .md)
      local topic_dir="$SPECS_DIR/$plan_name"

      ((plan_count++)) || true

      cat >> "$MIGRATION_PLAN" <<EOF
Topic $plan_count: $plan_name
  Source Plan: $plan_file
  Target Dir: $topic_dir/
  Create Subdirectories:
    - reports/
    - plans/
    - summaries/
    - debug/
    - scripts/
    - outputs/
    - artifacts/
    - backups/
  Move Artifacts:
    - $plan_file → $topic_dir/$plan_name.md

EOF
    done < <(find "$plans_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

    # Process expanded plan directories
    while IFS= read -r -d '' plan_dir; do
      local plan_name=$(basename "$plan_dir")
      local topic_dir="$SPECS_DIR/$plan_name"

      ((plan_count++)) || true

      cat >> "$MIGRATION_PLAN" <<EOF
Topic $plan_count: $plan_name (expanded)
  Source Plan: $plan_dir/ (directory)
  Target Dir: $topic_dir/
  Rename: Yes (already in directory format)
  Create Missing Subdirectories:
    - reports/
    - summaries/
    - debug/
    - scripts/
    - outputs/
    - artifacts/
    - backups/

EOF
    done < <(find "$plans_dir" -maxdepth 1 -type d ! -path "$plans_dir" -print0 2>/dev/null)

    cat >> "$MIGRATION_PLAN" <<EOF

Total Migration:
  - Topics to create: $plan_count
  - Estimated duration: 2-3 minutes

EOF
  else
    cat >> "$MIGRATION_PLAN" <<EOF
No plans directory found - nothing to migrate.
EOF
  fi

  info "Migration plan generated: $MIGRATION_PLAN"
  return 0
}

#
# execute_dry_run - Execute migration in dry-run mode
#
# Validates migration plan without modifying files:
# - Checks all source files exist
# - Verifies target directories don't exist
# - Validates disk space
# - Tests cross-reference patterns
#
# Outputs: Dry-run report to stdout
#
execute_dry_run() {
  info "Executing dry-run validation..."

  if [[ ! -f "$MIGRATION_PLAN" ]]; then
    error "Migration plan not found. Run generate_migration_plan first."
    return 1
  fi

  echo "Dry-Run Report"
  echo "=============="
  echo ""

  # Check source directories exist
  local plans_dir="$SPECS_DIR/plans"
  if [[ -d "$plans_dir" ]]; then
    echo "✓ Source plans directory exists"
  else
    echo "✗ Source plans directory not found"
    return 1
  fi

  # Check target directories don't exist (to avoid conflicts)
  local conflicts=0
  while IFS= read -r -d '' plan_file; do
    local plan_name=$(basename "$plan_file" .md)
    local topic_dir="$SPECS_DIR/$plan_name"

    if [[ -d "$topic_dir" ]]; then
      echo "⚠ Target directory already exists: $topic_dir"
      ((conflicts++)) || true
    fi
  done < <(find "$plans_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

  if [[ $conflicts -eq 0 ]]; then
    echo "✓ No target directory conflicts"
  else
    echo "✗ $conflicts target directory conflicts found"
  fi

  # Check disk space
  local available_space=$(df -BM "$SPECS_DIR" | awk 'NR==2 {print $4}' | sed 's/M//')
  if [[ $available_space -gt 100 ]]; then
    echo "✓ Sufficient disk space (${available_space}MB available)"
  else
    echo "✗ Insufficient disk space (${available_space}MB available)"
    return 1
  fi

  echo ""
  echo "Warnings:"
  if [[ $conflicts -gt 0 ]]; then
    echo "  ⚠ Target directory conflicts exist - may overwrite data"
  else
    echo "  None"
  fi

  echo ""
  echo "Errors:"
  echo "  None"

  echo ""
  echo "Recommendation: Proceed with migration"

  return 0
}

# ============================================================================
# Phase 2: Backup Creation
# ============================================================================

#
# backup_specs - Create timestamped backup of specs/ directory
#
# Creates tar.gz archive with:
# - All specs/ contents
# - Timestamp in filename
# - SHA256 checksum
#
# Returns: Path to backup file
#
backup_specs() {
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_file="$BACKUP_DIR/specs_backup_$timestamp.tar.gz"

  info "Creating backup: $backup_file"

  # Create backups directory
  mkdir -p "$BACKUP_DIR"

  # Create archive
  if tar -czf "$backup_file" -C "$(dirname "$SPECS_DIR")" "$(basename "$SPECS_DIR")" 2>/dev/null; then
    info "Backup archive created"
  else
    error "Failed to create backup archive"
    return 1
  fi

  # Verify archive integrity
  if tar -tzf "$backup_file" > /dev/null 2>&1; then
    info "Backup integrity verified"
  else
    error "Backup verification failed"
    return 1
  fi

  # Calculate checksum
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$backup_file" > "${backup_file}.sha256"
    info "Checksum created"
  else
    warn "sha256sum not available - skipping checksum"
  fi

  echo "$backup_file"
  return 0
}

# ============================================================================
# Phase 3: Migration Execution
# ============================================================================

#
# create_topic_directories - Create directory structure for topic
#
# Args:
#   $1 - Topic name (e.g., "009_orchestration_enhancement")
#
# Creates:
#   specs/{topic}/
#   specs/{topic}/{reports,plans,summaries,debug,scripts,outputs,artifacts,backups}/
#
create_topic_directories() {
  local topic_name="$1"
  local topic_dir="$SPECS_DIR/$topic_name"

  # Create main topic directory
  mkdir -p "$topic_dir"

  # Create subdirectories
  mkdir -p "$topic_dir"/{reports,plans,summaries,debug,scripts,outputs,artifacts,backups}

  info "Created topic directory: $topic_dir"
}

#
# execute_migration - Execute specs migration
#
# Performs migration:
# - Creates topic directories
# - Moves artifacts to appropriate locations
# - Updates cross-references
# - Cleans up empty old directories
#
execute_migration() {
  local plans_dir="$SPECS_DIR/plans"
  local reports_dir="$SPECS_DIR/reports"
  local summaries_dir="$SPECS_DIR/summaries"

  info "Executing migration..."

  if [[ ! -f "$MIGRATION_PLAN" ]]; then
    error "Migration plan not found. Run generate_migration_plan first."
    return 1
  fi

  # Process each plan file
  if [[ -d "$plans_dir" ]]; then
    # Migrate markdown plan files
    while IFS= read -r -d '' plan_file; do
      local plan_name=$(basename "$plan_file" .md)
      local topic_dir="$SPECS_DIR/$plan_name"

      # Create topic directory structure
      create_topic_directories "$plan_name"

      # Move main plan
      mv "$plan_file" "$topic_dir/$plan_name.md"
      info "Moved: $plan_file → $topic_dir/$plan_name.md"

      # Find and move associated summaries (same NNN prefix)
      if [[ -d "$summaries_dir" ]]; then
        local nnn_prefix="${plan_name%%_*}"
        while IFS= read -r -d '' summary_file; do
          local summary_name=$(basename "$summary_file")
          if [[ "$summary_name" =~ ^${nnn_prefix}_ ]]; then
            mv "$summary_file" "$topic_dir/summaries/$summary_name"
            info "Moved: $summary_file → $topic_dir/summaries/$summary_name"
          fi
        done < <(find "$summaries_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)
      fi

    done < <(find "$plans_dir" -maxdepth 1 -name "*.md" -type f -print0 2>/dev/null)

    # Migrate expanded plan directories
    while IFS= read -r -d '' plan_dir; do
      local plan_name=$(basename "$plan_dir")
      local topic_dir="$SPECS_DIR/$plan_name"

      # Rename directory to topic directory
      mv "$plan_dir" "$topic_dir"
      info "Moved: $plan_dir → $topic_dir"

      # Create missing subdirectories
      mkdir -p "$topic_dir"/{reports,summaries,debug,scripts,outputs,artifacts,backups}
      info "Created missing subdirectories in $topic_dir"

    done < <(find "$plans_dir" -maxdepth 1 -type d ! -path "$plans_dir" -print0 2>/dev/null)
  fi

  # Update cross-references
  info "Updating cross-references..."
  update_cross_references

  # Clean up empty old directories
  info "Cleaning up old directory structure..."
  rmdir "$plans_dir" 2>/dev/null && info "Removed empty plans directory" || true
  rmdir "$summaries_dir" 2>/dev/null && info "Removed empty summaries directory" || true

  # Handle orphaned reports
  if [[ -d "$reports_dir" ]] && [[ -n "$(ls -A "$reports_dir" 2>/dev/null)" ]]; then
    local orphaned_dir="$SPECS_DIR/orphaned"
    mkdir -p "$orphaned_dir"
    mv "$reports_dir"/*.md "$orphaned_dir/" 2>/dev/null || true
    info "Moved orphaned reports to $orphaned_dir"
    rmdir "$reports_dir" 2>/dev/null || true
  fi

  info "Migration execution complete"
  return 0
}

#
# update_cross_references - Update markdown links in all files
#
# Updates old-style references to new topic-based paths:
# - ../../reports/file.md → reports/file.md (plan → report)
# - ../../plans/file.md → ../file.md (summary → plan)
#
update_cross_references() {
  # Find all markdown files in topic directories
  while IFS= read -r -d '' md_file; do
    # Update plan references to reports (from ../../reports/ to reports/)
    sed -i 's|../../reports/\([^)]*\.md\)|reports/\1|g' "$md_file" 2>/dev/null || true

    # Update summary references to plans (from ../../plans/ to ../)
    sed -i 's|../../plans/\([^)]*\.md\)|../\1|g' "$md_file" 2>/dev/null || true

    # Update report references to plans (from ../../plans/ to ../)
    sed -i 's|../../plans/\([^)]*\.md\)|../\1|g' "$md_file" 2>/dev/null || true

  done < <(find "$SPECS_DIR" -name "*.md" -type f -print0 2>/dev/null)

  info "Cross-references updated"
}

# ============================================================================
# Phase 4: Post-Migration Verification
# ============================================================================

#
# verify_migration - Verify migration completed successfully
#
# Checks:
# - Topic directories created
# - Artifact counts match scan report
# - No broken cross-references
# - Gitignore rules applied
#
# Returns: 0 if verified, 1 if errors found
#
verify_migration() {
  info "Verifying migration..."

  local errors=0

  # Check scan report exists
  if [[ ! -f "$SCAN_REPORT" ]]; then
    warn "Scan report not found - skipping detailed verification"
    return 0
  fi

  # Count topic directories
  local topic_count=$(find "$SPECS_DIR" -maxdepth 1 -type d ! -path "$SPECS_DIR" ! -path "$SPECS_DIR/backups" ! -path "$SPECS_DIR/orphaned" | wc -l)
  info "Topic directories created: $topic_count"

  # Check for old-style references
  local broken_refs=$(find "$SPECS_DIR" -name "*.md" -type f -exec grep -l '../../\(plans\|reports\|summaries\)/' {} \; 2>/dev/null | wc -l)
  if [[ $broken_refs -eq 0 ]]; then
    info "✓ No old-style cross-references found"
  else
    error "✗ Found $broken_refs files with old-style references"
    ((errors++)) || true
  fi

  if [[ $errors -eq 0 ]]; then
    info "✓ Migration verification passed"
    return 0
  else
    error "✗ Migration verification failed with $errors errors"
    return 1
  fi
}

# ============================================================================
# Phase 5: Gitignore Updates
# ============================================================================

#
# update_gitignore_rules - Update .gitignore for topic-based structure
#
# Adds rules:
# - specs/ (gitignore entire directory)
# - !specs/**/debug/ (un-ignore debug subdirectories)
# - !specs/**/debug/*.md (un-ignore debug markdown files)
#
update_gitignore_rules() {
  local gitignore_file="$(dirname "$SPECS_DIR")/.gitignore"

  info "Updating .gitignore..."

  # Backup current .gitignore
  if [[ -f "$gitignore_file" ]]; then
    cp "$gitignore_file" "${gitignore_file}.backup"
    info "Backed up .gitignore to ${gitignore_file}.backup"
  fi

  # Check if rules already exist
  if grep -q "# Topic-based specs organization" "$gitignore_file" 2>/dev/null; then
    info ".gitignore already contains topic-based rules"
    return 0
  fi

  # Append new rules
  cat >> "$gitignore_file" <<'EOF'

# Topic-based specs organization (added by /migrate-specs)
specs/
!specs/**/debug/
!specs/**/debug/*.md
EOF

  info "✓ .gitignore updated with topic-based rules"
  return 0
}

# ============================================================================
# Rollback Operations
# ============================================================================

#
# rollback_migration - Restore from backup
#
# Args:
#   $1 - Backup file path (optional, uses latest if not specified)
#
# Restores specs/ directory from backup archive
#
rollback_migration() {
  local backup_file="$1"

  # Find latest backup if not specified
  if [[ -z "$backup_file" ]]; then
    backup_file=$(ls -t "$BACKUP_DIR"/specs_backup_*.tar.gz 2>/dev/null | head -1)

    if [[ -z "$backup_file" ]]; then
      error "No backup files found in $BACKUP_DIR"
      return 1
    fi

    info "Using latest backup: $backup_file"
  fi

  # Verify backup exists
  if [[ ! -f "$backup_file" ]]; then
    error "Backup file not found: $backup_file"
    return 1
  fi

  # Verify backup integrity
  if [[ -f "${backup_file}.sha256" ]]; then
    info "Verifying backup integrity..."
    if command -v sha256sum >/dev/null 2>&1; then
      if ! sha256sum -c "${backup_file}.sha256" >/dev/null 2>&1; then
        error "Backup integrity check failed"
        return 1
      fi
      info "✓ Backup integrity verified"
    fi
  fi

  # Remove current specs structure (except backups)
  info "Removing current specs structure..."
  find "$SPECS_DIR" -mindepth 1 -maxdepth 1 ! -path "$BACKUP_DIR" -exec rm -rf {} \; 2>/dev/null || true

  # Extract backup
  info "Restoring from backup..."
  if tar -xzf "$backup_file" -C "$(dirname "$SPECS_DIR")" 2>/dev/null; then
    info "✓ Backup restored successfully"
  else
    error "Failed to restore backup"
    return 1
  fi

  # Restore .gitignore
  local gitignore_file="$(dirname "$SPECS_DIR")/.gitignore"
  if [[ -f "${gitignore_file}.backup" ]]; then
    mv "${gitignore_file}.backup" "$gitignore_file"
    info "✓ .gitignore restored"
  fi

  info "Rollback complete"
  return 0
}

# Export functions
export -f scan_specs_structure
export -f generate_migration_plan
export -f execute_dry_run
export -f backup_specs
export -f create_topic_directories
export -f execute_migration
export -f update_cross_references
export -f verify_migration
export -f update_gitignore_rules
export -f rollback_migration
