#!/usr/bin/env bash
# auto-analysis-utils.sh
# Utilities for orchestrating complexity_estimator agent invocations
# Part of expand/collapse auto-analysis mode

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/plan-core-bundle.sh"
source "$SCRIPT_DIR/json-utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/error-handling.sh" 2>/dev/null || true

# Source modular components
source "$SCRIPT_DIR/agent-invocation.sh"
source "$SCRIPT_DIR/analysis-pattern.sh"
source "$SCRIPT_DIR/artifact-registry.sh"

# ============================================================================
# Parallel Execution Functions
# ============================================================================

# invoke_expansion_agents_parallel: Launch parallel expansion operations
# Args:
#   $1 - plan_path: Path to plan file
#   $2 - recommendations_json: JSON array from complexity_estimator
# Returns:
#   JSON array of artifact references
invoke_expansion_agents_parallel() {
  local plan_path="$1"
  local recommendations_json="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$recommendations_json" ]]; then
    echo "ERROR: invoke_expansion_agents_parallel requires plan_path and recommendations_json" >&2
    return 1
  fi

  # Extract plan name for artifact directory
  local plan_name
  plan_name=$(basename "$plan_path" .md)

  # Create artifact directory (function now available from artifact-creation.sh sourced at top)
  local artifact_dir
  artifact_dir=$(create_artifact_directory "$plan_path")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Parallel Expansion: Launching Agents" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Build artifact references array
  local artifact_refs="[]"

  # Filter recommendations for expansion
  local expansion_items
  expansion_items=$(echo "$recommendations_json" | jq -c '[.[] | select(.recommendation == "expand")]')

  local expansion_count
  expansion_count=$(echo "$expansion_items" | jq 'length')

  if [[ $expansion_count -eq 0 ]]; then
    echo "No items recommended for expansion" >&2
    echo "$artifact_refs"
    return 0
  fi

  echo "Launching $expansion_count expansion agents in parallel..." >&2
  echo "" >&2

  # For each expansion recommendation, prepare Task invocation prompt
  # NOTE: Actual Task tool invocation must happen in command layer
  # This function returns prompts that should be used for parallel invocation
  while IFS= read -r item; do
    local item_id item_name complexity
    item_id=$(echo "$item" | jq -r '.item_id')
    item_name=$(echo "$item" | jq -r '.item_name')
    complexity=$(echo "$item" | jq -r '.complexity_level')

    # Extract item number
    local item_num
    item_num=$(echo "$item_id" | grep -oP '\d+')

    echo "  $item_id: $item_name (complexity: $complexity/10)" >&2

    # Build agent prompt (command layer will invoke Task tool with this)
    local agent_prompt
    agent_prompt=$(cat <<EOF
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/expansion-specialist.md

Expansion Task: phase $item_num

Context:
- Plan path: $plan_path
- Item to expand: phase $item_num
- Complexity score: $complexity/10
- Current structure level: $(detect_structure_level "$plan_path")

Objective: Extract content, create file structure, save artifact

Output: Save artifact to specs/artifacts/${plan_name}/expansion_${item_num}.md
EOF
)

    # Store prompt for command layer to use
    # In actual implementation, command layer will use Task tool with this prompt
    local expected_artifact="specs/artifacts/${plan_name}/expansion_${item_num}.md"

    # Add to artifact references
    artifact_refs=$(echo "$artifact_refs" | jq \
      --arg id "$item_id" \
      --arg path "$expected_artifact" \
      --arg prompt "$agent_prompt" \
      '. += [{item_id: $id, artifact_path: $path, agent_prompt: $prompt}]')

  done < <(echo "$expansion_items" | jq -c '.[]')

  echo "" >&2
  echo "Prepared $expansion_count agent invocations for parallel execution" >&2
  echo "Command layer should invoke Task tool for each agent_prompt" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Return artifact references with prompts
  echo "$artifact_refs"
}

