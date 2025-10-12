#!/usr/bin/env bash
# Agent Performance Tracking Hook
# Captures SubagentStop events and updates agent-registry.json with performance metrics
# Also writes detailed per-invocation JSONL metrics for analysis

set -euo pipefail

REGISTRY_FILE="${CLAUDE_PROJECT_DIR}/.claude/agents/agent-registry.json"
METRICS_DIR="${CLAUDE_PROJECT_DIR}/.claude/data/metrics/agents"

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

# ============================================================================
# Per-Invocation JSONL Logging (Phase 6)
# ============================================================================

# Classify error type based on error message
classify_error() {
  local error_msg="$1"

  case "$error_msg" in
    *"syntax error"*|*"SyntaxError"*) echo "syntax_error" ;;
    *"No such file"*|*"not found"*|*"File not found"*) echo "file_not_found" ;;
    *"test"*"failed"*|*"assertion"*|*"Test"*"failed"*) echo "test_failure" ;;
    *"timeout"*|*"timed out"*|*"Timeout"*) echo "timeout" ;;
    *"permission denied"*|*"Permission denied"*) echo "permission_denied" ;;
    *"compilation failed"*|*"build error"*|*"compile error"*) echo "compilation_error" ;;
    *) echo "unknown_error" ;;
  esac
}

# Extract tool usage from event JSON (if available)
# Returns JSON object like {"Read":5,"Edit":3}
extract_tool_usage() {
  local event_json="$1"

  # Try to extract tools_used from event metadata
  local tools_used
  tools_used=$(echo "$event_json" | jq -c '.tools_used // {}' 2>/dev/null || echo '{}')

  echo "$tools_used"
}

# Generate unique invocation ID
generate_invocation_id() {
  local timestamp=$(date +%s)
  local random_suffix

  # Try openssl first, fallback to $RANDOM
  if command -v openssl &> /dev/null; then
    random_suffix=$(openssl rand -hex 3 2>/dev/null || printf "%06x" $RANDOM)
  else
    random_suffix=$(printf "%06x" $RANDOM)
  fi

  echo "inv_${timestamp}_${random_suffix}"
}

# Create and append JSONL record
mkdir -p "$METRICS_DIR"
AGENT_JSONL="${METRICS_DIR}/${AGENT_TYPE}.jsonl"

# Extract additional fields
ERROR_MSG="null"
ERROR_TYPE="null"
if [ "$STATUS" != "success" ]; then
  ERROR_MSG=$(echo "$EVENT_JSON" | jq -r '.error // "Unknown error"' 2>/dev/null || echo "Unknown error")
  ERROR_TYPE=$(classify_error "$ERROR_MSG")
fi

TOOLS_USED=$(extract_tool_usage "$EVENT_JSON")
INVOCATION_ID=$(generate_invocation_id)
TASK_SUMMARY=$(echo "$EVENT_JSON" | jq -r '.task_summary // .description // ""' 2>/dev/null | head -c 100)

# Build JSONL record
JSONL_RECORD=$(jq -n \
  --arg timestamp "$TIMESTAMP" \
  --arg agent "$AGENT_TYPE" \
  --arg inv_id "$INVOCATION_ID" \
  --argjson duration "$DURATION" \
  --arg status "$STATUS" \
  --argjson tools "$TOOLS_USED" \
  --arg error "$ERROR_MSG" \
  --arg error_type "$ERROR_TYPE" \
  --arg task "$TASK_SUMMARY" \
  '{
    timestamp: $timestamp,
    agent_type: $agent,
    invocation_id: $inv_id,
    duration_ms: ($duration | tonumber),
    status: $status,
    tools_used: $tools,
    error: (if $error == "null" or $error == "Unknown error" then null else $error end),
    error_type: (if $error_type == "null" or $error_type == "unknown_error" then null else $error_type end),
    task_summary: (if $task == "" then null else $task end)
  }' 2>/dev/null)

# Append to JSONL file (only if record creation succeeded)
if [ -n "$JSONL_RECORD" ] && [ "$JSONL_RECORD" != "null" ]; then
  echo "$JSONL_RECORD" >> "$AGENT_JSONL"
fi
