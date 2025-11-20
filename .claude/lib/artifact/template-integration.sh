#!/bin/bash
# Template Integration Helpers
# Provides utility functions for integrating template system with commands

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../../commands/templates"

# List all available templates with their categories
# Returns: category:template-name (one per line)
list_available_templates() {
  local templates_dir="${1:-$TEMPLATE_DIR}"

  if [[ ! -d "$templates_dir" ]]; then
    echo "Error: Template directory not found: $templates_dir" >&2
    return 1
  fi

  # List all .yaml files in templates directory
  find "$templates_dir" -name "*.yaml" -type f | while read -r template_file; do
    local template_name
    template_name=$(basename "$template_file" .yaml)

    # Extract category from template (if present)
    local category
    category=$(grep "^category:" "$template_file" 2>/dev/null | head -1 | sed 's/^category:[[:space:]]*//')

    if [[ -n "$category" ]]; then
      echo "${category}:${template_name}"
    else
      echo "general:${template_name}"
    fi
  done | sort
}

# List templates by category
# Args: $1 = category name (optional, lists all if not provided)
# Returns: template names (one per line)
list_templates_by_category() {
  local category="${1:-}"

  if [[ -z "$category" ]]; then
    # List all categories
    list_available_templates | cut -d: -f1 | sort -u
  else
    # List templates in specific category
    list_available_templates | grep "^${category}:" | cut -d: -f2
  fi
}

# Validate that a generated plan has the correct structure
# Args: $1 = path to plan file
# Returns: 0 if valid, 1 if invalid
validate_generated_plan() {
  local plan_file="$1"

  if [[ ! -f "$plan_file" ]]; then
    echo "Error: Plan file not found: $plan_file" >&2
    return 1
  fi

  local errors=0

  # Check for required sections
  local required_sections=(
    "^# "           # Title
    "^## Metadata"  # Metadata section
    "^## Overview"  # Overview section
    "^## Phase"     # At least one phase
  )

  for section in "${required_sections[@]}"; do
    if ! grep -q "$section" "$plan_file"; then
      echo "Error: Missing required section: $section" >&2
      ((errors++))
    fi
  done

  # Check for required metadata fields
  local required_metadata=(
    "Date"
    "Plan Number"
    "Feature"
  )

  for field in "${required_metadata[@]}"; do
    if ! grep -q "^- \*\*${field}\*\*:" "$plan_file"; then
      echo "Error: Missing required metadata field: $field" >&2
      ((errors++))
    fi
  done

  # Check that phases have task lists
  if ! grep -q "^- \[ \]" "$plan_file"; then
    echo "Warning: No task checkboxes found in plan" >&2
  fi

  if [[ $errors -gt 0 ]]; then
    echo "Plan validation failed with $errors error(s)" >&2
    return 1
  fi

  return 0
}

# Add template metadata to an existing plan file
# Args: $1 = plan file path, $2 = template name
# Returns: 0 on success, 1 on failure
link_template_to_plan() {
  local plan_file="$1"
  local template_name="$2"

  if [[ ! -f "$plan_file" ]]; then
    echo "Error: Plan file not found: $plan_file" >&2
    return 1
  fi

  # Check if template source already exists
  if grep -q "^- \*\*Template Source\*\*:" "$plan_file"; then
    echo "Warning: Plan already has template source metadata" >&2
    return 0
  fi

  # Find the metadata section and add template source
  local temp_file
  temp_file=$(mktemp)

  awk -v template="$template_name" '
    /^## Metadata/ {
      in_metadata = 1
      print
      next
    }
    /^##/ && in_metadata {
      # End of metadata section, insert template source before next section
      print "- **Template Source**: " template ".yaml"
      in_metadata = 0
      print
      next
    }
    { print }
  ' "$plan_file" > "$temp_file"

  if [[ $? -eq 0 ]]; then
    mv "$temp_file" "$plan_file"
    return 0
  else
    rm -f "$temp_file"
    echo "Error: Failed to add template metadata" >&2
    return 1
  fi
}

# Extract topic name from user question or feature description
# Args: $1 = question/description text
# Returns: Sanitized topic name (e.g., "user_authentication_jwt")
extract_topic_from_question() {
  local question="${1:-}"

  if [[ -z "$question" ]]; then
    echo "Error: extract_topic_from_question requires question text" >&2
    return 1
  fi

  # Remove common stop words
  local cleaned
  cleaned=$(echo "$question" | \
    sed -E 's/\b(implement|add|fix|update|create|the|a|an|for|with|using|to|from|in|on|at|by)\b//gi' | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9 ]//g' | \
    tr -s ' ' | \
    sed 's/^ //; s/ $//')

  # Extract 2-3 keywords and convert to snake_case
  local topic_name
  topic_name=$(echo "$cleaned" | \
    awk '{for(i=1;i<=3 && i<=NF;i++) printf "%s%s", $i, (i<3 && i<NF ? "_" : "")}' | \
    sed 's/__*/_/g' | \
    sed 's/^_//; s/_$//' | \
    cut -c1-50)  # Limit length

  echo "$topic_name"
}

