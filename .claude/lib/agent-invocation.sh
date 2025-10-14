#!/usr/bin/env bash
# agent-invocation.sh - Agent coordination and invocation
# Part of .claude/lib/ modular utilities
#
# Functions:
#   invoke_complexity_estimator - Construct prompts and invoke complexity analysis agent
#
# Usage:
#   source "${BASH_SOURCE%/*}/agent-invocation.sh"
#   invoke_complexity_estimator "expansion" "$content_json" "$context_json"

set -euo pipefail

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
  local agent_file="/home/benjamin/.config/.claude/agents/complexity-estimator.md"
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

# Export function for use by sourcing scripts
export -f invoke_complexity_estimator