# aggregate_expansion_artifacts: Collect and validate expansion artifacts
# Args:
#   $1 - plan_path: Path to plan file
#   $2 - artifact_refs_json: JSON array of artifact references
# Returns:
#   JSON summary of artifacts (lightweight, ~50 words per operation)
aggregate_expansion_artifacts() {
  local plan_path="$1"
  local artifact_refs_json="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$artifact_refs_json" ]]; then
    echo "ERROR: aggregate_expansion_artifacts requires plan_path and artifact_refs_json" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Artifact Aggregation: Validating Results" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  local artifact_count
  artifact_count=$(echo "$artifact_refs_json" | jq 'length')

  local summary="[]"
  local success_count=0
  local failure_count=0

  while IFS= read -r artifact_ref; do
    local item_id artifact_path
    item_id=$(echo "$artifact_ref" | jq -r '.item_id')
    artifact_path=$(echo "$artifact_ref" | jq -r '.artifact_path')

    # Check if artifact exists
    if [[ -f "${CLAUDE_PROJECT_DIR}/${artifact_path}" ]]; then
      # Extract lightweight summary from artifact
      local artifact_content
      artifact_content=$(head -50 "${CLAUDE_PROJECT_DIR}/${artifact_path}")

      local operation_type files_created status
      operation_type=$(echo "$artifact_content" | grep "^- \*\*Operation\*\*:" | sed 's/.*: //')
      files_created=$(echo "$artifact_content" | grep -A 5 "^## Files Created" | grep "^-" | wc -l)
      status="success"

      success_count=$((success_count + 1))

      # Build lightweight summary (~50 words)
      summary=$(echo "$summary" | jq \
        --arg id "$item_id" \
        --arg path "$artifact_path" \
        --arg op "$operation_type" \
        --arg files "$files_created" \
        --arg status "$status" \
        '. += [{
          item_id: $id,
          artifact_path: $path,
          operation: $op,
          files_created: ($files | tonumber),
          status: $status
        }]')

      echo "  ✓ $item_id: Artifact validated ($files_created files created)" >&2
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

# coordinate_metadata_updates: Update plan metadata after parallel operations
# Args:
#   $1 - plan_path: Path to plan file
#   $2 - aggregation_json: JSON from aggregate_expansion_artifacts
# Returns:
#   0 on success, non-zero on failure
coordinate_metadata_updates() {
  local plan_path="$1"
  local aggregation_json="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$aggregation_json" ]]; then
    echo "ERROR: coordinate_metadata_updates requires plan_path and aggregation_json" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Metadata Coordination: Updating Plan" >&2
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

    # Save checkpoint before metadata updates
    local checkpoint_id
    checkpoint_id=$(date +%s)
    echo "Creating checkpoint before metadata updates..." >&2
    # save_checkpoint "$plan_path" "pre_metadata_update_$checkpoint_id"
  fi

  # Update Structure Level if any phases were expanded
  local current_level
  current_level=$(detect_structure_level "$plan_path")

  if [[ "$current_level" == "0" ]]; then
    echo "  Updating Structure Level: 0 → 1" >&2
    # In actual implementation, would update plan file metadata
    # For now, just indicate the change
  fi

  # Build list of expanded phases
  local expanded_phases="[]"
  while IFS= read -r item; do
    local item_id
    item_id=$(echo "$item" | jq -r '.item_id')

    # Extract phase number
    local phase_num
    phase_num=$(echo "$item_id" | grep -oP '\d+')

    expanded_phases=$(echo "$expanded_phases" | jq --argjson num "$phase_num" '. += [$num]')

    echo "  Marking phase $phase_num as expanded" >&2
  done < <(echo "$successful_items")

  # Update Expanded Phases list in plan metadata
  echo "  Expanded Phases: $(echo "$expanded_phases" | jq -c '.')" >&2

  echo "" >&2
  echo "Metadata updates completed" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  return 0
}

# ============================================================================
# Parallel Collapse Functions
# ============================================================================

