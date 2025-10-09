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

# ============================================================================
# Agent Invocation Function
# ============================================================================

# Invoke complexity_estimator agent via general-purpose type
# Args:
#   $1 - mode: "expansion" or "collapse"
#   $2 - content_json: JSON array of items to analyze
#   $3 - context_json: JSON object with parent context
# Returns:
#   JSON array with agent's decisions (via stdout)
#   Exit 0 on success, non-zero on failure
invoke_complexity_estimator() {
  local mode="$1"
  local content_json="$2"
  local context_json="$3"

  # Validate inputs
  if [[ -z "$mode" ]] || [[ -z "$content_json" ]] || [[ -z "$context_json" ]]; then
    echo "ERROR: invoke_complexity_estimator requires mode, content_json, and context_json" >&2
    return 1
  fi

  if [[ "$mode" != "expansion" ]] && [[ "$mode" != "collapse" ]]; then
    echo "ERROR: mode must be 'expansion' or 'collapse', got: $mode" >&2
    return 1
  fi

  # Validate JSON inputs
  if ! echo "$content_json" | jq empty 2>/dev/null; then
    echo "ERROR: content_json is not valid JSON" >&2
    return 1
  fi

  if ! echo "$context_json" | jq empty 2>/dev/null; then
    echo "ERROR: context_json is not valid JSON" >&2
    return 1
  fi

  # Count items for progress indication
  local item_count
  item_count=$(echo "$content_json" | jq 'length')

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Invoking Complexity Estimator Agent" >&2
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
  echo "Mode: $mode" >&2
  echo "Items to analyze: $item_count" >&2
  echo "Estimated time: 20-40 seconds" >&2
  echo "" >&2

  # Build agent prompt
  local agent_file="/home/benjamin/.config/.claude/agents/complexity_estimator.md"
  local task_description

  if [[ "$mode" == "expansion" ]]; then
    task_description="Analyze complexity for expansion decisions"
  else
    task_description="Analyze complexity for collapse decisions"
  fi

  # Construct prompt following agent-integration-guide pattern
  local prompt
  prompt=$(cat <<EOF
Read and follow the behavioral guidelines from:
$agent_file

You are acting as a Complexity Estimator with constraints:
- Read-only operations (tools: Read, Grep, Glob only)
- Context-aware analysis (not just keyword matching)
- JSON output with structured recommendations

Analysis Task: $(echo "$mode" | sed 's/^./\U&/') Analysis

Parent Plan Context:
$(echo "$context_json" | jq -r '
  "  Overview: " + (.overview // "Not provided") + "\n" +
  "  Goals: " + (.goals // "Not provided") + "\n" +
  "  Constraints: " + (.constraints // "Not provided")
')

Current Structure Level: $(echo "$context_json" | jq -r '.current_level // "0"')

Items to Analyze:
$(echo "$content_json" | jq -r '.[] |
  "  " + .item_id + ": " + .item_name + "\n" +
  "    Content: " + .content + "\n"
')

For each item, provide:
- item_id: The item identifier (e.g., "phase_1")
- item_name: The item name
- complexity_level: Integer 1-10 scale
- reasoning: Context-aware explanation (consider architecture, integration, risk, testing)
- recommendation: "expand" or "skip" (for expansion mode), "collapse" or "keep" (for collapse mode)
- confidence: "low", "medium", or "high"

Output Format: JSON array only (no markdown, no code blocks, just raw JSON)
EOF
)

  # Note: This is a simulation since we can't actually invoke Task tool from bash
  # In production, this would be handled by the command layer (expand.md/collapse.md)
  # which has access to Task tool

  # For now, echo the prompt that should be used
  echo "AGENT_PROMPT_START" >&2
  echo "$prompt" >&2
  echo "AGENT_PROMPT_END" >&2
  echo "" >&2
  echo "NOTE: Actual agent invocation must be done from command layer using Task tool" >&2
  echo "      This function returns the prompt to use for invocation" >&2

  # Return placeholder JSON for testing
  # Real implementation would capture agent output
  echo '[{"item_id":"placeholder","complexity_level":5,"reasoning":"placeholder","recommendation":"skip","confidence":"medium"}]'

  return 0
}

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
fi
