#!/usr/bin/env bash
# analysis-pattern.sh - Unified expansion and collapse analysis for phases and stages
# Part of .claude/lib/ modular utilities
#
# Functions:
#   analyze_items_for_expansion - Generic expansion analysis
#   analyze_items_for_collapse - Generic collapse analysis
#   analyze_phases_for_expansion - Wrapper for phase expansion analysis
#   analyze_phases_for_collapse - Wrapper for phase collapse analysis
#   analyze_stages_for_expansion - Wrapper for stage expansion analysis
#   analyze_stages_for_collapse - Wrapper for stage collapse analysis
#
# Usage:
#   source "${BASH_SOURCE%/*}/analysis-pattern.sh"
#   analyze_phases_for_expansion "$plan_path"
#   analyze_phases_for_collapse "$plan_path"
#   analyze_stages_for_expansion "$plan_path" "$phase_num"
#   analyze_stages_for_collapse "$plan_path" "$phase_num"

set -euo pipefail

# ============================================================================
# Generic Analysis Pattern
# ============================================================================

# Generic expansion analysis
# Args:
#   $1 - item_type: "phase" or "stage"
#   $2 - source_file: Path to file containing items
#   $3 - context_json: JSON object with overview, goals, constraints
#   $4 - parent_item: (optional) Parent item ID for stages
# Returns:
#   JSON array of expansion recommendations
analyze_items_for_expansion() {
  local item_type="$1"
  local source_file="$2"
  local context_json="$3"
  local parent_item="${4:-}"

  if [[ ! -f "$source_file" ]]; then
    echo "ERROR: Source file not found: $source_file" >&2
    return 1
  fi

  local item_type_cap="${item_type^}"  # Capitalize
  local item_pattern="^###[[:space:]]${item_type_cap}[[:space:]]([0-9]+):[[:space:]](.+)$"

  echo "Analyzing ${item_type}s for expansion in: $source_file" >&2
  echo "" >&2

  # Extract all items
  local item_count=0
  local content_array="[]"

  while IFS= read -r line; do
    if [[ "$line" =~ $item_pattern ]]; then
      local item_num="${BASH_REMATCH[1]}"
      local item_name="${BASH_REMATCH[2]}"

      # Check if item is already expanded
      local source_dir="${source_file%.md}"
      local expected_file="${source_dir}/${item_type}_${item_num}.md"

      if [[ -f "$expected_file" ]]; then
        echo "  ${item_type_cap} $item_num already expanded, skipping" >&2
        continue
      fi

      # Extract item content (first 20 lines)
      local item_content
      item_content=$(awk "/${item_pattern}/,/^###[[:space:]]/ {print}" "$source_file" | head -20 | tr '\n' ' ')

      # Add to content array
      local item_id="${item_type}_${item_num}"
      if [[ -n "$parent_item" ]]; then
        item_id="${parent_item}_${item_type}_${item_num}"
      fi

      content_array=$(echo "$content_array" | jq \
        --arg id "$item_id" \
        --arg name "$item_name" \
        --arg content "${item_content:-No content}" \
        '. += [{item_id: $id, item_name: $name, content: $content}]')

      item_count=$((item_count + 1))
    fi
  done < "$source_file"

  if [[ $item_count -eq 0 ]]; then
    echo "No inline ${item_type}s found to analyze" >&2
    echo "[]"
    return 0
  fi

  echo "Found $item_count inline ${item_type}s to analyze" >&2
  echo "" >&2

  # Invoke complexity estimator (via agent-invocation.sh)
  if command -v invoke_complexity_estimator &>/dev/null; then
    invoke_complexity_estimator "expansion" "$content_array" "$context_json"
  else
    echo "[]"
    echo "WARNING: invoke_complexity_estimator not available" >&2
  fi
}

# Generic collapse analysis
# Args:
#   $1 - item_type: "phase" or "stage"
#   $2 - source_path: Path to directory containing expanded items
#   $3 - context_json: JSON object with overview, goals
# Returns:
#   JSON array of collapse recommendations
analyze_items_for_collapse() {
  local item_type="$1"
  local source_path="$2"
  local context_json="$3"

  local item_type_cap="${item_type^}"

  # Get directory containing expanded items
  local search_dir
  if [[ -d "$source_path" ]]; then
    search_dir="$source_path"
  elif [[ -f "$source_path" ]]; then
    search_dir="${source_path%.md}"
  else
    echo "ERROR: Invalid source path: $source_path" >&2
    return 1
  fi

  if [[ ! -d "$search_dir" ]]; then
    echo "No expanded ${item_type}s found (not a directory)" >&2
    echo "[]"
    return 0
  fi

  echo "Analyzing expanded ${item_type}s for collapse in: $search_dir" >&2
  echo "" >&2

  # Find all expanded item files
  local content_array="[]"
  local item_count=0

  while IFS= read -r item_file; do
    local item_name
    item_name=$(basename "$item_file" .md)

    # Extract item number
    local item_num
    if [[ "$item_name" =~ ${item_type}_([0-9]+)$ ]]; then
      item_num="${BASH_REMATCH[1]}"
    else
      continue
    fi

    # Check if item has sub-expansions (stages for phases, etc.)
    if [[ -d "${item_file%.md}" ]]; then
      echo "  ${item_type_cap} $item_num has sub-expansions, will skip" >&2
      continue
    fi

    # Extract item content (first 50 lines, skip first 10)
    local item_content
    item_content=$(head -50 "$item_file" | tail -40 | tr '\n' ' ')

    # Extract item title
    local item_title
    item_title=$(grep -m 1 "^#" "$item_file" | sed 's/^#*[[:space:]]*//' || echo "$item_name")

    content_array=$(echo "$content_array" | jq \
      --arg id "${item_type}_${item_num}" \
      --arg name "$item_title" \
      --arg content "${item_content:-Empty}" \
      --arg file "$item_file" \
      '. += [{item_id: $id, item_name: $name, content: $content, file_path: $file}]')

    item_count=$((item_count + 1))
  done < <(find "$search_dir" -maxdepth 1 -name "${item_type}_*.md" -type f 2>/dev/null | sort)

  if [[ $item_count -eq 0 ]]; then
    echo "No expanded ${item_type}s eligible for collapse" >&2
    echo "[]"
    return 0
  fi

  echo "Found $item_count expanded ${item_type}s to analyze" >&2
  echo "" >&2

  # Invoke complexity estimator
  if command -v invoke_complexity_estimator &>/dev/null; then
    invoke_complexity_estimator "collapse" "$content_array" "$context_json"
  else
    echo "[]"
    echo "WARNING: invoke_complexity_estimator not available" >&2
  fi
}

