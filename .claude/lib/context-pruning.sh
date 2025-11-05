#!/usr/bin/env bash
# context-pruning.sh - Aggressive context pruning for subagent workflows
# Part of .claude/lib/ modular utilities
#
# Primary Functions:
#   prune_subagent_output - Clear full output, retain metadata only
#   prune_phase_metadata - Remove phase-specific metadata after completion
#   prune_workflow_metadata - Remove workflow metadata after completion
#   get_pruned_context - Get minimal context for phase/workflow
#
# Usage:
#   source "${BASH_SOURCE%/*}/context-pruning.sh"
#   prune_subagent_output "$SUBAGENT_OUTPUT_VAR"
#   prune_phase_metadata "phase_3_research"

set -euo pipefail

# ==============================================================================
# Environment Setup
# ==============================================================================

# Set CLAUDE_PROJECT_DIR if not already set
: "${CLAUDE_PROJECT_DIR:=$(pwd)}"

# ==============================================================================
# Constants
# ==============================================================================

# Associative arrays for context storage
declare -A PRUNED_METADATA_CACHE
declare -A PHASE_METADATA_CACHE
declare -A WORKFLOW_METADATA_CACHE

readonly MAX_METADATA_SIZE=500  # chars
readonly MAX_SUMMARY_WORDS=50

# ==============================================================================
# Subagent Output Pruning Functions
# ==============================================================================

# prune_subagent_output: Clear full subagent output, retain metadata only
# Usage: prune_subagent_output <output_var_name> <operation_name>
# Returns: Pruned metadata (artifact paths + 50-word summary)
# Example: PRUNED=$(prune_subagent_output "SUBAGENT_OUTPUT" "phase_3_research")
prune_subagent_output() {
  local output_var_name="${1:-}"
  local operation_name="${2:-unknown}"

  if [ -z "$output_var_name" ]; then
    echo "Usage: prune_subagent_output <output_var_name> <operation_name>" >&2
    return 1
  fi

  # Get full output via nameref (bash 4.3+ pattern to avoid history expansion)
  local -n output_ref="$output_var_name"
  local full_output="$output_ref"

  # Extract artifact paths (regex: specs/.*/.*\.md or .claude/specs/.*/.*\.md)
  local artifact_paths=$(echo "$full_output" | grep -oE '(\.claude/)?specs/[^/]+/[^/]+/[^ ]+\.md' | head -5)

  # Extract or generate 50-word summary
  local summary=$(echo "$full_output" | head -c 500 | awk '{
    words = 0
    for (i = 1; i <= NF && words < 50; i++) {
      printf "%s ", $i
      words++
    }
  }')

  # Build pruned metadata JSON
  local pruned_json=""
  if command -v jq &> /dev/null; then
    pruned_json=$(jq -n \
      --arg op "$operation_name" \
      --arg summary "$summary" \
      --arg paths "$artifact_paths" \
      '{
        operation: $op,
        artifact_paths: ($paths | split("\n") | map(select(length > 0))),
        summary: $summary,
        full_output_size: 0,
        pruned: true
      }')
  else
    # Fallback without jq
    local paths_array=$(echo "$artifact_paths" | sed 's/^/    "/; s/$/",/' | sed '$ s/,$//')
    pruned_json=$(cat <<EOF
{
  "operation": "$operation_name",
  "artifact_paths": [
$paths_array
  ],
  "summary": "$summary",
  "full_output_size": 0,
  "pruned": true
}
EOF
    )
  fi

  # Cache pruned metadata
  PRUNED_METADATA_CACHE["$operation_name"]="$pruned_json"

  # Clear the original variable (save memory)
  # Note: Can't directly unset variable passed by name, caller must handle
  echo "PRUNING_NOTICE: Clear $output_var_name to save memory" >&2

  # Return pruned metadata
  echo "$pruned_json"
}

# get_pruned_metadata: Retrieve pruned metadata from cache
# Usage: get_pruned_metadata <operation_name>
# Returns: Pruned metadata JSON
# Example: METADATA=$(get_pruned_metadata "phase_3_research")
get_pruned_metadata() {
  local operation_name="${1:-}"

  if [ -z "$operation_name" ]; then
    echo "Usage: get_pruned_metadata <operation_name>" >&2
    return 1
  fi

  local metadata="${PRUNED_METADATA_CACHE[$operation_name]:-}"

  if [ -z "$metadata" ]; then
    echo "{\"error\": \"No pruned metadata found for operation: $operation_name\"}" >&2
    return 1
  fi

  echo "$metadata"
}

# ==============================================================================
# Phase Metadata Pruning Functions
# ==============================================================================

