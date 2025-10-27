#!/usr/bin/env bash
# Report Generation
# Extracted from artifact-operations.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/unified-logger.sh"

# Functions:

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
    local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/approval-decisions.log"

    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] APPROVED: $context ($rec_count recommendations)" >> "$log_file"

    return 0
  else
    echo "" >&2
    echo "✗ Recommendations rejected by user" >&2
    echo "" >&2

    # Log rejection
    local log_dir="${CLAUDE_PROJECT_DIR}/.claude/data/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/approval-decisions.log"

    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] REJECTED: $context ($rec_count recommendations)" >> "$log_file"

    return 1
  fi
}

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

# Export functions
export -f generate_analysis_report
export -f review_plan_hierarchy
export -f run_second_round_analysis
export -f present_recommendations_for_approval
export -f generate_recommendations_report