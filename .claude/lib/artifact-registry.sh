#!/usr/bin/env bash
# Artifact Registry
# Artifact tracking and querying

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"

# Configuration
readonly ARTIFACT_REGISTRY_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/data/registry"

# Functions:

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

# create_artifact_directory: Create artifact directory from plan path
# Usage: create_artifact_directory <plan-path>
# Returns: artifact_dir path
# Example: create_artifact_directory "specs/plans/001_feature.md"
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

# Export functions
export -f register_artifact
export -f query_artifacts
export -f update_artifact_status
export -f cleanup_artifacts
export -f validate_artifact_references
export -f list_artifacts
export -f get_artifact_path_by_id
export -f register_operation_artifact
export -f get_artifact_path
export -f validate_operation_artifacts
export -f create_artifact_directory