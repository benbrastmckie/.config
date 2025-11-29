#!/usr/bin/env bash
# todo-functions.sh
#
# Library functions for /todo command project scanning and TODO.md generation
# Provides project discovery, plan status extraction, and artifact collection
#
# Commands using this library: /todo
# Dependencies:
#   - unified-location-detection.sh (for specs root detection)
#   - error-handling.sh (for error logging)
#
# Usage:
#   source /path/to/todo-functions.sh
#   TOPICS=$(scan_project_directories)
#   STATUS=$(categorize_plan "completed")

set -eo pipefail

# Library version for compatibility checking
TODO_FUNCTIONS_VERSION="1.0.0"

# ============================================================================
# SECTION 1: Library Initialization
# ============================================================================

# Initialize library by detecting project directory and sourcing dependencies
_init_todo_functions() {
  # Detect project directory if not already set
  if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
    if command -v git &>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
      CLAUDE_PROJECT_DIR="$(git rev-parse --show-toplevel)"
    else
      local current_dir="$(pwd)"
      while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/.claude" ]; then
          CLAUDE_PROJECT_DIR="$current_dir"
          break
        fi
        current_dir="$(dirname "$current_dir")"
      done
    fi
  fi

  # Export for child processes
  export CLAUDE_PROJECT_DIR

  # Source unified-location-detection for specs root detection
  local lib_path="${CLAUDE_PROJECT_DIR}/.claude/lib"
  if [ -f "${lib_path}/core/unified-location-detection.sh" ]; then
    source "${lib_path}/core/unified-location-detection.sh" 2>/dev/null || true
  fi
}

# Initialize on source
_init_todo_functions

# ============================================================================
# SECTION 2: Project Discovery Functions
# ============================================================================

# scan_project_directories()
# Purpose: Discover all topic directories in specs/
# Returns: Newline-separated list of topic directory names (e.g., "959_todo_command")
# Usage:
#   TOPICS=$(scan_project_directories)
#   while IFS= read -r topic; do
#     echo "Processing: $topic"
#   done <<< "$TOPICS"
#
scan_project_directories() {
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"

  if [ ! -d "$specs_root" ]; then
    echo "" # Return empty if no specs directory
    return 0
  fi

  # List all directories in specs/, filter to numbered topic directories
  # Pattern: NNN_topic_name (3-digit number prefix)
  find "$specs_root" -maxdepth 1 -mindepth 1 -type d -name "[0-9][0-9][0-9]_*" 2>/dev/null | \
    while read -r dir; do
      basename "$dir"
    done | sort -t'_' -k1 -n
}

# find_plans_in_topic()
# Purpose: Find all plan files within a topic's plans/ directory
# Arguments:
#   $1 - Topic name (e.g., "959_todo_command")
# Returns: Newline-separated list of absolute plan file paths
# Usage:
#   PLANS=$(find_plans_in_topic "959_todo_command")
#
find_plans_in_topic() {
  local topic_name="$1"
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
  local topic_path="${specs_root}/${topic_name}"
  local plans_dir="${topic_path}/plans"

  if [ ! -d "$plans_dir" ]; then
    echo "" # Return empty if no plans directory
    return 0
  fi

  # Find all markdown files in plans/ directory
  find "$plans_dir" -maxdepth 1 -type f -name "*.md" 2>/dev/null | sort
}

