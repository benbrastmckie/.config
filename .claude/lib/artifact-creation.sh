#!/usr/bin/env bash
# Artifact Creation
# Extracted from artifact-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"
source "${SCRIPT_DIR}/artifact-registry.sh"

# Functions:

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
  # Artifact types and gitignore behavior:
  # - debug: Committed to git (contains diagnostic info worth preserving)
  # - reports, plans: Gitignored (ephemeral research/planning artifacts)
  # - scripts, outputs, artifacts, backups, data, logs, notes: Gitignored
  case "$artifact_type" in
    debug|scripts|outputs|artifacts|backups|data|logs|notes|reports|plans)
      ;;
    *)
      echo "Error: Invalid artifact type '$artifact_type'" >&2
      echo "Valid types: debug, scripts, outputs, artifacts, backups, data, logs, notes, reports, plans" >&2
      return 1
      ;;
  esac

  # Artifact subdirectory path
  local artifact_subdir="${CLAUDE_PROJECT_DIR}/${topic_dir}/${artifact_type}"

  # PATH-ONLY MODE: Calculate path without creating directory (lazy creation)
  # This mode is used when commands need to pre-calculate paths (e.g., /orchestrate)
  # without creating empty directories. Directories are created later when files are written.
  if [ -z "$content" ]; then
    # Get next artifact number without creating directory
    local next_num=$(get_next_artifact_number "$artifact_subdir" || echo "001")

    # Return formatted path without creating directory or file
    local artifact_file="${artifact_subdir}/${next_num}_${artifact_name}.md"
    echo "$artifact_file"
    return 0
  fi

  # FILE CREATION MODE: Create directory and file (original behavior)
  # This mode is used when commands are ready to write actual content
  mkdir -p "$artifact_subdir"

  # Get next artifact number
  local next_num=$(get_next_artifact_number "$artifact_subdir")

  # Create artifact file path
  local artifact_file="${artifact_subdir}/${next_num}_${artifact_name}.md"

  # Write content to file
  echo "$content" > "$artifact_file"

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

# Export functions
export -f create_topic_artifact
export -f create_artifact_directory
export -f create_artifact_directory_with_workflow
export -f get_next_artifact_number
export -f write_artifact_file
export -f generate_artifact_invocation