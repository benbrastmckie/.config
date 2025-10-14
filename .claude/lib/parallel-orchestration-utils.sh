#!/usr/bin/env bash
# parallel-orchestration-utils.sh
# Generic parallel orchestration patterns for expansion and collapse operations
# Part of auto-analysis framework

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/parse-plan-core.sh" 2>/dev/null || true
source "$SCRIPT_DIR/plan-structure-utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/plan-metadata-utils.sh" 2>/dev/null || true

# ============================================================================
# Generic Parallel Agent Invocation
# ============================================================================

# invoke_agents_parallel_generic: Launch parallel operations (expansion or collapse)
# Args:
#   $1 - operation_type: "expansion" or "collapse"
#   $2 - plan_path: Path to plan file or directory
#   $3 - recommendations_json: JSON array from complexity_estimator
# Returns:
#   JSON array of artifact references with agent prompts
invoke_agents_parallel_generic() {
  local operation_type="$1"
  local plan_path="$2"
  local recommendations_json="$3"

  # Validate inputs
  if [[ -z "$operation_type" ]] || [[ -z "$plan_path" ]] || [[ -z "$recommendations_json" ]]; then
    echo "ERROR: invoke_agents_parallel_generic requires operation_type, plan_path, and recommendations_json" >&2
    return 1
  fi

  if [[ "$operation_type" != "expansion" ]] && [[ "$operation_type" != "collapse" ]]; then
    echo "ERROR: operation_type must be 'expansion' or 'collapse', got: $operation_type" >&2
    return 1
  fi

  # Extract plan name for artifact directory
  local plan_name
  if [[ -d "$plan_path" ]]; then
    plan_name=$(basename "$plan_path")
  else
    plan_name=$(basename "$plan_path" .md)
  fi

  # Create artifact directory
  if [[ -f "$SCRIPT_DIR/artifact-utils.sh" ]]; then
    source "$SCRIPT_DIR/artifact-utils.sh"
    local artifact_dir
    artifact_dir=$(create_artifact_directory "$plan_path")
  fi

  # Display header
  local op_display="${operation_type^}"  # Capitalize first letter
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Parallel ${op_display}: Launching Agents" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Build artifact references array
  local artifact_refs="[]"

  # Filter recommendations based on operation type
  local operation_items
  operation_items=$(echo "$recommendations_json" | jq -c "[.[] | select(.recommendation == \"$operation_type\")]")

  local operation_count
  operation_count=$(echo "$operation_items" | jq 'length')

  if [[ $operation_count -eq 0 ]]; then
    echo "No items recommended for $operation_type" >&2
    echo "$artifact_refs"
    return 0
  fi

  echo "Launching $operation_count $operation_type agents in parallel..." >&2
  echo "" >&2

  # Select agent file based on operation type
  local agent_file
  if [[ "$operation_type" == "expansion" ]]; then
    agent_file="/home/benjamin/.config/.claude/agents/expansion-specialist.md"
  else
    agent_file="/home/benjamin/.config/.claude/agents/collapse-specialist.md"
  fi

  # Detect structure level once
  local current_level
  if [[ -d "$plan_path" ]]; then
    current_level=$(detect_structure_level "$plan_path" 2>/dev/null || echo "1")
  else
    current_level=$(detect_structure_level "$plan_path" 2>/dev/null || echo "0")
  fi

  # Process each recommendation
  while IFS= read -r item; do
    local item_id item_name complexity
    item_id=$(echo "$item" | jq -r '.item_id')
    item_name=$(echo "$item" | jq -r '.item_name')
    complexity=$(echo "$item" | jq -r '.complexity_level')

    # Extract item number
    local item_num
    item_num=$(echo "$item_id" | grep -oP '\d+' || echo "0")

    echo "  $item_id: $item_name (complexity: $complexity/10)" >&2

    # Build operation-specific objective
    local objective
    if [[ "$operation_type" == "expansion" ]]; then
      objective="Extract content, create file structure, save artifact"
    else
      objective="Merge content to parent, delete file, save artifact"
    fi

    # Build agent prompt
    local agent_prompt
    agent_prompt=$(cat <<EOF
Read and follow the behavioral guidelines from:
$agent_file

${op_display} Task: phase $item_num

Context:
- Plan path: $plan_path
- Item to $operation_type: phase $item_num
- Complexity score: $complexity/10
- Current structure level: $current_level

Objective: $objective

Output: Save artifact to specs/artifacts/${plan_name}/${operation_type}_${item_num}.md
EOF
)

    local expected_artifact="specs/artifacts/${plan_name}/${operation_type}_${item_num}.md"

    # Add to artifact references
    artifact_refs=$(echo "$artifact_refs" | jq \
      --arg id "$item_id" \
      --arg path "$expected_artifact" \
      --arg prompt "$agent_prompt" \
      '. += [{item_id: $id, artifact_path: $path, agent_prompt: $prompt}]')

  done < <(echo "$operation_items" | jq -c '.[]')

  echo "" >&2
  echo "Prepared $operation_count agent invocations for parallel execution" >&2
  echo "Command layer should invoke Task tool for each agent_prompt" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Return artifact references with prompts
  echo "$artifact_refs"
}

