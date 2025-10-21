#!/usr/bin/env bash
# artifact-operations.sh - Unified artifact registry, operations, and report generation
# Consolidates artifact-utils.sh and artifact-management.sh
# Part of .claude/lib/ modular utilities
#
# Primary Functions:
#   Registry Operations:
#     register_artifact - Register artifact in central registry
#     query_artifacts - Query artifacts by type or pattern
#     update_artifact_status - Update artifact metadata
#     cleanup_artifacts - Remove old artifact entries
#     validate_artifact_references - Check if artifact paths exist
#     list_artifacts - List all registered artifacts
#
#   Metadata Extraction:
#     get_plan_metadata - Extract plan metadata without reading full file
#     get_report_metadata - Extract report metadata without reading full file
#     get_plan_phase - Extract single phase content on-demand
#     get_plan_section - Generic section extraction by heading pattern
#     get_report_section - Extract report section by heading
#
#   Artifact Creation:
#     create_artifact_directory - Create artifact directory for plan operations
#     create_artifact_directory_with_workflow - Create artifact directory from workflow description
#     get_next_artifact_number - Find next available artifact number
#     write_artifact_file - Write artifact with variable-length content
#     generate_artifact_invocation - Generate research agent invocation prompt
#
#   Operation Tracking:
#     register_operation_artifact - Register artifacts in operation tracking
#     get_artifact_path - Retrieve artifact path by item ID (operation tracking)
#     get_artifact_path_by_id - Get path for artifact by registry ID
#     validate_operation_artifacts - Verify all operation artifacts exist
#
#   Parallel Operations:
#     save_operation_artifact - Save expansion/collapse operation result
#     load_artifact_references - Load artifact paths without reading content
#     cleanup_operation_artifacts - Remove artifacts after successful operations
#
#   Report Generation:
#     generate_analysis_report - Generate human-readable analysis reports
#     review_plan_hierarchy - Analyze plan structure for optimization
#     run_second_round_analysis - Re-analyze plan after operations
#     present_recommendations_for_approval - Display recommendations to user
#     generate_recommendations_report - Format analysis results as report
#
# Usage:
#   source "${BASH_SOURCE%/*}/artifact-operations.sh"
#   register_artifact "plan" "specs/plans/025.md" '{}'
#   generate_analysis_report "expand" "$decisions_json" "$plan_path"

set -euo pipefail

# ==============================================================================
# Environment Setup
# ==============================================================================

# Set CLAUDE_PROJECT_DIR if not already set
: "${CLAUDE_PROJECT_DIR:=$(pwd)}"

# ==============================================================================
# Constants
# ==============================================================================

# Artifact types
readonly ARTIFACT_TYPE_PLAN="plan"
readonly ARTIFACT_TYPE_REPORT="report"
readonly ARTIFACT_TYPE_SUMMARY="summary"
readonly ARTIFACT_TYPE_CHECKPOINT="checkpoint"

# Registry directory (conditional readonly to avoid conflicts with artifact-registry.sh)
if [[ -z "${ARTIFACT_REGISTRY_DIR:-}" ]]; then
  readonly ARTIFACT_REGISTRY_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/registry"
fi

# ==============================================================================
# Registry Operations
# ==============================================================================

# register_artifact: Register an artifact in the registry
# Usage: register_artifact <type> <path> [metadata-json]
# Returns: Registry entry ID
# Example: register_artifact "plan" "specs/plans/025.md" '{"status":"completed"}'
register_artifact() {
  local artifact_type="${1:-}"
  local artifact_path="${2:-}"
  local metadata_json="${3}"
  # Handle empty metadata with manual check to avoid bash brace expansion issue
  [ -z "$metadata_json" ] && metadata_json="{}"

  if [ -z "$artifact_type" ] || [ -z "$artifact_path" ]; then
    echo "Usage: register_artifact <type> <path> [metadata]" >&2
    return 1
  fi

  # Ensure registry directory exists
  mkdir -p "$ARTIFACT_REGISTRY_DIR"

  # Generate artifact ID
  local timestamp=$(date -u +%Y%m%d_%H%M%S)
  local artifact_name=$(basename "$artifact_path" | sed 's/\.[^.]*$//')
  local artifact_id="${artifact_type}_${artifact_name}_${timestamp}"

  # Build registry entry
  local entry_file="${ARTIFACT_REGISTRY_DIR}/${artifact_id}.json"

  if command -v jq &> /dev/null; then
    jq -n \
      --arg id "$artifact_id" \
      --arg type "$artifact_type" \
      --arg path "$artifact_path" \
      --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --argjson metadata "$metadata_json" \
      '{
        artifact_id: $id,
        artifact_type: $type,
        artifact_path: $path,
        created_at: $created,
        metadata: $metadata
      }' > "$entry_file"
  else
    local created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    cat > "$entry_file" <<EOF
{
  "artifact_id": "$artifact_id",
  "artifact_type": "$artifact_type",
  "artifact_path": "$artifact_path",
  "created_at": "$created",
  "metadata": $metadata_json
}
EOF
  fi

  echo "$artifact_id"
}

# query_artifacts: Query artifacts by type or pattern
# Usage: query_artifacts <type> [name-pattern]
# Returns: JSON array of matching artifacts
# Example: query_artifacts "plan" "auth"
query_artifacts() {
  local artifact_type="${1:-}"
  local name_pattern="${2:-*}"

  if [ ! -d "$ARTIFACT_REGISTRY_DIR" ]; then
    echo "[]"
    return
  fi

  # Find matching registry entries
  local pattern="${artifact_type}_${name_pattern}_*.json"
  local matching_files=$(ls "$ARTIFACT_REGISTRY_DIR"/$pattern 2>/dev/null || true)

  if [ -z "$matching_files" ]; then
    echo "[]"
    return
  fi

  # Build JSON array of results
  if command -v jq &> /dev/null; then
    jq -s '.' $matching_files 2>/dev/null || echo "[]"
  else
    echo "["
    local first=true
    for file in $matching_files; do
      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi
      cat "$file"
    done
    echo "]"
  fi
}

# update_artifact_status: Update artifact metadata
# Usage: update_artifact_status <artifact-id> <metadata-json>
# Returns: 0 on success
# Example: update_artifact_status "plan_auth_20251006" '{"status":"in_progress"}'
update_artifact_status() {
  local artifact_id="${1:-}"
  local metadata_json="${2:-}"

  if [ -z "$artifact_id" ]; then
    echo "Usage: update_artifact_status <artifact-id> <metadata>" >&2
    return 1
  fi

  local entry_file="${ARTIFACT_REGISTRY_DIR}/${artifact_id}.json"

  if [ ! -f "$entry_file" ]; then
    echo "Artifact not found: $artifact_id" >&2
    return 1
  fi

  # Update metadata
  if command -v jq &> /dev/null; then
    local temp_file="${entry_file}.tmp"
    jq --argjson metadata "$metadata_json" \
       '.metadata = $metadata' \
       "$entry_file" > "$temp_file"
    mv "$temp_file" "$entry_file"
  else
    echo "Warning: jq not available, cannot update metadata" >&2
    return 1
  fi
}

# cleanup_artifacts: Remove old artifact entries
# Usage: cleanup_artifacts <days-old>
# Returns: Count of cleaned up artifacts
# Example: cleanup_artifacts 30
cleanup_artifacts() {
  local days_old="${1:-30}"

  if [ ! -d "$ARTIFACT_REGISTRY_DIR" ]; then
    echo "0"
    return
  fi

  # Find and remove entries older than specified days
  local count=0
  local cutoff_date=$(date -u -d "$days_old days ago" +%Y%m%d 2>/dev/null || date -u -v-${days_old}d +%Y%m%d)

  for entry_file in "$ARTIFACT_REGISTRY_DIR"/*.json; do
    if [ ! -f "$entry_file" ]; then
      continue
    fi

    # Extract timestamp from filename
    local filename=$(basename "$entry_file")
    local timestamp=$(echo "$filename" | grep -oE '[0-9]{8}_[0-9]{6}')

    if [ -n "$timestamp" ]; then
      local entry_date=$(echo "$timestamp" | cut -d'_' -f1)

      if [ "$entry_date" -lt "$cutoff_date" ]; then
        rm -f "$entry_file"
        count=$((count + 1))
      fi
    fi
  done

  echo "$count"
}

# validate_artifact_references: Check if artifact paths still exist
# Usage: validate_artifact_references [artifact-type]
# Returns: JSON report of invalid references
# Example: validate_artifact_references "plan"
validate_artifact_references() {
  local artifact_type="${1:-*}"

  if [ ! -d "$ARTIFACT_REGISTRY_DIR" ]; then
    echo '{"valid":0,"invalid":0,"invalid_artifacts":[]}'
    return
  fi

  local valid_count=0
  local invalid_count=0
  local invalid_list=""

  local pattern="${artifact_type}_*.json"
  for entry_file in "$ARTIFACT_REGISTRY_DIR"/$pattern; do
    if [ ! -f "$entry_file" ]; then
      continue
    fi

    # Extract artifact path
    local artifact_path=""
    if command -v jq &> /dev/null; then
      artifact_path=$(jq -r '.artifact_path' "$entry_file")
    fi

    # Check if path exists
    if [ -n "$artifact_path" ] && [ -f "${CLAUDE_PROJECT_DIR}/$artifact_path" ]; then
      valid_count=$((valid_count + 1))
    else
      invalid_count=$((invalid_count + 1))
      local artifact_id=$(basename "$entry_file" .json)
      if [ -n "$invalid_list" ]; then
        invalid_list="$invalid_list,"
      fi
      invalid_list="$invalid_list\"$artifact_id\""
    fi
  done

  # Build report
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson valid "$valid_count" \
      --argjson invalid "$invalid_count" \
      --argjson list "[$invalid_list]" \
      '{valid:$valid,invalid:$invalid,invalid_artifacts:$list}'
  else
    echo "{\"valid\":$valid_count,\"invalid\":$invalid_count,\"invalid_artifacts\":[$invalid_list]}"
  fi
}

# list_artifacts: List all registered artifacts
# Usage: list_artifacts [artifact-type]
# Returns: Human-readable list
# Example: list_artifacts "plan"
list_artifacts() {
  local artifact_type="${1:-*}"

  local artifacts=$(query_artifacts "$artifact_type")

  if [ "$artifacts" = "[]" ]; then
    echo "No artifacts found"
    return
  fi

  echo "Registered Artifacts:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if command -v jq &> /dev/null; then
    echo "$artifacts" | jq -r '.[] | "  [\(.artifact_type)] \(.artifact_path) (created: \(.created_at))"'
  else
    echo "  (jq required for formatted listing)"
  fi
}

# get_artifact_path_by_id: Get path for artifact by registry ID
# Usage: get_artifact_path_by_id <artifact-id>
# Returns: Artifact path
# Example: get_artifact_path_by_id "plan_auth_20251006"
get_artifact_path_by_id() {
  local artifact_id="${1:-}"

  if [ -z "$artifact_id" ]; then
    return 1
  fi

  local entry_file="${ARTIFACT_REGISTRY_DIR}/${artifact_id}.json"

  if [ ! -f "$entry_file" ]; then
    return 1
  fi

  if command -v jq &> /dev/null; then
    jq -r '.artifact_path' "$entry_file"
  fi
}

# ==============================================================================
# Metadata Extraction Functions (Context Optimization)
# ==============================================================================

# get_plan_metadata: Extract plan metadata without reading full file
# Usage: get_plan_metadata <plan-file-path>
# Returns: JSON with title, date, phases, standards_file, path
# Example: get_plan_metadata "specs/plans/026_agential_system_refinement.md"
get_plan_metadata() {
  local plan_path="${1:-}"

  if [ -z "$plan_path" ]; then
    echo "Usage: get_plan_metadata <plan-path>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "{\"error\":\"File not found: $plan_path\"}" >&2
    return 1
  fi

  # Read only first 50 lines (metadata section)
  local metadata_lines=$(head -50 "$plan_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata (- **Date**: ...)
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Extract standards file reference
  local standards_file=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Standards File\*\*:' | sed 's/.*Standards File\*\*:\s*//')

  # Count phases in full file (### Phase N: or ## Phase N: pattern)
  local phases=$(grep -E '^##+ Phase [0-9]' "$plan_path" 2>/dev/null | wc -l)
  phases=${phases// /}  # Remove whitespace

  # Build JSON (handle jq availability)
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Plan}" \
      --arg date "${date:-Unknown}" \
      --arg phases "$phases" \
      --arg standards "${standards_file:-None}" \
      --arg path "$plan_path" \
      '{
        title: $title,
        date: $date,
        phases: ($phases | tonumber),
        standards_file: $standards,
        path: $path
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Plan}",
  "date": "${date:-Unknown}",
  "phases": $phases,
  "standards_file": "${standards_file:-None}",
  "path": "$plan_path"
}
EOF
  fi
}

