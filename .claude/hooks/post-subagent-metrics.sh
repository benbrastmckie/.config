#!/usr/bin/env bash
# Agent Performance Tracking Hook
# Captures SubagentStop events and updates agent-registry.json with performance metrics

set -euo pipefail

REGISTRY_FILE="${CLAUDE_PROJECT_DIR}/.claude/agents/agent-registry.json"

# Ensure registry exists
if [ ! -f "$REGISTRY_FILE" ]; then
  mkdir -p "$(dirname "$REGISTRY_FILE")"
  echo '{"agents":{},"metadata":{"created":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","last_updated":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","description":"Agent performance tracking registry","version":"1.0"}}' > "$REGISTRY_FILE"
fi

# Parse SubagentStop event from stdin
EVENT_JSON=$(cat)

# Extract fields using jq if available, otherwise skip
if ! command -v jq &> /dev/null; then
  exit 0  # Silently skip if jq not available
fi

AGENT_TYPE=$(echo "$EVENT_JSON" | jq -r '.subagent_type // .agent_type // "unknown"' 2>/dev/null || echo "unknown")
DURATION=$(echo "$EVENT_JSON" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")
STATUS=$(echo "$EVENT_JSON" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Skip if agent type is unknown
if [ "$AGENT_TYPE" = "unknown" ] || [ -z "$AGENT_TYPE" ]; then
  exit 0
fi

# Read current registry
CURRENT_DATA=$(cat "$REGISTRY_FILE")

# Check if agent exists in registry
if echo "$CURRENT_DATA" | jq -e ".agents.\"$AGENT_TYPE\"" > /dev/null 2>&1; then
  # Agent exists - update metrics
  TOTAL_INVOCATIONS=$(echo "$CURRENT_DATA" | jq -r ".agents.\"$AGENT_TYPE\".total_invocations // 0")
  SUCCESSES=$(echo "$CURRENT_DATA" | jq -r ".agents.\"$AGENT_TYPE\".successes // 0")
  TOTAL_DURATION=$(echo "$CURRENT_DATA" | jq -r ".agents.\"$AGENT_TYPE\".total_duration_ms // 0")

  # Increment invocations
  TOTAL_INVOCATIONS=$((TOTAL_INVOCATIONS + 1))

  # Increment successes if status is success
  if [ "$STATUS" = "success" ]; then
    SUCCESSES=$((SUCCESSES + 1))
  fi

  # Add to total duration
  TOTAL_DURATION=$((TOTAL_DURATION + DURATION))

  # Calculate averages
  SUCCESS_RATE=$(echo "scale=3; $SUCCESSES / $TOTAL_INVOCATIONS" | bc 2>/dev/null || echo "0")
  AVG_DURATION=$((TOTAL_DURATION / TOTAL_INVOCATIONS))

else
  # New agent - initialize metrics
  TOTAL_INVOCATIONS=1
  TOTAL_DURATION=$DURATION
  AVG_DURATION=$DURATION

  if [ "$STATUS" = "success" ]; then
    SUCCESSES=1
    SUCCESS_RATE="1.0"
  else
    SUCCESSES=0
    SUCCESS_RATE="0.0"
  fi
fi

# Update registry with new metrics
UPDATED_DATA=$(echo "$CURRENT_DATA" | jq \
  --arg agent "$AGENT_TYPE" \
  --argjson invocations "$TOTAL_INVOCATIONS" \
  --argjson successes "$SUCCESSES" \
  --argjson total_duration "$TOTAL_DURATION" \
  --argjson avg_duration "$AVG_DURATION" \
  --arg success_rate "$SUCCESS_RATE" \
  --arg timestamp "$TIMESTAMP" \
  --arg status "$STATUS" \
  '.agents[$agent] = {
    total_invocations: $invocations,
    successes: $successes,
    total_duration_ms: $total_duration,
    avg_duration_ms: $avg_duration,
    success_rate: ($success_rate | tonumber),
    last_execution: $timestamp,
    last_status: $status
  } | .metadata.last_updated = $timestamp')

# Write updated registry
echo "$UPDATED_DATA" > "$REGISTRY_FILE"
