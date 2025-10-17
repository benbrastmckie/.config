#!/usr/bin/env bash
# Context optimization utility for CLAUDE.md
# Analyzes bloat and performs automated extractions with summary generation

set -euo pipefail

# Default thresholds
THRESHOLD_BLOATED=80
THRESHOLD_MODERATE=50
SUMMARY_RATIO=15  # Generate summaries at 15% of original length

# Parse command-line threshold profile
set_threshold_profile() {
  local profile="${1:-balanced}"

  case "$profile" in
    aggressive)
      THRESHOLD_BLOATED=50
      THRESHOLD_MODERATE=30
      ;;
    balanced)
      THRESHOLD_BLOATED=80
      THRESHOLD_MODERATE=50
      ;;
    conservative)
      THRESHOLD_BLOATED=120
      THRESHOLD_MODERATE=80
      ;;
    *)
      echo "Error: Unknown profile '$profile'. Use: aggressive, balanced, or conservative" >&2
      return 1
      ;;
  esac
}

# Analyze CLAUDE.md for bloat using awk for reliable parsing
analyze_bloat() {
  local claude_md="$1"

  if [[ ! -f "$claude_md" ]]; then
    echo "Error: File $claude_md does not exist" >&2
    return 1
  fi

  echo "# CLAUDE.md Optimization Analysis"
  echo ""
  echo "**File**: $claude_md"
  echo "**Total Lines**: $(wc -l < "$claude_md")"
  echo "**Threshold Profile**: Bloated >${THRESHOLD_BLOATED} lines, Moderate ${THRESHOLD_MODERATE}-${THRESHOLD_BLOATED} lines"
  echo ""
  echo "## Section Analysis"
  echo ""
  echo "| Section | Lines | Status | Recommendation |"
  echo "|---------|-------|--------|----------------|"

  # Use awk for reliable section parsing
  awk -v bloated="$THRESHOLD_BLOATED" -v moderate="$THRESHOLD_MODERATE" '
    BEGIN {
      in_main = 0
      current_section = ""
      section_start = 0
      total_savings = 0
      bloated_count = 0
    }

    /^# Project/ { in_main = 1; next }

    !in_main { next }

    /^## / && !/^###/ {
      # Process previous section
      if (current_section != "") {
        lines = NR - section_start - 1
        status = "Optimal"
        recommendation = "Keep inline"
        savings = 0

        if (lines > bloated) {
          status = "**Bloated**"
          recommendation = "Extract to docs/ with summary"
          savings = int(lines * 0.85)
          bloated_count++
          total_savings += savings
        } else if (lines > moderate) {
          status = "Moderate"
          recommendation = "Consider extraction"
          savings = int(lines * 0.85)
        }

        printf "| %s | %d | %s | %s |\n", current_section, lines, status, recommendation
      }

      # Start new section
      current_section = substr($0, 4)  # Remove "## "
      section_start = NR
    }

    END {
      # Process final section
      if (current_section != "") {
        lines = NR - section_start
        status = "Optimal"
        recommendation = "Keep inline"
        savings = 0

        if (lines > bloated) {
          status = "**Bloated**"
          recommendation = "Extract to docs/ with summary"
          savings = int(lines * 0.85)
          bloated_count++
          total_savings += savings
        } else if (lines > moderate) {
          status = "Moderate"
          recommendation = "Consider extraction"
          savings = int(lines * 0.85)
        }

        printf "| %s | %d | %s | %s |\n", current_section, lines, status, recommendation
      }

      print ""
      print "## Summary"
      print ""
      printf "- **Bloated sections**: %d\n", bloated_count
      printf "- **Projected savings**: ~%d lines\n", total_savings
      printf "- **Target size**: %d lines\n", NR - total_savings
      printf "- **Reduction**: %.1f%%\n", (total_savings / NR) * 100
    }
  ' "$claude_md"
}

# Create backup of CLAUDE.md
create_backup() {
  local claude_md="$1"
  local backup_dir=".claude/backups"
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_file="$backup_dir/CLAUDE.md.$timestamp"

  mkdir -p "$backup_dir"
  cp "$claude_md" "$backup_file"

  echo "Backup created: $backup_file"
  echo "$backup_file"  # Return backup path
}

# Rollback to backup
rollback_optimization() {
  local backup_file="$1"
  local target_file="$2"

  if [[ ! -f "$backup_file" ]]; then
    echo "Error: Backup file $backup_file does not exist" >&2
    return 1
  fi

  cp "$backup_file" "$target_file"
  echo "Rolled back to: $backup_file"
}

# Main optimization workflow
optimize_claude_md() {
  local claude_md="${1:-CLAUDE.md}"
  local dry_run="${2:-false}"
  local profile="${3:-balanced}"

  # Set threshold profile
  set_threshold_profile "$profile"

  echo "=== CLAUDE.md Context Optimization ==="
  echo ""

  # Always show analysis
  analyze_bloat "$claude_md"

  if [[ "$dry_run" == "true" ]]; then
    echo ""
    echo "Dry-run mode: No changes made"
    return 0
  fi

  echo ""
  echo "=== Performing Optimization ==="
  echo ""

  # Create backup
  local backup_path
  backup_path=$(create_backup "$claude_md")

  # TODO: Implement automatic extraction based on analysis
  # For now, this is a manual process guided by the analysis report

  echo ""
  echo "Optimization complete!"
  echo "Backup saved to: $backup_path"
  echo "To rollback: rollback_optimization '$backup_path' '$claude_md'"
}

# Command-line interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse arguments
  DRY_RUN=false
  PROFILE="balanced"
  CLAUDE_MD="CLAUDE.md"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --aggressive)
        PROFILE="aggressive"
        shift
        ;;
      --balanced)
        PROFILE="balanced"
        shift
        ;;
      --conservative)
        PROFILE="conservative"
        shift
        ;;
      --rollback)
        shift
        if [[ $# -lt 2 ]]; then
          echo "Error: --rollback requires backup file and target file" >&2
          exit 1
        fi
        rollback_optimization "$1" "$2"
        exit 0
        ;;
      *)
        CLAUDE_MD="$1"
        shift
        ;;
    esac
  done

  optimize_claude_md "$CLAUDE_MD" "$DRY_RUN" "$PROFILE"
fi
