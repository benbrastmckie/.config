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
  local metadata_json="${3:-{}}"

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
  export -f register_artifact
  export -f query_artifacts
  export -f update_artifact_status
  export -f cleanup_artifacts
  export -f validate_artifact_references
  export -f list_artifacts
  export -f get_artifact_path
fi
