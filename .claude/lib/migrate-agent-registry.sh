#!/usr/bin/env bash
# Migrate agent registry from old to new schema
# Old schema: flat metrics at top level
# New schema: structured with schema_version, nested metrics object

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# Migrate agent registry from old to new schema
# Args:
#   $1 - Path to old registry (optional, defaults to .claude/agents/agent-registry.json)
# Returns:
#   0 if successful, 1 if error
migrate_agent_registry() {
  local old_registry="${1:-.claude/agents/agent-registry.json}"
  local backup_registry="${old_registry}.backup-$(date +%Y%m%d-%H%M%S)"
  local new_registry="${old_registry}.new"

  if [[ ! -f "$old_registry" ]]; then
    error "Registry file not found: $old_registry"
    return 1
  fi

  echo "Migrating agent registry to new schema..."
  echo "  Old registry: $old_registry"
  echo "  Backup: $backup_registry"

  # Backup old registry
  cp "$old_registry" "$backup_registry"
  echo "✓ Created backup"

  # Create new registry structure
  cat > "$new_registry" <<EOF
{
  "schema_version": "1.0.0",
  "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "agents": {}
}
EOF

  # Check if old registry has agents
  if ! jq -e '.agents' "$old_registry" >/dev/null 2>&1; then
    echo "✓ No agents to migrate"
    mv "$new_registry" "$old_registry"
    return 0
  fi

  # Get all agent names from old registry
  local agents
  agents=$(jq -r '.agents | keys[]' "$old_registry" 2>/dev/null || echo "")

  if [[ -z "$agents" ]]; then
    echo "✓ No agents to migrate"
    mv "$new_registry" "$old_registry"
    return 0
  fi

  local migrated_count=0

  while IFS= read -r agent_name; do
    echo "  Migrating: $agent_name"

    # Extract old entry
    local old_entry
    old_entry=$(jq ".agents[\"$agent_name\"]" "$old_registry")

    if [[ -z "$old_entry" || "$old_entry" == "null" ]]; then
      echo "  ⚠ Skipping $agent_name (no data found)"
      continue
    fi

    # Extract existing fields
    local agent_type
    agent_type=$(echo "$old_entry" | jq -r '.type // "specialized"')

    local description
    description=$(echo "$old_entry" | jq -r '.description // "Auto-migrated agent"')

    local tools
    tools=$(echo "$old_entry" | jq -c '.tools // []')

    # Migrate old metrics format to new format
    # Old format: total_invocations, successes, total_duration_ms, avg_duration_ms, success_rate, last_execution, last_status
    # New format: metrics object with total_invocations, successful_invocations, failed_invocations, average_duration_seconds, last_invocation
    local total_invocations
    total_invocations=$(echo "$old_entry" | jq -r '.total_invocations // 0')

    local successful_invocations
    successful_invocations=$(echo "$old_entry" | jq -r '.successes // 0')

    local failed_invocations
    failed_invocations=$((total_invocations - successful_invocations))

    local avg_duration_ms
    avg_duration_ms=$(echo "$old_entry" | jq -r '.avg_duration_ms // 0')

    # Convert milliseconds to seconds
    local average_duration_seconds
    if [[ "$avg_duration_ms" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
      average_duration_seconds=$(awk "BEGIN {printf \"%.2f\", $avg_duration_ms / 1000}")
    else
      average_duration_seconds=0
    fi

    local last_invocation
    last_invocation=$(echo "$old_entry" | jq -r '.last_execution // null')
    if [[ "$last_invocation" == "null" ]]; then
      last_invocation="null"
    else
      last_invocation="\"$last_invocation\""
    fi

    # Set default category based on agent name patterns
    local category="research"
    case "$agent_name" in
      *research*) category="research" ;;
      *plan*) category="planning" ;;
      *code*|*implementation*) category="implementation" ;;
      *debug*) category="debugging" ;;
      *doc*) category="documentation" ;;
      *metrics*|*complexity*|*spec*) category="analysis" ;;
      *) category="research" ;;
    esac

    # Use jq to build the entry safely
    local temp_registry="${new_registry}.tmp"
    jq --arg type "$agent_type" \
       --arg category "$category" \
       --arg description "$description" \
       --argjson tools "$tools" \
       --argjson total_inv "$total_invocations" \
       --argjson success_inv "$successful_invocations" \
       --argjson failed_inv "$failed_invocations" \
       --argjson avg_dur "$average_duration_seconds" \
       --arg last_inv "$last_invocation" \
       --arg behavioral_file ".claude/agents/${agent_name}.md" \
       ".agents[\"$agent_name\"] = {
         type: \$type,
         category: \$category,
         description: \$description,
         tools: \$tools,
         metrics: {
           total_invocations: \$total_inv,
           successful_invocations: \$success_inv,
           failed_invocations: \$failed_inv,
           average_duration_seconds: \$avg_dur,
           last_invocation: (if \$last_inv == \"null\" then null else \$last_inv end)
         },
         dependencies: [],
         behavioral_file: \$behavioral_file
       }" "$new_registry" > "$temp_registry"

    mv "$temp_registry" "$new_registry"
    ((migrated_count++))
  done <<< "$agents"

  # Replace old registry with new one
  mv "$new_registry" "$old_registry"

  echo ""
  echo "✓ Migration complete"
  echo "  Agents migrated: $migrated_count"
  echo "  Backup saved: $backup_registry"
  echo ""
  echo "Note: Some fields may need manual review:"
  echo "  - category: Auto-assigned based on agent name"
  echo "  - dependencies: Empty by default"
  echo "  - behavioral_file: Auto-set to .claude/agents/\${agent_name}.md"

  return 0
}

# Export function
export -f migrate_agent_registry

# If run directly, perform migration
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  registry_file="${1:-.claude/agents/agent-registry.json}"
  migrate_agent_registry "$registry_file"
fi
