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
#   source .claude/lib/workflow/workflow-initialization.sh
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
if [ -f "$SCRIPT_DIR/../plan/topic-utils.sh" ]; then
  source "$SCRIPT_DIR/../plan/topic-utils.sh"
else
  echo "ERROR: topic-utils.sh not found" >&2
  echo "Expected location: $SCRIPT_DIR/../plan/topic-utils.sh" >&2
  exit 1
fi

if [ -f "$SCRIPT_DIR/../core/detect-project-dir.sh" ]; then
  source "$SCRIPT_DIR/../core/detect-project-dir.sh"
else
  echo "ERROR: detect-project-dir.sh not found" >&2
  echo "Expected location: $SCRIPT_DIR/../core/detect-project-dir.sh" >&2
  exit 1
fi

# Source unified-location-detection.sh for atomic allocate_and_create_topic() function
# This function provides atomic topic number allocation AND directory creation under
# exclusive file lock, eliminating race conditions in concurrent workflows.
# See unified-location-detection.sh:247-305 for implementation details.
if [ -f "$SCRIPT_DIR/../core/unified-location-detection.sh" ]; then
  source "$SCRIPT_DIR/../core/unified-location-detection.sh"
else
  echo "ERROR: unified-location-detection.sh not found" >&2
  echo "Expected location: $SCRIPT_DIR/../core/unified-location-detection.sh" >&2
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
# Helper Function: validate_and_generate_filename_slugs
# ==============================================================================