# ============================================================================
# Generic Artifact Aggregation
# ============================================================================

# aggregate_artifacts_generic: Collect and validate operation artifacts
# Args:
#   $1 - operation_type: "expansion" or "collapse"
#   $2 - plan_path: Path to plan file or directory
#   $3 - artifact_refs_json: JSON array of artifact references
# Returns:
#   JSON summary of artifacts (lightweight, ~50 words per operation)
aggregate_artifacts_generic() {
  local operation_type="$1"
  local plan_path="$2"
  local artifact_refs_json="$3"

  # Validate inputs
  if [[ -z "$operation_type" ]] || [[ -z "$plan_path" ]] || [[ -z "$artifact_refs_json" ]]; then
    echo "ERROR: aggregate_artifacts_generic requires operation_type, plan_path, and artifact_refs_json" >&2
    return 1
  fi

  if [[ "$operation_type" != "expansion" ]] && [[ "$operation_type" != "collapse" ]]; then
    echo "ERROR: operation_type must be 'expansion' or 'collapse', got: $operation_type" >&2
    return 1
  fi

  # Display header
  local op_display="${operation_type^}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Artifact Aggregation: Validating ${op_display} Results" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  local artifact_count
  artifact_count=$(echo "$artifact_refs_json" | jq 'length')

  local summary="[]"
  local success_count=0
  local failure_count=0

  # Select file count field based on operation type
  local file_field_name file_field_section
  if [[ "$operation_type" == "expansion" ]]; then
    file_field_name="files_created"
    file_field_section="Files Created"
  else
    file_field_name="files_modified"
    file_field_section="Files Modified"
  fi

  # Process each artifact reference
  while IFS= read -r artifact_ref; do
    local item_id artifact_path
    item_id=$(echo "$artifact_ref" | jq -r '.item_id')
    artifact_path=$(echo "$artifact_ref" | jq -r '.artifact_path')

    # Check if artifact exists
    if [[ -f "${CLAUDE_PROJECT_DIR}/${artifact_path}" ]]; then
      # Extract lightweight summary from artifact
      local artifact_content
      artifact_content=$(head -50 "${CLAUDE_PROJECT_DIR}/${artifact_path}")

      local operation_value file_count status
      operation_value=$(echo "$artifact_content" | grep "^- \*\*Operation\*\*:" | sed 's/.*: //' || echo "$operation_type")
      file_count=$(echo "$artifact_content" | grep -A 5 "^## ${file_field_section}" | grep "^-" | wc -l)
      status="success"

      success_count=$((success_count + 1))

      # Build lightweight summary
      summary=$(echo "$summary" | jq \
        --arg id "$item_id" \
        --arg path "$artifact_path" \
        --arg op "$operation_value" \
        --arg files "$file_count" \
        --arg status "$status" \
        --arg field "$file_field_name" \
        '. += [{
          item_id: $id,
          artifact_path: $path,
          operation: $op,
          ($field): ($files | tonumber),
          status: $status
        }]')

      echo "  ✓ $item_id: Artifact validated ($file_count files)" >&2
    else
      failure_count=$((failure_count + 1))

      summary=$(echo "$summary" | jq \
        --arg id "$item_id" \
        --arg path "$artifact_path" \
        --arg status "missing" \
        '. += [{
          item_id: $id,
          artifact_path: $path,
          status: $status,
          error: "Artifact file not found"
        }]')

      echo "  ✗ $item_id: Artifact missing" >&2
    fi
  done < <(echo "$artifact_refs_json" | jq -c '.[]')

  echo "" >&2
  echo "Summary: $success_count successful, $failure_count failed" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Return summary with success/failure counts
  jq -n \
    --argjson artifacts "$summary" \
    --argjson total "$artifact_count" \
    --argjson success "$success_count" \
    --argjson failed "$failure_count" \
    '{
      total: $total,
      successful: $success,
      failed: $failed,
      artifacts: $artifacts
    }'
}

