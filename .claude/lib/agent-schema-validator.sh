#!/usr/bin/env bash
# Agent Registry Schema Validator
# Validates agent registry against JSON schema

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# Validate agent registry against schema
# Args:
#   $1 - Path to agent-registry.json
# Returns:
#   0 if valid, 1 if invalid
validate_agent_registry() {
  local registry_file="$1"
  local schema_file="${SCRIPT_DIR}/../agents/agent-registry-schema.json"

  if [[ ! -f "$registry_file" ]]; then
    error "Registry file not found: $registry_file"
    return 1
  fi

  if [[ ! -f "$schema_file" ]]; then
    error "Schema file not found: $schema_file"
    return 1
  fi

  # Validate JSON syntax
  if ! jq empty "$registry_file" 2>/dev/null; then
    error "Invalid JSON syntax in registry"
    return 1
  fi

  # Check required top-level fields
  local required_fields=("schema_version" "last_updated" "agents")
  for field in "${required_fields[@]}"; do
    if ! jq -e ".$field" "$registry_file" >/dev/null 2>&1; then
      error "Missing required field: $field"
      return 1
    fi
  done

  # Validate schema_version format (semver)
  local schema_version
  schema_version=$(jq -r '.schema_version' "$registry_file")
  if ! [[ "$schema_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Invalid schema_version format: $schema_version (expected semver)"
    return 1
  fi

  echo "✓ Agent registry schema validation passed"
  return 0
}

# Validate individual agent entry
# Args:
#   $1 - Agent name
#   $2 - Path to registry file
# Returns:
#   0 if valid, 1 if invalid
validate_agent_entry() {
  local agent_name="$1"
  local registry_file="$2"

  # Extract agent data
  local agent_data
  if ! agent_data=$(jq -e ".agents[\"$agent_name\"]" "$registry_file" 2>/dev/null); then
    error "Agent $agent_name not found in registry"
    return 1
  fi

  # Required fields check
  local required_fields=("type" "category" "description" "tools" "metrics" "behavioral_file")

  for field in "${required_fields[@]}"; do
    if ! echo "$agent_data" | jq -e ".$field" >/dev/null 2>&1; then
      error "Agent $agent_name missing required field: $field"
      return 1
    fi
  done

  # Type validation
  local agent_type
  agent_type=$(echo "$agent_data" | jq -r '.type')
  if [[ "$agent_type" != "specialized" && "$agent_type" != "hierarchical" ]]; then
    error "Agent $agent_name has invalid type: $agent_type"
    return 1
  fi

  # Category validation
  local valid_categories=("research" "planning" "implementation" "debugging" "documentation" "analysis" "coordination")
  local category
  category=$(echo "$agent_data" | jq -r '.category')
  local valid=0
  for valid_cat in "${valid_categories[@]}"; do
    if [[ "$category" == "$valid_cat" ]]; then
      valid=1
      break
    fi
  done
  if [[ $valid -eq 0 ]]; then
    error "Agent $agent_name has invalid category: $category"
    return 1
  fi

  # Description length validation
  local description
  description=$(echo "$agent_data" | jq -r '.description')
  local desc_len=${#description}
  if [[ $desc_len -lt 10 || $desc_len -gt 200 ]]; then
    error "Agent $agent_name description length invalid: $desc_len (must be 10-200 chars)"
    return 1
  fi

  # Behavioral file exists
  local behavioral_file
  behavioral_file=$(echo "$agent_data" | jq -r '.behavioral_file')
  if [[ ! -f "$behavioral_file" ]]; then
    error "Agent $agent_name behavioral file not found: $behavioral_file"
    return 1
  fi

  # Metrics validation
  local metrics_fields=("total_invocations" "successful_invocations" "failed_invocations" "average_duration_seconds")
  for metric in "${metrics_fields[@]}"; do
    if ! echo "$agent_data" | jq -e ".metrics.$metric" >/dev/null 2>&1; then
      error "Agent $agent_name missing metrics field: $metric"
      return 1
    fi
  done

  return 0
}

# Validate all agents in registry
# Args:
#   $1 - Path to agent-registry.json
# Returns:
#   0 if all valid, 1 if any invalid
validate_all_agents() {
  local registry_file="$1"
  local failed=0

  # First validate overall structure
  if ! validate_agent_registry "$registry_file"; then
    return 1
  fi

  # Get all agent names
  local agents
  agents=$(jq -r '.agents | keys[]' "$registry_file")

  echo "Validating individual agent entries..."

  while IFS= read -r agent_name; do
    if validate_agent_entry "$agent_name" "$registry_file"; then
      echo "  ✓ $agent_name"
    else
      echo "  ✗ $agent_name"
      ((failed++))
    fi
  done <<< "$agents"

  if [[ $failed -eq 0 ]]; then
    echo ""
    echo "✓ All agent entries valid"
    return 0
  else
    echo ""
    error "$failed agent entries failed validation"
    return 1
  fi
}

# Export functions
export -f validate_agent_registry
export -f validate_agent_entry
export -f validate_all_agents

# If run directly, validate the default registry
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  registry_file="${1:-.claude/agents/agent-registry.json}"
  validate_all_agents "$registry_file"
fi