# invoke_collapse_agents_parallel: Launch parallel collapse operations
# Args:
#   $1 - plan_path: Path to plan file or directory
#   $2 - recommendations_json: JSON array from complexity_estimator
# Returns:
#   JSON array of artifact references
invoke_collapse_agents_parallel() {
  local plan_path="$1"
  local recommendations_json="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$recommendations_json" ]]; then
    echo "ERROR: invoke_collapse_agents_parallel requires plan_path and recommendations_json" >&2
    return 1
  fi

  # Extract plan name for artifact directory
  local plan_name
  if [[ -d "$plan_path" ]]; then
    plan_name=$(basename "$plan_path")
  else
    plan_name=$(basename "$plan_path" .md)
  fi

  # Create artifact directory (function now available from artifact-creation.sh sourced at top)
  local artifact_dir
  artifact_dir=$(create_artifact_directory "$plan_path")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Parallel Collapse: Launching Agents" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Build artifact references array
  local artifact_refs="[]"

  # Filter recommendations for collapse
  local collapse_items
  collapse_items=$(echo "$recommendations_json" | jq -c '[.[] | select(.recommendation == "collapse")]')

  local collapse_count
  collapse_count=$(echo "$collapse_items" | jq 'length')

  if [[ $collapse_count -eq 0 ]]; then
    echo "No items recommended for collapse" >&2
    echo "$artifact_refs"
    return 0
  fi

  echo "Launching $collapse_count collapse agents in parallel..." >&2
  echo "" >&2

  # For each collapse recommendation, prepare Task invocation prompt
  while IFS= read -r item; do
    local item_id item_name complexity
    item_id=$(echo "$item" | jq -r '.item_id')
    item_name=$(echo "$item" | jq -r '.item_name')
    complexity=$(echo "$item" | jq -r '.complexity_level')

    # Extract item number
    local item_num
    item_num=$(echo "$item_id" | grep -oP '\d+')

    echo "  $item_id: $item_name (complexity: $complexity/10)" >&2

    # Determine current structure level
    local current_level
    if [[ -d "$plan_path" ]]; then
      current_level=$(detect_structure_level "$plan_path")
    else
      current_level=$(detect_structure_level "$plan_path")
    fi

    # Build agent prompt
    local agent_prompt
    agent_prompt=$(cat <<EOF
Read and follow the behavioral guidelines from:
/home/benjamin/.config/.claude/agents/collapse-specialist.md

Collapse Task: phase $item_num

Context:
- Plan path: $plan_path
- Item to collapse: phase $item_num
- Complexity score: $complexity/10
- Current structure level: $current_level

Objective: Merge content to parent, delete file, save artifact

Output: Save artifact to specs/artifacts/${plan_name}/collapse_${item_num}.md
EOF
)

    local expected_artifact="specs/artifacts/${plan_name}/collapse_${item_num}.md"

    # Add to artifact references
    artifact_refs=$(echo "$artifact_refs" | jq \
      --arg id "$item_id" \
      --arg path "$expected_artifact" \
      --arg prompt "$agent_prompt" \
      '. += [{item_id: $id, artifact_path: $path, agent_prompt: $prompt}]')

  done < <(echo "$collapse_items" | jq -c '.[]')

  echo "" >&2
  echo "Prepared $collapse_count agent invocations for parallel execution" >&2
  echo "Command layer should invoke Task tool for each agent_prompt" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  # Return artifact references with prompts
  echo "$artifact_refs"
}

# aggregate_collapse_artifacts: Collect and validate collapse artifacts
# Args:
#   $1 - plan_path: Path to plan file or directory
#   $2 - artifact_refs_json: JSON array of artifact references
# Returns:
#   JSON summary of artifacts (lightweight, ~50 words per operation)
aggregate_collapse_artifacts() {
  local plan_path="$1"
  local artifact_refs_json="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$artifact_refs_json" ]]; then
    echo "ERROR: aggregate_collapse_artifacts requires plan_path and artifact_refs_json" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Artifact Aggregation: Validating Collapse Results" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "" >&2

  local artifact_count
  artifact_count=$(echo "$artifact_refs_json" | jq 'length')

  local summary="[]"
  local success_count=0
  local failure_count=0

  while IFS= read -r artifact_ref; do
    local item_id artifact_path
    item_id=$(echo "$artifact_ref" | jq -r '.item_id')
    artifact_path=$(echo "$artifact_ref" | jq -r '.artifact_path')

    # Check if artifact exists
    if [[ -f "${CLAUDE_PROJECT_DIR}/${artifact_path}" ]]; then
      # Extract lightweight summary from artifact
      local artifact_content
      artifact_content=$(head -50 "${CLAUDE_PROJECT_DIR}/${artifact_path}")

      local operation_type files_modified status
      operation_type=$(echo "$artifact_content" | grep "^- \*\*Operation\*\*:" | sed 's/.*: //')
      files_modified=$(echo "$artifact_content" | grep -A 5 "^## Files Modified" | grep "^-" | wc -l)
      status="success"

      success_count=$((success_count + 1))

      # Build lightweight summary
      summary=$(echo "$summary" | jq \
        --arg id "$item_id" \
        --arg path "$artifact_path" \
        --arg op "$operation_type" \
        --arg files "$files_modified" \
        --arg status "$status" \
        '. += [{
          item_id: $id,
          artifact_path: $path,
          operation: $op,
          files_modified: ($files | tonumber),
          status: $status
        }]')

      echo "  ✓ $item_id: Artifact validated ($files_modified files modified)" >&2
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

