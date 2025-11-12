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

# Source guard: Prevent multiple sourcing
if [ -n "${WORKFLOW_INITIALIZATION_SOURCED:-}" ]; then
  return 0
fi
export WORKFLOW_INITIALIZATION_SOURCED=1

set -eo pipefail  # Removed -u flag to allow ${VAR:-} pattern in sourcing scripts

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
# Helper Function: extract_topic_from_plan_path
# ==============================================================================

# extract_topic_from_plan_path: Extract topic directory from plan path
#
# Used by research-and-revise workflows to determine which existing topic
# directory to use (instead of creating a new one).
#
# Arguments:
#   $1 - PLAN_PATH: Absolute path to existing plan (e.g., /path/to/specs/657_topic/plans/001_plan.md)
#
# Output:
#   Topic directory name (e.g., "657_topic") on stdout
#   Empty string on failure
#
# Returns:
#   0 on success, 1 on failure
#
# Expected Path Format:
#   /path/to/specs/NNN_topic_name/plans/NNN_plan_name.md
#   └─────────────┘ └────────────┘ └───┘ └──────────────┘
#   project root    topic dir      plans  plan file
#
# Regex Pattern:
#   /[^ ]+/specs/([0-9]{3}_[^/]+)/plans/[0-9]{3}_[^.]+\.md
#   Capture group 1: Topic directory (e.g., 657_review_tests_coordinate)
#
# Usage:
#   topic=$(extract_topic_from_plan_path "/home/user/.claude/specs/657_topic/plans/001_plan.md")
#   if [ -z "$topic" ]; then
#     echo "ERROR: Could not extract topic from plan path"
#     return 1
#   fi
#
extract_topic_from_plan_path() {
  local plan_path="${1:-}"

  # Validate input
  if [ -z "$plan_path" ]; then
    echo "ERROR: extract_topic_from_plan_path() requires plan path as argument" >&2
    return 1
  fi

  # Check if plan file exists
  if [ ! -f "$plan_path" ]; then
    echo "ERROR: Plan file does not exist: $plan_path" >&2
    return 1
  fi

  # Validate plan path format using regex
  # Expected: /path/to/specs/NNN_topic/plans/NNN_plan.md
  if ! echo "$plan_path" | grep -Eq '/specs/[0-9]{3}_[^/]+/plans/[0-9]{3}_[^.]+\.md$'; then
    echo "ERROR: Plan path does not match expected format" >&2
    echo "  Provided: $plan_path" >&2
    echo "  Expected: /path/to/specs/NNN_topic/plans/NNN_plan.md" >&2
    return 1
  fi

  # Extract topic directory using basename/dirname operations
  # Given: /home/benjamin/.config/.claude/specs/657_topic/plans/001_plan.md
  # Step 1: dirname → /home/benjamin/.config/.claude/specs/657_topic/plans
  # Step 2: dirname → /home/benjamin/.config/.claude/specs/657_topic
  # Step 3: basename → 657_topic
  local topic_parent
  topic_parent=$(dirname "$(dirname "$plan_path")")

  local topic_name
  topic_name=$(basename "$topic_parent")

  # Validate extracted topic name format (NNN_name)
  if ! echo "$topic_name" | grep -Eq '^[0-9]{3}_[^/]+$'; then
    echo "ERROR: Extracted topic name does not match expected format (NNN_name)" >&2
    echo "  Extracted: $topic_name" >&2
    return 1
  fi

  # Output topic name to stdout
  echo "$topic_name"
  return 0
}

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
  # STEP 1: Scope Detection (Silent - coordinate.md displays summary)
  # ============================================================================

  # Validate workflow scope (silent - only errors to stderr)
  case "$workflow_scope" in
    research-only|research-and-plan|research-and-revise|full-implementation|debug-only)
      # Valid scope - no output
      ;;
    *)
      echo "ERROR: Unknown workflow scope: $workflow_scope" >&2
      echo "Valid scopes: research-only, research-and-plan, research-and-revise, full-implementation, debug-only" >&2
      return 1
      ;;
  esac

  # ============================================================================
  # STEP 2: Path Pre-Calculation (Silent - coordinate.md displays summary)
  # ============================================================================

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
  # Note: Calculate topic_name first, then use get_or_create_topic_number for idempotency
  # This prevents topic number incrementing on each bash block invocation
  local topic_num
  local topic_name
  topic_name=$(sanitize_topic_name "$workflow_description")
  topic_num=$(get_or_create_topic_number "$specs_root" "$topic_name")

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
    echo "  get_or_create_topic_number() - from topic-utils.sh (idempotent)" >&2
    echo "  sanitize_topic_name() - from topic-utils.sh" >&2
    echo "" >&2
    return 1
  fi

  # Path calculation silent - coordinate.md will display summary

  # Calculate topic path
  local topic_path="${specs_root}/${topic_num}_${topic_name}"

  # ============================================================================
  # STEP 3: Directory Structure Creation (Silent - verification occurs, no output)
  # ============================================================================

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

  # Verification checkpoint silent - errors go to stderr

  # ============================================================================
  # Pre-calculate ALL artifact paths (exported to calling script)
  # ============================================================================

  # Research phase paths (pre-allocate maximum 4 paths for Phase 0 optimization)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Design Trade-off: Fixed capacity (4) vs. dynamic complexity (1-4)
  #   - Pre-allocate max paths upfront → 85% token reduction, 25x speedup
  #   - Actual usage determined by RESEARCH_COMPLEXITY in Phase 1 (see coordinate.md)
  #   - Unused paths remain exported but empty (minor memory overhead acceptable)
  #
  # Rationale: Phase 0 optimization pattern prioritizes performance over memory efficiency.
  # Separation of concerns: Path calculation (infrastructure) vs. complexity detection (orchestration).
  # See: phase-0-optimization.md (pattern guide), Spec 676 (architecture analysis)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  local -a report_paths
  for i in 1 2 3 4; do
    report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_topic${i}.md")
  done

  # Export individual report path variables for bash block persistence
  # Arrays cannot be exported across subprocess boundaries, so we export
  # individual REPORT_PATH_0, REPORT_PATH_1, etc. variables
  export REPORT_PATH_0="${report_paths[0]}"
  export REPORT_PATH_1="${report_paths[1]}"
  export REPORT_PATH_2="${report_paths[2]}"
  export REPORT_PATH_3="${report_paths[3]}"

  # Export fixed count (4) for subprocess persistence
  # Phase 1 orchestration uses RESEARCH_COMPLEXITY (1-4) for actual agent invocation control
  export REPORT_PATHS_COUNT=4

  # Define research subdirectory for overview synthesis
  local research_subdir="${topic_path}/reports"

  # Overview path will be calculated conditionally based on workflow scope
  # (see Phase 1: Research Overview section for actual path calculation)
  local overview_path=""  # Initialized empty, set conditionally during research phase

  # Planning phase paths
  local plan_path="${topic_path}/plans/001_${topic_name}_plan.md"

  # For research-and-revise workflows, use existing plan path from scope detection
  # This is different from creation workflows which generate new topic directories
  local existing_plan_path=""
  if [ "$workflow_scope" = "research-and-revise" ]; then
    # Validation Check 1: EXISTING_PLAN_PATH must be set by scope detection
    if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
      echo "ERROR: research-and-revise workflow requires existing plan path" >&2
      echo "  Workflow description: $workflow_description" >&2
      echo "  Expected: Path format like 'Revise the plan /path/to/specs/NNN_topic/plans/NNN_plan.md...'" >&2
      echo "" >&2
      echo "  Diagnostic:" >&2
      echo "    - Check workflow description contains full plan path" >&2
      echo "    - Verify scope detection exported EXISTING_PLAN_PATH" >&2
      return 1
    fi

    existing_plan_path="$EXISTING_PLAN_PATH"

    # Validation Check 2: Plan file must exist
    if [ ! -f "$existing_plan_path" ]; then
      echo "ERROR: Specified plan file does not exist" >&2
      echo "  Plan path: $existing_plan_path" >&2
      echo "" >&2
      echo "  Diagnostic:" >&2
      echo "    - Verify file path is correct: test -f \"$existing_plan_path\"" >&2
      echo "    - Check for typos in workflow description" >&2
      return 1
    fi

    # Extract topic directory from existing plan path
    local extracted_topic
    extracted_topic=$(extract_topic_from_plan_path "$existing_plan_path")

    if [ -z "$extracted_topic" ]; then
      echo "ERROR: Could not extract topic directory from plan path" >&2
      echo "  Plan path: $existing_plan_path" >&2
      echo "" >&2
      echo "  Diagnostic:" >&2
      echo "    - Check plan path format: /path/to/specs/NNN_topic/plans/NNN_plan.md" >&2
      echo "    - Verify path structure matches expected format" >&2
      return 1
    fi

    # Override topic_path and topic_name with extracted values (don't create new topic)
    topic_name="$extracted_topic"
    topic_path="${specs_root}/${topic_name}"

    # Extract topic number from topic name (format: NNN_name)
    topic_num=$(echo "$topic_name" | grep -oE '^[0-9]{3}')

    # Validation Check 3: Extracted topic directory must exist
    if [ ! -d "$topic_path" ]; then
      echo "ERROR: Extracted topic directory does not exist" >&2
      echo "  Topic directory: $topic_path" >&2
      echo "  Extracted from: $existing_plan_path" >&2
      echo "" >&2
      echo "  Diagnostic:" >&2
      echo "    - Verify topic directory exists: test -d \"$topic_path\"" >&2
      echo "    - Check specs directory structure" >&2
      return 1
    fi

    # Validation Check 4: Topic must have plans subdirectory
    if [ ! -d "$topic_path/plans" ]; then
      echo "ERROR: Topic directory missing plans/ subdirectory" >&2
      echo "  Topic path: $topic_path" >&2
      echo "  Expected: $topic_path/plans" >&2
      echo "" >&2
      echo "  Diagnostic:" >&2
      echo "    - Verify directory structure: ls -la \"$topic_path\"" >&2
      echo "    - Topic must follow specs/NNN_topic/plans/ structure" >&2
      return 1
    fi

    # Export for use in planning phase
    export EXISTING_PLAN_PATH="$existing_plan_path"
    append_workflow_state "EXISTING_PLAN_PATH" "$existing_plan_path"
  fi

  # Implementation phase paths
  local impl_artifacts="${topic_path}/artifacts/"

  # Debug phase paths
  local debug_report="${topic_path}/debug/001_debug_analysis.md"

  # Documentation phase paths
  local summary_path="${topic_path}/summaries/${topic_num}_${topic_name}_summary.md"

  # Artifact paths calculated silently - coordinate.md will display summary

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

  # Export tracking variables
  export SUCCESSFUL_REPORT_COUNT="$successful_report_count"
  export TESTS_PASSING="$tests_passing"
  export IMPLEMENTATION_OCCURRED="$implementation_occurred"

  # Silent completion - coordinate.md displays user-facing output

  return 0
}

