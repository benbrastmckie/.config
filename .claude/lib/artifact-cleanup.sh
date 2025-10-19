#!/usr/bin/env bash
# Artifact Cleanup
# Extracted from artifact-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"

# Functions:

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

# Export functions
export -f cleanup_all_temp_artifacts
export -f cleanup_operation_artifacts
export -f cleanup_topic_artifacts
export -f save_operation_artifact
export -f load_artifact_references