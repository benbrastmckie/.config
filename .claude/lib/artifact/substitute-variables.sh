#!/usr/bin/env bash
# Variable substitution engine for workflow templates
# Usage: substitute-variables.sh <template-file> <variables-json>
# Example: substitute-variables.sh crud.yaml '{"entity_name":"User","fields":["name","email"]}'

set -euo pipefail

TEMPLATE_FILE="${1:?Template file required}"
VARIABLES_JSON="${2:?Variables JSON required}"

# Validate inputs
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "ERROR: Template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

# Create temporary file for processing
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

cp "$TEMPLATE_FILE" "$TEMP_FILE"

# Function to get variable value from JSON
get_variable() {
  local var_name="$1"
  local value

  # Try to extract value using grep and sed
  value=$(echo "$VARIABLES_JSON" | grep -o "\"$var_name\":\"[^\"]*\"" | sed "s/\"$var_name\":\"\([^\"]*\)\"/\1/" || echo "")

  if [[ -z "$value" ]]; then
    # Try for array format
    value=$(echo "$VARIABLES_JSON" | grep -o "\"$var_name\":\[[^]]*\]" | sed "s/\"$var_name\"://" || echo "")
  fi

  if [[ -z "$value" ]]; then
    # Try for boolean/number
    value=$(echo "$VARIABLES_JSON" | grep -o "\"$var_name\":[^,}]*" | sed "s/\"$var_name\"://" | tr -d ' ' || echo "")
  fi

  echo "$value"
}

# Process simple variable substitutions {{variable_name}}
process_simple_variables() {
  local content
  content=$(cat "$TEMP_FILE")

  # Extract all variable names from JSON
  local var_names
  var_names=$(echo "$VARIABLES_JSON" | grep -o '"[^"]*":' | tr -d '":' | tr '\n' ' ')

  for var_name in $var_names; do
    local value
    value=$(get_variable "$var_name")

    # Remove quotes from value if present
    value="${value//\"/}"
    value="${value//\'/}"

    # Replace {{variable_name}} with value
    content="${content//\{\{$var_name\}\}/$value}"
  done

  echo "$content" > "$TEMP_FILE"
}

# Process array iterations {{#each array}}...{{this}}...{{/each}}
process_array_iterations() {
  local content
  content=$(cat "$TEMP_FILE")

  # Find all {{#each variable}}...{{/each}} blocks using a simpler approach
  while true; do
    # Check if there's a {{#each in the content
    if ! echo "$content" | grep -q "{{#each "; then
      # No more {{#each}} blocks
      break
    fi

    # Extract the first {{#each}} block using string manipulation
    local start_marker="{{#each "
    local start_idx="${content%%${start_marker}*}"
    local start_len="${#start_idx}"

    if [[ "$start_len" -eq "${#content}" ]]; then
      # No {{#each}} found
      break
    fi

    # Get everything after the start marker
    local after_start="${content:$((start_len + ${#start_marker}))}"

    # Extract variable name (up to first }})
    if [[ "$after_start" =~ ^([a-z_]+)\}\}(.*) ]]; then
      local var_name="${BASH_REMATCH[1]}"
      local remaining="${BASH_REMATCH[2]}"

      # Find the matching {{/each}}
      local end_marker="{{/each}}"
      local end_idx="${remaining%%${end_marker}*}"
      local end_len="${#end_idx}"

      if [[ "$end_len" -eq "${#remaining}" ]]; then
        # No matching {{/each}}, skip
        break
      fi

      # Extract the template block
      local template_block="${end_idx}"

      # Reconstruct the full match for replacement
      local full_match="{{#each ${var_name}}}${template_block}{{/each}}"

      # Get array value
      local array_json
      array_json=$(get_variable "$var_name")

      if [[ -z "$array_json" ]] || [[ "$array_json" == "null" ]] || [[ "$array_json" == "[]" ]]; then
        # Empty array, replace with empty string
        content="${content/$full_match/}"
        continue
      fi

      # Parse array items (basic JSON array parsing)
      local items
      items=$(echo "$array_json" | tr -d '[]' | tr ',' '\n' | tr -d '"' | tr -d "'")

      local result=""
      local index=0

      # Count non-empty items
      local item_count=0
      while IFS= read -r item; do
        [[ -n "$item" ]] && item_count=$((item_count + 1))
      done <<< "$items"

      while IFS= read -r item; do
        [[ -z "$item" ]] && continue

        local block="$template_block"

        # Replace {{this}} with current item
        block="${block//\{\{this\}\}/$item}"

        # Replace {{@index}} with current index
        block="${block//\{\{@index\}\}/$index}"

        # Replace {{@first}} with true/false
        if [[ $index -eq 0 ]]; then
          block="${block//\{\{@first\}\}/true}"
        else
          block="${block//\{\{@first\}\}/false}"
        fi

        # Replace {{@last}} with true/false
        if [[ $index -eq $((item_count - 1)) ]]; then
          block="${block//\{\{@last\}\}/true}"
        else
          block="${block//\{\{@last\}\}/false}"
        fi

        # Handle {{#unless @last}}...{{/unless}}
        if [[ $index -eq $((item_count - 1)) ]]; then
          # Remove the content between {{#unless @last}} and {{/unless}}
          block=$(echo "$block" | sed 's/{{#unless @last}}[^{]*{{\/unless}}//g')
        else
          # Keep the content, just remove the tags
          block="${block//\{\{#unless @last\}\}/}"
          block="${block//\{\{\/unless\}\}/}"
        fi

        result+="$block"
        index=$((index + 1))
      done <<< "$items"

      # Replace the entire {{#each}}...{{/each}} block with result
      content="${content/$full_match/$result}"
    else
      # Couldn't parse, skip
      break
    fi
  done

  echo "$content" > "$TEMP_FILE"
}

# Process conditionals {{#if variable}}...{{/if}}
process_conditionals() {
  local content
  content=$(cat "$TEMP_FILE")

  # Find all {{#if variable}}...{{/if}} blocks
  while [[ "$content" =~ \{\{#if[[:space:]]+([a-z_]+)\}\}([^}]*)\{\{/if\}\} ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local template_block="${BASH_REMATCH[2]}"
    local full_match="${BASH_REMATCH[0]}"

    # Get variable value
    local value
    value=$(get_variable "$var_name")

    # Check if truthy (not empty, not "false", not "0", not "null")
    if [[ -n "$value" ]] && [[ "$value" != "false" ]] && [[ "$value" != "0" ]] && [[ "$value" != "null" ]]; then
      # Replace with template block content
      content="${content//$full_match/$template_block}"
    else
      # Replace with empty string
      content="${content//$full_match/}"
    fi
  done

  # Handle {{#unless variable}}...{{/unless}} blocks
  while [[ "$content" =~ \{\{#unless[[:space:]]+([a-z_]+)\}\}([^}]*)\{\{/unless\}\} ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local template_block="${BASH_REMATCH[2]}"
    local full_match="${BASH_REMATCH[0]}"

    # Get variable value
    local value
    value=$(get_variable "$var_name")

    # Check if falsy
    if [[ -z "$value" ]] || [[ "$value" == "false" ]] || [[ "$value" == "0" ]] || [[ "$value" == "null" ]]; then
      # Replace with template block content
      content="${content//$full_match/$template_block}"
    else
      # Replace with empty string
      content="${content//$full_match/}"
    fi
  done

  echo "$content" > "$TEMP_FILE"
}

# Main processing pipeline
process_simple_variables
process_array_iterations
process_conditionals

# Output result
cat "$TEMP_FILE"