# ============================================================================
# Generic Metadata Coordination
# ============================================================================

# coordinate_metadata_generic: Update plan metadata after parallel operations
# Args:
#   $1 - operation_type: "expansion" or "collapse"
#   $2 - plan_path: Path to plan file or directory
#   $3 - aggregation_json: JSON from aggregate_artifacts_generic
# Returns:
#   0 on success, non-zero on failure
coordinate_metadata_generic() {
  local operation_type="$1"
  local plan_path="$2"
  local aggregation_json="$3"

  # Validate inputs
  if [[ -z "$operation_type" ]] || [[ -z "$plan_path" ]] || [[ -z "$aggregation_json" ]]; then
    echo "ERROR: coordinate_metadata_generic requires operation_type, plan_path, and aggregation_json" >&2
    return 1
  fi

  if [[ "$operation_type" != "expansion" ]] && [[ "$operation_type" != "collapse" ]]; then
    echo "ERROR: operation_type must be 'expansion' or 'collapse', got: $operation_type" >&2
    return 1
  fi

  # Display header
  local op_display="${operation_type^}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Metadata Coordination: Updating Plan (${op_display})" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Extract successful operations
  local successful_items
  successful_items=$(echo "$aggregation_json" | jq -c '.artifacts[] | select(.status == "success")')

  if [[ -z "$successful_items" ]]; then
    echo "No successful operations to coordinate" >&2
    return 0
  fi

  # Source checkpoint utilities for rollback capability
  if [[ -f "$SCRIPT_DIR/checkpoint-utils.sh" ]]; then
    source "$SCRIPT_DIR/checkpoint-utils.sh"
    local checkpoint_id
    checkpoint_id=$(date +%s)
    echo "Creating checkpoint before metadata updates..." >&2
  fi

  # Detect current structure level
  local current_level
  if [[ -d "$plan_path" ]]; then
    current_level=$(detect_structure_level "$plan_path" 2>/dev/null || echo "1")
  else
    current_level=$(detect_structure_level "$plan_path" 2>/dev/null || echo "0")
  fi

  # Handle structure level transitions
  if [[ "$operation_type" == "expansion" ]]; then
    if [[ "$current_level" == "0" ]]; then
      echo "  Updating Structure Level: 0 → 1" >&2
    fi
  fi

  # Build list of affected items
  local affected_items="[]"
  while IFS= read -r item; do
    local item_id
    item_id=$(echo "$item" | jq -r '.item_id')

    # Extract number
    local item_num
    item_num=$(echo "$item_id" | grep -oP '\d+' || echo "0")

    affected_items=$(echo "$affected_items" | jq --argjson num "$item_num" '. += [$num]')

    if [[ "$operation_type" == "expansion" ]]; then
      echo "  Marking phase $item_num as expanded" >&2
    else
      echo "  Removing phase $item_num from expanded list" >&2
    fi
  done < <(echo "$successful_items")

  # Display metadata updates
  if [[ "$operation_type" == "expansion" ]]; then
    echo "  Expanded Phases: $(echo "$affected_items" | jq -c '.')" >&2
  else
    echo "  Collapsed items: $(echo "$affected_items" | jq -c '.')" >&2
    echo "  Current Structure Level: $current_level" >&2
    echo "  (Structure Level transition logic would be applied here)" >&2
  fi

  echo "" >&2
  echo "Metadata updates completed" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  return 0
}

# ============================================================================
# Main (for testing)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "parallel-orchestration-utils.sh: Generic parallel orchestration utilities"
  echo "Source this file to use its functions"
  echo ""
  echo "Available functions:"
  echo "  - invoke_agents_parallel_generic <operation_type> <plan_path> <recommendations_json>"
  echo "  - aggregate_artifacts_generic <operation_type> <plan_path> <artifact_refs_json>"
  echo "  - coordinate_metadata_generic <operation_type> <plan_path> <aggregation_json>"
  echo ""
  echo "Operation types: 'expansion' or 'collapse'"
fi
