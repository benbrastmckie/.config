#!/usr/bin/env bash
# Simple script to register all agents - standalone version

set -euo pipefail

AGENTS_DIR=".claude/agents"
REGISTRY_FILE=".claude/agents/agent-registry.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the extraction function
source "${SCRIPT_DIR}/agent-discovery.sh"

echo "Registering all agents..."
echo ""

registered=0
failed=0

# Process each agent file
for agent_file in ${AGENTS_DIR}/*.md; do
  # Skip README and usage files
  if [[ "$(basename "$agent_file")" == "README.md" ]] || [[ "$(basename "$agent_file")" == *"-usage.md" ]]; then
    continue
  fi

  agent_name=$(basename "$agent_file" .md)

  echo "[$((registered + failed + 1))] Processing: $agent_name"

  # Extract metadata
  metadata=$(extract_agent_metadata "$agent_file" 2>&1)

  if [[ $? -ne 0 ]]; then
    echo "  ✗ Failed to extract metadata"
    ((failed++))
    continue
  fi

  # Show info
  agent_type=$(echo "$metadata" | jq -r '.type')
  agent_category=$(echo "$metadata" | jq -r '.category')
  echo "    Type: $agent_type, Category: $agent_category"

  # Write metadata to temp file
  temp_metadata=$(mktemp)
  echo "$metadata" > "$temp_metadata"

  # Update registry
  temp_registry=$(mktemp)
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  jq --slurpfile metadata_arr "$temp_metadata" \
     --arg name "$agent_name" \
     --arg timestamp "$timestamp" \
     '.agents[$name] = $metadata_arr[0] | .last_updated = $timestamp' \
     "$REGISTRY_FILE" > "$temp_registry"

  if [[ $? -eq 0 ]]; then
    mv "$temp_registry" "$REGISTRY_FILE"
    echo "  ✓ Registered"
    ((registered++))
  else
    echo "  ✗ Failed to register"
    ((failed++))
    rm -f "$temp_registry"
  fi

  rm -f "$temp_metadata"
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Registration Summary:"
echo "  Registered: $registered agents"
echo "  Failed: $failed agents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
