#!/usr/bin/env bash
# Validation script for topic-based spec structure migration
# Usage: ./validate_migration.sh [--verbose]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CLAUDE_DIR/.." && pwd)"

# Configuration
SPECS_DIR="$CLAUDE_DIR/specs"
VERBOSE=false

# Parse command line arguments
if [[ "${1:-}" == "--verbose" ]]; then
  VERBOSE=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Test results
declare -a FAILURES
declare -a WARNINGS

# Logging functions
log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((PASS_COUNT++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAILURES+=("$1")
  ((FAIL_COUNT++))
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  WARNINGS+=("$1")
  ((WARN_COUNT++))
}

log_info() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}[INFO]${NC} $1"
  fi
}

# Validation tests
validate_no_flat_structure() {
  echo "=========================================="
  echo "Test 1: No artifacts remain in flat structure"
  echo "=========================================="

  local flat_plans=$(find "$SPECS_DIR/plans" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l || echo "0")
  local flat_reports=$(find "$SPECS_DIR/reports" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l || echo "0")
  local flat_summaries=$(find "$SPECS_DIR/summaries" -maxdepth 1 -type f -name "*.md" 2>/dev/null | wc -l || echo "0")

  if [ "$flat_plans" -eq 0 ]; then
    log_pass "No plans remain in flat specs/plans/ directory"
  else
    log_fail "Found $flat_plans plans in flat specs/plans/ directory"
  fi

  if [ "$flat_reports" -eq 0 ]; then
    log_pass "No reports remain in flat specs/reports/ directory"
  else
    log_fail "Found $flat_reports reports in flat specs/reports/ directory"
  fi

  if [ "$flat_summaries" -eq 0 ]; then
    log_pass "No summaries remain in flat specs/summaries/ directory"
  else
    log_fail "Found $flat_summaries summaries in flat specs/summaries/ directory"
  fi

  echo ""
}

validate_topic_directories() {
  echo "=========================================="
  echo "Test 2: Topic directories have standard subdirectories"
  echo "=========================================="

  local topic_dirs=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" 2>/dev/null)

  if [ -z "$topic_dirs" ]; then
    log_fail "No topic directories found in $SPECS_DIR"
    echo ""
    return
  fi

  local topic_count=0
  local valid_topic_count=0

  while IFS= read -r topic_dir; do
    ((topic_count++))
    local topic_name=$(basename "$topic_dir")
    log_info "Checking topic: $topic_name"

    # Required subdirectories
    local required_subdirs=("plans" "reports" "summaries" "debug" "scripts" "outputs" "artifacts" "backups")
    local has_all_subdirs=true

    for subdir in "${required_subdirs[@]}"; do
      if [ ! -d "$topic_dir/$subdir" ]; then
        log_fail "Topic $topic_name missing subdirectory: $subdir"
        has_all_subdirs=false
      else
        log_info "  ✓ $subdir/"
      fi
    done

    # Check for .gitkeep in debug directory
    if [ ! -f "$topic_dir/debug/.gitkeep" ]; then
      log_warn "Topic $topic_name missing debug/.gitkeep file"
    fi

    if [ "$has_all_subdirs" = true ]; then
      ((valid_topic_count++))
    fi

  done <<< "$topic_dirs"

  if [ "$valid_topic_count" -eq "$topic_count" ]; then
    log_pass "All $topic_count topic directories have required subdirectories"
  else
    log_fail "Only $valid_topic_count of $topic_count topic directories have all required subdirectories"
  fi

  echo ""
}

validate_gitignore_compliance() {
  echo "=========================================="
  echo "Test 3: Gitignore compliance (debug/ committed, others ignored)"
  echo "=========================================="

  local topic_dirs=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" 2>/dev/null)

  if [ -z "$topic_dirs" ]; then
    log_warn "No topic directories found for gitignore validation"
    echo ""
    return
  fi

  local compliance_pass=true

  while IFS= read -r topic_dir; do
    local topic_name=$(basename "$topic_dir")

    # Check that debug/ is NOT ignored (should be committed)
    if git check-ignore -q "$topic_dir/debug" 2>/dev/null; then
      log_fail "Topic $topic_name: debug/ is gitignored (should be committed)"
      compliance_pass=false
    else
      log_info "  ✓ $topic_name: debug/ not gitignored"
    fi

    # Check that other subdirectories ARE ignored
    local ignored_subdirs=("plans" "reports" "summaries" "scripts" "outputs" "artifacts" "backups")

    for subdir in "${ignored_subdirs[@]}"; do
      if [ -d "$topic_dir/$subdir" ]; then
        # Check if at least one file in the subdirectory would be ignored
        local test_file="$topic_dir/$subdir/test.md"
        if git check-ignore -q "$test_file" 2>/dev/null; then
          log_info "  ✓ $topic_name: $subdir/ is gitignored"
        else
          log_warn "Topic $topic_name: $subdir/ is NOT gitignored (should be gitignored)"
          compliance_pass=false
        fi
      fi
    done

  done <<< "$topic_dirs"

  if [ "$compliance_pass" = true ]; then
    log_pass "All topic directories comply with gitignore rules"
  else
    log_fail "Some topic directories have gitignore violations"
  fi

  echo ""
}

