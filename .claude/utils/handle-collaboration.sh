#!/usr/bin/env bash
# Handle agent collaboration requests (REQUEST_AGENT protocol)
# Usage: handle-collaboration.sh <requesting-agent> <agent-output-file>

set -euo pipefail

REQUESTING_AGENT="${1:?Requesting agent name required}"
AGENT_OUTPUT_FILE="${2:?Agent output file required}"

# Safety limits
MAX_COLLABORATIONS=1
COLLABORATION_TIMEOUT=120  # 2 minutes

# Read-only agents that can be requested for collaboration
READONLY_AGENTS=("research-specialist" "debug-assistant")

# Parse REQUEST_AGENT calls from agent output
parse_collaboration_requests() {
  local output_file="$1"

  # Look for REQUEST_AGENT(agent-type, "query") pattern
  # Example: REQUEST_AGENT(research-specialist, "search for auth patterns")

  grep -oP 'REQUEST_AGENT\(\s*([^,]+)\s*,\s*"([^"]+)"\s*\)' "$output_file" || echo ""
}

# Validate collaboration request
validate_collaboration() {
  local requested_agent="$1"
  local collaboration_count="$2"

  # Check collaboration count limit
  if [[ $collaboration_count -ge $MAX_COLLABORATIONS ]]; then
    echo "ERROR: Maximum collaboration limit reached ($MAX_COLLABORATIONS per agent)" >&2
    return 1
  fi

  # Check if requested agent is read-only (safe for collaboration)
  local is_readonly=0
  for readonly_agent in "${READONLY_AGENTS[@]}"; do
    if [[ "$requested_agent" == "$readonly_agent" ]]; then
      is_readonly=1
      break
    fi
  done

  if [[ $is_readonly -eq 0 ]]; then
    echo "ERROR: Agent '$requested_agent' is not available for collaboration" >&2
    echo "Available agents: ${READONLY_AGENTS[*]}" >&2
    return 1
  fi

  # Prevent recursive collaboration (agent cannot be same as requesting agent)
  if [[ "$requested_agent" == "$REQUESTING_AGENT" ]]; then
    echo "ERROR: Agent cannot collaborate with itself" >&2
    return 1
  fi

  return 0
}

# Invoke requested agent and get lightweight summary
invoke_collaboration_agent() {
  local requested_agent="$1"
  local query="$2"

  echo "COLLABORATION: Invoking $requested_agent for: $query" >&2

  # Create temporary file for collaboration response
  local response_file
  response_file=$(mktemp)
  trap 'rm -f "$response_file"' EXIT

  # Invoke agent via Task tool with read-only context
  # This would be implemented by the calling command (e.g., /implement)
  # For now, we'll create the protocol structure

  cat > "$response_file" <<EOF
{
  "type": "collaboration_request",
  "requesting_agent": "$REQUESTING_AGENT",
  "requested_agent": "$requested_agent",
  "query": "$query",
  "max_response_words": 200,
  "timeout": $COLLABORATION_TIMEOUT,
  "read_only": true,
  "recursive_collaboration": false
}
EOF

  echo "$response_file"
}

# Format collaboration response for requesting agent
format_collaboration_response() {
  local requested_agent="$1"
  local query="$2"
  local response="$3"

  cat <<EOF

--- COLLABORATION RESPONSE ---
Requested: $requested_agent
Query: $query

$response

--- END COLLABORATION RESPONSE ---

EOF
}

# Log collaboration attempt for metrics
log_collaboration() {
  local requesting_agent="$1"
  local requested_agent="$2"
  local query="$3"
  local status="$4"  # success or failed

  local log_dir=".claude/metrics"
  local log_file="$log_dir/collaborations.jsonl"

  mkdir -p "$log_dir"

  cat >> "$log_file" <<EOF
{"timestamp":"$(date -Iseconds)","requesting_agent":"$requesting_agent","requested_agent":"$requested_agent","query":"$query","status":"$status"}
EOF
}

# Main collaboration handling logic
if [[ ! -f "$AGENT_OUTPUT_FILE" ]]; then
  echo "ERROR: Agent output file not found: $AGENT_OUTPUT_FILE" >&2
  exit 1
fi

# Parse collaboration requests
REQUESTS=$(parse_collaboration_requests "$AGENT_OUTPUT_FILE")

if [[ -z "$REQUESTS" ]]; then
  echo "No collaboration requests found"
  exit 0
fi

# Process collaboration requests (max 1)
COLLABORATION_COUNT=0

while IFS= read -r request_line; do
  [[ -z "$request_line" ]] && continue

  # Parse request (simplified - would use more robust parsing in production)
  REQUESTED_AGENT=$(echo "$request_line" | grep -oP 'REQUEST_AGENT\(\s*\K[^,]+' | tr -d ' ')
  QUERY=$(echo "$request_line" | grep -oP 'REQUEST_AGENT\([^,]+,\s*"\K[^"]+')

  # Validate collaboration
  if ! validate_collaboration "$REQUESTED_AGENT" "$COLLABORATION_COUNT"; then
    log_collaboration "$REQUESTING_AGENT" "$REQUESTED_AGENT" "$QUERY" "failed"
    exit 1
  fi

  # Invoke collaboration agent
  COLLABORATION_REQUEST_FILE=$(invoke_collaboration_agent "$REQUESTED_AGENT" "$QUERY")

  echo "Collaboration request created: $COLLABORATION_REQUEST_FILE"
  echo "Requesting agent: $REQUESTING_AGENT"
  echo "Requested agent: $REQUESTED_AGENT"
  echo "Query: $QUERY"

  # Log successful collaboration setup
  log_collaboration "$REQUESTING_AGENT" "$REQUESTED_AGENT" "$QUERY" "success"

  ((COLLABORATION_COUNT++))

  # Exit after first collaboration (MAX_COLLABORATIONS=1)
  break
done <<< "$REQUESTS"

echo "Collaboration processing complete. Count: $COLLABORATION_COUNT"