# find_related_artifacts()
# Purpose: Find reports and summaries related to a topic
# Arguments:
#   $1 - Topic name (e.g., "959_todo_command")
# Returns: JSON array with reports and summaries arrays
# Usage:
#   ARTIFACTS_JSON=$(find_related_artifacts "959_todo_command")
#   REPORTS=$(echo "$ARTIFACTS_JSON" | jq -r '.reports[]')
#
find_related_artifacts() {
  local topic_name="$1"
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
  local topic_path="${specs_root}/${topic_name}"

  local reports_dir="${topic_path}/reports"
  local summaries_dir="${topic_path}/summaries"

  local reports_json="[]"
  local summaries_json="[]"

  # Find reports
  if [ -d "$reports_dir" ]; then
    local reports_list=""
    while IFS= read -r report; do
      [ -n "$report" ] && reports_list="${reports_list}\"${report}\","
    done < <(find "$reports_dir" -maxdepth 1 -type f -name "*.md" 2>/dev/null | sort)
    # Remove trailing comma and wrap in array
    reports_list="${reports_list%,}"
    [ -n "$reports_list" ] && reports_json="[${reports_list}]"
  fi

  # Find summaries
  if [ -d "$summaries_dir" ]; then
    local summaries_list=""
    while IFS= read -r summary; do
      [ -n "$summary" ] && summaries_list="${summaries_list}\"${summary}\","
    done < <(find "$summaries_dir" -maxdepth 1 -type f -name "*.md" 2>/dev/null | sort)
    # Remove trailing comma and wrap in array
    summaries_list="${summaries_list%,}"
    [ -n "$summaries_list" ] && summaries_json="[${summaries_list}]"
  fi

  # Return JSON object
  echo "{\"reports\": ${reports_json}, \"summaries\": ${summaries_json}}"
}

# ============================================================================
# SECTION 3: Plan Status Functions
# ============================================================================

# extract_plan_metadata()
# Purpose: Extract title, description, and status from plan file
# Arguments:
#   $1 - Absolute path to plan file
# Returns: JSON object with title, description, status, phases_complete, phases_total
# Usage:
#   METADATA=$(extract_plan_metadata "/path/to/plan.md")
#   TITLE=$(echo "$METADATA" | jq -r '.title')
#
extract_plan_metadata() {
  local plan_path="$1"

  if [ ! -f "$plan_path" ]; then
    echo '{"error": "file_not_found", "title": "", "description": "", "status": "", "phases_complete": 0, "phases_total": 0}'
    return 1
  fi

  local title=""
  local description=""
  local status=""
  local phases_complete=0
  local phases_total=0

  # Read file content
  local content
  content=$(cat "$plan_path" 2>/dev/null)

  # Extract title (first # header or **Feature** field)
  title=$(echo "$content" | grep -m1 "^# " | sed 's/^# //' | head -1)
  if [ -z "$title" ]; then
    title=$(echo "$content" | grep -m1 "\*\*Feature\*\*:" | sed 's/.*\*\*Feature\*\*:\s*//' | head -1)
  fi

  # Extract status from metadata
  status=$(echo "$content" | grep -m1 "\*\*Status\*\*:" | sed 's/.*\*\*Status\*\*:\s*//' | head -1)
  if [ -z "$status" ]; then
    status=$(echo "$content" | grep -m1 "^Status:" | sed 's/^Status:\s*//' | head -1)
  fi

  # Extract description (Scope field or first paragraph after Overview)
  description=$(echo "$content" | grep -m1 "\*\*Scope\*\*:" | sed 's/.*\*\*Scope\*\*:\s*//' | head -1)
  if [ -z "$description" ]; then
    # Fallback: extract from Overview section (first non-empty line after ## Overview)
    description=$(echo "$content" | sed -n '/^## Overview/,/^##/p' | grep -v "^##" | grep -v "^$" | head -1 | cut -c1-100)
  fi

  # Count phase headers and completion markers
  phases_total=$(echo "$content" | grep -c "^### Phase [0-9]" 2>/dev/null || echo "0")
  phases_complete=$(echo "$content" | grep -c "^### Phase [0-9].*\[COMPLETE\]" 2>/dev/null || echo "0")

  # Ensure numeric values (strip any trailing newlines)
  phases_total="${phases_total%%[^0-9]*}"
  phases_complete="${phases_complete%%[^0-9]*}"
  [ -z "$phases_total" ] && phases_total=0
  [ -z "$phases_complete" ] && phases_complete=0

  # Escape special characters for JSON
  title=$(echo "$title" | sed 's/"/\\"/g' | head -c 200 | tr -d '\n')
  description=$(echo "$description" | sed 's/"/\\"/g' | head -c 100 | tr -d '\n')
  status=$(echo "$status" | sed 's/"/\\"/g' | tr -d '\n')

  # Return JSON (use printf for cleaner output)
  printf '{"title": "%s", "description": "%s", "status": "%s", "phases_complete": %d, "phases_total": %d}\n' \
    "$title" "$description" "$status" "$phases_complete" "$phases_total"
}