# prune_phase_metadata: Remove phase-specific metadata after phase completes
# Usage: prune_phase_metadata <phase_identifier>
# Returns: 0 on success
# Example: prune_phase_metadata "phase_3_implementation"
prune_phase_metadata() {
  local phase_id="${1:-}"

  if [ -z "$phase_id" ]; then
    echo "Usage: prune_phase_metadata <phase_identifier>" >&2
    return 1
  fi

  # Remove phase-specific entries from pruned metadata cache
  for key in "${!PRUNED_METADATA_CACHE[@]}"; do
    if [[ "$key" == *"$phase_id"* ]]; then
      unset PRUNED_METADATA_CACHE["$key"]
      echo "Pruned metadata for: $key" >&2
    fi
  done

  # Remove from phase metadata cache
  if [ -n "${PHASE_METADATA_CACHE[$phase_id]:-}" ]; then
    unset PHASE_METADATA_CACHE["$phase_id"]
    echo "Pruned phase metadata: $phase_id" >&2
  fi

  return 0
}

# store_phase_metadata: Store minimal phase metadata
# Usage: store_phase_metadata <phase_id> <status> <artifact_paths>
# Returns: 0 on success
# Example: store_phase_metadata "phase_3" "complete" "specs/042_auth/reports/001.md specs/042_auth/plans/001.md"
store_phase_metadata() {
  local phase_id="${1:-}"
  local status="${2:-unknown}"
  local artifact_paths="${3:-}"

  if [ -z "$phase_id" ]; then
    echo "Usage: store_phase_metadata <phase_id> <status> <artifact_paths>" >&2
    return 1
  fi

  # Build minimal metadata
  local phase_json=""
  if command -v jq &> /dev/null; then
    phase_json=$(jq -n \
      --arg id "$phase_id" \
      --arg status "$status" \
      --arg paths "$artifact_paths" \
      '{
        phase: $id,
        status: $status,
        artifacts: ($paths | split(" ") | map(select(length > 0))),
        timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ")
      }')
  else
    phase_json="{\"phase\":\"$phase_id\",\"status\":\"$status\",\"artifacts\":[\"$artifact_paths\"]}"
  fi

  PHASE_METADATA_CACHE["$phase_id"]="$phase_json"

  echo "$phase_json"
}

# get_phase_metadata: Retrieve phase metadata from cache
# Usage: get_phase_metadata <phase_id>
# Returns: Phase metadata JSON
# Example: METADATA=$(get_phase_metadata "phase_3")
get_phase_metadata() {
  local phase_id="${1:-}"

  if [ -z "$phase_id" ]; then
    echo "Usage: get_phase_metadata <phase_id>" >&2
    return 1
  fi

  local metadata="${PHASE_METADATA_CACHE[$phase_id]:-}"

  if [ -z "$metadata" ]; then
    echo "{\"error\": \"No phase metadata found for: $phase_id\"}" >&2
    return 1
  fi

  echo "$metadata"
}

# ==============================================================================
# Workflow Metadata Pruning Functions
# ==============================================================================

# prune_workflow_metadata: Remove workflow metadata after completion
# Usage: prune_workflow_metadata <workflow_name> [keep_artifacts]
# Returns: 0 on success
# Example: prune_workflow_metadata "plan_creation" "true"
prune_workflow_metadata() {
  local workflow_name="${1:-}"
  local keep_artifacts="${2:-false}"

  if [ -z "$workflow_name" ]; then
    echo "Usage: prune_workflow_metadata <workflow_name> [keep_artifacts]" >&2
    return 1
  fi

  echo "Pruning workflow metadata: $workflow_name" >&2

  # If keep_artifacts=false, prune all phase metadata
  if [ "$keep_artifacts" = "false" ]; then
    for phase_id in "${!PHASE_METADATA_CACHE[@]}"; do
      unset PHASE_METADATA_CACHE["$phase_id"]
      echo "  Pruned phase: $phase_id" >&2
    done
  fi

  # Prune workflow-specific pruned metadata
  for key in "${!PRUNED_METADATA_CACHE[@]}"; do
    unset PRUNED_METADATA_CACHE["$key"]
  done

  # Remove workflow metadata
  if [ -n "${WORKFLOW_METADATA_CACHE[$workflow_name]:-}" ]; then
    unset WORKFLOW_METADATA_CACHE["$workflow_name"]
    echo "  Pruned workflow: $workflow_name" >&2
  fi

  echo "Workflow metadata pruned successfully" >&2
  return 0
}

