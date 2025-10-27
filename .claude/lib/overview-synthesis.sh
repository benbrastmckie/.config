#!/bin/bash
# overview-synthesis.sh
# Library for standardized overview synthesis decision logic across orchestration commands
#
# Used by: /research, /supervise, /coordinate
#
# Purpose: Provides uniform decision logic for when OVERVIEW.md synthesis should occur.
# Overview synthesis only happens when workflows conclude with research (no planning follows).
# When planning is next, the plan-architect agent synthesizes reports, making OVERVIEW.md redundant.

# Function: should_synthesize_overview
# Determines if overview synthesis should occur based on workflow scope and report count
#
# Arguments:
#   $1 - workflow_scope: The workflow type (research-only, research-and-plan, full-implementation, debug-only)
#   $2 - report_count: Number of successful research reports created
#
# Returns:
#   0 (true) if overview should be created
#   1 (false) if overview should NOT be created
#
# Decision Logic:
#   - Requires at least 2 reports for synthesis (can't synthesize 1 report into overview)
#   - Only synthesize if workflow concludes with research (no planning phase follows)
#   - research-only: Create overview (workflow ends here)
#   - research-and-plan: Skip overview (plan-architect will synthesize)
#   - full-implementation: Skip overview (plan-architect will synthesize)
#   - debug-only: Skip overview (debug doesn't produce research reports)
#   - unknown: Skip overview (conservative default)
#
# Usage:
#   if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
#     echo "Creating OVERVIEW.md"
#   else
#     echo "Skipping OVERVIEW.md"
#   fi
should_synthesize_overview() {
  local workflow_scope="$1"
  local report_count="$2"

  # Require at least 2 reports for synthesis
  # Rationale: Can't meaningfully synthesize a single report into an overview
  if [ "$report_count" -lt 2 ]; then
    return 1  # false
  fi

  # Only synthesize if workflow concludes with research (no planning follows)
  case "$workflow_scope" in
    research-only)
      # Workflow ends with research - create overview as final synthesis
      return 0  # true
      ;;
    research-and-plan|full-implementation)
      # Planning phase follows - plan-architect will synthesize reports
      # Creating overview here would be redundant
      return 1  # false
      ;;
    debug-only)
      # Debug workflow doesn't produce research reports
      # Should never reach here, but return false as safeguard
      return 1  # false
      ;;
    *)
      # Unknown workflow scope - default to no synthesis (conservative)
      # Better to skip synthesis than create unexpected artifacts
      return 1  # false
      ;;
  esac
}

# Function: calculate_overview_path
# Calculates the standardized path for OVERVIEW.md synthesis report
#
# Arguments:
#   $1 - research_subdir: The directory containing research reports (e.g., specs/042_auth/reports/001_auth_research)
#
# Returns:
#   Prints the standardized overview path to stdout
#
# Path Format:
#   ${research_subdir}/OVERVIEW.md
#
# Rationale:
#   - ALL CAPS distinguishes synthesis from numbered subtopic reports
#   - Same directory as subtopic reports for logical grouping
#   - Consistent with industry convention (README, LICENSE, OVERVIEW)
#
# Usage:
#   OVERVIEW_PATH=$(calculate_overview_path "$RESEARCH_SUBDIR")
#   echo "Overview will be created at: $OVERVIEW_PATH"
calculate_overview_path() {
  local research_subdir="$1"

  # Validate argument
  if [ -z "$research_subdir" ]; then
    echo "ERROR: calculate_overview_path requires research_subdir argument" >&2
    return 1
  fi

  # Return standardized path (ALL CAPS)
  echo "${research_subdir}/OVERVIEW.md"
}

# Function: get_synthesis_skip_reason
# Returns a human-readable explanation of why overview synthesis was skipped
#
# Arguments:
#   $1 - workflow_scope: The workflow type
#   $2 - report_count: Number of successful research reports created
#
# Returns:
#   Prints skip reason to stdout
#
# Usage:
#   if ! should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
#     REASON=$(get_synthesis_skip_reason "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT")
#     echo "⏭️  Skipping overview synthesis"
#     echo "  Reason: $REASON"
#   fi
get_synthesis_skip_reason() {
  local workflow_scope="$1"
  local report_count="$2"

  # Check report count first
  if [ "$report_count" -lt 2 ]; then
    echo "Insufficient reports for synthesis (need ≥2, have $report_count)"
    return 0
  fi

  # Check workflow scope
  case "$workflow_scope" in
    research-only)
      # Should not be called in this case (synthesis would occur)
      echo "ERROR: get_synthesis_skip_reason called for research-only workflow" >&2
      echo "Unknown"
      ;;
    research-and-plan|full-implementation)
      echo "Reports will be synthesized by plan-architect in Phase 2 (Planning)"
      ;;
    debug-only)
      echo "Debug workflow does not produce research reports requiring synthesis"
      ;;
    *)
      echo "Unknown workflow scope: $workflow_scope (defaulting to no synthesis)"
      ;;
  esac
}

# Export functions for use by sourcing scripts
export -f should_synthesize_overview
export -f calculate_overview_path
export -f get_synthesis_skip_reason