# categorize_plan()
# Purpose: Map plan status to TODO.md section
# Arguments:
#   $1 - Status string (completed, in_progress, not_started, superseded, abandoned, backlog)
# Returns: Section name (In Progress, Not Started, Completed, etc.)
# Usage:
#   SECTION=$(categorize_plan "completed")
#   # Returns: "Completed"
#
categorize_plan() {
  local status="$1"

  case "$status" in
    completed|complete)
      echo "Completed"
      ;;
    in_progress|in-progress)
      echo "In Progress"
      ;;
    not_started|not-started|"")
      echo "Not Started"
      ;;
    superseded|deferred)
      echo "Superseded"
      ;;
    abandoned)
      echo "Abandoned"
      ;;
    backlog)
      echo "Backlog"
      ;;
    *)
      # Default to Not Started for unknown statuses
      echo "Not Started"
      ;;
  esac
}

# classify_status_from_metadata()
# Purpose: Apply status classification algorithm from plan metadata
# Arguments:
#   $1 - Status field value (may include [COMPLETE], [IN PROGRESS], etc.)
#   $2 - Phases complete count
#   $3 - Total phases count
# Returns: Normalized status (completed, in_progress, not_started, etc.)
# Usage:
#   STATUS=$(classify_status_from_metadata "[IN PROGRESS]" 3 8)
#   # Returns: "in_progress"
#
classify_status_from_metadata() {
  local status_field="$1"
  local phases_complete="${2:-0}"
  local phases_total="${3:-0}"

  # Normalize status field for comparison
  local status_lower
  status_lower=$(echo "$status_field" | tr '[:upper:]' '[:lower:]')

  # Apply classification algorithm
  if [[ "$status_lower" =~ \[complete\]|complete|100% ]]; then
    echo "completed"
  elif [[ "$status_lower" =~ \[in\ progress\]|in_progress|in-progress ]]; then
    echo "in_progress"
  elif [[ "$status_lower" =~ \[not\ started\]|not_started ]]; then
    echo "not_started"
  elif [[ "$status_lower" =~ superseded|deferred ]]; then
    echo "superseded"
  elif [[ "$status_lower" =~ abandoned ]]; then
    echo "abandoned"
  else
    # Fallback: use phase markers
    if [ "$phases_total" -gt 0 ]; then
      if [ "$phases_complete" -eq "$phases_total" ]; then
        echo "completed"
      elif [ "$phases_complete" -gt 0 ]; then
        echo "in_progress"
      else
        echo "not_started"
      fi
    else
      echo "not_started"
    fi
  fi
}

# ============================================================================
# SECTION 4: Checkbox Utilities
# ============================================================================

# get_checkbox_for_section()
# Purpose: Return appropriate checkbox marker for TODO.md section
# Arguments:
#   $1 - Section name (In Progress, Not Started, Completed, etc.)
# Returns: Checkbox string ([ ], [x], [~])
# Usage:
#   CHECKBOX=$(get_checkbox_for_section "Completed")
#   # Returns: "[x]"
#
get_checkbox_for_section() {
  local section="$1"

  case "$section" in
    "Not Started")
      echo "[ ]"
      ;;
    "In Progress"|"Completed"|"Abandoned")
      echo "[x]"
      ;;
    "Superseded")
      echo "[~]"
      ;;
    "Backlog")
      echo "[ ]"  # Backlog can use either, defaulting to unchecked
      ;;
    *)
      echo "[ ]"
      ;;
  esac
}

# ============================================================================
# SECTION 5: Path Utilities
# ============================================================================

# get_relative_path()
# Purpose: Convert absolute path to relative path from TODO.md location
# Arguments:
#   $1 - Absolute path to file
# Returns: Relative path from .claude/ directory
# Usage:
#   REL_PATH=$(get_relative_path "/home/user/.config/.claude/specs/959/plans/001.md")
#   # Returns: ".claude/specs/959/plans/001.md"
#
get_relative_path() {
  local abs_path="$1"
  local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

  # Remove project root prefix to get relative path
  local rel_path="${abs_path#$project_root/}"

  # Ensure path starts with .claude/ if within project
  if [[ ! "$rel_path" =~ ^\.claude/ ]] && [[ "$abs_path" =~ /.claude/ ]]; then
    rel_path=".claude${abs_path#*/.claude}"
  fi

  echo "$rel_path"
}

