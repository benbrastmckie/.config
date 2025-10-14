#!/usr/bin/env bash
#
# Structure Evaluation Utilities
# Provides functions for evaluating collapse/expansion opportunities in plan structures
#
# Usage:
#   source .claude/lib/structure-eval-utils.sh
#   should_collapse=$(evaluate_collapse_opportunity 3 "specs/plans/my_plan/")
#   should_expand=$(evaluate_expansion_opportunity 5 "specs/plans/my_plan.md")
#

set -euo pipefail

# Detect project directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/detect-project-dir.sh"

#
# Evaluate if an expanded phase should be collapsed
# Args:
#   $1: phase_num
#   $2: plan_path
# Returns: "true" or "false" (echoed to stdout)
#
evaluate_collapse_opportunity() {
  local phase_num="$1"
  local plan_path="$2"

  # Source required utilities
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-plan-core.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-structure-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-metadata-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

  # Get phase file path
  local phase_file
  phase_file=$(get_phase_file "$plan_path" "$phase_num" 2>/dev/null || echo "")

  if [ -z "$phase_file" ] || [ ! -f "$phase_file" ]; then
    echo "false"
    return 0
  fi

  # Extract phase content for analysis
  local phase_content
  phase_content=$(cat "$phase_file" 2>/dev/null || echo "")

  if [ -z "$phase_content" ]; then
    echo "false"
    return 0
  fi

  local phase_name
  phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//' || echo "")

  if [ -z "$phase_name" ]; then
    echo "false"
    return 0
  fi

  # Count tasks (both checked and unchecked)
  local task_count
  task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]" 2>/dev/null || echo "0")

  # Calculate complexity score
  local complexity_score
  complexity_score=$(calculate_phase_complexity "$phase_name" "$phase_content")

  # Collapse thresholds: tasks ≤ 5 AND complexity < 6.0
  if [ "$task_count" -le 5 ]; then
    # Use awk for floating point comparison
    if awk -v score="$complexity_score" 'BEGIN {exit !(score < 6.0)}'; then
      echo "true"
      return 0
    fi
  fi

  echo "false"
  return 1
}

#
# Evaluate if an inline phase should be expanded
# Args:
#   $1: phase_num
#   $2: plan_path
# Returns: "true" or "false" (echoed to stdout)
#
evaluate_expansion_opportunity() {
  local phase_num="$1"
  local plan_path="$2"

  # Source required utilities
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-plan-core.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-structure-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-metadata-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

  # Determine main plan file location
  local plan_file="$plan_path"
  if [ -d "$plan_path" ]; then
    local plan_name
    plan_name=$(basename "$plan_path")
    plan_file="$plan_path/$plan_name.md"
  fi

  if [ ! -f "$plan_file" ]; then
    echo "false"
    return 1
  fi

  # Extract phase content from main plan
  local phase_content
  phase_content=$(extract_phase_content "$plan_file" "$phase_num" 2>/dev/null || echo "")

  if [ -z "$phase_content" ]; then
    echo "false"
    return 0
  fi

  # Extract phase name
  local phase_name
  phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//' || echo "")

  if [ -z "$phase_name" ]; then
    echo "false"
    return 0
  fi

  # Count tasks
  local task_count
  task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]" 2>/dev/null || echo "0")

  # Calculate complexity score
  local complexity_score
  complexity_score=$(calculate_phase_complexity "$phase_name" "$phase_content")

  # Expansion thresholds: tasks > 10 OR complexity > 8.0
  if [ "$task_count" -gt 10 ]; then
    echo "true"
    return 0
  fi

  # Use awk for floating point comparison
  if awk -v score="$complexity_score" 'BEGIN {exit !(score > 8.0)}'; then
    echo "true"
    return 0
  fi

  echo "false"
  return 1
}

#
# Get list of phases affected by revision
# Args:
#   $1: plan_path
#   $2: revision_description (from user input or auto-mode context)
# Returns: Space-separated list of phase numbers (echoed to stdout)
#
get_affected_phases() {
  local plan_path="$1"
  local revision_desc="$2"

  # Approach 1: Parse revision description for phase mentions
  # Look for patterns: "Phase 2", "Phase 3 and 4", "Phases 2, 3, 5"
  local phases
  phases=$(echo "$revision_desc" | grep -oE "Phase [0-9]+" | sed 's/Phase //' | sort -n | uniq | tr '\n' ' ')

  # Approach 2: If no explicit mentions, check all phases (conservative)
  if [ -z "$phases" ]; then
    # Count total phases in plan
    local plan_file="$plan_path"
    if [ -d "$plan_path" ]; then
      local plan_name
      plan_name=$(basename "$plan_path")
      plan_file="$plan_path/$plan_name.md"
    fi

    local total_phases
    total_phases=$(grep -c "^### Phase [0-9]" "$plan_file" 2>/dev/null || echo "0")
    phases=$(seq 1 "$total_phases" | tr '\n' ' ')
  fi

  echo "$phases"
}

