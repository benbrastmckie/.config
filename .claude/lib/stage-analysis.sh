#!/usr/bin/env bash
# stage-analysis.sh - Stage expansion and collapse analysis
# Part of .claude/lib/ modular utilities
#
# Functions:
#   analyze_stages_for_expansion - Analyze inline stages for expansion candidates
#   analyze_stages_for_collapse - Analyze expanded stages for collapse candidates
#
# Usage:
#   source "${BASH_SOURCE%/*}/stage-analysis.sh"
#   analyze_stages_for_expansion "$plan_path" "$phase_num"
#   analyze_stages_for_collapse "$plan_path" "$phase_num"

set -euo pipefail

# ============================================================================
# Stage Analysis Functions
# ============================================================================

# Analyze stages within a phase for expansion
# Args:
#   $1 - plan_path: Path to plan
#   $2 - phase_num: Phase number
# Returns:
#   JSON array of stage recommendations
analyze_stages_for_expansion() {
  local plan_path="$1"
  local phase_num="$2"

  # Get phase file
  local phase_file
  phase_file=$(get_phase_file "$plan_path" "$phase_num")

  if [[ ! -f "$phase_file" ]]; then
    echo "ERROR: Phase file not found: $phase_file" >&2
    return 1
  fi

  echo "Analyzing stages in phase $phase_num" >&2
  echo "" >&2

  # Extract phase context
  local phase_name phase_overview
  phase_name=$(extract_phase_name "$phase_file")
  phase_overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$phase_file" | sed '/^$/d' | head -5 | tr '\n' ' ')

  # Get master plan context
  local main_plan
  if [[ -d "${plan_path%.md}" ]]; then
    main_plan=$(find "${plan_path%.md}" -maxdepth 1 -name "*.md" -type f | head -1)
  else
    main_plan="$plan_path"
  fi

  local master_overview
  master_overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -3 | tr '\n' ' ')

  local context_json
  context_json=$(jq -n \
    --arg phase_name "$phase_name" \
    --arg phase_overview "${phase_overview:-No overview}" \
    --arg master_overview "${master_overview:-No overview}" \
    '{phase_name: $phase_name, phase_overview: $phase_overview, master_overview: $master_overview, current_level: "1"}')

  # Extract all stages from phase file
  local stage_count=0
  local content_array="[]"

  while IFS= read -r line; do
    if [[ "$line" =~ ^####[[:space:]]Stage[[:space:]]([0-9]+):[[:space:]](.+)$ ]]; then
      local stage_num="${BASH_REMATCH[1]}"
      local stage_name="${BASH_REMATCH[2]}"

      # Check if stage is already expanded
      if is_stage_expanded "$phase_file" "$stage_num"; then
        echo "  Stage $stage_num already expanded, skipping" >&2
        continue
      fi

      # Extract stage content
      local stage_content
      stage_content=$(extract_stage_content "$phase_file" "$stage_num" | head -15 | tr '\n' ' ')

      content_array=$(echo "$content_array" | jq \
        --arg id "stage_$stage_num" \
        --arg name "$stage_name" \
        --arg content "${stage_content:-No content}" \
        '. += [{item_id: $id, item_name: $name, content: $content}]')

      stage_count=$((stage_count + 1))
    fi
  done < "$phase_file"

  if [[ $stage_count -eq 0 ]]; then
    echo "No inline stages found in phase $phase_num" >&2
    echo "[]"
    return 0
  fi

  echo "Found $stage_count inline stages to analyze" >&2
  echo "" >&2

  # Invoke agent
  invoke_complexity_estimator "expansion" "$content_array" "$context_json"
}

# Analyze expanded stages for collapse
# Args:
#   $1 - plan_path: Path to plan
#   $2 - phase_num: Phase number
# Returns:
#   JSON array of collapse recommendations
analyze_stages_for_collapse() {
  local plan_path="$1"
  local phase_num="$2"

  # Get phase file and directory
  local phase_file
  phase_file=$(get_phase_file "$plan_path" "$phase_num")

  local phase_dir="${phase_file%.md}"

  if [[ ! -d "$phase_dir" ]]; then
    echo "No expanded stages in phase $phase_num" >&2
    echo "[]"
    return 0
  fi

  echo "Analyzing expanded stages for collapse in phase $phase_num" >&2
  echo "" >&2

  # Extract context
  local phase_name phase_overview
  phase_name=$(extract_phase_name "$phase_file")
  phase_overview=$(head -30 "$phase_file" | tail -20 | tr '\n' ' ')

  local context_json
  context_json=$(jq -n \
    --arg phase_name "$phase_name" \
    --arg overview "${phase_overview:-No overview}" \
    '{phase_name: $phase_name, phase_overview: $overview, current_level: "2"}')

  # Get list of expanded stages
  local expanded_stages
  expanded_stages=$(list_expanded_stages "$phase_file")

  if [[ -z "$expanded_stages" ]]; then
    echo "No expanded stages found" >&2
    echo "[]"
    return 0
  fi

  # Build content array
  local content_array="[]"
  local stage_count=0

  while IFS= read -r stage_num; do
    local stage_file="$phase_dir/stage_${stage_num}_*.md"
    stage_file=$(ls $stage_file 2>/dev/null | head -1)

    if [[ ! -f "$stage_file" ]]; then
      echo "WARNING: Stage file not found for stage $stage_num" >&2
      continue
    fi

    local stage_name
    stage_name=$(extract_stage_name "$stage_file")

    local stage_content
    stage_content=$(head -40 "$stage_file" | tail -30 | tr '\n' ' ')

    content_array=$(echo "$content_array" | jq \
      --arg id "stage_$stage_num" \
      --arg name "$stage_name" \
      --arg content "${stage_content:-Empty}" \
      '. += [{item_id: $id, item_name: $name, content: $content}]')

    stage_count=$((stage_count + 1))
  done <<< "$expanded_stages"

  if [[ $stage_count -eq 0 ]]; then
    echo "No stages eligible for collapse" >&2
    echo "[]"
    return 0
  fi

  echo "Found $stage_count expanded stages to analyze" >&2
  echo "" >&2

  # Invoke agent
  invoke_complexity_estimator "collapse" "$content_array" "$context_json"
}

# Export functions for use by sourcing scripts
export -f analyze_stages_for_expansion
export -f analyze_stages_for_collapse