# ==============================================================================
# Helper Functions
# ==============================================================================

# ==============================================================================
# Generic Defensive Array Reconstruction Pattern (Spec 672, Phase 1)
# ==============================================================================

# reconstruct_array_from_indexed_vars: Generic defensive array reconstruction
#
# Reconstructs a bash array from indexed variables exported to state persistence.
# Implements defensive pattern to prevent unbound variable errors (Spec 637 bug fix).
#
# Pattern Purpose:
#   State persistence exports arrays as indexed variables:
#     export ARRAY_NAME_0="value0"
#     export ARRAY_NAME_1="value1"
#     export ARRAY_NAME_COUNT=2
#
#   This function safely reconstructs the original array with defensive checks
#   for missing count variables and missing indexed variables.
#
# When to Use This Pattern:
#   - Array must persist across bash blocks (subprocess isolation)
#   - State may be partially loaded (some variables missing)
#   - Silent failures are unacceptable (need warnings for debugging)
#
# When NOT to Use:
#   - Array only used within single bash block (use local array)
#   - Array reconstruction can fail-fast instead of degrading (use strict checks)
#   - Performance-critical tight loop (adds 1-2ms overhead per array)
#
# Arguments:
#   $1 - array_name: Name of target array variable (e.g., "REPORT_PATHS")
#   $2 - count_var_name: Name of count variable (e.g., "REPORT_PATHS_COUNT")
#   $3 - var_prefix: Optional prefix for indexed variables (default: $array_name)
#                    Use when variable names differ from array name (e.g., "REPORT_PATH" for REPORT_PATHS array)
#
# Effects:
#   - Sets global array variable named $array_name
#   - Prints warnings to stderr for missing variables
#
# Returns:
#   0 always (defensive graceful degradation)
#
# Example:
#   # State contains: REPORT_PATH_0, REPORT_PATH_1, REPORT_PATHS_COUNT=2
#   reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"
#   # Result: REPORT_PATHS=("value0" "value1")
#
# Reference: Spec 637 (unbound variable bug), Spec 672 Phase 1 (defensive patterns)
#
reconstruct_array_from_indexed_vars() {
  local array_name="${1:-}"
  local count_var_name="${2:-}"
  local var_prefix="${3:-$array_name}"  # Default to array_name if not specified

  # Validate arguments
  if [ -z "$array_name" ] || [ -z "$count_var_name" ]; then
    echo "ERROR: reconstruct_array_from_indexed_vars() requires array_name and count_var_name" >&2
    return 1
  fi

  # Initialize empty array (using eval to properly initialize global array)
  eval "${array_name}=()"

  # Defensive check: Ensure count variable is set
  # ${!count_var_name+x} returns "x" if variable exists, empty if undefined
  if [ -z "${!count_var_name+x}" ]; then
    echo "WARNING: $count_var_name not set, defaulting to 0 (array reconstruction skipped)" >&2
    return 0  # Graceful degradation: empty array
  fi

  # Safe to use indirect expansion now
  local count="${!count_var_name}"

  # Validate count is numeric
  if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    echo "WARNING: $count_var_name is not numeric (value: '$count'), defaulting to 0" >&2
    return 0
  fi

  # Reconstruct array from indexed variables
  for i in $(seq 0 $((count - 1))); do
    local var_name="${var_prefix}_${i}"

    # Defensive check: Verify indexed variable exists before accessing
    # This prevents "unbound variable" errors when state partially loaded
    if [ -z "${!var_name+x}" ]; then
      echo "WARNING: $var_name not set, skipping index $i" >&2
      continue
    fi

    # Safe to use indirect expansion - append to array
    local value="${!var_name}"
    eval "${array_name}+=(\"\$value\")"
  done
}

