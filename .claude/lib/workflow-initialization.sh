#!/usr/bin/env bash
# Shared workflow initialization utilities
# Provides consolidated Phase 0 initialization for orchestration commands
#
# This library implements the 3-step initialization pattern from /research:
# 1. STEP 1: Scope detection (research-only, research+planning, full workflow)
# 2. STEP 2: Path pre-calculation (topic dir, subdirs, artifact paths)
# 3. STEP 3: Directory structure creation (lazy creation, only topic root initially)
#
# Usage:
#   source .claude/lib/workflow-initialization.sh
#   initialize_workflow_paths "$WORKFLOW_DESC" "$WORKFLOW_TYPE"
#   # Returns: Exports all path variables (TOPIC_DIR, PLANS_DIR, etc.)

set -euo pipefail

# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source required dependencies
if [ -f "$SCRIPT_DIR/topic-utils.sh" ]; then
  source "$SCRIPT_DIR/topic-utils.sh"
else
  echo "ERROR: topic-utils.sh not found" >&2
  echo "Expected location: $SCRIPT_DIR/topic-utils.sh" >&2
  exit 1
fi

if [ -f "$SCRIPT_DIR/detect-project-dir.sh" ]; then
  source "$SCRIPT_DIR/detect-project-dir.sh"
else
  echo "ERROR: detect-project-dir.sh not found" >&2
  echo "Expected location: $SCRIPT_DIR/detect-project-dir.sh" >&2
  exit 1
fi

# ==============================================================================
# Core Function: initialize_workflow_paths
# ==============================================================================