# ============================================================================
# Phase Analysis Wrappers
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

  # Extract plan context
  local overview goals constraints
  overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$plan_path" | sed '/^$/d' | head -5 | tr '\n' ' ')
  goals=$(awk '/^## Success Criteria$/,/^##[^#]/ {if (!/^##/) print}' "$plan_path" | sed '/^$/d' | head -5 | tr '\n' ' ')
  constraints=$(awk '/^## Risk Assessment$/,/^##[^#]/ {if (!/^##/) print}' "$plan_path" | sed '/^$/d' | head -3 | tr '\n' ' ')

  local context_json
  context_json=$(jq -n \
    --arg overview "${overview:-No overview available}" \
    --arg goals "${goals:-No goals specified}" \
    --arg constraints "${constraints:-No constraints specified}" \
    --arg level "0" \
    '{overview: $overview, goals: $goals, constraints: $constraints, current_level: $level}')

  analyze_items_for_expansion "phase" "$plan_path" "$context_json"
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
  if [[ -d "$plan_path" ]]; then
    plan_dir="$plan_path"
  elif [[ -f "$plan_path" ]]; then
    plan_dir="${plan_path%.md}"
  else
    echo "ERROR: Invalid plan path: $plan_path" >&2
    return 1
  fi

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

  # Extract plan context
  local overview goals
  overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -5 | tr '\n' ' ')
  goals=$(awk '/^## Success Criteria$/,/^##[^#]/ {if (!/^##/) print}' "$main_plan" | sed '/^$/d' | head -5 | tr '\n' ' ')

  local context_json
  context_json=$(jq -n \
    --arg overview "${overview:-No overview}" \
    --arg goals "${goals:-No goals}" \
    '{overview: $overview, goals: $goals, current_level: "1"}')

  analyze_items_for_collapse "phase" "$plan_dir" "$context_json"
}

# ============================================================================
# Stage Analysis Wrappers
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
  local plan_dir
  if [[ -d "$plan_path" ]]; then
    plan_dir="$plan_path"
  else
    plan_dir="${plan_path%.md}"
  fi

  phase_file="${plan_dir}/phase_${phase_num}.md"

  if [[ ! -f "$phase_file" ]]; then
    echo "ERROR: Phase file not found: $phase_file" >&2
    return 1
  fi

  echo "Analyzing stages in phase $phase_num" >&2

  # Extract phase context
  local phase_name phase_overview
  phase_name=$(grep -m 1 "^#" "$phase_file" | sed 's/^#*[[:space:]]*//' || echo "Phase $phase_num")
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
    --arg phase_overview "${phase_overview:-No phase overview}" \
    --arg master_overview "${master_overview:-No plan overview}" \
    --arg phase_num "$phase_num" \
    '{phase_name: $phase_name, phase_overview: $phase_overview, master_overview: $master_overview, phase_num: $phase_num, current_level: "1"}')

  analyze_items_for_expansion "stage" "$phase_file" "$context_json" "phase_${phase_num}"
}

# Analyze stages within a phase for collapse
# Args:
#   $1 - plan_path: Path to plan
#   $2 - phase_num: Phase number
# Returns:
#   JSON array of collapse recommendations
analyze_stages_for_collapse() {
  local plan_path="$1"
  local phase_num="$2"

  # Get phase directory
  local plan_dir
  if [[ -d "$plan_path" ]]; then
    plan_dir="$plan_path"
  else
    plan_dir="${plan_path%.md}"
  fi

  local phase_dir="${plan_dir}/phase_${phase_num}"

  if [[ ! -d "$phase_dir" ]]; then
    echo "No expanded stages found in phase $phase_num" >&2
    echo "[]"
    return 0
  fi

  echo "Analyzing expanded stages for collapse in phase $phase_num" >&2

  # Get phase file for context
  local phase_file="${plan_dir}/phase_${phase_num}.md"
  local phase_overview=""
  if [[ -f "$phase_file" ]]; then
    phase_overview=$(awk '/^## Overview$/,/^##[^#]/ {if (!/^##/) print}' "$phase_file" | sed '/^$/d' | head -5 | tr '\n' ' ')
  fi

  local context_json
  context_json=$(jq -n \
    --arg overview "${phase_overview:-No overview}" \
    --arg phase_num "$phase_num" \
    '{overview: $overview, phase_num: $phase_num, current_level: "2"}')

  analyze_items_for_collapse "stage" "$phase_dir" "$context_json"
}

# Export functions for use by sourcing scripts
export -f analyze_items_for_expansion
export -f analyze_items_for_collapse
export -f analyze_phases_for_expansion
export -f analyze_phases_for_collapse
export -f analyze_stages_for_expansion
export -f analyze_stages_for_collapse