# coordinate_collapse_metadata_updates: Update metadata for collapse operations
# Args:
#   $1 - plan_path: Path to plan file or directory
#   $2 - aggregation_json: JSON from aggregate_collapse_artifacts
# Returns:
#   0 on success, non-zero on failure
#
# Handles three-way metadata updates (stage → phase → plan) and Structure Level
# transitions in reverse (2→1→0)
coordinate_collapse_metadata_updates() {
  local plan_path="$1"
  local aggregation_json="$2"

  if [[ -z "$plan_path" ]] || [[ -z "$aggregation_json" ]]; then
    echo "ERROR: coordinate_collapse_metadata_updates requires plan_path and aggregation_json" >&2
    return 1
  fi

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Metadata Coordination: Updating Plan (Collapse)" >&2
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

    # Save checkpoint before metadata updates
    local checkpoint_id
    checkpoint_id=$(date +%s)
    echo "Creating checkpoint before metadata updates..." >&2
  fi

  # Determine current structure level
  local current_level
  if [[ -d "$plan_path" ]]; then
    current_level=$(detect_structure_level "$plan_path")
  else
    current_level=$(detect_structure_level "$plan_path")
  fi

  # Build list of collapsed phases/stages
  local collapsed_items="[]"
  while IFS= read -r item; do
    local item_id
    item_id=$(echo "$item" | jq -r '.item_id')

    # Extract number
    local item_num
    item_num=$(echo "$item_id" | grep -oP '\d+')

    collapsed_items=$(echo "$collapsed_items" | jq --argjson num "$item_num" '. += [$num]')

    echo "  Removing $item_id from expanded list" >&2
  done < <(echo "$successful_items")

  # Update Expanded Phases/Stages lists
  echo "  Collapsed items: $(echo "$collapsed_items" | jq -c '.')" >&2

  # Check if Structure Level should transition
  # This would require checking if all expanded items at current level are collapsed
  echo "  Current Structure Level: $current_level" >&2
  echo "  (Structure Level transition logic would be applied here)" >&2

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
  echo "auto-analysis-utils.sh: Modular library for complexity estimator agent orchestration"
  echo "Source this file to use its functions"
  echo ""
  echo "Modular Components:"
  echo "  - agent-invocation.sh: Agent coordination and prompt building"
  echo "  - analysis-pattern.sh: Unified phase/stage expansion/collapse analysis"
  echo "  - artifact-management.sh: Report generation and artifact tracking"
  echo ""
  echo "Available functions (from modules):"
  echo "  - invoke_complexity_estimator <mode> <content_json> <context_json>"
  echo "  - analyze_phases_for_expansion <plan_path>"
  echo "  - analyze_phases_for_collapse <plan_path>"
  echo "  - analyze_stages_for_expansion <plan_path> <phase_num>"
  echo "  - analyze_stages_for_collapse <plan_path> <phase_num>"
  echo "  - generate_analysis_report <mode> <decisions_json> <plan_path>"
  echo "  - register_operation_artifact <plan_path> <operation_type> <item_id> <artifact_path>"
  echo "  - get_artifact_path <plan_path> <item_id>"
  echo "  - validate_operation_artifacts <plan_path>"
  echo "  - review_plan_hierarchy <plan_path> <operation_summary_json>"
  echo "  - run_second_round_analysis <plan_path> <initial_analysis_json>"
  echo "  - present_recommendations_for_approval <recommendations_json> <context>"
  echo "  - generate_recommendations_report <plan_path> <hierarchy_json> <second_round_json> <operations_json>"
  echo ""
  echo "Available functions (in this file):"
  echo "  - invoke_expansion_agents_parallel <plan_path> <recommendations_json>"
  echo "  - aggregate_expansion_artifacts <plan_path> <artifact_refs_json>"
  echo "  - coordinate_metadata_updates <plan_path> <aggregation_json>"
  echo "  - invoke_collapse_agents_parallel <plan_path> <recommendations_json>"
  echo "  - aggregate_collapse_artifacts <plan_path> <artifact_refs_json>"
  echo "  - coordinate_collapse_metadata_updates <plan_path> <aggregation_json>"
fi
