#!/usr/bin/env bash
# Shared artifact registry utilities
# Provides functions for registering and querying implementation artifacts

set -euo pipefail

# ==============================================================================
# Constants
# ==============================================================================

# Artifact types
readonly ARTIFACT_TYPE_PLAN="plan"
readonly ARTIFACT_TYPE_REPORT="report"
readonly ARTIFACT_TYPE_SUMMARY="summary"
readonly ARTIFACT_TYPE_CHECKPOINT="checkpoint"

# Registry directory
readonly ARTIFACT_REGISTRY_DIR="${CLAUDE_PROJECT_DIR}/.claude/registry"

# ==============================================================================
# Core Functions
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

# create_artifact_directory: Create artifact directory with topic-based naming
# Usage: create_artifact_directory <workflow-description>
# Returns: project_name artifact_dir next_number
# Example: create_artifact_directory "Implement user authentication"
create_artifact_directory() {
  local workflow_description="${1:-}"

  if [ -z "$workflow_description" ]; then
    echo "Usage: create_artifact_directory <workflow-description>" >&2
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
      (( num > max_num )) && max_num=$num
    fi
  done

  # Return next number with zero-padding
  printf "%03d" $((max_num + 1))
}

# write_artifact_file: Write artifact with variable-length content (fallback)
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

# generate_artifact_invocation: Generate research agent artifact invocation prompt
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
# Convenience Functions
# ==============================================================================

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

# get_artifact_path: Get path for artifact by ID
# Usage: get_artifact_path <artifact-id>
# Returns: Artifact path
# Example: get_artifact_path "plan_auth_20251006"
get_artifact_path() {
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
  export -f get_artifact_path

  # Artifact creation functions
  export -f create_artifact_directory
  export -f get_next_artifact_number
  export -f write_artifact_file
  export -f generate_artifact_invocation

  # Metadata extraction functions (context optimization)
  export -f get_plan_metadata
  export -f get_report_metadata
  export -f get_plan_phase
  export -f get_plan_section
  export -f get_report_section
fi
