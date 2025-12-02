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

# format_research_entry()
# Purpose: Format a research-only directory entry for TODO.md Research section
# Arguments:
#   $1 - Topic name (e.g., "991_repair_research_20251130_115356")
#   $2 - Topic path (absolute)
# Returns: Formatted entry string linking to directory
# Usage:
#   ENTRY=$(format_research_entry "991_repair_research" "/path/to/specs/991")
#
format_research_entry() {
  local topic_name="$1"
  local topic_path="$2"
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"

  # Extract title from first report file (if exists)
  local title="$topic_name"
  local description=""
  local reports_dir="${topic_path}/reports"

  if [ -d "$reports_dir" ]; then
    local first_report
    first_report=$(find "$reports_dir" -maxdepth 1 -type f -name "*.md" 2>/dev/null | sort | head -1)

    if [ -n "$first_report" ] && [ -f "$first_report" ]; then
      # Extract title from first heading
      local report_title
      report_title=$(grep -m1 "^# " "$first_report" | sed 's/^# //' | head -c 100 || echo "")
      if [ -n "$report_title" ]; then
        title="$report_title"
      fi

      # Extract description from second non-empty line or first paragraph
      description=$(sed -n '/^# /,/^$/{/^# /d; /^$/d; p;}' "$first_report" | head -1 | head -c 100 || echo "Research analysis")
    fi
  fi

  # Use fallback description if empty
  [ -z "$description" ] && description="Research-only project (no implementation plan)"

  # Get relative path to topic directory
  local rel_path
  rel_path=$(get_relative_path "$topic_path")

  # Format entry with directory link
  local checkbox="[ ]"
  echo "- ${checkbox} **${title}** - ${description} [${rel_path}/]"
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

# extract_saved_section()
# Purpose: Extract existing Saved section content for preservation
# Arguments:
#   $1 - Path to TODO.md file
# Returns: Saved section content (empty if not found)
#
extract_saved_section() {
  local todo_path="$1"

  if [ ! -f "$todo_path" ]; then
    echo ""
    return 0
  fi

  # Extract content between ## Saved and next ## header
  sed -n '/^## Saved$/,/^## /p' "$todo_path" | sed '1d;$d'
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

# extract_completed_section()
# Purpose: Extract existing Completed section content for preservation
# Arguments:
#   $1 - Path to TODO.md file
# Returns: Completed section content with date headers and entries (empty if not found)
#
extract_completed_section() {
  local todo_path="$1"

  if [ ! -f "$todo_path" ]; then
    echo ""
    return 0
  fi

  # Extract content between ## Completed and end of file (or next ## header if exists)
  sed -n '/^## Completed$/,$ p' "$todo_path" | sed '1d'
}

# parse_completed_entries()
# Purpose: Parse Completed section content to extract date-grouped entries
# Arguments:
#   $1 - Completed section content (from extract_completed_section)
# Returns: JSON array of objects with {date: "YYYY-MM-DD", entries: ["entry1", "entry2"]}
#
parse_completed_entries() {
  local content="$1"

  if [ -z "$content" ]; then
    echo "[]"
    return 0
  fi

  # Use awk to parse date headers and collect entries
  # Date headers match pattern: **Month Day, Year**: or **Month Day-Day, Year**:
  local json_output
  json_output=$(echo "$content" | awk '
    BEGIN {
      current_date = ""
      entry_buffer = ""
      first_group = 1
    }

    # Match date headers like **November 30, 2025**: or **November 27-29, 2025**:
    /^\*\*[A-Z][a-z]+ [0-9]/ {
      # Save previous group if exists
      if (current_date != "" && entry_buffer != "") {
        if (!first_group) printf ","
        first_group = 0
        # Escape quotes in entries
        gsub(/"/, "\\\"", entry_buffer)
        # Remove trailing newlines
        gsub(/\n+$/, "", entry_buffer)
        printf "{\"date\":\"%s\",\"entries\":\"%s\"}", current_date, entry_buffer
      }

      # Parse new date header
      # Extract date from **November 30, 2025**: format
      match($0, /\*\*([A-Z][a-z]+ [0-9]+(-[0-9]+)?, [0-9]+)\*\*:/, arr)
      if (arr[1] != "") {
        # Convert to YYYY-MM-DD format for sorting
        # For now, store the original format and convert later
        current_date = arr[1]
      }
      entry_buffer = ""
      next
    }

    # Collect entry lines (skip empty lines)
    /^- \[/ {
      if (entry_buffer != "") entry_buffer = entry_buffer "\\n"
      entry_buffer = entry_buffer $0
      next
    }

    # Collect continuation lines (indented lines starting with spaces)
    /^  / {
      entry_buffer = entry_buffer "\\n" $0
      next
    }

    END {
      # Save last group
      if (current_date != "" && entry_buffer != "") {
        if (!first_group) printf ","
        gsub(/"/, "\\\"", entry_buffer)
        gsub(/\n+$/, "", entry_buffer)
        printf "{\"date\":\"%s\",\"entries\":\"%s\"}", current_date, entry_buffer
      }
    }
  ')

  echo "[${json_output}]"
}

# detect_date_ranges()
# Purpose: Group consecutive dates into ranges
# Arguments:
#   $1 - JSON array of date strings in YYYY-MM-DD format
# Returns: JSON array of objects with {start: "YYYY-MM-DD", end: "YYYY-MM-DD"}
#
detect_date_ranges() {
  local dates_json="$1"

  if [ -z "$dates_json" ] || [ "$dates_json" = "[]" ]; then
    echo "[]"
    return 0
  fi

  # Use jq to sort dates and group consecutive ones
  if command -v jq &>/dev/null; then
    echo "$dates_json" | jq -r '
      sort | reverse |  # Newest first
      reduce .[] as $date (
        [];
        if length == 0 then
          [{start: $date, end: $date}]
        else
          . as $ranges |
          ($ranges | last) as $last_range |
          ($date | split("-") | map(tonumber)) as $date_parts |
          ($last_range.end | split("-") | map(tonumber)) as $last_parts |

          # Calculate if dates are consecutive (diff = 1 day)
          ($last_parts[0] * 10000 + $last_parts[1] * 100 + $last_parts[2]) as $last_num |
          ($date_parts[0] * 10000 + $date_parts[1] * 100 + $date_parts[2]) as $date_num |

          # Check if dates differ by exactly 1 day
          # This is a simplified check - proper implementation would handle month/year boundaries
          if ($last_num - $date_num == 1) then
            # Extend current range
            $ranges[:-1] + [{start: $date, end: $last_range.end}]
          else
            # Start new range
            $ranges + [{start: $date, end: $date}]
          end
        end
      )
    '
  else
    # Fallback: no grouping, just return individual dates
    echo "$dates_json" | sed 's/\[//;s/\]//;s/"//g' | tr ',' '\n' | while read -r date; do
      [ -z "$date" ] && continue
      echo "{\"start\":\"$date\",\"end\":\"$date\"}"
    done | jq -s '.'
  fi
}

# format_date_range_header()
# Purpose: Generate date header for Completed section (single date or range)
# Arguments:
#   $1 - Start date (YYYY-MM-DD format)
#   $2 - End date (YYYY-MM-DD format, optional - omit for single date)
# Returns: Formatted date header (e.g., "**November 29, 2025**:" or "**November 27-29, 2025**:")
#
format_date_range_header() {
  local start_date="$1"
  local end_date="${2:-}"

  # Convert YYYY-MM-DD to readable format
  local start_formatted
  start_formatted=$(date -d "$start_date" "+%B %-d, %Y" 2>/dev/null || date -j -f "%Y-%m-%d" "$start_date" "+%B %-d, %Y" 2>/dev/null)

  if [ -z "$end_date" ] || [ "$start_date" = "$end_date" ]; then
    # Single date
    echo "**${start_formatted}**:"
  else
    # Date range
    local end_formatted
    end_formatted=$(date -d "$end_date" "+%B %-d, %Y" 2>/dev/null || date -j -f "%Y-%m-%d" "$end_date" "+%B %-d, %Y" 2>/dev/null)

    # Extract components
    local start_month start_day start_year
    start_month=$(echo "$start_formatted" | cut -d' ' -f1)
    start_day=$(echo "$start_formatted" | cut -d' ' -f2 | tr -d ',')
    start_year=$(echo "$start_formatted" | cut -d' ' -f3)

    local end_month end_day end_year
    end_month=$(echo "$end_formatted" | cut -d' ' -f1)
    end_day=$(echo "$end_formatted" | cut -d' ' -f2 | tr -d ',')
    end_year=$(echo "$end_formatted" | cut -d' ' -f3)

    # Format based on month/year boundaries
    if [ "$start_year" != "$end_year" ]; then
      # Year boundary: "December 31, 2024 - January 1, 2025"
      echo "**${start_month} ${start_day}, ${start_year} - ${end_month} ${end_day}, ${end_year}**:"
    elif [ "$start_month" != "$end_month" ]; then
      # Month boundary: "October 31 - November 1, 2025"
      echo "**${start_month} ${start_day} - ${end_month} ${end_day}, ${end_year}**:"
    else
      # Same month: "November 27-29, 2025"
      echo "**${start_month} ${start_day}-${end_day}, ${start_year}**:"
    fi
  fi
}

# generate_completed_date_header()
# Purpose: Generate date header for Completed section (legacy compatibility)
# Returns: Formatted date header (e.g., "**November 29, 2025**:")
# Note: This function is deprecated in favor of format_date_range_header()
#
generate_completed_date_header() {
  local today
  today=$(date "+%Y-%m-%d")
  format_date_range_header "$today"
}

# update_todo_file()
# Purpose: Update TODO.md with classified plans
# Arguments:
#   $1 - Path to TODO.md file
#   $2 - JSON array of classified plans
#   $3 - Dry run flag (true/false)
# Returns: 0 on success, 1 on failure
#
# NOTE: This function does NOT create backups. Callers are responsible for
# creating git commits before calling this function if backup is needed.
# See /todo command for git-based backup pattern.
#
update_todo_file() {
  local todo_path="$1"
  local plans_json="$2"
  local dry_run="${3:-false}"

  # Extract existing Backlog and Saved sections to preserve
  local existing_backlog=""
  local existing_saved=""
  if [ -f "$todo_path" ]; then
    existing_backlog=$(extract_backlog_section "$todo_path")
    existing_saved=$(extract_saved_section "$todo_path")
  fi

  # Initialize section arrays
  local in_progress_entries=()
  local not_started_entries=()
  local research_entries=()
  local superseded_entries=()
  local abandoned_entries=()
  local completed_entries=()

  # Scan for research-only directories (have reports/ but no plans/)
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"
  if [ -d "$specs_root" ]; then
    while IFS= read -r topic_name; do
      [ -z "$topic_name" ] && continue

      local topic_path="${specs_root}/${topic_name}"
      local reports_dir="${topic_path}/reports"
      local plans_dir="${topic_path}/plans"

      # Check if directory has reports/ but no plans/ (or empty plans/)
      if [ -d "$reports_dir" ]; then
        local has_plans=false
        if [ -d "$plans_dir" ]; then
          # Check if plans directory has any .md files
          if ls "$plans_dir"/*.md >/dev/null 2>&1; then
            has_plans=true
          fi
        fi

        # If no plans, this is a research-only directory
        if [ "$has_plans" = "false" ]; then
          local research_entry
          research_entry=$(format_research_entry "$topic_name" "$topic_path")
          research_entries+=("$research_entry")
        fi
      fi
    done < <(scan_project_directories)
  fi

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

  # Research section (auto-populated from research-only directories)
  content+="## Research\n\n"
  if [ ${#research_entries[@]} -gt 0 ]; then
    for entry in "${research_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi

  # Saved section (manually curated, preserved)
  content+="## Saved\n\n"
  if [ -n "$existing_saved" ]; then
    content+="${existing_saved}\n"
  fi
  content+="\n"

  # Backlog section (manually curated, preserved)
  content+="## Backlog\n\n"
  if [ -n "$existing_backlog" ]; then
    content+="${existing_backlog}\n"
  fi
  content+="\n"

  # Abandoned section (includes superseded entries merged with [~] checkbox)
  content+="## Abandoned\n\n"
  if [ ${#abandoned_entries[@]} -gt 0 ]; then
    for entry in "${abandoned_entries[@]}"; do
      content+="${entry}\n\n"
    done
  fi
  # Add superseded entries to Abandoned section (migration compatibility)
  if [ ${#superseded_entries[@]} -gt 0 ]; then
    for entry in "${superseded_entries[@]}"; do
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
    # Write new content (caller responsible for git backup)
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

  # Check required sections exist (7 sections per standards)
  local required_sections=("## In Progress" "## Not Started" "## Research" "## Saved" "## Backlog" "## Abandoned" "## Completed")
  for section in "${required_sections[@]}"; do
    if ! echo "$content" | grep -q "^${section}"; then
      errors+=("Missing section: $section")
    fi
  done

  # Check section order (all 7 sections in canonical order)
  local canonical_sections=("## In Progress" "## Not Started" "## Research" "## Saved" "## Backlog" "## Abandoned" "## Completed")
  local prev_line=0
  local prev_section=""

  for section in "${canonical_sections[@]}"; do
    local section_line
    section_line=$(echo "$content" | grep -n "^${section}" | head -1 | cut -d: -f1 || echo "0")

    if [ "$section_line" -gt 0 ]; then
      # Check if this section appears after previous section
      if [ "$prev_line" -gt 0 ] && [ "$section_line" -lt "$prev_line" ]; then
        errors+=("Section order violation: '${section}' (line ${section_line}) appears before '${prev_section}' (line ${prev_line})")
      fi
      prev_line="$section_line"
      prev_section="$section"
    fi
  done

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
# SECTION 7: Query and Delegation Functions
# ============================================================================

# plan_exists_in_todo()
# Purpose: Check if plan appears in TODO.md (any section)
# Arguments:
#   $1 - Plan path (absolute or relative)
# Returns: 0 if found, 1 if not found
# Usage:
#   if plan_exists_in_todo "$plan_path"; then
#     echo "Plan found in TODO.md"
#   fi
#
plan_exists_in_todo() {
  local plan_path="$1"
  local todo_path="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

  # Check TODO.md exists
  if [ ! -f "$todo_path" ]; then
    return 1  # TODO.md doesn't exist, plan not found
  fi

  # Normalize path for searching (handle both absolute and relative)
  local search_path="$plan_path"
  if [[ "$plan_path" == /* ]]; then
    # Absolute path - convert to relative for TODO.md format
    search_path=$(get_relative_path "$plan_path")
  fi

  # Search for plan path in TODO.md
  if grep -qF "$search_path" "$todo_path" 2>/dev/null; then
    return 0  # Found
  else
    return 1  # Not found
  fi
}

# get_plan_current_section()
# Purpose: Find which TODO.md section contains the plan
# Arguments:
#   $1 - Plan path (absolute or relative)
# Returns: Section name (e.g., "Not Started", "In Progress") or empty string
# Usage:
#   SECTION=$(get_plan_current_section "$plan_path")
#   [ -n "$SECTION" ] && echo "Plan is in: $SECTION"
#
get_plan_current_section() {
  local plan_path="$1"
  local todo_path="${CLAUDE_PROJECT_DIR}/.claude/TODO.md"

  # Check TODO.md exists
  if [ ! -f "$todo_path" ]; then
    echo ""  # TODO.md doesn't exist
    return 1
  fi

  # Normalize path for searching
  local search_path="$plan_path"
  if [[ "$plan_path" == /* ]]; then
    # Absolute path - convert to relative
    search_path=$(get_relative_path "$plan_path")
  fi

  # Use awk to find section containing the plan
  local section_name
  section_name=$(awk -v path="$search_path" '
    /^## / {
      # Extract section name (strip ## prefix)
      current_section = substr($0, 4)
    }
    $0 ~ path {
      # Found plan in this section
      print current_section
      exit
    }
  ' "$todo_path")

  echo "$section_name"
  [ -n "$section_name" ] && return 0 || return 1
}

# ============================================================================
# SECTION 8: Cleanup Direct Execution (--clean mode)
# ============================================================================

# parse_todo_sections()
# Purpose: Parse TODO.md and extract entries from cleanup-eligible sections
# Arguments:
#   $1 - Path to TODO.md file
# Returns: JSON array with topic_name, topic_path, plan_path, section fields
# Note: This function reads directly from TODO.md sections rather than
#       relying on plan file classification, ensuring manual categorization
#       in TODO.md is honored during cleanup.
#
# Example output:
# [
#   {"topic_name": "902_error_logging", "topic_path": "/path/to/specs/902_error_logging",
#    "plan_path": ".claude/specs/902_error_logging/plans/001.md", "section": "Abandoned"},
#   ...
# ]
#
parse_todo_sections() {
  local todo_path="$1"
  local specs_root="${CLAUDE_SPECS_ROOT:-${CLAUDE_PROJECT_DIR}/.claude/specs}"

  # Validate TODO.md exists
  if [ ! -f "$todo_path" ]; then
    echo "[]"
    return 0
  fi

  # Read TODO.md content
  local content
  content=$(cat "$todo_path" 2>/dev/null)
  if [ -z "$content" ]; then
    echo "[]"
    return 0
  fi

  # Initialize JSON array builder
  local json_entries=""

  # Process each cleanup-eligible section (note: Superseded merged into Abandoned per standards)
  local sections=("Completed" "Abandoned")

  for section in "${sections[@]}"; do
    # Extract section content between ## Section and next ## header
    # Using awk for more reliable multi-line extraction
    local section_content
    section_content=$(echo "$content" | awk -v section="## $section" '
      $0 == section { found=1; next }
      /^## / && found { exit }
      found { print }
    ')

    # Skip if section is empty
    [ -z "$section_content" ] && continue

    # Extract entries from section
    # Pattern: - [x] or - [~] followed by **Title** ... [path/to/specs/NNN_topic/...]
    # Topic number can be in title (NNN) OR in the plan path
    while IFS= read -r line; do
      # Skip sub-bullets (indented lines)
      [[ "$line" =~ ^[[:space:]] ]] && continue

      # Match entry lines starting with - [x] or - [~] with bold title
      if echo "$line" | grep -qE '^- \[[x~]\] \*\*'; then
        # First, try to extract topic number from parentheses: (NNN)
        local topic_num
        topic_num=$(echo "$line" | grep -oE '\([0-9]+\)' | head -1 | tr -d '()')

        # If not found in title, try to extract from plan path: specs/NNN_topic/
        if [ -z "$topic_num" ]; then
          topic_num=$(echo "$line" | grep -oE 'specs/[0-9]+_' | head -1 | sed 's/specs\///' | tr -d '_')
        fi

        # Skip if no topic number found
        [ -z "$topic_num" ] && continue

        # Extract plan path from brackets at end: [.claude/specs/NNN_topic/plans/001.md]
        # Anchored regex matches only plan paths starting with .claude/specs/
        local plan_path
        plan_path=$(echo "$line" | grep -oE '\[\.claude/specs/[^]]+\.md\]' | tail -1 | tr -d '[]')

        # Find matching topic directory
        local topic_dir
        topic_dir=$(find "$specs_root" -maxdepth 1 -type d -name "${topic_num}_*" 2>/dev/null | head -1)

        # Skip if topic directory not found (already removed)
        if [ -z "$topic_dir" ]; then
          # Log info: topic directory not found
          [ "${DEBUG:-}" = "1" ] && echo "INFO: Topic directory not found for $topic_num (may already be removed)" >&2
          continue
        fi

        local topic_name
        topic_name=$(basename "$topic_dir")
        local topic_path="$topic_dir"

        # Build JSON entry
        # Escape special characters for JSON
        local escaped_plan_path
        escaped_plan_path=$(echo "$plan_path" | sed 's/"/\\"/g')

        local entry="{\"topic_name\": \"$topic_name\", \"topic_path\": \"$topic_path\", \"plan_path\": \"$escaped_plan_path\", \"section\": \"$section\"}"

        if [ -n "$json_entries" ]; then
          json_entries="${json_entries}, ${entry}"
        else
          json_entries="$entry"
        fi
      fi
    done <<< "$section_content"
  done

  # Build final JSON array
  local result="[${json_entries}]"

  # Validation logging: count parsed entries
  local parsed_count
  parsed_count=$(echo "$result" | jq -r 'length' 2>/dev/null || echo "0")
  [ "${DEBUG:-}" = "1" ] && echo "INFO: Parsed $parsed_count eligible projects from TODO.md" >&2

  # Return JSON array
  echo "$result"
}

# filter_completed_projects()
# Purpose: Filter projects by cleanup-eligible status (completed, superseded, abandoned)
# Arguments:
#   $1 - JSON array of classified plans
# Returns: JSON array of cleanup-eligible projects (all three statuses, no age filtering)
# Note: Previously filtered by age threshold, now includes all eligible projects regardless of age
#
filter_completed_projects() {
  local plans_json="$1"

  if ! command -v jq &>/dev/null; then
    echo "[]"
    return 1
  fi

  # Filter for cleanup-eligible statuses: completed, superseded, abandoned
  # No age-based filtering applied - all eligible projects included
  local eligible_projects
  eligible_projects=$(echo "$plans_json" | jq -r '[.[] | select(.status == "completed" or .status == "superseded" or .status == "abandoned")]')

  echo "$eligible_projects"
}

# has_uncommitted_changes()
# Purpose: Check if directory has uncommitted git-tracked changes
# Arguments:
#   $1 - Directory path to check
# Returns: 0 if changes exist, 1 if clean
#
has_uncommitted_changes() {
  local dir_path="$1"

  # Check directory exists
  if [ ! -d "$dir_path" ]; then
    return 1  # Non-existent directory is "clean"
  fi

  # Check git status for uncommitted changes in this directory
  local status_output
  status_output=$(git status --porcelain "$dir_path" 2>/dev/null)

  # Return 0 if changes exist, 1 if clean
  if [ -n "$status_output" ]; then
    return 0  # Has uncommitted changes
  else
    return 1  # Clean
  fi
}

# create_cleanup_git_commit()
# Purpose: Create pre-cleanup git commit for recovery
# Arguments: None (uses global context)
# Returns: 0 on success, 1 on failure
# Side Effects: Creates git commit, sets COMMIT_HASH variable
#
create_cleanup_git_commit() {
  local project_count="${1:-0}"

  # Stage all changes
  if ! git add . 2>/dev/null; then
    echo "ERROR: Failed to stage changes for git commit" >&2
    return 1
  fi

  # Create commit with standardized message
  local commit_message="chore: pre-cleanup snapshot before /todo --clean (${project_count} projects)"
  if ! git commit -m "$commit_message" 2>/dev/null; then
    # Check if there were no changes to commit
    if git diff --cached --quiet 2>/dev/null; then
      echo "WARNING: No changes to commit (repository already clean)" >&2
      COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
      return 0
    else
      echo "ERROR: Failed to create git commit" >&2
      return 1
    fi
  fi

  # Get commit hash
  COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null)
  if [ -z "$COMMIT_HASH" ]; then
    echo "ERROR: Failed to retrieve commit hash" >&2
    return 1
  fi

  echo "Created pre-cleanup commit: $COMMIT_HASH"
  echo "Recovery command: git revert $COMMIT_HASH"
  return 0
}

# execute_cleanup_removal()
# Purpose: Directly remove eligible project directories after git commit
# Arguments:
#   $1 - JSON array of eligible projects
#   $2 - Specs root path
# Returns: 0 on success, 1 on failure
# Side Effects: Removes directories, sets REMOVED_COUNT, SKIPPED_COUNT, FAILED_COUNT
#
execute_cleanup_removal() {
  local projects_json="$1"
  local specs_root="$2"

  # Initialize counters
  REMOVED_COUNT=0
  SKIPPED_COUNT=0
  FAILED_COUNT=0

  # Get project count
  local project_count
  project_count=$(echo "$projects_json" | jq -r 'length')

  if [ "$project_count" -eq 0 ]; then
    echo "No eligible projects to remove"
    return 0
  fi

  # First pass: Check for uncommitted changes and collect removable projects
  local -a removable_projects=()
  local -a skipped_projects=()

  echo "Checking for uncommitted changes in eligible projects..."

  while IFS= read -r topic_name; do
    [ -z "$topic_name" ] || [ "$topic_name" = "null" ] && continue

    local project_path="${specs_root}/${topic_name}"

    # Check if directory exists
    if [ ! -d "$project_path" ]; then
      echo "  ⚠ SKIP: $topic_name (directory not found)"
      skipped_projects+=("$topic_name")
      continue
    fi

    # Check for uncommitted changes BEFORE git commit
    if has_uncommitted_changes "$project_path"; then
      echo "  ⚠ SKIP: $topic_name (uncommitted changes detected)"
      skipped_projects+=("$topic_name")
      continue
    fi

    removable_projects+=("$topic_name")
  done < <(echo "$projects_json" | jq -r '.[].topic_name')

  # Update skipped count
  SKIPPED_COUNT=${#skipped_projects[@]}

  # If no projects can be removed, exit early
  if [ ${#removable_projects[@]} -eq 0 ]; then
    echo ""
    echo "No projects eligible for removal (all have uncommitted changes or not found)"
    echo "Skipped: $SKIPPED_COUNT"
    return 0
  fi

  # Create pre-cleanup git commit
  if ! create_cleanup_git_commit "$project_count"; then
    echo "ERROR: Failed to create pre-cleanup git commit. Aborting cleanup." >&2
    return 1
  fi

  # Second pass: Remove eligible projects
  echo ""
  echo "Removing eligible project directories..."

  for topic_name in "${removable_projects[@]}"; do
    local project_path="${specs_root}/${topic_name}"

    # Remove directory
    if rm -rf "$project_path" 2>/dev/null; then
      echo "  ✓ REMOVED: $topic_name"
      REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
      echo "  ✗ FAILED: $topic_name (removal error)"
      FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
  done

  echo ""
  echo "Cleanup summary:"
  echo "  Removed: $REMOVED_COUNT"
  echo "  Skipped: $SKIPPED_COUNT"
  echo "  Failed: $FAILED_COUNT"
  echo ""

  return 0
}

# ============================================================================
# SECTION 9: Export Functions
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
export -f format_research_entry
export -f extract_backlog_section
export -f extract_saved_section
export -f format_plan_entry
export -f generate_completed_date_header
export -f update_todo_file
export -f validate_todo_structure
export -f plan_exists_in_todo
export -f get_plan_current_section
export -f parse_todo_sections
export -f filter_completed_projects
export -f has_uncommitted_changes
export -f create_cleanup_git_commit
export -f execute_cleanup_removal
