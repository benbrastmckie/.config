#!/usr/bin/env bash
# Artifact Cross Reference
# Extracted from artifact-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"

# Functions:

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

# Export functions
export -f update_cross_references
export -f validate_gitignore_compliance
export -f link_artifact_to_plan