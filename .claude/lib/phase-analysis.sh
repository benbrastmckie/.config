#!/usr/bin/env bash
# phase-analysis.sh - Phase expansion and collapse analysis
# Part of .claude/lib/ modular utilities
#
# Functions:
#   analyze_phases_for_expansion - Analyze inline phases for expansion candidates
#   analyze_phases_for_collapse - Analyze expanded phases for collapse candidates
#
# Usage:
#   source "${BASH_SOURCE%/*}/phase-analysis.sh"
#   analyze_phases_for_expansion "$plan_path"
#   analyze_phases_for_collapse "$plan_path"

set -euo pipefail

# ============================================================================
# Phase Analysis Functions
# ============================================================================

# Analyze all inline phases for expansion
# Args:
#   $1 - plan_path: Path to plan file
# Returns:
#   JSON array of phase recommendations
analyze_phases_for_expansion() {
  local plan_path="$1"

  if [[ ! -f "$plan_path" ]]; then
    echo "ERROR: Plan file not found: $plan_path" >&2
    return 1
  fi

  # Detect structure level
  local structure_level
  structure_level=$(detect_structure_level "$plan_path")

  echo "Analyzing phases in: $plan_path" >&2
  echo "Structure level: $structure_level" >&2
  echo "" >&2

  # Extract plan context (overview, goals, constraints)
  local overview goals constraints
  overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$plan_path" | sed '/^$/d' | head -5 | tr '\n' ' ')
  goals=$(awk '/^## Success Criteria$/,/^##[^#]/ {if (!/^##/) print}' "$plan_path" | sed '/^$/d' | head -5 | tr '\n' ' ')
  constraints=$(awk '/^## Risk Assessment$/,/^##[^#]/ {if (!/^##/) print}' "$plan_path" | sed '/^$/d' | head -3 | tr '\n' ' ')

  # Build context JSON
  local context_json
  context_json=$(jq -n \
    --arg overview "${overview:-No overview available}" \
    --arg goals "${goals:-No goals specified}" \
    --arg constraints "${constraints:-No constraints specified}" \
    --arg level "$structure_level" \
    '{overview: $overview, goals: $goals, constraints: $constraints, current_level: $level}')

  # Extract all phases
  local phase_count=0
  local content_array="[]"

  # Find all phase headings (### Phase N:)
  while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]Phase[[:space:]]([0-9]+):[[:space:]](.+)$ ]]; then
      local phase_num="${BASH_REMATCH[1]}"
      local phase_name="${BASH_REMATCH[2]}"

      # Check if phase is already expanded
      if is_phase_expanded "$plan_path" "$phase_num"; then
        echo "  Phase $phase_num already expanded, skipping" >&2
        continue
      fi

      # Extract phase content
      local phase_content
      phase_content=$(extract_phase_content "$plan_path" "$phase_num" | head -20 | tr '\n' ' ')

      # Add to content array
      content_array=$(echo "$content_array" | jq \
        --arg id "phase_$phase_num" \
        --arg name "$phase_name" \
        --arg content "${phase_content:-No content}" \
        '. += [{item_id: $id, item_name: $name, content: $content}]')

      phase_count=$((phase_count + 1))
    fi
  done < "$plan_path"

  if [[ $phase_count -eq 0 ]]; then
    echo "No inline phases found to analyze" >&2
    echo "[]"
    return 0
  fi

  echo "Found $phase_count inline phases to analyze" >&2
  echo "" >&2

  # Invoke agent (returns prompt for now, real invocation in command layer)
  invoke_complexity_estimator "expansion" "$content_array" "$context_json"
}

# Analyze expanded phases for collapse
# Args:
#   $1 - plan_path: Path to plan file or directory
# Returns:
#   JSON array of collapse recommendations
analyze_phases_for_collapse() {
  local plan_path="$1"

  # Get plan directory
  local plan_dir
  plan_dir=$(get_plan_directory "$plan_path")

  if [[ ! -d "$plan_dir" ]]; then
    echo "No expanded phases found (not a directory)" >&2
    echo "[]"
    return 0
  fi

  # Find main plan file
  local main_plan
  main_plan=$(find "$plan_dir" -maxdepth 1 -name "*.md" -type f | head -1)

  if [[ -z "$main_plan" ]]; then
    echo "ERROR: No main plan file found in $plan_dir" >&2
    return 1
  fi

  echo "Analyzing expanded phases for collapse in: $plan_dir" >&2
  echo "" >&2

  # Extract plan context
  local overview goals
  overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -5 | tr '\n' ' ')
  goals=$(awk '/^## Success Criteria$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -5 | tr '\n' ' ')

  local context_json
  context_json=$(jq -n \
    --arg overview "${overview:-No overview}" \
    --arg goals "${goals:-No goals}" \
    '{overview: $overview, goals: $goals, current_level: "1"}')

  # Get list of expanded phases
  local expanded_phases
  expanded_phases=$(list_expanded_phases "$plan_path")

  if [[ -z "$expanded_phases" ]]; then
    echo "No expanded phases found" >&2
    echo "[]"
    return 0
  fi

  # Build content array from expanded phase files
  local content_array="[]"
  local phase_count=0

  while IFS= read -r phase_num; do
    local phase_file
    phase_file=$(get_phase_file "$plan_path" "$phase_num")

    if [[ ! -f "$phase_file" ]]; then
      echo "WARNING: Phase file not found: $phase_file" >&2
      continue
    fi

    # Check if phase has expanded stages (cannot collapse if it does)
    local has_stages=false
    if [[ -d "${phase_file%.md}" ]]; then
      has_stages=true
      echo "  Phase $phase_num has expanded stages, will skip" >&2
      continue
    fi

    local phase_name
    phase_name=$(extract_phase_name "$phase_file")

    local phase_content
    phase_content=$(head -50 "$phase_file" | tail -40 | tr '\n' ' ')

    content_array=$(echo "$content_array" | jq \
      --arg id "phase_$phase_num" \
      --arg name "$phase_name" \
      --arg content "${phase_content:-Empty}" \
      --arg file "$phase_file" \
      '. += [{item_id: $id, item_name: $name, content: $content, file_path: $file}]')

    phase_count=$((phase_count + 1))
  done <<< "$expanded_phases"

  if [[ $phase_count -eq 0 ]]; then
    echo "No expanded phases eligible for collapse" >&2
    echo "[]"
    return 0
  fi

  echo "Found $phase_count expanded phases to analyze" >&2
  echo "" >&2

  # Invoke agent
  invoke_complexity_estimator "collapse" "$content_array" "$context_json"
}

# Export functions for use by sourcing scripts
export -f analyze_phases_for_expansion
export -f analyze_phases_for_collapse