# get_report_metadata: Extract report metadata without reading full file
# Usage: get_report_metadata <report-file-path>
# Returns: JSON with title, date, research_questions, path
# Example: get_report_metadata "specs/reports/024_system_optimization.md"
get_report_metadata() {
  local report_path="${1:-}"

  if [ -z "$report_path" ]; then
    echo "Usage: get_report_metadata <report-path>" >&2
    return 1
  fi

  if [ ! -f "$report_path" ]; then
    echo "{\"error\":\"File not found: $report_path\"}" >&2
    return 1
  fi

  # Read only first 100 lines (metadata + exec summary section)
  local metadata_lines=$(head -100 "$report_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Extract research question count
  local question_count=$(echo "$metadata_lines" | grep -c '^\s*[0-9]\+\.\s' || echo "0")

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Report}" \
      --arg date "${date:-Unknown}" \
      --arg questions "$question_count" \
      --arg path "$report_path" \
      '{
        title: $title,
        date: $date,
        research_questions: ($questions | tonumber),
        path: $path
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Report}",
  "date": "${date:-Unknown}",
  "research_questions": $question_count,
  "path": "$report_path"
}
EOF
  fi
}

# get_plan_phase: Extract single phase content on-demand
# Usage: get_plan_phase <plan-file-path> <phase-number>
# Returns: Phase content as text
# Example: get_plan_phase "specs/plans/026_foo.md" 3
get_plan_phase() {
  local plan_path="${1:-}"
  local phase_num="${2:-}"

  if [ -z "$plan_path" ] || [ -z "$phase_num" ]; then
    echo "Usage: get_plan_phase <plan-path> <phase-number>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "Error: File not found: $plan_path" >&2
    return 1
  fi

  # Find line number of phase heading (supports both ## and ### levels)
  local start_line=$(grep -nE "^##+ Phase $phase_num:" "$plan_path" | cut -d: -f1 | head -1)

  if [ -z "$start_line" ]; then
    echo "Error: Phase $phase_num not found in $plan_path" >&2
    return 1
  fi

  # Find line number of next phase or end of file
  local next_phase=$((phase_num + 1))
  local end_line=$(grep -nE "^##+ Phase $next_phase:" "$plan_path" | cut -d: -f1 | head -1)

  # Extract phase content
  if [ -n "$end_line" ]; then
    sed -n "${start_line},$((end_line - 1))p" "$plan_path"
  else
    sed -n "${start_line},\$p" "$plan_path"
  fi
}

# get_plan_section: Generic section extraction by heading pattern
# Usage: get_plan_section <plan-file-path> <section-heading-pattern>
# Returns: Section content as text
# Example: get_plan_section "specs/plans/026_foo.md" "Technical Design"
get_plan_section() {
  local plan_path="${1:-}"
  local section_pattern="${2:-}"

  if [ -z "$plan_path" ] || [ -z "$section_pattern" ]; then
    echo "Usage: get_plan_section <plan-path> <section-heading>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "Error: File not found: $plan_path" >&2
    return 1
  fi

  # Find line number of section heading (## pattern)
  local start_line=$(grep -n "^## .*$section_pattern" "$plan_path" | cut -d: -f1 | head -1)

  if [ -z "$start_line" ]; then
    echo "Error: Section '$section_pattern' not found in $plan_path" >&2
    return 1
  fi

  # Find line number of next ## heading or end of file
  local end_line=$(awk "NR>$start_line && /^## / {print NR; exit}" "$plan_path")

  # Extract section content
  if [ -n "$end_line" ]; then
    sed -n "${start_line},$((end_line - 1))p" "$plan_path"
  else
    sed -n "${start_line},\$p" "$plan_path"
  fi
}

# get_report_section: Extract report section by heading
# Usage: get_report_section <report-file-path> <section-heading-pattern>
# Returns: Section content as text
# Example: get_report_section "specs/reports/024_foo.md" "Executive Summary"
get_report_section() {
  local report_path="${1:-}"
  local section_pattern="${2:-}"

  if [ -z "$report_path" ] || [ -z "$section_pattern" ]; then
    echo "Usage: get_report_section <report-path> <section-heading>" >&2
    return 1
  fi

  if [ ! -f "$report_path" ]; then
    echo "Error: File not found: $report_path" >&2
    return 1
  fi

  # Find line number of section heading (## pattern)
  local start_line=$(grep -n "^## .*$section_pattern" "$report_path" | cut -d: -f1 | head -1)

  if [ -z "$start_line" ]; then
    echo "Error: Section '$section_pattern' not found in $report_path" >&2
    return 1
  fi

  # Find line number of next ## heading or end of file
  local end_line=$(awk "NR>$start_line && /^## / {print NR; exit}" "$report_path")

  # Extract section content
  if [ -n "$end_line" ]; then
    sed -n "${start_line},$((end_line - 1))p" "$report_path"
  else
    sed -n "${start_line},\$p" "$report_path"
  fi
}

# ==============================================================================
# Artifact Creation Functions
# ==============================================================================

# create_topic_artifact: Create artifact in topic-based subdirectory
# Usage: create_topic_artifact <topic-dir> <artifact-type> <artifact-name> <content>
# Returns: Artifact file path
# Example: create_topic_artifact "specs/009_orchestration" "debug" "bundle_compatibility" "$debug_content"
create_topic_artifact() {
  local topic_dir="${1:-}"
  local artifact_type="${2:-}"
  local artifact_name="${3:-}"
  local content="${4:-}"

  if [ -z "$topic_dir" ] || [ -z "$artifact_type" ] || [ -z "$artifact_name" ]; then
    echo "Usage: create_topic_artifact <topic-dir> <artifact-type> <name> <content>" >&2
    return 1
  fi

  # Validate artifact type
  case "$artifact_type" in
    debug|scripts|outputs|artifacts|backups|data|logs|notes)
      ;;
    *)
      echo "Error: Invalid artifact type '$artifact_type'" >&2
      echo "Valid types: debug, scripts, outputs, artifacts, backups, data, logs, notes" >&2
      return 1
      ;;
  esac

  # Create artifact subdirectory
  local artifact_subdir="${CLAUDE_PROJECT_DIR}/${topic_dir}/${artifact_type}"
  mkdir -p "$artifact_subdir"

  # Get next artifact number
  local next_num=$(get_next_artifact_number "$artifact_subdir")

  # Create artifact file path
  local artifact_file="${artifact_subdir}/${next_num}_${artifact_name}.md"

  # Write content to file
  if [ -n "$content" ]; then
    echo "$content" > "$artifact_file"
  else
    # Create empty file with basic metadata
    cat > "$artifact_file" <<EOF
# ${artifact_name}

## Metadata
- **Date**: $(date -u +%Y-%m-%d)
- **Topic**: $(basename "$topic_dir")
- **Type**: $artifact_type
- **Number**: $next_num

## Content
(Content to be added)
EOF
  fi

  # Set executable permission for scripts
  if [ "$artifact_type" = "scripts" ]; then
    chmod +x "$artifact_file" 2>/dev/null || true
  fi

  # Register artifact
  local metadata_json=$(jq -n \
    --arg topic "$(basename "$topic_dir")" \
    --arg type "$artifact_type" \
    --arg num "$next_num" \
    '{topic: $topic, artifact_type: $type, number: $num}')

  register_artifact "$artifact_type" "${topic_dir}/${artifact_type}/${next_num}_${artifact_name}.md" "$metadata_json" >/dev/null

  echo "$artifact_file"
}

# create_artifact_directory: Create artifact directory for plan operations
# Usage: create_artifact_directory <plan-path>
# Returns: Artifact directory path
# Example: create_artifact_directory "specs/plans/026_foo.md"
create_artifact_directory() {
  local plan_path="${1:-}"

  if [ -z "$plan_path" ]; then
    echo "Usage: create_artifact_directory <plan-path>" >&2
    return 1
  fi

  # Extract plan name from path
  local plan_name
  plan_name=$(basename "$plan_path" .md)

  # Create artifact directory
  local artifact_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}"
  mkdir -p "$artifact_dir"

  echo "$artifact_dir"
}

# create_artifact_directory_with_workflow: Create artifact directory from workflow description
# Usage: create_artifact_directory_with_workflow <workflow-description>
# Returns: project_name artifact_dir next_number (space-separated)
# Example: create_artifact_directory_with_workflow "Implement user authentication"
create_artifact_directory_with_workflow() {
  local workflow_description="${1:-}"

  if [ -z "$workflow_description" ]; then
    echo "Usage: create_artifact_directory_with_workflow <workflow-description>" >&2
    return 1
  fi

  # Convert workflow description to snake_case project name
  # "Implement user auth" → "user_auth"
  # "Add OAuth2 support" → "oauth2_support"
  local project_name=$(echo "$workflow_description" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 ]//g' | \
    tr ' ' '_' | \
    sed 's/__*/_/g' | \
    sed 's/^_//; s/_$//')

  # Create artifact directory
  local artifact_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${project_name}"
  mkdir -p "$artifact_dir"

  # Get next available artifact number
  local next_number=$(get_next_artifact_number "$artifact_dir")

  # Return project name, directory, and next number (space-separated)
  echo "$project_name" "$artifact_dir" "$next_number"
}