# store_workflow_metadata: Store minimal workflow metadata
# Usage: store_workflow_metadata <workflow_name> <status> <final_artifacts>
# Returns: 0 on success
# Example: store_workflow_metadata "orchestrate_auth" "complete" "specs/042_auth/plans/001.md"
store_workflow_metadata() {
  local workflow_name="${1:-}"
  local status="${2:-unknown}"
  local final_artifacts="${3:-}"

  if [ -z "$workflow_name" ]; then
    echo "Usage: store_workflow_metadata <workflow_name> <status> <final_artifacts>" >&2
    return 1
  fi

  # Build minimal workflow metadata
  local workflow_json=""
  if command -v jq &> /dev/null; then
    workflow_json=$(jq -n \
      --arg name "$workflow_name" \
      --arg status "$status" \
      --arg artifacts "$final_artifacts" \
      '{
        workflow: $name,
        status: $status,
        final_artifacts: ($artifacts | split(" ") | map(select(length > 0))),
        timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ")
      }')
  else
    workflow_json="{\"workflow\":\"$workflow_name\",\"status\":\"$status\",\"final_artifacts\":[\"$final_artifacts\"]}"
  fi

  WORKFLOW_METADATA_CACHE["$workflow_name"]="$workflow_json"

  echo "$workflow_json"
}

# ==============================================================================
# Context Size Reporting Functions
# ==============================================================================

# get_current_context_size: Estimate current context size (in chars)
# Usage: get_current_context_size
# Returns: Estimated context size
# Example: SIZE=$(get_current_context_size)
get_current_context_size() {
  local total_size=0

  # Size of pruned metadata cache
  for key in "${!PRUNED_METADATA_CACHE[@]}"; do
    local entry_size=${#PRUNED_METADATA_CACHE[$key]}
    total_size=$((total_size + entry_size))
  done

  # Size of phase metadata cache
  for key in "${!PHASE_METADATA_CACHE[@]}"; do
    local entry_size=${#PHASE_METADATA_CACHE[$key]}
    total_size=$((total_size + entry_size))
  done

  # Size of workflow metadata cache
  for key in "${!WORKFLOW_METADATA_CACHE[@]}"; do
    local entry_size=${#WORKFLOW_METADATA_CACHE[$key]}
    total_size=$((total_size + entry_size))
  done

  echo "$total_size"
}

# report_context_savings: Calculate and report context savings
# Usage: report_context_savings <before_size> <after_size>
# Returns: Reduction percentage and statistics
# Example: report_context_savings 10000 500
report_context_savings() {
  local before="${1:-0}"
  local after="${2:-0}"

  if [ "$before" -eq 0 ]; then
    echo "No context savings (before size is 0)"
    return 0
  fi

  local reduction=$(( (before - after) * 100 / before ))
  local saved=$(( before - after ))

  cat <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT PRUNING REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before pruning: $before chars
After pruning:  $after chars
Saved:          $saved chars
Reduction:      $reduction%

Target: <30% context usage
Status: $([ "$reduction" -ge 70 ] && echo "✓ Target met" || echo "⚠ Below target")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# ==============================================================================
# Pruning Policy Functions
# ==============================================================================

# apply_pruning_policy: Apply pruning policy to workflow
# Usage: apply_pruning_policy <phase_name> <workflow_type>
# Returns: 0 if pruning applied
# Example: apply_pruning_policy "research" "plan_creation"
apply_pruning_policy() {
  local phase_name="${1:-}"
  local workflow_type="${2:-}"

  if [ -z "$phase_name" ] || [ -z "$workflow_type" ]; then
    echo "Usage: apply_pruning_policy <phase_name> <workflow_type>" >&2
    return 1
  fi

  echo "Applying pruning policy: $phase_name in $workflow_type" >&2

  # Pruning policies by workflow type
  case "$workflow_type" in
    plan_creation)
      # After planning completes, prune research metadata (no longer needed)
      if [ "$phase_name" = "planning" ]; then
        prune_phase_metadata "research"
        echo "  Policy: Pruned research metadata after planning" >&2
      fi
      ;;

    orchestrate)
      # After implementation completes, prune research and planning metadata
      if [ "$phase_name" = "implementation" ]; then
        prune_phase_metadata "research"
        prune_phase_metadata "planning"
        echo "  Policy: Pruned research/planning metadata after implementation" >&2
      fi
      ;;

    implement)
      # After each phase completes, prune previous phase research
      if [[ "$phase_name" == phase_* ]]; then
        local prev_phase_num=$(echo "$phase_name" | grep -oE '[0-9]+' | head -1)
        if [ -n "$prev_phase_num" ] && [ "$prev_phase_num" -gt 1 ]; then
          local prev_phase_id="phase_$((prev_phase_num - 1))_research"
          prune_phase_metadata "$prev_phase_id"
          echo "  Policy: Pruned previous phase research: $prev_phase_id" >&2
        fi
      fi
      ;;

    *)
      echo "  Policy: No specific pruning policy for workflow type: $workflow_type" >&2
      ;;
  esac

  return 0
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f prune_subagent_output
  export -f get_pruned_metadata
  export -f prune_phase_metadata
  export -f store_phase_metadata
  export -f get_phase_metadata
  export -f prune_workflow_metadata
  export -f store_workflow_metadata
  export -f get_current_context_size
  export -f report_context_savings
  export -f apply_pruning_policy
fi