# get_topic_path()
# Purpose: Get topic directory path from topic name
# Arguments:
#   $1 - Topic name (e.g., "959_todo_command")
# Returns: Absolute path to topic directory
# Usage:
#   TOPIC_PATH=$(get_topic_path "959_todo_command")
#
get_topic_path() {
  local topic_name="$1"
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
  echo "${specs_root}/${topic_name}"
}

# ============================================================================
# SECTION 6: TODO.md File Operations
# ============================================================================

# extract_backlog_section()
# Purpose: Extract existing Backlog section content for preservation
# Arguments:
#   $1 - Path to TODO.md file
# Returns: Backlog section content (empty if not found)
#
extract_backlog_section() {
  local todo_path="$1"

  if [ ! -f "$todo_path" ]; then
    echo ""
    return 0
  fi

  # Extract content between ## Backlog and next ## header
  sed -n '/^## Backlog$/,/^## /p' "$todo_path" | sed '1d;$d'
}

# format_plan_entry()
# Purpose: Format a single plan entry for TODO.md
# Arguments:
#   $1 - Section name
#   $2 - Plan title
#   $3 - Description
#   $4 - Plan path (relative)
#   $5 - Phase info (optional)
#   $6 - Reports JSON array (optional)
#   $7 - Summaries JSON array (optional)
# Returns: Formatted entry string
#
format_plan_entry() {
  local section="$1"
  local title="$2"
  local description="$3"
  local plan_path="$4"
  local phase_info="${5:-}"
  local reports="${6:-[]}"
  local summaries="${7:-[]}"

  local checkbox
  checkbox=$(get_checkbox_for_section "$section")

  # Build entry
  local entry="- ${checkbox} **${title}** - ${description} [${plan_path}]"

  # Add phase info if provided
  if [ -n "$phase_info" ]; then
    entry="${entry}\n  - ${phase_info}"
  fi

  # Add reports
  if [ "$reports" != "[]" ] && command -v jq &>/dev/null; then
    local report_count
    report_count=$(echo "$reports" | jq -r 'length')
    if [ "$report_count" -gt 0 ]; then
      local report_list=""
      while IFS= read -r report_path; do
        [ -z "$report_path" ] && continue
        local report_name
        report_name=$(basename "$report_path" .md)
        local rel_path
        rel_path=$(get_relative_path "$report_path")
        report_list="${report_list}[${report_name}](${rel_path}), "
      done < <(echo "$reports" | jq -r '.[]')
      report_list="${report_list%, }"
      if [ -n "$report_list" ]; then
        entry="${entry}\n  - Related reports: ${report_list}"
      fi
    fi
  fi

  # Add summaries
  if [ "$summaries" != "[]" ] && command -v jq &>/dev/null; then
    local summary_count
    summary_count=$(echo "$summaries" | jq -r 'length')
    if [ "$summary_count" -gt 0 ]; then
      local summary_list=""
      while IFS= read -r summary_path; do
        [ -z "$summary_path" ] && continue
        local summary_name
        summary_name=$(basename "$summary_path" .md)
        local rel_path
        rel_path=$(get_relative_path "$summary_path")
        summary_list="${summary_list}[${summary_name}](${rel_path}), "
      done < <(echo "$summaries" | jq -r '.[]')
      summary_list="${summary_list%, }"
      if [ -n "$summary_list" ]; then
        entry="${entry}\n  - Related summaries: ${summary_list}"
      fi
    fi
  fi

  echo -e "$entry"
}

# generate_completed_date_header()
# Purpose: Generate date header for Completed section
# Returns: Formatted date header (e.g., "**November 29, 2025**:")
#
generate_completed_date_header() {
  local date_str
  date_str=$(date "+%B %d, %Y")
  echo "**${date_str}**:"
}

