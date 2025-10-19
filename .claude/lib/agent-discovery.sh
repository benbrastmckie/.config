#!/usr/bin/env bash
# Agent Discovery Utility - Auto-scan and register agents

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"
source "${SCRIPT_DIR}/agent-schema-validator.sh"

# Discover all agents in .claude/agents/
# Returns: List of agent behavioral file paths (one per line)
discover_agents() {
  local agents_dir="${1:-.claude/agents}"

  if [[ ! -d "$agents_dir" ]]; then
    error "Agents directory not found: $agents_dir"
    return 1
  fi

  # Find all .md files except README.md and special files
  find "$agents_dir" -maxdepth 1 -name "*.md" \
    ! -name "README.md" \
    ! -name "*-usage.md" \
    -type f | sort
}

# Extract agent metadata from behavioral file
# Args:
#   $1 - Path to agent behavioral file
# Returns: JSON object with agent metadata (printed to stdout)
extract_agent_metadata() {
  local behavioral_file="$1"

  if [[ ! -f "$behavioral_file" ]]; then
    error "Behavioral file not found: $behavioral_file"
    return 1
  fi

  local agent_name
  agent_name=$(basename "$behavioral_file" .md)

  # Check if file has frontmatter (YAML between --- markers)
  local has_frontmatter=0
  if grep -q "^---$" "$behavioral_file"; then
    has_frontmatter=1
  fi

  # Extract metadata based on format
  local description=""
  local tools_json="[]"
  local agent_type="specialized"
  local category="research"

  if [[ $has_frontmatter -eq 1 ]]; then
    # Extract frontmatter
    local frontmatter
    frontmatter=$(sed -n '1,/^---$/p' "$behavioral_file" | sed '1d;$d')

    # Extract description from frontmatter
    if echo "$frontmatter" | grep -q "^description:"; then
      description=$(echo "$frontmatter" | grep "^description:" | sed 's/^description:[ ]*//' | sed 's/^["'\'']//' | sed 's/["'\'']$//')
    fi

    # Extract tools from frontmatter (allowed-tools field)
    if echo "$frontmatter" | grep -q "^allowed-tools:"; then
      local tools_str
      tools_str=$(echo "$frontmatter" | grep "^allowed-tools:" | sed 's/^allowed-tools:[ ]*//')
      # Convert comma-separated tools to JSON array
      tools_json=$(echo "$tools_str" | tr ',' '\n' | sed 's/^[ ]*//' | sed 's/[ ]*$//' | grep -v '^$' | jq -R . | jq -s .)
    fi
  fi

  # If no description from frontmatter, extract from first paragraph
  if [[ -z "$description" ]]; then
    description=$(sed -n '/^---$/,/^---$/!p' "$behavioral_file" | \
      grep -v "^#" | grep -v "^$" | grep -v "^-" | head -1 | sed 's/^[*-] //' | cut -c1-200)
  fi

  # Default description if still empty
  if [[ -z "$description" ]]; then
    description="Agent: $agent_name"
  fi

  # Determine agent type (specialized or hierarchical)
  # Hierarchical agents typically coordinate other agents
  if grep -qi "hierarchical\|coordinator\|supervisor\|sub-supervisor" "$behavioral_file"; then
    agent_type="hierarchical"
  fi

  # Determine category based on agent name and content
  case "$agent_name" in
    *research*) category="research" ;;
    *plan*) category="planning" ;;
    *code*|*implementation*|*writer*) category="implementation" ;;
    *debug*) category="debugging" ;;
    *doc*) category="documentation" ;;
    *metrics*|*complexity*|*spec*|*analyzer*|*estimator*) category="analysis" ;;
    *coordinator*|*supervisor*) category="coordination" ;;
    *)
      # Fallback: determine from content
      if grep -qi "research\|investigate\|analyze" "$behavioral_file" | head -10; then
        category="research"
      elif grep -qi "plan\|design\|architect" "$behavioral_file" | head -10; then
        category="planning"
      elif grep -qi "implement\|code\|write" "$behavioral_file" | head -10; then
        category="implementation"
      elif grep -qi "debug\|diagnose\|troubleshoot" "$behavioral_file" | head -10; then
        category="debugging"
      elif grep -qi "document\|doc\|guide" "$behavioral_file" | head -10; then
        category="documentation"
      else
        category="research"
      fi
      ;;
  esac

  # If tools not extracted from frontmatter, try to extract from content
  if [[ "$tools_json" == "[]" ]]; then
    # Look for tool mentions in the file (Read, Write, Edit, etc.)
    local tools_found
    tools_found=$(grep -oE "(Read|Write|Edit|Bash|Grep|Glob|WebSearch|WebFetch|Task)" "$behavioral_file" | \
      sort -u | jq -R . | jq -s .)
    if [[ "$tools_found" != "[]" ]]; then
      tools_json="$tools_found"
    fi
  fi

  # Create JSON metadata
  jq -n \
    --arg type "$agent_type" \
    --arg category "$category" \
    --arg description "$description" \
    --argjson tools "$tools_json" \
    --arg behavioral_file "$behavioral_file" \
    '{
      type: $type,
      category: $category,
      description: $description,
      tools: $tools,
      metrics: {
        total_invocations: 0,
        successful_invocations: 0,
        failed_invocations: 0,
        average_duration_seconds: 0,
        last_invocation: null
      },
      dependencies: [],
      behavioral_file: $behavioral_file
    }'
}