# validate_and_generate_filename_slugs: Three-tier validation for filename slug generation
#
# Implements hybrid filename generation (Strategy 3 from Spec 688 Report 002):
# Tier 1: Use LLM-generated slug if valid (preferred)
# Tier 2: Sanitize short_name if LLM slug invalid (fallback)
# Tier 3: Use generic topicN if short_name empty (ultimate fallback)
#
# Arguments:
#   $1 - classification_result: JSON classification result containing research_topics array
#   $2 - research_complexity: Expected number of topics (1-4)
#
# Output:
#   Prints bash array declaration: slugs=("slug1" "slug2" ...)
#   Can be eval'd by caller: eval "$(validate_and_generate_filename_slugs "$json" 2)"
#
# Returns:
#   0 on success, 1 on error
#
# Side effects:
#   Logs slug generation strategy to unified-logger.sh (if available)
#
validate_and_generate_filename_slugs() {
  local classification_result="$1"
  local research_complexity="$2"

  # Validate inputs
  if [ -z "$classification_result" ]; then
    echo "ERROR: validate_and_generate_filename_slugs: classification_result required" >&2
    return 1
  fi

  if [ -z "$research_complexity" ]; then
    echo "ERROR: validate_and_generate_filename_slugs: research_complexity required" >&2
    return 1
  fi

  # Extract research_topics array from classification result
  local research_topics
  research_topics=$(echo "$classification_result" | jq -c '.research_topics // []')

  if [ "$research_topics" = "[]" ] || [ -z "$research_topics" ] || [ "$research_topics" = "null" ]; then
    # WARNING only (not error): Fallback behavior works correctly
    # LLM classification agent sometimes returns valid topic_directory_slug with empty research_topics
    # This is handled gracefully by generating sequential fallback slugs - no error logging needed
    echo "WARNING: research_topics empty - generating fallback slugs" >&2

    # Generate fallback topics based on complexity
    local -a fallback_slugs=()
    for ((i=1; i<=research_complexity; i++)); do
      fallback_slugs+=("topic${i}")
    done

    # Output bash array declaration for eval by caller (matches line 266 format)
    local slugs_str
    slugs_str=$(printf '"%s" ' "${fallback_slugs[@]}")
    echo "slugs=($slugs_str)"
    return 0
  fi

  # Validate count matches complexity
  local topics_count
  topics_count=$(echo "$research_topics" | jq 'length')

  if [ "$topics_count" -ne "$research_complexity" ]; then
    # Log mismatch warning (continue with available topics + fallbacks)
    if declare -f log_command_error >/dev/null 2>&1; then
      log_command_error \
        "${COMMAND_NAME:-/unknown}" \
        "${WORKFLOW_ID:-unknown}" \
        "${USER_ARGS:-}" \
        "validation_error" \
        "research_topics count mismatch: expected $research_complexity, got $topics_count - adjusting" \
        "validate_and_generate_filename_slugs" \
        "$(jq -n --argjson expected "$research_complexity" --argjson actual "$topics_count" \
           '{expected_count: $expected, actual_count: $actual, action: "adjusting_count"}')"
    fi
    echo "WARNING: topics count ($topics_count) != complexity ($research_complexity) - adjusting" >&2
    # Continue processing with available topics (don't fail)
  fi

  # Generate validated slugs (three-tier fallback)
  local -a validated_slugs
  local slug_regex='^[a-z0-9_]{1,50}$'

  for ((i=0; i<research_complexity; i++)); do
    local filename_slug short_name final_slug strategy

    # Extract fields from topic
    filename_slug=$(echo "$research_topics" | jq -r ".[$i].filename_slug // empty")
    short_name=$(echo "$research_topics" | jq -r ".[$i].short_name // empty")

    # Tier 1: Validate LLM-generated slug
    if [ -n "$filename_slug" ] && echo "$filename_slug" | grep -Eq "$slug_regex"; then
      # Check for path separator injection and 255-byte filename limit
      if echo "$filename_slug" | grep -q '/'; then
        # Path separator found - reject and fall back
        strategy="sanitize"
        # Basic sanitization for short_name
        final_slug=$(echo "$short_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g' | sed 's/__*/_/g' | sed 's/^_*//;s/_*$//' | cut -c1-50)
      elif [ ${#filename_slug} -gt 255 ]; then
        # Exceeds filesystem limit - truncate
        strategy="truncate"
        final_slug="${filename_slug:0:255}"
      else
        # Valid LLM slug - use it
        strategy="llm"
        final_slug="$filename_slug"
      fi
    # Tier 2: Sanitize short_name fallback
    elif [ -n "$short_name" ]; then
      strategy="sanitize"
      # Basic sanitization for short_name
      final_slug=$(echo "$short_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g' | sed 's/__*/_/g' | sed 's/^_*//;s/_*$//' | cut -c1-50)
    # Tier 3: Generic fallback
    else
      strategy="generic"
      final_slug="topic$((i+1))"
    fi

    validated_slugs+=("$final_slug")

    # Log slug generation strategy (if unified-logger available)
    if declare -f log_slug_generation >/dev/null 2>&1; then
      log_slug_generation "INFO" "$i" "$strategy" "$final_slug"
    fi
  done

  # Output bash array declaration for eval by caller
  local slugs_str
  slugs_str=$(printf '"%s" ' "${validated_slugs[@]}")
  echo "slugs=($slugs_str)"

  return 0
}

# ==============================================================================
# Helper Function: validate_topic_directory_slug
# ==============================================================================

# validate_topic_directory_slug: Two-tier validation for topic directory slug generation
#
# Implements hybrid topic slug generation:
# Tier 1: Use LLM-generated topic_directory_slug if valid (preferred)
# Tier 2: Use basic sanitization as fallback
#
# Arguments:
#   $1 - classification_result: JSON classification result containing topic_directory_slug field
#   $2 - workflow_description: Original workflow description (for fallbacks)
#
# Output:
#   Validated topic_directory_slug string on stdout
#
# Returns:
#   0 on success, 1 on error
#
# Side effects:
#   Logs slug generation strategy (if log function available)
#
validate_topic_directory_slug() {
  local classification_result="${1:-}"
  local workflow_description="${2:-}"

  local topic_slug=""
  local strategy="sanitize"  # Default strategy

  # Slug validation regex: lowercase letters, numbers, underscores only, 1-40 chars
  local slug_regex='^[a-z0-9_]{1,40}$'

  # Tier 1: Try to extract and validate LLM-generated slug
  if [ -n "$classification_result" ]; then
    # Extract topic_directory_slug from JSON
    topic_slug=$(echo "$classification_result" | jq -r '.topic_directory_slug // empty' 2>/dev/null)

    if [ -n "$topic_slug" ]; then
      # Security check: Reject if contains path separators
      if echo "$topic_slug" | grep -q '/'; then
        echo "WARNING: topic_directory_slug contains path separator, rejecting (security check)" >&2
        topic_slug=""
      # Validate format
      elif echo "$topic_slug" | grep -Eq "$slug_regex"; then
        strategy="llm"
        # Valid LLM slug - use it
      else
        echo "WARNING: topic_directory_slug '$topic_slug' invalid format, falling back" >&2
        topic_slug=""
      fi
    fi
  fi

  # Tier 2: Static fallback (no sanitization - use clear failure signal)
  if [ -z "$topic_slug" ]; then
    # Use static fallback that clearly signals LLM naming failure
    topic_slug="no_name_error"
    strategy="fallback"
  fi

  # Log slug generation strategy (if unified-logger available)
  if declare -f log_topic_slug_generation >/dev/null 2>&1; then
    log_topic_slug_generation "INFO" "$strategy" "$topic_slug"
  fi

  # Output the validated slug
  echo "$topic_slug"
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
#   $3 - RESEARCH_COMPLEXITY: Number of research subtopics (1-4, default: 2) - NEW in Spec 678
#   $4 - CLASSIFICATION_RESULT: JSON classification result with research_topics array (optional, for filename slugs) - NEW in Spec 688
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
  local research_complexity="${3:-2}"  # NEW: Accept RESEARCH_COMPLEXITY as third argument (default: 2)
  local classification_result="${4:-}"  # NEW in Spec 688: JSON classification result for filename slugs (optional)

  # Validate inputs
  if [ -z "$workflow_description" ]; then
    echo "ERROR: initialize_workflow_paths() requires WORKFLOW_DESCRIPTION as first argument" >&2
    return 1
  fi

  if [ -z "$workflow_scope" ]; then
    echo "ERROR: initialize_workflow_paths() requires WORKFLOW_SCOPE as second argument" >&2
    return 1
  fi

  # Validate RESEARCH_COMPLEXITY range (1-4)
  if ! echo "$research_complexity" | grep -Eq '^[1-4]$'; then
    echo "ERROR: RESEARCH_COMPLEXITY must be 1-4, got: $research_complexity" >&2
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
  # CRITICAL: Check CLAUDE_SPECS_ROOT override first (for test isolation)
  # This allows tests to redirect spec creation to temporary directories
  local specs_root
  if [ -n "${CLAUDE_SPECS_ROOT:-}" ] && [ -d "${CLAUDE_SPECS_ROOT}" ]; then
    specs_root="${CLAUDE_SPECS_ROOT}"
    # Warn if override seems like a test but CLAUDE_PROJECT_DIR points to real project
    if [[ "$CLAUDE_SPECS_ROOT" == /tmp/* ]] && [[ "${CLAUDE_PROJECT_DIR:-}" != /tmp/* ]]; then
      echo "WARNING: CLAUDE_SPECS_ROOT is temporary but CLAUDE_PROJECT_DIR is not. This may cause isolation issues." >&2
    fi
  elif [ -d "${project_root}/.claude/specs" ]; then
    specs_root="${project_root}/.claude/specs"
  elif [ -d "${project_root}/specs" ]; then
    specs_root="${project_root}/specs"
  else
    # Default to .claude/specs and create it
    specs_root="${project_root}/.claude/specs"
    mkdir -p "$specs_root"
  fi

  # Calculate topic metadata
  # Uses atomic allocate_and_create_topic() for concurrent safety, eliminating race conditions
  # that caused duplicate topic numbers (see Spec 933 for details)
  local topic_num
  local topic_name
  local topic_path

  # Use LLM-generated topic_directory_slug if classification_result provided (Spec 771)
  # Otherwise fall back to basic sanitization for backward compatibility
  if [ -n "$classification_result" ]; then
    # Use two-tier validation: LLM slug -> sanitize
    topic_name=$(validate_topic_directory_slug "$classification_result" "$workflow_description")
  else
    # No classification result - use basic sanitization (backward compatible)
    topic_name=$(echo "$workflow_description" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | sed 's/[^a-z0-9_]//g' | sed 's/__*/_/g' | sed 's/^_*//;s/_*$//' | cut -c1-50)
  fi

  # Validate topic_name is set
  if [ -z "$topic_name" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "DIAGNOSTIC INFO: Topic Name Calculation Failed" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "ERROR: Failed to calculate topic name" >&2
    echo "" >&2
    echo "Source Values:" >&2
    echo "  WORKFLOW_DESCRIPTION: '${workflow_description:-<empty>}'" >&2
    echo "  CLASSIFICATION_RESULT: '${classification_result:+<provided>}'" >&2
    echo "" >&2
    return 1
  fi

  # Calculate topic path - conditional based on workflow scope
  if [ "${workflow_scope:-}" = "research-and-revise" ]; then
    # research-and-revise: Reuse existing plan's topic directory (NO atomic allocation needed)
    if [ -z "${EXISTING_PLAN_PATH:-}" ]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "CRITICAL ERROR: research-and-revise requires EXISTING_PLAN_PATH" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "" >&2
      echo "Workflow scope: research-and-revise" >&2
      echo "EXISTING_PLAN_PATH: ${EXISTING_PLAN_PATH:-<not set>}" >&2
      echo "" >&2
      echo "Root cause: EXISTING_PLAN_PATH must be set in environment before calling initialize_workflow_paths()" >&2
      echo "Solution: Set EXISTING_PLAN_PATH to the path of the plan being revised" >&2
      echo "" >&2
      return 1
    fi

    # Extract topic directory from plan path
    # Pattern: /path/to/specs/NNN_topic_name/plans/001_plan.md -> /path/to/specs/NNN_topic_name
    topic_path=$(dirname $(dirname "$EXISTING_PLAN_PATH"))

    # Validate it exists (defensive check)
    if [ ! -d "$topic_path" ]; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "CRITICAL ERROR: Existing topic directory not found" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "" >&2
      echo "Extracted path: $topic_path" >&2
      echo "EXISTING_PLAN_PATH: $EXISTING_PLAN_PATH" >&2
      echo "" >&2
      echo "Root cause: Extracted topic directory does not exist on filesystem" >&2
      echo "Solution: Verify EXISTING_PLAN_PATH points to a valid plan file" >&2
      echo "" >&2
      return 1
    fi

    # Extract topic number and name from existing directory
    topic_num=$(basename "$topic_path" | grep -oE '^[0-9]+')
    topic_name=$(basename "$topic_path" | sed 's/^[0-9]\+_//')

    echo "Using existing topic directory: $topic_path (research-and-revise mode)" >&2
  else
    # ============================================================================
    # All other workflow scopes: ATOMIC topic allocation AND directory creation
    # Uses allocate_and_create_topic() for concurrent safety under file lock
    # This eliminates race conditions that caused duplicate topic numbers (Spec 933)
    # ============================================================================

    # Check if topic directory already exists (idempotent behavior)
    local existing_topic
    existing_topic=$(ls -1d "${specs_root}"/[0-9][0-9][0-9]_"${topic_name}" 2>/dev/null | head -1 || echo "")

    if [ -n "$existing_topic" ]; then
      # Existing topic found - reuse it (idempotent behavior preserved)
      topic_path="$existing_topic"
      topic_num=$(basename "$topic_path" | grep -oE '^[0-9]+')
    else
      # No existing topic - use ATOMIC allocation to prevent race conditions
      # allocate_and_create_topic() holds exclusive file lock through BOTH
      # number calculation AND directory creation, preventing collisions
      local allocation_result
      allocation_result=$(allocate_and_create_topic "$specs_root" "$topic_name")

      if [ -z "$allocation_result" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "CRITICAL ERROR: Atomic topic allocation failed" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "" >&2
        echo "SPECS_ROOT: $specs_root" >&2
        echo "TOPIC_NAME: $topic_name" >&2
        echo "" >&2
        echo "This indicates a failure in allocate_and_create_topic() from unified-location-detection.sh" >&2
        echo "" >&2
        return 1
      fi

      # Parse pipe-delimited result: "topic_number|topic_path"
      topic_num="${allocation_result%|*}"
      topic_path="${allocation_result#*|}"
    fi
  fi

  # Validate required fields
  if [ -z "$project_root" ] || [ -z "$topic_num" ] || [ -z "$topic_name" ] || [ -z "$topic_path" ]; then
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
    echo "  TOPIC_PATH: '${topic_path:-<empty>}'" >&2
    echo "" >&2
    echo "Source Values:" >&2
    echo "  SPECS_ROOT: '${specs_root:-<empty>}'" >&2
    echo "  WORKFLOW_DESCRIPTION: '${workflow_description:-<empty>}'" >&2
    echo "" >&2
    echo "Functions Used:" >&2
    echo "  allocate_and_create_topic() - from unified-location-detection.sh (atomic)" >&2
    echo "  validate_topic_directory_slug() - from workflow-initialization.sh" >&2
    echo "" >&2
    return 1
  fi

  # ============================================================================
  # STEP 3: Directory Structure Verification
  # ============================================================================
  # Note: Directory creation is now handled atomically by allocate_and_create_topic()
  # for new topics, or directory already exists for research-and-revise and idempotent cases

  # Verify topic directory exists (already created by atomic allocation or exists for idempotent case)
  if [ ! -d "$topic_path" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "CRITICAL ERROR: Topic directory does not exist after allocation" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Topic path: $topic_path" >&2
    echo "" >&2
    echo "This should never happen - allocate_and_create_topic() creates the directory atomically" >&2
    echo "" >&2
    return 1
  fi

  # Directory verification passed - no separate create_topic_structure() call needed
  # (directory created atomically by allocate_and_create_topic() or already existed)

  # ============================================================================
  # Pre-calculate ALL artifact paths (exported to calling script)
  # ============================================================================

  # Research phase paths (dynamically allocate based on RESEARCH_COMPLEXITY)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Design Enhancement: Just-in-time dynamic allocation with filename slugs (Spec 678, 688)
  #   - Allocate EXACTLY $research_complexity paths (1-4)
  #   - Use LLM-generated filename slugs (validated) for semantic filenames
  #   - Three-tier fallback: LLM slug → sanitized short_name → generic topicN
  #   - Eliminates pre-allocation tension and post-research filename discovery
  #   - Maintains Phase 0 optimization (85% token reduction, 25x speedup)
  #
  # Rationale: Complexity and filename slugs determined in sm_init (before path
  # allocation), enabling just-in-time allocation with semantic filenames.
  # See: Spec 678 Phase 4 (dynamic allocation), Spec 688 Phase 2 (slug validation)
  # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  local -a report_paths
  local -a validated_slugs

  # Generate validated filename slugs if classification_result provided
  if [ -n "$classification_result" ]; then
    # Extract and validate filename slugs using three-tier fallback
    # NOTE: Only capture stdout for eval - stderr warnings pass through without eval
    local slugs_declaration
    if slugs_declaration=$(validate_and_generate_filename_slugs "$classification_result" "$research_complexity"); then
      # eval the array declaration: slugs=("slug1" "slug2" ...)
      eval "$slugs_declaration"
      validated_slugs=("${slugs[@]}")
    else
      # Validation failed - log warning and fall back to generic filenames
      echo "WARNING: Filename slug validation failed, using generic filenames" >&2
      echo "  Error: $slugs_declaration" >&2
      # Generate generic fallback slugs
      for i in $(seq 1 "$research_complexity"); do
        validated_slugs+=("topic${i}")
      done
    fi
  else
    # No classification result provided - use generic filenames (backwards compatibility)
    for i in $(seq 1 "$research_complexity"); do
      validated_slugs+=("topic${i}")
    done
  fi

  # Allocate report paths using validated slugs
  for i in $(seq 1 "$research_complexity"); do
    local slug_index=$((i - 1))  # slugs array is 0-indexed
    local slug="${validated_slugs[$slug_index]}"
    report_paths+=("${topic_path}/reports/$(printf '%03d' $i)_${slug}.md")
  done

  # Export individual report path variables for bash block persistence
  # Arrays cannot be exported across subprocess boundaries, so we export
  # individual REPORT_PATH_0, REPORT_PATH_1, etc. variables
  # NOTE: Zero-indexed (REPORT_PATH_0, REPORT_PATH_1, ...), count is $research_complexity
  for i in $(seq 0 $((research_complexity - 1))); do
    export "REPORT_PATH_$i=${report_paths[$i]}"
  done

  # Export exact count matching RESEARCH_COMPLEXITY (no unused variables)
  export REPORT_PATHS_COUNT="$research_complexity"

  # Define research subdirectory for overview synthesis
  local research_subdir="${topic_path}/reports"

  # Overview path will be calculated conditionally based on workflow scope
  # (see Phase 1: Research Overview section for actual path calculation)
  local overview_path=""  # Initialized empty, set conditionally during research phase

  # Planning phase paths (kebab-case for filenames)
  local plan_slug=$(echo "$topic_name" | tr '_' '-')
  local plan_path="${topic_path}/plans/001-${plan_slug}-plan.md"

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

  # Use nameref pattern to avoid indirect expansion (bash 4.3+ pattern)
  local -n count_ref="$count_var_name"
  local count="$count_ref"

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