# update_todo_file()
# Purpose: Update TODO.md with classified plans
# Arguments:
#   $1 - Path to TODO.md file
#   $2 - JSON array of classified plans
#   $3 - Dry run flag (true/false)
# Returns: 0 on success, 1 on failure
#
update_todo_file() {
  local todo_path="$1"
  local plans_json="$2"
  local dry_run="${3:-false}"

  # Extract existing Backlog section to preserve
  local existing_backlog=""
  if [ -f "$todo_path" ]; then
    existing_backlog=$(extract_backlog_section "$todo_path")
  fi

  # Initialize section arrays
  local in_progress_entries=()
  local not_started_entries=()
  local superseded_entries=()
  local abandoned_entries=()
  local completed_entries=()

  # Process each plan
  if command -v jq &>/dev/null && [ -n "$plans_json" ] && [ "$plans_json" != "[]" ]; then
    local plan_count
    plan_count=$(echo "$plans_json" | jq -r 'length')

    for ((i=0; i<plan_count; i++)); do
      local plan
      plan=$(echo "$plans_json" | jq -r ".[$i]")

      local status title description plan_path section phases_complete phases_total
      status=$(echo "$plan" | jq -r '.status // "not_started"')
      title=$(echo "$plan" | jq -r '.title // "Untitled"')
      description=$(echo "$plan" | jq -r '.description // ""')
      plan_path=$(echo "$plan" | jq -r '.plan_path // ""')
      phases_complete=$(echo "$plan" | jq -r '.phases_complete // 0')
      phases_total=$(echo "$plan" | jq -r '.phases_total // 0')

      # Get artifacts
      local topic_name
      topic_name=$(echo "$plan" | jq -r '.topic_name // ""')
      local artifacts_json=""
      if [ -n "$topic_name" ]; then
        artifacts_json=$(find_related_artifacts "$topic_name")
      fi
      local reports_json summaries_json
      reports_json=$(echo "$artifacts_json" | jq -r '.reports // []')
      summaries_json=$(echo "$artifacts_json" | jq -r '.summaries // []')

      # Get section
      section=$(categorize_plan "$status")
      local rel_path
      rel_path=$(get_relative_path "$plan_path")

      # Build phase info
      local phase_info=""
      if [ "$phases_total" -gt 0 ]; then
        if [ "$phases_complete" -eq "$phases_total" ]; then
          phase_info="All ${phases_total} phases complete"
        elif [ "$phases_complete" -gt 0 ]; then
          phase_info="Phase ${phases_complete}/${phases_total} complete"
        fi
      fi

      # Format entry
      local entry
      entry=$(format_plan_entry "$section" "$title" "$description" "$rel_path" "$phase_info" "$reports_json" "$summaries_json")

      # Add to appropriate section
      case "$section" in
        "In Progress")
          in_progress_entries+=("$entry")
          ;;
        "Not Started")
          not_started_entries+=("$entry")
          ;;
        "Superseded")
          superseded_entries+=("$entry")
          ;;
        "Abandoned")
          abandoned_entries+=("$entry")
          ;;
        "Completed")
          completed_entries+=("$entry")
          ;;
      esac
    done
  fi

  # Generate TODO.md content
  local content="# TODO\n\n"

  # In Progress section
  content+="## In Progress\n\n"
  if [ ${#in_progress_entries[@]} -gt 0 ]; then
    for entry in "${in_progress_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi

  # Not Started section
  content+="## Not Started\n\n"
  if [ ${#not_started_entries[@]} -gt 0 ]; then
    for entry in "${not_started_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi

  # Backlog section (preserved)
  content+="## Backlog\n\n"
  if [ -n "$existing_backlog" ]; then
    content+="${existing_backlog}\n"
  fi
  content+="\n"

  # Superseded section
  content+="## Superseded\n\n"
  if [ ${#superseded_entries[@]} -gt 0 ]; then
    for entry in "${superseded_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi

  # Abandoned section
  content+="## Abandoned\n\n"
  if [ ${#abandoned_entries[@]} -gt 0 ]; then
    for entry in "${abandoned_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi

  # Completed section with date grouping
  content+="## Completed\n\n"
  if [ ${#completed_entries[@]} -gt 0 ]; then
    local date_header
    date_header=$(generate_completed_date_header)
    content+="${date_header}\n\n"
    for entry in "${completed_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi

  # Output or write
  if [ "$dry_run" = "true" ]; then
    echo "=== DRY RUN: TODO.md Preview ==="
    echo ""
    echo -e "$content"
    echo "=== END PREVIEW ==="
  else
    # Backup existing file
    if [ -f "$todo_path" ]; then
      cp "$todo_path" "${todo_path}.backup"
    fi

    # Write new content
    echo -e "$content" > "$todo_path"
    echo "TODO.md updated: $todo_path"
  fi

  return 0
}

# validate_todo_structure()
# Purpose: Validate TODO.md file structure
# Arguments:
#   $1 - Path to TODO.md file
# Returns: 0 if valid, 1 if invalid with error messages
# Usage:
#   if validate_todo_structure "$TODO_PATH"; then
#     echo "Valid"
#   fi
#
validate_todo_structure() {
  local todo_path="$1"
  local errors=()

  if [ ! -f "$todo_path" ]; then
    echo "ERROR: TODO.md file not found: $todo_path" >&2
    return 1
  fi

  local content
  content=$(cat "$todo_path" 2>/dev/null)

  # Check required sections exist
  local required_sections=("## In Progress" "## Not Started" "## Backlog" "## Superseded" "## Abandoned" "## Completed")
  for section in "${required_sections[@]}"; do
    if ! echo "$content" | grep -q "^${section}"; then
      errors+=("Missing section: $section")
    fi
  done

  # Check section order (In Progress should come before Completed)
  local in_progress_line completed_line
  in_progress_line=$(echo "$content" | grep -n "^## In Progress" | head -1 | cut -d: -f1 || echo "0")
  completed_line=$(echo "$content" | grep -n "^## Completed" | head -1 | cut -d: -f1 || echo "0")

  if [ "$in_progress_line" -gt "$completed_line" ] && [ "$completed_line" -gt 0 ]; then
    errors+=("Section order violation: 'In Progress' should come before 'Completed'")
  fi

  # Report errors
  if [ ${#errors[@]} -gt 0 ]; then
    for error in "${errors[@]}"; do
      echo "VALIDATION ERROR: $error" >&2
    done
    return 1
  fi

  return 0
}

# ============================================================================
# SECTION 7: Cleanup Plan Generation (--clean mode)
# ============================================================================

# filter_completed_projects()
# Purpose: Filter completed projects older than specified age threshold
# Arguments:
#   $1 - JSON array of classified plans
#   $2 - Age threshold in days (default: 30)
# Returns: JSON array of completed projects meeting age criteria
#
filter_completed_projects() {
  local plans_json="$1"
  local age_threshold="${2:-30}"

  if ! command -v jq &>/dev/null; then
    echo "[]"
    return 1
  fi

  local current_epoch
  current_epoch=$(date +%s)
  local threshold_epoch=$((current_epoch - age_threshold * 86400))

  # Filter for completed status
  local completed_projects
  completed_projects=$(echo "$plans_json" | jq -r '[.[] | select(.status == "completed")]')

  # Further filter by age (based on plan file modification time)
  local filtered_projects="["
  local first=true

  while IFS= read -r plan_path; do
    [ -z "$plan_path" ] || [ "$plan_path" = "null" ] && continue
    [ ! -f "$plan_path" ] && continue

    local file_epoch
    file_epoch=$(stat -c %Y "$plan_path" 2>/dev/null || stat -f %m "$plan_path" 2>/dev/null || echo "$current_epoch")

    if [ "$file_epoch" -lt "$threshold_epoch" ]; then
      local plan_obj
      plan_obj=$(echo "$completed_projects" | jq -r --arg path "$plan_path" '.[] | select(.plan_path == $path)')
      if [ -n "$plan_obj" ] && [ "$plan_obj" != "null" ]; then
        if [ "$first" = "true" ]; then
          first=false
        else
          filtered_projects+=","
        fi
        filtered_projects+="$plan_obj"
      fi
    fi
  done < <(echo "$completed_projects" | jq -r '.[].plan_path')

  filtered_projects+="]"
  echo "$filtered_projects"
}

# generate_cleanup_plan()
# Purpose: Generate a cleanup plan for completed projects
# Arguments:
#   $1 - JSON array of completed projects to clean up
#   $2 - Archive destination path
#   $3 - Specs root path
# Returns: Plan content as string
#
generate_cleanup_plan() {
  local projects_json="$1"
  local archive_path="$2"
  local specs_root="$3"

  local project_count
  project_count=$(echo "$projects_json" | jq -r 'length')

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)

  local plan_content="# TODO Cleanup Plan

## Metadata
- **Date**: $(date +%Y-%m-%d)
- **Feature**: Archive completed projects from TODO.md
- **Scope**: Move ${project_count} completed projects to archive directory
- **Status**: [NOT STARTED]
- **Archive Path**: ${archive_path}

## Overview

This plan archives ${project_count} completed projects that are older than 30 days. Projects will be moved to the archive directory with a manifest for future reference.

## Success Criteria

- [ ] All ${project_count} projects archived successfully
- [ ] Archive manifest created with project metadata
- [ ] TODO.md updated to reflect archived projects
- [ ] Verification confirms no data loss

## Implementation Phases

### Phase 1: Create Archive Directory and Manifest [NOT STARTED]
dependencies: []

**Objective**: Prepare archive directory and create manifest file

Tasks:
- [ ] Create archive directory: ${archive_path}
- [ ] Generate archive manifest with project metadata
- [ ] Verify directory permissions

---

### Phase 2: Archive Project Directories [NOT STARTED]
dependencies: [1]

**Objective**: Move completed project directories to archive

Tasks:
"

  # Add task for each project
  local i=0
  while IFS= read -r topic_name; do
    [ -z "$topic_name" ] || [ "$topic_name" = "null" ] && continue
    plan_content+="- [ ] Archive project: ${topic_name}\n"
    i=$((i + 1))
  done < <(echo "$projects_json" | jq -r '.[].topic_name')

  plan_content+="
---

### Phase 3: Update TODO.md [NOT STARTED]
dependencies: [2]

**Objective**: Update TODO.md to reflect archived projects

Tasks:
- [ ] Backup current TODO.md
- [ ] Remove archived entries from Completed section
- [ ] Add archive reference to Completed section header

---

### Phase 4: Verification [NOT STARTED]
dependencies: [3]

**Objective**: Verify cleanup completed successfully

Tasks:
- [ ] Verify all project directories moved to archive
- [ ] Verify manifest contains all project metadata
- [ ] Verify TODO.md updated correctly
- [ ] Generate cleanup summary report

## Projects to Archive

"

  # List projects
  while IFS= read -r line; do
    local topic_name title
    topic_name=$(echo "$line" | cut -d'|' -f1)
    title=$(echo "$line" | cut -d'|' -f2)
    [ -z "$topic_name" ] || [ "$topic_name" = "null" ] && continue
    plan_content+="- **${title}** - ${specs_root}/${topic_name}\n"
  done < <(echo "$projects_json" | jq -r '.[] | "\(.topic_name)|\(.title)"')

  plan_content+="
## Safety Measures

- Archive (not delete) all projects
- Create manifest with full metadata
- Backup TODO.md before modifications
- Log all operations for audit

## Notes

This plan was generated by /todo --clean command.
Execute with /build to perform cleanup.
"

  echo -e "$plan_content"
}

# ============================================================================
# SECTION 8: Export Functions
# ============================================================================

# Export all public functions
export -f scan_project_directories
export -f find_plans_in_topic
export -f find_related_artifacts
export -f extract_plan_metadata
export -f categorize_plan
export -f classify_status_from_metadata
export -f get_checkbox_for_section
export -f get_relative_path
export -f get_topic_path
export -f extract_backlog_section
export -f format_plan_entry
export -f generate_completed_date_header
export -f update_todo_file
export -f validate_todo_structure
export -f filter_completed_projects
export -f generate_cleanup_plan