# get_next_artifact_number: Find next available artifact number in topic directory
# Usage: get_next_artifact_number <topic-dir>
# Returns: Next number with zero-padding (e.g., "001", "002")
# Example: get_next_artifact_number "specs/artifacts/user_auth"
get_next_artifact_number() {
  local topic_dir="${1:-}"

  if [ -z "$topic_dir" ]; then
    echo "Usage: get_next_artifact_number <topic-dir>" >&2
    return 1
  fi

  local max_num=0

  # Find highest existing number in NNN_*.md files
  for file in "$topic_dir"/[0-9][0-9][0-9]_*.md; do
    [[ -e "$file" ]] || continue
    local num=$(basename "$file" | grep -oE '^[0-9]+')
    if [ -n "$num" ]; then
      # Strip leading zeros to avoid octal interpretation (10#$num forces base-10)
      num=$((10#$num))
      (( num > max_num )) && max_num=$num
    fi
  done

  # Return next number with zero-padding
  printf "%03d" $((max_num + 1))
}

# write_artifact_file: Write artifact with variable-length content
# Usage: write_artifact_file <summary_text> <artifact_path> <metadata_json>
# Returns: 0 on success
# Example: write_artifact_file "$summary" "specs/artifacts/test/001_topic.md" '{"topic":"test"}'
write_artifact_file() {
  local summary_text="${1:-}"
  local artifact_path="${2:-}"
  local metadata_json="${3}"
  # Handle empty metadata with manual check to avoid bash brace expansion issue
  [ -z "$metadata_json" ] && metadata_json="{}"

  if [ -z "$summary_text" ] || [ -z "$artifact_path" ]; then
    echo "Usage: write_artifact_file <summary> <path> <metadata>" >&2
    return 1
  fi

  # Extract metadata fields (with fallback if jq not available or parsing fails)
  local topic="Unknown"
  local workflow="Unknown"

  if command -v jq &> /dev/null; then
    # jq's // operator provides fallback, no need for || with pipefail
    topic=$(echo "$metadata_json" | jq -r '.topic // "Unknown"' 2>/dev/null) || topic="Unknown"
    workflow=$(echo "$metadata_json" | jq -r '.workflow // "Unknown"' 2>/dev/null) || workflow="Unknown"
  fi

  # Calculate word count
  local word_count=$(echo "$summary_text" | wc -w | tr -d ' ')

  # Create artifact file with variable-length template
  cat > "$artifact_path" <<EOF
# $topic

## Metadata
- **Created**: $(date -u +%Y-%m-%d)
- **Workflow**: $workflow
- **Agent**: research-specialist
- **Focus**: $topic
- **Length**: $word_count words

## Findings
$summary_text

## Recommendations
(No specific recommendations provided)
EOF

  return 0
}

# generate_artifact_invocation: Generate research agent invocation prompt
# Usage: generate_artifact_invocation <artifact_path> <research_topic> <workflow_description>
# Returns: Formatted invocation prompt
# Example: generate_artifact_invocation "specs/artifacts/auth/001_patterns.md" "JWT vs sessions" "Implement authentication"
generate_artifact_invocation() {
  local artifact_path="${1:-}"
  local research_topic="${2:-}"
  local workflow_description="${3:-}"

  if [ -z "$artifact_path" ] || [ -z "$research_topic" ]; then
    echo "Usage: generate_artifact_invocation <artifact_path> <research_topic> <workflow>" >&2
    return 1
  fi

  # Generate the invocation prompt
  cat <<EOF
OUTPUT MODE: Artifact

Write your research findings directly to an artifact file at:
$artifact_path

ARTIFACT FORMAT REQUIREMENTS:

1. **Variable-Length Content**: Adapt the length to match research complexity:
   - Simple findings: 100-200 words
   - Moderate analysis: 200-500 words
   - Complex research: 500-1000+ words
   - Optimize for concision but preserve all essential findings and recommendations
   - No arbitrary length limits - use what the research needs

2. **Required Structure**:
   \`\`\`markdown
   # $research_topic

   ## Metadata
   - **Created**: $(date -u +%Y-%m-%d)
   - **Workflow**: $workflow_description
   - **Agent**: research-specialist
   - **Focus**: $research_topic
   - **Length**: {word_count} words

   ## Findings
   {Your research findings - variable length based on complexity}

   ## Recommendations
   {Actionable recommendations based on findings - variable length}
   \`\`\`

3. **Return Format**: After writing the artifact, return only:
   - Artifact ID: {artifact_id}
   - Path: $artifact_path

   Do NOT include the full summary in your response - it's already in the artifact file.

ARTIFACT PATH: $artifact_path
RESEARCH TOPIC: $research_topic
WORKFLOW: $workflow_description
EOF
}

# ==============================================================================
# Operation Tracking Functions
# ==============================================================================

# register_operation_artifact: Register artifact in operation tracking
# Args:
#   $1 - plan_path: Path to plan
#   $2 - operation_type: "expansion" or "collapse"
#   $3 - item_id: Item identifier (e.g., "phase_2")
#   $4 - artifact_path: Path to artifact file
# Returns:
#   0 on success, non-zero on failure
register_operation_artifact() {
  local plan_path="$1"
  local operation_type="$2"
  local item_id="$3"
  local artifact_path="$4"

  # Validate inputs
  if [[ -z "$plan_path" ]] || [[ -z "$operation_type" ]] || [[ -z "$item_id" ]] || [[ -z "$artifact_path" ]]; then
    echo "ERROR: register_operation_artifact requires plan_path, operation_type, item_id, and artifact_path" >&2
    return 1
  fi

  # Create tracking file
  local plan_name
  plan_name=$(basename "$plan_path" .md)

  local tracking_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}"
  mkdir -p "$tracking_dir"

  local tracking_file="${tracking_dir}/.artifact_registry.json"

  # Build registry entry
  local entry
  if command -v jq &> /dev/null; then
    entry=$(jq -n \
      --arg id "$item_id" \
      --arg type "$operation_type" \
      --arg path "$artifact_path" \
      --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '{item_id: $id, operation: $type, artifact_path: $path, registered: $timestamp}')
  else
    entry="{\"item_id\":\"$item_id\",\"operation\":\"$operation_type\",\"artifact_path\":\"$artifact_path\",\"registered\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  fi

  # Append to registry
  if [[ -f "$tracking_file" ]]; then
    if command -v jq &> /dev/null; then
      local temp_file="${tracking_file}.tmp"
      jq --argjson entry "$entry" '. += [$entry]' "$tracking_file" > "$temp_file"
      mv "$temp_file" "$tracking_file"
    fi
  else
    echo "[$entry]" > "$tracking_file"
  fi

  return 0
}

# get_artifact_path: Retrieve artifact path by item ID (operation tracking)
# Args:
#   $1 - plan_path: Path to plan
#   $2 - item_id: Item identifier
# Returns:
#   Artifact path or empty string
get_artifact_path() {
  local plan_path="$1"
  local item_id="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$item_id" ]]; then
    echo ""
    return 1
  fi

  local plan_name
  plan_name=$(basename "$plan_path" .md)

  local tracking_file="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}/.artifact_registry.json"

  if [[ ! -f "$tracking_file" ]]; then
    echo ""
    return 1
  fi

  if command -v jq &> /dev/null; then
    jq -r ".[] | select(.item_id == \"$item_id\") | .artifact_path" "$tracking_file" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# validate_operation_artifacts: Verify all operation artifacts exist
# Args:
#   $1 - plan_path: Path to plan
# Returns:
#   JSON report of validation results
validate_operation_artifacts() {
  local plan_path="$1"

  if [[ -z "$plan_path" ]]; then
    echo '{"valid":0,"invalid":0,"missing":[]}'
    return 1
  fi

  local plan_name
  plan_name=$(basename "$plan_path" .md)

  local tracking_file="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}/.artifact_registry.json"

  if [[ ! -f "$tracking_file" ]]; then
    echo '{"valid":0,"invalid":0,"missing":[]}'
    return 0
  fi

  if command -v jq &> /dev/null; then
    local valid=0
    local invalid=0
    local missing="[]"

    while IFS= read -r entry; do
      local artifact_path
      artifact_path=$(echo "$entry" | jq -r '.artifact_path')

      if [[ -f "${CLAUDE_PROJECT_DIR}/${artifact_path}" ]]; then
        valid=$((valid + 1))
      else
        invalid=$((invalid + 1))
        local item_id
        item_id=$(echo "$entry" | jq -r '.item_id')
        missing=$(echo "$missing" | jq --arg id "$item_id" '. += [$id]')
      fi
    done < <(jq -c '.[]' "$tracking_file")

    jq -n \
      --argjson valid "$valid" \
      --argjson invalid "$invalid" \
      --argjson missing "$missing" \
      '{valid: $valid, invalid: $invalid, missing: $missing}'
  else
    echo '{"valid":0,"invalid":0,"missing":[]}'
  fi
}

# ==============================================================================
# Parallel Operation Functions
# ==============================================================================

# save_operation_artifact: Save expansion/collapse operation result
# Usage: save_operation_artifact <plan-name> <operation-type> <item-id> <content>
# Returns: Artifact file path
# Example: save_operation_artifact "026_foo" "expansion" "phase_2" "$artifact_content"
save_operation_artifact() {
  local plan_name="${1:-}"
  local operation_type="${2:-}"
  local item_id="${3:-}"
  local content="${4:-}"

  if [ -z "$plan_name" ] || [ -z "$operation_type" ] || [ -z "$item_id" ]; then
    echo "Usage: save_operation_artifact <plan-name> <operation-type> <item-id> <content>" >&2
    return 1
  fi

  # Create artifact directory
  local artifact_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}"
  mkdir -p "$artifact_dir"

  # Create artifact file
  local artifact_file="${artifact_dir}/${operation_type}_${item_id}.md"
  echo "$content" > "$artifact_file"

  echo "$artifact_file"
}

# load_artifact_references: Load artifact paths without reading content
# Usage: load_artifact_references <plan-name> <operation-type>
# Returns: JSON array of artifact references
# Example: load_artifact_references "026_foo" "expansion"
load_artifact_references() {
  local plan_name="${1:-}"
  local operation_type="${2:-}"

  if [ -z "$plan_name" ]; then
    echo "[]"
    return 0
  fi

  local artifact_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}"

  if [ ! -d "$artifact_dir" ]; then
    echo "[]"
    return 0
  fi

  # Find matching artifact files
  local pattern="${operation_type}_*.md"
  if [ -z "$operation_type" ]; then
    pattern="*.md"
  fi

  local artifact_files=$(find "$artifact_dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | sort)

  if [ -z "$artifact_files" ]; then
    echo "[]"
    return 0
  fi

  # Build JSON array of references (paths only, not content)
  if command -v jq &> /dev/null; then
    local refs="[]"
    for artifact_file in $artifact_files; do
      local rel_path="${artifact_file#${CLAUDE_PROJECT_DIR}/}"
      local item_id=$(basename "$artifact_file" .md | sed "s/^${operation_type}_//")
      refs=$(echo "$refs" | jq \
        --arg path "$rel_path" \
        --arg id "$item_id" \
        --arg size "$(wc -c < "$artifact_file")" \
        '. += [{item_id: $id, path: $path, size: ($size | tonumber)}]')
    done
    echo "$refs"
  else
    echo "[]"
  fi
}

# cleanup_operation_artifacts: Remove artifacts after successful operations
# Usage: cleanup_operation_artifacts <plan-name> [operation-type]
# Returns: Count of artifacts deleted
# Example: cleanup_operation_artifacts "026_foo" "expansion"
cleanup_operation_artifacts() {
  local plan_name="${1:-}"
  local operation_type="${2:-}"

  if [ -z "$plan_name" ]; then
    echo "0"
    return 0
  fi

  local artifact_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}"

  if [ ! -d "$artifact_dir" ]; then
    echo "0"
    return 0
  fi

  # Find matching artifacts
  local pattern="*.md"
  if [ -n "$operation_type" ]; then
    pattern="${operation_type}_*.md"
  fi

  local count=0
  for artifact_file in "$artifact_dir"/$pattern; do
    if [ -f "$artifact_file" ]; then
      rm -f "$artifact_file"
      count=$((count + 1))
    fi
  done

  # Remove directory if empty
  if [ -z "$(ls -A "$artifact_dir" 2>/dev/null)" ]; then
    rmdir "$artifact_dir"
  fi

  echo "$count"
}

# cleanup_topic_artifacts: Clean up temporary topic-scoped artifacts
# Usage: cleanup_topic_artifacts <topic-dir> <artifact-type> [age-days]
# Returns: Count of artifacts deleted
# Example: cleanup_topic_artifacts "specs/009_orchestration" "scripts" 7
cleanup_topic_artifacts() {
  local topic_dir="${1:-}"
  local artifact_type="${2:-}"
  local age_days="${3:-0}"

  if [ -z "$topic_dir" ] || [ -z "$artifact_type" ]; then
    echo "Usage: cleanup_topic_artifacts <topic-dir> <artifact-type> [age-days]" >&2
    return 1
  fi

  local artifact_subdir="${CLAUDE_PROJECT_DIR}/${topic_dir}/${artifact_type}"

  if [ ! -d "$artifact_subdir" ]; then
    echo "0"
    return 0
  fi

  local count=0

  # Clean up based on age
  if [ "$age_days" -gt 0 ]; then
    # Remove files older than specified days
    local cutoff_date=$(date -u -d "$age_days days ago" +%Y%m%d 2>/dev/null || date -u -v-${age_days}d +%Y%m%d)

    for artifact_file in "$artifact_subdir"/*; do
      if [ ! -f "$artifact_file" ]; then
        continue
      fi

      local file_date=$(date -u -r "$artifact_file" +%Y%m%d 2>/dev/null || stat -f %Sm -t %Y%m%d "$artifact_file" 2>/dev/null)

      if [ -n "$file_date" ] && [ "$file_date" -lt "$cutoff_date" ]; then
        rm -f "$artifact_file"
        count=$((count + 1))
      fi
    done
  else
    # Remove all files in subdirectory (age_days = 0 means all)
    for artifact_file in "$artifact_subdir"/*; do
      if [ -f "$artifact_file" ]; then
        rm -f "$artifact_file"
        count=$((count + 1))
      fi
    done
  fi

  # Remove subdirectory if empty
  if [ -z "$(ls -A "$artifact_subdir" 2>/dev/null)" ]; then
    rmdir "$artifact_subdir"
  fi

  echo "$count"
}

# cleanup_all_temp_artifacts: Clean up all temporary artifacts from topic directory
# Usage: cleanup_all_temp_artifacts <topic-dir>
# Returns: Total count of artifacts deleted
# Example: cleanup_all_temp_artifacts "specs/009_orchestration"
cleanup_all_temp_artifacts() {
  local topic_dir="${1:-}"

  if [ -z "$topic_dir" ]; then
    echo "Usage: cleanup_all_temp_artifacts <topic-dir>" >&2
    return 1
  fi

  local total_count=0

  # Clean up temporary artifact types (not debug/ which is committed)
  for artifact_type in scripts outputs artifacts backups data logs notes; do
    local artifact_subdir="${CLAUDE_PROJECT_DIR}/${topic_dir}/${artifact_type}"

    if [ -d "$artifact_subdir" ]; then
      local count=$(cleanup_topic_artifacts "$topic_dir" "$artifact_type" 0)
      total_count=$((total_count + count))
    fi
  done

  echo "$total_count"
}

# ==============================================================================
# Report Generation Functions
# ==============================================================================

# generate_analysis_report: Generate human-readable analysis reports
# Args:
#   $1 - mode: "expand" or "collapse"
#   $2 - decisions_json: JSON array of agent decisions
#   $3 - plan_path: Path to plan (for display)
# Outputs:
#   Formatted report to stdout
generate_analysis_report() {
  local mode="$1"
  local decisions_json="$2"
  local plan_path="$3"

  local plan_name
  plan_name=$(basename "$plan_path")

  local item_count
  item_count=$(echo "$decisions_json" | jq 'length')

  local action_verb action_past
  if [[ "$mode" == "expand" ]]; then
    action_verb="Expand"
    action_past="Expanded"
  else
    action_verb="Collapse"
    action_past="Collapsed"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Auto-Analysis Mode: ${action_verb}ing Items"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Plan: $plan_name"
  echo ""
  echo "Complexity Estimator Analysis:"
  echo ""

  local expanded_count=0
  local skipped_count=0

  # Iterate through decisions
  while IFS= read -r decision; do
    local item_id item_name complexity reasoning recommendation confidence
    item_id=$(echo "$decision" | jq -r '.item_id')
    item_name=$(echo "$decision" | jq -r '.item_name')
    complexity=$(echo "$decision" | jq -r '.complexity_level')
    reasoning=$(echo "$decision" | jq -r '.reasoning')
    recommendation=$(echo "$decision" | jq -r '.recommendation')
    confidence=$(echo "$decision" | jq -r '.confidence // "medium"')

    echo "  $item_name (complexity: $complexity/10)"
    echo "    Reasoning: $reasoning"

    if [[ "$recommendation" == "expand" ]] || [[ "$recommendation" == "collapse" ]]; then
      echo "    Action: $(echo "$recommendation" | tr '[:lower:]' '[:upper:]') (confidence: $confidence)"
      expanded_count=$((expanded_count + 1))
    else
      echo "    Action: SKIP (confidence: $confidence)"
      skipped_count=$((skipped_count + 1))
    fi
    echo ""
  done < <(echo "$decisions_json" | jq -c '.[]')

  echo "Summary:"
  echo "  Total Items: $item_count"
  echo "  ${action_past}: $expanded_count"
  echo "  Skipped: $skipped_count"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
}

# review_plan_hierarchy: Analyze plan structure for optimization opportunities
# Args:
#   $1 - plan_path: Path to plan file or directory
#   $2 - operation_summary_json: JSON summary of recent operations
# Returns:
#   JSON with recommendations for hierarchy improvements
review_plan_hierarchy() {
  local plan_path="${1:-}"
  local operation_summary_json="${2:-}"

  if [[ -z "$plan_path" ]]; then
    echo "ERROR: review_plan_hierarchy requires plan_path" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Hierarchy Review: Analyzing Plan Organization" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Determine current structure level
  local current_level
  if [[ -d "$plan_path" ]]; then
    current_level=$(detect_structure_level "$plan_path")
  else
    current_level=$(detect_structure_level "$plan_path")
  fi

  echo "Current Structure Level: $current_level" >&2
  echo "" >&2

  # Extract plan context
  local main_plan
  if [[ -d "$plan_path" ]]; then
    main_plan=$(find "$plan_path" -maxdepth 1 -name "*.md" -type f | head -1)
  else
    main_plan="$plan_path"
  fi

  local overview goals
  overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -5 | tr '\n' ' ')
  goals=$(awk '/^## Success Criteria$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -5 | tr '\n' ' ')

  # Build context for agent
  local context_json
  context_json=$(jq -n \
    --arg overview "${overview:-No overview}" \
    --arg goals "${goals:-No goals}" \
    --arg level "$current_level" \
    --argjson operations "${operation_summary_json:-{}}" \
    '{
      plan_overview: $overview,
      plan_goals: $goals,
      current_level: $level,
      recent_operations: $operations
    }')

  # Build agent prompt for hierarchy review
  local agent_file="/home/benjamin/.config/.claude/agents/complexity-estimator.md"
  local agent_prompt
  agent_prompt=$(cat <<EOF
Read and follow the behavioral guidelines from:
$agent_file

You are acting as a Complexity Estimator with hierarchy review focus.

Hierarchy Review Task

Context:
- Plan path: $plan_path
- Current structure level: $current_level
- Recent operations: $(echo "$operation_summary_json" | jq -r 'if . == null then "None" else (.total // 0) | "Performed \(.) operations" end')

Plan Overview:
$(echo "$overview" | head -200)

Objective: Identify potential improvements in plan organization

Analyze the plan structure and recommend:
1. Phases that could be combined (overly granular)
2. Phases that should be split (still too complex)
3. Structural reorganization opportunities
4. Balance assessment (are operations at appropriate levels?)

Output Format: JSON object with:
{
  "overall_assessment": "Brief assessment of current hierarchy",
  "recommendations": [
    {
      "type": "combine" | "split" | "reorganize",
      "target": "phase_N" or "multiple",
      "reasoning": "Why this change would improve the plan",
      "confidence": "low" | "medium" | "high"
    }
  ],
  "balance_score": 1-10,
  "next_suggested_action": "expand" | "collapse" | "maintain"
}
EOF
)

  echo "Invoking complexity_estimator for hierarchy review..." >&2
  echo "" >&2
  echo "NOTE: Agent invocation must be done from command layer using Task tool" >&2
  echo "      This function returns the prompt to use" >&2
  echo "" >&2

  # Return prompt structure for command layer
  # In actual implementation, command layer invokes Task tool
  jq -n \
    --arg prompt "$agent_prompt" \
    --arg plan "$plan_path" \
    --arg level "$current_level" \
    '{
      agent_prompt: $prompt,
      plan_path: $plan,
      current_level: $level,
      mode: "hierarchy_review"
    }'
}

# run_second_round_analysis: Re-analyze plan after operations complete
# Args:
#   $1 - plan_path: Path to plan file or directory
#   $2 - initial_analysis_json: JSON from first round of analysis
# Returns:
#   JSON with second-round recommendations
run_second_round_analysis() {
  local plan_path="${1:-}"
  local initial_analysis_json="${2:-}"

  if [[ -z "$plan_path" ]]; then
    echo "ERROR: run_second_round_analysis requires plan_path" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Second-Round Analysis: Re-analyzing Plan" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Extract initial complexity scores if available
  local initial_scores=""
  if [[ -n "$initial_analysis_json" ]]; then
    initial_scores=$(echo "$initial_analysis_json" | jq -c '[.[] | {item_id, complexity_level}]')
    echo "Initial analysis included $(echo "$initial_scores" | jq 'length') items" >&2
  fi

  # Determine current structure level
  local current_level
  if [[ -d "$plan_path" ]]; then
    current_level=$(detect_structure_level "$plan_path")
  else
    current_level=$(detect_structure_level "$plan_path")
  fi

  echo "Current Structure Level: $current_level" >&2
  echo "" >&2

  # Re-analyze based on current structure level
  # Level 0: Analyze phases for expansion
  # Level 1: Analyze expanded phases for collapse + inline phases for expansion
  # Level 2: Analyze stages for collapse + inline stages for expansion

  local new_recommendations="{}"

  if [[ "$current_level" == "0" ]]; then
    echo "Analyzing inline phases for potential expansion..." >&2
    # Would call analyze_phases_for_expansion
    new_recommendations=$(jq -n \
      --arg mode "expansion" \
      --arg target "phases" \
      '{mode: $mode, target: $target, requires_agent_invocation: true}')

  elif [[ "$current_level" == "1" ]]; then
    echo "Analyzing both expanded and inline content..." >&2
    # Would call both analyze_phases_for_collapse and analyze_phases_for_expansion
    new_recommendations=$(jq -n \
      --arg mode "mixed" \
      --arg target "phases" \
      '{mode: $mode, target: $target, requires_agent_invocation: true}')

  elif [[ "$current_level" == "2" ]]; then
    echo "Analyzing stage-level structure..." >&2
    # Would call analyze_stages_for_collapse and analyze_stages_for_expansion
    new_recommendations=$(jq -n \
      --arg mode "mixed" \
      --arg target "stages" \
      '{mode: $mode, target: $target, requires_agent_invocation: true}')
  fi

  # Build comparison report
  local report
  report=$(jq -n \
    --argjson initial "${initial_scores:-[]}" \
    --argjson new "$new_recommendations" \
    --arg level "$current_level" \
    '{
      initial_analysis: $initial,
      current_level: $level,
      second_round: $new,
      comparison_available: ($initial | length > 0),
      recommendation: "Review changes and determine if further operations needed"
    }')

  echo "" >&2
  echo "Second-round analysis complete" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  echo "$report"
}

# present_recommendations_for_approval: Display recommendations to user
# Args:
#   $1 - recommendations_json: JSON array of recommendations
#   $2 - context: Description of what these recommendations are for
# Returns:
#   User approval decision (y/n) via exit code: 0=approved, 1=rejected
present_recommendations_for_approval() {
  local recommendations_json="${1:-}"
  local context="${2:-Recommendations}"

  if [[ -z "$recommendations_json" ]]; then
    echo "ERROR: present_recommendations_for_approval requires recommendations_json" >&2
    return 1
  fi

  # Parse recommendations
  local rec_count
  rec_count=$(echo "$recommendations_json" | jq 'length')

  if [[ $rec_count -eq 0 ]]; then
    echo "" >&2
    echo "No recommendations to approve" >&2
    return 0
  fi

  echo "" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "User Approval Required: $context" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2
  echo "The following recommendations have been generated:" >&2
  echo "" >&2

  # Display each recommendation
  local idx=1
  while IFS= read -r rec; do
    local rec_type target reasoning confidence
    rec_type=$(echo "$rec" | jq -r '.type // .recommendation // "action"')
    target=$(echo "$rec" | jq -r '.target // .item_id // "unknown"')
    reasoning=$(echo "$rec" | jq -r '.reasoning // "No reasoning provided"')
    confidence=$(echo "$rec" | jq -r '.confidence // "medium"')

    echo "  $idx. Action: $rec_type" >&2
    echo "     Target: $target" >&2
    echo "     Reasoning: $reasoning" >&2
    echo "     Confidence: $confidence" >&2
    echo "" >&2

    idx=$((idx + 1))
  done < <(echo "$recommendations_json" | jq -c '.[]')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Prompt for approval
  echo -n "Proceed with these recommendations? (y/n): " >&2
  read -r response

  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "" >&2
    echo "✓ Recommendations approved by user" >&2
    echo "" >&2

    # Log approval decision
    local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/approval-decisions.log"

    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] APPROVED: $context ($rec_count recommendations)" >> "$log_file"

    return 0
  else
    echo "" >&2
    echo "✗ Recommendations rejected by user" >&2
    echo "" >&2

    # Log rejection
    local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/approval-decisions.log"

    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] REJECTED: $context ($rec_count recommendations)" >> "$log_file"

    return 1
  fi
}

# generate_recommendations_report: Format analysis results as report
# Args:
#   $1 - plan_path: Path to plan file or directory
#   $2 - hierarchy_review_json: JSON from review_plan_hierarchy
#   $3 - second_round_json: JSON from run_second_round_analysis
#   $4 - operations_performed_json: JSON summary of operations executed
# Returns:
#   Path to generated report file
generate_recommendations_report() {
  local plan_path="${1:-}"
  local hierarchy_review_json="${2:-}"
  local second_round_json="${3:-}"
  local operations_performed_json="${4:-}"

  if [[ -z "$plan_path" ]]; then
    echo "ERROR: generate_recommendations_report requires plan_path" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Generating Recommendations Report" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Extract plan name
  local plan_name
  if [[ -d "$plan_path" ]]; then
    plan_name=$(basename "$plan_path")
  else
    plan_name=$(basename "$plan_path" .md)
  fi

  # Create report directory
  local report_dir="${CLAUDE_PROJECT_DIR}/specs/artifacts/${plan_name}"
  mkdir -p "$report_dir"

  local report_file="${report_dir}/recommendations.md"

  # Build report content
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  cat > "$report_file" <<EOF
# Recommendations Report: $plan_name

## Metadata
- **Generated**: $timestamp
- **Plan**: $plan_path
- **Structure Level**: $(detect_structure_level "$plan_path" 2>/dev/null || echo "0")

## Operations Performed

$(if [[ -n "$operations_performed_json" ]]; then
    echo "$operations_performed_json" | jq -r '
      "- **Total Operations**: \(.total // 0)\n" +
      "- **Successful**: \(.successful // 0)\n" +
      "- **Failed**: \(.failed // 0)\n"
    '
  else
    echo "No operations recorded"
  fi)

## Hierarchy Review

$(if [[ -n "$hierarchy_review_json" ]]; then
    echo "$hierarchy_review_json" | jq -r '
      if .overall_assessment then
        "### Overall Assessment\n\n" + .overall_assessment + "\n\n" +
        "### Balance Score: " + (.balance_score // "N/A" | tostring) + "/10\n\n" +
        "### Recommendations\n\n" +
        (if .recommendations and (.recommendations | length > 0) then
          (.recommendations | map(
            "- **\(.type | ascii_upcase)** \(.target)\n" +
            "  - Reasoning: \(.reasoning)\n" +
            "  - Confidence: \(.confidence)\n"
          ) | join("\n"))
        else
          "No specific recommendations"
        end)
      else
        "Hierarchy review not available"
      end
    '
  else
    echo "Hierarchy review not performed"
  fi)

## Second-Round Analysis

$(if [[ -n "$second_round_json" ]]; then
    echo "$second_round_json" | jq -r '
      "### Comparison\n\n" +
      (if .comparison_available then
        "Initial analysis included " + (.initial_analysis | length | tostring) + " items\n\n"
      else
        "No initial analysis for comparison\n\n"
      end) +
      "### Current Status\n\n" +
      "- **Structure Level**: " + .current_level + "\n" +
      "- **Recommendation**: " + .recommendation + "\n"
    '
  else
    echo "Second-round analysis not performed"
  fi)

## Next Steps

Based on the analysis above:

1. Review hierarchy recommendations and determine if structural changes are needed
2. Consider second-round analysis suggestions for further expansion/collapse
3. Verify that current structure matches complexity of implementation tasks
4. Run additional analysis if major changes have occurred

## Notes

This report provides guidance for optimizing plan structure. All recommendations
should be reviewed in context of actual implementation complexity and team needs.
EOF

  echo "Report saved to: $report_file" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  echo "$report_file"
}

# ==============================================================================
# Cross-Reference Management Functions
# ==============================================================================

# update_cross_references: Update cross-references between artifacts
# Args: $1 = artifact_path (the artifact being linked)
#       $2 = related_artifacts_json (JSON array of related artifacts)
# Returns: 0 on success
# Example: update_cross_references "specs/001_auth/plans/001_impl.md" '[{"type":"report","path":"specs/001_auth/reports/001_research.md"}]'
update_cross_references() {
  local artifact_path="${1:-}"
  local related_artifacts_json="${2:-[]}"

  if [ -z "$artifact_path" ]; then
    echo "Usage: update_cross_references <artifact-path> <related-artifacts-json>" >&2
    return 1
  fi

  if [ ! -f "$artifact_path" ]; then
    echo "Error: Artifact not found: $artifact_path" >&2
    return 1
  fi

  # Parse related artifacts
  if ! command -v jq &> /dev/null; then
    echo "Warning: jq not available, cannot update cross-references" >&2
    return 1
  fi

  local count
  count=$(echo "$related_artifacts_json" | jq 'length')

  if [ "$count" -eq 0 ]; then
    return 0
  fi

  # For each related artifact, add bidirectional reference
  while IFS= read -r related; do
    local related_type related_path
    related_type=$(echo "$related" | jq -r '.type')
    related_path=$(echo "$related" | jq -r '.path')

    if [ -f "$related_path" ]; then
      # Add reference to artifact if not already present
      if ! grep -q "$artifact_path" "$related_path" 2>/dev/null; then
        link_artifact_to_plan "$related_path" "$artifact_path" "$related_type"
      fi

      # Add reference from artifact to related if not already present
      if ! grep -q "$related_path" "$artifact_path" 2>/dev/null; then
        link_artifact_to_plan "$artifact_path" "$related_path" "$related_type"
      fi
    fi
  done < <(echo "$related_artifacts_json" | jq -c '.[]')

  return 0
}

# validate_gitignore_compliance: Verify gitignore compliance for topic directory
# Args: $1 = topic_dir path
# Returns: JSON validation report
# Example: validate_gitignore_compliance "specs/001_auth"
validate_gitignore_compliance() {
  local topic_dir="${1:-}"

  if [ -z "$topic_dir" ]; then
    echo "Usage: validate_gitignore_compliance <topic-dir>" >&2
    return 1
  fi

  if [ ! -d "$topic_dir" ]; then
    echo "{\"error\":\"Directory not found: $topic_dir\"}" >&2
    return 1
  fi

  # Check if debug/ subdirectory is NOT gitignored (should be committed)
  local debug_committed=true
  if [ -d "${topic_dir}/debug" ]; then
    if git check-ignore "${topic_dir}/debug" &> /dev/null; then
      debug_committed=false
    fi
  fi

  # Check if other subdirectories ARE gitignored
  local plans_ignored=true
  local reports_ignored=true
  local summaries_ignored=true
  local scripts_ignored=true

  [ -d "${topic_dir}/plans" ] && ! git check-ignore "${topic_dir}/plans" &> /dev/null && plans_ignored=false
  [ -d "${topic_dir}/reports" ] && ! git check-ignore "${topic_dir}/reports" &> /dev/null && reports_ignored=false
  [ -d "${topic_dir}/summaries" ] && ! git check-ignore "${topic_dir}/summaries" &> /dev/null && summaries_ignored=false
  [ -d "${topic_dir}/scripts" ] && ! git check-ignore "${topic_dir}/scripts" &> /dev/null && scripts_ignored=false

  # Build validation report
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson debug_ok "$debug_committed" \
      --argjson plans_ok "$plans_ignored" \
      --argjson reports_ok "$reports_ignored" \
      --argjson summaries_ok "$summaries_ignored" \
      --argjson scripts_ok "$scripts_ignored" \
      '{
        debug_committed: $debug_ok,
        plans_gitignored: $plans_ok,
        reports_gitignored: $reports_ok,
        summaries_gitignored: $summaries_ok,
        scripts_gitignored: $scripts_ok,
        compliant: ($debug_ok and $plans_ok and $reports_ok and $summaries_ok and $scripts_ok)
      }'
  else
    cat <<EOF
{
  "debug_committed": $debug_committed,
  "plans_gitignored": $plans_ignored,
  "reports_gitignored": $reports_ignored,
  "summaries_gitignored": $summaries_ignored,
  "scripts_gitignored": $scripts_ignored,
  "compliant": $([ "$debug_committed" = true ] && [ "$plans_ignored" = true ] && echo "true" || echo "false")
}
EOF
  fi
}

# link_artifact_to_plan: Add artifact reference to plan metadata
# Args: $1 = plan_path
#       $2 = artifact_path (artifact to link)
#       $3 = artifact_type (e.g., "report", "debug", "summary")
# Returns: 0 on success
# Example: link_artifact_to_plan "specs/001_auth/plans/001_impl.md" "specs/001_auth/reports/001_research.md" "report"
link_artifact_to_plan() {
  local plan_path="${1:-}"
  local artifact_path="${2:-}"
  local artifact_type="${3:-artifact}"

  if [ -z "$plan_path" ] || [ -z "$artifact_path" ]; then
    echo "Usage: link_artifact_to_plan <plan-path> <artifact-path> <type>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "Error: Plan not found: $plan_path" >&2
    return 1
  fi

  # Check if reference already exists
  if grep -q "$artifact_path" "$plan_path" 2>/dev/null; then
    return 0
  fi

  # Find metadata section and add reference
  local temp_file
  temp_file=$(mktemp)

  # Determine section name based on artifact type
  local section_name
  case "$artifact_type" in
    report)
      section_name="Research Reports"
      ;;
    debug)
      section_name="Debug Reports"
      ;;
    summary)
      section_name="Implementation Summary"
      ;;
    *)
      section_name="Related Artifacts"
      ;;
  esac

  # Add reference to metadata section or create new section
  awk -v artifact="$artifact_path" -v section="$section_name" '
    /^## Metadata/ {
      in_metadata = 1
      print
      next
    }
    /^##/ && in_metadata && !section_added {
      # End of metadata, add reference section before next heading
      print "- **" section "**: " artifact
      section_added = 1
      in_metadata = 0
      print
      next
    }
    { print }
  ' "$plan_path" > "$temp_file"

  if [ $? -eq 0 ]; then
    mv "$temp_file" "$plan_path"
    return 0
  else
    rm -f "$temp_file"
    echo "Error: Failed to add artifact reference" >&2
    return 1
  fi
}

# ==============================================================================
# Hierarchical Agent Context Preservation Functions
# ==============================================================================

# Metadata cache (associative array for in-memory caching)
declare -A METADATA_CACHE

# extract_report_metadata: Extract enhanced metadata from report
# Usage: extract_report_metadata <report-file-path>
# Returns: JSON with title, summary (50 words), file_paths, recommendations, path, size
# Example: extract_report_metadata "specs/042_auth/reports/001_patterns.md"
extract_report_metadata() {
  local report_path="${1:-}"

  if [ -z "$report_path" ]; then
    echo "Usage: extract_report_metadata <report-path>" >&2
    return 1
  fi

  if [ ! -f "$report_path" ]; then
    echo "{\"error\":\"File not found: $report_path\"}" >&2
    return 1
  fi

  # Extract title (first # heading)
  local title=$(head -100 "$report_path" | grep -m1 '^# ' | sed 's/^# //')

  # Extract 50-word summary from Executive Summary section or first paragraph
  local summary=""
  local exec_summary_section=$(get_report_section "$report_path" "Executive Summary" 2>/dev/null || echo "")

  if [ -n "$exec_summary_section" ]; then
    # Extract first paragraph from executive summary (non-heading, non-empty lines)
    summary=$(echo "$exec_summary_section" | grep -v '^#' | grep -v '^$' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50 && i<=NF;i++) printf "%s ", $i}')
  else
    # Fallback: first 50 words from content after title
    summary=$(head -200 "$report_path" | grep -v '^#' | grep -v '^-' | grep -v '^$' | head -5 | tr '\n' ' ' | awk '{for(i=1;i<=50 && i<=NF;i++) printf "%s ", $i}')
  fi

  # Extract key file paths mentioned (look for code blocks and inline code with paths)
  local file_paths=$(grep -E '`[^`]*\.(sh|md|js|py|lua|rs|go|java|rb)`|```.*\.(sh|md|js|py|lua|rs|go|java|rb)' "$report_path" | \
    grep -oE '[a-zA-Z0-9_/-]+\.(sh|md|js|py|lua|rs|go|java|rb)' | head -10 | jq -R -s -c 'split("\n") | map(select(length > 0))')

  # Extract 3-5 top recommendations (from Recommendations section)
  local recommendations=""
  local rec_section=$(get_report_section "$report_path" "Recommendations" 2>/dev/null || echo "")

  if [ -n "$rec_section" ]; then
    recommendations=$(echo "$rec_section" | grep '^-' | head -5 | sed 's/^- //' | jq -R -s -c 'split("\n") | map(select(length > 0))')
  else
    recommendations="[]"
  fi

  # Get file size
  local file_size=$(wc -c < "$report_path" | tr -d ' ')

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Report}" \
      --arg summary "${summary% }" \
      --argjson paths "${file_paths:-[]}" \
      --argjson recs "${recommendations}" \
      --arg path "$report_path" \
      --arg size "$file_size" \
      '{
        title: $title,
        summary: $summary,
        file_paths: $paths,
        recommendations: $recs,
        path: $path,
        size: ($size | tonumber)
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Report}",
  "summary": "${summary% }",
  "file_paths": ${file_paths:-[]},
  "recommendations": ${recommendations},
  "path": "$report_path",
  "size": $file_size
}
EOF
  fi
}

# extract_plan_metadata: Extract enhanced metadata from plan
# Usage: extract_plan_metadata <plan-file-path>
# Returns: JSON with title, date, phases, complexity, time_estimate, success_criteria, path, size
# Example: extract_plan_metadata "specs/042_auth/plans/001_implementation.md"
extract_plan_metadata() {
  local plan_path="${1:-}"

  if [ -z "$plan_path" ]; then
    echo "Usage: extract_plan_metadata <plan-path>" >&2
    return 1
  fi

  if [ ! -f "$plan_path" ]; then
    echo "{\"error\":\"File not found: $plan_path\"}" >&2
    return 1
  fi

  # Read metadata section (first 50 lines)
  local metadata_lines=$(head -50 "$plan_path")

  # Extract title (first # heading)
  local title=$(echo "$metadata_lines" | grep -m1 '^# ' | sed 's/^# //')

  # Extract date from metadata
  local date=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Date\*\*:' | sed 's/.*Date\*\*:\s*//')

  # Count phases
  local phases=$(grep -E '^##+ Phase [0-9]' "$plan_path" 2>/dev/null | wc -l)
  phases=${phases// /}

  # Extract complexity assessment (from Risk field in phases or overall complexity)
  local complexity="Unknown"
  local risk_line=$(grep -m1 '^\*\*Risk\*\*:' "$plan_path" || echo "")
  if [ -n "$risk_line" ]; then
    complexity=$(echo "$risk_line" | sed 's/.*Risk\*\*:\s*//' | awk '{print $1}')
  fi

  # Extract estimated time (from Estimated Time or Estimated Phases metadata)
  local time_estimate=$(echo "$metadata_lines" | grep -m1 '^\s*-\s*\*\*Estimated.*\*\*:' | sed 's/.*Estimated.*\*\*:\s*//')

  # Count success criteria checkboxes
  local success_criteria=$(grep -c '^\s*-\s*\[[ x]\]' "$plan_path" || echo "0")

  # Get file size
  local file_size=$(wc -c < "$plan_path" | tr -d ' ')

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg title "${title:-Unknown Plan}" \
      --arg date "${date:-Unknown}" \
      --arg phases "$phases" \
      --arg complexity "$complexity" \
      --arg time "${time_estimate:-Unknown}" \
      --arg criteria "$success_criteria" \
      --arg path "$plan_path" \
      --arg size "$file_size" \
      '{
        title: $title,
        date: $date,
        phases: ($phases | tonumber),
        complexity: $complexity,
        time_estimate: $time,
        success_criteria: ($criteria | tonumber),
        path: $path,
        size: ($size | tonumber)
      }'
  else
    cat <<EOF
{
  "title": "${title:-Unknown Plan}",
  "date": "${date:-Unknown}",
  "phases": $phases,
  "complexity": "$complexity",
  "time_estimate": "${time_estimate:-Unknown}",
  "success_criteria": $success_criteria,
  "path": "$plan_path",
  "size": $file_size
}
EOF
  fi
}

# extract_summary_metadata: Extract metadata from implementation summary
# Usage: extract_summary_metadata <summary-file-path>
# Returns: JSON with workflow_type, artifacts_count, tests_passing, performance, path, size
# Example: extract_summary_metadata "specs/042_auth/summaries/001_implementation_summary.md"
extract_summary_metadata() {
  local summary_path="${1:-}"

  if [ -z "$summary_path" ]; then
    echo "Usage: extract_summary_metadata <summary-path>" >&2
    return 1
  fi

  if [ ! -f "$summary_path" ]; then
    echo "{\"error\":\"File not found: $summary_path\"}" >&2
    return 1
  fi

  # Read first 100 lines for metadata
  local content=$(head -100 "$summary_path")

  # Extract workflow type (from Metadata or title)
  local workflow_type="Unknown"
  local workflow_line=$(echo "$content" | grep -m1 '^\s*-\s*\*\*Workflow\*\*:' || echo "")
  if [ -n "$workflow_line" ]; then
    workflow_type=$(echo "$workflow_line" | sed 's/.*Workflow\*\*:\s*//')
  fi

  # Count artifacts generated (plans, reports, debug reports mentioned)
  local artifacts_count=$(grep -cE '(specs/.*\.md|Created.*:.*specs/)' "$summary_path" || echo "0")

  # Extract test status
  local tests_passing="Unknown"
  local test_line=$(echo "$content" | grep -m1 -i 'test.*pass\|pass.*test\|all tests' || echo "")
  if echo "$test_line" | grep -qi 'pass'; then
    tests_passing="true"
  elif echo "$test_line" | grep -qi 'fail'; then
    tests_passing="false"
  fi

  # Extract performance metrics (time saved, parallel effectiveness)
  local performance="Unknown"
  local perf_line=$(echo "$content" | grep -m1 -iE 'time saved|performance|parallel.*%|reduction.*%' || echo "")
  if [ -n "$perf_line" ]; then
    performance=$(echo "$perf_line" | sed 's/^[^:]*:\s*//' | head -c 100)
  fi

  # Get file size
  local file_size=$(wc -c < "$summary_path" | tr -d ' ')

  # Build JSON
  if command -v jq &> /dev/null; then
    jq -n \
      --arg type "$workflow_type" \
      --arg count "$artifacts_count" \
      --arg tests "$tests_passing" \
      --arg perf "$performance" \
      --arg path "$summary_path" \
      --arg size "$file_size" \
      '{
        workflow_type: $type,
        artifacts_count: ($count | tonumber),
        tests_passing: $tests,
        performance: $perf,
        path: $path,
        size: ($size | tonumber)
      }'
  else
    cat <<EOF
{
  "workflow_type": "$workflow_type",
  "artifacts_count": $artifacts_count,
  "tests_passing": "$tests_passing",
  "performance": "$performance",
  "path": "$summary_path",
  "size": $file_size
}
EOF
  fi
}

# load_metadata_on_demand: Load artifact metadata by path with caching
# Usage: load_metadata_on_demand <artifact-path>
# Returns: Cached or freshly extracted metadata JSON
# Example: load_metadata_on_demand "specs/042_auth/reports/001_patterns.md"
load_metadata_on_demand() {
  local artifact_path="${1:-}"

  if [ -z "$artifact_path" ]; then
    echo "Usage: load_metadata_on_demand <artifact-path>" >&2
    return 1
  fi

  # Check cache first
  local cached=$(get_cached_metadata "$artifact_path")
  if [ -n "$cached" ]; then
    echo "$cached"
    return 0
  fi

  # Determine artifact type from path
  local artifact_type="unknown"
  if [[ "$artifact_path" == */reports/* ]]; then
    artifact_type="report"
  elif [[ "$artifact_path" == */plans/* ]]; then
    artifact_type="plan"
  elif [[ "$artifact_path" == */summaries/* ]]; then
    artifact_type="summary"
  fi

  # Extract metadata based on type
  local metadata=""
  case "$artifact_type" in
    report)
      metadata=$(extract_report_metadata "$artifact_path")
      ;;
    plan)
      metadata=$(extract_plan_metadata "$artifact_path")
      ;;
    summary)
      metadata=$(extract_summary_metadata "$artifact_path")
      ;;
    *)
      echo "{\"error\":\"Unknown artifact type for: $artifact_path\"}" >&2
      return 1
      ;;
  esac

  # Cache metadata
  if [ -n "$metadata" ]; then
    cache_metadata "$artifact_path" "$metadata"
  fi

  echo "$metadata"
}

# cache_metadata: Store metadata in cache
# Usage: cache_metadata <artifact-path> <metadata-json>
# Returns: 0 on success
cache_metadata() {
  local artifact_path="${1:-}"
  local metadata_json="${2:-}"

  if [ -z "$artifact_path" ] || [ -z "$metadata_json" ]; then
    return 1
  fi

  METADATA_CACHE["$artifact_path"]="$metadata_json"
  return 0
}

# get_cached_metadata: Retrieve metadata from cache
# Usage: get_cached_metadata <artifact-path>
# Returns: Cached metadata JSON or empty string
get_cached_metadata() {
  local artifact_path="${1:-}"

  if [ -z "$artifact_path" ]; then
    return 1
  fi

  echo "${METADATA_CACHE[$artifact_path]:-}"
}

# clear_metadata_cache: Clear all cached metadata
# Usage: clear_metadata_cache
# Returns: 0 on success
clear_metadata_cache() {
  METADATA_CACHE=()
  return 0
}

# ==============================================================================
# Forward Message Pattern (Context Preservation)
# ==============================================================================

# forward_message: Pass subagent response to next phase without re-summarization
# Usage: forward_message <subagent-output>
# Returns: JSON with structured handoff context
# Example: forward_message "$research_agent_output"
forward_message() {
  local subagent_output="${1:-}"

  if [ -z "$subagent_output" ]; then
    echo "Usage: forward_message <subagent-output>" >&2
    return 1
  fi

  # Parse subagent output for artifact paths
  local artifact_paths=$(echo "$subagent_output" | grep -oE 'specs/[^[:space:]]+\.md' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')

  # Extract status indicators
  local status="unknown"
  if echo "$subagent_output" | grep -qi 'success\|complete'; then
    status="success"
  elif echo "$subagent_output" | grep -qi 'fail\|error'; then
    status="failed"
  fi

  # Extract metadata blocks (JSON or YAML in code blocks)
  local metadata_blocks=$(echo "$subagent_output" | sed -n '/```json/,/```/p' | grep -v '```' || echo "{}")

  # Build summary (first 100 words of subagent output)
  local summary=$(echo "$subagent_output" | tr '\n' ' ' | awk '{for(i=1;i<=100 && i<=NF;i++) printf "%s ", $i}')

  # Build structured handoff
  local handoff_context=""
  if command -v jq &> /dev/null && [ -n "$artifact_paths" ] && [ "$artifact_paths" != "[]" ]; then
    # Extract metadata for each artifact
    local artifacts_with_metadata="[]"
    while IFS= read -r artifact_path; do
      if [ -f "$artifact_path" ]; then
        local metadata=$(load_metadata_on_demand "$artifact_path" 2>/dev/null || echo '{"error":"metadata_unavailable"}')
        # Only add if metadata is valid JSON
        if echo "$metadata" | jq -e . >/dev/null 2>&1; then
          artifacts_with_metadata=$(echo "$artifacts_with_metadata" | jq \
            --arg path "$artifact_path" \
            --argjson meta "$metadata" \
            '. += [{path: $path, metadata: $meta}]')
        else
          # Add with minimal metadata if extraction failed
          artifacts_with_metadata=$(echo "$artifacts_with_metadata" | jq \
            --arg path "$artifact_path" \
            '. += [{path: $path, metadata: {}}]')
        fi
      fi
    done < <(echo "$artifact_paths" | jq -r '.[]')

    handoff_context=$(jq -n \
      --arg phase "unknown" \
      --argjson artifacts "$artifacts_with_metadata" \
      --arg summary "${summary% }" \
      --arg status "$status" \
      '{
        phase_complete: $phase,
        artifacts: $artifacts,
        summary: $summary,
        status: $status,
        next_phase_reads: ($artifacts | map(.path))
      }')
  else
    # Fallback without artifact metadata
    handoff_context=$(jq -n \
      --arg summary "$(echo "$subagent_output" | tr '\n' ' ' | head -c 200)" \
      --arg status "$status" \
      '{
        phase_complete: "unknown",
        artifacts: [],
        summary: $summary,
        status: $status,
        next_phase_reads: []
      }')
  fi

  # Log original subagent output
  local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
  mkdir -p "$log_dir"
  local log_file="$log_dir/subagent-outputs.log"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUBAGENT OUTPUT:" >> "$log_file"
  echo "$subagent_output" >> "$log_file"
  echo "---" >> "$log_file"

  # Log handoff context
  local handoff_log="$log_dir/phase-handoffs.log"
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] PHASE HANDOFF:" >> "$handoff_log"
  echo "$handoff_context" | jq '.' >> "$handoff_log" 2>/dev/null || echo "$handoff_context" >> "$handoff_log"
  echo "---" >> "$handoff_log"

  # Enable log rotation (10MB max, 5 files)
  for log in "$log_file" "$handoff_log"; do
    if [ -f "$log" ] && [ $(wc -c < "$log") -gt 10485760 ]; then
      # Rotate logs
      for i in {4..1}; do
        [ -f "${log}.$i" ] && mv "${log}.$i" "${log}.$((i+1))"
      done
      mv "$log" "${log}.1"
      touch "$log"
    fi
  done

  echo "$handoff_context"
}

# parse_subagent_response: Extract structured data from subagent output
# Usage: parse_subagent_response <subagent-output>
# Returns: JSON with artifact paths, status, metadata
# Example: parse_subagent_response "$agent_response"
parse_subagent_response() {
  local subagent_output="${1:-}"

  if [ -z "$subagent_output" ]; then
    echo "Usage: parse_subagent_response <subagent-output>" >&2
    return 1
  fi

  # Extract artifact paths (markdown files in specs/)
  local artifact_paths=$(echo "$subagent_output" | grep -oE 'specs/[^[:space:]]+\.md' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')

  # Extract status indicators
  local status="unknown"
  if echo "$subagent_output" | grep -qi 'success\|complete\|done'; then
    status="success"
  elif echo "$subagent_output" | grep -qi 'fail\|error'; then
    status="failed"
  elif echo "$subagent_output" | grep -qi 'in progress\|working'; then
    status="in_progress"
  fi

  # Extract JSON metadata blocks
  local metadata_blocks=$(echo "$subagent_output" | sed -n '/```json/,/```/p' | sed '1d;$d' || echo "{}")

  # Build response object
  if command -v jq &> /dev/null; then
    jq -n \
      --argjson paths "${artifact_paths:-[]}" \
      --arg status "$status" \
      --argjson meta "${metadata_blocks:-{}}" \
      '{
        artifact_paths: $paths,
        status: $status,
        metadata: $meta
      }'
  else
    cat <<EOF
{
  "artifact_paths": ${artifact_paths:-[]},
  "status": "$status",
  "metadata": ${metadata_blocks:-{}}
}
EOF
  fi
}

# build_handoff_context: Build context for next phase
# Usage: build_handoff_context <phase-name> <artifacts-json> <summary>
# Returns: JSON handoff context
# Example: build_handoff_context "research" "$artifacts" "Research complete"
build_handoff_context() {
  local phase_name="${1:-unknown}"
  local artifacts_json="${2:-[]}"
  local summary="${3:-No summary provided}"

  # Limit summary to 100 words
  local summary_limited=$(echo "$summary" | tr '\n' ' ' | awk '{for(i=1;i<=100 && i<=NF;i++) printf "%s ", $i}')

  if command -v jq &> /dev/null; then
    jq -n \
      --arg phase "$phase_name" \
      --argjson artifacts "$artifacts_json" \
      --arg summary "${summary_limited% }" \
      '{
        phase_complete: $phase,
        artifacts: $artifacts,
        summary: $summary,
        next_phase_reads: ($artifacts | map(.path))
      }'
  else
    cat <<EOF
{
  "phase_complete": "$phase_name",
  "artifacts": $artifacts_json,
  "summary": "${summary_limited% }",
  "next_phase_reads": []
}
EOF
  fi
}

# ==============================================================================
# Recursive Supervision Support
# ==============================================================================

# Supervision depth tracking (global variable)
SUPERVISION_DEPTH=${SUPERVISION_DEPTH:-0}
MAX_SUPERVISION_DEPTH=3

# invoke_sub_supervisor: Invoke sub-supervisor for complex multi-level workflows
# Usage: invoke_sub_supervisor <task-domain> <subagent-count> <task-list-json> [max-words]
# Returns: JSON with summary and artifact metadata
# Example: invoke_sub_supervisor "security_research" 2 '[{"task":"Auth patterns"},{"task":"Security practices"}]' 100
invoke_sub_supervisor() {
  local task_domain="${1:-}"
  local subagent_count="${2:-2}"
  local task_list_json="${3:-[]}"
  local max_words="${4:-100}"

  if [ -z "$task_domain" ]; then
    echo "Usage: invoke_sub_supervisor <task-domain> <subagent-count> <task-list-json> [max-words]" >&2
    return 1
  fi

  # Check depth limit
  SUPERVISION_DEPTH=$((SUPERVISION_DEPTH + 1))
  if [ "$SUPERVISION_DEPTH" -gt "$MAX_SUPERVISION_DEPTH" ]; then
    echo "{\"error\":\"Maximum supervision depth ($MAX_SUPERVISION_DEPTH) exceeded\"}" >&2
    SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
    return 1
  fi

  # Load sub-supervisor template
  local template_file="${CLAUDE_PROJECT_DIR}/.claude/templates/sub_supervisor_pattern.md"
  if [ ! -f "$template_file" ]; then
    echo "{\"error\":\"Sub-supervisor template not found: $template_file\"}" >&2
    SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
    return 1
  fi

  # Convert task list JSON to numbered list
  local task_list=""
  if command -v jq &> /dev/null; then
    local idx=1
    while IFS= read -r task; do
      if [ -n "$task" ]; then
        task_list="${task_list}${idx}. ${task}"$'\n'
        idx=$((idx + 1))
      fi
    done < <(echo "$task_list_json" | jq -r '.[] | .task')
  fi

  # Build sub-supervisor prompt from template (use awk to avoid sed multiline issues)
  local sub_supervisor_prompt=$(cat "$template_file" | awk \
    -v n="$subagent_count" \
    -v domain="$task_domain" \
    -v words="$max_words" \
    -v tasks="$task_list" \
    '{
      gsub(/{N}/, n);
      gsub(/{task_domain}/, domain);
      gsub(/{max_words}/, words);
      if (/{task_list}/) {
        sub(/{task_list}/, tasks);
      }
      print
    }')

  # Log sub-supervisor invocation
  local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
  mkdir -p "$log_dir"
  local supervision_log="$log_dir/supervision-tree.log"

  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] SUB-SUPERVISOR INVOKED:" >> "$supervision_log"
  echo "  Domain: $task_domain" >> "$supervision_log"
  echo "  Depth: $SUPERVISION_DEPTH" >> "$supervision_log"
  echo "  Subagent Count: $subagent_count" >> "$supervision_log"
  echo "---" >> "$supervision_log"

  # Note: Actual agent invocation must be done by command layer using Task tool
  # This function prepares the prompt and returns invocation metadata

  local invocation_metadata=$(jq -n \
    --arg prompt "$sub_supervisor_prompt" \
    --arg domain "$task_domain" \
    --arg depth "$SUPERVISION_DEPTH" \
    --arg count "$subagent_count" \
    '{
      sub_supervisor_prompt: $prompt,
      task_domain: $domain,
      supervision_depth: ($depth | tonumber),
      subagent_count: ($count | tonumber),
      requires_agent_invocation: true
    }')

  # Decrement depth when returning (will be incremented again if sub-supervisor invokes another)
  SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))

  echo "$invocation_metadata"
}

