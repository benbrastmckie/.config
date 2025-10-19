#!/usr/bin/env bash
# Command Discovery Utility
# Scans .claude/commands/ and extracts metadata

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# Discover all command files
discover_commands() {
  local commands_dir="${1:-.claude/commands}"

  if [[ ! -d "$commands_dir" ]]; then
    error "Commands directory not found: $commands_dir"
    return 1
  fi

  find "$commands_dir" -maxdepth 1 -name "*.md" \
    ! -name "README.md" \
    -type f | sort
}

# Extract command metadata
extract_command_metadata() {
  local command_file="$1"
  local command_name
  command_name=$(basename "$command_file" .md)

  # Extract description (first non-empty line that's not a comment)
  local description
  description=$(grep -v "^#" "$command_file" | grep -v "^$" | head -1 | sed 's/^[*-] //' | cut -c1-200)

  # Count sourced utilities
  local utilities
  utilities=$(grep -c "source.*\.sh" "$command_file" 2>/dev/null || echo "0")
  utilities=$(echo "$utilities" | tr -d ' ')

  # Detect agent invocations
  local agents
  agents=$(grep -c "\.claude/agents/[a-z0-9-]*\.md" "$command_file" 2>/dev/null || echo "0")
  agents=$(echo "$agents" | tr -d ' ')

  # Get file size
  local file_size
  file_size=$(wc -l < "$command_file" | tr -d ' ')

  # Build JSON
  jq -n \
    --arg name "$command_name" \
    --arg description "${description:-Command: $command_name}" \
    --arg file "$command_file" \
    --argjson utilities "$utilities" \
    --argjson agents "$agents" \
    --argjson lines "$file_size" \
    '{
      name: $name,
      description: $description,
      file: $file,
      utilities_count: $utilities,
      agents_count: $agents,
      lines: $lines,
      discovered_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
    }'
}

# Discover and catalog all commands
discover_and_catalog_all() {
  local commands_dir="${1:-.claude/commands}"
  local output_file="${2:-.claude/data/registries/command-metadata.json}"

  echo "Discovering commands in $commands_dir..."

  # Ensure output directory exists
  mkdir -p "$(dirname "$output_file")"

  # Create registry structure
  echo '{"commands": {}, "last_updated": ""}' > "$output_file"

  local count=0

  while IFS= read -r command_file; do
    local command_name
    command_name=$(basename "$command_file" .md)

    echo "  Processing: $command_name"

    local metadata
    metadata=$(extract_command_metadata "$command_file")

    # Add to registry
    local temp_file="${output_file}.tmp"
    jq --argjson metadata "$metadata" \
       --arg name "$command_name" \
       '.commands[$name] = $metadata' \
       "$output_file" > "$temp_file"
    mv "$temp_file" "$output_file"

    ((count++))
  done < <(discover_commands "$commands_dir")

  # Update timestamp
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq --arg ts "$timestamp" '.last_updated = $ts' "$output_file" > "${output_file}.tmp"
  mv "${output_file}.tmp" "$output_file"

  echo "✓ Discovered $count commands"
  echo "✓ Registry saved: $output_file"
}

# Export functions
export -f discover_commands
export -f extract_command_metadata
export -f discover_and_catalog_all

# If run directly, discover all commands
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  discover_and_catalog_all
fi
