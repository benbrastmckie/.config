#!/usr/bin/env bash
#
# Show Agent Metrics
# Display performance metrics from agent-registry.json in human-readable format
#

set -euo pipefail

REGISTRY_FILE="${1:-.claude/agents/agent-registry.json}"

if [[ ! -f "$REGISTRY_FILE" ]]; then
  echo "Error: Registry file not found: $REGISTRY_FILE"
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required for this script"
  exit 1
fi

echo "=========================================="
echo "Agent Performance Metrics"
echo "=========================================="
echo ""

# Get all agent names
agents=$(jq -r '.agents | keys[]' "$REGISTRY_FILE")

if [[ -z "$agents" ]]; then
  echo "No agents registered"
  exit 0
fi

for agent in $agents; do
  echo "Agent: $agent"
  echo "----------------------------------------"

  type=$(jq -r ".agents.\"$agent\".type // \"unknown\"" "$REGISTRY_FILE")
  desc=$(jq -r ".agents.\"$agent\".description // \"No description\"" "$REGISTRY_FILE")
  invocations=$(jq -r ".agents.\"$agent\".total_invocations // 0" "$REGISTRY_FILE")
  successes=$(jq -r ".agents.\"$agent\".successes // 0" "$REGISTRY_FILE")
  avg_duration=$(jq -r ".agents.\"$agent\".avg_duration_ms // 0" "$REGISTRY_FILE")
  success_rate=$(jq -r ".agents.\"$agent\".success_rate // 0.0" "$REGISTRY_FILE")
  last_exec=$(jq -r ".agents.\"$agent\".last_execution // \"Never\"" "$REGISTRY_FILE")
  last_status=$(jq -r ".agents.\"$agent\".last_status // \"N/A\"" "$REGISTRY_FILE")

  echo "  Type: $type"
  echo "  Description: $desc"
  echo ""
  echo "  Performance:"
  echo "    Total Invocations: $invocations"
  echo "    Successes: $successes"

  # Calculate success rate percentage using awk
  success_rate_pct=$(echo "$success_rate" | awk '{printf "%.1f", $1 * 100}')
  echo "    Success Rate: ${success_rate_pct}%"

  # Calculate average duration in seconds using awk
  avg_duration_secs=$(echo "$avg_duration" | awk '{printf "%.2f", $1 / 1000}')
  echo "    Average Duration: ${avg_duration}ms (${avg_duration_secs}s)"
  echo ""
  echo "  Last Execution:"
  echo "    Time: $last_exec"
  echo "    Status: $last_status"
  echo ""
done

echo "=========================================="
echo "Registry: $REGISTRY_FILE"
echo "Last Updated: $(jq -r '.metadata.last_updated' "$REGISTRY_FILE")"
echo "=========================================="
