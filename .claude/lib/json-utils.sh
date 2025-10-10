#!/usr/bin/env bash
# Shared JSON/jq operations utilities
# Centralized jq operations with consistent error handling

set -euo pipefail

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/deps-utils.sh"

# ==============================================================================
# Constants
# ==============================================================================

readonly JSON_UTILS_VERSION="1.0.0"

# ==============================================================================
# Core Functions
# ==============================================================================

# jq_extract_field: Extract field value from JSON file
# Usage: jq_extract_field <json-file> <field-path>
# Returns: Field value or empty string if not found
# Example: jq_extract_field "config.json" ".metadata.date"
jq_extract_field() {
  local json_file="${1:-}"
  local field_path="${2:-}"

  if [ -z "$json_file" ] || [ -z "$field_path" ]; then
    echo "Usage: jq_extract_field <json-file> <field-path>" >&2
    return 1
  fi

  if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file" >&2
    return 1
  fi

  # Require jq
  if ! require_jq; then
    echo "" # Return empty string if jq not available
    return 1
  fi

  # Extract field with error handling
  local value
  value=$(jq -r "${field_path} // empty" "$json_file" 2>/dev/null || echo "")

  echo "$value"
}

# jq_validate_json: Validate JSON file syntax
# Usage: jq_validate_json <json-file>
# Returns: 0 if valid JSON, 1 otherwise
# Example: jq_validate_json "config.json" && echo "Valid"
jq_validate_json() {
  local json_file="${1:-}"

  if [ -z "$json_file" ]; then
    echo "Usage: jq_validate_json <json-file>" >&2
    return 1
  fi

  if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file" >&2
    return 1
  fi

  # Require jq
  if ! require_jq; then
    return 1
  fi

  # Validate JSON
  if jq empty "$json_file" 2>/dev/null; then
    return 0
  else
    echo "Error: Invalid JSON in $json_file" >&2
    return 1
  fi
}

# jq_merge_objects: Merge two JSON objects
# Usage: jq_merge_objects <json-file1> <json-file2>
# Returns: Merged JSON object
# Example: jq_merge_objects "base.json" "overrides.json"
jq_merge_objects() {
  local json_file1="${1:-}"
  local json_file2="${2:-}"

  if [ -z "$json_file1" ] || [ -z "$json_file2" ]; then
    echo "Usage: jq_merge_objects <json-file1> <json-file2>" >&2
    return 1
  fi

  if [ ! -f "$json_file1" ] || [ ! -f "$json_file2" ]; then
    echo "Error: One or both files not found" >&2
    return 1
  fi

  # Require jq
  if ! require_jq; then
    return 1
  fi

  # Merge objects (file2 overrides file1)
  jq -s '.[0] * .[1]' "$json_file1" "$json_file2" 2>/dev/null
}

# jq_pretty_print: Pretty-print JSON file
# Usage: jq_pretty_print <json-file>
# Returns: Formatted JSON
# Example: jq_pretty_print "config.json"
jq_pretty_print() {
  local json_file="${1:-}"

  if [ -z "$json_file" ]; then
    echo "Usage: jq_pretty_print <json-file>" >&2
    return 1
  fi

  if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file" >&2
    return 1
  fi

  # Require jq
  if ! require_jq; then
    # Fallback: just cat the file
    cat "$json_file"
    return 0
  fi

  # Pretty print
  jq '.' "$json_file" 2>/dev/null || cat "$json_file"
}

# jq_set_field: Set field value in JSON file
# Usage: jq_set_field <json-file> <field-path> <new-value>
# Returns: 0 on success
# Example: jq_set_field "config.json" ".metadata.updated" "2025-10-06"
jq_set_field() {
  local json_file="${1:-}"
  local field_path="${2:-}"
  local new_value="${3:-}"

  if [ -z "$json_file" ] || [ -z "$field_path" ]; then
    echo "Usage: jq_set_field <json-file> <field-path> <new-value>" >&2
    return 1
  fi

  if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file" >&2
    return 1
  fi

  # Require jq
  if ! require_jq; then
    return 1
  fi

  # Update field (in-place with temp file)
  local temp_file="${json_file}.tmp"
  if jq --arg val "$new_value" "${field_path} = \$val" "$json_file" > "$temp_file" 2>/dev/null; then
    mv "$temp_file" "$json_file"
    return 0
  else
    rm -f "$temp_file"
    echo "Error: Failed to update field $field_path" >&2
    return 1
  fi
}

# jq_extract_array: Extract array from JSON file
# Usage: jq_extract_array <json-file> <array-path>
# Returns: JSON array
# Example: jq_extract_array "config.json" ".items"
jq_extract_array() {
  local json_file="${1:-}"
  local array_path="${2:-}"

  if [ -z "$json_file" ] || [ -z "$array_path" ]; then
    echo "Usage: jq_extract_array <json-file> <array-path>" >&2
    return 1
  fi

  if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file" >&2
    return 1
  fi

  # Require jq
  if ! require_jq; then
    echo "[]"
    return 1
  fi

  # Extract array
  jq -r "${array_path} // []" "$json_file" 2>/dev/null || echo "[]"
}

# ==============================================================================
# Export Functions
# ==============================================================================

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  export -f jq_extract_field
  export -f jq_validate_json
  export -f jq_merge_objects
  export -f jq_pretty_print
  export -f jq_set_field
  export -f jq_extract_array
fi
