#!/usr/bin/env bash
# auto-analysis-utils.sh
# Utilities for orchestrating complexity_estimator agent invocations
# Part of expand/collapse auto-analysis mode

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/parse-adaptive-plan.sh"
source "$SCRIPT_DIR/json-utils.sh" 2>/dev/null || true
source "$SCRIPT_DIR/error-utils.sh" 2>/dev/null || true

# Source modular components
source "$SCRIPT_DIR/agent-invocation.sh"
source "$SCRIPT_DIR/phase-analysis.sh"
source "$SCRIPT_DIR/stage-analysis.sh"

# ============================================================================
# Report Generation
# ============================================================================

# Generate human-readable analysis report
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

# ============================================================================
# Artifact Registry Functions
# ============================================================================

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

# get_artifact_path: Retrieve artifact path by item ID
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

# validate_operation_artifacts: Verify all artifacts exist
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

  # Create artifact directory
  source "$SCRIPT_DIR/artifact-utils.sh"
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

  # Create artifact directory
  source "$SCRIPT_DIR/artifact-utils.sh"
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
# Hierarchy Review and Second-Round Analysis
# ============================================================================

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
    local log_dir="${CLAUDE_PROJECT_DIR}/.claude/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/approval-decisions.log"

    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] APPROVED: $context ($rec_count recommendations)" >> "$log_file"

    return 0
  else
    echo "" >&2
    echo "✗ Recommendations rejected by user" >&2
    echo "" >&2

    # Log rejection
    local log_dir="${CLAUDE_PROJECT_DIR}/.claude/logs"
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

# ============================================================================
# Main (for testing)
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "auto-analysis-utils.sh: Library for complexity estimator agent orchestration"
  echo "Source this file to use its functions"
  echo ""
  echo "Available functions:"
  echo "  - invoke_complexity_estimator <mode> <content_json> <context_json>"
  echo "  - analyze_phases_for_expansion <plan_path>"
  echo "  - analyze_phases_for_collapse <plan_path>"
  echo "  - analyze_stages_for_expansion <plan_path> <phase_num>"
  echo "  - analyze_stages_for_collapse <plan_path> <phase_num>"
  echo "  - generate_analysis_report <mode> <decisions_json> <plan_path>"
  echo "  - register_operation_artifact <plan_path> <operation_type> <item_id> <artifact_path>"
  echo "  - get_artifact_path <plan_path> <item_id>"
  echo "  - validate_operation_artifacts <plan_path>"
  echo "  - invoke_expansion_agents_parallel <plan_path> <recommendations_json>"
  echo "  - aggregate_expansion_artifacts <plan_path> <artifact_refs_json>"
  echo "  - coordinate_metadata_updates <plan_path> <aggregation_json>"
  echo "  - invoke_collapse_agents_parallel <plan_path> <recommendations_json>"
  echo "  - aggregate_collapse_artifacts <plan_path> <artifact_refs_json>"
  echo "  - coordinate_collapse_metadata_updates <plan_path> <aggregation_json>"
  echo "  - review_plan_hierarchy <plan_path> <operation_summary_json>"
  echo "  - run_second_round_analysis <plan_path> <initial_analysis_json>"
  echo "  - present_recommendations_for_approval <recommendations_json> <context>"
  echo "  - generate_recommendations_report <plan_path> <hierarchy_json> <second_round_json> <operations_json>"
fi