validate_cross_references() {
  echo "=========================================="
  echo "Test 4: No broken cross-references"
  echo "=========================================="

  # Search for old flat structure references in topic-based files
  local broken_refs=0

  # Check for references to specs/plans/, specs/reports/, specs/summaries/ in topic files
  local topic_files=$(find "$SPECS_DIR" -path "*/[0-9][0-9][0-9]_*/*.md" -type f 2>/dev/null)

  if [ -z "$topic_files" ]; then
    log_warn "No topic files found for cross-reference validation"
    echo ""
    return
  fi

  while IFS= read -r file; do
    # Check for flat structure references
    if grep -q "specs/plans/[0-9]" "$file" 2>/dev/null; then
      log_fail "File $(basename "$file") contains reference to flat specs/plans/"
      ((broken_refs++))
    fi

    if grep -q "specs/reports/[0-9]" "$file" 2>/dev/null; then
      log_fail "File $(basename "$file") contains reference to flat specs/reports/"
      ((broken_refs++))
    fi

    if grep -q "specs/summaries/[0-9]" "$file" 2>/dev/null; then
      log_fail "File $(basename "$file") contains reference to flat specs/summaries/"
      ((broken_refs++))
    fi

  done <<< "$topic_files"

  if [ "$broken_refs" -eq 0 ]; then
    log_pass "No broken cross-references found"
  else
    log_fail "Found $broken_refs broken cross-references to flat structure"
  fi

  echo ""
}

validate_numbering() {
  echo "=========================================="
  echo "Test 5: Artifact numbering within topics"
  echo "=========================================="

  local numbering_issues=0
  local topic_dirs=$(find "$SPECS_DIR" -maxdepth 1 -type d -name "[0-9][0-9][0-9]_*" 2>/dev/null)

  if [ -z "$topic_dirs" ]; then
    log_warn "No topic directories found for numbering validation"
    echo ""
    return
  fi

  while IFS= read -r topic_dir; do
    local topic_name=$(basename "$topic_dir")

    # Check numbering in each artifact type subdirectory
    for subdir in plans reports summaries debug; do
      if [ -d "$topic_dir/$subdir" ]; then
        local files=$(find "$topic_dir/$subdir" -maxdepth 1 -type f -name "[0-9]*.md" 2>/dev/null | sort)

        if [ -n "$files" ]; then
          local expected=1
          while IFS= read -r file; do
            local filename=$(basename "$file")

            if [[ "$filename" =~ ^([0-9]+)_ ]]; then
              local number="${BASH_REMATCH[1]}"
              # Remove leading zeros for comparison
              local number_int=$((10#$number))

              if [ "$number_int" -ne "$expected" ]; then
                log_warn "Topic $topic_name/$subdir: Expected number $expected, found $number in $filename"
                ((numbering_issues++))
              else
                log_info "  ✓ $topic_name/$subdir/$filename (correct numbering)"
              fi

              ((expected++))
            fi
          done <<< "$files"
        fi
      fi
    done

  done <<< "$topic_dirs"

  if [ "$numbering_issues" -eq 0 ]; then
    log_pass "All artifact numbering is sequential within topics"
  else
    log_warn "Found $numbering_issues numbering gaps or issues"
  fi

  echo ""
}

validate_backup_exists() {
  echo "=========================================="
  echo "Test 6: Migration backup exists"
  echo "=========================================="

  local backup_dir=$(find "$SPECS_DIR/backups" -maxdepth 1 -type d -name "pre_migration_*" 2>/dev/null | tail -1)

  if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
    log_pass "Migration backup found at: $backup_dir"

    # Verify backup has content
    local backup_files=$(find "$backup_dir" -type f -name "*.md" 2>/dev/null | wc -l)
    if [ "$backup_files" -gt 0 ]; then
      log_pass "Backup contains $backup_files files"
    else
      log_warn "Backup directory exists but contains no markdown files"
    fi
  else
    log_warn "No migration backup found in $SPECS_DIR/backups/"
  fi

  echo ""
}

# Generate summary report
generate_summary() {
  echo "=========================================="
  echo "Validation Summary"
  echo "=========================================="
  echo ""
  echo "Tests Passed: $PASS_COUNT"
  echo "Tests Failed: $FAIL_COUNT"
  echo "Warnings:     $WARN_COUNT"
  echo ""

  if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Failures:"
    for failure in "${FAILURES[@]}"; do
      echo "  - $failure"
    done
    echo ""
  fi

  if [ "$WARN_COUNT" -gt 0 ] && [ "$VERBOSE" = true ]; then
    echo "Warnings:"
    for warning in "${WARNINGS[@]}"; do
      echo "  - $warning"
    done
    echo ""
  fi

  if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ Migration validation PASSED${NC}"
    echo ""
    echo "The topic-based structure migration completed successfully."
    return 0
  else
    echo -e "${RED}✗ Migration validation FAILED${NC}"
    echo ""
    echo "Please review and fix the issues above before proceeding."
    return 1
  fi
}

# Main validation workflow
main() {
  echo "============================================"
  echo "Spec Structure Migration Validation"
  echo "============================================"
  echo ""

  validate_no_flat_structure
  validate_topic_directories
  validate_gitignore_compliance
  validate_cross_references
  validate_numbering
  validate_backup_exists

  generate_summary
}

# Run main function
main "$@"
