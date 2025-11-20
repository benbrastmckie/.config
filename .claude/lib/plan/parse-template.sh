#!/usr/bin/env bash
# Parse and validate workflow template YAML files
# Usage: parse-template.sh <template-file> [action]
# Actions: validate, extract-metadata, extract-variables, extract-phases

set -euo pipefail

TEMPLATE_FILE="${1:?Template file required}"
ACTION="${2:-validate}"

# Check if template file exists
if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "ERROR: Template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

# Validate template has required fields
validate_template() {
  local errors=0

  # Check for name
  if ! grep -q '^name:' "$TEMPLATE_FILE"; then
    echo "ERROR: Template missing 'name' field" >&2
    ((errors++))
  fi

  # Check for description
  if ! grep -q '^description:' "$TEMPLATE_FILE"; then
    echo "ERROR: Template missing 'description' field" >&2
    ((errors++))
  fi

  # Note: We don't require variables or phases for basic validation
  # This keeps the validator simple and allows for minimal test templates

  if ((errors > 0)); then
    echo "VALIDATION FAILED: $errors error(s)" >&2
    return 1
  fi

  echo "VALIDATION PASSED"
  return 0
}

# Extract template metadata (name, description)
extract_metadata() {
  local name
  local description

  name=$(grep '^name:' "$TEMPLATE_FILE" | sed 's/^name: *"\(.*\)"/\1/' | sed "s/^name: *'\(.*\)'/\1/" | sed 's/^name: *//')
  description=$(grep '^description:' "$TEMPLATE_FILE" | sed 's/^description: *"\(.*\)"/\1/' | sed "s/^description: *'\(.*\)'/\1/" | sed 's/^description: *//')

  cat <<EOF
{
  "name": "$name",
  "description": "$description"
}
EOF
}

# Extract variable definitions
extract_variables() {
  local in_variables=0
  local variables="["
  local first=1

  while IFS= read -r line; do
    # Start of variables section
    if [[ "$line" =~ ^variables: ]]; then
      in_variables=1
      continue
    fi

    # End of variables section (next top-level key)
    if [[ $in_variables -eq 1 ]] && [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      break
    fi

    # Extract variable name
    if [[ $in_variables -eq 1 ]] && [[ "$line" =~ ^[[:space:]]+-[[:space:]]+name:[[:space:]]+(.*) ]]; then
      local var_name="${BASH_REMATCH[1]}"
      var_name="${var_name//\"/}"
      var_name="${var_name//\'/}"

      # Read ahead for other properties
      local var_type="string"
      local var_required="false"
      local var_desc=""
      local var_default=""

      # Simple extraction (would need more robust YAML parser for production)
      if [[ $(tail -n +$((LINENO+1)) "$TEMPLATE_FILE" | head -5 | grep -c "type:") -gt 0 ]]; then
        var_type=$(tail -n +$((LINENO+1)) "$TEMPLATE_FILE" | head -5 | grep "type:" | head -1 | sed 's/.*type: *//' | tr -d '"' | tr -d "'")
      fi

      if [[ ! $first -eq 1 ]]; then
        variables+=","
      fi
      first=0

      variables+="{\"name\":\"$var_name\",\"type\":\"$var_type\",\"required\":$var_required}"
    fi
  done < "$TEMPLATE_FILE"

  variables+="]"
  echo "$variables"
}

# Extract phase definitions
extract_phases() {
  local in_phases=0
  local phase_count=0
  local in_plan=0

  while IFS= read -r line; do
    # Check if we're entering a plan: section
    if [[ "$line" =~ ^plan: ]]; then
      in_plan=1
      continue
    fi

    # Start of phases section (top-level or under plan)
    if [[ "$line" =~ ^phases: ]] || [[ $in_plan -eq 1 && "$line" =~ ^[[:space:]]+phases: ]]; then
      in_phases=1
      continue
    fi

    # End of phases section (next top-level key)
    if [[ $in_phases -eq 1 ]] && [[ "$line" =~ ^[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
      break
    fi

    # End of phases section (next plan sub-key at same indentation level)
    if [[ $in_phases -eq 1 ]] && [[ $in_plan -eq 1 ]] && [[ "$line" =~ ^[[:space:]]+[a-z_]+: ]] && [[ ! "$line" =~ ^[[:space:]]+[[:space:]] ]]; then
      break
    fi

    # Count phases (lines starting with spaces + "- name:")
    if [[ $in_phases -eq 1 ]] && [[ "$line" =~ ^[[:space:]]+[[:space:]]*-[[:space:]]+name: ]]; then
      phase_count=$((phase_count + 1))
    fi
  done < "$TEMPLATE_FILE"

  echo "$phase_count"
}

# Execute requested action
case "$ACTION" in
  validate)
    validate_template
    ;;
  extract-metadata)
    extract_metadata
    ;;
  extract-variables)
    extract_variables
    ;;
  extract-phases)
    extract_phases
    ;;
  *)
    echo "ERROR: Unknown action: $ACTION" >&2
    echo "Valid actions: validate, extract-metadata, extract-variables, extract-phases" >&2
    exit 1
    ;;
esac