# initialize_workflow_paths: Consolidate Phase 0 initialization (350+ lines → ~100 lines)
#
# Implements 3-step pattern:
#   STEP 1: Scope detection (research-only, research+planning, full workflow)
#   STEP 2: Path pre-calculation (all artifact paths calculated upfront)
#   STEP 3: Directory structure creation (lazy: only topic root created initially)
#
# Arguments:
#   $1 - WORKFLOW_DESCRIPTION: User's workflow description (e.g., "implement auth")
#   $2 - WORKFLOW_SCOPE: Workflow type (research-only, research-and-plan, full-implementation, debug-only)
#
# Exports (all paths exported to calling script):
#   LOCATION - Project root directory
#   PROJECT_ROOT - Same as LOCATION (for compatibility)
#   SPECS_ROOT - Specs directory path
#   TOPIC_NUM - Topic number (e.g., 042)
#   TOPIC_NAME - Sanitized topic name (e.g., implement_auth)
#   TOPIC_PATH - Full topic directory path
#   RESEARCH_SUBDIR - Research reports subdirectory
#   OVERVIEW_PATH - Overview synthesis path (empty initially, set conditionally)
#   REPORT_PATHS - Array of research report paths (max 4 topics)
#   PLAN_PATH - Implementation plan path
#   IMPL_ARTIFACTS - Implementation artifacts directory
#   DEBUG_REPORT - Debug analysis report path
#   SUMMARY_PATH - Implementation summary path
#   SUCCESSFUL_REPORT_PATHS - Array to track successful reports
#   SUCCESSFUL_REPORT_COUNT - Count of successful reports
#   TESTS_PASSING - Test status tracker
#   IMPLEMENTATION_OCCURRED - Implementation status tracker
#
# Returns:
#   0 on success, 1 on failure
#
# Progress markers (for user visibility):
#   - "Detecting workflow scope..."
#   - "Pre-calculating artifact paths..."
#   - "Creating topic directory structure..."
#
initialize_workflow_paths() {
  local workflow_description="${1:-}"
  local workflow_scope="${2:-}"

  # Validate inputs
  if [ -z "$workflow_description" ]; then
    echo "ERROR: initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument" >&2
    return 1
  fi

  if [ -z "$workflow_scope" ]; then
    echo "ERROR: initialize_workflow_paths() requires WORKFLOW_SCOPE as second argument" >&2
    return 1
  fi

  # ============================================================================
  # STEP 1: Scope Detection
  # ============================================================================

  echo "Detecting workflow scope..."
  echo ""

  # Display workflow scope information
  case "$workflow_scope" in
    research-only)
      echo "Workflow Scope: Research Only"
      echo "  - Research topic in parallel (2-4 agents)"
      echo "  - Generate overview synthesis"
      echo "  - Exit after Phase 1"
      ;;
    research-and-plan)
      echo "Workflow Scope: Research + Planning"
      echo "  - Research topic in parallel (2-4 agents)"
      echo "  - Generate implementation plan"
      echo "  - Exit after Phase 2"
      ;;
    full-implementation)
      echo "Workflow Scope: Full Implementation"
      echo "  - Research → Plan → Implement → Test → Document"
      echo "  - Full end-to-end workflow"
      ;;
    debug-only)
      echo "Workflow Scope: Debug Analysis"
      echo "  - Research root cause"
      echo "  - Generate debug report"
      echo "  - Exit after Phase 5"
      ;;
    *)
      echo "ERROR: Unknown workflow scope: $workflow_scope" >&2
      echo "Valid scopes: research-only, research-and-plan, full-implementation, debug-only" >&2
      return 1
      ;;
  esac
  echo ""

  # ============================================================================
  # STEP 2: Path Pre-Calculation
  # ============================================================================

  echo "Pre-calculating artifact paths..."
  echo ""

  # Get project root (from detect-project-dir.sh)
  local project_root="${CLAUDE_PROJECT_DIR}"
  if [ -z "$project_root" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "DIAGNOSTIC INFO: Project Root Detection Failed" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "ERROR: Could not determine project root" >&2
    echo "" >&2
    echo "Environment:" >&2
    echo "  CLAUDE_PROJECT_DIR: '${CLAUDE_PROJECT_DIR:-<not set>}'" >&2
    echo "  Current directory: $(pwd)" >&2
    echo "  Git repo: $(git rev-parse --show-toplevel 2>/dev/null || echo '<not a git repo>')" >&2
    echo "" >&2
    echo "Expected: CLAUDE_PROJECT_DIR should be set by detect-project-dir.sh" >&2
    echo "" >&2
    return 1
  fi

  # Determine specs directory
  local specs_root
  if [ -d "${project_root}/.claude/specs" ]; then
    specs_root="${project_root}/.claude/specs"
  elif [ -d "${project_root}/specs" ]; then
    specs_root="${project_root}/specs"
  else
    # Default to .claude/specs and create it
    specs_root="${project_root}/.claude/specs"
    mkdir -p "$specs_root"
  fi

  # Calculate topic metadata using utility functions
  local topic_num
  local topic_name
  topic_num=$(get_next_topic_number "$specs_root")
  topic_name=$(sanitize_topic_name "$workflow_description")

  # Validate required fields
  if [ -z "$project_root" ] || [ -z "$topic_num" ] || [ -z "$topic_name" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "DIAGNOSTIC INFO: Location Metadata Calculation Failed" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "ERROR: Failed to calculate location metadata" >&2
    echo "" >&2
    echo "Calculated Values:" >&2
    echo "  PROJECT_ROOT: '${project_root:-<empty>}'" >&2
    echo "  TOPIC_NUM: '${topic_num:-<empty>}'" >&2
    echo "  TOPIC_NAME: '${topic_name:-<empty>}'" >&2
    echo "" >&2
    echo "Source Values:" >&2
    echo "  SPECS_ROOT: '${specs_root:-<empty>}'" >&2
    echo "  WORKFLOW_DESCRIPTION: '${workflow_description:-<empty>}'" >&2
    echo "" >&2
    echo "Functions Used:" >&2
    echo "  get_next_topic_number() - from topic-utils.sh" >&2
    echo "  sanitize_topic_name() - from topic-utils.sh" >&2
    echo "" >&2
    return 1
  fi

  echo "Project Location: $project_root"
  echo "Specs Root: $specs_root"
  echo "Topic Number: $topic_num"
  echo "Topic Name: $topic_name"
  echo ""

  # Calculate topic path
  local topic_path="${specs_root}/${topic_num}_${topic_name}"

  # ============================================================================
  # STEP 3: Directory Structure Creation (Lazy Creation)
  # ============================================================================

  echo "Creating topic directory structure..."
  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  MANDATORY VERIFICATION - Topic Directory Creation"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "Creating topic root directory at: $topic_path"
  echo "   (Subdirectories created on-demand when files written)"
  echo ""

  # Create topic structure using utility function (creates only root directory)
  if ! create_topic_structure "$topic_path"; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "CRITICAL ERROR: Topic root directory creation failed" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Attempted Path: $topic_path" >&2
    echo "" >&2
    echo "Parent Directory Status:" >&2
    if [ -d "$(dirname "$topic_path")" ]; then
      echo "  Exists: Yes" >&2
      echo "  Permissions: $(ls -ld "$(dirname "$topic_path")" 2>/dev/null | awk '{print $1}')" >&2
      echo "  Owner: $(ls -ld "$(dirname "$topic_path")" 2>/dev/null | awk '{print $3":"$4}')" >&2
    else
      echo "  Exists: No" >&2
      echo "  Issue: Parent directory does not exist" >&2
    fi
    echo "" >&2
    echo "Diagnostic commands:" >&2
    echo "  # Check parent directory" >&2
    echo "  ls -ld \"$(dirname "$topic_path")\"" >&2
    echo "" >&2
    echo "  # Check permissions" >&2
    echo "  touch \"$(dirname "$topic_path")/test.tmp\" && rm \"$(dirname "$topic_path")/test.tmp\"" >&2
    echo "" >&2
    echo "  # Check disk space" >&2
    echo "  df -h \"$(dirname "$topic_path")\"" >&2
    echo "" >&2
    echo "Possible causes:" >&2
    echo "  - Insufficient permissions to create directory" >&2
    echo "  - Read-only filesystem" >&2
    echo "  - Disk full" >&2
    echo "  - Path contains invalid characters" >&2
    echo "" >&2
    echo "Workflow TERMINATED (fail-fast: no fallback mechanisms)" >&2
    return 1
  fi

  echo "✅ VERIFIED: Topic root directory exists at $topic_path"
  echo ""

  # VERIFICATION REQUIREMENT: Confirm before proceeding
  echo "Verification checkpoint passed - proceeding to artifact path calculation"
  echo ""

  # ============================================================================
  # Pre-calculate ALL artifact paths (exported to calling script)
  # ============================================================================

  # Research phase paths (calculate for max 4 topics)
  local -a report_paths
  for i in 1 2 3 4; do
    report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
  done

  # Define research subdirectory for overview synthesis
  local research_subdir="${topic_path}/reports"

  # Overview path will be calculated conditionally based on workflow scope
  # (see Phase 1: Research Overview section for actual path calculation)
  local overview_path=""  # Initialized empty, set conditionally during research phase

  # Planning phase paths
  local plan_path="${topic_path}/plans/001_${topic_name}_plan.md"

  # Implementation phase paths
  local impl_artifacts="${topic_path}/artifacts/"

  # Debug phase paths
  local debug_report="${topic_path}/debug/001_debug_analysis.md"

  # Documentation phase paths
  local summary_path="${topic_path}/summaries/${topic_num}_${topic_name}_summary.md"

  echo "Pre-calculated Artifact Paths:"
  echo "  Research Reports: ${#report_paths[@]} paths"
  echo "  Overview: $overview_path"
  echo "  Plan: $plan_path"
  echo "  Implementation: $impl_artifacts"
  echo "  Debug: $debug_report"
  echo "  Summary: $summary_path"
  echo ""

  # ============================================================================
  # Initialize tracking arrays
  # ============================================================================

  # Track successful report paths for Phase 1
  local -a successful_report_paths=()
  local successful_report_count=0

  # Track phase status
  local tests_passing="unknown"
  local implementation_occurred="false"

  # ============================================================================
  # Export all variables to calling script
  # ============================================================================

  # Export path variables
  export LOCATION="$project_root"
  export PROJECT_ROOT="$project_root"
  export SPECS_ROOT="$specs_root"
  export TOPIC_NUM="$topic_num"
  export TOPIC_NAME="$topic_name"
  export TOPIC_PATH="$topic_path"
  export RESEARCH_SUBDIR="$research_subdir"
  export OVERVIEW_PATH="$overview_path"
  export PLAN_PATH="$plan_path"
  export IMPL_ARTIFACTS="$impl_artifacts"
  export DEBUG_REPORT="$debug_report"
  export SUMMARY_PATH="$summary_path"

  # Export arrays (requires bash 4.2+ for declare -g)
  # Note: Arrays must be re-declared in calling script
  # Workaround: Use REPORT_PATHS_COUNT and individual REPORT_PATH_N variables
  export REPORT_PATHS_COUNT="${#report_paths[@]}"
  for i in "${!report_paths[@]}"; do
    export "REPORT_PATH_$i=${report_paths[$i]}"
  done

  # Export tracking variables
  export SUCCESSFUL_REPORT_COUNT="$successful_report_count"
  export TESTS_PASSING="$tests_passing"
  export IMPLEMENTATION_OCCURRED="$implementation_occurred"

  echo "Phase 0 Complete: Ready for Phase 1 (Research)"
  echo ""

  return 0
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# reconstruct_report_paths_array: Reconstruct REPORT_PATHS array from exported variables
#
# Usage:
#   reconstruct_report_paths_array
#   # Populates global REPORT_PATHS array
#
reconstruct_report_paths_array() {
  REPORT_PATHS=()
  for i in $(seq 0 $((REPORT_PATHS_COUNT - 1))); do
    local var_name="REPORT_PATH_$i"
    REPORT_PATHS+=("${!var_name}")
  done
}
