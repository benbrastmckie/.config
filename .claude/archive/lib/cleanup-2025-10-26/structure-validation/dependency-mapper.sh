#!/usr/bin/env bash
# Dependency Mapper
# Maps dependencies between commands, agents, and utilities

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base-utils.sh"

# Map utility dependencies
map_utility_dependencies() {
  local lib_dir="${1:-.claude/lib}"
  local output_file="${2:-.claude/data/registries/utility-dependency-map.json}"

  echo "Mapping utility dependencies..."

  mkdir -p "$(dirname "$output_file")"

  # Create registry structure
  echo '{"utilities": {}, "last_updated": ""}' > "$output_file"

  local count=0

  while IFS= read -r util_file; do
    local util_name
    util_name=$(basename "$util_file")

    # Extract sourced utilities
    local deps
    deps=$(grep -o "source.*\.sh" "$util_file" 2>/dev/null | \
           grep -o "[a-z0-9-]*\.sh" | \
           grep -v "$(basename "$util_file")" | \
           sort -u | \
           jq -R . | jq -s . || echo "[]")

    # Count functions exported
    local funcs
    funcs=$(grep -c "^export -f" "$util_file" 2>/dev/null || echo "0")

    # Get file size
    local lines
    lines=$(wc -l < "$util_file")

    # Build metadata
    local metadata
    metadata=$(jq -n \
      --arg name "$util_name" \
      --arg file "$util_file" \
      --argjson deps "$deps" \
      --argjson funcs "$funcs" \
      --argjson lines "$lines" \
      '{
        name: $name,
        file: $file,
        dependencies: $deps,
        exported_functions: $funcs,
        lines: $lines
      }')

    # Add to registry
    local temp_file="${output_file}.tmp"
    jq --argjson metadata "$metadata" \
       --arg name "$util_name" \
       '.utilities[$name] = $metadata' \
       "$output_file" > "$temp_file"
    mv "$temp_file" "$output_file"

    ((count++))
  done < <(find "$lib_dir" -name "*.sh" -type f | sort)

  # Update timestamp
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  jq --arg ts "$timestamp" '.last_updated = $ts' "$output_file" > "${output_file}.tmp"
  mv "${output_file}.tmp" "$output_file"

  echo "✓ Mapped $count utilities"
  echo "✓ Dependency map saved: $output_file"
}

# Generate dependency graph (text format)
generate_dependency_graph() {
  local map_file="${1:-.claude/data/registries/utility-dependency-map.json}"

  if [[ ! -f "$map_file" ]]; then
    error "Dependency map not found: $map_file"
    return 1
  fi

  echo "Utility Dependency Graph"
  echo "========================"
  echo ""

  # List utilities and their dependencies
  jq -r '.utilities | to_entries[] |
    "\(.key) (\(.value.exported_functions) functions, \(.value.lines) lines)\n" +
    (.value.dependencies | if length > 0 then
      "  Depends on: " + (. | join(", "))
    else
      "  No dependencies"
    end)' "$map_file"
}

# Export functions
export -f map_utility_dependencies
export -f generate_dependency_graph

# If run directly, map dependencies
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  map_utility_dependencies
  echo ""
  generate_dependency_graph
fi