# Find matching topic directory by keyword
# Args: $1 = keyword to match
#       $2 = base specs directory (optional, defaults to "specs")
# Returns: Matching topic directory path or empty string
find_matching_topic() {
  local keyword="${1:-}"
  local base_specs_dir="${2:-specs}"

  if [[ -z "$keyword" ]]; then
    echo ""
    return 0
  fi

  if [[ ! -d "$base_specs_dir" ]]; then
    echo ""
    return 0
  fi

  # Normalize keyword for matching
  local norm_keyword
  norm_keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

  # Find all topic directories and check for fuzzy match
  local best_match=""
  local best_score=0

  while IFS= read -r topic_dir; do
    local topic_name
    topic_name=$(basename "$topic_dir" | sed 's/^[0-9]*_//')

    # Normalize topic name
    local norm_topic
    norm_topic=$(echo "$topic_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

    # Check for substring match
    if [[ "$norm_topic" == *"$norm_keyword"* ]]; then
      # Calculate match score (longer match = better score)
      local score=${#norm_keyword}
      if [[ $score -gt $best_score ]]; then
        best_score=$score
        best_match="$topic_dir"
      fi
    fi
  done < <(find "$base_specs_dir" -maxdepth 1 -type d -name "[0-9]*_*" 2>/dev/null)

  echo "$best_match"
}

# Get next available topic number
# Args: $1 = base specs directory (optional, defaults to "specs")
# Returns: Next topic number with zero-padding (e.g., "042")
get_next_topic_number() {
  local base_specs_dir="${1:-specs}"

  local max_num=0

  if [[ -d "$base_specs_dir" ]]; then
    while IFS= read -r topic_dir; do
      local num
      num=$(basename "$topic_dir" | grep -oE "^[0-9]+" || echo "0")
      # Remove leading zeros to avoid octal interpretation
      num=$((10#$num))
      if [[ $num -gt $max_num ]]; then
        max_num=$num
      fi
    done < <(find "$base_specs_dir" -maxdepth 1 -type d -name "[0-9]*_*" 2>/dev/null)
  fi

  printf "%03d" $((max_num + 1))
}

# Get or create topic directory with proper numbering
# Args: $1 = description (for generating topic name)
#       $2 = base specs directory (optional, defaults to "specs")
# Returns: topic directory path (e.g., "specs/042_authentication")
get_or_create_topic_dir() {
  local description="${1:-}"
  local base_specs_dir="${2:-specs}"

  if [[ -z "$description" ]]; then
    echo "Error: get_or_create_topic_dir requires description" >&2
    return 1
  fi

  # Extract topic name from description
  local topic_name
  topic_name=$(extract_topic_from_question "$description")

  # Try to find existing matching topic
  local existing_topic
  existing_topic=$(find_matching_topic "$topic_name" "$base_specs_dir")

  if [[ -n "$existing_topic" ]]; then
    echo "$existing_topic"
    return 0
  fi

  # No existing topic found, create new one
  local next_num
  next_num=$(get_next_topic_number "$base_specs_dir")
  local topic_dir="${base_specs_dir}/${next_num}_${topic_name}"

  # Create topic directory with all standard subdirectories
  mkdir -p "$topic_dir"/{plans,reports,summaries,debug,scripts,outputs,artifacts,backups}

  echo "$topic_dir"
}

# Get the next available plan number
# Args: $1 = plans directory (optional, defaults to specs/plans)
# Returns: next plan number (e.g., "047")
get_next_plan_number() {
  local plans_dir="${1:-specs/plans}"

  # Find all plan files with numeric prefixes
  local max_num=0

  if [[ -d "$plans_dir" ]]; then
    while IFS= read -r plan_file; do
      local num
      num=$(basename "$plan_file" | grep -oE "^[0-9]+" || echo "0")
      # Remove leading zeros to avoid octal interpretation
      num=$((10#$num))
      if [[ $num -gt $max_num ]]; then
        max_num=$num
      fi
    done < <(find "$plans_dir" -maxdepth 2 -name "[0-9]*.md" -type f 2>/dev/null)
  fi

  # Return next number with zero-padding
  printf "%03d" $((max_num + 1))
}

# Display available templates in a user-friendly format
# Args: $1 = category filter (optional)
display_available_templates() {
  local category_filter="${1:-}"

  echo "Available Templates:"
  echo "===================="
  echo

  if [[ -n "$category_filter" ]]; then
    echo "Category: $category_filter"
    echo
    list_templates_by_category "$category_filter"
  else
    # Group by category
    local categories
    categories=$(list_templates_by_category)

    while IFS= read -r category; do
      echo "[$category]"
      list_templates_by_category "$category" | sed 's/^/  - /'
      echo
    done <<< "$categories"
  fi
}

# Main function for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    list)
      list_available_templates
      ;;
    list-category)
      list_templates_by_category "${2:-}"
      ;;
    display)
      display_available_templates "${2:-}"
      ;;
    validate)
      validate_generated_plan "$2"
      ;;
    link)
      link_template_to_plan "$2" "$3"
      ;;
    next-number)
      get_next_plan_number "${2:-}"
      ;;
    *)
      echo "Usage: $0 {list|list-category|display|validate|link|next-number} [args...]"
      exit 1
      ;;
  esac
fi