#
# Display structure optimization recommendations
# Args:
#   $1: plan_path
#   $2: affected_phases (space-separated list)
# Output: Formatted recommendations to stdout
#
display_structure_recommendations() {
  local plan_path="$1"
  local affected_phases="$2"

  # Source required utilities
  source "$CLAUDE_PROJECT_DIR/.claude/lib/parse-plan-core.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-structure-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/plan-metadata-utils.sh"
  source "$CLAUDE_PROJECT_DIR/.claude/lib/complexity-utils.sh"

  local collapse_recommendations=()
  local expansion_recommendations=()

  # Evaluate each affected phase
  for phase_num in $affected_phases; do
    # Check current state
    local is_expanded
    is_expanded=$(is_phase_expanded "$plan_path" "$phase_num")

    if [ "$is_expanded" = "true" ]; then
      # Evaluate collapse
      local should_collapse
      should_collapse=$(evaluate_collapse_opportunity "$phase_num" "$plan_path")

      if [ "$should_collapse" = "true" ]; then
        # Get phase details for display
        local phase_file
        phase_file=$(get_phase_file "$plan_path" "$phase_num")

        local task_count
        task_count=$(grep -c "^- \[[ x]\]" "$phase_file" || echo "0")

        local phase_name
        phase_name=$(grep "^### Phase $phase_num" "$phase_file" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//')

        local complexity
        complexity=$(calculate_phase_complexity "$phase_name" "$(cat "$phase_file")")

        collapse_recommendations+=("Phase $phase_num: $phase_name (${task_count} tasks, complexity ${complexity})")
      fi
    else
      # Evaluate expansion
      local should_expand
      should_expand=$(evaluate_expansion_opportunity "$phase_num" "$plan_path")

      if [ "$should_expand" = "true" ]; then
        # Get phase details
        local plan_file="$plan_path"
        if [ -d "$plan_path" ]; then
          plan_file="$plan_path/$(basename "$plan_path").md"
        fi

        local phase_content
        phase_content=$(extract_phase_content "$plan_file" "$phase_num")

        local task_count
        task_count=$(echo "$phase_content" | grep -c "^- \[[ x]\]" || echo "0")

        local phase_name
        phase_name=$(echo "$phase_content" | grep "^### Phase $phase_num" | head -1 | sed "s/^### Phase $phase_num:* //" | sed 's/ \[.*\]$//')

        local complexity
        complexity=$(calculate_phase_complexity "$phase_name" "$phase_content")

        expansion_recommendations+=("Phase $phase_num: $phase_name (${task_count} tasks, complexity ${complexity})")
      fi
    fi
  done

  # Display recommendations if any exist
  if [ ${#collapse_recommendations[@]} -gt 0 ] || [ ${#expansion_recommendations[@]} -gt 0 ]; then
    echo ""
    echo "**Structure Recommendations**:"

    # Collapse recommendations
    if [ ${#collapse_recommendations[@]} -gt 0 ]; then
      echo ""
      echo "*Collapse Opportunities (simple expanded phases):*"
      for rec in "${collapse_recommendations[@]}"; do
        local phase_num
        phase_num=$(echo "$rec" | grep -oE "Phase [0-9]+" | sed 's/Phase //')
        echo "- $rec"
        echo "  - Command: \`/collapse phase $(realpath "$plan_path") $phase_num\`"
      done
    fi

    # Expansion recommendations
    if [ ${#expansion_recommendations[@]} -gt 0 ]; then
      echo ""
      echo "*Expansion Opportunities (complex inline phases):*"
      for rec in "${expansion_recommendations[@]}"; do
        local phase_num
        phase_num=$(echo "$rec" | grep -oE "Phase [0-9]+" | sed 's/Phase //')
        echo "- $rec"
        echo "  - Command: \`/expand phase $(realpath "$plan_path") $phase_num\`"
      done
    fi
  fi
}

# Export functions for use in other scripts
export -f evaluate_collapse_opportunity
export -f evaluate_expansion_opportunity
export -f get_affected_phases
export -f display_structure_recommendations