# track_supervision_depth: Track and validate supervision depth
# Usage: track_supervision_depth <operation>
# Operations: increment, decrement, reset, check
# Example: track_supervision_depth increment
track_supervision_depth() {
  local operation="${1:-check}"

  case "$operation" in
    increment)
      SUPERVISION_DEPTH=$((SUPERVISION_DEPTH + 1))
      if [ "$SUPERVISION_DEPTH" -gt "$MAX_SUPERVISION_DEPTH" ]; then
        echo "ERROR: Maximum supervision depth ($MAX_SUPERVISION_DEPTH) exceeded" >&2
        SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
        return 1
      fi
      echo "$SUPERVISION_DEPTH"
      ;;
    decrement)
      if [ "$SUPERVISION_DEPTH" -gt 0 ]; then
        SUPERVISION_DEPTH=$((SUPERVISION_DEPTH - 1))
      fi
      echo "$SUPERVISION_DEPTH"
      ;;
    reset)
      SUPERVISION_DEPTH=0
      echo "$SUPERVISION_DEPTH"
      ;;
    check)
      echo "$SUPERVISION_DEPTH"
      ;;
    *)
      echo "Usage: track_supervision_depth <increment|decrement|reset|check>" >&2
      return 1
      ;;
  esac
}

# generate_supervision_tree: Generate ASCII tree showing supervisor hierarchy
# Usage: generate_supervision_tree <workflow-state-json>
# Returns: ASCII tree visualization
# Example: generate_supervision_tree "$workflow_state"
generate_supervision_tree() {
  local workflow_state_json="${1:-{}}"

  if [ -z "$workflow_state_json" ] || [ "$workflow_state_json" = "{}" ]; then
    echo "No supervision hierarchy to display"
    return 0
  fi

  # Parse workflow state for supervision structure
  local tree_output="Orchestrator\n"

  if command -v jq &> /dev/null; then
    # Extract supervisor information
    local supervisor_count=$(echo "$workflow_state_json" | jq -r '.supervisors | length' 2>/dev/null | tr -d '\n' || echo "0")
    supervisor_count=${supervisor_count:-0}

    if [ "$supervisor_count" -gt 0 ]; then
      local idx=0
      while [ "$idx" -lt "$supervisor_count" ]; do
        local supervisor_name=$(echo "$workflow_state_json" | jq -r ".supervisors[$idx].name" 2>/dev/null || echo "Unknown")
        local subagent_count=$(echo "$workflow_state_json" | jq ".supervisors[$idx].subagents | length" 2>/dev/null || echo "0")

        # Determine tree connector
        local connector="├──"
        if [ "$idx" -eq $((supervisor_count - 1)) ]; then
          connector="└──"
        fi

        tree_output="${tree_output}${connector} ${supervisor_name} (${subagent_count} subagents)\n"

        # Add subagents
        if [ "$subagent_count" -gt 0 ]; then
          local sub_idx=0
          while [ "$sub_idx" -lt "$subagent_count" ]; do
            local agent_name=$(echo "$workflow_state_json" | jq -r ".supervisors[$idx].subagents[$sub_idx].name" 2>/dev/null || echo "Agent")
            local artifact_path=$(echo "$workflow_state_json" | jq -r ".supervisors[$idx].subagents[$sub_idx].artifact" 2>/dev/null || echo "")

            local sub_connector="│   ├──"
            if [ "$sub_idx" -eq $((subagent_count - 1)) ]; then
              sub_connector="│   └──"
            fi
            if [ "$idx" -eq $((supervisor_count - 1)) ]; then
              sub_connector="    ${sub_connector:4}"
            fi

            tree_output="${tree_output}${sub_connector} ${agent_name}"
            if [ -n "$artifact_path" ] && [ "$artifact_path" != "null" ]; then
              tree_output="${tree_output} → ${artifact_path}\n"
            else
              tree_output="${tree_output}\n"
            fi

            sub_idx=$((sub_idx + 1))
          done
        fi

        idx=$((idx + 1))
      done
    fi
  fi

  echo -e "$tree_output"
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  # Registry functions
  export -f register_artifact
  export -f query_artifacts
  export -f update_artifact_status
  export -f cleanup_artifacts
  export -f validate_artifact_references
  export -f list_artifacts
  export -f get_artifact_path_by_id

  # Metadata extraction functions
  export -f get_plan_metadata
  export -f get_report_metadata
  export -f get_plan_phase
  export -f get_plan_section
  export -f get_report_section

  # Artifact creation functions
  export -f create_topic_artifact
  export -f create_artifact_directory
  export -f create_artifact_directory_with_workflow
  export -f get_next_artifact_number
  export -f write_artifact_file
  export -f generate_artifact_invocation

  # Operation tracking functions
  export -f register_operation_artifact
  export -f get_artifact_path
  export -f validate_operation_artifacts

  # Parallel operation functions
  export -f save_operation_artifact
  export -f load_artifact_references
  export -f cleanup_operation_artifacts
  export -f cleanup_topic_artifacts
  export -f cleanup_all_temp_artifacts

  # Report generation functions
  export -f generate_analysis_report
  export -f review_plan_hierarchy
  export -f run_second_round_analysis
  export -f present_recommendations_for_approval
  export -f generate_recommendations_report

  # Cross-reference management functions
  export -f update_cross_references
  export -f validate_gitignore_compliance
  export -f link_artifact_to_plan

  # Hierarchical agent context preservation functions
  export -f extract_report_metadata
  export -f extract_plan_metadata
  export -f extract_summary_metadata
  export -f load_metadata_on_demand
  export -f cache_metadata
  export -f get_cached_metadata
  export -f clear_metadata_cache

  # Forward message pattern functions
  export -f forward_message
  export -f parse_subagent_response
  export -f build_handoff_context

  # Recursive supervision functions
  export -f invoke_sub_supervisor
  export -f track_supervision_depth
  export -f generate_supervision_tree
fi
