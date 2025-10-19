#!/usr/bin/env bash
#
# Agent Registry Utilities
# Functions for reading and updating agent-registry.json
#
# Usage:
#   source .claude/lib/agent-registry-utils.sh
#   update_agent_metrics "agent-name" "success" 1500
#   get_agent_info "agent-name"
#

set -euo pipefail

# Configuration
readonly REGISTRY_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/agents/agent-registry.json"

# Ensure registry file exists
ensure_registry_exists() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    mkdir -p "$(dirname "$REGISTRY_FILE")"
    cat > "$REGISTRY_FILE" <<'EOF'
{
  "agents": {},
  "metadata": {
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "description": "Agent performance tracking registry",
    "version": "1.0"
  }
}
EOF
  fi
}

#
# register_agent - Add or update agent entry in registry
#
# Arguments:
#   $1 - agent_name
#   $2 - agent_type (specialized/general-purpose)
#   $3 - description
#   $4 - tools (comma-separated string)
#
register_agent() {
  local agent_name="$1"
  local agent_type="$2"
  local description="$3"
  local tools="$4"

  ensure_registry_exists

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    echo "Warning: jq not available, skipping agent registration" >&2
    return 1
  fi

  # Convert comma-separated tools to JSON array
  local tools_json
  tools_json=$(echo "$tools" | jq -R 'split(",") | map(. | gsub("^\\s+|\\s+$"; ""))')

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Use atomic write: create temp file, then move
  local temp_file="${REGISTRY_FILE}.tmp.$$"

  jq \
    --arg agent "$agent_name" \
    --arg type "$agent_type" \
    --arg desc "$description" \
    --argjson tools "$tools_json" \
    --arg timestamp "$timestamp" \
    '.agents[$agent] = {
      type: $type,
      description: $desc,
      tools: $tools,
      total_invocations: (.agents[$agent].total_invocations // 0),
      successes: (.agents[$agent].successes // 0),
      total_duration_ms: (.agents[$agent].total_duration_ms // 0),
      avg_duration_ms: (.agents[$agent].avg_duration_ms // 0),
      success_rate: (.agents[$agent].success_rate // 0.0),
      last_execution: (.agents[$agent].last_execution // null),
      last_status: (.agents[$agent].last_status // null)
    } | .metadata.last_updated = $timestamp' \
    "$REGISTRY_FILE" > "$temp_file"

  # Atomic move
  mv "$temp_file" "$REGISTRY_FILE"

  return 0
}

#
# update_agent_metrics - Update agent performance metrics
#
# Arguments:
#   $1 - agent_name
#   $2 - status (success/failure)
#   $3 - duration_ms
#
update_agent_metrics() {
  local agent_name="$1"
  local status="$2"
  local duration_ms="$3"

  ensure_registry_exists

  # Check if jq is available
  if ! command -v jq &> /dev/null; then
    return 1
  fi

  # Check if agent exists
  if ! jq -e ".agents.\"$agent_name\"" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Warning: Agent '$agent_name' not found in registry, skipping metrics update" >&2
    return 1
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Use atomic write
  local temp_file="${REGISTRY_FILE}.tmp.$$"

  # Read current values
  local total_invocations
  local successes
  local total_duration

  total_invocations=$(jq -r ".agents.\"$agent_name\".total_invocations // 0" "$REGISTRY_FILE")
  successes=$(jq -r ".agents.\"$agent_name\".successes // 0" "$REGISTRY_FILE")
  total_duration=$(jq -r ".agents.\"$agent_name\".total_duration_ms // 0" "$REGISTRY_FILE")

  # Update counters
  total_invocations=$((total_invocations + 1))
  total_duration=$((total_duration + duration_ms))

  if [[ "$status" == "success" ]]; then
    successes=$((successes + 1))
  fi

  # Calculate metrics
  local avg_duration=$((total_duration / total_invocations))
  local success_rate
  success_rate=$(awk "BEGIN {printf \"%.3f\", $successes / $total_invocations}")

  # Update registry
  jq \
    --arg agent "$agent_name" \
    --argjson invocations "$total_invocations" \
    --argjson successes "$successes" \
    --argjson total_duration "$total_duration" \
    --argjson avg_duration "$avg_duration" \
    --arg success_rate "$success_rate" \
    --arg timestamp "$timestamp" \
    --arg status "$status" \
    '.agents[$agent].total_invocations = $invocations |
     .agents[$agent].successes = $successes |
     .agents[$agent].total_duration_ms = $total_duration |
     .agents[$agent].avg_duration_ms = $avg_duration |
     .agents[$agent].success_rate = ($success_rate | tonumber) |
     .agents[$agent].last_execution = $timestamp |
     .agents[$agent].last_status = $status |
     .metadata.last_updated = $timestamp' \
    "$REGISTRY_FILE" > "$temp_file"

  # Atomic move
  mv "$temp_file" "$REGISTRY_FILE"

  return 0
}

#
# get_agent_info - Retrieve agent information from registry
#
# Arguments:
#   $1 - agent_name
#
get_agent_info() {
  local agent_name="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq ".agents.\"$agent_name\"" "$REGISTRY_FILE"
}

#
# list_agents - List all agents in registry
#
list_agents() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq -r '.agents | keys[]' "$REGISTRY_FILE"
}

#
# get_agents_by_type - Get agents filtered by type
#
# Arguments:
#   $1 - agent_type (specialized/hierarchical)
#
get_agents_by_type() {
  local agent_type="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq -r ".agents | to_entries[] | select(.value.type == \"$agent_type\") | .key" \
    "$REGISTRY_FILE"
}

#
# get_agents_by_category - Get agents filtered by category
#
# Arguments:
#   $1 - category (research/planning/implementation/debugging/documentation/analysis/coordination)
#
get_agents_by_category() {
  local category="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq -r ".agents | to_entries[] | select(.value.category == \"$category\") | .key" \
    "$REGISTRY_FILE"
}

#
# get_agents_by_tool - Get agents that use a specific tool
#
# Arguments:
#   $1 - tool_name (Read/Write/Edit/Bash/Grep/Glob/WebSearch/WebFetch/Task)
#
get_agents_by_tool() {
  local tool="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq -r ".agents | to_entries[] | select(.value.tools | contains([\"$tool\"])) | .key" \
    "$REGISTRY_FILE"
}

#
# update_agent_metrics_v2 - Update agent metrics (new schema with nested metrics object)
#
# Arguments:
#   $1 - agent_name
#   $2 - success (true/false)
#   $3 - duration_seconds
#
update_agent_metrics_v2() {
  local agent_name="$1"
  local success="$2"
  local duration="$3"

  ensure_registry_exists

  if ! command -v jq &> /dev/null; then
    return 1
  fi

  if ! jq -e ".agents.\"$agent_name\"" "$REGISTRY_FILE" > /dev/null 2>&1; then
    echo "Warning: Agent '$agent_name' not found in registry" >&2
    return 1
  fi

  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local temp_file="${REGISTRY_FILE}.tmp.$$"

  # Update metrics based on new schema (nested metrics object)
  if [[ "$success" == "true" ]]; then
    jq \
      --arg agent "$agent_name" \
      --argjson duration "$duration" \
      --arg timestamp "$timestamp" \
      '.agents[$agent].metrics.total_invocations += 1 |
       .agents[$agent].metrics.successful_invocations += 1 |
       .agents[$agent].metrics.average_duration_seconds =
         ((.agents[$agent].metrics.average_duration_seconds *
           (.agents[$agent].metrics.total_invocations - 1)) + $duration) /
         .agents[$agent].metrics.total_invocations |
       .agents[$agent].metrics.last_invocation = $timestamp |
       .last_updated = $timestamp' \
      "$REGISTRY_FILE" > "$temp_file"
  else
    jq \
      --arg agent "$agent_name" \
      --argjson duration "$duration" \
      --arg timestamp "$timestamp" \
      '.agents[$agent].metrics.total_invocations += 1 |
       .agents[$agent].metrics.failed_invocations += 1 |
       .agents[$agent].metrics.average_duration_seconds =
         ((.agents[$agent].metrics.average_duration_seconds *
           (.agents[$agent].metrics.total_invocations - 1)) + $duration) /
         .agents[$agent].metrics.total_invocations |
       .agents[$agent].metrics.last_invocation = $timestamp |
       .last_updated = $timestamp' \
      "$REGISTRY_FILE" > "$temp_file"
  fi

  mv "$temp_file" "$REGISTRY_FILE"
  return 0
}

#
# get_agent_stats - Get formatted stats for an agent
#
# Arguments:
#   $1 - agent_name
#
get_agent_stats() {
  local agent_name="$1"

  if [[ ! -f "$REGISTRY_FILE" ]]; then
    echo "Registry file not found: $REGISTRY_FILE" >&2
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo "jq not available" >&2
    return 1
  fi

  jq -r ".agents.\"$agent_name\" |
    \"Agent: \($agent_name)
Type: \(.type)
Category: \(.category)
Description: \(.description)
Tools: \(.tools | join(\", \"))
Total Invocations: \(.metrics.total_invocations)
Success Rate: \((.metrics.successful_invocations / (.metrics.total_invocations | if . > 0 then . else 1 end) * 100))%
Avg Duration: \(.metrics.average_duration_seconds)s
Last Invocation: \(.metrics.last_invocation // \"never\")\"" \
    "$REGISTRY_FILE"
}

# Export functions
export -f ensure_registry_exists
export -f register_agent
export -f update_agent_metrics
export -f update_agent_metrics_v2
export -f get_agent_info
export -f get_agent_stats
export -f list_agents
export -f get_agents_by_type
export -f get_agents_by_category
export -f get_agents_by_tool