# Register discovered agent in registry
# Args:
#   $1 - Agent name
#   $2 - Agent metadata JSON string
#   $3 - Registry file path (optional, defaults to .claude/agents/agent-registry.json)
# Returns:
#   0 if successful, 1 if error
register_agent() {
  local agent_name="$1"
  local agent_metadata="$2"
  local registry_file="${3:-.claude/agents/agent-registry.json}"

  if [[ ! -f "$registry_file" ]]; then
    error "Registry file not found: $registry_file"
    return 1
  fi

  # Validate metadata against schema
  if ! validate_agent_entry "$agent_name" "$registry_file" 2>/dev/null; then
    # Agent not in registry yet or invalid, proceed with registration
    :
  fi

  # Add to registry using jq (use temp file for metadata to avoid quoting issues)
  local temp_metadata="${registry_file}.metadata.tmp"
  local temp_registry="${registry_file}.tmp"
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Write metadata to temp file
  echo "$agent_metadata" > "$temp_metadata"

  # Use jq with --slurpfile to read metadata
  jq --slurpfile metadata_arr "$temp_metadata" \
     --arg name "$agent_name" \
     --arg timestamp "$timestamp" \
     '.agents[$name] = $metadata_arr[0] | .last_updated = $timestamp' \
     "$registry_file" > "$temp_registry"

  local jq_result=$?
  rm -f "$temp_metadata"

  if [[ $jq_result -eq 0 ]]; then
    mv "$temp_registry" "$registry_file"
    echo "✓ Registered agent: $agent_name"
    return 0
  else
    error "Failed to register agent: $agent_name"
    rm -f "$temp_registry"
    return 1
  fi
}

# Discover and register all agents
# Args:
#   $1 - Agents directory (optional, defaults to .claude/agents)
#   $2 - Registry file (optional, defaults to .claude/agents/agent-registry.json)
# Returns:
#   0 if successful, 1 if any errors
discover_and_register_all() {
  local agents_dir="${1:-.claude/agents}"
  local registry_file="${2:-.claude/agents/agent-registry.json}"
  local discovered_count=0
  local registered_count=0
  local failed_count=0

  echo "Discovering agents in $agents_dir..."
  echo ""

  while IFS= read -r behavioral_file; do
    ((discovered_count++))

    local agent_name
    agent_name=$(basename "$behavioral_file" .md)

    echo "[$discovered_count] Processing: $agent_name"

    # Extract metadata
    local metadata
    if metadata=$(extract_agent_metadata "$behavioral_file" 2>&1); then
      # Show extracted info
      local agent_type
      local agent_category
      agent_type=$(echo "$metadata" | jq -r '.type')
      agent_category=$(echo "$metadata" | jq -r '.category')
      echo "    Type: $agent_type, Category: $agent_category"

      # Register agent
      if register_agent "$agent_name" "$metadata" "$registry_file"; then
        ((registered_count++))
      else
        ((failed_count++))
      fi
    else
      echo "    ✗ Failed to extract metadata"
      ((failed_count++))
    fi
    echo ""
  done < <(discover_agents "$agents_dir")

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Discovery Summary:"
  echo "  Discovered: $discovered_count agents"
  echo "  Registered: $registered_count agents"
  if [[ $failed_count -gt 0 ]]; then
    echo "  Failed: $failed_count agents"
  fi
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  return 0
}

# Export functions
export -f discover_agents
export -f extract_agent_metadata
export -f register_agent
export -f discover_and_register_all

# If run directly, discover and register all agents
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  agents_dir="${1:-.claude/agents}"
  registry_file="${2:-.claude/agents/agent-registry.json}"
  discover_and_register_all "$agents_dir" "$registry_file"
fi