# reconstruct_report_paths_array: Reconstruct REPORT_PATHS array from exported variables
#
# Primary: Reads REPORT_PATH_N variables from state using generic defensive pattern
# Fallback: Filesystem discovery via glob pattern (verification fallback per Spec 057)
#
# Usage:
#   reconstruct_report_paths_array
#   # Populates global REPORT_PATHS array
#
# Implementation Note (Spec 672 Phase 1):
#   Refactored to use generic reconstruct_array_from_indexed_vars() function
#   for defensive array reconstruction. Preserves existing filesystem fallback
#   behavior as verification fallback (Spec 057 pattern).
#
reconstruct_report_paths_array() {
  # Use generic defensive reconstruction pattern (Spec 672 Phase 1)
  # Note: var_prefix is "REPORT_PATH" (singular) because state variables are REPORT_PATH_0, REPORT_PATH_1, etc.
  reconstruct_array_from_indexed_vars "REPORT_PATHS" "REPORT_PATHS_COUNT" "REPORT_PATH"

  # Verification Fallback: If reconstruction failed and TOPIC_PATH exists, use filesystem discovery
  # This is a verification fallback (per Spec 057): detects state persistence failures
  # immediately rather than hiding them, enables workflow to continue with discovered paths
  if [ ${#REPORT_PATHS[@]} -eq 0 ] && [ -n "${TOPIC_PATH:-}" ]; then
    local reports_dir="${TOPIC_PATH}/reports"

    if [ -d "$reports_dir" ]; then
      echo "Warning: State reconstruction failed ($REPORT_PATHS_COUNT expected, 0 found), using filesystem discovery fallback (verification fallback per Spec 057)" >&2

      # Discover report files via glob pattern, preserving numeric sorting
      for report_file in "$reports_dir"/[0-9][0-9][0-9]_*.md; do
        if [ -f "$report_file" ]; then
          REPORT_PATHS+=("$report_file")
        fi
      done

      echo "Fallback discovery found ${#REPORT_PATHS[@]} reports in $reports_dir" >&2
    fi
  fi
}
